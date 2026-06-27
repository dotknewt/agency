---
description: Scaffold one or more GitHub issue forms (YAML schema) in .github/ISSUE_TEMPLATE/
allowed-tools: Read, Write, Bash, Glob
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

## Step 3: Gather all templates (loop)

Repeat this loop until the user says they have no more templates to add.

### 3a — Gather template metadata

Ask the user (single conversational turn) for:

- **`name`** — shown on the issue chooser (e.g. `"Bug report"`)
- **`description`** — one-line description under the template name
- **`title`** prefix — optional default title prefix (e.g. `"[bug] "`)
- **`labels`** — optional comma-separated list (e.g. `"bug, needs-triage"`)
- **filename** — default: kebab-case of `name` + `.yml` (e.g. `bug-report.yml`)

### 3b — Gather fields for this template

Ask the user to describe the fields they want. For each field, collect:

| Key | Values |
|-----|--------|
| `type` | `dropdown`, `input`, or `textarea` |
| `id` | lowercase, hyphens/underscores only |
| `label` | display label |
| `description` | optional helper text |
| `placeholder` | optional (input/textarea) |
| `options` | required for `dropdown` — comma-separated list |
| `required` | `true` or `false` |

Suggest a `markdown` type for a section separator or header if the user wants one.

### 3c — Ask whether to add another template

After gathering fields for this template, ask: **"Add another template, or done?"**

- If another: return to 3a for the next template.
- If done: proceed to Step 4.

Keep an internal list of all templates collected so far (name, filename, YAML content).

## Step 4: Render and validate all templates

For each template collected in Step 3, print its full YAML in a labeled fenced block (`## <filename>`). Before showing each one, verify:

- Top-level keys present: `name`, `description`, `body`
- Each `body` entry has `type`, `id` (or omit `id` only for `markdown`), `attributes.label`
- `dropdown` entries have at least one option
- All `id` values match `^[a-z][a-z0-9_-]*$` and are unique within the template

Surface any violations as a list before the relevant YAML preview.

Example shape (matches this repo's `.github/ISSUE_TEMPLATE/new.yml`):

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

## Step 5: Approval gate, then write all

Show a summary list of all files that will be written (template files + `config.yml` if approved). Ask the user to confirm once before writing anything.

On approval, write all files in one pass:

1. Create `.github/ISSUE_TEMPLATE/` if absent:
   ```bash
   mkdir -p .github/ISSUE_TEMPLATE
   ```
2. Write each template file.
3. Write `config.yml` if approved in Step 2.

Confirm each path written.
