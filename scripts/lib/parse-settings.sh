#!/usr/bin/env bash
# Shared library: platform detection and YAML front matter parser
# Source this file from other scripts: source "$(dirname "$0")/lib/parse-settings.sh"

# --- Platform Detection ---
# Sets: IS_WINDOWS, PYTHON_CMD, VENV_PYTHON_REL

detect_platform() {
  case "${OSTYPE:-}" in
    msys*|cygwin*|win32*) IS_WINDOWS=true ;;
    *)                     IS_WINDOWS=false ;;
  esac

  if $IS_WINDOWS; then
    PYTHON_CMD="python"
    VENV_PYTHON_REL="venv/Scripts/python.exe"
    # Guard against Microsoft Store Python stub: it exists in PATH but opens
    # the Store app instead of running Python. Fall back to python3 if the
    # default "python" can't actually execute a simple script.
    if ! "$PYTHON_CMD" -c "import sys" 2>/dev/null; then
      if command -v python3 &>/dev/null && python3 -c "import sys" 2>/dev/null; then
        PYTHON_CMD="python3"
      fi
    fi
  else
    PYTHON_CMD="python3"
    VENV_PYTHON_REL="venv/bin/python"
  fi
}

# --- YAML Front Matter Parser ---
# Reads a settings file and exports all known fields as GERDSEN_* variables.
# Usage: parse_settings "/path/to/settings.md"
# Exports: GERDSEN_DOC_BUILDER_PATH, GERDSEN_OUTPUT_MODE, GERDSEN_OUTPUT_DIR,
#          GERDSEN_FILENAME_PATTERN, GERDSEN_COVER_LOGO, GERDSEN_FOOTER_LOGO,
#          GERDSEN_PAGE_SIZE, GERDSEN_CITATION_STYLE,
#          GERDSEN_VECTOR_DB_MODE, GERDSEN_VECTOR_DB_BACKEND,
#          GERDSEN_VECTOR_DB_HOOK_ON_COMMIT, GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE,
#          GERDSEN_VECTOR_DB_HOOK_ON_SESSION_END

parse_settings() {
  local settings_file="$1"

  GERDSEN_DOC_BUILDER_PATH=""
  GERDSEN_OUTPUT_MODE=""
  GERDSEN_OUTPUT_DIR=""
  GERDSEN_FILENAME_PATTERN=""
  GERDSEN_COVER_LOGO=""
  GERDSEN_FOOTER_LOGO=""
  GERDSEN_PAGE_SIZE=""
  GERDSEN_CITATION_STYLE=""
  GERDSEN_VECTOR_DB_MODE=""
  GERDSEN_VECTOR_DB_BACKEND=""
  GERDSEN_VECTOR_DB_HOOK_ON_COMMIT=""
  GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE=""
  GERDSEN_VECTOR_DB_HOOK_ON_SESSION_END=""

  local in_frontmatter=false
  while IFS= read -r line; do
    line="${line%$'\r'}"   # strip trailing CR for Windows CRLF compatibility
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
        GERDSEN_DOC_BUILDER_PATH="${BASH_REMATCH[1]}"
        GERDSEN_DOC_BUILDER_PATH="${GERDSEN_DOC_BUILDER_PATH/#\~/$HOME}"
      fi
      if [[ "$line" =~ ^output_mode:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_OUTPUT_MODE="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^default_output_dir:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_OUTPUT_DIR="${BASH_REMATCH[1]}"
        GERDSEN_OUTPUT_DIR="${GERDSEN_OUTPUT_DIR/#\~/$HOME}"
      fi
      if [[ "$line" =~ ^filename_pattern:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_FILENAME_PATTERN="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^cover_logo:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_COVER_LOGO="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^footer_logo:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_FOOTER_LOGO="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^preferred_page_size:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_PAGE_SIZE="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^citation_style:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_CITATION_STYLE="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^vector_db_mode:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_MODE="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^vector_db_backend:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_BACKEND="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^vector_db_hook_on_commit:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_HOOK_ON_COMMIT="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^vector_db_hook_on_file_change:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^vector_db_hook_on_session_end:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_HOOK_ON_SESSION_END="${BASH_REMATCH[1]}"
      fi
    fi
  done < "$settings_file"

  # Strip trailing whitespace from all parsed values (guards against editors
  # that pad lines or trailing spaces after closing quotes)
  GERDSEN_DOC_BUILDER_PATH="${GERDSEN_DOC_BUILDER_PATH%"${GERDSEN_DOC_BUILDER_PATH##*[![:space:]]}"}"
  GERDSEN_OUTPUT_MODE="${GERDSEN_OUTPUT_MODE%"${GERDSEN_OUTPUT_MODE##*[![:space:]]}"}"
  GERDSEN_OUTPUT_DIR="${GERDSEN_OUTPUT_DIR%"${GERDSEN_OUTPUT_DIR##*[![:space:]]}"}"
  GERDSEN_FILENAME_PATTERN="${GERDSEN_FILENAME_PATTERN%"${GERDSEN_FILENAME_PATTERN##*[![:space:]]}"}"
  GERDSEN_COVER_LOGO="${GERDSEN_COVER_LOGO%"${GERDSEN_COVER_LOGO##*[![:space:]]}"}"
  GERDSEN_FOOTER_LOGO="${GERDSEN_FOOTER_LOGO%"${GERDSEN_FOOTER_LOGO##*[![:space:]]}"}"
  GERDSEN_PAGE_SIZE="${GERDSEN_PAGE_SIZE%"${GERDSEN_PAGE_SIZE##*[![:space:]]}"}"
  GERDSEN_CITATION_STYLE="${GERDSEN_CITATION_STYLE%"${GERDSEN_CITATION_STYLE##*[![:space:]]}"}"
  GERDSEN_VECTOR_DB_MODE="${GERDSEN_VECTOR_DB_MODE%"${GERDSEN_VECTOR_DB_MODE##*[![:space:]]}"}"
  GERDSEN_VECTOR_DB_BACKEND="${GERDSEN_VECTOR_DB_BACKEND%"${GERDSEN_VECTOR_DB_BACKEND##*[![:space:]]}"}"
  GERDSEN_VECTOR_DB_HOOK_ON_COMMIT="${GERDSEN_VECTOR_DB_HOOK_ON_COMMIT%"${GERDSEN_VECTOR_DB_HOOK_ON_COMMIT##*[![:space:]]}"}"
  GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE="${GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE%"${GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE##*[![:space:]]}"}"
  GERDSEN_VECTOR_DB_HOOK_ON_SESSION_END="${GERDSEN_VECTOR_DB_HOOK_ON_SESSION_END%"${GERDSEN_VECTOR_DB_HOOK_ON_SESSION_END##*[![:space:]]}"}"

  # Validate output_mode if set
  if [[ -n "$GERDSEN_OUTPUT_MODE" ]]; then
    case "$GERDSEN_OUTPUT_MODE" in
      same_directory|custom|builder_pdfs) ;;
      *)
        echo "WARNING: Unknown output_mode '$GERDSEN_OUTPUT_MODE' in settings. Expected: same_directory|custom|builder_pdfs" >&2
        ;;
    esac
  fi
}
