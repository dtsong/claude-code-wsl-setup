#!/bin/bash

#===============================================================================
# Claude Code Setup Script for Windows/WSL
# Based on Boris Cherney's workflow (creator of Claude Code)
#
# This script sets up:
# - Notification hooks for multi-agent workflows
# - Auto-formatting hooks
# - Pre-approved safe permissions
# - Starter slash commands
# - Project templates
#
# Usage: bash claude-code-setup.sh
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

#===============================================================================
# Pre-flight checks
#===============================================================================

print_header "Claude Code Setup Script"

echo "This script will configure Claude Code for a multi-agent workflow."
echo "It will create files in ~/.claude/ and optionally in your current project."
echo ""

# Check if running in WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
    print_success "Detected WSL environment"
    IS_WSL=true
else
    print_warning "Not running in WSL - some Windows-specific features may not work"
    IS_WSL=false
fi

# Check if Claude Code is installed
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    print_success "Claude Code is installed (version: $CLAUDE_VERSION)"
else
    print_warning "Claude Code not found in PATH - install with: npm install -g @anthropic-ai/claude-code"
fi

#===============================================================================
# Create directory structure
#===============================================================================

print_header "Creating Directory Structure"

mkdir -p ~/.claude/hooks
print_success "Created ~/.claude/hooks/"

mkdir -p ~/.claude/commands
print_success "Created ~/.claude/commands/"

#===============================================================================
# Create notification hook
#===============================================================================

print_header "Creating Notification Hooks"

cat > ~/.claude/hooks/notify.sh << 'HOOK_EOF'
#!/bin/bash
#===============================================================================
# Notification Hook
# Runs when Claude Code needs user input (permission prompt or idle)
# No third-party dependencies required!
#
# Agent identification priority:
# 1. CLAUDE_AGENT_NAME env var (user-defined per terminal)
# 2. Git branch name (for worktree setups)
# 3. Agent number from directory name (e.g., project-agent-3)
# 4. Project directory name (fallback)
#
# For multi-tab setups: export CLAUDE_AGENT_NAME="Frontend" in each terminal
#===============================================================================

PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
TIMESTAMP=$(date "+%H:%M:%S")

