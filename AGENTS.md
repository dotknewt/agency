# AGENTS.md

This file provides guidance to AI agents (Claude Code, Codex, Cursor, etc.) when working with code in this repository.

# agency

Personal LLM configuration repository — skills, plugins, agents, and templates, primarily targeting Claude Code.

## Repository layout

Top-level content directories:

- `skills/` — standalone skill definitions (each dir has a `SKILL.md` with YAML frontmatter + instructions)
- `plugins/` — distributable plugin bundles; see `plugins/AGENTS.md` for versioning rules and the plugin catalog
- `agents/` — standalone agent-persona plugins (`agent-ember`, `agent-doublecheck`, `agent-eyeball`) that don't fit the `plugins/` catalog's build-tooling theme; same plugin.json layout, separate catalog
- `templates/` — example settings/hooks configs: `settings.json` (full example with `enabledPlugins`) and `hooks.json` (references `integrations/claude_code_hooks/*.py`, which doesn't exist in this repo — treat as an unfinished template, not working config)

Plugins bundle their own agents and instructions under `plugins/<name>/agents/` and `plugins/<name>/instructions/` respectively.

## Skill format

Skills follow the Agent Skills spec (`skills/Skill-Specification.md`). Minimum required:

```yaml
---
name: skill-name          # lowercase, hyphens only, must match directory name
description: >
  One-paragraph trigger description — this is the primary signal for activation.
---
```

Body: markdown instructions. Keep `SKILL.md` under 500 lines; move details to `references/` or `scripts/` subdirs.

Skills have no `model` field — model selection is session/project level (via `/model` or `settings.json`).

## Plugin format

Plugins are directories with a `.claude-plugin/plugin.json` manifest. The local marketplace at `/.claude-plugin/marketplace.json` registers full plugins under `./plugins/` and `./agents/`, plus many skills exposed as plugin sources under `./skills/`. Check `marketplace.json` for the current list — it changes as new skills/plugins are added.

Enable plugins repo-wide in `.claude/settings.json` (tracked in git — the file `/pin-plugins` writes to). Use `.claude/settings.local.json` for personal-only overrides (gitignored), or `~/.claude/settings.json` for user-global defaults.

The `instruction-management` plugin provides three skills: `instruction-management` (audits AGENTS.md quality, then orchestrates the other two by default), `revise-instructions` (captures session learnings), and `restructure-instructions` (moves content to the right depth).

Branch lifecycle rules and commit-vs-PR guidance are loaded via the `@`-references below.

## No build or test step

There is no top-level build, lint, or test command. Validation for skills can be done with `skills-ref validate ./skill-dir` (from the agentskills reference library) if installed.

## .claudeignore

`claude/templates/` is excluded (legacy path). Do not load, execute, or treat any file there as active config.

@plugins/github-toolkit/instructions/branch-hygiene.md
@plugins/github-toolkit/instructions/commit-vs-pr.md
