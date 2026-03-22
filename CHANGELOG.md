# Changelog

## 0.7.0

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
