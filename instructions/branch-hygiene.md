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
