# AGENTS.md

This file provides guidance to AI agents (Claude Code, Codex, Cursor, etc.) when working with code in this repository.

# agency

Personal LLM configuration repository — skills, plugins, agents, and templates, primarily targeting Claude Code.

## Repository layout

Top-level content directories:

- `skills/` — standalone skill definitions (each dir has a `SKILL.md` with YAML frontmatter + instructions)
- `plugins/` — distributable plugin bundles; the local marketplace (`/.claude-plugin/marketplace.json`) points here
- `mcp/` — MCP servers and their packaging (e.g. `mcp/ludus`, a Node/TypeScript stdio server with a `Dockerfile` + Docker MCP Gateway catalog; see `mcp/ludus/README.md`)
- `templates/` — drop-in Claude Code settings variants: `settings.hooked.json`, `settings.unhooked.json`

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

Plugins are directories with a `.claude-plugin/plugin.json` manifest. The local marketplace at `/.claude-plugin/marketplace.json` registers full plugins under `./plugins/` plus many skills exposed as plugin sources under `./skills/`. Check `marketplace.json` for the current list — it changes as new skills/plugins are added.

Enable plugins at project scope in `.claude/settings.json` (committed, follows the repo). Personal overrides go in `.claude/settings.local.json` (gitignored). Global defaults live in `~/.claude/settings.json`.

## Plugin versioning

When a change deviates from `origin/main`, bump the version in **both** `plugins/<name>/.claude-plugin/plugin.json` and the matching entry in `.claude-plugin/marketplace.json`:

- **0.0.1** — minor modifications to an existing artifact: adding/removing a slash-command file, tweaking auto-trigger descriptions, small edits to an existing agent or skill.
- **0.1.0** — adding or removing a whole artifact (or most of one): new agent, new skill, new hook, removing an entire command, etc.

## Key plugins

| Plugin | Version | Purpose | Primary entry points |
|---|---|---|---|
| `agency-development` | 1.0.2 | Build new plugins, agents, skills, commands, hooks | `plugin-validator` agent, `agent-creator` agent, `/create-plugin` command, `/create-skill` command, `/create-agent` command, `/pin-plugins` command |
| `github-scaffold` | 1.1.1 | Scaffold `.github/` metadata; branch hygiene; issue/CI workflows | `/github-scaffold` command, `branch-warden` agent, `issue-filer` agent |
| `memory-management` | 1.2.2 | Audit and maintain AGENTS.md; nudges `/revise-memory` on busy sessions | `/revise-memory`, `/restructure-memory`, `memory-management` skill |
| `hooks-toolkit` | 0.1.0 | Composable safety hooks — force-push guard, secret scanner, manifest validators | `hooks/hooks.json`, `/install-hook` command |
| `ember` | 1.0.2 | AI partner agent — carries fire from person to person for AI onboarding | `Ember` agent |
| `naming-toolkit` | 0.1.0 | Conjures memorable, brandable name shortlists by reading a project and applying ≥4 naming techniques | `name-alchemist` agent |

Branch lifecycle rules and commit-vs-PR guidance are loaded via the `@`-references below.

## No build or test step

There is no top-level build, lint, or test command. Validation for skills can be done with `skills-ref validate ./skill-dir` (from the agentskills reference library) if installed.

## .claudeignore

`claude/templates/` is excluded (legacy path). Do not load, execute, or treat any file there as active config.

## Subdirectory context

- MCP servers: @mcp/ludus/AGENTS.md

@plugins/github-scaffold/instructions/branch-hygiene.md
@plugins/github-scaffold/instructions/commit-vs-pr.md
