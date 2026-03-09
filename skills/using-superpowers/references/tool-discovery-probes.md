# ToolSearch Probe Catalog

This is the exhaustive reference for Phase 0b capability discovery. The main SKILL.md has the summary table; this file has detailed per-tool documentation.

## How ToolSearch Works

`ToolSearch` finds deferred tools — MCP server tools that exist but aren't loaded until discovered. Two query modes:

- **Keyword search**: `ToolSearch("firecrawl")` — finds up to 5 matching tools, all immediately available
- **Direct select**: `ToolSearch("select:mcp__firecrawl-mcp__firecrawl_search")` — loads one specific tool by name

Both modes load tools equally. Don't follow a keyword search with `select:` calls for tools already returned.

## Probe Reference

### Web Research: `"firecrawl"`

| Tool Name | Capability |
|-----------|-----------|
| `firecrawl_search` | Web search with LLM-optimized markdown results |
| `firecrawl_scrape` | Scrape a single URL to clean markdown |
| `firecrawl_crawl` | Crawl an entire site, follow links |
| `firecrawl_map` | Discover all URLs on a site without scraping |
| `firecrawl_extract` | Structured data extraction from pages |
| `firecrawl_browser_*` | Full browser session (create, execute JS, navigate) |

**Preferred over** WebSearch/WebFetch for all web operations when available. Returns cleaner, more structured output.

**Fallback chain**: Firecrawl → WebSearch (built-in) → WebFetch (built-in, needs specific URL)

### Browser Automation: `"playwright"`

| Tool Name | Capability |
|-----------|-----------|
| `browser_navigate` | Go to a URL |
| `browser_click` | Click elements |
| `browser_fill_form` | Fill form fields |
| `browser_take_screenshot` | Capture page screenshot |
| `browser_evaluate` | Execute JavaScript in page |
| `browser_snapshot` | Get accessibility tree snapshot |
| `browser_press_key` | Keyboard input |
| `browser_select_option` | Select dropdown options |
| `browser_file_upload` | Upload files to inputs |
| `browser_hover` | Hover over elements |
| `browser_drag` | Drag and drop |
| `browser_tabs` | Manage browser tabs |
| `browser_close` | Close browser |
| `browser_console_messages` | Read console output |
| `browser_network_requests` | Monitor network traffic |

**Use when**: You need to interact with a page (login, fill forms, click through SPAs, take screenshots). Firecrawl is better for passive reading; Playwright is better for active interaction.

**Fallback chain**: Playwright → Firecrawl browser mode → Bash + curl (very limited)

### Vector Storage: `"pinecone"`

| Tool Name | Capability |
|-----------|-----------|
| `search-records` | Semantic vector search across an index |
| `upsert-records` | Add or update records in an index |
| `create-index-for-model` | Create a new index optimized for a specific embedding model |
| `list-indexes` | List all available indexes |
| `describe-index` | Get index configuration and stats |
| `describe-index-stats` | Get record count and dimension info |
| `rerank-documents` | Re-rank search results for relevance |
| `cascading-search` | Search across multiple indexes |
| `search-docs` | Search Pinecone documentation |

Also look for Pinecone Assistant tools via the `pinecone:assistant` skill for document Q&A with citations.

**Use when**: Research findings exceed ~20 pages, you need cross-session memory, or you're building a RAG pipeline.

**Fallback chain**: Pinecone → local JSON files → keep everything in conversation context

### Cloud Infrastructure: `"cloudflare"`

| Tool Name | Capability |
|-----------|-----------|
| `workers_list` / `workers_get_worker` | List and inspect Cloudflare Workers |
| `d1_database_*` | D1 SQL databases (create, query, list, delete) |
| `kv_namespace_*` | KV key-value storage |
| `r2_bucket_*` | R2 object storage (S3-compatible) |
| `hyperdrive_config_*` | Database connection pooling |
| `accounts_list` / `set_active_account` | Account management |

**Use when**: Deploying edge APIs, serverless functions, or needing managed databases/storage.

### Deployment: `"vercel"`

| Tool Name | Capability |
|-----------|-----------|
| `deploy_to_vercel` | Deploy a project |
| `list_projects` / `get_project` | Manage projects |
| `list_deployments` / `get_deployment` | Track deployments |
| `get_deployment_build_logs` | Read build logs |
| `get_runtime_logs` | Read runtime logs |
| `check_domain_availability_and_price` | Domain management |

