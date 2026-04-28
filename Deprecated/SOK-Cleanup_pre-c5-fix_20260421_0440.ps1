<#
.SYNOPSIS
    SOK-Cleanup.ps1 — Targeted cleanup and offload based on SpaceAudit findings.

.DESCRIPTION
    Executes specific space recovery actions identified by SpaceAudit:
    1. Kills processes that hold file locks (Temp, Chrome, Claude, etc.)
    2. Deletes safe-to-clean temp/cache directories
    3. Offloads identified directories to E:\SOK_Offload with NTFS junctions
    4. Cleans stale root-level installs

    Based on 19Mar2026 SpaceAudit run + manual review.

.PARAMETER DryRun
    Preview all actions without executing.

.PARAMETER ExternalDrive
    Target drive for offloads. Default: E:

.NOTES
    Author: S. Clay Caddell
    Version: 1.0.0
    Date: 19Mar2026
    Domain: PRESENT — purges caches and temp; offloads identified dirs to E: with junctions
    REQUIRES: Administrator (junctions, process termination)
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$ExternalDrive = 'E:'
)

#Requires -Version 7.0
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog {
        param([string]$Message, [string]$Level = 'Ignore')
        $color = switch ($Level) {
            'Error' { 'Red' } 'Warn' { 'Yellow' } 'Annotate' { 'DarkCyan' }
            'Success' { 'Green' } 'Debug' { 'DarkGray' } 'Section' { 'Magenta' }
            default { 'Cyan' }
        }
        if ($Level -eq 'Section') { Write-Host "`n━━━ $Message ━━━" -ForegroundColor Magenta }
        else { Write-Host "[$(Get-Date -Format 'ddMMMyyyy HH:mm:ss')] [$($Level.ToUpper().PadRight(8))] $Message" -ForegroundColor $color }
    }
    function Get-HumanSize {
        param([double]$Bytes)
        if ($Bytes -ge 1GB) { return "$([math]::Round($Bytes/1GB, 2)) GB" }
        if ($Bytes -ge 1MB) { return "$([math]::Round($Bytes/1MB, 2)) MB" }
        return "$([math]::Round($Bytes/1KB, 2)) KB"
    }
}

$startTime = Get-Date

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-Cleanup'
}

# ── SYSTEM-CONTEXT PATH RESOLUTION ──
if ($env:USERPROFILE -like '*systemprofile*') {
    $env:USERPROFILE  = 'C:\Users\shelc'
    $env:LOCALAPPDATA = 'C:\Users\shelc\AppData\Local'
    $env:APPDATA      = 'C:\Users\shelc\AppData\Roaming'
    Write-SOKLog '[SYSTEM-CONTEXT] Remapped profile env vars to C:\Users\shelc' -Level Warn
}

Write-SOKLog "SOK-Cleanup — $(if($DryRun){'DRY RUN'}else{'LIVE'}) — $(Get-Date -Format 'ddMMMyyyy HH:mm')" -Level Section

