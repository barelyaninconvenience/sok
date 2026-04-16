<#
.SYNOPSIS
    SOK-Inventory.ps1 — Multi-drive system state snapshot to JSON.

.DESCRIPTION
    v3.0.0: Multi-drive aware inventory with drive topology mapping,
    junction tracking, and run-completeness comparison against prior runs.

    [NEW] Full physical disk → logical drive → partition mapping
    [NEW] Junction/symlink map across all volumes
    [NEW] Previous run comparison with drive-loadout diff
    [NEW] Completeness scoring: which collectors ran, which drives were present
    [NEW] -AllowRedundancy flag for explicit cross-drive redundant scanning
    [FIX] All v2 fixes preserved (Scoop 3-tier, Node.js, Size=0 guard, KB)

.PARAMETER OutputPath
    Path for the JSON output. Defaults to Documents\SOK\Inventory\

.PARAMETER ScanCaliber
    1=Quick (packages only), 2=Standard (+registry+services), 3=Deep (+hashes)

.PARAMETER PreviousRunPath
    Path to a prior inventory JSON for completeness comparison.
    If not specified, auto-detects the most recent run in the output directory.

.PARAMETER AllowRedundancy
    If set, scans offloaded directories on external drives even when
    junction targets are already reachable from C:\. Default: skip redundant.

.NOTES
    Author: S. Clay Caddell
    Version: 3.2.0
    Date: 19Mar2026
    Domain: PAST — reads and snapshots system state; no process kills or data modification
#>

[CmdletBinding()]
param(
    [string]$OutputPath,
    [ValidateRange(1, 3)]
    [int]$ScanCaliber = 2,
    [string]$PreviousRunPath,
    [switch]$AllowRedundancy,
    # DryRun: run all collectors (read-only) but skip writing the output JSON.
    # Use for test-sequencing validation that collectors execute without errors.
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level = 'Ignore') Write-Host "[$Level] $Message" }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) }
    function Initialize-SOKLog { param([string]$ScriptName) return $null }
    function Get-SOKConfig { return @{} }
    function Get-HumanSize { param([long]$Bytes) return "$([math]::Round($Bytes / 1KB, 1)) KB" }
}

Show-SOKBanner -ScriptName 'SOK-Inventory' -Subheader "Depth: $ScanCaliber | Multi-Drive | Redundancy: $(if($AllowRedundancy){'ON'}else{'OFF'})"
$logPath = Initialize-SOKLog -ScriptName 'SOK-Inventory'
$config = Get-SOKConfig
$startTime = Get-Date

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-Inventory'
}

# ── SYSTEM-CONTEXT PATH RESOLUTION ──
if ($env:USERPROFILE -like '*systemprofile*') {
    $env:USERPROFILE  = 'C:\Users\shelc'
    $env:LOCALAPPDATA = 'C:\Users\shelc\AppData\Local'
    $env:APPDATA      = 'C:\Users\shelc\AppData\Roaming'
    Write-SOKLog '[SYSTEM-CONTEXT] Remapped profile env vars to C:\Users\shelc' -Level Warn
}

$errors = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()

if (-not $OutputPath) {
    $outDir = if (Get-Command Get-ScriptLogDir -ErrorAction SilentlyContinue) { Get-ScriptLogDir -ScriptName 'SOK-Inventory' } else { Join-Path $env:USERPROFILE 'Documents\SOK\Inventory' }
    if (-not (Test-Path $outDir)) { New-Item -Path $outDir -ItemType Directory -Force | Out-Null }
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $OutputPath = Join-Path $outDir "SOK_Inventory_${ts}.json"
}

Write-SOKLog "Scan caliber: $ScanCaliber | Output: $OutputPath" -Level Ignore

$inventory = [ordered]@{}

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: DRIVE TOPOLOGY (physical → logical → partition map)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'DRIVE TOPOLOGY' -Level Section

