#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-Common.psm1 — Shared module for all SOK automation scripts.
.DESCRIPTION
    v4.6.1 (2026-04-14 post-crash recovery): three surgical fixes to unblock SOK-TestBatch.
    (1) Save-SOKHistory: $history now a List[object] instead of @()-seeded array; the prior
        `$history = if (...) { @($parsed) }` pattern unwrapped 1-element arrays back to
        a PSCustomObject scalar, which has no op_Addition — every test that reached
        Save-SOKHistory with a prior single-entry _history.json file exploded with
        "does not contain a method named 'op_Addition'". Serialization now -AsArray.
    (2) Write-SOKLog: 'Info' added to ValidateSet (case-insensitive match for 'INFO').
        189 call sites across PAST-v2, PAST-Verbose, PAST-BlankSlate used 'INFO' and
        all FATAL-ed at banner-time on the ValidateSet rejection.
    (3) Show-SOKBanner: -Title aliased to -ScriptName. PAST-v2 and ~8 local-fallback
        definitions use -Title; the canonical used -ScriptName. Both now accepted.

    v4.6.0: PrerequisiteMap — factorial pass against full script family (15 tactical + 3 utility):
    (1) DefenderOptimizer added as ?optional prereq to all disk-intensive scripts:
        Maintenance, SpaceAudit, LiveScan, Backup, Offload, BackupRestructure.
        Rationale: AV at full throttle adds 5-10x overhead to binary downloads, parallel
        disk scans, robocopy transfers, and 7z extractions. Throttling first is always correct.
    (2) New utility scripts wired into map:
        Install-GitHubRelease → ?SOK-Inventory (ScanInventory mode needs fresh JSON)
        Export-SoftwareManifest → ?SOK-DefenderOptimizer (package manager queries faster)
        SOK-Vectorize → ?SOK-InfraFix (junction health for E: traversal)
        SOK-ProjectsReorg, SOK-Reinstall → @() (one-shot tools, no prereqs)

    v4.5.0: PrerequisiteMap expanded — SOK-Backup, SOK-BackupRestructure, SOK-DriveViability
    added; SOK-Inventory prereq corrected (InfraFix, not Maintenance — fixes junction health
    before scan); SOK-Archiver gets optional Inventory prereq; SOK-Cleanup gains optional
    SpaceAudit prereq (improves target precision). Invoke-SOKPrerequisite wired into
    ProcessOptimizer, Restructure, PreSwap, LiveDigest, Archiver, BackupRestructure.

    v4.4.0: Temporal architecture additions (PrerequisiteMap entries for PAST/PRESENT/FUTURE,
    TemporalRunSequence, New-SOKStateDict), Invoke-WithTimeout rewritten to use
    Start-ThreadJob (inherits PATH — fixes choco/scoop/winget not-found in jobs),
    Get-LatestLogPath convenience wrapper (eliminates PSCustomObject→path casting bugs
    across all three temporal scripts), Save-SOKHistory now captures full RunData
    (not just .Duration/.Results), Write-SOKDivider helper. Version comment aligned
    with constant. All exports updated.

    BREAKING CHANGE from v4.3.x:
    - Invoke-WithTimeout now requires ThreadJob module (auto-imported; bundled in PS7.2+)
    - Save-SOKHistory stores full RunData under 'Results' key (superset of prior behavior)

.NOTES
    Author: S. Clay Caddell
    Version: 4.6.0
    Date: 07Apr2026
#>

# ═══════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════
$script:SOKVersion = '4.6.1'
$script:SOKName    = 'SOK'

# Date format strings — used consistently across all log output
$script:DateDisplay = 'ddMMMyyyy HH:mm:ss'
$script:DateISO     = 'yyyy-MM-dd HH:mm:ss'
$script:DateFile    = 'yyyyMMdd_HHmmss'

# Filesystem roots — all script path resolution bottoms out here
$script:ProjectRoot = 'C:\Users\shelc\Documents\Journal\Projects'
$script:ScriptBase  = Join-Path $script:ProjectRoot 'scripts'
$script:CommonPath  = Join-Path $script:ScriptBase 'common\SOK-Common.psm1'
$script:ConfigPath  = Join-Path $script:ScriptBase 'config\sok-config.json'
$script:SOKRoot     = Join-Path $script:ProjectRoot 'SOK'
$script:DefaultLogBase = Join-Path $script:SOKRoot 'Logs'

