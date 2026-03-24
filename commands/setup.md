---
description: "Install, configure, or update the GerdsenAI Document Builder"
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, Glob
---

You are managing the GerdsenAI Document Builder installation and configuration.

## Steps

1. **Detect state**: Read `.claude/gerdsenai.local.md` to check if the Document Builder is already configured.

---

### If NOT configured (first-time setup)

Follow the full setup wizard:

2. Ask the user where to install the Document Builder. Suggest `~/.gerdsenai/document-builder` as the default (hidden directory, keeps home folder clean). If the directory already exists and contains `document_builder_reportlab.py`, offer to use the existing installation instead of downloading/cloning.

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

7. Create the settings file at `.claude/gerdsenai.local.md`. **IMPORTANT on Windows**: Use Python to write this file with LF line endings (`newline='\n'`), not the Write tool, because CRLF breaks the bash YAML parser:
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
   vector_db_mode: "chromadb"
   vector_db_primary: "chromadb"
   vector_db_chromadb_enabled: "true"
   vector_db_chromadb_embedding_model: "all-MiniLM-L6-v2"
   vector_db_chromadb_chunk_size: "500"
   vector_db_chromadb_chunk_overlap: "100"
   vector_db_chromadb_max_distance: "1.0"
   vector_db_chromadb_default_results: "5"
   vector_db_hook_on_commit: "true"
   vector_db_hook_on_session_end: "true"
   vector_db_hook_on_file_change: "false"
   ---
   # GerdsenAI Document Builder Settings
   Local configuration for the MD-to-PDF plugin.
   ```

   ChromaDB is installed automatically during setup. The vector DB defaults above enable local research memory out of the box. Use `/gerdsenai:vector-db configure` to customize backends, embedding models, or disable.

8. If the user selected a page size different from config.yaml's default, update `<install_path>/config.yaml` to match.

9. **Optional: Local AI detection (Ollama)** — detect automatically, never install:
    - Check if `ollama` is in PATH: `which ollama 2>/dev/null`
    - If found, run `ollama list` to check for available models
    - If not found, inform: "Ollama not detected. For local AI capabilities (optional), visit ollama.com."

10. Verify the installation:
    ```
    bash '${CLAUDE_PLUGIN_ROOT}/scripts/verify-install.sh'
    ```

11. Report success with a summary and next steps: "Use `/gerdsenai:build <file>` to build a PDF."

---

### If ALREADY configured

The Document Builder is installed. Present a menu using AskUserQuestion:

- **Configure settings** — Change logos, output mode, page size, margins, typography, colors, research citation style
- **Update builder** — Update the Document Builder to the latest version
- **Reinstall** — Re-run the full setup wizard (with current values as defaults)
- **Check health** — Verify the installation is working correctly

#### Configure settings

2. Verify `<document_builder_path>` exists and contains `document_builder_reportlab.py`. If unreachable, offer to reinstall.

3. Read the current `config.yaml` from `<document_builder_path>/config.yaml`. If it doesn't exist, offer to create one.

4. Present the current configuration in a readable summary, organized by section:
   - **Default metadata**: author, company, version, confidential, watermark, filename_prefix
   - **Logos**: cover logo, footer logo (list available images in `<document_builder_path>/Assets/`)
   - **Page**: size (A4/Letter/Legal/A3), orientation
   - **Margins**: top, right, bottom, left (in mm)
   - **Header/Footer**: height, show_title, show_page_numbers, show_logo, show_date
   - **Typography**: font families, sizes, line height
   - **Colors**: primary, secondary, accent, code_background, link, table colors
   - **Syntax highlighting**: enabled, theme (github/monokai/dracula/tomorrow), line numbers
   - **Code blocks**: diff, treeview, shell, generic color schemes
   - **Mermaid**: enabled, theme, viewport, max width, error handling
   - **Export**: optimize_size, PDF variant, compress images, embed fonts
   - **Research**: citation style (from `.claude/gerdsenai.local.md`, default: APA)

5. Ask the user what they want to change. Use AskUserQuestion for common choices.

6. **Logo browser**: When changing logos:
   - List all image files in `<document_builder_path>/Assets/` using Glob (`*.png`, `*.jpg`, `*.jpeg`, `*.svg`)
   - Show current selections, let user pick or add new logos
   - Copy new logo files to `<document_builder_path>/Assets/`

7. Apply config.yaml changes using the Edit tool. Apply settings changes by updating `.claude/gerdsenai.local.md`.

8. After making changes, offer to do a test build to verify the configuration works.

#### Update builder

2. Run the update script:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/update.sh' '<document_builder_path>'
   ```

3. Report the results:
   - If already up to date, say so
   - If updated, show the commit range and summary of changes
   - Report whether dependencies were updated
   - Flag any potential breaking changes if the update touched `config.yaml` or `document_builder_reportlab.py`

#### Reinstall

2. Re-run the full setup wizard above (steps 2-11), using current settings as defaults.

#### Check health

2. Run the verification script:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/verify-install.sh'
   ```
3. Report the health status: installation path, venv status, config.yaml presence, available logos, output mode.
