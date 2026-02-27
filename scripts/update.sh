#!/usr/bin/env bash
# Update the GerdsenAI Document Builder to the latest version
# Supports: GitHub Release download (if installed from release) or git pull (if cloned)
# Args: <document_builder_path>

set -euo pipefail

# Platform detection
case "${OSTYPE:-}" in
  msys*|cygwin*|win32*) IS_WINDOWS=true ;;
  *)                     IS_WINDOWS=false ;;
esac

if $IS_WINDOWS; then
  PYTHON_CMD="python"
  VENV_PYTHON_REL="venv/Scripts/python.exe"
else
  PYTHON_CMD="python3"
  VENV_PYTHON_REL="venv/bin/python"
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <document_builder_path>"
  exit 1
fi

DOC_BUILDER_PATH="$1"

# Expand ~ if present
DOC_BUILDER_PATH="${DOC_BUILDER_PATH/#\~/$HOME}"

if [[ ! -d "$DOC_BUILDER_PATH" ]]; then
  echo "ERROR: Document Builder not found at $DOC_BUILDER_PATH"
  exit 1
fi

GITHUB_REPO="GerdsenAI/GerdsenAI_Document_Builder"

# Determine update method: git repo or release-based
if [[ -d "$DOC_BUILDER_PATH/.git" ]]; then
  # Git-based update
  echo "Updating via git pull..."
  cd "$DOC_BUILDER_PATH"
  BEFORE=$(git rev-parse HEAD)
  git pull
  AFTER=$(git rev-parse HEAD)

  if [[ "$BEFORE" == "$AFTER" ]]; then
    echo "Already up to date."
  else
    echo "Updated from ${BEFORE:0:7} to ${AFTER:0:7}"
    echo ""
    echo "Changes:"
    git log --oneline "$BEFORE..$AFTER"
  fi
else
  # Release-based update
  echo "Checking for latest GitHub Release..."
  if ! command -v curl &>/dev/null; then
    echo "ERROR: curl is required for release-based updates"
    exit 1
  fi

  RELEASE_INFO=$(curl -sf "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" 2>/dev/null || true)
  if [[ -z "$RELEASE_INFO" ]]; then
    echo "ERROR: Could not fetch release info. Check internet connection."
    exit 1
  fi

  LATEST_TAG=$(echo "$RELEASE_INFO" | $PYTHON_CMD -c "import sys, json; print(json.load(sys.stdin).get('tag_name', ''))" 2>/dev/null || true)
  TARBALL_URL=$(echo "$RELEASE_INFO" | $PYTHON_CMD -c "
import sys, json
data = json.load(sys.stdin)
for a in data.get('assets', []):
    if a['name'].endswith('.tar.gz'):
        print(a['browser_download_url'])
        break
" 2>/dev/null || true)

  if [[ -z "$TARBALL_URL" ]]; then
    echo "No release tarball found. Try installing via git clone instead."
    exit 1
  fi

  # Check current version if available
  CURRENT_VERSION=""
  if [[ -f "$DOC_BUILDER_PATH/.release_version" ]]; then
    CURRENT_VERSION=$(cat "$DOC_BUILDER_PATH/.release_version")
  fi

  if [[ "$CURRENT_VERSION" == "$LATEST_TAG" ]]; then
    echo "Already up to date (version: $LATEST_TAG)."
  else
    echo "Updating to $LATEST_TAG..."
    # Backup Assets directory (user may have added custom logos)
    if [[ -d "$DOC_BUILDER_PATH/Assets" ]]; then
      cp -r "$DOC_BUILDER_PATH/Assets" "$DOC_BUILDER_PATH/Assets.bak"
    fi

    # Download and extract new release
    if curl -sfL "$TARBALL_URL" | tar xz -C "$DOC_BUILDER_PATH" --strip-components=0; then
      echo "$LATEST_TAG" > "$DOC_BUILDER_PATH/.release_version"
      echo "Updated to $LATEST_TAG"

      # Restore custom assets
      if [[ -d "$DOC_BUILDER_PATH/Assets.bak" ]]; then
        cp -n "$DOC_BUILDER_PATH/Assets.bak/"* "$DOC_BUILDER_PATH/Assets/" 2>/dev/null || true
        rm -rf "$DOC_BUILDER_PATH/Assets.bak"
        echo "Custom assets preserved."
      fi
    else
      echo "ERROR: Update download failed"
      # Restore backup if it exists
      if [[ -d "$DOC_BUILDER_PATH/Assets.bak" ]]; then
        rm -rf "$DOC_BUILDER_PATH/Assets"
        mv "$DOC_BUILDER_PATH/Assets.bak" "$DOC_BUILDER_PATH/Assets"
      fi
      exit 1
    fi
  fi
fi

# Update dependencies
if [[ -f "$DOC_BUILDER_PATH/$VENV_PYTHON_REL" ]]; then
  echo ""
  echo "Updating dependencies..."
  "$DOC_BUILDER_PATH/$VENV_PYTHON_REL" -m pip install --upgrade pip -q
  if [[ -f "$DOC_BUILDER_PATH/requirements.txt" ]]; then
    "$DOC_BUILDER_PATH/$VENV_PYTHON_REL" -m pip install -r "$DOC_BUILDER_PATH/requirements.txt" --upgrade -q
  fi
  echo "Dependencies updated."
else
  echo "WARNING: Virtual environment not found. Run setup to recreate it."
fi

echo ""
echo "Update complete."
