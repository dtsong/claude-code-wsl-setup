#!/bin/bash
#===============================================================================
# PostToolUse Format Hook
# Auto-formats code after Claude makes edits
#
# Supports: JavaScript, TypeScript, Python, Go, Rust, Ruby, Shell
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
