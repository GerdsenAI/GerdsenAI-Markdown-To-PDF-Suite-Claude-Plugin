---
description: "Manage vector databases — report, store, query, and configure ChromaDB or Pinecone backends"
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion, ToolSearch
argument-hint: "[report | store | query | configure] [options]"
---

You are managing vector database operations for GerdsenAI.

## Steps

1. **Read settings** from `.claude/gerdsenai.local.md` to find the `document_builder_path`. If the file doesn't exist or `document_builder_path` is missing, offer to run setup: "The Document Builder isn't configured yet. Want me to set it up now?" Determine the venv Python path:
   - Windows: `<document_builder_path>/venv/Scripts/python.exe`
   - macOS/Linux: `<document_builder_path>/venv/bin/python`

2. **Discover backend** — use only one, never both:
   a. Check if ChromaDB is available: `'<venv_python>' -c "import chromadb; print('available')" 2>/dev/null`
   b. If ChromaDB is NOT available, probe for Pinecone: `ToolSearch("pinecone")`
   c. If neither is available, report "No vector database backend configured" and offer to configure one (see Configure operation below).

3. **Auto-detect intent** from `$ARGUMENTS`:
   - Starts with `report` or `--all` or is a project name → **Report**
   - Starts with `store` → **Store**
   - Starts with `query` or `search` → **Query**
   - Starts with `configure` or `config` → **Configure**
   - No arguments → ask using AskUserQuestion:
     - "Generate a report on vector DB contents"
     - "Store documents into vector DB"
     - "Query the vector DB"
     - "Configure vector DB settings"

---

### Report

Generate a detailed inventory and health report on vector DB contents.

4. **Generate report based on backend**:

   **ChromaDB Path:**
   - If a project name was provided: `'<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-report.py' report '<project-name>'`
   - If `--all` or no project specified: `'<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-report.py' report --all`
   - Also run health check: `'<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-report.py' health`

   **Pinecone Path:**
   - Use `list-indexes` to enumerate indexes
   - Use `describe-index` and `describe-index-stats` for each relevant index
   - Compile into the same report format

5. **Present formatted report** with these sections:
   - **System Overview**: Backend type, version, storage path, model info
   - **Inventory**: Projects/indexes with document counts and sizes
   - **Metadata Schema**: Observed fields and value distributions
   - **Sample Documents**: Preview of stored content
   - **Data Quality**: Duplicates, empties, metadata completeness
   - **Recommendations**: Suggestions based on findings

6. **Offer optional PDF build**: "Would you like me to build this report as a PDF using `/gerdsenai:build`?"

---

### Store

Store documents into the vector database with chunking and metadata.

4. **Resolve what to store**:
   - If a file path was provided after `store`, read the file
   - If a directory was provided, scan for text/markdown files
   - If raw text follows `store`, use it directly
   - Ask the user for the target collection/project name

5. **Store to backend**:

   **ChromaDB Path:**
   ```
   '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-store.py' store '<collection>' '<text>' --metadata '{"source": "<filename>", "type": "document"}'
   ```
   - For multiple files, iterate and store each with source metadata
   - Report: documents stored, chunk count, collection size

   **Pinecone Path:**
   - Use `upsert-records` MCP tool with the configured index
   - Include source metadata for each record

6. **Report results**: Documents stored, total chunks, collection/index size.

---

### Query

Search the vector database with natural language.

4. **Parse the query**: Extract the search text from arguments after `query`.
   - If no query text, ask the user what to search for

5. **Execute search**:

   **ChromaDB Path:**
   ```
   '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-store.py' query '<collection>' '<query_text>' --n-results 10
   ```
   - Optionally apply filters: `--where '{"key": "value"}'`, `--max-distance 1.0`

   **Pinecone Path:**
   - Use `search-records` MCP tool with the configured index
   - If re-ranking is configured, use `rerank-documents` on results
   - If cascading search is configured, use `cascading-search`

6. **Present results**: Show matched documents with relevance scores, metadata, and content previews.
7. **Offer follow-up**: "Refine the query?" or "Store these results?"

---

### Configure

Configure vector DB settings — backend, index, re-ranking, chunking.

4. **Read current config** from `.claude/gerdsenai.local.md` for any existing vector DB settings.

5. **Present configuration options** using AskUserQuestion:

   **Backend selection:**
   - "ChromaDB (local, no API key needed)" — check if installed, offer to install via pip if not
   - "Pinecone (cloud, requires API key)" — check if MCP tools available via ToolSearch

   **Index/Collection settings:**
   - Collection/index name (default: project name)
   - Embedding model (ChromaDB: default all-MiniLM-L6-v2; Pinecone: model specified at index creation)

   **Chunking settings:**
   - Chunk size (default: 500 characters)
   - Chunk overlap (default: 100 characters)

   **Query settings:**
   - Default result count (default: 10)
   - Maximum distance threshold (default: 1.5)

   **Re-ranking (Pinecone only):**
   - Enable/disable re-ranking
   - Re-ranking model selection
   - Top-N after re-ranking

6. **Save configuration** to `.claude/gerdsenai.local.md` by adding/updating vector DB fields. **IMPORTANT on Windows**: Use Python to write settings with LF line endings (`newline='\n'`), not the Write tool, because CRLF breaks the bash YAML parser:
   ```yaml
   vector_db_backend: "chromadb|pinecone"
   vector_db_collection: "<name>"
   vector_db_chunk_size: 500
   vector_db_chunk_overlap: 100
   vector_db_default_results: 10
   vector_db_max_distance: 1.5
   vector_db_rerank_enabled: false
   vector_db_rerank_model: ""
   ```

7. **Verify configuration** by running a test operation (init collection or list indexes).
