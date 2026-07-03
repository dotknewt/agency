---
name: plugin-settings
description: Use this skill when the user wants to store or read plugin-specific configuration or state on a per-project basis — e.g. "plugin settings", "store plugin configuration", "user-configurable plugin", ".local.md files", "plugin state files", "per-project plugin settings", or parsing the YAML frontmatter of a `.claude/plugin-name.local.md` file. Push further and use it even if they don't say .local.md, such as when asking to make a hook or command remember state per project, persist config between sessions, or toggle plugin behavior without editing hooks.json. Documents the .claude/plugin-name.local.md pattern — YAML frontmatter plus a markdown body — including how to read, create, and validate these files from hooks, commands, and agents.
metadata:
  version: "0.1.0"
---

# Settings Pattern for Claude Code Plugins

## Overview

Plugins can store user-configurable settings and state in `.claude/plugin-name.local.md` files within the project directory. This pattern uses YAML frontmatter for structured configuration and markdown content for prompts or additional context.

**Key characteristics:**
- File location: `.claude/plugin-name.local.md` in project root
- Structure: YAML frontmatter + markdown body
- Purpose: Per-project plugin configuration and state
- Usage: Read from hooks, commands, and agents
- Lifecycle: User-managed (not in git, should be in `.gitignore`)

**See also:** `.claude/skills/hook-development` for general hook file I/O patterns, and `.claude/skills/plugin-structure` for overall plugin file/directory conventions — both have light overlap with this skill but distinct scope.

## Gotchas

- Quoted and unquoted scalar values are both valid YAML (`field: value` and `field: "value"`); strip both single and double quotes when parsing, or values will include the literal quote characters.
- If the markdown body itself contains a `---` line (e.g. a horizontal rule), frontmatter extraction still works — `sed -n '/^---$/,/^---$/{ /^---$/d; p; }'` and `awk '/^---$/{i++; next} i>=2'` only count the first two `---` markers.
- A malformed file with only one `---` marker does not error on its own — sed's range extraction silently treats everything after that single marker as "frontmatter" (or as the body), producing garbage rather than a clear failure. Run `scripts/validate-settings.sh` before parsing to catch this.
- Settings changes never hot-reload. Hooks and their configuration are only re-read on Claude Code restart — always tell the user to restart after creating or editing a `.local.md` file.
- List fields (`list_field: ["a", "b"]`) are not reliably parseable with grep/sed; use `yq -o json` for real list handling, or treat the field as an opaque string for simple substring checks.
- Never edit a settings file in place with `sed -i`; write to a temp file and `mv` it atomically, or a crash mid-write can corrupt the file the next hook invocation reads.
- With `set -euo pipefail`, a `grep` that finds no match (an unset/optional field) exits non-zero and — unguarded — aborts the whole script instead of falling through to a default. Append `|| true` to field-extraction pipelines that read optional fields.

## File Structure

### Basic Template

```markdown
---
enabled: true
setting1: value1
setting2: value2
numeric_setting: 42
list_setting: ["item1", "item2"]
---

# Additional Context

This markdown body can contain:
- Task descriptions
- Additional instructions
- Prompts to feed back to Claude
- Documentation or notes
```

### Example: Plugin State File

**.claude/my-plugin.local.md:**
```markdown
---
enabled: true
strict_mode: false
max_retries: 3
notification_level: info
coordinator_session: team-leader
---

# Plugin Configuration

This plugin is configured for standard validation mode.
Contact @team-lead with questions.
```

## Reading Settings Files

### From Hooks (Bash Scripts)

**Pattern: Check existence and parse frontmatter**

```bash
#!/bin/bash
set -euo pipefail

# Define state file path
STATE_FILE=".claude/my-plugin.local.md"

# Quick exit if file doesn't exist
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0  # Plugin not configured, skip
fi

# Parse YAML frontmatter (between --- markers)
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")

# Extract individual fields
ENABLED=$(echo "$FRONTMATTER" | grep '^enabled:' | sed 's/enabled: *//' | sed 's/^"\(.*\)"$/\1/')
STRICT_MODE=$(echo "$FRONTMATTER" | grep '^strict_mode:' | sed 's/strict_mode: *//' | sed 's/^"\(.*\)"$/\1/')

# Check if enabled
if [[ "$ENABLED" != "true" ]]; then
  exit 0  # Disabled
fi

# Use configuration in hook logic
if [[ "$STRICT_MODE" == "true" ]]; then
  # Apply strict validation
  # ...
fi
```

See `examples/read-settings-hook.sh` for a complete working example, including the correct deny/allow decision output pattern.

### From Commands

Commands can read settings files to customize behavior:

```markdown
---
description: Process data with plugin
allowed-tools: ["Read", "Bash"]
---

# Process Command

Steps:
1. Check if settings exist at `.claude/my-plugin.local.md`
2. Read configuration using Read tool
3. Parse YAML frontmatter to extract settings
4. Apply settings to processing logic
5. Execute with configured behavior
```

### From Agents

Agents can reference settings in their instructions:

```markdown
---
name: configured-agent
description: Agent that adapts to project settings
---

Check for plugin settings at `.claude/my-plugin.local.md`.
If present, parse YAML frontmatter and adapt behavior according to:
- enabled: Whether plugin is active
- mode: Processing mode (strict, standard, lenient)
- Additional configuration fields
```

## Parsing and Usage Patterns

Frontmatter is extracted with `sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE"`, then individual fields are pulled out with `grep '^field:' | sed 's/field: *//'` and quote-stripped as needed (see Gotchas above for the traps in this approach). Once fields are parsed, three usage patterns cover most cases:

