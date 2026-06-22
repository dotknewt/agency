# CLAUDE.md Management Plugin

Tools to maintain and improve CLAUDE.md files - audit quality, capture session learnings, and keep project memory current.

## What It Does

Three tools for keeping project memory healthy:

| | memory-management (skill) | /revise-memory (command) | /restructure-memory (command) |
|---|---|---|---|
| **Purpose** | Audit CLAUDE.md quality | Capture session learnings | Move content to the right depth |
| **Triggered by** | Codebase changes | End of session | Root CLAUDE.md getting bloated |
| **Use when** | Periodic maintenance | Session revealed missing context | Detail is too high up in the tree |

## Usage

### Skill: memory-management

Audits CLAUDE.md files against current codebase state:

```
"audit my CLAUDE.md files"
"check if my CLAUDE.md is up to date"
```

### Command: /revise-memory

Captures learnings from the current session:

```
/revise-memory
```

### Command: /restructure-memory

Moves content closer to where it is needed:

```
/restructure-memory
```
