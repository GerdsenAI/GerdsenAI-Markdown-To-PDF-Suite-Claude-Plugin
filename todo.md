# GerdsenAI-Markdown-To-PDF-Suite v0.2 - Implementation Checklist

## Bug Fixes

- [ ] B1: Fix quoted strings on title page — replace manual YAML parsing with `yaml.safe_load()` in `document_builder_reportlab.py:_extract_metadata()`
- [ ] B2: Fix missing logo on cover page — update `config.yaml` logos to reference existing `GerdsenAI_Neural_G_Invoice.png`
- [ ] B3: Fix maturity sections lacking proper headings — update skill with assessment heading guidance
- [ ] B4: Fix setup script not auto-installing deps — rewrite `scripts/setup.sh` with full bootstrap
- [ ] B5: Fix minimal settings file — expand settings to include output_dir, logos, page_size, filename pattern

## Architecture Changes

- [ ] A1: Self-contained distribution via GitHub Releases — create `.github/workflows/release.yml` in Document Builder repo; update setup.sh to download release
- [ ] A2: Flexible output location — add output_mode setting; update build.sh and build-pdf.md to support same_directory / custom / builder_pdfs
- [ ] A3: Recursive directory scanning — create `commands/build-recursive.md` command
- [ ] A4: TUI/CLI folder browsing — use AskUserQuestion with filesystem-generated options for directory selection
- [ ] A5: Custom output filename and enumeration — add filename_pattern and filename_enumeration to settings; pass -o flag through
- [ ] A6: Logo selection at runtime — list Assets/ logos in commands; support cover/footer logo override
- [ ] A7: First-run error handling — add inline setup offer to all commands and agent

## Scripts

- [ ] Rewrite `scripts/setup.sh` — GitHub Release download, full venv bootstrap, tilde expansion
- [ ] Update `scripts/build.sh` — output dir override, custom filename, JSON result output, tilde expansion
- [ ] Update `scripts/update.sh` — support release-based updates
- [ ] Update `scripts/verify-install.sh` — check new settings fields

## Commands

- [ ] Update `commands/setup.md` — guided preferences (output dir, logos, page size)
- [ ] Update `commands/build-pdf.md` — first-run check, output location, logo override
- [ ] Create `commands/build-recursive.md` — recursive directory scanning
- [ ] Update `commands/configure.md` — logo browser, add logos from filesystem
- [ ] Update `commands/build-all.md` — first-run check alignment

## Skill + Agent + Hooks

- [ ] Update `skills/pdf-document-authoring/SKILL.md` — assessment heading guidance, output options, logo selection
- [ ] Update `agents/gerdsenai-document-builder.md` — first-run detection, output awareness, logo selection
- [ ] Update `hooks/session-start` — check new settings fields

## Release Workflow + Docs

- [ ] Create `.github/workflows/release.yml` in Document Builder repo
- [ ] Update `README.md` in plugin repo — document all new features
- [ ] Update `.claude-plugin/plugin.json` — bump version to 0.2.0

## Final

- [ ] Commit Document Builder fixes (B1, B2, release workflow)
- [ ] Commit plugin v0.2 updates
- [ ] Run plugin-validator agent
