#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-Backup.ps1 — Additive-by-default backup engine with verification.
.DESCRIPTION
    Robocopy with pre-flight validation, post-copy verification, structured logging.
    DEFAULT: /E — additive only. NEVER deletes from destination. Safe for nightly unattended runs.
    OPTIONAL: /MIR via -Incremental — two-way sync. DELETES from destination when source files
    are absent. Never pass -Incremental in scheduled/unattended contexts.
.PARAMETER Sources
    Paths to back up. Default: Documents\Journal\Projects.
.PARAMETER Destination
    Target path. Default: E:\Backup_Archive.
.PARAMETER Incremental
    DESTRUCTIVE: switches to /MIR (two-way sync). Deletes from destination any files no longer
    present in source. NOT the default. NOT used in SOK-Scheduler. Manual invocation only.
.PARAMETER Threads
    Robocopy /MT. Default: 13.
.PARAMETER DryRun
    Preview with /L (no files copied or deleted).
.NOTES
    Author: S. Clay Caddell
    Version: 1.1.0
    Date: 02Apr2026
    Domain: FUTURE — additive-only robocopy mirror for DR; /MIR never default; runs last nightly
    Changelog: 1.1.0 — strengthen -Incremental/MIR documentation and add runtime warn;
               /MIR is NEVER the default and NEVER used in scheduled runs.
#>
[CmdletBinding()]
param(
    [string[]]$Sources = @("$env:USERPROFILE\Documents\Journal\Projects"),
    [string]$Destination = 'E:\Backup_Archive',
    [switch]$Incremental,
    [int]$Threads = 13,
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

$logPath = Initialize-SOKLog -ScriptName 'SOK-Backup'
Show-SOKBanner -ScriptName 'SOK-Backup' -Subheader "$(if ($Incremental) { '/MIR' } else { '/E' }) | MT:$Threads$(if ($DryRun) { ' | DRY RUN' })"

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-Backup'
}

$startTime = Get-Date
$results = [ordered]@{ SourceCount = 0; TotalSizeKB = 0; CopiedFiles = 0; CopiedKB = 0; FailedFiles = 0; Verified = $false; DurationSec = 0; DryRun = $DryRun.IsPresent }

# /MIR runtime guard — explicit red-flag before any destructive sync
if ($Incremental) {
    Write-SOKLog '/MIR mode (/Incremental) — WILL DELETE from destination any files absent in source.' -Level Warn
    Write-SOKLog 'This is NOT the default. NOT for scheduled/unattended runs. Confirm intent.' -Level Warn
}

# ═══════════════════════════════════════════════════════════════
# PRE-FLIGHT
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PRE-FLIGHT' -Level Section

$destDrive = Split-Path $Destination -Qualifier
$destDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$destDrive'" -ErrorAction SilentlyContinue
if (-not $destDisk) {
    if ($DryRun) {
        Write-SOKLog "[DRY] Destination $destDrive not present (drive offline) — preview exits cleanly" -Level Warn
        exit 0
    }
    Write-SOKLog "Destination $destDrive not found!" -Level Error; exit 1
}
$destFreeKB = [math]::Round($destDisk.FreeSpace / 1KB, 0)
Write-SOKLog "$destDrive — $destFreeKB KB free ($([math]::Round((($destDisk.Size - $destDisk.FreeSpace) / $destDisk.Size) * 100, 1))% used)" -Level Ignore

