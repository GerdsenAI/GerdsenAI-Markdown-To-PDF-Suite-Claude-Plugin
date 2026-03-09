#!/usr/bin/env bash
# Update the GerdsenAI Document Builder to the latest version
# Supports: GitHub Release download (if installed from release) or git pull (if cloned)
# Args: <document_builder_path>

set -euo pipefail

# Load shared library
source "$(dirname "$0")/lib/parse-settings.sh"
detect_platform

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

  # Check for uncommitted changes that could cause conflicts
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo "WARNING: Uncommitted changes detected in $DOC_BUILDER_PATH"
    echo "         Stashing changes before pulling..."
    git stash
  fi

  BEFORE=$(git rev-parse HEAD)
  if ! git pull; then
    echo "ERROR: git pull failed. Check your internet connection or resolve any conflicts manually."
    exit 1
  fi

  # Check for merge conflicts after pull
  if ! git diff --quiet --diff-filter=U 2>/dev/null; then
    echo "ERROR: git pull resulted in merge conflicts. Manual resolution required at: $DOC_BUILDER_PATH"
    echo "       Run 'cd $DOC_BUILDER_PATH && git status' to see conflicting files."
    exit 1
  fi

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
    if curl -sfL "$TARBALL_URL" | tar xz -C "$DOC_BUILDER_PATH" --strip-components=1; then
      echo "$LATEST_TAG" > "$DOC_BUILDER_PATH/.release_version"
      echo "Updated to $LATEST_TAG"

      # Restore custom assets (only files not in the new release)
      if [[ -d "$DOC_BUILDER_PATH/Assets.bak" ]]; then
        restore_failed=false
        for f in "$DOC_BUILDER_PATH/Assets.bak/"*; do
          [[ -f "$f" ]] || continue
          dest="$DOC_BUILDER_PATH/Assets/$(basename "$f")"
          if [[ ! -f "$dest" ]]; then
            if ! cp "$f" "$dest"; then
              echo "WARNING: Failed to restore custom asset: $(basename "$f")"
              restore_failed=true
            fi
          fi
        done
        if $restore_failed; then
          echo "WARNING: Some custom assets could not be restored. Backup preserved at: $DOC_BUILDER_PATH/Assets.bak"
        else
          rm -rf "$DOC_BUILDER_PATH/Assets.bak"
          echo "Custom assets preserved."
        fi
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
  if ! "$DOC_BUILDER_PATH/$VENV_PYTHON_REL" -m pip install --upgrade pip -q; then
    echo "WARNING: pip upgrade failed. Continuing with existing pip version."
  fi
  if [[ -f "$DOC_BUILDER_PATH/requirements.txt" ]]; then
    if ! "$DOC_BUILDER_PATH/$VENV_PYTHON_REL" -m pip install -r "$DOC_BUILDER_PATH/requirements.txt" --upgrade -q; then
      echo "ERROR: Dependency update failed. Retrying with verbose output:"
      if ! "$DOC_BUILDER_PATH/$VENV_PYTHON_REL" -m pip install -r "$DOC_BUILDER_PATH/requirements.txt" --upgrade 2>&1 | tail -30; then
        echo "ERROR: Dependencies could not be updated. PDF builds may fail."
        echo "       Try running /gerdsenai:setup to recreate the virtual environment."
        exit 1
      fi
    fi
  fi
  echo "Dependencies updated."
else
  echo "WARNING: Virtual environment not found. Run /gerdsenai:setup to recreate it."
fi

echo ""
echo "Update complete."
