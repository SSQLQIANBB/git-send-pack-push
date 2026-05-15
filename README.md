# git-send-pack-push

[中文文档](./README.zh-CN.md)

Codex skill for pushing Git branches with low-level `git send-pack`.

Use this skill when normal `git push` fails but lower-level Git commands still work, or when a user explicitly asks Codex to push with `send-pack`.

## Highlights

- Pushes with `git send-pack`, not `git push`.
- Resolves the real remote push URL before sending.
- Refuses dirty worktrees in the helper script.
- Refuses non-fast-forward updates in the helper script.
- Verifies the remote branch after a successful push.
- Works well when `git status`, `git fetch`, and `git ls-remote` work but regular `git push` is unreliable.

## Installation & Setup

Install from npm or GitHub, then place the skill folder under your Codex skills directory. Restart Codex after installation so the new skill metadata is loaded.

### 1. Choose your install source

Recommended: install from npm if you only want to use the skill.

```bash
npm view git-send-pack-push version --registry https://registry.npmjs.org
```

Use GitHub if you want to inspect, edit, or contribute to the source.

```bash
git ls-remote https://github.com/SSQLQIANBB/git-send-pack-push.git HEAD
```

### 2. Install from npm

Codex discovers skills from:

- `$CODEX_HOME/skills` when `CODEX_HOME` is set.
- `~/.codex/skills` when `CODEX_HOME` is not set.

#### Windows PowerShell

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

#### macOS or Linux

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
TEMP_DIR="$(mktemp -d)"

mkdir -p "$SKILL_ROOT"
npm pack git-send-pack-push@latest --pack-destination "$TEMP_DIR"
tar -xzf "$TEMP_DIR"/git-send-pack-push-*.tgz -C "$TEMP_DIR"

rm -rf "$SKILL_ROOT/git-send-pack-push"
cp -R "$TEMP_DIR/package" "$SKILL_ROOT/git-send-pack-push"
```

### 3. Install from GitHub

Use HTTPS:

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$SKILL_ROOT"
git clone https://github.com/SSQLQIANBB/git-send-pack-push.git "$SKILL_ROOT/git-send-pack-push"
```

Use SSH:

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$SKILL_ROOT"
git clone git@github.com:SSQLQIANBB/git-send-pack-push.git "$SKILL_ROOT/git-send-pack-push"
```

Windows PowerShell:

```powershell
$SkillRoot = if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME "skills" } else { Join-Path $HOME ".codex\skills" }
New-Item -ItemType Directory -Force $SkillRoot | Out-Null
git clone git@github.com:SSQLQIANBB/git-send-pack-push.git (Join-Path $SkillRoot "git-send-pack-push")
```

### 4. Verify the installation

Check that these files exist:

```text
git-send-pack-push/
  SKILL.md
  agents/openai.yaml
  scripts/send-pack-push.ps1
```

Optional validation if you have the Codex skill validator available:

```bash
python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/git-send-pack-push
```

Restart Codex after verification.

### 5. Use the skill in Codex

Ask Codex to use the skill by name:

```text
Use $git-send-pack-push to push the current branch to origin.
```

Other examples:

```text
Normal git push is failing. Use $git-send-pack-push and push this branch with send-pack.
```

```text
Use $git-send-pack-push to push master to origin through the low-level Git protocol.
```

The skill will inspect the repository, resolve the remote push URL, check fast-forward safety, run `git send-pack`, fetch the remote branch, and verify the remote ref.

## Direct Helper Usage

The bundled PowerShell helper can be used without Codex.

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

## Requirements

- Git installed and available in `PATH`.
- PowerShell when using `scripts/send-pack-push.ps1`.
- Existing remote repository.
- Working Git credentials for the target remote URL.
- Clean local worktree before helper-script pushes.

## Troubleshooting

- `Repository not found`: Create the remote repository first, then check that your SSH key or token has access.
- `Permission denied (publickey)`: Fix SSH authentication for the remote host.
- `Worktree is dirty`: Commit, stash, or discard local changes before pushing.
- `Remote branch is not an ancestor`: Fetch and rebase or merge before retrying.
- Skill does not appear in Codex: Confirm the folder is under the active Codex skills directory and restart Codex.

## Package Contents

- `SKILL.md` - Codex instructions for safe `send-pack` pushes.
- `agents/openai.yaml` - Codex UI metadata.
- `scripts/send-pack-push.ps1` - Safe helper for low-level pushes.
- `README.md` - English documentation.
- `README.zh-CN.md` - Chinese documentation.
