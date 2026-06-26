---
description: Scaffold GitHub repo metadata — pick a subtask (issue templates, PR templates, …)
allowed-tools: Read, Bash, Glob
---

Present the available GitHub-scaffolding subtasks and run whichever one the user picks.

## Step 1: Show the catalogue

Print this menu:

| Subtask | Command | What it does |
|---------|---------|--------------|
| Create issue template | `/create-issue-template` | Scaffold a YAML issue form in `.github/ISSUE_TEMPLATE/` |

_(Add a row here each time a new scaffolding command is added to this plugin.)_

## Step 2: Ask the user

Use `AskUserQuestion` to ask which subtask to run. Present one option per catalogue row, plus a "Cancel" option.

## Step 3: Dispatch

Run the chosen sub-command's workflow. The umbrella's only job is selection — do not duplicate logic here.

- **create-issue-template** → follow the workflow in `plugins/github-scaffold/commands/create-issue-template.md`.
- **Cancel** → acknowledge and stop.
