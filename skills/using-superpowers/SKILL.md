---
name: using-superpowers
description: "Comprehensive meta-skill for discovering and orchestrating ALL available tools, MCP servers, skills, plugins, agents, and CLI capabilities to solve any problem optimally. Invoke this skill for ANY non-trivial task — building software, researching topics, analyzing data, debugging systems, deploying code, creating reports, automating workflows, or solving complex multi-step problems. This skill teaches runtime capability discovery via ToolSearch, parallel agent dispatch, and multi-tool orchestration across Firecrawl (web research), Playwright (browser automation), Pinecone (vector storage/RAG), Vercel (deployment), Cloudflare (edge infrastructure), Mermaid Chart (diagrams), Context7 (library docs), Greptile (codebase search), HuggingFace (ML/AI), CodeRabbit (code review), GerdsenAI Document Builder (PDF reports), language servers (TypeScript, Python, C#, C++), and the superpowers workflow skills (TDD, debugging, planning, code review, worktrees). Even for seemingly simple tasks, run capability discovery first — a specialized tool often produces dramatically better results than a manual approach. When in doubt, use this skill."
---

# Orchestrating All Capabilities

This skill turns you from a single-tool operator into a full-stack orchestrator. The environment you're running in typically has dozens of specialized tools — MCP servers, CLI utilities, language servers, plugins, and skills — but most go unused because they aren't top-of-mind. This skill fixes that by teaching a systematic discovery-first approach.

The core insight: **the cost of discovering a better tool is seconds; the cost of missing one is minutes or hours of manual work.** Always discover first.

## Phase 0: Capability Discovery

Before doing anything substantive, survey what's available. Tools change between sessions (MCP servers added/removed, plugins installed/uninstalled), so discovery is essential even if you think you know what's available.

### 0a: Check for Applicable Skills

Before responding to any user message — even clarifying questions — check whether a skill applies. This incorporates the superpowers skill-routing discipline:

1. Scan the available skills list in your system context
2. If there's even a small chance a skill applies, invoke it via the `Skill` tool
3. Process skills first (brainstorming, debugging, planning), then implementation skills

**Rationalizations to watch for:**
- "This is just a simple question" — Questions are tasks. Check for skills.
- "I need more context first" — Skill check comes before exploration.
- "The skill is overkill" — Simple things become complex. Use it.
- "I'll just do this one thing first" — Check BEFORE doing anything.

### 0b: Probe for Deferred MCP Tools

Many powerful tools are "deferred" — they exist but aren't loaded until you discover them via `ToolSearch`. Run these probes **in parallel** (they are independent):

| Probe Keyword | What You Find | Use When |
|---------------|---------------|----------|
| `"firecrawl"` | Web search, scrape, crawl, extract, browser | Research, data gathering, live web content |
| `"playwright"` | Full browser automation (click, fill, screenshot) | Interactive testing, form filling, visual verification |
| `"pinecone"` | Vector DB: indexes, search, upsert, rerank, assistants | Knowledge storage, RAG, cross-session memory |
| `"cloudflare"` | Workers, D1, KV, R2, Hyperdrive | Edge deployment, databases, object storage |
| `"vercel"` | Deploy, projects, logs, domains | Frontend deployment, monitoring |
| `"hugging face"` | Model search, paper search, datasets, spaces | ML/AI research, model discovery |
| `"mermaid"` | Diagram rendering and validation | Architecture diagrams, flowcharts, visualizations |
| `"context7"` | Library documentation lookup | API references, framework-specific questions |
| `"greptile"` | Codebase search, code review, PR analysis | Understanding unfamiliar codebases |
| `"ollama"` | Local LLM inference (OpenAI-compatible API) | Pre-screening, counter-arguments, offline drafts |
| `"github"` | Issues, PRs, repos, actions via MCP | GitHub operations beyond the gh CLI |

Not every probe will find tools — that's fine. The ones that do will dramatically expand your capabilities. See `references/tool-discovery-probes.md` for the full catalog with expected tool names and detailed capabilities.

### 0c: Check CLI Tools

