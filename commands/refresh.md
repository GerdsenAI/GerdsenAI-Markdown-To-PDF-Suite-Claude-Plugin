---
description: "Refresh a monitored report by re-researching sections affected by stale sources, then rebuild the PDF with a revision history"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, WebSearch, WebFetch, AskUserQuestion
argument-hint: "<markdown-file-path>"
---

You are refreshing a GerdsenAI Living Intelligence Report — updating sections affected by changed sources.

## Steps

1. **Resolve the target file**:
   - If an argument was provided (`$ARGUMENTS`), use it as the file path
   - If no argument, ask the user which report to refresh using AskUserQuestion
   - Verify both the markdown file and its `.sources.json` manifest exist

2. **Check freshness first**:
   Run a freshness check to identify what changed:
   ```
   python '${CLAUDE_PLUGIN_ROOT}/scripts/source-tracker.py' check '<markdown_file>'
   ```
   - If no sources have changed, tell the user the report is current — no refresh needed
   - Parse the JSON output to identify changed sources and affected sections

3. **Read the report**: Read the full markdown file to understand context.

4. **Re-research affected sections only**:
   - For each section affected by changed sources:
     - Use WebSearch to find updated information on the topic
     - Use WebFetch to read the changed source URLs for new content
     - Compare old claims against new data
   - Do NOT re-research sections that are unaffected — preserve them exactly

5. **Apply updates to the markdown**:
   - Use the Edit tool to update affected sections with new data
   - Update any statistics, dates, or claims that have changed
   - Add or update citations as needed
   - Maintain the existing document structure and style
   - Add a `## Revision History` section at the end (before Sources & References) if one doesn't exist, or append to it:
     ```markdown
     ## Revision History

     | Date | Sections Updated | Changes |
     |------|-----------------|---------|
     | YYYY-MM-DD | Section Name, Section Name | Brief description of what changed |
     ```

6. **Update the manifest**:
   ```
   python '${CLAUDE_PLUGIN_ROOT}/scripts/source-tracker.py' update '<markdown_file>'
   ```

7. **Rebuild the PDF**:
   Ask the user if they want to rebuild:
   - If yes, build using the standard build command:
     ```
     bash '${CLAUDE_PLUGIN_ROOT}/scripts/build.sh' '.claude/gerdsenai.local.md' '<markdown_file>'
     ```
   - Report the new PDF path

8. **Summary**: Tell the user:
   - How many sections were updated
   - What key changes were found
   - Where the updated PDF was saved (if rebuilt)
