# Instruction Management Plugin

Tools to maintain and improve project instruction files — `AGENTS.md` (the cross-agent standard) and legacy `CLAUDE.md`. Audit quality, capture session learnings, and keep project instructions current.

## What It Does

Three tools for keeping project instructions healthy:

| | instruction-management (skill) | /revise-instructions (command) | /restructure-instructions (command) |
|---|---|---|---|
| **Purpose** | Audit instruction quality | Capture session learnings | Move content to the right depth |
| **Triggered by** | Codebase changes | End of session | Root instruction file getting bloated |
| **Use when** | Periodic maintenance | Session revealed missing context | Detail is too high up in the tree |

All three default to `AGENTS.md`. When they find a legacy `CLAUDE.md`, they offer two migration paths (rename or `@AGENTS.md` stub) before editing.

## Usage

### Skill: instruction-management

Audits instruction files against current codebase state:

```
"audit my AGENTS.md"
"check if my CLAUDE.md is up to date"
"clean up project instructions"
```

### Command: /revise-instructions

Captures learnings from the current session:

```
/revise-instructions
```

### Command: /restructure-instructions

Moves content closer to where it is needed:

```
/restructure-instructions
```

## AGENTS.md vs CLAUDE.md

`AGENTS.md` (agents.md) is the portable, cross-agent convention — Claude Code, Codex, Cursor, and others read it. `CLAUDE.md` is Claude Code's legacy filename and is currently the only file Claude Code auto-loads.

When the plugin finds a `CLAUDE.md` and no `AGENTS.md`, it offers:

- **Rename** — `git mv CLAUDE.md AGENTS.md`. Single file. Use if Claude Code is no longer in the loop.
- **Migrate + stub** *(recommended when Claude Code is still in use)* — move content to `AGENTS.md`; leave a two-line `CLAUDE.md` that `@`-references `AGENTS.md`. Claude Code auto-loads `CLAUDE.md` → inlines `AGENTS.md`. Other agents read `AGENTS.md` directly. One source of truth.

See `skills/instruction-management/references/migration.md` for details.