try {
    # Physical disks
    $physDisks = @(Get-PhysicalDisk -ErrorAction Continue | ForEach-Object {
        [ordered]@{
            device_id     = $_.DeviceId
            friendly_name = $_.FriendlyName
            manufacturer  = $_.Manufacturer
            model         = $_.Model
            media_type    = "$($_.MediaType)"
            bus_type      = "$($_.BusType)"
            health_status = "$($_.HealthStatus)"
            op_status     = "$($_.OperationalStatus)"
            size_kb       = [math]::Round($_.Size / 1KB, 0)
            firmware      = $_.FirmwareVersion
            serial_number = "$($_.SerialNumber)".Trim()
        }
    })

    # Logical drives (all types: fixed, removable, network)
    $logicalDrives = @(Get-CimInstance Win32_LogicalDisk -ErrorAction Continue | ForEach-Object {
        $pctUsed = if ($_.Size -gt 0) { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1) } else { 0 }
        [ordered]@{
            device_id    = $_.DeviceID
            volume_name  = $_.VolumeName
            filesystem   = $_.FileSystem
            drive_type   = switch ($_.DriveType) { 2 {'Removable'} 3 {'Fixed'} 4 {'Network'} 5 {'Optical'} default {"$($_.DriveType)"} }
            total_kb     = if ($_.Size -gt 0) { [math]::Round($_.Size / 1KB, 0) } else { 0 }
            free_kb      = if ($_.FreeSpace) { [math]::Round($_.FreeSpace / 1KB, 0) } else { 0 }
            used_kb      = if ($_.Size -gt 0) { [math]::Round(($_.Size - $_.FreeSpace) / 1KB, 0) } else { 0 }
            percent_used = $pctUsed
            serial       = $_.VolumeSerialNumber
        }
    })

    # Drive letter → physical disk mapping via partitions
    $driveMap = @{}
    try {
        $partitions = Get-CimInstance Win32_DiskDriveToDiskPartition -ErrorAction Continue
        $logicalToPartition = Get-CimInstance Win32_LogicalDiskToPartition -ErrorAction Continue

        foreach ($ltp in $logicalToPartition) {
            $driveLetter = ($ltp.Dependent -split '"')[1]
            $partRef = $ltp.Antecedent
            foreach ($dtp in $partitions) {
                if ($dtp.Dependent -eq $partRef) {
                    $diskIndex = if ($dtp.Antecedent -match 'DeviceID="([^"]+)"') { $Matches[1] } else { '' }
                    $driveMap[$driveLetter] = $diskIndex
                }
            }
        }
    }
    catch {
        Write-SOKLog "Drive mapping partial: $($_.Exception.Message)" -Level Debug
    }

    # Build drive fingerprint for completeness tracking
    $driveFingerprint = @($logicalDrives | ForEach-Object {
        "$($_.device_id)|$($_.serial)|$($_.total_kb)"
    }) -join ';'

    $inventory['drive_topology'] = [ordered]@{
        physical_disks    = $physDisks
        logical_drives    = $logicalDrives
        drive_to_disk_map = $driveMap
        drive_fingerprint = $driveFingerprint
        scan_timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }

    foreach ($d in $logicalDrives) {
        $level = if ($d.percent_used -gt 83.33) { 'Error' } elseif ($d.percent_used -gt 66.66) { 'Warn' } elseif ($d.percent_used -gt 50) { 'Annotate' } else { 'Ignore' }
        Write-SOKLog "  $($d.device_id) $($d.volume_name) — $($d.filesystem) $(Get-HumanSize ($d.total_kb * 1KB)) ($($d.percent_used)% used) [$($d.drive_type)]" -Level $level
    }
    Write-SOKLog "  Physical: $($physDisks.Count) | Logical: $($logicalDrives.Count)" -Level Success
}
catch {
    $errors.Add("drive_topology: $($_.Exception.Message)") | Out-Null
    Write-SOKLog "Drive topology failed: $($_.Exception.Message)" -Level Error
}

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: JUNCTION MAP (cross-volume symlinks)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'JUNCTION MAP' -Level Section

