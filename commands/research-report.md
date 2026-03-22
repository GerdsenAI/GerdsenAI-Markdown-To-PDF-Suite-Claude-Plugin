---
description: "Conduct deep research and generate professional intelligence reports, dossiers, and white papers as PDFs — includes source monitoring, freshness checking, and report refresh"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Task, WebSearch, WebFetch, ToolSearch
argument-hint: "[research topic or question | markdown-file-path]"
---

## Auto-detect intent from arguments

Examine `$ARGUMENTS` to determine which mode to run:

### Mode A: New Research (argument is a topic/question, not a file path)

If the argument is NOT a path to an existing `.md` file, this is a new research request.

Read the full agent protocol at `${CLAUDE_PLUGIN_ROOT}/agents/research-report.md` and follow it completely.

The user's topic is: `$ARGUMENTS`

Begin at Phase 0 (Tool & Capability Discovery). Do not skip any phase. Execute every phase in order through Phase 8 (PDF Build & Delivery).

After Phase 8, offer to register the report for source monitoring:
- Ask using AskUserQuestion: "Register this report for source monitoring? This tracks cited URLs so you can detect when sources change."
- If yes, read `document_builder_path` from `.claude/gerdsenai.local.md` and determine the venv Python path:
  - Windows: `<document_builder_path>/venv/Scripts/python.exe`
  - macOS/Linux: `<document_builder_path>/venv/bin/python`
- Run the source tracker:
  ```
  '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/source-tracker.py' extract '<markdown_file>'
  ```
- Report how many sources were registered and explain: "Run `/gerdsenai:research-report <file>` again to check freshness."

---

### Mode B: Source Monitoring (argument is a path to an existing `.md` file)

If the argument IS a path to an existing `.md` file, check for a `.sources.json` manifest alongside it.

Read `document_builder_path` from `.claude/gerdsenai.local.md`. Determine the venv Python path:
- Windows: `<document_builder_path>/venv/Scripts/python.exe`
- macOS/Linux: `<document_builder_path>/venv/bin/python`

#### B1: File HAS a .sources.json manifest → Freshness check

1. Run the freshness check:
   ```
   '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/source-tracker.py' check '<markdown_file>'
   ```

2. Present results:
   - **No sources changed**: "All N sources are current as of [date]."
   - **Sources changed**: Show summary — count, list of changed sources with citation numbers, affected sections
   - **Sources failed**: Note URLs that could not be fetched

3. If sources changed, offer next steps using AskUserQuestion:
   - "Refresh the report" → proceed to refresh flow below
   - "Show me the changed sources" → fetch and display changed content
   - "Ignore for now"

**Refresh flow** (when user chooses to refresh, or if called with a stale report):

4. Read the full markdown file to understand context.

5. Re-research affected sections only:
   - Use WebSearch for updated information on each affected topic
   - Use WebFetch to read changed source URLs for new content
   - Compare old claims against new data
   - Do NOT re-research unaffected sections — preserve them exactly

6. Apply updates using the Edit tool:
   - Update affected sections with new data
   - Update statistics, dates, or claims that have changed
   - Add or update citations as needed
   - Maintain existing document structure and style
   - Add or append to a `## Revision History` section:
     ```markdown
     ## Revision History

     | Date | Sections Updated | Changes |
     |------|-----------------|---------|
     | YYYY-MM-DD | Section Name | Brief description of what changed |
     ```

7. Update the manifest:
   ```
   '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/source-tracker.py' update '<markdown_file>'
   ```

8. Ask if the user wants to rebuild the PDF:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/build.sh' '.claude/gerdsenai.local.md' '<markdown_file>'
   ```

9. Summary: sections updated, key changes found, PDF path if rebuilt.

#### B2: File has NO .sources.json manifest → Offer to monitor

1. Ask using AskUserQuestion:
   - "Register this report for source monitoring" (recommended)
   - "Open for editing instead"
   - "Cancel"

2. If monitoring, run the source tracker:
   ```
   '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/source-tracker.py' extract '<markdown_file>'
   ```

3. Report results: sources found, URLs fetched, manifest location. Explain: "Run this command again with the file path to check freshness."

---

### Mode C: No arguments

If no arguments provided, ask the user using AskUserQuestion:
- "Start a new research report" → ask for topic, proceed to Mode A
- "Check/refresh an existing report" → ask for file path, proceed to Mode B
