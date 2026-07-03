## What

Splitting `dotknewt/agency` (one monolithic repo that is both the Claude Code plugin marketplace and the home of every plugin it lists) into a multi-repo marketplace — `dotknewt/agency` (thin aggregator), `dotknewt/skills`, `dotknewt/agents`, `dotknewt/toolkits`, `dotknewt/ludus-toolkit` — so extensions install and combine more granularly.

## How

Plan lives at `/home/dotme/.claude/plans/i-want-to-split-cuddly-peacock.md`. Each skill/agent/toolkit gets one entry in `dotknewt/agency`'s `.claude-plugin/marketplace.json`, sourced cross-repo via:

```json
"source": { "source": "git-subdir", "url": "git@github.com:dotknewt/<repo>.git", "path": "<name>", "ref": "main" }
```

Must use an **SSH url** (`git@github.com:...`) — HTTPS fails for these private repos with `fatal: unable to get password from user`. Validate with `claude plugin validate <path>`, refresh with `claude plugin marketplace update agency`, confirm with `claude plugin install <name>@agency`.

## WIP

- Creating `dotknewt/toolkits` repo; migrating `agency-toolkit`, `github-toolkit`, `docker-toolkit`, `hooks-toolkit`, `instruction-management`

## ToDo


- Create `dotknewt/toolkits` repo; migrate `agency-toolkit`, `github-toolkit`, `docker-toolkit`, `hooks-toolkit`, `instruction-management`
- Create `dotknewt/ludus-toolkit` repo; flatten `plugins/ludus-toolkit/*` to repo root; reference from `agency` as a whole-repo `github` source (not `git-subdir`)
- Once everything is migrated: remove leftover `instructions/`, `templates/` from `dotknewt/agency`; update its root `README.md`/`AGENTS.md` to describe the new split
- Give `toolkits-repo` its own `validate.yml` CI using its now-local `hooks-toolkit` scripts; give `dotknewt/agency` a lightweight schema-only validator with no plugin dependency
- Re-verify installs across all known consumers of the `agency` marketplace: this machine (user + project scope), `/home/dotme/Code/tidereach`, `/home/dotme/Code/llm/spektralia`
- Flag orphaned `naming-toolkit@agency` install in `spektralia` — no longer exists anywhere in the `agency` repo/history, doesn't map onto any new repo bucket

## Completed

- 2026-07-03 ??:?? — `dotknewt/agents` created with `agent-doublecheck` + `agent-ember` (each kept bundled: `plugin.json` + `agents/*.md` + its own dedicated skills) and its own `.claude-plugin/marketplace.json`; `dotknewt/agency` updated to source both via `git-subdir` (commit `0bb1c96`); local `agents/` directory removed entirely; verified live — both install with full agent + skills content intact
- 2026-07-03 ??:?? — `dotknewt/skills` complete with all 4 skills (`agentic-eval`, `context-engineering`, `make-a-monorepo`, `eyeball`) + its own `.claude-plugin/marketplace.json`; `dotknewt/agency` marketplace.json updated to source all 4 via `git-subdir` (commits `0bc04fb`, `2977016`, `5ea5955` — the last one a fixup after `marketplace.json` edits were left unstaged in `2977016` and silently didn't ship); local `skills/` and `agents/agent-eyeball/` directories removed from `dotknewt/agency`; verified live by installing all 4 from `@agency` and inspecting cached content
- 2026-07-03 ??:?? — Phase 0 smoke test: confirmed a cross-repo `git-subdir` source to a bare `SKILL.md` directory (no `plugin.json`) resolves correctly via `claude plugin install` — the core assumption the whole split depends on

## Decisions

- Cross-repo `git-subdir` sources must use SSH urls (`git@github.com:...`), not HTTPS — HTTPS clone fails for private repos with no credential helper configured
- Marketplace repo identity preserved: the `dotknewt/agency` repo and its manifest `"name": "agency"` stay unchanged, so existing `<plugin>@agency` installs across this machine, `tidereach`, and `spektralia` keep resolving without a mass reinstall
- Composite plugins (toolkits, persona agents) stay bundled, not decomposed into skills-repo/agents-repo — they're coherent single-install units
- One marketplace entry per skill/agent, not thematic bundles — maximizes install/discovery granularity
- `ludus-toolkit` gets its own repo — it bundles a full separate npm/TS MCP server project, heavier than the other toolkits
- `agent-eyeball` has no agent file — reclassified as a skill-only plugin, moves to skills-repo as `eyeball`, not agents-repo (this renames its install key from `agent-eyeball@agency` to `eyeball@agency`)
- Always `git add` the manifest file explicitly and `git diff --cached` before committing marketplace.json edits — `git status` showing "M" (unstaged) next to it is easy to miss when a commit is otherwise dominated by `git rm` deletions (which auto-stage), and a silently-unstaged manifest edit ships a no-op commit that looks correct in the diff summary
