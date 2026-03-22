# Vector DB Reference

Configuration reference for the GerdsenAI vector database infrastructure. Covers embedding models, re-ranking models, backend comparison, collection naming, metadata schema, hook triggers, and dual-backend routing.

---

## Embedding Models

### ChromaDB (Local)

| Model | Dimensions | Size | Speed | Quality | Best For |
|-------|-----------|------|-------|---------|----------|
| `all-MiniLM-L6-v2` | 384 | ~50MB | Fast | Good | Default. Research summaries, technical findings, decision logs |
| `sentence-transformers/all-mpnet-base-v2` | 768 | ~400MB | Moderate | Better | Higher precision needs. Longer passages, nuanced queries |

Both models are downloaded automatically on first use. Cached at `~/.cache/chroma/`.

### Pinecone (Cloud, Integrated Indexes)

| Model | Type | Best For |
|-------|------|----------|
| `llama-text-embed-v2` | Dense | High-performance. Structured documents, long passages |
| `multilingual-e5-large` | Dense | Efficient. Messy data, short queries, multilingual |
| `pinecone-sparse-english-v0` | Sparse | Keyword/hybrid search. Lexical importance estimation |

Integrated indexes handle embedding automatically on upsert and query — no external embedding step needed.

---

## Re-Ranking Models (Pinecone Only)

| Model | Strengths | Max Tokens | Best For |
|-------|-----------|------------|----------|
| `pinecone-rerank-v0` | State-of-the-art accuracy | 512/chunk | Default. Best benchmark scores |
| `bge-reranker-v2-m3` | Multilingual, handles messy data | 512/chunk | Non-English or mixed-language content |
| `cohere-rerank-3.5` | Multi-field ranking, enterprise | 512/chunk | Enterprise search, multiple rank fields |

Re-ranking improves result quality by cross-encoding query-document pairs after initial vector search. Enable via `vector_db_pinecone_rerank_enabled: true`.

---

## Backend Comparison

| Feature | ChromaDB | Pinecone |
|---------|----------|----------|
| **Hosting** | Local (SQLite) | Cloud (managed) |
| **API keys** | None needed | PINECONE_API_KEY required |
| **Latency** | <10ms (local disk) | 50-200ms (network) |
| **Cost** | Free | Free tier: 2GB, then usage-based |
| **Persistence** | `~/.gerdsenai/chromadb/` | Cloud-managed |
| **Embedding** | all-MiniLM-L6-v2 (configurable) | Integrated (auto on upsert) |
| **Re-ranking** | Not supported | 3 models available |
| **Cascading search** | Not supported | Cross-index with dedup |
| **Max document size** | Unlimited (auto-chunked) | Varies by plan |
| **Offline** | Yes | No |
| **MCP tools** | No (Python script) | Yes (8 tools) |
| **Python SDK** | `pip install chromadb` | `pip install pinecone` |

---

## Collection/Index Naming Convention

**Principle**: Each repo gets its own isolated collections/indexes. Data from different repos is NEVER mixed.

**Format**: `<repo-basename>-<context>`

| Context | ChromaDB Collection | Pinecone Index/Namespace | Purpose |
|---------|--------------------|-----------------------|---------|
| research | `my-app-research` | `my-app` / namespace `research` | Research findings, citations, sources |
| sprint | `my-app-sprint` | `my-app` / namespace `sprint` | Sprint state, decisions, progress |
| redteam | `my-app-redteam` | `my-app` / namespace `redteam` | Adversarial findings, regressions |

**Override**: Set `vector_db_collection_prefix` in settings to use a custom prefix instead of the auto-detected repo basename.

---

## Metadata Schema Standard

