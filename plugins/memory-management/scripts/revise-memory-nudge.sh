#!/usr/bin/env bash
# Stop hook: suggest /revise-memory when the session touched many files.
# Threshold configurable via MEMORY_NUDGE_THRESHOLD (default 5).
set -euo pipefail

threshold="${MEMORY_NUDGE_THRESHOLD:-5}"

project_dir="${CLAUDE_PROJECT_DIR:-.}"

# Count files changed since the session-start commit heuristic:
# use git status (uncommitted changes) + commits in the last 2 hours.
dirty=$(git -C "$project_dir" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
recent=$(git -C "$project_dir" diff --name-only "@{2 hours ago}" HEAD 2>/dev/null | wc -l | tr -d ' ' || echo 0)
total=$((dirty + recent))

if [ "$total" -ge "$threshold" ]; then
  printf '{"decision":"approve","systemMessage":"This session touched ~%s file(s). Consider running /revise-memory to capture key learnings in AGENTS.md before finishing."}\n' "$total"
else
  printf '{"decision":"approve"}\n'
fi

exit 0
