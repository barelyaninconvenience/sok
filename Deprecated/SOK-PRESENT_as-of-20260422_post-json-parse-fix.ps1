#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-PRESENT v1.1.0 — The Tactician & Optimizer
    Temporal Domain: Active Machine State, Real-Time Performance, Current Session Health

.DESCRIPTION
    SOK-PRESENT is the second of three temporal meta-scripts. It consolidates nine
    scripts that all answer one operational question: "What is happening right now,
    and how do we make this session run better?"

    WHY THIS TEMPORAL SLICE?
    These nine modules operate on the LIVE, mutable state of the machine. They kill
    processes, empty caches, throttle Defender, update packages, and establish
    post-reboot hygiene. Unlike PAST (which reads) and FUTURE (which provisions),
    PRESENT is transient — its changes evaporate on reboot (processes return,
    caches fill, Defender resets). It is meant to be run repeatedly: at session
    start, before intensive workloads, or when performance degrades mid-session.

    INTEGRATED MODULES:
    1. DefenderOptimizer — Throttle AV CPU cap to 20%, add dev path exclusions
    2. ProcessOptimizer  — Property-based process kill (Conservative/Balanced/Aggressive)
    3. ServiceOptimizer  — Stop/report idle databases and services
    4. Maintenance       — Package updates, cache cleanup, TRIM, DNS flush
    5. Cleanup           — Kill lock-holding processes + deep cache purge
    6. PreSwap           — Pre-drive-swap deep junction repair + cache eviction
    7. RebootClean       — Post-reboot junction verification + temp file cleanup
    8. LiveScan          — Streaming filesystem inventory to JSON
    9. LiveDigest        — Summarize latest LiveScan into human-readable TopN report

    SEQUENCING NOTE:
    DefenderOptimizer runs first — throttling AV before package updates prevents
    Defender from scanning every downloaded package binary in real time, which can
    turn a 2-minute package update into a 15-minute stall. The order matters.

    FULL DISCLOSURE (PROGRESSIVE ENCLOSURE):
    By default this script runs ALL core modules (DefenderOptimizer, ProcessOptimizer,
    ServiceOptimizer, Maintenance, Cleanup). Use -Skip* flags to narrow the default run.
    Opt-in flags still work for targeted runs (backward compatible).
    -Optimize is a shortcut for -OptimizeDefender -OptimizeProcesses -OptimizeServices.
    -All forces all core modules regardless of -Skip* flags.
    Always-explicit (never in default run): PreSwap (interactive), RebootClean (post-reboot
    only), LiveScan (slow/disk-heavy), LiveDigest (requires LiveScan output).

    TYPICAL CADENCE:
    Morning sprint prep   : .\SOK-PRESENT.ps1 -Optimize -Clean
    After package install : .\SOK-PRESENT.ps1 -Maintain -MaintMode Standard
    Post-reboot check     : .\SOK-PRESENT.ps1 -RebootClean
    RAM reclaim (urgent)  : .\SOK-PRESENT.ps1 -OptimizeProcesses -ProcessMode Aggressive -DryRun
    Pre-drive-swap        : .\SOK-PRESENT.ps1 -PreSwap
    Full live inventory   : .\SOK-PRESENT.ps1 -LiveScan -LiveDigest
    Safe full run         : .\SOK-PRESENT.ps1 -All -DryRun
    Production full run   : .\SOK-PRESENT.ps1 -Optimize -Clean -Maintain -MaintMode Thorough

.EXAMPLE
    .\SOK-PRESENT.ps1 -Optimize -ProcessMode Balanced -ServiceAction Auto -Clean
    Throttle Defender, kill balanced tier processes, auto-stop idle databases, purge caches.

.EXAMPLE
    .\SOK-PRESENT.ps1 -Maintain -MaintMode Thorough -DryRun
    Preview a thorough maintenance pass (TRIM, package updates, NuGet purge) without changes.

.EXAMPLE
    .\SOK-PRESENT.ps1 -LiveScan -LiveScanDirsOnly -LiveScanExcludeNoisy
    Fast directory-only live scan of C:\ excluding node_modules and AppData noise.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # ── GLOBAL ─────────────────────────────────────────────────────────────────
    [switch]$DryRun,

    # ── MODULE SHORTCUTS ──────────────────────────────────────────────────────
    # -Optimize: activates DefenderOptimizer + ProcessOptimizer + ServiceOptimizer
    # -All:      force all core modules regardless of -Skip* flags
    [switch]$Optimize,
    [switch]$All,

    # ── MODULE ACTIVATION (opt-in, backward compat) ───────────────────────────
    # If NONE of these are set, default is full-run (progressive enclosure).
    # Use -Skip* to narrow the default. These flags still work for targeted runs.
    [switch]$OptimizeDefender,   # SOK-DefenderOptimizer: throttle AV + add dev exclusions
    [switch]$OptimizeProcesses,  # SOK-ProcessOptimizer: kill background bloat by category
    [switch]$OptimizeServices,   # SOK-ServiceOptimizer: stop idle databases and services
    [switch]$Maintain,           # SOK-Maintenance: updates + TRIM + cache + drive health
    [switch]$Clean,              # SOK-Cleanup: kill lock holders + deep cache eviction
    [switch]$PreSwap,            # SOK-PreSwap: one-shot pre-swap prep (excluded from default)
    [switch]$RebootClean,        # SOK-RebootClean: post-reboot cleanup (excluded from default)
    [switch]$LiveScan,           # SOK-LiveScan: stream filesystem inventory to JSON (excluded from default — slow/disk-heavy)
    [switch]$LiveDigest,         # SOK-LiveDigest: summarize latest LiveScan (excluded from default)
    # ── MODULE SKIP (progressive enclosure) ───────────────────────────────────
    # Narrow the default full run. Only applies when no opt-in flags are set.
    [switch]$SkipDefender,       # Exclude DefenderOptimizer from default run
    [switch]$SkipProcesses,      # Exclude ProcessOptimizer from default run
    [switch]$SkipServices,       # Exclude ServiceOptimizer from default run
    [switch]$SkipMaintain,       # Exclude Maintenance from default run
    [switch]$SkipClean,          # Exclude Cleanup from default run

    # ── PROCESS OPTIMIZER PARAMS ──────────────────────────────────────────────
    # Conservative: kill only telemetry/updaters/crash reporters
    # Balanced:     ^ + cloud sync background, high-CPU background processes (DEFAULT)
    # Aggressive:   ^ + any user process with no window and no session interaction
    [ValidateSet('Conservative', 'Balanced', 'Aggressive')]
    [string]$ProcessMode = 'Balanced',

    # ── SERVICE OPTIMIZER PARAMS ──────────────────────────────────────────────
    # Report: display analysis, no changes
    # Auto:   stop all STOP-recommended services without prompting
    # Interactive: prompt per service (useful for selectively stopping databases)
    [ValidateSet('Auto', 'Interactive', 'Report')]
    [string]$ServiceAction = 'Report',

    # ── MAINTENANCE PARAMS ─────────────────────────────────────────────────────
    # Cumulative modes (each includes the previous):
    # Quick:    junction check + core cache cleanup + recycle bin
    # Standard: ^ + package updates (choco, scoop, winget, pip, npm)
    # Deep:     ^ + TRIM + drive health + DNS flush + Windows Update
    # Thorough: ^ + SSD wear report + full NuGet/dotnet purge + stale scan
    [ValidateSet('Quick', 'Standard', 'Deep', 'Thorough')]
    [string]$MaintMode = 'Standard',

    # ── SHARED PARAMS ─────────────────────────────────────────────────────────
    [string]$ExternalDrive   = 'E:',
    [int]$ThrottleLimit      = 13,
    [int]$PackageTimeoutSec  = 360,

    # ── LIVESCAN PARAMS ────────────────────────────────────────────────────────
    [string]$LiveScanSource  = 'C:\',
    # DirsOnly: scan directories only (much faster, good for structure overview)
    [switch]$LiveScanDirsOnly,
    # ExcludeNoisy: skip AppData, WinSxS, node_modules (reduces noise ~60%)
    [switch]$LiveScanExcludeNoisy,

    # ── LIVEDIGEST PARAMS ──────────────────────────────────────────────────────
    [int]$DigestTopN         = 50,
    [string]$DigestInputPath         # Override: path to a specific LiveScan JSON
)

# ══════════════════════════════════════════════════════════════════════════════
# [0] CORE INITIALIZATION
# ══════════════════════════════════════════════════════════════════════════════
$ErrorActionPreference = 'Continue'
$GlobalStartTime       = Get-Date

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) {
    $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1'
}
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "CRITICAL: SOK-Common.psm1 not found."
    exit 1
}

$logPath = Initialize-SOKLog -ScriptName 'SOK-PRESENT'
$config  = Get-SOKConfig

