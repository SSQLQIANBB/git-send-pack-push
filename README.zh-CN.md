# git-send-pack-push

[English README](./README.md)

这是一个用于通过底层 `git send-pack` 推送 Git 分支的 Codex skill。

当普通 `git push` 失败，但 `git status`、`git fetch`、`git ls-remote` 等底层 Git 命令仍可用时，可以使用这个 skill。用户明确要求“使用 send-pack 推送”“走底层 Git 协议推送”时，也适合使用它。

## 功能亮点

- 使用 `git send-pack`，不是 `git push`。
- 推送前解析真实的 remote push URL。
- helper 脚本会拒绝脏工作区。
- helper 脚本会拒绝非快进推送。
- 推送成功后会校验远端分支引用。
- 适用于普通 `git push` 不稳定，但其他 Git 命令可用的场景。

## Installation & Setup

你可以从 npm 或 GitHub 安装，然后把 skill 文件夹放到 Codex 的 skills 目录下。安装完成后重启 Codex，让新的 skill 元数据生效。

### 1. 选择安装来源

如果只是使用 skill，推荐从 npm 安装。

```bash
npm view git-send-pack-push version --registry https://registry.npmjs.org
```

如果想查看、修改或贡献源码，推荐从 GitHub 安装。

```bash
git ls-remote https://github.com/SSQLQIANBB/git-send-pack-push.git HEAD
```

### 2. 从 npm 安装

Codex 会从以下目录发现 skills：

- 设置了 `CODEX_HOME` 时：`$CODEX_HOME/skills`
- 未设置 `CODEX_HOME` 时：`~/.codex/skills`

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

#### macOS 或 Linux

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
TEMP_DIR="$(mktemp -d)"

mkdir -p "$SKILL_ROOT"
npm pack git-send-pack-push@latest --pack-destination "$TEMP_DIR"
tar -xzf "$TEMP_DIR"/git-send-pack-push-*.tgz -C "$TEMP_DIR"

rm -rf "$SKILL_ROOT/git-send-pack-push"
cp -R "$TEMP_DIR/package" "$SKILL_ROOT/git-send-pack-push"
```

### 3. 从 GitHub 安装

使用 HTTPS：

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$SKILL_ROOT"
git clone https://github.com/SSQLQIANBB/git-send-pack-push.git "$SKILL_ROOT/git-send-pack-push"
```

使用 SSH：

```bash
SKILL_ROOT="${CODEX_HOME:-$HOME/.codex}/skills"
mkdir -p "$SKILL_ROOT"
git clone git@github.com:SSQLQIANBB/git-send-pack-push.git "$SKILL_ROOT/git-send-pack-push"
```

Windows PowerShell：

```powershell
$SkillRoot = if ($env:CODEX_HOME) { Join-Path $env:CODEX_HOME "skills" } else { Join-Path $HOME ".codex\skills" }
New-Item -ItemType Directory -Force $SkillRoot | Out-Null
git clone git@github.com:SSQLQIANBB/git-send-pack-push.git (Join-Path $SkillRoot "git-send-pack-push")
```

### 4. 验证安装

确认目录中存在这些文件：

```text
git-send-pack-push/
  SKILL.md
  agents/openai.yaml
  scripts/send-pack-push.ps1
```

如果本机有 Codex skill 校验脚本，可以额外执行：

```bash
python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py ~/.codex/skills/git-send-pack-push
```

验证后重启 Codex。

### 5. 在 Codex 中使用

在对话里明确点名这个 skill：

```text
使用 $git-send-pack-push 通过 send-pack 推送当前分支到 origin。
```

其他示例：

```text
普通 git push 失败了，请用 $git-send-pack-push 走底层 send-pack 推送。
```

```text
使用 $git-send-pack-push 把 master 分支通过底层 Git 协议推送到 origin。
```

这个 skill 会检查仓库状态、解析远端 push URL、检查快进安全性、执行 `git send-pack`、拉取远端分支并校验远端引用。

## 直接使用 helper 脚本

即使不通过 Codex，也可以直接运行内置 PowerShell helper。

预演：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\send-pack-push.ps1 -Repo D:\path\to\repo -Remote origin -DryRun
```

推送当前分支：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\send-pack-push.ps1 -Repo D:\path\to\repo -Remote origin
```

推送指定分支：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\send-pack-push.ps1 -Repo D:\path\to\repo -Remote origin -Branch master
```

## 安全行为

helper 脚本会在以下情况停止推送：

- 工作区存在未提交变更。
- 远端分支已存在，且本次推送不是快进更新。
- 无法解析 remote URL。

它不会执行强制推送。如果确实需要强推，请先人工确认风险，再手动运行 Git 命令。

## 环境要求

- 已安装 Git，且 Git 在 `PATH` 中可用。
- 直接运行 `scripts/send-pack-push.ps1` 时需要 PowerShell。
- 目标远端仓库已经存在。
- 当前 Git 凭据能访问目标 remote URL。
- 使用 helper 脚本推送前，本地工作区应保持干净。

## 常见问题

- `Repository not found`：先创建远端仓库，再确认 SSH key 或 token 有访问权限。
- `Permission denied (publickey)`：修复当前机器到远端 Git 服务的 SSH 认证。
- `Worktree is dirty`：先提交、stash 或丢弃本地变更。
- `Remote branch is not an ancestor`：先 fetch，然后 rebase 或 merge，再重试。
- Codex 中没有出现该 skill：确认目录位于当前 Codex 的 skills 目录下，并重启 Codex。

## 包内容

- `SKILL.md`：Codex 使用该 skill 的核心指令。
- `agents/openai.yaml`：Codex UI 元数据。
- `scripts/send-pack-push.ps1`：安全的底层推送 helper。
- `README.md`：英文文档。
- `README.zh-CN.md`：中文文档。
