---
description: "Configure Document Builder settings: logos, page size, fonts, and more"
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, Glob
---

You are helping the user configure the GerdsenAI Document Builder's `config.yaml`.

## Steps

1. Read `.claude/gerdsenai-md-to-pdf-suite.local.md` to get `document_builder_path`. If not configured, tell the user to run `/gerdsenai-md-to-pdf-suite:setup` first.

2. Read the current `config.yaml` from `<document_builder_path>/config.yaml`.

3. Present the current configuration to the user in a readable summary, organized by section:
   - **Default metadata**: author, company, version, confidential, watermark, filename_prefix
   - **Logos**: cover logo, footer logo (list available images in `<document_builder_path>/Assets/`)
   - **Page**: size (A4/Letter/Legal/A3), orientation
   - **Margins**: top, right, bottom, left (in mm)
   - **Header/Footer**: height, show_title, show_page_numbers, show_logo, show_date
   - **Typography**: font families, sizes, line height
   - **Colors**: primary, secondary, accent, code_background, link, table colors
   - **Syntax highlighting**: enabled, theme (github/monokai/dracula/tomorrow), line numbers
   - **Code blocks**: diff, treeview, shell, generic color schemes
   - **Mermaid**: enabled, theme, viewport, max width, error handling
   - **Export**: optimize_size, PDF variant, compress images, embed fonts

4. Ask the user what they want to change. Use AskUserQuestion for common choices.

5. For logo changes: list available images in `<document_builder_path>/Assets/` and let the user pick. They can also specify a path to a new image to copy into Assets.

6. Apply changes by editing the `config.yaml` file directly using the Edit tool.

7. After making changes, offer to do a test build to verify the configuration works.