- **Toggle a hook on/off** — gate a hook's whole body behind `enabled: true` in the settings file, so it can be activated/deactivated without editing `hooks.json` (which requires a restart anyway).
- **Coordinate state across agents/sessions** — store IDs, session names, or task metadata in frontmatter and read it from a Stop/notification hook.
- **Switch behavior on a mode field** — `case` over a `mode`/`validation_level` field to change strictness.

For the complete parsing reference — string/boolean/numeric/list field parsing, extracting the markdown body, atomic updates, validation, debugging, and the full edge-case list — see `references/parsing-techniques.md`.

## Creating Settings Files

### From Commands

Commands can create settings files:

```markdown
# Setup Command

Steps:
1. Ask user for configuration preferences
2. Create `.claude/my-plugin.local.md` with YAML frontmatter
3. Set appropriate values based on user input
4. Inform user that settings are saved
5. Remind user to restart Claude Code for hooks to recognize changes
```

### Template Generation

Provide template in plugin README:

```markdown
## Configuration

Create `.claude/my-plugin.local.md` in your project:

\`\`\`markdown
---
enabled: true
mode: standard
max_retries: 3
---

# Plugin Configuration

Your settings are active.
\`\`\`

After creating or editing, restart Claude Code for changes to take effect.
```

## Best Practices

### File Naming

✅ **DO:**
- Use `.claude/plugin-name.local.md` format
- Match plugin name exactly
- Use `.local.md` suffix for user-local files

❌ **DON'T:**
- Use different directory (not `.claude/`)
- Use inconsistent naming
- Use `.md` without `.local` (might be committed)

### Gitignore

Always add to `.gitignore`:

```gitignore
.claude/*.local.md
.claude/*.local.json
```

Document this in plugin README.

### Defaults

Provide sensible defaults when settings file doesn't exist:

```bash
if [[ ! -f "$STATE_FILE" ]]; then
  # Use defaults
  ENABLED=true
  MODE=standard
else
  # Read from file
  # ...
fi
```

### Validation

Validate settings values:

```bash
MAX=$(echo "$FRONTMATTER" | grep '^max_value:' | sed 's/max_value: *//')

# Validate numeric range
if ! [[ "$MAX" =~ ^[0-9]+$ ]] || [[ $MAX -lt 1 ]] || [[ $MAX -gt 100 ]]; then
  echo "⚠️  Invalid max_value in settings (must be 1-100)" >&2
  MAX=10  # Use default
fi
```

### Restart Requirement

**Important:** Settings changes require Claude Code restart.

Document in your README:

```markdown
## Changing Settings

After editing `.claude/my-plugin.local.md`:
1. Save the file
2. Exit Claude Code
3. Restart: `claude` or `cc`
4. New settings will be loaded
```

Hooks cannot be hot-swapped within a session.

## Security Considerations

### Sanitize User Input

When writing settings files from user input:

```bash
# Escape quotes in user input
SAFE_VALUE=$(echo "$USER_INPUT" | sed 's/"/\\"/g')

# Write to file
cat > "$STATE_FILE" <<EOF
---
user_setting: "$SAFE_VALUE"
---
EOF
```

### Validate File Paths

If settings contain file paths:

```bash
FILE_PATH=$(echo "$FRONTMATTER" | grep '^data_file:' | sed 's/data_file: *//')

# Check for path traversal
if [[ "$FILE_PATH" == *".."* ]]; then
  echo "⚠️  Invalid path in settings (path traversal)" >&2
  exit 2
fi
```

### Permissions

Settings files should be:
- Readable by user only (`chmod 600`)
- Not committed to git
- Not shared between users

## Illustrative Examples

`references/real-world-examples.md` walks through two illustrative example plugins — `multi-agent-swarm` (agent-coordination state) and `ralph-loop` (loop-iteration state). Both names were invented to demonstrate the pattern end-to-end; they are not real, production plugins shipped in this marketplace. Each walkthrough includes a full settings file, the hook that reads it, and the command that creates it — use it as a template when designing a new plugin's settings schema.

## Quick Reference

### File Location

```
project-root/
└── .claude/
    └── plugin-name.local.md
```

### Frontmatter Parsing

```bash
# Extract frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$FILE")

# Read field
VALUE=$(echo "$FRONTMATTER" | grep '^field:' | sed 's/field: *//' | sed 's/^"\(.*\)"$/\1/')
```

### Body Parsing

```bash
# Extract body (after second ---)
BODY=$(awk '/^---$/{i++; next} i>=2' "$FILE")
```

### Quick Exit Pattern

```bash
if [[ ! -f ".claude/my-plugin.local.md" ]]; then
  exit 0  # Not configured
fi
```

## Additional Resources

### Reference Files

For detailed implementation patterns:

- **`references/parsing-techniques.md`** - Complete guide to parsing YAML frontmatter and markdown bodies
- **`references/real-world-examples.md`** - Illustrative multi-agent-swarm and ralph-loop walkthroughs (not real, production plugins)

### Example Files

Working examples in `examples/`:

- **`read-settings-hook.sh`** - Hook that reads and uses settings
- **`create-settings-command.md`** - Command that creates settings file
- **`example-settings.md`** - Template settings file

### Utility Scripts

Development tools in `scripts/`:

- **`validate-settings.sh`** - Validate settings file structure
- **`parse-frontmatter.sh`** - Extract frontmatter fields

## Implementation Workflow

To add settings to a plugin:

1. Design settings schema (which fields, types, defaults)
2. Create template file in plugin documentation
3. Add gitignore entry for `.claude/*.local.md`
4. Implement settings parsing in hooks/commands
5. Use quick-exit pattern (check file exists, check enabled field)
6. Document settings in plugin README with template
7. Remind users that changes require Claude Code restart

Focus on keeping settings simple and providing good defaults when settings file doesn't exist.
