# Contributing

Thanks for contributing.

## Principles

- Keep changes practical and composable.
- Prefer small, reviewable pull requests.
- Preserve compatibility with Claude Code workflows.

## Repository Structure

- `skills/` contains Claude Code skills (each skill is a directory with `SKILL.md`).
- `agents/` contains agent persona markdown (21 council + 17 academy).
- `commands/` contains slash command prompt files and the shared deliberation engine.
- `scripts/` and `hooks/` contain shell automation used by this setup.
- `workspaces/` contains project-specific context templates.
- `templates/` contains project initialization templates.
- `legacy/` contains the original monolithic installer (preserved for reference).

## Pull Requests

- Explain why the change exists.
- Include before/after behavior when relevant.
- Update docs when behavior changes (especially `README.md` and `ARCHITECTURE.md`).

## Ways to Contribute

- **Onboarding feedback:** if you ran the installer for the first time, report what was confusing or brittle.
- **Docs:** clarify adoption paths, presets/flags, or third-party attribution.
- **Skills/agents/commands:** fix incorrect guidance, tighten triggers, or add concise examples.
- **Installer hardening:** improve conflict handling, manifest uninstall behavior, and dry-run correctness.
- **WSL improvements:** better notification handling, cross-boundary compatibility.

## Workflow

- Create a branch from `main`.
- Open (or reference) a GitHub issue that explains what you're changing and why.
- Open a pull request.
- Keep changes focused (small PRs merge faster).
- Link the issue in the PR description (e.g. `Closes #123` or `Refs #123`) so the rationale is easy to find later.

## Local Validation

Run these checks before opening a PR:

```bash
# Shell
bash -n install.sh
bash -n hooks/*.sh
bash -n scripts/*.sh

# JSON
python3 -m json.tool settings.json >/dev/null
python3 -m json.tool hooks.json >/dev/null

# Installer smoke test (safe, isolated)
CLAUDE_DIR="/tmp/claude-test" ./install.sh --preset skills --conflict-policy fail
CLAUDE_DIR="/tmp/claude-test" ./install.sh --uninstall
```

## Documentation Expectations

- Prefer minimal-diff edits.
- Keep paths and commands copy/pasteable.
- Avoid introducing non-ASCII characters unless the file already uses them.
