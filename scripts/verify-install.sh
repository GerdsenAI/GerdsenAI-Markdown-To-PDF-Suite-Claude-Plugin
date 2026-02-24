#!/usr/bin/env bash
# Verify GerdsenAI Document Builder installation
# Exit codes: 0 = installed, 1 = not installed, 2 = broken install
# Output: JSON status on stdout

set -euo pipefail

SETTINGS_FILE=".claude/gerdsenai-md-to-pdf-suite.local.md"

# Check if settings file exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{"installed": false, "error": "Settings file not found"}'
  exit 1
fi

# Extract document_builder_path from YAML front matter
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
if [[ ! -f "$DOC_BUILDER_PATH/venv/bin/python" ]]; then
  echo "{\"installed\": false, \"path\": \"$DOC_BUILDER_PATH\", \"error\": \"Venv python binary missing\"}"
  exit 2
fi

echo "{\"installed\": true, \"path\": \"$DOC_BUILDER_PATH\"}"
exit 0
