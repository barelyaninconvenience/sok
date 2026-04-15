<#
.SYNOPSIS
    SOK-BackupRestructure v2.0.0 — Delete raw trees, extract .7z in-place, merge with derivation tagging.
.DESCRIPTION
    PHASE 1: Delete raw extracted folders (robocopy /MIR /B fast-delete, then fallback parallel takeown).
             SKIPPED BY DEFAULT — most destructive phase. Requires explicit -RunPhase1 to activate.
    PHASE 2: Extract each .7z in-place (overwrite+append via 7z x -aoa).
    PHASE 3: Merge all source dirs into MergeTarget with derivation suffix on collision.

    Derivation tags (overlapping name resolution):
      2020 Seagate 1 Backup             → _a1
      2020 Seagate 2 Backup             → _a2
      2025                              → _b
      13JUL2025                         → _c
      mommaddell backup CAO 06JUN2025   → _d

    v2.0.0 changes:
    - BREAKING: Phase 1 now requires explicit -RunPhase1 (was opt-out; now opt-in — safest default)
    - ADD: SOK-Common integration (Write-SOKLog, Initialize-SOKLog, Save-SOKHistory)
    - ADD: -SkipPhase3 parameter (was missing; now consistent with -SkipPhase1/-SkipPhase2)
    - ADD: -ForceConfirm flag — suppresses all interactive prompts (for scripted/pipeline use)
    - FIX: $diskBeforeKB now captured at script START (was incorrectly computed from end-state values)
    - FIX: All size metrics in KB (was GB; now KB per project standard)
    - FIX: Phase 3 post-move verification — confirms item exists at dest, reports failures
    - OPT: Phase 3 parallel move where no collision (PS7 ForEach-Object -Parallel, ThrottleLimit 13)
    - OPT: Archive sizes sorted ascending before Phase 2 (extract small first to create space headroom)

.PARAMETER ArchiveRoot
    Root of backup archives. Default: E:\Backup_Archive
.PARAMETER MergeTarget
    Merge destination. Default: E:\Backup_Merged
.PARAMETER RunPhase1
    Activate Phase 1 (delete raw folders). SKIPPED BY DEFAULT. Always run -DryRun first.
.PARAMETER SkipPhase2
    Skip Phase 2 (.7z extraction).
.PARAMETER SkipPhase3
    Skip Phase 3 (merge with derivation tagging).
.PARAMETER DryRun
    Preview all phases. No disk mutations.
.PARAMETER ForceConfirm
    Suppress all interactive Y/N prompts (assumes Y). Useful in scripted/pipeline contexts.
    Has no effect during -DryRun.
.NOTES
    REQUIRES: Administrator, 7-Zip
    Author: S. Clay Caddell
    Version: 2.0.0
    Date: 02Apr2026
    Domain: PAST — extracts and merges historical backup archives; resolves derivation collisions
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$ArchiveRoot    = 'E:\Backup_Archive',
    [string]$MergeTarget    = 'E:\Backup_Merged',
    [switch]$RunPhase1,      # OPT-IN: Phase 1 (delete raw) — most destructive
    [switch]$SkipPhase2,
    [switch]$SkipPhase3,
    [switch]$DryRun,
    [switch]$ForceConfirm,   # Suppress interactive prompts (assume Y)
    [int]$ThrottleLimit      = 13
)

$ErrorActionPreference = 'Continue'
$StartTime = Get-Date