# Tuned constants — all values are deliberate; document before changing
$script:LOCK_TIMEOUT_SEC          = 30      # History file lock wait ceiling
$script:LOCK_POLL_MS              = 240     # History lock poll interval (Fibonacci: 240ms)
$script:HISTORY_CAP               = 666     # Max history entries per script (ring buffer)
$script:DEFAULT_MAX_LOG_AGE_DAYS  = 160     # Log rotation cutoff
$script:DEFAULT_STALE_HOURS       = 48      # Prerequisite freshness threshold
$script:DEFAULT_TIMEOUT_SEC       = 360     # Default per-operation timeout (6 minutes)
$script:PREREQUISITE_NESTING_LIMIT = 21     # Max recursive prerequisite depth (Fibonacci)
$script:MAX_UTILIZATION_PCT       = 96      # E: drive budget ceiling (96% leaves ~4 GB head room)
$script:SKIP_CLAUDE               = $true   # Exclude claude.exe from ALL process kill operations

# ── Legacy 10-script run sequence (preserved for SOK-Scheduler compatibility) ──
# SOK-Scheduler.ps1 still references these individual script names.
# Do NOT modify this list without updating SOK-Scheduler.ps1.
$script:RunSequence = @(
    'SOK-Inventory'; 'SOK-SpaceAudit'; 'SOK-ProcessOptimizer'; 'SOK-ServiceOptimizer'
    'SOK-DefenderOptimizer'; 'SOK-Maintenance'; 'SOK-Offload'; 'SOK-Cleanup'
    'SOK-LiveScan'; 'SOK-LiveDigest'
)

# ── Temporal run sequence (for the three meta-scripts) ──────────────────────
# SOK-Scheduler can reference this for temporal-mode scheduling.
# Note: PAST is always a prerequisite for FUTURE; PRESENT is independent.
$script:TemporalRunSequence = @('SOK-PAST', 'SOK-PRESENT', 'SOK-FUTURE')

