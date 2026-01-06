# Claude Code Setup - Project Guide

This repository contains configuration files and scripts to set up Claude Code for multi-agent parallel development on Windows/WSL, based on Boris Cherney's workflow.

## Quick Install (For New Users)

If the user wants to install this setup, run:

```bash
chmod +x claude-code-setup.sh
./claude-code-setup.sh
```

This single command will configure everything automatically.

## What This Project Does

This setup enables running **5 parallel Claude Code agents** with:
- Windows toast notifications that identify which agent needs attention
- Auto-formatting hooks for code changes
- Pre-approved permissions for common safe commands
- Slash commands for git workflows
- Git worktree helpers for parallel development

## Project Structure

```
claude-code-setup/
├── claude-code-setup.sh    # Main installer script (run this!)
├── settings.json           # Claude Code settings with hooks & permissions
├── hooks/
│   ├── notify.sh          # Notification when Claude needs input
│   ├── stop.sh            # Notification when Claude completes
│   └── format.sh          # Auto-format code after edits
├── commands/
│   ├── commit-push-pr.md  # Git commit → push → PR workflow
│   ├── commit.md          # Quick commit
│   ├── test.md            # Run project tests
│   ├── lint.md            # Run linter
│   ├── review.md          # Review changes
│   └── simplify.md        # Refactor/simplify code
├── templates/
│   ├── CLAUDE.md          # Template for user projects
│   └── project-settings.json
├── scripts/
│   ├── init-project.sh    # Initialize Claude Code in a project
│   └── create-worktrees.sh # Create git worktrees for parallel agents
├── README.md
└── LICENSE
```

## Key Commands

```bash
# Install everything
./claude-code-setup.sh

# After installation, these helpers are available:

# Initialize Claude Code in any project
~/.claude/init-project.sh /path/to/project

# Create 5 git worktrees for parallel agents
cd your-repo
~/.claude/create-worktrees.sh 5
```

## Installation Details

The setup script installs files to:
- `~/.claude/settings.json` - Global Claude Code configuration
- `~/.claude/hooks/` - Notification and formatting hooks
- `~/.claude/commands/` - Global slash commands
- `~/.claude/templates/` - Project templates
- `~/.claude/init-project.sh` - Project initializer
- `~/.claude/create-worktrees.sh` - Worktree creator

## Development Guidelines

### When modifying hooks (`hooks/*.sh`):
- Keep them fast (under 10 seconds)
- Always exit with code 0 for success
- Test on WSL before committing
- Maintain cross-platform support (WSL, macOS, Linux)
- Use the `get_agent_id()` function pattern for agent identification

### When modifying the setup script:
- The setup script must be idempotent (safe to run multiple times)
- Use the print_success/print_warning/print_error functions for output
- Test the full installation flow after changes

### When adding new slash commands:
- Place in `commands/` directory
- Use `.md` extension
- Include bash code blocks for commands Claude should run
- Keep commands focused on a single workflow

## Testing Changes

After modifying any files:

1. Run the setup script on a clean environment:
   ```bash
   # Backup existing config
   mv ~/.claude ~/.claude.backup
   
   # Run setup
   ./claude-code-setup.sh
   
   # Test notifications
   ~/.claude/hooks/notify.sh
   ~/.claude/hooks/stop.sh
   ```

2. Verify hooks work in Claude Code:
   ```bash
   claude
   # Do something that triggers a notification
   ```

## No External Dependencies

This project uses only built-in Windows/macOS/Linux APIs:
- Windows: `Windows.UI.Notifications` (built-in Windows 10+)
- macOS: `osascript` (built-in)
- Linux: `notify-send` (usually pre-installed)

Do NOT add dependencies on external PowerShell modules like BurntToast.

## Reference

Based on Boris Cherney's workflow: https://www.linkedin.com/posts/boris-cherny-3a8b2513_im-boris-and-i-created-claude-code-lots-activity-7337184857029169152-WUZB/
