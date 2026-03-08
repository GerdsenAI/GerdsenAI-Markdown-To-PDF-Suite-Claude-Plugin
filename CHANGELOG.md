# Changelog

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
