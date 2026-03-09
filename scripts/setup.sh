#!/usr/bin/env bash
# Install the GerdsenAI Document Builder
# Args: <install_path>
# Supports: GitHub Release download (preferred) or git clone (fallback)
# Creates venv, installs dependencies, installs Playwright+Chromium

set -euo pipefail

# Load shared library
source "$(dirname "$0")/lib/parse-settings.sh"
detect_platform

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
if ! command -v "$PYTHON_CMD" &>/dev/null; then
  echo "ERROR: $PYTHON_CMD is required but not found. Please install Python 3.9+."
  exit 1
fi

# Check Python version (need 3.9+)
PYTHON_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [[ "$PYTHON_MAJOR" -lt 3 ]] || [[ "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 9 ]]; then
  echo "ERROR: Python 3.9+ required, found $PYTHON_VERSION"
  exit 1
fi

# Check pip availability (via module, not standalone command)
if ! "$PYTHON_CMD" -m pip --version &>/dev/null; then
  echo "ERROR: pip is required but not available. Install it with: $PYTHON_CMD -m ensurepip"
  exit 1
fi

# Download or clone the Document Builder
if [[ -d "$INSTALL_PATH" ]]; then
  if [[ -f "$INSTALL_PATH/document_builder_reportlab.py" ]]; then
    echo "Document Builder already exists at $INSTALL_PATH"
  else
    echo "ERROR: Directory exists but doesn't contain Document Builder: $INSTALL_PATH"
    echo "       If this is a failed previous install, delete it and retry:"
    echo "       rm -rf '$INSTALL_PATH'"
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
        if curl -sfL "$TARBALL_URL" | tar xz -C "$INSTALL_PATH" --strip-components=1; then
          # Verify the extracted content is actually the Document Builder
          if [[ ! -f "$INSTALL_PATH/document_builder_reportlab.py" ]]; then
            echo "WARNING: Downloaded archive does not contain the Document Builder (main script missing). Falling back to git clone."
            rm -rf "$INSTALL_PATH"
          else
            DOWNLOADED=true
            echo "Downloaded release successfully."
          fi
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

# Detect and recreate broken venv (directory exists but python binary is missing)
if [[ -d "$INSTALL_PATH/venv" ]] && [[ ! -f "$INSTALL_PATH/$VENV_PYTHON_REL" ]]; then
  echo "WARNING: Virtual environment is broken (python binary missing). Recreating..."
  rm -rf "$INSTALL_PATH/venv"
fi

# Create venv if it doesn't exist
if [[ ! -d "$INSTALL_PATH/venv" ]]; then
  echo "Creating virtual environment..."
  VENV_ERR=""
  if ! VENV_ERR=$($PYTHON_CMD -m venv "$INSTALL_PATH/venv" 2>&1); then
    echo "Standard venv creation failed: $VENV_ERR"
    echo "Trying fallback (venv without pip)..."
    rm -rf "$INSTALL_PATH/venv"
    if ! VENV_ERR=$($PYTHON_CMD -m venv --without-pip "$INSTALL_PATH/venv" 2>&1); then
      echo "ERROR: Failed to create virtual environment: $VENV_ERR. Ensure the 'venv' module is available."
      exit 1
    fi
    # Bootstrap pip into the venv
    echo "Bootstrapping pip..."
    if command -v curl &>/dev/null; then
      if ! curl -sfL https://bootstrap.pypa.io/get-pip.py -o "$INSTALL_PATH/venv/get-pip.py"; then
        echo "ERROR: Failed to download get-pip.py. Check your internet connection."
        exit 1
      fi
      if ! "$INSTALL_PATH/$VENV_PYTHON_REL" "$INSTALL_PATH/venv/get-pip.py" -q; then
        echo "ERROR: Failed to bootstrap pip into the virtual environment."
        exit 1
      fi
      rm -f "$INSTALL_PATH/venv/get-pip.py"
    else
      echo "ERROR: curl is not available. Cannot bootstrap pip into the virtual environment."
      echo "       Install curl or use a Python installation that includes ensurepip."
      exit 1
    fi
  fi
fi

VENV_PYTHON="$INSTALL_PATH/$VENV_PYTHON_REL"

# Validate the venv python is functional
echo "Validating virtual environment..."
VENV_CHECK_ERR=""
if ! VENV_CHECK_ERR=$("$VENV_PYTHON" -c "import sys; assert sys.prefix != sys.base_prefix" 2>&1); then
  echo "ERROR: Virtual environment was created but Python is not functional or not isolated: $VENV_CHECK_ERR"
  exit 1
fi

# Install/upgrade pip
echo "Upgrading pip..."
if ! "$VENV_PYTHON" -m pip install --upgrade pip -q; then
  echo "WARNING: pip upgrade failed. Continuing with existing pip version."
fi

# Install dependencies
if [[ -f "$INSTALL_PATH/requirements.txt" ]]; then
  echo "Installing dependencies..."
  if ! "$VENV_PYTHON" -m pip install -r "$INSTALL_PATH/requirements.txt" -q; then
    echo "ERROR: Failed to install dependencies. Retrying with verbose output:"
    if ! "$VENV_PYTHON" -m pip install -r "$INSTALL_PATH/requirements.txt" 2>&1 | tail -50; then
      exit 1
    fi
  fi
else
  echo "WARNING: requirements.txt not found. Skipping dependency install."
fi

# Install Playwright and Chromium for Mermaid rendering
echo "Installing Playwright and Chromium for Mermaid diagram rendering..."
if ! "$VENV_PYTHON" -m playwright install chromium; then
  echo "WARNING: Playwright Chromium install failed. Mermaid diagrams will fall back to code blocks."
  echo "         To install manually: $VENV_PYTHON -m playwright install chromium"
fi

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