These are always available via the Bash tool:

```bash
which gh python node claude 2>/dev/null
```

- **gh** — GitHub CLI for repos, PRs, issues, releases, actions
- **python** — Scripting, data processing, automation
- **node/npm** — JavaScript execution, package management
- **claude** — Claude CLI for spawning subprocesses

### 0d: Scan Available Skills

Review your system context for loaded skills. Key families to look for:

**Superpowers workflow skills** (prefix `superpowers:`):
- `brainstorming` — Socratic design exploration before implementation
- `writing-plans` — Detailed bite-sized implementation plans
- `executing-plans` — Execute plans in batches with review checkpoints
- `subagent-driven-development` — Dispatch one subagent per task with two-stage review
- `systematic-debugging` — 4-phase root cause investigation
- `test-driven-development` — RED-GREEN-REFACTOR cycle
- `dispatching-parallel-agents` — Concurrent problem solving
- `requesting-code-review` / `receiving-code-review` — Quality gates
- `using-git-worktrees` — Isolated development branches
- `verification-before-completion` — Evidence-based success claims
- `finishing-a-development-branch` — Merge/PR/cleanup flow

**GerdsenAI skills** (prefix `gerdsenai:`):
- `pdf-document-authoring` — Professional PDF output with Mermaid diagrams
- `build-pdf` / `build-recursive` — PDF build commands
- `research-report` — Full research pipeline with parallel sub-agents
- `configure` / `setup` / `update` — Document Builder management

**Other skills** (check system context for availability):
- `firecrawl:firecrawl-cli` — Web operations
- `coderabbit:code-review` — AI-powered code review
- `frontend-design` — UI/UX patterns
- `feature-dev` — Feature development workflows
- `code-simplifier` — Code simplification
- `security-guidance` — Security best practices
- `skill-creator` — Creating new skills
- `pinecone:*` — Pinecone assistant and query operations
- `huggingface-skills:*` — ML training, datasets, evaluation, CLI

### 0e: Build a Capability Manifest

Organize everything you discovered into a mental manifest. This becomes your decision-making reference for the rest of the task:

