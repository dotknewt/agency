#!/usr/bin/env bash
# Repo-wide lint for plugin.json / SKILL.md / marketplace.json manifests.
# Usage: manifest-lint.sh [--help] [path ...]   (defaults to the whole repo)
#
# Reuses the shared validators from the hooks-toolkit plugin (JSON syntax,
# required fields, kebab-case name, semver format) so there is one source of
# truth for those rules, when the gitignored `toolkits/` sibling checkout
# happens to be present locally (best-effort — see SKILL.md). On top of that
# it adds checks the per-edit hook can't do in isolation:
#   - name <-> directory match (plugin.json and SKILL.md)
#   - plugin.json version vs. its marketplace.json entry
#   - version bumped vs. the last committed version of the file (WARNs,
#     rather than silently no-op-ing, when the path is git-ignored)
#   - marketplace.json "source" entries match the git-subdir object shape
#
# Run with --help for full usage, flags, and exit codes.
set -uo pipefail

show_help() {
  cat <<'EOF'
manifest-lint.sh — repo-wide lint for plugin.json / SKILL.md / marketplace.json manifests

Usage:
  manifest-lint.sh [--help] [path ...]

Arguments:
  path ...      Optional. Scope the scan to these files/directories instead
                of the whole repo. Defaults to the whole repo, resolved via
                `git rev-parse --show-toplevel`.

Options:
  -h, --help    Show this help and exit 0.

Exit codes:
  0   Completed, no ERROR was found (WARNings are allowed and don't fail the run).
  1   Completed, at least one ERROR was found.
  2   Could not run at all — e.g. not inside a git repository.

Checks (see references/checks.md for the full list and how to fix each):
  - JSON syntax, required fields, kebab-case name, semver — reused from
    toolkits/hooks-toolkit's validators when that gitignored sibling
    checkout is present locally (best-effort; skipped with a WARN
    otherwise).
  - name <-> directory match, for plugin.json and SKILL.md.
  - plugin.json version vs. its marketplace.json entry.
  - version bumped vs. the last committed version of the file (WARNs
    instead of silently no-op-ing when the path is git-ignored).
  - marketplace.json "source" entries match the git-subdir object shape.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h|--help)
      show_help
      exit 0
      ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  echo "ERROR: not inside a git repository" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_TOOLKIT_SCRIPTS="$REPO_ROOT/toolkits/hooks-toolkit/scripts"
VALIDATE_PLUGIN_JSON="$HOOKS_TOOLKIT_SCRIPTS/validate-plugin-json.sh"
VALIDATE_SKILL_FRONTMATTER="$HOOKS_TOOLKIT_SCRIPTS/validate-skill-frontmatter.sh"

shared_validators_available=true
if [ ! -x "$VALIDATE_PLUGIN_JSON" ] || [ ! -x "$VALIDATE_SKILL_FRONTMATTER" ]; then
  shared_validators_available=false
  echo "WARN: hooks-toolkit validators not found at $HOOKS_TOOLKIT_SCRIPTS — toolkits/ is a gitignored sibling checkout and not guaranteed present locally (see AGENTS.md); skipping shared JSON/frontmatter checks (name/dir, version-consistency, and version-bump checks below still run)" >&2
fi

errors=0
warnings=0

err() { echo "ERROR [$1]: $2" >&2; errors=$((errors + 1)); }
warn() { echo "WARN [$1]: $2" >&2; warnings=$((warnings + 1)); }

# Scope: explicit paths, or the whole repo.
if [ "$#" -gt 0 ]; then
  scan_roots=("$@")
else
  scan_roots=("$REPO_ROOT")
fi

plugin_manifests=()
skill_manifests=()
for root in "${scan_roots[@]}"; do
  while IFS= read -r -d '' f; do plugin_manifests+=("$f"); done \
    < <(find "$root" -path '*/.claude-plugin/plugin.json' -not -path '*/node_modules/*' -print0 2>/dev/null)
  while IFS= read -r -d '' f; do skill_manifests+=("$f"); done \
    < <(find "$root" -name 'SKILL.md' -not -path '*/node_modules/*' -print0 2>/dev/null)
done

marketplace_file="$REPO_ROOT/.claude-plugin/marketplace.json"

# --- version-bump helper -----------------------------------------------
# Warn if a manifest's version is unchanged from the last commit despite
# other content in the file having changed. There is no per-plugin git tag
# convention in this repo yet, so "last tag" is approximated as "last
# committed version of this file" — the closest real baseline available.
#
# Caveat: this can only see agency's own tracked git history. Every real
# plugin manifest it's meant to catch lives under the gitignored sibling
# checkouts (agents/, skills/, toolkits/) — agency's history has no record
# of their contents. `git cat-file -e HEAD:$rel` fails identically for that
# case and for "brand-new file about to be committed", so distinguish them
# via `git check-ignore` first and WARN visibly for the gitignored case
# instead of silently returning success (which looked indistinguishable
# from "nothing to check" and meant this check never actually fired for any
# real plugin manifest).
check_version_bump() {
  local file="$1" field_jq="$2"
  local rel="${file#"$REPO_ROOT"/}"

  if git -C "$REPO_ROOT" check-ignore -q -- "$rel" 2>/dev/null; then
    warn "$file" "version-bump check skipped: path is git-ignored in agency (this manifest lives in a sibling checkout — e.g. agents/, skills/, toolkits/ — that isn't part of agency's own git history, so there is no committed baseline to diff against here)"
    return 0
  fi

  git -C "$REPO_ROOT" cat-file -e "HEAD:$rel" 2>/dev/null || return 0 # new (tracked) file, nothing to compare yet
  if git -C "$REPO_ROOT" diff --quiet HEAD -- "$rel" 2>/dev/null; then
    return 0 # no uncommitted changes to compare against
  fi
  local old_version new_version
  old_version=$(git -C "$REPO_ROOT" show "HEAD:$rel" 2>/dev/null | jq -r "$field_jq" 2>/dev/null)
  new_version=$(jq -r "$field_jq" "$file" 2>/dev/null)
  if [ -n "$old_version" ] && [ -n "$new_version" ] && [ "$old_version" = "$new_version" ]; then
    warn "$file" "content changed but version is still $new_version (bump it, or ignore if this is a non-release edit)"
  fi
}

# --- plugin.json checks --------------------------------------------------
for file in "${plugin_manifests[@]}"; do
  if $shared_validators_available; then
    err_file="/tmp/manifest-lint-plugin.$$.err"
    "$VALIDATE_PLUGIN_JSON" "$file" >/dev/null 2>"$err_file"
    shared_rc=$?
    if [ -s "$err_file" ]; then
      cat "$err_file" >&2
      if [ "$shared_rc" -ne 0 ]; then errors=$((errors + 1)); else warnings=$((warnings + 1)); fi
    fi
    rm -f "$err_file"
  fi

  name=$(jq -r '.name // ""' "$file" 2>/dev/null)
  version=$(jq -r '.version // ""' "$file" 2>/dev/null)
  plugin_dir="$(dirname "$(dirname "$file")")"
  dir_name="$(basename "$plugin_dir")"

  if [ -n "$name" ] && [ "$name" != "$dir_name" ]; then
    err "$file" "'name' ($name) does not match containing directory ($dir_name)"
  fi

  if [ -f "$marketplace_file" ] && [ -n "$name" ]; then
    market_version=$(jq -r --arg n "$name" '.plugins[]? | select(.name == $n) | .version // ""' "$marketplace_file" 2>/dev/null)
    if [ -n "$market_version" ] && [ -n "$version" ] && [ "$market_version" != "$version" ]; then
      err "$file" "version ($version) does not match marketplace.json entry for '$name' ($market_version)"
    fi
  fi

  check_version_bump "$file" '.version // ""'
done

# --- SKILL.md checks -------------------------------------------------------
for file in "${skill_manifests[@]}"; do
  if $shared_validators_available; then
    err_file="/tmp/manifest-lint-skill.$$.err"
    "$VALIDATE_SKILL_FRONTMATTER" "$file" >/dev/null 2>"$err_file"
    shared_rc=$?
    if [ -s "$err_file" ]; then
      cat "$err_file" >&2
      if [ "$shared_rc" -ne 0 ]; then errors=$((errors + 1)); else warnings=$((warnings + 1)); fi
    fi
    rm -f "$err_file"
  fi

  frontmatter=$(awk '/^---$/{c++; if(c==2) exit} c==1{print}' "$file")
  name=$(echo "$frontmatter" | grep -E '^name:' | sed 's/^name:[[:space:]]*//' | tr -d '"' || true)
  dir_name="$(basename "$(dirname "$file")")"

  if [ -n "$name" ] && [ "$name" != "$dir_name" ]; then
    err "$file" "'name' ($name) does not match containing directory ($dir_name)"
  fi
done

# --- marketplace.json checks -----------------------------------------------
if [ -f "$marketplace_file" ]; then
  if $shared_validators_available; then
    err_file="/tmp/manifest-lint-market.$$.err"
    "$VALIDATE_PLUGIN_JSON" "$marketplace_file" >/dev/null 2>"$err_file"
    shared_rc=$?
    if [ -s "$err_file" ]; then
      cat "$err_file" >&2
      if [ "$shared_rc" -ne 0 ]; then errors=$((errors + 1)); else warnings=$((warnings + 1)); fi
    fi
    rm -f "$err_file"
  fi

  # Each plugins[] entry's "source" is a git-subdir object (not a bare local
  # path) — e.g. {"source": "git-subdir", "url": "git@...", "path": "...",
  # "ref": "main"}. Content is fetched remotely at install/update time, so
  # there's no local path here to resolve; just validate the object shape.
  while IFS= read -r entry_json; do
    [ -z "$entry_json" ] && continue
    entry_name=$(jq -r '.name // ""' <<<"$entry_json" 2>/dev/null)
    [ -z "$entry_name" ] && continue

    src_is_object=$(jq -r '(.source | type) == "object"' <<<"$entry_json" 2>/dev/null)
    if [ "$src_is_object" != "true" ]; then
      err "$marketplace_file" "entry '$entry_name' source is not an object (expected {source, url, path, ref} — see AGENTS.md); got: $(jq -c '.source' <<<"$entry_json" 2>/dev/null)"
      continue
    fi

    src_kind=$(jq -r '.source.source // ""' <<<"$entry_json" 2>/dev/null)
    src_url=$(jq -r '.source.url // ""' <<<"$entry_json" 2>/dev/null)
    src_path=$(jq -r '.source.path // ""' <<<"$entry_json" 2>/dev/null)
    src_ref=$(jq -r '.source.ref // ""' <<<"$entry_json" 2>/dev/null)

    [ -z "$src_kind" ] && err "$marketplace_file" "entry '$entry_name' source.source (the fetch mechanism, e.g. 'git-subdir') is missing"
    if [ -z "$src_url" ]; then
      err "$marketplace_file" "entry '$entry_name' source.url is missing"
    elif [[ "$src_url" != git@*:*.git ]]; then
      warn "$marketplace_file" "entry '$entry_name' source.url ($src_url) doesn't look like an SSH git url (expected git@host:owner/repo.git — HTTPS urls fail git-subdir's non-interactive clone, see AGENTS.md)"
    fi
    [ -z "$src_path" ] && err "$marketplace_file" "entry '$entry_name' source.path is missing"
    [ -z "$src_ref" ] && warn "$marketplace_file" "entry '$entry_name' source.ref is missing (recommend pinning explicitly, e.g. 'main')"
  done < <(jq -c '.plugins[]?' "$marketplace_file" 2>/dev/null)
fi

# --- summary ----------------------------------------------------------------
echo ""
echo "manifest-lint: ${#plugin_manifests[@]} plugin.json, ${#skill_manifests[@]} SKILL.md checked — $errors error(s), $warnings warning(s)"

if [ "$errors" -gt 0 ]; then
  exit 1
fi
exit 0
