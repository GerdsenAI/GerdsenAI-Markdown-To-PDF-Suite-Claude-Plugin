#!/usr/bin/env bash
# Verify GerdsenAI Document Builder installation
# Exit codes: 0 = installed, 1 = not installed, 2 = broken install
# Output: JSON status on stdout

set -euo pipefail

# Load shared library
source "$(dirname "$0")/lib/parse-settings.sh"
detect_platform

SETTINGS_FILE=".claude/gerdsenai.local.md"

# Check if settings file exists
if [[ ! -f "$SETTINGS_FILE" ]]; then
  echo '{"installed": false, "error": "Settings file not found"}'
  exit 1
fi

# Parse settings using shared library
parse_settings "$SETTINGS_FILE"
DOC_BUILDER_PATH="$GERDSEN_DOC_BUILDER_PATH"
OUTPUT_MODE="$GERDSEN_OUTPUT_MODE"
DEFAULT_OUTPUT_DIR="$GERDSEN_OUTPUT_DIR"
COVER_LOGO="$GERDSEN_COVER_LOGO"
FOOTER_LOGO="$GERDSEN_FOOTER_LOGO"
PAGE_SIZE="$GERDSEN_PAGE_SIZE"

if [[ -z "$DOC_BUILDER_PATH" ]]; then
  echo '{"installed": false, "error": "document_builder_path not set in settings"}'
  exit 1
fi

# Helper: emit JSON error with safe path escaping (backslashes in Windows paths)
json_error() {
  local safe_path="${1//\\/\\\\}"
  safe_path="${safe_path//\"/\\\"}"
  local safe_msg="${2//\\/\\\\}"
  safe_msg="${safe_msg//\"/\\\"}"
  echo "{\"installed\": false, \"path\": \"$safe_path\", \"error\": \"$safe_msg\"}"
}

# Check if path exists
if [[ ! -d "$DOC_BUILDER_PATH" ]]; then
  json_error "$DOC_BUILDER_PATH" "Path does not exist: $DOC_BUILDER_PATH"
  exit 1
fi

# Check for the main builder script
if [[ ! -f "$DOC_BUILDER_PATH/document_builder_reportlab.py" ]]; then
  json_error "$DOC_BUILDER_PATH" "document_builder_reportlab.py not found at $DOC_BUILDER_PATH"
  exit 2
fi

# Check for venv
if [[ ! -d "$DOC_BUILDER_PATH/venv" ]]; then
  json_error "$DOC_BUILDER_PATH" "Virtual environment not found"
  exit 2
fi

# Check venv has python
if [[ ! -f "$DOC_BUILDER_PATH/$VENV_PYTHON_REL" ]]; then
  json_error "$DOC_BUILDER_PATH" "Venv python binary missing"
  exit 2
fi

# Verify the venv python is functional and isolated
VENV_PYTHON="$DOC_BUILDER_PATH/$VENV_PYTHON_REL"
VENV_CHECK_ERR=""
if ! VENV_CHECK_ERR=$("$VENV_PYTHON" -c "import sys; assert sys.prefix != sys.base_prefix" 2>&1); then
  json_error "$DOC_BUILDER_PATH" "Venv python is not functional or not isolated: $VENV_CHECK_ERR. Run /gerdsenai:setup to recreate it."
  exit 2
fi

# Check for config.yaml
HAS_CONFIG=false
if [[ -f "$DOC_BUILDER_PATH/config.yaml" ]]; then
  HAS_CONFIG=true
fi

# Build comprehensive status using Python for safe JSON escaping
# (paths on Windows may contain backslashes or special characters)
"$VENV_PYTHON" -c "
import json, sys, os, glob

path = sys.argv[1]
has_config = sys.argv[2] == 'true'
output_mode = sys.argv[3] or 'builder_pdfs'
output_dir = sys.argv[4]
cover_logo = sys.argv[5]
footer_logo = sys.argv[6]
page_size = sys.argv[7] or 'A4'

# List image files in Assets/
logos = []
assets_dir = os.path.join(path, 'Assets')
if os.path.isdir(assets_dir):
    for ext in ('*.png', '*.jpg', '*.jpeg', '*.svg'):
        logos.extend(os.path.basename(f) for f in glob.glob(os.path.join(assets_dir, ext)))
    logos.sort()

print(json.dumps({
    'installed': True,
    'path': path,
    'has_config': has_config,
    'output_mode': output_mode,
    'default_output_dir': output_dir,
    'cover_logo': cover_logo,
    'footer_logo': footer_logo,
    'page_size': page_size,
    'available_logos': ','.join(logos)
}))
" "$DOC_BUILDER_PATH" "$HAS_CONFIG" "${OUTPUT_MODE:-}" "${DEFAULT_OUTPUT_DIR:-}" "${COVER_LOGO:-}" "${FOOTER_LOGO:-}" "${PAGE_SIZE:-}"
exit 0
