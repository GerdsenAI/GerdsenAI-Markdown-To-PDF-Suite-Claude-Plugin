---
description: "Install and configure the GerdsenAI Document Builder"
allowed-tools: Bash, Read, Write, AskUserQuestion
model: sonnet
---

You are setting up the GerdsenAI Document Builder for this project.

## Steps

1. Check if already installed by reading `.claude/gerdsenai-md-to-pdf-suite.local.md`. If it exists, read it and check if the path is valid. If installed and working, ask the user if they want to reinstall or reconfigure.

2. Ask the user where to install the Document Builder. Suggest `~/GerdsenAI_Document_Builder` as the default. If the directory already exists and contains `document_builder_reportlab.py`, offer to use the existing installation instead of cloning.

3. Run the setup script:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh' '<install_path>'
   ```

4. Create or update the settings file at `.claude/gerdsenai-md-to-pdf-suite.local.md`:
   ```yaml
   ---
   document_builder_path: "<install_path>"
   default_output_dir: ""
   auto_open_pdf: false
   preferred_page_size: "A4"
   ---
   # GerdsenAI Document Builder Settings
   Local configuration for the MD-to-PDF plugin.
   ```

5. Verify the installation by checking that the key files exist:
   - `<install_path>/document_builder_reportlab.py`
   - `<install_path>/venv/bin/python`
   - `<install_path>/config.yaml`

6. Report success with a summary:
   - Install path
   - Python version in venv
   - Whether Playwright/Chromium installed successfully
   - Next steps: "Place markdown files in `<path>/To_Build/` or use `/gerdsenai-md-to-pdf-suite:build-pdf <file>` to build a PDF"