# ── Prerequisite map ─────────────────────────────────────────────────────────
# ? prefix = optional (run if stale, but do not block if unavailable)
# No prefix = required (block and run if stale)
# Entries cover both the legacy individual scripts and the new temporal meta-scripts.
$script:PrerequisiteMap = @{
    # ── Tactical scripts ───────────────────────────────────────────────────────
    # InfraFix: no prereqs — heals junctions; must run unconditionally as the repair tool
    'SOK-InfraFix'              = @()
    # Inventory: InfraFix (optional) ensures junction map is accurate before filesystem scan
    'SOK-Inventory'             = @('?SOK-InfraFix')
    # DefenderOptimizer: no prereqs — AV throttle is a precondition for disk-intensive work
    'SOK-DefenderOptimizer'     = @()
    # Maintenance: Inventory for package baseline; DefenderOptimizer reduces AV scanning
    # overhead during binary downloads (choco/scoop/winget/pip) — turns 15-min stalls into 2 min
    'SOK-Maintenance'           = @('SOK-Inventory', '?SOK-DefenderOptimizer')
    # SpaceAudit: Inventory for drive topology; Offload (optional) for accurate C: usage;
    # DefenderOptimizer for 13-thread parallel scan (AV scans every opened file handle)
    'SOK-SpaceAudit'            = @('SOK-Inventory', '?SOK-Offload', '?SOK-DefenderOptimizer')
    # Circular optional prereqs: process instances vs. service startup states — different layers,
    # each benefits from the other having run. Both optional — no loop risk.
    'SOK-ProcessOptimizer'      = @('?SOK-ServiceOptimizer')
    'SOK-ServiceOptimizer'      = @('?SOK-ProcessOptimizer')
    # Offload: Inventory for junction map (avoid re-offloading already-moved dirs);
    # DefenderOptimizer reduces AV overhead during large directory moves
    'SOK-Offload'               = @('SOK-Inventory', '?SOK-DefenderOptimizer')
    # Cleanup: Maintenance required; SpaceAudit optional — improves target precision
    'SOK-Cleanup'               = @('SOK-Maintenance', '?SOK-SpaceAudit')
    # LiveScan: Inventory optional (scoped exclusion list); DefenderOptimizer for filesystem streaming
    'SOK-LiveScan'              = @('?SOK-Inventory', '?SOK-DefenderOptimizer')
    'SOK-LiveDigest'            = @('SOK-LiveScan')
    'SOK-Scheduler'             = @('SOK-DefenderOptimizer')
    'SOK-Archiver'              = @('?SOK-Inventory')
    # Backup: Inventory required (drive state); Archiver optional (snapshot before mirror);
    # DefenderOptimizer reduces AV overhead during multi-GB robocopy transfer
    'SOK-Backup'                = @('SOK-Inventory', '?SOK-Archiver', '?SOK-DefenderOptimizer')
    # BackupRestructure: Inventory required (derivation mapping); DefenderOptimizer for 7z extraction
    # (AV scans each extracted binary — critical for large archive sets)
    'SOK-BackupRestructure'     = @('SOK-Inventory', '?SOK-DefenderOptimizer')
    'SOK-Comparator'            = @()
    'SOK-PreSwap'               = @('SOK-Offload', 'SOK-Inventory')
    'SOK-RebootClean'           = @()
    'SOK-Restructure'           = @('SOK-Inventory')
    'SOK-DriveViability'        = @()
    # ── Utility scripts ────────────────────────────────────────────────────────
    # Install-GitHubRelease: Inventory optional — ScanInventory mode uses Inventory JSON for
    # installed package list; basic install mode has no prereqs
    'Install-GitHubRelease'     = @('?SOK-Inventory')
    # Export-SoftwareManifest: DefenderOptimizer optional — winget/choco queries faster with AV throttled
    'Export-SoftwareManifest'   = @('?SOK-DefenderOptimizer')
    # SOK-Vectorize: InfraFix optional — file walk traverses E: via junctions; broken junctions
    # cause silent path failures during project directory traversal
    'SOK-Vectorize'             = @('?SOK-InfraFix')
    'SOK-ProjectsReorg'         = @()
    'SOK-Reinstall'             = @()
    # ── Temporal meta-scripts ──────────────────────────────────────────────────
    'SOK-PAST'                  = @()
    'SOK-PRESENT'               = @('?SOK-PAST')
    'SOK-FUTURE'                = @('SOK-PAST', '?SOK-PRESENT')
    # METICUL.OS: convenience wrapper for sequencing all three temporal scripts interactively
    'SOK-METICUL.OS'            = @()
}

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════
function Get-SOKConfig {
    [CmdletBinding()]
    param([string]$ConfigPath = $script:ConfigPath)
    $defaults = @{
        LogBase               = $script:DefaultLogBase
        MaxLogAgeDays         = $script:DEFAULT_MAX_LOG_AGE_DAYS
        MemoryThresholdMB     = 2048
        CPUThresholdPercent   = 83.33
        # ProtectedProcesses: NEVER killed by any SOK module (PRESENT, Cleanup, PreSwap).
        # This list is the authoritative kill-exclusion set for all of SOK.
        # Add SKIP_CLAUDE guard check at each kill site — belt + suspenders.
        ProtectedProcesses    = @(
            # Windows kernel + session
            'explorer', 'svchost', 'csrss', 'wininit', 'winlogon', 'lsass',
            'services', 'smss', 'dwm', 'taskhostw', 'RuntimeBroker',
            'SecurityHealthService', 'SearchHost', 'fontdrvhost', 'logonui',
            # Security
            'MsMpEng', 'NisSrv', 'WmiPrvSE',
            # Developer tools (operator is actively using these)
            'Code', 'pwsh', 'powershell', 'WindowsTerminal', 'conhost',
            # Operator-specific critical apps
            'claude',           # SKIP_CLAUDE — never kill the AI session
            'Spotify',          # Music during work sessions
            'olk', 'OUTLOOK',   # Email (Outlook New + Classic)
            'OneDrive',         # Cloud sync — killing mid-sync corrupts files
            'GoogleDriveFS',    # Same rationale as OneDrive
            'Microsoft.AAD.BrokerPlugin',  # Azure AD auth — kills SSO on kill
            # Databases — protected even in Aggressive mode
            'neo4j', 'mongod', 'mysqld', 'postgres', 'redis-server', 'memurai-server',
            # Infrastructure
            'tailscaled', 'docker', 'dockerd',
            # Audio pipeline — killing audiodg causes audio dropout until reboot
            'audiodg', 'WavesSysSvc64', 'WavesSvc64'
        )
        AggressionMode        = 'Balanced'
        EnabledManagers       = @('chocolatey', 'scoop', 'winget', 'pip', 'npm',
                                   'cargo', 'dotnet', 'pipx', 'go', 'powershell')
        DisabledManagers      = @('wsl')
        PackageTimeoutSeconds = $script:DEFAULT_TIMEOUT_SEC
        StaleHours            = $script:DEFAULT_STALE_HOURS
        SkipWindowsUpdate     = $false
        SkipCleanmgr          = $true
    }
    # CRIT-1 FIX (2026-04-18): Get-SOKConfig is called BEFORE Initialize-SOKLog in
    # most tactical scripts, so $script:CurrentLogPath is $null and Write-SOKLog
    # silently drops config-load diagnostics. Guard with log-path check; fall back
    # to Write-Verbose (not silently swallowed) when log isn't initialized yet.
    if (Test-Path $ConfigPath) {
        try {
            $userConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            foreach ($prop in $userConfig.PSObject.Properties) {
                if ($prop.Name -notmatch '^_') { $defaults[$prop.Name] = $prop.Value }
            }
            if ($script:CurrentLogPath) { Write-SOKLog "Config loaded: $ConfigPath" -Level Ignore }
            else                         { Write-Verbose "Config loaded: $ConfigPath" }
        }
        catch {
            if ($script:CurrentLogPath) { Write-SOKLog "Config parse failed ($ConfigPath) — using defaults: $_" -Level Warn }
            else                         { Write-Verbose "Config parse failed ($ConfigPath) — using defaults: $_" }
        }
    }
    else {
        if ($script:CurrentLogPath) { Write-SOKLog "No config file at $ConfigPath — using defaults" -Level Ignore }
        else                         { Write-Verbose "No config file at $ConfigPath — using defaults" }
    }
    return $defaults
}

