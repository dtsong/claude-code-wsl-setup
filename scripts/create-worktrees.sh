#!/bin/bash
#===============================================================================
# Create git worktrees for parallel Claude Code agents
# Usage: ./create-worktrees.sh [number-of-agents] [base-name]
#
# Example: ./create-worktrees.sh 5 agent
# Creates: ../project-agent-1, ../project-agent-2, etc.
#===============================================================================

set -e

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
echo "=========================================="
echo "Worktrees created! To run $NUM_AGENTS parallel agents:"
echo "=========================================="
echo ""
for i in $(seq 1 $NUM_AGENTS); do
    echo "  Terminal $i: cd ${PARENT_DIR}/${REPO_NAME}-${BASE_NAME}-${i} && claude"
done
echo ""
echo "=========================================="
echo "To remove all worktrees later:"
echo "=========================================="
echo "  git worktree list"
echo "  git worktree remove <path>"
