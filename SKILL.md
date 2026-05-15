---
name: git-send-pack-push
description: Push Git code with low-level git send-pack instead of normal git push. Use when the user explicitly asks to use send-pack, asks to push via the low-level Git protocol, says to submit code with send-pack, or normal git push fails while other Git commands such as status, fetch, or ls-remote still work.
---

# Git Send-Pack Push

## Workflow

1. Inspect the repository:
   - `git -C <repo> status --short --branch`
   - `git -C <repo> rev-parse --abbrev-ref HEAD`
   - `git -C <repo> rev-parse HEAD`
   - `git -C <repo> remote get-url --push <remote>`

2. If the worktree is dirty, do not push blindly.
   - If the user asked to commit current work, inspect the diff, stage only intended files, commit, then push.
   - If there are unrelated or unclear changes, report them and ask before committing.

3. Prefer pushing the current branch to the same branch name on the remote:
   - `refs/heads/<branch>:refs/heads/<branch>`
   - Use the remote URL, not the remote alias, when normal `git push origin <branch>` is failing.

4. Check fast-forward safety before sending:
   - Fetch the remote branch if possible: `git -C <repo> fetch <remote> <branch>`
   - Verify the remote branch is an ancestor of `HEAD` when it exists.
   - Do not force push with send-pack unless the user explicitly asks for force and the risk is acknowledged.

5. Push with send-pack:
   - `git -C <repo> send-pack <remote-url> refs/heads/<branch>:refs/heads/<branch>`

6. Verify and update local tracking refs:
   - `git -C <repo> fetch <remote> <branch>`
   - `git -C <repo> ls-remote <remote> refs/heads/<branch>`
   - `git -C <repo> status --short --branch`

## Helper Script

Use `scripts/send-pack-push.ps1` for the standard path:

```powershell
powershell -ExecutionPolicy Bypass -File <skill-dir>\scripts\send-pack-push.ps1 -Repo <repo> -Remote origin
```

Options:

```powershell
# Push a specific branch
powershell -ExecutionPolicy Bypass -File <skill-dir>\scripts\send-pack-push.ps1 -Repo <repo> -Remote origin -Branch master

# Dry-run the send-pack operation
powershell -ExecutionPolicy Bypass -File <skill-dir>\scripts\send-pack-push.ps1 -Repo <repo> -Remote origin -DryRun
```

The script refuses dirty worktrees and non-fast-forward pushes.

## Reporting

After success, tell the user:

- The branch pushed.
- The commit SHA pushed.
- That `origin/<branch>` was refreshed.

If using the Codex desktop app and the push succeeds, emit the `::git-push{...}` directive in the final response.
