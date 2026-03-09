# Local Infrastructure Reference

Setup, usage, and troubleshooting for optional local infrastructure components that enhance the research pipeline without requiring cloud services.

## ChromaDB (Local Vector Database)

ChromaDB provides local vector storage as an alternative to Pinecone. It uses SQLite for persistence and built-in embeddings, requiring no API keys or cloud accounts.

### Setup

ChromaDB is installed into the Document Builder's virtual environment:

```bash
# macOS/Linux
<document_builder_path>/venv/bin/python -m pip install chromadb

# Windows
<document_builder_path>/venv/Scripts/python.exe -m pip install chromadb
```

### Usage via chromadb-store.py

The `scripts/chromadb-store.py` utility provides a CLI interface:

```bash
# Initialize a project collection
<venv_python> scripts/chromadb-store.py init my-project

# Store a research finding (auto-chunked for long text)
<venv_python> scripts/chromadb-store.py store my-project "Key finding text here" \
  --metadata '{"source": "url", "section": "Market Analysis"}' \
  --chunk-size 500 --chunk-overlap 100

# Query stored findings with relevance filtering
<venv_python> scripts/chromadb-store.py query my-project "market trends 2025" \
  --n-results 5 --max-distance 1.0

# Query with metadata filter
<venv_python> scripts/chromadb-store.py query my-project "key findings" \
  --where '{"phase": "4"}'

# List all project collections
<venv_python> scripts/chromadb-store.py list

# Clear a collection
<venv_python> scripts/chromadb-store.py clear my-project
```

All commands output JSON for programmatic consumption.

#### Store Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--chunk-size` | 500 | Chunk size in characters. Documents longer than this are split into overlapping chunks for better embedding coverage. |
| `--chunk-overlap` | 100 | Overlap between chunks in characters. Ensures context continuity across chunk boundaries. |
| `--metadata` | none | JSON metadata string. Nested values (lists, dicts) are serialized to JSON strings automatically. |

#### Query Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--n-results` | 5 | Maximum number of results to return. |
| `--max-distance` | 1.0 | Maximum cosine distance threshold (range 0-2, where 0 = identical). Results beyond this distance are filtered out. |
| `--where` | none | ChromaDB where filter as JSON, e.g., `'{"phase": "4"}'`. Filters by metadata fields. |

### Reporting via chromadb-report.py

The `scripts/chromadb-report.py` utility provides detailed Vector DB reporting:

```bash
# Detailed report for a single project
<venv_python> scripts/chromadb-report.py report my-project

# Cross-project overview
<venv_python> scripts/chromadb-report.py report --all

# System health check (version, storage, cache)
<venv_python> scripts/chromadb-report.py health
```

Reports include metadata schema analysis, sample documents, data quality metrics (duplicates, empties, metadata completeness), and optional query tests. Use `/gerdsenai:vector-db-report` for formatted output.

### Storage Location

Collections are stored at `~/.gerdsenai/chromadb/<project-name>/`. Override with the `GERDSEN_CHROMADB_PATH` environment variable.

### When ChromaDB is Used

The research pipeline (Phase 0.5) discovers ChromaDB availability and uses it when:
1. Pinecone is NOT available (ChromaDB is the fallback)
2. The venv Python can `import chromadb` successfully

Priority order: Pinecone > ChromaDB > in-context (no vector DB)

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `ModuleNotFoundError: No module named 'chromadb'` | Install: `<venv_python> -m pip install chromadb` |
| Slow first query | ChromaDB downloads its embedding model on first use (~50MB). Subsequent queries are fast. |
| Long documents not searchable | ChromaDB's embedding model (all-MiniLM-L6-v2) truncates to 256 tokens. Use `--chunk-size 500` (default) to auto-chunk long documents. |
| Irrelevant query results | Use `--max-distance 0.5` for stricter relevance filtering (default: 1.0). Range is 0-2 for cosine distance. |
| Disk space | Each project collection uses ~1MB base + ~1KB per document. Safe to delete `~/.gerdsenai/chromadb/` to reclaim space. |
| Permission errors | Ensure the storage directory is writable. Check `GERDSEN_CHROMADB_PATH` if set. |

---

## Ollama (Local AI Inference)

Ollama provides local LLM inference with an OpenAI-compatible API. It supports NVIDIA (CUDA), AMD (ROCm), Apple Silicon (Metal), and CPU-only operation.

### Detection

The research pipeline detects Ollama via `ToolSearch("ollama")`. The plugin never installs Ollama -- it only detects and uses it if present.

To install Ollama yourself: visit [ollama.com](https://ollama.com) and follow the instructions for your platform.

### What Ollama Enables

When available, Ollama can be used for:
- **Pre-screening factual claims** before dispatching the Opus red-team reviewer (reduces API costs)
- **Counter-argument generation** in Extreme Research mode (parallel local agents)
- **Offline draft generation** for report sections

### Model Recommendations

| Use Case | Recommended Model | Min RAM | Min VRAM |
|----------|------------------|---------|----------|
| Pre-screening / counter-arguments | `llama3.1:8b` or `mistral:7b` | 16GB | 8GB (or CPU) |
| High-quality synthesis | `llama3.1:70b` or `mixtral:8x7b` | 32GB | 24GB+ |
| Code analysis | `codellama:13b` | 16GB | 8GB |

### Platform-Specific Notes

- **macOS (Apple Silicon)**: Ollama runs natively via Metal. M1 with 16GB unified memory handles 8B models well. 70B models need M2 Pro+ with 32GB+.
- **Windows/Linux (NVIDIA)**: Uses CUDA automatically. Any GPU with 8GB+ VRAM handles 8B models.
- **Windows/Linux (AMD)**: ROCm support. RX 7600+ with 8GB VRAM for 8B models.
- **CPU-only**: Works but slow. Suitable for pre-screening small text chunks, not full synthesis.

### Troubleshooting

| Issue | Solution |
|-------|----------|
| `ollama` not found in PATH | Install from ollama.com. Restart terminal after installation. |
| No models loaded | Run `ollama pull llama3.1:8b` to download a model |
| Out of memory | Use a smaller model or add `OLLAMA_NUM_PARALLEL=1` to limit concurrency |
| Slow inference on CPU | Expected. Use for small tasks (pre-screening), not full report generation. |

---

## Hardware Requirements by Tier

Extreme Research mode adapts to whatever hardware is available. More capability = more local offloading, but the mode works at every tier.

| Configuration | RAM | GPU | What It Enables |
|--------------|-----|-----|-----------------|
| Base (Claude Code only) | 8GB | None | Standard + Extreme mode (cloud-only, more sub-agents, multi-pass) |
| + ChromaDB | 8GB | None | Context window relief for 50+ page reports, no cloud vector DB needed |
| + Ollama (7-8B model) | 16GB | Any 8GB GPU or CPU-only | Pre-screening, counter-argument agents, offline drafts |
| + Ollama (30-70B model) | 32-64GB | 24-48GB GPU | High-quality local synthesis, reduced cloud API costs |
| Full stack (all available) | Whatever you have | Whatever you have | Uses best available at every tier |

The plugin queries `ollama list` to discover loaded models and selects the best available for each task. It never specifies GPU type or vendor -- Ollama handles hardware abstraction.