$validSources = @()
$totalSourceKB = 0
foreach ($src in $Sources) {
    if (-not (Test-Path $src)) { Write-SOKLog "NOT FOUND: $src" -Level Error; continue }
    $srcSize = 0; $fileCount = 0
    try {
        $opts = [System.IO.EnumerationOptions]::new()
        $opts.RecurseSubdirectories = $true; $opts.IgnoreInaccessible = $true
        $opts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint
        foreach ($fi in [System.IO.Directory]::EnumerateFiles($src, '*', $opts)) {
            try { $srcSize += ([System.IO.FileInfo]::new($fi)).Length; $fileCount++ } catch {}
        }
    } catch { $srcSize = (Get-ChildItem $src -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum; $fileCount = (Get-ChildItem $src -Recurse -File -Force -ErrorAction SilentlyContinue).Count }
    $srcSizeKB = [math]::Round($srcSize / 1KB, 0)
    $totalSourceKB += $srcSizeKB
    Write-SOKLog "$src — $srcSizeKB KB ($fileCount files)" -Level Success
    $validSources += @{ Path = $src; SizeKB = $srcSizeKB; Files = $fileCount }
}

if ($validSources.Count -eq 0) { Write-SOKLog 'No valid sources. Aborting.' -Level Error; exit 1 }
$results.SourceCount = $validSources.Count; $results.TotalSizeKB = $totalSourceKB

# Space validation — /E mode and /MIR mode have different requirements.
# /E (additive): destination must have at least as much free space as source total.
# /MIR (destructive sync): /MIR first COPIES all source files, then purges destination
#   extras. At peak, both old and new data coexist briefly. Require 110% of source
#   size as free headroom to ensure the copy phase completes before the purge phase.
$mirRequiredKB = [math]::Round($totalSourceKB * 1.10, 0)

if ($Incremental) {
    # /MIR pre-flight space check
    Write-SOKLog "Space check (/MIR): $totalSourceKB KB source, 110% threshold = $mirRequiredKB KB required, $destFreeKB KB free" -Level Ignore
    if ($destFreeKB -lt $mirRequiredKB) {
        $shortfallKB = $mirRequiredKB - $destFreeKB
        Write-SOKLog "INSUFFICIENT SPACE FOR /MIR: need $mirRequiredKB KB (110% of $totalSourceKB KB), have $destFreeKB KB free — shortfall $shortfallKB KB" -Level Error
        if ($DryRun) {
            Write-SOKLog 'DRY RUN — would abort here due to insufficient space for /MIR.' -Level Warn
        } else {
            exit 1
        }
    } else {
        Write-SOKLog "Space: $totalSourceKB KB source, $mirRequiredKB KB required (110%), $destFreeKB KB free — OK" -Level Success
    }
} else {
    # /E additive — destination just needs to fit the source delta
    if ($totalSourceKB -gt $destFreeKB) {
        Write-SOKLog "INSUFFICIENT SPACE: $totalSourceKB KB > $destFreeKB KB free" -Level Error; exit 1
    }
    Write-SOKLog "Space: $totalSourceKB KB needed, $destFreeKB KB available" -Level Success
}

# ═══════════════════════════════════════════════════════════════
# ROBOCOPY
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'BACKUP' -Level Section

foreach ($src in $validSources) {
    $srcName = Split-Path $src.Path -Leaf
    $destPath = Join-Path $Destination $srcName
    Write-SOKLog "$($src.Path) → $destPath ($($src.SizeKB) KB)" -Level Ignore

    $roboLog = $logPath -replace '\.log$', "_robo_${srcName}.log"
    $roboArgs = @(
        $src.Path, $destPath
        $(if ($Incremental) { '/MIR' } else { '/E' })
        '/R:3', '/W:5', "/MT:$Threads", '/XJ'
        '/COPY:DAT', '/DCOPY:T', '/NP', '/ETA', '/BYTES'
        "/LOG+:$roboLog"
    )
    if ($DryRun) { $roboArgs += '/L' }

    $roboStart = Get-Date
    & robocopy @roboArgs 2>&1 | ForEach-Object {
        $line = "$_".Trim()
        if ($line -match '^\s*(Dirs|Files|Bytes|Times|Speed|Ended)\s*:') {
            Write-SOKLog "  [robo] $line" -Level Debug
        }
    }
    $roboExit = $LASTEXITCODE
    $roboDur = [math]::Round(((Get-Date) - $roboStart).TotalSeconds, 1)
    $level = if ($roboExit -lt 4) { 'Success' } elseif ($roboExit -lt 8) { 'Warn' } else { 'Error' }
    Write-SOKLog "  Exit: $roboExit (${roboDur}s) — log: $roboLog" -Level $level
    if ($roboExit -ge 8) { $results.FailedFiles++ }
}

# ═══════════════════════════════════════════════════════════════
# VERIFY
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'VERIFICATION' -Level Section
if (-not $DryRun) {
    foreach ($src in $validSources) {
        $destPath = Join-Path $Destination (Split-Path $src.Path -Leaf)
        if (-not (Test-Path $destPath)) { Write-SOKLog "MISSING: $destPath" -Level Error; continue }
        $destSize = 0; $destFiles = 0
        try {
            $opts = [System.IO.EnumerationOptions]::new()
            $opts.RecurseSubdirectories = $true; $opts.IgnoreInaccessible = $true
            $opts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint
            foreach ($fi in [System.IO.Directory]::EnumerateFiles($destPath, '*', $opts)) {
                try { $destSize += ([System.IO.FileInfo]::new($fi)).Length; $destFiles++ } catch {}
            }
        } catch {}
        $destSizeKB = [math]::Round($destSize / 1KB, 0)
        $diffPct = if ($src.SizeKB -gt 0) { [math]::Round([math]::Abs($destSizeKB - $src.SizeKB) / $src.SizeKB * 100, 2) } else { 0 }

        if ($diffPct -lt 1 -and [math]::Abs($destFiles - $src.Files) -lt 5) {
            Write-SOKLog "VERIFIED: $(Split-Path $src.Path -Leaf) — $destFiles files, $destSizeKB KB (diff $diffPct%)" -Level Success
            $results.Verified = $true; $results.CopiedFiles += $destFiles; $results.CopiedKB += $destSizeKB
        } else {
            Write-SOKLog "MISMATCH: src=$($src.Files)/$($src.SizeKB)KB dest=$destFiles/${destSizeKB}KB (diff $diffPct%)" -Level Warn
        }
    }
} else { Write-SOKLog 'DRY RUN — skipped' -Level Debug }

$results.DurationSec = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
Write-SOKSummary -Stats $results -Title 'BACKUP COMPLETE'

if ($results.Verified -and -not $DryRun) {
    Write-SOKLog 'Backup VERIFIED. Safe to delete source:' -Level Success
    foreach ($src in $validSources) { Write-SOKLog "  Remove-Item '$($src.Path)' -Recurse -Force" -Level Annotate }
}

if (Get-Command Save-SOKHistory -ErrorAction SilentlyContinue) {
    Save-SOKHistory -ScriptName 'SOK-Backup' -RunData @{ Duration = $results.DurationSec; Results = $results }
}