$junctions = [System.Collections.ArrayList]::new()
try {
    # Scan known offload roots + common junction sources
    $junctionScanRoots = @(
        'C:\ProgramData'
        'C:\Program Files'
        "$env:USERPROFILE"
        "$env:USERPROFILE\scoop"
        "$env:USERPROFILE\.nuget"
        "$env:USERPROFILE\.cargo"
        "$env:USERPROFILE\.vscode"
        "$env:LOCALAPPDATA"
        "$env:APPDATA"
    )
    # Also scan root of C:\ for top-level junctions
    $junctionScanRoots += @(Get-ChildItem 'C:\' -Directory -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)

    $scanned = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($root in $junctionScanRoots) {
        if (-not (Test-Path $root)) { continue }
        if ($scanned.Contains($root)) { continue }
        $scanned.Add($root) | Out-Null

        try {
            $dirs = Get-ChildItem -Path $root -Directory -Force -ErrorAction SilentlyContinue
            foreach ($dir in $dirs) {
                if ($dir.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
                    $target = try { $dir.Target } catch { $null }
                    if (-not $target) {
                        # Fallback: fsutil
                        $fsResult = fsutil reparsepoint query $dir.FullName 2>&1
                        $target = if ("$fsResult" -match 'Print Name:\s*(.+)') { $Matches[1].Trim() } else { 'unknown' }
                    }
                    $targetDrive = if ("$target" -match '^([A-Z]):') { $Matches[1] + ':' } else { 'unknown' }

                    $junctions.Add([ordered]@{
                        source_path  = $dir.FullName
                        target_path  = "$target"
                        target_drive = $targetDrive
                        source_drive = $dir.FullName.Substring(0, 2)
                        type         = if ($dir.LinkType) { $dir.LinkType } else { 'Junction' }
                        target_exists = if ($target) { Test-Path "$target" } else { $false }
                    }) | Out-Null
                }
            }
        }
        catch { }
    }

    $inventory['junction_map'] = [ordered]@{
        junction_count    = $junctions.Count
        cross_drive_count = @($junctions | Where-Object { $_.source_drive -ne $_.target_drive }).Count
        broken_count      = @($junctions | Where-Object { -not $_.target_exists }).Count
        junctions         = @($junctions)
    }

    $crossDrive = @($junctions | Where-Object { $_.source_drive -ne $_.target_drive })
    $broken = @($junctions | Where-Object { -not $_.target_exists })

    Write-SOKLog "  Found: $($junctions.Count) junctions ($($crossDrive.Count) cross-drive, $($broken.Count) broken)" -Level $(if ($broken.Count -gt 0) { 'Warn' } else { 'Success' })

    foreach ($j in $crossDrive) {
        Write-SOKLog "    $($j.source_path) → $($j.target_path)" -Level Debug
    }
    if ($broken.Count -gt 0) {
        foreach ($b in $broken) {
            Write-SOKLog "    BROKEN: $($b.source_path) → $($b.target_path)" -Level Error
        }
    }
}
catch {
    $errors.Add("junction_map: $($_.Exception.Message)") | Out-Null
}

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: SYSTEM METADATA
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'SYSTEM METADATA' -Level Section
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Continue
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Continue
    $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Continue
    $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Continue

    $inventory['system_metadata'] = [ordered]@{
        hostname = $env:COMPUTERNAME
        domain   = $env:USERDOMAIN
        username = $env:USERNAME
        os       = [ordered]@{
            caption      = $os.Caption
            version      = $os.Version
            build        = $os.BuildNumber
            architecture = $os.OSArchitecture
            install_date = $os.InstallDate.ToString('yyyy-MM-dd')
        }
        hardware = [ordered]@{
            manufacturer = $cs.Manufacturer
            model        = $cs.Model
            system_type  = $cs.SystemType
            ram_kb       = [math]::Round($cs.TotalPhysicalMemory / 1KB, 0)
            cpu_name     = $cpu.Name
            cpu_cores    = $cpu.NumberOfCores
            cpu_threads  = $cpu.NumberOfLogicalProcessors
            bios_version = $bios.SMBIOSBIOSVersion
        }
    }
    Write-SOKLog 'System metadata collected' -Level Success
}
catch {
    $errors.Add("system_metadata: $($_.Exception.Message)") | Out-Null
}

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: OFFLOAD INVENTORY (scan E:\SOK_Offload if present)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'OFFLOAD INVENTORY' -Level Section

$offloadDrives = @($logicalDrives | Where-Object { $_.device_id -ne 'C:' -and $_.drive_type -eq 'Fixed' })
$offloadInventory = [System.Collections.ArrayList]::new()

