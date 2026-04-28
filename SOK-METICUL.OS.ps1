#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-METICUL.OS v2.0.0 — True Monolith
    ALL temporal domains inlined. One process, one $GlobalState, zero JSON handoffs.

.DESCRIPTION
    METICUL.OS v2.0.0 is the empirical monolith experiment: every module from
    SOK-PAST, SOK-PRESENT, and SOK-FUTURE is fully inlined here, operating on
    a single $GlobalState dictionary with no intermediate process boundaries.

    18 MODULES IN EXECUTION ORDER (3 temporal domains):
    ──────────────────────────────────────────────────
    DOMAIN 1: PAST — Historical State, Debt Reconciliation
      [1]  InfraFix           — One-shot environmental repairs
      [2]  Inventory          — Full system snapshot to JSON + GlobalState
      [3]  SpaceAudit         — Parallel disk classification (KEEP/CLEAN/OFFLOAD)
      [4]  Restructure        — Structural debt analysis
      [5]  CompareSnapshots   — Archive diff with symbolic grammar
      [6]  BackupRestructure  — Extract + merge E:\Backup_Archive

    DOMAIN 2: PRESENT — Live Machine State, Performance
      [7]  DefenderOptimizer  — Throttle AV to 20% CPU cap + dev exclusions
      [8]  ProcessOptimizer   — Property-based background process kill
      [9]  ServiceOptimizer   — Stop idle databases and services
      [10] Maintenance        — Package updates, cache cleanup, TRIM, DNS
      [11] Cleanup            — Kill lock holders + deep cache eviction
      [12] PreSwap            — Pre-drive-swap junction repair (explicit only)
      [13] RebootClean        — Post-reboot junction verification (explicit only)
      [14] LiveScan           — Streaming filesystem inventory (explicit only)
      [15] LiveDigest         — Summarize LiveScan results (explicit only)

    DOMAIN 3: FUTURE — Proactive Protection, Data Continuity
      [16] Offload            — Move heavy toolchains to E: + NTFS junctions
      [17] Backup             — Robocopy mirror to E:\Backup_Archive
      [18] Archive            — Source code snapshot to versioned .txt

    MONOLITH OPTIMIZATION: GLOBALSTATE FLOWS
    ─────────────────────────────────────────
    In the distributed model, PAST→FUTURE handoffs require reading JSON from disk
    (Get-LatestLogPath). Here, all data lives in $GlobalState:

      Inventory_DriveTopology  → Offload (no drive re-query)
      Inventory_JunctionMap    → Offload (no inventory JSON read), Maintenance
      Inventory_ChocoPackages  → Maintenance (package list available immediately)
      Inventory_WingetPackages → Maintenance
      Inventory_RunningServices→ ServiceOptimizer
      SpaceAudit_Offloadable   → Offload (23-target list extended by classification)
      LiveScan_OutputPath      → LiveDigest (same as distributed)

    ARCHITECTURAL CONCLUSION (written after empirical trial):
    ─────────────────────────────────────────────────────────
    [See SOK-FamilyPicture.ps1 for the definitive write-up]
    This script exists to make the comparison honest, not to replace the
    distributed model. See the finally block for per-run conclusions.

    DEFAULT RUN BEHAVIOR (Full Disclosure):
    Core PAST  : InfraFix, Inventory, SpaceAudit, Restructure, BackupRestructure
    Core PRESENT: DefenderOptimizer, ProcessOptimizer, ServiceOptimizer, Maintenance, Cleanup
    Core FUTURE : Offload, Backup, Archive
    Always-explicit: CompareSnapshots, PreSwap, RebootClean, LiveScan, LiveDigest

    Use -Skip* flags to narrow. Use -SkipPast / -SkipPresent / -SkipFuture to exclude
    entire temporal domains. -All forces everything regardless of -Skip*.

.EXAMPLE
    .\SOK-METICUL.OS.ps1 -DryRun
    Preview all 18 modules with zero disk mutations.

.EXAMPLE
    .\SOK-METICUL.OS.ps1 -SkipPresent -SkipFuture -TakeInventory -AuditSpace
    Run only PAST Inventory + SpaceAudit (targeted, like calling SOK-PAST directly).

.EXAMPLE
    .\SOK-METICUL.OS.ps1 -SkipPast -OptimizeDefender -OptimizeProcesses -Clean
    Run only PRESENT DefenderOptimizer + ProcessOptimizer + Cleanup.

.EXAMPLE
    .\SOK-METICUL.OS.ps1 -SkipPast -SkipPresent -Backup -Incremental
    Run only FUTURE Backup (incremental mirror).

.NOTES
    Author:  S. Clay Caddell
    Version: 2.0.0
    Date:    2026-04-03
    Domain:  Meta — Empirical monolith for architectural comparison
    Runtime: ~15-30 min full run (all 18 modules, non-DryRun)
    Basis:   SOK-PAST v1.1.1 + SOK-PRESENT v1.1.0 + SOK-FUTURE v1.1.0

    MAINTENANCE NOTE:
    This script is a derived copy. When individual tactical scripts or meta-scripts
    are updated, sync changes here. Tracked divergence is expected — this is a
    comparison artifact, not the production script.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # ── GLOBAL ─────────────────────────────────────────────────────────────────
    [switch]$DryRun,

    # ── DOMAIN-LEVEL SKIP (monolith ergonomics) ───────────────────────────────
    [switch]$SkipPast,     # Exclude all PAST modules from run
    [switch]$SkipPresent,  # Exclude all PRESENT modules from run
    [switch]$SkipFuture,   # Exclude all FUTURE modules from run

    # ── CROSS-DOMAIN FLAGS ─────────────────────────────────────────────────────
    # -All forces all modules regardless of -Skip* flags.
    # -Optimize: shortcut for -OptimizeDefender -OptimizeProcesses -OptimizeServices
    [switch]$All,
    [switch]$Optimize,

    # ═══════════════════════════════════════════════════════════════════════════
    # DOMAIN 1: PAST MODULE FLAGS
    # ═══════════════════════════════════════════════════════════════════════════
    # Opt-in (backward compat)
    [switch]$FixInfra,
    [switch]$TakeInventory,
    [switch]$AuditSpace,
    [switch]$FixStructure,
    [switch]$CompareSnapshots,   # Always explicit — requires -OldSnapshot/-NewSnapshot
    [switch]$RestructureBackups,
    # Progressive enclosure skip
    [switch]$SkipInfraFix,
    [switch]$SkipInventory,
    [switch]$SkipSpaceAudit,
    [switch]$SkipRestructure,
    [switch]$SkipBackupRestructure,

    # PAST: Inventory params
    [ValidateRange(1, 3)]
    [int]$ScanCaliber = 2,
    [string]$InventoryOutputPath,

    # PAST: SpaceAudit params
    [int]$MinSizeKB     = 21138,
    [int]$ScanDepth     = 21,
    [int]$ThrottleLimit = 13,

    # PAST: Comparator params
    [string]$OldSnapshot,
    [string]$NewSnapshot,
    [double]$AutoApproveThreshold = 16.66,
    [string]$ComparatorOutputDir  = "$env:USERPROFILE\Documents\Journal\Projects\SOK\Archives",

    # PAST: Restructure params
    [string[]]$RestructureTargets = @(
        "$env:USERPROFILE\Documents\Backup",
        "$env:USERPROFILE\Downloads"
    ),
    [int]$MaxDepth = 13,
    [ValidateSet('Report', 'Flatten')]
    [string]$RestructureAction = 'Report',

    # PAST: BackupRestructure params
    [string]$ArchiveRoot  = 'E:\Backup_Archive',
    [string]$MergeTarget  = 'E:\Backup_Merged',
    [switch]$RunPhase1,
    [switch]$SkipExtraction,
    [switch]$SkipMerge,

    # ═══════════════════════════════════════════════════════════════════════════
    # DOMAIN 2: PRESENT MODULE FLAGS
    # ═══════════════════════════════════════════════════════════════════════════
    # Opt-in (backward compat)
    [switch]$OptimizeDefender,
    [switch]$OptimizeProcesses,
    [switch]$OptimizeServices,
    [switch]$Maintain,
    [switch]$Clean,
    [switch]$PreSwap,     # Always explicit (destructive/interactive)
    [switch]$RebootClean, # Always explicit (post-reboot only)
    [switch]$LiveScan,    # Always explicit (slow/disk-heavy)
    [switch]$LiveDigest,  # Always explicit (requires LiveScan)
    # Progressive enclosure skip
    [switch]$SkipDefender,
    [switch]$SkipProcesses,
    [switch]$SkipServices,
    [switch]$SkipMaintain,
    [switch]$SkipClean,

    # PRESENT: ProcessOptimizer params
    [ValidateSet('Conservative', 'Balanced', 'Aggressive')]
    [string]$ProcessMode = 'Balanced',

    # PRESENT: ServiceOptimizer params
    [ValidateSet('Auto', 'Interactive', 'Report')]
    [string]$ServiceAction = 'Report',

    # PRESENT: Maintenance params
    [ValidateSet('Quick', 'Standard', 'Deep', 'Thorough')]
    [string]$MaintMode = 'Standard',
    [int]$PackageTimeoutSec = 360,

    # PRESENT: LiveScan params
    [string]$LiveScanSource       = 'C:\',
    [switch]$LiveScanDirsOnly,
    [switch]$LiveScanExcludeNoisy,

    # PRESENT: LiveDigest params
    [int]$DigestTopN       = 50,
    [string]$DigestInputPath,

    # ═══════════════════════════════════════════════════════════════════════════
    # DOMAIN 3: FUTURE MODULE FLAGS
    # ═══════════════════════════════════════════════════════════════════════════
    # Opt-in (backward compat)
    [switch]$Offload,
    [switch]$Backup,
    [switch]$Archive,
    # Progressive enclosure skip
    [switch]$SkipOffload,
    [switch]$SkipBackup,
    [switch]$SkipArchive,

    # FUTURE: Offload params
    [string]$ExternalDrive   = 'E:',
    [string]$InventoryPath,
    [int]$MinOffloadKB       = 21138,
    [int]$MaxDriveUtilPct    = 96,

    # FUTURE: Backup params
    [string[]]$BackupSources = @("$env:USERPROFILE\Documents\Journal\Projects"),
    [string]$BackupDest      = 'E:\Backup_Archive',
    [switch]$Incremental,
    [int]$Threads            = 13,

    # FUTURE: Archive params
    [string[]]$ArchiveSources = @(
        "$env:USERPROFILE\Documents\Journal\Projects\SOK",
        "$env:USERPROFILE\Documents\Journal\Projects\scripts"
    ),
    [string]$ArchiveBaseName   = 'SOK_Archive',
    [string]$ArchiveOutputDir  = "$env:USERPROFILE\Documents\Journal\Projects\SOK\Archives",
    [string]$ArchiveExtensions = '(?i)\.(txt|md|ps1|psm1|psd1|py|json|log|yaml|yml|xml|conf|ini|sh|bat|css|js|jsx|ts|tsx|sql|toml|cfg|r|go|rs)$'
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
    Write-Error "CRITICAL: SOK-Common.psm1 not found at $modulePath"
    exit 1
}

$logPath = Initialize-SOKLog -ScriptName 'SOK-METICUL.OS'
$config  = Get-SOKConfig

# ── Resolve -Optimize shortcut ────────────────────────────────────────────────
if ($Optimize) { $OptimizeDefender = $OptimizeProcesses = $OptimizeServices = $true }

# ── Full Disclosure / Progressive Enclosure gate ─────────────────────────────
# Determine if any explicit opt-in flag was set across all three domains.
$anyOptIn = $FixInfra.IsPresent -or $TakeInventory.IsPresent -or $AuditSpace.IsPresent -or
            $FixStructure.IsPresent -or $CompareSnapshots.IsPresent -or $RestructureBackups.IsPresent -or
            $OptimizeDefender.IsPresent -or $OptimizeProcesses.IsPresent -or $OptimizeServices.IsPresent -or
            $Maintain.IsPresent -or $Clean.IsPresent -or $Optimize.IsPresent -or
            $Offload.IsPresent -or $Backup.IsPresent -or $Archive.IsPresent

if ($All) {
    # Force all modules across all domains
    $FixInfra = $TakeInventory = $AuditSpace = $FixStructure = $RestructureBackups = $true
    $OptimizeDefender = $OptimizeProcesses = $OptimizeServices = $Maintain = $Clean = $RebootClean = $true
    $Offload = $Backup = $Archive = $true
} elseif (-not $anyOptIn) {
    # No explicit opt-in — Full Disclosure: activate all core modules per domain
    if (-not $SkipPast) {
        if (-not $SkipInfraFix)          { $FixInfra            = $true }
        if (-not $SkipInventory)         { $TakeInventory        = $true }
        if (-not $SkipSpaceAudit)        { $AuditSpace           = $true }
        if (-not $SkipRestructure)       { $FixStructure         = $true }
        if (-not $SkipBackupRestructure) { $RestructureBackups   = $true }
        # CompareSnapshots always requires -OldSnapshot/-NewSnapshot — never auto-activated
    }
    if (-not $SkipPresent) {
        if (-not $SkipDefender)  { $OptimizeDefender  = $true }
        if (-not $SkipProcesses) { $OptimizeProcesses = $true }
        if (-not $SkipServices)  { $OptimizeServices  = $true }
        if (-not $SkipMaintain)  { $Maintain          = $true }
        if (-not $SkipClean)     { $Clean             = $true }
        # PreSwap/RebootClean/LiveScan/LiveDigest always require explicit opt-in
    }
    if (-not $SkipFuture) {
        if (-not $SkipOffload) { $Offload  = $true }
        if (-not $SkipBackup)  { $Backup   = $true }
        if (-not $SkipArchive) { $Archive  = $true }
    }
}

# ── Build ActiveModules list ──────────────────────────────────────────────────
$ActiveModules = [System.Collections.Generic.List[string]]::new()
if ($FixInfra)           { $ActiveModules.Add('[P] InfraFix') }
if ($TakeInventory)      { $ActiveModules.Add("[P] Inventory(C$ScanCaliber)") }
if ($AuditSpace)         { $ActiveModules.Add('[P] SpaceAudit') }
if ($FixStructure)       { $ActiveModules.Add('[P] Restructure') }
if ($CompareSnapshots)   { $ActiveModules.Add('[P] CompareSnapshots') }
if ($RestructureBackups) { $ActiveModules.Add('[P] BackupRestructure') }
if ($OptimizeDefender)   { $ActiveModules.Add('[N] DefenderOptimizer') }
if ($OptimizeProcesses)  { $ActiveModules.Add("[N] ProcessOptimizer($ProcessMode)") }
if ($OptimizeServices)   { $ActiveModules.Add("[N] ServiceOptimizer($ServiceAction)") }
if ($Maintain)           { $ActiveModules.Add("[N] Maintenance[$MaintMode]") }
if ($Clean)              { $ActiveModules.Add('[N] Cleanup') }
if ($PreSwap)            { $ActiveModules.Add('[N] PreSwap') }
if ($RebootClean)        { $ActiveModules.Add('[N] RebootClean') }
if ($LiveScan)           { $ActiveModules.Add('[N] LiveScan') }
if ($LiveDigest)         { $ActiveModules.Add('[N] LiveDigest') }
if ($Offload)            { $ActiveModules.Add('[F] Offload') }
if ($Backup)             { $ActiveModules.Add("[F] Backup[$(if($Incremental){'MIR'}else{'/E'})]") }
if ($Archive)            { $ActiveModules.Add('[F] Archive') }

