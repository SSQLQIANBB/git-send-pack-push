# git-send-pack-push

Codex skill for pushing Git branches with low-level `git send-pack`.

Use this skill when normal `git push` fails but lower-level Git commands still work, or when a user explicitly asks Codex to push with `send-pack`.

## What It Provides

- `SKILL.md` - Codex instructions for safe `send-pack` pushes.
- `agents/openai.yaml` - Codex UI metadata.
- `scripts/send-pack-push.ps1` - PowerShell helper that refuses dirty worktrees and non-fast-forward pushes.

## Requirements

- Git must be installed and available in `PATH`.
- The target remote must already exist.
- Your Git credentials must already work for the remote URL, for example SSH access to GitHub.
- The repository should have a clean worktree before pushing.

## Install From npm

Codex discovers skills from the `skills` directory under `CODEX_HOME`. If `CODEX_HOME` is not set, use `~/.codex/skills`.

### Windows PowerShell

```powershell
$SkillRoot = if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME "skills" } else { Join-Path $HOME ".codex\skills" }
$TempDir = Join-Path $env:TEMP ("git-send-pack-push-" + [guid]::NewGuid())

New-Item -ItemType Directory -Force $SkillRoot, $TempDir | Out-Null
npm pack git-send-pack-push@latest --pack-destination $TempDir
tar -xzf (Get-ChildItem $TempDir -Filter "git-send-pack-push-*.tgz" | Select-Object -First 1).FullName -C $TempDir

$Target = Join-Path $SkillRoot "git-send-pack-push"
if (Test-Path $Target) { Remove-Item -Recurse -Force $Target }
Copy-Item -Recurse (Join-Path $TempDir "package") $Target
```

### macOS or Linux

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
TEMP_DIR="$(mktemp -d)"

mkdir -p "$SKILL_ROOT"
npm pack git-send-pack-push@latest --pack-destination "$TEMP_DIR"
tar -xzf "$TEMP_DIR"/git-send-pack-push-*.tgz -C "$TEMP_DIR"

rm -rf "$SKILL_ROOT/git-send-pack-push"
cp -R "$TEMP_DIR/package" "$SKILL_ROOT/git-send-pack-push"
```

Restart Codex after installing so the new skill metadata is loaded.

## Install From GitHub

Use this if you want the source repository instead of the npm package.

### HTTPS

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$SKILL_ROOT"
git clone https://github.com/SSQLQIANBB/git-send-pack-push.git "$SKILL_ROOT/git-send-pack-push"
```

### SSH

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$SKILL_ROOT"
git clone git@github.com:SSQLQIANBB/git-send-pack-push.git "$SKILL_ROOT/git-send-pack-push"
```

On Windows PowerShell, set the skill root first:

```powershell
$SkillRoot = if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME "skills" } else { Join-Path $HOME ".codex\skills" }
New-Item -ItemType Directory -Force $SkillRoot | Out-Null
git clone git@github.com:SSQLQIANBB/git-send-pack-push.git (Join-Path $SkillRoot "git-send-pack-push")
```

## Use In Codex

After installation and restart, ask Codex to use the skill by name:

```text
Use $git-send-pack-push to push the current branch to origin.
```

Chinese examples:

```text
使用 $git-send-pack-push 通过 send-pack 推送当前分支到 origin。
```

```text
普通 git push 失败了，请用 $git-send-pack-push 走底层 send-pack 推送。
```

The skill will inspect the repository, resolve the remote push URL, check fast-forward safety, run `git send-pack`, then verify the remote branch.

## Use The Helper Script Directly

Dry run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\send-pack-push.ps1 -Repo D:\path\to\repo -Remote origin -DryRun
```

Push the current branch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\send-pack-push.ps1 -Repo D:\path\to\repo -Remote origin
```

Push a specific branch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\send-pack-push.ps1 -Repo D:\path\to\repo -Remote origin -Branch master
```

## Safety Behavior

The helper script stops before pushing when:

- The worktree has uncommitted changes.
- The remote branch exists and the push would not be fast-forward.
- The remote URL cannot be resolved.

It does not force push. If you need a force update, review the risk manually and run Git yourself.

## Troubleshooting

- `Repository not found`: Create the remote repository first, then check that your SSH key or token has access.
- `Permission denied (publickey)`: Fix SSH authentication for the remote host.
- `Worktree is dirty`: Commit, stash, or discard local changes before pushing.
- `Remote branch is not an ancestor`: Fetch and rebase or merge before retrying.
