#!/usr/bin/env bash
#
# validate-command.sh - Validate a Claude Code slash command file's structure.
#
# Checks file location, extension, emptiness, and basic YAML frontmatter
# syntax (that '---' markers are balanced). Does not validate individual
# frontmatter field values -- see validate-frontmatter.sh for that.
#
# USAGE:
#   validate-command.sh <command-file.md> [command-file2.md ...]
#   validate-command.sh --help
#
# EXAMPLES:
#   validate-command.sh .claude/commands/review.md
#   validate-command.sh .claude/commands/*.md
#
# OUTPUT:
#   Results (PASS/FAIL per file, one line each) are written to stdout.
#   Diagnostic/progress messages are written to stderr.
#
# EXIT CODES:
#   0  all files valid
#   1  usage error (no files given)
#   2  one or more files failed validation

set -euo pipefail

print_help() {
  cat <<'EOF'
validate-command.sh - Validate Claude Code slash command file structure

USAGE:
  validate-command.sh <command-file.md> [command-file2.md ...]
  validate-command.sh --help

EXAMPLES:
  validate-command.sh .claude/commands/review.md
  validate-command.sh .claude/commands/*.md

CHECKS:
  - File exists and is readable
  - File has a .md extension
  - File is not empty
  - If YAML frontmatter is present, it has exactly two '---' markers

OUTPUT:
  Results (PASS/FAIL per file) go to stdout.
  Diagnostics and progress messages go to stderr.

EXIT CODES:
  0  all files valid
  1  usage error (no files given)
  2  one or more files failed validation
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  print_help
  exit 0
fi

if [[ $# -eq 0 ]]; then
  echo "Error: no command files given." >&2
  echo "Run 'validate-command.sh --help' for usage." >&2
  exit 1
fi

overall_status=0

for command_file in "$@"; do
  echo "Checking: $command_file" >&2

  if [[ ! -f "$command_file" ]]; then
    echo "FAIL: $command_file: file not found"
    overall_status=2
    continue
  fi

  failures=()

  if [[ "$command_file" != *.md ]]; then
    failures+=("must have a .md extension")
  fi

  if [[ ! -s "$command_file" ]]; then
    failures+=("file is empty")
  elif head -n 1 "$command_file" | grep -q '^---$'; then
    marker_count=$(grep -c '^---$' "$command_file" || true)
    echo "  frontmatter opener found, $marker_count '---' marker(s) total" >&2
    if [[ "$marker_count" -lt 2 ]]; then
      failures+=("frontmatter opened with '---' but never closed (need exactly 2 markers, found $marker_count)")
    fi
  fi

  if [[ ${#failures[@]} -eq 0 ]]; then
    echo "PASS: $command_file"
  else
    for reason in "${failures[@]}"; do
      echo "FAIL: $command_file: $reason"
    done
    overall_status=2
  fi
done

exit $overall_status
