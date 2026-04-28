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

.PARAMETER AggressiveCleanup
    C-4 fix 2026-04-21: opt-in flag for extensions that may contain legitimate user data.
    When false (default), .bak/.old/.lnk/.url/.etl/.evtx are NOT deleted.
    Rationale: .pst.bak (Outlook), .lnk/.url (the only pointer to an app install on the
    archive), .etl/.evtx (forensics data — may be intentionally archived).

.NOTES
    Author: S. Clay Caddell (L-9: normalized 2026-04-22 — prior "Claude + Clay" was non-canonical)
    Date: 2026-04-08; C-4 fix 2026-04-21; L-6/L-9 polish 2026-04-22
    Domain: Utility — Phase 3 of E:\ restructure
    WARNING: This is destructive. DryRun first. Always.

    C-4 also adds: per-file manifest JSON written to SOK\Logs\CleanNoise\ BEFORE
    deletion so recovery is possible from robocopy-offload of the archive tree.
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$TargetPath = 'E:\Backup_Archive',
    # L-6 (Cluster C) fix 2026-04-22: changed [switch] → [bool] for $KeepArchives.
    # PowerShell switches conventionally default $false; `[switch]$KeepArchives = $true`
    # was non-conventional and required the `-KeepArchives:$false` syntax to opt out.
    # Existing callers using that syntax continue to work (bool accepts :$false).
    [bool]$KeepArchives = $true,
    [switch]$AggressiveCleanup
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

# C-4 fix 2026-04-21: Default noise list NEVER includes extensions that may contain
# legitimate user data. Aggressive list (gated by -AggressiveCleanup) adds:
#   .bak / .old (commonly safety renames + legitimate user backups like .pst.bak)
#   .lnk / .url (often the only pointer to an app install on an archive)
#   .etl / .evtx (user forensics data — may be intentionally archived)
$noiseExtensions = @(
    '.dll', '.sys', '.drv', '.ocx', '.cpl',           # System libraries
    '.msi', '.msp', '.msu', '.msm',                   # Installers
    '.esd', '.wim', '.swm',                            # Windows images
    '.cab', '.cat',                                     # Cabinet files
    '.nupkg', '.whl',                                   # Package managers
    '.pdb', '.ilk', '.obj', '.lib', '.exp',            # Debug/build artifacts
    '.partial',                                         # Incomplete downloads
    '.vdi', '.vhdx', '.vmdk', '.vhd',                  # Virtual disks
    '.tmp', '.temp'                                     # Temp files
)
if ($AggressiveCleanup) {
    $noiseExtensions += @(
        '.bak', '.old',           # Backup/safety-rename — legitimate user data possible
        '.lnk', '.url',           # Shortcuts — may be only app-install pointer
        '.etl', '.evtx'           # Event logs — forensics data, may be archived intentionally
    )
    Log "AGGRESSIVE CLEANUP enabled — .bak/.old/.lnk/.url/.etl/.evtx now in noise list" -Level Warn
}

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

# C-4 fix 2026-04-21: write manifest BEFORE deletion for post-run recovery.
# Manifest captures FullName + Length + LastWriteTime + Extension so a robocopy-offload
# of the archive tree can be selectively restored. Manifest is written in BOTH DryRun
# and live mode — DryRun manifest documents what WOULD be deleted.
$manifestPath = Join-Path $logDir "CleanNoise_Manifest_${timestamp}.jsonl"
try {
    $sw = [System.IO.StreamWriter]::new($manifestPath, $false, [System.Text.Encoding]::UTF8)
    foreach ($f in $noiseFiles) {
        $entry = [ordered]@{
            FullName = $f.FullName
            Length = $f.Length
            LastWriteTime = $f.LastWriteTime.ToString('o')
            Extension = $f.Extension.ToLower()
        }
        $sw.WriteLine(($entry | ConvertTo-Json -Compress -Depth 4))
    }
    $sw.Close()
    Log "Pre-deletion manifest written: $manifestPath ($($noiseFiles.Count) entries)" -Level Success
} catch {
    Log "Manifest write FAILED: $_ — aborting before deletion" -Level Error
    if (-not $DryRun) { exit 1 }
}

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
    $emptySkippedEnumFail = 0
    # H-4 fix 2026-04-21: surface enumeration failures instead of silently treating
    # them as empty. Get-ChildItem -Force on an ACL-protected dir or a path-too-long
    # dir returns an empty collection without raising an error; the prior code then
    # treated empty as "safely deletable" → removing the dir header lost the MFT
    # pointer to still-present children (orphaned files). Use
    # [System.IO.Directory]::EnumerateFileSystemEntries which throws on enumeration
    # failure; only delete when enumeration completes cleanly AND returns zero entries.
    Get-ChildItem $TargetPath -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Sort-Object { $_.FullName.Length } -Descending |
        ForEach-Object {
            $dir = $_.FullName
            $reallyEmpty = $false
            try {
                $iter = [System.IO.Directory]::EnumerateFileSystemEntries($dir)
                $reallyEmpty = -not $iter.GetEnumerator().MoveNext()
            } catch {
                # Enumeration failed (ACL-protected, path-too-long, or transient I/O).
                # Refuse to delete — false-empty would orphan children.
                $emptySkippedEnumFail++
                Log "  SKIP (enumeration failed, dir NOT deleted): $dir — $($_.Exception.Message)" -Level Warn
                return
            }
            if ($reallyEmpty) {
                try {
                    Remove-Item $dir -Force -ErrorAction Stop
                    $emptyRemoved++
                } catch { }
            }
        }
    Log "Removed $emptyRemoved empty directories ($emptySkippedEnumFail skipped due to enumeration failure)" -Level Success
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
