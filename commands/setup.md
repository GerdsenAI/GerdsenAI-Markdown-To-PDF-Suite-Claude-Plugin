---
description: "Install and configure the GerdsenAI Document Builder with guided preferences"
allowed-tools: Bash, Read, Write, AskUserQuestion, Glob
model: sonnet
---

You are setting up the GerdsenAI Document Builder for this project.

## Steps

1. Check if already installed by reading `.claude/gerdsenai.local.md`. If it exists, read it and check if the path is valid. If installed and working, ask the user if they want to reinstall or reconfigure.

2. Ask the user where to install the Document Builder. Suggest `~/GerdsenAI_Document_Builder` as the default. If the directory already exists and contains `document_builder_reportlab.py`, offer to use the existing installation instead of downloading/cloning.

3. Run the setup script (handles GitHub Release download with git clone fallback, venv creation, dependency install, Playwright install):
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh' '<install_path>'
   ```

4. **Ask output preferences** using AskUserQuestion:
   - **Output location**: Where should generated PDFs be saved?
     - "Same directory as source markdown" (output_mode: same_directory)
     - "A custom directory" (output_mode: custom) — then ask for the path
     - "Document Builder's PDFs/ folder" (output_mode: builder_pdfs)

5. **Ask logo preferences** using AskUserQuestion:
   - List available logos in `<install_path>/Assets/` using Glob
   - Ask user to pick a **cover page logo** (or "none")
   - Ask user to pick a **footer logo** (or "none")
   - If user wants to add a new logo, ask for the source path and copy it to Assets/

6. **Ask page size** using AskUserQuestion:
   - A4 (default, international standard)
   - Letter (US standard)
   - Legal
   - A3

7. Create or update the settings file at `.claude/gerdsenai.local.md`:
   ```yaml
   ---
   document_builder_path: "<install_path>"
   default_output_dir: "<user_chosen_dir_or_empty>"
   output_mode: "<same_directory|custom|builder_pdfs>"
   filename_pattern: "{prefix}{name}_{date}_{time}"
   filename_enumeration: false
   cover_logo: "<chosen_logo_or_empty>"
   footer_logo: "<chosen_logo_or_empty>"
   preferred_page_size: "<A4|Letter|Legal|A3>"
   ---
   # GerdsenAI Document Builder Settings
   Local configuration for the MD-to-PDF plugin.
   ```

8. If the user selected a page size different from config.yaml's default, update `<install_path>/config.yaml` to match.

9. Verify the installation by running:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/verify-install.sh'
   ```

10. Report success with a summary:
    - Install path
    - Output mode and directory
    - Selected logos
    - Page size
    - Next steps: Use `/gerdsenai:build-pdf <file>` to build a PDF
