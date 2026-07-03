# manifest-lint checks

## Reused from hooks-toolkit (best-effort, only when `toolkits/` is checked out)

Run via `toolkits/hooks-toolkit/scripts/validate-plugin-json.sh` and `validate-skill-frontmatter.sh` — the `hooks-toolkit` plugin's own validators, sourced from the gitignored `dotknewt/toolkits` sibling checkout (see `AGENTS.md`). If you need to change these rules, change them there — both the `PostToolUse` hook and this skill call the same scripts.

**This reuse is best-effort.** `toolkits/` is gitignored and not guaranteed to be present in any given working tree (see `AGENTS.md`'s "Repository layout") — it's only there if `dotknewt/toolkits` has been checked out locally alongside `agency` for plugin development. If `toolkits/hooks-toolkit/scripts/` isn't found, manifest-lint prints a `WARN` and skips just these shared checks — the repo-wide checks below still run.

- Valid JSON (`plugin.json`, `marketplace.json`) / presence of `---` frontmatter delimiters (`SKILL.md`).
- Required fields: `name` + `description` on plugin manifests; `name` + `plugins[]` on `marketplace.json`; `name` + `description` in SKILL.md frontmatter.
- `name` must be kebab-case.
- `version`, if present, should look like semver (`X.Y.Z`) — warning only, doesn't fail.
- SKILL.md over 500 lines — warning, move detail into `references/`.

## New in manifest-lint (repo-wide only)

### name ↔ directory match

- `plugin.json`: `name` must equal the directory containing `.claude-plugin/` (e.g. a locally checked-out `toolkits/hooks-toolkit/.claude-plugin/plugin.json` → name must be `hooks-toolkit`).
- `SKILL.md`: `name` must equal its parent directory (e.g. `.claude/skills/manifest-lint/SKILL.md` → name must be `manifest-lint`).
- Deliberately scoped to `*/.claude-plugin/plugin.json` only — `.github/plugin/plugin.json` files (used by some forked plugins for a GitHub App manifest) are a different mechanism and excluded.
- Fix: rename the directory or the `name` field, whichever is correct.

### plugin.json ↔ marketplace.json version consistency

- For each `plugin.json`, look up the matching entry in `.claude-plugin/marketplace.json` by `name` and compare `version`.
- Fix: bump whichever one is stale so both agree.
- `agency` itself carries no `plugin.json` files — all plugin content is sourced from the `agents`/`skills`/`toolkits` siblings (see `AGENTS.md`) — so in practice this check only fires when one of those sibling checkouts happens to be present locally.

### version bump vs. last commit

- There's no per-plugin git tag convention in this repo (`git tag` currently returns nothing), so "bumped since last release" can't be checked against a tag. Instead: if a manifest file has uncommitted changes AND its `version` field is identical to the version at `HEAD` for that file, warn.
- **Gitignored paths degrade with a visible `WARN`, not silently.** Every real plugin manifest this check is meant to catch lives under the gitignored sibling checkouts (`agents/`, `skills/`, `toolkits/`) — `agency`'s own git history has no record of their contents, so there's nothing to diff against. `check_version_bump()` runs `git check-ignore` on the target path first: if it's ignored, it prints `WARN [file]: version-bump check skipped: path is git-ignored...` and returns — rather than the old behavior, where `git cat-file -e HEAD:$rel || return 0` failed identically for "gitignored, permanently invisible to history" and "brand-new file about to be committed", so the check silently never fired for any real plugin manifest and nobody could tell.
- For paths that genuinely are new-but-tracked files inside `agency` itself (not gitignored, just not committed yet), the check still silently no-ops — there's really nothing to compare there, and that case doesn't need a warning.
- This only catches the "I edited a plugin.json / SKILL.md right now and forgot to bump" case, and only for manifests tracked in `agency`'s own git history — it says nothing about releases that already landed, and it's now an honest (visibly warned) no-op for anything living in a sibling checkout.
- If this repo adopts a tagging convention later (e.g. `<plugin-name>@X.Y.Z`, as hinted at in `skills/make-a-monorepo/SKILL.md`), update `check_version_bump()` in `scripts/manifest-lint.sh` to prefer `git describe --match "<plugin-name>@*"` over the `HEAD` comparison.
- Not a false-positive risk for intentional non-release edits (typo fixes, wording tweaks) — it's a warning, not an error, and won't fail the run.

### marketplace.json source shape

- `.plugins[].source` is an object, not a bare path. The live shape (verified against `.claude-plugin/marketplace.json`) is:

  ```json
  { "source": "git-subdir", "url": "git@github.com:dotknewt/<repo>.git", "path": "<name>", "ref": "main" }
  ```

- manifest-lint checks, per entry: `source` is an object (not a string); `source.source` (the fetch mechanism, e.g. `git-subdir`) is present; `source.url` is present and looks like an SSH git url (`git@host:owner/repo.git`) rather than HTTPS — HTTPS urls fail `git-subdir`'s non-interactive clone (see `AGENTS.md`); `source.path` is present; `source.ref` is present (warning only if missing).
- There is no local path to resolve anymore — the content is fetched remotely from the sibling repo at install/update time, not checked out under `agency` itself. (The old check assumed `source` was a bare relative path and tested it with `[ -e ... ]`, which no longer means anything under the current schema and never actually ran against a real entry.)
- Fix: correct the malformed/missing key in the `source` object, or remove the stale entry if the plugin was deleted from its sibling repo.
