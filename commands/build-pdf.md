---
description: "Build a markdown file into a professional PDF"
allowed-tools: Bash, Read, Write, Glob, AskUserQuestion
argument-hint: "<markdown-file-path> [--output-dir <dir>] [--output-name <name>]"
---

You are building a single markdown file into a PDF using the GerdsenAI Document Builder.

## Steps

1. **First-run check**: Read `.claude/gerdsenai.local.md` to get settings. If the file doesn't exist or `document_builder_path` is missing/invalid:
   - Don't just tell the user to run setup — offer to run it inline
   - Say: "The Document Builder isn't configured yet. Want me to set it up now?"
   - If yes, follow the setup.md workflow, then continue with the build

2. Resolve the markdown file to build:
   - If an argument was provided (`$ARGUMENTS`), parse the file path (first argument before any `--` flags)
   - Also parse optional `--output-dir` and `--output-name` from arguments
   - Resolve relative paths against the current working directory
   - Verify the file exists and has a `.md` extension

3. Validate the markdown file:
   - Read the file and check if it has YAML front matter (starts with `---`)
   - If no front matter, warn the user that the PDF will use default metadata (title from first H1, default author from config.yaml)

4. **Check output preferences**: Read settings for `output_mode`:
   - If `output_mode` is not set and no `--output-dir` flag provided, ask the user using AskUserQuestion:
     - "Same directory as the source file" (recommended for single builds)
     - "Document Builder's PDFs/ folder"
     - "Custom directory" (then ask for path)
   - If `output_mode` is already set, use that unless overridden by `--output-dir`

5. **Optional: Logo override**: If the user wants different logos for this build, they can specify. Otherwise use defaults from settings/config.yaml.

6. Run the build script with appropriate arguments:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/build.sh' '.claude/gerdsenai.local.md' '<markdown_file_path>' [--output-dir '<dir>'] [--output-name '<name>']
   ```

7. Report the result:
   - If successful: show the path to the generated PDF, file size
   - If the PDF was copied to an output directory, show that location
   - If failed: show the error and suggest fixes (common issues: missing front matter closing `---`, invalid Mermaid syntax, missing images)
