#!/usr/bin/env bash
# Build markdown file(s) into PDF using the GerdsenAI Document Builder
# Args: <settings_path> <markdown_file|--all|--recursive> [--output-dir <dir>] [--output-name <name>]

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <settings_path> <markdown_file|--all|--recursive [dir]> [--output-dir <dir>] [--output-name <name>]"
  exit 1
fi

SETTINGS_FILE="$1"
TARGET="$2"
shift 2

# Parse optional arguments
OUTPUT_DIR=""
OUTPUT_NAME=""
RECURSIVE_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="${2:-}"
      OUTPUT_DIR="${OUTPUT_DIR/#\~/$HOME}"
      shift 2
      ;;
    --output-name)
      OUTPUT_NAME="${2:-}"
      shift 2
      ;;
    *)
      # For --recursive, the next arg might be the directory
      if [[ "$TARGET" == "--recursive" ]] && [[ -z "$RECURSIVE_DIR" ]]; then
        RECURSIVE_DIR="$1"
        RECURSIVE_DIR="${RECURSIVE_DIR/#\~/$HOME}"
      fi
      shift
      ;;
  esac
done

# Expand ~ in settings path
SETTINGS_FILE="${SETTINGS_FILE/#\~/$HOME}"

# Extract settings from YAML front matter
DOC_BUILDER_PATH=""
SETTINGS_OUTPUT_MODE=""
SETTINGS_OUTPUT_DIR=""
SETTINGS_FILENAME_PATTERN=""

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
      SETTINGS_OUTPUT_MODE="${BASH_REMATCH[1]}"
    fi
    if [[ "$line" =~ ^default_output_dir:[[:space:]]*\"?([^\"]*)\"? ]]; then
      SETTINGS_OUTPUT_DIR="${BASH_REMATCH[1]}"
      SETTINGS_OUTPUT_DIR="${SETTINGS_OUTPUT_DIR/#\~/$HOME}"
    fi
    if [[ "$line" =~ ^filename_pattern:[[:space:]]*\"?([^\"]*)\"? ]]; then
      SETTINGS_FILENAME_PATTERN="${BASH_REMATCH[1]}"
    fi
  fi
done < "$SETTINGS_FILE"

if [[ -z "$DOC_BUILDER_PATH" ]]; then
  echo '{"success": false, "error": "document_builder_path not found in settings"}'
  exit 1
fi

if [[ ! -d "$DOC_BUILDER_PATH" ]]; then
  echo "{\"success\": false, \"error\": \"Document Builder not found at $DOC_BUILDER_PATH\"}"
  exit 1
fi

VENV_PYTHON="$DOC_BUILDER_PATH/venv/bin/python"
BUILDER_SCRIPT="$DOC_BUILDER_PATH/document_builder_reportlab.py"

if [[ ! -f "$VENV_PYTHON" ]]; then
  echo '{"success": false, "error": "Virtual environment not found. Run setup first."}'
  exit 1
fi

# Function to build a single file and handle output
build_single_file() {
  local markdown_file="$1"
  local custom_output_dir="${2:-}"
  local custom_output_name="${3:-}"

  # Resolve to absolute path if relative
  if [[ ! "$markdown_file" = /* ]]; then
    markdown_file="$(pwd)/$markdown_file"
  fi

  if [[ ! -f "$markdown_file" ]]; then
    echo "{\"success\": false, \"error\": \"File not found: $markdown_file\"}"
    return 1
  fi

  local filename
  filename=$(basename "$markdown_file")
  local source_dir
  source_dir=$(dirname "$markdown_file")

  # Copy file to To_Build/ directory
  cp "$markdown_file" "$DOC_BUILDER_PATH/To_Build/$filename"

  # Build the PDF
  local build_args=("$filename")
  if [[ -n "$custom_output_name" ]]; then
    build_args+=("-o" "$custom_output_name")
  fi

  cd "$DOC_BUILDER_PATH"
  local build_exit=0
  "$VENV_PYTHON" "$BUILDER_SCRIPT" "${build_args[@]}" && build_exit=0 || build_exit=$?

  if [[ $build_exit -eq 0 ]]; then
    # Find the generated PDF (most recent in PDFs/)
    local pdf_path
    pdf_path=$(ls -1t "$DOC_BUILDER_PATH/PDFs/"*.pdf 2>/dev/null | head -1)

    if [[ -n "$pdf_path" ]]; then
      local final_pdf_path="$pdf_path"
      local pdf_size
      pdf_size=$(stat -c%s "$pdf_path" 2>/dev/null || stat -f%z "$pdf_path" 2>/dev/null || echo "0")

      # Determine output location
      local effective_output_dir="$custom_output_dir"
      if [[ -z "$effective_output_dir" ]]; then
        case "${SETTINGS_OUTPUT_MODE:-builder_pdfs}" in
          same_directory)
            effective_output_dir="$source_dir"
            ;;
          custom)
            effective_output_dir="${SETTINGS_OUTPUT_DIR:-}"
            ;;
          builder_pdfs|*)
            # Default: leave in PDFs/
            effective_output_dir=""
            ;;
        esac
      fi

      # Copy PDF to output location if different from builder PDFs
      if [[ -n "$effective_output_dir" ]] && [[ "$effective_output_dir" != "$DOC_BUILDER_PATH/PDFs" ]]; then
        mkdir -p "$effective_output_dir"
        local pdf_basename
        pdf_basename=$(basename "$pdf_path")
        cp "$pdf_path" "$effective_output_dir/$pdf_basename"
        final_pdf_path="$effective_output_dir/$pdf_basename"
      fi

      echo "{\"success\": true, \"pdf_path\": \"$final_pdf_path\", \"builder_pdf_path\": \"$pdf_path\", \"size_bytes\": $pdf_size}"
    else
      echo "{\"success\": true, \"warning\": \"Build succeeded but no PDF found in PDFs/\"}"
    fi
  else
    # Show recent log for diagnostics
    local log_excerpt=""
    local latest_log
    latest_log=$(ls -1t "$DOC_BUILDER_PATH/Logs/"*.log* 2>/dev/null | head -1)
    if [[ -n "${latest_log:-}" ]]; then
      log_excerpt=$(tail -10 "$latest_log" | tr '\n' '|' | sed 's/"/\\"/g')
    fi
    echo "{\"success\": false, \"error\": \"Build failed (exit code: $build_exit)\", \"log\": \"$log_excerpt\"}"
    return $build_exit
  fi
}

# Handle build modes
if [[ "$TARGET" == "--all" ]]; then
  echo "Building all markdown files..."
  cd "$DOC_BUILDER_PATH"
  "$VENV_PYTHON" "$BUILDER_SCRIPT" --all && BUILD_EXIT=0 || BUILD_EXIT=$?
  if [[ $BUILD_EXIT -eq 0 ]]; then
    echo "BUILD_SUCCESS"
    if [[ -d "$DOC_BUILDER_PATH/PDFs" ]]; then
      echo "Generated PDFs:"
      ls -1t "$DOC_BUILDER_PATH/PDFs/"*.pdf 2>/dev/null | head -10
    fi
  else
    echo "BUILD_FAILED (exit code: $BUILD_EXIT)"
    LATEST_LOG=$(ls -1t "$DOC_BUILDER_PATH/Logs/"*.log* 2>/dev/null | head -1)
    if [[ -n "${LATEST_LOG:-}" ]]; then
      echo "Recent log output:"
      tail -20 "$LATEST_LOG"
    fi
    exit $BUILD_EXIT
  fi
elif [[ "$TARGET" == "--recursive" ]]; then
  # Recursive mode: find all .md files in directory tree
  SCAN_DIR="${RECURSIVE_DIR:-.}"
  SCAN_DIR="${SCAN_DIR/#\~/$HOME}"
  if [[ ! "$SCAN_DIR" = /* ]]; then
    SCAN_DIR="$(pwd)/$SCAN_DIR"
  fi

  echo "Scanning $SCAN_DIR for markdown files..."
  RESULTS=()
  FAIL_COUNT=0
  SUCCESS_COUNT=0

  while IFS= read -r -d '' md_file; do
    md_dir=$(dirname "$md_file")
    echo "Building: $md_file"
    if build_single_file "$md_file" "$md_dir" "$OUTPUT_NAME"; then
      ((SUCCESS_COUNT++))
    else
      ((FAIL_COUNT++))
    fi
  done < <(find "$SCAN_DIR" -name "*.md" \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/venv/*" \
    -not -path "*/__pycache__/*" \
    -not -path "*/.claude/*" \
    -not -path "*/todo.md" \
    -not -name "README.md" \
    -not -name "CLAUDE.md" \
    -not -name "CHANGELOG.md" \
    -not -name "LICENSE.md" \
    -print0)

  echo "{\"recursive_complete\": true, \"success_count\": $SUCCESS_COUNT, \"fail_count\": $FAIL_COUNT}"
else
  # Single file build
  build_single_file "$TARGET" "$OUTPUT_DIR" "$OUTPUT_NAME"
fi
