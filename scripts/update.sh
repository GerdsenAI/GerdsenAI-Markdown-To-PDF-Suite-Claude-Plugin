#!/usr/bin/env bash
# Update the GerdsenAI Document Builder to the latest version
# Args: <document_builder_path>

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <document_builder_path>"
  exit 1
fi

DOC_BUILDER_PATH="$1"

if [[ ! -d "$DOC_BUILDER_PATH" ]]; then
  echo "ERROR: Document Builder not found at $DOC_BUILDER_PATH"
  exit 1
fi

if [[ ! -d "$DOC_BUILDER_PATH/.git" ]]; then
  echo "ERROR: Not a git repository: $DOC_BUILDER_PATH"
  exit 1
fi

# Pull latest changes
echo "Pulling latest changes..."
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

# Update dependencies
if [[ -f "$DOC_BUILDER_PATH/venv/bin/python" ]]; then
  echo ""
  echo "Updating dependencies..."
  "$DOC_BUILDER_PATH/venv/bin/python" -m pip install --upgrade pip -q
  "$DOC_BUILDER_PATH/venv/bin/python" -m pip install -r "$DOC_BUILDER_PATH/requirements.txt" --upgrade -q
  echo "Dependencies updated."
else
  echo "WARNING: Virtual environment not found. Run setup to recreate it."
fi

echo ""
echo "Update complete."