# ═══════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════
$script:CurrentLogPath = $null
$script:CurrentLogDir  = $null

function Get-ScriptLogDir {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ScriptName)
    $cleanName = $ScriptName -replace '^SOK-', ''
    $logDir    = Join-Path $script:DefaultLogBase $cleanName
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    return $logDir
}

function Initialize-SOKLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ScriptName)
    $logDir = Get-ScriptLogDir -ScriptName $ScriptName
    $script:CurrentLogDir  = $logDir
    $ts = Get-Date -Format $script:DateFile
    $script:CurrentLogPath = Join-Path $logDir "${ScriptName}_${ts}.log"
    $header = @"
════════════════════════════════════════════════════════════
  $script:SOKName v$script:SOKVersion — $ScriptName
  Started: $(Get-Date -Format $script:DateDisplay)
  Host: $env:COMPUTERNAME | User: $env:USERNAME
  PowerShell: $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))
  PID: $PID
════════════════════════════════════════════════════════════

"@
    Set-Content -Path $script:CurrentLogPath -Value $header -Force
    return $script:CurrentLogPath
}

function Write-SOKLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        # v4.6.1: 'Info' added as a first-class level (maps to Cyan). 189 call sites
        # across PAST-v2/PAST-Verbose/PAST-BlankSlate use -Level 'INFO'; prior ValidateSet
        # rejected them all with a FATAL. ValidateSet is case-insensitive so 'INFO' matches.
        [ValidateSet('Info', 'Ignore', 'Annotate', 'Warn', 'Error', 'Success', 'Debug', 'Section')]
        [string]$Level = 'Ignore'
    )
    if ($Level -eq 'Section') {
        Write-Host "`n━━━ $Message ━━━" -ForegroundColor Magenta
        $entry = "[$(Get-Date -Format $script:DateISO)] [SECTION ] $Message"
    }
    else {
        $entry = "[$(Get-Date -Format $script:DateISO)] [$($Level.ToUpper().PadRight(8))] $Message"
        switch ($Level) {
            'Info'     { Write-Host $entry -ForegroundColor Cyan }
            'Ignore'   { Write-Host $entry -ForegroundColor Cyan }
            'Annotate' { Write-Host $entry -ForegroundColor DarkCyan }
            'Warn'     { Write-Host $entry -ForegroundColor Yellow }
            'Error'    { Write-Host $entry -ForegroundColor Red }
            'Success'  { Write-Host $entry -ForegroundColor Green }
            'Debug'    { Write-Host $entry -ForegroundColor DarkGray }
        }
    }
    if ($script:CurrentLogPath) {
        $logDir = Split-Path $script:CurrentLogPath -Parent
        if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null }
        Add-Content -Path $script:CurrentLogPath -Value $entry -ErrorAction Continue
    }
}

function Write-SOKSummary {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Stats, [string]$Title = 'OPERATION SUMMARY')
    $border = [string]::new([char]0x2550, 55)
    Write-Host "`n$border" -ForegroundColor Magenta
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host $border -ForegroundColor Magenta
    foreach ($key in $Stats.Keys | Sort-Object) {
        Write-Host "  $($key.PadRight(34)) $($Stats[$key])" -ForegroundColor Cyan
    }
    Write-Host "$border`n" -ForegroundColor Magenta
    if ($script:CurrentLogPath) {
        Add-Content -Path $script:CurrentLogPath -Value "`n$border"
        Add-Content -Path $script:CurrentLogPath -Value "  $Title"
        foreach ($key in $Stats.Keys | Sort-Object) {
            Add-Content -Path $script:CurrentLogPath -Value "  $($key.PadRight(34)) $($Stats[$key])"
        }
        Add-Content -Path $script:CurrentLogPath -Value $border
    }
}