All agents should use these shared metadata fields for cross-agent queryability:

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `type` | str | plan, architecture, progress, commit, decision, error_resolution, plan_adjustment, finding | What kind of data |
| `phase` | str | "0"-"8" | Which workflow phase produced this |
| `domain` | str | code, security, deps, architecture, testing, devops, database, aiml, accessibility, document, strategic | Red-team domain |
| `severity` | str | BLOCK, WARN, NOTE | Finding severity |
| `status` | str | open, resolved, approved, complete | Current state |
| `task` | str | "1.1", "2.3" | Sprint task ID |
| `file` | str | relative path | Source file |
| `line` | int | line number | Source line |
| `hash` | str | git commit hash | Associated commit |
| `topic` | str | free text | Decision topic |
| `facet` | str | free text | Research facet |
| `blast_radius` | str | LOCAL, MODULE, SYSTEM, EXTERNAL | Impact scope |
| `rabbit_hole_depth` | int | 0-5 | Investigation depth |

Not all fields are required — use what's relevant. ChromaDB validates scalar types only (str, int, float, bool).

---

## Dual-Backend Routing

### Mirror Mode (Default)

Write to BOTH backends on every store operation. Query the primary backend first.

```
Store → ChromaDB + Pinecone (parallel)
Query → Primary (configured) → if no results → Secondary
```

### Split Mode

Route by context:

```
sprint context → ChromaDB (fast local access for frequent state updates)
research context → Pinecone (cloud persistence, re-ranking for quality)
redteam context → user-configurable
```

### Primary-Only Mode

Write only to the primary backend. Secondary is available for manual sync or migration.

---

## Hook Triggers

| Hook | Event | Condition | Action |
|------|-------|-----------|--------|
| PostToolUse | Bash (git commit) | `vector_db_hook_on_commit: true` | Upsert commit summary with files changed |
| PostToolUse | Write/Edit | `vector_db_hook_on_file_change: true` | Upsert file content (expensive, opt-in) |
| SessionStart | Session begins | `vector_db_hook_on_session_start: true` | Health check, report stats |
| Stop | Session ends | `vector_db_hook_on_session_end: true` | Flush pending, store session marker |

Hooks exit silently if vector DB is not configured or settings file is missing.

---

## Settings Reference

All settings are stored in `.claude/gerdsenai.local.md` as flat YAML front matter.

```yaml
# Backend mode
vector_db_mode: "dual"                        # chromadb | pinecone | dual | none
vector_db_chromadb_enabled: true
vector_db_pinecone_enabled: true
vector_db_primary: "chromadb"                 # primary for queries in dual mode
vector_db_sync_mode: "mirror"                 # mirror | split | primary_only
vector_db_collection_prefix: ""               # empty = auto-detect from repo basename

# ChromaDB
vector_db_chromadb_embedding_model: "all-MiniLM-L6-v2"
vector_db_chromadb_chunk_size: 500
vector_db_chromadb_chunk_overlap: 100
vector_db_chromadb_max_distance: 1.5
vector_db_chromadb_default_results: 10

# Pinecone
vector_db_pinecone_index: ""                  # empty = auto-create from repo basename
vector_db_pinecone_embedding_model: "llama-text-embed-v2"
vector_db_pinecone_cloud: "aws"
vector_db_pinecone_region: "us-east-1"
vector_db_pinecone_rerank_enabled: false
vector_db_pinecone_rerank_model: "pinecone-rerank-v0"
vector_db_pinecone_rerank_top_n: 5

# Hooks
vector_db_hook_on_commit: true
vector_db_hook_on_session_start: true
vector_db_hook_on_session_end: true
vector_db_hook_on_file_change: false
```

**IMPORTANT on Windows**: Always use Python to write this file with `newline='\n'`. CRLF line endings break the bash YAML parser.

---

## Unified Init Script

All agents use `scripts/vector-db-init.py` instead of inline backend selection:

```
<venv_python> '${CLAUDE_PLUGIN_ROOT}/scripts/vector-db-init.py' '.claude/gerdsenai.local.md' '<context>'
```

Returns JSON:
```json
{
  "success": true,
  "mode": "dual",
  "backends": {
    "chromadb": {"collection": "my-app-research", "document_count": 5},
    "pinecone": {"index": "my-app-research", "document_count": 12}
  },
  "primary": "chromadb",
  "sync_mode": "mirror"
}
```
