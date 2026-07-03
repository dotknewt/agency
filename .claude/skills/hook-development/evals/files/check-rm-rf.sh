#!/bin/bash
# Existing PreToolUse command hook: blocks "rm -rf" bash commands.
# Only catches the exact literal pattern "rm -rf" — misses variations like
# "rm -fr", "rm -r -f", or other destructive commands (dd, mkfs, etc).

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command')

if [[ "$command" == *"rm -rf"* ]]; then
  echo "Dangerous command detected: rm -rf" >&2
  exit 2
fi

exit 0
