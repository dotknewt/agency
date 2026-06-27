---
description: Scaffold one or more GitHub issue forms (YAML schema) in .github/ISSUE_TEMPLATE/
allowed-tools: Read, Write, Bash, Glob, AskUserQuestion
---

Walk the user through creating one or more GitHub issue forms using the YAML issue-forms schema (`name`, `description`, `title`, `labels`, `body`). Collect all templates before writing anything; write them all in a single approval step at the end. Model output on `.github/ISSUE_TEMPLATE/new.yml` in the current repo if it exists, otherwise use the canonical structure described here.

## Step 1: Locate `.github/ISSUE_TEMPLATE/`

```bash
ls .github/ISSUE_TEMPLATE/ 2>/dev/null || echo "(directory absent)"
```

Note whether the directory exists; if not, plan to create it during the write step.

## Step 2: Check for `config.yml`

If `.github/ISSUE_TEMPLATE/config.yml` is missing, offer to scaffold one:

```bash
git remote get-url origin 2>/dev/null || echo "(no remote)"
```

Derive the README URL from the remote (e.g. `https://github.com/owner/repo/blob/main/README.md`). Propose:

```yaml
blank_issues_enabled: false
contact_links:
  - name: Repository README
    url: <derived-url>
    about: Overview of this repository.
```

Show the proposed file in a fenced block and ask the user to approve or skip. Do not write yet.

## Step 3: Select templates (multi-select)

Use `AskUserQuestion` with `multiSelect: true` to present the template catalogue. Show up to 5 items per question; if you have more than 5 candidates, split into sequential questions (page 1 of N, page 2 of N, …) before proceeding.

Standard catalogue (use these 4 options; "Other" is added automatically as the 5th slot):

| Option label | Description |
|---|---|
| Bug report | Reproducible defect with steps to reproduce, expected vs actual behaviour |
| Feature request | New capability or enhancement proposal |
| Question / Support | Usage question or request for help |
| Documentation | Doc errors, missing content, or typos |

If the user selects "Other", ask them to name the custom template type before continuing.

Record every selected type; proceed to Step 4 for each in turn.

## Step 4: Gather fields for each selected template

For each template type selected in Step 3, work through it in sequence:

### 4a — Pre-populate defaults

Propose sensible default metadata and body fields based on the template type:

- **Bug report**: title prefix `"[bug] "`, label `bug`, fields: Description (textarea, required), Steps to reproduce (textarea, required), Expected behaviour (textarea), Actual behaviour (textarea), Environment (input).
- **Feature request**: title prefix `"[feat] "`, label `enhancement`, fields: Problem statement (textarea, required), Proposed solution (textarea, required), Alternatives considered (textarea).
- **Question / Support**: title prefix `"[question] "`, label `question`, fields: What are you trying to do? (textarea, required), What have you tried? (textarea).
- **Documentation**: title prefix `"[docs] "`, label `documentation`, fields: Page or section (input, required), Issue description (textarea, required), Suggested correction (textarea).
- **Custom type**: no defaults; ask the user for all metadata and fields.

Show the proposed metadata and field list in plain text and ask the user to confirm, remove, or add fields before generating YAML.

### 4b — Field schema

For each field that will appear in `body`, ensure:

| Key | Values |
|-----|--------|
| `type` | `dropdown`, `input`, `textarea`, or `markdown` |
| `id` | lowercase, hyphens/underscores only (omit for `markdown`) |
| `label` | display label |
| `description` | optional helper text |
| `placeholder` | optional (input/textarea) |
| `options` | required for `dropdown` — comma-separated list |
| `required` | `true` or `false` |

Suggest a `markdown` field for section separators or headers when appropriate.

After fields are confirmed for this template, move on to the next selected type (back to 4a) until all are done, then proceed to Step 5.

## Step 5: Render and validate all templates

For each template, print its full YAML in a labeled fenced block (`## <filename>`). Before showing each one, verify:

- Top-level keys present: `name`, `description`, `body`
- Each `body` entry has `type`, `id` (or omit `id` only for `markdown`), `attributes.label`
- `dropdown` entries have at least one option
- All `id` values match `^[a-z][a-z0-9_-]*$` and are unique within the template

Surface any violations as a list before the relevant YAML preview.

Example shape:

```yaml
name: "Bug report"
description: Report a reproducible bug.
title: "[bug] "
labels:
  - "bug"
body:
  - type: textarea
    id: description
    attributes:
      label: Description
      description: What happened?
    validations:
      required: true

  - type: dropdown
    id: severity
    attributes:
      label: Severity
      options:
        - low
        - medium
        - high
    validations:
      required: true
```

## Step 6: Approval gate, then write all

Show a summary list of all files that will be written (template files + `config.yml` if approved in Step 2). Ask the user to confirm once before writing anything.

On approval, write all files in one pass:

1. Create `.github/ISSUE_TEMPLATE/` if absent:
   ```bash
   mkdir -p .github/ISSUE_TEMPLATE
   ```
2. Write each template file.
3. Write `config.yml` if approved in Step 2.

Confirm each path written.
