# GerdsenAI MD-to-PDF Suite - Claude Code Plugin

A Claude Code plugin for creating and building professional PDFs from Markdown using the [GerdsenAI Document Builder](https://github.com/GerdsenAI/GerdsenAI_Document_Builder).

## What It Does

- **Author PDF-ready markdown** with guidance on front matter, structure, code blocks, Mermaid diagrams, and formatting
- **Build PDFs** directly from Claude Code with styled code blocks, cover pages, table of contents, headers/footers, and page numbers
- **Configure** the Document Builder's settings (logos, page size, colors, fonts, Mermaid themes)
- **Autonomous document creation** via an agent that handles the full workflow from requirements to finished PDF

## Prerequisites

- Python 3.9+
- Git

## Quick Start

1. Install the plugin:
   ```
   claude install-plugin /path/to/GerdsenAI-Markdown-To-PDF-Suite-Claude-Plugin
   ```

2. Set up the Document Builder:
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
| `/gerdsenai-md-to-pdf-suite:setup` | Install and configure the Document Builder |
| `/gerdsenai-md-to-pdf-suite:build-pdf <file>` | Build a single markdown file into a PDF |
| `/gerdsenai-md-to-pdf-suite:build-all` | Build all markdown files in the To_Build directory |
| `/gerdsenai-md-to-pdf-suite:configure` | Edit Document Builder settings (logos, page size, colors, etc.) |
| `/gerdsenai-md-to-pdf-suite:update` | Update the Document Builder to the latest version |

## Skill: PDF Document Authoring

The `pdf-document-authoring` skill activates when you're writing markdown intended for PDF output. It guides you on:

- YAML front matter fields (title, subtitle, author, date, version, confidential, watermark)
- Document structure and heading hierarchy
- Code block language identifiers for styled output (diff, tree, shell, python, yaml, etc.)
- Mermaid diagram syntax and best practices
- Table and image formatting
- Quality checklist before building

## Agent: GerdsenAI Document Builder

The agent handles the full document creation workflow autonomously:

1. Gathers requirements (document type, audience, sections)
2. Authors publication-quality markdown
3. Builds the PDF
4. Reports results and offers revisions

It activates on requests like "create a report", "write a document", "build a PDF", or "generate documentation".

## Configuration

After running `/gerdsenai-md-to-pdf-suite:setup`, your settings are stored at `.claude/gerdsenai-md-to-pdf-suite.local.md`. The Document Builder's own `config.yaml` controls PDF output:

- **Logos**: Cover page and footer logos (place images in `Assets/`)
- **Page**: Size (A4/Letter/Legal/A3), orientation, margins
- **Typography**: Font sizes for headings and body text
- **Colors**: Primary, accent, code background, table colors
- **Code blocks**: Per-language styling (diff, tree, shell, generic)
- **Mermaid**: Theme, viewport, fallback behavior, label length limits
- **Export**: PDF/A variant, image compression, font embedding

Use `/gerdsenai-md-to-pdf-suite:configure` to edit these interactively.

## Troubleshooting

**"Document Builder is not configured"**
Run `/gerdsenai-md-to-pdf-suite:setup` to install and configure it.

**Mermaid diagrams not rendering**
Playwright + Chromium must be installed. Run setup again or manually:
```
cd <document_builder_path> && ./venv/bin/python -m playwright install chromium
```

**Build fails with no output**
Check the log files in `<document_builder_path>/Logs/` for details.

**Missing front matter**
Ensure your markdown starts with `---` delimiters containing at least a `title` field.

## License

MIT License - see [LICENSE](LICENSE)
