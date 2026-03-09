---
description: "Register a markdown report for source monitoring — extracts all cited URLs, computes content hashes, and creates a .sources.json manifest for freshness tracking"
allowed-tools: Read, Bash, Glob, AskUserQuestion
argument-hint: "<markdown-file-path>"
---

You are registering a markdown report for source monitoring as part of GerdsenAI's Living Intelligence Reports feature.

## Steps

1. **Resolve the target file**:
   - If an argument was provided (`$ARGUMENTS`), use it as the file path
   - If no argument, ask the user which report to monitor using AskUserQuestion
   - Resolve relative paths against the current working directory
   - Verify the file exists and is a markdown file

2. **Read settings**: Read `.claude/gerdsenai.local.md` to get the `document_builder_path`.

3. **Run the source tracker** using the venv Python (never system Python):
   - Read `document_builder_path` from `.claude/gerdsenai.local.md`
   - Determine the venv Python path: `<document_builder_path>/venv/Scripts/python.exe` on Windows, `<document_builder_path>/venv/bin/python` on macOS/Linux
   - Run:
   ```
   '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/source-tracker.py' extract '<markdown_file>'
   ```

4. **Report results**:
   - Show how many sources were found and how many URLs were successfully fetched
   - Show any URLs that failed to fetch (dead links, timeouts)
   - Tell the user where the `.sources.json` manifest was created
   - Explain next steps:
     - Run `/gerdsenai:check-freshness <file>` to check if sources have changed
     - Run `/gerdsenai:refresh <file>` to update the report when sources go stale
     - Stale sources will be flagged automatically at session start

5. **Handle errors**:
   - If no Sources & References section is found, explain that the report needs a properly formatted references section
   - If most URLs fail, warn that monitoring will be limited
