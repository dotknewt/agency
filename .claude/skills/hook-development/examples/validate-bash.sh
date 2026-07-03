#!/bin/bash
# Example PreToolUse hook for validating Bash commands
# This script demonstrates bash command validation patterns
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

# Extract command
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Validate command exists
if [ -z "$command" ]; then
  exit 0 # No command to validate
fi

# Check for obviously safe commands (quick approval)
if [[ "$command" =~ ^(ls|pwd|echo|date|whoami)(\s|$) ]]; then
  exit 0
fi

# Check for destructive operations -> deny: plain-text reason to stderr, exit 2
if [[ "$command" == *"rm -rf"* ]] || [[ "$command" == *"rm -fr"* ]]; then
  echo "Dangerous command detected: rm -rf" >&2
  exit 2
fi

# Check for other dangerous commands -> deny: plain-text reason to stderr, exit 2
if [[ "$command" == *"dd if="* ]] || [[ "$command" == *"mkfs"* ]] || [[ "$command" == *"> /dev/"* ]]; then
  echo "Dangerous system operation detected: $command" >&2
  exit 2
fi

# Check for privilege escalation -> ask: structured JSON on stdout, exit 0
if [[ "$command" == sudo* ]] || [[ "$command" == su* ]]; then
  jq -n --arg cmd "$command" \
    '{hookSpecificOutput: {permissionDecision: "ask"}, systemMessage: ("Command requires elevated privileges: " + $cmd)}'
  exit 0
fi

# Approve the operation
exit 0