# ── Full Disclosure / Progressive Enclosure gate ─────────────────────────────
# Default: run all core modules. -Skip* flags narrow the default.
# Explicit opt-in flags run only those modules (backward compat).
# -All forces all core modules regardless of -Skip* flags.
# PreSwap, LiveScan, LiveDigest always require explicit opt-in — never in default
# (PreSwap is destructive/one-shot; LiveScan/LiveDigest are slow and disk-heavy).
if ($Optimize) { $OptimizeDefender = $OptimizeProcesses = $OptimizeServices = $true }

$anyOptIn = $OptimizeDefender.IsPresent -or $OptimizeProcesses.IsPresent -or
            $OptimizeServices.IsPresent -or $Maintain.IsPresent -or $Clean.IsPresent -or
            $Optimize.IsPresent

if ($All) {
    $OptimizeDefender = $OptimizeProcesses = $OptimizeServices = $Maintain = $Clean = $RebootClean = $true
} elseif (-not $anyOptIn) {
    # Full disclosure: activate all core modules unless skipped
    if (-not $SkipDefender)  { $OptimizeDefender  = $true }
    if (-not $SkipProcesses) { $OptimizeProcesses = $true }
    if (-not $SkipServices)  { $OptimizeServices  = $true }
    if (-not $SkipMaintain)  { $Maintain          = $true }
    if (-not $SkipClean)     { $Clean             = $true }
    # PreSwap/RebootClean/LiveScan/LiveDigest always require explicit opt-in
}

$ActiveModules = @()
if ($OptimizeDefender)  { $ActiveModules += 'DefenderOptimizer' }
if ($OptimizeProcesses) { $ActiveModules += 'ProcessOptimizer' }
if ($OptimizeServices)  { $ActiveModules += 'ServiceOptimizer' }
if ($Maintain)          { $ActiveModules += "Maintenance[$MaintMode]" }
if ($Clean)             { $ActiveModules += 'Cleanup' }
if ($PreSwap)           { $ActiveModules += 'PreSwap' }
if ($RebootClean)       { $ActiveModules += 'RebootClean' }
if ($LiveScan)          { $ActiveModules += 'LiveScan' }
if ($LiveDigest)        { $ActiveModules += 'LiveDigest' }

if ($ActiveModules.Count -eq 0) {
    Write-SOKLog 'All modules skipped via -Skip* flags. Nothing to run.' -Level Warn
    exit 0
}

Show-SOKBanner -ScriptName 'SOK-PRESENT' -Subheader "Active: $($ActiveModules -join ' | ')$(if ($DryRun) {' [DRY RUN]'})"
Write-SOKLog "Temporal Domain: PRESENT — Live Machine State, Performance, Current Session Hygiene" -Level Section

$GlobalState = New-SOKStateDict

