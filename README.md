# GerdsenAI MD-to-PDF Suite - Claude Code Plugin

A Claude Code plugin for creating and building professional PDFs from Markdown using the [GerdsenAI Document Builder](https://github.com/GerdsenAI/GerdsenAI_Document_Builder).

## What It Does

- **Author PDF-ready markdown** with guidance on front matter, structure, code blocks, Mermaid diagrams, and formatting
- **Build PDFs** directly from Claude Code with styled code blocks, cover pages, table of contents, headers/footers, and page numbers
- **Flexible output** - place PDFs alongside source files, in a custom directory, or in the builder's PDFs/ folder
- **Recursive builds** - build PDFs for all markdown files in a directory tree
- **Logo selection** - browse and select cover page and footer logos from available assets
- **Configure** the Document Builder's settings (logos, page size, colors, fonts, Mermaid themes)
- **Autonomous document creation** via an agent that handles the full workflow from requirements to finished PDF
- **Guided first-run setup** - if you haven't configured the plugin, any command will offer to set it up inline

## Prerequisites

- Python 3.9+
- Git (for clone-based install) or curl (for release-based install)

## Quick Start

1. Install the plugin:
   ```
   claude install-plugin /path/to/GerdsenAI-Markdown-To-PDF-Suite-Claude-Plugin
   ```

2. Set up the Document Builder (guided setup with preferences):
   ```
   /gerdsenai-md-to-pdf-suite:setup
   ```

3. Build a PDF:
   ```
   /gerdsenai-md-to-pdf-suite:build-pdf my-document.md
   ```

## Commands

| Command | Description |
|---------|-------------|
| `/gerdsenai-md-to-pdf-suite:setup` | Install and configure the Document Builder with guided preferences |
| `/gerdsenai-md-to-pdf-suite:build-pdf <file>` | Build a single markdown file into a PDF |
| `/gerdsenai-md-to-pdf-suite:build-all` | Build all markdown files in the To_Build directory |
| `/gerdsenai-md-to-pdf-suite:build-recursive [dir]` | Build PDFs for all .md files in a directory tree |
| `/gerdsenai-md-to-pdf-suite:configure` | Edit settings: logos, page size, output preferences, colors, etc. |
| `/gerdsenai-md-to-pdf-suite:update` | Update the Document Builder to the latest version |

### Output Location Options

PDFs can be saved to different locations based on your preferences (configured during setup):

- **Same directory** as the source .md file - best for keeping PDFs with their source
- **Custom directory** - a single folder for all generated PDFs
- **Document Builder's PDFs/** folder - the legacy default

Override for a single build:
```
/gerdsenai-md-to-pdf-suite:build-pdf report.md --output-dir ~/Reports
```

### Custom Filenames

Override the output filename for a single build:
```
/gerdsenai-md-to-pdf-suite:build-pdf report.md --output-name Q4-Business-Review
```

### Recursive Builds

Build PDFs for all markdown files in the current project:
```
/gerdsenai-md-to-pdf-suite:build-recursive
```

Or specify a directory:
```
/gerdsenai-md-to-pdf-suite:build-recursive ./docs
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

## Agent: GerdsenAI Document Builder

The agent handles the full document creation workflow autonomously:

1. Checks installation (offers inline setup if not configured)
2. Gathers requirements (document type, audience, sections)
3. Authors publication-quality markdown
4. Builds the PDF with appropriate output location
5. Reports results and offers revisions

It activates on requests like "create a report", "write a document", "build a PDF", or "generate documentation".

## Configuration

### Plugin Settings

After running `/gerdsenai-md-to-pdf-suite:setup`, your settings are stored at `.claude/gerdsenai-md-to-pdf-suite.local.md` with these fields:

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

### Document Builder Config

The Document Builder's `config.yaml` controls PDF output styling:

- **Logos**: Cover page and footer logos (place images in `Assets/`)
- **Page**: Size (A4/Letter/Legal/A3), orientation, margins
- **Typography**: Font sizes for headings and body text
- **Colors**: Primary, accent, code background, table colors
- **Code blocks**: Per-language styling (diff, tree, shell, generic)
- **Mermaid**: Theme, viewport, fallback behavior, label length limits
- **Export**: PDF/A variant, image compression, font embedding

Use `/gerdsenai-md-to-pdf-suite:configure` to edit these interactively, including a logo browser for selecting from available assets.

## Installation Methods

The setup command supports two installation methods:

1. **GitHub Release** (preferred): Downloads a self-contained tarball from the latest release. Smaller, no git history, versioned.
2. **Git Clone** (fallback): Clones the full repository. Used automatically if no release is available.

Both methods include full automated setup: venv creation, dependency installation, and Playwright/Chromium for Mermaid rendering.

## Troubleshooting

**"Document Builder is not configured"**
Run `/gerdsenai-md-to-pdf-suite:setup` to install and configure it. Or just run any build command - it will offer to set up inline.

**"Document Builder is installed but not fully configured"**
Run `/gerdsenai-md-to-pdf-suite:configure` to complete setup with output preferences and logo selection.

**Mermaid diagrams not rendering**
Playwright + Chromium must be installed. Run setup again or manually:
```
cd <document_builder_path> && ./venv/bin/python -m playwright install chromium
```

**Build fails with no output**
Check the log files in `<document_builder_path>/Logs/` for details.

**Missing front matter**
Ensure your markdown starts with `---` delimiters containing at least a `title` field.

**Quoted strings on title page**
Update to the latest Document Builder version with `/gerdsenai-md-to-pdf-suite:update`. The YAML parser was fixed in v0.2.

**No logo on cover page**
Run `/gerdsenai-md-to-pdf-suite:configure` and select a valid logo from the Assets/ directory.

## License

MIT License - see [LICENSE](LICENSE)
