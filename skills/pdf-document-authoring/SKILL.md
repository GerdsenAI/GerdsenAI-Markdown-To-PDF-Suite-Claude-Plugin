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

## Assessment and Maturity Sections

When writing assessment or maturity ratings for components, technologies, or features, use proper headings for scannability and TOC inclusion.

**WRONG** (hard to scan, no TOC entry):
```markdown
**Maturity: Solid.** The math is correct. DAS is production-ready.
```

**RIGHT** (scannable, appears in TOC):
```markdown
#### Beamforming: Solid (Production-Ready)
The math is correct. DAS is production-ready; MVDR and MUSIC are research-grade.
```

Rules for assessment sections:
- Use `#### H4` or `##### H5` headings for each assessed item
- Include the rating or status in the heading text for quick scanning
- Follow the heading with explanation paragraphs
- Group related assessments under a common `### H3` parent section
- Use consistent rating terminology across the document (e.g., "Production-Ready", "Beta", "Research-Grade", "Not Started")

## Code Blocks

Use fenced code blocks with language identifiers for styled output. The builder applies distinct styling per language:

- **`diff`** - Dark background with green (added), red (removed), blue (hunk headers)
- **`tree`** - Dark background with blue tree characters, yellow directories, gray files
- **`shell` / `bash`** - Black terminal background with green prompt/commands
- **`python`**, **`yaml`**, **`json`**, **`javascript`** - Light background with syntax highlighting (GitHub theme by default)

Always specify the language. A bare ` ``` ` block gets generic styling with no highlighting.

## Mermaid Diagrams

Mermaid diagrams are rendered locally via Playwright + Chromium. Wrap diagrams in ` ```mermaid ` fences. Standalone `.mermaid` and `.mmd` files can also be built directly to PDF.

### Proactive Diagram Creation

**Include diagrams without being asked** when the content benefits from visual representation. If you are describing a process, architecture, data model, timeline, comparison, or flow, create the appropriate diagram. Do NOT ask the user if they want a diagram — just include it where it adds clarity.

When conducting research or writing reports, proactively create diagrams for:
- System architectures and component relationships (flowchart, C4, block)
- API or service interaction flows (sequence)
- Database schemas and data models (ER, class)
- Project plans and roadmaps (gantt, timeline)
- Decision frameworks and prioritization (quadrant)
- User experience and satisfaction analysis (journey)
- Proportional breakdowns and metrics (pie, XY chart)
- Concept exploration and brainstorming (mindmap)
- Status and lifecycle modeling (state)
- Resource allocation and data flows (sankey)
- Requirements traceability (requirement)
- Branching and release strategies (git graph)

### Supported Types (17)

| Type | Keyword | Best For |
|------|---------|----------|
| Flowchart | `flowchart TD` | Processes, decisions, workflows |
| Sequence | `sequenceDiagram` | API flows, system interactions |
| State | `stateDiagram-v2` | Lifecycles, status transitions |
| Class | `classDiagram` | OOP design, type hierarchies |
| ER | `erDiagram` | Database schemas, data models |
| Gantt | `gantt` | Project schedules, sprint plans |
| Pie | `pie` | Proportional breakdowns |
| Git Graph | `gitGraph` | Branching strategies |
| Mindmap | `mindmap` | Brainstorming, concept maps |
| Timeline | `timeline` | Roadmaps, milestones |
| Journey | `journey` | UX flows, satisfaction mapping |
| Quadrant | `quadrantChart` | Prioritization, 2-axis comparison |
| C4 Context | `C4Context` | High-level system architecture |
| XY Chart | `xychart` | Line/bar charts, metrics |
| Requirement | `requirementDiagram` | Requirements traceability |
| Sankey | `sankey` | Resource/data flow volumes |
| Block | `block-beta` | Component layouts, hardware |

### Rules
- Keep node labels under 80 characters (configurable via `max_label_length` in config.yaml)
- Avoid special characters in labels: `"`, `<`, `>`, `{`, `}` - use parentheses or brackets instead
- For long labels, use `<br>` for line breaks within nodes
- Do NOT use `%%{init:...}%%` theme directives — theming is handled by config.yaml
- If a diagram fails to render, the builder falls back to showing it as a code block (configurable)

See `references/mermaid-diagrams.md` for complete syntax templates and choosing the right diagram type.
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

Use these commands to build PDFs:

- `/gerdsenai:build <file>` - Build a single file into a PDF
- `/gerdsenai:build --recursive [dir]` - Build all .md files in a directory tree (PDFs placed alongside source files)

### Output Location

PDFs can be saved to different locations based on your settings:
- **Same directory** as the source .md file (default for single builds)
- **Custom directory** configured during setup
- **Document Builder's PDFs/** folder (legacy behavior)

Override for a single build: `/gerdsenai:build file.md --output-dir /path/to/dir`

### Custom Filenames

Override the output filename: `/gerdsenai:build file.md --output-name MyReport`

### Logo Selection

Cover and footer logos are configured via `/gerdsenai:setup` (choose "Configure settings"). The setup command lets you browse available logos in the Assets/ directory and add new ones.

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
- [ ] Assessment/maturity sections use proper headings, not inline bold text

See `references/config-options.md` for all `config.yaml` options.
