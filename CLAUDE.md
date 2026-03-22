# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code plugin** (not a standalone app) that converts Markdown to professional PDFs. It wraps the external [GerdsenAI Document Builder](https://github.com/GerdsenAI/GerdsenAI_Document_Builder) Python tool, providing commands, a skill, an agent, and shell scripts that Claude Code uses to author and build PDFs.

The plugin is installed into Claude Code via `claude --plugin-dir <path>` and exposes slash commands prefixed with `/gerdsenai:`.

## Architecture

```
.claude-plugin/plugin.json   ← Plugin manifest (name, version, metadata)
commands/                     ← Slash command definitions (6 commands)
  setup.md                    ← /setup - install, configure, or update Document Builder
  build.md                    ← /build - build single file or recursive directory
  research-report.md          ← /research-report - deep research + source monitoring
  red-team.md                 ← /red-team - adversarial analysis (code, security, docs, 11 domains)
  vector-db.md                ← /vector-db - report, store, query, configure (dual-backend)
  sprint-execute.md           ← /sprint-execute - autonomous sprint planning + autocoding
scripts/                      ← Shell scripts executed by commands
  setup.sh                    ← Downloads/clones builder, creates venv, installs deps
  build.sh                    ← Core build logic (single + recursive modes)
  update.sh                   ← Updates builder via git pull or release download
  verify-install.sh           ← Outputs JSON status of installation health
  chromadb-store.py           ← ChromaDB vector storage (init, store, query, list, clear)
  pinecone-store.py           ← Pinecone SDK wrapper (init, store, query, list, clear)
  vector-db-init.py           ← Unified vector DB initializer (reads settings, sets up backends)
  chromadb-report.py          ← ChromaDB reporting (report, health)
  source-tracker.py           ← Source monitoring (extract, check, update, list-stale)
  lib/
    parse-settings.sh         ← Shared library: platform detection + YAML parser
hooks/
  hooks.json                  ← SessionStart, PostToolUse, Stop hook registration
  vector-db-hooks.sh          ← Vector DB automation (commit upsert, session flush)
  session-start               ← Checks install status, silently exits if not configured
agents/
  gerdsenai-document-builder.md  ← Autonomous agent: requirements → authoring → PDF
  research-report.md          ← Research intelligence agent (8-phase workflow)
  red-team-reviewer.md        ← Adversarial quality review agent
  sprint-executor.md          ← Autonomous sprint execution agent (Socratic planning)
skills/
  pdf-document-authoring/
    SKILL.md                  ← Authoring rules (front matter, headings, Mermaid, etc.)
    references/               ← Config, formatting, front matter, Mermaid, red-team, research, architecture, vector-db
  using-superpowers/
    SKILL.md                  ← Tool discovery and orchestration meta-skill
    references/               ← Tool discovery probes, orchestration examples
```

### How It Works

1. **Commands** are markdown files that define the prompt and allowed tools for each slash command. They reference `${CLAUDE_PLUGIN_ROOT}/scripts/` to run shell scripts.
2. **Scripts** do the actual work: `build.sh` copies the markdown to the builder's `To_Build/` dir, runs `document_builder_reportlab.py` via the venv Python, then copies the output PDF to the configured location.
3. **Settings** are stored per-project at `.claude/gerdsenai.local.md` (YAML front matter with `document_builder_path`, `output_mode`, logos, page size, vector DB config). This file is gitignored.
4. **Agents** handle autonomous workflows: document creation, research reports, adversarial red-team review (11 domains), and sprint execution (Socratic autocoder).
5. **The skill** activates when authoring PDF-targeted markdown, providing rules for front matter, heading hierarchy, Mermaid diagrams, code blocks, and quality checks.
6. **Hooks** run on session start (health check + vector DB status), after Bash tool use (auto-upsert git commits to vector DB), and on session end (flush pending vector DB operations).
7. **Vector DB** supports dual-backend mode (ChromaDB local + Pinecone cloud simultaneously). Collections are repo-scoped (`<repo-basename>-<context>`). Configured via `/gerdsenai:vector-db configure`.

### Settings YAML Front Matter Format

The settings file (`.claude/gerdsenai.local.md`) uses YAML front matter parsed by bash regex in all scripts. The parser is line-by-line `key: value` — no nested structures. Key fields: `document_builder_path`, `output_mode` (`same_directory`|`custom`|`builder_pdfs`), `default_output_dir`, `cover_logo`, `footer_logo`, `preferred_page_size`, plus `vector_db_*` fields for backend config (mode, embedding models, chunking, re-ranking, hooks).

### Build Script Output

`scripts/build.sh` outputs JSON on success/failure:
- `{"success": true, "pdf_path": "...", "builder_pdf_path": "...", "size_bytes": N}`
- `{"success": false, "error": "...", "log": "..."}`

## Development

There is no build step, test suite, or linter for this plugin. The codebase is markdown prompts and bash scripts.

To test changes locally, install the plugin from the local directory:
```
claude --plugin-dir /path/to/this/repo
```

Then run commands in any project to verify behavior. The `session-start` hook fires automatically on new sessions.

### Script Testing

Test scripts directly:
```bash
bash scripts/verify-install.sh              # Check installation status (JSON output)
bash scripts/build.sh <settings> <file.md>  # Build a single PDF
bash scripts/setup.sh ~/TestBuilder         # Test fresh install
```

## Key Conventions

- All scripts use `set -euo pipefail` and expand `~` via `${VAR/#\~/$HOME}`.
- Scripts parse settings by reading YAML front matter line-by-line with bash regex (`^key:[[:space:]]*"?([^"]*)"?`). Do not introduce nested YAML or multi-line values in settings.
- Build output location is determined by `output_mode` in settings, overridable per-build with `--output-dir`.
- The `build.sh` `--recursive` mode auto-excludes `node_modules/`, `.git/`, `venv/`, `__pycache__/`, `.claude/`, and common non-document markdown files (README.md, CLAUDE.md, CHANGELOG.md, LICENSE.md).
- Commands specify `allowed-tools` in their front matter to restrict which tools Claude Code can use during that command.
- The document-builder agent uses `model: sonnet` for cost efficiency. The sprint-executor agent runs on the default model (requires maximum intelligence).
- Vector DB collections are named `<repo-basename>-<context>` (e.g., `my-app-research`, `my-app-sprint`, `my-app-redteam`). All agents use `scripts/vector-db-init.py` for unified backend initialization.
- Vector DB hooks (PostToolUse, Stop) auto-upsert git commits and flush on session end. Configured via `vector_db_hook_*` settings.
