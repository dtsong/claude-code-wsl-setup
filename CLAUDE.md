# Claude Code Setup - Project Guide

This repository contains a portable Claude Code configuration system — 38 agent personas, 100+ structured skills, multi-agent deliberation, session persistence, lifecycle hooks, and a permissions system optimized for Windows/WSL parallel development.

## Quick Install (For New Users)

If the user wants to install this setup, run:

```bash
chmod +x install.sh
./install.sh --preset full --with-settings --with-hooks-json
```

For a minimal install (skills only):

```bash
./install.sh
```

The legacy monolithic installer is preserved at `legacy/claude-code-setup.sh`.

## What This Project Does

This setup enables:
- **38 agent personas** (21 Council + 17 Academy) for multi-agent deliberation
- **100+ structured skills** across 20 council departments + standalone packs
- **8 deliberation modes** from quick brainstorm to deep audit
- **Windows toast notifications** identifying which agent needs attention
- **Auto-formatting hooks** for code changes
- **Pre-approved permissions** for 76 common safe commands
- **Session persistence** via `/handover` and auto-compaction hooks
- **Issue-driven execution** via `/looper`, `/implement`, `/ralf`
- **Project scaffolding** via `/new-python`, `/new-typescript`, `/new-terraform`, `/new-mcp-server`
- **Workspace context** auto-loading based on git remote
- **Git worktree helpers** for parallel development

## Project Structure

```
claude-code-wsl-setup/
├── install.sh              # Symlink-based installer (presets: skills/core/full)
├── settings.json           # Merged settings: env + hooks + permissions
├── hooks.json              # Standalone PreCompact hook config
├── agents/                 # 38 agent personas (21 council + 17 academy)
│   ├── council-architect.md
│   ├── council-advocate.md
│   ├── ...                 # 19 more council agents
│   ├── academy-sage.md
│   └── ...                 # 16 more academy agents
├── commands/               # 26 slash commands + shared engine
│   ├── _council-engine.md  # Shared deliberation engine (~1200 lines)
│   ├── council.md          # Council theme layer
│   ├── academy.md          # Academy theme layer
│   ├── brainstorm.md       # Quick 3-agent gut check
│   ├── looper.md           # Issue-to-PR with retry loops
│   ├── implement.md        # Implement GitHub issues
│   ├── ralf.md             # Autonomous PRD executor
│   ├── handover.md         # Session knowledge transfer
│   ├── g.md                # Git porcelain
│   ├── ops.md              # Operations center
│   ├── new-python.md       # Python project scaffolding
│   ├── new-typescript.md   # TypeScript project scaffolding
│   ├── new-terraform.md    # Terraform module scaffolding
│   ├── new-mcp-server.md   # MCP server scaffolding
│   ├── commit-push-pr.md   # Git commit → push → PR workflow
│   ├── commit.md           # Quick commit
│   ├── test.md             # Run project tests
│   ├── lint.md             # Run linter
│   ├── review.md           # Review changes
│   ├── simplify.md         # Refactor/simplify code
│   ├── diagnose.md         # Diagnose UI/CSS bugs
│   ├── fix.md              # Apply and verify fixes
│   ├── map.md              # Map route component trees
│   └── qa.md               # Full frontend QA pipeline
├── skills/                 # 100+ structured skill templates
│   ├── council/            # 20 departments × 2-3 skills each
│   ├── academy/            # Academy theme skills
│   ├── git-workflows/      # Git operations
│   ├── github-workflow/    # GitHub interactions
│   ├── language-conventions/ # Python, TypeScript, Terraform refs
│   ├── terraform-skill/    # Terraform best practices
│   ├── dbt-skill/          # dbt data engineering
│   ├── tdd/                # Test-driven development
│   ├── frontend-qa/        # Frontend QA pipeline (4 sub-skills)
│   └── ...                 # 7 more standalone skill packs
├── hooks/                  # Lifecycle hook scripts
│   ├── notify.sh           # Notification when Claude needs input
│   ├── stop.sh             # Notification when Claude completes
│   ├── format.sh           # Auto-format code after edits
│   ├── acceptance-gate.sh  # Quality gate for task completion
│   └── pre-compact-handover.sh  # Auto-save before compaction
├── workspaces/             # Project-specific context templates
│   ├── FORMAT.md
│   ├── _example/
│   └── _full-stack/
├── scripts/                # Utility scripts
│   ├── create-worktrees.sh # Create git worktrees for parallel agents
│   ├── init-project.sh     # Initialize Claude Code in a project
│   ├── launch-agent.sh     # Launch an agent with context
│   ├── run-agent.sh        # Run an agent task
│   ├── agent-broadcast.sh  # Broadcast to all agents
│   ├── agent-status.sh     # Check agent status
│   ├── find-workspaces.sh  # Discover workspace configs
│   ├── launch-workspace.sh # Initialize workspace context
│   ├── notify-complete.sh  # Send completion notification
│   └── task-board.sh       # Display task board
├── templates/              # Project initialization templates
│   ├── CLAUDE.md
│   └── project-settings.json
├── legacy/                 # Original monolithic installer (reference)
│   └── claude-code-setup.sh
├── ARCHITECTURE.md         # Technical reference
├── CONTRIBUTING.md         # Contributor guide
├── CHANGELOG.md
├── README.md
└── LICENSE
```