# RAM baseline — captured before any module runs so we can show total reclaimed at the end.
# Committed bytes = total RAM in use (including page file). Available bytes is the actionable metric.
$ramBefore = try { (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory } catch { 0 }  # KB units
Write-SOKLog "RAM baseline: $([math]::Round($ramBefore/1MB,2)) GB free" -Level Ignore

try {
# ══════════════════════════════════════════════════════════════════════════════
# [1] DEFENDER OPTIMIZER — Throttle AV Before Anything Else
# ══════════════════════════════════════════════════════════════════════════════
# Windows Defender defaults to using up to 50% CPU during package installs and
# file operations. With 220+ packages being updated across 5 managers, this
# turns Maintenance into a multi-hour stall. Throttling to 20% CPU cap and
# adding dev directory exclusions before any other module runs is the single
# highest-leverage action in the PRESENT suite.
#
# IMPORTANT: If a third-party AV (Avast/AVG/Avira) is detected as the PRIMARY
# AV, this module skips — modifying Defender settings when it's not the primary
# AV can cause unpredictable behavior. Phase 0 of BareMetal purges these.
if ($OptimizeDefender) {
    Write-SOKLog '━━━ [1] DEFENDER OPTIMIZER: Throttle + Dev Exclusions ━━━' -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    # Check if Windows Defender is the active AV (skip if third-party is primary)
    $mpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if (-not $mpStatus) {
        Write-SOKLog "Cannot read MpComputerStatus. Defender may not be present or accessible." -Level Warn
    } elseif (-not $mpStatus.RealTimeProtectionEnabled -and -not $mpStatus.AntivirusEnabled) {
        Write-SOKLog "Third-party AV appears to be the primary protection layer. Skipping Defender config." -Level Warn
    } else {
        # Stop any active MpCmdRun scan to prevent CPU spike during config
        Get-Process MpCmdRun -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-SOKLog "Stopped MpCmdRun scan processes." -Level Ignore

        if (-not $DryRun) {
            # Performance throttles:
            # ScanAvgCPULoadFactor 20: cap at 20% (default is 50% on Windows 11)
            # EnableLowCpuPriority: run scan threads at BELOW_NORMAL priority
            # DisableArchiveScanning: skip .zip/.tar scanning (catches most false positives from pip/npm)
            Set-MpPreference -ScanAvgCPULoadFactor 20 -ErrorAction SilentlyContinue
            Set-MpPreference -EnableLowCpuPriority $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
            # Shift quick scan to 3:00 AM (avoids competing with scheduled SOK runs at 2:17)
            Set-MpPreference -ScanScheduleQuickScanTime 180 -ErrorAction SilentlyContinue
            # Telemetry: Basic only. NeverSend samples (no binary uploads to Microsoft)
            Set-MpPreference -MAPSReporting Basic -ErrorAction SilentlyContinue
            Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
            Write-SOKLog "Defender throttled: 20% CPU cap, low priority, archive scanning disabled." -Level Success

            # Dev path exclusions — these directories contain thousands of small binary files
            # (pip packages, npm modules, cargo crates) that Defender aggressively scans.
            # Excluding them eliminates the primary cause of post-install slowdowns.
            $exclusions = @(
                "$env:USERPROFILE\Documents\Journal\Projects",
                "$env:USERPROFILE\Documents\Journal\Projects\SOK",
                "$env:USERPROFILE\.cargo",
                "$env:USERPROFILE\.npm",
                "$env:USERPROFILE\.pyenv",
                "$env:USERPROFILE\scoop",
                'C:\Python314',
                'C:\ProgramData\chocolatey',
                'C:\tools',
                'C:\Program Files\Git',
                'C:\ProgramData\Docker',
                'C:\Program Files\PostgreSQL',
                'C:\Program Files\MongoDB',
                'C:\Program Files\JetBrains'
            )
            foreach ($path in $exclusions) {
                if (Test-Path $path) {
                    Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
                    Write-SOKLog "  Exclusion added: $path" -Level Ignore
                }
            }
            # Trigger definition update in the background (non-blocking)
            Start-Job { Update-MpSignature -ErrorAction SilentlyContinue } | Out-Null
            Write-SOKLog "Defender definition update started (background)." -Level Ignore
        } else {
            Write-SOKLog "[DRY] Would configure Defender throttles + $($exclusions.Count) exclusions." -Level Ignore
        }
        Write-SOKLog "DefenderOptimizer complete." -Level Success
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# [2] PROCESS OPTIMIZER — Property-Based Background Process Termination
# ══════════════════════════════════════════════════════════════════════════════
# The ProcessOptimizer uses a PROPERTY-BASED categorization model rather than
# a hardcoded kill list. This is a core SOK design principle: the system infers
# intent from observable properties (window state, session ID, CPU time, path)
# rather than matching names. This is why it doesn't kill dev tools even in
# Aggressive mode — they have windows, which indicates active operator use.
#
# Categories and their kill eligibility:
#   WindowsCore, Shell, Security, AudioVideo: NEVER killed (kernel-level)
#   DevTool (has window): NEVER killed (operator is actively using it)
#   ConfigProtected: NEVER killed (operator's explicit protection list)
#   Telemetry, Updater, CrashReporter: always killed (Conservative+)
#   CloudSync, AppDataBackground, HighCPUBackground: killed at Balanced+
#   UserProcess (no window, non-system): killed at Aggressive only
if ($OptimizeProcesses) {
    Write-SOKLog "━━━ [2] PROCESS OPTIMIZER: Property-Based Kill ($ProcessMode) ━━━" -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $selfPid    = $PID
    $parentPid  = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId

    # v1.1.1 backport from SOK-ProcessOptimizer (C-1 / C-2 fix 2026-04-21):
    #   - Read namespaced $config.ProcessOptimizer.ProtectedProcesses (was $config.ProtectedProcesses → empty)
    #   - Case-normalized to lowercase
    #   - Read $config.ProcessOptimizer.BloatProcesses (was completely ignored)
    $protected = @($config.ProcessOptimizer.ProtectedProcesses) |
        Where-Object { $_ } |
        ForEach-Object { $_.ToString().ToLower() }
    if ($null -eq $protected) { $protected = @() }
    $bloat = @($config.ProcessOptimizer.BloatProcesses) |
        Where-Object { $_ } |
        ForEach-Object { $_.ToString().ToLower() }
    if ($null -eq $bloat) { $bloat = @() }

    function Get-ProcessCategory {
        param([System.Diagnostics.Process]$Proc)
        # NOTE: $selfPid and $parentPid are accessed via PowerShell's dynamic scope —
        # no $using: prefix needed here. $using: only applies inside ForEach-Object -Parallel
        # runspace boundaries; inside a regular function it resolves to $null silently.
        if ($Proc.Id -eq $selfPid -or $Proc.Id -eq $parentPid) { return 'SelfProtected' }
        $name = $Proc.ProcessName.ToLower()
        if ($protected -contains $name) { return 'ConfigProtected' }
        # v1.1.1 backport: BloatProcess check moved BEFORE heuristics so config beats DevTool/Shell/etc
        if ($bloat -contains $name) { return 'BloatProcess' }
        $path = try { $Proc.MainModule.FileName } catch { '' }

        if ($name -in @('system','registry','smss','csrss','wininit','services','lsass','dwm','winlogon','fontdrvhost','logonui','idle')) { return 'WindowsCore' }
        if ($name -eq 'svchost') { return 'WindowsService' }
        if ($name -in @('msmpeng','nissrv','securityhealthservice') -or
            (($Proc.Company -match 'Microsoft') -and $name -match 'defender|security|protect')) { return 'Security' }
        if ($name -match '^(audiodg|wavessys|wavessvc|rtkaudioservice)' -or
            $Proc.Company -match 'Realtek|NVIDIA Audio|Waves Audio') { return 'AudioVideo' }
        if ($name -in @('explorer','sihost','shellexperiencehost','startmenuexperiencehost','runtimebroker','textinputhost','searchhost')) { return 'Shell' }
        # v1.1.1 backport: anchored exact-match regex; removed cmd|conhost|node|terminal|cursor; added claude|windowsterminal; $hasWindow gate removed
        if ($name -match '^(code|pwsh|powershell|windowsterminal|claude|idea|pycharm|rider|datagrip|postman|dbeaver)$') { return 'DevTool' }
        $hasWindow = ($Proc.MainWindowHandle -ne [System.IntPtr]::Zero)
        if ($name -match 'telemetry|diagtrack|census|compattelrunner|diagscap') { return 'Telemetry' }
        if ($name -match 'update' -and $Proc.Company -notmatch 'Microsoft') { return 'Updater' }
        if ($name -match 'crash|reporter|werfault|wermgr') { return 'CrashReporter' }
        if ($path -match 'OneDrive|Dropbox|GoogleDrive' -and -not $hasWindow) { return 'CloudSync' }
        if ($path -match '\\AppData\\Local\\' -and -not $hasWindow -and $Proc.SessionId -ne 0) { return 'AppDataBackground' }
        if ($path -match '\\AppData\\Roaming\\' -and -not $hasWindow) { return 'AppDataRoaming' }
        try { if ($Proc.TotalProcessorTime.TotalSeconds -gt 10 -and -not $hasWindow) { return 'HighCPUBackground' } } catch { }
        if ($Proc.SessionId -ne 0 -and -not $hasWindow) { return 'UserProcess' }
        return 'Uncategorized'
    }

    # Kill tiers — each mode includes all previous tiers
    # v1.1.0 backport: BloatProcess added to Balanced and Aggressive
    $killTiers = @{
        Conservative = @('Telemetry', 'Updater', 'CrashReporter')
        Balanced     = @('Telemetry', 'Updater', 'CrashReporter', 'CloudSync', 'AppDataBackground', 'AppDataRoaming', 'HighCPUBackground', 'BloatProcess')
        Aggressive   = @('Telemetry', 'Updater', 'CrashReporter', 'CloudSync', 'AppDataBackground', 'AppDataRoaming', 'HighCPUBackground', 'BloatProcess', 'UserProcess')
    }
    $killCategories = $killTiers[$ProcessMode]

    $allProcesses = Get-Process -ErrorAction SilentlyContinue
    $categoryStats = @{}; $killList = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()

    foreach ($proc in $allProcesses) {
        $cat = Get-ProcessCategory $proc
        if (-not $categoryStats.ContainsKey($cat)) { $categoryStats[$cat] = 0 }
        $categoryStats[$cat]++
        # v1.1.1 backport: case-normalized $protected check
        if ($cat -in $killCategories -and $protected -notcontains $proc.ProcessName.ToLower()) {
            $killList.Add($proc)
        }
    }

    Write-SOKLog "Process categories: $(($categoryStats.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' | ')" -Level Ignore
    Write-SOKLog "Kill candidates ($ProcessMode): $($killList.Count) processes" -Level Warn

    $killed = 0; $skipped = 0
    foreach ($proc in $killList) {
        if ($DryRun) {
            Write-SOKLog "[DRY] Would stop: $($proc.ProcessName) (PID $($proc.Id))" -Level Ignore; $skipped++
        } else {
            try {
                Stop-Process -Id $proc.Id -Force -ErrorAction Stop
                Write-SOKLog "  Stopped: $($proc.ProcessName) (PID $($proc.Id))" -Level Ignore
                $killed++
            } catch { Write-SOKLog "  Could not stop $($proc.ProcessName): $_" -Level Warn; $skipped++ }
        }
    }

    $GlobalState['ProcessOptimizer_Killed'] = $killed
    Write-SOKLog "ProcessOptimizer complete. Killed: $killed | Skipped/protected: $skipped" -Level Success
    Save-SOKHistory -ScriptName 'SOK-ProcessOptimizer' -RunData @{ Mode=$ProcessMode; Killed=$killed; DryRun=$DryRun.IsPresent }
}

# ══════════════════════════════════════════════════════════════════════════════
# [3] SERVICE OPTIMIZER — Stop Idle Databases and Background Services
# ══════════════════════════════════════════════════════════════════════════════
# <HOST> runs PostgreSQL, MongoDB, Neo4j, MySQL, Redis, and InfluxDB as services.
# These together consume ~3-4 GB RAM when idle. The SOK design philosophy:
# all database services are set to MANUAL startup (not Automatic). They are started
# on-demand when needed and stopped after. ServiceOptimizer enforces this discipline.
#
# The service targets list encodes architectural knowledge about each service:
# - Port: used to confirm the service is actually listening (not just "Running")
# - Rec: STOP = unconditionally stop | CONDITIONAL = stop only if port is idle
# - Reason: the human-readable rationale for the stop recommendation
if ($OptimizeServices) {
    Write-SOKLog "━━━ [3] SERVICE OPTIMIZER: Reclaim Idle Database Memory ($ServiceAction) ━━━" -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $serviceTargets = @(
        @{ Name='Neo4j';        ServiceName='neo4j';              ProcessName='java';           Port=7474; Rec='STOP';        Reason='~800MB RAM when idle; start with net start neo4j' }
        @{ Name='MongoDB';      ServiceName='MongoDB';            ProcessName='mongod';         Port=27017;Rec='STOP';        Reason='~250MB RAM idle; rarely needed outside IS7036' }
        @{ Name='MySQL';        ServiceName='MySQL80';            ProcessName='mysqld';         Port=3306; Rec='CONDITIONAL'; Reason='Stop if no active connections' }
        @{ Name='PostgreSQL';   ServiceName='postgresql-x64-15';  ProcessName='postgres';       Port=5432; Rec='CONDITIONAL'; Reason='Stop if no pgAdmin4 or dbt session active' }
        @{ Name='Redis';        ServiceName='Redis';              ProcessName='redis-server';   Port=6379; Rec='STOP';        Reason='~50MB; restart is instant' }
        @{ Name='Memurai';      ServiceName='Memurai';            ProcessName='memurai-server'; Port=6379; Rec='STOP';        Reason='Redis-compat; stop if Redis is preferred' }
        @{ Name='InfluxDB';     ServiceName='influxdb';           ProcessName='influxd';        Port=8086; Rec='CONDITIONAL'; Reason='Stop if not actively collecting metrics' }
        @{ Name='Waves Audio';  ServiceName='WavesSysSvc';        ProcessName='WavesSysSvc64';  Port=0;    Rec='CONDITIONAL'; Reason='Stop only if no audio output needed' }
        @{ Name='ZeroTier';     ServiceName='ZeroTierOneService'; ProcessName='ZeroTier One';   Port=9993; Rec='CONDITIONAL'; Reason='Stop if not using ZT VPN' }
        @{ Name='TeamViewer';   ServiceName='TeamViewer';         ProcessName='TeamViewer';     Port=5938; Rec='STOP';        Reason='Attack surface; start manually when remote support needed' }
        @{ Name='Adobe ARM';    ServiceName='AdobeARMservice';    ProcessName='armsvc';         Port=0;    Rec='STOP';        Reason='Updater service; no need to run continuously' }
        @{ Name='Jenkins';      ServiceName='Jenkins';            ProcessName='java';           Port=8080; Rec='CONDITIONAL'; Reason='Heavy; run only during CI/CD work' }
        @{ Name='Puppet';       ServiceName='puppet';             ProcessName='puppet';         Port=8140; Rec='STOP';        Reason='Config management agent; start manually' }
    )

    $stopped = 0; $skipped = 0; $report = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($svc in $serviceTargets) {
        $svcObj  = Get-Service $svc.ServiceName -ErrorAction SilentlyContinue
        $procObj = Get-Process -Name $svc.ProcessName -ErrorAction SilentlyContinue
        $portActive = if ($svc.Port -gt 0) {
            $null -ne (Get-NetTCPConnection -LocalPort $svc.Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1)
        } else { $false }
        $memMB = if ($procObj) { [math]::Round(($procObj | Measure-Object WorkingSet -Sum).Sum / 1MB, 1) } else { 0 }
        $isRunning = ($svcObj -and $svcObj.Status -eq 'Running') -or ($null -ne $procObj)

        $entry = @{
            Name = $svc.Name; Running = $isRunning; PortActive = $portActive
            MemoryMB = $memMB; Rec = $svc.Rec; Reason = $svc.Reason
        }
        $report.Add($entry)

        if (-not $isRunning) {
            Write-SOKLog "  IDLE: $($svc.Name) (not running)" -Level Ignore; continue
        }

        Write-SOKLog "  RUNNING: $($svc.Name) | $memMB MB | Port $($svc.Port) $(if($portActive){'ACTIVE'}else{'IDLE'})" -Level $(if ($memMB -gt 500) {'Warn'} else {'Ignore'})

        $shouldStop = ($svc.Rec -eq 'STOP') -or ($svc.Rec -eq 'CONDITIONAL' -and -not $portActive)
        if ($shouldStop -and $ServiceAction -ne 'Report') {
            $doStop = if ($ServiceAction -eq 'Interactive') {
                $ans = Read-Host "  Stop $($svc.Name)? ($($svc.Reason)) [Y/N]"
                $ans -match '^[Yy]'
            } else { $true }

            if ($doStop) {
                if ($DryRun) {
                    Write-SOKLog "  [DRY] Would stop: $($svc.Name)" -Level Ignore
                } else {
                    try {
                        if ($svcObj) { Stop-Service -Name $svc.ServiceName -Force -ErrorAction Stop; Set-Service -Name $svc.ServiceName -StartupType Manual -ErrorAction SilentlyContinue }
                        if ($procObj) { Start-Sleep -Milliseconds 300; $procObj | Stop-Process -Force -ErrorAction SilentlyContinue }
                        Write-SOKLog "  Stopped: $($svc.Name) (freed ~$memMB MB)" -Level Success
                        $stopped++
                    } catch { Write-SOKLog "  Stop failed: $($svc.Name) — $_" -Level Warn; $skipped++ }
                }
            }
        }
    }

    $totalFreedMB = ($report | Where-Object { $_.Running } | Measure-Object MemoryMB -Sum).Sum
    $GlobalState['ServiceOptimizer_Report'] = $report
    Write-SOKLog "ServiceOptimizer complete. Stopped: $stopped | Mode: $ServiceAction | Potential RAM freed: $([math]::Round($totalFreedMB,0)) MB" -Level Success
    Save-SOKHistory -ScriptName 'SOK-ServiceOptimizer' -RunData @{ Action=$ServiceAction; Stopped=$stopped; DryRun=$DryRun.IsPresent }
}

# ══════════════════════════════════════════════════════════════════════════════
# [4] MAINTENANCE — Package Updates, Cache Cleanup, System Optimization
# ══════════════════════════════════════════════════════════════════════════════
# Maintenance is the most time-intensive module — a Thorough run can take 30+
# minutes due to package manager update operations. The cumulative mode design
# lets you pick the tradeoff between thoroughness and duration.
#
# PACKAGE UPDATE PHILOSOPHY:
# We update across 5 managers because each owns different things:
#   choco: system binaries (PostgreSQL, Redis, tools installed as Windows services)
#   scoop: user-space portable tools (Neovim, FZF, CLI modernization tools)
#   winget: GUI apps + Microsoft Store integrations (VS Code, PowerShell, Teams)
#   pip:   Python ML/data science ecosystem (scikit-learn, torch, langchain)
#   npm:   Node.js global CLIs (TypeScript compiler, Playwright, etc.)
# Running all 5 ensures no "shadow outdated" dependencies persist.
#
# DIVERGENCE NOTE: This section inlines SOK-Maintenance.ps1 logic so GlobalState
# can be shared in-session. When SOK-Maintenance.ps1 is updated, sync changes here.
# Long-term: replace with `& SOK-Maintenance.ps1 -Mode $MaintMode` + GlobalState
# injected via env var handoff. Tracked as optimization area #3 (adaptive scheduling).
if ($Maintain) {
    Write-SOKLog "━━━ [4] MAINTENANCE: System Optimization ($MaintMode) ━━━" -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $allDrives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Continue)

    # ── 4a: Junction Health Check ────────────────────────────────────────────
    # Uses GlobalState from Inventory if available; otherwise does a targeted scan.
    Write-SOKLog "4a: Junction health check..." -Level Ignore
    $junctionRoots = @('C:\ProgramData', 'C:\Program Files', $env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA)
    $brokenJunctions = [System.Collections.Generic.List[string]]::new()
    foreach ($root in $junctionRoots) {
        if (-not (Test-Path $root)) { continue }
        try {
            foreach ($dir in [System.IO.Directory]::GetDirectories($root)) {
                $attr = [System.IO.File]::GetAttributes($dir)
                if (($attr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    $target = ([System.IO.DirectoryInfo]::new($dir)).LinkTarget
                    if ($target -and -not (Test-Path $target -ErrorAction SilentlyContinue)) {
                        $brokenJunctions.Add("$dir -> $target"); Write-SOKLog "  BROKEN: $dir -> $target" -Level Warn
                    }
                }
            }
        } catch { }
    }
    if ($brokenJunctions.Count -eq 0) { Write-SOKLog "  All junctions healthy." -Level Success }

    # ── 4b: Cache Cleanup (all modes) ────────────────────────────────────────
    # This is the safe cache cleanup — only caches that regenerate automatically.
    # Contrast with SOK-Cleanup (which kills processes first) and SOK-PreSwap
    # (which does a deep 46-path eviction before a drive swap).
    Write-SOKLog "4b: Core cache cleanup..." -Level Ignore
    $cacheTargets = @(
        $env:TEMP, "$env:WINDIR\Temp",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:USERPROFILE\.cache",
        "$env:LOCALAPPDATA\Temp",
        "$env:APPDATA\npm-cache",
        "$env:LOCALAPPDATA\pip\Cache"
    )
    foreach ($path in $cacheTargets) {
        if (-not (Test-Path $path)) { continue }
        if ($DryRun) { Write-SOKLog "[DRY] Would clean: $path" -Level Ignore; continue }
        try {
            Get-ChildItem $path -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-SOKLog "  Cleaned: $path" -Level Ignore
        } catch { Write-SOKLog "  Partial clean: $path" -Level Warn }
    }

    # Recycle bin
    if (-not $DryRun) {
        try { Clear-RecycleBin -Force -ErrorAction Stop; Write-SOKLog "  Recycle bin emptied." -Level Success }
        catch {
            # Fallback: Shell.Application COM for edge cases where CmdLet fails
            try { (New-Object -ComObject Shell.Application).Namespace(10).Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }; Write-SOKLog "  Recycle bin emptied (COM fallback)." -Level Success }
            catch { Write-SOKLog "  Recycle bin: $_" -Level Warn }
        }
    }

    # ── 4c: Package Updates (Standard+) ──────────────────────────────────────
    if ($MaintMode -in @('Standard', 'Deep', 'Thorough')) {
        Write-SOKLog "4c: Package manager updates (timeout: $PackageTimeoutSec s each)..." -Level Ignore
        if ($DryRun) {
            Write-SOKLog "[DRY] Would run: choco upgrade all, scoop update *, winget upgrade --all, pip updates, npm updates" -Level Warn
            # pip check is read-only — runs even in DryRun to surface conflicts
            if (Get-Command py -ErrorAction SilentlyContinue) {
                $pipDryCheck = py -3.14 -m pip check 2>&1
                $pipDryConflicts = @($pipDryCheck | Where-Object { $_ -and $_ -notmatch 'No broken requirements' })
                if ($pipDryConflicts.Count -gt 0) {
                    Write-SOKLog "  pip check: $($pipDryConflicts.Count) conflict(s)" -Level Warn
                    $pipDryConflicts | ForEach-Object { Write-SOKLog "    $_" -Level Warn }
                } else { Write-SOKLog "  pip check: no conflicts" -Level Success }
                # Cluster-A JSON-parse fix 2026-04-22: pip emits WARNING: lines on
                # stderr; 2>&1 merges them into stdout; ConvertFrom-Json chokes on "W"
                # at position 0 with a TERMINATING error that -ErrorAction
                # SilentlyContinue does NOT catch (this class of error bypasses the
                # preference). Separate stderr, wrap in try/catch.
                $dryOutdated = $null
                try {
                    $dryRaw = & py -3.14 -m pip list --outdated --format=json 2>$null
                    if ($dryRaw) { $dryOutdated = $dryRaw | ConvertFrom-Json -ErrorAction Stop }
                } catch {
                    Write-SOKLog "[DRY] pip outdated JSON parse failed (likely pip stderr warning): $($_.Exception.Message)" -Level Warn
                }
                Write-SOKLog "[DRY] pip: $(@($dryOutdated).Count) package(s) would be upgraded" -Level Debug
            }
        } else {
            # Chocolatey
            # Invoke-WithTimeout returns {Success:bool, Error:string, Output:string} — no .Status property.
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                Write-SOKLog "  choco upgrade all..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { choco upgrade all -y --no-progress 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  choco: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
            }
            # Scoop
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Write-SOKLog "  scoop update + upgrade..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { scoop update; scoop upgrade * 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  scoop: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
            }
            # Winget
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-SOKLog "  winget upgrade --all..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { winget upgrade --all --silent --accept-package-agreements --accept-source-agreements 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  winget: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
            }
            # pip — per-package upgrade (py -3.14 explicitly, avoids Altair Python collision)
            if (Get-Command py -ErrorAction SilentlyContinue) {
                # Pre-upgrade conflict audit
                $pipPreCheck = py -3.14 -m pip check 2>&1
                $pipPreConflicts = @($pipPreCheck | Where-Object { $_ -and $_ -notmatch 'No broken requirements' })
                if ($pipPreConflicts.Count -gt 0) {
                    Write-SOKLog "  pip check (pre): $($pipPreConflicts.Count) conflict(s)" -Level Warn
                    $pipPreConflicts | ForEach-Object { Write-SOKLog "    $_" -Level Warn }
                } else { Write-SOKLog "  pip check: no conflicts" -Level Success }

                Write-SOKLog "  pip outdated check (py -3.14)..." -Level Ignore
                # Cluster-A JSON-parse fix 2026-04-22: see line ~580 for rationale.
                # This is the live-mode twin of the DryRun fix above. Was the source of
                # the TERMINATING ERROR "W at position 0" flagged on the 23:34 run.
                $outdated = $null
                try {
                    $outRaw = & py -3.14 -m pip list --outdated --format=json 2>$null
                    if ($outRaw) { $outdated = $outRaw | ConvertFrom-Json -ErrorAction Stop }
                } catch {
                    Write-SOKLog "  pip outdated JSON parse failed (likely pip stderr warning): $($_.Exception.Message) — skipping pip upgrade phase" -Level Warn
                }
                if ($outdated) {
                    Write-SOKLog "  pip: $($outdated.Count) packages outdated" -Level Warn
                    foreach ($pkg in ($outdated | Select-Object -First 20)) {  # Cap at 20 to avoid timeout
                        Invoke-WithTimeout -ScriptBlock { py -3.14 -m pip install --upgrade $pkg.name --quiet 2>&1 } -TimeoutSec 60 | Out-Null
                    }
                    Write-SOKLog "  pip: updates applied (capped at 20, re-run for remainder)." -Level Success
                    # Post-upgrade conflict re-check
                    $pipPostCheck = py -3.14 -m pip check 2>&1
                    $pipPostConflicts = @($pipPostCheck | Where-Object { $_ -and $_ -notmatch 'No broken requirements' })
                    if ($pipPostConflicts.Count -gt 0) {
                        Write-SOKLog "  pip check (post): $($pipPostConflicts.Count) conflict(s) — review manually" -Level Warn
                        $pipPostConflicts | ForEach-Object { Write-SOKLog "    $_" -Level Warn }
                    } else { Write-SOKLog "  pip check (post): clean" -Level Success }
                } else { Write-SOKLog "  pip: all packages current." -Level Ignore }
            }
            # npm
            if (Get-Command npm -ErrorAction SilentlyContinue) {
                Write-SOKLog "  npm global outdated..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { npm update -g 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  npm: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
            }
            # Rust — rustup update + cargo install-update for all installed crates
            # cargo-update crate must be installed: cargo install cargo-update
            if (Get-Command rustup -ErrorAction SilentlyContinue) {
                Write-SOKLog "  rustup update + cargo install-update..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { rustup update 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  rustup: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
                if (Get-Command cargo -ErrorAction SilentlyContinue) {
                    $cu = Invoke-WithTimeout -ScriptBlock { cargo install-update --all 2>&1 } -TimeoutSec $PackageTimeoutSec
                    Write-SOKLog "  cargo install-update: $(if ($cu.Success) {'OK'} else {"FAILED (cargo-update installed? Run: cargo install cargo-update)"})" -Level $(if ($cu.Success) {'Ignore'} else {'Warn'})
                }
            }
            # Go — update toolchain + refresh GOPATH env (go env may have stale module cache)
            if (Get-Command go -ErrorAction SilentlyContinue) {
                Write-SOKLog "  go toolchain update..." -Level Ignore
                # go get -u updates modules in the current module's context only.
                # For the global tool install pattern, use go install pkg@latest.
                # The most broadly applicable maintenance step is refreshing the module cache proxy.
                $r = Invoke-WithTimeout -ScriptBlock { go env GOPATH 2>&1 } -TimeoutSec 30
                $gopath = if ($r.Success -and $r.Output) { $r.Output.Trim() } else { "$env:USERPROFILE\go" }
                if ($env:GOPATH -ne $gopath) {
                    [System.Environment]::SetEnvironmentVariable('GOPATH', $gopath, 'Process')
                    Write-SOKLog "  go: GOPATH refreshed to $gopath" -Level Ignore
                }
                # Clean module cache of stale/corrupt entries
                $rClean = Invoke-WithTimeout -ScriptBlock { go clean -modcache 2>&1 } -TimeoutSec 120
                Write-SOKLog "  go clean -modcache: $(if ($rClean.Success) {'OK'} else {"FAILED — $($rClean.Error)"})" -Level $(if ($rClean.Success) {'Ignore'} else {'Warn'})
            }
        }
    }

    # ── 4d: Deep System Optimization (Deep+) ─────────────────────────────────
    if ($MaintMode -in @('Deep', 'Thorough') -and -not $DryRun) {
        Write-SOKLog "4d: Deep optimization (DNS flush + TRIM + drive health)..." -Level Ignore
        Clear-DnsClientCache -ErrorAction SilentlyContinue; Write-SOKLog "  DNS cache flushed." -Level Success
        foreach ($drive in $allDrives | Where-Object { $_.FileSystem -eq 'NTFS' }) {
            try {
                Optimize-Volume -DriveLetter $drive.DeviceID.TrimEnd(':') -ReTrim -ErrorAction Stop
                Write-SOKLog "  TRIM: $($drive.DeviceID)" -Level Success
            } catch { Write-SOKLog "  TRIM failed: $($drive.DeviceID) — $_" -Level Warn }
        }
        # Drive health via physical disk SMART data
        foreach ($disk in Get-PhysicalDisk -ErrorAction SilentlyContinue) {
            $health = $disk.HealthStatus
            Write-SOKLog "  Disk '$($disk.FriendlyName)': $health" -Level $(if ($health -eq 'Healthy') {'Ignore'} else {'Warn'})
        }
    }

    # ── 4e: Thorough Mode Extras ──────────────────────────────────────────────
    if ($MaintMode -eq 'Thorough' -and -not $DryRun) {
        Write-SOKLog "4e: Thorough — NuGet purge + SSD wear + Windows Update..." -Level Ignore
        try { dotnet nuget locals all --clear 2>&1 | Out-Null; Write-SOKLog "  .NET NuGet locals cleared." -Level Success } catch {}
        # SSD wear reporting via StorageReliabilityCounter
        foreach ($disk in Get-PhysicalDisk -ErrorAction SilentlyContinue) {
            try {
                $rc = $disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
                if ($rc) {
                    $wearPct = if ($rc.Wear -gt 0) { "$($rc.Wear)%" } else { 'N/A' }
                    $hours   = if ($rc.PowerOnHours -gt 0) { "$($rc.PowerOnHours)h" } else { 'N/A' }
                    $state   = switch ($rc.Wear) {
                        { $_ -lt 10 } { 'HEALTHY' }
                        { $_ -lt 30 } { 'MODERATE' }
                        { $_ -lt 70 } { 'AGING' }
                        { $_ -lt 90 } { 'DEGRADED' }
                        default { 'CRITICAL' }
                    }
                    Write-SOKLog "  SSD Wear: $($disk.FriendlyName) | $wearPct worn | $hours on | $state" -Level $(if ($state -eq 'HEALTHY') {'Ignore'} else {'Warn'})
                }
            } catch { }
        }
        # Windows Update check (requires PSWindowsUpdate module)
        if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction SilentlyContinue) {
            Write-SOKLog "  Checking Windows Updates..." -Level Ignore
            $updates = Get-WindowsUpdate -ErrorAction SilentlyContinue
            if ($updates.Count -gt 0) { Write-SOKLog "  Windows Update: $($updates.Count) pending (run Install-WindowsUpdate -AutoReboot to apply)" -Level Warn }
            else { Write-SOKLog "  Windows Update: system current." -Level Success }
        }
    }

    Write-SOKLog "Maintenance ($MaintMode) complete." -Level Success
    Save-SOKHistory -ScriptName 'SOK-Maintenance' -RunData @{ Mode=$MaintMode; DryRun=$DryRun.IsPresent; BrokenJunctions=$brokenJunctions.Count }
}

