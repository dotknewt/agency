---
description: Restructure CLAUDE.md files to move content closer to where it is needed
allowed-tools: Read, Bash, Edit
---

Goal: reduce context bloat by keeping content only at the deepest level where it applies.

- Root CLAUDE.md = orientation only
- Detail lives in the file closest to where it is needed
- When content appears in multiple files, keep it only in the deepest applicable file and remove it from all shallower files

## Step 1: Find all CLAUDE.md files

```bash
find . -name "CLAUDE.md" -o -name ".claude.local.md" 2>/dev/null | sort
```

## Step 2: Identify misplaced content

Read each file and flag content that belongs deeper:
- Server-specific commands in root → move closer to that server
- Rules only relevant in a subdirectory → move to that subdirectory's CLAUDE.md
- Commands duplicated across files → keep only in the deepest file
- Schema tables duplicated → move to the deepest file where they're used
- Stale content in any subdirectory file → remove it

## Step 3: Show proposed changes

For each move or removal:

```
### Move: ./CLAUDE.md → ./packages/api/CLAUDE.md

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
