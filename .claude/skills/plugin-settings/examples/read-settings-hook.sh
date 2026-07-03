#!/bin/bash
# Example hook that reads plugin settings from .claude/my-plugin.local.md
# Demonstrates the complete pattern for settings-driven hook behavior
#
# Decision output pattern (do not mix these up):
#   - deny/ask (blocking): write a short, PLAIN-TEXT reason to stderr and
#     exit 2. On exit 2, stderr is surfaced to Claude as plain text context —
#     it is NOT parsed as JSON, so a JSON blob here would just show up as
#     literal text.
#   - allow (explicit, structured decision): write the "hookSpecificOutput"
#     JSON to STDOUT and exit 0. Structured decision JSON is only ever parsed
#     from stdout on exit 0.

set -euo pipefail

# Define settings file path
SETTINGS_FILE=".claude/my-plugin.local.md"

# Quick exit if settings file doesn't exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
  # Plugin not configured - use defaults or skip
  exit 0
fi

# Parse YAML frontmatter (everything between --- markers)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS_FILE")

# Extract configuration fields. Each pipeline ends in `|| true`: with `set -e`
# + `pipefail`, a `grep` that finds no match (a field simply isn't set) would
# otherwise abort the whole script right here instead of falling through to
# the defaults/quick-exit checks below.
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//' | sed 's/^"\(.*\)"$/\1/' || true)
STRICT_MODE=$(echo "$FRONTMATTER" | grep '^strict_mode:' | sed 's/strict_mode: *//' | sed 's/^"\(.*\)"$/\1/' || true)
MAX_SIZE=$(echo "$FRONTMATTER" | grep '^max_file_size:' | sed 's/max_file_size: *//' || true)

# Quick exit if disabled
if [[ "$ENABLED" != "true" ]]; then
  exit 0
fi

# Read hook input
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Apply configured validation
if [[ "$STRICT_MODE" == "true" ]]; then
  # Strict mode: apply all checks
  if [[ "$file_path" == *".."* ]]; then
    echo "Path traversal blocked (strict mode): $file_path" >&2
    exit 2
  fi

  if [[ "$file_path" == *".env"* ]] || [[ "$file_path" == *"secret"* ]]; then
    echo "Sensitive file blocked (strict mode): $file_path" >&2
    exit 2
  fi
else
  # Standard mode: basic checks only
  if [[ "$file_path" == "/etc/"* ]] || [[ "$file_path" == "/sys/"* ]]; then
    echo "System path blocked: $file_path" >&2
    exit 2
  fi
fi

# Check file size if configured
if [[ -n "$MAX_SIZE" ]] && [[ "$MAX_SIZE" =~ ^[0-9]+$ ]]; then
  content=$(echo "$input" | jq -r '.tool_input.content // empty')
  content_size=${#content}

  if [[ $content_size -gt $MAX_SIZE ]]; then
    echo "File exceeds configured max size: ${MAX_SIZE} bytes" >&2
    exit 2
  fi
fi

# All checks passed. Emit an explicit "allow" decision as structured JSON on
# stdout with exit 0 - this is the only combination Claude Code parses as
# hookSpecificOutput JSON.
jq -n '{"hookSpecificOutput": {"permissionDecision": "allow"}}'
exit 0