# ══════════════════════════════════════════════════════════════════════════════
# [5] CLEANUP — Kill Lock Holders + Deep Cache Eviction
# ══════════════════════════════════════════════════════════════════════════════
# Cleanup differs from Maintenance's cache cleanup in one key way: it KILLS
# processes first. Chrome, Slack, Discord, and GitKraken hold lock handles on
# their cache directories — you cannot delete them while the app is running.
# Cleanup solves this with a targeted process kill (not the broad sweep of
# ProcessOptimizer) followed by a 3-second pause for handles to release.
#
# The skip rationale for Outlook/Spotify is preserved from SOK-Cleanup v1.0:
# Deleting Outlook's web cache forces a full re-sync (hours of re-download).
# Deleting Spotify's cache causes a session logout (annoying, not catastrophic).
# Neither is worth the tradeoff for the space saved.
if ($Clean) {
    Write-SOKLog '━━━ [5] CLEANUP: Process Kill + Deep Cache Eviction ━━━' -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    # Kill lock-holding processes before attempting cache deletion.
    # Claude is included because its Code Cache can reach 2+ GB and grows unbounded.
    # However: if the operator has added 'Claude' to $config.ProtectedProcesses, we respect that.
    # The typical use case for protection is running this script from inside the Claude desktop app.
    $candidateKills = @('chrome', 'msedge', 'Claude', 'Slack', 'Discord', 'GitKraken', 'Cypress', 'Insomnia', 'AcroCEF', 'Acrobat')
    # C-1 fix 2026-04-21: namespaced $config.ProcessOptimizer.ProtectedProcesses + case-normalized comparison
    $cfgProtected = @($config.ProcessOptimizer.ProtectedProcesses) |
        Where-Object { $_ } |
        ForEach-Object { $_.ToString().ToLower() }
    $processesToKill = $candidateKills | Where-Object { $_.ToLower() -notin $cfgProtected }
    if ($candidateKills.Count -ne $processesToKill.Count) {
        $skippedProcs = $candidateKills | Where-Object { $_.ToLower() -in $cfgProtected }
        Write-SOKLog "  Protected processes excluded from kill list: $($skippedProcs -join ', ')" -Level Warn
    }
    foreach ($proc in $processesToKill) {
        $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
        if ($running) {
            if ($DryRun) { Write-SOKLog "[DRY] Would stop: $proc" -Level Ignore }
            else { $running | Stop-Process -Force -ErrorAction Continue; Write-SOKLog "  Stopped: $proc" -Level Warn }
        }
    }
    if (-not $DryRun) { Start-Sleep -Seconds 3 }  # Wait for handles to release

    # Deep cache eviction — 10 cache paths
    # NOTE: Outlook Web Cache and Spotify omitted intentionally (see header)
    $cacheTargets = @(
        "$env:TEMP",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:USERPROFILE\.cache",
        "$env:APPDATA\Claude\Code Cache",
        "$env:APPDATA\Claude\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge Dev\User Data\Default\Cache",
        "$env:APPDATA\Slack\Code Cache",
        "$env:APPDATA\Discord\Code Cache",
        "$env:APPDATA\Adobe\Acrobat\DC\Cache",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache",
        "$env:APPDATA\Cypress\cy\production\cache"
    )

    $deletedKB = 0L
    foreach ($path in $cacheTargets) {
        if (-not (Test-Path $path)) { continue }
        if ($DryRun) {
            try {
                $sz = (Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                Write-SOKLog "[DRY] Would clean: $path ($([math]::Round($sz/1KB,0)) KB)" -Level Ignore
            } catch { Write-SOKLog "[DRY] Would clean: $path" -Level Ignore }
        } else {
            try {
                $beforeSz = (Get-ChildItem $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                Get-ChildItem $path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                $deletedKB += [math]::Round($beforeSz / 1KB, 0)
                Write-SOKLog "  Cleaned: $path" -Level Success
            } catch { Write-SOKLog "  Partial clean: $path" -Level Warn }
        }
    }

    Write-SOKLog "Cleanup complete. Freed: $([math]::Round($deletedKB/1MB,2)) GB" -Level Success
    Save-SOKHistory -ScriptName 'SOK-Cleanup' -RunData @{ FreedKB=$deletedKB; DryRun=$DryRun.IsPresent }
}

# ══════════════════════════════════════════════════════════════════════════════
# [6] PRESWAP — Deep Junction Repair + Cache Eviction Before Drive Swap
# ══════════════════════════════════════════════════════════════════════════════
# PreSwap is the "operating room prep" script — run it before swapping the E:
# drive for a larger one, or before performing a major junction restructure.
# It does a deep (46-path) cache eviction, repairs the Scoop apps junction
# (which contains nested junctions that must be stripped before robocopy),
# and renames choco .exe shims before moving the lib directory.
# It is intentionally excluded from -All because it is interactive and takes
# significant time. Run it explicitly when preparing for a drive swap.
if ($PreSwap) {
    Write-SOKLog '━━━ [6] PRESWAP: Deep Junction Repair + Pre-Swap Cache Eviction ━━━' -Level Section
    Write-SOKLog 'This module prepares the machine for an E: drive swap or major offload operation.' -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    # ── Phase 1: Repair critical junctions ───────────────────────────────────
    Write-SOKLog "Phase 1: Repairing critical junctions..." -Level Ignore

    function Repair-Junction {
        param([string]$Source, [string]$Target, [string]$Label, [switch]$StripInternalJunctions, [switch]$RenameExesFirst)
        $sourceExists = Test-Path $Source
        $targetExists = Test-Path $Target
        if (-not $targetExists) { Write-SOKLog "  SKIP ${Label}: target $Target not found" -Level Warn; return }
        $isAlreadyJunction = $sourceExists -and (([System.IO.File]::GetAttributes($Source) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
        if ($isAlreadyJunction) {
            $currentTarget = ([System.IO.DirectoryInfo]::new($Source)).LinkTarget
            if ($currentTarget -eq $Target) { Write-SOKLog "  OK $Label (junction valid)" -Level Ignore; return }
            Write-SOKLog "  Fixing ${Label}: wrong target ($currentTarget -> $Target)" -Level Warn
        }
        if ($DryRun) { Write-SOKLog "  [DRY] Would repair junction: $Source -> $Target" -Level Ignore; return }
        if ($RenameExesFirst -and $sourceExists -and -not $isAlreadyJunction) {
            Get-ChildItem $Source -Filter '*.exe' -Recurse -ErrorAction SilentlyContinue |
                ForEach-Object { Rename-Item $_.FullName "$($_.FullName).bak" -Force -ErrorAction SilentlyContinue }
        }
        if ($StripInternalJunctions -and $sourceExists -and -not $isAlreadyJunction) {
            Get-ChildItem $Source -Recurse -Force -ErrorAction SilentlyContinue |
                Where-Object { ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0 } |
                ForEach-Object { cmd /c "rmdir `"$($_.FullName)`"" 2>$null | Out-Null }
        }
        if ($sourceExists -and -not $isAlreadyJunction) {
            $roboArgs = @($Source, (Join-Path $env:TEMP 'SOK_empty_src'), '/E', '/MOVE', '/R:1', '/W:1', '/NFL', '/NDL', '/NP')
            New-Item -Path (Join-Path $env:TEMP 'SOK_empty_src') -ItemType Directory -Force | Out-Null
            & robocopy @roboArgs 2>&1 | Out-Null
            Remove-Item (Join-Path $env:TEMP 'SOK_empty_src') -Force -ErrorAction SilentlyContinue
            Remove-Item $Source -Recurse -Force -ErrorAction SilentlyContinue
        } elseif ($isAlreadyJunction) {
            cmd /c "rmdir `"$Source`"" 2>$null | Out-Null
        }
        $result = cmd /c "mklink /J `"$Source`" `"$Target`"" 2>&1
        if ($LASTEXITCODE -eq 0) { Write-SOKLog "  Repaired: $Label ($Source -> $Target)" -Level Success }
        else { Write-SOKLog "  Junction repair failed: $Label — $result" -Level Error }
    }

    Repair-Junction -Source "$env:USERPROFILE\scoop\apps" -Target "$ExternalDrive\SOK_Offload\C_Users_shelc_scoop_apps" -Label "Scoop apps" -StripInternalJunctions
    Repair-Junction -Source "C:\ProgramData\chocolatey\lib" -Target "$ExternalDrive\SOK_Offload\C_ProgramData_chocolatey_lib" -Label "Choco lib" -RenameExesFirst

    # ── Phase 2: Deep cache eviction (46 paths) ───────────────────────────────
    # Kill all lock-holding apps first
    Write-SOKLog "Phase 2: Killing lock-holding applications..." -Level Ignore
    $killList = @('chrome', 'msedge', 'Slack', 'Discord', 'GitKraken', 'Cypress', 'Insomnia', 'AcroCEF', 'Acrobat', 'Logseq', 'Postman', 'balena_etcher', 'signal', 'Bitwarden', 'GitHubDesktop', 'Zoom', 'Teams', 'obs64', 'obs32', 'Code', 'Grammarly', 'Kindle')
    foreach ($proc in $killList) {
        if (-not $DryRun) { Get-Process $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue }
    }
    if (-not $DryRun) { Start-Sleep -Seconds 5 }

    $deepCachePaths = @(
        $env:TEMP, "$env:WINDIR\Temp", "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
        "$env:APPDATA\Slack\Code Cache", "$env:APPDATA\Discord\Code Cache",
        "$env:APPDATA\Acrobat\DC\Cache", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:APPDATA\npm-cache", "$env:USERPROFILE\.cache",
        "$env:LOCALAPPDATA\pip\Cache", "$env:USERPROFILE\AppData\LocalLow\Microsoft\CryptnetUrlCache",
        "$env:APPDATA\GitKraken\logs", "$env:APPDATA\Logseq\IndexedDB",
        "$env:APPDATA\Claude\Code Cache", "$env:APPDATA\Claude\Cache",
        "$env:APPDATA\Cypress\cy\production\cache",
        "$env:LOCALAPPDATA\Microsoft\Terminal Server Client\Cache",
        "$env:LOCALAPPDATA\D3DSCache", "$env:LOCALAPPDATA\CrashDumps"
    )
    foreach ($path in $deepCachePaths) {
        if (-not (Test-Path $path)) { continue }
        if ($DryRun) { Write-SOKLog "[DRY] Would evict: $path" -Level Ignore }
        else {
            Get-ChildItem $path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-SOKLog "  Evicted: $path" -Level Ignore
        }
    }
    # Package manager caches
    if (-not $DryRun) {
        py -3.14 -m pip cache purge 2>&1 | Out-Null; Write-SOKLog "  pip cache purged." -Level Ignore
        npm cache clean --force 2>&1 | Out-Null;     Write-SOKLog "  npm cache purged." -Level Ignore
        dotnet nuget locals all --clear 2>&1 | Out-Null; Write-SOKLog "  NuGet cache purged." -Level Ignore
    }
    Write-SOKLog "PreSwap complete. Machine prepared for drive operations." -Level Success
}

# ══════════════════════════════════════════════════════════════════════════════
# [7] REBOOT CLEAN — Post-Reboot Junction Verification
# ══════════════════════════════════════════════════════════════════════════════
# After reboot, files that were locked during the last session (temp files,
# D3D shader cache, ETW logs) can finally be deleted. More importantly, Windows
# sometimes recreates directories over junctions during updates (e.g., JetBrains
# ETW host). RebootClean verifies 12 expected junctions and repairs any that
# reverted to real directories during the reboot.
# NOTE: If you add junctions via SOK-FUTURE -Offload, update $expectedJunctions here too.
if ($RebootClean) {
    Write-SOKLog '━━━ [7] REBOOT CLEAN: Post-Reboot Junction Verification + Temp Cleanup ━━━' -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    # Clear persistent temp locks freed by reboot
    foreach ($tempPath in @($env:TEMP, "$env:WINDIR\Temp")) {
        if ($DryRun) { Write-SOKLog "[DRY] Would clean post-reboot temp: $tempPath" -Level Ignore }
        else { Get-ChildItem $tempPath -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
    }

    # 12 expected junctions — validate source→target mapping
    $expectedJunctions = @(
        @{ Source = "$env:USERPROFILE\.pyenv";                  Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_.pyenv" }
        @{ Source = "$env:USERPROFILE\scoop\cache";             Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_scoop_cache" }
        @{ Source = "$env:USERPROFILE\scoop\apps";              Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_scoop_apps" }
        @{ Source = "$env:USERPROFILE\.nuget\packages";         Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_.nuget_packages" }
        @{ Source = "$env:USERPROFILE\.cargo\registry";         Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_.cargo_registry" }
        @{ Source = "$env:USERPROFILE\.vscode\extensions";      Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_.vscode_extensions" }
        @{ Source = "$env:USERPROFILE\AppData\Local\JetBrains"; Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_AppData_Local_JetBrains" }
        @{ Source = "C:\tools\flutter";                         Target = "$ExternalDrive\SOK_Offload\C_tools_flutter" }
        @{ Source = "C:\Program Files\JetBrains";               Target = "$ExternalDrive\SOK_Offload\C_Program Files_JetBrains" }
        @{ Source = "C:\ProgramData\chocolatey\lib";            Target = "$ExternalDrive\SOK_Offload\C_ProgramData_chocolatey_lib" }
        @{ Source = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"; Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_AppData_Local_WinGet_Packages" }
        @{ Source = "$env:USERPROFILE\scoop\persist\rustup\.cargo\registry"; Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_scoop_persist_rustup_.cargo_registry" }
    )

    $ok = 0; $broken = 0; $missing = 0
    foreach ($jxn in $expectedJunctions) {
        $srcExists = Test-Path $jxn.Source
        $isJunction = $srcExists -and (([System.IO.File]::GetAttributes($jxn.Source) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
        $tgtExists  = Test-Path $jxn.Target -ErrorAction SilentlyContinue

        if ($isJunction -and $tgtExists) { Write-SOKLog "  OK: $(Split-Path $jxn.Source -Leaf)" -Level Ignore; $ok++ }
        elseif (-not $srcExists -and -not $tgtExists) { Write-SOKLog "  MISSING (both sides absent): $($jxn.Source)" -Level Warn; $missing++ }
        elseif (-not $tgtExists) { Write-SOKLog "  BROKEN (target offline): $($jxn.Source) -> $($jxn.Target)" -Level Warn; $broken++ }
        else { Write-SOKLog "  IS REAL DIR (reverted!): $($jxn.Source) — needs repair" -Level Error; $broken++ }
    }

    Write-SOKLog "Junction check: $ok OK | $broken broken | $missing missing" -Level $(if ($broken -gt 0) {'Warn'} else {'Success'})

    # Quick tool version spot-check (confirms PATH is correctly configured post-reboot)
    Write-SOKLog "Tool version spot-check:" -Level Ignore
    foreach ($tool in @(@{Cmd='scoop';Args='--version'},@{Cmd='choco';Args='--version'},@{Cmd='node';Args='--version'},@{Cmd='py';Args='--version'},@{Cmd='git';Args='--version'})) {
        if (Get-Command $tool.Cmd -ErrorAction SilentlyContinue) {
            $v = (& $tool.Cmd $tool.Args 2>&1 | Select-Object -First 1) -replace '\r?\n',''
            Write-SOKLog "  $($tool.Cmd): $v" -Level Ignore
        } else { Write-SOKLog "  MISSING: $($tool.Cmd)" -Level Warn }
    }
    Write-SOKLog "RebootClean complete." -Level Success
}

# ══════════════════════════════════════════════════════════════════════════════
# [8] LIVE SCAN — Streaming Filesystem Inventory
# ══════════════════════════════════════════════════════════════════════════════
# LiveScan produces a real-time JSON inventory of the filesystem using .NET
# streaming (1MB buffer). It deliberately does NOT load the full file list into
# memory — on a 1TB drive with 500k+ files, that would require 2-4 GB of RAM.
# Instead, each entry is written immediately to the output stream.
# The resulting JSON feeds LiveDigest (below) for human-readable summarization.
if ($LiveScan) {
    Write-SOKLog '━━━ [8] LIVE SCAN: Streaming Filesystem Inventory ━━━' -Level Section
    Write-SOKLog "Source: $LiveScanSource | DirsOnly: $LiveScanDirsOnly | ExcludeNoisy: $LiveScanExcludeNoisy" -Level Ignore
    if ($DryRun) { Write-SOKLog '[DRY] Would stream scan to JSON. Skipping.' -Level Warn }
    else {
        $outDir  = Get-ScriptLogDir -ScriptName 'SOK-LiveScan'
        $ts      = Get-Date -Format 'yyyyMMdd_HHmmss'
        $outJson = Join-Path $outDir "LiveScan_$ts.json"
        $errLog  = Join-Path $outDir "LiveScan_Errors_$ts.log"

        $noisyRegex = [regex]::new('(?ix)\\(AppData\\Local\\Microsoft\\Windows\\WebCache|WinSxS|node_modules)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
        $enumOpts   = [System.IO.EnumerationOptions]::new()
        $enumOpts.RecurseSubdirectories = $true; $enumOpts.IgnoreInaccessible = $true
        $enumOpts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint

        # M-6 (Cluster C) consistency 2026-04-22: 1MB → 128KB
        $utf8   = [System.Text.Encoding]::UTF8
        $stream = [System.IO.FileStream]::new($outJson, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read, 131072)
        $writer = [System.IO.StreamWriter]::new($stream, $utf8)
        $errStream = [System.IO.StreamWriter]::new($errLog, $false, $utf8)
        $count = 0; $errCount = 0; $scanStart = Get-Date

        try {
            $writer.WriteLine('{"meta":{"script":"SOK-LiveScan","source":"' + $LiveScanSource + '","started":"' + (Get-Date -Format 'o') + '"},"items":[')
            $first = $true
            $root  = [System.IO.DirectoryInfo]::new($LiveScanSource)
            $items = if ($LiveScanDirsOnly) { $root.EnumerateDirectories('*', $enumOpts) }
                     else { $root.EnumerateFiles('*', $enumOpts) }
            foreach ($item in $items) {
                # EnumerateFiles/EnumerateDirectories with IgnoreInaccessible set will skip
                # most permission errors silently, but malformed reparse points and certain
                # network path errors still surface as exceptions during iteration.
                try {
                    if ($LiveScanExcludeNoisy -and $noisyRegex.IsMatch($item.FullName)) { continue }
                    $prefix = if ($first) { $first = $false; '' } else { ',' }
                    if ($LiveScanDirsOnly) {
                        $writer.WriteLine($prefix + '{"p":"' + ($item.FullName -replace '\\','\\' -replace '"','\"') + '","m":"' + $item.LastWriteTime.ToString('o') + '"}')
                    } else {
                        $writer.WriteLine($prefix + '{"p":"' + ($item.FullName -replace '\\','\\' -replace '"','\"') + '","s":' + [math]::Round($item.Length/1KB,0) + ',"m":"' + $item.LastWriteTime.ToString('o') + '"}')
                    }
                    $count++
                    if ($count % 10000 -eq 0) { Write-SOKLog "  LiveScan: $count items..." -Level Ignore; $writer.Flush() }
                } catch {
                    $errStream.WriteLine("[$($item.FullName)] $_")
                    $errCount++
                }
            }
            $duration = [math]::Round(((Get-Date) - $scanStart).TotalSeconds, 1)
            $writer.WriteLine('],"summary":{"total_items":' + $count + ',"errors":' + $errCount + ',"duration_seconds":' + $duration + '}}')
            Write-SOKLog "LiveScan complete: $count items, ${duration}s -> $outJson" -Level Success
            $GlobalState['LiveScan_OutputPath'] = $outJson
        } catch { Write-SOKLog "LiveScan error: $_" -Level Error }
        finally {
            if ($writer)    { $writer.Flush();    $writer.Dispose()    }
            if ($stream)    { $stream.Dispose()    }
            if ($errStream) { $errStream.Dispose() }
        }
        Save-SOKHistory -ScriptName 'SOK-LiveScan' -RunData @{ ItemCount=$count; DurationSec=$duration; Source=$LiveScanSource }
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# [9] LIVE DIGEST — Summarize Latest LiveScan into TopN Report
# ══════════════════════════════════════════════════════════════════════════════
# LiveDigest reads the most recent LiveScan JSON and produces a human-readable
# summary: top N largest directories, extension breakdown, and largest individual
# files. It is the "dashboard readout" that completes the LiveScan pipeline.
# If LiveScan was just run in this session, it reads directly from GlobalState
# (avoiding a second disk read of potentially 500MB+ JSON).
if ($LiveDigest) {
    Write-SOKLog '━━━ [9] LIVE DIGEST: Telemetry Summarization ━━━' -Level Section

    # Prefer in-session GlobalState output, then explicit path, then latest log.
    # IMPORTANT: Get-LatestLog returns a [PSCustomObject] {Path, Name, Age, Data} — NOT a path string.
    # Use Get-LatestLogPath (Common v4.4.0+) which unwraps .Path for callers that only need the file path.
    $inputPath = if ($DigestInputPath) { $DigestInputPath }
        elseif ($GlobalState.ContainsKey('LiveScan_OutputPath')) { $GlobalState['LiveScan_OutputPath'] }
        else { Get-LatestLogPath -ScriptName 'SOK-LiveScan' }

    if (-not $inputPath -or -not (Test-Path $inputPath)) {
        Write-SOKLog "No LiveScan JSON found. Run -LiveScan first or provide -DigestInputPath." -Level Warn
    } elseif ($DryRun) {
        Write-SOKLog "[DRY] Would parse $inputPath for TopN=$DigestTopN summary." -Level Ignore
    } else {
        Write-SOKLog "Parsing: $inputPath ($([math]::Round((Get-Item $inputPath).Length/1MB,1)) MB)..." -Level Ignore
        try {
            $scanData = Get-Content $inputPath -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if (-not $scanData -or -not $scanData.items) { Write-SOKLog "LiveScan JSON empty or malformed." -Level Warn }
            else {
                # Group by top-level 3-path-component (drive\tier1\tier2)
                $topFolders = $scanData.items | Where-Object { $_.s } |
                    Group-Object { ($_.p -split '\\')[0..2] -join '\' } |
                    Select-Object Name, @{N='Count';E={$_.Count}}, @{N='SizeKB';E={($_.Group | Measure-Object s -Sum).Sum}} |
                    Sort-Object SizeKB -Descending | Select-Object -First $DigestTopN

                $extBreakdown = $scanData.items | Where-Object { $_.p -match '\.' } |
                    Group-Object { [System.IO.Path]::GetExtension($_.p).ToLower() } |
                    Select-Object Name, @{N='Count';E={$_.Count}}, @{N='SizeKB';E={($_.Group | Measure-Object s -Sum).Sum}} |
                    Sort-Object SizeKB -Descending | Select-Object -First 30

                $largest = $scanData.items | Where-Object { $_.s } |
                    Sort-Object s -Descending | Select-Object -First $DigestTopN |
                    Select-Object p, s, m

                $outDir   = Get-ScriptLogDir -ScriptName 'SOK-LiveDigest'
                $ts       = Get-Date -Format 'yyyyMMdd_HHmmss'
                $outJson  = Join-Path $outDir "LiveDigest_$ts.json"
                $digestData = @{
                    GeneratedAt = (Get-Date -Format 'o')
                    SourceFile  = $inputPath
                    TopN        = $DigestTopN
                    TopFolders  = $topFolders
                    Extensions  = $extBreakdown
                    LargestFiles= $largest
                }
                $digestData | ConvertTo-Json -Depth 6 | Out-File $outJson -Encoding utf8 -Force
                Write-SOKLog "LiveDigest saved: $outJson" -Level Success

                # Console summary
                Write-SOKLog "Top 10 directories by size:" -Level Section
                $topFolders | Select-Object -First 10 | ForEach-Object {
                    Write-SOKLog "  $([math]::Round($_.SizeKB/1MB,2)) GB — $($_.Name)  ($($_.Count) files)" -Level Ignore
                }
            }
        } catch { Write-SOKLog "LiveDigest parse error: $_" -Level Error }
    }
}

} catch {
    Write-SOKLog "TERMINATING ERROR in SOK-PRESENT: $_" -Level Error
} finally {
    $duration = [math]::Round(((Get-Date) - $GlobalStartTime).TotalSeconds, 1)

    # RAM delta — compare against baseline captured before any module ran
    $ramAfter = try { (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory } catch { 0 }
    $ramDeltaMB = [math]::Round(($ramAfter - $ramBefore) / 1KB, 0)  # FreePhysicalMemory is in KB
    $ramDeltaSign = if ($ramDeltaMB -ge 0) { "+$ramDeltaMB" } else { "$ramDeltaMB" }

    Write-SOKLog "━━━ SOK-PRESENT EXECUTION COMPLETE (${duration}s) ━━━" -Level Section
    if ($DryRun) { Write-SOKLog "DRY RUN — no persistent changes were made to disk." -Level Warn }

    # Surface key results for operator review
    Write-SOKLog "RAM: $([math]::Round($ramAfter/1MB,2)) GB free now | ${ramDeltaSign} MB vs baseline" -Level $(if ($ramDeltaMB -gt 0) {'Success'} else {'Ignore'})
    if ($GlobalState.ContainsKey('ProcessOptimizer_Killed')) {
        Write-SOKLog "Processes killed: $($GlobalState['ProcessOptimizer_Killed'])" -Level Ignore
    }
    if ($GlobalState.ContainsKey('LiveScan_OutputPath')) {
        Write-SOKLog "LiveScan output: $($GlobalState['LiveScan_OutputPath'])" -Level Ignore
    }
    Write-SOKLog "Next: SOK-FUTURE.ps1 -Offload (protect gains) | SOK-PAST.ps1 -AuditSpace (verify)" -Level Ignore
    Save-SOKHistory -ScriptName 'SOK-PRESENT' -RunData @{ Modules=$ActiveModules; DurationSec=$duration; DryRun=$DryRun.IsPresent; RamDeltaMB=$ramDeltaMB }
}
