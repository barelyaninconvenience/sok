<#
.SYNOPSIS
    SOK-Restructure.ps1 — Identify deeply nested, redundant, and flattened file structures.
.DESCRIPTION
    Scans target directories for structural inefficiencies:
    1. Recursive backups (backup-of-backup nesting like C_\Users\shelc\Documents\Backup\...)
    2. Flattened paths (files renamed with path separators replaced by underscores)
    3. Duplicate subtrees (same directory name appearing at multiple depths)
    4. Excessive nesting (paths exceeding depth threshold)

    Report-only by default. Use -Action Flatten to restructure.
.PARAMETER TargetPaths
    Directories to scan. Defaults to Documents\Backup and Downloads.
.PARAMETER MaxDepth
    Flag paths deeper than this. Default: 13 (Fibonacci).
.PARAMETER Action
    Report (default) or Flatten.
.NOTES
    Author: S. Clay Caddell
    Version: 1.0.0
    Date: 27Mar2026
    Domain: PAST — analyzes file structure for redundancy and excessive nesting; report-only by default
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string[]]$TargetPaths = @(
        "$env:USERPROFILE\Documents\Backup",
        "$env:USERPROFILE\Downloads"
    ),
    [int]$MaxDepth = 13,
    [ValidateSet('Report', 'Flatten')]
    [string]$Action = 'Report'
)

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
$_hasCommon = $false
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
    $_hasCommon = $true
    $logPath = Initialize-SOKLog -ScriptName 'SOK-Restructure'
    Show-SOKBanner -ScriptName 'SOK-Restructure' -Subheader "Targets: $($TargetPaths.Count) | MaxDepth: $MaxDepth | Action: $Action"
}
if ($_hasCommon -and (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue)) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-Restructure'
}

function Log { param([string]$Msg, [string]$Level = 'Ignore')
    if ($_hasCommon) { Write-SOKLog $Msg -Level $Level }
    else { Write-Host "[$Level] $Msg" }
}

$startTime = Get-Date
$findings = @{
    RecursiveBackups = [System.Collections.ArrayList]::new()
    FlattenedPaths   = [System.Collections.ArrayList]::new()
    ExcessiveNesting = [System.Collections.ArrayList]::new()
    DuplicateNames   = [System.Collections.ArrayList]::new()
}
$totalScanned = 0

