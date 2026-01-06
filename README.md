# Claude Code Setup for Windows/WSL

A comprehensive setup script and configuration for running multiple Claude Code agents in parallel, based on [Boris Cherney's workflow](https://www.linkedin.com/posts/boris-cherny-3a8b2513_im-boris-and-i-created-claude-code-lots-activity-7337184857029169152-WUZB/) (creator of Claude Code).

## Features

- 🔔 **Windows notifications** when Claude needs input or completes tasks
- 🏷️ **Agent identification** - know exactly which terminal/agent needs attention
- 🚀 **5 parallel agents** using git worktrees
- 📝 **Auto-formatting** hooks for multiple languages
- ⚡ **Pre-approved permissions** for common safe commands
- 📁 **Slash commands** for common workflows (commit, test, lint, PR)
- 📋 **Project templates** for quick initialization

## Quick Start

```bash
# Clone this repo
git clone https://github.com/dtsong/claude-code-setup.git
cd claude-code-setup

# Run the setup script
chmod +x claude-code-setup.sh
./claude-code-setup.sh
```

**No additional dependencies required!** The notifications use built-in Windows APIs.

## What Gets Installed

```
~/.claude/
├── settings.json           # Main configuration (hooks, permissions)
├── hooks/
│   ├── notify.sh          # Notification when Claude needs input
│   ├── stop.sh            # Notification when Claude finishes
│   └── format.sh          # Auto-format code after edits
├── commands/
│   ├── commit-push-pr.md  # Full git workflow command
│   ├── commit.md          # Quick commit command
│   ├── test.md            # Run project tests
│   ├── lint.md            # Run linter with auto-fix
│   ├── review.md          # Review current changes
│   └── simplify.md        # Simplify/refactor code
├── templates/
│   ├── CLAUDE.md          # Project documentation template
│   └── settings.json      # Project settings template
├── init-project.sh        # Initialize new projects
└── create-worktrees.sh    # Create parallel agent worktrees
```

## Usage

### Running 5 Parallel Agents

This is the core workflow from Boris's setup:

```bash
# Navigate to your project
cd your-project

# Create 5 worktrees for parallel work
~/.claude/create-worktrees.sh 5

# This creates:
# ../your-project-agent-1/
# ../your-project-agent-2/
# ../your-project-agent-3/
# ../your-project-agent-4/
# ../your-project-agent-5/
```

Open 5 terminal tabs (Windows Terminal recommended) and run `claude` in each worktree.

### Initializing a New Project

```bash
cd your-project
~/.claude/init-project.sh
```

This creates:
- `CLAUDE.md` - Project documentation for Claude (customize this!)
- `.claude/settings.json` - Project-specific permissions

### Using Slash Commands

Once set up, these commands are available in any Claude Code session:

| Command | Description |
|---------|-------------|
| `/user:commit-push-pr` | Stage, commit, push, and create a PR |
| `/user:commit` | Quick local commit with conventional message |
| `/user:test` | Auto-detect and run project tests |
| `/user:lint` | Run linter with auto-fix |
| `/user:review` | Review current git changes |
| `/user:simplify` | Refactor and simplify recent changes |

### Using Plan Mode (Recommended)

Boris recommends starting most sessions in Plan mode:

```bash
claude
# Press Shift+Tab twice to enter Plan mode
# Iterate on the plan with Claude
# Then switch to auto-accept mode to execute
```

## Agent Identification

When running multiple agents in parallel, notifications will show **which agent** needs attention:

```
Claude Code [Frontend]    ← Custom name via CLAUDE_AGENT_NAME env var
Claude Code [agent-1]     ← Git branch name (best for worktrees)
Claude Code [Agent 3]     ← Extracted from directory name (e.g., project-agent-3)
Claude Code [my-project]  ← Project directory name fallback
```

### How It Works

The hooks automatically detect the agent identifier using this priority:

1. **CLAUDE_AGENT_NAME** - User-defined environment variable (best for multi-tab without worktrees)
2. **Git branch name** - Perfect for worktree setups where each agent works on a different branch
3. **Agent number** - Extracted from directory names like `project-agent-1`, `myapp-agent-3`
4. **Project name** - Falls back to the directory name

### Setting Custom Agent Names (Multi-Tab Setup)

For multiple Claude sessions in the **same project** (without worktrees), set a custom name in each terminal:

```bash
# Terminal 1 - Frontend work
export CLAUDE_AGENT_NAME="Frontend"
claude

# Terminal 2 - Backend work
export CLAUDE_AGENT_NAME="Backend"
claude

# Terminal 3 - Testing
export CLAUDE_AGENT_NAME="Tests"
claude
```

You can add these exports to your shell profile or create aliases:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias claude-frontend='CLAUDE_AGENT_NAME="Frontend" claude'
alias claude-backend='CLAUDE_AGENT_NAME="Backend" claude'
alias claude-tests='CLAUDE_AGENT_NAME="Tests" claude'
```

### Example Notifications

| Setup | Notification Title |
|-------|-------------------|
| `CLAUDE_AGENT_NAME="Frontend"` | `Claude Code [Frontend]` |
| Worktree on branch `feature-auth` | `Claude Code [feature-auth]` |
| Directory `myapp-agent-2` | `Claude Code [Agent 2]` |

### Notification Log

All notifications are logged with timestamps and agent IDs:

```bash
cat ~/.claude/logs/notifications.log
# [14:32:15] [agent-1] Notification from: myproject-agent-1
# [14:33:42] [feature-auth] Task complete in: myproject-agent-2
```

## Configuration Details

### Hooks

The setup includes three hooks:

#### Notification Hook
Triggers when Claude needs your input (permission prompt or idle for 60+ seconds).

```json
{
  "hooks": {
    "Notification": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/notify.sh",
        "timeout": 10
      }]
    }]
  }
}
```

#### Stop Hook
Triggers when Claude finishes responding.

#### PostToolUse Format Hook
Auto-formats code after Claude makes edits. Supports:
- JavaScript/TypeScript (Prettier)
- Python (Black, autopep8)
- Go (gofmt)
- Rust (rustfmt)
- Ruby (rubocop)
- Shell (shfmt)

### Permissions

The setup pre-approves common safe commands to reduce permission prompts:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(git:*)",
      "Bash(python:*)",
      "Bash(prettier:*)",
      // ... and many more
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(sudo rm:*)",
      // ... dangerous commands
    ]
  }
}
```

