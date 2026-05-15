# git-send-pack-push

Codex skill for pushing Git branches with low-level `git send-pack`.

Use this skill when normal `git push` fails but lower-level Git commands still work, or when a user explicitly asks to push with `send-pack`.

## Contents

- `SKILL.md` - Codex skill instructions.
- `agents/openai.yaml` - Codex UI metadata.
- `scripts/send-pack-push.ps1` - PowerShell helper for safe `send-pack` pushes.

## Helper Usage

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\send-pack-push.ps1 -Repo D:\path\to\repo -Remote origin -DryRun
```

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\send-pack-push.ps1 -Repo D:\path\to\repo -Remote origin
```

The helper refuses dirty worktrees and non-fast-forward pushes.
