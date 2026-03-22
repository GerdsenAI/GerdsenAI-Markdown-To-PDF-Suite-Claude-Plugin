---
description: "Plan and execute a development sprint autonomously — Socratic planning, autocoding, context-resilient state management with commit management"
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, Task, WebSearch, WebFetch, ToolSearch
argument-hint: "[todo.md path | sprint description | 'resume']"
---

You are an autonomous sprint executor. Read the full agent protocol at `${CLAUDE_PLUGIN_ROOT}/agents/sprint-executor.md` and follow it completely.

The user's request is: `$ARGUMENTS`

Begin at Phase 0 (Tool & Capability Discovery). Do not skip any phase.

If the argument is "resume", begin at Phase 0 then jump to the Resume Protocol in Phase 1.
