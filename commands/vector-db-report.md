---
description: "Generate a detailed report on Vector DB contents — collection inventory, metadata analysis, sample documents, and data quality for ChromaDB or Pinecone"
allowed-tools: Bash, Read, Glob, AskUserQuestion, ToolSearch
argument-hint: "[project-name | --all]"
model: sonnet
---

You are generating a Vector DB status report. Discover the available backend, query it, and present a formatted report.

## Steps

1. **Read settings** from `.claude/gerdsenai.local.md` to find the `document_builder_path`. Determine the venv Python path:
   - Windows: `<document_builder_path>/venv/Scripts/python.exe`
   - macOS/Linux: `<document_builder_path>/venv/bin/python`

2. **Discover backend** — use only one, never both:
   a. Check if ChromaDB is available: `'<venv_python>' -c "import chromadb; print('available')" 2>/dev/null`
   b. If ChromaDB is NOT available, probe for Pinecone: `ToolSearch("pinecone")`
   c. If neither is available, report "No vector database backend configured" and suggest running `/gerdsenai:setup` with ChromaDB enabled.

3. **Generate report based on backend**:

   ### ChromaDB Path
   - If the user provided a project name: `'<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-report.py' report '<project-name>'`
   - If the user passed `--all` or no argument: `'<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-report.py' report --all`
   - Also run: `'<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-report.py' health`

   ### Pinecone Path
   - Use `list-indexes` to enumerate indexes
   - Use `describe-index` and `describe-index-stats` for each relevant index
   - Compile the data into the same report format

4. **Present formatted report** with these sections:
   - **System Overview**: Backend type, version, storage path, model info
   - **Inventory**: Projects/indexes with document counts and sizes
   - **Metadata Schema**: Observed fields and value distributions
   - **Sample Documents**: Preview of stored content
   - **Data Quality**: Duplicates, empties, metadata completeness
   - **Recommendations**: Suggestions based on findings (e.g., "5 duplicate documents found — consider deduplication", "Collection X has no metadata — add metadata for better retrieval")

5. **Offer optional PDF build**: "Would you like me to build this report as a PDF using `/gerdsenai:build-pdf`?"
