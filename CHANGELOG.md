# Changelog

## 0.8.1

### Mermaid Rendering Fix
- **Fixed mermaid diagrams not rendering** — the Python `codehilite` markdown extension was stripping the `language-mermaid` class from fenced code blocks, preventing the Document Builder from detecting them as Mermaid diagrams. Added pre-processing in both `build.sh` (belt-and-suspenders) and the Document Builder itself to convert mermaid fenced blocks to raw HTML before codehilite runs.

### Image and Screenshot Embedding
- **Markdown image support** — the Document Builder now processes `![alt](path)` syntax, embedding images in PDFs with auto-numbered figure captions (e.g., "Figure 1: Architecture diagram"), aspect-ratio-preserving scaling, and multi-path resolution (absolute, relative to source, env var, cwd).
- **`GERDSENAI_SOURCE_DIR` env var** — `build.sh` now exports the source directory so the Document Builder can resolve relative image paths from the original markdown location.

### Enhanced Mermaid Sanitization
- Expanded edge case handling in `_sanitize_mermaid_diagram()`: emoji removal, multi-line label fixes, triple-arrow edge label cleanup, subgraph title handling, long label auto-wrapping, and arrow syntax normalization.

### Red-Team Audit Fixes (36 issues)
- **Page break enforcement** -- `page_break_avoid` config now actually enforced; headings grouped with following content via KeepTogether; CondPageBreak before h1/h2
- **Table column widths** -- replaced character-count estimation with `stringWidth()` for accurate rendered text measurement; configurable `tables:` section in config.yaml
- **HR rendering** -- horizontal rules (`---`) now render in PDFs (previously silently dropped)
- **Image hardening** -- HTML-escaped alt text, SVG/format detection, RGBA transparency handling, permission validation, URL rejection
- **Mermaid robustness** -- temp PNG cleanup, specific error messages, `html.escape()`, xychart-beta safety
- **build.sh regex** -- anchored mermaid pattern to line boundaries with `re.MULTILINE`, path validation guard
- **Nested lists** -- 5 levels of depth (up from 3), configurable bullet character
- **Public readiness** -- untracked `settings.local.json`, expanded `.gitignore`, removed client asset names

## 0.8.0

