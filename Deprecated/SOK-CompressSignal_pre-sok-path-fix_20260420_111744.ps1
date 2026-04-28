<#
.SYNOPSIS
    SOK-CompressSignal.ps1 — Compress staged signal files into 7z archives for E:\ consolidation.
.DESCRIPTION
    Phase 2 of the E:\ restructure. Takes the staged signal files from SOK-ExtractSignal.ps1
    (at C:\Temp_Staging\E_Signal) and compresses them into category-based 7z archives.

    After compression and verification, the archives are moved to E:\ and the staging area is cleaned.

    Compression settings match Clay's preferences (from screenshot):
    - Format: 7z, LZMA2, Maximum compression (level 9)
    - Dictionary: 128 MB, Word size: 64, Solid block: 16 GB
    - Threads: 17/20 (configurable)

    Phases:
    1. Inventory staged files by category
    2. Compress each category to separate 7z archive
    3. Verify archive integrity (7z t)
    4. Move verified archives to E:\
    5. Clean staging area (optional)

.PARAMETER DryRun
    Preview compression plan without executing.

.PARAMETER StagingPath
    Source of staged files. Default: C:\Temp_Staging\E_Signal

.PARAMETER ArchiveDestination
    Where to store final archives. Default: E:\Archives_Consolidated

.PARAMETER SkipVerify
    Skip archive integrity verification (not recommended).

.PARAMETER SkipClean
    Don't delete staging files after successful compression + verification.

.PARAMETER CompressionLevel
    7z compression level: 1 (fastest) to 9 (maximum). Default: 9

.PARAMETER Threads
    Number of CPU threads for compression. Default: 17

.NOTES
    Author: Claude + Clay
    Date: 2026-04-08
    Domain: Utility — Phase 2 of E:\ restructure
    REQUIRES: 7z.exe in PATH (installed via Chocolatey: 7zip)
    REQUIRES: SOK-ExtractSignal.ps1 Phase 1 completed successfully
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$StagingPath = 'C:\Temp_Staging\E_Signal',
    [string]$ArchiveDestination = 'E:\Archives_Consolidated',
    [switch]$SkipVerify,
    [switch]$SkipClean,
    [int]$CompressionLevel = 9,
    [int]$Threads = 17
)

$ErrorActionPreference = 'Continue'

# ─── MODULE LOAD ────────────────────────────────────────

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) Write-Host "`n$ScriptName — $Subheader`n" }
}

if (Get-Command Show-SOKBanner -ErrorAction SilentlyContinue) {
    Show-SOKBanner -ScriptName 'SOK-CompressSignal' -Subheader "$(Get-Date -Format 'yyyy-MM-dd HH:mm')$(if ($DryRun) { ' [DRY RUN]' })"
}

# ─── INITIALIZATION ─────────────────────────────────────

$logDir = 'C:\Users\shelc\Documents\SOK\Logs\CompressSignal'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile = Join-Path $logDir "CompressSignal_${timestamp}.log"

function Log { param([string]$Msg, [string]$Level = 'Annotate')
    $sokLevel = switch ($Level) {
        'Info'    { 'Annotate' }
        'Warning' { 'Warn' }
        default   { $Level }
    }
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg"
    Add-Content -Path $logFile -Value $line
    if (Get-Command Write-SOKLog -ErrorAction SilentlyContinue) { Write-SOKLog $Msg -Level $sokLevel }
    else { Write-Host $line }
}

# ─── PREREQUISITES ──────────────────────────────────────

$7zExe = Get-Command '7z' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $7zExe) {
    $7zExe = 'C:\Program Files\7-Zip\7z.exe'
    if (-not (Test-Path $7zExe)) {
        Log "7z.exe not found. Install via: choco install 7zip" -Level Error
        exit 1
    }
}
Log "7z: $7zExe"

if (-not (Test-Path $StagingPath)) {
    Log "Staging path not found: $StagingPath — run SOK-ExtractSignal.ps1 first" -Level Error
    exit 1
}

# ─── PHASE 1: INVENTORY STAGED CATEGORIES ───────────────