# Get agent identifier
get_agent_id() {
    # 1. User-defined agent name (best for multi-tab without worktrees)
    if [ -n "$CLAUDE_AGENT_NAME" ]; then echo "$CLAUDE_AGENT_NAME"; return; fi
    # 2. Git branch (works great with worktrees)
    if command -v git &> /dev/null; then
        if [ -d "${CLAUDE_PROJECT_DIR}/.git" ] || [ -f "${CLAUDE_PROJECT_DIR}/.git" ]; then
            BRANCH=$(cd "${CLAUDE_PROJECT_DIR}" 2>/dev/null && git branch --show-current 2>/dev/null)
            if [ -n "$BRANCH" ] && [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
                echo "$BRANCH"; return
            fi
        fi
    fi
    # 3. Agent number from directory pattern
    if [[ "$PROJECT_NAME" =~ -([0-9]+)$ ]]; then echo "Agent ${BASH_REMATCH[1]}"; return; fi
    # 4. Fallback to project name
    echo "$PROJECT_NAME"
}

AGENT_ID=$(get_agent_id)
NOTIFICATION_TITLE="Claude Code [$AGENT_ID]"
NOTIFICATION_MSG="Needs your input!"

mkdir -p ~/.claude/logs
echo "[${TIMESTAMP}] [$AGENT_ID] Notification from: ${PROJECT_NAME}" >> ~/.claude/logs/notifications.log

if grep -qi microsoft /proc/version 2>/dev/null; then
    powershell.exe -Command "
        [System.Media.SystemSounds]::Exclamation.Play()
        try {
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
            \$template = '<toast><visual><binding template=\"ToastText02\"><text id=\"1\">$NOTIFICATION_TITLE</text><text id=\"2\">$NOTIFICATION_MSG</text></binding></visual></toast>'
            \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            \$xml.LoadXml(\$template)
            \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
        } catch {
            try {
                Add-Type -AssemblyName System.Windows.Forms
                \$balloon = New-Object System.Windows.Forms.NotifyIcon
                \$balloon.Icon = [System.Drawing.SystemIcons]::Information
                \$balloon.BalloonTipTitle = '$NOTIFICATION_TITLE'
                \$balloon.BalloonTipText = '$NOTIFICATION_MSG'
                \$balloon.Visible = \$true
                \$balloon.ShowBalloonTip(5000)
                Start-Sleep -Milliseconds 5100
                \$balloon.Dispose()
            } catch { [System.Media.SystemSounds]::Exclamation.Play() }
        }
    " 2>/dev/null &
elif [[ "\$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$NOTIFICATION_MSG\" with title \"$NOTIFICATION_TITLE\" sound name \"Default\""
elif command -v notify-send &> /dev/null; then
    notify-send "$NOTIFICATION_TITLE" "$NOTIFICATION_MSG" --urgency=normal
else
    echo -e "\a"
fi

exit 0
HOOK_EOF

chmod +x ~/.claude/hooks/notify.sh
print_success "Created ~/.claude/hooks/notify.sh"

#===============================================================================
# Create stop hook
#===============================================================================

cat > ~/.claude/hooks/stop.sh << 'HOOK_EOF'
#!/bin/bash
#===============================================================================
# Stop Hook
# Runs when Claude Code finishes responding
# No third-party dependencies required!
#
# Agent identification priority:
# 1. CLAUDE_AGENT_NAME env var (user-defined per terminal)
# 2. Git branch name (for worktree setups)
# 3. Agent number from directory name (e.g., project-agent-3)
# 4. Project directory name (fallback)
#
# For multi-tab setups: export CLAUDE_AGENT_NAME="Frontend" in each terminal
#===============================================================================

PROJECT_NAME=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")
TIMESTAMP=$(date "+%H:%M:%S")

# Get agent identifier
get_agent_id() {
    # 1. User-defined agent name (best for multi-tab without worktrees)
    if [ -n "$CLAUDE_AGENT_NAME" ]; then echo "$CLAUDE_AGENT_NAME"; return; fi
    # 2. Git branch (works great with worktrees)
    if command -v git &> /dev/null; then
        if [ -d "${CLAUDE_PROJECT_DIR}/.git" ] || [ -f "${CLAUDE_PROJECT_DIR}/.git" ]; then
            BRANCH=$(cd "${CLAUDE_PROJECT_DIR}" 2>/dev/null && git branch --show-current 2>/dev/null)
            if [ -n "$BRANCH" ] && [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
                echo "$BRANCH"; return
            fi
        fi
    fi
    # 3. Agent number from directory pattern
    if [[ "$PROJECT_NAME" =~ -([0-9]+)$ ]]; then echo "Agent ${BASH_REMATCH[1]}"; return; fi
    # 4. Fallback to project name
    echo "$PROJECT_NAME"
}

AGENT_ID=$(get_agent_id)
NOTIFICATION_TITLE="Claude Code [$AGENT_ID]"
NOTIFICATION_MSG="Task complete!"

mkdir -p ~/.claude/logs
echo "[${TIMESTAMP}] [$AGENT_ID] Task complete in: ${PROJECT_NAME}" >> ~/.claude/logs/notifications.log

if grep -qi microsoft /proc/version 2>/dev/null; then
    powershell.exe -Command "
        [System.Media.SystemSounds]::Asterisk.Play()
        try {
            [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
            [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
            \$template = '<toast><visual><binding template=\"ToastText02\"><text id=\"1\">$NOTIFICATION_TITLE</text><text id=\"2\">$NOTIFICATION_MSG</text></binding></visual></toast>'
            \$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            \$xml.LoadXml(\$template)
            \$toast = New-Object Windows.UI.Notifications.ToastNotification \$xml
            [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Claude Code').Show(\$toast)
        } catch {
            try {
                Add-Type -AssemblyName System.Windows.Forms
                \$balloon = New-Object System.Windows.Forms.NotifyIcon
                \$balloon.Icon = [System.Drawing.SystemIcons]::Information
                \$balloon.BalloonTipTitle = '$NOTIFICATION_TITLE'
                \$balloon.BalloonTipText = '$NOTIFICATION_MSG'
                \$balloon.Visible = \$true
                \$balloon.ShowBalloonTip(3000)
                Start-Sleep -Milliseconds 3100
                \$balloon.Dispose()
            } catch { }
        }
    " 2>/dev/null &
elif [[ "\$OSTYPE" == "darwin"* ]]; then
    osascript -e "display notification \"$NOTIFICATION_MSG\" with title \"$NOTIFICATION_TITLE\" sound name \"Glass\""
elif command -v notify-send &> /dev/null; then
    notify-send "$NOTIFICATION_TITLE" "$NOTIFICATION_MSG" --urgency=low
else
    echo -e "\a"
fi

exit 0
HOOK_EOF

chmod +x ~/.claude/hooks/stop.sh
print_success "Created ~/.claude/hooks/stop.sh"

#===============================================================================
# Create format hook
#===============================================================================

cat > ~/.claude/hooks/format.sh << 'HOOK_EOF'
#!/bin/bash
#===============================================================================
# PostToolUse Format Hook
# Auto-formats code after Claude makes edits
#===============================================================================

# Exit early if no file paths provided
if [ -z "$CLAUDE_FILE_PATHS" ]; then
    exit 0
fi

# Process each file
for file in $CLAUDE_FILE_PATHS; do
    # Skip if file doesn't exist
    if [ ! -f "$file" ]; then
        continue
    fi

    # Format based on file extension
    case "$file" in
        # JavaScript/TypeScript/Web files - use Prettier
        *.js|*.jsx|*.ts|*.tsx|*.json|*.md|*.css|*.scss|*.less|*.html|*.vue|*.svelte)
            if command -v prettier &> /dev/null; then
                prettier --write "$file" 2>/dev/null || true
            fi
            ;;

        # Python files - use Black or autopep8
        *.py)
            if command -v black &> /dev/null; then
                black --quiet "$file" 2>/dev/null || true
            elif command -v autopep8 &> /dev/null; then
                autopep8 --in-place "$file" 2>/dev/null || true
            fi
            ;;

        # Go files - use gofmt
        *.go)
            if command -v gofmt &> /dev/null; then
                gofmt -w "$file" 2>/dev/null || true
            fi
            ;;

        # Rust files - use rustfmt
        *.rs)
            if command -v rustfmt &> /dev/null; then
                rustfmt "$file" 2>/dev/null || true
            fi
            ;;

        # Ruby files - use rubocop
        *.rb)
            if command -v rubocop &> /dev/null; then
                rubocop --autocorrect --silent "$file" 2>/dev/null || true
            fi
            ;;

        # Shell scripts - use shfmt
        *.sh|*.bash)
            if command -v shfmt &> /dev/null; then
                shfmt -w "$file" 2>/dev/null || true
            fi
            ;;
    esac
done

exit 0
HOOK_EOF

chmod +x ~/.claude/hooks/format.sh
print_success "Created ~/.claude/hooks/format.sh"

#===============================================================================
# Create main settings.json
#===============================================================================

print_header "Creating Settings Configuration"

cat > ~/.claude/settings.json << 'SETTINGS_EOF'
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
SETTINGS_EOF

print_success "Created ~/.claude/settings.json"

#===============================================================================
# Create global slash commands
#===============================================================================

print_header "Creating Global Slash Commands"

# Commit, push, and create PR command
cat > ~/.claude/commands/commit-push-pr.md << 'CMD_EOF'
Create a commit, push to remote, and open a pull request for the current changes.

First, gather context about the current state:
```bash
git status
git diff --stat
git branch --show-current
git log -3 --oneline
```

Then follow these steps:
1. Review the changes and create a clear, descriptive commit message following conventional commits format (feat:, fix:, docs:, refactor:, test:, chore:)
2. Stage all changes with `git add -A`
3. Commit with the descriptive message
4. Push to the current branch (create upstream tracking if needed with `git push -u origin <branch>`)
5. Create a PR using `gh pr create --fill` or with a custom title/body if the changes warrant more description

If there are no changes to commit, let me know.
If we're on main/master, suggest creating a feature branch first.
CMD_EOF

print_success "Created ~/.claude/commands/commit-push-pr.md"

# Quick commit command
cat > ~/.claude/commands/commit.md << 'CMD_EOF'
Create a commit for the current staged or unstaged changes.

```bash
git status
git diff --stat
```

Create an appropriate commit message following conventional commits format and commit the changes.
Do not push - just commit locally.
CMD_EOF

print_success "Created ~/.claude/commands/commit.md"

# Test command
cat > ~/.claude/commands/test.md << 'CMD_EOF'
Run the project's test suite and report results.

First, detect the project type and find the appropriate test command:
```bash
ls package.json pyproject.toml setup.py Cargo.toml go.mod Makefile 2>/dev/null
```

Then run the appropriate test command:
- Node.js: `npm test` or `yarn test` or `pnpm test`
- Python: `pytest` or `python -m pytest`
- Go: `go test ./...`
- Rust: `cargo test`
- Make: `make test`

Report the results clearly. If tests fail, analyze the failures and suggest fixes.
CMD_EOF

print_success "Created ~/.claude/commands/test.md"

# Lint command
cat > ~/.claude/commands/lint.md << 'CMD_EOF'
Run linting and fix any auto-fixable issues.

First, detect the project type:
```bash
ls package.json pyproject.toml setup.py Cargo.toml go.mod 2>/dev/null
```

Then run the appropriate linter:
- Node.js: `npm run lint` or `npx eslint . --fix`
- Python: `ruff check --fix .` or `black .`
- Go: `go fmt ./...` and `go vet ./...`
- Rust: `cargo fmt` and `cargo clippy`

Report any issues that couldn't be auto-fixed.
CMD_EOF

print_success "Created ~/.claude/commands/lint.md"

# Review command
cat > ~/.claude/commands/review.md << 'CMD_EOF'
Review the current changes and provide feedback.

```bash
git diff
git diff --cached
```

Analyze the changes and provide:
1. A summary of what the changes do
2. Any potential issues or bugs
3. Suggestions for improvement
4. Security considerations if applicable

Be constructive and specific in the feedback.
CMD_EOF

print_success "Created ~/.claude/commands/review.md"

# Simplify command (Boris's code-simplifier as a command)
cat > ~/.claude/commands/simplify.md << 'CMD_EOF'
Review recent changes and simplify the code.

```bash
git diff HEAD~1 --name-only
```

For each changed file, look for opportunities to:
1. Remove code duplication
2. Improve variable and function naming
3. Simplify complex conditionals
4. Extract reusable functions
5. Improve readability

Make the improvements without changing functionality. Run tests after to verify nothing broke.
CMD_EOF

print_success "Created ~/.claude/commands/simplify.md"

#===============================================================================
# Create project template files
#===============================================================================

print_header "Creating Project Templates"

mkdir -p ~/.claude/templates
print_success "Created ~/.claude/templates/"

# CLAUDE.md template
cat > ~/.claude/templates/CLAUDE.md << 'TEMPLATE_EOF'
# Project Guidelines for Claude

## Project Overview
<!-- Brief description of what this project does -->

## Tech Stack
<!-- List main technologies, frameworks, and tools -->

## Key Commands
```bash
# Development
npm run dev          # Start development server

# Testing
npm run test         # Run test suite
npm run test:watch   # Run tests in watch mode

# Building
npm run build        # Production build
npm run lint         # Run linter
```

## Project Structure
```
src/
├── components/     # Reusable UI components
├── pages/          # Page components
├── hooks/          # Custom React hooks
├── utils/          # Utility functions
├── types/          # TypeScript types
└── api/            # API client code
```

## Code Style Guidelines
<!-- Add specific style rules for this project -->
- Use functional components with hooks
- Prefer named exports over default exports
- Use TypeScript strict mode

## Things to Remember
<!-- Add learnings and gotchas as you discover them -->
- Always run tests before committing
- Use conventional commit messages

## Things to Avoid
<!-- Add anti-patterns and mistakes to avoid -->
- Don't commit directly to main
- Avoid console.log in production code

## Architecture Decisions
<!-- Document key architectural decisions -->

## Environment Setup
<!-- Any special setup instructions -->
TEMPLATE_EOF

print_success "Created ~/.claude/templates/CLAUDE.md"

# Project settings.json template
cat > ~/.claude/templates/settings.json << 'TEMPLATE_EOF'
{
  "permissions": {
    "allow": [
      "Bash(npm run:*)",
      "Bash(npm test:*)",
      "Bash(npm run dev)",
      "Bash(npm run build)",
      "Bash(npm run lint:*)"
    ]
  }
}
TEMPLATE_EOF

print_success "Created ~/.claude/templates/settings.json"

#===============================================================================
# Create helper script for initializing projects
#===============================================================================

cat > ~/.claude/init-project.sh << 'INIT_EOF'
#!/bin/bash
#===============================================================================
# Initialize Claude Code configuration for a project
# Usage: ~/.claude/init-project.sh [project-directory]
#===============================================================================

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Directory $PROJECT_DIR does not exist"
    exit 1
fi

cd "$PROJECT_DIR"

# Create .claude directory
mkdir -p .claude/commands

# Copy CLAUDE.md template if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
    cp ~/.claude/templates/CLAUDE.md ./CLAUDE.md
    echo "✓ Created CLAUDE.md (remember to customize it!)"
else
    echo "⚠ CLAUDE.md already exists, skipping"
fi

# Copy project settings template if it doesn't exist
if [ ! -f ".claude/settings.json" ]; then
    cp ~/.claude/templates/settings.json .claude/settings.json
    echo "✓ Created .claude/settings.json"
else
    echo "⚠ .claude/settings.json already exists, skipping"
fi

echo ""
echo "Project initialized! Next steps:"
echo "1. Edit CLAUDE.md to describe your project"
echo "2. Edit .claude/settings.json to add project-specific permissions"
echo "3. Add project-specific commands to .claude/commands/"
echo "4. Run 'claude' to start coding!"
INIT_EOF

chmod +x ~/.claude/init-project.sh
print_success "Created ~/.claude/init-project.sh"

#===============================================================================
# Create worktree helper script
#===============================================================================

cat > ~/.claude/create-worktrees.sh << 'WORKTREE_EOF'
#!/bin/bash
#===============================================================================
# Create git worktrees for parallel Claude Code agents
# Usage: ~/.claude/create-worktrees.sh [number-of-agents] [base-name]
#===============================================================================

NUM_AGENTS="${1:-5}"
BASE_NAME="${2:-agent}"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
PARENT_DIR=$(dirname "$REPO_ROOT")

echo "Creating $NUM_AGENTS worktrees for parallel Claude Code agents..."
echo ""

for i in $(seq 1 $NUM_AGENTS); do
    WORKTREE_DIR="${PARENT_DIR}/${REPO_NAME}-${BASE_NAME}-${i}"
    BRANCH_NAME="${BASE_NAME}-${i}"
    
    if [ -d "$WORKTREE_DIR" ]; then
        echo "⚠ Worktree $WORKTREE_DIR already exists, skipping"
    else
        # Create branch if it doesn't exist
        if ! git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
            git branch "$BRANCH_NAME" 2>/dev/null || true
        fi
        
        git worktree add "$WORKTREE_DIR" "$BRANCH_NAME" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo "✓ Created worktree: $WORKTREE_DIR (branch: $BRANCH_NAME)"
        else
            # If branch exists, just create worktree
            git worktree add "$WORKTREE_DIR" -b "$BRANCH_NAME" 2>/dev/null || \
            git worktree add "$WORKTREE_DIR" "$BRANCH_NAME" 2>/dev/null
            echo "✓ Created worktree: $WORKTREE_DIR"
        fi
    fi
done

echo ""
echo "Worktrees created! To run 5 parallel agents:"
echo ""
for i in $(seq 1 $NUM_AGENTS); do
    echo "  Terminal $i: cd ${PARENT_DIR}/${REPO_NAME}-${BASE_NAME}-${i} && claude"
done
echo ""
echo "To remove all worktrees later:"
echo "  git worktree list"
echo "  git worktree remove <path>"
WORKTREE_EOF

chmod +x ~/.claude/create-worktrees.sh
print_success "Created ~/.claude/create-worktrees.sh"

#===============================================================================
# Windows-specific setup instructions
#===============================================================================

print_header "Setup Complete!"

echo "Your Claude Code environment has been configured with:"
echo ""
echo "  📁 ~/.claude/settings.json     - Main configuration with hooks & permissions"
echo "  📁 ~/.claude/hooks/            - Notification, stop, and format hooks"
echo "  📁 ~/.claude/commands/         - Global slash commands"
echo "  📁 ~/.claude/templates/        - Project templates"
echo "  📁 ~/.claude/init-project.sh   - Initialize new projects"
echo "  📁 ~/.claude/create-worktrees.sh - Create parallel agent worktrees"
echo ""

print_header "Next Steps"

echo "1. ${YELLOW}Initialize your project:${NC}"
echo "   ${GREEN}~/.claude/init-project.sh /path/to/your/project${NC}"
echo "   Or cd into your project and run: ${GREEN}~/.claude/init-project.sh${NC}"
echo ""

echo "2. ${YELLOW}Set up parallel agents (optional):${NC}"
echo "   cd into your git repo and run:"
echo "   ${GREEN}~/.claude/create-worktrees.sh 5${NC}"
echo ""

echo "3. ${YELLOW}Configure Windows Terminal for 5 tabs:${NC}"
echo "   Add to Windows Terminal settings.json:"
echo '   "startupActions": "new-tab ; new-tab ; new-tab ; new-tab ; new-tab"'
echo ""

echo "4. ${YELLOW}Start using Claude Code:${NC}"
echo "   ${GREEN}claude${NC}"
echo "   Use ${GREEN}Shift+Tab${NC} twice to enter Plan mode (recommended)"
echo ""

echo "Available slash commands:"
echo "   /user:commit-push-pr  - Commit, push, and create PR"
echo "   /user:commit          - Quick commit"
echo "   /user:test            - Run tests"
echo "   /user:lint            - Run linter"
echo "   /user:review          - Review changes"
echo "   /user:simplify        - Simplify recent code changes"
echo ""

print_success "Setup complete! Happy coding with Claude! 🚀"
