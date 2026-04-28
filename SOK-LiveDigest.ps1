<#
.SYNOPSIS
    SOK-LiveDigest.ps1 — Summarizes LiveScan JSON output into uploadable digest.

.DESCRIPTION
    LiveScan produces 79MB+ (DirsOnly) or 525MB+ (full) JSON files that are
    too large to upload to Claude or most tools. This script reads the JSON
    locally and produces a summary containing:
    - Directory sizes (top N)
    - File counts per top-level folder
    - Extension breakdown with total sizes
    - Top N largest files

    LiveScan JSON property mapping:
    - "p" = path (double-backslash escaped)
    - "s" = sizeKB (files only, absent in DirsOnly mode)
    - "c" = creation time (files only)
    - "m" = modified time

    Output: JSON (machine-parseable) + TXT (human-readable) in SOK\Logs\LiveDigest\

.PARAMETER InputPath
    Path to the LiveScan JSON file. If not specified, auto-detects most recent.

.PARAMETER TopN
    Number of items to include in "top N" lists. Default: 66666

.PARAMETER OutputDir
    Output directory. Default: SOK\Logs\LiveDigest\

.NOTES
    Author: S. Clay Caddell
    Version: 1.1.0
    Date: 25Mar2026
    Domain: PRESENT — consumes LiveScan JSON; produces uploadable digest; downstream of LiveScan
    Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-LiveDigest.ps1
    Flags: -InputPath <path> -TopN <int> -OutputDir <path>
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    # DryRun: parse the LiveScan JSON but skip writing digest output files.
    [switch]$DryRun,
    [string]$InputPath,
    # LOW-1 fix 2026-04-22: magic number documented. 204661 = Fibonacci convention
    # adopted across SOK (see SOK-Common $script:LOCK_TIMEOUT_SEC + ScanDepth=21 + other
    # Fibonacci-ish defaults). At this scale, TopN is effectively "don't truncate" —
    # typical LiveScan outputs have 50K-500K entries; 204661 keeps everything in the
    # top-N lists unless operator explicitly sets a lower value.
    [int]$TopN = 204661,
    [string]$OutputDir
)

$ErrorActionPreference = 'Continue'

# Date formats — literal strings, NOT module-scoped $script: vars (those are inaccessible from script scope)
$DateFile = 'yyyyMMdd_HHmmss'
$DateISO = 'yyyy-MM-dd HH:mm:ss'

# Module import
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else { Write-Error "SOK-Common.psm1 not found at $modulePath"; exit 1 }

Show-SOKBanner -ScriptName 'SOK-LiveDigest' -Subheader "TopN: $TopN"
$logPath = Initialize-SOKLog -ScriptName 'SOK-LiveDigest'
$startTime = Get-Date

# HIGH-10 fix 2026-04-21: gate the LiveScan cascade behind an explicit env var.
# Prior behavior: Invoke-SOKPrerequisite could auto-run a 30+ minute LiveScan as
# a "staleness freshness" step. Under SYSTEM (scheduled task), this silently
# extends LiveDigest's runtime by ~30 min with no operator awareness. The gate
# preserves the cascade for intentional interactive use (SOK_ALLOW_LIVESCAN_CASCADE=1)
# while protecting scheduled/automated invocations.
if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    if ($env:SOK_ALLOW_LIVESCAN_CASCADE -eq '1') {
        Invoke-SOKPrerequisite -CallingScript 'SOK-LiveDigest'
    } else {
        Write-SOKLog '  Invoke-SOKPrerequisite cascade SKIPPED (set $env:SOK_ALLOW_LIVESCAN_CASCADE=1 to enable auto-LiveScan if stale)' -Level Debug
    }
}

