---
description: "Build markdown files into professional PDFs — single file or entire directory"
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion
argument-hint: "<file-or-directory> [--recursive] [--output-dir <dir>] [--output-name <name>]"
---

You are building markdown files into PDFs using the GerdsenAI Document Builder.

## Steps

1. **First-run check**: Read `.claude/gerdsenai.local.md` to get settings. If the file doesn't exist or `document_builder_path` is missing/invalid:
   - Don't just tell the user to run setup — offer to run it inline
   - Say: "The Document Builder isn't configured yet. Want me to set it up now?"
   - If yes, follow the setup workflow, then continue with the build

2. **Resolve the target**:
   - If an argument was provided (`$ARGUMENTS`), parse the target path (first argument before any `--` flags)
   - Also parse optional `--recursive`, `--output-dir`, and `--output-name` from arguments
   - Resolve relative paths against the current working directory
   - Determine if the target is a **file** or **directory**:
     - If it ends in `.md` or is an existing file → **single file mode**
     - If it is an existing directory or `--recursive` is passed → **recursive mode**
     - If no target provided, ask the user using AskUserQuestion:
       - "Build a single markdown file" (then ask for path)
       - "Build all markdown files in a directory"

---

## Single File Mode

3. Verify the file exists and has a `.md` extension.

4. **Validate the markdown file**:
   - Read the file and check if it has YAML front matter (starts with `---`)
   - If no front matter, warn the user that the PDF will use default metadata (title from first H1, default author from config.yaml)

5. **Check output preferences**: Read settings for `output_mode`:
   - If `output_mode` is not set and no `--output-dir` flag provided, ask the user using AskUserQuestion:
     - "Same directory as the source file" (recommended for single builds)
     - "Document Builder's PDFs/ folder"
     - "Custom directory" (then ask for path)
   - If `output_mode` is already set, use that unless overridden by `--output-dir`

6. Run the build script:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/build.sh' '.claude/gerdsenai.local.md' '<markdown_file_path>' [--output-dir '<dir>'] [--output-name '<name>']
   ```

7. **Report the result**:
   - If successful: show the path to the generated PDF, file size
   - If the PDF was copied to an output directory, show that location
   - If failed: show the error and suggest fixes (common issues: missing front matter closing `---`, invalid Mermaid syntax, missing images)

---

## Recursive Mode

Use `model: sonnet` for cost efficiency when building multiple files.

3. **Determine scan directory**:
   - Use the provided directory path, or current working directory if none given

4. **Scan for markdown files**: Use Glob to find all `.md` files recursively. Exclude:
   - `node_modules/`, `.git/`, `venv/`, `__pycache__/`, `.claude/`
   - Common non-document files: `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `LICENSE.md`, `todo.md`

5. **Present file list**: Show the user all found `.md` files with their relative paths. Include the count. Ask for confirmation using AskUserQuestion:
   - "Build all N files" (default)
   - "Let me pick which files to build"
   - "Cancel"
   If they want to pick, present the files as a selectable list.

6. **Ask output mode** using AskUserQuestion:
   - "Place each PDF alongside its source .md file" (recommended)
   - "Put all PDFs in one output directory" (then ask for path)
   - "Use settings default" (if output_mode is already configured)

7. **Build each file**: Run the build script for each file:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/build.sh' '.claude/gerdsenai.local.md' '<markdown_file>' --output-dir '<dir>'
   ```

8. **Report results**: Show a summary table:
   - Source file path -> PDF output path -> Status (success/failed)
   - Total: "Built X of Y files successfully"
   - List any failures with error messages
