#!/usr/bin/env bash
# Vector DB automation hooks for GerdsenAI Document Builder plugin
# Triggered by Claude Code PostToolUse and Stop hooks.
#
# Usage: vector-db-hooks.sh <event> [args...]
# Events: post-tool, session-end
#
# CRITICAL: Hooks must NEVER block the user. All errors are silently ignored.
# This script exits 0 in every code path — failure is not an option for hooks.

set -euo pipefail

EVENT="${1:-}"
shift || true

# --- Load shared library ---
SCRIPT_DIR="$(dirname "$0")"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! source "$PLUGIN_ROOT/scripts/lib/parse-settings.sh" 2>/dev/null; then
  exit 0
fi
detect_platform

# --- Read settings ---
SETTINGS_FILE=".claude/gerdsenai.local.md"

if [[ ! -f "$SETTINGS_FILE" ]]; then
  exit 0
fi

parse_settings "$SETTINGS_FILE" 2>/dev/null || exit 0

# Exit silently if vector DB is not configured
if [[ -z "$GERDSEN_VECTOR_DB_MODE" ]] || [[ "$GERDSEN_VECTOR_DB_MODE" == "none" ]]; then
  exit 0
fi

# Resolve venv Python path
DOC_BUILDER_PATH="$GERDSEN_DOC_BUILDER_PATH"
if [[ -z "$DOC_BUILDER_PATH" ]]; then
  exit 0
fi
VENV_PY="$DOC_BUILDER_PATH/$VENV_PYTHON_REL"
if [[ ! -f "$VENV_PY" ]]; then
  exit 0
fi

# --- Event Handlers ---

handle_post_tool() {
  # Git commit detection
  if [[ "$GERDSEN_VECTOR_DB_HOOK_ON_COMMIT" == "true" ]]; then
    # Check if a git commit just happened by inspecting recent git activity.
    # The PostToolUse hook fires after Bash tool use — we check if the repo
    # HEAD changed recently (within the last 5 seconds) as a proxy for
    # "a commit just happened in this tool invocation".
    if git rev-parse --is-inside-work-tree &>/dev/null; then
      local head_hash
      head_hash="$(git log --oneline -1 --format='%H' 2>/dev/null)" || return 0

      # Use a marker file to avoid re-processing the same commit
      local marker_dir="${TMPDIR:-/tmp}/gerdsenai-hooks"
      mkdir -p "$marker_dir" 2>/dev/null || return 0
      local marker_file="$marker_dir/last-commit-hook"

      local last_processed=""
      if [[ -f "$marker_file" ]]; then
        last_processed="$(cat "$marker_file" 2>/dev/null)" || true
      fi

      if [[ "$head_hash" == "$last_processed" ]]; then
        # Already processed this commit
        return 0
      fi

      # Record that we are processing this commit
      echo "$head_hash" > "$marker_file" 2>/dev/null || true

      # Extract commit info
      local commit_oneline
      commit_oneline="$(git log --oneline -1 2>/dev/null)" || return 0

      local changed_files
      changed_files="$(git diff-tree --no-commit-id --name-only -r HEAD 2>/dev/null | tr '\n' ', ' | sed 's/,$//')" || return 0

      local short_hash
      short_hash="$(git log -1 --format='%h' 2>/dev/null)" || return 0

      local summary="Commit: ${commit_oneline}. Files: ${changed_files}"

      # Get repo name for collection
      local repo_name
      repo_name="$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")" || return 0

      local collection="${repo_name}-sprint"

      # Upsert to ChromaDB if mode includes it (chromadb or dual or unset)
      if [[ "$GERDSEN_VECTOR_DB_MODE" == "chromadb" ]] || [[ "$GERDSEN_VECTOR_DB_MODE" == "dual" ]] || [[ -z "$GERDSEN_VECTOR_DB_MODE" ]]; then
        "$VENV_PY" "$PLUGIN_ROOT/scripts/chromadb-store.py" store "$collection" "$summary" \
          --metadata "{\"type\":\"commit\",\"hash\":\"${short_hash}\"}" \
          >/dev/null 2>&1 || true
      fi
    fi
  fi

  # File change detection (opt-in, currently a stub)
  if [[ "$GERDSEN_VECTOR_DB_HOOK_ON_FILE_CHANGE" == "true" ]]; then
    # Stub: file change tracking is too noisy for automatic upsert.
    # Future: could batch file changes and upsert on session-end instead.
    :
  fi
}

handle_session_end() {
  if [[ "$GERDSEN_VECTOR_DB_HOOK_ON_SESSION_END" != "true" ]]; then
    return 0
  fi

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    return 0
  fi

  local repo_name
  repo_name="$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")" || return 0

  local collection="${repo_name}-sprint"
  local timestamp
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)" || timestamp="unknown"

  local summary="Session ended at ${timestamp}."

  # Upsert to ChromaDB if mode includes it (chromadb or dual or unset)
  if [[ "$GERDSEN_VECTOR_DB_MODE" == "chromadb" ]] || [[ "$GERDSEN_VECTOR_DB_MODE" == "dual" ]] || [[ -z "$GERDSEN_VECTOR_DB_MODE" ]]; then
    "$VENV_PY" "$PLUGIN_ROOT/scripts/chromadb-store.py" store "$collection" "$summary" \
      --metadata "{\"type\":\"session-marker\",\"timestamp\":\"${timestamp}\"}" \
      >/dev/null 2>&1 || true
  fi
}

# --- Dispatch ---
case "$EVENT" in
  post-tool)
    handle_post_tool || exit 0
    ;;
  session-end)
    handle_session_end || exit 0
    ;;
  *)
    # Unknown event — exit silently
    ;;
esac

exit 0