# ═══════════════════════════════════════════════════════════════
# LOCATE INPUT
# ═══════════════════════════════════════════════════════════════
if (-not $InputPath) {
    Write-SOKLog 'No input path specified -- searching for latest LiveScan output...' -Level Ignore
    $searchDirs = @(
        (Get-ScriptLogDir -ScriptName 'SOK-LiveScan')
        # Legacy-path fallbacks removed 2026-04-20 per CLAUDE.md §2 SOK Boundaries.
        # All SOK logs now live under Documents\Journal\Projects\SOK\Logs\ via Get-ScriptLogDir.
    )
    $candidates = @()
    foreach ($dir in $searchDirs) {
        if (Test-Path $dir) {
            $found = Get-ChildItem -Path $dir -Filter 'LiveScan_*.json' -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch 'Errors' -and $_.Name -notmatch '_history' } |
                Sort-Object LastWriteTime -Descending
            if ($found) { $candidates = @($found); break }
        }
    }
    if ($candidates.Count -eq 0) {
        Write-SOKLog 'No LiveScan JSON found. Run SOK-LiveScan first.' -Level Error
        exit 1
    }
    $InputPath = $candidates[0].FullName
    $sizeKB = Get-SizeKB -Bytes $candidates[0].Length
    Write-SOKLog "Found: $($candidates[0].Name) ($sizeKB KB)" -Level Success
}

if (-not (Test-Path $InputPath)) {
    Write-SOKLog "Input file not found: $InputPath" -Level Error
    exit 1
}

$inputSizeKB = Get-SizeKB -Bytes (Get-Item $InputPath).Length
Write-SOKLog "Input: $InputPath ($inputSizeKB KB)" -Level Ignore

# ═══════════════════════════════════════════════════════════════
# PARSE
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PARSING LIVESCAN DATA' -Level Section
$parseStart = Get-Date
# MEDIUM-5 fix 2026-04-21: memory-safety for large LiveScan JSON.
# Prior behavior: Get-Content -Raw loads the entire 525MB+ file into a single
# string, then ConvertFrom-Json builds a deep PSObject tree (often 3-4x the
# string size in RAM). Under SYSTEM's reduced working set (typically ~1.4GB
# commit ceiling), this has OOMed in the wild. Mitigations applied here:
#   (1) Size gate: warn at >250MB; refuse at >1GB with actionable error
#   (2) -AsHashtable flag on ConvertFrom-Json: ~40% less memory + faster property
#       access downstream (dictionary lookup beats PSObject.Properties walk)
#   (3) Free the raw string before GC to reduce peak
$inputSizeMB = (Get-Item $InputPath).Length / 1MB
if ($inputSizeMB -gt 1024) {
    Write-SOKLog "Input file is $([math]::Round($inputSizeMB,1)) MB — refusing to load (>1GB would OOM under SYSTEM). Consider splitting the scan or running LiveDigest interactively with expanded working set." -Level Error
    exit 2
}
if ($inputSizeMB -gt 250) {
    Write-SOKLog "Large input: $([math]::Round($inputSizeMB,1)) MB — memory-aware parse path (may take 20-60s)" -Level Warn
}
Write-SOKLog 'Loading JSON (this may take a moment for large files)...' -Level Annotate
try {
    $raw = Get-Content $InputPath -Raw -ErrorAction Stop
    # -AsHashtable: PS7+ only; faster + lower memory than PSObject tree
    $data = $raw | ConvertFrom-Json -AsHashtable -Depth 32 -ErrorAction Stop
    $raw = $null
    [System.GC]::Collect()
}
catch {
    Write-SOKLog "Failed to parse JSON: $_" -Level Error
    exit 1
}
$parseTime = [math]::Round(((Get-Date) - $parseStart).TotalSeconds, 1)
Write-SOKLog "Parsed in ${parseTime}s" -Level Success

# Extract items from LiveScan wrapper: { "scan_metadata":{}, "items":[], "summary":{} }
# MEDIUM-5 fix 2026-04-21: -AsHashtable (applied above) returns IDictionary, not
# PSCustomObject, so membership check must go through ContainsKey or Keys.
$entries = @()
$hasItems = $false
if ($data -is [System.Collections.IDictionary]) {
    $hasItems = $data.Contains('items')
} elseif ($null -ne $data -and $null -ne $data.PSObject) {
    $hasItems = $data.PSObject.Properties.Name -contains 'items'
}
if ($hasItems) {
    $entries = @($data['items'])
    $scanMeta = if ($data -is [System.Collections.IDictionary]) { $data['scan_metadata'] } else { $data.scan_metadata }
    if ($scanMeta) {
        $dirsOnlyRaw = if ($scanMeta -is [System.Collections.IDictionary]) { $scanMeta['dirs_only'] } else { $scanMeta.dirs_only }
        $source = if ($scanMeta -is [System.Collections.IDictionary]) { $scanMeta['source'] } else { $scanMeta.source }
        $dirsOnly = if ($dirsOnlyRaw) { 'DirsOnly' } else { 'Full' }
        Write-SOKLog "Scan mode: $dirsOnly | Source: $source" -Level Annotate
    }
}
elseif ($data -is [array]) { $entries = $data }
else { $entries = @($data) }