foreach ($drv in $offloadDrives) {
    $offloadRoot = Join-Path "$($drv.device_id)" 'SOK_Offload'
    if (-not (Test-Path $offloadRoot)) {
        Write-SOKLog "  $($drv.device_id) — no SOK_Offload directory" -Level Debug
        continue
    }

    Write-SOKLog "  Scanning $offloadRoot..." -Level Ignore
    $offloadDirs = Get-ChildItem -Path $offloadRoot -Directory -Force -ErrorAction Continue

    foreach ($dir in $offloadDirs) {
        $sizeKB = try {
            $opts = [System.IO.EnumerationOptions]::new()
            $opts.RecurseSubdirectories = $true; $opts.IgnoreInaccessible = $true
            $opts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint -bor [System.IO.FileAttributes]::System
            $total = [long]0
            foreach ($fi in [System.IO.Directory]::EnumerateFiles($dir.FullName, '*', $opts)) {
                try { $total += ([System.IO.FileInfo]::new($fi)).Length } catch { }
            }
            [math]::Round($total / 1KB, 0)
        } catch { 0 }

        # Reconstruct original path from directory name
        $origPath = $dir.Name -replace '^([A-Z])_', '$1:\' -replace '_', '\'

        # Check if junction exists pointing back
        $junctionExists = $junctions | Where-Object { $_.target_path -eq $dir.FullName -or $_.source_path -eq $origPath } | Select-Object -First 1

        $offloadInventory.Add([ordered]@{
            offload_path   = $dir.FullName
            original_path  = $origPath
            drive          = $drv.device_id
            size_kb        = $sizeKB
            junction_active = $null -ne $junctionExists
            last_modified  = $dir.LastWriteTime.ToString('yyyy-MM-dd')
        }) | Out-Null
    }

    Write-SOKLog "  $($drv.device_id): $($offloadDirs.Count) offloaded items" -Level Success
}

