#!/bin/bash
# Hook Linter
# Checks hook scripts for common issues and best practices

set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: hook-linter.sh <hook-script.sh> [hook-script2.sh ...]
       hook-linter.sh -h | --help

Checks hook scripts for:
  - Shebang presence
  - set -euo pipefail usage
  - Input reading from stdin
  - Proper error handling
  - Variable quoting
  - Exit code usage
  - Hardcoded paths
  - Timeout considerations
  - Correct decision-output channel (stdout+exit0 JSON vs stderr+exit2 text)

Examples:
  hook-linter.sh scripts/my-hook.sh
  hook-linter.sh examples/*.sh
  hook-linter.sh ../my-plugin/scripts/validate.sh ../my-plugin/scripts/notify.sh

Output:
  Progress/diagnostic banners are printed to stderr.
  Lint results (per-check findings and the final summary) are printed to
  stdout.

Exit codes:
  0 - All scripts passed (errors == 0; warnings are still allowed)
  1 - One or more scripts had errors, or no scripts were given
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

check_script() {
  local script="$1"
  local warnings=0
  local errors=0

  echo "🔍 Linting: $script" >&2
  echo "" >&2

  if [ ! -f "$script" ]; then
    echo "❌ Error: File not found"
    return 1
  fi

  # Check 1: Executable
  if [ ! -x "$script" ]; then
    echo "⚠️  Not executable (chmod +x $script)"
    warnings=$((warnings + 1))
  fi

  # Check 2: Shebang
  first_line=$(head -1 "$script")
  if [[ ! "$first_line" =~ ^#!/ ]]; then
    echo "❌ Missing shebang (#!/bin/bash)"
    errors=$((errors + 1))
  fi

  # Check 3: set -euo pipefail
  if ! grep -q "set -euo pipefail" "$script"; then
    echo "⚠️  Missing 'set -euo pipefail' (recommended for safety)"
    warnings=$((warnings + 1))
  fi

  # Check 4: Reads from stdin
  if ! grep -q "cat\|read" "$script"; then
    echo "⚠️  Doesn't appear to read input from stdin"
    warnings=$((warnings + 1))
  fi

  # Check 5: Uses jq for JSON parsing
  if grep -q "tool_input\|tool_name" "$script" && ! grep -q "jq" "$script"; then
    echo "⚠️  Parses hook input but doesn't use jq"
    warnings=$((warnings + 1))
  fi

  # Check 6: Unquoted variables
  if grep -E '\$[A-Za-z_][A-Za-z0-9_]*[^"]' "$script" | grep -v '#' | grep -q .; then
    echo "⚠️  Potentially unquoted variables detected (injection risk)"
    echo "   Always use double quotes: \"\$variable\" not \$variable"
    warnings=$((warnings + 1))
  fi

  # Check 7: Hardcoded paths
  if grep -E '^[^#]*/home/|^[^#]*/usr/|^[^#]*/opt/' "$script" | grep -q .; then
    echo "⚠️  Hardcoded absolute paths detected"
    echo "   Use \$CLAUDE_PROJECT_DIR or \$CLAUDE_PLUGIN_ROOT"
    warnings=$((warnings + 1))
  fi

  # Check 8: Uses CLAUDE_PLUGIN_ROOT
  if ! grep -q "CLAUDE_PLUGIN_ROOT\|CLAUDE_PROJECT_DIR" "$script"; then
    echo "💡 Tip: Use \$CLAUDE_PLUGIN_ROOT for plugin-relative paths"
  fi

  # Check 9: Exit codes
  if ! grep -q "exit 0\|exit 2" "$script"; then
    echo "⚠️  No explicit exit codes (should exit 0 or 2)"
    warnings=$((warnings + 1))
  fi

  # Check 10: Decision-output channel correctness
  #
  # Claude Code only parses hookSpecificOutput/permissionDecision JSON from
  # STDOUT when the hook exits 0. On exit 2, stderr is fed back to Claude as
  # PLAIN TEXT, not parsed as JSON. A script that echoes decision JSON and
  # then redirects it to stderr while exiting 2 is a confirmed bug pattern:
  # the JSON is never parsed, so "ask"/structured decisions silently degrade
  # into raw JSON text shown to Claude.
  if grep -qE '(permissionDecision|hookSpecificOutput)' "$script"; then
    if grep -E 'echo.*(permissionDecision|hookSpecificOutput).*>&2' "$script" | grep -q .; then
      echo "❌ Decision JSON (hookSpecificOutput/permissionDecision) is written to stderr."
      echo "   On exit 2, stderr is shown to Claude as plain text, NOT parsed as JSON."
      echo "   Fix: emit this JSON on stdout and exit 0 instead, e.g.:"
      echo "     echo '{\"hookSpecificOutput\": {\"permissionDecision\": \"ask\"}}'  # stdout"
      echo "     exit 0"
      errors=$((errors + 1))
    fi
  elif grep -q "PreToolUse\|Stop" "$script"; then
    echo "💡 Tip: PreToolUse/Stop hooks can return a decision two ways:"
    echo "   - stdout + exit 0: JSON with hookSpecificOutput.permissionDecision"
    echo "     (allow/deny/ask) — the only path that is parsed as structured output"
    echo "   - stderr + exit 2: a plain-text reason (shown to Claude as feedback,"
    echo "     NOT parsed as JSON) — use this for a simple block/deny"
  fi

  # Check 11: Long-running commands
  if grep -E 'sleep [0-9]{3,}|while true' "$script" | grep -v '#' | grep -q .; then
    echo "⚠️  Potentially long-running code detected"
    echo "   Hooks should complete quickly (< 60s)"
    warnings=$((warnings + 1))
  fi

  # Check 12: Error messages to stderr
  if grep -q 'echo.*".*error\|Error\|denied\|Denied' "$script"; then
    if ! grep -q '>&2' "$script"; then
      echo "⚠️  Error messages should be written to stderr (>&2)"
      warnings=$((warnings + 1))
    fi
  fi

  # Check 13: Input validation
  if ! grep -q "if.*empty\|if.*null\|if.*-z" "$script"; then
    echo "💡 Tip: Consider validating input fields aren't empty"
  fi

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
    echo "✅ No issues found"
    return 0
  elif [ $errors -eq 0 ]; then
    echo "⚠️  Found $warnings warning(s)"
    return 0
  else
    echo "❌ Found $errors error(s) and $warnings warning(s)"
    return 1
  fi
}

echo "🔎 Hook Script Linter" >&2
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
echo "" >&2

total_errors=0

for script in "$@"; do
  if ! check_script "$script"; then
    total_errors=$((total_errors + 1))
  fi
  echo ""
done

if [ $total_errors -eq 0 ]; then
  echo "✅ All scripts passed linting"
  exit 0
else
  echo "❌ $total_errors script(s) had errors"
  exit 1
fi
