---
description: "Configure Document Builder settings: logos, page size, fonts, output preferences, and more"
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, Glob
---

You are helping the user configure the GerdsenAI Document Builder.

## Steps

1. **First-run check**: Read `.claude/gerdsenai.local.md` to get `document_builder_path`. If not configured:
   - Offer to run setup inline: "The Document Builder isn't configured yet. Want me to set it up now?"
   - If yes, follow the setup workflow, then continue

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
   - **Research**: citation style (read from `.claude/gerdsenai.local.md`, default: APA)

4. Ask the user what they want to change. Use AskUserQuestion for common choices.

5. **Logo browser**: When changing logos:
   - List all image files in `<document_builder_path>/Assets/` using Glob with patterns `*.png`, `*.jpg`, `*.jpeg`, `*.svg`
   - Show current cover logo and footer logo selections
   - Let the user pick from available logos or "none"
   - **Add new logo**: If the user wants to add a new logo file:
     - Ask for the source file path
     - Copy the file to `<document_builder_path>/Assets/`
     - Then let them select it

6. **Output preferences**: If the user wants to change output settings, update `.claude/gerdsenai.local.md`:
   - Output mode (same_directory / custom / builder_pdfs)
   - Default output directory
   - Filename pattern
   - Cover and footer logo overrides

7. **Research settings**: Show and allow editing of research-related preferences in `.claude/gerdsenai.local.md`:
   - **Citation style**: APA (default) / MLA / Chicago / IEEE / Harvard
   - When changing citation style, offer the 5 options via AskUserQuestion
   - Update `.claude/gerdsenai.local.md` with `citation_style: "<style>"`

8. Apply config.yaml changes by editing the file directly using the Edit tool.

9. Apply settings changes by updating `.claude/gerdsenai.local.md`.

10. After making changes, offer to do a test build to verify the configuration works.
