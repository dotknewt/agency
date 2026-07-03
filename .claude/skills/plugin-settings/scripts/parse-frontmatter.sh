#!/bin/bash
# Frontmatter Parser Utility
# Extracts YAML frontmatter from .local.md files
#
# Exit codes:
#   0  = success
#   1  = file not found
#   2  = file not readable (permission denied)
#   3  = invalid/missing frontmatter (missing --- markers or empty frontmatter)
#   4  = requested field not found in frontmatter
#   64 = usage error (missing required argument)

set -euo pipefail

PROG="$(basename "$0")"

show_usage() {
  cat <<EOF
Usage: $PROG <settings-file.md> [field-name]

Examples:
  # Show all frontmatter
  $PROG .claude/my-plugin.local.md

  # Extract specific field
  $PROG .claude/my-plugin.local.md enabled

  # Extract and use in script
  ENABLED=\$($PROG .claude/my-plugin.local.md enabled)

Exit codes:
  0=success 1=not-found 2=unreadable 3=invalid-frontmatter 4=field-not-found 64=usage-error
EOF
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

FILE="$1"
FIELD="${2:-}"

# Validate file exists
if [ ! -f "$FILE" ]; then
  echo "Error: File not found: $FILE" >&2
  exit 1
fi

# Validate file is readable
if [ ! -r "$FILE" ]; then
  echo "Error: File not readable (permission denied): $FILE" >&2
  exit 2
fi

# Extract frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")

if [ -z "$FRONTMATTER" ]; then
  echo "Error: No frontmatter found in $FILE (missing or empty --- block)" >&2
  exit 3
fi

# If no field specified, output all frontmatter
if [ -z "$FIELD" ]; then
  echo "$FRONTMATTER"
  exit 0
fi

# Extract specific field (the trailing `|| true` keeps a no-match grep from
# tripping `set -e`/`pipefail` before we get a chance to report it cleanly)
VALUE=$(echo "$FRONTMATTER" | grep "^${FIELD}:" | sed "s/${FIELD}: *//" | sed 's/^"\(.*\)"$/\1/' | sed "s/^'\\(.*\\)'$/\\1/" || true)

if [ -z "$VALUE" ]; then
  echo "Error: Field '$FIELD' not found in frontmatter" >&2
  exit 4
fi

echo "$VALUE"
exit 0
