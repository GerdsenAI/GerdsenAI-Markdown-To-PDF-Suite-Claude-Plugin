#!/usr/bin/env bash
# Build markdown file(s) into PDF using the GerdsenAI Document Builder
# Args: <settings_path> <markdown_file|--all>

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <settings_path> <markdown_file|--all>"
  exit 1
fi

SETTINGS_FILE="$1"
TARGET="$2"

# Extract document_builder_path from settings YAML front matter
DOC_BUILDER_PATH=""
in_frontmatter=false
while IFS= read -r line; do
  if [[ "$line" == "---" ]]; then
    if $in_frontmatter; then
      break
    else
      in_frontmatter=true
      continue
    fi
  fi
  if $in_frontmatter; then
    if [[ "$line" =~ ^document_builder_path:[[:space:]]*\"?([^\"]*)\"? ]]; then
      DOC_BUILDER_PATH="${BASH_REMATCH[1]}"
    fi
  fi
done < "$SETTINGS_FILE"

if [[ -z "$DOC_BUILDER_PATH" ]]; then
  echo "ERROR: document_builder_path not found in $SETTINGS_FILE"
  exit 1
fi

if [[ ! -d "$DOC_BUILDER_PATH" ]]; then
  echo "ERROR: Document Builder not found at $DOC_BUILDER_PATH"
  exit 1
fi

VENV_PYTHON="$DOC_BUILDER_PATH/venv/bin/python"
BUILDER_SCRIPT="$DOC_BUILDER_PATH/document_builder_reportlab.py"

if [[ ! -f "$VENV_PYTHON" ]]; then
  echo "ERROR: Virtual environment not found. Run setup first."
  exit 1
fi

if [[ "$TARGET" == "--all" ]]; then
  # Build all files in To_Build/
  echo "Building all markdown files..."
  cd "$DOC_BUILDER_PATH"
  "$VENV_PYTHON" "$BUILDER_SCRIPT" --all
  BUILD_EXIT=$?
else
  # Build a single file
  MARKDOWN_FILE="$TARGET"

  # Resolve to absolute path if relative
  if [[ ! "$MARKDOWN_FILE" = /* ]]; then
    MARKDOWN_FILE="$(pwd)/$MARKDOWN_FILE"
  fi

  if [[ ! -f "$MARKDOWN_FILE" ]]; then
    echo "ERROR: File not found: $MARKDOWN_FILE"
    exit 1
  fi

  FILENAME=$(basename "$MARKDOWN_FILE")

  # Copy file to To_Build/ directory
  cp "$MARKDOWN_FILE" "$DOC_BUILDER_PATH/To_Build/$FILENAME"

  echo "Building: $FILENAME"
  cd "$DOC_BUILDER_PATH"
  "$VENV_PYTHON" "$BUILDER_SCRIPT" "$FILENAME"
  BUILD_EXIT=$?
fi

if [[ $BUILD_EXIT -eq 0 ]]; then
  echo "BUILD_SUCCESS"
  # List generated PDFs
  if [[ -d "$DOC_BUILDER_PATH/PDFs" ]]; then
    echo "Generated PDFs:"
    ls -1t "$DOC_BUILDER_PATH/PDFs/"*.pdf 2>/dev/null | head -5
  fi
else
  echo "BUILD_FAILED (exit code: $BUILD_EXIT)"
  # Show recent log for diagnostics
  LATEST_LOG=$(ls -1t "$DOC_BUILDER_PATH/Logs/"*.log* 2>/dev/null | head -1)
  if [[ -n "${LATEST_LOG:-}" ]]; then
    echo "Recent log output:"
    tail -20 "$LATEST_LOG"
  fi
  exit $BUILD_EXIT
fi