### Auto-Initialize Vector DB on Plugin Install
- **ChromaDB auto-installed** during `/gerdsenai:setup` — no longer an optional step. Users get local vector memory out of the box with zero configuration.
- **Settings auto-populated** with 12 `vector_db_*` defaults (mode: chromadb, hooks enabled, all-MiniLM-L6-v2 embedding model). No manual `/gerdsenai:vector-db configure` required.
- **Auto-repair on session start** — if the ChromaDB package goes missing after a venv rebuild, a detached background `pip install` restores it silently with platform-aware process detach (DETACHED_PROCESS on Windows, start_new_session on Unix).
- **update.sh re-ensures** ChromaDB after dependency updates (plugin dependency not in Builder's requirements.txt).

### Red-Team Audit Hardening
- **`install_chromadb_locked()` shared helper** — all 3 pip install sites (setup.sh, update.sh, session-start) now use a locked installer with a 5-minute staleness check to prevent concurrent pip races across sessions.
- **`vector_db_hook_on_session_start` wired end-to-end** — was documented in vector-db.md and vector-db-reference.md but never parsed or checked. Now parsed by `parse-settings.sh`, checked by `session-start` hook, and included in the setup template.
- **Version pinning** — `chromadb>=0.5,<1.0` and `sentence-transformers>=2.2,<4.0` in the shared helper.
- **Error capture** in update.sh pip failure (matching setup.sh pattern).
- **Dead code removed** — unreachable `|| [[ -z "$GERDSEN_VECTOR_DB_MODE" ]]` branches removed from session-start and vector-db-hooks.sh.
- **Quoting normalized** across all settings templates (vector-db.md configure template now uses quoted values matching setup.md).
- **Default values harmonized** — `max_distance: 1.0` and `default_results: 5` consistent across chromadb-store.py, vector-db.md, and vector-db-reference.md.

## 0.7.0

### Vector DB Infrastructure Overhaul
- **Dual-backend support** — run ChromaDB (local) and Pinecone (cloud) simultaneously with configurable routing (mirror, split, primary-only)
- **`scripts/pinecone-store.py`** — Python SDK wrapper mirroring chromadb-store.py interface (init, store, query, list, clear) with re-ranking support
- **`scripts/vector-db-init.py`** — unified initializer that reads settings and sets up the correct backend(s) for any context (research, sprint, redteam)
- **Configurable embedding models** — ChromaDB: all-MiniLM-L6-v2 or all-mpnet-base-v2. Pinecone: llama-text-embed-v2, multilingual-e5-large, or sparse
- **Re-ranking** — Pinecone supports pinecone-rerank-v0, bge-reranker-v2-m3, or cohere-rerank-3.5 with configurable top-N
- **Automated hooks** — PostToolUse hook auto-upserts git commit summaries, Stop hook flushes on session end, SessionStart hook checks vector DB health
- **Repo-scoped isolation** — collections/indexes named `<repo-basename>-<context>`, data from different repos NEVER mixed
- **Expanded `/gerdsenai:vector-db configure`** — full setup wizard for backend selection, embedding models, re-ranking, chunk settings, hook triggers
- **Unified Phase 0.5** — all agents (research-report, red-team-reviewer, sprint-executor) use vector-db-init.py instead of inline backend selection
- **Vector DB reference doc** — embedding model comparison, re-ranking models, metadata schema standard, dual-backend routing patterns

### Command Consolidation (11 → 6 commands)
- **`/gerdsenai:build`** — merged `build-pdf` and `build-recursive` into a single command that auto-detects file vs directory targets. Supports `--recursive`, `--output-dir`, `--output-name` flags.
- **`/gerdsenai:setup`** — merged `setup`, `configure`, and `update` into one command. Shows a menu when already installed (Configure settings / Update builder / Reinstall / Check health). Full wizard on first run.
- **`/gerdsenai:research-report`** — absorbed `monitor`, `check-freshness`, and `refresh` with context auto-detection. Passing a file with `.sources.json` triggers freshness check; without triggers monitoring registration. New reports offer monitoring after build.
- **`/gerdsenai:vector-db`** — expanded from `vector-db-report` to full vector DB management: report, store, query, and configure (index, re-ranking, embedding model, chunking). Supports Pinecone and ChromaDB.

### New Features
- **`/gerdsenai:sprint-execute`** — autonomous sprint executor using the Socratic Method (Thesis → Antithesis → Synthesis). Plans development sprints, then autocodes them to completion with ChromaDB context management, auto-commit at planned points, permission injection to `.claude/settings.local.json`, and CLAUDE.md sprint state for context compaction resilience. Supports `resume` for interrupted sprints.

### Red-Team Redesign
- **`/gerdsenai:red-team`** — completely redesigned from document-only reviewer to full adversarial analysis engine. Now covers 11 domains: code quality, security (OWASP Top 10), dependencies (CVE scanning), architecture, testing, DevOps/CI/CD, database, AI/ML, accessibility (WCAG 2.1 AA), documents, and strategic alignment. Uses Socratic reasoning chains (5 stages) and rabbit hole investigation protocol (pattern proliferation → dependency tracing → blast radius → STRIDE threat modeling). Auto-detects technology stack and activates relevant domains. Supports `--domains`, `--depth`, and `--fix` flags. ChromaDB persistence for cross-session finding continuity. Re-integrated into research-report Phase 7.5, document-builder Step 5, and sprint-executor Phase 6 with domain scoping.

### Removed Commands
- `/gerdsenai:build-pdf` → use `/gerdsenai:build`
- `/gerdsenai:build-recursive` → use `/gerdsenai:build <directory>`
- `/gerdsenai:configure` → use `/gerdsenai:setup` (choose "Configure settings")
- `/gerdsenai:update` → use `/gerdsenai:setup` (choose "Update builder")
- `/gerdsenai:monitor` → use `/gerdsenai:research-report <file>`
- `/gerdsenai:check-freshness` → use `/gerdsenai:research-report <file>`
- `/gerdsenai:refresh` → use `/gerdsenai:research-report <file>`
- `/gerdsenai:vector-db-report` → use `/gerdsenai:vector-db report`

## 0.6.1

### Bug Fixes
- **CRLF fix in shared YAML parser** — `scripts/lib/parse-settings.sh` now strips trailing `\r` from every line, fixing silent parse failures when settings files have Windows CRLF line endings. This was the root cause of all settings-related failures on Windows.
- **Tarball extraction** — `setup.sh` and `update.sh` now use `--strip-components=1` so release tarballs extract correctly (files at install root, not nested in a subdirectory).
- **pip prerequisite check** — `setup.sh` checks `python -m pip` instead of looking for a standalone `pip` binary, which may not exist on Windows or in minimal Python installs.
- **ChromaDB install path** — `commands/setup.md` now uses explicit per-platform venv Python paths instead of a template variable that could resolve incorrectly.
- **Ollama model detection** — `/gerdsenai:setup` now runs `ollama list` after detecting the binary, distinguishing between "installed but no models" and "installed with models ready".
- **Script path** — ChromaDB store invocations in the research agent now use the full `${CLAUDE_PLUGIN_ROOT}/scripts/chromadb-store.py` path instead of a bare filename.

### Improvements
- **Document chunking** — `chromadb-store.py` now auto-chunks long documents (default: 500-char chunks with 100-char overlap) so content beyond the embedding model's 256-token limit is fully searchable. Configurable via `--chunk-size` and `--chunk-overlap`.
- **Relevance filtering** — `chromadb-store.py query` now supports `--max-distance` (default: 1.0) to filter out irrelevant results by cosine distance.
- **Metadata where filter** — `chromadb-store.py query` now supports `--where '{"field":"value"}'` for metadata-based filtering.
- **Metadata validation** — nested metadata values (lists, dicts) are serialized to JSON strings instead of crashing ChromaDB.
- **Collection name normalization** — all ChromaDB commands normalize names (lowercase, strip, hyphens) for consistency.
- **Error handling** — all ChromaDB operations wrapped in try/except, always outputting JSON (never raw tracebacks).
- **Ollama pre-screen protocol** — Extreme Research mode now has a concrete specification for local LLM fact-checking: batched claims, JSON output contract, model selection, and failure handling.
- **Backend selection decision tree** — research agent Phase 0.5 now uses an explicit decision tree (Pinecone → ChromaDB → in-context) instead of prose priority list. Only one backend is ever active.
- **Prior research check** — research agent now checks for existing documents in the vector DB before starting new research, enabling cross-session knowledge reuse.
- **Ollama tool names** — tool-discovery-probes.md now marks Ollama tool names as exemplary (vary by MCP implementation) with a note to use actual returned names.

### New Features
- **Vector DB Report Generator** — new `/gerdsenai:vector-db-report` command and `scripts/chromadb-report.py` utility. Generates detailed reports on vector database contents including metadata schema analysis, sample documents, data quality metrics (duplicates, empties, completeness), and system health. Supports single-project reports, cross-project overviews, and health checks. Works with both ChromaDB and Pinecone backends.

## 0.6.0

### Architecture Fixes
- **Unified red-team architecture** — the dedicated `red-team-reviewer` agent is now dispatched via `Task` from both the research pipeline (Phase 7.5) and the document-builder agent. Previously, the review protocol was duplicated inline in three places. The reviewer agent is the single source of truth.
- **Command/agent deduplication** — `commands/research-report.md` reduced from 294 lines to a thin wrapper that delegates to `agents/research-report.md`. No more divergent copies.
- **Fixed source-tracker.py invocation** — `/gerdsenai:monitor`, `/gerdsenai:check-freshness`, and `/gerdsenai:refresh` now use the venv Python instead of system `python`, preventing failures on systems where `python` is absent or Python 2.
- **Removed `--all` dead code** — the unused `--all` handler in `build.sh` (never called by any command) has been removed.

### Infrastructure Improvements
- **Shared YAML parser** — extracted platform detection and YAML front matter parsing into `scripts/lib/parse-settings.sh`. All five bash scripts (`build.sh`, `verify-install.sh`, `session-start`, `setup.sh`, `update.sh`) now source this library instead of duplicating the parser.
- **Quiet session-start hook** — when `.claude/gerdsenai.local.md` is missing (user hasn't configured the plugin), the hook exits silently instead of printing a warning. Users discover the plugin through commands, not unsolicited alerts. Stale-source detection still fires for configured projects.

### New Capabilities
- **ChromaDB local vector storage** — `scripts/chromadb-store.py` provides local persistent vector storage as a Pinecone alternative. Uses SQLite persistence and built-in embeddings — no cloud account or API keys needed. The research pipeline discovers ChromaDB automatically and uses it when Pinecone is unavailable. Priority: Pinecone > ChromaDB > in-context.
- **Extreme Research mode** — new depth tier (50-100+ pages) that maximizes every available tool. Launches 5-8 sub-agents with counter-argument agents per facet, runs multi-pass verification (gap-fill, cross-validate, seek contrary evidence), adds per-section confidence scores, targets 20-30 diagrams, and makes red-team review mandatory. Adapts to whatever hardware is available — works on a MacBook Air or a workstation with four GPUs.
- **Ollama integration** — optional local AI inference detected via `ToolSearch("ollama")`. When available, used for pre-screening factual claims before Opus red-team review (reduces API costs) and for counter-argument agents in Extreme mode. The plugin detects but never installs Ollama. Supports NVIDIA (CUDA), AMD (ROCm), Apple Silicon (Metal), and CPU-only via Ollama's hardware abstraction.
- **Local infrastructure reference** — new `skills/pdf-document-authoring/references/local-infrastructure-reference.md` documents ChromaDB setup/usage, Ollama detection/integration, and hardware requirements by capability tier.
- **Setup enhancements** — `/gerdsenai:setup` now offers optional ChromaDB installation and detects Ollama availability.

## 0.5.0

- **Adversarial red-team review** — research reports now undergo automated adversarial quality review before PDF generation. A dialectical review step challenges factual claims, evaluates source quality (1-5 rubric), checks citation completeness, and flags logical fallacies. Challenges are assigned BLOCK/WARN/NOTE severity levels; all BLOCKs must be resolved before building. The final PDF documents the review process in its Methodology section.
- **Standalone red-team command** — `/gerdsenai:red-team <file>` runs adversarial review against any markdown file, not just research reports. Presents structured findings and offers to help fix challenges.
- **Living Intelligence Reports** — reports are no longer static. `/gerdsenai:monitor` registers a report for source tracking, extracting all cited URLs and computing content hashes. `/gerdsenai:check-freshness` detects which sources have changed. `/gerdsenai:refresh` re-researches only affected sections and rebuilds the PDF with a Revision History.
- **Source tracker utility** — `scripts/source-tracker.py` provides extract, check, update, and list-stale commands for managing `.sources.json` manifests alongside monitored reports.
- **Session-start stale source alerts** — the session-start hook now detects monitored reports with changed sources and alerts the user on session start.
- **Red-team quality gate metrics** — research reports track claims revised, sources added, assertions removed, and average source quality score during adversarial review.

## 0.4.0

- **Windows compatibility** — all scripts and the session-start hook now detect the platform via `$OSTYPE` and use the correct Python command (`python` vs `python3`) and venv path (`venv/Scripts/python.exe` vs `venv/bin/python`). Absolute path checks also recognize Windows drive letters.
- **Default install path** changed to `~/.gerdsenai/document-builder` (hidden directory, keeps home folder clean)
- **Migration detection** in `setup.sh` — warns if old install exists at `~/GerdsenAI_Document_Builder` when installing to the new default
- **Research agent tool discovery** overhauled — now discovers sequential-thinking, Pinecone, Hugging Face paper search, context7 library docs, and greptile codebase search alongside existing firecrawl/brave/WebSearch
- **Pinecone Research Memory** — repo-scoped persistent storage for research findings, reducing context window pressure on long reports and enabling cross-session knowledge retrieval
- **Enhanced sub-agent prompting** — sub-agents receive full tool manifests with capabilities, facet-specific recommendations, fallback chains, and sequential thinking instructions
- **Blueprint sub-agent table** now includes a Recommended Tools column per research facet
- **Sequential thinking** integrated into deep-dive analysis (Phase 5) and synthesis (Phase 6) for structured conflict resolution
- **Document Builder release workflow** updated to trigger on merge to main with auto-versioning (`YYYY.MM.DD-<sha>`)

## 0.3.0

- **Deep research intelligence reports** — new `/gerdsenai:research-report` command and agent for multi-source research with parallel sub-agents, Mermaid visualizations, and academic citations
- **Software Architecture Blueprint** mode for research reports — developer-ready technical documents with tech stack comparisons, database schema, API design, infrastructure planning, and implementation roadmap
- **Citation styles** — APA, MLA, Chicago, IEEE, Harvard (configurable via `/gerdsenai:configure`)
- **Marketplace support** — `marketplace.json` for `/plugin` UI installation
- All 17 Mermaid diagram types supported with proactive creation guidance
- Plugin renamed to `/gerdsenai:<command>` namespace

## 0.2.0

- **Flexible output locations** — save PDFs alongside source, in a custom directory, or in the builder's PDFs/ folder
- **Recursive builds** — `/gerdsenai:build-recursive` for building all .md files in a directory tree
- **Guided setup** — `/gerdsenai:setup` with interactive preferences (output mode, logos, page size)
- **Logo selection** — browse and select cover page and footer logos from Assets/
- **Session-start hook** — warns if plugin is not configured

## 0.1.0

- Initial release
- PDF building from markdown via `/gerdsenai:build-pdf`
- PDF document authoring skill with front matter, heading hierarchy, code blocks, and Mermaid diagram guidance
- Document Builder agent for autonomous requirements-to-PDF workflow
