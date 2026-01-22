# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **Claude Code configuration repository** containing custom commands, agents, and orchestration patterns for AI-assisted software development. It is not a traditional software project with build artifacts—its "code" is the configuration files themselves.

## Key Architectural Patterns

### Sub-Agent Delegation Model

Commands delegate to specialized sub-agents rather than doing everything themselves:

- **codebase-locator**: Finds WHERE files live (Grep/Glob/LS only, no analysis)
- **codebase-analyzer**: Understands HOW code works (Read/Grep with file:line precision)
- **codebase-pattern-finder**: Finds similar implementations to model after
- **thoughts-locator**: Finds thoughts/ documents relevant to a topic
- **thoughts-analyzer**: Extracts high-value insights from thoughts documents (filters aggressively)
- **web-search-researcher**: Web research for modern/external information

**Key principle**: Spawn multiple sub-agents in parallel, wait for ALL to complete, then synthesize.

### Documentation-First Philosophy

All codebase research agents are **documentarians, not critics**. They describe what exists without suggesting improvements, identifying problems, or recommending changes. This separation of concerns is intentional—research answers "what is", planning answers "what should be".

### Linear-Driven Development

The `ralph_*` commands automate the full ticket lifecycle:

```
research needed → /ralph_research → research in review
ready for spec → /ralph_plan → plan in review
ready for dev → /ralph_impl → in dev
```

Each command:
1. Fetches top 10 priority tickets via Linear MCP
2. Selects highest priority SMALL or XS issue
3. Uses `linear` CLI to fetch ticket into thoughts/
4. Performs its task (research/plan/implement)
5. Attaches results and moves ticket to next state

### Handoff Pattern for Session Continuity

When work spans sessions:
1. `/create_handoff` creates a structured document with tasks, learnings, artifacts, and next steps
2. `/resume_handoff` (in new session) reads handoff, verifies current state, and continues work

Handoffs live in `thoughts/shared/handoffs/ENG-XXXX/` with timestamped filenames.

### tmux Orchestration Control Plane

The tmux KV pattern (see `.claude/docs/orchestration/tmux-kv-control-plane.md`) provides:

- **KV storage** via `tmux set-option @key value` and `tmux show-options -qv @key`
- **Environment broadcast** via `tmux set-environment` for child processes
- **Signaling** via `tmux wait-for -S topic` (signal) and `tmux wait-for topic` (wait)

Session naming: `llm.run.<RUN_ID>` — one session per orchestration run.

## Command Variants

Several commands have multiple variants for different contexts:

- `create_plan.md` / `create_plan_generic.md` / `create_plan_nt.md` — Different ticket path conventions
- `research_codebase.md` / `research_codebase_generic.md` / `research_codebase_nt.md` — Same pattern
- The `_nt` variants omit thoughts/ directory exploration
- The `_generic` variants are for non-ticket workflows

## Important Constraints

### File Reading Protocol

When commands reference files (tickets, research, plans):
1. Read mentioned files **fully** (no limit/offset) before spawning sub-tasks
2. Read them in main context, not through sub-agents
3. Only spawn sub-tasks after primary context is loaded

### Thoughts Path Handling

The `thoughts/searchable/` directory contains hard links for searching. Always document paths by removing ONLY "searchable/":
- `thoughts/searchable/shared/research/foo.md` → `thoughts/shared/research/foo.md`
- `thoughts/searchable/jbolus/tickets/eng_123.md` → `thoughts/jbolus/tickets/eng_123.md`
Preserve all other subdirectory structure exactly.

### Commit Rules

From `/commit`:
- Never commit `thoughts/` directory
- Never commit dummy files or test scripts created during exploration
- Use `git add` with specific files (never `-A` or `.`)
- No co-author information or Claude attribution
- Follow Conventional Commits format

### Success Criteria Format

Implementation plans MUST separate success criteria into:

**Automated Verification** (agents can run):
- `make test`, `npm run lint`, compilation, etc.

**Manual Verification** (requires human):
- UI/UX testing using playwright or https://github.com/browser-use/browser-use
```
mkdir -p ~/.claude/skills/browser-use
curl -o ~/.claude/skills/browser-use/SKILL.md \
  https://raw.githubusercontent.com/browser-use/browser-use/main/skills/browser-use/SKILL.md
```
 performance under real conditions, edge cases

After completing automated verification for a phase, **pause** for manual confirmation before proceeding.

## Linear Integration Details

### Workflow States (in order)
Triage → Spec Needed → Research Needed → Research in Progress → Research in Review → Ready for Plan → Plan in Progress → Plan in Review → Ready for Dev → In Dev → Code Review → Done


Use the `links` parameter (not markdown in description) when attaching URLs to tickets.

## Script: spec_metadata.sh

`.claude/scripts/spec_metadata.sh` generates metadata for research/plan documents:

- `DATETIME_TZ`: Current date/time with timezone
- `FILENAME_TS`: Timestamp for filename formatting (YYYY-MM-DD_HH-MM-SS)
- `GIT_COMMIT`, `GIT_BRANCH`, `REPO_NAME`: Git context
- `THOUGHTS_STATUS`: First 40 lines of `humanlayer thoughts status`

