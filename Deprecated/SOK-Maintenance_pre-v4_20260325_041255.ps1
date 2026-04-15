<#
.SYNOPSIS
    SOK-Maintenance v3 — Multi-drive cleanup, health, package management.
.DESCRIPTION
    v3.0.0: Ingests prior inventory, recycle bin clearing, verbose timeouts,
    WSL exclusion, monthly Thorough tier, per-script history.

    Modes:
      Quick    — Junction check + cache cleanup + recycle bin
      Standard — Quick + package updates (default)
      Deep     — Standard + TRIM + drive health + DNS flush + Windows Update
      Thorough — Deep + stale program scan + SSD wear report + full NuGet/dotnet purge
.NOTES
    Author: S. Clay Caddell
    Version: 3.0.0
    Date: 23Mar2026
#>
[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Standard', 'Deep', 'Thorough')]
    [string]$Mode = 'Standard',
    [switch]$DryRun
)

#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$modulePath = "C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1"
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else { Write-Error "SOK-Common.psm1 not found at $modulePath"; exit 1 }

Show-SOKBanner -ScriptName "Maintenance ($Mode)"
$logPath = Initialize-SOKLog -ScriptName 'SOK-Maintenance'
$config = Get-SOKConfig
$startTime = Get-Date
$results = [ordered]@{
    CacheFreedKB = 0; RecycleBinKB = 0; PackagesUpdated = 0
    JunctionsChecked = 0; BrokenJunctions = 0; Errors = 0
    TimeoutDetails = @()
}

if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

# WSL exclusion paths — never touch these with robocopy/cleanup
$script:WSLExclusions = @(
    "$env:LOCALAPPDATA\Packages\*CanonicalGroup*"
    "$env:LOCALAPPDATA\Packages\*Kali*"
    "$env:LOCALAPPDATA\Packages\*SUSE*"
    "$env:LOCALAPPDATA\Packages\*Debian*"
    '*ext4.vhdx*'
    '*rootfs*'
)

# ═══════════════════════════════════════════════════════════════
# INGEST PRIOR INVENTORY (if available)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PRIOR INVENTORY CHECK' -Level Section

$invDir = "C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\Inventory"
$lastInventory = $null
if (Test-Path $invDir) {
    $invFiles = Get-ChildItem $invDir -Filter 'SOK_Inventory_*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($invFiles) {
        try {
            $lastInventory = Get-Content $invFiles.FullName -Raw | ConvertFrom-Json
            $invAge = [math]::Round(((Get-Date) - $invFiles.LastWriteTime).TotalHours, 1)
            $jCount = $lastInventory.junction_map.junction_count
            $bCount = $lastInventory.junction_map.broken_count
            Write-SOKLog "  Loaded: $($invFiles.Name) (${invAge}h old)" -Level Success
            Write-SOKLog "  Last scan: $jCount junctions, $bCount broken" -Level $(if ($bCount -gt 0) { 'Warn' } else { 'Ignore' })

            # Flag if inventory is stale (>48h)
            if ($invAge -gt 48) {
                Write-SOKLog "  Inventory is ${invAge}h old — consider running SOK-Inventory" -Level Annotate
            }
        }
        catch { Write-SOKLog "  Failed to parse inventory: $_" -Level Warn }
    }
    else { Write-SOKLog '  No prior inventory found' -Level Annotate }
}

# ═══════════════════════════════════════════════════════════════
# DRIVE DISCOVERY
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'DRIVE DISCOVERY' -Level Section

$allDrives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Continue)
foreach ($d in $allDrives) {
    $pctUsed = if ($d.Size -gt 0) { [math]::Round((($d.Size - $d.FreeSpace) / $d.Size) * 100, 1) } else { 0 }
    $level = if ($pctUsed -gt 88) { 'Error' } elseif ($pctUsed -gt 66) { 'Warn' } elseif ($pctUsed -gt 44) { 'Annotate' } else { 'Ignore' }
    Write-SOKLog "  $($d.DeviceID) $($d.VolumeName) — $($d.FileSystem) $(Get-HumanSize $d.Size) ($pctUsed% used)" -Level $level
}

$beforeFreeC = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Continue).FreeSpace

# ═══════════════════════════════════════════════════════════════
# PHASE 1: JUNCTION HEALTH (all modes)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'JUNCTION HEALTH CHECK' -Level Section

