# AGENTS.md

This file provides guidance to AI agents (Claude Code, Codex, Cursor, etc.) when working with code in this repository.

# agency

`agency` is the thin, aggregating Claude Code plugin marketplace at the root of a multi-repo split. It hosts no *distributable* plugin content itself — every marketplace-listed plugin is sourced from one of three sibling repos, each independently addable as its own marketplace too:

- [`dotknewt/skills`](https://github.com/dotknewt/skills) — standalone single-skill plugins (bare `SKILL.md` dirs, no `plugin.json`)
- [`dotknewt/agents`](https://github.com/dotknewt/agents) — agent-persona plugins, each bundling an agent `.md` with its own dedicated skills
- [`dotknewt/toolkits`](https://github.com/dotknewt/toolkits) — composite plugins bundling skills+agents+commands+hooks together, including `ludus-toolkit` (bundles a full separate npm/TS MCP server project — merged into `toolkits` after briefly living in its own repo; sourced the same `git-subdir` way as every other toolkit, not a whole-repo source)

This split lets users install a single skill, a single agent, a whole toolkit, or any combination — instead of one all-or-nothing repo.

`agency`'s own working tree also has three things that are **not** part of the marketplace:
- `.claude/` — local-only Claude Code config for developing plugins in this repo (agents: `agent-creator`, `plugin-validator`, `skill-reviewer`, `statusline-setup`; commands: `create-agent`, `create-plugin`, `create-skill`, `pin-plugins`; skills covering agent/command/hook/mcp/plugin development). No `plugin.json` — never published, just tooling for building what ships to the sibling repos.
- `specs/agents/Agent-Specification.md`, `specs/skills/Skill-Specification.md` — reference specs consumed by the `.claude/` tooling above.
- `/agents/`, `/skills/`, `/toolkits/` at repo root — gitignored checkouts of the sibling repos above, nested here purely so local work has one working directory. Each is its own independent repo with its own remote; none of it is tracked by `agency`'s git history (see `.gitignore`).

## `marketplace.json` conventions

Every entry's `source` is a cross-repo reference, not a local path:

```json
{ "source": "git-subdir", "url": "git@github.com:dotknewt/<repo>.git", "path": "<name>", "ref": "main" }
```

**Must use SSH urls** (`git@github.com:...`), not HTTPS — these are private repos and HTTPS clone fails with `fatal: unable to get password from user` (no credential helper configured for git-subdir's non-interactive clone).

The marketplace `"name"` (`agency`) is preserved deliberately — installs are keyed as `<plugin-name>@<marketplace-name>`, and other projects (and this repo's own `.claude/settings.json`) already reference `...@agency`. Renaming it would force a mass reinstall everywhere.

Validate before committing: `claude plugin validate .` Refresh a live install with `claude plugin marketplace update agency`. Note that `claude plugin install` caches by `<name>/<version>` — if you change a plugin's source but not its version, `install` may report "already installed" without re-fetching. Verify a source change with an explicit `uninstall` + `install`.

## Repository layout

- `.claude-plugin/marketplace.json` — the manifest; see conventions above
- `.claude/` — local plugin-development tooling (agents/commands/skills); see above
- `specs/` — `Agent-Specification.md` and `Skill-Specification.md` reference docs for the `.claude/` tooling
- `TODO.md` — cross-repo backlog notes (not repo-specific to `agency` alone)
- `.github/workflows/validate.yml` — lightweight jq-only schema check on `marketplace.json` (valid JSON, required fields, kebab-case names, unique names). It does **not** validate plugin content anymore, since that content lives in sibling repos now — `dotknewt/toolkits` carries its own `validate.yml` for that, using scripts that used to live in this repo's `hooks-toolkit` and are now local to `toolkits-repo`.
- `STATE.md` — session bookmarks; currently just a stub (the multi-repo split it tracked is complete) — don't expect current content there until a new effort starts using it

## No build or test step

There is no top-level build, lint, or test command beyond the CI workflow above.
