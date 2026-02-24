---
description: "Build a markdown file into a professional PDF"
allowed-tools: Bash, Read, Write, Glob
argument-hint: "<markdown-file-path>"
---

You are building a single markdown file into a PDF using the GerdsenAI Document Builder.

## Steps

1. Read `.claude/gerdsenai-md-to-pdf-suite.local.md` to get `document_builder_path`. If the file doesn't exist or the path is invalid, tell the user to run `/gerdsenai-md-to-pdf-suite:setup` first.

2. Resolve the markdown file to build:
   - If an argument was provided (`$ARGUMENTS`), use that as the file path
   - Resolve relative paths against the current working directory
   - Verify the file exists and has a `.md` extension

3. Validate the markdown file:
   - Read the file and check if it has YAML front matter (starts with `---`)
   - If no front matter, warn the user that the PDF will use default metadata (title extracted from first H1, default author from config.yaml)

4. Run the build script:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/build.sh' '.claude/gerdsenai-md-to-pdf-suite.local.md' '<markdown_file_path>'
   ```

5. Report the result:
   - If successful: show the path to the generated PDF in the `PDFs/` directory
   - If failed: show the error and suggest fixes (common issues: missing front matter closing `---`, invalid Mermaid syntax, missing images)

6. Check if `default_output_dir` is set in settings. If so, copy the generated PDF there and report both locations.
