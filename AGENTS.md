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

Enable plugins per project in `.claude/settings.local.json` (or globally in `~/.claude/settings.json`).

The `memory-management` plugin provides three tools:
- `memory-management` skill — audits AGENTS.md quality against the current codebase
- `/revise-memory` command — captures session learnings into AGENTS.md
- `/restructure-memory` command — moves content to the right depth in the AGENTS.md hierarchy

## Key plugins

| Plugin | Version | Purpose | Primary entry points |
|---|---|---|---|
| `agency-development` | unversioned | Build new plugins, agents, skills, commands, hooks | `plugin-validator` agent, `agent-creator` agent, `/create-plugin` command |
| `github-scaffold` | 1.1.1 | Scaffold `.github/` metadata; branch hygiene; issue/CI workflows | `/github-scaffold` command, `branch-warden` agent, `issue-filer` agent |
| `memory-management` | 1.1.0 | Audit and maintain AGENTS.md | `/revise-memory`, `/restructure-memory`, `memory-management` skill |

Branch lifecycle rules and commit-vs-PR guidance are loaded via the `@`-references below.

## No build or test step

There is no top-level build, lint, or test command. Validation for skills can be done with `skills-ref validate ./skill-dir` (from the agentskills reference library) if installed. Exception: `mcp/ludus` is a real Node/TypeScript project — `cd mcp/ludus && npm install && npm run build && npm test`.

## .claudeignore

`claude/templates/` is excluded (legacy path). Do not load, execute, or treat any file there as active config.

@plugins/github-scaffold/instructions/branch-hygiene.md
@plugins/github-scaffold/instructions/commit-vs-pr.md