# Write-SOKDivider: lightweight section separator without the Section log level overhead.
# Use for sub-sections within a module to improve scan readability without inflating
# the Section count in the log index.
function Write-SOKDivider {
    param([string]$Label = '')
    $line = if ($Label) { "── $Label $(([string]::new([char]0x2500, [math]::Max(3, 55 - $Label.Length - 4))))" }
             else       { [string]::new([char]0x2500, 55) }
    Write-Host "  $line" -ForegroundColor DarkGray
    if ($script:CurrentLogPath) { Add-Content -Path $script:CurrentLogPath -Value "  $line" }
}

# ═══════════════════════════════════════════════════════════════
# AGE FORMATTING
# ═══════════════════════════════════════════════════════════════
function Format-SOKAge {
    [CmdletBinding()]
    param([Parameter(Mandatory)][TimeSpan]$Age)
    $h = [math]::Floor($Age.TotalHours)
    return "$($h.ToString().PadLeft(2,'0')):$($Age.ToString('mm\:ss'))"
}

# ═══════════════════════════════════════════════════════════════
# HISTORY
# ═══════════════════════════════════════════════════════════════
function Save-SOKHistory {
    [CmdletBinding()]
    param(
        [string]$ScriptName,
        [hashtable]$RunData,
        # AggregateOnly: write to the rolling _history.json only, not a per-run file.
        # Use for high-frequency scripts (LiveScan, Maintenance) to avoid log sprawl.
        [switch]$AggregateOnly
    )
    $histDir  = Get-ScriptLogDir -ScriptName $ScriptName
    $timestamp = Get-Date -Format $script:DateFile

    # v4.4.0: store the full RunData hashtable under Results so all caller-supplied
    # keys (Mode, Killed, Offloaded, etc.) are preserved in history.
    # Duration is surfaced separately for quick age queries.
    $entry = [ordered]@{
        Script    = $ScriptName
        Timestamp = Get-Date -Format $script:DateISO
        Duration  = if ($RunData.Duration) { $RunData.Duration }
                    elseif ($RunData.DurationSec) { $RunData.DurationSec }
                    else { 0 }
        Results   = $RunData
    }

    if (-not $AggregateOnly) {
        $filePath = Join-Path $histDir "${ScriptName}_${timestamp}.json"
        $entry | ConvertTo-Json -Depth 8 | Set-Content -Path $filePath -Force -Encoding UTF8
    }

    # Rolling aggregate (ring buffer, capped at $HISTORY_CAP entries)
    $aggPath  = Join-Path $histDir "${ScriptName}_history.json"
    $aggLock  = "$aggPath.lock"
    $lockStart = Get-Date
    while (Test-Path $aggLock) {
        if (((Get-Date) - $lockStart).TotalSeconds -gt $script:LOCK_TIMEOUT_SEC) {
            Remove-Item $aggLock -Force -ErrorAction Continue; break
        }
        Start-Sleep -Milliseconds $script:LOCK_POLL_MS
    }
    Set-Content -Path $aggLock -Value $PID -Force
    try {
        # v4.6.1: $history built as explicit List[object] to sidestep the PowerShell
        # "$var = if (...) { @(single) }" gotcha where 1-element arrays get unwrapped
        # back to their scalar during assignment, yielding a PSCustomObject with no
        # op_Addition method — which exploded $history += $entry on every caller that
        # had a prior single-entry history file (PAST-v2, PAST-Verbose, tacticals).
        $history = [System.Collections.Generic.List[object]]::new()
        if (Test-Path $aggPath) {
            try {
                $raw = Get-Content $aggPath -Raw -ErrorAction Continue
                if ($raw -and $raw.Trim().Length -gt 2) {
                    $parsed = $raw | ConvertFrom-Json -ErrorAction Continue
                    if ($parsed -is [array]) {
                        foreach ($p in $parsed) { [void]$history.Add($p) }
                    } else {
                        [void]$history.Add($parsed)
                    }
                }
            }
            catch {
                Copy-Item $aggPath "$aggPath.corrupted_$(Get-Date -Format $script:DateFile)" -Force -ErrorAction Continue
                $history = [System.Collections.Generic.List[object]]::new()
            }
        }
        [void]$history.Add($entry)
        # v4.6.1: ring-buffer trim rewritten for List[object]; negative-range indexing
        # on generic List doesn't give the same slice semantics as [object[]].
        if ($history.Count -gt $script:HISTORY_CAP) {
            $trimmed = [System.Collections.Generic.List[object]]::new()
            for ($i = $history.Count - $script:HISTORY_CAP; $i -lt $history.Count; $i++) {
                [void]$trimmed.Add($history[$i])
            }
            $history = $trimmed
        }
        if (Test-Path $aggPath) { Copy-Item $aggPath "$aggPath.bak" -Force -ErrorAction Continue }
        # v4.6.1: -AsArray forces consistent JSON-array output even for Count=1.
        # Prior behavior emitted a bare object for single-entry histories, which is
        # what made the read path fragile to begin with.
        $history.ToArray() | ConvertTo-Json -Depth 8 -AsArray | Set-Content -Path $aggPath -Force -Encoding UTF8
    }
    finally { Remove-Item $aggLock -Force -ErrorAction Continue }

    if (-not $AggregateOnly) { Write-SOKLog "History: $filePath" -Level Ignore }
}