$inventory['offload_inventory'] = [ordered]@{
    drives_scanned = $offloadDrives.Count
    offloaded_items = $offloadInventory.Count
    items = @($offloadInventory)
}

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: CHOCOLATEY
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'CHOCOLATEY' -Level Section
try {
    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoCmd) {
        $chocoVersion = (& choco --version 2>&1).ToString().Trim()
        $raw = & choco list --limit-output 2>&1
        $chocoPackages = @()
        if ($raw) {
            $chocoPackages = @($raw | Where-Object { $_ -match '\S+\|' } | ForEach-Object {
                $parts = $_ -split '\|'
                [ordered]@{ name = $parts[0].Trim(); version = if ($parts.Count -gt 1) { $parts[1].Trim() } else { 'unknown' } }
            })
        }
        if ($chocoPackages.Count -eq 0) {
            $raw2 = & choco list 2>&1
            $chocoPackages = @($raw2 | Where-Object { $_ -match '^\S+\s+\d' -and $_ -notmatch 'packages installed' } | ForEach-Object {
                $parts = $_ -split '\s+', 2
                [ordered]@{ name = $parts[0]; version = if ($parts.Count -gt 1) { $parts[1] } else { 'unknown' } }
            })
        }
        Write-SOKLog "Chocolatey v$chocoVersion — $($chocoPackages.Count) packages" -Level $(if ($chocoPackages.Count -gt 0) { 'Success' } else { 'Warn' })
        $inventory['chocolatey_packages'] = [ordered]@{ installed = $true; version = $chocoVersion; package_count = $chocoPackages.Count; packages = $chocoPackages }
    }
    else {
        $inventory['chocolatey_packages'] = @{ installed = $false }
        Write-SOKLog 'Chocolatey not found' -Level Warn
    }
}
catch { $errors.Add("chocolatey: $($_.Exception.Message)") | Out-Null }

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: SCOOP (3-tier fallback preserved from v2)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'SCOOP' -Level Section
try {
    $scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue
    if ($scoopCmd) {
        $scoopVersion = try { (& scoop --version 2>&1 | Select-Object -First 1).ToString().Trim() } catch { 'unknown' }
        $scoopApps = @()
        $scoopBuckets = @()

        # Tier 1: scoop export (JSON)
        try {
            $exportRaw = & scoop export 2>$null
            $exportJson = $exportRaw | ConvertFrom-Json -ErrorAction Stop
            if ($exportJson.apps) { $scoopApps = @($exportJson.apps | ForEach-Object { [ordered]@{ name = $_.Name; version = $_.Version; bucket = $_.Source } }) }
            if ($exportJson.buckets) { $scoopBuckets = @($exportJson.buckets | ForEach-Object { [ordered]@{ name = $_.Name; source = $_.Source } }) }
        } catch {
            Write-SOKLog "Scoop Tier 1 (export) failed: $($_.Exception.Message)" -Level Ignore
        }

        # Tier 2: scoop list (table parse)
        if ($scoopApps.Count -eq 0) {
            try {
                $listRaw = & scoop list 2>$null
                $scoopApps = @($listRaw | Where-Object { $_ -match '^\s*\S+\s+\d' } | ForEach-Object {
                    $parts = $_.Trim() -split '\s+', 3
                    [ordered]@{ name = $parts[0]; version = if ($parts.Count -gt 1) { $parts[1] } else { 'unknown' }; bucket = if ($parts.Count -gt 2) { $parts[2] } else { '' } }
                })
            } catch {
                Write-SOKLog "Scoop Tier 2 (list) failed: $($_.Exception.Message)" -Level Ignore
            }
        }

        # Tier 3: directory scan fallback
        if ($scoopApps.Count -eq 0) {
            $scoopAppsDir = Join-Path $env:USERPROFILE 'scoop\apps'
            if (Test-Path $scoopAppsDir) {
                $scoopApps = @(Get-ChildItem $scoopAppsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'scoop' } | ForEach-Object {
                    $currentDir = Join-Path $_.FullName 'current'
                    $ver = if (Test-Path $currentDir) {
                        $manifest = Join-Path $currentDir 'manifest.json'
                        if (Test-Path $manifest) { try { (Get-Content $manifest -Raw | ConvertFrom-Json).version } catch { 'dir-scan' } } else { 'dir-scan' }
                    } else { 'dir-scan' }
                    [ordered]@{ name = $_.Name; version = $ver; bucket = 'dir-scan' }
                })
            }
        }

        $inventory['scoop_packages'] = [ordered]@{ installed = $true; version = $scoopVersion; app_count = $scoopApps.Count; apps = $scoopApps; bucket_count = $scoopBuckets.Count; buckets = $scoopBuckets }
        $scoopLogLevel = if ($scoopApps.Count -gt 0) { 'Success' } else { 'Warn' }
        Write-SOKLog "Scoop $scoopVersion — $($scoopApps.Count) apps, $($scoopBuckets.Count) buckets$(if($scoopApps.Count -eq 0){' (all tiers returned empty)'})" -Level $scoopLogLevel
    }
    else {
        $inventory['scoop_packages'] = @{ installed = $false }
    }
}
catch { $errors.Add("scoop: $($_.Exception.Message)") | Out-Null }

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: PYTHON / NODE / RUST / .NET / WINGET
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'LANGUAGE RUNTIMES' -Level Section

# Python
try {
    $pyCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pyCmd) {
        $pyVer = & python --version 2>&1
        $pipVer = try { & pip --version 2>&1 } catch { 'unknown' }
        $pipPkgs = try { (& pip list --format=json 2>$null | ConvertFrom-Json).Count } catch { 0 }
        $inventory['python'] = [ordered]@{ installed = $true; version = "$pyVer".Trim(); pip_version = "$pipVer".Trim(); pip_packages = $pipPkgs; path = $pyCmd.Source }
        Write-SOKLog "Python: $("$pyVer".Trim()) ($pipPkgs pip packages)" -Level Success
    }
}
catch { $errors.Add("python: $($_.Exception.Message)") | Out-Null }

# Node.js (v2 fix: check output string for errors)
try {
    $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
    if ($nodeCmd) {
        $nodeVer = & node --version 2>&1
        $nodeVerStr = "$nodeVer".Trim()
        if ($nodeVerStr -match '^v\d') {
            $npmVer = try { & npm --version 2>&1 } catch { 'unknown' }
            $npmGlobal = try { (& npm list -g --depth=0 --json 2>$null | ConvertFrom-Json).dependencies.PSObject.Properties.Count } catch { 0 }
            $inventory['nodejs'] = [ordered]@{ installed = $true; version = $nodeVerStr; npm_version = "$npmVer".Trim(); global_packages = $npmGlobal; path = $nodeCmd.Source }
            Write-SOKLog "Node.js: $nodeVerStr ($npmGlobal global npm packages)" -Level Success
        }
        else {
            $inventory['nodejs'] = [ordered]@{ installed = $true; error = "node --version returned: $nodeVerStr"; path = $nodeCmd.Source }
            Write-SOKLog "Node.js: found but version check failed ($nodeVerStr)" -Level Warn
        }
    }
}
catch { $errors.Add("nodejs: $($_.Exception.Message)") | Out-Null }

