#!/usr/bin/env bash
# Install the GerdsenAI Document Builder
# Args: <install_path>
# Clones the repo, creates venv, installs dependencies, installs Playwright+Chromium

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <install_path>"
  exit 1
fi

INSTALL_PATH="$1"

# Expand ~ if present
INSTALL_PATH="${INSTALL_PATH/#\~/$HOME}"

# Check prerequisites
for cmd in python3 git pip3; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is required but not found. Please install it first."
    exit 1
  fi
done

# Check Python version (need 3.9+)
PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)
if [[ "$PYTHON_MAJOR" -lt 3 ]] || [[ "$PYTHON_MAJOR" -eq 3 && "$PYTHON_MINOR" -lt 9 ]]; then
  echo "ERROR: Python 3.9+ required, found $PYTHON_VERSION"
  exit 1
fi

# Clone if not already present
if [[ -d "$INSTALL_PATH" ]]; then
  if [[ -f "$INSTALL_PATH/document_builder_reportlab.py" ]]; then
    echo "Document Builder already exists at $INSTALL_PATH"
  else
    echo "ERROR: Directory exists but doesn't contain Document Builder: $INSTALL_PATH"
    exit 1
  fi
else
  echo "Cloning GerdsenAI Document Builder..."
  if ! git clone https://github.com/GerdsenAI/GerdsenAI_Document_Builder.git "$INSTALL_PATH"; then
    echo "ERROR: Failed to clone repository"
    # Clean up partial clone
    rm -rf "$INSTALL_PATH"
    exit 1
  fi
fi

# Create venv if it doesn't exist
if [[ ! -d "$INSTALL_PATH/venv" ]]; then
  echo "Creating virtual environment..."
  python3 -m venv "$INSTALL_PATH/venv"
fi

# Install dependencies
echo "Installing dependencies..."
"$INSTALL_PATH/venv/bin/python" -m pip install --upgrade pip -q
"$INSTALL_PATH/venv/bin/python" -m pip install -r "$INSTALL_PATH/requirements.txt" -q

# Install Playwright and Chromium for Mermaid rendering
echo "Installing Playwright and Chromium for Mermaid diagram rendering..."
"$INSTALL_PATH/venv/bin/python" -m playwright install chromium 2>/dev/null || {
  echo "WARNING: Playwright Chromium install failed. Mermaid diagrams will fall back to code blocks."
}

# Create required directories
mkdir -p "$INSTALL_PATH/To_Build" "$INSTALL_PATH/PDFs" "$INSTALL_PATH/Logs" "$INSTALL_PATH/Assets"

echo "SUCCESS: Document Builder installed at $INSTALL_PATH"
echo "$INSTALL_PATH"
