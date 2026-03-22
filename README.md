# GerdsenAI MD-to-PDF Suite - Claude Code Plugin

A Claude Code plugin for creating professional PDFs from Markdown and conducting deep research with auto-generated intelligence reports, powered by the [GerdsenAI Document Builder](https://github.com/GerdsenAI/GerdsenAI_Document_Builder).

## What It Does

- **Deep research intelligence reports** - conduct multi-source research and generate professional reports with Mermaid visualizations and academic citations as PDFs
- **Author PDF-ready markdown** with guidance on front matter, structure, code blocks, Mermaid diagrams, and formatting
- **Build PDFs** directly from Claude Code with styled code blocks, cover pages, table of contents, headers/footers, and page numbers
- **Flexible output** - place PDFs alongside source files, in a custom directory, or in the builder's PDFs/ folder
- **Recursive builds** - build PDFs for all markdown files in a directory tree
- **Logo selection** - browse and select cover page and footer logos from available assets
- **Configure** the Document Builder's settings (logos, page size, colors, fonts, Mermaid themes, citation style)
- **Autonomous document creation** via agents that handle the full workflow from requirements to finished PDF
- **Guided first-run setup** - if you haven't configured the plugin, any command will offer to set it up inline

## Prerequisites

- [Claude Code](https://code.claude.com/docs/en/overview) CLI installed
- Python 3.9+
- **Windows:** Git for Windows (provides Git Bash, which all scripts run under)
- **Optional:** Pinecone API key (for cloud vector DB), Ollama (for local AI inference)

## Install

### From within Claude Code (recommended)

1. Open Claude Code in any project
2. Run `/plugin` to open the plugin manager
3. Go to the **Marketplaces** tab
4. Add the marketplace: `GerdsenAI/GerdsenAI-Markdown-To-PDF-Suite-Claude-Plugin`
5. Go to the **Discover** tab
6. Select **gerdsenai** and install (User scope recommended)
7. Run `/reload-plugins` to activate

### Local development

```
claude --plugin-dir /path/to/this/repo
```

After installing, run `/gerdsenai:setup` in any project to configure the Document Builder, vector DB backends, and preferences.

## Quick Start

1. Set up the Document Builder (guided setup with preferences):
   ```
   /gerdsenai:setup
   ```

2. Build a PDF:
   ```
   /gerdsenai:build my-document.md
   ```

3. Research a topic and generate an intelligence report:
   ```
   /gerdsenai:research-report AI chip market landscape
   ```

## Commands

| Command | Description |
|---------|-------------|
| `/gerdsenai:setup` | Install, configure, or update the Document Builder |
| `/gerdsenai:build <target>` | Build PDFs — single file or recursive directory (auto-detects) |
| `/gerdsenai:research-report [topic\|file]` | Deep research + intelligence reports; source monitoring when given a file path |
| `/gerdsenai:red-team <target>` | Adversarial analysis: 11 domains (code, security, deps, architecture, testing, DevOps, DB, AI/ML, a11y, docs, strategic) with Socratic reasoning |
| `/gerdsenai:vector-db [operation]` | Vector DB management: report, store, query, configure — dual-backend (ChromaDB + Pinecone) with hooks |
| `/gerdsenai:sprint-execute [plan\|description\|resume]` | Autonomous sprint executor: Socratic planning, autocoding, auto-commit |

### Build Options

```
/gerdsenai:build report.md                        # Single file
/gerdsenai:build report.md --output-dir ~/Reports  # Custom output directory
/gerdsenai:build report.md --output-name Q4-Review  # Custom filename
/gerdsenai:build ./docs                            # Recursive directory build
/gerdsenai:build ./docs --recursive                # Explicit recursive flag
```

Recursive mode auto-excludes `node_modules/`, `.git/`, `venv/`, `__pycache__/`, `.claude/`, and common non-document files (README.md, CLAUDE.md, etc.).

## Skill: PDF Document Authoring

The `pdf-document-authoring` skill activates when you're writing markdown intended for PDF output. It guides you on:

- YAML front matter fields (title, subtitle, author, date, version, confidential, watermark)
- Document structure and heading hierarchy
- Assessment/maturity sections using proper headings (not inline bold)
- Code block language identifiers for styled output (diff, tree, shell, python, yaml, etc.)
- Mermaid diagram syntax and best practices
- Table and image formatting
- Output location and filename options
- Quality checklist before building

## Agents

### Document Builder

Handles the full document creation workflow autonomously:

1. Checks installation (offers inline setup if not configured)
2. Gathers requirements (document type, audience, sections)
3. Authors publication-quality markdown
4. Builds the PDF with appropriate output location
5. Reports results and offers revisions

Activates on requests like "create a report", "write a document", "build a PDF", or "generate documentation".

### Research Report

Conducts deep, multi-source research and generates professional intelligence reports:

1. Discovers available search tools (WebSearch, firecrawl, brave, etc.)
2. Asks 2-4 clarifying questions about scope, depth, and key questions
3. Presents a research plan for approval
4. Launches parallel sub-agents to research each facet simultaneously
5. Conducts sequential deep-dives to fill gaps and resolve conflicts
6. Synthesizes findings into a structured report with Mermaid visualizations and citations
7. Runs quality checks (citation completeness, source diversity, heading hierarchy)
8. Builds the PDF and offers revisions

Activates on requests like "research the AI chip market", "build a dossier on quantum computing", "competitive analysis of cloud providers", or "write a white paper with citations".

**Report types:** Executive Brief (5-10 pages), Standard Report (15-30 pages), Deep-Dive Technical (30-50+ pages), Academic White Paper, Software Architecture Blueprint (40-70+ pages), Extreme Research (50-100+ pages).

**Citation styles:** APA (default), MLA, Chicago, IEEE, Harvard. Configured via `/gerdsenai:setup` (choose "Configure settings").

### Adversarial Analysis Engine

The `/gerdsenai:red-team` command is a full adversarial analysis engine using Socratic reasoning chains. It covers 11 domains: code quality, security (OWASP Top 10), dependencies (CVEs), architecture, testing, DevOps/CI/CD, database, AI/ML, accessibility (WCAG 2.1 AA), documents, and strategic alignment.

```
/gerdsenai:red-team ./src                              # Full repo analysis
/gerdsenai:red-team report.md                          # Document review
/gerdsenai:red-team ./src --domains security,deps      # Specific domains
/gerdsenai:red-team ./src --depth deep --fix           # Deep analysis with auto-fix
```

When an issue is found, the agent applies the **rabbit hole protocol**: if it's wrong here, where else? Pattern proliferation, dependency tracing, blast radius assessment, and STRIDE threat modeling. Research reports also undergo automated adversarial review before PDF generation.

### Living Intelligence Reports

Research reports are not static. Source monitoring is built into `/gerdsenai:research-report`:

```
/gerdsenai:research-report my-report.md   # Auto-detects .sources.json → checks freshness
                                           # No .sources.json → offers to register monitoring
```

After building a new report, you'll be offered to register it for monitoring. The session-start hook automatically alerts you when monitored reports have stale sources. The refresh flow updates only affected sections, adds a Revision History, and rebuilds the PDF.

### Sprint Execution

Plan and execute development sprints autonomously with `/gerdsenai:sprint-execute`:

```
/gerdsenai:sprint-execute "Add user authentication with JWT"  # New sprint
/gerdsenai:sprint-execute todo.md                              # Execute from plan
/gerdsenai:sprint-execute resume                               # Resume interrupted sprint
```

Uses the Socratic Method (Thesis → Antithesis → Synthesis) for sprint planning, then autocodes the entire sprint: writes code, runs tests, commits at planned points, and manages context via ChromaDB for resilience against context compaction.

## Local Infrastructure (Optional)

The plugin can use local infrastructure to extend the research pipeline without requiring cloud services. All local components are optional and detected automatically.

### ChromaDB (Local Vector Database)

An alternative to Pinecone for research memory. Uses SQLite persistence and built-in embeddings -- no cloud account or API keys needed.

```bash
# Install into the Document Builder venv (offered during /gerdsenai:setup)
<document_builder_path>/venv/bin/python -m pip install chromadb     # macOS/Linux
<document_builder_path>/venv/Scripts/python.exe -m pip install chromadb  # Windows
```

The research pipeline discovers ChromaDB automatically. Supports dual-backend mode (ChromaDB + Pinecone simultaneously) — configure via `/gerdsenai:vector-db configure`.

Features: automatic document chunking (500-char default with 100-char overlap), cosine distance filtering (`--max-distance`), metadata where filters, and data quality reporting.

### Vector DB Management

Manage vector databases with `/gerdsenai:vector-db`:

```
/gerdsenai:vector-db report my-project   # Detailed single-project report
/gerdsenai:vector-db report --all        # Cross-project overview
/gerdsenai:vector-db store <file>        # Store documents with chunking
/gerdsenai:vector-db query "search text" # Semantic search
/gerdsenai:vector-db configure           # Set backend, index, re-ranking, chunking
```

Supports dual-backend mode (ChromaDB local + Pinecone cloud simultaneously) with configurable routing (mirror, split, primary-only). Hooks auto-upsert on git commits and check health on session start. Re-ranking available via Pinecone (3 models). Each repo gets isolated collections — data is never mixed across repos.

### Ollama (Local AI Inference)

Optional local LLM inference for pre-screening and counter-argument generation. The plugin detects but never installs Ollama. Visit [ollama.com](https://ollama.com) to install.

### Extreme Research Mode

A depth tier (50-100+ pages) that uses the best of whatever your machine has:
- 5-8 sub-agents with counter-argument agents per facet
- Multi-pass verification (gap-fill, cross-validate, seek contrary evidence)
- Per-section confidence scores
- Mandatory Opus red-team review
- 20-30 target diagrams
- Ollama pre-screening if available (batched claim verification with JSON output, reduces API costs)

**Hardware requirements**: None beyond Claude Code itself. Extreme mode adapts to the runtime.

| Configuration | What It Enables |
|--------------|-----------------|
| Base (Claude Code only) | Full Extreme mode with cloud-only sub-agents and multi-pass verification |
| + ChromaDB | Context window relief for 50+ page reports |
| + Ollama (8B model, 16GB RAM) | Pre-screening, counter-argument agents, offline drafts |
| + Ollama (70B model, 32GB+ RAM) | High-quality local synthesis, reduced cloud API costs |

## Configuration

### Plugin Settings

After running `/gerdsenai:setup`, your settings are stored at `.claude/gerdsenai.local.md` with these fields:

| Setting | Description |
|---------|-------------|
| `document_builder_path` | Where the Document Builder is installed |
| `output_mode` | `same_directory`, `custom`, or `builder_pdfs` |
| `default_output_dir` | Custom output directory (when output_mode is `custom`) |
| `filename_pattern` | Template for output filenames |
| `filename_enumeration` | Auto-increment filenames |
| `cover_logo` | Override cover page logo |
| `footer_logo` | Override footer logo |
| `preferred_page_size` | A4, Letter, Legal, or A3 |
| `citation_style` | APA, MLA, Chicago, IEEE, or Harvard (default: APA) |

### Document Builder Config

The Document Builder's `config.yaml` controls PDF output styling:

- **Logos**: Cover page and footer logos (place images in `Assets/`)
- **Page**: Size (A4/Letter/Legal/A3), orientation, margins
- **Typography**: Font sizes for headings and body text
- **Colors**: Primary, accent, code background, table colors
- **Code blocks**: Per-language styling (diff, tree, shell, generic)
- **Mermaid**: Theme, viewport, fallback behavior, label length limits
- **Export**: PDF/A variant, image compression, font embedding

Use `/gerdsenai:setup` (choose "Configure settings") to edit these interactively, including a logo browser for selecting from available assets.

## Installation Methods

The setup command supports two installation methods:

1. **GitHub Release** (preferred): Downloads a self-contained tarball from the latest release. Smaller, no git history, versioned.
2. **Git Clone** (fallback): Clones the full repository. Used automatically if no release is available.

Both methods include full automated setup: venv creation, dependency installation, and Playwright/Chromium for Mermaid rendering.

## Troubleshooting

**"Document Builder is not configured"**
Run `/gerdsenai:setup` to install and configure it. Or just run any build command - it will offer to set up inline.

**"Document Builder is installed but not fully configured"**
Run `/gerdsenai:setup` and choose "Configure settings" to complete setup with output preferences and logo selection.

**Mermaid diagrams not rendering**
Playwright + Chromium must be installed. Run `/gerdsenai:setup` again, or manually:
```bash
# macOS/Linux
cd <document_builder_path> && ./venv/bin/python -m playwright install chromium

# Windows (Git Bash)
cd <document_builder_path> && ./venv/Scripts/python.exe -m playwright install chromium
```

**Build fails with no output**
Check the log files in `<document_builder_path>/Logs/` for details.

**Missing front matter**
Ensure your markdown starts with `---` delimiters containing at least a `title` field.

**Quoted strings on title page**
Run `/gerdsenai:setup` and choose "Update builder". The YAML parser was fixed in v0.2.

**No logo on cover page**
Run `/gerdsenai:setup` (choose "Configure settings") and select a valid logo from the Assets/ directory.

**Settings not being read on Windows**
The settings file may have CRLF line endings. The parser handles this automatically since v0.6.1. If using an older version, run `/gerdsenai:setup` and choose "Update builder".

**ChromaDB queries miss content from long documents**
Documents longer than ~256 tokens are silently truncated by the embedding model. Since v0.6.1, `chromadb-store.py` auto-chunks documents (500-char chunks with 100-char overlap). Re-store existing documents to benefit from chunking.

**ChromaDB returns irrelevant results**
Use `--max-distance 0.5` for stricter filtering (default: 1.0, range 0-2 for cosine distance).

## License

MIT License - see [LICENSE](LICENSE)
