# Context Engineering

A collection of Claude Code custom commands, agents, and orchestration patterns for AI-assisted software development. This configuration enables sophisticated multi-agent workflows, research-driven development, and seamless integration with Linear ticket management.

## Overview

This repository contains Claude Code configuration files that define:
- **Custom commands** for common development workflows (research, planning, implementation, commits, PRs)
- **Specialized agents** for codebase exploration, web research, and thoughts analysis
- **Orchestration patterns** using tmux for multi-agent coordination
- **Linear integration** for ticket-driven development workflows

## Structure

```
.claude/
├── agents/              # Specialized sub-agent configurations
│   ├── codebase-locator.md
│   ├── codebase-analyzer.md
│   ├── codebase-pattern-finder.md
│   ├── thoughts-locator.md
│   ├── thoughts-analyzer.md
│   └── web-search-researcher.md
├── commands/            # Custom slash commands
│   ├── create_plan*.md  # Implementation planning workflows
│   ├── research_codebase*.md
│   ├── ralph_*.md       # Linear ticket workflows
│   ├── commit.md        # Git commit automation
│   ├── describe_pr.md   # PR description generation
│   ├── debug.md         # Debugging assistance
│   ├── implement_plan.md
│   ├── linear.md        # Linear ticket management
│   ├── local_review.md  # Peer review setup
│   ├── resume_handoff.md
│   ├── validate_plan.md
│   └── founder_mode.md  # Retroactive ticket creation
├── scripts/             # Utility scripts
│   ├── spec_metadata.sh
│   ├── tmux-kv-bootstrap.sh
│   └── tmux-kv-demo.sh
├── docs/                # Documentation
│   └── orchestration/tmux-kv-control-plane.md
└── settings.json        # Claude Code settings
```

## Custom Commands

### Planning & Research

| Command | Description |
|---------|-------------|
| `/create_plan` | Create detailed implementation plans through interactive research |
| `/research_codebase` | Conduct comprehensive codebase research with parallel sub-agents |
| `/ralph_research` | Automated research for Linear tickets |
| `/ralph_plan` | Automated planning for Linear tickets |
| `/ralph_impl` | Automated implementation for Linear tickets |

### Implementation

| Command | Description |
|---------|-------------|
| `/implement_plan` | Execute approved implementation plans phase by phase |
| `/validate_plan` | Verify implementation against success criteria |
| `/debug` | Debug issues using logs, database, and git state |

### Git & PR Workflow

| Command | Description |
|---------|-------------|
| `/commit` | Create git commits following Conventional Commits |
| `/describe_pr` | Generate comprehensive PR descriptions |
| `/create_handoff` | Create handoff documents for session continuity |
| `/resume_handoff` | Resume work from a handoff document |

### Ticket Management

| Command | Description |
|---------|-------------|
| `/linear` | Create and manage Linear tickets from thoughts documents |
| `/founder_mode` | Retroactively create tickets for completed work |
| `/local_review` | Set up worktree for reviewing colleagues' branches |

### Oneshot Workflow

| Command | Description |
|---------|-------------|
| `/oneshot` | Research → Plan → Implement in one session |
| `/oneshot_plan` | Research → Plan in one session |

## Agents

### Codebase Research Agents

- **codebase-locator**: Finds files and directories related to features/tasks
- **codebase-analyzer**: Analyzes implementation details with file:line references
- **codebase-pattern-finder**: Finds similar implementations and usage examples

### Thoughts Directory Agents

- **thoughts-locator**: Discovers relevant documents in thoughts/ directory
- **thoughts-analyzer**: Extracts high-value insights from thoughts documents

### External Research

- **web-search-researcher**: Conducts web research for modern information

## Linear Integration

This configuration integrates with Linear for ticket-driven development:

1. **Workflow States**: Triage → Spec Needed → Research Needed → Research in Progress → Research in Review → Ready for Plan → Plan in Progress → Plan in Review → Ready for Dev → In Dev → Code Review → Done

2. **Automatic Label Assignment**:
   - `hld`: Tickets about the daemon (hld/)
   - `wui`: Tickets about the web UI (humanlayer-wui/)
   - `meta`: Tickets about tooling and thoughts/

3. **Commands**:
   - `/ralph_research` - Auto-research tickets in "research needed" status
   - `/ralph_plan` - Auto-plan tickets in "ready for spec" status
   - `/ralph_impl` - Auto-implement tickets in "ready for dev" status

## Orchestration

### tmux KV Control Plane

Includes patterns for coordinating multiple AI agents using tmux:

- **Key-Value Storage**: Using tmux user options (`@keys`)
- **Environment Broadcasting**: Using `set-environment` for child processes
- **Signaling**: Using `wait-for` for agent readiness and handoffs
- **Namespacing**: One session per orchestration run

See `.claude/docs/orchestration/tmux-kv-control-plane.md` for complete documentation.

## Settings

The `settings.json` configures:
- Permissions for specific scripts
- MCP server settings

## Installation

1. Clone this repository to your project's `.claude/` directory
2. Ensure Claude Code has access to the required tools
3. Set up any external integrations (Linear CLI, GitHub CLI)
4. Configure local settings in `.claude/settings.local.json` if needed

## Development Workflow

The typical workflow using this configuration:

1. **Research**: `/research_codebase` to understand the problem space
2. **Plan**: `/create_plan` to create detailed implementation plans
3. **Implement**: `/implement_plan` to execute the plan
4. **Commit**: `/commit` to create atomic commits
5. **PR**: `/describe_pr` to generate PR description

Or use the automated Linear workflow:

1. Create ticket in Linear
2. `/ralph_research` - Research the ticket
3. `/ralph_plan` - Create implementation plan
4. `/ralph_impl` - Implement in a worktree
5. Review and merge

## Contributing

When adding new commands or agents:
1. Follow existing naming conventions
2. Include clear descriptions and usage examples
3. Document any external dependencies
4. Test thoroughly before committing

## License

MIT