# ═══════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════
function Show-SOKBanner {
    # v4.6.1: -Title added as an alias for -ScriptName. Many tactical scripts have
    # local-fallback Show-SOKBanner definitions with a -Title parameter, and PAST-v2
    # calls it as `Show-SOKBanner -Title "..."`. Aliasing keeps both call shapes
    # valid without touching 30+ call sites.
    [CmdletBinding()]
    param(
        [Alias('Title')]
        [string]$ScriptName = 'SOK',
        [string]$Subheader = ''
    )
    $banner = @"

    ╔═══════════════════════════════════════════════╗
    ║     ███████╗ ██████╗ ██╗  ██╗               ║
    ║     ██╔════╝██╔═══██╗██║ ██╔╝               ║
    ║     ███████╗██║   ██║█████╔╝                ║
    ║     ╚════██║██║   ██║██╔═██╗                ║
    ║     ███████║╚██████╔╝██║  ██╗               ║
    ║     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝  v$($script:SOKVersion)     ║
    ║                                               ║
    ║     Son of Klem -- System Operations Kit      ║
    ╚═══════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "  Script:   $ScriptName" -ForegroundColor Gray
    Write-Host "  Host:     $env:COMPUTERNAME | User: $env:USERNAME" -ForegroundColor Gray
    Write-Host "  Time:     $(Get-Date -Format $script:DateDisplay)" -ForegroundColor Gray
    Write-Host "  PS:       $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" -ForegroundColor Gray
    if ($Subheader) { Write-Host "  Context:  $Subheader" -ForegroundColor Gray }
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════
function Test-IsAdmin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SizeKB { param([long]$Bytes); return [math]::Round($Bytes / 1KB, 2) }

function Get-HumanSize {
    # DEPRECATED: use Get-SizeKB or format inline. Kept for backward compatibility.
    param([long]$Bytes)
    return "$([math]::Round($Bytes / 1KB, 2)) KB"
}

# New-SOKStateDict: creates the ConcurrentDictionary used for in-memory pipeline
# handoff between modules within a single SOK-PAST/PRESENT/FUTURE invocation.
# Using a single factory function ensures all three temporal scripts create
# compatible state objects and makes the type explicit in code review.
function New-SOKStateDict {
    return [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
}

# ═══════════════════════════════════════════════════════════════
# TIMEOUT EXECUTION
# ═══════════════════════════════════════════════════════════════
function Invoke-WithTimeout {
    # v4.4.0 rewrite: uses Start-ThreadJob (PS7.2+ built-in) instead of Start-Job.
    # Start-Job creates a new process that does NOT inherit the parent's PATH —
    # choco, scoop, winget, and other user-PATH tools are not found inside Start-Job
    # blocks. Start-ThreadJob runs on a thread in the same process, inheriting all
    # environment variables including PATH. This was the root cause of all package
    # manager update failures in Maintenance when invoked via Invoke-WithTimeout.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [int]$TimeoutSeconds  = $script:DEFAULT_TIMEOUT_SEC,
        [string]$Description  = 'Operation'
    )

    # Ensure ThreadJob module is loaded (bundled in PS7.2+; installable in PS7.0/7.1)
    if (-not (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue)) {
        Import-Module ThreadJob -ErrorAction SilentlyContinue
        if (-not (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue)) {
            # Hard fallback to Start-Job with manual PATH injection
            Write-SOKLog "ThreadJob not available — falling back to Start-Job with PATH injection." -Level Warn
            $jobPath = $env:PATH
            $job = Start-Job -ScriptBlock {
                $env:PATH = $using:jobPath
                & $using:ScriptBlock
            }
            $completed = $job | Wait-Job -Timeout $TimeoutSeconds
            if ($null -eq $completed) {
                $job | Stop-Job; $job | Remove-Job -Force
                Write-SOKLog "$Description timed out after ${TimeoutSeconds}s" -Level Warn
                return @{ Success = $false; Error = "Timeout after ${TimeoutSeconds}s"; Output = $null }
            }
            $output  = $job | Receive-Job 2>&1
            $failed  = $job.State -eq 'Failed'
            $job | Remove-Job -Force
            return @{ Success = (-not $failed); Error = if ($failed) { "Job failed" } else { $null }; Output = $output }
        }
    }

    $job = Start-ThreadJob -ScriptBlock $ScriptBlock
    $completed = $job | Wait-Job -Timeout $TimeoutSeconds
    if ($null -eq $completed) {
        $job | Stop-Job; $job | Remove-Job -Force
        Write-SOKLog "$Description timed out after ${TimeoutSeconds}s" -Level Warn
        return @{ Success = $false; Error = "Timeout after ${TimeoutSeconds}s"; Output = $null }
    }
    $output = $job | Receive-Job 2>&1
    $failed = $job.State -eq 'Failed'
    $job | Remove-Job -Force
    return @{ Success = (-not $failed); Error = if ($failed) { "Job failed: $($job.JobStateInfo.Reason)" } else { $null }; Output = $output }
}

# ═══════════════════════════════════════════════════════════════
# DEPRECATED FILE MANAGEMENT
# ═══════════════════════════════════════════════════════════════
function Move-ToDeprecated {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FilePath)
    if (-not (Test-Path $FilePath)) { return }
    $parentDir     = Split-Path $FilePath -Parent
    $deprecatedDir = Join-Path $parentDir 'deprecated'
    if (-not (Test-Path $deprecatedDir)) { New-Item -Path $deprecatedDir -ItemType Directory -Force | Out-Null }
    $fileName = Split-Path $FilePath -Leaf
    $destPath = Join-Path $deprecatedDir $fileName
    if (Test-Path $destPath) {
        $ts       = Get-Date -Format $script:DateFile
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        $ext      = [System.IO.Path]::GetExtension($fileName)
        $destPath = Join-Path $deprecatedDir "${baseName}_${ts}${ext}"
    }
    Move-Item -Path $FilePath -Destination $destPath -Force -ErrorAction Continue
    Write-SOKLog "Deprecated: $fileName" -Level Debug
}

