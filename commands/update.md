---
description: "Update the GerdsenAI Document Builder to the latest version"
allowed-tools: Bash, Read
---

You are updating the GerdsenAI Document Builder to the latest version.

## Steps

1. Read `.claude/gerdsenai.local.md` to get `document_builder_path`. If not configured, tell the user to run `/gerdsenai:setup` first.

2. Run the update script:
   ```
   bash '${CLAUDE_PLUGIN_ROOT}/scripts/update.sh' '<document_builder_path>'
   ```

3. Report the results:
   - If already up to date, say so
   - If updated, show the commit range and summary of changes
   - Report whether dependencies were updated
   - Flag any potential breaking changes if the update touched `config.yaml` or `document_builder_reportlab.py` significantly
