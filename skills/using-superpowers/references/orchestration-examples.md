# Orchestration Examples

Three worked examples showing the full discovery-to-delivery flow. These illustrate how the phases from SKILL.md play out in practice.

## Example 1: Multi-Source Research + PDF Report

**User prompt**: "Research the current state of WebAssembly support across browsers and create a professional report. Also check if there are any HuggingFace models related to WASM compilation."

### Phase 0 — Discovery

Probes run in parallel:
- `ToolSearch("firecrawl")` → found: firecrawl_search, firecrawl_scrape, firecrawl_crawl
- `ToolSearch("pinecone")` → found: search-records, upsert-records, create-index-for-model
- `ToolSearch("hugging face")` → found: hub_repo_search, paper_search
- `ToolSearch("mermaid")` → found: validate_and_render_mermaid_diagram
- `ToolSearch("context7")` → found: resolve-library-id, query-docs

Skills checked: `pdf-document-authoring` (applies — PDF output), `research-report` (applies — could use full pipeline)

Manifest built. Decision: use `research-report` agent for the full pipeline since this is a comprehensive research task. Alternatively, orchestrate manually using individual tools.

### Phase 1 — Decomposition

| Subtask | Tool | Depends On |
|---------|------|-----------|
| Browser support research | Firecrawl search + scrape | None |
| WASM specification status | Firecrawl (W3C site) | None |
| HuggingFace model search | HF hub_repo_search + paper_search | None |
| Performance benchmarks | Firecrawl search | None |
| Diagram creation | Mermaid (inline) | Research results |
| PDF authoring | GerdsenAI Document Builder | All research + diagrams |

Batch 1 (parallel): browser support, WASM spec, HuggingFace search, benchmarks
Batch 2 (sequential): diagram creation, PDF authoring

### Phase 2 — Execution

Four Task subagents launched simultaneously:
1. **Browser support agent**: Uses firecrawl_search for "WebAssembly browser support 2026", scrapes MDN and caniuse.com
2. **WASM spec agent**: Uses firecrawl_scrape on W3C WASM spec page, Context7 for WASM API docs
3. **HuggingFace agent**: Searches hub_repo_search for "WebAssembly compilation", paper_search for "WASM compiler"
4. **Benchmarks agent**: Uses firecrawl_search for WASM benchmark comparisons, scrapes benchmark sites

### Phase 3 — Pattern applied: Analysis + Report

After subagents return:
- Synthesize findings into report sections
- Create Mermaid diagrams: browser support timeline, architecture flowchart, performance comparison chart
- Invoke `pdf-document-authoring` skill for formatting rules
- Write markdown with YAML front matter, citations, diagrams
- Build PDF via `/gerdsenai:build`

### Phase 4 — Output: PDF report + inline summary

Deliver the PDF path and a brief summary of key findings in the conversation.

---

## Example 2: Build + Deploy + Verify

**User prompt**: "Create a simple status dashboard that shows if our API endpoints are healthy, deploy it to Vercel, and take a screenshot so I can see it works."

### Phase 0 — Discovery

Probes:
- `ToolSearch("vercel")` → found: deploy_to_vercel, list_projects, get_deployment_build_logs
- `ToolSearch("playwright")` → found: browser_navigate, browser_take_screenshot, browser_snapshot
- `ToolSearch("context7")` → found: resolve-library-id, query-docs

CLI: `gh` available, `node`/`npm` available
Skills: `frontend-design` (applies), `brainstorming` (maybe — requirements seem clear), `test-driven-development` (applies for tests)

### Phase 1 — Decomposition

| Subtask | Tool | Depends On |
|---------|------|-----------|
| Scaffold Next.js app | Node/npm + Write tool | None |
| Query Context7 for Next.js API | Context7 | None |
| Implement health check UI | Edit tool + TypeScript LSP | Scaffold |
| Write tests | TDD skill | Implement |
| Deploy to Vercel | Vercel MCP | Tests pass |
| Screenshot verification | Playwright | Deploy |

Batch 1 (parallel): scaffold app, query Context7
Batch 2 (sequential): implement → test → deploy → screenshot

### Phase 2 — Execution

Parallel batch: scaffold + Context7 query
Sequential: implement dashboard UI using Context7 docs for correct APIs → write tests via TDD skill → deploy via `deploy_to_vercel` → navigate Playwright to deployment URL → take screenshot

### Phase 3 — Pattern applied: Build + Deploy

Follow the Build + Deploy pattern from SKILL.md. Code review skipped (user asked for quick dashboard, not production system — match response to request complexity).

### Phase 4 — Output: deployed URL + screenshot

Present the Vercel deployment URL and the Playwright screenshot showing the live dashboard.

---

## Example 3: Debug with Code Review Gate

**User prompt**: "Our API tests pass individually but fail when run together. Something is leaking state between tests. Find it and fix it."

### Phase 0 — Discovery

Probes:
- `ToolSearch("greptile")` → found: search_greptile_comments, trigger_code_review

Skills: `systematic-debugging` (applies — this is a root cause investigation), `test-driven-development` (applies — need to verify fix), `requesting-code-review` (applies — user wants confidence in the fix)

CLI: `python`/`node` for running tests, language servers for type analysis

### Phase 1 — Decomposition

This is a sequential pipeline — each step depends on the previous:

1. Reproduce the failure (run tests together, confirm failure)
2. Investigate shared state (database connections, global variables, singletons, module-level state)
3. Identify the leaking test(s)
4. Write a regression test that captures the leak
5. Fix the root cause
6. Verify all tests pass (individually and together)
7. Code review the fix

### Phase 2 — Execution

**Step 1**: Run the test suite, capture output showing failures.

**Step 2**: Invoke `systematic-debugging` skill. Phase 1 (Evidence Gathering):
- Use language server to find all `beforeAll`, `afterAll`, `beforeEach`, `afterEach` hooks
- Use Grep to find global/module-level mutable state (`let`, `var` at module scope)
- Use Greptile to search for "database connection" or "singleton" patterns
- Run tests in isolation to identify which specific test pollutes state

**Step 3**: From evidence, form hypothesis about which test leaves state behind.

**Step 4**: Invoke `test-driven-development` skill — write a test that explicitly checks for the state leak (RED phase — it should fail with the leak present).

**Step 5**: Fix the root cause (proper cleanup in afterEach, isolate shared resources).

**Step 6**: Run all tests together — the regression test and all original tests should now pass (GREEN phase).

**Step 7**: Invoke `requesting-code-review` skill → dispatches CodeRabbit or Greptile to review the diff. Present review results to user.

### Phase 4 — Output: code changes + review report

Present the fix (file edits), the new regression test, the passing test output, and the code review results. No PDF needed — this is a code-focused deliverable.