function Remove-StaleLogFiles {
    [CmdletBinding()]
    param(
        [string]$LogDirectory = $script:DefaultLogBase,
        [int]$MaxAgeDays      = $script:DEFAULT_MAX_LOG_AGE_DAYS
    )
    if (-not (Test-Path $LogDirectory)) { return }
    $cutoff = (Get-Date).AddDays(-$MaxAgeDays)
    $stale  = Get-ChildItem -Path $LogDirectory -File -Recurse -ErrorAction Continue |
        Where-Object {
            $_.LastWriteTime -lt $cutoff -and
            $_.Name -notmatch '_history\.json$' -and
            $_.Name -notmatch '\.lock$'
        }
    if ($stale.Count -gt 0) {
        foreach ($file in $stale) { Move-ToDeprecated -FilePath $file.FullName }
        Write-SOKLog "Deprecated $($stale.Count) stale files (older than ${MaxAgeDays}d)" -Level Ignore
    }
}

# ═══════════════════════════════════════════════════════════════
# PREREQUISITE SYSTEM
# ═══════════════════════════════════════════════════════════════
function Get-LatestLog {
    # Returns a PSCustomObject: { Path, Name, Age, Data }
    # Callers that need only the path should use Get-LatestLogPath (see below).
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ScriptName, [string]$Filter = '*.json')
    $logDir = Get-ScriptLogDir -ScriptName $ScriptName
    if (-not (Test-Path $logDir)) { return $null }
    $latest = Get-ChildItem -Path $logDir -Filter $Filter -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -notmatch '_history\.json$' -and
            $_.Name -notmatch '\.lock$' -and
            $_.Name -notmatch '\.bak$' -and
            $_.Name -notmatch '\.corrupted_'
        } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { return $null }
    $age  = (Get-Date) - $latest.LastWriteTime
    $data = $null
    try { $data = Get-Content $latest.FullName -Raw -ErrorAction Continue | ConvertFrom-Json -ErrorAction Continue }
    catch { Write-SOKLog "Failed to parse $($latest.Name): $_" -Level Warn }
    return [PSCustomObject]@{ Path = $latest.FullName; Name = $latest.Name; Age = $age; Data = $data }
}

