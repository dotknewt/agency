#!/usr/bin/env python3
"""Validate a SKILL.md file against the core structural rules in specs/skills/skill-spec.md.

Checks performed:
  1. name       - present, lowercase alphanumeric + hyphens, matches the parent directory name
  2. description - present, non-empty, <= 1024 characters
  3. body length - the Markdown body (everything after the frontmatter) is under
                    ~500 lines (specs/skills/skill-spec.md: "Keep your main SKILL.md
                    under 500 lines")
  4. references  - every relative file reference found in the body (e.g. `references/foo.md`,
                    `scripts/bar.py`, `examples/baz.sh`, `assets/qux.png`) resolves to a real
                    file relative to the skill root. References inside fenced code blocks
                    (``` ... ```) are skipped, since those are frequently illustrative
                    templates rather than real bundled files.

This script is pure standard library - no third-party dependencies required.

Usage:
  validate_skill.py <path-to-SKILL.md>
  validate_skill.py <path-to-skill-directory>
  validate_skill.py --json <path-to-SKILL.md>

Options:
  --json          Emit machine-readable JSON instead of human-readable text.
  --max-lines N   Override the body line-count ceiling (default: 500).
  -h, --help      Show this help message and exit.

Examples:
  validate_skill.py .claude/skills/skill-development/SKILL.md
  validate_skill.py .claude/skills/skill-development --json
  python3 scripts/validate_skill.py ../hook-development --max-lines 400

Exit codes (bitmask - values OR together when multiple checks fail):
  0   All checks passed.
  1   Usage error (bad arguments, file/directory not found, unreadable file).
  2   No YAML frontmatter found, or frontmatter missing `name` or `description`.
  4   `name` is invalid (not lowercase alphanumeric+hyphens) or does not match
      the parent directory name.
  8   `description` is empty or exceeds 1024 characters.
  16  Body exceeds the maximum line count.
  32  One or more relative file references in the body do not exist on disk.

When several checks fail at once, the exit code is the sum of the relevant bits
(e.g. 12 means both the name check and the description check failed).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

EXIT_OK = 0
EXIT_USAGE = 1
EXIT_FRONTMATTER = 2
EXIT_NAME = 4
EXIT_DESCRIPTION = 8
EXIT_BODY_LENGTH = 16
EXIT_BROKEN_REFERENCES = 32

DEFAULT_MAX_LINES = 500
MAX_DESCRIPTION_CHARS = 1024
NAME_PATTERN = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")

# Directories conventionally used for bundled skill resources. A reference is only
# checked against disk if it starts with one of these (avoids false positives on
# arbitrary prose that happens to contain a slash).
RESOURCE_DIR_PREFIXES = ("references/", "scripts/", "examples/", "assets/")

REFERENCE_PATTERN = re.compile(
    r"(?<![\w./-])(?:references|scripts|examples|assets)/[A-Za-z0-9_.\-/]+[A-Za-z0-9_/]"
)

FENCED_CODE_BLOCK_PATTERN = re.compile(r"```.*?```", re.DOTALL)


def strip_fenced_code_blocks(text: str) -> str:
    """Remove fenced code blocks so illustrative example paths inside them are not
    treated as real bundled-resource references."""
    return FENCED_CODE_BLOCK_PATTERN.sub("", text)


def parse_frontmatter(text: str):
    """Extract a best-effort dict of top-level frontmatter keys and the index of the
    first body line. Supports plain scalars and simple '>'/'|' block scalars, which
    covers every SKILL.md style seen in this repo. Returns (data, body_start_line)
    or (None, None) if no frontmatter delimiters are found."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None, None

    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break
    if end_idx is None:
        return None, None

    data: dict[str, str] = {}
    current_key = None
    block_mode = None
    block_buffer: list[str] = []

    def flush_block():
        if current_key is not None and block_mode is not None:
            joined = (
                " ".join(block_buffer) if block_mode == ">" else "\n".join(block_buffer)
            )
            data[current_key] = joined.strip()

    for line in lines[1:end_idx]:
        if line.strip() == "":
            if current_key is not None and block_mode is not None:
                block_buffer.append("")
            continue
        if not line[0].isspace() and ":" in line:
            flush_block()
            current_key, _, value = line.partition(":")
            current_key = current_key.strip()
            value = value.strip()
            if value in (">", "|", ">-", "|-", ">+", "|+"):
                block_mode = value[0]
                block_buffer = []
            else:
                block_mode = None
                block_buffer = []
                if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                    value = value[1:-1]
                data[current_key] = value
        else:
            if current_key is not None and block_mode is not None:
                block_buffer.append(line.strip())
    flush_block()

    return data, end_idx + 1


def find_broken_references(body_lines: list[str], skill_root: Path) -> list[str]:
    body_text = "\n".join(body_lines)
    cleaned = strip_fenced_code_blocks(body_text)

    found = set(REFERENCE_PATTERN.findall(cleaned))
    broken = []
    for ref in sorted(found):
        ref = ref.rstrip(").,;:'\"")
        if not ref.startswith(RESOURCE_DIR_PREFIXES):
            continue
        candidate = skill_root / ref
        if not candidate.exists():
            broken.append(ref)
    return broken


