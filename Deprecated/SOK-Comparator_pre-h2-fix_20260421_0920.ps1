#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-Comparator.ps1 — Differential analysis between archive snapshots.
    (Formerly: TITAN COMPARATOR / The Diff Engine)

.DESCRIPTION
    Context-aware differential analysis tool for SOK/TITAN archives.
    O(n) indexing, lazy content loading, statistical gating, symbolic grammar.

.PARAMETER OldSnapshot
    Path to the older archive file.

.PARAMETER NewSnapshot
    Path to the newer archive file.

.PARAMETER OutputDir
    Directory for the diff report.

.PARAMETER AutoApproveThreshold
    Percentage of changed lines below which the report generates automatically.
    Above this threshold, user confirmation is required. Default: 16.66%

.NOTES
    Author: S. Clay Caddell
    Version: 2.1.0 (SOK canonical — formerly TITAN Comparator)
    Date: 18Mar2026
    Domain: PAST — differential analysis between Archiver snapshots; read-only; standalone tool

    Symbolic grammar: [+] Addition | [-] Subtraction | [x] Rescinded | [*] Revision | [~] Mixed
#>

[CmdletBinding()]
param(
    # In DryRun mode, OldSnapshot/NewSnapshot are optional — stub output is emitted.
    # In normal mode, both are mandatory and must point to existing archive files.
    [switch]$DryRun,

    [string]$OldSnapshot,
    [string]$NewSnapshot,

    [string]$OutputDir = "$env:USERPROFILE\Documents\Journal\Projects\SOK\Logs\Archives",

    [double]$AutoApproveThreshold = 16.66
)

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) }
    function Initialize-SOKLog { param([string]$ScriptName) return $null }
}

# If both snapshots are missing, force DryRun mode — no real comparison is possible.
# This makes the script resilient to ambiguous arg-binding scenarios (e.g. Start-Process marshaling).
if (-not $OldSnapshot -and -not $NewSnapshot -and -not $DryRun) {
    Write-Warning 'No snapshots provided; forcing DryRun mode.'
    $DryRun = $true
}

# Validate snapshot paths in non-DryRun mode
if (-not $DryRun) {
    if (-not $OldSnapshot) { throw "-OldSnapshot is required in non-DryRun mode." }
    if (-not $NewSnapshot)  { throw "-NewSnapshot is required in non-DryRun mode." }
    if (-not (Test-Path $OldSnapshot -PathType Leaf)) { throw "OldSnapshot not found: $OldSnapshot" }
    if (-not (Test-Path $NewSnapshot -PathType Leaf)) { throw "NewSnapshot not found: $NewSnapshot" }
}

$oldName = if ($OldSnapshot) { [System.IO.Path]::GetFileNameWithoutExtension($OldSnapshot) } else { 'DRY-OLD' }
$newName = if ($NewSnapshot) { [System.IO.Path]::GetFileNameWithoutExtension($NewSnapshot) } else { 'DRY-NEW' }

Show-SOKBanner -ScriptName 'SOK-Comparator' -Subheader "Base: $oldName | Compare: $newName$(if($DryRun){' [DRY RUN]'})"
$logPath = Initialize-SOKLog -ScriptName 'SOK-Comparator'

if ($DryRun) {
    Write-SOKLog 'DRY RUN — read-only analysis will proceed; no report file will be written.' -Level Warn
    Write-SOKLog "Would compare: $oldName vs $newName" -Level Ignore
    Write-SOKLog "OutputDir: $OutputDir" -Level Ignore
    if (-not $OldSnapshot -or -not $NewSnapshot) {
        Write-SOKLog 'DRY RUN — no snapshots provided, skipping analysis phases.' -Level Warn
        exit 0
    }
}

$HeaderRegex = '^\# FILE:\s+(?<Path>.*)$'

# ── INDEX BUILDER ──
function Get-ArchiveMap {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw [System.IO.FileNotFoundException] "Archive not found: $Path" }

    $map = @{}
    $currentFile = $null
    $lineNumber = 0

    Write-Progress -Activity "Indexing" -Status "Mapping: $(Split-Path $Path -Leaf)"

    $reader = $null
    try {
        $reader = [System.IO.StreamReader]::new($Path)
        while (($line = $reader.ReadLine()) -ne $null) {
            $lineNumber++
            if ($line -match $HeaderRegex) {
                if ($currentFile) { $map[$currentFile].End = $lineNumber - 5 }
                $currentFile = $matches['Path'].Trim()
                $map[$currentFile] = @{ Start = $lineNumber + 2; End = 0 }
            }
        }
        if ($currentFile) { $map[$currentFile].End = $lineNumber }
    }
    finally {
        if ($reader) { $reader.Dispose() }
    }

    Write-Progress -Activity "Indexing" -Completed
    return @{ Index = $map; TotalLines = $lineNumber }
}

