## What

Splitting `dotknewt/agency` (one monolithic repo that is both the Claude Code plugin marketplace and the home of every plugin it lists) into a multi-repo marketplace — `dotknewt/agency` (thin aggregator), `dotknewt/skills`, `dotknewt/agents`, `dotknewt/toolkits`, `dotknewt/ludus-toolkit` — so extensions install and combine more granularly.

## How

Plan lives at `/home/dotme/.claude/plans/i-want-to-split-cuddly-peacock.md`. Each skill/agent/toolkit gets one entry in `dotknewt/agency`'s `.claude-plugin/marketplace.json`, sourced cross-repo via:

```json
"source": { "source": "git-subdir", "url": "git@github.com:dotknewt/<repo>.git", "path": "<name>", "ref": "main" }
```

Must use an **SSH url** (`git@github.com:...`) — HTTPS fails for these private repos with `fatal: unable to get password from user`. Validate with `claude plugin validate <path>`, refresh with `claude plugin marketplace update agency`, confirm with `claude plugin install <name>@agency`.

## WIP

(none — the 5-repo split is complete and verified end-to-end on this machine)

## ToDo

- Re-verify/reinstall plugins in `/home/dotme/Code/tidereach` and `/home/dotme/Code/llm/spektralia`, which have project-scoped `...@agency` installs from before the split (not touched by this work — out of scope without an explicit ask on those repos, but their cached plugin content is now stale relative to the new cross-repo sources)
- Flag orphaned `naming-toolkit@agency` install in `spektralia` — no longer exists anywhere in the `agency` repo/history, doesn't map onto any new repo bucket
- Optional polish: `docker-toolkit` and `github-toolkit` `plugin.json` files (now in `dotknewt/toolkits`) still lack an `author` field — pre-existing, not caused by the split, flagged by `claude plugin validate`

## Completed

- 2026-07-03 ??:?? — Full split verified end-to-end: `dotknewt/agency` marketplace.json now lists 12 plugins, all cross-repo sourced, `claude plugin validate` passes clean with zero warnings; `ludus-toolkit` force-reinstalled and its `.mcp.json` `${CLAUDE_PLUGIN_ROOT}/mcp/ludus/...` path confirmed intact after the flatten
- 2026-07-03 ??:?? — `dotknewt/ludus-toolkit` created (repo root = plugin root, `mcp/ludus/` nested project's internal layout preserved); `dotknewt/agency` updated to source it as a whole-repo `github` source (commit `8532e72`); local `plugins/` (now empty) and dead `templates/`/`.claudeignore` removed; `AGENTS.md`/`README.md` rewritten for the new structure — kept `instructions/AGENTS-Global.md` (general guidance, not toolkit-specific, wasn't actually `@`-included by the old AGENTS.md either) despite the original plan saying to remove "leftover instructions/"; dropped the two `@plugins/github-toolkit/instructions/*.md` references since that content no longer lives locally
- 2026-07-03 ??:?? — `dotknewt/toolkits` created with all 5 composite plugins (`agency-toolkit`, `github-toolkit`, `docker-toolkit`, `hooks-toolkit`, `instruction-management`) + its own `validate.yml` CI (using the now-local `hooks-toolkit` scripts, sanity-checked locally with 0 failures) + its own `.claude-plugin/marketplace.json`; `dotknewt/agency` updated to source all 5 via `git-subdir` (commit `ada6e02`); local `plugins/` contents removed except `ludus-toolkit` (still pending); root `validate.yml` rewritten as a lightweight jq-only schema check since it no longer has local access to `hooks-toolkit` scripts; verified live — all 5 install with correct nested agents/skills/commands/hooks content (forced a clean uninstall+reinstall of `instruction-management` since it hit a stale pre-migration cache entry that "already installed" would have silently passed through)
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
- `claude plugin install` caches by `<name>/<version>`; if a plugin's version string doesn't change across a source migration, `install` reports "already installed" without re-fetching from the new source — this can mask a broken cross-repo source behind a stale local cache. Verify migrations with an explicit `uninstall` + `install`, not just `install`
