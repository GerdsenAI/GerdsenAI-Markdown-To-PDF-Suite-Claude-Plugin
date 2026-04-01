# Config Options Reference

Complete reference for `config.yaml` in the GerdsenAI Document Builder.

Edit this file directly or use `/gerdsenai:setup` (choose "Configure settings").

## default

Default metadata applied to documents without front matter overrides.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `author` | string | `"Author"` | Default author name |
| `company` | string | `"GerdsenAI"` | Default company name |
| `version` | string | `"1.0.0"` | Default version number |
| `confidential` | boolean | `false` | Mark documents as confidential |
| `watermark` | boolean | `false` | Add watermark overlay |
| `filename_prefix` | string | `"GerdsenAI_"` | Prefix for generated PDF filenames |

## logos

Logo images relative to the `Assets/` directory.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `cover` | string | _(varies)_ | Logo displayed on cover page |
| `footer` | string | _(varies)_ | Logo displayed in page footer |

Supported formats: PNG, JPG, JPEG, SVG.

## page

| Key | Type | Default | Options |
|-----|------|---------|---------|
| `size` | string | `"A4"` | `A4`, `Letter`, `Legal`, `A3` |
| `orientation` | string | `"portrait"` | `portrait`, `landscape` |

## margins

All values in millimeters.

| Key | Type | Default |
|-----|------|---------|
| `top` | integer | `25` |
| `right` | integer | `20` |
| `bottom` | integer | `25` |
| `left` | integer | `20` |

## header

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `height` | integer | `15` | Header height in mm |
| `show_title` | boolean | `true` | Show document title in header |
| `show_section` | boolean | `false` | Show current section in header |

## footer

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `height` | integer | `15` | Footer height in mm |
| `show_page_numbers` | boolean | `true` | Show page numbers |
| `show_logo` | boolean | `true` | Show footer logo |
| `show_date` | boolean | `false` | Show date in footer |

## fonts

### fonts.body

| Key | Type | Default |
|-----|------|---------|
| `family` | string | `"SF Pro Rounded"` |
| `size` | integer | `11` |
| `line_height` | float | `1.6` |

Note: The builder currently uses ReportLab's built-in Helvetica as the body font regardless of this setting. This field is reserved for future custom font support.

### fonts.heading1 / heading2 / heading3

| Key | Type | H1 Default | H2 Default | H3 Default |
|-----|------|-----------|-----------|-----------|
| `size` | integer | `24` | `18` | `14` |
| `weight` | integer | `700` | `600` | `600` |

### fonts.code

| Key | Type | Default |
|-----|------|---------|
| `family` | string | `"SF Mono"` |
| `size` | float | `9.5` |

Note: The builder currently uses ReportLab's built-in Courier for code. This field is reserved for future custom font support.

## colors

All values are hex color strings.

| Key | Default | Description |
|-----|---------|-------------|
| `primary` | `"#1a1a1a"` | Primary text color |
| `secondary` | `"#2c3e50"` | Secondary text color |
| `accent` | `"#3498db"` | Accent/link color |
| `code_background` | `"#f6f8fa"` | Generic code block background |
| `code_text` | `"#24292e"` | Generic code block text |
| `link` | `"#3498db"` | Hyperlink color |
| `table_header` | `"#f6f8fa"` | Table header background |
| `table_border` | `"#e1e4e8"` | Table border color |

## syntax_highlighting

| Key | Type | Default | Options |
|-----|------|---------|---------|
| `enabled` | boolean | `true` | |
| `theme` | string | `"github"` | `github`, `monokai`, `dracula`, `tomorrow` |
| `line_numbers` | boolean | `false` | |

## code_blocks

Per-language styling for fenced code blocks. Each has `background`, `border_color`, and language-specific text colors.

### code_blocks.diff

| Key | Default | Description |
|-----|---------|-------------|
| `background` | `"#1e1e2e"` | Dark background |
| `added` | `"#a6e3a1"` | Green for added lines |
| `removed` | `"#f38ba8"` | Red for removed lines |
| `context` | `"#cdd6f4"` | Gray for context lines |
| `hunk_header` | `"#89b4fa"` | Blue for `@@` headers |
| `border_color` | `"#89b4fa"` | Border accent |

### code_blocks.treeview

| Key | Default | Description |
|-----|---------|-------------|
| `background` | `"#1e1e2e"` | Dark background |
| `tree_chars` | `"#89b4fa"` | Blue for tree connector characters |
| `directories` | `"#f9e2af"` | Yellow for directory names |
| `files` | `"#cdd6f4"` | Gray for file names |
| `border_color` | `"#a6e3a1"` | Green border |

### code_blocks.shell

| Key | Default | Description |
|-----|---------|-------------|
| `background` | `"#000000"` | Black terminal background |
| `prompt` | `"#a6e3a1"` | Green prompt character |
| `command` | `"#00ff00"` | Green command text |
| `output` | `"#94e2d5"` | Teal output text |
| `border_color` | `"#00ff00"` | Green border |

### code_blocks.generic

| Key | Default | Description |
|-----|---------|-------------|
| `background` | `"#f6f8fa"` | Light background |
| `text` | `"#24292e"` | Dark text |
| `border_color` | `"#e1e4e8"` | Light border |

## mermaid

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enabled` | boolean | `true` | Enable Mermaid rendering |
| `theme` | string | `"default"` | `default`, `dark`, `forest`, `neutral`, `base` |
| `background` | string | `"white"` | `white`, `transparent`, or hex color |
| `viewport_width` | integer | `1200` | Rendering viewport width |
| `viewport_height` | integer | `800` | Rendering viewport height |
| `max_width_percent` | integer | `95` | Max % of page width for diagrams |
| `auto_fix_edge_cases` | boolean | `true` | Auto-fix common diagram issues |
| `max_label_length` | integer | `80` | Max chars per label line |
| `show_fix_warnings` | boolean | `true` | Log warnings when fixes applied |
| `fallback_to_code` | boolean | `true` | Show as code block if rendering fails |
| `fallback_to_simplified` | boolean | `true` | Try simplified if normal fails |
| `auto_accept_simplified` | boolean | `true` | Auto-use simplified without prompting |
| `flow_curve` | string | `"basis"` | `basis`, `linear`, `cardinal` |
| `sequence_diagram_actors` | boolean | `true` | Show actor boxes in sequence diagrams |

## export

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `optimize_size` | boolean | `true` | Optimize PDF file size |
| `pdf_variant` | string | `"pdf/a-3b"` | PDF standard variant |
| `compress_images` | boolean | `true` | Compress embedded images |
| `embed_fonts` | boolean | `true` | Embed fonts in PDF |

## advanced

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enable_hyphenation` | boolean | `true` | Enable word hyphenation |
| `orphan_lines` | integer | `3` | Minimum lines at bottom of page |
| `widow_lines` | integer | `3` | Minimum lines at top of page |
| `page_break_avoid` | list | `[headings, tables, code_blocks, images, mermaid_diagrams]` | Elements that avoid page breaks |