# ── CHUNK EXTRACTOR ──
function Get-ArchiveChunk {
    param($Path, $Range)
    $content = @()
    $current = 0
    $reader = $null
    try {
        $reader = [System.IO.StreamReader]::new($Path)
        while (($line = $reader.ReadLine()) -ne $null) {
            $current++
            if ($current -ge $Range.Start -and $current -le $Range.End) { $content += $line }
            if ($current -gt $Range.End) { break }
        }
    }
    finally { if ($reader) { $reader.Dispose() } }
    return $content
}

# ── PHASE 1: INDEX ──
Write-SOKLog 'PHASE 1: INDEXING' -Level Section

try {
    $oldData = Get-ArchiveMap -Path $OldSnapshot
    $newData = Get-ArchiveMap -Path $NewSnapshot
    $mapOld = $oldData.Index
    $mapNew = $newData.Index
    Write-SOKLog "Old: $($mapOld.Count) files, $($oldData.TotalLines) lines" -Level Ignore
    Write-SOKLog "New: $($mapNew.Count) files, $($newData.TotalLines) lines" -Level Ignore
}
catch {
    Write-SOKLog "Indexing failed: $($_.Exception.Message)" -Level Error
    exit 1
}

# ── PHASE 2: STATISTICAL AUDIT ──
Write-SOKLog 'PHASE 2: DIFFERENTIAL ANALYSIS' -Level Section

$allFiles = ($mapOld.Keys + $mapNew.Keys) | Select-Object -Unique | Sort-Object
$diffCache = @{}
$stats = @{ Added = 0; Removed = 0; FilesMod = 0; FilesNew = 0; FilesDel = 0 }

$i = 0
foreach ($file in $allFiles) {
    $i++
    $pct = [math]::Round(($i / $allFiles.Count) * 100)
    Write-Progress -Activity "Phase 2: Audit" -Status "Comparing: $(Split-Path $file -Leaf)" -PercentComplete $pct

    if (-not $mapNew.ContainsKey($file)) {
        $lines = ($mapOld[$file].End - $mapOld[$file].Start) + 1
        $diffCache[$file] = @{ Type = "[x]"; LinesRemoved = $lines; LinesAdded = 0 }
        $stats.FilesDel++; $stats.Removed += $lines
        continue
    }
    if (-not $mapOld.ContainsKey($file)) {
        $lines = ($mapNew[$file].End - $mapNew[$file].Start) + 1
        $diffCache[$file] = @{ Type = "[+]"; LinesRemoved = 0; LinesAdded = $lines }
        $stats.FilesNew++; $stats.Added += $lines
        continue
    }

    $oldContent = Get-ArchiveChunk -Path $OldSnapshot -Range $mapOld[$file]
    $newContent = Get-ArchiveChunk -Path $NewSnapshot -Range $mapNew[$file]
    $diff = Compare-Object -ReferenceObject $oldContent -DifferenceObject $newContent

    if ($diff) {
        $add = ($diff | Where-Object SideIndicator -eq "=>").Count
        $rem = ($diff | Where-Object SideIndicator -eq "<=").Count
        $subType = if ($add -gt 0 -and $rem -gt 0) { "[~]" } elseif ($add -gt 0) { "[+]" } else { "[-]" }
        $diffCache[$file] = @{ Type = "[*]"; SubType = $subType; DiffObj = $diff; LinesAdded = $add; LinesRemoved = $rem }
        $stats.FilesMod++; $stats.Added += $add; $stats.Removed += $rem
    }
}
Write-Progress -Activity "Phase 2: Audit" -Completed

# ── THRESHOLD GATES ──
$totalChanges = $stats.Added + $stats.Removed
$maxLines = [math]::Max($oldData.TotalLines, $newData.TotalLines)
if ($maxLines -eq 0) { $maxLines = 1 }
$percentDiff = [math]::Round(($totalChanges / $maxLines) * 100, 2)

Write-SOKLog "Volatility: $percentDiff% | +$($stats.FilesNew) new | -$($stats.FilesDel) deleted | ~$($stats.FilesMod) modified" -Level Ignore
Write-SOKLog "Lines: +$($stats.Added) / -$($stats.Removed)" -Level Ignore

