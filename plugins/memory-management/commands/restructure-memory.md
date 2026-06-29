---
description: Restructure agent-memory files (AGENTS.md / legacy CLAUDE.md) to move content closer to where it is needed
allowed-tools: Read, Bash, Edit
---

Goal: reduce context bloat by keeping content only at the deepest level where it applies.

- Root `AGENTS.md` = orientation only
- Detail lives in the file closest to where it is needed
- When content appears in multiple files, keep it only in the deepest applicable file and remove it from all shallower files

Applies equally to `AGENTS.md` and any legacy `CLAUDE.md` not yet migrated. Never edit a `CLAUDE.md` stub (one containing only `@AGENTS.md`) — restructure the `AGENTS.md` it points at instead.

## Step 1: Find all memory files

```bash
find . \( -name "AGENTS.md" -o -name "CLAUDE.md" -o -name ".claude.local.md" \) \
  -not -path '*/node_modules/*' -not -path '*/.git/*' 2>/dev/null | sort
```

## Step 2: Identify misplaced content

Read each file and flag content that belongs deeper:
- Server-specific commands in root → move closer to that server
- Rules only relevant in a subdirectory → move to that subdirectory's memory file
- Commands duplicated across files → keep only in the deepest file
- Schema tables duplicated → move to the deepest file where they're used
- Stale content in any subdirectory file → remove it

If both `AGENTS.md` and a non-stub `CLAUDE.md` exist in the same directory, flag the drift and propose consolidating on `AGENTS.md` first (see `skills/memory-management/references/migration.md`). Then restructure.

## Step 3: Show proposed changes

For each move or removal:

```
### Move: ./AGENTS.md → ./packages/api/AGENTS.md

**Why:** [rule is specific to the api package]

\`\`\`diff
- [content being removed from shallower file]
\`\`\`

\`\`\`diff
+ [content being added to deeper file]
\`\`\`
```

## Step 4: Apply with approval

Ask the user to confirm before editing any files.

## Step 5: Refresh the nudge sentinel

After applying changes, run:

```bash
_proj="${CLAUDE_PROJECT_DIR:-.}"
_hash=$(printf '%s' "$_proj" | md5sum | cut -c1-8)
_dirty=$(git -C "$_proj" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
_recent=$(git -C "$_proj" diff --name-only "@{2 hours ago}" HEAD 2>/dev/null | wc -l | tr -d ' ' || echo 0)
mkdir -p /tmp/revise-memory-nudge
printf '%s' "$((_dirty + _recent))" > "/tmp/revise-memory-nudge/$_hash"
```

This prevents the stop hook from re-nudging after this command touches AGENTS.md.