$junctionRoots = @("$env:USERPROFILE", "$env:LOCALAPPDATA", "$env:APPDATA",
    'C:\ProgramData', 'C:\Program Files', 'C:\')

$checkedJunctions = 0; $brokenJunctions = 0

foreach ($root in $junctionRoots) {
    if (-not (Test-Path $root)) { continue }
    try {
        $dirs = Get-ChildItem -Path $root -Directory -Force -ErrorAction SilentlyContinue
        foreach ($dir in $dirs) {
            if ($dir.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                $checkedJunctions++
                $target = try { $dir.Target } catch { $null }

                if ($target -and -not (Test-Path "$target")) {
                    $brokenJunctions++
                    $targetDrive = if ("$target" -match '^([A-Z]):') { $Matches[1] + ':' } else { '?' }
                    $drivePresent = $allDrives | Where-Object { $_.DeviceID -eq $targetDrive }
                    $level = if (-not $drivePresent) { 'Warn' } else { 'Error' }
                    $reason = if (-not $drivePresent) { 'drive offline' } else { 'path missing' }
                    Write-SOKLog "  BROKEN ($reason): $($dir.FullName) → $target" -Level $level
                }
            }
        }
    } catch { }
}

$results.JunctionsChecked = $checkedJunctions
$results.BrokenJunctions = $brokenJunctions
Write-SOKLog "  Checked: $checkedJunctions junctions ($brokenJunctions broken)" -Level $(if ($brokenJunctions -gt 0) { 'Warn' } else { 'Success' })

# ═══════════════════════════════════════════════════════════════
# PHASE 2: CACHE CLEANUP (all modes)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'CACHE CLEANUP (multi-drive)' -Level Section

$cachePaths = @(
    @{ Path = $env:TEMP;                                                         Label = 'Windows Temp' }
    @{ Path = "$env:LOCALAPPDATA\Temp";                                          Label = 'User Temp' }
    @{ Path = 'C:\Windows\Temp';                                                 Label = 'System Temp' }
    @{ Path = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache";                   Label = 'Internet Cache' }
    @{ Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache";         Label = 'Chrome Cache' }
    @{ Path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache";    Label = 'Chrome Code Cache' }
    @{ Path = "$env:LOCALAPPDATA\pip\cache";                                     Label = 'pip Cache' }
    @{ Path = "$env:APPDATA\npm-cache";                                          Label = 'npm Cache' }
    @{ Path = 'C:\ProgramData\chocolatey\lib-bkp';                              Label = 'Choco Backup' }
    @{ Path = 'C:\ProgramData\chocolatey\cache';                                 Label = 'Choco Cache' }
    @{ Path = "$env:USERPROFILE\.cargo\registry\cache";                          Label = 'Cargo Cache' }
    @{ Path = "$env:LOCALAPPDATA\D3DSCache";                                     Label = 'D3D Shader Cache' }
    @{ Path = "$env:LOCALAPPDATA\CrashDumps";                                    Label = 'Crash Dumps' }
    @{ Path = "$env:LOCALAPPDATA\Microsoft\VisualStudio\Roslyn\Cache";           Label = 'Roslyn Cache' }
    @{ Path = "$env:LOCALAPPDATA\NuGet\v3-cache";                               Label = 'NuGet HTTP Cache' }
    @{ Path = "$env:LOCALAPPDATA\node-gyp\Cache";                               Label = 'node-gyp Cache' }
    @{ Path = "$env:APPDATA\Claude\Code Cache";                                  Label = 'Claude Code Cache' }
    @{ Path = "$env:APPDATA\Slack\Code Cache";                                   Label = 'Slack Code Cache' }
    @{ Path = "$env:APPDATA\discord\Cache";                                      Label = 'Discord Cache' }
)

# Scan offload drives for temp/cache (skip WSL paths)
foreach ($d in $allDrives) {
    if ($d.DeviceID -eq 'C:') { continue }
    $offloadRoot = Join-Path "$($d.DeviceID)" 'SOK_Offload'
    if (Test-Path $offloadRoot) {
        $tempDirs = Get-ChildItem -Path $offloadRoot -Directory -Recurse -Depth 3 -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match '^(temp|tmp|cache|__pycache__)$' -and
                -not ($script:WSLExclusions | Where-Object { $_.FullName -like $_ })
            }
        foreach ($td in $tempDirs) {
            $cachePaths += @{ Path = $td.FullName; Label = "$($d.DeviceID) offload temp: $($td.Name)" }
        }
    }
}

foreach ($item in $cachePaths) {
    if (-not (Test-Path $item.Path)) { continue }
    # Skip WSL paths
    $isWSL = $false
    foreach ($excl in $script:WSLExclusions) { if ($item.Path -like $excl) { $isWSL = $true; break } }
    if ($isWSL) { Write-SOKLog "  SKIP (WSL): $($item.Label)" -Level Debug; continue }

    $sizeKB = try {
        $opts = [System.IO.EnumerationOptions]::new()
        $opts.RecurseSubdirectories = $true; $opts.IgnoreInaccessible = $true
        $opts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint -bor [System.IO.FileAttributes]::System
        $total = [long]0
        foreach ($fi in [System.IO.Directory]::EnumerateFiles($item.Path, '*', $opts)) {
            try { $total += ([System.IO.FileInfo]::new($fi)).Length } catch { }
        }
        [math]::Round($total / 1KB, 0)
    } catch { 0 }

    if ($sizeKB -lt 1024) { continue }

    if ($DryRun) {
        Write-SOKLog "[DRY] Would clean: $($item.Label) — $(Get-HumanSize ($sizeKB * 1KB))" -Level Debug
        $results.CacheFreedKB += $sizeKB
    } else {
        try {
            Get-ChildItem -Path $item.Path -Force -ErrorAction Continue | Remove-Item -Recurse -Force -ErrorAction Continue
            Write-SOKLog "Cleaned: $($item.Label) — $(Get-HumanSize ($sizeKB * 1KB))" -Level Success
            $results.CacheFreedKB += $sizeKB
        } catch {
            Write-SOKLog "Partial: $($item.Label) — $($_.Exception.Message)" -Level Warn
            $results.CacheFreedKB += [math]::Round($sizeKB / 2, 0)
        }
    }
}

# Package manager cache purges
$cacheCommands = @(
    @{ Name = 'Scoop';  Cmd = 'scoop';  Args = 'cleanup *' }
    @{ Name = 'pip';    Cmd = 'pip';    Args = 'cache purge' }
    @{ Name = 'npm';    Cmd = 'npm';    Args = 'cache clean --force' }
)
foreach ($cc in $cacheCommands) {
    if (Get-Command $cc.Cmd -ErrorAction SilentlyContinue) {
        if (-not $DryRun) {
            try { Invoke-Expression "$($cc.Cmd) $($cc.Args)" 2>&1 | Out-Null; Write-SOKLog "$($cc.Name) cache purged" -Level Success }
            catch { Write-SOKLog "$($cc.Name) purge failed: $_" -Level Warn }
        }
    }
}

# Recycle Bin (all modes)
Write-SOKLog 'RECYCLE BIN' -Level Section
if (-not $DryRun) {
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-SOKLog 'Recycle bin emptied' -Level Success
    } catch {
        # Fallback for older PS versions
        try {
            $shell = New-Object -ComObject Shell.Application
            $recycleBin = $shell.Namespace(0xA)
            $rbItems = $recycleBin.Items()
            $rbCount = $rbItems.Count
            if ($rbCount -gt 0) {
                foreach ($item in $rbItems) { Remove-Item $item.Path -Recurse -Force -ErrorAction Continue }
                Write-SOKLog "Recycle bin: $rbCount items removed" -Level Success
            } else { Write-SOKLog 'Recycle bin: empty' -Level Ignore }
        } catch { Write-SOKLog "Recycle bin: $($_.Exception.Message)" -Level Warn }
    }
} else { Write-SOKLog '[DRY] Would empty recycle bin' -Level Debug }

Write-SOKLog 'Skipping cleanmgr.exe (permanently disabled — known hang)' -Level Debug

$afterFreeC = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Continue).FreeSpace
if ($beforeFreeC -and $afterFreeC) {
    $freedKB = [math]::Round(($afterFreeC - $beforeFreeC) / 1KB, 0)
    $results.CacheFreedKB = $freedKB
    Write-SOKLog "C: space freed: $(Get-HumanSize ($freedKB * 1KB))" -Level Success
}

# ═══════════════════════════════════════════════════════════════
# PHASE 3: PACKAGE UPDATES (Standard+)
# ═══════════════════════════════════════════════════════════════
if ($Mode -in @('Standard', 'Deep', 'Thorough')) {
    Write-SOKLog 'PACKAGE UPDATES' -Level Section

    $managers = @(
        @{ Name = 'Chocolatey'; Cmd = 'choco';  UpdateCmd = 'choco upgrade all -y' }
        @{ Name = 'Scoop';      Cmd = 'scoop';  UpdateCmd = 'scoop update; scoop upgrade *' }
        @{ Name = 'Winget';     Cmd = 'winget'; UpdateCmd = 'winget upgrade --all --accept-source-agreements --accept-package-agreements' }
        @{ Name = 'pip';        Cmd = 'pip';    UpdateCmd = $null }
        @{ Name = 'npm';        Cmd = 'npm';    UpdateCmd = 'npm update -g' }
    )

    $disabled = if ($config.PackageSync.DisabledManagers) { $config.PackageSync.DisabledManagers } else { @() }
    $timeout = if ($config.PackageSync.PackageTimeoutSeconds) { $config.PackageSync.PackageTimeoutSeconds } else { 300 }

    foreach ($mgr in $managers) {
        if ($mgr.Name.ToLower() -in $disabled) { Write-SOKLog "$($mgr.Name): DISABLED" -Level Debug; continue }
        if (-not (Get-Command $mgr.Cmd -ErrorAction SilentlyContinue)) { Write-SOKLog "$($mgr.Name): not installed" -Level Debug; continue }

        Write-SOKLog "Updating $($mgr.Name)..." -Level Ignore

        if ($DryRun) { Write-SOKLog "[DRY] Would run: $($mgr.UpdateCmd)" -Level Debug; continue }

        # pip special handling
        if ($mgr.Name -eq 'pip') {
            try {
                $outdated = pip list --outdated --format=json 2>$null | ConvertFrom-Json
                if ($outdated -and $outdated.Count -gt 0) {
                    foreach ($pkg in $outdated) { pip install --upgrade $pkg.name 2>&1 | Out-Null }
                    $results.PackagesUpdated += $outdated.Count
                    Write-SOKLog "pip: $($outdated.Count) packages updated" -Level Success
                } else { Write-SOKLog 'pip: all current' -Level Success }
            } catch { Write-SOKLog "pip failed: $_" -Level Warn; $results.Errors++ }
            continue
        }

        # Verbose timeout handling
        $tempLog = Join-Path $env:TEMP "sok_${($mgr.Name)}_$(Get-Date -Format 'HHmmss').log"
        try {
            $updateScript = [scriptblock]::Create("$($mgr.UpdateCmd) 2>&1 | Tee-Object -FilePath '$tempLog'")
            $result = Invoke-WithTimeout -ScriptBlock $updateScript -TimeoutSeconds $timeout -Description "$($mgr.Name) update"
            if ($result.Success) {
                Write-SOKLog "$($mgr.Name): complete" -Level Success
                $results.PackagesUpdated++
            } else {
                # Verbose timeout: show last lines of output
                $detail = "$($mgr.Name): $($result.Error)"
                if (Test-Path $tempLog) {
                    $lastLines = Get-Content $tempLog -Tail 5 -ErrorAction SilentlyContinue
                    if ($lastLines) {
                        $detail += " | Last output: $($lastLines -join ' → ')"
                    }
                }
                Write-SOKLog $detail -Level Warn
                $results.TimeoutDetails += @{ Manager = $mgr.Name; Timeout = $timeout; LastOutput = ($lastLines -join "`n") }
                $results.Errors++
            }
        } catch {
            Write-SOKLog "$($mgr.Name): $($_.Exception.Message)" -Level Warn
            $results.Errors++
        } finally {
            Remove-Item $tempLog -Force -ErrorAction SilentlyContinue
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# PHASE 4: SYSTEM OPTIMIZATION (Deep+)
# ═══════════════════════════════════════════════════════════════
if ($Mode -in @('Deep', 'Thorough')) {
    Write-SOKLog 'SYSTEM OPTIMIZATION' -Level Section

    if (-not $DryRun) {
        Clear-DnsClientCache -ErrorAction Continue
        Write-SOKLog 'DNS cache flushed' -Level Success
    }

    # SSD TRIM
    Write-SOKLog 'SSD TRIM (all SSD volumes)' -Level Ignore
    foreach ($drive in $allDrives) {
        $driveLetter = $drive.DeviceID.TrimEnd(':')
        if (-not $DryRun) {
            try {
                Optimize-Volume -DriveLetter $driveLetter -ReTrim -ErrorAction Stop
                Write-SOKLog "  TRIM: $($drive.DeviceID) $($drive.VolumeName)" -Level Success
            } catch { Write-SOKLog "  TRIM failed: $($drive.DeviceID) — $($_.Exception.Message)" -Level Warn }
        }
    }

    # Drive health
    Write-SOKLog 'DRIVE HEALTH' -Level Ignore
    $physDisks = Get-PhysicalDisk -ErrorAction Continue
    foreach ($pd in $physDisks) {
        $level = if ($pd.HealthStatus -ne 'Healthy') { 'Error' } else { 'Success' }
        Write-SOKLog "  $($pd.FriendlyName): $($pd.HealthStatus) ($($pd.OperationalStatus)) [$($pd.BusType)]" -Level $level
    }

    # Windows Updates
    if (-not ($config.Maintenance.SkipWindowsUpdate)) {
        Write-SOKLog 'Windows Updates...' -Level Ignore
        if (-not $DryRun -and (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            try {
                Import-Module PSWindowsUpdate
                $updates = Get-WindowsUpdate -ErrorAction Continue
                if ($updates -and $updates.Count -gt 0) {
                    Install-WindowsUpdate -AcceptAll -AutoReboot:$false -ErrorAction Continue
                    Write-SOKLog "Installed $($updates.Count) Windows updates" -Level Success
                } else { Write-SOKLog 'Windows: up to date' -Level Success }
            } catch { Write-SOKLog "Windows Update failed: $_" -Level Warn; $results.Errors++ }
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# PHASE 5: THOROUGH — Monthly deep analysis
# ═══════════════════════════════════════════════════════════════
if ($Mode -eq 'Thorough') {
    Write-SOKLog 'THOROUGH ANALYSIS (monthly)' -Level Section

    # SSD Wear Reporting
    Write-SOKLog 'SSD WEAR REPORT' -Level Ignore
    foreach ($pd in (Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -eq 'SSD' })) {
        $reliability = Get-StorageReliabilityCounter -PhysicalDisk $pd -ErrorAction SilentlyContinue
        if ($reliability) {
            $wear = $reliability.Wear
            $poh = $reliability.PowerOnHours
            $level = if ($wear -gt 80) { 'Error' } elseif ($wear -gt 50) { 'Warn' } else { 'Success' }
            Write-SOKLog "  $($pd.FriendlyName): Wear=$wear% PowerOn=${poh}h" -Level $level
        } else {
            Write-SOKLog "  $($pd.FriendlyName): SMART data unavailable" -Level Annotate
        }
    }

    # Full NuGet + dotnet purge
    Write-SOKLog 'DEEP CACHE PURGE' -Level Ignore
    if (-not $DryRun) {
        try { dotnet nuget locals all --clear 2>&1 | Out-Null; Write-SOKLog '  dotnet NuGet locals cleared' -Level Success } catch {}
        $deepPaths = @(
            @{ Path = "$env:LOCALAPPDATA\Microsoft\VisualStudio\Packages"; Label = 'VS Package Cache' }
            @{ Path = "$env:LOCALAPPDATA\Package Cache";                    Label = 'Local Package Cache' }
            @{ Path = 'C:\msys64\var\cache';                               Label = 'msys2 cache' }
        )
        foreach ($dp in $deepPaths) {
            if (-not (Test-Path $dp.Path)) { continue }
            $sizeKB = try { [math]::Round(((Get-ChildItem $dp.Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1KB), 0) } catch { 0 }
            if ($sizeKB -gt 10240) {
                Get-ChildItem $dp.Path -Force -ErrorAction Continue | Remove-Item -Recurse -Force -ErrorAction Continue
                Write-SOKLog "  Cleaned: $($dp.Label) — $(Get-HumanSize ($sizeKB * 1KB))" -Level Success
            }
        }
    }

    # Stale program detection (from SpaceAudit patterns)
    Write-SOKLog 'STALE PROGRAM CHECK' -Level Ignore
    $stalePaths = @(
        'C:\ProgramData\miniconda3', 'C:\ProgramData\mingw64', 'C:\ProgramData\nvm',
        'C:\ProgramData\Jenkins', 'C:\ProgramData\glasswire', 'C:\ProgramData\MySQL',
        'C:\ProgramData\USOShared', 'C:\ProgramData\SquirrelMachineInstalls'
    )
    foreach ($sp in $stalePaths) {
        if (-not (Test-Path $sp)) { continue }
        $age = [math]::Round(((Get-Date) - (Get-Item $sp).LastWriteTime).TotalDays)
        if ($age -gt 90) {
            $sizeKB = try { [math]::Round(((Get-ChildItem $sp -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1KB), 0) } catch { 0 }
            Write-SOKLog "  STALE (${age}d): $sp — $(Get-HumanSize ($sizeKB * 1KB))" -Level Warn
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# LOG CLEANUP
# ═══════════════════════════════════════════════════════════════
$maxAge = if ($config.MaxLogAgeDays) { $config.MaxLogAgeDays } else { 160 }
Remove-StaleLogFiles -MaxAgeDays $maxAge

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
$results['DurationSec'] = $duration
$results['Mode'] = $Mode
$results['DryRun'] = $DryRun.IsPresent
$results['DrivesScanned'] = $allDrives.Count

Write-SOKSummary -Stats $results -Title 'MAINTENANCE COMPLETE'

Save-SOKHistory -ScriptName 'SOK-Maintenance' -RunData @{
    Duration = $duration
    Results  = $results
}
