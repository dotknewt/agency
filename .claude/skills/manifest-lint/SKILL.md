---
name: manifest-lint
description: On-demand repo-wide lint for plugin.json, SKILL.md, and marketplace.json manifests — checks required fields, kebab-case naming, name-to-directory match, semver format, plugin.json/marketplace.json version consistency, and whether a manifest's version was bumped after a content edit. Invoke explicitly (e.g., ask to "run manifest-lint") — this skill does not auto-trigger and has no registered slash command; run `scripts/manifest-lint.sh` directly.
version: 0.2.0
disable-model-invocation: true
# Note: `version`/`disable-model-invocation` stay top-level rather than under
# `metadata:` (the skill-spec's documented extension point) — `version` matches
# the convention used by every other SKILL.md under .claude/skills/, and
# `disable-model-invocation` must stay top-level for Claude Code to actually
# honor it (metadata is inert key-value storage per spec, not read for behavior).
---

# Manifest Lint

Validates every `plugin.json`, `SKILL.md`, and `marketplace.json` in the repo in one pass. Built because this repo carries ~25+ hand-rolled manifest files and the same class of bug (name/directory drift, stale versions) keeps slipping in.

## Relationship to hooks-toolkit

The `hooks-toolkit` plugin (sourced from the gitignored `dotknewt/toolkits` sibling checkout — see `AGENTS.md`) already validates manifests via `PostToolUse(Write|Edit)` hooks — but only the one file you just touched, and only at edit time. When that sibling repo happens to be checked out locally at `toolkits/`, this skill reuses those exact same validators (`toolkits/hooks-toolkit/scripts/validate-plugin-json.sh` and `validate-skill-frontmatter.sh`) as the source of truth for JSON syntax, required fields, kebab-case names, and semver format, so the rules never drift between the two.

**This reuse is best-effort, not guaranteed.** `toolkits/` is gitignored and not part of `agency`'s own working tree by default (see `AGENTS.md`'s "Repository layout") — it's only present if someone has checked out `dotknewt/toolkits` alongside `agency` for local plugin development. If it's missing, the shared checks are skipped with a `WARN` and only the repo-wide checks below still run. On top of that shared base, it adds checks that only make sense with a whole-repo view:

- **name ↔ directory match** — a `plugin.json`'s `name` field vs. the directory it lives in; a `SKILL.md`'s `name` field vs. its parent directory. (Neither the hook nor the `plugin-validator` agent currently checks this.)
- **plugin.json ↔ marketplace.json version consistency** — flags when a plugin's manifest version and its `marketplace.json` registry entry have drifted apart.
- **version bump vs. last commit** — warns when a manifest's content changed but its `version` field didn't, for manifests tracked in `agency`'s own git history. Manifests living under the gitignored sibling checkouts (`agents/`, `skills/`, `toolkits/`) can't be diffed this way; see `references/checks.md` for how that's now surfaced with a visible `WARN` instead of silently doing nothing.
- **marketplace.json source shape** — each `plugins[].source` entry is the `git-subdir` object shape agency actually uses (`{"source": "git-subdir", "url": ..., "path": ..., "ref": ...}`), not a bare path.

## Usage

The script resolves the repo root itself via `git rev-parse --show-toplevel`, so invoke it by that root rather than relying on `${CLAUDE_PLUGIN_ROOT}` being set in the Bash tool's shell (that variable is only guaranteed inside hook/command subprocesses, not an arbitrary Bash call the model makes while running a skill):

```bash
REPO_ROOT="$(git rev-parse --show-toplevel)"
bash "$REPO_ROOT/.claude/skills/manifest-lint/scripts/manifest-lint.sh"            # whole repo
bash "$REPO_ROOT/.claude/skills/manifest-lint/scripts/manifest-lint.sh" some/path  # scoped
bash "$REPO_ROOT/.claude/skills/manifest-lint/scripts/manifest-lint.sh" --help     # usage, flags, exit codes
```

Errors go to stderr as `ERROR [file]: message`, non-fatal issues as `WARN [file]: message`, followed by a one-line summary. Exit codes: `0` if no `ERROR` was found (warnings alone don't fail the run), `1` if at least one `ERROR` was found, `2` if the script couldn't run at all (e.g. not inside a git repository).

If `hooks-toolkit`'s scripts aren't found at `toolkits/hooks-toolkit/scripts/` (because the `toolkits` sibling repo isn't checked out locally), the shared checks are skipped with a warning — the new repo-wide checks still run.

See `references/checks.md` for the full list of checks and how to fix each one.
