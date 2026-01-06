#!/bin/bash
#===============================================================================
# Initialize Claude Code configuration for a project
# Usage: ./init-project.sh [project-directory]
#===============================================================================

set -e

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Directory $PROJECT_DIR does not exist"
    exit 1
fi

cd "$PROJECT_DIR"

echo "Initializing Claude Code configuration in $(pwd)..."
echo ""

# Create .claude directory
mkdir -p .claude/commands

# Copy CLAUDE.md template if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
    if [ -f ~/.claude/templates/CLAUDE.md ]; then
        cp ~/.claude/templates/CLAUDE.md ./CLAUDE.md
        echo "✓ Created CLAUDE.md (remember to customize it!)"
    else
        echo "⚠ CLAUDE.md template not found, skipping"
    fi
else
    echo "⚠ CLAUDE.md already exists, skipping"
fi

# Copy project settings template if it doesn't exist
if [ ! -f ".claude/settings.json" ]; then
    if [ -f ~/.claude/templates/project-settings.json ]; then
        cp ~/.claude/templates/project-settings.json .claude/settings.json
        echo "✓ Created .claude/settings.json"
    else
        echo "⚠ Project settings template not found, skipping"
    fi
else
    echo "⚠ .claude/settings.json already exists, skipping"
fi

echo ""
echo "Project initialized! Next steps:"
echo "  1. Edit CLAUDE.md to describe your project"
echo "  2. Edit .claude/settings.json to add project-specific permissions"
echo "  3. Add project-specific commands to .claude/commands/"
echo "  4. Run 'claude' to start coding!"
