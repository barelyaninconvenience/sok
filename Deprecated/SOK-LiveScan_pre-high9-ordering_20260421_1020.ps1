<#
.SYNOPSIS
    SOK-LiveScan — Scan live filesystem to JSON with full metadata.
.DESCRIPTION
    Uses .NET EnumerateFiles for speed (same approach as SOK-SpaceAudit).
    Outputs streaming JSON with file path, size, dates, and directory structure.
    Skips junctions to avoid infinite loops and cross-drive traversal.
.NOTES
    Author: S. Clay Caddell
    Version: 1.1.0
    Date: 23Mar2026
    Domain: PRESENT — live filesystem snapshot to JSON; feeds LiveDigest for digest/summary
    Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-LiveScan.ps1
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    # DryRun: validate init and output path resolution but skip the actual filesystem scan.
    # LiveScan is inherently slow (30+ min full C:\); DryRun confirms invocability.
    [switch]$DryRun,
    [string]$SourcePath  = 'C:\',
    [string]$OutJson     = "$env:USERPROFILE\Documents\Journal\Projects\SOK\Logs\LiveScan\LiveScan_$(Get-Date -Format 'yyyyMMdd_HHmmss').json",
    [string]$ErrorLog    = "$env:USERPROFILE\Documents\Journal\Projects\SOK\Logs\LiveScan_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').log",
    [switch]$DirsOnly,         # Only output directories (much faster, smaller output)
    [int]$MinSizeKB      = 0,  # Skip files smaller than this
    [switch]$ExcludeNoisyDirs  # Flag to drop massive system folders
)

$ErrorActionPreference = 'Continue'

# ── SYSTEM-CONTEXT PATH RESOLUTION ──
if ($env:USERPROFILE -like '*systemprofile*') {
    $actualProfile = 'C:\Users\shelc'
    $OutJson  = $OutJson  -replace [regex]::Escape($env:USERPROFILE), $actualProfile
    $ErrorLog = $ErrorLog -replace [regex]::Escape($env:USERPROFILE), $actualProfile
    $env:USERPROFILE  = $actualProfile
    $env:LOCALAPPDATA = "$actualProfile\AppData\Local"
    $env:APPDATA      = "$actualProfile\AppData\Roaming"
}

$startTime = Get-Date

# Import Common module
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
$_hasCommon = $false
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
    $_hasCommon = $true
    $logPath = Initialize-SOKLog -ScriptName 'SOK-LiveScan'
    # Prerequisite check (optional — LiveScan can run independently)
    if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
        Invoke-SOKPrerequisite -CallingScript 'SOK-LiveScan'
    }
}

# Route output to Logs dir if Common is available
if ($_hasCommon -and -not $PSBoundParameters.ContainsKey('OutJson')) {
    $scanDir = Get-ScriptLogDir -ScriptName 'SOK-LiveScan'
    $OutJson = Join-Path $scanDir "LiveScan_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
}
if ($_hasCommon -and -not $PSBoundParameters.ContainsKey('ErrorLog')) {
    $scanDir = Get-ScriptLogDir -ScriptName 'SOK-LiveScan'
    $ErrorLog = Join-Path $scanDir "LiveScan_Errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
}

if ($_hasCommon) { Show-SOKBanner -ScriptName 'SOK-LiveScan' -Subheader "Source: $SourcePath | DirsOnly: $($DirsOnly.IsPresent)" }

# Ensure output dirs
foreach ($f in @($OutJson, $ErrorLog)) {
    $d = Split-Path $f -Parent
    if (-not (Test-Path $d)) { New-Item -Path $d -ItemType Directory -Force | Out-Null }
}

# The black hole directories to skip if the flag is thrown
$excludePattern = '\\AppData\\|\\WinSxS\\|\\node_modules\\'

if ($DryRun) {
    Write-Host "SOK-LiveScan [DRY RUN]: Would scan $SourcePath" -ForegroundColor Yellow
    Write-Host "  Output would be: $OutJson" -ForegroundColor DarkGray
    Write-Host "  DirsOnly: $($DirsOnly.IsPresent) | MinSizeKB: $MinSizeKB | ExcludeNoisy: $($ExcludeNoisyDirs.IsPresent)" -ForegroundColor DarkGray
    if ($_hasCommon) { Write-SOKLog 'DRY RUN — scan skipped. No JSON written.' -Level Warn }
    exit 0
}

Write-Host "SOK-LiveScan: Scanning $SourcePath..." -ForegroundColor Cyan
Write-Host "Output: $OutJson" -ForegroundColor DarkGray

# .NET enumeration options — skip junctions, ignore inaccessible
$enumOpts = [System.IO.EnumerationOptions]::new()
$enumOpts.RecurseSubdirectories = $true
$enumOpts.IgnoreInaccessible = $true
$enumOpts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint -bor [System.IO.FileAttributes]::System