**Use when**: Deploying frontend applications, static sites, or Next.js/serverless apps.

**Fallback chain**: Vercel → Cloudflare Workers/Pages → manual deploy instructions

### AI/ML Research: `"hugging face"`

| Tool Name | Capability |
|-----------|-----------|
| `hub_repo_search` | Search models, datasets, spaces on HF Hub |
| `paper_search` | Search academic papers (arXiv-linked) |
| `hub_repo_details` | Get detailed repo info (model card, stats) |
| `space_search` | Find HF Spaces (demos) |
| `hf_doc_search` / `hf_doc_fetch` | Search and fetch HF documentation |

**Use when**: Looking for ML models, academic papers, datasets, or HF-specific documentation.

### Diagrams: `"mermaid"`

| Tool Name | Capability |
|-----------|-----------|
| `validate_and_render_mermaid_diagram` | Render a Mermaid diagram to image |
| `get_diagram_summary` | Summarize an existing diagram |
| `get_diagram_title` | Extract diagram title |

**Use when**: You need validated, rendered diagram images. For inline Mermaid in markdown/PDF, just write Mermaid code blocks directly — the GerdsenAI Document Builder renders them.

### Library Docs: `"context7"`

| Tool Name | Capability |
|-----------|-----------|
| `resolve-library-id` | Find the Context7 ID for a library |
| `query-docs` | Query documentation for a resolved library |

**Two-step pattern**: First resolve the library ID, then query its docs.

**Use when**: You need accurate, current API documentation for a specific library or framework. More reliable than web-searching for docs.

**Fallback chain**: Context7 → Firecrawl (scrape doc site) → WebSearch for docs

### Codebase Intelligence: `"greptile"`

| Tool Name | Capability |
|-----------|-----------|
| `search_greptile_comments` | Search code with AI understanding |
| `trigger_code_review` / `get_code_review` | Automated code review |
| `list_pull_requests` / `list_merge_requests` | PR/MR listing |
| `list_merge_request_comments` | Review comments |
| `create_custom_context` / `search_custom_context` | Custom knowledge bases |

**Use when**: Understanding unfamiliar codebases, getting AI-powered code review, or searching code semantically (not just by regex).

### Local AI Inference: `"ollama"`

> **Note**: Tool names vary by MCP server implementation. The names below are examples — use the ACTUAL tool names returned by `ToolSearch("ollama")`.

| Example Tool Name | Capability |
|-------------------|-----------|
| `ollama_chat` | Chat completion with local models |
| `ollama_generate` | Text generation with local models |
| `ollama_list` | List available/loaded models |
| `ollama_pull` | Download a model |

**Use when**: You want to offload simple tasks (pre-screening, counter-arguments, draft generation) to a local LLM to reduce cloud API costs. Ollama handles hardware abstraction across NVIDIA (CUDA), AMD (ROCm), Apple Silicon (Metal), and CPU-only.

**Fallback chain**: Ollama → Claude API (cloud) — Ollama is always optional, never required.

**Discovery**: Probe with `ToolSearch("ollama")`. If no MCP tools found, also check if `ollama` is in PATH via Bash (`which ollama`). The CLI can be used directly even without MCP integration.

### GitHub MCP: `"github"`

The `gh` CLI handles most GitHub operations, but the GitHub MCP server may provide additional capabilities depending on configuration. Probe if you need operations beyond what `gh` offers.

## Probe Execution Strategy

For maximum speed, run all relevant probes in a single message with parallel ToolSearch calls. A typical discovery sweep:

```
ToolSearch("firecrawl")      — web research
ToolSearch("playwright")     — browser automation
ToolSearch("pinecone")       — vector storage
ToolSearch("cloudflare")     — cloud infra
ToolSearch("vercel")         — deployment
ToolSearch("hugging face")   — ML/AI
ToolSearch("mermaid")        — diagrams
ToolSearch("context7")       — library docs
ToolSearch("greptile")       — codebase search
ToolSearch("ollama")         — local AI inference
```

You don't need to run every probe every time. Match probes to the task:

- **Research task** → firecrawl, pinecone, hugging face, context7, ollama
- **Build task** → vercel, cloudflare, playwright, context7
- **Debug task** → greptile, playwright
- **Report task** → firecrawl, pinecone, mermaid, ollama
- **Unknown/complex** → run them all
