---
description: "Manage vector databases — report, store, query, and configure ChromaDB and/or Pinecone backends with dual-backend, re-ranking, and hook automation"
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion, ToolSearch
argument-hint: "[report | store | query | configure] [options]"
---

You are managing vector database operations for GerdsenAI.

## Steps

1. **Read settings** from `.claude/gerdsenai.local.md` to find the `document_builder_path`. If the file doesn't exist or `document_builder_path` is missing, offer to run setup: "The Document Builder isn't configured yet. Want me to set it up now?" Determine the venv Python path:
   - Windows: `<document_builder_path>/venv/Scripts/python.exe`
   - macOS/Linux: `<document_builder_path>/venv/bin/python`

2. **Discover backends** — check both, respecting user configuration:
   - Read `vector_db_mode` from settings (chromadb | pinecone | dual | none). If not set, auto-detect:
     a. Check ChromaDB: `'<venv_python>' -c "import chromadb; print('available')" 2>/dev/null`
     b. Probe for Pinecone: `ToolSearch("pinecone")` and check `PINECONE_API_KEY`
   - If neither available, offer to configure (see Configure operation below)
   - **Dual mode**: both backends active. User's `vector_db_primary` determines query preference.

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

Full vector DB setup wizard — backends, indexes, embeddings, re-ranking, hooks.

4. **Read current config** from `.claude/gerdsenai.local.md` for any existing vector DB settings.

5. **Backend selection** using AskUserQuestion:
   - "ChromaDB only (local, no API keys)" — check if installed, offer `pip install chromadb` if not
   - "Pinecone only (cloud, requires API key)" — verify PINECONE_API_KEY is set
   - "Dual: ChromaDB (local) + Pinecone (cloud)" — both backends active
   - "None (disable vector DB)"

6. **If ChromaDB enabled**, configure:
   - Embedding model using AskUserQuestion:
     - "all-MiniLM-L6-v2 (384d, fast, ~50MB download)" — recommended for most use cases
     - "sentence-transformers/all-mpnet-base-v2 (768d, better quality, ~400MB)" — for higher precision
   - Chunk size (default: 500 characters)
   - Chunk overlap (default: 100 characters)
   - Max distance threshold (default: 1.5, range 0-2 for cosine)
   - Default result count (default: 10)

7. **If Pinecone enabled**, configure:
   - Verify PINECONE_API_KEY is set in environment
   - Index name: auto-generate from repo basename, or let user specify
   - Embedding model using AskUserQuestion:
     - "llama-text-embed-v2 (high-performance dense, best for structured docs)"
     - "multilingual-e5-large (efficient, good for messy data)"
     - "pinecone-sparse-english-v0 (sparse/hybrid search)"
   - Cloud and region (default: aws us-east-1)
   - Re-ranking using AskUserQuestion:
     - "Enable re-ranking" → then select model:
       - "pinecone-rerank-v0 (state-of-the-art, up to 512 tokens)"
       - "bge-reranker-v2-m3 (multilingual, good on messy data)"
       - "cohere-rerank-3.5 (enterprise-focused, multi-field)"
     - "Disable re-ranking"
   - Re-rank top-N (default: 5)

8. **If dual mode**, configure:
   - Primary backend for queries using AskUserQuestion:
     - "ChromaDB (local, faster response)"
     - "Pinecone (cloud, better quality with re-ranking)"
   - Sync mode using AskUserQuestion:
     - "Mirror (write to both simultaneously)" — recommended for reliability
     - "Split (route by context — e.g., sprint→local, research→cloud)" — ask for routing rules
     - "Primary only (write to primary, manual sync to secondary)"

9. **Hook configuration** using AskUserQuestion:
   - "Auto-upsert on git commit?" (recommended: yes)
   - "Health check on session start?" (recommended: yes)
   - "Flush on session end?" (recommended: yes)
   - "Auto-index file changes?" (warn: expensive, default: no)

10. **Save all settings** to `.claude/gerdsenai.local.md`. **IMPORTANT on Windows**: Use Python to write with LF line endings (`newline='\n'`):
    ```yaml
    vector_db_mode: "dual"
    vector_db_chromadb_enabled: true
    vector_db_pinecone_enabled: true
    vector_db_primary: "chromadb"
    vector_db_sync_mode: "mirror"
    vector_db_collection_prefix: ""
    vector_db_chromadb_embedding_model: "all-MiniLM-L6-v2"
    vector_db_chromadb_chunk_size: 500
    vector_db_chromadb_chunk_overlap: 100
    vector_db_chromadb_max_distance: 1.5
    vector_db_chromadb_default_results: 10
    vector_db_pinecone_index: ""
    vector_db_pinecone_embedding_model: "llama-text-embed-v2"
    vector_db_pinecone_cloud: "aws"
    vector_db_pinecone_region: "us-east-1"
    vector_db_pinecone_rerank_enabled: false
    vector_db_pinecone_rerank_model: "pinecone-rerank-v0"
    vector_db_pinecone_rerank_top_n: 5
    vector_db_hook_on_commit: true
    vector_db_hook_on_session_start: true
    vector_db_hook_on_session_end: true
    vector_db_hook_on_file_change: false
    ```

11. **Verify configuration** by running the unified init:
    ```
    '<venv_python>' '${CLAUDE_PLUGIN_ROOT}/scripts/vector-db-init.py' '.claude/gerdsenai.local.md' 'research'
    ```
    Report: backends initialized, collection/index names, document counts.

12. **Data isolation guarantee**: Each repo gets its own collections/indexes derived from the repo directory basename. Collections are named `<repo-basename>-<context>` (e.g., `my-app-research`, `my-app-sprint`, `my-app-redteam`). Data from different repos is NEVER mixed.