# Streaming JSON writer — avoids loading millions of objects into memory
$stream = [System.IO.StreamWriter]::new($OutJson, $false, [System.Text.Encoding]::UTF8)
$errStream = [System.IO.StreamWriter]::new($ErrorLog, $false, [System.Text.Encoding]::UTF8)
$stream.WriteLine('{')
$stream.WriteLine('  "scan_metadata": {')
$stream.WriteLine("    `"source`": `"$($SourcePath.Replace('\','\\'))`",")
$stream.WriteLine("    `"start_time`": `"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`",")
$stream.WriteLine("    `"hostname`": `"$env:COMPUTERNAME`",")
$stream.WriteLine("    `"dirs_only`": $($DirsOnly.ToString().ToLower())")
$stream.WriteLine('  },')
$stream.WriteLine('  "items": [')

$count = 0
$errCount = 0
$isFirst = $true
$lastProgress = $startTime

try {
    if ($DirsOnly) {
        # Directory-only mode — much faster, great for structure mapping
        $root = [System.IO.DirectoryInfo]::new($SourcePath)
        foreach ($dir in $root.EnumerateDirectories('*', $enumOpts)) {
            try {
                if (-not $isFirst) { $stream.Write(',') }
                $isFirst = $false

                $safePath = $dir.FullName.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t').Replace("`n", '\n').Replace("`r", '\r')
                $modified = $dir.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')

                $stream.Write("{`"p`":`"$safePath`",`"m`":`"$modified`"}")
                $count++

                if ($count % 5000 -eq 0) {
                    $elapsed = (Get-Date) - $startTime
                    $rate = [Math]::Round($count / [Math]::Max($elapsed.TotalSeconds, 1))
                    Write-Host "  Dirs: $($count.ToString('N0')) | ${rate}/s | $([Math]::Floor($elapsed.TotalMinutes))m" -ForegroundColor DarkYellow
                }
            }
            catch {
                $errCount++
                $errStream.WriteLine("[$($_.CategoryInfo.Category)] $($dir.FullName) - $($_.Exception.Message)")
            }
        }
    }
    else {
        # Full file mode — includes size and creation date
        $root = [System.IO.DirectoryInfo]::new($SourcePath)
        foreach ($file in $root.EnumerateFiles('*', $enumOpts)) {
            try {
				if ($file.FullName -match $excludePattern) { continue }
				
                $sizeKB = [Math]::Round($file.Length / 1024, 2)
                if ($sizeKB -lt $MinSizeKB) { continue }

                if (-not $isFirst) { $stream.Write(',') }
                $isFirst = $false

                $safePath = $file.FullName.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t').Replace("`n", '\n').Replace("`r", '\r')
                $creation = $file.CreationTime.ToString('yyyy-MM-dd HH:mm:ss')
                $modified = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')

                $stream.Write("{`"p`":`"$safePath`",`"s`":$sizeKB,`"c`":`"$creation`",`"m`":`"$modified`"}")
                $count++

                if ($count % 10000 -eq 0) {
                    $elapsed = (Get-Date) - $startTime
                    $rate = [Math]::Round($count / [Math]::Max($elapsed.TotalSeconds, 1))
                    Write-Host "  Files: $($count.ToString('N0')) | ${rate}/s | $([Math]::Floor($elapsed.TotalMinutes))m" -ForegroundColor DarkYellow
                }
            }
            catch {
                $errCount++
                $errStream.WriteLine("[$($_.CategoryInfo.Category)] $($file.FullName) - $($_.Exception.Message)")
            }
        }
    }
}
catch {
    $errStream.WriteLine("[FATAL] $($_.Exception.Message)")
}

# Close JSON
$stream.WriteLine('')
$stream.WriteLine('  ],')
$totalTime = (Get-Date) - $startTime
$stream.WriteLine("  `"summary`": {")
$stream.WriteLine("    `"total_items`": $count,")
$stream.WriteLine("    `"errors`": $errCount,")
$stream.WriteLine("    `"duration_seconds`": $([Math]::Round($totalTime.TotalSeconds, 1)),")
$stream.WriteLine("    `"end_time`": `"$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`"")
$stream.WriteLine('  }')
$stream.WriteLine('}')
$stream.Close(); $stream.Dispose()
$errStream.Close(); $errStream.Dispose()

$totalMin = [Math]::Floor($totalTime.TotalMinutes)
$totalSec = $totalTime.Seconds
$sizeKB = [Math]::Round((Get-Item $OutJson).Length / 1KB)

Write-Host ""
Write-Host "  COMPLETE: $($count.ToString('N0')) items in ${totalMin}m${totalSec}s" -ForegroundColor Green
Write-Host "  JSON: $OutJson ($sizeKB KB)" -ForegroundColor Cyan
Write-Host "  Errors: $errCount (see $ErrorLog)" -ForegroundColor $(if ($errCount -gt 0) { 'Yellow' } else { 'DarkGray' })
Write-Host ""