# Normalize drive letter
$ExternalDrive = $ExternalDrive.TrimEnd('\', '/')
if ($ExternalDrive -notmatch '^[A-Z]:$') {
    if ($ExternalDrive -match '^([A-Za-z]):?') { $ExternalDrive = "$($Matches[1].ToUpper()):" }
    else { Write-SOKLog "Invalid drive: $ExternalDrive" -Level Error; exit 1 }
}

$offloadRoot = if ($ExternalDrive) { Join-Path $ExternalDrive 'SOK_Offload' } else { $null }
$movedCount = 0; $movedKB = 0; $deletedCount = 0; $deletedKB = 0; $failedCount = 0

# ═══════════════════════════════════════════════════════════════
# PHASE 1: KILL LOCK-HOLDING PROCESSES
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PHASE 1: RELEASING FILE LOCKS' -Level Section

$processesToKill = @(
    @{ Name = 'chrome';        Label = 'Google Chrome' }
    @{ Name = 'msedge';        Label = 'Microsoft Edge' }
    @{ Name = 'Claude';        Label = 'Claude Desktop' }
    @{ Name = 'Slack';         Label = 'Slack' }
    @{ Name = 'Discord';       Label = 'Discord' }
    @{ Name = 'GitKraken';     Label = 'GitKraken' }
    @{ Name = 'Cypress';       Label = 'Cypress' }
    @{ Name = 'Insomnia';      Label = 'Insomnia' }
    @{ Name = 'Outlook';       Label = 'Outlook' }
    @{ Name = 'AcroCEF';       Label = 'Acrobat CEF' }
    @{ Name = 'Acrobat';       Label = 'Acrobat' }
)

foreach ($proc in $processesToKill) {
    $running = Get-Process -Name $proc.Name -ErrorAction SilentlyContinue
    if ($running) {
        if ($DryRun) {
            Write-SOKLog "[DRY] Would stop: $($proc.Label) ($($running.Count) processes)" -Level Ignore
        }
        else {
            Write-SOKLog "Stopping: $($proc.Label) ($($running.Count) processes)" -Level Warn
            $running | Stop-Process -Force -ErrorAction Continue
            Start-Sleep -Milliseconds 500
        }
    }
    else {
        Write-SOKLog "Not running: $($proc.Label)" -Level Debug
    }
}

# Wait for file handles to release
if (-not $DryRun) {
    Write-SOKLog "Waiting 3s for file handles to release..." -Level Ignore
    Start-Sleep -Seconds 3
}

# ═══════════════════════════════════════════════════════════════
# PHASE 2: DELETE SAFE-TO-CLEAN
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PHASE 2: DELETING CACHES AND TEMP' -Level Section

$toDelete = @(
    @{ Path = "$env:TEMP";                                                            Label = 'Windows Temp' }
    @{ Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache";         Label = 'Chrome Code Cache' }
    @{ Path = "$env:USERPROFILE\.cache";                                              Label = 'User .cache directory' }
    @{ Path = "$env:APPDATA\Claude\Code Cache";                                       Label = 'Claude Desktop Code Cache' }
    @{ Path = "$env:APPDATA\Claude\Cache";                                            Label = 'Claude Desktop Cache' }
    @{ Path = "$env:LOCALAPPDATA\Microsoft\Edge Dev\User Data\Default\Code Cache";    Label = 'Edge Dev Code Cache' }
    @{ Path = "$env:APPDATA\Slack\Cache";                                             Label = 'Slack Cache' }
    @{ Path = "$env:APPDATA\discord\Cache";                                           Label = 'Discord Cache' }
    # EXCLUDED: Outlook Web Cache -- causes full re-login + mailbox re-sync
    # EXCLUDED: Spotify Storage -- causes session loss requiring re-login
    @{ Path = "$env:LOCALAPPDATA\Adobe\AcroCef\DC\Acrobat\Cache";                     Label = 'Acrobat CEF Cache' }
    @{ Path = "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache";              Label = 'RDP bitmap cache' }
    @{ Path = "$env:LOCALAPPDATA\Cypress\Cache";                                      Label = 'Cypress test cache' }
)

foreach ($item in $toDelete) {
    if (-not (Test-Path $item.Path)) {
        Write-SOKLog "  NOT FOUND: $($item.Label) — $($item.Path)" -Level Debug
        continue
    }

    $sizeKB = try {
        $bytes = ([System.IO.Directory]::EnumerateFiles($item.Path, '*',
            [System.IO.SearchOption]::AllDirectories) |
            ForEach-Object { try { ([System.IO.FileInfo]::new($_)).Length } catch { 0 } } |
            Measure-Object -Sum).Sum
        [math]::Round($bytes / 1KB, 0)
    } catch { 0 }

    if ($DryRun) {
        Write-SOKLog "[DRY] Would delete: $($item.Label) — $sizeKB KB" -Level Ignore
        $deletedCount++; $deletedKB += $sizeKB
    }
    else {
        Write-SOKLog "Deleting: $($item.Label) — $sizeKB KB" -Level Ignore
        try {
            # Delete contents, not the directory itself (some apps expect the dir to exist)
            Get-ChildItem -Path $item.Path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-SOKLog "  Cleaned: $($item.Label)" -Level Success
            $deletedCount++; $deletedKB += $sizeKB
        }
        catch {
            Write-SOKLog "  Partial: $($item.Label) — $($_.Exception.Message)" -Level Warn
            $deletedCount++; $deletedKB += ($sizeKB / 2)  # Estimate partial
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# PHASE 3: OFFLOAD TO E: WITH JUNCTIONS
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PHASE 3: OFFLOADING TO E:' -Level Section

$toOffload = @(
    # Large discovered items from SpaceAudit
    @{ Path = 'C:\Program Files\JetBrains';                              Label = 'JetBrains IDEs (full install)' }
    @{ Path = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages";             Label = 'WinGet packages' }
    @{ Path = "$env:USERPROFILE\scoop\persist\rustup\.cargo\registry";   Label = 'Scoop Cargo registry (2nd)' }
    @{ Path = 'C:\tools\flutter';                                        Label = 'Flutter SDK' }

    # Stale root-level installs → offload (not delete, in case needed later)
    @{ Path = 'C:\Hadoop';                                               Label = 'Hadoop (113d stale)' }
    @{ Path = 'C:\Strawberry';                                           Label = 'Strawberry Perl (114d stale)' }
    @{ Path = 'C:\influxdata';                                           Label = 'InfluxDB (114d stale)' }
    @{ Path = 'C:\vcpkg';                                                Label = 'vcpkg C++ pkgmgr (114d stale)' }
    @{ Path = 'C:\gitlab-runner';                                        Label = 'GitLab Runner (96d stale)' }
    @{ Path = 'C:\Squid';                                                Label = 'Squid proxy (113d stale)' }
    @{ Path = 'C:\CocosDashboard';                                       Label = 'Cocos Dashboard (22d)' }
)

if (-not $DryRun -and -not (Test-Path $offloadRoot)) {
    New-Item -Path $offloadRoot -ItemType Directory -Force | Out-Null
}

foreach ($item in $toOffload) {
    if (-not (Test-Path $item.Path)) {
        Write-SOKLog "  NOT FOUND: $($item.Label) — $($item.Path)" -Level Debug
        continue
    }

    # Skip if already a junction
    $dirInfo = Get-Item $item.Path -Force -ErrorAction Continue
    if ($dirInfo -and ($dirInfo.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        Write-SOKLog "  ALREADY JUNCTION: $($item.Label)" -Level Annotate
        continue
    }

    $sizeKB = try {
        $opts = [System.IO.EnumerationOptions]::new()
        $opts.RecurseSubdirectories = $true
        $opts.IgnoreInaccessible = $true
        $opts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint -bor [System.IO.FileAttributes]::System
        $total = [long]0
        foreach ($fi in [System.IO.Directory]::EnumerateFiles($item.Path, '*', $opts)) {
            try { $total += ([System.IO.FileInfo]::new($fi)).Length } catch { }
        }
        [math]::Round($total / 1KB, 0)
    } catch { 0 }

    $relative = $item.Path -replace '^([A-Z]):', '$1' -replace '\\', '_'
    $destPath = Join-Path $offloadRoot $relative

    if ($DryRun) {
        Write-SOKLog "[DRY] Would offload: $($item.Label) — $sizeKB KB" -Level Ignore
        Write-SOKLog "  $($item.Path) → $destPath" -Level Debug
        $movedCount++; $movedKB += $sizeKB
        continue
    }

    Write-SOKLog "Offloading: $($item.Label) — $sizeKB KB" -Level Ignore
    Write-SOKLog "  $($item.Path) → $destPath" -Level Debug

    try {
        if (-not (Test-Path $destPath)) { New-Item -Path $destPath -ItemType Directory -Force | Out-Null }

        $roboArgs = @(
            $item.Path, $destPath
            '/E', '/MOVE', '/R:3', '/W:5', '/MT:8', '/XJ'
            '/COPY:DAT', '/DCOPY:T', '/NFL', '/NDL', '/NP'
        )

        $roboOutput = & robocopy @roboArgs 2>&1
        $roboExit = $LASTEXITCODE

        if ($roboExit -lt 8) {
            Write-SOKLog "  Robocopy OK (exit: $roboExit)" -Level Success

            # Create junction
            if (Test-Path $item.Path) {
                Remove-Item -Path $item.Path -Recurse -Force -ErrorAction SilentlyContinue
            }
            if (-not (Test-Path $item.Path)) {
                $jResult = cmd /c "mklink /J `"$($item.Path)`" `"$destPath`"" 2>&1
                if (Test-Path $item.Path) {
                    Write-SOKLog "  Junction: $($item.Path) → $destPath" -Level Success
                }
                else {
                    Write-SOKLog "  Junction FAILED" -Level Error
                }
            }
            else {
                Write-SOKLog "  Source not fully removed — junction skipped" -Level Warn
            }

            $movedCount++; $movedKB += $sizeKB
        }
        else {
            Write-SOKLog "  Robocopy FAILED (exit: $roboExit)" -Level Error
            $failedCount++
        }
    }
    catch {
        Write-SOKLog "  EXCEPTION: $($_.Exception.Message)" -Level Error
        $failedCount++
    }
}

# ═══════════════════════════════════════════════════════════════
# PHASE 4: STALE ROOT CLEANUP (items too small to junction, just delete)
# ═══════════════════════════════════════════════════════════════
# (All stale root items are being offloaded in Phase 3 instead of deleted,
#  preserving them on E: in case they're needed later.)

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)

# Check new drive state
$cDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction SilentlyContinue
$newFreeKB = if ($cDisk) { [math]::Round($cDisk.FreeSpace / 1KB, 0) } else { 0 }
$newUsedPct = if ($cDisk -and $cDisk.Size -gt 0) {
    [math]::Round((($cDisk.Size - $cDisk.FreeSpace) / $cDisk.Size) * 100, 1)
} else { 'N/A' }

Write-SOKLog 'RESULTS' -Level Section
Write-SOKLog "  Deleted:    $deletedCount items, $deletedKB KB" -Level Success
Write-SOKLog "  Offloaded:  $movedCount items, $movedKB KB" -Level Success
Write-SOKLog "  Failed:     $failedCount" -Level $(if ($failedCount -gt 0) { 'Error' } else { 'Success' })
Write-SOKLog "  C: now:     $newFreeKB KB free ($newUsedPct% used)" -Level Ignore
Write-SOKLog "  Duration:   ${duration}s" -Level Ignore
Write-SOKLog "  DryRun:     $($DryRun.IsPresent)" -Level Ignore