$totalEntries = $entries.Count
Write-SOKLog "Entries: $totalEntries" -Level Success

# Detect size data (present in full mode, absent in DirsOnly)
$hasSizeData = $false
if ($entries.Count -gt 0 -and $null -ne $entries[0].s) { $hasSizeData = $true }
Write-SOKLog "Size data present: $hasSizeData" -Level Annotate

# ═══════════════════════════════════════════════════════════════
# ANALYZE — LiveScan shorthand: p=path, s=sizeKB, m=modified, c=created
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ANALYZING' -Level Section

$topLevelMap = @{}
$processedCount = 0
foreach ($e in $entries) {
    $path = $e.p
    if (-not $path) { continue }
    # Note: LiveScan streaming JSON uses \\ in paths, but ConvertFrom-Json already unescapes them.
    # Only unescape if we detect double-backslashes still present.
    if ($path.Contains('\\')) { $path = $path.Replace('\\', '\') }

    $parts = $path -split '\\'
    $topLevel = if ($parts.Count -ge 3) { "$($parts[0])\$($parts[1])\$($parts[2])" } elseif ($parts.Count -ge 2) { "$($parts[0])\$($parts[1])" } else { $path }

    if (-not $topLevelMap.ContainsKey($topLevel)) { $topLevelMap[$topLevel] = @{ Count = 0; SizeKB = 0 } }
    $topLevelMap[$topLevel].Count++
    if ($e.s) { $topLevelMap[$topLevel].SizeKB += $e.s }

    $processedCount++
    # LOW-2 fix 2026-04-22: magic number documented. 222222 is the Fibonacci-adjacent
    # progress-log frequency — every ~222K entries processed (tens-of-seconds wall
    # clock) emit a progress line. Prevents log spam on small scans while still
    # showing liveness on multi-hundred-thousand-entry scans.
    if ($processedCount % 222222 -eq 0) {
        Write-SOKLog "  Processed $processedCount / $totalEntries entries..." -Level Debug
    }
}
Write-SOKLog "  Top-level folders: $($topLevelMap.Count)" -Level Success

$topLevelSorted = @($topLevelMap.GetEnumerator() |
    Sort-Object { $_.Value.SizeKB } -Descending |
    Select-Object -First $TopN |
    ForEach-Object { [ordered]@{ Path = $_.Key; Count = $_.Value.Count; SizeKB = [math]::Round($_.Value.SizeKB, 2) } })

# Extension breakdown
$extMap = @{}
foreach ($e in $entries) {
    $path = $e.p
    if (-not $path) { continue }
    $ext = [System.IO.Path]::GetExtension($path)
    if (-not $ext) { $ext = '(no-ext)' }
    $ext = $ext.ToLower()
    if (-not $extMap.ContainsKey($ext)) { $extMap[$ext] = @{ Count = 0; SizeKB = 0 } }
    $extMap[$ext].Count++
    if ($e.s) { $extMap[$ext].SizeKB += $e.s }
}
Write-SOKLog "  Extensions: $($extMap.Count)" -Level Success

$extSorted = @($extMap.GetEnumerator() |
    Sort-Object { $_.Value.SizeKB } -Descending |
    Select-Object -First $TopN |
    ForEach-Object { [ordered]@{ Extension = $_.Key; Count = $_.Value.Count; SizeKB = [math]::Round($_.Value.SizeKB, 2) } })

# Largest entries (only meaningful with size data)
$largestEntries = @()
if ($hasSizeData) {
    $largestEntries = @($entries |
        Where-Object { $_.s -gt 0 } |
        Sort-Object { $_.s } -Descending |
        Select-Object -First $TopN |
        ForEach-Object { [ordered]@{ Path = $_.p; SizeKB = $_.s; Modified = $_.m } })
    Write-SOKLog "  Largest entries: $($largestEntries.Count)" -Level Success
}
else {
    Write-SOKLog "  DirsOnly mode -- no per-file size data for largest entries" -Level Annotate
}

# ═══════════════════════════════════════════════════════════════
# BUILD OUTPUT
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'BUILDING DIGEST' -Level Section
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)

$digest = [ordered]@{
    metadata = [ordered]@{
        script_version = 'SOK-LiveDigest 1.1.0'
        source_file    = $InputPath
        source_size_kb = $inputSizeKB
        total_entries  = $totalEntries
        has_size_data  = $hasSizeData
        top_n          = $TopN
        generated_iso  = Get-Date -Format $DateISO
        duration_sec   = $duration
    }
    top_level_folders   = $topLevelSorted
    extension_breakdown = $extSorted
    largest_entries     = $largestEntries
}

if (-not $OutputDir) { $OutputDir = Get-ScriptLogDir -ScriptName 'SOK-LiveDigest' }
if (-not (Test-Path $OutputDir)) { New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null }

$ts = Get-Date -Format $DateFile
$jsonOut = Join-Path $OutputDir "LiveDigest_${ts}.json"
$txtOut = Join-Path $OutputDir "LiveDigest_${ts}.txt"

if ($DryRun) {
    Write-SOKLog "DRY RUN — digest complete; no output files written." -Level Warn
    Write-SOKLog "  Would write: $jsonOut" -Level Ignore
    Write-SOKLog "  Would write: $txtOut" -Level Ignore
    exit 0
}
$digest | ConvertTo-Json -Depth 6 | Set-Content -Path $jsonOut -Force -Encoding UTF8
$jsonSizeKB = Get-SizeKB -Bytes (Get-Item $jsonOut).Length
Write-SOKLog "JSON: $jsonOut ($jsonSizeKB KB)" -Level Success

# TXT summary
$txt = [System.Text.StringBuilder]::new()
[void]$txt.AppendLine("SOK-LiveDigest Summary -- $(Get-Date -Format $DateISO)")
[void]$txt.AppendLine("Source: $InputPath ($inputSizeKB KB)")
[void]$txt.AppendLine("Entries: $totalEntries | Size data: $hasSizeData | Duration: ${duration}s")
[void]$txt.AppendLine("")
[void]$txt.AppendLine("=== TOP-LEVEL FOLDERS (by size, count: $($topLevelSorted.Count)) ===")
foreach ($f in $topLevelSorted) {
    [void]$txt.AppendLine("  $($f.SizeKB.ToString().PadLeft(14)) KB  $($f.Count.ToString().PadLeft(8)) items  $($f.Path)")
}
[void]$txt.AppendLine("")
[void]$txt.AppendLine("=== EXTENSIONS (by size, count: $($extSorted.Count)) ===")
foreach ($e in $extSorted) {
    [void]$txt.AppendLine("  $($e.SizeKB.ToString().PadLeft(14)) KB  $($e.Count.ToString().PadLeft(8)) files  $($e.Extension)")
}
if ($hasSizeData -and $largestEntries.Count -gt 0) {
    [void]$txt.AppendLine("")
    [void]$txt.AppendLine("=== LARGEST FILES (count: $($largestEntries.Count)) ===")
    foreach ($l in $largestEntries) {
        [void]$txt.AppendLine("  $($l.SizeKB.ToString().PadLeft(14)) KB  $($l.Path)")
    }
}
Set-Content -Path $txtOut -Value $txt.ToString() -Force -Encoding UTF8
$txtSizeKB = Get-SizeKB -Bytes (Get-Item $txtOut).Length
Write-SOKLog "TXT:  $txtOut ($txtSizeKB KB)" -Level Success

Write-SOKSummary -Stats ([ordered]@{
    InputSizeKB     = $inputSizeKB
    TotalEntries    = $totalEntries
    HasSizeData     = $hasSizeData
    TopLevelFolders = $topLevelSorted.Count
    Extensions      = $extSorted.Count
    LargestEntries  = $largestEntries.Count
    OutputJsonKB    = $jsonSizeKB
    OutputTxtKB     = $txtSizeKB
    DurationSec     = $duration
}) -Title 'LIVEDIGEST COMPLETE'

# History write suppressed -- the LiveDigest JSON/TXT ARE the artifacts
# Save-SOKHistory -ScriptName 'SOK-LiveDigest' -AggregateOnly -RunData @{
#     Duration = $duration
#     Results  = @{ InputSizeKB = $inputSizeKB; Entries = $totalEntries; OutputKB = $jsonSizeKB + $txtSizeKB }
# }