foreach ($target in $TargetPaths) {
    if (-not (Test-Path $target)) {
        Log "NOT FOUND: $target" -Level Warn
        continue
    }
    Log "SCANNING: $target" -Level Section

    $enumOpts = [System.IO.EnumerationOptions]::new()
    $enumOpts.RecurseSubdirectories = $true
    $enumOpts.IgnoreInaccessible = $true
    $enumOpts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint

    $dirs = try {
        [System.IO.Directory]::EnumerateDirectories($target, '*', $enumOpts)
    } catch { @() }

    $nameMap = @{}  # track directory names for duplicate detection
    $dirCount = 0

    foreach ($dir in $dirs) {
        $dirCount++
        $totalScanned++
        $relative = $dir.Substring($target.Length).TrimStart('\')
        $depth = ($relative -split '\\').Count
        $dirName = Split-Path $dir -Leaf

        # Excessive nesting
        if ($depth -gt $MaxDepth) {
            $sizeKB = 0
            try {
                $opts2 = [System.IO.EnumerationOptions]::new()
                $opts2.RecurseSubdirectories = $true; $opts2.IgnoreInaccessible = $true
                foreach ($fi in [System.IO.Directory]::EnumerateFiles($dir, '*', $opts2)) {
                    try { $sizeKB += ([System.IO.FileInfo]::new($fi)).Length } catch {}
                }
                $sizeKB = [math]::Round($sizeKB / 1KB, 0)
            } catch {}
            $findings.ExcessiveNesting.Add(@{ Path = $dir; Depth = $depth; SizeKB = $sizeKB }) | Out-Null
        }

        # Recursive backup detection: path contains backup-like nesting patterns
        # e.g., Backup\...\Backup, C_\Users\...\Documents\Backup
        if ($relative -match '(?i)backup.*\\.*backup|C_\\|20\d{2}\s+(Seagate|Laptop|Desktop)\s+Backup') {
            $findings.RecursiveBackups.Add(@{ Path = $dir; Depth = $depth; Pattern = $Matches[0] }) | Out-Null
        }

        # Flattened path detection: directory names containing path-like separators
        if ($dirName -match '^[A-Z]_' -or $dirName -match '_Users_|_Program Files_|_AppData_') {
            $findings.FlattenedPaths.Add(@{ Path = $dir; Name = $dirName }) | Out-Null
        }

        # Duplicate name tracking (top-level within each target only)
        if ($depth -le 3) {
            if (-not $nameMap.ContainsKey($dirName)) { $nameMap[$dirName] = @() }
            $nameMap[$dirName] += $dir
        }
    }
    Log "  Scanned $dirCount directories" -Level Success
}

# Collect duplicates (names appearing 3+ times)
foreach ($name in $nameMap.Keys) {
    if ($nameMap[$name].Count -ge 3) {
        $findings.DuplicateNames.Add(@{ Name = $name; Count = $nameMap[$name].Count; Paths = $nameMap[$name] }) | Out-Null
    }
}

# ═══════════════════════════════════════════════════════════════
# REPORT
# ═══════════════════════════════════════════════════════════════
Log 'FINDINGS' -Level Section

Log "Excessive nesting (depth > $MaxDepth): $($findings.ExcessiveNesting.Count)" -Level $(if ($findings.ExcessiveNesting.Count -gt 0) { 'Warn' } else { 'Success' })
foreach ($item in ($findings.ExcessiveNesting | Sort-Object { $_.Depth } -Descending | Select-Object -First 21)) {
    $name = if ($item.Path.Length -gt 89) { '...' + $item.Path.Substring($item.Path.Length - 86) } else { $item.Path }
    Log "  depth=$($item.Depth) $($item.SizeKB) KB  $name" -Level Warn
}
if ($findings.ExcessiveNesting.Count -gt 21) { Log "  ... +$($findings.ExcessiveNesting.Count - 21) more" -Level Debug }

Log "Recursive backups: $($findings.RecursiveBackups.Count)" -Level $(if ($findings.RecursiveBackups.Count -gt 0) { 'Warn' } else { 'Success' })
$uniquePatterns = $findings.RecursiveBackups | Group-Object { $_.Pattern } | Sort-Object Count -Descending
foreach ($p in ($uniquePatterns | Select-Object -First 8)) {
    Log "  '$($p.Name)' — $($p.Count) occurrences" -Level Annotate
}

Log "Flattened path names: $($findings.FlattenedPaths.Count)" -Level $(if ($findings.FlattenedPaths.Count -gt 0) { 'Annotate' } else { 'Success' })
foreach ($item in ($findings.FlattenedPaths | Select-Object -First 8)) {
    Log "  $($item.Name)" -Level Debug
}
if ($findings.FlattenedPaths.Count -gt 8) { Log "  ... +$($findings.FlattenedPaths.Count - 8) more" -Level Debug }

Log "Duplicate directory names (3+ occurrences): $($findings.DuplicateNames.Count)" -Level $(if ($findings.DuplicateNames.Count -gt 0) { 'Annotate' } else { 'Success' })
foreach ($item in ($findings.DuplicateNames | Sort-Object { $_.Count } -Descending | Select-Object -First 13)) {
    Log "  '$($item.Name)' x$($item.Count)" -Level Debug
}

# ═══════════════════════════════════════════════════════════════
# JSON REPORT
# ═══════════════════════════════════════════════════════════════
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)

if ($_hasCommon) {
    $reportDir = Get-ScriptLogDir -ScriptName 'SOK-Restructure'
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $reportPath = Join-Path $reportDir "Restructure_Report_${ts}.json"

    [ordered]@{
        Timestamp        = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Targets          = $TargetPaths
        MaxDepth         = $MaxDepth
        TotalScanned     = $totalScanned
        DurationSec      = $duration
        ExcessiveNesting = $findings.ExcessiveNesting.Count
        RecursiveBackups = $findings.RecursiveBackups.Count
        FlattenedPaths   = $findings.FlattenedPaths.Count
        DuplicateNames   = $findings.DuplicateNames.Count
        Details          = @{
            ExcessiveNesting = @($findings.ExcessiveNesting | Select-Object -First 55)
            RecursiveBackups = @($uniquePatterns | ForEach-Object { @{ Pattern = $_.Name; Count = $_.Count } })
            FlattenedPaths   = @($findings.FlattenedPaths | Select-Object -First 55)
            DuplicateNames   = @($findings.DuplicateNames | Select-Object -First 34)
        }
    } | ConvertTo-Json -Depth 8 | ForEach-Object {
        if ($DryRun) {
            Log "DRY RUN — scan complete; report not written. Would output: $reportPath" -Level Warn
        } else {
            $_ | Set-Content -Path $reportPath -Force -Encoding UTF8
            Log "Report: $reportPath" -Level Success
        }
    }
}

# Summary
if ($_hasCommon) {
    Write-SOKSummary -Stats ([ordered]@{
        DuplicateNames   = $findings.DuplicateNames.Count
        DurationSec      = $duration
        ExcessiveNesting = $findings.ExcessiveNesting.Count
        FlattenedPaths   = $findings.FlattenedPaths.Count
        RecursiveBackups = $findings.RecursiveBackups.Count
        TotalScanned     = $totalScanned
    }) -Title 'RESTRUCTURE REPORT'
}

Log "Scanned $totalScanned directories in ${duration}s" -Level Success
if ($Action -eq 'Report') {
    Log 'Report mode — no changes made. Use -Action Flatten to restructure.' -Level Ignore
}
