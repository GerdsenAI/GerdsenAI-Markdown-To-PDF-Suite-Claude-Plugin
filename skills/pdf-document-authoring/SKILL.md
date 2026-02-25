---
name: pdf-document-authoring
description: "This skill should be used when the user asks to create a PDF, write a report, build a professional document, generate formatted documentation, author a technical spec for PDF output, or mentions GerdsenAI Document Builder. Covers trigger phrases like 'make me a PDF', 'write a report', 'create a document', 'format this for PDF', 'build a PDF from markdown', and 'generate a formatted report'. Provides rules for YAML front matter, heading hierarchy, code blocks, Mermaid diagrams, tables, and page layout."
---

# PDF Document Authoring

Follow these rules when writing markdown intended for the GerdsenAI Document Builder.

## Document Structure

Every document MUST begin with YAML front matter enclosed in `---` delimiters. The first `#` heading becomes the document title if `title` is not set in front matter.

Use heading hierarchy strictly:
- `# H1` - Document title only (one per document, on the cover page)
- `## H2` - Major sections (appear in Table of Contents)
- `### H3` - Subsections (appear in Table of Contents)
- `#### H4` - Minor subsections

Do NOT skip heading levels (e.g., jumping from H2 to H4).

## Front Matter

Required fields:
```yaml
---
title: "Document Title"
subtitle: "Optional Subtitle"
author: "Author Name"
date: "January 15, 2026"  # Always use the current date
version: "1.0.0"
---
```

Optional fields:
- `confidential: true` - Marks document as confidential
- `watermark: true` - Adds watermark overlay
- `company: "Company Name"` - Company attribution
- `subject: "Subject line"` - PDF metadata subject field

If `title` is omitted, the builder extracts it from the first `# H1` heading. If `date` is omitted, the current date is used. If `author` is omitted, the default from `config.yaml` is used.

See `references/frontmatter-reference.md` for complete field documentation.

## Code Blocks

Use fenced code blocks with language identifiers for styled output. The builder applies distinct styling per language:

- **`diff`** - Dark background with green (added), red (removed), blue (hunk headers)
- **`tree`** - Dark background with blue tree characters, yellow directories, gray files
- **`shell` / `bash`** - Black terminal background with green prompt/commands
- **`python`**, **`yaml`**, **`json`**, **`javascript`** - Light background with syntax highlighting (GitHub theme by default)

Always specify the language. A bare ` ``` ` block gets generic styling with no highlighting.

## Mermaid Diagrams

Mermaid diagrams are rendered locally via Playwright + Chromium. Wrap diagrams in ` ```mermaid ` fences.

Supported types: flowchart, sequence, class, state, gantt, pie, er, journey, gitgraph, mindmap, timeline.

Rules:
- Keep node labels under 80 characters (configurable via `max_label_length` in config.yaml)
- Avoid special characters in labels: `"`, `<`, `>`, `{`, `}` - use parentheses or brackets instead
- For long labels, use `<br>` for line breaks within nodes
- If a diagram fails to render, the builder falls back to showing it as a code block (configurable)

Example flowchart (place inside a `mermaid` fenced code block):

    ```mermaid
    flowchart TD
        A[Start] --> B{Decision}
        B -->|Yes| C[Action One]
        B -->|No| D[Action Two]
        C --> E[End]
        D --> E
    ```

See `references/formatting-guide.md` for examples of each diagram type.

## Tables

Use standard markdown tables. Keep columns reasonable in width - the builder flows text within cells.

```markdown
| Column A | Column B | Column C |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |
```

- Table headers get a light gray background (`#f6f8fa` by default)
- Borders are light gray (`#e1e4e8` by default)
- Tables avoid page breaks when possible

## Lists

Both ordered and unordered lists are supported with nesting:

```markdown
- Item one
  - Nested item
    - Deeply nested
1. First step
2. Second step
   1. Sub-step
```

## Images

Include images with standard markdown syntax. Images should be placed in the Document Builder's `Assets/` directory or referenced by absolute path.

```markdown
![Alt text](Assets/image.png)
```

The builder scales images to fit within page margins while preserving aspect ratio.

## Page Breaks

Force a page break with an HTML comment:

```markdown
<!-- pagebreak -->
```

Or use a horizontal rule as a visual section separator (does not force a page break):

```markdown
---
```

## Building

Save markdown files to the Document Builder's `To_Build/` directory, or use `/gerdsenai-md-to-pdf-suite:build-pdf` which copies the file there automatically.

- `/gerdsenai-md-to-pdf-suite:build-pdf <file>` - Build a single file into a PDF
- `/gerdsenai-md-to-pdf-suite:build-all` - Build all files in `To_Build/`

Generated PDFs appear in the `PDFs/` directory. Build logs are in `Logs/`.

## Quality Checklist

Before building, verify:
- [ ] Front matter has `title`, `author`, and `date`
- [ ] Only one `# H1` heading (used as cover page title)
- [ ] Heading hierarchy is sequential (no skipped levels)
- [ ] All code blocks have language identifiers
- [ ] Mermaid diagrams use supported syntax with short labels
- [ ] Images reference valid paths
- [ ] Tables have header rows
- [ ] No unclosed front matter delimiters (`---`)

See `references/config-options.md` for all `config.yaml` options.
