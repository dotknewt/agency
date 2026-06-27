## Branch lifecycle

   Branches accumulate fast and merged ones quietly cause problems  new commits land on top of stale `main`, follow-up work piles onto an already-merged branch and needs its own PR to untangle, and the branch list fills with dead refs. Keep the working set small.
                                                                                                                             
   **Before starting work on a new branch.** Sync `main` with origin first; never branch from a stale local `main`.

   ```bash                                                                                                                   
   git checkout main
   git fetch origin
   git pull --ff-only origin main                                                                                            
   git checkout -b <new-branch-name>
   ```

   When to switch working branches. Start a new branch for every distinct piece of work  every issue, every PR. Do not pile follow-up changes onto a branch whose PR has already merged; the branch's job is done and any new commits on it will diverge from main. If new scope surfaces mid-flight, finish and merge the current branch first, then branch again from a freshly-pulled main.

   After a PR merges. Delete the branch locally and on origin in the same step  don't leave it for "later".
    
    ```bash
    git checkout main
    git fetch --prune origin           # also drops remote-tracking refs for deleted branches
    git pull --ff-only origin main
    git branch -d <merged-branch>      # local
    git push origin --delete <merged-branch>   # remote (skip if GitHub auto-deleted it)
    ```
   If git branch -d refuses (says "not fully merged"), the branch was probably squash-merged; verify on GitHub that the PR is closed/merged, then use git branch -D to force-delete.

 Stale-branch sweep. git branch -a should be short. If you notice merged branches still listed on origin, delete them  they are not someone's in-flight work.

## Right branch for the right task

Before the first commit of any session, run `git branch --show-current` and confirm the branch name reflects the task at hand. If the current branch belongs to a different issue or a PR that has already merged, stop — switch to the correct branch or branch fresh from `main`. Never add commits to a branch whose scope is unrelated to what you are about to change.

```bash
git branch --show-current   # confirm this matches your task
gh pr list --state merged --head $(git branch --show-current)  # if this returns anything, the branch's PR has merged — do not add work here
```

## Check open PRs before branching

Run this before creating a new branch:

```bash
gh pr list --state open --json number,title,headRefName,files
```

Scan the output for two situations:

1. **File overlap** — an open PR already touches files you are about to edit. This is a squash-merge tangle risk: two PRs rewriting the same lines will produce a conflict when the second one merges. Options: wait for the first PR to merge, rebase your work onto its head (stacked PR), or coordinate with the author.
2. **Natural stacking point** — an open PR's `headRefName` is the logical predecessor to your work (e.g., you are adding tests for a feature branch that has not landed yet). In that case branch from `<headRefName>` rather than `main`, and set the new PR's base to `<headRefName>` so it does not include the predecessor's commits.

When there are no overlapping files and no stacking dependency, branch from `main` as usual.

## Branch cleanup recipe

Run this recipe after a PR merges, or as a periodic sweep. It is idempotent — safe to run at any time.

```bash
git checkout main
git fetch --prune origin
git pull --ff-only origin main

# Drop local branches whose upstream tracking ref has been deleted (i.e., GitHub auto-deleted after merge)
git branch -vv | awk '/: gone]/{print $1}' | xargs -r git branch -D

# List branches locally merged into main — review before deleting
git branch --merged main | grep -vE '^\*|^  main$' || true
```

The last command prints candidates for `git branch -d`. Pipe to `git branch -d` once you have confirmed none of them represent in-flight work.

For origin branches merged into `origin/main`:

```bash
git branch -r --merged origin/main | grep -vE 'origin/(main|HEAD)' || true
```

These are candidates for `git push origin --delete <branch>`. Skip any branch that belongs to an open PR (rare, but possible in draft state).

---

For automated cleanup or new-branch prep, invoke the `branch-warden` agent.