if ($ActiveModules.Count -eq 0) {
    Write-SOKLog 'All modules skipped. Nothing to run.' -Level Warn
    exit 0
}

Show-SOKBanner -ScriptName 'SOK-METICUL.OS' `
    -Subheader "v2.0.0 — $(($ActiveModules | Select-Object -First 6) -join ' | ')$(if($ActiveModules.Count -gt 6){ " + $($ActiveModules.Count-6) more" })$(if ($DryRun) {' [DRY RUN]'})"

Write-SOKLog "MONOLITH RUN: $($ActiveModules.Count) modules across 3 temporal domains" -Level Section
Write-SOKLog "Domains active: $(if($FixInfra-or$TakeInventory-or$AuditSpace-or$FixStructure-or$CompareSnapshots-or$RestructureBackups){'PAST '})$(if($OptimizeDefender-or$OptimizeProcesses-or$OptimizeServices-or$Maintain-or$Clean-or$PreSwap-or$RebootClean-or$LiveScan-or$LiveDigest){'PRESENT '})$(if($Offload-or$Backup-or$Archive){'FUTURE'})" -Level Ignore

# ── Single GlobalState for all 18 modules ────────────────────────────────────
# This is the architectural crux of the monolith: one dictionary flows through
# every module in order. No JSON reads between PAST and FUTURE.
$GlobalState = New-SOKStateDict

# RAM baseline for PRESENT domain
$ramBefore = try { (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory } catch { 0 }

# Domain timing accumulators
$pastStart    = $null
$presentStart = $null
$futureStart  = $null

try {

# ══════════════════════════════════════════════════════════════════════════════
# ████ DOMAIN 1: PAST — Historical State, Debt Reconciliation ████
# ══════════════════════════════════════════════════════════════════════════════
if ($FixInfra -or $TakeInventory -or $AuditSpace -or $FixStructure -or $CompareSnapshots -or $RestructureBackups) {
    $pastStart = Get-Date
    Write-SOKLog '' -Level Ignore
    Write-SOKLog "████████ DOMAIN 1: PAST — Historical State & Debt Reconciliation ████████" -Level Section
    Write-SOKLog "Temporal Domain: Looking BACKWARD — what happened, and how do we reconcile it?" -Level Ignore
}

# ══════════════════════════════════════════════════════════════════════════════
# [1] INFRAFIX — One-Shot Environmental Repairs
# ══════════════════════════════════════════════════════════════════════════════
if ($FixInfra) {
    Write-SOKLog '━━━ [1] INFRAFIX: One-Shot Environmental Repairs ━━━' -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN — no changes will be made ***' -Level Warn }
    $infraFixed = 0; $infraSkipped = 0; $infraFailed = 0

    # ── FIX 1: nvm4w junction ────────────────────────────────────────────────
    $nvmDir    = 'C:\ProgramData\nvm'
    $nvmSource = 'C:\nvm4w\nodejs'
    $nvmTarget = $null
    if (Test-Path $nvmDir) {
        $nvmTarget = Get-ChildItem $nvmDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } |
            Sort-Object { [Version]($_.Name.TrimStart('v')) } -Descending |
            Select-Object -First 1 -ExpandProperty FullName
    }
    if ($nvmTarget) {
        if ($DryRun) {
            Write-SOKLog "[DRY] Would repair nvm junction: $nvmSource -> $nvmTarget" -Level Ignore
        } else {
            cmd /c "rmdir `"$nvmSource`"" 2>$null | Out-Null
            $r = cmd /c "mklink /J `"$nvmSource`" `"$nvmTarget`"" 2>&1
            if ($LASTEXITCODE -eq 0) { Write-SOKLog "Fixed nvm4w junction: $nvmSource -> $nvmTarget" -Level Success; $infraFixed++ }
            else { Write-SOKLog "nvm4w junction failed: $r" -Level Warn; $infraFailed++ }
        }
    } else {
        Write-SOKLog "SKIP nvm4w: no versioned dir found under $nvmDir" -Level Warn
        $infraSkipped++
    }

    # ── FIX 2: OneDrive UC orphan ────────────────────────────────────────────
    $odPath = 'C:\Users\shelc\OneDrive - University of Cincinnati'
    if (Test-Path $odPath) {
        $odAttr = [System.IO.File]::GetAttributes($odPath)
        if ($odAttr -band [System.IO.FileAttributes]::ReparsePoint) {
            if ($DryRun) {
                Write-SOKLog "[DRY] Would remove orphaned UC OneDrive junction: $odPath" -Level Ignore
            } else {
                cmd /c "rmdir `"$odPath`"" 2>$null | Out-Null
                if (-not (Test-Path $odPath)) { Write-SOKLog "Removed orphaned UC OneDrive junction." -Level Success; $infraFixed++ }
                else { Write-SOKLog "Could not remove UC OneDrive junction (manual rmdir required)" -Level Warn; $infraFailed++ }
            }
        } else {
            Write-SOKLog "SKIP UC OneDrive: exists but is NOT a reparse point — manual review" -Level Warn; $infraSkipped++
        }
    } else {
        Write-SOKLog "SKIP UC OneDrive: path absent (already clean)" -Level Ignore
    }

    # ── FIX 3: Kibana node.exe shim ─────────────────────────────────────────
    $kibanaShim = 'C:\ProgramData\chocolatey\bin\node.exe'
    if (Test-Path $kibanaShim) {
        $shimSize = (Get-Item $kibanaShim -ErrorAction SilentlyContinue).Length
        if ($shimSize -lt 256KB) {
            if ($DryRun) {
                Write-SOKLog "[DRY] Would rename Kibana node shim ($([math]::Round($shimSize/1KB,1)) KB)" -Level Ignore
            } else {
                Rename-Item $kibanaShim "$kibanaShim.bak" -Force -ErrorAction SilentlyContinue
                Write-SOKLog "Renamed Kibana node shim -> .bak ($([math]::Round($shimSize/1KB,1)) KB)" -Level Success
                $infraFixed++
            }
        } else {
            Write-SOKLog "SKIP Kibana shim: $([math]::Round($shimSize/1MB,1)) MB — looks like real Node binary" -Level Ignore
            $infraSkipped++
        }
    }

    # ── FIX 4: Legacy SOK History dir ───────────────────────────────────────
    $legacyHistory     = Join-Path $env:USERPROFILE 'Documents\Journal\Projects\SOK\History'
    $deprecatedHistory = Join-Path $env:USERPROFILE 'Documents\Journal\Projects\SOK\Deprecated\History'
    if (Test-Path $legacyHistory) {
        if ($DryRun) {
            Write-SOKLog "[DRY] Would move legacy SOK\History -> SOK\Deprecated\History" -Level Ignore
        } else {
            $depParent = Split-Path $deprecatedHistory -Parent
            if (-not (Test-Path $depParent)) { New-Item -Path $depParent -ItemType Directory -Force | Out-Null }
            Move-Item $legacyHistory $deprecatedHistory -Force -ErrorAction Continue
            Write-SOKLog "Moved legacy SOK\History -> SOK\Deprecated\History" -Level Success
            $infraFixed++
        }
    }

    # ── FIX 5: Scoop shim repair ─────────────────────────────────────────────
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        $scoopShimDir = "$env:USERPROFILE\scoop\shims"
        if (Test-Path $scoopShimDir) {
            if ($DryRun) {
                Write-SOKLog "[DRY] Would run: scoop update (repairs shim paths)" -Level Ignore
            } else {
                Write-SOKLog "Running scoop update to repair shim paths..." -Level Ignore
                $r = & scoop update 2>&1 | Select-Object -Last 3
                Write-SOKLog "  scoop update: $($r -join ' | ')" -Level Ignore
                $infraFixed++
            }
        }
    } else {
        Write-SOKLog "SKIP Scoop shim repair: scoop not found in PATH" -Level Warn; $infraSkipped++
    }

    Write-SOKLog "InfraFix complete. Fixed: $infraFixed | Skipped: $infraSkipped | Failed: $infraFailed" -Level Success
    $GlobalState['InfraFix_Result'] = @{ Fixed = $infraFixed; Skipped = $infraSkipped; Failed = $infraFailed }
}

# ══════════════════════════════════════════════════════════════════════════════
# [2] INVENTORY — Full System Snapshot
# ══════════════════════════════════════════════════════════════════════════════
if ($TakeInventory) {
    Write-SOKLog '━━━ [2] INVENTORY: Full System Snapshot ━━━' -Level Section
    Write-SOKLog "ScanCaliber: $ScanCaliber (1=Quick / 2=Standard / 3=Deep)" -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN — snapshot in memory only ***' -Level Warn }

    $invStart = Get-Date
    $invData  = [ordered]@{
        CapturedAt  = (Get-Date -Format 'o')
        ScanCaliber = $ScanCaliber
        Host        = $env:COMPUTERNAME
        User        = $env:USERNAME
        PSVersion   = $PSVersionTable.PSVersion.ToString()
    }

    # ── Drive Topology ───────────────────────────────────────────────────────
    Write-SOKDivider "Drive Topology"
    $logDisks      = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
    $driveTopology = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($ld in $logDisks) {
        $entry = @{
            Letter     = $ld.DeviceID
            Label      = $ld.VolumeName
            SizeKB     = [math]::Round($ld.Size / 1KB, 0)
            FreeKB     = [math]::Round($ld.FreeSpace / 1KB, 0)
            UsedPct    = if ($ld.Size -gt 0) { [math]::Round((($ld.Size - $ld.FreeSpace) / $ld.Size) * 100, 1) } else { 0 }
            FileSystem = $ld.FileSystem
        }
        $driveTopology.Add($entry)
        $warnFlag = if ($entry.UsedPct -gt 85) { ' *** HIGH UTILIZATION ***' } else { '' }
        Write-SOKLog "  $($entry.Letter) [$($entry.Label)] $($entry.FreeKB) KB free / $($entry.SizeKB) KB ($($entry.UsedPct)%)$warnFlag" -Level Ignore
    }
    $invData['drive_topology']              = $driveTopology
    $GlobalState['Inventory_DriveTopology'] = $driveTopology

    # ── Junction Map ─────────────────────────────────────────────────────────
    Write-SOKDivider "Junction Map"
    $junctionRoots = @(
        'C:\ProgramData', 'C:\Program Files', 'C:\Program Files (x86)',
        $env:USERPROFILE, (Join-Path $env:USERPROFILE '.nuget'),
        (Join-Path $env:USERPROFILE '.cargo'), (Join-Path $env:USERPROFILE '.vscode'),
        $env:LOCALAPPDATA, $env:APPDATA
    )
    $junctionMap = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($root in $junctionRoots) {
        if (-not (Test-Path $root)) { continue }
        try {
            $enumOpts = [System.IO.EnumerationOptions]::new()
            $enumOpts.RecurseSubdirectories = $false
            $enumOpts.IgnoreInaccessible    = $true
            $enumOpts.AttributesToSkip      = [System.IO.FileAttributes]::System
            foreach ($dir in [System.IO.Directory]::EnumerateDirectories($root, '*', $enumOpts)) {
                $attr = [System.IO.File]::GetAttributes($dir)
                if (($attr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    $dirInfo   = [System.IO.DirectoryInfo]::new($dir)
                    $target    = if ($dirInfo.LinkTarget) { $dirInfo.LinkTarget } else { 'unknown' }
                    $broken    = -not (Test-Path $target -ErrorAction SilentlyContinue)
                    $crossDrive = ($broken -eq $false -and $target -match '^[A-Z]:' -and $target[0] -ne $dir[0])
                    $junctionMap.Add(@{ Source = $dir; Target = $target; Broken = $broken; CrossDrive = $crossDrive })
                    if ($broken) { Write-SOKLog "  BROKEN: $dir -> $target" -Level Warn }
                }
            }
        } catch { Write-SOKLog "  Junction scan partial error ($root): $_" -Level Warn }
    }
    $invData['junction_map']              = $junctionMap
    $GlobalState['Inventory_JunctionMap'] = $junctionMap
    $brokenCount = @($junctionMap | Where-Object { $_.Broken }).Count
    $crossCount  = @($junctionMap | Where-Object { $_.CrossDrive }).Count
    Write-SOKLog "Junction map: $($junctionMap.Count) total | $brokenCount broken | $crossCount cross-drive" `
        -Level $(if ($brokenCount -gt 0) { 'Warn' } else { 'Success' })

    if ($ScanCaliber -ge 2) {
        Write-SOKDivider "Package Managers (Caliber 2+)"
        # Chocolatey
        $chocoPackages = @()
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $raw = choco list --limit-output --local-only 2>&1
            $chocoPackages = ($raw -split '\r?\n') | Where-Object { $_ -match '\|' } |
                ForEach-Object { $p = $_ -split '\|'; @{ Name = $p[0]; Version = $p[1] } }
            Write-SOKLog "  choco: $($chocoPackages.Count) packages" -Level Ignore
        }
        $invData['choco_packages']              = @{ Count = $chocoPackages.Count; Packages = $chocoPackages }
        $GlobalState['Inventory_ChocoPackages'] = $chocoPackages

        # Scoop
        $scoopPackages = @()
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            $scoopExport = scoop export 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($scoopExport -and $scoopExport.apps) {
                $scoopPackages = $scoopExport.apps | ForEach-Object { @{ Name = $_.name; Version = $_.version } }
            } elseif (Test-Path "$env:USERPROFILE\scoop\apps") {
                $scoopPackages = Get-ChildItem "$env:USERPROFILE\scoop\apps" -Directory |
                    ForEach-Object { @{ Name = $_.Name; Version = 'unknown' } }
            }
            Write-SOKLog "  scoop: $($scoopPackages.Count) packages" -Level Ignore
        }
        $invData['scoop_packages'] = @{ Count = $scoopPackages.Count; Packages = $scoopPackages }

        # Winget
        $wingetPackages = @()
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $wgRaw = winget list --source winget 2>&1 | Select-Object -Skip 3
            $wingetPackages = $wgRaw | Where-Object { $_ -match '\S' } |
                ForEach-Object {
                    if ($_ -match '^(.+?)\s{2,}(\S+)\s{2,}(\S+)') {
                        @{ Name = $Matches[1].Trim(); Id = $Matches[2].Trim(); Version = $Matches[3].Trim() }
                    }
                } | Where-Object { $_ }
            Write-SOKLog "  winget: $($wingetPackages.Count) packages" -Level Ignore
        }
        $invData['winget_packages']              = @{ Count = $wingetPackages.Count; Packages = $wingetPackages }
        $GlobalState['Inventory_WingetPackages'] = $wingetPackages

        # pip (py -3.14)
        $pipPackages = @()
        if (Get-Command py -ErrorAction SilentlyContinue) {
            $pipRaw = py -3.14 -m pip list --format=json 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($pipRaw) {
                $pipPackages = $pipRaw | ForEach-Object { @{ Name = $_.name; Version = $_.version } }
                Write-SOKLog "  pip (py -3.14): $($pipPackages.Count) packages" -Level Ignore
            }
        }
        $invData['pip_packages']              = @{ Count = $pipPackages.Count; Packages = $pipPackages }
        $GlobalState['Inventory_PipPackages'] = $pipPackages

        # Language runtimes
        Write-SOKDivider "Language Runtimes"
        $runtimes = @{}
        @(
            @{ Name='python'; Cmd='py';     Args=@('--version') }
            @{ Name='node';   Cmd='node';   Args=@('--version') }
            @{ Name='go';     Cmd='go';     Args=@('version')   }
            @{ Name='rustc';  Cmd='rustc';  Args=@('--version') }
            @{ Name='dotnet'; Cmd='dotnet'; Args=@('--version') }
            @{ Name='java';   Cmd='java';   Args=@('-version')  }
            @{ Name='ruby';   Cmd='ruby';   Args=@('--version') }
        ) | ForEach-Object {
            if (Get-Command $_.Cmd -ErrorAction SilentlyContinue) {
                $ver = (& $_.Cmd @($_.Args) 2>&1 | Select-Object -First 1) -replace '\r?\n',''
                $runtimes[$_.Name] = $ver
                Write-SOKLog "  $($_.Name): $ver" -Level Ignore
            }
        }
        $invData['runtimes']               = $runtimes
        $GlobalState['Inventory_Runtimes'] = $runtimes

        # Running services snapshot
        Write-SOKDivider "Running Services"
        $runningServices = Get-Service -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq 'Running' } |
            Select-Object -Property Name, DisplayName, StartType |
            ForEach-Object { @{ Name = $_.Name; Display = $_.DisplayName; Start = $_.StartType.ToString() } }
        $invData['running_services']                = @{ Count = $runningServices.Count; Services = $runningServices }
        $GlobalState['Inventory_RunningServices']   = $runningServices
        Write-SOKLog "  Services running: $($runningServices.Count)" -Level Ignore
    }

    if ($ScanCaliber -ge 3) {
        Write-SOKDivider "Binary Hashes (Caliber 3)"
        $hashTargets = @(
            'C:\Windows\System32\cmd.exe'
            'C:\Windows\System32\powershell.exe'
            (Get-Command pwsh.exe   -ErrorAction SilentlyContinue)?.Source
            (Get-Command python.exe -ErrorAction SilentlyContinue)?.Source
            (Get-Command node.exe   -ErrorAction SilentlyContinue)?.Source
            (Get-Command git.exe    -ErrorAction SilentlyContinue)?.Source
        ) | Where-Object { $_ -and (Test-Path $_) }
        $fileHashes = @{}
        foreach ($target in $hashTargets) {
            try {
                $hash = (Get-FileHash $target -Algorithm SHA256 -ErrorAction Stop).Hash
                $fileHashes[$target] = $hash
                Write-SOKLog "  $([System.IO.Path]::GetFileName($target)): $($hash.Substring(0,16))..." -Level Ignore
            } catch { Write-SOKLog "  Hash failed: $target" -Level Warn }
        }
        $invData['binary_hashes'] = $fileHashes
    }

    # Save to disk
    $invDuration = [math]::Round(((Get-Date) - $invStart).TotalSeconds, 1)
    if (-not $DryRun) {
        $outPath = if ($InventoryOutputPath) { $InventoryOutputPath } else {
            Join-Path (Get-ScriptLogDir -ScriptName 'SOK-Inventory') "SOK_Inventory_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        }
        $invData | ConvertTo-Json -Depth 8 | Out-File $outPath -Encoding utf8 -Force
        Write-SOKLog "Inventory saved: $outPath (${invDuration}s)" -Level Success
        $GlobalState['Inventory_OutputPath'] = $outPath
        Save-SOKHistory -ScriptName 'SOK-Inventory' -RunData @{
            Duration        = $invDuration
            ScanCaliber     = $ScanCaliber
            JunctionCount   = $junctionMap.Count
            BrokenJunctions = $brokenCount
            ChocoCount      = $chocoPackages.Count
            PipCount        = $pipPackages.Count
        }
    } else {
        Write-SOKLog "[DRY] Inventory complete (${invDuration}s). In-memory only." -Level Warn
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# [3] SPACE AUDIT — Parallel Disk Classification
# ══════════════════════════════════════════════════════════════════════════════
if ($AuditSpace) {
    Write-SOKLog '━━━ [3] SPACE AUDIT: Parallel Disk Classification ━━━' -Level Section
    Write-SOKLog "Parameters: MinSize=$MinSizeKB KB | Depth=$ScanDepth | Threads=$ThrottleLimit" -Level Ignore

    # Pre-compile regexes once — passed via $using: into parallel runspaces
    $rxSystemEssential  = [regex]::new('(?ix)^C:\\Windows|^C:\\Recovery|\\(System32|SysWOW64|WinSxS|assembly|Microsoft\.NET)([\\]|$)|^C:\\\$|^C:\\Boot|^C:\\EFI|^C:\\PerfLogs|^C:\\System\sVolume\sInformation', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxUserEssential    = [regex]::new('(?ix)\\(Documents|Desktop|AppData\\Roaming\\Microsoft|\.ssh|\.gnupg|Journal)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxOffloadable      = [regex]::new('(?ix)\\(node_modules|\.nuget\\packages|\.cargo\\registry|\.pyenv|JetBrains|scoop\\apps|chocolatey\\lib|Docker\\wsl|Insomnia|GitKraken|Logseq|GitHubDesktop|Postman|Discord\\app-|Slack\\app-)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxDeletable        = [regex]::new('(?ix)\\(Temp|tmp|INetCache|Code\sCache|GPUCache|ShaderCache|CacheStorage|Cache\\Cache_Data|Crash\sReports|pip\\cache|yarn\\cache|D3DSCache)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxDatabaseData     = [regex]::new('(?ix)\\(postgresql\d*|MongoDB\\Server|neo4j\\data|redis\\data|influxdb\\data|mysql\\data)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxSkipEnumeration  = [regex]::new('(?ix)^C:\\Documents\sand\sSettings|^C:\\System\sVolume\sInformation|^C:\\\$Recycle\.Bin|^C:\\\$WINDOWS|WinSxS|WindowsApps|WinREAgent', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxPotentiallyStale = [regex]::new('(?ix)\\(Package\sCache|\.old$|_backup|deprecated|\.bak$|uninstall|NuGet\\packages(?!\\Microsoft))([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)

    # Phase 1: Parallel Directory Enumeration
    Write-SOKLog "Phase 1: Enumerating C:\ (parallel, $ThrottleLimit threads)..." -Level Ignore
    $allDirs = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $topDirs = try { [System.IO.Directory]::GetDirectories('C:\') } catch { @() }

    $topDirs | ForEach-Object -Parallel {
        $topPath  = $_
        $bag      = $using:allDirs
        $rxSkip   = $using:rxSkipEnumeration
        $maxDepth = $using:ScanDepth
        if ($rxSkip.IsMatch($topPath)) { return }
        try {
            $attr = [System.IO.File]::GetAttributes($topPath)
            if (($attr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { return }
        } catch { return }
        $bag.Add($topPath)
        try {
            $opts = [System.IO.EnumerationOptions]::new()
            $opts.RecurseSubdirectories = $true
            $opts.MaxRecursionDepth     = $maxDepth
            $opts.IgnoreInaccessible    = $true
            $opts.AttributesToSkip      = [System.IO.FileAttributes]::ReparsePoint -bor [System.IO.FileAttributes]::System
            foreach ($d in [System.IO.Directory]::EnumerateDirectories($topPath, '*', $opts)) {
                if (-not $rxSkip.IsMatch($d)) { $bag.Add($d) }
            }
        } catch { }
    } -ThrottleLimit $ThrottleLimit
    Write-SOKLog "Phase 1: $($allDirs.Count) directories enumerated." -Level Success

    # Phase 2: Recursive Size + Classification
    Write-SOKLog "Phase 2: Recursive sizing and classification (threshold $MinSizeKB KB)..." -Level Ignore
    $classified = [System.Collections.Concurrent.ConcurrentBag[hashtable]]::new()
    $sizeErrors = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

    $allDirs | ForEach-Object -Parallel {
        $dirPath = $_
        $minKB   = $using:MinSizeKB
        $results = $using:classified
        $errs    = $using:sizeErrors
        $rxSys   = $using:rxSystemEssential
        $rxUser  = $using:rxUserEssential
        $rxDel   = $using:rxDeletable
        $rxDB    = $using:rxDatabaseData
        $rxOff   = $using:rxOffloadable
        $rxStale = $using:rxPotentiallyStale
        try {
            $totalSize = 0L
            $fileOpts  = [System.IO.EnumerationOptions]::new()
            $fileOpts.IgnoreInaccessible    = $true
            $fileOpts.RecurseSubdirectories = $true
            foreach ($f in [System.IO.Directory]::EnumerateFiles($dirPath, '*', $fileOpts)) {
                try { $totalSize += (New-Object System.IO.FileInfo($f)).Length } catch { }
            }
            $sizeKB = [math]::Round($totalSize / 1KB, 0)
            if ($sizeKB -ge $minKB) {
                $verdict = if     ($rxSys.IsMatch($dirPath))   { 'KEEP' }
                           elseif ($rxUser.IsMatch($dirPath))   { 'KEEP' }
                           elseif ($rxDel.IsMatch($dirPath))    { 'CLEAN' }
                           elseif ($rxDB.IsMatch($dirPath))     { 'DB_OFFLOAD' }
                           elseif ($rxOff.IsMatch($dirPath))    { 'OFFLOAD' }
                           elseif ($rxStale.IsMatch($dirPath))  { 'INVESTIGATE' }
                           else                                  { 'UNKNOWN' }
                $results.Add(@{ Path = $dirPath; SizeKB = $sizeKB; Verdict = $verdict; Depth = ($dirPath -split '\\').Count - 1 })
            }
        } catch { $errs.Add("$dirPath : $_") }
    } -ThrottleLimit $ThrottleLimit

    # Phase 3: Aggregate + Report
    $byVerdict = $classified | Group-Object Verdict
    $summary   = @{}
    foreach ($grp in $byVerdict) {
        $totalGB = [math]::Round(($grp.Group | Measure-Object SizeKB -Sum).Sum / 1MB, 2)
        $summary[$grp.Name] = @{ Count = $grp.Count; TotalGB = $totalGB }
        Write-SOKLog "  $($grp.Name.PadRight(12)) $($grp.Count) dirs   $totalGB GB" `
            -Level $(if ($grp.Name -in 'CLEAN','OFFLOAD','DB_OFFLOAD') { 'Warn' } else { 'Ignore' })
    }

    $offloadable = @($classified | Where-Object { $_.Verdict -in 'OFFLOAD','DB_OFFLOAD' } | Sort-Object SizeKB -Descending)
    $cleanable   = @($classified | Where-Object { $_.Verdict -eq 'CLEAN' } | Sort-Object SizeKB -Descending)
    $GlobalState['SpaceAudit_Offloadable'] = $offloadable
    $GlobalState['SpaceAudit_Cleanable']   = $cleanable
    Write-SOKLog "Pipeline: $($offloadable.Count) offloadable ($([math]::Round(($offloadable|Measure-Object SizeKB -Sum).Sum/1MB,1)) GB) + $($cleanable.Count) cleanable dirs in GlobalState." -Level Success

    # MONOLITH NOTE: In the distributed model, SpaceAudit_Offloadable never reaches
    # FUTURE's Offload module (separate process). Here it's in GlobalState and will
    # be available to Offload [16] when it runs later in this session.

    if (-not $DryRun) {
        $auditOutDir = Get-ScriptLogDir -ScriptName 'SOK-SpaceAudit'
        $ts          = Get-Date -Format 'yyyyMMdd_HHmmss'
        $reportPath  = Join-Path $auditOutDir "SpaceAudit_Report_$ts.json"
        @{
            GeneratedAt         = (Get-Date -Format 'o')
            MinSizeKB           = $MinSizeKB
            ScanDepth           = $ScanDepth
            TotalDirsScanned    = $allDirs.Count
            TotalDirsClassified = $classified.Count
            Summary             = $summary
            Offloadable         = ($offloadable | Select-Object -First 100)
            Cleanable           = ($cleanable   | Select-Object -First 100)
            Errors              = @($sizeErrors  | Select-Object -First 50)
        } | ConvertTo-Json -Depth 6 | Out-File $reportPath -Encoding utf8 -Force
        Write-SOKLog "SpaceAudit report: $reportPath" -Level Success
        $GlobalState['SpaceAudit_ReportPath'] = $reportPath
        Save-SOKHistory -ScriptName 'SOK-SpaceAudit' -RunData @{
            Duration         = 0
            TotalDirs        = $allDirs.Count
            OffloadableCount = $offloadable.Count
            CleanableCount   = $cleanable.Count
            ErrorCount       = $sizeErrors.Count
        }
    } else {
        Write-SOKLog "[DRY] Classified $($classified.Count) dirs. Results in GlobalState only." -Level Warn
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# [4] RESTRUCTURE — Identify Backup Structural Debt
# ══════════════════════════════════════════════════════════════════════════════
if ($FixStructure) {
    Write-SOKLog '━━━ [4] RESTRUCTURE: Backup Structural Debt Analysis ━━━' -Level Section
    Write-SOKLog "Mode: $RestructureAction | MaxDepth: $MaxDepth | Targets: $($RestructureTargets.Count)" -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $restructureResults = @{
        ExcessiveNesting = [System.Collections.Generic.List[hashtable]]::new()
        RecursiveBackups = [System.Collections.Generic.List[hashtable]]::new()
        FlattenedPaths   = [System.Collections.Generic.List[hashtable]]::new()
        DuplicateNames   = [System.Collections.Generic.List[hashtable]]::new()
    }
    $nameMap      = [System.Collections.Generic.Dictionary[string, int]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $totalScanned = 0

    foreach ($target in $RestructureTargets) {
        if (-not (Test-Path $target)) { Write-SOKLog "SKIP: $target not found" -Level Warn; continue }
        Write-SOKLog "Scanning: $target" -Level Ignore
        $enumOpts = [System.IO.EnumerationOptions]::new()
        $enumOpts.RecurseSubdirectories = $true
        $enumOpts.IgnoreInaccessible    = $true
        $enumOpts.AttributesToSkip      = [System.IO.FileAttributes]::ReparsePoint

        $dirs = try { [System.IO.Directory]::EnumerateDirectories($target, '*', $enumOpts) } catch { @() }
        foreach ($dir in $dirs) {
            $totalScanned++
            $relative = $dir.Substring($target.Length).TrimStart('\')
            $depth    = ($relative -split '\\').Count
            $dirName  = Split-Path $dir -Leaf

            if ($depth -gt $MaxDepth) {
                $sizeKB = 0
                try {
                    $fo = [System.IO.EnumerationOptions]::new()
                    $fo.IgnoreInaccessible = $true; $fo.RecurseSubdirectories = $true
                    foreach ($f in [System.IO.Directory]::EnumerateFiles($dir, '*', $fo)) {
                        try { $sizeKB += [math]::Round((New-Object System.IO.FileInfo($f)).Length / 1KB, 0) } catch { }
                    }
                } catch { }
                $restructureResults.ExcessiveNesting.Add(@{ Path=$dir; Depth=$depth; SizeKB=$sizeKB })
                Write-SOKLog "  Nesting depth $depth ($([math]::Round($sizeKB/1MB,1)) GB): $dir" -Level Warn
            }

            if ($relative -match '(?i)(backup.*\\.*backup|C_\\|20\d{2}\s+(Seagate|Laptop|Desktop)\s+Backup)') {
                $restructureResults.RecursiveBackups.Add(@{ Path=$dir; Depth=$depth; Pattern=$Matches[0] })
                Write-SOKLog "  Recursive backup '$($Matches[0])': $dir" -Level Warn
            }

            if ($dirName -match '^[A-Z]_' -or $dirName -match '_(Users|Program.Files|AppData|ProgramData)_') {
                $restructureResults.FlattenedPaths.Add(@{ Path=$dir; Name=$dirName })
                Write-SOKLog "  Flattened path: $dirName" -Level Annotate
            }

            $shortName = $dirName.ToLower()
            if ($nameMap.ContainsKey($shortName)) { $nameMap[$shortName]++ }
            else { $nameMap[$shortName] = 1 }
        }
    }

    foreach ($kv in $nameMap.GetEnumerator() | Where-Object { $_.Value -ge 3 }) {
        $restructureResults.DuplicateNames.Add(@{ Name = $kv.Key; Count = $kv.Value })
    }

    Write-SOKLog ("Restructure complete: $totalScanned dirs | " +
        "$($restructureResults.ExcessiveNesting.Count) over-nested | " +
        "$($restructureResults.RecursiveBackups.Count) recursive-backup | " +
        "$($restructureResults.FlattenedPaths.Count) flattened | " +
        "$($restructureResults.DuplicateNames.Count) duplicated names") -Level Success

    if (-not $DryRun) {
        $rsOutDir = Get-ScriptLogDir -ScriptName 'SOK-Restructure'
        $rsPath   = Join-Path $rsOutDir "Restructure_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        $restructureResults | ConvertTo-Json -Depth 6 | Out-File $rsPath -Encoding utf8 -Force
        Write-SOKLog "Restructure report: $rsPath" -Level Success
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# [5] COMPARE SNAPSHOTS — Archive Diff with Symbolic Grammar
# ══════════════════════════════════════════════════════════════════════════════
if ($CompareSnapshots) {
    Write-SOKLog '━━━ [5] COMPARE SNAPSHOTS: Archive Differential Analysis ━━━' -Level Section
    do {
        if (-not $OldSnapshot -or -not $NewSnapshot) {
            Write-SOKLog 'CompareSnapshots requires both -OldSnapshot and -NewSnapshot.' -Level Error
            Write-SOKLog 'Example: -OldSnapshot "...\SOK_Archive_v9.txt" -NewSnapshot "...\SOK_Archive_v10.txt"' -Level Warn
            break
        }
        if (-not (Test-Path $OldSnapshot)) { Write-SOKLog "OldSnapshot not found: $OldSnapshot" -Level Error; break }
        if (-not (Test-Path $NewSnapshot)) { Write-SOKLog "NewSnapshot not found: $NewSnapshot" -Level Error; break }

        Write-SOKLog "Old: $OldSnapshot ($([math]::Round((Get-Item $OldSnapshot).Length/1MB,1)) MB)" -Level Ignore
        Write-SOKLog "New: $NewSnapshot ($([math]::Round((Get-Item $NewSnapshot).Length/1MB,1)) MB)" -Level Ignore

        function Get-ArchiveIndex {
            param([string]$Path)
            $index = @{}; $currentFile = $null; $startLine = 0; $lineNum = 0
            # H-2 fix 2026-04-21: prior `$lineNum - 1` was inconsistent with
            # SOK-Comparator.ps1 Build-FileIndex (uses -5) and factually wrong for
            # Archiver's 5-line per-file header block (blank + dashes + FILE: +
            # SIZE: + dashes — see SOK-Archiver.ps1 lines 188-191). Using -1
            # under-accounted by 4 lines, leaking 4 separator lines into the
            # previous file's range. Unified to the Comparator's ArchiveHeaderOffset.
            $ArchiveHeaderOffset = 5
            $reader = [System.IO.StreamReader]::new($Path)
            try {
                while (($line = $reader.ReadLine()) -ne $null) {
                    $lineNum++
                    if ($line -match '^# FILE: (.+)$') {
                        if ($currentFile) {
                            $endLine = $lineNum - $ArchiveHeaderOffset
                            if ($endLine -lt $startLine) { $endLine = $startLine }
                            $index[$currentFile] = @{ Start = $startLine; End = $endLine }
                        }
                        $currentFile = $Matches[1].Trim(); $startLine = $lineNum
                    }
                }
                if ($currentFile) { $index[$currentFile] = @{ Start = $startLine; End = $lineNum } }
            } finally { $reader.Dispose() }
            return @{ Index = $index; TotalLines = $lineNum }
        }

        function Get-ArchiveChunk {
            param([string]$Path, [hashtable]$Range)
            $lines  = [System.Collections.Generic.List[string]]::new()
            $reader = [System.IO.StreamReader]::new($Path); $n = 0
            try {
                while (($line = $reader.ReadLine()) -ne $null) {
                    $n++
                    if ($n -gt $Range.End) { break }
                    if ($n -ge $Range.Start) { $lines.Add($line) }
                }
            } finally { $reader.Dispose() }
            return $lines
        }

        Write-SOKLog "Indexing archives (streaming)..." -Level Ignore
        $oldIdx = Get-ArchiveIndex -Path $OldSnapshot
        $newIdx = Get-ArchiveIndex -Path $NewSnapshot
        Write-SOKLog "Old index: $($oldIdx.TotalLines) lines, $($oldIdx.Index.Count) files" -Level Ignore
        Write-SOKLog "New index: $($newIdx.TotalLines) lines, $($newIdx.Index.Count) files" -Level Ignore

        $allFiles = @($oldIdx.Index.Keys) + @($newIdx.Index.Keys) | Select-Object -Unique
        $diffs    = [System.Collections.Generic.List[hashtable]]::new()
        $stats    = @{ Added=0; Removed=0; FilesMod=0; FilesNew=0; FilesDel=0; TotalChanges=0 }

        foreach ($file in $allFiles) {
            $inOld = $oldIdx.Index.ContainsKey($file)
            $inNew = $newIdx.Index.ContainsKey($file)
            if (-not $inOld) {
                $diffs.Add(@{ File=$file; Status='[+] Addition'; AddedLines=0; RemovedLines=0 }); $stats.FilesNew++
            } elseif (-not $inNew) {
                $diffs.Add(@{ File=$file; Status='[x] Rescinded'; AddedLines=0; RemovedLines=0 }); $stats.FilesDel++
            } else {
                $oldChunk  = Get-ArchiveChunk -Path $OldSnapshot -Range $oldIdx.Index[$file]
                $newChunk  = Get-ArchiveChunk -Path $NewSnapshot -Range $newIdx.Index[$file]
                $comparison = Compare-Object $oldChunk $newChunk -ErrorAction SilentlyContinue
                if ($comparison) {
                    $added   = @($comparison | Where-Object { $_.SideIndicator -eq '=>' }).Count
                    $removed = @($comparison | Where-Object { $_.SideIndicator -eq '<=' }).Count
                    $subtype = if ($added -gt 0 -and $removed -gt 0) { '[~] Mixed' }
                               elseif ($added -gt 0) { '[+]' } else { '[-]' }
                    $diffs.Add(@{ File=$file; Status="[*] Revision $subtype"; AddedLines=$added; RemovedLines=$removed })
                    $stats.FilesMod++; $stats.Added += $added; $stats.Removed += $removed
                }
            }
        }
        $stats.TotalChanges = $stats.Added + $stats.Removed + $stats.FilesNew + $stats.FilesDel

        $maxLines = [math]::Max($oldIdx.TotalLines, $newIdx.TotalLines)
        $pctDiff  = if ($maxLines -gt 0) { [math]::Round(($stats.TotalChanges / $maxLines) * 100, 2) } else { 0 }
        Write-SOKLog "Volatility: $pctDiff% ($($stats.TotalChanges) changes / $maxLines lines)" `
            -Level $(if ($pctDiff -gt $AutoApproveThreshold) {'Warn'} else {'Success'})

        if ($pctDiff -ge 100) { Write-SOKLog "ABORT: Archives appear completely disjoint (100% volatility)." -Level Error; break }

        if ($pctDiff -gt $AutoApproveThreshold -and -not $DryRun) {
            $confirm = Read-Host "Volatility $pctDiff% exceeds threshold $AutoApproveThreshold%. Write report? (Y/N)"
            if ($confirm -notmatch '^[Yy]') { Write-SOKLog "Report cancelled by operator." -Level Warn; break }
        }

        if (-not $DryRun) {
            if (-not (Test-Path $ComparatorOutputDir)) { New-Item -Path $ComparatorOutputDir -ItemType Directory -Force | Out-Null }
            $diffPath = "$ComparatorOutputDir\SOK_Diff_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            $v = 1
            while (Test-Path $diffPath) { $diffPath = "$ComparatorOutputDir\SOK_Diff_$(Get-Date -Format 'yyyyMMdd_HHmmss')_v$v.txt"; $v++ }

            # M-6 (Cluster C) consistency 2026-04-22: 1MB → 128KB buffer (matches SOK-Comparator fix)
            $utf8   = [System.Text.Encoding]::UTF8
            $stream = [System.IO.FileStream]::new($diffPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read, 131072)
            $writer = [System.IO.StreamWriter]::new($stream, $utf8)
            try {
                $writer.WriteLine("# SOK DIFFERENTIAL REPORT")
                $writer.WriteLine("# Old : $OldSnapshot")
                $writer.WriteLine("# New : $NewSnapshot")
                $writer.WriteLine("# Generated: $(Get-Date -Format 'o')")
                $writer.WriteLine("# Volatility: $pctDiff% | Modified: $($stats.FilesMod) | New: $($stats.FilesNew) | Deleted: $($stats.FilesDel)")
                $writer.WriteLine("# Grammar: [+]=Addition  [-]=Subtraction  [x]=Rescinded  [*]=Revision  [~]=Mixed")
                $writer.WriteLine("")
                foreach ($diff in ($diffs | Sort-Object { $_.Status })) {
                    $writer.WriteLine("$($diff.Status) | +$($diff.AddedLines) -$($diff.RemovedLines) | $($diff.File)")
                }
            } finally {
                if ($writer) { $writer.Flush(); $writer.Dispose() }
                if ($stream) { $stream.Dispose() }
            }
            Write-SOKLog "Diff report saved: $diffPath" -Level Success
        } else {
            Write-SOKLog "[DRY] $($diffs.Count) files differ. Report not written." -Level Warn
        }
        Write-SOKLog "CompareSnapshots: Modified=$($stats.FilesMod) New=$($stats.FilesNew) Deleted=$($stats.FilesDel)" -Level Success
    } while ($false)
}

# ══════════════════════════════════════════════════════════════════════════════
# [6] BACKUP RESTRUCTURE — Extract and Merge Archive Collections
# ══════════════════════════════════════════════════════════════════════════════
if ($RestructureBackups) {
    Write-SOKLog '━━━ [6] BACKUP RESTRUCTURE: Archive Extraction & Merge ━━━' -Level Section
    Write-SOKLog "Archive root: $ArchiveRoot | Merge target: $MergeTarget" -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN — no deletions or extractions ***' -Level Warn }

    $sevenZip = @(
        'C:\Program Files\7-Zip\7z.exe'
        'C:\Program Files (x86)\7-Zip\7z.exe'
        (Get-Command 7z.exe -ErrorAction SilentlyContinue)?.Source
    ) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

    if (-not $sevenZip -and -not $SkipExtraction) {
        Write-SOKLog "7-Zip not found. Extraction phase will be skipped. Install via: choco install 7zip" -Level Warn
    }

    $derivationMap = @{
        '2020 Seagate 1'    = '_a1'
        '2020 Seagate 2'    = '_a2'
        '2025'              = '_b'
        '13JUL2025'         = '_c'
        'mommaddell backup' = '_d'
    }

    function Get-DerivationTag { param([string]$Path)
        foreach ($kv in $derivationMap.GetEnumerator()) {
            if ($Path -match [regex]::Escape($kv.Key)) { return $kv.Value }
        }
        return ''
    }

    # Phase 1: Delete raw folder duplicates (opt-in via -RunPhase1)
    if ($RunPhase1 -and (Test-Path $ArchiveRoot)) {
        Write-SOKDivider "Phase 1: Delete Pre-Extracted Raw Folders"
        $rawFolders = Get-ChildItem $ArchiveRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { -not $_.Name.EndsWith('.7z') }
        foreach ($folder in $rawFolders) {
            $sevenZ = Join-Path $ArchiveRoot "$($folder.Name).7z"
            if (Test-Path $sevenZ) {
                Write-SOKLog "  Raw (has .7z): $($folder.Name)" -Level Warn
                if ($DryRun) {
                    Write-SOKLog "  [DRY] Would delete: $($folder.FullName)" -Level Ignore
                } else {
                    $emptyTemp = Join-Path $env:TEMP "SOK_Empty_$([System.Guid]::NewGuid().ToString('N').Substring(0,8))"
                    New-Item -Path $emptyTemp -ItemType Directory -Force | Out-Null
                    & robocopy $emptyTemp $folder.FullName /MIR /R:1 /W:1 /NFL /NDL /NP 2>&1 | Out-Null
                    Remove-Item $emptyTemp -Force -ErrorAction SilentlyContinue
                    Remove-Item $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
                    Write-SOKLog "  Deleted raw folder: $($folder.Name)" -Level Success
                }
            }
        }
    }

    # Phase 2: Extract .7z archives
    if (-not $SkipExtraction -and $sevenZip -and (Test-Path $ArchiveRoot)) {
        Write-SOKDivider "Phase 2: Extract .7z Archives"
        $archives = Get-ChildItem $ArchiveRoot -Filter '*.7z' -File -ErrorAction SilentlyContinue
        function Test-IsFirstVolume { param([System.IO.FileInfo]$F)
            return $F.Name -notmatch '\.(7z\.00[2-9]|7z\.\d{3,}|part[2-9]\d*\.7z|r\d{2,})$'
        }
        foreach ($archive in ($archives | Where-Object { Test-IsFirstVolume $_ })) {
            $extractDest = Join-Path $ArchiveRoot $archive.BaseName
            Write-SOKLog "  $($archive.Name) -> $extractDest" -Level Ignore
            if ($DryRun) {
                Write-SOKLog "  [DRY] Would: & `"$sevenZip`" x `"$($archive.FullName)`" -o`"$extractDest`" -aoa -mmt=16" -Level Ignore
            } else {
                $r = & $sevenZip x $archive.FullName "-o$extractDest" -aoa -mmt=16 -bsp1 2>&1
                if ($LASTEXITCODE -le 1) {
                    Write-SOKLog "  Extracted: $($archive.Name)" -Level Success
                    $confirm = Read-Host "  Delete $($archive.Name) after verified extraction? (Y/N)"
                    if ($confirm -match '^[Yy]') {
                        Remove-Item $archive.FullName -Force -ErrorAction SilentlyContinue
                        Write-SOKLog "  Deleted: $($archive.Name)" -Level Success
                    }
                } else { Write-SOKLog "  7z exit ${LASTEXITCODE}: $($archive.Name)" -Level Error }
            }
        }
    }

    # Phase 3: Merge with derivation tagging
    if (-not $SkipMerge -and (Test-Path $ArchiveRoot)) {
        Write-SOKDivider "Phase 3: Merge with Derivation Tags -> $MergeTarget"
        if (-not $DryRun -and -not (Test-Path $MergeTarget)) { New-Item -Path $MergeTarget -ItemType Directory -Force | Out-Null }
        $moved = 0; $renamed = 0; $failed = 0
        foreach ($src in (Get-ChildItem $ArchiveRoot -Directory -ErrorAction SilentlyContinue)) {
            $tag  = Get-DerivationTag $src.FullName
            $dest = Join-Path $MergeTarget $src.Name
            if (Test-Path $dest) {
                $taggedName = "$($src.Name)$tag"
                $dest = Join-Path $MergeTarget $taggedName
                if (Test-Path $dest) {
                    $counter = 2
                    while (Test-Path (Join-Path $MergeTarget "$taggedName`_$counter")) { $counter++ }
                    $dest = Join-Path $MergeTarget "$taggedName`_$counter"
                }
                $renamed++
            }
            if ($DryRun) {
                Write-SOKLog "[DRY] $($src.Name) -> $(Split-Path $dest -Leaf)$tag" -Level Ignore
            } else {
                try {
                    Move-Item $src.FullName $dest -Force
                    Write-SOKLog "  Moved: $($src.Name) -> $(Split-Path $dest -Leaf)" -Level Success; $moved++
                } catch { Write-SOKLog "  Failed: $($src.Name) — $_" -Level Error; $failed++ }
            }
        }
        Write-SOKLog "Phase 3 complete: Moved=$moved | Renamed=$renamed | Failed=$failed" -Level Success
    }
}

# Log PAST domain timing
if ($pastStart) {
    $pastDuration = [math]::Round(((Get-Date) - $pastStart).TotalSeconds, 1)
    Write-SOKLog "━━━ DOMAIN 1 (PAST) COMPLETE: ${pastDuration}s ━━━" -Level Section
    if ($GlobalState.ContainsKey('SpaceAudit_Offloadable')) {
        $offGB = [math]::Round((($GlobalState['SpaceAudit_Offloadable'] | Measure-Object SizeKB -Sum).Sum) / 1MB, 2)
        Write-SOKLog "MONOLITH PIPELINE: $offGB GB offloadable identified → flowing to FUTURE Offload via GlobalState (no JSON read)" -Level Warn
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# ████ DOMAIN 2: PRESENT — Live Machine State, Performance, Hygiene ████
# ══════════════════════════════════════════════════════════════════════════════
if ($OptimizeDefender -or $OptimizeProcesses -or $OptimizeServices -or $Maintain -or $Clean -or $PreSwap -or $RebootClean -or $LiveScan -or $LiveDigest) {
    $presentStart = Get-Date
    Write-SOKLog '' -Level Ignore
    Write-SOKLog "████████ DOMAIN 2: PRESENT — Live State, Performance, Hygiene ████████" -Level Section
    Write-SOKLog "Temporal Domain: What is happening RIGHT NOW, and how do we make this session better?" -Level Ignore
}

# ══════════════════════════════════════════════════════════════════════════════
# [7] DEFENDER OPTIMIZER — Throttle AV Before Anything Else
# ══════════════════════════════════════════════════════════════════════════════
if ($OptimizeDefender) {
    Write-SOKLog '━━━ [7] DEFENDER OPTIMIZER: Throttle + Dev Exclusions ━━━' -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $mpStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if (-not $mpStatus) {
        Write-SOKLog "Cannot read MpComputerStatus. Defender may not be present or accessible." -Level Warn
    } elseif (-not $mpStatus.RealTimeProtectionEnabled -and -not $mpStatus.AntivirusEnabled) {
        Write-SOKLog "Third-party AV appears to be the primary protection layer. Skipping Defender config." -Level Warn
    } else {
        Get-Process MpCmdRun -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-SOKLog "Stopped MpCmdRun scan processes." -Level Ignore

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

        if (-not $DryRun) {
            Set-MpPreference -ScanAvgCPULoadFactor 20 -ErrorAction SilentlyContinue
            Set-MpPreference -EnableLowCpuPriority $true -ErrorAction SilentlyContinue
            Set-MpPreference -DisableArchiveScanning $true -ErrorAction SilentlyContinue
            Set-MpPreference -ScanScheduleQuickScanTime 180 -ErrorAction SilentlyContinue
            Set-MpPreference -MAPSReporting Basic -ErrorAction SilentlyContinue
            Set-MpPreference -SubmitSamplesConsent 2 -ErrorAction SilentlyContinue
            Write-SOKLog "Defender throttled: 20% CPU cap, low priority, archive scanning disabled." -Level Success
            foreach ($path in $exclusions) {
                if (Test-Path $path) {
                    Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
                    Write-SOKLog "  Exclusion added: $path" -Level Ignore
                }
            }
            Start-Job { Update-MpSignature -ErrorAction SilentlyContinue } | Out-Null
            Write-SOKLog "Defender definition update started (background)." -Level Ignore
        } else {
            Write-SOKLog "[DRY] Would configure Defender throttles + $($exclusions.Count) exclusions." -Level Ignore
        }
        Write-SOKLog "DefenderOptimizer complete." -Level Success
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# [8] PROCESS OPTIMIZER — Property-Based Background Process Termination
# ══════════════════════════════════════════════════════════════════════════════
if ($OptimizeProcesses) {
    Write-SOKLog "━━━ [8] PROCESS OPTIMIZER: Property-Based Kill ($ProcessMode) ━━━" -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $selfPid   = $PID
    $parentPid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").ParentProcessId

    # v1.1.1 backport from SOK-ProcessOptimizer (C-1 / C-2 fix 2026-04-21):
    #   - Read namespaced $config.ProcessOptimizer.ProtectedProcesses (was $config.ProtectedProcesses → empty)
    #   - Case-normalized to lowercase for consistent matching
    #   - Read $config.ProcessOptimizer.BloatProcesses (was completely ignored → user bloat list silently inert)
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
        # v1.1.1 backport: anchored exact-match regex; removed cmd|conhost|node|terminal|cursor (Electron node.exe
        # / shell-out cmd were immortalizing every consumer app); added claude|windowsterminal; $hasWindow gate
        # removed so headless pwsh automation is protected.
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

    # v1.1.0 backport: BloatProcess added to Balanced and Aggressive — catches configured consumer apps that
    # used to land in Uncategorized regardless of window state.
    $killTiers = @{
        Conservative = @('Telemetry', 'Updater', 'CrashReporter')
        Balanced     = @('Telemetry', 'Updater', 'CrashReporter', 'CloudSync', 'AppDataBackground', 'AppDataRoaming', 'HighCPUBackground', 'BloatProcess')
        Aggressive   = @('Telemetry', 'Updater', 'CrashReporter', 'CloudSync', 'AppDataBackground', 'AppDataRoaming', 'HighCPUBackground', 'BloatProcess', 'UserProcess')
    }
    $killCategories = $killTiers[$ProcessMode]

    $allProcesses  = Get-Process -ErrorAction SilentlyContinue
    $categoryStats = @{}
    $killList      = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()

    foreach ($proc in $allProcesses) {
        $cat = Get-ProcessCategory $proc
        if (-not $categoryStats.ContainsKey($cat)) { $categoryStats[$cat] = 0 }
        $categoryStats[$cat]++
        # v1.1.1 backport: case-normalized $protected check
        if ($cat -in $killCategories -and $protected -notcontains $proc.ProcessName.ToLower()) { $killList.Add($proc) }
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
# [9] SERVICE OPTIMIZER — Stop Idle Databases and Background Services
# ══════════════════════════════════════════════════════════════════════════════
if ($OptimizeServices) {
    Write-SOKLog "━━━ [9] SERVICE OPTIMIZER: Reclaim Idle Database Memory ($ServiceAction) ━━━" -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $serviceTargets = @(
        @{ Name='Neo4j';       ServiceName='neo4j';              ProcessName='java';           Port=7474; Rec='STOP';        Reason='~800MB RAM when idle; start with net start neo4j' }
        @{ Name='MongoDB';     ServiceName='MongoDB';            ProcessName='mongod';         Port=27017;Rec='STOP';        Reason='~250MB RAM idle; rarely needed outside IS7036' }
        @{ Name='MySQL';       ServiceName='MySQL80';            ProcessName='mysqld';         Port=3306; Rec='CONDITIONAL'; Reason='Stop if no active connections' }
        @{ Name='PostgreSQL';  ServiceName='postgresql-x64-15';  ProcessName='postgres';       Port=5432; Rec='CONDITIONAL'; Reason='Stop if no pgAdmin4 or dbt session active' }
        @{ Name='Redis';       ServiceName='Redis';              ProcessName='redis-server';   Port=6379; Rec='STOP';        Reason='~50MB; restart is instant' }
        @{ Name='Memurai';     ServiceName='Memurai';            ProcessName='memurai-server'; Port=6379; Rec='STOP';        Reason='Redis-compat; stop if Redis is preferred' }
        @{ Name='InfluxDB';    ServiceName='influxdb';           ProcessName='influxd';        Port=8086; Rec='CONDITIONAL'; Reason='Stop if not actively collecting metrics' }
        @{ Name='Waves Audio'; ServiceName='WavesSysSvc';        ProcessName='WavesSysSvc64';  Port=0;    Rec='CONDITIONAL'; Reason='Stop only if no audio output needed' }
        @{ Name='ZeroTier';    ServiceName='ZeroTierOneService'; ProcessName='ZeroTier One';   Port=9993; Rec='CONDITIONAL'; Reason='Stop if not using ZT VPN' }
        @{ Name='TeamViewer';  ServiceName='TeamViewer';         ProcessName='TeamViewer';     Port=5938; Rec='STOP';        Reason='Attack surface; start manually when remote support needed' }
        @{ Name='Adobe ARM';   ServiceName='AdobeARMservice';    ProcessName='armsvc';         Port=0;    Rec='STOP';        Reason='Updater service; no need to run continuously' }
        @{ Name='Jenkins';     ServiceName='Jenkins';            ProcessName='java';           Port=8080; Rec='CONDITIONAL'; Reason='Heavy; run only during CI/CD work' }
        @{ Name='Puppet';      ServiceName='puppet';             ProcessName='puppet';         Port=8140; Rec='STOP';        Reason='Config management agent; start manually' }
    )

    $stopped = 0; $skipped = 0; $report = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($svc in $serviceTargets) {
        $svcObj     = Get-Service $svc.ServiceName -ErrorAction SilentlyContinue
        $procObj    = Get-Process -Name $svc.ProcessName -ErrorAction SilentlyContinue
        $portActive = if ($svc.Port -gt 0) {
            $null -ne (Get-NetTCPConnection -LocalPort $svc.Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1)
        } else { $false }
        $memMB    = if ($procObj) { [math]::Round(($procObj | Measure-Object WorkingSet -Sum).Sum / 1MB, 1) } else { 0 }
        $isRunning = ($svcObj -and $svcObj.Status -eq 'Running') -or ($null -ne $procObj)

        $entry = @{ Name=$svc.Name; Running=$isRunning; PortActive=$portActive; MemoryMB=$memMB; Rec=$svc.Rec; Reason=$svc.Reason }
        $report.Add($entry)

        if (-not $isRunning) { Write-SOKLog "  IDLE: $($svc.Name) (not running)" -Level Ignore; continue }

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
# [10] MAINTENANCE — Package Updates, Cache Cleanup, System Optimization
# ══════════════════════════════════════════════════════════════════════════════
if ($Maintain) {
    Write-SOKLog "━━━ [10] MAINTENANCE: System Optimization ($MaintMode) ━━━" -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $allDrives = @(Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Continue)

    # 10a: Junction Health Check
    # MONOLITH OPTIMIZATION: Use GlobalState junction map from Inventory [2] if available
    Write-SOKLog "10a: Junction health check..." -Level Ignore
    $brokenJunctions = [System.Collections.Generic.List[string]]::new()
    if ($GlobalState.ContainsKey('Inventory_JunctionMap')) {
        $cachedMap    = $GlobalState['Inventory_JunctionMap']
        $cachedBroken = @($cachedMap | Where-Object { $_.Broken })
        foreach ($jxn in $cachedBroken) {
            $brokenJunctions.Add("$($jxn.Source) -> $($jxn.Target)")
            Write-SOKLog "  BROKEN (from Inventory GlobalState): $($jxn.Source) -> $($jxn.Target)" -Level Warn
        }
        Write-SOKLog "  Junction check from GlobalState: $($cachedMap.Count) total, $($cachedBroken.Count) broken" -Level $(if ($cachedBroken.Count -gt 0) {'Warn'} else {'Success'})
    } else {
        # Fallback: targeted scan (distributed-compatible path)
        $junctionRootsM = @('C:\ProgramData', 'C:\Program Files', $env:USERPROFILE, $env:LOCALAPPDATA, $env:APPDATA)
        foreach ($root in $junctionRootsM) {
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
    }

    # 10b: Cache Cleanup (all modes)
    Write-SOKLog "10b: Core cache cleanup..." -Level Ignore
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
            Get-ChildItem $path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Write-SOKLog "  Cleaned: $path" -Level Ignore
        } catch { Write-SOKLog "  Partial clean: $path" -Level Warn }
    }
    if (-not $DryRun) {
        try { Clear-RecycleBin -Force -ErrorAction Stop; Write-SOKLog "  Recycle bin emptied." -Level Success }
        catch {
            try { (New-Object -ComObject Shell.Application).Namespace(10).Items() | ForEach-Object { Remove-Item $_.Path -Recurse -Force -ErrorAction SilentlyContinue }; Write-SOKLog "  Recycle bin emptied (COM fallback)." -Level Success }
            catch { Write-SOKLog "  Recycle bin: $_" -Level Warn }
        }
    }

    # 10c: Package Updates (Standard+)
    if ($MaintMode -in @('Standard', 'Deep', 'Thorough')) {
        Write-SOKLog "10c: Package manager updates (timeout: $PackageTimeoutSec s each)..." -Level Ignore
        if ($DryRun) {
            Write-SOKLog "[DRY] Would run: choco upgrade all, scoop update *, winget upgrade --all, pip updates, npm updates" -Level Warn
            if (Get-Command py -ErrorAction SilentlyContinue) {
                $pipDryCheck = py -3.14 -m pip check 2>&1
                $pipDryConflicts = @($pipDryCheck | Where-Object { $_ -and $_ -notmatch 'No broken requirements' })
                if ($pipDryConflicts.Count -gt 0) {
                    Write-SOKLog "  pip check: $($pipDryConflicts.Count) conflict(s)" -Level Warn
                    $pipDryConflicts | ForEach-Object { Write-SOKLog "    $_" -Level Warn }
                } else { Write-SOKLog "  pip check: no conflicts" -Level Success }
            }
        } else {
            if (Get-Command choco -ErrorAction SilentlyContinue) {
                Write-SOKLog "  choco upgrade all..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { choco upgrade all -y --no-progress 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  choco: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
            }
            if (Get-Command scoop -ErrorAction SilentlyContinue) {
                Write-SOKLog "  scoop update + upgrade..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { scoop update; scoop upgrade * 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  scoop: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
            }
            if (Get-Command winget -ErrorAction SilentlyContinue) {
                Write-SOKLog "  winget upgrade --all..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { winget upgrade --all --silent --accept-package-agreements --accept-source-agreements 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  winget: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
            }
            if (Get-Command py -ErrorAction SilentlyContinue) {
                $pipPreCheck = py -3.14 -m pip check 2>&1
                $pipPreConflicts = @($pipPreCheck | Where-Object { $_ -and $_ -notmatch 'No broken requirements' })
                if ($pipPreConflicts.Count -gt 0) {
                    Write-SOKLog "  pip check (pre): $($pipPreConflicts.Count) conflict(s)" -Level Warn
                    $pipPreConflicts | ForEach-Object { Write-SOKLog "    $_" -Level Warn }
                } else { Write-SOKLog "  pip check: no conflicts" -Level Success }
                $outdated = py -3.14 -m pip list --outdated --format=json 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($outdated) {
                    Write-SOKLog "  pip: $($outdated.Count) packages outdated" -Level Warn
                    foreach ($pkg in ($outdated | Select-Object -First 20)) {
                        Invoke-WithTimeout -ScriptBlock { py -3.14 -m pip install --upgrade $pkg.name --quiet 2>&1 } -TimeoutSec 60 | Out-Null
                    }
                    Write-SOKLog "  pip: updates applied (capped at 20)." -Level Success
                    $pipPostCheck = py -3.14 -m pip check 2>&1
                    $pipPostConflicts = @($pipPostCheck | Where-Object { $_ -and $_ -notmatch 'No broken requirements' })
                    if ($pipPostConflicts.Count -gt 0) {
                        Write-SOKLog "  pip check (post): $($pipPostConflicts.Count) conflict(s) — review manually" -Level Warn
                    } else { Write-SOKLog "  pip check (post): clean" -Level Success }
                } else { Write-SOKLog "  pip: all packages current." -Level Ignore }
            }
            if (Get-Command npm -ErrorAction SilentlyContinue) {
                Write-SOKLog "  npm global outdated..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { npm update -g 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  npm: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
            }
            if (Get-Command rustup -ErrorAction SilentlyContinue) {
                Write-SOKLog "  rustup update + cargo install-update..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { rustup update 2>&1 } -TimeoutSec $PackageTimeoutSec
                Write-SOKLog "  rustup: $(if ($r.Success) {'OK'} else {"FAILED — $($r.Error)"})" -Level $(if ($r.Success) {'Success'} else {'Warn'})
                if (Get-Command cargo -ErrorAction SilentlyContinue) {
                    $cu = Invoke-WithTimeout -ScriptBlock { cargo install-update --all 2>&1 } -TimeoutSec $PackageTimeoutSec
                    Write-SOKLog "  cargo install-update: $(if ($cu.Success) {'OK'} else {"FAILED (cargo-update installed? Run: cargo install cargo-update)"})" -Level $(if ($cu.Success) {'Ignore'} else {'Warn'})
                }
            }
            if (Get-Command go -ErrorAction SilentlyContinue) {
                Write-SOKLog "  go toolchain update..." -Level Ignore
                $r = Invoke-WithTimeout -ScriptBlock { go env GOPATH 2>&1 } -TimeoutSec 30
                $gopath = if ($r.Success -and $r.Output) { $r.Output.Trim() } else { "$env:USERPROFILE\go" }
                if ($env:GOPATH -ne $gopath) { [System.Environment]::SetEnvironmentVariable('GOPATH', $gopath, 'Process'); Write-SOKLog "  go: GOPATH refreshed to $gopath" -Level Ignore }
                $rClean = Invoke-WithTimeout -ScriptBlock { go clean -modcache 2>&1 } -TimeoutSec 120
                Write-SOKLog "  go clean -modcache: $(if ($rClean.Success) {'OK'} else {"FAILED — $($rClean.Error)"})" -Level $(if ($rClean.Success) {'Ignore'} else {'Warn'})
            }
        }
    }

    # 10d: Deep System Optimization (Deep+)
    if ($MaintMode -in @('Deep', 'Thorough') -and -not $DryRun) {
        Write-SOKLog "10d: Deep optimization (DNS flush + TRIM + drive health)..." -Level Ignore
        Clear-DnsClientCache -ErrorAction SilentlyContinue; Write-SOKLog "  DNS cache flushed." -Level Success
        foreach ($drive in $allDrives | Where-Object { $_.FileSystem -eq 'NTFS' }) {
            try {
                Optimize-Volume -DriveLetter $drive.DeviceID.TrimEnd(':') -ReTrim -ErrorAction Stop
                Write-SOKLog "  TRIM: $($drive.DeviceID)" -Level Success
            } catch { Write-SOKLog "  TRIM failed: $($drive.DeviceID) — $_" -Level Warn }
        }
        foreach ($disk in Get-PhysicalDisk -ErrorAction SilentlyContinue) {
            $health = $disk.HealthStatus
            Write-SOKLog "  Disk '$($disk.FriendlyName)': $health" -Level $(if ($health -eq 'Healthy') {'Ignore'} else {'Warn'})
        }
    }

    # 10e: Thorough Mode Extras
    if ($MaintMode -eq 'Thorough' -and -not $DryRun) {
        Write-SOKLog "10e: Thorough — NuGet purge + SSD wear + Windows Update..." -Level Ignore
        try { dotnet nuget locals all --clear 2>&1 | Out-Null; Write-SOKLog "  .NET NuGet locals cleared." -Level Success } catch {}
        foreach ($disk in Get-PhysicalDisk -ErrorAction SilentlyContinue) {
            try {
                $rc = $disk | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
                if ($rc) {
                    $wearPct = if ($rc.Wear -gt 0) { "$($rc.Wear)%" } else { 'N/A' }
                    $hours   = if ($rc.PowerOnHours -gt 0) { "$($rc.PowerOnHours)h" } else { 'N/A' }
                    $state   = switch ($rc.Wear) {
                        { $_ -lt 10 } { 'HEALTHY' }; { $_ -lt 30 } { 'MODERATE' }; { $_ -lt 70 } { 'AGING' }; { $_ -lt 90 } { 'DEGRADED' }; default { 'CRITICAL' }
                    }
                    Write-SOKLog "  SSD Wear: $($disk.FriendlyName) | $wearPct worn | $hours on | $state" -Level $(if ($state -eq 'HEALTHY') {'Ignore'} else {'Warn'})
                }
            } catch { }
        }
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
# [11] CLEANUP — Kill Lock Holders + Deep Cache Eviction
# ══════════════════════════════════════════════════════════════════════════════
if ($Clean) {
    Write-SOKLog '━━━ [11] CLEANUP: Process Kill + Deep Cache Eviction ━━━' -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    $candidateKills  = @('chrome', 'msedge', 'Claude', 'Slack', 'Discord', 'GitKraken', 'Cypress', 'Insomnia', 'AcroCEF', 'Acrobat')
    # C-1 fix 2026-04-21: namespaced $config.ProcessOptimizer.ProtectedProcesses + case-normalized comparison
    $cfgProtected = @($config.ProcessOptimizer.ProtectedProcesses) |
        Where-Object { $_ } |
        ForEach-Object { $_.ToString().ToLower() }
    $processesToKill = $candidateKills | Where-Object { $_.ToLower() -notin $cfgProtected }
    if ($candidateKills.Count -ne $processesToKill.Count) {
        $skippedProcs = $candidateKills | Where-Object { $_.ToLower() -in $cfgProtected }
        Write-SOKLog "  Protected processes excluded: $($skippedProcs -join ', ')" -Level Warn
    }
    foreach ($proc in $processesToKill) {
        $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
        if ($running) {
            if ($DryRun) { Write-SOKLog "[DRY] Would stop: $proc" -Level Ignore }
            else { $running | Stop-Process -Force -ErrorAction Continue; Write-SOKLog "  Stopped: $proc" -Level Warn }
        }
    }
    if (-not $DryRun) { Start-Sleep -Seconds 3 }

    $cacheTargetsC = @(
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
    foreach ($path in $cacheTargetsC) {
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
# [12] PRESWAP — Deep Junction Repair + Cache Eviction Before Drive Swap
# ══════════════════════════════════════════════════════════════════════════════
if ($PreSwap) {
    Write-SOKLog '━━━ [12] PRESWAP: Deep Junction Repair + Pre-Swap Cache Eviction ━━━' -Level Section
    Write-SOKLog 'This module prepares the machine for an E: drive swap or major offload operation.' -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

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

    Write-SOKLog "Phase 2: Killing lock-holding applications..." -Level Ignore
    $killListPS = @('chrome','msedge','Slack','Discord','GitKraken','Cypress','Insomnia','AcroCEF','Acrobat','Logseq','Postman','balena_etcher','signal','Bitwarden','GitHubDesktop','Zoom','Teams','obs64','obs32','Code','Grammarly','Kindle')
    foreach ($proc in $killListPS) {
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
    if (-not $DryRun) {
        py -3.14 -m pip cache purge 2>&1 | Out-Null; Write-SOKLog "  pip cache purged." -Level Ignore
        npm cache clean --force 2>&1 | Out-Null;     Write-SOKLog "  npm cache purged." -Level Ignore
        dotnet nuget locals all --clear 2>&1 | Out-Null; Write-SOKLog "  NuGet cache purged." -Level Ignore
    }
    Write-SOKLog "PreSwap complete. Machine prepared for drive operations." -Level Success
}

# ══════════════════════════════════════════════════════════════════════════════
# [13] REBOOT CLEAN — Post-Reboot Junction Verification
# ══════════════════════════════════════════════════════════════════════════════
if ($RebootClean) {
    Write-SOKLog '━━━ [13] REBOOT CLEAN: Post-Reboot Junction Verification + Temp Cleanup ━━━' -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

    foreach ($tempPath in @($env:TEMP, "$env:WINDIR\Temp")) {
        if ($DryRun) { Write-SOKLog "[DRY] Would clean post-reboot temp: $tempPath" -Level Ignore }
        else { Get-ChildItem $tempPath -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue }
    }

    $expectedJunctions = @(
        @{ Source = "$env:USERPROFILE\.pyenv";                    Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_.pyenv" }
        @{ Source = "$env:USERPROFILE\scoop\cache";               Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_scoop_cache" }
        @{ Source = "$env:USERPROFILE\scoop\apps";                Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_scoop_apps" }
        @{ Source = "$env:USERPROFILE\.nuget\packages";           Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_.nuget_packages" }
        @{ Source = "$env:USERPROFILE\.cargo\registry";           Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_.cargo_registry" }
        @{ Source = "$env:USERPROFILE\.vscode\extensions";        Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_.vscode_extensions" }
        @{ Source = "$env:USERPROFILE\AppData\Local\JetBrains";   Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_AppData_Local_JetBrains" }
        @{ Source = "C:\tools\flutter";                           Target = "$ExternalDrive\SOK_Offload\C_tools_flutter" }
        @{ Source = "C:\Program Files\JetBrains";                 Target = "$ExternalDrive\SOK_Offload\C_Program Files_JetBrains" }
        @{ Source = "C:\ProgramData\chocolatey\lib";              Target = "$ExternalDrive\SOK_Offload\C_ProgramData_chocolatey_lib" }
        @{ Source = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages";Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_AppData_Local_WinGet_Packages" }
        @{ Source = "$env:USERPROFILE\scoop\persist\rustup\.cargo\registry"; Target = "$ExternalDrive\SOK_Offload\C_Users_shelc_scoop_persist_rustup_.cargo_registry" }
    )

    $ok = 0; $broken = 0; $missing = 0
    foreach ($jxn in $expectedJunctions) {
        $srcExists  = Test-Path $jxn.Source
        $isJunction = $srcExists -and (([System.IO.File]::GetAttributes($jxn.Source) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
        $tgtExists  = Test-Path $jxn.Target -ErrorAction SilentlyContinue
        if ($isJunction -and $tgtExists) { Write-SOKLog "  OK: $(Split-Path $jxn.Source -Leaf)" -Level Ignore; $ok++ }
        elseif (-not $srcExists -and -not $tgtExists) { Write-SOKLog "  MISSING (both sides absent): $($jxn.Source)" -Level Warn; $missing++ }
        elseif (-not $tgtExists) { Write-SOKLog "  BROKEN (target offline): $($jxn.Source) -> $($jxn.Target)" -Level Warn; $broken++ }
        else { Write-SOKLog "  IS REAL DIR (reverted!): $($jxn.Source) — needs repair" -Level Error; $broken++ }
    }
    Write-SOKLog "Junction check: $ok OK | $broken broken | $missing missing" -Level $(if ($broken -gt 0) {'Warn'} else {'Success'})

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
# [14] LIVE SCAN — Streaming Filesystem Inventory
# ══════════════════════════════════════════════════════════════════════════════
if ($LiveScan) {
    Write-SOKLog '━━━ [14] LIVE SCAN: Streaming Filesystem Inventory ━━━' -Level Section
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
        $utf8      = [System.Text.Encoding]::UTF8
        $stream    = [System.IO.FileStream]::new($outJson, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read, 131072)
        $writer    = [System.IO.StreamWriter]::new($stream, $utf8)
        $errStream = [System.IO.StreamWriter]::new($errLog, $false, $utf8)
        $count     = 0; $errCount = 0; $scanStart = Get-Date

        try {
            $writer.WriteLine('{"meta":{"script":"SOK-LiveScan","source":"' + $LiveScanSource + '","started":"' + (Get-Date -Format 'o') + '"},"items":[')
            $first = $true
            $root  = [System.IO.DirectoryInfo]::new($LiveScanSource)
            $items = if ($LiveScanDirsOnly) { $root.EnumerateDirectories('*', $enumOpts) }
                     else { $root.EnumerateFiles('*', $enumOpts) }
            foreach ($item in $items) {
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
                } catch { $errStream.WriteLine("[$($item.FullName)] $_"); $errCount++ }
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
# [15] LIVE DIGEST — Summarize Latest LiveScan into TopN Report
# ══════════════════════════════════════════════════════════════════════════════
if ($LiveDigest) {
    Write-SOKLog '━━━ [15] LIVE DIGEST: Telemetry Summarization ━━━' -Level Section

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
                $topFolders = $scanData.items | Where-Object { $_.s } |
                    Group-Object { ($_.p -split '\\')[0..2] -join '\' } |
                    Select-Object Name, @{N='Count';E={$_.Count}}, @{N='SizeKB';E={($_.Group | Measure-Object s -Sum).Sum}} |
                    Sort-Object SizeKB -Descending | Select-Object -First $DigestTopN

                $extBreakdown = $scanData.items | Where-Object { $_.p -match '\.' } |
                    Group-Object { [System.IO.Path]::GetExtension($_.p).ToLower() } |
                    Select-Object Name, @{N='Count';E={$_.Count}}, @{N='SizeKB';E={($_.Group | Measure-Object s -Sum).Sum}} |
                    Sort-Object SizeKB -Descending | Select-Object -First 30

                $largest = $scanData.items | Where-Object { $_.s } |
                    Sort-Object s -Descending | Select-Object -First $DigestTopN | Select-Object p, s, m

                $outDir     = Get-ScriptLogDir -ScriptName 'SOK-LiveDigest'
                $ts         = Get-Date -Format 'yyyyMMdd_HHmmss'
                $outJson    = Join-Path $outDir "LiveDigest_$ts.json"
                $digestData = @{
                    GeneratedAt  = (Get-Date -Format 'o')
                    SourceFile   = $inputPath
                    TopN         = $DigestTopN
                    TopFolders   = $topFolders
                    Extensions   = $extBreakdown
                    LargestFiles = $largest
                }
                $digestData | ConvertTo-Json -Depth 6 | Out-File $outJson -Encoding utf8 -Force
                Write-SOKLog "LiveDigest saved: $outJson" -Level Success

                Write-SOKLog "Top 10 directories by size:" -Level Section
                $topFolders | Select-Object -First 10 | ForEach-Object {
                    Write-SOKLog "  $([math]::Round($_.SizeKB/1MB,2)) GB — $($_.Name)  ($($_.Count) files)" -Level Ignore
                }
            }
        } catch { Write-SOKLog "LiveDigest parse error: $_" -Level Error }
    }
}

# Log PRESENT domain timing
if ($presentStart) {
    $presentDuration = [math]::Round(((Get-Date) - $presentStart).TotalSeconds, 1)
    $ramAfterPresent = try { (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory } catch { 0 }
    $ramDeltaMB      = [math]::Round(($ramAfterPresent - $ramBefore) / 1KB, 0)
    $ramDeltaSign    = if ($ramDeltaMB -ge 0) { "+$ramDeltaMB" } else { "$ramDeltaMB" }
    Write-SOKLog "━━━ DOMAIN 2 (PRESENT) COMPLETE: ${presentDuration}s | RAM ${ramDeltaSign} MB ━━━" -Level Section
}

# ══════════════════════════════════════════════════════════════════════════════
# ████ DOMAIN 3: FUTURE — Proactive Protection, Data Continuity ████
# ══════════════════════════════════════════════════════════════════════════════
if ($Offload -or $Backup -or $Archive) {
    $futureStart = Get-Date
    Write-SOKLog '' -Level Ignore
    Write-SOKLog "████████ DOMAIN 3: FUTURE — Proactive Protection, Data Continuity ████████" -Level Section
    Write-SOKLog "Temporal Domain: Looking FORWARD — how do we ensure the machine survives the next crisis?" -Level Ignore
}

# ══════════════════════════════════════════════════════════════════════════════
# [16] OFFLOAD — Move Heavy Toolchains to E:\ + Replace with NTFS Junctions
# ══════════════════════════════════════════════════════════════════════════════
if ($Offload) {
    Write-SOKLog "━━━ [16] OFFLOAD: Move Heavy Toolchains to $ExternalDrive + NTFS Junctions ━━━" -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN — no files will be moved ***' -Level Warn }

    do {
        # Validate external drive
        $extDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$ExternalDrive'" -ErrorAction SilentlyContinue
        if (-not $extDisk) {
            Write-SOKLog "ABORT: External drive $ExternalDrive not found. Is the drive connected?" -Level Error; break
        }
        $extFreeGB  = [math]::Round($extDisk.FreeSpace / 1GB, 1)
        $extUsedPct = [math]::Round((($extDisk.Size - $extDisk.FreeSpace) / $extDisk.Size) * 100, 1)
        Write-SOKLog "External drive $ExternalDrive : $extFreeGB GB free ($extUsedPct% used)" -Level $(if ($extUsedPct -gt 85) {'Warn'} else {'Ignore'})

        if ($extUsedPct -ge $MaxDriveUtilPct) {
            Write-SOKLog "ABORT: $ExternalDrive is at $extUsedPct%, >= $MaxDriveUtilPct% ceiling." -Level Error; break
        }

        $extVolume = Get-Volume -DriveLetter ($ExternalDrive.TrimEnd(':')) -ErrorAction SilentlyContinue
        if ($extVolume -and $extVolume.HealthStatus -ne 'Healthy') {
            Write-SOKLog "ABORT: $ExternalDrive volume health is '$($extVolume.HealthStatus)'." -Level Error; break
        }

        $offloadRoot = Join-Path $ExternalDrive 'SOK_Offload'
        if (-not $DryRun -and -not (Test-Path $offloadRoot)) { New-Item -Path $offloadRoot -ItemType Directory -Force | Out-Null }

        $rxNeverMove = [regex]::new('(?ix)^[A-Z]:\\Windows|^[A-Z]:\\Recovery|\\(System32|SysWOW64|WinSxS|pagefile|hiberfil)([\\]|$)|^[A-Z]:\\Users$|\.git\\objects', [System.Text.RegularExpressions.RegexOptions]::Compiled)

        $offloadTargets = @(
            @{ Source = "$env:LOCALAPPDATA\Docker\wsl";                      Group='P1-Docker';   Priority=1; Desc='Docker WSL2 VM disk (ext4.vhdx) — can be 30-60 GB' }
            @{ Source = 'C:\Program Files\PostgreSQL\15\data';               Group='P2-Database'; Priority=2; Desc='PostgreSQL 15 data dir' }
            @{ Source = 'C:\Program Files\MongoDB\Server\7.0\data';          Group='P2-Database'; Priority=2; Desc='MongoDB data dir' }
            @{ Source = 'C:\Program Files\Neo4j\data';                       Group='P2-Database'; Priority=2; Desc='Neo4j graph data' }
            @{ Source = "$env:USERPROFILE\.pyenv";                           Group='P3-Runtime';  Priority=3; Desc='Python version manager environments' }
            @{ Source = "$env:USERPROFILE\.conda\envs";                      Group='P3-Runtime';  Priority=3; Desc='Conda virtual environments' }
            @{ Source = "$env:USERPROFILE\scoop\apps";                       Group='P3-Runtime';  Priority=3; Desc='Scoop app binaries' }
            @{ Source = "$env:LOCALAPPDATA\Programs\miniconda3\pkgs";        Group='P3-Runtime';  Priority=3; Desc='Miniconda package cache' }
            @{ Source = 'C:\ProgramData\chocolatey\lib';                     Group='P4-Cache';    Priority=4; Desc='Chocolatey installed packages lib' }
            @{ Source = "$env:USERPROFILE\.cargo\registry";                  Group='P4-Cache';    Priority=4; Desc='Cargo crate registry cache' }
            @{ Source = "$env:USERPROFILE\.nuget\packages";                  Group='P4-Cache';    Priority=4; Desc='.NET NuGet packages cache' }
            @{ Source = "$env:APPDATA\npm\node_modules";                     Group='P4-Cache';    Priority=4; Desc='NPM global modules' }
            @{ Source = "$env:USERPROFILE\.gradle\caches";                   Group='P4-Cache';    Priority=4; Desc='Gradle build cache' }
            @{ Source = "$env:LOCALAPPDATA\Packages\Insomnia.Insomnia_*";   Group='P5-AppData';  Priority=5; Desc='Insomnia app data' }
            @{ Source = "$env:APPDATA\GitKraken";                            Group='P5-AppData';  Priority=5; Desc='GitKraken app data + logs' }
            @{ Source = "$env:APPDATA\Logseq";                               Group='P5-AppData';  Priority=5; Desc='Logseq IndexedDB + workspace cache' }
            @{ Source = "$env:LOCALAPPDATA\GitHubDesktop";                   Group='P5-AppData';  Priority=5; Desc='GitHub Desktop app-* update dirs' }
            @{ Source = "$env:APPDATA\Postman";                              Group='P5-AppData';  Priority=5; Desc='Postman app + package cache' }
            @{ Source = "$env:LOCALAPPDATA\JetBrains";                      Group='P6-IDE';      Priority=6; Desc='JetBrains IDE local app data' }
            @{ Source = "C:\Program Files\JetBrains";                        Group='P6-IDE';      Priority=6; Desc='JetBrains IDE installations' }
            @{ Source = "$env:USERPROFILE\.vscode\extensions";               Group='P6-IDE';      Priority=6; Desc='VS Code extensions' }
            @{ Source = 'C:\tools\flutter';                                  Group='P7-Misc';     Priority=7; Desc='Flutter SDK' }
            @{ Source = "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Packages"; Group='P7-Misc'; Priority=7; Desc='WinGet installed packages cache' }
        )

        # MONOLITH OPTIMIZATION: Check GlobalState for junction map instead of reading inventory JSON
        if ($GlobalState.ContainsKey('Inventory_JunctionMap')) {
            Write-SOKLog "PIPELINE: Using junction map from GlobalState (no JSON read required)" -Level Ignore
        } else {
            # Fallback: read inventory JSON from disk (distributed-compatible path)
            $resolvedInvPath = $InventoryPath
            if (-not $resolvedInvPath) { $resolvedInvPath = Get-LatestLogPath -ScriptName 'SOK-Inventory' }
            if ($resolvedInvPath -and (Test-Path $resolvedInvPath)) {
                Write-SOKLog "Inventory loaded from disk: $resolvedInvPath" -Level Ignore
            } else { Write-SOKLog "No inventory JSON found. Run -TakeInventory first for richer context." -Level Warn }
        }

        $offloaded = 0; $skipped = 0; $failed = 0
        $runningFreeBytes = $extDisk.FreeSpace

        foreach ($target in ($offloadTargets | Sort-Object Priority)) {
            $resolvedSrc = if ($target.Source -match '\*') {
                $candidates = @(Get-Item $target.Source -ErrorAction SilentlyContinue | Select-Object -First 1)
                if ($candidates) { $candidates[0].FullName } else { $null }
            } else { $target.Source }

            if (-not $resolvedSrc -or -not (Test-Path $resolvedSrc)) {
                Write-SOKLog "  SKIP (not found): $($target.Source)" -Level Ignore; $skipped++; continue
            }

            if ($rxNeverMove.IsMatch($resolvedSrc)) {
                Write-SOKLog "  SKIP (protected): $resolvedSrc" -Level Warn; $skipped++; continue
            }

            $srcAttr = [System.IO.File]::GetAttributes($resolvedSrc)
            if (($srcAttr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                $existingTarget = ([System.IO.DirectoryInfo]::new($resolvedSrc)).LinkTarget
                Write-SOKLog "  SKIP (already junction -> $existingTarget): $resolvedSrc" -Level Ignore; $skipped++; continue
            }

            $sizeKB = 0
            try {
                $fo = [System.IO.EnumerationOptions]::new(); $fo.IgnoreInaccessible = $true; $fo.RecurseSubdirectories = $true
                foreach ($f in [System.IO.Directory]::EnumerateFiles($resolvedSrc, '*', $fo)) {
                    try { $sizeKB += [math]::Round((New-Object System.IO.FileInfo($f)).Length / 1KB, 0) } catch { }
                }
            } catch { }

            if ($sizeKB -lt $MinOffloadKB) {
                Write-SOKLog "  SKIP (too small, $([math]::Round($sizeKB/1MB,1)) GB < threshold): $resolvedSrc" -Level Ignore; $skipped++; continue
            }

            $projectedUsedBytes = $extDisk.Size - $runningFreeBytes + ($sizeKB * 1KB)
            $projectedPct = [math]::Round(($projectedUsedBytes / $extDisk.Size) * 100, 1)
            if ($projectedPct -gt $MaxDriveUtilPct) {
                Write-SOKLog "  SKIP (budget: $projectedPct% would exceed ${MaxDriveUtilPct}%): $resolvedSrc ($([math]::Round($sizeKB/1MB,1)) GB)" -Level Warn; $skipped++; continue
            }

            $relative = ($resolvedSrc -replace '^([A-Z]):', '$1') -replace '[\\]', '_'
            $destPath = Join-Path $offloadRoot $relative

            Write-SOKLog "  [$($target.Priority)] $resolvedSrc ($([math]::Round($sizeKB/1MB,1)) GB) — $($target.Desc)" -Level Warn

            if ($DryRun) {
                Write-SOKLog "  [DRY] Would offload: $resolvedSrc -> $destPath" -Level Ignore; $skipped++; continue
            }

            if (-not (Test-Path $destPath)) { New-Item -Path $destPath -ItemType Directory -Force | Out-Null }
            $roboArgs   = @($resolvedSrc, $destPath, '/E', '/MOVE', '/R:3', '/W:5', "/MT:$Threads", '/XJ', '/COPY:DAT', '/DCOPY:T', '/NFL', '/NDL', '/NP')
            $roboOutput = & robocopy @roboArgs 2>&1
            $roboExit   = $LASTEXITCODE

            if ($roboExit -lt 8) {
                # C-5 fix 2026-04-21: replaced SilentlyContinue with try/Stop/catch +
                # explicit gate before mklink. Without the gate, a silently-failed
                # Remove-Item leaves source partially populated; mklink then fails
                # silently against the existing path and the operator never sees the
                # half-moved state. With the gate, partial /MOVE now logs explicit
                # data-preserved-in-both-places diagnostic.
                if (Test-Path $resolvedSrc) {
                    try {
                        Remove-Item $resolvedSrc -Recurse -Force -ErrorAction Stop
                    } catch {
                        Write-SOKLog "  Source removal failed: $($_.Exception.Message) — junction skipped; data preserved at source $resolvedSrc AND dest $destPath" -Level Error
                        $failed++
                        continue
                    }
                }
                if (Test-Path $resolvedSrc) {
                    Write-SOKLog "  Source still exists after removal — junction skipped (locked files remain at $resolvedSrc; data also at $destPath)" -Level Warn
                    $failed++
                    continue
                }
                $junctionResult = cmd /c "mklink /J `"$resolvedSrc`" `"$destPath`"" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $jxnAttr   = [System.IO.File]::GetAttributes($resolvedSrc) -band [System.IO.FileAttributes]::ReparsePoint
                    $jxnTarget = ([System.IO.DirectoryInfo]::new($resolvedSrc)).LinkTarget
                    if ($jxnAttr -ne 0 -and $jxnTarget -and (Test-Path $jxnTarget)) {
                        Write-SOKLog "  Junction verified: $resolvedSrc -> $destPath" -Level Success
                    } else {
                        Write-SOKLog "  WARN: Junction created but verification failed (target: $jxnTarget)" -Level Error
                    }
                    $offloaded++
                    $runningFreeBytes -= ($sizeKB * 1KB)
                } else {
                    Write-SOKLog "  WARN: robocopy OK but junction failed: $junctionResult" -Level Error; $failed++
                }
            } else {
                Write-SOKLog "  ERROR: robocopy exit $roboExit for $resolvedSrc" -Level Error; $failed++
            }
        }

        $finalUsedPct = [math]::Round((($extDisk.Size - $runningFreeBytes) / $extDisk.Size) * 100, 1)
        Write-SOKLog "Offload complete. Moved: $offloaded | Skipped: $skipped | Failed: $failed | E: utilization now ~$finalUsedPct%" -Level Success
        Save-SOKHistory -ScriptName 'SOK-Offload' -RunData @{ Offloaded=$offloaded; Skipped=$skipped; Failed=$failed; DryRun=$DryRun.IsPresent; FinalDriveUtilPct=$finalUsedPct }

    } while ($false)
}

# ══════════════════════════════════════════════════════════════════════════════
# [17] BACKUP — Robocopy Mirror to E:\Backup_Archive
# ══════════════════════════════════════════════════════════════════════════════
if ($Backup) {
    Write-SOKLog "━━━ [17] BACKUP: Robocopy $(if($Incremental){'Mirror (Incremental /MIR)'}else{'Full Copy (/E)'}) ━━━" -Level Section
    Write-SOKLog "Sources: $($BackupSources.Count) | Dest: $BackupDest | Threads: $Threads" -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN — robocopy /L mode (list only) ***' -Level Warn }

    $destDrive = ($BackupDest -split ':')[0] + ':'
    $destDisk  = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$destDrive'" -ErrorAction SilentlyContinue
    if ($destDisk) {
        $destFreeKB = [math]::Round($destDisk.FreeSpace / 1KB, 0)
        Write-SOKLog "Destination drive ${destDrive}: $destFreeKB KB free" -Level $(if ($destFreeKB -lt 10485760) {'Warn'} else {'Ignore'})
    }

    if (-not $DryRun -and -not (Test-Path $BackupDest)) { New-Item -Path $BackupDest -ItemType Directory -Force | Out-Null }

    $totalCopied = 0; $totalFailed = 0; $allVerified = $true
    $roboFlag    = if ($Incremental) { '/MIR' } else { '/E' }

    foreach ($src in $BackupSources) {
        if (-not (Test-Path $src)) {
            Write-SOKLog "SOURCE NOT FOUND: $src" -Level Error; $totalFailed++; continue
        }
        $srcName  = Split-Path $src -Leaf
        $destPath = Join-Path $BackupDest $srcName
        $logFile  = Join-Path (Get-ScriptLogDir -ScriptName 'SOK-Backup') "robo_${srcName}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

        Write-SOKLog "Backing up: $src -> $destPath" -Level Ignore

        $roboArgs = @(
            $src, $destPath, $roboFlag,
            '/R:3', '/W:5', "/MT:$Threads",
            '/XJ', '/COPY:DAT', '/DCOPY:T', '/NP', '/ETA', '/BYTES',
            "/LOG+:$logFile"
        )
        if ($DryRun) { $roboArgs += '/L' }

        $roboOutput = & robocopy @roboArgs 2>&1
        $roboExit   = $LASTEXITCODE

        $level = if ($roboExit -lt 4) { 'Success' } elseif ($roboExit -lt 8) { 'Warn' } else { 'Error' }
        Write-SOKLog "  robocopy exit $roboExit ($srcName) — $logFile" -Level $level

        if ($roboExit -ge 8) { $totalFailed++; $allVerified = $false; continue }

        if (-not $DryRun -and (Test-Path $destPath)) {
            try {
                $fo = [System.IO.EnumerationOptions]::new(); $fo.IgnoreInaccessible = $true; $fo.RecurseSubdirectories = $true
                $srcFiles = @([System.IO.Directory]::EnumerateFiles($src, '*', $fo))
                $dstFiles = @([System.IO.Directory]::EnumerateFiles($destPath, '*', $fo))
                $srcSize  = ($srcFiles | ForEach-Object { try { (New-Object System.IO.FileInfo($_)).Length } catch { 0 } } | Measure-Object -Sum).Sum
                $dstSize  = ($dstFiles | ForEach-Object { try { (New-Object System.IO.FileInfo($_)).Length } catch { 0 } } | Measure-Object -Sum).Sum
                $countDelta    = [math]::Abs($srcFiles.Count - $dstFiles.Count)
                $sizeDeltaPct  = if ($srcSize -gt 0) { [math]::Abs(($srcSize - $dstSize) / $srcSize * 100) } else { 0 }
                $verified      = ($countDelta -le 5 -and $sizeDeltaPct -le 1.0)
                if ($verified) {
                    Write-SOKLog "  Verified: $($srcFiles.Count) files, $([math]::Round($srcSize/1MB,1)) MB" -Level Success
                    $totalCopied += $srcFiles.Count
                } else {
                    Write-SOKLog "  WARN: verification delta — files: $countDelta, size: $([math]::Round($sizeDeltaPct,2))%" -Level Warn
                    $allVerified = $false
                }
            } catch { Write-SOKLog "  Verification skipped: $_" -Level Warn }
        }
    }

    Write-SOKLog "Backup complete. Sources: $($BackupSources.Count) | Files copied: ~$totalCopied | Errors: $totalFailed | Verified: $allVerified" -Level $(if ($allVerified) {'Success'} else {'Warn'})
    Save-SOKHistory -ScriptName 'SOK-Backup' -RunData @{
        Sources=$BackupSources.Count; Incremental=$Incremental.IsPresent
        FilesCopied=$totalCopied; FailedSources=$totalFailed; Verified=$allVerified; DryRun=$DryRun.IsPresent
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# [18] ARCHIVE — Stream Source Code to Versioned Flat-File Snapshot
# ══════════════════════════════════════════════════════════════════════════════
if ($Archive) {
    Write-SOKLog "━━━ [18] ARCHIVE: Source Code Snapshot ━━━" -Level Section
    Write-SOKLog "Sources: $($ArchiveSources.Count) | Output: $ArchiveOutputDir | Name: $ArchiveBaseName" -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN — manifest will be built but no file will be written ***' -Level Warn }

    if (-not (Test-Path $ArchiveOutputDir)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $ArchiveOutputDir -Force | Out-Null }
        else { Write-SOKLog "[DRY] Would create: $ArchiveOutputDir" -Level Ignore }
    }

    $version = 1
    while (Test-Path "$ArchiveOutputDir\${ArchiveBaseName}_v$version.txt") { $version++ }
    $targetFile = "$ArchiveOutputDir\${ArchiveBaseName}_v$version.txt"
    Write-SOKLog "Archive version: v$version -> $targetFile" -Level Ignore

    $extRegex  = [regex]::new($ArchiveExtensions, [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $manifest  = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $totalSize = 0L

    foreach ($folder in $ArchiveSources) {
        if (-not (Test-Path $folder)) { Write-SOKLog "  SKIP (not found): $folder" -Level Warn; continue }
        $files = Get-ChildItem $folder -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $extRegex.IsMatch($_.Extension) -and
                $_.Name -notmatch [regex]::Escape($ArchiveBaseName)
            }
        foreach ($f in $files) { $manifest.Add($f); $totalSize += $f.Length }
    }

    $manifest = @($manifest | Sort-Object FullName)
    Write-SOKLog "Manifest: $($manifest.Count) files, $([math]::Round($totalSize/1MB,1)) MB" -Level Success

    if ($DryRun) {
        Write-SOKLog "[DRY] Would write $($manifest.Count) files to $targetFile" -Level Warn
        $manifest | Select-Object -First 20 | ForEach-Object { Write-SOKLog "  $($_.FullName)" -Level Ignore }
        if ($manifest.Count -gt 20) { Write-SOKLog "  ... and $($manifest.Count - 20) more" -Level Ignore }
    } else {
        # M-6 (Cluster C) consistency 2026-04-22: 1MB → 128KB
        $utf8   = [System.Text.Encoding]::UTF8
        $stream = [System.IO.FileStream]::new($targetFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read, 131072)
        $writer = [System.IO.StreamWriter]::new($stream, $utf8)
        try {
            $writer.WriteLine("# ══════════════════════════════════════════════════════════════════════")
            $writer.WriteLine("# SOK ARCHIVE SNAPSHOT v$version")
            $writer.WriteLine("# Generated  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
            $writer.WriteLine("# Sources    : $($ArchiveSources -join ', ')")
            $writer.WriteLine("# File count : $($manifest.Count)")
            $writer.WriteLine("# Total size : $([math]::Round($totalSize/1MB,1)) MB")
            $writer.WriteLine("# Format     : SOK Archiver v2.1 | Diff-compatible with SOK-Comparator")
            $writer.WriteLine("# ══════════════════════════════════════════════════════════════════════")
            $writer.WriteLine("")
            $writer.WriteLine("# ── TABLE OF CONTENTS ─────────────────────────────────────────────────")
            foreach ($f in $manifest) {
                $fname   = $f.Name.PadRight(50).Substring(0,50)
                $sizeStr = "$([math]::Round($f.Length/1KB,1)) KB".PadLeft(10)
                $mod     = $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                $writer.WriteLine("# $fname $sizeStr  $mod")
            }
            $writer.WriteLine("")
            $readErrors = 0
            foreach ($f in $manifest) {
                $writer.WriteLine("# ════════════════════════════════════════════════════════════════════════")
                $writer.WriteLine("# FILE: $($f.FullName)")
                $writer.WriteLine("# Size: $([math]::Round($f.Length/1KB,1)) KB | Modified: $($f.LastWriteTime.ToString('o')) | Attributes: $($f.Attributes)")
                $writer.WriteLine("# ════════════════════════════════════════════════════════════════════════")
                try {
                    $reader = [System.IO.StreamReader]::new($f.FullName)
                    while (($line = $reader.ReadLine()) -ne $null) { $writer.WriteLine($line) }
                    $reader.Dispose()
                } catch {
                    $writer.WriteLine("# !!! READ ERROR: $($_.Exception.Message) !!!")
                    $readErrors++
                }
                $writer.WriteLine("")
            }
            Write-SOKLog "Archive written: $targetFile ($([math]::Round((Get-Item $targetFile).Length/1MB,1)) MB) | Read errors: $readErrors" -Level $(if ($readErrors -eq 0) {'Success'} else {'Warn'})
        } finally {
            if ($writer) { $writer.Flush(); $writer.Dispose() }
            if ($stream) { $stream.Dispose() }
            [System.GC]::Collect()
        }
        Save-SOKHistory -ScriptName 'SOK-Archiver' -RunData @{
            Version=$version; FileCount=$manifest.Count; SizeBytes=$totalSize; TargetPath=$targetFile
        }
    }
}

# Log FUTURE domain timing
if ($futureStart) {
    $futureDuration = [math]::Round(((Get-Date) - $futureStart).TotalSeconds, 1)
    Write-SOKLog "━━━ DOMAIN 3 (FUTURE) COMPLETE: ${futureDuration}s ━━━" -Level Section
}

# ══════════════════════════════════════════════════════════════════════════════
# END ALL MODULES
# ══════════════════════════════════════════════════════════════════════════════
} catch {
    Write-SOKLog "TERMINATING ERROR in SOK-METICUL.OS: $($_.Exception.Message)" -Level Error
    Write-SOKLog "Stack trace: $($_.ScriptStackTrace)" -Level Debug
} finally {
    $totalDuration = [math]::Round(((Get-Date) - $GlobalStartTime).TotalSeconds, 1)
    $ramFinal      = try { (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory } catch { 0 }
    $ramNetMB      = [math]::Round(($ramFinal - $ramBefore) / 1KB, 0)

    Write-SOKLog '' -Level Ignore
    Write-SOKLog "═══════════════════════════════════════════════════════════" -Level Section
    Write-SOKLog "  SOK-METICUL.OS v2.0.0 — COMPLETE" -Level Section
    Write-SOKLog "  Total duration : ${totalDuration}s" -Level Section
    Write-SOKLog "  Modules run    : $($ActiveModules.Count)" -Level Section
    Write-SOKLog "  RAM delta      : $(if($ramNetMB -ge 0){"+$ramNetMB"}else{"$ramNetMB"}) MB" -Level Section
    Write-SOKLog "  DryRun         : $($DryRun.IsPresent)" -Level Section
    Write-SOKLog "═══════════════════════════════════════════════════════════" -Level Section

    # ── GlobalState artifacts summary ─────────────────────────────────────────
    Write-SOKLog "GlobalState keys populated this run:" -Level Ignore
    foreach ($key in ($GlobalState.Keys | Sort-Object)) {
        $val     = $GlobalState[$key]
        $summary = if ($val -is [System.Collections.ICollection]) { "[$($val.Count) items]" }
                   elseif ($val -is [string]) { $val }
                   else { $val.ToString().Substring(0, [math]::Min($val.ToString().Length, 80)) }
        Write-SOKLog "  $key = $summary" -Level Ignore
    }

    # ── Architectural verdict ─────────────────────────────────────────────────
    Write-SOKLog '' -Level Ignore
    Write-SOKLog "ARCHITECTURAL VERDICT:" -Level Section
    Write-SOKLog "  + $($GlobalState.Keys.Count) shared keys available in-process across all 18 modules" -Level Ignore
    Write-SOKLog "  + Inventory_JunctionMap → Offload: junction check via GlobalState (no JSON read)" -Level Ignore
    if ($GlobalState.ContainsKey('SpaceAudit_Offloadable')) {
        $offGB = [math]::Round((($GlobalState['SpaceAudit_Offloadable'] | Measure-Object SizeKB -Sum).Sum) / 1MB, 2)
        Write-SOKLog "  + SpaceAudit_Offloadable ($offGB GB) flowed to Offload without disk I/O" -Level Ignore
    }
    Write-SOKLog "  - Full 18-module run is one atomic process — partial failure can stop everything" -Level Warn
    Write-SOKLog "  - Cannot schedule PAST at 02:00 and FUTURE independently at 04:00" -Level Warn
    Write-SOKLog "  - A 30-min Maintenance stall blocks Archive from running" -Level Warn
    Write-SOKLog "  - Combined param surface is unwieldy (~50 params vs ~15 per distributed script)" -Level Warn
    Write-SOKLog "  CONCLUSION: In-memory sharing wins for interactive on-demand runs." -Level Section
    Write-SOKLog "  CONCLUSION: Distributed wins for nightly scheduled automation." -Level Section
    Write-SOKLog "  See SOK-FamilyPicture.ps1 for the definitive architectural write-up." -Level Ignore

    if ($DryRun) { Write-SOKLog "DRY RUN — zero persistent disk changes made." -Level Warn }

    Save-SOKHistory -ScriptName 'SOK-METICUL.OS' -RunData @{
        Duration        = $totalDuration
        ModuleCount     = $ActiveModules.Count
        GlobalStateKeys = $GlobalState.Keys.Count
        DryRun          = $DryRun.IsPresent
        RamDeltaMB      = $ramNetMB
    }
}
