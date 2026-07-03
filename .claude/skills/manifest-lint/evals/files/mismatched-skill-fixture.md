---
name: totally-different-name
description: A deliberately mismatched skill used only as a manifest-lint eval fixture — its frontmatter 'name' intentionally does not match the directory it will be placed under. Do not treat this as a real skill.
---

# Fixture: intentionally mismatched SKILL.md

This file exists only so `evals/evals.json` test case 2 can copy it into a
temporary `.claude/skills/wrong-dir/SKILL.md` (inside a scratch git repo) and
assert that `scripts/manifest-lint.sh` reports a name <-> directory `ERROR`.

It is deliberately **not** named `SKILL.md` itself and does not live under a
real `.claude/skills/` directory, so a real run of manifest-lint against this
repo never picks it up as an actual skill manifest.