if ($totalChanges -eq 0) {
    Write-SOKLog 'Archives are IDENTICAL. No report needed.' -Level Success
    exit
}
if ($percentDiff -ge 100) {
    Write-SOKLog 'Archives are 100% DISJOINT — likely comparing unrelated snapshots.' -Level Error
    exit 1
}
if ($percentDiff -gt $AutoApproveThreshold) {
    Write-SOKLog "Volatility ($percentDiff%) exceeds auto-approve threshold ($AutoApproveThreshold%)." -Level Warn
    if (-not $DryRun) {
        $conf = Read-Host "Generate report anyway? (y/n)"
        if ($conf -ne 'y') { exit }
    }
}

# ── PHASE 3: REPORT ──
Write-SOKLog 'PHASE 3: REPORT GENERATION' -Level Section

$filesToWrite = $allFiles | Where-Object { $diffCache.ContainsKey($_) } | Sort-Object

if ($DryRun) {
    Write-SOKLog "DRY RUN — would write report to: $OutputDir" -Level Warn
    Write-SOKLog "DRY RUN — $($filesToWrite.Count) changed files | Volatility: $percentDiff%" -Level Warn
    foreach ($file in $filesToWrite) {
        $d = $diffCache[$file]
        Write-SOKLog "  $($d.Type) $file (+$($d.LinesAdded)/-$($d.LinesRemoved))" -Level Ignore
    }
    Write-SOKLog 'DRY RUN — no files created.' -Level Success
    exit 0
}

# ── Non-DryRun: create output directory and write report ──
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

$repV = 1
while (Test-Path "$OutputDir\SOK_Diff_${oldName}_${newName}_V${repV}.txt") { $repV++ }
$ReportPath = "$OutputDir\SOK_Diff_${oldName}_${newName}_V${repV}.txt"

$utf8 = [System.Text.Encoding]::UTF8
$stream = [System.IO.FileStream]::new($ReportPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read, 1048576)
$writer = [System.IO.StreamWriter]::new($stream, $utf8)

try {
    $writer.WriteLine("# " + ("=" * 111))
    $writer.WriteLine("# SOK DIFF REPORT V$repV")
    $writer.WriteLine("# DATE:       $(Get-Date -Format 'ddMMMyyyy HH:mm:ss')")
    $writer.WriteLine("# BASE:       $oldName")
    $writer.WriteLine("# COMPARE:    $newName")
    $writer.WriteLine("# VOLATILITY: $percentDiff%")
    $writer.WriteLine("# STATS:      +$($stats.Added) / -$($stats.Removed) lines | +$($stats.FilesNew) new | -$($stats.FilesDel) del | ~$($stats.FilesMod) mod")
    $writer.WriteLine("# " + ("=" * 111))
    $writer.WriteLine("# LEGEND: [+] Addition | [-] Subtraction | [x] Rescinded | [*] Revision | [~] Mixed")
    $writer.WriteLine("# " + ("=" * 111) + "`n")

    $i = 0

    foreach ($file in $filesToWrite) {
        $i++
        Write-Progress -Activity "Phase 3: Writing" -Status "$(Split-Path $file -Leaf)" -PercentComplete ([math]::Round(($i / $filesToWrite.Count) * 100))

        $d = $diffCache[$file]
        $net = $d.LinesAdded - $d.LinesRemoved
        $sym = if ($net -gt 0) { "+" } elseif ($net -lt 0) { "" } else { " " }

        if ($d.Type -eq "[x]") {
            $writer.WriteLine("# [x] FILE RESCINDED: $file (-$($d.LinesRemoved) lines)")
            $writer.WriteLine("# " + ("-" * 111) + "`n")
        }
        elseif ($d.Type -eq "[+]") {
            $writer.WriteLine("# [+] NEW FILE: $file (+$($d.LinesAdded) lines)")
            $writer.WriteLine("# " + ("-" * 111) + "`n")
        }
        elseif ($d.Type -eq "[*]") {
            $writer.WriteLine("# [*] REVISION: $file  (Type: $($d.SubType))")
            $writer.WriteLine("# STATS: +$($d.LinesAdded) / -$($d.LinesRemoved) | Net: $sym$net")
            $writer.WriteLine("# " + ("-" * 111))
            foreach ($change in $d.DiffObj) {
                if ($change.SideIndicator -eq "<=") { $writer.WriteLine("[-] $($change.InputObject)") }
                elseif ($change.SideIndicator -eq "=>") { $writer.WriteLine("[+] $($change.InputObject)") }
            }
            $writer.WriteLine("")
        }
    }
}
finally {
    Write-Progress -Activity "Phase 3: Writing" -Completed
    $writer.Flush(); $writer.Close(); $writer.Dispose(); $stream.Dispose()
    [System.GC]::Collect()
}

Write-SOKLog "Report: $ReportPath" -Level Success
Write-SOKLog "Changed files: $($filesToWrite.Count) | Volatility: $percentDiff%" -Level Ignore
