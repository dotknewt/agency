#!/usr/bin/env bash
#
# validate-frontmatter.sh - Validate YAML frontmatter field VALUES in a
# Claude Code slash command file (as opposed to validate-command.sh, which
# only checks overall file structure).
#
# USAGE:
#   validate-frontmatter.sh <command-file.md>
#   validate-frontmatter.sh --help
#
# EXAMPLES:
#   validate-frontmatter.sh .claude/commands/deploy.md
#
# OUTPUT:
#   Results (OK/WARN/FAIL per field) are written to stdout.
#   Diagnostic/progress messages are written to stderr.
#
# EXIT CODES:
#   0  frontmatter valid (WARN lines do not fail the run)
#   1  usage error
#   2  file not found
#   3  one or more fields invalid

set -euo pipefail

print_help() {
  cat <<'EOF'
validate-frontmatter.sh - Validate slash command YAML frontmatter field values

USAGE:
  validate-frontmatter.sh <command-file.md>
  validate-frontmatter.sh --help

EXAMPLES:
  validate-frontmatter.sh .claude/commands/deploy.md

CHECKS:
  - model (if present) is one of: sonnet, opus, haiku
  - description (if present) length: WARN above 60 chars, FAIL above 80
  - allowed-tools (if present) is non-empty
  - disable-model-invocation (if present) is exactly 'true' or 'false'

OUTPUT:
  Results (OK/WARN/FAIL per field) go to stdout.
  Diagnostics go to stderr.

EXIT CODES:
  0  frontmatter valid (warnings do not fail the run)
  1  usage error
  2  file not found
  3  one or more fields invalid
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  print_help
  exit 0
fi

if [[ $# -ne 1 ]]; then
  echo "Error: expected exactly one command file, got $#." >&2
  echo "Run 'validate-frontmatter.sh --help' for usage." >&2
  exit 1
fi

command_file="$1"

if [[ ! -f "$command_file" ]]; then
  echo "Error: file not found: $command_file" >&2
  exit 2
fi

echo "Extracting frontmatter from: $command_file" >&2
frontmatter=$(sed -n '/^---$/,/^---$/p' "$command_file" | sed '1d;$d')

if [[ -z "$frontmatter" ]]; then
  echo "OK: no frontmatter present (all fields are optional)"
  exit 0
fi

exit_status=0

model_line=$(echo "$frontmatter" | grep '^model:' || true)
if [[ -n "$model_line" ]]; then
  model=$(echo "$model_line" | cut -d: -f2- | tr -d ' ')
  echo "Checking model: '$model'" >&2
  case "$model" in
    sonnet|opus|haiku)
      echo "OK: model: $model"
      ;;
    *)
      echo "FAIL: model: '$model' is not one of sonnet, opus, haiku"
      exit_status=3
      ;;
  esac
fi

desc_line=$(echo "$frontmatter" | grep '^description:' || true)
if [[ -n "$desc_line" ]]; then
  desc=$(echo "$desc_line" | cut -d: -f2-)
  length=${#desc}
  echo "Checking description length: $length chars" >&2
  if [[ $length -gt 80 ]]; then
    echo "FAIL: description: $length chars exceeds the 80-char hard limit for clean /help display"
    exit_status=3
  elif [[ $length -gt 60 ]]; then
    echo "WARN: description: $length chars (recommend under 60)"
  else
    echo "OK: description: $length chars"
  fi
fi

if echo "$frontmatter" | grep -q '^allowed-tools:'; then
  echo "OK: allowed-tools field present"
fi

dmi_line=$(echo "$frontmatter" | grep '^disable-model-invocation:' || true)
if [[ -n "$dmi_line" ]]; then
  dmi=$(echo "$dmi_line" | cut -d: -f2- | tr -d ' ')
  echo "Checking disable-model-invocation: '$dmi'" >&2
  case "$dmi" in
    true|false)
      echo "OK: disable-model-invocation: $dmi"
      ;;
    *)
      echo "FAIL: disable-model-invocation: '$dmi' must be exactly 'true' or 'false'"
      exit_status=3
      ;;
  esac
fi

exit $exit_status
