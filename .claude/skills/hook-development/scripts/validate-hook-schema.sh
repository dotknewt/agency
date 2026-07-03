#!/bin/bash
# Hook Schema Validator
# Validates hooks.json structure and checks for common issues
#
# Supports both hook configuration shapes:
#   - Plugin format:   {"description": "...", "hooks": {"PreToolUse": [...], ...}}
#   - Settings format: {"PreToolUse": [...], ...}
# The format is auto-detected; see --help for details.

set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: validate-hook-schema.sh <path/to/hooks.json>
       validate-hook-schema.sh -h | --help

Validates a Claude Code hook configuration file for:
  - Valid JSON syntax
  - Valid hook event names
  - Required fields (matcher, hooks, type, command/prompt)
  - Valid hook types (command/prompt)
  - Timeout ranges
  - Hardcoded absolute paths (recommends ${CLAUDE_PLUGIN_ROOT})
  - Prompt-hook/event compatibility

Accepts both hook configuration shapes and auto-detects which one it's
looking at:
  - Plugin hooks.json format: events are wrapped in a "hooks" key, e.g.
      {"description": "...", "hooks": {"PreToolUse": [...]}}
  - Settings format: events are directly at the top level, e.g.
      {"PreToolUse": [...]}

Examples:
  validate-hook-schema.sh hooks/hooks.json
  validate-hook-schema.sh .claude/settings.json
  ./validate-hook-schema.sh ../my-plugin/hooks/hooks.json

Output:
  Progress/diagnostic messages are printed to stderr.
  Validation results (per-check status, errors, warnings, summary) are
  printed to stdout.

Exit codes:
  0 - Valid (no errors; warnings are still allowed)
  1 - Invalid JSON, file not found, or validation errors found
EOF
}