| Category | Available Tools | Fallback Chain |
|----------|----------------|----------------|
| Web Research | Firecrawl > WebSearch > WebFetch | If Firecrawl unavailable, WebSearch still works |
| Browser Automation | Playwright > Firecrawl browser | Firecrawl has a browser mode as backup |
| Vector Storage / RAG | Pinecone > local JSON files > in-context | Degrade gracefully if Pinecone unavailable |
| Cloud / Deploy | Vercel (frontend) + Cloudflare (edge/API) | Manual deploy instructions as last resort |
| Code Intelligence | Language servers (TS/Py/C#/C++) > Grep + Glob | LSPs give precise types; Grep is a fallback |
| Local AI | Ollama > (not available) | Local inference for pre-screening, counter-arguments |
| Diagrams | Mermaid Chart MCP > inline Mermaid code blocks | Inline Mermaid always works |
| Documentation | Context7 > Firecrawl doc sites > WebFetch | Multiple paths to get docs |
| Code Review | CodeRabbit > Greptile > superpowers code review | At least one is usually available |
| ML / AI | HuggingFace MCP > WebSearch for papers | HF tools are specialized but optional |
| PDF / Reports | GerdsenAI Document Builder | The skill for formatted output |
| Git / GitHub | gh CLI + GitHub MCP | gh CLI is always available |

## Phase 1: Task Decomposition

With your capability manifest in hand, break the user's request into discrete subtasks.

### 1a: Identify Independent Subtasks

Two subtasks are independent if neither needs the other's output to begin. Look for natural boundaries:

- **Data gathering** vs **scaffolding** — research and skeleton code can proceed simultaneously
- **Multiple research questions** — each question is its own subtask
- **Build** vs **deploy config** — application code and deployment setup are independent
- **Tests** vs **documentation** — can be written in parallel once the interface is defined

### 1b: Map Tools to Subtasks

For each subtask, select the optimal tool from your manifest. The right tool is not always the obvious one:

- Firecrawl's structured extraction beats WebFetch for pulling specific data from web pages
- Playwright beats Firecrawl when you need to interact (log in, fill forms, navigate SPAs)
- Pinecone beats keeping everything in context when research findings exceed ~20 pages
- Context7 beats web-searching for framework-specific API questions
- Language servers give precise type information that Grep cannot provide
- GerdsenAI PDF builder produces professional reports; raw markdown is fine for internal notes
- CodeRabbit or Greptile code review catches things a manual scan misses

### 1c: Design the Execution Plan

Sequence subtasks by dependency:

1. **Parallel batch 1** — all independent subtasks
2. **Parallel batch 2** — subtasks that depend only on batch 1 outputs
3. Continue until all subtasks are sequenced

Use `TaskCreate` to register subtasks. This creates visible progress for the user and ensures nothing is forgotten.

## Phase 2: Parallel Execution

### 2a: Dispatch Independent Work

When multiple subtasks can proceed simultaneously, use the `Task` tool with subagents. Each subagent should receive:

- A clear, self-contained objective
- The specific tools it should use (include ToolSearch probe instructions if it needs deferred tools)
- Where to save outputs
- What format to return results in

Launch all independent subagents in a **single message** — this maximizes parallelism.

### 2b: When to Parallelize vs Serialize

**Parallel** when:
- Subtasks are truly independent (no shared state or outputs needed between them)
- Each subtask is substantial (>30 seconds of work)
- You want to minimize wall-clock time

**Sequential** when:
- Tasks have tight dependencies (output of one feeds into the next)
- You need to inspect intermediate results before continuing
- The task is small enough that dispatch overhead exceeds the parallelism benefit

### 2c: Fallback Chains

Every tool can fail. When one does, move to the next in the chain:

- **Firecrawl fails** → WebSearch → manual URL + WebFetch
- **Playwright fails** → Firecrawl browser mode → Bash + curl
- **Pinecone fails** → keep findings in local files → accumulate in context
- **Vercel deploy fails** → check logs, fix, retry → suggest manual deploy
- **Language server unresponsive** → fall back to Grep + Glob for code intelligence
- **Context7 fails** → Firecrawl the documentation site → WebSearch for docs

Report what failed and why before trying the fallback. Never silently skip a subtask.

## Phase 3: Domain-Specific Orchestration Patterns

These are reusable multi-tool recipes. Match the user's task to the closest pattern, then adapt.

### Research Pattern

When the task involves gathering information from external sources:

1. Discover search tools (Phase 0b: firecrawl, brave, WebSearch)
2. Cast a wide net with broad searches first
3. Use Firecrawl `crawl` or `map` for deep site analysis
4. Use Context7 for library/framework documentation
5. Use HuggingFace `paper_search` for academic/ML research
6. Store extensive findings in Pinecone (if available) to manage context window
7. Synthesize findings — resolve conflicting sources, identify gaps, follow up

### Build + Deploy Pattern

When the task involves creating and shipping code:

1. Check for relevant language server (TypeScript, Python, C#, C++)
2. Invoke `brainstorming` skill if requirements are ambiguous
3. Use `frontend-design` skill for UI work
4. Use `feature-dev` or `code-simplifier` for implementation
5. Write tests first — invoke `test-driven-development` skill
6. Request code review via CodeRabbit, Greptile, or `requesting-code-review`
7. Deploy via Vercel (frontend) or Cloudflare Workers (edge/API)
8. Verify with Playwright browser automation (screenshot, interaction test)

### Analysis + Report Pattern

When the task involves analyzing data and producing a deliverable:

1. Gather data using the Research Pattern
2. Process and analyze with Python or Node scripts
3. Create visualizations with Mermaid Chart (or inline Mermaid)
4. Generate PDF via GerdsenAI Document Builder — invoke `pdf-document-authoring` skill
5. For full research reports, use `/gerdsenai:research-report` for the complete pipeline
6. Store analysis in Pinecone for future reference (if available)

### Debug + Fix Pattern

When the task involves finding and fixing a problem:

1. Invoke `systematic-debugging` skill — 4-phase root cause investigation
2. Use language servers for precise type errors, references, and call hierarchies
3. Use Greptile for codebase-wide pattern search
4. Use Playwright for reproducing browser-based bugs
5. Invoke `test-driven-development` — write a failing test for the bug, then fix
6. Request code review to verify the fix won't introduce regressions

### Security Audit Pattern

When the task involves security assessment:

1. Invoke `security-guidance` skill for best practices framework
2. Use Greptile to search for common vulnerability patterns (SQL injection, XSS, etc.)
3. Use language servers to trace data flow from user input to sensitive operations
4. Use Firecrawl to check for known CVEs in dependencies
5. Generate findings report via GerdsenAI PDF builder

## Phase 4: Output Format Selection

Match the deliverable to what the user actually needs. Don't default to one format — choose deliberately:

| User Needs | Format | Tool |
|------------|--------|------|
| Quick answer or explanation | Inline text | Direct response |
| Code changes | File edits | Write / Edit tools |
| Professional report or document | PDF | GerdsenAI Document Builder (`pdf-document-authoring` skill) |
| Architecture or process visualization | Diagram | Mermaid Chart MCP or inline Mermaid |
| Live demo or application | Deployed app | Vercel or Cloudflare |
| Data analysis with charts | Charts + narrative | Python scripts + Mermaid + optional PDF |
| Persistent knowledge base | Vector embeddings | Pinecone |
| Visual verification | Screenshots | Playwright |
| Code quality assessment | Review report | CodeRabbit or Greptile |

When the deliverable is a report or formal document, activate the `pdf-document-authoring` skill for proper formatting (front matter, heading hierarchy, Mermaid diagrams, citations). For full research reports, use the `research-report` agent which handles the entire pipeline.

## Phase 5: Verification and Completion

### 5a: Cross-check Results

Before presenting final results:

- Did every subtask complete successfully?
- Were fallback chains triggered? Note any quality degradation.
- Are external data sources cited?
- Did code changes pass language server checks?
- Were tests written and passing?
- If using `verification-before-completion` skill, provide fresh evidence for every success claim

### 5b: Present Results with Context

Tell the user what happened:

- Which tools and capabilities you discovered and used
- Which you chose NOT to use and why
- What fallbacks were triggered
- How subtasks were parallelized

This transparency builds trust and helps the user understand the value of the orchestration.

### 5c: Offer Next Steps

Based on the capability manifest, suggest what else is possible. Examples:

- "Pinecone is available — want me to store these research findings for future sessions?"
- "I can deploy this to Vercel if you want a live version."
- "I can generate a PDF report of these findings using the GerdsenAI Document Builder."
- "CodeRabbit could do a deeper review of this code."
- "I can run the superpowers TDD workflow to add test coverage."

## Anti-Patterns to Avoid

### The "Obvious Tool" Trap
Don't reach for the first tool that comes to mind. A 30-second ToolSearch probe might reveal a specialized tool that saves 10 minutes of manual work. Discovery cost is low; missing a better tool is expensive.

### The "One Tool" Trap
Complex problems rarely have single-tool solutions. If you're doing everything with Bash scripts and file reads, step back and check whether specialized MCP tools exist for what you're doing.

### The "Context Window" Trap
When accumulating large amounts of research or data, use Pinecone to offload findings instead of keeping everything in the conversation. Context windows have limits; vector databases don't.

### The "Sequential by Default" Trap
When you have 4 independent research questions, don't answer them one by one. Dispatch 4 parallel subagents. The wall-clock time improvement is dramatic and the user experience is fundamentally better.

### The "Skip Discovery" Trap
Tool availability changes between sessions. Run Phase 0 discovery at the start of every complex task, even if you "remember" what was available last time. It takes seconds and prevents costly mistakes.

### The "Gold Plating" Trap
Not every task needs every tool. A simple file edit doesn't need Playwright verification, Pinecone storage, and a PDF report. Match the response to the complexity of the request. Use the minimum tool set that solves the problem well.