## Key Commands

```bash
# Install (symlink-based, incremental)
./install.sh                           # Skills only (safe default)
./install.sh --preset core             # + commands + agents
./install.sh --preset full             # + scripts + hooks + workspaces + templates
./install.sh --with-settings           # Also link settings.json
./install.sh --with-hooks-json         # Also link hooks.json
./install.sh --dry-run                 # Preview what would be installed
./install.sh --uninstall               # Remove all managed symlinks

# After installation:
~/.claude/scripts/init-project.sh /path/to/project
~/.claude/scripts/create-worktrees.sh 5
```

## Development Guidelines

### When modifying hooks (`hooks/*.sh`):
- Keep them fast (under 10 seconds)
- Always exit with code 0 for success
- Maintain cross-platform support (WSL, macOS, Linux)
- Use the `get_agent_id()` function pattern for agent identification

### When modifying the installer:
- The installer must be idempotent (safe to run multiple times)
- WSL detection uses `/proc/version` — symlinks become copies on WSL
- Test with `CLAUDE_DIR=/tmp/test-claude ./install.sh --preset full`
- Verify uninstall: `./install.sh --uninstall`

### When adding new slash commands:
- Place in `commands/` directory with `.md` extension
- Include YAML frontmatter with `description` and optional `argument-hint`
- Keep commands focused on a single workflow

### When modifying agents or skills:
- Agent files require YAML frontmatter (`name`, `description`, `model`)
- Skill files follow: Purpose, Inputs, Process, Output Format, Quality Checks
- See [ARCHITECTURE.md](ARCHITECTURE.md) for full schema

### When modifying the deliberation engine:
- All workflow logic lives in `commands/_council-engine.md`
- Theme files (`council.md`, `academy.md`) supply 14 configuration variables
- Do not duplicate engine logic in theme files

## Testing Changes

```bash
# Shell syntax
bash -n install.sh
bash -n hooks/*.sh
bash -n scripts/*.sh

# JSON validation
python3 -m json.tool settings.json >/dev/null
python3 -m json.tool hooks.json >/dev/null

# Installer smoke test (isolated)
CLAUDE_DIR="/tmp/claude-test" ./install.sh --preset skills --conflict-policy fail
CLAUDE_DIR="/tmp/claude-test" ./install.sh --uninstall
```

## No External Dependencies

This project uses only built-in Windows/macOS/Linux APIs:
- Windows: `Windows.UI.Notifications` (built-in Windows 10+)
- macOS: `osascript` (built-in)
- Linux: `notify-send` (usually pre-installed)

Do NOT add dependencies on external PowerShell modules like BurntToast.

## Reference

Based on Boris Cherney's workflow: https://www.linkedin.com/posts/boris-cherny-3a8b2513_im-boris-and-i-created-claude-code-lots-activity-7337184857029169152-WUZB/
