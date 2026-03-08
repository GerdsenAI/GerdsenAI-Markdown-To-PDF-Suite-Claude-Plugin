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

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- Python 3.9+
- **Windows:** Git for Windows (provides Git Bash, which all scripts run under)

## Install

Inside a Claude Code session, run these two commands:

```
/plugin marketplace add GerdsenAI/GerdsenAI-Markdown-To-PDF-Suite-Claude-Plugin
/plugin install gerdsenai@gerdsenai-marketplace
```

Restart Claude Code, then run `/gerdsenai:setup` inside any project to install the Document Builder and configure your preferences.

> **Local development:** `claude --plugin-dir /path/to/this/repo`

## Quick Start

1. Set up the Document Builder (guided setup with preferences):
   ```
   /gerdsenai:setup
   ```

2. Build a PDF:
   ```
   /gerdsenai:build-pdf my-document.md
   ```

3. Research a topic and generate an intelligence report:
   ```
   /gerdsenai:research-report AI chip market landscape
   ```

## Commands

| Command | Description |
|---------|-------------|
| `/gerdsenai:setup` | Install and configure the Document Builder with guided preferences |
| `/gerdsenai:build-pdf <file>` | Build a single markdown file into a PDF |
| `/gerdsenai:build-recursive [dir]` | Build PDFs for all .md files in a directory tree |
| `/gerdsenai:research-report [topic]` | Conduct deep research and generate an intelligence report as PDF |
| `/gerdsenai:red-team <file>` | Run adversarial review: challenge claims, verify citations, flag logical fallacies |
| `/gerdsenai:monitor <file>` | Register a report for source monitoring (creates `.sources.json` manifest) |
| `/gerdsenai:check-freshness [file]` | Check if monitored sources have changed since last check |
| `/gerdsenai:refresh <file>` | Re-research stale sections and rebuild the PDF with revision history |
| `/gerdsenai:configure` | Edit settings: logos, page size, output preferences, citation style, etc. |
| `/gerdsenai:update` | Update the Document Builder to the latest version |

### Output Location Options

PDFs can be saved to different locations based on your preferences (configured during setup):

- **Same directory** as the source .md file - best for keeping PDFs with their source
- **Custom directory** - a single folder for all generated PDFs
- **Document Builder's PDFs/** folder - the legacy default

Override for a single build:
```
/gerdsenai:build-pdf report.md --output-dir ~/Reports
```

### Custom Filenames

Override the output filename for a single build:
```
/gerdsenai:build-pdf report.md --output-name Q4-Business-Review
```

### Recursive Builds

Build PDFs for all markdown files in the current project:
```
/gerdsenai:build-recursive
```

Or specify a directory:
```
/gerdsenai:build-recursive ./docs
```

Automatically excludes `node_modules/`, `.git/`, `venv/`, `__pycache__/`, `.claude/`, and common non-document files (README.md, CLAUDE.md, etc.).

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

**Report types:** Executive Brief (5-10 pages), Standard Report (15-30 pages), Deep-Dive Technical (30-50+ pages), Academic White Paper.

**Citation styles:** APA (default), MLA, Chicago, IEEE, Harvard. Configured via `/gerdsenai:configure`.

### Adversarial Quality Review

Research reports undergo automated adversarial review before PDF generation. The red-team step challenges every factual claim, evaluates source quality against a 1-5 rubric, checks citation completeness, and flags logical fallacies. Claims are assigned severity levels:

- **BLOCK** -- demonstrably false claims, broken citations, logical contradictions. Must be resolved before building.
- **WARN** -- weakly supported claims, single-source assertions, language stronger than evidence warrants.
- **NOTE** -- informational observations for quality improvement.

All BLOCK challenges are resolved automatically. The final PDF includes an "Adversarial Quality Review" subsection in the Methodology section documenting the review process.

Run `/gerdsenai:red-team <file>` to review any markdown file standalone, not just research reports.

### Living Intelligence Reports

Research reports are not static. After building a report, register it for source monitoring:

```
/gerdsenai:monitor my-report.md          # Extract source URLs, compute content hashes
/gerdsenai:check-freshness my-report.md  # Check if any sources have changed
/gerdsenai:refresh my-report.md          # Re-research stale sections, rebuild PDF
```

The session-start hook automatically alerts you when monitored reports have stale sources. The refresh command updates only affected sections, adds a Revision History, and rebuilds the PDF.

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

Use `/gerdsenai:configure` to edit these interactively, including a logo browser for selecting from available assets.

## Installation Methods

The setup command supports two installation methods:

1. **GitHub Release** (preferred): Downloads a self-contained tarball from the latest release. Smaller, no git history, versioned.
2. **Git Clone** (fallback): Clones the full repository. Used automatically if no release is available.

Both methods include full automated setup: venv creation, dependency installation, and Playwright/Chromium for Mermaid rendering.

## Troubleshooting

**"Document Builder is not configured"**
Run `/gerdsenai:setup` to install and configure it. Or just run any build command - it will offer to set up inline.

**"Document Builder is installed but not fully configured"**
Run `/gerdsenai:configure` to complete setup with output preferences and logo selection.

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
Update to the latest Document Builder version with `/gerdsenai:update`. The YAML parser was fixed in v0.2.

**No logo on cover page**
Run `/gerdsenai:configure` and select a valid logo from the Assets/ directory.

## License

MIT License - see [LICENSE](LICENSE)