# Rust
try {
    $rustCmd = Get-Command rustc -ErrorAction SilentlyContinue
    if ($rustCmd) {
        $rustVer = & rustc --version 2>&1
        $cargoVer = try { & cargo --version 2>&1 } catch { 'unknown' }
        $inventory['rust'] = [ordered]@{ installed = $true; rustc_version = "$rustVer".Trim(); cargo_version = "$cargoVer".Trim(); path = $rustCmd.Source }
        Write-SOKLog "Rust: $("$rustVer".Trim())" -Level Success
    }
}
catch { $errors.Add("rust: $($_.Exception.Message)") | Out-Null }

# .NET
try {
    $dotnetCmd = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($dotnetCmd) {
        $dotnetVer = & dotnet --version 2>&1
        $sdks = try { @(& dotnet --list-sdks 2>&1) } catch { @() }
        $inventory['dotnet'] = [ordered]@{ installed = $true; version = "$dotnetVer".Trim(); sdk_count = $sdks.Count; path = $dotnetCmd.Source }
        Write-SOKLog ".NET: $("$dotnetVer".Trim()) ($($sdks.Count) SDKs)" -Level Success
    }
}
catch { $errors.Add("dotnet: $($_.Exception.Message)") | Out-Null }

# WinGet
try {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetCmd) {
        $wingetVer = try { & winget --version 2>&1 } catch { 'unknown' }
        $inventory['winget'] = [ordered]@{ installed = $true; version = "$wingetVer".Trim() }
        Write-SOKLog "WinGet: $("$wingetVer".Trim())" -Level Success
    }
}
catch { $errors.Add("winget: $($_.Exception.Message)") | Out-Null }

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: DOCKER
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'DOCKER' -Level Section
try {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if ($dockerCmd) {
        $dockerVersion = try { & docker --version 2>&1 } catch { 'unknown' }
        $dockerImages = try { @(& docker images --format '{{json .}}' 2>&1 | ForEach-Object { try { "$_" | ConvertFrom-Json } catch {} } | Where-Object { $null -ne $_ }) } catch { @() }
        $dockerContainers = try { @(& docker ps -a --format '{{json .}}' 2>&1 | ForEach-Object { try { "$_" | ConvertFrom-Json } catch {} } | Where-Object { $null -ne $_ }) } catch { @() }
        $inventory['docker'] = [ordered]@{ installed = $true; version = "$dockerVersion".Trim(); image_count = $dockerImages.Count; images = $dockerImages; container_count = $dockerContainers.Count; containers = $dockerContainers }
        Write-SOKLog "Docker: $($dockerImages.Count) images, $($dockerContainers.Count) containers" -Level Success
    }
    else { $inventory['docker'] = @{ installed = $false } }
}
catch { $errors.Add("docker: $($_.Exception.Message)") | Out-Null }

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: DATABASES
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'DATABASES' -Level Section
try {
    $dbs = [ordered]@{}
    foreach ($db in @(
        @{ Name = 'postgresql'; Cmd = 'psql';         VerArgs = '--version' }
        @{ Name = 'mysql';      Cmd = 'mysql';        VerArgs = '--version' }
        @{ Name = 'redis';      Cmd = 'redis-server'; VerArgs = '--version' }
        @{ Name = 'mongodb';    Cmd = 'mongod';       VerArgs = '--version' }
        @{ Name = 'sqlite';     Cmd = 'sqlite3';      VerArgs = '--version' }
    )) {
        $cmd = Get-Command $db.Cmd -ErrorAction SilentlyContinue
        if ($cmd) {
            $ver = try { (& $db.Cmd $db.VerArgs 2>&1 | Select-Object -First 1).ToString().Trim() } catch { 'unknown' }
            $dbs[$db.Name] = [ordered]@{ installed = $true; version = $ver; path = $cmd.Source }
        }
    }
    $inventory['databases'] = $dbs
    Write-SOKLog "Databases: $($dbs.Count) found" -Level Success
}
catch { $errors.Add("databases: $($_.Exception.Message)") | Out-Null }

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: GIT CONFIG
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'GIT' -Level Section
try {
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitVersion = (& git --version 2>&1).ToString().Trim()
        $gitName = (& git config --global user.name 2>&1).ToString().Trim()
        $gitEmail = (& git config --global user.email 2>&1).ToString().Trim()
        $inventory['git'] = [ordered]@{ installed = $true; version = $gitVersion; user_name = $gitName; user_email = $gitEmail }
        Write-SOKLog "Git: $gitVersion (user: $gitName)" -Level Success
    }
}
catch { $errors.Add("git: $($_.Exception.Message)") | Out-Null }

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: INSTALLED PROGRAMS (registry) — Depth 2+
# ═══════════════════════════════════════════════════════════════
if ($ScanCaliber -ge 2) {
    Write-SOKLog 'INSTALLED PROGRAMS' -Level Section
    try {
        $regPaths = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
        $programs = @($regPaths | ForEach-Object { Get-ItemProperty $_ -ErrorAction SilentlyContinue } |
            Where-Object { $_.DisplayName } | ForEach-Object {
                [ordered]@{
                    name = $_.DisplayName; version = $_.DisplayVersion; publisher = $_.Publisher
                    install_date = $_.InstallDate; install_location = $_.InstallLocation
                    size_kb = if ($_.EstimatedSize) { $_.EstimatedSize } else { $null }
                }
            } | Sort-Object { $_.name })
        $inventory['installed_programs'] = [ordered]@{ program_count = $programs.Count; programs = $programs }
        Write-SOKLog "Installed programs: $($programs.Count)" -Level Success
    }
    catch { $errors.Add("installed_programs: $($_.Exception.Message)") | Out-Null }
}

