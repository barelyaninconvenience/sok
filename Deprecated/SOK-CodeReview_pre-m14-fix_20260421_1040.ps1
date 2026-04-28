<#
.SYNOPSIS
    SOK-CodeReview.ps1 — Invoke Claude Code review and security-review skills on SOK scripts.

.DESCRIPTION
    Wraps Claude Code's built-in /review and /security-review skills into the SOK lifecycle.
    Runs against all modified .ps1 files (vs main branch) or a specified file list.

    Intended to run:
    - Before git push (pre-push gate)
    - After SOK-TestBatch passes (quality gate)
    - On demand for specific scripts after edits

    Outputs structured review results to SOK/Logs/CodeReview/

.PARAMETER Files
    Specific files to review. Default: all modified .ps1 files vs main branch.

.PARAMETER SecurityOnly
    Only run security-review, skip general review.

.PARAMETER DryRun
    Show what would be reviewed without invoking Claude Code.

.NOTES
    Author: S. Clay Caddell
    Version: 1.0.0
    Date: 16Apr2026
    Domain: Utility — Claude Code skill integration for SOK quality gates
#>
#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string[]]$Files,
    [switch]$SecurityOnly
)

$ErrorActionPreference = 'Continue'
$scriptDir = if (Test-Path (Join-Path $PSScriptRoot 'SOK-Inventory.ps1')) { $PSScriptRoot }
             else { 'C:\Users\shelc\Documents\Journal\Projects\scripts' }

$modulePath = Join-Path $scriptDir 'common\SOK-Common.psm1'
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

$logDir = Join-Path (Split-Path $scriptDir) 'SOK\Logs\CodeReview'
$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $logDir $runId
if (-not (Test-Path $runDir)) { New-Item -ItemType Directory -Path $runDir -Force | Out-Null }

# Determine files to review
if (-not $Files) {
    # Default: all modified .ps1 files vs main branch (or all .ps1 if no git)
    Push-Location $scriptDir
    try {
        $gitFiles = git diff --name-only main -- '*.ps1' 2>$null
        if ($gitFiles) {
            $Files = $gitFiles | ForEach-Object { Join-Path $scriptDir $_ }
        } else {
            # No git diff available — review all SOK scripts
            $Files = Get-ChildItem -Path $scriptDir -Filter 'SOK-*.ps1' | Select-Object -ExpandProperty FullName
        }
    } finally { Pop-Location }
}

Write-Host "`n=== SOK Code Review === ($($Files.Count) files)" -ForegroundColor Cyan
Write-Host "Run: $runId | SecurityOnly: $SecurityOnly | DryRun: $DryRun" -ForegroundColor Gray

if ($DryRun) {
    Write-Host "`n[DRY RUN] Would review:" -ForegroundColor Yellow
    $Files | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host "`nSkills: $(if ($SecurityOnly) { '/security-review' } else { '/review + /security-review' })" -ForegroundColor Yellow
    exit
}

$results = @()
foreach ($file in $Files) {
    $name = Split-Path $file -Leaf
    Write-Host "`n  Reviewing: $name" -ForegroundColor White -NoNewline

    # General review (unless SecurityOnly)
    if (-not $SecurityOnly) {
        $reviewLog = Join-Path $runDir "${name}_review.md"
        Write-Host " [review]" -ForegroundColor Blue -NoNewline
        # Note: claude CLI invocation — adjust path as needed
        $reviewResult = & claude -p "Review this PowerShell script for code quality, bugs, and improvements. Be concise. File: $file" --output-file $reviewLog 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " OK" -ForegroundColor Green -NoNewline
        } else {
            Write-Host " FAIL" -ForegroundColor Red -NoNewline
        }
    }

    # Security review
    $secLog = Join-Path $runDir "${name}_security.md"
    Write-Host " [security]" -ForegroundColor Magenta -NoNewline
    $secResult = & claude -p "Security review this PowerShell script. Check for: command injection, credential exposure, path traversal, privilege escalation, unsafe Remove-Item, unvalidated input. Be concise. File: $file" --output-file $secLog 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
    }

    $results += [PSCustomObject]@{
        File     = $name
        Review   = if (-not $SecurityOnly) { $LASTEXITCODE -eq 0 } else { 'SKIPPED' }
        Security = $LASTEXITCODE -eq 0
    }
}

# Summary
$summaryPath = Join-Path $runDir 'summary.md'
$summary = @"
# SOK Code Review — $runId

| File | Review | Security |
|------|--------|----------|
$($results | ForEach-Object { "| $($_.File) | $($_.Review) | $($_.Security) |" } | Out-String)

**Total files:** $($Files.Count)
**Run directory:** $runDir
"@
$summary | Set-Content $summaryPath -Encoding UTF8
Write-Host "`n=== Summary: $summaryPath ===" -ForegroundColor Cyan