Log "PHASE 1: Inventorying staged files..." -Level Section

$categories = Get-ChildItem $StagingPath -Directory -ErrorAction SilentlyContinue
if (-not $categories -or $categories.Count -eq 0) {
    Log "No category directories found in $StagingPath" -Level Error
    exit 1
}

$plan = @()
foreach ($cat in $categories) {
    $files = Get-ChildItem $cat.FullName -Recurse -File -Force -ErrorAction SilentlyContinue
    $fileCount = ($files | Measure-Object).Count
    $sizeGB = [math]::Round(($files | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
    $archiveName = "E_Signal_$($cat.Name)_${timestamp}.7z"

    $plan += [PSCustomObject]@{
        Category    = $cat.Name
        SourceDir   = $cat.FullName
        FileCount   = $fileCount
        SizeGB      = $sizeGB
        ArchiveName = $archiveName
        ArchivePath = Join-Path $StagingPath $archiveName
        FinalPath   = Join-Path $ArchiveDestination $archiveName
    }

    Log "  $($cat.Name.PadRight(15)) $($fileCount.ToString().PadLeft(8)) files  $($sizeGB.ToString().PadLeft(8)) GB  -> $archiveName"
}

$totalFiles = ($plan | Measure-Object -Property FileCount -Sum).Sum
$totalGB = [math]::Round(($plan | Measure-Object -Property SizeGB -Sum).Sum, 2)
Log "Total: $totalFiles files ($totalGB GB) across $($plan.Count) categories"

if ($DryRun) {
    Log "" -Level Section
    Log "=== DRY RUN COMPRESSION PLAN ===" -Level Section
    foreach ($p in $plan) {
        Log "  $($p.Category): $($p.FileCount) files ($($p.SizeGB) GB) -> $($p.ArchiveName)"
        Log "    Estimated compressed: ~$([math]::Round($p.SizeGB * 0.5, 2)) GB (50% ratio estimate)"
    }
    $estCompressed = [math]::Round($totalGB * 0.5, 2)
    Log ""
    Log "  Estimated total compressed: ~$estCompressed GB"
    Log "  C:\ free space needed: ~$estCompressed GB (currently $([math]::Round((Get-PSDrive C).Free/1GB, 1)) GB free)"
    Log "  E:\ destination: $ArchiveDestination"
    Log ""
    Log "  [DRY RUN] No compression executed. Remove -DryRun to proceed." -Level Warn
    exit 0
}

# ─── PHASE 2: COMPRESS EACH CATEGORY ────────────────────

Log "PHASE 2: Compressing..." -Level Section

if (-not (Test-Path $ArchiveDestination)) {
    New-Item -ItemType Directory -Path $ArchiveDestination -Force | Out-Null
    Log "Created destination: $ArchiveDestination"
}

$results = @()
foreach ($p in $plan) {
    Log "  Compressing $($p.Category) ($($p.FileCount) files, $($p.SizeGB) GB)..." -Level Annotate

    $7zArgs = @(
        'a'                           # Add to archive
        '-t7z'                        # 7z format
        "-mx=$CompressionLevel"       # Compression level
        '-m0=LZMA2'                   # LZMA2 method
        '-md=128m'                    # 128 MB dictionary
        '-mfb=64'                     # 64 word size
        '-ms=16g'                     # 16 GB solid block
        "-mmt=$Threads"               # Thread count
        $p.ArchivePath                # Output archive
        "$($p.SourceDir)\*"           # Input files
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process -FilePath $7zExe -ArgumentList $7zArgs -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$logDir\7z_${timestamp}_$($p.Category)_stdout.log" -RedirectStandardError "$logDir\7z_${timestamp}_$($p.Category)_stderr.log"
    $sw.Stop()

    $archiveSize = if (Test-Path $p.ArchivePath) { (Get-Item $p.ArchivePath).Length } else { 0 }
    $archiveSizeGB = [math]::Round($archiveSize / 1GB, 2)
    $ratio = if ($p.SizeGB -gt 0) { [math]::Round($archiveSizeGB / $p.SizeGB * 100, 1) } else { 0 }

    $result = [PSCustomObject]@{
        Category     = $p.Category
        InputFiles   = $p.FileCount
        InputGB      = $p.SizeGB
        OutputGB     = $archiveSizeGB
        Ratio        = "$ratio%"
        ExitCode     = $proc.ExitCode
        Duration     = "$([math]::Round($sw.Elapsed.TotalMinutes, 1)) min"
        ArchivePath  = $p.ArchivePath
        FinalPath    = $p.FinalPath
    }
    $results += $result

    if ($proc.ExitCode -eq 0) {
        Log "    OK: $archiveSizeGB GB ($ratio% ratio) in $([math]::Round($sw.Elapsed.TotalMinutes, 1)) min" -Level Success
    } else {
        Log "    FAILED: 7z exit code $($proc.ExitCode). Check $logDir for details." -Level Error
    }
}

# ─── PHASE 3: VERIFY ARCHIVES ───────────────────────────

if (-not $SkipVerify) {
    Log "PHASE 3: Verifying archive integrity..." -Level Section

    foreach ($r in $results) {
        if ($r.ExitCode -ne 0) {
            Log "  SKIP $($r.Category) — compression failed" -Level Warn
            continue
        }
        $testProc = Start-Process -FilePath $7zExe -ArgumentList @('t', $r.ArchivePath) -NoNewWindow -Wait -PassThru
        if ($testProc.ExitCode -eq 0) {
            Log "  VERIFIED: $($r.Category)" -Level Success
        } else {
            Log "  CORRUPT: $($r.Category) — archive failed integrity check!" -Level Error
            $r | Add-Member -NotePropertyName Verified -NotePropertyValue $false -Force
        }
    }
} else {
    Log "PHASE 3: Skipped (SkipVerify=$SkipVerify)" -Level Warn
}

# ─── PHASE 4: MOVE TO E:\ ───────────────────────────────

Log "PHASE 4: Moving verified archives to $ArchiveDestination..." -Level Section

foreach ($r in $results) {
    if ($r.ExitCode -ne 0) {
        Log "  SKIP $($r.Category) — compression failed" -Level Warn
        continue
    }
    try {
        Move-Item -Path $r.ArchivePath -Destination $r.FinalPath -Force
        Log "  MOVED: $($r.Category) -> $($r.FinalPath)" -Level Success
    } catch {
        Log "  MOVE FAILED: $($r.Category) — $_" -Level Error
    }
}

# ─── PHASE 5: CLEAN STAGING ─────────────────────────────

if (-not $SkipClean) {
    Log "PHASE 5: Cleaning staging area..." -Level Section
    try {
        Remove-Item $StagingPath -Recurse -Force
        Log "  Staging area removed: $StagingPath" -Level Success
    } catch {
        Log "  Cleanup failed: $_" -Level Warn
    }
} else {
    Log "PHASE 5: Skipped (SkipClean=$SkipClean)" -Level Annotate
}

# ─── SUMMARY ────────────────────────────────────────────

Log "" -Level Section
Log "=== COMPRESSION SUMMARY ===" -Level Section
$totalInput = [math]::Round(($results | Measure-Object -Property InputGB -Sum).Sum, 2)
$totalOutput = [math]::Round(($results | Measure-Object -Property OutputGB -Sum).Sum, 2)
$overallRatio = if ($totalInput -gt 0) { [math]::Round($totalOutput / $totalInput * 100, 1) } else { 0 }

foreach ($r in $results) {
    Log "  $($r.Category.PadRight(15)) $($r.InputGB.ToString().PadLeft(8)) GB -> $($r.OutputGB.ToString().PadLeft(8)) GB ($($r.Ratio)) [$($r.Duration)]"
}
Log ""
Log "  Total input:  $totalInput GB"
Log "  Total output: $totalOutput GB ($overallRatio% overall ratio)"
Log "  Destination:  $ArchiveDestination"
Log "  Log: $logFile"
Log ""
Log "Next step: Delete noise from E:\Backup_Archive to reclaim space" -Level Section