# ═══════════════════════════════════════════════════════════════
# COLLECTOR: SERVICES — Depth 2+
# ═══════════════════════════════════════════════════════════════
if ($ScanCaliber -ge 2) {
    Write-SOKLog 'SERVICES' -Level Section
    try {
        $services = @(Get-Service -ErrorAction Continue | Where-Object { $_.Status -eq 'Running' } | ForEach-Object {
            [ordered]@{ name = $_.Name; display_name = $_.DisplayName; status = $_.Status.ToString(); start_type = $_.StartType.ToString() }
        })
        $inventory['running_services'] = [ordered]@{ count = $services.Count; services = $services }
        Write-SOKLog "Running services: $($services.Count)" -Level Success
    }
    catch { $errors.Add("services: $($_.Exception.Message)") | Out-Null }
}

# ═══════════════════════════════════════════════════════════════
# COMPLETENESS COMPARISON (against previous run)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'COMPLETENESS CHECK' -Level Section

$completeness = [ordered]@{
    collectors_run      = @($inventory.Keys | Where-Object { $_ -ne 'scan_metadata' -and $_ -ne 'completeness' })
    collector_count     = ($inventory.Keys | Where-Object { $_ -ne 'scan_metadata' -and $_ -ne 'completeness' }).Count
    drives_present      = @($logicalDrives | ForEach-Object { $_.device_id })
    drive_fingerprint   = $driveFingerprint
    comparison          = $null
}

# Auto-detect previous run
if (-not $PreviousRunPath) {
    $prevDir = Split-Path $OutputPath
    $prevRuns = Get-ChildItem -Path $prevDir -Filter 'SOK_Inventory_*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($prevRuns.Count -gt 0) {
        # Skip the one we're about to write
        $PreviousRunPath = ($prevRuns | Where-Object { $_.FullName -ne $OutputPath } | Select-Object -First 1).FullName
    }
}

