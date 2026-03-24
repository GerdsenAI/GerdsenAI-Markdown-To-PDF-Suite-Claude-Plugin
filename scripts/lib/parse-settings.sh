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
#          GERDSEN_VECTOR_DB_MODE, GERDSEN_VECTOR_DB_PRIMARY,
#          GERDSEN_VECTOR_DB_HOOK_ON_COMMIT, GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE,
#          GERDSEN_VECTOR_DB_HOOK_ON_SESSION_START, GERDSEN_VECTOR_DB_HOOK_ON_SESSION_END

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
  GERDSEN_VECTOR_DB_PRIMARY=""
  GERDSEN_VECTOR_DB_HOOK_ON_COMMIT=""
  GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE=""
  GERDSEN_VECTOR_DB_HOOK_ON_SESSION_START=""
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
      if [[ "$line" =~ ^vector_db_primary:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_PRIMARY="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^vector_db_hook_on_commit:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_HOOK_ON_COMMIT="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^vector_db_hook_on_file_change:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE="${BASH_REMATCH[1]}"
      fi
      if [[ "$line" =~ ^vector_db_hook_on_session_start:[[:space:]]*\"?([^\"]*)\"? ]]; then
        GERDSEN_VECTOR_DB_HOOK_ON_SESSION_START="${BASH_REMATCH[1]}"
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
  GERDSEN_VECTOR_DB_PRIMARY="${GERDSEN_VECTOR_DB_PRIMARY%"${GERDSEN_VECTOR_DB_PRIMARY##*[![:space:]]}"}"
  GERDSEN_VECTOR_DB_HOOK_ON_COMMIT="${GERDSEN_VECTOR_DB_HOOK_ON_COMMIT%"${GERDSEN_VECTOR_DB_HOOK_ON_COMMIT##*[![:space:]]}"}"
  GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE="${GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE%"${GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE##*[![:space:]]}"}"
  GERDSEN_VECTOR_DB_HOOK_ON_SESSION_START="${GERDSEN_VECTOR_DB_HOOK_ON_SESSION_START%"${GERDSEN_VECTOR_DB_HOOK_ON_SESSION_START##*[![:space:]]}"}"
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

# --- Locked ChromaDB Installer ---
# Prevents concurrent pip installs from racing on the same venv.
# Usage: install_chromadb_locked <venv_python> [--background]
# Foreground: returns 0 on success, 1 on failure (error on stdout).
# Background: spawns detached process, always returns 0.
# Skips if lock is held by another process (< 5 minutes old).

install_chromadb_locked() {
  local venv_py="$1"
  local background="${2:-}"
  local venv_dir
  venv_dir="$(dirname "$(dirname "$venv_py")")"
  local lock_file="$venv_dir/.chromadb-install.lock"

  # Check if lock exists and is recent (< 300 seconds = 5 minutes)
  if [[ -f "$lock_file" ]]; then
    local lock_age=9999
    if [[ "$IS_WINDOWS" == "true" ]]; then
      lock_age=$("$venv_py" -c "
import os, time
try:
    print(int(time.time() - os.path.getmtime('$(echo "$lock_file" | sed "s/'/\\\\'/g")')))
except:
    print(9999)
" 2>/dev/null) || lock_age=9999
    else
      local lock_mtime
      lock_mtime=$(stat -c %Y "$lock_file" 2>/dev/null || stat -f %m "$lock_file" 2>/dev/null || echo 0)
      lock_age=$(( $(date +%s) - lock_mtime ))
    fi
    if [[ "$lock_age" -lt 300 ]]; then
      return 0  # Another install is in progress, skip
    fi
  fi

  local pin_spec="'chromadb>=0.5,<1.0' 'sentence-transformers>=2.2,<4.0'"

  if [[ "$background" == "--background" ]]; then
    # Background: detach via Python Popen (cross-platform)
    "$venv_py" -c "
import subprocess, sys, os
lock = '$(echo "$lock_file" | sed "s/'/\\\\'/g")'
open(lock, 'w').write(str(os.getpid()))
kwargs = dict(stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
if os.name == 'nt':
    kwargs['creationflags'] = subprocess.DETACHED_PROCESS | subprocess.CREATE_NO_WINDOW
else:
    kwargs['start_new_session'] = True
# Child installs then removes lock
subprocess.Popen([sys.executable, '-c', '''
import subprocess, sys, os
r = subprocess.call([sys.executable, '-m', 'pip', 'install',
    'chromadb>=0.5,<1.0', 'sentence-transformers>=2.2,<4.0', '-q'])
lock = \"\"\"''' + lock + '''\"\"\"
if os.path.exists(lock):
    os.remove(lock)
'''], **kwargs)
" 2>/dev/null
    return 0
  else
    # Foreground: run with error capture
    echo "$$" > "$lock_file" 2>/dev/null || true
    local err=""
    if ! err=$("$venv_py" -m pip install 'chromadb>=0.5,<1.0' 'sentence-transformers>=2.2,<4.0' -q 2>&1); then
      rm -f "$lock_file" 2>/dev/null || true
      echo "$err"
      return 1
    fi
    rm -f "$lock_file" 2>/dev/null || true
    return 0
  fi
}
