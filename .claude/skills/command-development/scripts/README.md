# Command Development Validation Scripts

Runnable validators for testing slash commands before you ship them. These implement the "Level 1" and "Level 2" checks described in `references/testing-strategies.md`.

## validate-command.sh

Validates a command file's structure: correct extension, non-empty, and balanced YAML frontmatter markers.

**Usage:**
```bash
scripts/validate-command.sh <command-file.md> [command-file2.md ...]
scripts/validate-command.sh --help
```

**Example:**
```bash
scripts/validate-command.sh .claude/commands/*.md
```

**Exit codes:** `0` all valid, `1` usage error, `2` one or more files failed.

## validate-frontmatter.sh

Validates individual frontmatter field values: `model` is a real model name, `description` length, `disable-model-invocation` is a real boolean, `allowed-tools` presence.

**Usage:**
```bash
scripts/validate-frontmatter.sh <command-file.md>
scripts/validate-frontmatter.sh --help
```

**Example:**
```bash
scripts/validate-frontmatter.sh .claude/commands/deploy.md
```

**Exit codes:** `0` valid (warnings don't fail the run), `1` usage error, `2` file not found, `3` one or more fields invalid.

## test-commands.sh

Runs both validators against every `.md` file in a directory and prints a pass/fail summary. Wraps `validate-command.sh` and `validate-frontmatter.sh`.

**Usage:**
```bash
scripts/test-commands.sh [command-dir]   # defaults to .claude/commands
scripts/test-commands.sh --help
```

**Example:**
```bash
scripts/test-commands.sh .claude/commands
scripts/test-commands.sh path/to/plugin/commands
```

**Exit codes:** `0` all commands passed, `1` usage error, `2` directory not found or has no `.md` files, `3` one or more commands failed.

## Output conventions

All three scripts follow the same convention: **results go to stdout** (`PASS:`/`FAIL:`/`OK:`/`WARN:` lines, safe to pipe or grep), and **diagnostics go to stderr** (which file is being checked, intermediate parsing detail). Redirect stderr to silence progress noise while keeping results:

```bash
scripts/test-commands.sh .claude/commands 2>/dev/null
```

## Typical workflow

1. Write or edit a command in `.claude/commands/`.
2. Validate the one you changed: `scripts/validate-command.sh .claude/commands/my-command.md && scripts/validate-frontmatter.sh .claude/commands/my-command.md`
3. Before committing, validate everything: `scripts/test-commands.sh .claude/commands`
4. Wire `test-commands.sh` into a pre-commit hook or CI job so regressions are caught automatically — see the "Pre-Commit Hook" and "Continuous Testing" sections of `references/testing-strategies.md`.
