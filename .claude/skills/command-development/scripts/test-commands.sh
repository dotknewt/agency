#!/usr/bin/env bash
#
# test-commands.sh - Run structural and frontmatter validation across every
# slash command file in a directory. Wraps validate-command.sh and
# validate-frontmatter.sh and prints a pass/fail summary.
#
# USAGE:
#   test-commands.sh [command-dir]
#   test-commands.sh --help
#
# EXAMPLES:
#   test-commands.sh                     # defaults to .claude/commands
#   test-commands.sh .claude/commands
#   test-commands.sh path/to/plugin/commands
#
# OUTPUT:
#   Per-file PASS/FAIL lines and the final summary go to stdout.
#   Diagnostics (which file/script is running) go to stderr.
#
# EXIT CODES:
#   0  all commands passed both validators
#   1  usage error
#   2  command directory not found, or contains no .md files
#   3  one or more commands failed validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_help() {
  cat <<'EOF'
test-commands.sh - Validate every slash command in a directory

USAGE:
  test-commands.sh [command-dir]
  test-commands.sh --help

EXAMPLES:
  test-commands.sh                    # defaults to .claude/commands
  test-commands.sh .claude/commands
  test-commands.sh path/to/plugin/commands

Runs validate-command.sh (structure) and validate-frontmatter.sh (field
values) against every *.md file in the directory and prints a summary.

OUTPUT:
  Per-file PASS/FAIL results and the summary line go to stdout.
  Diagnostics go to stderr.

EXIT CODES:
  0  all commands passed
  1  usage error
  2  command directory not found, or contains no .md files
  3  one or more commands failed validation
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  print_help
  exit 0
fi

if [[ $# -gt 1 ]]; then
  echo "Error: too many arguments." >&2
  echo "Run 'test-commands.sh --help' for usage." >&2
  exit 1
fi

command_dir="${1:-.claude/commands}"

if [[ ! -d "$command_dir" ]]; then
  echo "Error: directory not found: $command_dir" >&2
  exit 2
fi

shopt -s nullglob
command_files=("$command_dir"/*.md)
shopt -u nullglob

if [[ ${#command_files[@]} -eq 0 ]]; then
  echo "Error: no .md files found in $command_dir" >&2
  exit 2
fi

echo "Testing ${#command_files[@]} command file(s) in $command_dir" >&2
echo "Command Test Suite"
echo "=================="

passed=0
failed=0

for command_file in "${command_files[@]}"; do
  echo "Checking: $command_file" >&2
  name=$(basename "$command_file" .md)
  echo ""
  echo "-- $name --"

  ok=1

  if ! "$SCRIPT_DIR/validate-command.sh" "$command_file"; then
    ok=0
  fi

  if ! "$SCRIPT_DIR/validate-frontmatter.sh" "$command_file"; then
    ok=0
  fi

  if [[ $ok -eq 1 ]]; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

echo ""
echo "=================="
echo "Summary: $passed passed, $failed failed, ${#command_files[@]} total"

if [[ $failed -gt 0 ]]; then
  exit 3
fi

exit 0
