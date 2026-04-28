#Requires -Version 7.0
<#
.SYNOPSIS
    Daily Writings/ auto-commit — captures the day's changes to the corpus.

.DESCRIPTION
    Runs git add -A + commit if any changes are pending in Writings/.
    Credential pre-scan fails-closed before commit. Respects .gitignore.
    Safe to run multiple times per day; no-op if nothing changed.

.PARAMETER DryRun
    Preview what would be committed without executing git add / git commit.

.EXAMPLE
    pwsh -File SOK-WritingsCommit.ps1 -DryRun

.EXAMPLE
    pwsh -File SOK-WritingsCommit.ps1

.NOTES
    Registered as SOK-Daily-WritingsCommit scheduled task (22:00 daily).
    Author: Shelby Clay Caddell with Claude Opus 4.7
    Created: 2026-04-22
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$WritingsRoot = "C:\Users\shelc\Documents\Journal\Projects\Writings"
$LogRoot = "C:\Users\shelc\Documents\Journal\Projects\SOK\Logs"
$null = New-Item $LogRoot -ItemType Directory -Force -ErrorAction SilentlyContinue

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $LogRoot ("SOK-WritingsCommit_{0}.log" -f $timestamp)

function Write-Log {
    param([string]$Message)
    $line = "{0} | {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logPath -Value $line
    Write-Output $line
}

Write-Log "=== SOK-WritingsCommit start (DryRun=$DryRun) ==="

if (-not (Test-Path $WritingsRoot)) {
    Write-Log "ABORT: Writings root not found: $WritingsRoot"
    exit 1
}

Set-Location $WritingsRoot

# Verify .git exists
if (-not (Test-Path (Join-Path $WritingsRoot ".git"))) {
    Write-Log "ABORT: Writings/ is not a git repo"
    exit 1
}

# Check for pending changes
$status = git status --porcelain 2>&1
if (-not $status) {
    Write-Log "No pending changes. Clean exit."
    exit 0
}

$changeCount = ($status | Measure-Object).Count
Write-Log "Pending changes: $changeCount files"

# Credential pre-scan (fail-closed before commit)
Write-Log "Running credential pre-scan..."
$patterns = @(
    'sk-[a-zA-Z0-9]{20,}',
    'ghp_[a-zA-Z0-9]{36}',
    'AKIA[0-9A-Z]{16}',
    'BEGIN RSA PRIVATE',
    'BEGIN OPENSSH PRIVATE',
    'ya29\.[a-zA-Z0-9_-]{30,}'
)
$hits = 0
$changedFiles = git diff --cached --name-only 2>&1; $untracked = git ls-files --others --exclude-standard 2>&1
$allChanged = @($changedFiles) + @($untracked) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
foreach ($f in $allChanged) {
    foreach ($p in $patterns) {
        $m = Get-Content $f -ErrorAction SilentlyContinue | Select-String -Pattern $p -CaseSensitive:$false
        if ($m) {
            Write-Log "CREDENTIAL HIT: $f (pattern=$p line=$($m[0].LineNumber))"
            $hits++
        }
    }
}
if ($hits -gt 0) {
    Write-Log "ABORT: $hits credential hits found. Commit blocked."
    exit 2
}
Write-Log "Credential scan clean."

if ($DryRun) {
    Write-Log "DRY RUN — would stage and commit $changeCount files"
    $status | Select-Object -First 20 | ForEach-Object { Write-Log "  $_" }
    if ($changeCount -gt 20) { Write-Log "  ... and $($changeCount - 20) more" }
    exit 0
}

# Stage all (respecting .gitignore)
git add -A 2>&1 | Out-Null
$stagedCount = (git status --porcelain 2>&1 | Measure-Object).Count
Write-Log "Staged $stagedCount files"

# Build commit message
$dateStr = Get-Date -Format "yyyy-MM-dd"
$msgBody = @"
auto-commit: $dateStr daily Writings/ snapshot

$stagedCount file changes captured during automated daily run.
Changes detected by SOK-WritingsCommit.ps1 at $(Get-Date -Format 'HH:mm:ss').

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
"@

# Write message to temp file to avoid shell quoting issues
$msgFile = [System.IO.Path]::GetTempFileName()
Set-Content -Path $msgFile -Value $msgBody -Encoding UTF8

try {
    git commit -F $msgFile 2>&1 | ForEach-Object { Write-Log "git: $_" }
    $commitHash = (git rev-parse --short HEAD 2>&1).Trim()
    Write-Log "Commit created: $commitHash"
} finally {
    Remove-Item $msgFile -ErrorAction SilentlyContinue
}

Write-Log "=== SOK-WritingsCommit complete ==="
exit 0
