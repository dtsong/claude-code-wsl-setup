# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [2.0.0] - 2026-02-13

Major expansion bringing feature parity with `my-claude-setup`.

### Added

- Symlink-based installer (`install.sh`) with presets (skills/core/full), WSL detection, conflict policies, and manifest-based uninstall
- 34 agent personas (17 Council + 17 Academy)
- Shared deliberation engine (`_council-engine.md`) with 8 modes
- `/council` and `/academy` multi-agent deliberation commands
- `/brainstorm` quick 3-agent gut check
- 48 structured skill templates across 16 departments
- 15 standalone skill packs (git-workflows, github-workflow, language-conventions, terraform, dbt, and more)
- Issue-driven execution commands: `/looper`, `/implement`, `/ralf`, `/roadmap-executor`, `/create-issues`
- Project scaffolding commands: `/new-python`, `/new-typescript`, `/new-terraform`, `/new-mcp-server`
- Session management: `/handover`, `/ops`, `/g`
- PreCompact hook for auto-session handover before context compaction
- Workspace context system for project-specific auto-loading
- 8 utility scripts for agent management and workspace discovery
- `hooks.json` for standalone PreCompact hook
- ARCHITECTURE.md technical reference
- CONTRIBUTING.md contributor guide
- CI validation workflow (`.github/workflows/validate.yml`)

### Changed

- `settings.json` now includes `env` block and `PreCompact` hook alongside existing hooks and permissions
- `.gitignore` expanded for runtime state, telemetry, and auto-generated data
- Old monolithic installer moved to `legacy/claude-code-setup.sh`

### Preserved

- All existing WSL features: notification hooks, auto-format hook, permissions, worktree scripts
- Original 6 slash commands: commit, commit-push-pr, test, lint, review, simplify
- Project templates for initialization

## [1.0.0] - 2026-02-12

Initial release — WSL-focused Claude Code multi-agent setup.

### Added

- Monolithic setup script (`claude-code-setup.sh`)
- Windows toast notification hooks (notify, stop)
- Auto-format hook for PostToolUse
- Pre-approved permissions for 76 safe commands
- 6 slash commands: commit, commit-push-pr, test, lint, review, simplify
- Git worktree helper for parallel agents
- Project initialization script
- Agent identification via CLAUDE_AGENT_NAME
