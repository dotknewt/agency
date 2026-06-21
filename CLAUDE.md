# llm monorepo

Four sub-projects, each with their own CLAUDE.md:
- `plugins/` — Claude Code plugin repository distributed via marketplace.json
- `claude-templates/` — Reusable skills, agents, commands, hooks for Claude Code projects
- `agency/` — Agent and skill definitions (in development, no CLAUDE.md yet)
- `skills/` — Standalone skill definitions (no CLAUDE.md — see `Skill-Specification.md`)

Each sub-project is independent — read its CLAUDE.md before working in it. No top-level
build or test step; all workflows are per-sub-project.
