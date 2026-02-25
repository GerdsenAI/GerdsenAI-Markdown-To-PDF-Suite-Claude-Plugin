---
description: "Build all markdown files in the To_Build directory into PDFs"
allowed-tools: Bash, Read, Glob, AskUserQuestion
---

You are building all markdown files in the Document Builder's `To_Build/` directory into PDFs.

## Steps

1. **First-run check**: Read `.claude/gerdsenai-md-to-pdf-suite.local.md` to get `document_builder_path`. If not configured or path invalid:
   - Offer to run setup inline: "The Document Builder isn't configured yet. Want me to set it up now?"
   - If yes, follow the setup workflow, then continue

2. List the markdown files in `<document_builder_path>/To_Build/` using Glob. If the directory is empty, tell the user:
   - "No markdown files found in `To_Build/`"
   - Suggest using `/gerdsenai-md-to-pdf-suite:build-pdf <file>` to build a specific file, which copies it to `To_Build/` automatically
   - Or use `/gerdsenai-md-to-pdf-suite:build-recursive` to build all .md files in the current project

3. Show the user which files will be built and how many.

4. Run the build script:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/build.sh' '.claude/gerdsenai-md-to-pdf-suite.local.md' '--all'
   ```

5. Report results:
   - List each generated PDF with its path in the `PDFs/` directory
   - Report any files that failed to build
   - Show total: "Built X of Y files successfully"
