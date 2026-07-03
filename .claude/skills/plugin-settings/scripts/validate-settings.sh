#!/bin/bash
# Settings File Validator
# Validates .claude/plugin-name.local.md structure
#
# All human-readable progress/diagnostics (checkmarks, warnings, prose) are
# written to stderr. A single machine-parseable JSON summary is written to
# stdout when validation finishes, whether it passes or fails.
#
# Exit codes:
#   0  = valid (structural checks passed; warnings alone do not fail the run)
#   1  = file not found
#   2  = file not readable (permission denied)
#   3  = invalid/missing frontmatter structure
#   64 = usage error (missing required argument)

set -uo pipefail

PROG="$(basename "$0")"

show_usage() {
  cat <<EOF
Usage: $PROG <path/to/settings.local.md>

Validates plugin settings file for:
  - File existence and readability
  - YAML frontmatter structure
  - Required --- markers
  - Field format

Example: $PROG .claude/my-plugin.local.md

Exit codes:
  0=valid 1=not-found 2=unreadable 3=invalid-frontmatter 64=usage-error
EOF
}

# Minimal JSON string escaping (backslashes and double quotes) - no jq
# dependency required for the machine-readable summary line.
json_str() {
  printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}

# -h/--help is a help request, not an error: print to stdout, exit 0.
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  show_usage
  exit 0
fi

# Missing required argument is a usage error: print to stderr, exit 64.
if [ $# -eq 0 ]; then
  show_usage >&2
  exit 64
fi

SETTINGS_FILE="$1"
WARNINGS=0

echo "Validating settings file: $SETTINGS_FILE" >&2
echo "" >&2

# Check 1: File exists
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "FAIL: File not found: $SETTINGS_FILE" >&2
  printf '{"status":"fail","reason":"not_found","file":%s}\n' "$(json_str "$SETTINGS_FILE")"
  exit 1
fi
echo "OK: File exists" >&2

# Check 2: File is readable
if [ ! -r "$SETTINGS_FILE" ]; then
  echo "FAIL: File is not readable" >&2
  printf '{"status":"fail","reason":"unreadable","file":%s}\n' "$(json_str "$SETTINGS_FILE")"
  exit 2
fi
echo "OK: File is readable" >&2

# Check 3: Has frontmatter markers
MARKER_COUNT=$(grep -c '^---$' "$SETTINGS_FILE" 2>/dev/null || echo "0")

if [ "$MARKER_COUNT" -lt 2 ]; then
  echo "FAIL: Invalid frontmatter: found $MARKER_COUNT '---' markers (need at least 2)" >&2
  echo "      Expected format:" >&2
  echo "      ---" >&2
  echo "      field: value" >&2
  echo "      ---" >&2
  echo "      Content..." >&2
  printf '{"status":"fail","reason":"invalid_frontmatter","file":%s,"marker_count":%s}\n' \
    "$(json_str "$SETTINGS_FILE")" "$MARKER_COUNT"
  exit 3
fi
echo "OK: Frontmatter markers present" >&2

# Check 4: Extract and validate frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SETTINGS_FILE")

if [ -z "$FRONTMATTER" ]; then
  echo "FAIL: Empty frontmatter (nothing between --- markers)" >&2
  printf '{"status":"fail","reason":"empty_frontmatter","file":%s}\n' "$(json_str "$SETTINGS_FILE")"
  exit 3
fi
echo "OK: Frontmatter not empty" >&2

# Check 5: Frontmatter has valid YAML-like structure
if ! echo "$FRONTMATTER" | grep -q ':'; then
  echo "WARN: Frontmatter has no key:value pairs" >&2
  WARNINGS=$((WARNINGS + 1))
fi

# Check 6: Look for common fields
FIELD_COUNT=$(echo "$FRONTMATTER" | grep -c '^[a-z_][a-z0-9_]*:' 2>/dev/null || echo "0")
echo "" >&2
echo "Detected fields ($FIELD_COUNT):" >&2
echo "$FRONTMATTER" | grep '^[a-z_][a-z0-9_]*:' 2>/dev/null | while IFS=':' read -r key value; do
  echo "  - $key: ${value:0:50}" >&2
done || true

# Check 7: Validate common boolean fields
for field in enabled strict_mode; do
  VALUE=$(echo "$FRONTMATTER" | grep "^${field}:" | sed "s/${field}: *//" || true)
  if [ -n "$VALUE" ]; then
    if [ "$VALUE" != "true" ] && [ "$VALUE" != "false" ]; then
      echo "WARN: Field '$field' should be boolean (true/false), got: $VALUE" >&2
      WARNINGS=$((WARNINGS + 1))
    fi
  fi
done

# Check 8: Check body exists
BODY=$(awk '/^---$/{i++; next} i>=2' "$SETTINGS_FILE")

HAS_BODY=false
BODY_LINES=0
echo "" >&2
if [ -n "$BODY" ]; then
  HAS_BODY=true
  BODY_LINES=$(echo "$BODY" | wc -l | tr -d ' ')
  echo "OK: Markdown body present ($BODY_LINES lines)" >&2
else
  echo "WARN: No markdown body (frontmatter only)" >&2
  WARNINGS=$((WARNINGS + 1))
fi

echo "" >&2
echo "Settings file structure is valid" >&2
echo "Reminder: Changes to this file require restarting Claude Code" >&2

# Machine-parseable summary on stdout (the only thing a caller should parse).
printf '{"status":"pass","file":%s,"fields":%s,"has_body":%s,"body_lines":%s,"warnings":%s}\n' \
  "$(json_str "$SETTINGS_FILE")" "$FIELD_COUNT" "$HAS_BODY" "$BODY_LINES" "$WARNINGS"

exit 0
