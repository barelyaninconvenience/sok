#Requires -Version 7.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    SOK-PAST-BlankSlate — Historical State Audit and Reconciliation Tool for CLAY_PC

.DESCRIPTION
    Answers the question: "What is the accumulated historical state of this system,
    and what reconciliation actions should be taken?"

    Phases:
      1. Environment Probe      — Validate toolchain, discover drives, load common module
      2. Installed State Snap   — Software, packages, scheduled tasks, services
      3. Storage Topology Map   — Drive layout, usage, large files, orphan paths
      4. Storage Debt Audit     — Candidates for move/clean/reorganize on C: vs E:
      5. Structural Debt Audit  — Backup archives, deep nesting, redundant trees
      6. Drift Detection        — Compare current state to a saved reference snapshot
      7. Archive Consolidation  — Deduplicate and catalog scattered backup archives
      8. Reconciliation Plan    — Emit a prioritized action manifest (JSON + human report)
      9. Selective Repair       — Fix broken environment items gated by -DryRun

.PARAMETER DryRun
    When set, no destructive operations are performed. All actions are logged as
    [WOULD-DO] rather than executed. This is the safe default for first runs.

.PARAMETER SnapshotOnly
    Collect data and write snapshots but skip reconciliation plan generation.

.PARAMETER ReferenceDate
    ISO-8601 date string (e.g. "2025-10-01") of the reference snapshot to diff against.
    If omitted and a prior snapshot exists, the most recent prior snapshot is used.

.PARAMETER ScanRoots
    Override the default scan roots. Defaults to C:\ and E:\

.PARAMETER ArchiveScanPaths
    Explicit paths to scan for backup archives (zip, 7z, tar, bak). Defaults to
    common locations under C:\ and E:\

.EXAMPLE
    .\SOK-PAST-BlankSlate.ps1 -DryRun
    Full audit, no changes written to disk.