See [`settings.json`](#full-settingsjson) for the complete list.

## Windows Terminal Setup

For the best multi-agent experience, configure Windows Terminal to open 5 tabs on startup:

1. Open Windows Terminal Settings (Ctrl+,)
2. Click "Open JSON file" in the bottom left
3. Add to the root of the JSON:

```json
{
  "startupActions": "new-tab -p \"Ubuntu\" ; new-tab -p \"Ubuntu\" ; new-tab -p \"Ubuntu\" ; new-tab -p \"Ubuntu\" ; new-tab -p \"Ubuntu\""
}
```

### Renaming Tabs

You can rename tabs to identify which agent is which:
- Right-click on a tab → "Rename Tab"
- Or use the shortcut: Ctrl+Shift+R

## CLAUDE.md Best Practices

The `CLAUDE.md` file is crucial for getting good results. From Boris:

> "Anytime we see Claude do something incorrectly we add it to the CLAUDE.md, so Claude knows not to do it next time."

### Template Structure

```markdown
# Project Guidelines for Claude

## Project Overview
Brief description of what this project does.

## Tech Stack
- Frontend: React, TypeScript
- Backend: Node.js, PostgreSQL
- Testing: Jest, Playwright

## Key Commands
- `npm run dev` - Start development server
- `npm run test` - Run tests
- `npm run lint` - Lint code

## Code Style Guidelines
- Use functional components with hooks
- Prefer named exports
- Use TypeScript strict mode

## Things to Remember
- Always run tests before committing
- Use conventional commit messages

## Things to Avoid
- Don't commit directly to main
- Avoid console.log in production code

## Architecture Decisions
Document key decisions here.
```

## Subagents

For advanced workflows, you can create custom subagents. Add to your project's `.claude/agents.json`:

```json
{
  "code-simplifier": {
    "description": "Simplifies and cleans up code after changes",
    "prompt": "Review the recent changes and simplify the code. Remove duplication, improve naming, and make it more readable without changing functionality.",
    "tools": ["Read", "Edit", "Glob", "Grep"],
    "model": "sonnet"
  },
  "verify-app": {
    "description": "Tests the application end-to-end",
    "prompt": "Run the test suite and manually verify the app works correctly. Report any issues found.",
    "tools": ["Read", "Bash", "Glob"],
    "model": "sonnet"
  }
}
```

## Troubleshooting

### Notifications Not Working

The hooks use multiple fallback methods for Windows notifications:

1. **Windows Toast Notifications** (Windows 10+) - Built-in, no dependencies
2. **Balloon Notifications** - Fallback for older Windows
3. **System Sounds** - Always works as a last resort

**To test notifications manually:**

```powershell
# Test sound
[System.Media.SystemSounds]::Exclamation.Play()

# Test toast notification (Windows 10+)
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml('<toast><visual><binding template="ToastText02"><text id="1">Test</text><text id="2">This is a test</text></binding></visual></toast>')
$toast = New-Object Windows.UI.Notifications.ToastNotification $xml
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Test').Show($toast)
```

**Check Windows notification settings:**
- Settings → System → Notifications
- Ensure notifications are enabled
- Check "Focus Assist" isn't blocking notifications

### Hooks Not Running

1. **Verify hook files are executable**:
   ```bash
   ls -la ~/.claude/hooks/
   # Should show -rwxr-xr-x permissions
   ```

2. **Check settings.json syntax**:
   ```bash
   cat ~/.claude/settings.json | jq .
   ```

3. **Restart Claude Code** after changing settings.

### Permission Issues in WSL

If you get permission errors accessing Windows from WSL:

```bash
# Check if WSL can access PowerShell
which powershell.exe

# If not found, add to PATH in ~/.bashrc or ~/.zshrc
export PATH="$PATH:/mnt/c/Windows/System32/WindowsPowerShell/v1.0"
```

## Full settings.json

<details>
<summary>Click to expand complete settings.json</summary>

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/stop.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/format.sh",
            "timeout": 30
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(npm:*)",
      "Bash(npx:*)",
      "Bash(yarn:*)",
      "Bash(pnpm:*)",
      "Bash(node:*)",
      "Bash(bun:*)",
      "Bash(deno:*)",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(ls:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(less:*)",
      "Bash(more:*)",
      "Bash(grep:*)",
      "Bash(rg:*)",
      "Bash(find:*)",
      "Bash(fd:*)",
      "Bash(wc:*)",
      "Bash(sort:*)",
      "Bash(uniq:*)",
      "Bash(diff:*)",
      "Bash(echo:*)",
      "Bash(printf:*)",
      "Bash(pwd:*)",
      "Bash(cd:*)",
      "Bash(mkdir:*)",
      "Bash(touch:*)",
      "Bash(cp:*)",
      "Bash(mv:*)",
      "Bash(basename:*)",
      "Bash(dirname:*)",
      "Bash(realpath:*)",
      "Bash(which:*)",
      "Bash(whereis:*)",
      "Bash(type:*)",
      "Bash(file:*)",
      "Bash(stat:*)",
      "Bash(tree:*)",
      "Bash(prettier:*)",
      "Bash(eslint:*)",
      "Bash(tsc:*)",
      "Bash(jest:*)",
      "Bash(vitest:*)",
      "Bash(mocha:*)",
      "Bash(python:*)",
      "Bash(python3:*)",
      "Bash(pip:*)",
      "Bash(pip3:*)",
      "Bash(pytest:*)",
      "Bash(black:*)",
      "Bash(ruff:*)",
      "Bash(go:*)",
      "Bash(cargo:*)",
      "Bash(rustc:*)",
      "Bash(make:*)",
      "Bash(cmake:*)",
      "Bash(docker compose:*)",
      "Bash(docker-compose:*)",
      "Bash(jq:*)",
      "Bash(yq:*)",
      "Bash(curl -s:*)",
      "Bash(wget -q:*)",
      "Bash(date:*)",
      "Bash(env:*)",
      "Bash(export:*)",
      "Bash(source:*)",
      "Bash(seq:*)",
      "Bash(xargs:*)",
      "Bash(awk:*)",
      "Bash(sed:*)",
      "Bash(tr:*)",
      "Bash(cut:*)",
      "Bash(tee:*)"
    ],
    "deny": [
      "Bash(rm -rf /)",
      "Bash(rm -rf /*)",
      "Bash(rm -rf ~)",
      "Bash(rm -rf ~/*)",
      "Bash(sudo rm:*)",
      "Bash(sudo dd:*)",
      "Bash(mkfs:*)",
      "Bash(:(){ :|:& };:)",
      "Bash(chmod -R 777 /)",
      "Bash(chown -R:*)"
    ]
  }
}
```

</details>

## Boris's Original Tips

For reference, here are Boris's 13 tips that inspired this setup:

1. ✅ Run 5 Claudes in parallel with system notifications
2. ⏳ Run additional Claudes on claude.ai/code (web + mobile)
3. ✅ Use Opus 4.5 with thinking for everything
4. ✅ Share a single CLAUDE.md checked into git
5. ⏳ Use @.claude in PR reviews (requires GitHub Action)
6. ✅ Start most sessions in Plan mode
7. ✅ Use slash commands for repeated workflows
8. ✅ Use subagents for common tasks
9. ✅ Use PostToolUse hook to format code
10. ✅ Pre-allow safe commands instead of --dangerously-skip-permissions
11. ⏳ Integrate with Slack, BigQuery, Sentry via MCP
12. ⏳ Use background agents for long-running tasks
13. ✅ Give Claude a way to verify its work

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - feel free to use and modify as needed.

## Acknowledgments

- [Boris Cherney](https://www.linkedin.com/in/boris-cherny-3a8b2513/) for sharing his Claude Code workflow
- The [Claude Code team](https://github.com/anthropics/claude-code) at Anthropic

---

**Happy coding with Claude! 🚀**