def resolve_skill_md(path_arg: str) -> Path:
    p = Path(path_arg)
    if p.is_dir():
        p = p / "SKILL.md"
    return p


def validate(skill_md_path: Path, max_lines: int) -> dict:
    result = {
        "skill_md": str(skill_md_path),
        "checks": [],
        "exit_code": EXIT_OK,
    }

    def add_check(name: str, passed: bool, detail: str, bit: int = 0):
        result["checks"].append({"check": name, "passed": passed, "detail": detail})
        if not passed:
            result["exit_code"] |= bit

    if not skill_md_path.exists():
        raise FileNotFoundError(f"No such file: {skill_md_path}")
    if not skill_md_path.is_file():
        raise FileNotFoundError(f"Not a file: {skill_md_path}")

    text = skill_md_path.read_text(encoding="utf-8")
    skill_root = skill_md_path.parent

    data, body_start = parse_frontmatter(text)

    if data is None:
        add_check(
            "frontmatter",
            False,
            "No YAML frontmatter delimited by '---' lines was found.",
            EXIT_FRONTMATTER,
        )
        # Nothing further can be checked reliably without frontmatter.
        return result

    name = data.get("name")
    description = data.get("description")

    if not name or not description:
        missing = [k for k in ("name", "description") if not data.get(k)]
        add_check(
            "frontmatter",
            False,
            f"Frontmatter is missing required field(s): {', '.join(missing)}",
            EXIT_FRONTMATTER,
        )
    else:
        add_check("frontmatter", True, "name and description fields are present.")

    if name:
        expected_dir = skill_root.name
        name_valid = bool(NAME_PATTERN.match(name))
        name_matches = name == expected_dir
        if name_valid and name_matches:
            add_check("name", True, f"name '{name}' matches parent directory '{expected_dir}'.")
        else:
            problems = []
            if not name_valid:
                problems.append("must be lowercase alphanumeric characters and hyphens only, no leading/trailing/consecutive hyphens")
            if not name_matches:
                problems.append(f"must match parent directory name (got '{name}', directory is '{expected_dir}')")
            add_check("name", False, "; ".join(problems), EXIT_NAME)

    if description is not None:
        desc_len = len(description)
        if desc_len == 0:
            add_check("description", False, "description is empty.", EXIT_DESCRIPTION)
        elif desc_len > MAX_DESCRIPTION_CHARS:
            add_check(
                "description",
                False,
                f"description is {desc_len} characters, exceeds the {MAX_DESCRIPTION_CHARS} limit.",
                EXIT_DESCRIPTION,
            )
        else:
            add_check("description", True, f"description is {desc_len} characters (limit {MAX_DESCRIPTION_CHARS}).")

    body_lines = text.splitlines()[body_start:] if body_start is not None else []
    body_line_count = len(body_lines)
    if body_line_count > max_lines:
        add_check(
            "body_length",
            False,
            f"body is {body_line_count} lines, exceeds the {max_lines}-line guidance.",
            EXIT_BODY_LENGTH,
        )
    else:
        add_check("body_length", True, f"body is {body_line_count} lines (limit {max_lines}).")

    broken = find_broken_references(body_lines, skill_root)
    if broken:
        add_check(
            "file_references",
            False,
            "referenced file(s) not found on disk: " + ", ".join(broken),
            EXIT_BROKEN_REFERENCES,
        )
    else:
        add_check("file_references", True, "all relative file references resolve to real files.")

    return result


def print_human(result: dict) -> None:
    print(f"Validating {result['skill_md']}")
    for check in result["checks"]:
        status = "PASS" if check["passed"] else "FAIL"
        print(f"  [{status}] {check['check']}: {check['detail']}")
    if result["exit_code"] == EXIT_OK:
        print("All checks passed.")
    else:
        print(f"One or more checks failed (exit code {result['exit_code']}).")


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        prog="validate_skill.py",
        description="Validate a SKILL.md file's structure against specs/skills/skill-spec.md.",
        epilog=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("path", help="Path to a SKILL.md file, or a skill directory containing one.")
    parser.add_argument("--json", action="store_true", help="Emit machine-readable JSON instead of text.")
    parser.add_argument(
        "--max-lines",
        type=int,
        default=DEFAULT_MAX_LINES,
        help=f"Maximum allowed body line count (default: {DEFAULT_MAX_LINES}).",
    )
    args = parser.parse_args(argv)

    skill_md_path = resolve_skill_md(args.path)

    try:
        result = validate(skill_md_path, args.max_lines)
    except FileNotFoundError as exc:
        if args.json:
            print(json.dumps({"error": str(exc)}, indent=2))
        else:
            print(f"Error: {exc}", file=sys.stderr)
        return EXIT_USAGE
    except OSError as exc:
        if args.json:
            print(json.dumps({"error": str(exc)}, indent=2))
        else:
            print(f"Error: {exc}", file=sys.stderr)
        return EXIT_USAGE

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print_human(result)

    return result["exit_code"]


if __name__ == "__main__":
    sys.exit(main())
