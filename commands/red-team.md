---
description: "Run adversarial red team review on a markdown document to challenge claims, verify citations, and identify logical weaknesses"
allowed-tools: Read, Grep, Glob, Bash, WebSearch, WebFetch, AskUserQuestion
argument-hint: "<markdown-file-path>"
---

You are running an adversarial red team review on a markdown document.

## Steps

1. **Resolve the target file**:
   - If an argument was provided (`$ARGUMENTS`), use it as the file path
   - If no argument, ask the user which file to review using AskUserQuestion
   - Resolve relative paths against the current working directory
   - Verify the file exists and read it

2. **Read the red team reference**: Read `${CLAUDE_PLUGIN_ROOT}/skills/pdf-document-authoring/references/red-team-reference.md` for the full challenge protocol, severity levels, and output format.

3. **Conduct the review** following the protocol in the reference document:
   - Catalogue all factual claims section by section
   - Verify high-stakes claims against external sources (use WebSearch)
   - Evaluate source quality using the 1-5 rubric
   - Check citation completeness (in-text markers vs. References section)
   - Assess logical structure for fallacies and contradictions
   - Assign severity levels: BLOCK, WARN, NOTE

4. **Present the structured review**:
   - Show the summary statistics (total challenges by severity)
   - List all BLOCK challenges with exact quoted text, evidence, and suggested fixes
   - List all WARN challenges with suggestions
   - List NOTE observations
   - Calculate the average source quality score

5. **Offer next steps** using AskUserQuestion:
   - "Help me fix the BLOCK challenges" -- walk through each BLOCK and apply fixes
   - "Help me address the WARN challenges too" -- fix BLOCKs and WARNs
   - "I'll fix these myself" -- end the review
   - If the user wants fixes, use the Edit tool to apply them to the markdown file

6. **After fixes** (if the user chose to fix):
   - Offer to re-run the review to verify fixes
   - Offer to build the PDF via `/gerdsenai:build`