function Get-LatestLogPath {
    # Convenience wrapper: returns ONLY the file path string (or $null).
    # Use this instead of (Get-LatestLog ...).Path when you only need the path —
    # it prevents the PSCustomObject → Test-Path casting bugs that caused
    # FUTURE Offload and PRESENT LiveDigest to silently skip context loading.
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ScriptName, [string]$Filter = '*.json')
    $result = Get-LatestLog -ScriptName $ScriptName -Filter $Filter
    if ($result) { return $result.Path }
    return $null
}

function Invoke-SOKPrerequisite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CallingScript,
        [int]$StaleHours   = $script:DEFAULT_STALE_HOURS,
        [int]$NestingDepth = 0
    )
    if ($NestingDepth -ge $script:PREREQUISITE_NESTING_LIMIT) {
        Write-SOKLog "Prerequisite nesting limit ($script:PREREQUISITE_NESTING_LIMIT) reached — skipping" -Level Annotate
        return
    }
    $prereqs = $script:PrerequisiteMap[$CallingScript]
    if (-not $prereqs -or $prereqs.Count -eq 0) { return }

    foreach ($raw in $prereqs) {
        $optional   = $false
        $prereqName = $raw
        if ($raw.StartsWith('?')) { $optional = $true; $prereqName = $raw.Substring(1) }

        $latest = Get-LatestLog -ScriptName $prereqName
        $fresh  = $false
        if ($latest -and $latest.Age.TotalHours -lt $StaleHours) {
            Write-SOKLog "Prerequisite ${prereqName}: fresh ($(Format-SOKAge -Age $latest.Age) old)" -Level Success
            $fresh = $true
        }
        if (-not $fresh) {
            $ageStr = if ($latest) { "$(Format-SOKAge -Age $latest.Age) old" } else { "no log found" }
            if ($optional) {
                Write-SOKLog "Optional prerequisite ${prereqName}: stale ($ageStr) — skipping" -Level Annotate
                continue
            }
            Write-SOKLog "Prerequisite ${prereqName}: STALE ($ageStr) — triggering..." -Level Warn
            $scriptPath = Join-Path $script:ScriptBase "${prereqName}.ps1"
            if (-not (Test-Path $scriptPath)) {
                Write-SOKLog "Cannot find: $scriptPath" -Level Error; continue
            }
            try {
                $env:SOK_NESTED = '1'
                $env:SOK_NESTING_DEPTH = $NestingDepth + 1
                Write-SOKLog "Executing: $scriptPath (depth $($NestingDepth + 1))" -Level Annotate
                & $scriptPath
                Write-SOKLog "Prerequisite $prereqName completed" -Level Success
            }
            catch { Write-SOKLog "Prerequisite $prereqName FAILED: $_" -Level Error }
            finally {
                if ($NestingDepth -eq 0) {
                    Remove-Item Env:\SOK_NESTED        -ErrorAction SilentlyContinue
                    Remove-Item Env:\SOK_NESTING_DEPTH -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# EXPORTS
# ═══════════════════════════════════════════════════════════════
Export-ModuleMember -Function @(
    'Get-SOKConfig'; 'Save-SOKHistory'; 'Initialize-SOKLog'; 'Write-SOKLog'; 'Write-SOKSummary'
    'Write-SOKDivider'; 'Show-SOKBanner'; 'Test-IsAdmin'; 'Get-SizeKB'; 'Get-HumanSize'
    'Format-SOKAge'; 'New-SOKStateDict'; 'Invoke-WithTimeout'
    'Remove-StaleLogFiles'; 'Move-ToDeprecated'
    'Get-LatestLog'; 'Get-LatestLogPath'; 'Get-ScriptLogDir'; 'Invoke-SOKPrerequisite'
)
Export-ModuleMember -Variable @(
    'SOKVersion'; 'SOKName'; 'ProjectRoot'; 'ScriptBase'; 'SOKRoot'
    'DefaultLogBase'; 'ConfigPath'; 'RunSequence'; 'TemporalRunSequence'; 'PrerequisiteMap'
    'MAX_UTILIZATION_PCT'; 'DEFAULT_STALE_HOURS'; 'DEFAULT_TIMEOUT_SEC'
    'PREREQUISITE_NESTING_LIMIT'; 'HISTORY_CAP'; 'DEFAULT_MAX_LOG_AGE_DAYS'; 'SKIP_CLAUDE'
)
