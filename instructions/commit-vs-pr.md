## Commit directly to main

Use a direct commit when the change is:

- **Self-contained and low-risk** — a single file change or a tightly coupled set of changes with an obvious correct outcome (typo fix, label update, adding a `workflow_dispatch` trigger).
- **Configuration or housekeeping** — settings, `.claudeignore`, workflow tweaks, adding an `@file` reference to `CLAUDE.md`.
- **Instruction or documentation only** — adding or editing files under `instructions/`, updating `CLAUDE.md` / `AGENTS.md` with no behaviour change to agents or skills.
- **Unambiguous implementation of a prior decision** — the approach was already agreed in an issue or conversation; the commit is execution, not deliberation.

## Open a pull request

Open a PR when:

- **Multiple logical changes are bundled** — even if individually simple, grouping them for review makes intent clear and revert easier.
- **The change affects agent or skill behaviour** — modifications to `agents/`, `skills/`, `plugins/`, or `mcp/` that could alter how a session runs warrant a second look before landing on main.
- **The correct approach is uncertain** — if the implementation required non-obvious choices, a PR surfaces those choices for inspection.
- **The change touches shared infrastructure** — workflow files that affect CI/CD for the whole repo, `marketplace.json`, global settings.

## Default rule

When in doubt: **commit directly** for instructions and config; **open a PR** for anything that changes how an agent, skill, plugin, or MCP server behaves.
