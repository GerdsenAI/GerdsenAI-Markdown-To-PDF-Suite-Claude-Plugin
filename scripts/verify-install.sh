#!/usr/bin/env bash
# Verify GerdsenAI Document Builder installation
# Exit codes: 0 = installed, 1 = not installed, 2 = broken install
# Output: JSON status on stdout

set -euo pipefail

# Platform detection
case "${OSTYPE:-}" in
  msys*|cygwin*|win32*) IS_WINDOWS=true ;;
  *)                     IS_WINDOWS=false ;;
esac

if $IS_WINDOWS; then
  VENV_PYTHON_REL="venv/Scripts/python.exe"
else
  VENV_PYTHON_REL="venv/bin/python"
fi

SETTINGS_FILE=".claude/gerdsenai.local.md"

# Check if settings file exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{"installed": false, "error": "Settings file not found"}'
  exit 1
fi

# Extract all settings from YAML front matter
DOC_BUILDER_PATH=""
OUTPUT_MODE=""
DEFAULT_OUTPUT_DIR=""
COVER_LOGO=""
FOOTER_LOGO=""
PAGE_SIZE=""

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
      DOC_BUILDER_PATH="${DOC_BUILDER_PATH/#\~/$HOME}"
    fi
    if [[ "$line" =~ ^output_mode:[[:space:]]*\"?([^\"]*)\"? ]]; then
      OUTPUT_MODE="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ ^default_output_dir:[[:space:]]*\"?([^\"]*)\"? ]]; then
      DEFAULT_OUTPUT_DIR="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ ^cover_logo:[[:space:]]*\"?([^\"]*)\"? ]]; then
      COVER_LOGO="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ ^footer_logo:[[:space:]]*\"?([^\"]*)\"? ]]; then
      FOOTER_LOGO="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ ^preferred_page_size:[[:space:]]*\"?([^\"]*)\"? ]]; then
      PAGE_SIZE="${BASH_REMATCH[1]}"
    fi
  fi
done < "$SETTINGS_FILE"

if [[ -z "$DOC_BUILDER_PATH" ]]; then
  echo '{"installed": false, "error": "document_builder_path not set in settings"}'
  exit 1
fi

# Check if path exists
if [[ ! -d "$DOC_BUILDER_PATH" ]]; then
  echo "{\"installed\": false, \"error\": \"Path does not exist: $DOC_BUILDER_PATH\"}"
  exit 1
fi

# Check for the main builder script
if [[ ! -f "$DOC_BUILDER_PATH/document_builder_reportlab.py" ]]; then
  echo "{\"installed\": false, \"error\": \"document_builder_reportlab.py not found at $DOC_BUILDER_PATH\"}"
  exit 2
fi

# Check for venv
if [[ ! -d "$DOC_BUILDER_PATH/venv" ]]; then
  echo "{\"installed\": false, \"path\": \"$DOC_BUILDER_PATH\", \"error\": \"Virtual environment not found\"}"
  exit 2
fi

# Check venv has python
if [[ ! -f "$DOC_BUILDER_PATH/$VENV_PYTHON_REL" ]]; then
  echo "{\"installed\": false, \"path\": \"$DOC_BUILDER_PATH\", \"error\": \"Venv python binary missing\"}"
  exit 2
fi

# Verify the venv python is functional and isolated
VENV_PYTHON="$DOC_BUILDER_PATH/$VENV_PYTHON_REL"
VENV_CHECK_ERR=""
if ! VENV_CHECK_ERR=$("$VENV_PYTHON" -c "import sys; assert sys.prefix != sys.base_prefix" 2>&1); then
  echo "{\"installed\": false, \"path\": \"$DOC_BUILDER_PATH\", \"error\": \"Venv python is not functional or not isolated: $VENV_CHECK_ERR. Run /gerdsenai:setup to recreate it.\"}"
  exit 2
fi

# Check for config.yaml
HAS_CONFIG=false
if [[ -f "$DOC_BUILDER_PATH/config.yaml" ]]; then
  HAS_CONFIG=true
fi

# List available logos
AVAILABLE_LOGOS=""
if [[ -d "$DOC_BUILDER_PATH/Assets" ]]; then
  AVAILABLE_LOGOS=$(ls -1 "$DOC_BUILDER_PATH/Assets/" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
fi

# Build comprehensive status
echo "{\"installed\": true, \"path\": \"$DOC_BUILDER_PATH\", \"has_config\": $HAS_CONFIG, \"output_mode\": \"${OUTPUT_MODE:-builder_pdfs}\", \"default_output_dir\": \"${DEFAULT_OUTPUT_DIR}\", \"cover_logo\": \"${COVER_LOGO}\", \"footer_logo\": \"${FOOTER_LOGO}\", \"page_size\": \"${PAGE_SIZE:-A4}\", \"available_logos\": \"${AVAILABLE_LOGOS}\"}"
exit 0