#region ── SOK-Common ─────────────────────────────────────────────────────────
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    # Minimal fallback so script runs without Common
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
    function Initialize-SOKLog { param([string]$ScriptName) return $null }
    function Save-SOKHistory { param([string]$ScriptName, [hashtable]$RunData) }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) Write-Host "$ScriptName — $Subheader" }
}
$logPath = Initialize-SOKLog -ScriptName 'SOK-BackupRestructure'
$phases  = if ($RunPhase1) { '1+2+3' } else { '2+3' }
$phases  = if ($SkipPhase2) { $phases -replace '2\+','' } else { $phases }
$phases  = if ($SkipPhase3) { $phases -replace '\+3','' } else { $phases }
Show-SOKBanner -ScriptName 'SOK-BackupRestructure' `
    -Subheader "Phases: $phases$(if($DryRun){' [DRY RUN]'})$(if($ForceConfirm){' [FORCE]'})"
#endregion

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-BackupRestructure'
}

#region ── Pre-flight ─────────────────────────────────────────────────────────
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
    Write-SOKLog 'Must run as Administrator' -Level Error; exit 1
}
$7z = @('C:\Program Files\7-Zip\7z.exe','C:\Program Files (x86)\7-Zip\7z.exe') |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $7z) { Write-SOKLog '7-Zip not found at expected paths' -Level Error; exit 1 }

$driveLetter = ($ArchiveRoot -split '\\')[0]  # e.g. "E:"

# FIX: capture disk free at script START (previous version re-queried at end, giving wrong delta)
function Get-FreeKB {
    [long]([math]::Round(
        (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$driveLetter'" -ErrorAction SilentlyContinue).FreeSpace / 1KB, 0
    ))
}
$diskBeforeKB = Get-FreeKB
Write-SOKLog "Pre-flight: $driveLetter free at start: ${diskBeforeKB} KB" -Level Ignore

if (-not (Test-Path $ArchiveRoot)) {
    if ($DryRun) {
        Write-SOKLog "[DRY] ArchiveRoot not present: $ArchiveRoot (target drive offline) — preview exits cleanly" -Level Warn
        exit 0
    }
    Write-SOKLog "ArchiveRoot not found: $ArchiveRoot" -Level Error; exit 1
}
#endregion

#region ── Derivation map ─────────────────────────────────────────────────────
$derivationMap = [ordered]@{
    '2020 Seagate 1 Backup'           = '_a1'
    '2020 Seagate 2 Backup'           = '_a2'
    '2025'                            = '_b'
    '13JUL2025'                       = '_c'
    'mommaddell backup CAO 06JUN2025' = '_d'
}
#endregion

#region ── Helpers ────────────────────────────────────────────────────────────
function Confirm-Step {
    param([string]$Prompt)
    if ($DryRun -or $ForceConfirm) { return $true }
    $r = Read-Host "$Prompt [Y/N/Q]"
    if ($r -match '^[Qq]') { Write-SOKLog 'Operator abort.' -Level Warn; exit 0 }
    return ($r -match '^[Yy]')
}

# Fast-delete via robocopy /MIR /B then parallel takeown fallback.
# /B = backup-privilege mode, bypasses ACL locks (2020-era Seagate ACL artifacts).
function Invoke-FastDelete {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) { Write-SOKLog "SKIP delete (already gone): $Label" -Level Ignore; return }
    Write-SOKLog "Deleting: $Label ($Path)" -Level Warn
    $emptyDir = Join-Path $env:TEMP "SOK_Empty_$(Get-Random)"
    New-Item -Path $emptyDir -ItemType Directory -Force | Out-Null
    try {
        $t = Get-Date
        & robocopy $emptyDir $Path /MIR /B /R:0 /W:0 /MT:$ThrottleLimit /NFL /NDL /NP /NJH /NJS 2>&1 | Out-Null
        $exit = $LASTEXITCODE
        Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
        $durS = [math]::Round(((Get-Date)-$t).TotalSeconds,1)
        if (-not (Test-Path $Path)) {
            Write-SOKLog "Deleted ${Label} in ${durS}s (robocopy exit $exit)" -Level Success
        } else {
            # Parallel takeown fallback for ACL-locked survivors
            Write-SOKLog "robocopy incomplete (${durS}s exit $exit) — parallel takeown fallback..." -Level Warn
            $items = @(Get-ChildItem $Path -Force -ErrorAction SilentlyContinue)
            $items | ForEach-Object -Parallel {
                $p = $_.FullName
                & takeown /F $p /R /A /D Y 2>&1 | Out-Null
                & icacls $p /grant "BUILTIN\Administrators:(OI)(CI)F" /T /C /Q 2>&1 | Out-Null
                if ((Get-Item $p -Force -ErrorAction SilentlyContinue)?.PSIsContainer) {
                    & cmd /c "rd /s /q `"$p`"" 2>&1 | Out-Null
                } else { Remove-Item $p -Force -ErrorAction SilentlyContinue }
            } -ThrottleLimit $ThrottleLimit
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
            $dur2 = [math]::Round(((Get-Date)-$t).TotalSeconds,1)
            if (-not (Test-Path $Path)) {
                Write-SOKLog "Fallback delete succeeded (${dur2}s total)" -Level Success
            } else {
                Write-SOKLog "WARNING: Residual files remain in $Path — manual review required" -Level Warn
            }
        }
    } finally { Remove-Item $emptyDir -Force -ErrorAction SilentlyContinue }
}
#endregion

