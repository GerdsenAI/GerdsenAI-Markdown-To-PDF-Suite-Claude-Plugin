---
description: "Build PDFs for all markdown files in a directory and its subdirectories"
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion
argument-hint: "[directory-path]"
model: sonnet
---

You are building PDFs for all markdown files found recursively in a directory tree.

## Steps

1. **First-run check**: Read `.claude/gerdsenai.local.md` to get settings. If the file doesn't exist or `document_builder_path` is missing/invalid:
   - Offer to run setup inline: "The Document Builder isn't configured yet. Want me to set it up now?"
   - If yes, follow the setup workflow, then continue

2. **Determine scan directory**:
   - If an argument was provided (`$ARGUMENTS`), use that as the directory path
   - If no argument, use the current working directory
   - Resolve relative paths to absolute

3. **Scan for markdown files**: Use Glob to find all `.md` files recursively. Exclude:
   - `node_modules/`
   - `.git/`
   - `venv/`
   - `__pycache__/`
   - `.claude/`
   - Common non-document files: `README.md`, `CLAUDE.md`, `CHANGELOG.md`, `LICENSE.md`, `todo.md`

4. **Present file list**: Show the user all found `.md` files with their relative paths. Include the count. Ask for confirmation using AskUserQuestion:
   - "Build all N files" (default)
   - "Let me pick which files to build"
   - "Cancel"
   If they want to pick, present the files as a selectable list.

5. **Ask output mode** using AskUserQuestion:
   - "Place each PDF alongside its source .md file" (recommended)
   - "Put all PDFs in one output directory" (then ask for path)
   - "Use settings default" (if output_mode is already configured)

6. **Build each file**: Run the build script for each file:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/build.sh' '.claude/gerdsenai.local.md' '<markdown_file>' --output-dir '<dir>'
   ```

7. **Report results**: Show a summary table:
   - Source file path -> PDF output path -> Status (success/failed)
   - Total: "Built X of Y files successfully"
   - List any failures with error messages
