#!/usr/bin/env bash
# Install the GerdsenAI Document Builder
# Args: <install_path>
# Supports: GitHub Release download (preferred) or git clone (fallback)
# Creates venv, installs dependencies, installs Playwright+Chromium

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

DEFAULT_INSTALL_PATH="$HOME/.gerdsenai/document-builder"
OLD_DEFAULT_PATH="$HOME/GerdsenAI_Document_Builder"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <install_path>"
  exit 1
fi

INSTALL_PATH="$1"

# Expand ~ if present
INSTALL_PATH="${INSTALL_PATH/#\~/$HOME}"

# Migration detection: if installing to the new default and an old install exists, inform the user
if [[ "$INSTALL_PATH" == "$DEFAULT_INSTALL_PATH" ]] && [[ -d "$OLD_DEFAULT_PATH" ]] && [[ -f "$OLD_DEFAULT_PATH/document_builder_reportlab.py" ]]; then
  echo "NOTE: Existing Document Builder found at $OLD_DEFAULT_PATH"
  echo "      Installing to the new default location: $INSTALL_PATH"
  echo "      Your old installation will not be modified. You can remove it later if no longer needed."
fi

GITHUB_REPO="GerdsenAI/GerdsenAI_Document_Builder"

# Check prerequisites
if $IS_WINDOWS; then
  REQUIRED_CMDS=(python pip)
else
  REQUIRED_CMDS=(python3 pip3)
fi
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is required but not found. Please install it first."
    exit 1
  fi
done

# Check Python version (need 3.9+)
PYTHON_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [[ "$PYTHON_MAJOR" -lt 3 ]] || [[ "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 9 ]]; then
  echo "ERROR: Python 3.9+ required, found $PYTHON_VERSION"
  exit 1
fi

# Download or clone the Document Builder
if [[ -d "$INSTALL_PATH" ]]; then
  if [[ -f "$INSTALL_PATH/document_builder_reportlab.py" ]]; then
    echo "Document Builder already exists at $INSTALL_PATH"
  else
    echo "ERROR: Directory exists but doesn't contain Document Builder: $INSTALL_PATH"
    exit 1
  fi
else
  # Try GitHub Release download first
  DOWNLOADED=false
  if command -v curl &>/dev/null; then
    echo "Checking for latest GitHub Release..."
    RELEASE_INFO=$(curl -sf "https://api.github.com/repos/${GITHUB_REPO}/releases/latest" 2>/dev/null || true)
    if [[ -n "$RELEASE_INFO" ]]; then
      TARBALL_URL=$(echo "$RELEASE_INFO" | $PYTHON_CMD -c "
import sys, json
data = json.load(sys.stdin)
assets = data.get('assets', [])
for a in assets:
    if a['name'].endswith('.tar.gz'):
        print(a['browser_download_url'])
        break
" 2>/dev/null || true)
      if [[ -n "$TARBALL_URL" ]]; then
        echo "Downloading release from $TARBALL_URL..."
        mkdir -p "$INSTALL_PATH"
        if curl -sfL "$TARBALL_URL" | tar xz -C "$INSTALL_PATH"; then
          DOWNLOADED=true
          echo "Downloaded release successfully."
        else
          echo "WARNING: Release download failed, falling back to git clone."
          rm -rf "$INSTALL_PATH"
        fi
      fi
    fi
  fi

  # Fallback: git clone
  if [[ "$DOWNLOADED" == "false" ]]; then
    if ! command -v git &>/dev/null; then
      echo "ERROR: git is required for clone fallback but not found."
      exit 1
    fi
    echo "Cloning GerdsenAI Document Builder..."
    if ! git clone "https://github.com/${GITHUB_REPO}.git" "$INSTALL_PATH"; then
      echo "ERROR: Failed to clone repository"
      rm -rf "$INSTALL_PATH"
      exit 1
    fi
  fi
fi

# Create venv if it doesn't exist
if [[ ! -d "$INSTALL_PATH/venv" ]]; then
  echo "Creating virtual environment..."
  $PYTHON_CMD -m venv "$INSTALL_PATH/venv"
fi

VENV_PYTHON="$INSTALL_PATH/$VENV_PYTHON_REL"

# Install dependencies
echo "Installing dependencies..."
"$VENV_PYTHON" -m pip install --upgrade pip -q
if [[ -f "$INSTALL_PATH/requirements.txt" ]]; then
  "$VENV_PYTHON" -m pip install -r "$INSTALL_PATH/requirements.txt" -q
else
  echo "WARNING: requirements.txt not found. Skipping dependency install."
fi

# Install Playwright and Chromium for Mermaid rendering
echo "Installing Playwright and Chromium for Mermaid diagram rendering..."
"$VENV_PYTHON" -m playwright install chromium 2>/dev/null || {
  echo "WARNING: Playwright Chromium install failed. Mermaid diagrams will fall back to code blocks."
}

# Create required directories
mkdir -p "$INSTALL_PATH/To_Build" "$INSTALL_PATH/PDFs" "$INSTALL_PATH/Logs" "$INSTALL_PATH/Assets"

# Sanity check
if [[ -f "$INSTALL_PATH/document_builder_reportlab.py" ]] && [[ -f "$VENV_PYTHON" ]]; then
  echo "SUCCESS: Document Builder installed at $INSTALL_PATH"
  echo "$INSTALL_PATH"
else
  echo "ERROR: Installation verification failed"
  exit 1
fi
