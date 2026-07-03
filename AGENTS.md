# AGENTS.md

This file provides guidance to AI agents (Claude Code, Codex, Cursor, etc.) when working with code in this repository.

# agency

`agency` is the thin, aggregating Claude Code plugin marketplace at the root of a multi-repo split. It contains **only** `.claude-plugin/marketplace.json` plus repo-level docs and CI — it does not host any plugin content itself anymore. Every plugin it lists is sourced from one of four sibling repos, each independently addable as its own marketplace too:

- [`dotknewt/skills`](https://github.com/dotknewt/skills) — standalone single-skill plugins (bare `SKILL.md` dirs, no `plugin.json`)
- [`dotknewt/agents`](https://github.com/dotknewt/agents) — agent-persona plugins, each bundling an agent `.md` with its own dedicated skills
- [`dotknewt/toolkits`](https://github.com/dotknewt/toolkits) — composite plugins bundling skills+agents+commands+hooks together
- [`dotknewt/ludus-toolkit`](https://github.com/dotknewt/ludus-toolkit) — its own repo (bundles a full separate npm/TS MCP server project, referenced as a whole-repo source, not `git-subdir`)

This split lets users install a single skill, a single agent, a whole toolkit, or any combination — instead of one all-or-nothing repo. See `STATE.md` for the split's current status and decisions made along the way.

## `marketplace.json` conventions

Every entry's `source` is a cross-repo reference, not a local path:

```json
{ "source": "git-subdir", "url": "git@github.com:dotknewt/<repo>.git", "path": "<name>", "ref": "main" }
```

except `ludus-toolkit`, whose entire repo is one plugin:

```json
{ "source": "github", "repo": "dotknewt/ludus-toolkit" }
```

**Must use SSH urls** (`git@github.com:...`), not HTTPS — these are private repos and HTTPS clone fails with `fatal: unable to get password from user` (no credential helper configured for git-subdir's non-interactive clone).

The marketplace `"name"` (`agency`) is preserved deliberately — installs are keyed as `<plugin-name>@<marketplace-name>`, and other projects (and this repo's own `.claude/settings.json`) already reference `...@agency`. Renaming it would force a mass reinstall everywhere.

Validate before committing: `claude plugin validate .` Refresh a live install with `claude plugin marketplace update agency`. Note that `claude plugin install` caches by `<name>/<version>` — if you change a plugin's source but not its version, `install` may report "already installed" without re-fetching. Verify a source change with an explicit `uninstall` + `install`.

## Repository layout

- `.claude-plugin/marketplace.json` — the manifest; see conventions above
- `instructions/AGENTS-Global.md` — general cross-project agent behavior guidance (verification discipline, exploration caps, GitHub workflow habits). Not repo-specific; not currently `@`-included anywhere — read it directly if relevant
- `.github/workflows/validate.yml` — lightweight jq-only schema check on `marketplace.json` (valid JSON, required fields, kebab-case names, unique names). It does **not** validate plugin content anymore, since that content lives in sibling repos now — `dotknewt/toolkits` carries its own `validate.yml` for that, using scripts that used to live in this repo's `hooks-toolkit` and are now local to `toolkits-repo`.
- `STATE.md` — session bookmarks and in-progress work for the ongoing multi-repo split

## No build or test step

There is no top-level build, lint, or test command beyond the CI workflow above.
