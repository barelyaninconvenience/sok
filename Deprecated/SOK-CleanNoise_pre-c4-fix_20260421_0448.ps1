<#
.SYNOPSIS
    SOK-CleanNoise.ps1 — Delete noise files from E:\Backup_Archive after signal extraction.
.DESCRIPTION
    Phase 3 of the E:\ restructure. After SOK-ExtractSignal has staged signal files and
    SOK-CompressSignal has archived them, this script removes the noise (DLLs, system files,
    duplicate backup trees) from E:\Backup_Archive to reclaim space.

    Safety: DryRun is MANDATORY for first run. Reviews what will be deleted before acting.

    Order of operations:
    1. Delete known noise file types (.dll, .exe [non-keep-list], .vdi, .vhdx, .esd, .jar, .cab, .bin, .sys, .msi)
    2. Delete empty directories (bottom-up)
    3. Report space reclaimed

.PARAMETER DryRun
    MANDATORY first run. Preview deletions without executing.

.PARAMETER TargetPath
    Path to clean. Default: E:\Backup_Archive

.PARAMETER KeepArchives
    Don't delete the existing .7z files in the backup (they're already signal). Default: true.

.NOTES
    Author: Claude + Clay
    Date: 2026-04-08
    Domain: Utility — Phase 3 of E:\ restructure
    WARNING: This is destructive. DryRun first. Always.
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$TargetPath = 'E:\Backup_Archive',
    [switch]$KeepArchives = $true
)

$ErrorActionPreference = 'Continue'

# ─── MODULE LOAD ────────────────────────────────────────

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
}

$logDir = 'C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\CleanNoise'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile = Join-Path $logDir "CleanNoise_${timestamp}.log"

function Log { param([string]$Msg, [string]$Level = 'Annotate')
    $sokLevel = switch ($Level) { 'Info' { 'Annotate' } 'Warning' { 'Warn' } default { $Level } }
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg"
    Add-Content -Path $logFile -Value $line
    if (Get-Command Write-SOKLog -ErrorAction SilentlyContinue) { Write-SOKLog $Msg -Level $sokLevel }
    else { Write-Host $line }
}

Write-Host "`nSOK-CleanNoise — $(Get-Date -Format 'yyyy-MM-dd HH:mm')$(if ($DryRun) { ' [DRY RUN]' })`n"

# ─── NOISE EXTENSIONS ──────────────────────────────────

$noiseExtensions = @(
    '.dll', '.sys', '.drv', '.ocx', '.cpl',           # System libraries
    '.msi', '.msp', '.msu', '.msm',                   # Installers
    '.esd', '.wim', '.swm',                            # Windows images
    '.cab', '.cat',                                     # Cabinet files
    '.nupkg', '.whl',                                   # Package managers
    '.pdb', '.ilk', '.obj', '.lib', '.exp',            # Debug/build artifacts
    '.partial',                                         # Incomplete downloads
    '.etl', '.evtx',                                    # Event logs
    '.vdi', '.vhdx', '.vmdk', '.vhd',                  # Virtual disks
    '.tmp', '.temp', '.bak', '.old',                   # Temp files
    '.lnk', '.url'                                     # Shortcuts
)

# EXEs to keep (same patterns as ExtractSignal)
$keepExePatterns = @(
    'arcgis*', 'volatility*', 'analyst*', 'i2*', 'maltego*',
    'wireshark*', 'nmap*', 'autopsy*', 'ghidra*', 'binwalk*',
    'putty*', 'aida64*', 'cityengine*'
)

# ─── PHASE 1: SCAN NOISE ───────────────────────────────

Log "PHASE 1: Scanning for noise files in $TargetPath..." -Level Section

$noiseFiles = [System.Collections.Generic.List[PSObject]]::new()
$keepCount = 0

