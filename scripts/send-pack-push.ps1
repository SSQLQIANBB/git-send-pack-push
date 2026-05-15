param(
  [string]$Repo = (Get-Location).Path,
  [string]$Remote = "origin",
  [string]$Branch = "",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Run-Git {
  param([string[]]$GitArgs)
  & git -C $Repo @GitArgs
  if ($LASTEXITCODE -ne 0) {
    throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
  }
}

if (-not (Test-Path -LiteralPath $Repo)) {
  throw "Repository path does not exist: $Repo"
}

$inside = (& git -C $Repo rev-parse --is-inside-work-tree 2>$null)
if ($LASTEXITCODE -ne 0 -or $inside -ne "true") {
  throw "Not a Git worktree: $Repo"
}

if (-not $Branch) {
  $Branch = (& git -C $Repo rev-parse --abbrev-ref HEAD).Trim()
  if ($LASTEXITCODE -ne 0 -or -not $Branch -or $Branch -eq "HEAD") {
    throw "Cannot determine current branch"
  }
}

$status = (& git -C $Repo status --porcelain)
if ($status) {
  throw "Worktree is dirty. Commit or clean changes before send-pack push.`n$status"
}

$remoteUrl = (& git -C $Repo remote get-url --push $Remote).Trim()
if ($LASTEXITCODE -ne 0 -or -not $remoteUrl) {
  throw "Cannot resolve push URL for remote '$Remote'"
}

$head = (& git -C $Repo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $head) {
  throw "Cannot resolve HEAD"
}

& git -C $Repo fetch $Remote $Branch
if ($LASTEXITCODE -ne 0) {
  throw "Failed to fetch $Remote $Branch"
}

$remoteRef = "refs/remotes/$Remote/$Branch"
$remoteSha = (& git -C $Repo rev-parse --verify $remoteRef 2>$null)
if ($LASTEXITCODE -eq 0 -and $remoteSha) {
  & git -C $Repo merge-base --is-ancestor $remoteSha.Trim() HEAD
  if ($LASTEXITCODE -ne 0) {
    throw "Remote $Remote/$Branch is not an ancestor of HEAD. Refusing non-fast-forward send-pack."
  }
}

$refspec = "refs/heads/$Branch`:refs/heads/$Branch"
$sendPackArgs = @()
if ($DryRun) {
  $sendPackArgs += "--dry-run"
}
$sendPackArgs += @($remoteUrl, $refspec)
Run-Git -GitArgs (@("send-pack") + $sendPackArgs)

if (-not $DryRun) {
  Run-Git -GitArgs @("fetch", $Remote, $Branch)
}

$remoteHead = (& git -C $Repo ls-remote $Remote "refs/heads/$Branch").Trim()
Write-Output "branch=$Branch"
Write-Output "head=$head"
Write-Output "remote=$remoteUrl"
Write-Output "remote_ref=$remoteHead"
