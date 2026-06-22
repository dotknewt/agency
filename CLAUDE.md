# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# agency

Personal LLM configuration repository — skills, plugins, agents, and templates, primarily targeting Claude Code.

## Repository layout

Top-level content directories:

- `skills/` — standalone skill definitions (each dir has a `SKILL.md` with YAML frontmatter + instructions)
- `plugins/` — distributable plugin bundles; the local marketplace (`/.claude-plugin/marketplace.json`) points here
- `mcp/` — MCP servers and their packaging (e.g. `mcp/ludus`, a Node/TypeScript stdio server with a `Dockerfile` + Docker MCP Gateway catalog; see `mcp/ludus/README.md`)
- `claude/templates/` — reference material and copy-paste templates:
  - `project-directory.example/` — canonical `.claude/` layout (agents, commands, skills, hooks, settings)
  - `hooks/` — PreToolUse/PostToolUse shell scripts
  - `agents/` — subagent definition examples
  - `mcp-wrapper/` — Python MCP server scaffold
  - `plugins/` — vendored source copies of published plugins (claude-context-optimizer, code-simplifier, mcp-server-dev)
  - `Extension-Points.md` — overview of every Claude Code extension point
  - `Quick-Reference.md` — detailed Claude Code reference (commands, shortcuts, context management)

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

Plugins are directories with a `.claude-plugin/plugin.json` manifest. The local marketplace at `/.claude-plugin/marketplace.json` registers entries: the `memory-management` plugin (`./plugins/memory-management`) and the `ludus-cli` skill exposed as a plugin source (`./skills/ludus-cli`). `memory-management` is enabled via `.claude/settings.local.json`.

The `memory-management` plugin provides three tools:
- `memory-management` skill — audits CLAUDE.md quality against the current codebase
- `/revise-memory` command — captures session learnings into CLAUDE.md
- `/restructure-memory` command — moves content to the right depth in the CLAUDE.md hierarchy

## No build or test step

There is no top-level build, lint, or test command. Validation for skills can be done with `skills-ref validate ./skill-dir` (from the agentskills reference library) if installed. Exception: `mcp/ludus` is a real Node/TypeScript project — `cd mcp/ludus && npm install && npm run build && npm test`.

## .claudeignore

`claude/templates/` is excluded. It is human-only reference material — do not load, execute, or treat any file there as active config.
