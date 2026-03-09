---
description: "Check if any sources cited in a monitored report have changed since last check — reports stale sources and affected sections"
allowed-tools: Read, Bash, Glob, AskUserQuestion
argument-hint: "[markdown-file-path]"
---

You are checking source freshness for a monitored GerdsenAI report.

## Steps

1. **Resolve the target**:
   - If an argument was provided (`$ARGUMENTS`), use it as the file path
   - If no argument, look for `.sources.json` files in the current directory:
     ```
     find . -name "*.sources.json" -maxdepth 3
     ```
   - If multiple manifests found, ask the user which report to check using AskUserQuestion
   - If no manifests found, tell the user to run `/gerdsenai:monitor <file>` first

2. **Run the freshness check** using the venv Python (never system Python):
   - Read `document_builder_path` from `.claude/gerdsenai.local.md`
   - Determine the venv Python path: `<document_builder_path>/venv/Scripts/python.exe` on Windows, `<document_builder_path>/venv/bin/python` on macOS/Linux
   - Run:
   ```
   '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/source-tracker.py' check '<markdown_file>'
   ```

3. **Present results clearly**:
   - **If no sources changed**: "All N sources are current as of [date]."
   - **If sources changed**: Show a summary:
     - "N of M sources have changed since [last_checked_date]"
     - List each changed source with its citation number, title, and URL
     - List which report sections are affected
   - **If sources failed**: Note any URLs that could not be fetched (may be temporarily down or permanently dead)

4. **Offer next steps** using AskUserQuestion:
   - "Refresh the report" — run `/gerdsenai:refresh <file>` to update affected sections
   - "Show me the changed sources" — fetch and display the changed source content
   - "Ignore for now" — end the check

5. **Handle edge cases**:
   - If the manifest doesn't exist, tell the user to run `/gerdsenai:monitor` first
   - If the markdown file has been deleted but the manifest exists, warn the user
