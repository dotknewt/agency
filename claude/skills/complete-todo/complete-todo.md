---
name: complete-todo
description: Find TODOs, implement pending ones, remove completed ones, then commit. TRIGGER when: (1) the user says "complete todo", "do the TODOs", "finish the TODO", "work through TODOs", or any similar phrasing asking to act on outstanding tasks; (2) a follow-up prompt directly references a specific item, task, or feature that appeared in a previously-displayed TODO summary — e.g. "now do the X one", "what about the Y task", "also handle the Z item", "can you do that one too", or any phrasing that picks up a named item from a prior TODO list shown in this session.
---

# Complete TODO

## Phase 1 — Discover (read once, remember)

1. **Before reading any tasks**: Run `git status --porcelain TODO.md`
   - If `TODO.md` is modified (unstaged changes), re-read it now — do not trust any previously-read version
   - If clean or not found, proceed with the version you have
2. Check for a `TODO.md` at the project root. If absent, grep for `TODO` / `FIXME` comments across source files. Note every item with its location.
3. Run `git log --oneline -5` to understand recent work — some TODOs may already be done.
4. For each TODO item, read the relevant source file(s) **once** using `offset`/`limit` to target only the section that matters. Record what you read so you don't re-read later.
5. Cross-reference each TODO against the code you just read. Mark each item: **done** or **pending**.

## Phase 2 — Plan

Enter plan mode. For each **pending** item, describe exactly what change is needed and which file/line it touches. Reference the code content already in context — do not re-read files you already read in Phase 1.

## Phase 3 — Implement

Before editing a file, run: `git status --porcelain <file>`
If the file shows as modified (i.e. changed since Phase 1 read), re-read the relevant section before editing. Otherwise use the content already in context.

Implement each pending item. After each edit, mark it done in your mental list.

**Rules:**
- After completing each item, update any relevant memory files (e.g. `CLAUDE.md`, project notes) to reflect new state.
- Commit after each item — one commit per task/bullet-point, not one big commit at the end.

## Phase 4 — Clean up TODO source

- Remove every completed item from `TODO.md` (or clear the inline comment).
- If `TODO.md` is now empty (or only has a header with no items), delete the file.

## Phase 5 — Commit (per item)
```
git add <changed files>
git commit -m "<concise summary of what was implemented>"
```

Repeat Phase 3–5 for each pending item before moving to the next.