.EXAMPLE
    .\SOK-PAST-BlankSlate.ps1 -ReferenceDate "2025-10-01"
    Audit and diff against the October 2025 reference snapshot.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$DryRun,
    [switch]$SnapshotOnly,
    [string]$ReferenceDate,
    [string[]]$ScanRoots = @('C:\', 'E:\'),
    [string[]]$ArchiveScanPaths
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'   # surface errors without aborting all phases
$ProgressPreference    = 'SilentlyContinue'

# ─────────────────────────────────────────────────────────────────────────────
# REGION: Constants
# ─────────────────────────────────────────────────────────────────────────────

$SCRIPT_VERSION  = '1.0.0'
$SCRIPT_NAME     = 'SOK-PAST-BlankSlate'
$SOK_ROOT        = 'C:\Users\shelc\Documents\Journal\Projects\SOK'
$COMMON_MODULE   = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1'
$LOG_BASE        = Join-Path $SOK_ROOT 'Logs\BlankSlate'
$SNAPSHOT_BASE   = Join-Path $SOK_ROOT 'Snapshots\BlankSlate'
$ARCHIVE_CATALOG = Join-Path $SOK_ROOT 'Catalogs\ArchiveCatalog.json'

# Storage thresholds
$LARGE_FILE_THRESHOLD_GB   = 1.0
$DEEP_NEST_THRESHOLD       = 12          # directory depth before flagging
$BACKUP_REDUNDANCY_DAYS    = 30          # flag if >N day-old backup has a newer sibling
$ARCHIVE_EXTENSIONS        = @('.zip', '.7z', '.tar', '.gz', '.bz2', '.bak', '.rar', '.cab')
$OFFLOAD_TARGET_DRIVE      = 'E:'
$PRIMARY_DRIVE             = 'C:'
$STORAGE_DEBT_THRESHOLD_GB = 0.5        # files >= this size in "cold" paths are debt

# Paths considered cold/offloadable on C:
$COLD_PATH_PATTERNS = @(
    'C:\Users\shelc\Downloads',
    'C:\Users\shelc\Videos',
    'C:\Users\shelc\Music',
    'C:\Users\shelc\Documents\Journal\Projects\SOK\Archives',
    'C:\Users\shelc\AppData\Local\Temp',
    "$env:TEMP"
)

# Paths excluded from deep scans (noise sources)
$SCAN_EXCLUSIONS = @(
    'C:\Windows',
    'C:\Program Files\Windows Defender',
    'C:\ProgramData\Microsoft\Windows Defender',
    'C:\$Recycle.Bin',
    'C:\System Volume Information',
    'E:\System Volume Information',
    'E:\$Recycle.Bin'
)

# ─────────────────────────────────────────────────────────────────────────────
# REGION: Logging stubs (overwritten if SOK-Common loads)
# ─────────────────────────────────────────────────────────────────────────────

function Write-SOKLog {
    param([string]$Message, [string]$Level = 'INFO', [string]$Component = 'BlankSlate')
    $ts    = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $color = switch ($Level) {
        'WARN'  { 'Yellow'  }
        'ERROR' { 'Red'     }
        'DEBUG' { 'DarkGray'}
        default { 'Cyan'    }
    }
    Write-Host "[$ts][$Level][$Component] $Message" -ForegroundColor $color
    if ($script:LogFilePath -and (Test-Path (Split-Path $script:LogFilePath))) {
        "[$ts][$Level][$Component] $Message" | Out-File -FilePath $script:LogFilePath -Append -Encoding utf8
    }
}

function Show-SOKBanner {
    param([string]$Title)
    $line = '=' * 72
    Write-Host "`n$line" -ForegroundColor DarkCyan
    Write-Host "  $Title" -ForegroundColor White
    Write-Host "$line`n" -ForegroundColor DarkCyan
}

function Initialize-SOKLog {
    param([string]$LogDir, [string]$ScriptName)
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
    $ts   = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $path = Join-Path $LogDir "$ScriptName-$ts.log"
    $script:LogFilePath = $path
    return $path
}

function Get-ScriptLogDir { return $LOG_BASE }

function Save-SOKHistory {
    param([string]$Key, [object]$Value, [string]$StorePath)
    try {
        $store = if (Test-Path $StorePath) { Get-Content $StorePath -Raw | ConvertFrom-Json -AsHashtable } else { @{} }
        $store[$Key] = $Value
        $store | ConvertTo-Json -Depth 10 | Set-Content -Path $StorePath -Encoding utf8
    } catch {
        Write-SOKLog "Save-SOKHistory failed for key '$Key': $_" 'WARN'
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: Helper utilities
# ─────────────────────────────────────────────────────────────────────────────

function Format-Bytes {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return '{0:N2} MB' -f ($Bytes / 1MB) }
    if ($Bytes -ge 1KB) { return '{0:N2} KB' -f ($Bytes / 1KB) }
    return "$Bytes B"
}

function Get-DirectoryDepth {
    param([string]$Path)
    return ($Path.Split([System.IO.Path]::DirectorySeparatorChar) | Where-Object { $_ -ne '' }).Count
}

function Test-PathExcluded {
    param([string]$Path)
    foreach ($ex in $SCAN_EXCLUSIONS) {
        if ($Path.StartsWith($ex, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function New-SOKDirectory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-SOKLog "Created directory: $Path" 'DEBUG'
    }
}

function Invoke-Timed {
    param([string]$Label, [scriptblock]$Block)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $result = & $Block
    $sw.Stop()
    Write-SOKLog "$Label completed in $($sw.Elapsed.TotalSeconds.ToString('N1'))s" 'DEBUG'
    return $result
}

function Write-ActionRecord {
    param(
        [string]$Phase,
        [string]$Action,
        [string]$Target,
        [string]$Detail,
        [string]$Priority = 'MEDIUM',
        [bool]$Destructive = $false
    )
    $record = [pscustomobject]@{
        Timestamp   = (Get-Date -Format 'o')
        Phase       = $Phase
        Action      = $Action
        Target      = $Target
        Detail      = $Detail
        Priority    = $Priority
        Destructive = $Destructive
        DryRun      = $DryRun.IsPresent
    }
    $script:ReconciliationActions.Add($record) | Out-Null
    $tag = if ($Destructive -and $DryRun) { '[WOULD-DO]' } elseif ($Destructive) { '[EXECUTE]' } else { '[RECORD]' }
    Write-SOKLog "$tag [$Priority] $Action — $Target" 'INFO' $Phase
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 0: Bootstrap
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-Bootstrap {
    # Attempt to load SOK-Common
    $commonLoaded = $false
    if (Test-Path $COMMON_MODULE) {
        try {
            Import-Module $COMMON_MODULE -Force -ErrorAction Stop
            $commonLoaded = $true
            Write-Host "[Bootstrap] SOK-Common loaded from $COMMON_MODULE" -ForegroundColor Green
        } catch {
            Write-Host "[Bootstrap] SOK-Common found but failed to load: $_  — using stubs." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[Bootstrap] SOK-Common not found at $COMMON_MODULE — using built-in stubs." -ForegroundColor Yellow
    }

    # Ensure output directories exist
    foreach ($dir in @($LOG_BASE, $SNAPSHOT_BASE, (Split-Path $ARCHIVE_CATALOG))) {
        New-SOKDirectory $dir
    }

    # Initialize log
    $logPath = Initialize-SOKLog -LogDir $LOG_BASE -ScriptName $SCRIPT_NAME
    $script:LogFilePath = $logPath

    Show-SOKBanner "$SCRIPT_NAME v$SCRIPT_VERSION  |  DryRun=$($DryRun.IsPresent)  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm')"

    Write-SOKLog "Bootstrap complete. SOK-Common loaded: $commonLoaded" 'INFO' 'Bootstrap'
    Write-SOKLog "Log: $logPath" 'INFO' 'Bootstrap'
    Write-SOKLog "Snapshot base: $SNAPSHOT_BASE" 'INFO' 'Bootstrap'

    return @{
        CommonLoaded = $commonLoaded
        LogPath      = $logPath
        RunId        = (Get-Date -Format 'yyyyMMdd-HHmmss')
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 1: Environment Probe
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-EnvironmentProbe {
    Show-SOKBanner 'Phase 1 — Environment Probe'

    $probe = [ordered]@{
        Timestamp       = (Get-Date -Format 'o')
        Hostname        = $env:COMPUTERNAME
        Username        = $env:USERNAME
        PSVersion       = $PSVersionTable.PSVersion.ToString()
        OS              = (Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
        OSBuildNumber   = (Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber)
        OSLastBoot      = (Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime)
        UptimeDays      = [math]::Round(((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).TotalDays, 2)
        CPUModel        = (Get-CimInstance Win32_Processor | Select-Object -First 1 -ExpandProperty Name)
        LogicalCores    = (Get-CimInstance Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
        TotalRAM_GB     = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        AvailableRAM_GB = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
        Drives          = @()
        EnvVariables    = @{}
        PowerShellPath  = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
        GitVersion      = $null
        PythonVersion   = $null
        NodeVersion     = $null
        DotNetVersions  = @()
        Broken          = @()
    }

    # Drive topology
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match '^[A-Z]:\\$' }
    $probe.Drives = $drives | ForEach-Object {
        $di = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($_.Name):'" -ErrorAction SilentlyContinue
        [ordered]@{
            Letter     = $_.Name
            Root       = $_.Root
            Used_GB    = [math]::Round($_.Used / 1GB, 2)
            Free_GB    = [math]::Round($_.Free / 1GB, 2)
            Total_GB   = if ($di) { [math]::Round($di.Size / 1GB, 2) } else { $null }
            DriveType  = if ($di) { $di.DriveType } else { $null }
            FileSystem = if ($di) { $di.FileSystem } else { $null }
            VolumeLabel= if ($di) { $di.VolumeName } else { $null }
        }
    }

    # Key env variables
    $interestingEnv = @('PATH', 'TEMP', 'TMP', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA',
                        'PROGRAMFILES', 'PROGRAMFILES(X86)', 'PYTHONPATH', 'NODE_PATH', 'JAVA_HOME', 'GOPATH')
    foreach ($v in $interestingEnv) {
        $val = [System.Environment]::GetEnvironmentVariable($v)
        if ($val) { $probe.EnvVariables[$v] = $val }
    }

    # Toolchain versions
    $toolChecks = @(
        @{ Name = 'Git';    Cmd = 'git';    Args = '--version' },
        @{ Name = 'Python'; Cmd = 'python'; Args = '--version' },
        @{ Name = 'Node';   Cmd = 'node';   Args = '--version' },
        @{ Name = 'pip';    Cmd = 'pip';    Args = '--version' }
    )
    foreach ($t in $toolChecks) {
        try {
            $out = & $t.Cmd $t.Args 2>&1
            $probe["$($t.Name)Version"] = ($out -join ' ').Trim()
        } catch {
            $probe["$($t.Name)Version"] = 'NOT FOUND'
        }
    }

    # .NET versions
    try {
        $probe.DotNetVersions = (& dotnet --list-runtimes 2>&1) -join "`n"
    } catch {
        $probe.DotNetVersions = 'dotnet CLI not found'
    }

    # PATH integrity check — find entries that do not exist
    $pathEntries = $env:PATH -split ';' | Where-Object { $_ -ne '' }
    $brokenPaths = $pathEntries | Where-Object { -not (Test-Path $_) } | ForEach-Object {
        [ordered]@{ Type = 'BrokenPATH'; Value = $_ }
    }
    $probe.Broken += $brokenPaths

    # Check for broken scheduled tasks (status = 'Unknown')
    try {
        $badTasks = Get-ScheduledTask -ErrorAction Stop |
            Where-Object { $_.State -eq 'Unknown' } |
            ForEach-Object {
                [ordered]@{ Type = 'BrokenScheduledTask'; Name = $_.TaskName; Path = $_.TaskPath }
            }
        $probe.Broken += $badTasks
    } catch {
        Write-SOKLog "Scheduled task probe failed: $_" 'WARN' 'EnvProbe'
    }

    # Check for services in stuck states
    try {
        $stuckSvc = Get-Service -ErrorAction Stop |
            Where-Object { $_.Status -in @('StartPending','StopPending','ContinuePending','PausePending') } |
            ForEach-Object {
                [ordered]@{ Type = 'StuckService'; Name = $_.Name; Status = $_.Status.ToString() }
            }
        $probe.Broken += $stuckSvc
    } catch {
        Write-SOKLog "Service probe failed: $_" 'WARN' 'EnvProbe'
    }

    # Check TEMP directory accessibility
    foreach ($tmpPath in @($env:TEMP, $env:TMP) | Select-Object -Unique) {
        if ($tmpPath -and -not (Test-Path $tmpPath)) {
            $probe.Broken += [ordered]@{ Type = 'MissingTEMP'; Value = $tmpPath }
        }
    }

    # Report broken items
    foreach ($b in $probe.Broken) {
        Write-SOKLog "BROKEN: $($b.Type) — $($b | ConvertTo-Json -Compress)" 'WARN' 'EnvProbe'
        Write-ActionRecord -Phase 'EnvProbe' -Action 'RepairBrokenItem' -Target ($b.Value ?? $b.Name ?? '') `
            -Detail ($b | ConvertTo-Json -Compress) -Priority 'HIGH' -Destructive $true
    }

    Write-SOKLog "Drives found: $($probe.Drives.Count)  Broken items: $($probe.Broken.Count)" 'INFO' 'EnvProbe'
    return $probe
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 2: Installed State Snapshot
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-InstalledStateSnapshot {
    Show-SOKBanner 'Phase 2 — Installed State Snapshot'

    $snapshot = [ordered]@{
        Timestamp      = (Get-Date -Format 'o')
        Programs       = @()
        WingetPackages = @()
        ScoopPackages  = @()
        PipPackages    = @()
        NpmGlobal      = @()
        PowerShellMods = @()
        ScheduledTasks = @()
        Services       = @()
        StartupEntries = @()
        WindowsFeatures= @()
    }

    # Installed programs via registry (more reliable than Win32_Product)
    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $programs = foreach ($rp in $regPaths) {
        try {
            Get-ItemProperty $rp -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName } |
                Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, InstallLocation, EstimatedSize
        } catch {}
    }
    $snapshot.Programs = $programs | Sort-Object DisplayName -Unique | ForEach-Object {
        [ordered]@{
            Name        = $_.DisplayName
            Version     = $_.DisplayVersion
            Publisher   = $_.Publisher
            InstallDate = $_.InstallDate
            Location    = $_.InstallLocation
            Size_KB     = $_.EstimatedSize
        }
    }

    # Winget packages
    try {
        $wgOut = & winget list --accept-source-agreements 2>&1
        if ($LASTEXITCODE -eq 0) {
            $lines = $wgOut | Select-Object -Skip 3 | Where-Object { $_ -match '\S' }
            $snapshot.WingetPackages = $lines | ForEach-Object {
                $parts = $_ -split '\s{2,}'
                if ($parts.Count -ge 2) {
                    [ordered]@{
                        Name    = $parts[0].Trim()
                        Id      = $parts[1].Trim()
                        Version = if ($parts.Count -ge 3) { $parts[2].Trim() } else { '' }
                    }
                }
            } | Where-Object { $_ }
        }
    } catch {
        Write-SOKLog "winget list failed: $_" 'WARN' 'InstalledState'
    }

    # Scoop packages
    try {
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            $scoopOut = & scoop list 2>&1
            $snapshot.ScoopPackages = ($scoopOut | Select-Object -Skip 1 | Where-Object { $_ -match '^\s+\S' }) |
                ForEach-Object {
                    $parts = $_.Trim() -split '\s+'
                    [ordered]@{ Name = $parts[0]; Version = if ($parts.Count -gt 1) { $parts[1] } else { '' } }
                }
        }
    } catch {
        Write-SOKLog "scoop list failed: $_" 'WARN' 'InstalledState'
    }

    # pip packages (global)
    try {
        if (Get-Command pip -ErrorAction SilentlyContinue) {
            $pipOut = & pip list --format=json 2>&1
            $snapshot.PipPackages = $pipOut | ConvertFrom-Json -ErrorAction SilentlyContinue
        }
    } catch {
        Write-SOKLog "pip list failed: $_" 'WARN' 'InstalledState'
    }

    # npm global packages
    try {
        if (Get-Command npm -ErrorAction SilentlyContinue) {
            $npmOut = & npm list -g --depth=0 --json 2>&1
            $npmData = $npmOut | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($npmData?.dependencies) {
                $snapshot.NpmGlobal = $npmData.dependencies.PSObject.Properties | ForEach-Object {
                    [ordered]@{ Name = $_.Name; Version = $_.Value.version }
                }
            }
        }
    } catch {
        Write-SOKLog "npm list failed: $_" 'WARN' 'InstalledState'
    }

    # PowerShell modules
    $snapshot.PowerShellMods = Get-Module -ListAvailable |
        Sort-Object Name, Version -Unique |
        Select-Object Name, Version, ModuleType, @{N='Path';E={$_.ModuleBase}} |
        ForEach-Object {
            [ordered]@{ Name = $_.Name; Version = $_.Version.ToString(); Type = $_.ModuleType.ToString(); Path = $_.Path }
        }

    # Scheduled tasks (enabled, non-Microsoft)
    try {
        $snapshot.ScheduledTasks = Get-ScheduledTask -ErrorAction Stop |
            Where-Object { $_.State -ne 'Disabled' -and $_.TaskPath -notmatch '\\Microsoft\\' } |
            ForEach-Object {
                $info = $_ | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue
                [ordered]@{
                    Name       = $_.TaskName
                    Path       = $_.TaskPath
                    State      = $_.State.ToString()
                    LastRun    = $info?.LastRunTime
                    LastResult = $info?.LastTaskResult
                    NextRun    = $info?.NextRunTime
                }
            }
    } catch {
        Write-SOKLog "ScheduledTask snapshot failed: $_" 'WARN' 'InstalledState'
    }

    # Auto-start services
    $snapshot.Services = Get-Service -ErrorAction SilentlyContinue |
        Where-Object { $_.StartType -eq 'Automatic' } |
        ForEach-Object {
            [ordered]@{
                Name      = $_.Name
                Display   = $_.DisplayName
                Status    = $_.Status.ToString()
                StartType = $_.StartType.ToString()
            }
        }

    # Startup registry entries
    $startupKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
    )
    $snapshot.StartupEntries = foreach ($sk in $startupKeys) {
        try {
            Get-ItemProperty $sk -ErrorAction SilentlyContinue | ForEach-Object {
                $props = $_.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
                foreach ($p in $props) {
                    [ordered]@{ Hive = $sk; Name = $p.Name; Value = $p.Value }
                }
            }
        } catch {}
    }

    # Windows optional features
    try {
        $snapshot.WindowsFeatures = Get-WindowsOptionalFeature -Online -ErrorAction Stop |
            Where-Object { $_.State -eq 'Enabled' } |
            Select-Object FeatureName, State |
            ForEach-Object { [ordered]@{ Feature = $_.FeatureName; State = $_.State.ToString() } }
    } catch {
        Write-SOKLog "WindowsOptionalFeature probe skipped: $_" 'WARN' 'InstalledState'
    }

    Write-SOKLog "Programs: $($snapshot.Programs.Count)  PSModules: $($snapshot.PowerShellMods.Count)  Tasks: $($snapshot.ScheduledTasks.Count)" 'INFO' 'InstalledState'
    return $snapshot
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 3: Storage Topology Map
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-StorageTopologyMap {
    param([string[]]$Roots)

    Show-SOKBanner 'Phase 3 — Storage Topology Map'

    $topology = [ordered]@{
        Timestamp        = (Get-Date -Format 'o')
        DriveMap         = @()
        LargeFiles       = @()
        TopFoldersBySize = @()
        RecentlyModified = @()
        OldLargeFiles    = @()
    }

    # Per-drive summary
    $topology.DriveMap = $Roots | ForEach-Object {
        $letter = $_ -replace '\\',''
        $di = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$letter'" -ErrorAction SilentlyContinue
        if ($di) {
            [ordered]@{
                Drive       = $letter
                Total_GB    = [math]::Round($di.Size / 1GB, 2)
                Free_GB     = [math]::Round($di.FreeSpace / 1GB, 2)
                Used_GB     = [math]::Round(($di.Size - $di.FreeSpace) / 1GB, 2)
                UsedPct     = [math]::Round((($di.Size - $di.FreeSpace) / $di.Size) * 100, 1)
                FileSystem  = $di.FileSystem
                VolumeLabel = $di.VolumeName
            }
        }
    }

    # Large file scan
    Write-SOKLog "Scanning for large files (>= $LARGE_FILE_THRESHOLD_GB GB)..." 'INFO' 'StorageTopo'
    $thresholdBytes = [long]($LARGE_FILE_THRESHOLD_GB * 1GB)
    $largeFiles     = [System.Collections.Generic.List[object]]::new()
    $now            = Get-Date
    $cutoffOld      = $now.AddDays(-365)
    $cutoffRecent   = $now.AddDays(-7)

    foreach ($root in $Roots) {
        try {
            Get-ChildItem -Path $root -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Length -ge $thresholdBytes -and
                    -not (Test-PathExcluded $_.FullName)
                } |
                ForEach-Object {
                    $rec = [ordered]@{
                        Path       = $_.FullName
                        Size_GB    = [math]::Round($_.Length / 1GB, 3)
                        LastWrite  = $_.LastWriteTime
                        LastAccess = $_.LastAccessTime
                        Extension  = $_.Extension.ToLower()
                        AgeDays    = [math]::Round(($now - $_.LastWriteTime).TotalDays, 0)
                    }
                    $largeFiles.Add($rec)
                }
        } catch {
            Write-SOKLog "Large file scan error at $root $_" 'WARN' 'StorageTopo'
        }
    }

    $topology.LargeFiles       = $largeFiles | Sort-Object Size_GB -Descending
    $topology.OldLargeFiles    = $largeFiles | Where-Object { $_.LastWrite -lt $cutoffOld } | Sort-Object Size_GB -Descending
    $topology.RecentlyModified = $largeFiles | Where-Object { $_.LastWrite -gt $cutoffRecent } | Sort-Object LastWrite -Descending

    # Top folders by size (first-level under each root)
    $folderSizes = [System.Collections.Generic.List[object]]::new()
    foreach ($root in $Roots) {
        try {
            $firstLevel = Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue |
                Where-Object { -not (Test-PathExcluded $_.FullName) }
            foreach ($dir in $firstLevel) {
                try {
                    $size = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                    $folderSizes.Add([ordered]@{
                        Path    = $dir.FullName
                        Size_GB = [math]::Round(($size ?? 0) / 1GB, 3)
                    })
                } catch {}
            }
        } catch {
            Write-SOKLog "Folder size scan error at $root $_" 'WARN' 'StorageTopo'
        }
    }
    $topology.TopFoldersBySize = $folderSizes | Sort-Object Size_GB -Descending | Select-Object -First 40

    Write-SOKLog "Large files found: $($topology.LargeFiles.Count)  Old large: $($topology.OldLargeFiles.Count)" 'INFO' 'StorageTopo'
    return $topology
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 4: Storage Debt Audit
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-StorageDebtAudit {
    param([object]$Topology)

    Show-SOKBanner 'Phase 4 — Storage Debt Audit'

    $debt = [ordered]@{
        Timestamp         = (Get-Date -Format 'o')
        ColdFileDebt      = @()
        TempDebt          = @()
        DownloadDebt      = @()
        DuplicateHints    = @()
        OffloadCandidates = @()
        TotalDebt_GB      = 0.0
    }

    $thresholdBytes = [long]($STORAGE_DEBT_THRESHOLD_GB * 1GB)
    $now            = Get-Date
    $cutoffDownload = $now.AddDays(-30)

    # Cold path debt
    foreach ($coldPath in $COLD_PATH_PATTERNS) {
        if (-not (Test-Path $coldPath)) { continue }
        try {
            $files = Get-ChildItem -Path $coldPath -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Length -ge $thresholdBytes }
            foreach ($f in $files) {
                $rec = [ordered]@{
                    Path     = $f.FullName
                    Size_GB  = [math]::Round($f.Length / 1GB, 3)
                    AgeDays  = [math]::Round(($now - $f.LastWriteTime).TotalDays, 0)
                    ColdPath = $coldPath
                    Reason   = 'LargeFileInColdPath'
                }
                $debt.ColdFileDebt      += $rec
                $debt.OffloadCandidates += $rec
            }
        } catch {
            Write-SOKLog "Cold path scan failed at $coldPath $_" 'WARN' 'StorageDebt'
        }
    }

    # Temp debt
    foreach ($tmpPath in @($env:TEMP, $env:TMP, 'C:\Windows\Temp') | Select-Object -Unique) {
        if (-not (Test-Path $tmpPath)) { continue }
        try {
            $items = Get-ChildItem -Path $tmpPath -Recurse -ErrorAction SilentlyContinue
            $totalSize = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum ?? 0
            $fileCount = ($items | Where-Object { -not $_.PSIsContainer }).Count
            $debt.TempDebt += [ordered]@{
                Path         = $tmpPath
                TotalSize_GB = [math]::Round($totalSize / 1GB, 3)
                FileCount    = $fileCount
                Reason       = 'TemporaryFilesAccumulation'
            }
        } catch {}
    }

    # Downloads older than 30 days
    $downloadsPath = 'C:\Users\shelc\Downloads'
    if (Test-Path $downloadsPath) {
        try {
            $oldDownloads = Get-ChildItem -Path $downloadsPath -File -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt $cutoffDownload }
            $totalOld = ($oldDownloads | Measure-Object -Property Length -Sum).Sum ?? 0
            foreach ($f in $oldDownloads | Sort-Object Length -Descending | Select-Object -First 50) {
                $debt.DownloadDebt += [ordered]@{
                    Path    = $f.FullName
                    Size_MB = [math]::Round($f.Length / 1MB, 2)
                    AgeDays = [math]::Round(($now - $f.LastWriteTime).TotalDays, 0)
                    Reason  = 'StaleDownload'
                }
            }
            Write-SOKLog "Downloads debt: $(Format-Bytes $totalOld) in $($oldDownloads.Count) files older than 30d" 'INFO' 'StorageDebt'
        } catch {
            Write-SOKLog "Downloads scan failed: $_" 'WARN' 'StorageDebt'
        }
    }

    # Duplicate hint detection (same filename + same size, different paths)
    if ($Topology.LargeFiles.Count -gt 0) {
        $grouped = $Topology.LargeFiles |
            Group-Object { "$($_.Size_GB)_$(Split-Path $_.Path -Leaf)" } |
            Where-Object { $_.Count -gt 1 }
        foreach ($g in $grouped) {
            $debt.DuplicateHints += [ordered]@{
                Key            = $g.Name
                Paths          = $g.Group.Path
                Count          = $g.Count
                TotalWaste_GB  = [math]::Round($g.Group[0].Size_GB * ($g.Count - 1), 3)
                Reason         = 'SameNameAndSizeDuplicate'
            }
        }
    }

    # Compute total debt estimate
    $coldTotal = ($debt.ColdFileDebt    | Measure-Object -Property Size_GB     -Sum).Sum ?? 0
    $tempTotal = ($debt.TempDebt        | Measure-Object -Property TotalSize_GB -Sum).Sum ?? 0
    $dupTotal  = ($debt.DuplicateHints  | Measure-Object -Property TotalWaste_GB -Sum).Sum ?? 0
    $debt.TotalDebt_GB = [math]::Round($coldTotal + $tempTotal + $dupTotal, 2)

    # Emit action records
    foreach ($item in $debt.ColdFileDebt) {
        Write-ActionRecord -Phase 'StorageDebt' -Action 'OffloadFile' `
            -Target $item.Path `
            -Detail "Size: $($item.Size_GB) GB  Age: $($item.AgeDays)d  -> $OFFLOAD_TARGET_DRIVE" `
            -Priority 'MEDIUM' -Destructive $true
    }
    foreach ($item in $debt.TempDebt) {
        Write-ActionRecord -Phase 'StorageDebt' -Action 'CleanTempDir' `
            -Target $item.Path `
            -Detail "Size: $($item.TotalSize_GB) GB  Files: $($item.FileCount)" `
            -Priority 'LOW' -Destructive $true
    }
    foreach ($item in $debt.DuplicateHints) {
        Write-ActionRecord -Phase 'StorageDebt' -Action 'ReviewDuplicate' `
            -Target ($item.Paths -join ' | ') `
            -Detail "Potential waste: $($item.TotalWaste_GB) GB" `
            -Priority 'MEDIUM' -Destructive $false
    }

    Write-SOKLog "Total estimated storage debt: $($debt.TotalDebt_GB) GB" 'INFO' 'StorageDebt'
    return $debt
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 5: Structural Debt Audit
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-StructuralDebtAudit {
    param([string[]]$Roots)

    Show-SOKBanner 'Phase 5 — Structural Debt Audit'

    $structDebt = [ordered]@{
        Timestamp          = (Get-Date -Format 'o')
        DeepNestViolations = @()
        BackupRedundancy   = @()
        FlattenedPaths     = @()
        EmptyDirectories   = @()
        OrphanedProfiles   = @()
    }

    $userRoot = 'C:\Users\shelc'

    # Deep nesting violations
    Write-SOKLog "Scanning for deep nesting (>$DEEP_NEST_THRESHOLD levels)..." 'INFO' 'StructDebt'
    try {
        Get-ChildItem -Path $userRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object {
                (Get-DirectoryDepth $_.FullName) -gt $DEEP_NEST_THRESHOLD -and
                -not (Test-PathExcluded $_.FullName)
            } |
            Select-Object -First 200 |
            ForEach-Object {
                $depth = Get-DirectoryDepth $_.FullName
                $structDebt.DeepNestViolations += [ordered]@{
                    Path   = $_.FullName
                    Depth  = $depth
                    Reason = 'ExcessiveNesting'
                }
            }
    } catch {
        Write-SOKLog "Deep nest scan failed: $_" 'WARN' 'StructDebt'
    }

    # Backup redundancy
    $backupPatterns = @(
        '\bbackup\b', '\barchive\b', '\bold\b', '\bcopy\b', '\bbak\b',
        '_\d{4}[-_]\d{2}[-_]\d{2}', '[-_]v\d+', '\(\d+\)$', '[-_]copy'
    )
    $backupRegex = ($backupPatterns -join '|')

    try {
        $suspectDirs = Get-ChildItem -Path $userRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match $backupRegex -and
                -not (Test-PathExcluded $_.FullName)
            } |
            Select-Object -First 500

        $grouped = $suspectDirs | Group-Object { $_.Parent.FullName }
        foreach ($g in $grouped | Where-Object { $_.Count -gt 1 }) {
            $latest     = $g.Group | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $candidates = $g.Group | Where-Object { $_.FullName -ne $latest.FullName } |
                ForEach-Object {
                    [ordered]@{
                        Path    = $_.FullName
                        AgeDays = [math]::Round(((Get-Date) - $_.LastWriteTime).TotalDays, 0)
                    }
                }
            if ($candidates) {
                $structDebt.BackupRedundancy += [ordered]@{
                    Parent   = $g.Name
                    Latest   = $latest.FullName
                    Obsolete = $candidates
                    Count    = $g.Count
                    Reason   = 'VersionedBackupRedundancy'
                }
            }
        }
    } catch {
        Write-SOKLog "Backup redundancy scan failed: $_" 'WARN' 'StructDebt'
    }

    # Flattened paths: directories that contain only a single file in their entire subtree
    try {
        $singleFileDirs = Get-ChildItem -Path $userRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { -not (Test-PathExcluded $_.FullName) } |
            Where-Object {
                $children  = Get-ChildItem -Path $_.FullName -Recurse -ErrorAction SilentlyContinue
                $fileCount = ($children | Where-Object { -not $_.PSIsContainer }).Count
                $dirCount  = ($children | Where-Object { $_.PSIsContainer }).Count
                $fileCount -eq 1 -and $dirCount -ge 2
            } |
            Select-Object -First 100 |
            ForEach-Object {
                $f = Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
                [ordered]@{
                    ContainerPath = $_.FullName
                    SingleFile    = $f?.FullName
                    Depth         = Get-DirectoryDepth $_.FullName
                    Reason        = 'LoneFileInDeepHierarchy'
                }
            }
        $structDebt.FlattenedPaths = $singleFileDirs
    } catch {
        Write-SOKLog "Flattened path scan failed: $_" 'WARN' 'StructDebt'
    }

    # Empty directories
    try {
        $emptyDirs = Get-ChildItem -Path $userRoot -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object {
                -not (Test-PathExcluded $_.FullName) -and
                (Get-ChildItem -Path $_.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0
            } |
            Select-Object -First 500 |
            ForEach-Object { [ordered]@{ Path = $_.FullName; Reason = 'EmptyDirectory' } }
        $structDebt.EmptyDirectories = $emptyDirs
    } catch {
        Write-SOKLog "Empty dir scan failed: $_" 'WARN' 'StructDebt'
    }

    # Orphaned user profiles
    try {
        $otherProfiles = Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^(Public|Default|All Users|shelc)$' }
        foreach ($p in $otherProfiles) {
            $ageDays = [math]::Round(((Get-Date) - $p.LastWriteTime).TotalDays, 0)
            if ($ageDays -gt 90) {
                $structDebt.OrphanedProfiles += [ordered]@{
                    Path    = $p.FullName
                    AgeDays = $ageDays
                    Reason  = 'StaleUserProfile'
                }
            }
        }
    } catch {
        Write-SOKLog "Profile scan failed: $_" 'WARN' 'StructDebt'
    }

    # Emit action records
    foreach ($v in $structDebt.DeepNestViolations | Select-Object -First 20) {
        Write-ActionRecord -Phase 'StructDebt' -Action 'ReviewDeepNesting' `
            -Target $v.Path -Detail "Depth: $($v.Depth)" -Priority 'LOW'
    }
    foreach ($r in $structDebt.BackupRedundancy) {
        Write-ActionRecord -Phase 'StructDebt' -Action 'RemoveObsoleteBackups' `
            -Target $r.Parent -Detail "Latest: $($r.Latest)  Obsolete: $($r.Obsolete.Count)" `
            -Priority 'MEDIUM' -Destructive $true
    }
    foreach ($e in $structDebt.EmptyDirectories | Select-Object -First 10) {
        Write-ActionRecord -Phase 'StructDebt' -Action 'RemoveEmptyDirectory' `
            -Target $e.Path -Detail 'EmptyDirectory' -Priority 'LOW' -Destructive $true
    }
    foreach ($op in $structDebt.OrphanedProfiles) {
        Write-ActionRecord -Phase 'StructDebt' -Action 'ReviewOrphanedProfile' `
            -Target $op.Path -Detail "Age: $($op.AgeDays) days" -Priority 'HIGH'
    }

    Write-SOKLog "Deep nest violations: $($structDebt.DeepNestViolations.Count)  Backup redundancy groups: $($structDebt.BackupRedundancy.Count)  Empty dirs: $($structDebt.EmptyDirectories.Count)" 'INFO' 'StructDebt'
    return $structDebt
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 6: Drift Detection
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-DriftDetection {
    param(
        [object]$CurrentInstalled,
        [object]$CurrentEnv,
        [string]$ReferenceDate
    )

    Show-SOKBanner 'Phase 6 — Drift Detection'

    $drift = [ordered]@{
        Timestamp        = (Get-Date -Format 'o')
        ReferenceUsed    = $null
        ReferenceDate    = $null
        AddedPrograms    = @()
        RemovedPrograms  = @()
        AddedServices    = @()
        RemovedServices  = @()
        AddedTasks       = @()
        RemovedTasks     = @()
        AddedPSModules   = @()
        RemovedPSModules = @()
        PathChanges      = @()
        DriveChanges     = @()
        NoPriorSnapshot  = $false
    }

    # Find reference snapshot
    $refSnapshot = $null
    $snapshots   = Get-ChildItem -Path $SNAPSHOT_BASE -Filter 'installed-*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime

    if ($ReferenceDate) {
        $refDt   = [datetime]::Parse($ReferenceDate)
        $refFile = $snapshots | Where-Object { $_.LastWriteTime -le $refDt } | Select-Object -Last 1
        if (-not $refFile) {
            Write-SOKLog "No snapshot found on or before $ReferenceDate" 'WARN' 'DriftDetection'
        } else {
            $refSnapshot          = Get-Content $refFile.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            $drift.ReferenceUsed  = $refFile.FullName
            $drift.ReferenceDate  = $refFile.LastWriteTime.ToString('o')
        }
    } elseif ($snapshots.Count -ge 2) {
        $refFile              = $snapshots[-2]
        $refSnapshot          = Get-Content $refFile.FullName -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
        $drift.ReferenceUsed  = $refFile.FullName
        $drift.ReferenceDate  = $refFile.LastWriteTime.ToString('o')
    } else {
        Write-SOKLog "No prior snapshot available for drift comparison." 'INFO' 'DriftDetection'
        $drift.NoPriorSnapshot = $true
        return $drift
    }

    if (-not $refSnapshot) {
        Write-SOKLog "Could not parse reference snapshot." 'WARN' 'DriftDetection'
        $drift.NoPriorSnapshot = $true
        return $drift
    }

    Write-SOKLog "Comparing against snapshot: $($drift.ReferenceUsed)" 'INFO' 'DriftDetection'

    function Get-SetDiff {
        param([object[]]$Old, [object[]]$New, [string]$KeyProp)
        $oldKeys = $Old | ForEach-Object { $_.$KeyProp }
        $newKeys = $New | ForEach-Object { $_.$KeyProp }
        $added   = $New | Where-Object { $_.$KeyProp -notin $oldKeys }
        $removed = $Old | Where-Object { $_.$KeyProp -notin $newKeys }
        return @{ Added = $added; Removed = $removed }
    }

    # Programs diff
    $progDiff = Get-SetDiff -Old @($refSnapshot.Programs) -New @($CurrentInstalled.Programs) -KeyProp 'Name'
    $drift.AddedPrograms   = @($progDiff.Added   | ForEach-Object { [ordered]@{ Name = $_.Name; Version = $_.Version } })
    $drift.RemovedPrograms = @($progDiff.Removed | ForEach-Object { [ordered]@{ Name = $_.Name; Version = $_.Version } })

    # Services diff
    $svcDiff = Get-SetDiff -Old @($refSnapshot.Services) -New @($CurrentInstalled.Services) -KeyProp 'Name'
    $drift.AddedServices   = @($svcDiff.Added   | ForEach-Object { [ordered]@{ Name = $_.Name; Display = $_.Display } })
    $drift.RemovedServices = @($svcDiff.Removed | ForEach-Object { [ordered]@{ Name = $_.Name; Display = $_.Display } })

    # Scheduled tasks diff
    $taskDiff = Get-SetDiff -Old @($refSnapshot.ScheduledTasks) -New @($CurrentInstalled.ScheduledTasks) -KeyProp 'Name'
    $drift.AddedTasks   = @($taskDiff.Added   | ForEach-Object { [ordered]@{ Name = $_.Name; Path = $_.Path } })
    $drift.RemovedTasks = @($taskDiff.Removed | ForEach-Object { [ordered]@{ Name = $_.Name; Path = $_.Path } })

    # PS Modules diff
    $modDiff = Get-SetDiff -Old @($refSnapshot.PowerShellMods) -New @($CurrentInstalled.PowerShellMods) -KeyProp 'Name'
    $drift.AddedPSModules   = @($modDiff.Added   | ForEach-Object { [ordered]@{ Name = $_.Name; Version = $_.Version } })
    $drift.RemovedPSModules = @($modDiff.Removed | ForEach-Object { [ordered]@{ Name = $_.Name; Version = $_.Version } })

    # Drive changes
    if ($refSnapshot.Drives) {
        $driveDiff = Get-SetDiff -Old @($refSnapshot.Drives) -New @($CurrentEnv.Drives) -KeyProp 'Letter'
        if ($driveDiff.Added.Count -gt 0 -or $driveDiff.Removed.Count -gt 0) {
            $drift.DriveChanges = [ordered]@{
                Added   = @($driveDiff.Added)
                Removed = @($driveDiff.Removed)
            }
        }
    }

    # Emit action records
    foreach ($p in $drift.AddedPrograms | Select-Object -First 30) {
        Write-ActionRecord -Phase 'DriftDetection' -Action 'ReviewNewProgram' `
            -Target $p.Name -Detail "Version: $($p.Version)  (added since $($drift.ReferenceDate))" -Priority 'INFO'
    }
    foreach ($t in $drift.AddedTasks) {
        Write-ActionRecord -Phase 'DriftDetection' -Action 'ReviewNewScheduledTask' `
            -Target $t.Name -Detail "Path: $($t.Path)" -Priority 'MEDIUM'
    }

    Write-SOKLog "Drift — Programs: +$($drift.AddedPrograms.Count)/-$($drift.RemovedPrograms.Count)  Services: +$($drift.AddedServices.Count)/-$($drift.RemovedServices.Count)  Tasks: +$($drift.AddedTasks.Count)/-$($drift.RemovedTasks.Count)" 'INFO' 'DriftDetection'
    return $drift
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 7: Archive Consolidation
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-ArchiveConsolidation {
    param([string[]]$ScanPaths)

    Show-SOKBanner 'Phase 7 — Archive Consolidation'

    if (-not $ScanPaths -or $ScanPaths.Count -eq 0) {
        $ScanPaths = @(
            'C:\Users\shelc\Downloads',
            'C:\Users\shelc\Documents',
            'C:\Users\shelc\Desktop',
            'C:\Users\shelc\Documents\Journal',
            'E:\'
        )
    }

    $catalog = [ordered]@{
        Timestamp         = (Get-Date -Format 'o')
        Archives          = @()
        DuplicateGroups   = @()
        ConsolidationPlan = @()
        TotalArchives     = 0
        TotalSize_GB      = 0.0
        PotentialSave_GB  = 0.0
    }

    $archives = [System.Collections.Generic.List[object]]::new()

    foreach ($scanPath in $ScanPaths) {
        if (-not (Test-Path $scanPath)) { continue }
        Write-SOKLog "Scanning for archives under: $scanPath" 'DEBUG' 'ArchiveConsolidate'
        try {
            Get-ChildItem -Path $scanPath -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Extension.ToLower() -in $ARCHIVE_EXTENSIONS -and
                    -not (Test-PathExcluded $_.FullName)
                } |
                ForEach-Object {
                    $key = "$($_.Length)_$($_.LastWriteTime.Ticks)"
                    $archives.Add([ordered]@{
                        Path        = $_.FullName
                        Name        = $_.Name
                        BaseName    = $_.BaseName
                        Extension   = $_.Extension.ToLower()
                        Size_MB     = [math]::Round($_.Length / 1MB, 2)
                        Size_GB     = [math]::Round($_.Length / 1GB, 4)
                        LastWrite   = $_.LastWriteTime
                        CreatedDate = $_.CreationTime
                        AgeDays     = [math]::Round(((Get-Date) - $_.LastWriteTime).TotalDays, 0)
                        SizeKey     = $key
                        OnPrimary   = $_.FullName.StartsWith('C:', [System.StringComparison]::OrdinalIgnoreCase)
                    })
                }
        } catch {
            Write-SOKLog "Archive scan failed at $scanPath $_" 'WARN' 'ArchiveConsolidate'
        }
    }

    $catalog.Archives      = $archives
    $catalog.TotalArchives = $archives.Count
    $catalog.TotalSize_GB  = [math]::Round(($archives | Measure-Object -Property Size_GB -Sum).Sum ?? 0, 3)

    # Exact duplicate detection (same size + mtime ticks)
    $exactDupes = $archives | Group-Object SizeKey | Where-Object { $_.Count -gt 1 }
    foreach ($g in $exactDupes) {
        $largest = $g.Group | Sort-Object Size_GB -Descending | Select-Object -First 1
        $catalog.DuplicateGroups += [ordered]@{
            SizeKey         = $g.Name
            Count           = $g.Count
            Size_MB         = $largest.Size_MB
            Paths           = $g.Group.Path
            WasteIfDedup_GB = [math]::Round($largest.Size_GB * ($g.Count - 1), 4)
            Recommendation  = 'Keep newest, delete older duplicates'
        }
    }

    # Near-duplicate detection (same base name, different locations)
    $nameDupes = $archives | Group-Object BaseName | Where-Object { $_.Count -gt 1 }
    foreach ($g in $nameDupes) {
        $sorted = $g.Group | Sort-Object LastWrite -Descending
        $catalog.DuplicateGroups += [ordered]@{
            SizeKey         = "NAME_$($g.Name)"
            Count           = $g.Count
            Size_MB         = ($g.Group | Measure-Object -Property Size_MB -Sum).Sum
            Paths           = $sorted.Path
            WasteIfDedup_GB = [math]::Round((($g.Group | Measure-Object -Property Size_GB -Sum).Sum - $sorted[0].Size_GB), 4)
            Recommendation  = 'Same base name — verify and keep canonical copy'
        }
    }

    $catalog.PotentialSave_GB = [math]::Round(
        ($catalog.DuplicateGroups | Measure-Object -Property WasteIfDedup_GB -Sum).Sum ?? 0, 3)

    # Consolidation plan: archives on C: > 100MB should migrate to E:\Archives
    $archiveDest     = Join-Path $OFFLOAD_TARGET_DRIVE '\Archives\Consolidated'
    $primaryArchives = $archives | Where-Object { $_.OnPrimary -and $_.Size_GB -gt 0.1 } |
        Sort-Object Size_GB -Descending
    foreach ($a in $primaryArchives | Select-Object -First 100) {
        $destPath = Join-Path $archiveDest $a.Name
        $catalog.ConsolidationPlan += [ordered]@{
            Source  = $a.Path
            Dest    = $destPath
            Size_GB = $a.Size_GB
            AgeDays = $a.AgeDays
            Action  = 'MoveToE_Archives'
        }
        Write-ActionRecord -Phase 'ArchiveConsolidate' -Action 'MoveArchiveToOffload' `
            -Target $a.Path -Detail "Dest: $destPath  Size: $($a.Size_GB) GB" `
            -Priority 'MEDIUM' -Destructive $true
    }

    foreach ($d in $catalog.DuplicateGroups | Select-Object -First 30) {
        Write-ActionRecord -Phase 'ArchiveConsolidate' -Action 'DeduplicateArchives' `
            -Target ($d.Paths -join ' | ') `
            -Detail "Potential save: $($d.WasteIfDedup_GB) GB  Reason: $($d.Recommendation)" `
            -Priority 'MEDIUM' -Destructive $true
    }

    # Write catalog
    try {
        New-SOKDirectory (Split-Path $ARCHIVE_CATALOG)
        $catalog | ConvertTo-Json -Depth 8 | Set-Content -Path $ARCHIVE_CATALOG -Encoding utf8
        Write-SOKLog "Archive catalog saved: $ARCHIVE_CATALOG" 'INFO' 'ArchiveConsolidate'
    } catch {
        Write-SOKLog "Failed to save archive catalog: $_" 'WARN' 'ArchiveConsolidate'
    }

    Write-SOKLog "Archives found: $($catalog.TotalArchives)  Total: $($catalog.TotalSize_GB) GB  Potential dedup save: $($catalog.PotentialSave_GB) GB" 'INFO' 'ArchiveConsolidate'
    return $catalog
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 8: Selective Repair
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-SelectiveRepair {
    param([object]$EnvProbe)

    Show-SOKBanner 'Phase 8 — Selective Repair'

    $repairLog = [ordered]@{
        Timestamp  = (Get-Date -Format 'o')
        Repairs    = @()
        Skipped    = @()
        DryRunMode = $DryRun.IsPresent
    }

    # 1. Remove broken PATH entries from user PATH
    $userPathKey     = 'HKCU:\Environment'
    $currentUserPath = (Get-ItemProperty -Path $userPathKey -Name 'Path' -ErrorAction SilentlyContinue)?.Path
    if ($currentUserPath) {
        $pathEntries   = $currentUserPath -split ';' | Where-Object { $_ -ne '' }
        $validEntries  = $pathEntries | Where-Object { Test-Path $_ }
        $brokenEntries = $pathEntries | Where-Object { -not (Test-Path $_) }

        if ($brokenEntries.Count -gt 0) {
            Write-SOKLog "Found $($brokenEntries.Count) broken PATH entries to remove." 'INFO' 'Repair'
            foreach ($b in $brokenEntries) {
                Write-SOKLog "  Broken PATH: $b" 'WARN' 'Repair'
            }
            if (-not $DryRun) {
                $newPath = ($validEntries -join ';')
                try {
                    Set-ItemProperty -Path $userPathKey -Name 'Path' -Value $newPath
                    $repairLog.Repairs += [ordered]@{
                        Action  = 'PrunedBrokenPATH'
                        Removed = $brokenEntries
                        NewPath = $newPath
                    }
                    Write-SOKLog "User PATH pruned. Removed $($brokenEntries.Count) broken entries." 'INFO' 'Repair'
                } catch {
                    Write-SOKLog "Failed to update PATH: $_" 'ERROR' 'Repair'
                }
            } else {
                Write-SOKLog "[WOULD-DO] Prune $($brokenEntries.Count) broken PATH entries" 'INFO' 'Repair'
                $repairLog.Skipped += [ordered]@{ Action = 'PrunedBrokenPATH'; Reason = 'DryRun'; Entries = $brokenEntries }
            }
        } else {
            Write-SOKLog "User PATH is clean — no broken entries." 'INFO' 'Repair'
        }
    }

    # 2. Clean user TEMP if above 500 MB
    $tempPath = $env:TEMP
    if (Test-Path $tempPath) {
        try {
            $tempSize = (Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum ?? 0
            Write-SOKLog "TEMP size: $(Format-Bytes $tempSize)" 'INFO' 'Repair'

            if ($tempSize -gt 500MB) {
                if (-not $DryRun) {
                    $removed = 0
                    $errors  = 0
                    Get-ChildItem -Path $tempPath -Recurse -File -ErrorAction SilentlyContinue |
                        ForEach-Object {
                            try { Remove-Item $_.FullName -Force -ErrorAction Stop; $removed++ }
                            catch { $errors++ }
                        }
                    Get-ChildItem -Path $tempPath -Recurse -Directory -ErrorAction SilentlyContinue |
                        Sort-Object FullName -Descending |
                        ForEach-Object {
                            try {
                                if ((Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
                                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                                }
                            } catch {}
                        }
                    $repairLog.Repairs += [ordered]@{
                        Action     = 'CleanedTEMP'
                        Path       = $tempPath
                        Removed    = $removed
                        Errors     = $errors
                        SizeBefore = Format-Bytes $tempSize
                    }
                    Write-SOKLog "TEMP cleaned: $removed files removed, $errors errors" 'INFO' 'Repair'
                } else {
                    Write-SOKLog "[WOULD-DO] Clean TEMP ($(Format-Bytes $tempSize)) at $tempPath" 'INFO' 'Repair'
                    $repairLog.Skipped += [ordered]@{ Action = 'CleanedTEMP'; Reason = 'DryRun'; Size = Format-Bytes $tempSize }
                }
            }
        } catch {
            Write-SOKLog "TEMP clean failed: $_" 'WARN' 'Repair'
        }
    }

    # 3. Remove empty directories under Downloads
    $downloadsPath = 'C:\Users\shelc\Downloads'
    if (Test-Path $downloadsPath) {
        $emptyUnderDownloads = Get-ChildItem -Path $downloadsPath -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { (Get-ChildItem $_.FullName -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0 }

        if ($emptyUnderDownloads.Count -gt 0) {
            if (-not $DryRun) {
                $removed = 0
                $emptyUnderDownloads | Sort-Object FullName -Descending | ForEach-Object {
                    try { Remove-Item $_.FullName -Force; $removed++ } catch {}
                }
                $repairLog.Repairs += [ordered]@{ Action = 'RemovedEmptyDownloadsDirs'; Count = $removed }
                Write-SOKLog "Removed $removed empty directories from Downloads" 'INFO' 'Repair'
            } else {
                Write-SOKLog "[WOULD-DO] Remove $($emptyUnderDownloads.Count) empty dirs from Downloads" 'INFO' 'Repair'
                $repairLog.Skipped += [ordered]@{ Action = 'RemovedEmptyDownloadsDirs'; Reason = 'DryRun'; Count = $emptyUnderDownloads.Count }
            }
        }
    }

    # 4. Ensure E:\Archives\Consolidated exists (always safe)
    $archiveDest = Join-Path $OFFLOAD_TARGET_DRIVE '\Archives\Consolidated'
    if (Test-Path $OFFLOAD_TARGET_DRIVE) {
        if (-not $DryRun) {
            New-SOKDirectory $archiveDest
            $repairLog.Repairs += [ordered]@{ Action = 'EnsuredArchiveDestination'; Path = $archiveDest }
        } else {
            Write-SOKLog "[WOULD-DO] Ensure archive destination: $archiveDest" 'INFO' 'Repair'
        }
    }

    # 5. Attempt to restart stuck services
    $stuckSvcs = $EnvProbe.Broken | Where-Object { $_.Type -eq 'StuckService' }
    foreach ($svc in $stuckSvcs) {
        Write-SOKLog "Stuck service found: $($svc.Name) ($($svc.Status))" 'WARN' 'Repair'
        if (-not $DryRun) {
            try {
                Restart-Service -Name $svc.Name -Force -ErrorAction Stop
                $repairLog.Repairs += [ordered]@{ Action = 'RestartedStuckService'; Name = $svc.Name }
                Write-SOKLog "Restarted service: $($svc.Name)" 'INFO' 'Repair'
            } catch {
                Write-SOKLog "Failed to restart service $($svc.Name): $_" 'WARN' 'Repair'
            }
        } else {
            Write-SOKLog "[WOULD-DO] Restart stuck service: $($svc.Name)" 'INFO' 'Repair'
            $repairLog.Skipped += [ordered]@{ Action = 'RestartStuckService'; Reason = 'DryRun'; Name = $svc.Name }
        }
    }

    Write-SOKLog "Repairs performed: $($repairLog.Repairs.Count)  Skipped (DryRun): $($repairLog.Skipped.Count)" 'INFO' 'Repair'
    return $repairLog
}

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 9: Reconciliation Plan & Report
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-ReconciliationReport {
    param(
        [string]$RunId,
        [object]$EnvProbe,
        [object]$InstalledSnap,
        [object]$StorageTopo,
        [object]$StorageDebt,
        [object]$StructDebt,
        [object]$DriftResult,
        [object]$ArchiveCatalog,
        [object]$RepairLog
    )

    Show-SOKBanner 'Phase 9 — Reconciliation Plan & Report'

    $priorityOrder  = @{ 'HIGH' = 0; 'MEDIUM' = 1; 'LOW' = 2; 'INFO' = 3 }
    $sortedActions  = $script:ReconciliationActions |
        Sort-Object { $p = $_.Priority; if ($priorityOrder.ContainsKey($p)) { $priorityOrder[$p] } else { 99 } }

    $report = [ordered]@{
        RunId         = $RunId
        GeneratedAt   = (Get-Date -Format 'o')
        ScriptVersion = $SCRIPT_VERSION
        DryRun        = $DryRun.IsPresent
        Summary       = [ordered]@{
            Hostname           = $EnvProbe.Hostname
            OS                 = $EnvProbe.OS
            UptimeDays         = $EnvProbe.UptimeDays
            TotalRAM_GB        = $EnvProbe.TotalRAM_GB
            AvailableRAM_GB    = $EnvProbe.AvailableRAM_GB
            Drives             = $EnvProbe.Drives
            BrokenItems        = $EnvProbe.Broken.Count
            InstalledPrograms  = $InstalledSnap.Programs.Count
            PSModules          = $InstalledSnap.PowerShellMods.Count
            LargeFiles         = $StorageTopo.LargeFiles.Count
            OldLargeFiles      = $StorageTopo.OldLargeFiles.Count
            StorageDebt_GB     = $StorageDebt.TotalDebt_GB
            DeepNestViolations = $StructDebt.DeepNestViolations.Count
            BackupRedundancy   = $StructDebt.BackupRedundancy.Count
            EmptyDirs          = $StructDebt.EmptyDirectories.Count
            ArchivesFound      = $ArchiveCatalog.TotalArchives
            ArchivesTotalSize_GB = $ArchiveCatalog.TotalSize_GB
            DuplicateArchives  = $ArchiveCatalog.DuplicateGroups.Count
            PotentialSave_GB   = $ArchiveCatalog.PotentialSave_GB
            DriftMode          = -not $DriftResult.NoPriorSnapshot
            AddedPrograms      = if ($DriftResult.NoPriorSnapshot) { 'N/A' } else { $DriftResult.AddedPrograms.Count }
            RemovedPrograms    = if ($DriftResult.NoPriorSnapshot) { 'N/A' } else { $DriftResult.RemovedPrograms.Count }
            TotalActions       = $sortedActions.Count
            HighPriorityActions= ($sortedActions | Where-Object { $_.Priority -eq 'HIGH' }).Count
            RepairsExecuted    = $RepairLog.Repairs.Count
            RepairsSkipped     = $RepairLog.Skipped.Count
        }
        Actions = $sortedActions
        Phases  = [ordered]@{
            EnvProbe        = $EnvProbe
            InstalledState  = $InstalledSnap
            StorageTopology = $StorageTopo
            StorageDebt     = $StorageDebt
            StructuralDebt  = $StructDebt
            DriftDetection  = $DriftResult
            ArchiveCatalog  = $ArchiveCatalog
            Repairs         = $RepairLog
        }
    }

    # Write full JSON report
    $reportPath = Join-Path $SNAPSHOT_BASE "report-$RunId.json"
    try {
        $report | ConvertTo-Json -Depth 12 | Set-Content -Path $reportPath -Encoding utf8
        Write-SOKLog "Full JSON report: $reportPath" 'INFO' 'Report'
    } catch {
        Write-SOKLog "Failed to write JSON report: $_" 'ERROR' 'Report'
    }

    # Write human-readable Markdown summary
    $mdPath = Join-Path $SNAPSHOT_BASE "report-$RunId.md"
    $md = New-Object System.Text.StringBuilder

    [void]$md.AppendLine("# SOK-PAST-BlankSlate Report")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("**Run ID:** $RunId  ")
    [void]$md.AppendLine("**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  ")
    [void]$md.AppendLine("**Host:** $($EnvProbe.Hostname)  ")
    [void]$md.AppendLine("**DryRun:** $($DryRun.IsPresent)  ")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("---")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("## System Overview")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("| Property | Value |")
    [void]$md.AppendLine("|----------|-------|")
    [void]$md.AppendLine("| OS | $($EnvProbe.OS) |")
    [void]$md.AppendLine("| PS Version | $($EnvProbe.PSVersion) |")
    [void]$md.AppendLine("| Uptime | $($EnvProbe.UptimeDays) days |")
    [void]$md.AppendLine("| RAM | $($EnvProbe.TotalRAM_GB) GB total / $($EnvProbe.AvailableRAM_GB) GB free |")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("### Drives")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("| Drive | Total GB | Used GB | Free GB |")
    [void]$md.AppendLine("|-------|----------|---------|---------|")
    foreach ($d in $EnvProbe.Drives) {
        [void]$md.AppendLine("| $($d.Letter): | $($d.Total_GB) | $($d.Used_GB) | $($d.Free_GB) |")
    }
    [void]$md.AppendLine("")
    [void]$md.AppendLine("## Broken / Drifted Items  ($($EnvProbe.Broken.Count))")
    [void]$md.AppendLine("")
    if ($EnvProbe.Broken.Count -eq 0) {
        [void]$md.AppendLine("No broken items detected.")
    } else {
        foreach ($b in $EnvProbe.Broken) {
            [void]$md.AppendLine("- **$($b.Type)**: $($b.Value ?? $b.Name ?? ($b | ConvertTo-Json -Compress))")
        }
    }
    [void]$md.AppendLine("")
    [void]$md.AppendLine("## Storage Debt Summary")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("| Category | Count | Size |")
    [void]$md.AppendLine("|----------|-------|------|")
    [void]$md.AppendLine("| Cold file debt (C:->E:) | $($StorageDebt.ColdFileDebt.Count) | $(($StorageDebt.ColdFileDebt | Measure-Object -Property Size_GB -Sum | ForEach-Object{'{0:N2} GB' -f $_.Sum})) |")
    [void]$md.AppendLine("| Temp debt | $($StorageDebt.TempDebt.Count) dirs | $(($StorageDebt.TempDebt | Measure-Object -Property TotalSize_GB -Sum | ForEach-Object{'{0:N2} GB' -f $_.Sum})) |")
    [void]$md.AppendLine("| Stale downloads (>30d) | $($StorageDebt.DownloadDebt.Count) | — |")
    [void]$md.AppendLine("| Duplicate hints | $($StorageDebt.DuplicateHints.Count) | — |")
    [void]$md.AppendLine("| **Total estimated debt** | — | **$($StorageDebt.TotalDebt_GB) GB** |")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("## Structural Debt Summary")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("- Deep nesting violations (>$DEEP_NEST_THRESHOLD levels): **$($StructDebt.DeepNestViolations.Count)**")
    [void]$md.AppendLine("- Backup redundancy groups: **$($StructDebt.BackupRedundancy.Count)**")
    [void]$md.AppendLine("- Empty directories: **$($StructDebt.EmptyDirectories.Count)**")
    [void]$md.AppendLine("- Lone-file hierarchies: **$($StructDebt.FlattenedPaths.Count)**")
    [void]$md.AppendLine("- Orphaned profiles: **$($StructDebt.OrphanedProfiles.Count)**")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("## Archive Consolidation")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("- Archives found: **$($ArchiveCatalog.TotalArchives)** ($($ArchiveCatalog.TotalSize_GB) GB total)")
    [void]$md.AppendLine("- Duplicate groups: **$($ArchiveCatalog.DuplicateGroups.Count)**")
    [void]$md.AppendLine("- Potential dedup savings: **$($ArchiveCatalog.PotentialSave_GB) GB**")
    [void]$md.AppendLine("- Archives to migrate C:->E:: **$($ArchiveCatalog.ConsolidationPlan.Count)**")
    [void]$md.AppendLine("")

    if (-not $DriftResult.NoPriorSnapshot) {
        [void]$md.AppendLine("## Drift Since $($DriftResult.ReferenceDate)")
        [void]$md.AppendLine("")
        [void]$md.AppendLine("- Programs added: **$($DriftResult.AddedPrograms.Count)**")
        [void]$md.AppendLine("- Programs removed: **$($DriftResult.RemovedPrograms.Count)**")
        [void]$md.AppendLine("- Services added: **$($DriftResult.AddedServices.Count)**")
        [void]$md.AppendLine("- Services removed: **$($DriftResult.RemovedServices.Count)**")
        [void]$md.AppendLine("- Scheduled tasks added: **$($DriftResult.AddedTasks.Count)**")
        [void]$md.AppendLine("")
        if ($DriftResult.AddedPrograms.Count -gt 0) {
            [void]$md.AppendLine("### Newly Installed Programs")
            foreach ($p in $DriftResult.AddedPrograms | Select-Object -First 20) {
                [void]$md.AppendLine("- $($p.Name) $($p.Version)")
            }
            [void]$md.AppendLine("")
        }
    } else {
        [void]$md.AppendLine("## Drift Detection")
        [void]$md.AppendLine("")
        [void]$md.AppendLine("No prior snapshot available. Drift detection will be active on next run.")
        [void]$md.AppendLine("")
    }

    [void]$md.AppendLine("## Reconciliation Actions ($($sortedActions.Count) total)")
    [void]$md.AppendLine("")
    [void]$md.AppendLine("Sorted by priority. HIGH items require immediate attention.")
    [void]$md.AppendLine("")

    $byPriority = $sortedActions | Group-Object Priority
    foreach ($pg in $byPriority) {
        [void]$md.AppendLine("### $($pg.Name) ($($pg.Count))")
        [void]$md.AppendLine("")
        foreach ($a in $pg.Group | Select-Object -First 30) {
            $dryTag = if ($a.Destructive -and $DryRun) { ' `[WOULD-DO]`' } else { '' }
            [void]$md.AppendLine("- **[$($a.Phase)]** ``$($a.Action)``$dryTag  ")
            [void]$md.AppendLine("  Target: $($a.Target)  ")
            [void]$md.AppendLine("  $($a.Detail)")
            [void]$md.AppendLine("")
        }
    }

    [void]$md.AppendLine("## Repairs Executed")
    [void]$md.AppendLine("")
    if ($RepairLog.Repairs.Count -eq 0) {
        [void]$md.AppendLine("No repairs executed$(if ($DryRun) { ' (DryRun mode — see Skipped section)' } else { '.' })")
    } else {
        foreach ($r in $RepairLog.Repairs) {
            [void]$md.AppendLine("- **$($r.Action)**: $($r | ConvertTo-Json -Compress)")
        }
    }
    [void]$md.AppendLine("")

    if ($RepairLog.Skipped.Count -gt 0) {
        [void]$md.AppendLine("## Repairs Skipped (DryRun)")
        [void]$md.AppendLine("")
        foreach ($s in $RepairLog.Skipped) {
            [void]$md.AppendLine("- **$($s.Action)**: $($s | ConvertTo-Json -Compress)")
        }
        [void]$md.AppendLine("")
    }

    [void]$md.AppendLine("---")
    [void]$md.AppendLine("*Generated by $SCRIPT_NAME v$SCRIPT_VERSION on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')*")

    try {
        $md.ToString() | Set-Content -Path $mdPath -Encoding utf8
        Write-SOKLog "Markdown report: $mdPath" 'INFO' 'Report'
    } catch {
        Write-SOKLog "Failed to write markdown report: $_" 'ERROR' 'Report'
    }

    return @{
        JsonPath     = $reportPath
        MarkdownPath = $mdPath
        Summary      = $report.Summary
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# REGION: Snapshot persistence helpers
# ─────────────────────────────────────────────────────────────────────────────

function Save-PhaseSnapshot {
    param([string]$Name, [object]$Data, [string]$RunId)
    $path = Join-Path $SNAPSHOT_BASE "$Name-$RunId.json"
    try {
        $Data | ConvertTo-Json -Depth 12 | Set-Content -Path $path -Encoding utf8
        Write-SOKLog "Snapshot saved: $path" 'DEBUG' 'Snapshot'
        return $path
    } catch {
        Write-SOKLog "Failed to save snapshot $Name $_" 'WARN' 'Snapshot'
        return $null
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────

$script:ReconciliationActions = [System.Collections.Generic.List[object]]::new()
$script:LogFilePath           = $null

# Phase 0: Bootstrap
$boot = Invoke-Bootstrap

Write-SOKLog "Starting run: $($boot.RunId)  DryRun=$($DryRun.IsPresent)  SnapshotOnly=$($SnapshotOnly.IsPresent)" 'INFO' 'Main'

# Phase 1: Environment Probe
$envProbe = Invoke-Timed 'Phase1-EnvProbe' { Invoke-EnvironmentProbe }
Save-PhaseSnapshot -Name 'env-probe' -Data $envProbe -RunId $boot.RunId | Out-Null

# Phase 2: Installed State Snapshot
$installedSnap = Invoke-Timed 'Phase2-InstalledState' { Invoke-InstalledStateSnapshot }
Save-PhaseSnapshot -Name 'installed' -Data $installedSnap -RunId $boot.RunId | Out-Null

# Phase 3: Storage Topology
$storageTopo = Invoke-Timed 'Phase3-StorageTopo' { Invoke-StorageTopologyMap -Roots $ScanRoots }
Save-PhaseSnapshot -Name 'storage-topo' -Data $storageTopo -RunId $boot.RunId | Out-Null

# Phase 4: Storage Debt
$storageDebt = Invoke-Timed 'Phase4-StorageDebt' { Invoke-StorageDebtAudit -Topology $storageTopo }
Save-PhaseSnapshot -Name 'storage-debt' -Data $storageDebt -RunId $boot.RunId | Out-Null

# Phase 5: Structural Debt
$structDebt = Invoke-Timed 'Phase5-StructDebt' { Invoke-StructuralDebtAudit -Roots $ScanRoots }
Save-PhaseSnapshot -Name 'struct-debt' -Data $structDebt -RunId $boot.RunId | Out-Null

# Phase 6: Drift Detection
$driftResult = Invoke-Timed 'Phase6-Drift' {
    Invoke-DriftDetection -CurrentInstalled $installedSnap -CurrentEnv $envProbe -ReferenceDate $ReferenceDate
}
Save-PhaseSnapshot -Name 'drift' -Data $driftResult -RunId $boot.RunId | Out-Null

# Phase 7: Archive Consolidation
$archivePaths   = if ($ArchiveScanPaths -and $ArchiveScanPaths.Count -gt 0) { $ArchiveScanPaths } else { $null }
$archiveCatalog = Invoke-Timed 'Phase7-Archives' { Invoke-ArchiveConsolidation -ScanPaths $archivePaths }
Save-PhaseSnapshot -Name 'archives' -Data $archiveCatalog -RunId $boot.RunId | Out-Null

if (-not $SnapshotOnly) {
    # Phase 8: Selective Repair
    $repairLog = Invoke-Timed 'Phase8-Repair' { Invoke-SelectiveRepair -EnvProbe $envProbe }
    Save-PhaseSnapshot -Name 'repairs' -Data $repairLog -RunId $boot.RunId | Out-Null

    # Phase 9: Reconciliation Report
    $reportResult = Invoke-Timed 'Phase9-Report' {
        Invoke-ReconciliationReport `
            -RunId          $boot.RunId `
            -EnvProbe       $envProbe `
            -InstalledSnap  $installedSnap `
            -StorageTopo    $storageTopo `
            -StorageDebt    $storageDebt `
            -StructDebt     $structDebt `
            -DriftResult    $driftResult `
            -ArchiveCatalog $archiveCatalog `
            -RepairLog      $repairLog
    }

    # Final console summary
    Show-SOKBanner "RUN COMPLETE — $($boot.RunId)"
    Write-SOKLog "JSON Report  : $($reportResult.JsonPath)"     'INFO' 'Main'
    Write-SOKLog "MD Report    : $($reportResult.MarkdownPath)" 'INFO' 'Main'
    Write-SOKLog "Log file     : $($boot.LogPath)"              'INFO' 'Main'
    Write-SOKLog "" 'INFO' 'Main'

    $s = $reportResult.Summary
    Write-SOKLog "── SUMMARY ──────────────────────────────────────" 'INFO' 'Main'
    Write-SOKLog "  Broken items      : $($s.BrokenItems)"                                    'INFO' 'Main'
    Write-SOKLog "  Storage debt      : $($s.StorageDebt_GB) GB"                              'INFO' 'Main'
    Write-SOKLog "  Large files       : $($s.LargeFiles) (old: $($s.OldLargeFiles))"          'INFO' 'Main'
    Write-SOKLog "  Deep nest issues  : $($s.DeepNestViolations)"                             'INFO' 'Main'
    Write-SOKLog "  Backup redundancy : $($s.BackupRedundancy) groups"                        'INFO' 'Main'
    Write-SOKLog "  Empty dirs        : $($s.EmptyDirs)"                                      'INFO' 'Main'
    Write-SOKLog "  Archives found    : $($s.ArchivesFound) ($($s.ArchivesTotalSize_GB) GB)"  'INFO' 'Main'
    Write-SOKLog "  Dedup potential   : $($s.PotentialSave_GB) GB"                            'INFO' 'Main'
    Write-SOKLog "  Total actions     : $($s.TotalActions) ($($s.HighPriorityActions) HIGH)"  'INFO' 'Main'
    Write-SOKLog "  Repairs done      : $($s.RepairsExecuted) / Skipped: $($s.RepairsSkipped)" 'INFO' 'Main'
    Write-SOKLog "─────────────────────────────────────────────────" 'INFO' 'Main'

    if ($DryRun) {
        Write-Host "`n[DRY RUN] No destructive operations were performed. Re-run without -DryRun to apply repairs." -ForegroundColor Yellow
    }
} else {
    Write-SOKLog "SnapshotOnly mode — skipping repair and reconciliation phases." 'INFO' 'Main'
    Show-SOKBanner "SNAPSHOTS COMPLETE — $($boot.RunId)"
    Write-SOKLog "Snapshot base: $SNAPSHOT_BASE" 'INFO' 'Main'
}