Get-ChildItem $TargetPath -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $ext = $_.Extension.ToLower()
    $name = $_.Name.ToLower()
    $isNoise = $false

    if ($ext -in $noiseExtensions) { $isNoise = $true }

    # Non-keep-list EXEs are noise
    if ($ext -eq '.exe') {
        $isKeep = $false
        foreach ($pattern in $keepExePatterns) {
            if ($name -like $pattern) { $isKeep = $true; break }
        }
        if (-not $isKeep) { $isNoise = $true }
    }

    # Extensionless files in system paths are noise
    if ($ext -eq '' -and $_.FullName -match '\\(Program Files|Windows|AppData|ProgramData)\\') {
        $isNoise = $true
    }

    # .jar files are noise (Java archives from app installs)
    if ($ext -eq '.jar') { $isNoise = $true }

    # .bin files are noise
    if ($ext -eq '.bin') { $isNoise = $true }

    if ($isNoise) {
        $noiseFiles.Add($_)
    } else {
        $keepCount++
    }
}

$noiseSizeGB = [math]::Round(($noiseFiles | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
Log "Found $($noiseFiles.Count) noise files ($noiseSizeGB GB)" -Level Annotate
Log "Keeping $keepCount files"

# ─── PHASE 2: DELETE NOISE (or preview) ─────────────────

Log "PHASE 2: $(if ($DryRun) { 'PREVIEW' } else { 'DELETING' }) noise files..." -Level Section

$deleted = 0
$deletedSize = 0
$deleteErrors = 0

if ($DryRun) {
    # Just report top noise by extension
    $byExt = $noiseFiles | Group-Object { $_.Extension.ToLower() } |
        Select-Object @{N='Ext';E={$_.Name}}, Count, @{N='SizeGB';E={[math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum/1GB, 2)}} |
        Sort-Object SizeGB -Descending | Select-Object -First 15

    foreach ($e in $byExt) {
        Log "  WOULD DELETE: $($e.Ext.PadRight(10)) $($e.Count.ToString().PadLeft(8)) files  $($e.SizeGB.ToString().PadLeft(8)) GB"
    }
    Log ""
    Log "  TOTAL: $($noiseFiles.Count) files ($noiseSizeGB GB) would be deleted" -Level Warn
    Log "  [DRY RUN] Nothing was deleted. Remove -DryRun to execute." -Level Warn
} else {
    foreach ($f in $noiseFiles) {
        try {
            $size = $f.Length
            Remove-Item -Path $f.FullName -Force -ErrorAction Stop
            $deleted++
            $deletedSize += $size
        } catch {
            $deleteErrors++
        }
        if ($deleted % 10000 -eq 0) { Log "  Deleted $deleted / $($noiseFiles.Count)..." }
    }
    Log "Deleted $deleted files ($([math]::Round($deletedSize/1GB, 2)) GB). Errors: $deleteErrors" -Level Success
}

# ─── PHASE 3: REMOVE EMPTY DIRECTORIES ──────────────────

if (-not $DryRun) {
    Log "PHASE 3: Removing empty directories..." -Level Section
    $emptyRemoved = 0
    # Bottom-up: deepest first
    Get-ChildItem $TargetPath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Sort-Object { $_.FullName.Length } -Descending |
        ForEach-Object {
            $items = Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue
            if (-not $items -or $items.Count -eq 0) {
                try {
                    Remove-Item $_.FullName -Force -ErrorAction Stop
                    $emptyRemoved++
                } catch { }
            }
        }
    Log "Removed $emptyRemoved empty directories" -Level Success
} else {
    $emptyDirs = Get-ChildItem $TargetPath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { -not (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue) }
    Log "PHASE 3: Would remove ~$($emptyDirs.Count) empty directories [DRY RUN]" -Level Warn
}

# ─── SUMMARY ────────────────────────────────────────────

Log "" -Level Section
Log "=== CLEAN NOISE SUMMARY ===" -Level Section
Log "  Target: $TargetPath"
Log "  Noise files: $($noiseFiles.Count) ($noiseSizeGB GB)"
if (-not $DryRun) {
    Log "  Deleted: $deleted files ($([math]::Round($deletedSize/1GB, 2)) GB)"
    Log "  Errors: $deleteErrors"
    Log "  Empty dirs removed: $emptyRemoved"
    $freeGB = [math]::Round((Get-PSDrive E -ErrorAction SilentlyContinue).Free / 1GB, 1)
    Log "  E:\ free space now: $freeGB GB"
}
Log "  Log: $logFile"
