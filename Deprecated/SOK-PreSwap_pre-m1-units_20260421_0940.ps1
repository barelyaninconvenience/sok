<#
.SYNOPSIS
    SOK-PreSwap — Maximize C: space before swapping E: for recovery NVMe.
    Throwaway script. Run once, verify, delete.
.DESCRIPTION
    Phase 1: Fix broken junctions (scoop apps, chocolatey lib)
    Phase 2: Kill processes, deep cache purge
    Phase 3: New offloads to E: (items not yet moved)
    Phase 4: Stale program cleanup (safe deletes)
    Phase 5: Report big-ticket user decisions (Documents\Backup, Downloads)
.NOTES
    Author: S. Clay Caddell
    Version: 1.1.0
    Date: 20Mar2026
    Domain: PRESENT — one-shot C: space maximization before physical drive swap; not scheduled
    REQUIRES: Run as Administrator
    Run with -DryRun first!
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$ExternalDrive = 'E:'
)

$ErrorActionPreference = 'Continue'
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else { Write-Host "WARNING: SOK-Common not found, using raw output" -ForegroundColor Yellow }

function Log { param([string]$Msg, [string]$Level = 'Ignore')
    if (Get-Command Write-SOKLog -ErrorAction SilentlyContinue) { Write-SOKLog $Msg -Level $Level }
    else { Write-Host "[$Level] $Msg" }
}

$startTime = Get-Date
$startFreeKB = [math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" ).FreeSpace / 1KB, 0)
Log "C: free at start: $startFreeKB KB" -Level Warn

if ($DryRun) { Log "DRY RUN — no changes will be made" -Level Debug }

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-PreSwap'
}

# ═══════════════════════════════════════════════════
# PHASE 1: FIX BROKEN JUNCTIONS
# ═══════════════════════════════════════════════════
Log " " -Level Section
Log "PHASE 1: FIX BROKEN JUNCTIONS" -Level Section