# ═══════════════════════════════════════════════════════════════
# PHASE 1: DELETE RAW EXTRACTED FOLDERS (OPT-IN)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog '━━━ PHASE 1: DELETE RAW FOLDERS ━━━' -Level Section
if (-not $RunPhase1) {
    # Safety: Phase 1 is opt-in. Require explicit -RunPhase1 flag.
    Write-SOKLog 'Phase 1 SKIPPED (requires explicit -RunPhase1 flag). This is the safest default.' -Level Warn
    Write-SOKLog 'To delete raw pre-extracted folders: re-run with -RunPhase1 -DryRun first, then without -DryRun.' -Level Warn
} else {
    if ($DryRun) { Write-SOKLog '*** DRY RUN — no deletions ***' -Level Warn }
    $deleteAll = $false
    foreach ($name in $derivationMap.Keys) {
        $rawPath = Join-Path $ArchiveRoot $name
        if (-not (Test-Path $rawPath)) { Write-SOKLog "SKIP (not found): $name" -Level Ignore; continue }
        if ($DryRun) { Write-SOKLog "[DRY] Would delete: $rawPath" -Level Warn; continue }
        if (-not $deleteAll -and -not $ForceConfirm) {
            $r = Read-Host "Delete raw '$name'? [Y/N/A(ll)/Q]"
            if ($r -match '^[Qq]') { Write-SOKLog 'Phase 1 aborted by operator.' -Level Warn; break }
            if ($r -match '^[Aa]') { $deleteAll = $true }
            if ($r -notmatch '^[YyAa]') { Write-SOKLog "Skipped: $name" -Level Ignore; continue }
        }
        Invoke-FastDelete -Path $rawPath -Label $name
        Write-SOKLog "$driveLetter free after deletion: $(Get-FreeKB) KB" -Level Ignore
    }
}