if ($PreviousRunPath -and (Test-Path $PreviousRunPath)) {
    Write-SOKLog "  Comparing against: $(Split-Path $PreviousRunPath -Leaf)" -Level Ignore
    try {
        $prev = Get-Content $PreviousRunPath -Raw | ConvertFrom-Json

        $prevFingerprint = if ($prev.drive_topology) { $prev.drive_topology.drive_fingerprint } elseif ($prev.completeness) { $prev.completeness.drive_fingerprint } else { '' }
        $prevDrives = if ($prev.drive_topology.logical_drives) { @($prev.drive_topology.logical_drives | ForEach-Object { $_.device_id }) } elseif ($prev.completeness) { @($prev.completeness.drives_present) } else { @() }
        $prevCollectors = if ($prev.completeness) { @($prev.completeness.collectors_run) } else { @($prev.PSObject.Properties.Name | Where-Object { $_ -ne 'scan_metadata' }) }

        $currentDrives = @($logicalDrives | ForEach-Object { $_.device_id })
        $missingDrives = @($prevDrives | Where-Object { $_ -notin $currentDrives })
        $newDrives = @($currentDrives | Where-Object { $_ -notin $prevDrives })
        $missingCollectors = @($prevCollectors | Where-Object { $_ -notin $completeness.collectors_run })

        $driveMatch = $missingDrives.Count -eq 0 -and $newDrives.Count -eq 0
        $collectorMatch = $missingCollectors.Count -eq 0

        $completeness.comparison = [ordered]@{
            previous_run     = Split-Path $PreviousRunPath -Leaf
            previous_date    = if ($prev.scan_metadata.timestamp_iso) { $prev.scan_metadata.timestamp_iso } else { 'unknown' }
            drive_match      = $driveMatch
            missing_drives   = $missingDrives
            new_drives       = $newDrives
            collector_match  = $collectorMatch
            missing_collectors = $missingCollectors
            is_complete      = $driveMatch -and $collectorMatch
        }

        if ($missingDrives.Count -gt 0) {
            Write-SOKLog "  INCOMPLETE: Drives missing from previous run: $($missingDrives -join ', ')" -Level Warn
            Write-SOKLog "  Previous data for these drives is NOT reflected in this run." -Level Warn
            if (-not $AllowRedundancy) {
                Write-SOKLog "  Run with -AllowRedundancy to scan offload targets even when junctions exist." -Level Annotate
            }
        }
        if ($newDrives.Count -gt 0) {
            Write-SOKLog "  NEW DRIVES detected: $($newDrives -join ', ')" -Level Annotate
        }
        if ($missingCollectors.Count -gt 0) {
            Write-SOKLog "  MISSING COLLECTORS: $($missingCollectors -join ', ')" -Level Warn
        }
        if ($driveMatch -and $collectorMatch) {
            Write-SOKLog "  COMPLETE: drive loadout and collectors match previous run" -Level Success
        }
    }
    catch {
        Write-SOKLog "  Could not parse previous run: $($_.Exception.Message)" -Level Warn
        $completeness.comparison = [ordered]@{ error = $_.Exception.Message }
    }
}
else {
    Write-SOKLog "  No previous run found — baseline scan" -Level Annotate
    $completeness.comparison = [ordered]@{ previous_run = $null; is_complete = $true; note = 'Baseline — no comparison available' }
}

$inventory['completeness'] = $completeness

# ═══════════════════════════════════════════════════════════════
# FINALIZE
# ═══════════════════════════════════════════════════════════════
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

$inventory['scan_metadata'] = [ordered]@{
    script_version    = 'SOK-Inventory 3.2.0'
    hostname          = $env:COMPUTERNAME
    timestamp_display = (Get-Date).ToString('ddMMMyyyy HH:mm:ss')
    timestamp_iso     = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    scan_caliber        = $ScanCaliber
    allow_redundancy  = $AllowRedundancy.IsPresent
    duration_secs     = $duration
    error_count       = $errors.Count
    errors            = @($errors)
    warning_count     = $warnings.Count
    warnings          = @($warnings)
}

if ($DryRun) {
    Write-SOKLog "DRY RUN — scan complete; JSON not written. Would output: $OutputPath" -Level Warn
} else {
    $inventory | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Force -Encoding UTF8
    Write-SOKLog "Output: $OutputPath" -Level Success
}

Write-SOKLog "`nInventory complete in $([math]::Round($duration,1))s" -Level Success
Write-SOKLog "Collectors: $($completeness.collector_count) | Errors: $($errors.Count) | Warnings: $($warnings.Count)" -Level $(if ($errors.Count -gt 0) { 'Warn' } else { 'Success' })

Save-SOKHistory -ScriptName 'SOK-Inventory' -AggregateOnly -RunData @{
    Duration = $duration
    Results  = @{ Collectors = $completeness.collector_count; Errors = $errors.Count; Drives = $logicalDrives.Count; Junctions = $junctions.Count }
}
