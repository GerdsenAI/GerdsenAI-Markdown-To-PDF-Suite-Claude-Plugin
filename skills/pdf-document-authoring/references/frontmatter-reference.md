# Front Matter Reference

Complete YAML front matter field reference for GerdsenAI Document Builder.

## Required Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `title` | string | Document title (displayed on cover page) | `"API Documentation"` |

## Recommended Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `subtitle` | string | _(none)_ | Subtitle displayed below title on cover page |
| `author` | string | From config.yaml | Document author (shown as "Prepared by {author}") |
| `date` | string | Current date | Date displayed on cover page (format: "Month DD, YYYY") |
| `version` | string | `"1.0.0"` | Version number displayed on cover page |

## Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `company` | string | From config.yaml | Company name for attribution |
| `confidential` | boolean | `false` | Mark document as confidential |
| `watermark` | boolean | `false` | Add watermark overlay to pages |
| `subject` | string | _(none)_ | PDF metadata subject field |

## Example: Minimal

```yaml
---
title: "Project Status Report"
author: "Jane Smith"
---
```

The builder will use the current date and version `1.0.0`.

## Example: Complete

```yaml
---
title: "GerdsenAI Platform Architecture"
subtitle: "Technical Design Document"
author: "Garrett Gerdsen"
company: "GerdsenAI"
date: "February 24, 2026"
version: "2.1.0"
confidential: true
watermark: false
subject: "System architecture and design decisions"
---
```

## Behavior Notes

- If `title` is omitted, the builder extracts it from the first `# H1` heading in the document body. If no H1 is found, it defaults to "Document".
- If `date` is omitted, the builder uses the current date formatted as "Month DD, YYYY" (e.g., "February 24, 2026").
- If `author` is omitted, the default from the `default.author` field in `config.yaml` is used.
- Front matter values override `config.yaml` defaults for that document.
- The front matter parser is simple key-value: each line must be `key: value`. Nested YAML structures are not supported in front matter.