# ═══════════════════════════════════════════════════════════════
# PHASE 2: EXTRACT .7z IN-PLACE
# ═══════════════════════════════════════════════════════════════
Write-SOKLog '━━━ PHASE 2: EXTRACT .7z IN-PLACE ━━━' -Level Section
$p2Extracted = 0; $p2Failed = 0
if ($SkipPhase2) {
    Write-SOKLog 'Phase 2 skipped (-SkipPhase2)' -Level Warn
} else {
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }
    # Sort ascending by size: extract small archives first to create space headroom for large ones.
    $archives = Get-ChildItem $ArchiveRoot -Filter '*.7z' -File -ErrorAction SilentlyContinue |
        Sort-Object Length
    if (-not $archives -or $archives.Count -eq 0) {
        Write-SOKLog "No .7z files found in $ArchiveRoot" -Level Warn
    } else {
        Write-SOKLog "Found $($archives.Count) archives (smallest first):" -Level Ignore
        foreach ($a in $archives) {
            $sizeKB = [math]::Round($a.Length / 1KB, 0)
            Write-SOKLog "  $($a.Name) — ${sizeKB} KB" -Level Ignore
        }

        foreach ($archive in $archives) {
            $sizeKB  = [math]::Round($archive.Length / 1KB, 0)
            $freeKB  = Get-FreeKB
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($archive.Name)

            Write-SOKLog "Archive: $($archive.Name) | ${sizeKB} KB | $driveLetter free: ${freeKB} KB" -Level Warn
            if ($freeKB -lt 1048576) {  # <1GB free = 1,048,576 KB
                Write-SOKLog "WARNING: <1 GB (${freeKB} KB) free — extraction may fail. Delete a prior .7z to reclaim space." -Level Warn
            }
            if ($DryRun) { Write-SOKLog "[DRY] Would extract $($archive.Name) with 7z -aoa to $ArchiveRoot" -Level Warn; continue }

            if (-not (Confirm-Step "Extract $($archive.Name) (${sizeKB} KB)?")) {
                Write-SOKLog "Skipped: $($archive.Name)" -Level Ignore; continue
            }

            $t = Get-Date
            $errLines = [System.Collections.Generic.List[string]]::new()
            & $7z x "$($archive.FullName)" -o"$ArchiveRoot" -aoa -y 2>&1 | ForEach-Object {
                $ln = "$_".Trim()
                if ($ln -match 'Everything is Ok') { Write-SOKLog "7z: $ln" -Level Success }
                elseif ($ln -match 'ERROR|Cannot')  { $errLines.Add($ln) }
            }
            $exit = $LASTEXITCODE
            $durS = [math]::Round(((Get-Date)-$t).TotalSeconds,1)

            if ($exit -eq 0) {
                Write-SOKLog "$($archive.Name) extracted in ${durS}s" -Level Success; $p2Extracted++
            } else {
                Write-SOKLog "$($archive.Name) 7z exit $exit (${durS}s) | $($errLines.Count) errors" -Level Warn
                $errLines | Select-Object -First 5 | ForEach-Object { Write-SOKLog "  $_" -Level Error }
                $p2Failed++
            }

            # Offer .7z deletion to free space for next archive
            Write-SOKLog "$driveLetter free after extraction: $(Get-FreeKB) KB" -Level Ignore
            if (Confirm-Step "Delete $($archive.Name) (${sizeKB} KB freed)?") {
                Remove-Item $archive.FullName -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $archive.FullName)) {
                    Write-SOKLog "Deleted $($archive.Name)" -Level Success
                } else { Write-SOKLog "Could not delete $($archive.Name) (may be locked)" -Level Warn }
            }
        }
    }
}
Write-SOKLog "Phase 2 complete: $p2Extracted extracted | $p2Failed failed" `
    -Level $(if($p2Failed -gt 0){'Warn'}else{'Success'})

# ═══════════════════════════════════════════════════════════════
# PHASE 3: MERGE WITH DERIVATION TAGS
# ═══════════════════════════════════════════════════════════════
Write-SOKLog '━━━ PHASE 3: MERGE WITH DERIVATION TAGS ━━━' -Level Section
$p3Moved = 0; $p3Renamed = 0; $p3Failed = 0
if ($SkipPhase3) {
    Write-SOKLog 'Phase 3 skipped (-SkipPhase3)' -Level Warn
} else {
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    # Resolve which source folders actually exist
    $sources = [ordered]@{}
    foreach ($kv in $derivationMap.GetEnumerator()) {
        $p = Join-Path $ArchiveRoot $kv.Key
        if (Test-Path $p) { $sources[$kv.Key] = @{ Path=$p; Tag=$kv.Value } }
        else { Write-SOKLog "MISS: $($kv.Key) — not found in $ArchiveRoot" -Level Ignore }
    }
    Write-SOKLog "Source folders found: $($sources.Count)" -Level Ignore

    if ($sources.Count -eq 0) {
        Write-SOKLog 'No source folders found — Phase 3 skipped.' -Level Warn
    } elseif ($DryRun) {
        Write-SOKLog "[DRY] Would merge $($sources.Count) source(s) into $MergeTarget with derivation tagging" -Level Warn
    } elseif (-not (Confirm-Step "Merge $($sources.Count) source(s) into $MergeTarget?")) {
        Write-SOKLog 'Merge cancelled by operator.' -Level Warn
    } else {
        if (-not (Test-Path $MergeTarget)) { New-Item -Path $MergeTarget -ItemType Directory -Force | Out-Null }
        $mergeStart = Get-Date

        foreach ($kv in $sources.GetEnumerator()) {
            $srcName = $kv.Key; $srcPath = $kv.Value.Path; $tag = $kv.Value.Tag
            Write-SOKLog "Merging: $srcName (tag: $tag)" -Level Section

            $topItems = @(Get-ChildItem $srcPath -Force -ErrorAction SilentlyContinue)
            Write-SOKLog "  $($topItems.Count) top-level items" -Level Ignore

            # Split into collision vs no-collision buckets for parallel vs sequential handling
            $noCollision = [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new()
            $collision   = [System.Collections.Generic.List[System.IO.FileSystemInfo]]::new()
            foreach ($item in $topItems) {
                if (-not (Test-Path (Join-Path $MergeTarget $item.Name))) { $noCollision.Add($item) }
                else { $collision.Add($item) }
            }

            # Parallel move for no-collision items (PS7 runspace; no shared state needed)
            if ($noCollision.Count -gt 0) {
                $noCollision | ForEach-Object -Parallel {
                    $destPath = Join-Path ($using:MergeTarget) $_.Name
                    Move-Item $_.FullName $destPath -Force -ErrorAction SilentlyContinue
                } -ThrottleLimit $ThrottleLimit
                # Verify
                $moved = $noCollision | Where-Object { -not (Test-Path $_.FullName) -and (Test-Path (Join-Path $MergeTarget $_.Name)) }
                $p3Moved += $moved.Count
                $moveFailed = $noCollision | Where-Object { Test-Path $_.FullName }
                $p3Failed += $moveFailed.Count
                if ($moveFailed.Count -gt 0) {
                    $moveFailed | ForEach-Object { Write-SOKLog "  MOVE FAILED: $($_.FullName)" -Level Error }
                }
                Write-SOKLog "  Parallel move: $($moved.Count) moved | $($moveFailed.Count) failed" -Level Ignore
            }

            # Sequential for collision items (need per-item tag suffix + existence check loop)
            foreach ($item in $collision) {
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($item.Name)
                $ext = if ($item.PSIsContainer) { '' } else { $item.Extension }
                $newName = "${baseName}${tag}${ext}"; $newDest = Join-Path $MergeTarget $newName
                $counter = 1
                while (Test-Path $newDest) {
                    $newName = "${baseName}${tag}_${counter}${ext}"; $newDest = Join-Path $MergeTarget $newName; $counter++
                }
                Move-Item $item.FullName $newDest -Force -ErrorAction SilentlyContinue
                # Post-move verification: confirm dest exists AND source is gone
                if ((Test-Path $newDest) -and -not (Test-Path $item.FullName)) {
                    Write-SOKLog "  RENAMED: $($item.Name) → $newName" -Level Ignore; $p3Renamed++
                } elseif (Test-Path $newDest) {
                    Write-SOKLog "  WARN: $($item.Name) → $newName but source still exists (partial?)" -Level Warn; $p3Failed++
                } else {
                    Write-SOKLog "  FAILED: $($item.Name)" -Level Error; $p3Failed++
                }
            }

            # Clean empty source dir
            $remaining = @(Get-ChildItem $srcPath -Force -ErrorAction SilentlyContinue).Count
            if ($remaining -eq 0) {
                Remove-Item $srcPath -Force -ErrorAction SilentlyContinue
                Write-SOKLog "  Source emptied and removed: $srcPath" -Level Success
            } else {
                Write-SOKLog "  $remaining items remain in source (locked/failed): $srcPath" -Level Warn
            }
        }

        $mergeDurS = [math]::Round(((Get-Date)-$mergeStart).TotalSeconds,1)
        Write-SOKLog "Phase 3 complete in ${mergeDurS}s: $p3Moved moved | $p3Renamed renamed (collision) | $p3Failed failed" `
            -Level $(if($p3Failed -gt 0){'Warn'}else{'Success'})
    }
}