function Repair-Junction {
    param(
        [string]$Source,
        [string]$Target,
        [string]$Label,
        [switch]$StripInternalJunctions,  # scoop-style: recurse to rmdir internal reparse points
        [switch]$RenameExesFirst          # choco-style: rename .exe to .bak before removal
    )
    $item = Get-Item $Source -ErrorAction SilentlyContinue
    if (-not $item) { Log "$Label`: not found — skipping" -Level Annotate; return }
    if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        Log "$Label`: junction already active" -Level Success; return
    }
    # Real directory that should be a junction
    Log "$Label`: directory exists but is NOT a junction — fixing" -Level Warn
    if ($DryRun) { Log "  [DRY] Would strip + junction $Source → $Target" -Level Debug; return }

    if ($StripInternalJunctions) {
        $ij = Get-ChildItem $Source -Recurse -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReparsePoint }
        foreach ($j in $ij) { cmd /c "rmdir `"$($j.FullName)`"" 2>$null }
        Log "  Stripped $($ij.Count) internal junctions" -Level Success
    }
    if ($RenameExesFirst) {
        Get-ChildItem $Source -Recurse -File -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -eq '.exe' } |
            ForEach-Object { try { Rename-Item $_.FullName "$($_.Name).bak" -Force -ErrorAction Stop } catch {} }
    }
    # C-3 fix 2026-04-21: substrate-recovery data-loss prevention.
    # Old behavior: Remove-Item $Source ran BEFORE mklink. If E: target was missing
    # or mklink failed for any reason (permissions, path quirks), the source was
    # already gone with no recovery. On the substrate-recovery critical path, this
    # left a system with the source destroyed AND no junction.
    # New behavior: pre-validate target exists; rename source to .bak (atomic;
    # preserves data); attempt mklink; on success delete .bak; on failure restore
    # source from .bak. Net result: no data loss possible from junction failures.
    if (-not (Test-Path $Target)) {
        Log "  E: target not found: $Target — ABORT (source preserved)" -Level Error
        return
    }
    $backup = "${Source}.preswap_bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    try {
        Rename-Item -Path $Source -NewName $backup -Force -ErrorAction Stop
    } catch {
        Log "  Rename to backup failed: $_ — ABORT (source preserved)" -Level Error
        return
    }
    cmd /c "mklink /J `"$Source`" `"$Target`"" 2>$null
    $junctionOk = $false
    $itm = Get-Item $Source -ErrorAction SilentlyContinue
    if ($itm -and ($itm.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
        $junctionOk = $true
    }
    if ($junctionOk) {
        Log "  Junction: $Source → $Target" -Level Success
        # Safe to drop backup — junction is verified active
        try {
            Remove-Item $backup -Recurse -Force -ErrorAction Stop
            Log "  Cleanup: removed pre-junction backup $backup" -Level Debug
        } catch {
            Log "  WARN: junction succeeded but backup cleanup failed at $backup — manual sweep needed: $_" -Level Warn
        }
    } else {
        Log "  Junction creation FAILED — restoring source from backup" -Level Error
        # Drop the failed-junction stub if it exists
        if (Test-Path $Source) {
            try { cmd /c "rmdir `"$Source`"" 2>$null } catch {}
        }
        try {
            Rename-Item -Path $backup -NewName (Split-Path $Source -Leaf) -Force -ErrorAction Stop
            Log "  Source restored from backup at $Source" -Level Success
        } catch {
            Log "  CRITICAL: source restore failed — manual recovery required from $backup → $Source : $_" -Level Error
        }
    }
}

# Data-driven junction repairs — one line each instead of nested if blocks
Repair-Junction -Source 'C:\Users\shelc\scoop\apps'   -Target "$ExternalDrive\SOK_Offload\C_Users_shelc_scoop_apps"   -Label 'Scoop apps' -StripInternalJunctions
Repair-Junction -Source 'C:\ProgramData\chocolatey\lib' -Target "$ExternalDrive\SOK_Offload\C_ProgramData_chocolatey_lib" -Label 'Choco lib' -RenameExesFirst

# ═══════════════════════════════════════════════════
# PHASE 2: DEEP CACHE PURGE (aggressive)
# ═══════════════════════════════════════════════════
Log " " -Level Section
Log "PHASE 2: DEEP CACHE PURGE" -Level Section

# Kill apps that hold caches
$killTargets = @('chrome','msedge','Slack','Discord','GitKraken',
    'Cypress','Insomnia','AcroCEF','Acrobat','Logseq','Postman',
    'balena_etcher','signal','Bitwarden','GitHubDesktop','Zoom','Teams',
    'obs64','obs32','Code','Grammarly','Kindle')
    # EXCLUDED: Claude (bricking), Spotify (session loss), Outlook (re-login + re-sync)
foreach ($proc in $killTargets) {
    $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
    if ($running -and -not $DryRun) {
        $running | Stop-Process -Force -ErrorAction Continue
        Log "Stopped: $proc ($($running.Count) processes)" -Level Warn
    }
}
if (-not $DryRun) { Start-Sleep -Seconds 3 }

# Expanded cache targets (beyond what Cleanup/Maintenance hit)
$cachePaths = @(
    @{ Name = 'Windows Temp';           Path = "$env:TEMP" }
    @{ Name = 'System Temp';            Path = "$env:WINDIR\Temp" }
    @{ Name = 'User .cache';            Path = "$env:USERPROFILE\.cache" }
    @{ Name = 'Chrome Code Cache';      Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache" }
    @{ Name = 'Chrome GPU Cache';       Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\GPUCache" }
    @{ Name = 'Chrome Service Worker';  Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Service Worker\CacheStorage" }
    @{ Name = 'Edge Code Cache';        Path = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache" }
    @{ Name = 'Edge Dev Cache';         Path = "$env:LOCALAPPDATA\Microsoft\Edge Dev\User Data\Default\Cache" }
    @{ Name = 'Edge Dev Code Cache';    Path = "$env:LOCALAPPDATA\Microsoft\Edge Dev\User Data\Default\Code Cache" }
    # Claude caches EXCLUDED -- bricking risk
    @{ Name = 'Slack Code Cache';       Path = "$env:APPDATA\Slack\Code Cache" }
    @{ Name = 'Slack Cache';            Path = "$env:APPDATA\Slack\Cache" }
    @{ Name = 'Discord Cache';          Path = "$env:APPDATA\discord\Cache" }
    @{ Name = 'Discord Code Cache';     Path = "$env:APPDATA\discord\Code Cache" }
    # Outlook Web Cache EXCLUDED -- causes re-login + full mailbox re-sync
    @{ Name = 'Office Wef Cache';       Path = "$env:LOCALAPPDATA\Microsoft\Office\16.0\Wef" }
    @{ Name = 'Acrobat CEF Cache';      Path = "$env:LOCALAPPDATA\Adobe\AcroCef" }
    @{ Name = 'RDP Bitmap Cache';       Path = "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache" }
    @{ Name = 'D3D Shader Cache';       Path = "$env:LOCALAPPDATA\D3DSCache" }
    @{ Name = 'Intel Shader Cache';     Path = "$env:LOCALAPPDATA\..\LocalLow\Intel\ShaderCache" }
    @{ Name = 'Crash Dumps';            Path = "$env:LOCALAPPDATA\CrashDumps" }
    @{ Name = 'pip Cache';              Path = "$env:LOCALAPPDATA\pip\cache" }
    @{ Name = 'npm Cache';              Path = "$env:LOCALAPPDATA\npm-cache" }
    @{ Name = 'node-gyp Cache';         Path = "$env:LOCALAPPDATA\node-gyp\Cache" }
    @{ Name = 'NuGet HTTP Cache';       Path = "$env:LOCALAPPDATA\NuGet\v3-cache" }
    @{ Name = 'Roslyn Cache';           Path = "$env:LOCALAPPDATA\Microsoft\VisualStudio\Roslyn\Cache" }
    @{ Name = 'VS Packages';            Path = "$env:LOCALAPPDATA\Microsoft\VisualStudio\Packages" }
    @{ Name = 'Logseq Cache';           Path = "$env:LOCALAPPDATA\Logseq\Cache" }
    @{ Name = 'GitKraken Cache';        Path = "$env:LOCALAPPDATA\gitkraken\Cache" }
    @{ Name = 'Postman Cache';          Path = "$env:LOCALAPPDATA\Postman\Cache" }
    @{ Name = 'Kindle Cache';           Path = "$env:LOCALAPPDATA\Amazon\Kindle\Cache" }
    @{ Name = 'Zoom Cache';             Path = "$env:APPDATA\Zoom\data" }
    @{ Name = 'Grammarly Cache';        Path = "$env:APPDATA\Grammarly\DesktopIntegrations\WebViewUserDataFolder\EBWebView\Default\Code Cache" }
    @{ Name = 'Maltego Cache';          Path = "$env:APPDATA\maltego\v4.10.1\var\cache" }
    @{ Name = 'msys2 Cache';            Path = 'C:\msys64\var\cache' }
    @{ Name = 'Cypress Cache';          Path = "$env:LOCALAPPDATA\Cypress\Cache" }
)

$totalCleaned = 0
foreach ($c in $cachePaths) {
    if (-not (Test-Path $c.Path)) { continue }
    $sizeKB = 0
    try {
        $sizeKB = (Get-ChildItem $c.Path -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum / 1KB
    } catch { }
    if ($sizeKB -lt 100) { continue }  # Skip tiny ones

    $sizeHuman = if ($sizeKB -gt 1MB) { "$([math]::Round($sizeKB/1MB, 2)) GB" }
                 elseif ($sizeKB -gt 1KB) { "$([math]::Round($sizeKB/1KB, 2)) MB" }
                 else { "$([math]::Round($sizeKB, 0)) KB" }

    if (-not $DryRun) {
        Get-ChildItem $c.Path -Force -ErrorAction Continue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Log "Cleaned: $($c.Name) — $sizeHuman" -Level Success
    } else {
        Log "[DRY] Would clean: $($c.Name) — $sizeHuman" -Level Debug
    }
    $totalCleaned += $sizeKB
}

# Package manager cache purges
if (-not $DryRun) {
    try { & pip cache purge 2>$null; Log "pip cache purged" -Level Success } catch {}
    try { & npm cache clean --force 2>$null; Log "npm cache purged" -Level Success } catch {}
    try { & dotnet nuget locals all --clear 2>$null; Log "NuGet cache purged" -Level Success } catch {}
}

Log "Total cleaned: $([math]::Round($totalCleaned/1MB, 2)) GB" -Level Success

# ═══════════════════════════════════════════════════
# PHASE 3: NEW OFFLOADS TO E:
# ═══════════════════════════════════════════════════
Log " " -Level Section
Log "PHASE 3: NEW OFFLOADS TO E:" -Level Section

$offloadTargets = @(
    # Large app data not yet offloaded
    @{ Name = 'Docker WSL data';        Path = "$env:LOCALAPPDATA\Docker\wsl";                                  StopFirst = 'com.docker*' }
    @{ Name = 'Insomnia node_modules';  Path = "$env:LOCALAPPDATA\insomnia\app-12.3.1\resources\app.asar.unpacked\node_modules" }
    @{ Name = 'Insomnia packages';      Path = "$env:LOCALAPPDATA\insomnia\packages" }
    @{ Name = 'GitKraken packages';     Path = "$env:LOCALAPPDATA\gitkraken\packages" }
    @{ Name = 'Logseq packages';        Path = "$env:LOCALAPPDATA\Logseq\packages" }
    @{ Name = 'GitHubDesktop packages'; Path = "$env:LOCALAPPDATA\GitHubDesktop\packages" }
    @{ Name = 'Balena Etcher packages'; Path = "$env:LOCALAPPDATA\balena_etcher\packages" }
    @{ Name = 'Postman packages';       Path = "$env:LOCALAPPDATA\Postman\packages" }
    @{ Name = 'Discord packages';       Path = "$env:LOCALAPPDATA\Discord\packages" }
    @{ Name = 'Slack packages';         Path = "$env:LOCALAPPDATA\slack\packages" }
    @{ Name = 'VS Shared Packages';     Path = 'C:\Program Files (x86)\Microsoft Visual Studio\Shared\Packages' }
    @{ Name = '.npm-global modules';    Path = "$env:USERPROFILE\.npm-global\node_modules" }
    # Stale root dirs not yet junctioned
    @{ Name = 'Squid proxy';            Path = 'C:\Squid' }
)

$offloadedKB = 0
foreach ($t in $offloadTargets) {
    if (-not (Test-Path $t.Path)) { continue }
    # Skip if already a junction
    if ((Get-Item $t.Path).Attributes -match 'ReparsePoint') {
        Log "ALREADY JUNCTION: $($t.Name)" -Level Annotate
        continue
    }

    $sizeKB = 0
    try {
        $sizeKB = (Get-ChildItem $t.Path -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum / 1KB
    } catch {}
    $sizeHuman = if ($sizeKB -gt 1MB) { "$([math]::Round($sizeKB/1MB, 2)) GB" }
                 else { "$([math]::Round($sizeKB/1KB, 2)) MB" }

    if ($sizeKB -lt 10240) { continue }  # Skip < 10 MB

    # Build offload destination
    $destName = $t.Path.Replace('C:\', 'C_').Replace('\', '_').Replace(' ', '_')
    $destPath = "$ExternalDrive\SOK_Offload\$destName"

    Log "Offloading: $($t.Name) — $sizeHuman" -Level Ignore
    Log "  $($t.Path) → $destPath" -Level Debug

    if (-not $DryRun) {
        # Stop process if specified
        if ($t.StopFirst) {
            Get-Process -Name $t.StopFirst -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Continue
            Start-Sleep -Seconds 2
        }

        # Robocopy move
        $roboArgs = @($t.Path, $destPath, '/E', '/MOVE', '/R:1', '/W:2', '/MT:8', '/XJ', '/COPY:DAT', '/DCOPY:T', '/NFL', '/NDL', '/NP')
        $roboResult = & robocopy @roboArgs 2>&1
        $roboExit = $LASTEXITCODE

        if ($roboExit -le 3) {
            # Clean source remnants and create junction
            if (Test-Path $t.Path) { Remove-Item $t.Path -Recurse -Force -ErrorAction Continue }
            if (-not (Test-Path $t.Path)) {
                cmd /c "mklink /J `"$($t.Path)`" `"$destPath`"" 2>$null
                Log "  Junction created" -Level Success
                $offloadedKB += $sizeKB
            } else {
                Log "  Source not fully removed — junction skipped" -Level Warn
            }
        } else {
            Log "  Robocopy failed (exit: $roboExit)" -Level Error
        }
    } else {
        Log "  [DRY] Would robocopy + junction ($sizeHuman)" -Level Debug
        $offloadedKB += $sizeKB
    }
}

Log "Total offloaded: $([math]::Round($offloadedKB/1MB, 2)) GB" -Level Success

# ═══════════════════════════════════════════════════
# PHASE 4: STALE PROGRAM CLEANUP
# ═══════════════════════════════════════════════════
Log " " -Level Section
Log "PHASE 4: STALE ITEMS (safe deletes)" -Level Section

$staleDeletes = @(
    # ProgramData stale items identified by SpaceAudit
    @{ Name = 'ProgramData miniconda3 (113d stale)';  Path = 'C:\ProgramData\miniconda3' }
    @{ Name = 'ProgramData mingw64 (114d stale)';     Path = 'C:\ProgramData\mingw64' }
    @{ Name = 'ProgramData nvm (114d stale)';         Path = 'C:\ProgramData\nvm' }
    @{ Name = 'ProgramData Jenkins (114d stale)';     Path = 'C:\ProgramData\Jenkins' }
    @{ Name = 'ProgramData glasswire (113d stale)';   Path = 'C:\ProgramData\glasswire' }
    @{ Name = 'ProgramData MySQL (114d stale)';       Path = 'C:\ProgramData\MySQL' }
    @{ Name = 'ProgramData USOShared (718d stale)';   Path = 'C:\ProgramData\USOShared' }
    @{ Name = 'ProgramData SquirrelMachineInstalls';   Path = 'C:\ProgramData\SquirrelMachineInstalls' }
    # Package installer caches
    @{ Name = 'Local Package Cache';     Path = "$env:LOCALAPPDATA\Package Cache" }
    @{ Name = 'ProgramData Package Cache'; Path = 'C:\ProgramData\Package Cache' }
    # Weka docs (1514 days stale!)
    @{ Name = 'Weka docs (4+ years stale)';  Path = 'C:\Program Files\weka-3-8-6\doc' }
    # Gephi (198d stale, 4 dirs)
    @{ Name = 'Gephi extra (198d)';      Path = 'C:\Program Files\Gephi-0.10.1\extra' }
    @{ Name = 'Gephi jre (198d)';        Path = 'C:\Program Files\Gephi-0.10.1\jre-x64' }
    # Duplicate SoapUI installs
    @{ Name = 'SoapUI 5.8.0 (old)';     Path = 'C:\Program Files\SmartBear\SoapUI-5.8.0' }
    # Duplicate Erlang OTP versions (keep latest)
    @{ Name = 'Erlang OTP erts-16.1.1 (old)'; Path = 'C:\Program Files\Erlang OTP\erts-16.1.1' }
    @{ Name = 'Erlang OTP erts-16.1.2 (old)'; Path = 'C:\Program Files\Erlang OTP\erts-16.1.2' }
    @{ Name = 'Erlang OTP erts-16.2 (old)';   Path = 'C:\Program Files\Erlang OTP\erts-16.2' }
    # IncrediBuild backup/updates
    @{ Name = 'IncrediBuild ManagerInstallBackup'; Path = 'C:\Program Files (x86)\IncrediBuild\ManagerInstallBackup' }
    @{ Name = 'IncrediBuild Updates';    Path = 'C:\Program Files (x86)\IncrediBuild\Updates' }
)

$staleFreed = 0
foreach ($s in $staleDeletes) {
    if (-not (Test-Path $s.Path)) { continue }
    $sizeKB = 0
    try {
        $sizeKB = (Get-ChildItem $s.Path -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum / 1KB
    } catch {}
    $sizeHuman = if ($sizeKB -gt 1MB) { "$([math]::Round($sizeKB/1MB, 2)) GB" }
                 else { "$([math]::Round($sizeKB/1KB, 2)) MB" }

    if (-not $DryRun) {
        # v4.3.2: Offload to E: instead of deleting
        $depDir = "$ExternalDrive\SOK_Offload\Deprecated"
        if (-not (Test-Path $depDir)) { New-Item -Path $depDir -ItemType Directory -Force | Out-Null }
        $depDest = Join-Path $depDir ($s.Path -replace '^([A-Z]):', '$1' -replace '\\', '_')
        $roboArgs = @($s.Path, $depDest, '/E', '/MOVE', '/R:1', '/W:1', '/MT:8', '/XJ', '/NP', '/NFL', '/NDL')
        & robocopy @roboArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -lt 8 -and -not (Test-Path $s.Path)) {
            Log "Offloaded: $($s.Name) — $sizeHuman → $depDest" -Level Success
            $staleFreed += $sizeKB
        } else { Log "Partial: $($s.Name) — some files locked" -Level Warn }
    } else {
        Log "[DRY] Would delete: $($s.Name) — $sizeHuman" -Level Debug
        $staleFreed += $sizeKB
    }
}

Log "Stale items freed: $([math]::Round($staleFreed/1MB, 2)) GB" -Level Success

# ═══════════════════════════════════════════════════
# PHASE 5: BIG-TICKET REPORT (user decisions)
# ═══════════════════════════════════════════════════
Log " " -Level Section
Log "PHASE 5: USER DECISIONS NEEDED" -Level Section

$bigTickets = @(
    @{ Name = 'Documents\Backup';   Path = "$env:USERPROFILE\Documents\Backup" }
    @{ Name = 'Downloads';           Path = "$env:USERPROFILE\Downloads" }
    @{ Name = 'Pictures';            Path = "$env:USERPROFILE\Pictures" }
    @{ Name = 'Videos';              Path = "$env:USERPROFILE\Videos" }
    @{ Name = 'BlueStacks';          Path = 'C:\ProgramData\BlueStacks_nxt' }
    @{ Name = 'Unity 6000.2.13f1';   Path = 'C:\Program Files\Unity 6000.2.13f1' }
    @{ Name = 'Unity 6000.2.14f1';   Path = 'C:\Program Files\Unity 6000.2.14f1' }
    @{ Name = 'Unity 6000.2.15f1';   Path = 'C:\Program Files\Unity 6000.2.15f1' }
    @{ Name = 'Visual Studio 220GB'; Path = 'C:\Program Files\Microsoft Visual Studio' }
    @{ Name = 'Android SDK (x86)';   Path = 'C:\Program Files (x86)\Android\android-sdk' }
    @{ Name = 'GOG.com data';        Path = 'C:\ProgramData\GOG.com' }
    @{ Name = 'Docker (Program Files)'; Path = 'C:\Program Files\Docker' }
)

$totalBigTicket = 0
foreach ($bt in $bigTickets) {
    if (-not (Test-Path $bt.Path)) { continue }
    $sizeKB = 0
    try {
        # Fast: use .NET for top-level size estimate
        $di = [System.IO.DirectoryInfo]::new($bt.Path)
        $sizeKB = ($di.EnumerateFiles('*', [System.IO.SearchOption]::AllDirectories) |
            ForEach-Object { $_.Length } | Measure-Object -Sum).Sum / 1KB
    } catch {
        try {
            $sizeKB = (Get-ChildItem $bt.Path -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum / 1KB
        } catch {}
    }

    $sizeGB = [math]::Round($sizeKB / 1MB, 2)
    if ($sizeGB -lt 0.1) { continue }
    $totalBigTicket += $sizeKB

    $action = switch -Wildcard ($bt.Name) {
        'Documents\Backup'    { 'OFFLOAD TO E: or verify content before swap' }
        'Downloads'           { 'REVIEW & PURGE old downloads' }
        'Pictures'            { 'Will recover from HDD — verify no duplicates' }
        'Videos'              { 'Will recover from HDD — verify no duplicates' }
        'BlueStacks'          { 'UNINSTALL if not actively using (8 GB)' }
        'Unity*'              { 'KEEP LATEST ONLY — uninstall older versions via Unity Hub' }
        'Visual Studio*'      { 'VS Installer → Modify → remove unused workloads' }
        'Android SDK*'        { 'Review via Android Studio SDK Manager' }
        'GOG*'                { 'UNINSTALL if not gaming' }
        'Docker*'             { 'OFFLOAD or uninstall if using Podman instead' }
        default               { 'REVIEW' }
    }

    Log "$([math]::Round($sizeGB, 1).ToString().PadLeft(8)) GB  $($bt.Name)" -Level Warn
    Log "             → $action" -Level Ignore
}

Log " " -Level Ignore
Log "Total addressable (user decisions): $([math]::Round($totalBigTicket/1MB, 1)) GB" -Level Warn

# ═══════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════
$endFreeKB = [math]::Round((Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" ).FreeSpace / 1KB, 0)
$gainedKB = $endFreeKB - $startFreeKB
$duration = ((Get-Date) - $startTime).TotalSeconds

Log " " -Level Section
Log "PRE-SWAP COMPLETE" -Level Section
Log "  C: before:    $startFreeKB KB free" -Level Ignore
Log "  C: after:     $endFreeKB KB free" -Level $(if ($gainedKB -gt 1048576) { 'Success' } else { 'Warn' })
Log "  Gained:       $gainedKB KB" -Level $(if ($gainedKB -gt 5242880) { 'Success' } else { 'Annotate' })
Log "  Duration:     $([math]::Round($duration, 1))s" -Level Ignore
Log "  DryRun:       $DryRun" -Level Ignore
