#!/bin/bash
# Example PreToolUse hook for validating Write/Edit operations
# This script demonstrates file write validation patterns
#
# Decision output model (important!):
#   - Deny (block the tool call): print a plain-text reason to stderr and
#     exit 2. On exit 2, stderr is fed back to Claude as plain text — it is
#     NOT parsed as JSON.
#   - Ask (request user confirmation) or any other structured decision:
#     print hookSpecificOutput JSON to stdout and exit 0. JSON is only
#     parsed from stdout on exit 0; exit 2 cannot express "ask", only block.
#   - Approve with nothing to say: exit 0 with no output.

set -euo pipefail

# Read input from stdin
input=$(cat)

# Extract file path and content
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Validate path exists
if [ -z "$file_path" ]; then
  exit 0 # No path to validate
fi

# Check for path traversal -> deny: plain-text reason to stderr, exit 2
if [[ "$file_path" == *".."* ]]; then
  echo "Path traversal detected in: $file_path" >&2
  exit 2
fi

# Check for system directories -> deny: plain-text reason to stderr, exit 2
if [[ "$file_path" == /etc/* ]] || [[ "$file_path" == /sys/* ]] || [[ "$file_path" == /usr/* ]]; then
  echo "Cannot write to system directory: $file_path" >&2
  exit 2
fi

# Check for sensitive files -> ask: structured JSON on stdout, exit 0
if [[ "$file_path" == *.env ]] || [[ "$file_path" == *secret* ]] || [[ "$file_path" == *credentials* ]]; then
  jq -n --arg path "$file_path" \
    '{hookSpecificOutput: {permissionDecision: "ask"}, systemMessage: ("Writing to potentially sensitive file: " + $path)}'
  exit 0
fi

# Approve the operation
exit 0