# ═══════════════════════════════════════════════════════════════
# FINAL REPORT + HISTORY
# ═══════════════════════════════════════════════════════════════
$totalDurS  = [math]::Round(((Get-Date)-$StartTime).TotalSeconds,1)
$diskAfterKB = Get-FreeKB
$diskDeltaKB = $diskAfterKB - $diskBeforeKB  # positive = space freed, negative = space consumed

Write-SOKLog '━━━ BACKUP RESTRUCTURE COMPLETE ━━━' -Level Section
Write-SOKLog "Duration: ${totalDurS}s" -Level Ignore
Write-SOKLog "$driveLetter free: ${diskBeforeKB} KB → ${diskAfterKB} KB (delta: ${diskDeltaKB} KB)" -Level Ignore
Write-SOKLog "Phase 2: $p2Extracted extracted | $p2Failed failed" -Level Ignore
Write-SOKLog "Phase 3: $p3Moved moved | $p3Renamed renamed | $p3Failed failed" `
    -Level $(if($p3Failed -gt 0){'Warn'}else{'Success'})

if (Test-Path $MergeTarget) {
    $mc = @(Get-ChildItem $MergeTarget -Force -ErrorAction SilentlyContinue)
    Write-SOKLog "MergeTarget contents: $($mc.Where{$_.PSIsContainer}.Count) dirs, $($mc.Where{-not $_.PSIsContainer}.Count) files" -Level Ignore
}

Save-SOKHistory -ScriptName 'SOK-BackupRestructure' -RunData @{
    DryRun       = $DryRun.IsPresent
    Phase1Ran    = $RunPhase1.IsPresent
    P2Extracted  = $p2Extracted
    P2Failed     = $p2Failed
    P3Moved      = $p3Moved
    P3Renamed    = $p3Renamed
    P3Failed     = $p3Failed
    DiskBeforeKB = $diskBeforeKB
    DiskAfterKB  = $diskAfterKB
    DiskDeltaKB  = $diskDeltaKB
    DurationSec  = $totalDurS
}