if [ $# -eq 0 ]; then
  show_help >&2
  exit 1
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  show_help
  exit 0
fi

HOOKS_FILE="$1"

if [ ! -f "$HOOKS_FILE" ]; then
  echo "❌ Error: File not found: $HOOKS_FILE"
  exit 1
fi

echo "🔍 Validating hooks configuration: $HOOKS_FILE" >&2
echo "" >&2

# Check 1: Valid JSON
echo "Checking JSON syntax..." >&2
if ! jq empty "$HOOKS_FILE" 2>/dev/null; then
  echo "❌ Invalid JSON syntax"
  exit 1
fi
echo "✅ Valid JSON"

# Detect format and unwrap to a normalized "events" document so the rest of
# the script can treat both shapes identically.
#
# Plugin format wraps events in a "hooks" key:
#   {"description": "...", "hooks": {"PreToolUse": [...], ...}}
# Settings format has events directly at the top level:
#   {"PreToolUse": [...], ...}
echo "" >&2
echo "Detecting configuration format..." >&2

EVENTS_FILE=$(mktemp)
trap 'rm -f "$EVENTS_FILE"' EXIT

if jq -e 'type == "object" and has("hooks") and (.hooks | type == "object")' "$HOOKS_FILE" >/dev/null 2>&1; then
  echo "📦 Detected plugin format (events wrapped in a \"hooks\" key)" >&2
  jq '.hooks' "$HOOKS_FILE" > "$EVENTS_FILE"
else
  echo "📄 Detected settings format (events at top level)" >&2
  jq '.' "$HOOKS_FILE" > "$EVENTS_FILE"
fi

# Check 2: Root structure
echo "" >&2
echo "Checking root structure..." >&2
VALID_EVENTS=("PreToolUse" "PostToolUse" "UserPromptSubmit" "Stop" "SubagentStop" "SessionStart" "SessionEnd" "PreCompact" "Notification")

for event in $(jq -r 'keys[]' "$EVENTS_FILE"); do
  found=false
  for valid_event in "${VALID_EVENTS[@]}"; do
    if [ "$event" = "$valid_event" ]; then
      found=true
      break
    fi
  done

  if [ "$found" = false ]; then
    echo "⚠️  Unknown event type: $event"
  fi
done
echo "✅ Root structure valid"

# Check 3: Validate each hook
echo "" >&2
echo "Validating individual hooks..." >&2

error_count=0
warning_count=0

for event in $(jq -r 'keys[]' "$EVENTS_FILE"); do
  hook_count=$(jq -r ".\"$event\" | length" "$EVENTS_FILE")

  for ((i=0; i<hook_count; i++)); do
    # Check matcher exists
    matcher=$(jq -r ".\"$event\"[$i].matcher // empty" "$EVENTS_FILE")
    if [ -z "$matcher" ]; then
      echo "❌ $event[$i]: Missing 'matcher' field"
      error_count=$((error_count + 1))
      continue
    fi

    # Check hooks array exists
    hooks=$(jq -r ".\"$event\"[$i].hooks // empty" "$EVENTS_FILE")
    if [ -z "$hooks" ] || [ "$hooks" = "null" ]; then
      echo "❌ $event[$i]: Missing 'hooks' array"
      error_count=$((error_count + 1))
      continue
    fi

    # Validate each hook in the array
    hook_array_count=$(jq -r ".\"$event\"[$i].hooks | length" "$EVENTS_FILE")

    for ((j=0; j<hook_array_count; j++)); do
      hook_type=$(jq -r ".\"$event\"[$i].hooks[$j].type // empty" "$EVENTS_FILE")

      if [ -z "$hook_type" ]; then
        echo "❌ $event[$i].hooks[$j]: Missing 'type' field"
        error_count=$((error_count + 1))
        continue
      fi

      if [ "$hook_type" != "command" ] && [ "$hook_type" != "prompt" ]; then
        echo "❌ $event[$i].hooks[$j]: Invalid type '$hook_type' (must be 'command' or 'prompt')"
        error_count=$((error_count + 1))
        continue
      fi

      # Check type-specific fields
      if [ "$hook_type" = "command" ]; then
        command=$(jq -r ".\"$event\"[$i].hooks[$j].command // empty" "$EVENTS_FILE")
        if [ -z "$command" ]; then
          echo "❌ $event[$i].hooks[$j]: Command hooks must have 'command' field"
          error_count=$((error_count + 1))
        else
          # Check for hardcoded paths
          if [[ "$command" == /* ]] && [[ "$command" != *'${CLAUDE_PLUGIN_ROOT}'* ]]; then
            echo "⚠️  $event[$i].hooks[$j]: Hardcoded absolute path detected. Consider using \${CLAUDE_PLUGIN_ROOT}"
            warning_count=$((warning_count + 1))
          fi
        fi
      elif [ "$hook_type" = "prompt" ]; then
        prompt=$(jq -r ".\"$event\"[$i].hooks[$j].prompt // empty" "$EVENTS_FILE")
        if [ -z "$prompt" ]; then
          echo "❌ $event[$i].hooks[$j]: Prompt hooks must have 'prompt' field"
          error_count=$((error_count + 1))
        fi

        # Check if prompt-based hooks are used on supported events
        if [ "$event" != "Stop" ] && [ "$event" != "SubagentStop" ] && [ "$event" != "UserPromptSubmit" ] && [ "$event" != "PreToolUse" ]; then
          echo "⚠️  $event[$i].hooks[$j]: Prompt hooks may not be fully supported on $event (best on Stop, SubagentStop, UserPromptSubmit, PreToolUse)"
          warning_count=$((warning_count + 1))
        fi
      fi

      # Check timeout
      timeout=$(jq -r ".\"$event\"[$i].hooks[$j].timeout // empty" "$EVENTS_FILE")
      if [ -n "$timeout" ] && [ "$timeout" != "null" ]; then
        if ! [[ "$timeout" =~ ^[0-9]+$ ]]; then
          echo "❌ $event[$i].hooks[$j]: Timeout must be a number"
          error_count=$((error_count + 1))
        elif [ "$timeout" -gt 600 ]; then
          echo "⚠️  $event[$i].hooks[$j]: Timeout $timeout seconds is very high (max 600s)"
          warning_count=$((warning_count + 1))
        elif [ "$timeout" -lt 5 ]; then
          echo "⚠️  $event[$i].hooks[$j]: Timeout $timeout seconds is very low"
          warning_count=$((warning_count + 1))
        fi
      fi
    done
  done
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
  echo "✅ All checks passed!"
  exit 0
elif [ $error_count -eq 0 ]; then
  echo "⚠️  Validation passed with $warning_count warning(s)"
  exit 0
else
  echo "❌ Validation failed with $error_count error(s) and $warning_count warning(s)"
  exit 1
fi
