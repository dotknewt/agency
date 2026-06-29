---
description: Scaffold a new agent file inside a plugin's agents/ directory (delegates spec generation to the agent-creator agent)
argument-hint: "<agent-name> [<one-line purpose>]"
allowed-tools: ["Read", "Write", "Bash", "Glob", "AskUserQuestion", "Task"]
---

# /create-agent

Scaffold a new agent under a plugin's `agents/` directory.

**Arguments:** `$ARGUMENTS`

## Steps

1. **Parse arguments:**
   - First token: the agent identifier (kebab-case). If missing, ask.
   - Remaining tokens: optional one-line purpose seed.

2. **Validate the identifier:**
   - Must match `^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$` and be 3–50 characters.
   - If invalid, report the issue and stop.

3. **Resolve the target plugin directory:**
   - If cwd contains `.claude-plugin/plugin.json`, use cwd.
   - Else search `plugins/*/.claude-plugin/plugin.json` (Glob); if exactly one match, use it; if multiple, use AskUserQuestion to let the user pick.
   - If none found, ask the user for an explicit plugin path.

4. **Collision check:** If `<plugin>/agents/<name>.md` already exists, stop and report.

5. **Ensure `<plugin>/agents/` exists** (create it if not).

6. **Gather missing context:** If no purpose seed was supplied, ask the user with one AskUserQuestion call covering:
   - Purpose / what the agent does
   - Trigger phrases that should activate it
   - Tools it needs (or "all tools")
   - Model preference (default `inherit`)
   - Color preference (blue/cyan for analysis, green for generation, yellow for validation, red for security, magenta for creative)

7. **Delegate to `agent-creator`** via the Task tool. The prompt to the agent must include:
   - Identifier
   - Target output path: `<plugin>/agents/<name>.md`
   - Purpose and trigger phrases
   - Tool list, model, color
   - Instruction: write the file at exactly that path and return a short summary.

8. **Confirm** to the user:
   ```
   Created <plugin>/agents/<name>.md
   Next: run the plugin-validator agent to check the plugin structure.
   ```
   Do not register in `marketplace.json` — agents live inside plugins, not the marketplace.

## Notes

- All agent spec generation (persona, examples, system prompt, quality checks) is handled by `agent-creator`. This command's job is orchestration only.
- The auto-trigger on "create an agent..." phrases remains unchanged — this command adds an explicit slash-command entry point alongside it.
