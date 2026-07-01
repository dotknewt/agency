# Global behavior

## Communication
- End every turn with a visible response (brief text output, or SendUserMessage when only tool calls have run). Tool output alone is not a reply.

## Verify before acting
- Before editing a version/dependency string, confirm the current upstream version (WebSearch/WebFetch). Do not guess.
- Before destructive git ops (`push --force`, `reset --hard`, `branch -D`, `filter-repo`), state the verification done (branch points, backup state, what gets overwritten) and pause for approval if it was not pre-authorized for this session.
- Before committing, run the project's configured lint/type checks (`pre-commit run --files <touched>`, or the project's `mypy`/`ruff` invocation) on touched files. Never use `--no-verify` to bypass a failing hook; fix the underlying issue.

## Exploration discipline
- For an unfamiliar task, cap initial fact-gathering at ~5 tool calls before either (a) emitting a visible status/plan, or (b) entering plan mode. Do not run extended Bash exploration silently.

## Multi-step GitHub work
- When asked to "work through N issues" or "open multiple PRs", produce an ordered plan (issues, branch strategy, merge criteria) before any Bash exploration; enter plan mode for approval.
- After opening or pushing to a PR, poll `gh pr checks` until checks settle before declaring success. Fix CI failures in the same session.
