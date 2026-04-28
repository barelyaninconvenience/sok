#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-PAST v1.1.1 — The Archaeologist & Fixer
    Temporal Domain: Historical State, Accumulated Debt, Structural Reconciliation

.DESCRIPTION
    SOK-PAST is the first of three temporal meta-scripts. It consolidates six scripts
    that all answer one operational question: "What happened, and how do we reconcile it?"

    WHY THREE META-SCRIPTS INSTEAD OF ONE MONOLITH?
    The temporal design preserves logical isolation while enabling in-memory pipeline
    chaining. When -TakeInventory and -AuditSpace run together, Inventory's drive
    topology and junction map are deposited into $GlobalState and consumed directly
    by SpaceAudit — eliminating a redundant full-disk enumeration (~11 seconds saved).
    Cross-script handoffs (PAST → FUTURE) use JSON telemetry via Get-LatestLogPath.

    WHY THIS TEMPORAL SLICE?
    These six modules look BACKWARD. They analyze what the system accumulated over
    time — which packages are installed, where storage debt lives, what changed
    between two states, which structures are broken. Safe to run offline, low-memory,
    or right after a cold boot. They READ more than they WRITE. Destructive actions
    (BackupRestructure, Flatten) require explicit flags and preferably -DryRun first.

    INTEGRATED MODULES (run in this order when -All is specified):
    1. InfraFix       — One-shot repairs of known broken junctions/shims (always first)
    2. Inventory      — Full system snapshot: packages, drives, junctions, runtimes,
                        services, pip packages, winget packages (Caliber 2+)
    3. SpaceAudit     — Parallel disk classification (KEEP/CLEAN/OFFLOAD/INVESTIGATE)
    4. Restructure    — Identify excessive nesting, flattened paths, recursive backups
    5. CompareSnaps   — Line-level diff of two SOK-Archiver snapshots
    6. BkupRestruc    — Extract/merge E:\Backup_Archive with derivation tagging

    v1.1.1 CHANGES:
    - FIX: BackupRestructure Phase 1 gate changed from -SkipDeletion (opt-out, ran by default)
           to -RunPhase1 (opt-in, skipped by default) — now matches BackupRestructure.ps1 v2.0.0
           semantics. Prior behavior ran Phase 1 (delete raw folders) by default, which was
           inconsistent with the standalone script's explicit opt-in design.

    v1.1.0 CHANGES:
    - BUG: goto endCompare → do/while + break (PowerShell has no goto)
    - BUG: InfraFix FIX-4 condition -or $true (always fired) → correct Test-Path guard
    - BUG: SpaceAudit parallel block: function reference across runspace boundary replaced
           with inline regex application using $using:rx* variables (functions don't
           transfer to -Parallel runspaces — classification was silently returning nothing)
    - BUG: SpaceAudit file sizing now recursive (was shallow — only direct files counted)
    - BUG: Save-SOKHistory calls now pass Duration key (history aggregates were empty)
    - BUG: InfraFix nvm target was hardcoded v24.14.0 — now dynamically detected
    - ADD: Inventory now captures winget packages (Caliber 2+)
    - ADD: Inventory now captures pip packages via py -3.14 (Caliber 2+)
    - ADD: Inventory now captures running services snapshot (Caliber 2+)
    - ADD: InfraFix: scoop shim repair (parallel to BareMetal FIX-100)
    - UPD: $GlobalState created via New-SOKStateDict from Common
    - UPD: Uses Get-LatestLogPath where only path is needed

.EXAMPLE
    .\SOK-PAST.ps1 -TakeInventory -ScanCaliber 3 -AuditSpace
    Full deep inventory + space classification. In-memory pipeline skips re-enumeration.

.EXAMPLE
    .\SOK-PAST.ps1 -FixStructure -RestructureTargets "E:\Backup_Archive" -RestructureAction Flatten -DryRun
    Preview flatten without changes.

.EXAMPLE
    .\SOK-PAST.ps1 -CompareSnapshots -OldSnapshot "...\SOK_Archive_v9.txt" -NewSnapshot "...\SOK_Archive_v10.txt"
    Diff two archive snapshots with symbolic grammar.

.EXAMPLE
    .\SOK-PAST.ps1 -All -DryRun
    Preview full PAST run without any disk mutations.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # ── GLOBAL ─────────────────────────────────────────────────────────────────
    # DryRun spans ALL modules. No persistent changes are made. Use first on any
    # new machine or before any destructive operation.
    [switch]$DryRun,

    # ── MODULE ACTIVATION (opt-in, backward compat) ───────────────────────────
    # These flags still work. If NONE of these are set, the default is full-run
    # (progressive enclosure). Use -Skip* flags to narrow the default.
    [switch]$FixInfra,           # SOK-InfraFix:          repair known broken junctions/shims
    [switch]$TakeInventory,      # SOK-Inventory:         full system snapshot to JSON
    [switch]$AuditSpace,         # SOK-SpaceAudit:        classify C:\ by space verdict
    [switch]$FixStructure,       # SOK-Restructure:       identify structural debt
    [switch]$CompareSnapshots,   # SOK-Comparator:        diff two archive .txt snapshots (requires -OldSnapshot/-NewSnapshot)
    [switch]$RestructureBackups, # SOK-BackupRestructure: extract + merge E:\Backup_Archive
    # -All: force all modules (ignores -Skip* flags).
    [switch]$All,
    # ── MODULE SKIP (progressive enclosure) ───────────────────────────────────
    # Narrow the default full run. Only applies when no opt-in flags are set.
    [switch]$SkipInfraFix,          # Exclude SOK-InfraFix from default run
    [switch]$SkipInventory,         # Exclude SOK-Inventory from default run
    [switch]$SkipSpaceAudit,        # Exclude SOK-SpaceAudit from default run
    [switch]$SkipRestructure,       # Exclude SOK-Restructure from default run
    [switch]$SkipBackupRestructure, # Exclude SOK-BackupRestructure from default run

    # ── INVENTORY PARAMS ───────────────────────────────────────────────────────
    # ScanCaliber 1 = Quick  (~5s): packages only — good for automated daily runs
    # ScanCaliber 2 = Standard (~20s): + junction map, services, all package managers
    # ScanCaliber 3 = Deep   (~90s): + SHA-256 hashes of critical binaries (forensics)
    [ValidateRange(1, 3)]
    [int]$ScanCaliber = 2,
    [string]$InventoryOutputPath,   # Override timestamped output path

    # ── SPACE AUDIT PARAMS ─────────────────────────────────────────────────────
    # MinSizeKB: only report directories above this size. Default ~20MB.
    # Prevents noise from thousands of tiny system dirs.
    [int]$MinSizeKB    = 21138,
    # ScanDepth: max directory depth. Beyond 21 is generally backup artifact noise.
    [int]$ScanDepth    = 21,
    # ThrottleLimit: parallel threads. 13 = reserve 7 logical cores for foreground
    # on i7-13700H (20 logical cores total).
    [int]$ThrottleLimit = 13,

    # ── COMPARATOR PARAMS ──────────────────────────────────────────────────────
    [string]$OldSnapshot,
    [string]$NewSnapshot,
    # If %diff exceeds this threshold, operator must confirm before report writes.
    # 16.66% = 1/6 of files changed — signals architectural shift, not incremental.
    [double]$AutoApproveThreshold = 16.66,
    [string]$ComparatorOutputDir  = "$env:USERPROFILE\Documents\Journal\Projects\SOK\Archives",

    # ── RESTRUCTURE PARAMS ─────────────────────────────────────────────────────
    [string[]]$RestructureTargets = @(
        "$env:USERPROFILE\Documents\Backup",
        "$env:USERPROFILE\Downloads"
    ),
    # Directories deeper than MaxDepth are flagged as excessively nested.
    [int]$MaxDepth = 13,
    # Report: analysis only. Flatten: actually restructure (always -DryRun first).
    [ValidateSet('Report', 'Flatten')]
    [string]$RestructureAction = 'Report',

    # ── BACKUP RESTRUCTURE PARAMS ──────────────────────────────────────────────
    [string]$ArchiveRoot  = 'E:\Backup_Archive',
    [string]$MergeTarget  = 'E:\Backup_Merged',
    # RunPhase1: activate Phase 1 (delete raw pre-extracted folders — most destructive; opt-in)
    [switch]$RunPhase1,
    # SkipExtraction: skip Phase 2 (7z extraction — time-consuming)
    [switch]$SkipExtraction,
    # SkipMerge: skip Phase 3 (merge with derivation tagging)
    [switch]$SkipMerge
)

# ══════════════════════════════════════════════════════════════════════════════
# [0] CORE INITIALIZATION
# ══════════════════════════════════════════════════════════════════════════════
$ErrorActionPreference = 'Continue'
$GlobalStartTime       = Get-Date

# Load SOK-Common — the shared logging, telemetry, and utility backbone.
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

$logPath = Initialize-SOKLog -ScriptName 'SOK-PAST'
$config  = Get-SOKConfig

# ── Full Disclosure / Progressive Enclosure gate ─────────────────────────────
# Default behavior: run ALL modules (full disclosure).
# -Skip* flags narrow the default. Explicit opt-in flags override the default
# and run only the specified modules (backward compatible with prior usage).
# -All forces all modules regardless of -Skip* flags.
$anyOptIn = $FixInfra.IsPresent -or $TakeInventory.IsPresent -or $AuditSpace.IsPresent -or
            $FixStructure.IsPresent -or $CompareSnapshots.IsPresent -or $RestructureBackups.IsPresent

if ($All) {
    # -All: force everything, ignore Skip flags
    $FixInfra = $TakeInventory = $AuditSpace = $FixStructure = $RestructureBackups = $true
} elseif (-not $anyOptIn) {
    # No opt-in specified — full disclosure: activate all unless explicitly skipped
    if (-not $SkipInfraFix)          { $FixInfra            = $true }
    if (-not $SkipInventory)         { $TakeInventory        = $true }
    if (-not $SkipSpaceAudit)        { $AuditSpace           = $true }
    if (-not $SkipRestructure)       { $FixStructure         = $true }
    if (-not $SkipBackupRestructure) { $RestructureBackups   = $true }
    # CompareSnapshots always requires -OldSnapshot/-NewSnapshot — never in default run
}

$ActiveModules = @()
if ($FixInfra)           { $ActiveModules += 'InfraFix' }
if ($TakeInventory)      { $ActiveModules += 'Inventory' }
if ($AuditSpace)         { $ActiveModules += 'SpaceAudit' }
if ($FixStructure)       { $ActiveModules += 'Restructure' }
if ($CompareSnapshots)   { $ActiveModules += 'CompareSnapshots' }
if ($RestructureBackups) { $ActiveModules += 'BackupRestructure' }

if ($ActiveModules.Count -eq 0) {
    Write-SOKLog 'All modules skipped via -Skip* flags. Nothing to run.' -Level Warn
    exit 0
}

Show-SOKBanner -ScriptName 'SOK-PAST' `
    -Subheader "Active: $($ActiveModules -join ' | ')$(if ($DryRun) {' [DRY RUN]'})"
Write-SOKLog "Temporal Domain: PAST — Historical State, Debt Reconciliation, Structural Analysis" -Level Section

# In-memory pipeline state. Modules write results here; downstream modules
# in the same invocation read from it without re-hitting disk.
# Cross-invocation handoffs (PAST → FUTURE in separate runs) use Get-LatestLogPath.
$GlobalState = New-SOKStateDict

try {
# ══════════════════════════════════════════════════════════════════════════════
# [1] INFRAFIX — One-Shot Environmental Repairs
# ══════════════════════════════════════════════════════════════════════════════
# InfraFix runs FIRST — broken junctions make downstream modules report incorrect
# results. A broken nvm junction makes Node.js appear absent in Inventory. The
# UC OneDrive orphan causes robocopy errors in Offload/PreSwap. Repairing these
# before any read operation ensures clean baselines.
#
# These are KNOWN, NAMED issues specific to <HOST> derived from documented
# incidents (v4 crisis, SOK-BareMetal FIX-100, post-reinstall patterns).
# InfraFix does not dynamically discover issues — it has a fixed repair list.
# New incidents → new named FIX entries here.
if ($FixInfra) {
    Write-SOKLog '━━━ [1] INFRAFIX: One-Shot Environmental Repairs ━━━' -Level Section
    if ($DryRun) { Write-SOKLog '*** DRY RUN — no changes will be made ***' -Level Warn }
    $infraFixed = 0; $infraSkipped = 0; $infraFailed = 0

    # ── FIX 1: nvm4w junction — Node Version Manager for Windows ────────────
    # nvm4w maintains a junction C:\nvm4w\nodejs -> the active Node.js version dir.
    # This junction breaks silently when nvm switches versions (the link stays
    # pointing at the old version path). Dynamically detect the current active
    # version rather than hardcoding (v1.0 had v24.14.0 hardcoded — brittle).
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
        Write-SOKLog "SKIP nvm4w: no versioned dir found under $nvmDir (nvm may not be installed)" -Level Warn
        $infraSkipped++
    }

    # ── FIX 2: OneDrive UC orphan ────────────────────────────────────────────
    # After leaving UC SSO or re-provisioning OneDrive, "OneDrive - University of
    # Cincinnati" becomes an orphaned reparse point with no valid target. It causes
    # "path does not exist" errors in robocopy and backup operations.
    # rmdir on a junction removes only the link, not the data — safe.
    $odPath = 'C:\Users\shelc\OneDrive - University of Cincinnati'
    if (Test-Path $odPath) {
        $odAttr = [System.IO.File]::GetAttributes($odPath)
        if ($odAttr -band [System.IO.FileAttributes]::ReparsePoint) {
            if ($DryRun) {
                Write-SOKLog "[DRY] Would remove orphaned UC OneDrive junction: $odPath" -Level Ignore
            } else {
                cmd /c "rmdir `"$odPath`"" 2>$null | Out-Null
                if (-not (Test-Path $odPath)) {
                    Write-SOKLog "Removed orphaned UC OneDrive junction: $odPath" -Level Success; $infraFixed++
                } else {
                    Write-SOKLog "Could not remove UC OneDrive junction (manual rmdir required)" -Level Warn; $infraFailed++
                }
            }
        } else {
            Write-SOKLog "SKIP UC OneDrive: exists but is NOT a reparse point — manual review" -Level Warn
            $infraSkipped++
        }
    } else {
        Write-SOKLog "SKIP UC OneDrive: path absent (already clean)" -Level Ignore
    }

    # ── FIX 3: Kibana node.exe shim ─────────────────────────────────────────
    # Kibana's Chocolatey installer drops a ~100-byte node.exe shim into the choco
    # bin directory. This shim intercepts ALL 'node' CLI invocations system-wide,
    # breaking nvm4w's ability to delegate to the correct Node version.
    # Detection heuristic: real node.exe is 40-70 MB; a shim is < 256 KB.
    $kibanaShim = 'C:\ProgramData\chocolatey\bin\node.exe'
    if (Test-Path $kibanaShim) {
        $shimSize = (Get-Item $kibanaShim -ErrorAction SilentlyContinue).Length
        if ($shimSize -lt 256KB) {
            if ($DryRun) {
                Write-SOKLog "[DRY] Would rename Kibana node shim: $kibanaShim ($([math]::Round($shimSize/1KB,1)) KB)" -Level Ignore
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
    # SOK v3 and earlier wrote history to SOK\History\. v4+ moved this to
    # SOK\Deprecated\History\. The old path causes log rotation conflicts.
    $legacyHistory    = Join-Path $env:USERPROFILE 'Documents\Journal\Projects\SOK\History'
    $deprecatedHistory = Join-Path $env:USERPROFILE 'Documents\Journal\Projects\SOK\Deprecated\History'
    if (Test-Path $legacyHistory) {   # v1.0 had an erroneous -or $true here — fixed
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
    # Scoop shims can become broken when the shim file references a relative path
    # (..\..\apps\scoop\...) that resolves incorrectly from certain working dirs.
    # Running `scoop update` repairs shims in-place without reinstalling packages.
    # This mirrors BareMetal v5.4 FIX-100.
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
        Write-SOKLog "SKIP Scoop shim repair: scoop not found in PATH" -Level Warn
        $infraSkipped++
    }

    Write-SOKLog "InfraFix complete. Fixed: $infraFixed | Skipped: $infraSkipped | Failed: $infraFailed" -Level Success
    $GlobalState['InfraFix_Result'] = @{ Fixed = $infraFixed; Skipped = $infraSkipped; Failed = $infraFailed }
}

# ══════════════════════════════════════════════════════════════════════════════
# [2] INVENTORY — Full System Snapshot
# ══════════════════════════════════════════════════════════════════════════════
# SOK-Inventory is the foundation of the PAST→FUTURE pipeline.
# Its JSON output is consumed by SOK-FUTURE's Offload module (knows which
# junctions already exist, preventing redundant moves) and by SOK-PRESENT's
# Maintenance and RebootClean modules.
#
# ScanCaliber tiers balance completeness vs. runtime:
#   1 = Quick  (~5s):  drive topology + junction map
#   2 = Standard (~20s): + all package managers + runtimes + services
#   3 = Deep   (~90s): + SHA-256 file hashes for critical system binaries
#
# Caliber 3 is reserved for forensic snapshots and post-incident investigation.
# The Scheduler runs Caliber 2 nightly.
if ($TakeInventory) {
    Write-SOKLog '━━━ [2] INVENTORY: Full System Snapshot ━━━' -Level Section
    Write-SOKLog "ScanCaliber: $ScanCaliber (1=Quick / 2=Standard / 3=Deep)" -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN — snapshot generated in memory only ***' -Level Warn }

    $invStart = Get-Date
    $invData  = [ordered]@{
        CapturedAt   = (Get-Date -Format 'o')
        ScanCaliber  = $ScanCaliber
        Host         = $env:COMPUTERNAME
        User         = $env:USERNAME
        PSVersion    = $PSVersionTable.PSVersion.ToString()
    }

    # ── Drive Topology ──────────────────────────────────────────────────────
    # Physical disk serial numbers fingerprint drives across reboots. This lets
    # the junction map track which junctions point to E: vs. an absent drive.
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
    $invData['drive_topology'] = $driveTopology
    $GlobalState['Inventory_DriveTopology'] = $driveTopology

    # ── Junction Map ────────────────────────────────────────────────────────
    # Junction health is the most critical metric on <HOST>. The v4 crisis (10
    # broken junctions after E: hit 78%) was the origin event of the full SOK
    # suite. We scan 9 known roots — deeper scan would catch more but costs time.
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
                    $dirInfo    = [System.IO.DirectoryInfo]::new($dir)
                    $target     = if ($dirInfo.LinkTarget) { $dirInfo.LinkTarget } else { 'unknown' }
                    $broken     = -not (Test-Path $target -ErrorAction SilentlyContinue)
                    $crossDrive = ($broken -eq $false -and $target -match '^[A-Z]:' -and $target[0] -ne $dir[0])
                    $junctionMap.Add(@{
                        Source      = $dir
                        Target      = $target
                        Broken      = $broken
                        CrossDrive  = $crossDrive
                    })
                    if ($broken) { Write-SOKLog "  BROKEN: $dir -> $target" -Level Warn }
                }
            }
        } catch { Write-SOKLog "  Junction scan partial error ($root): $_" -Level Warn }
    }
    $invData['junction_map']    = $junctionMap
    $GlobalState['Inventory_JunctionMap'] = $junctionMap
    $brokenCount = @($junctionMap | Where-Object { $_.Broken }).Count
    $crossCount  = @($junctionMap | Where-Object { $_.CrossDrive }).Count
    Write-SOKLog "Junction map: $($junctionMap.Count) total | $brokenCount broken | $crossCount cross-drive" `
        -Level $(if ($brokenCount -gt 0) { 'Warn' } else { 'Success' })

    if ($ScanCaliber -ge 2) {
        # ── Chocolatey packages ──────────────────────────────────────────────
        # --local-only is the v2.x flag (--localonly is deprecated in v2)
        Write-SOKDivider "Package Managers (Caliber 2+)"
        $chocoPackages = @()
        if (Get-Command choco -ErrorAction SilentlyContinue) {
            $raw = choco list --limit-output --local-only 2>&1
            $chocoPackages = ($raw -split '\r?\n') | Where-Object { $_ -match '\|' } |
                ForEach-Object { $p = $_ -split '\|'; @{ Name = $p[0]; Version = $p[1] } }
            Write-SOKLog "  choco: $($chocoPackages.Count) packages" -Level Ignore
        }
        $invData['choco_packages'] = @{ Count = $chocoPackages.Count; Packages = $chocoPackages }
        $GlobalState['Inventory_ChocoPackages'] = $chocoPackages

        # ── Scoop packages (3-tier fallback) ─────────────────────────────────
        $scoopPackages = @()
        if (Get-Command scoop -ErrorAction SilentlyContinue) {
            $scoopExport = scoop export 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($scoopExport -and $scoopExport.apps) {
                $scoopPackages = $scoopExport.apps | ForEach-Object { @{ Name = $_.name; Version = $_.version } }
            } elseif (Test-Path "$env:USERPROFILE\scoop\apps") {
                # Directory scan fallback when scoop export is unavailable
                $scoopPackages = Get-ChildItem "$env:USERPROFILE\scoop\apps" -Directory |
                    ForEach-Object { @{ Name = $_.Name; Version = 'unknown' } }
            }
            Write-SOKLog "  scoop: $($scoopPackages.Count) packages" -Level Ignore
        }
        $invData['scoop_packages'] = @{ Count = $scoopPackages.Count; Packages = $scoopPackages }

        # ── Winget packages ──────────────────────────────────────────────────
        # winget list --source winget limits output to community repo installs,
        # filtering out MSI/MSIX apps that show up via the "winget" source.
        # v1.0 omitted this entirely — winget is the second-largest package manager.
        $wingetPackages = @()
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            $wgRaw = winget list --source winget 2>&1 | Select-Object -Skip 3  # Skip header
            $wingetPackages = $wgRaw | Where-Object { $_ -match '\S' } |
                ForEach-Object {
                    if ($_ -match '^(.+?)\s{2,}(\S+)\s{2,}(\S+)') {
                        @{ Name = $Matches[1].Trim(); Id = $Matches[2].Trim(); Version = $Matches[3].Trim() }
                    }
                } | Where-Object { $_ }
            Write-SOKLog "  winget: $($wingetPackages.Count) packages" -Level Ignore
        }
        $invData['winget_packages'] = @{ Count = $wingetPackages.Count; Packages = $wingetPackages }
        $GlobalState['Inventory_WingetPackages'] = $wingetPackages

        # ── pip packages (py -3.14) ───────────────────────────────────────────
        # py -3.14 explicitly to avoid Altair embedded Python collision.
        # v1.0 omitted this — pip is the primary ML/AI toolchain manager on <HOST>.
        $pipPackages = @()
        if (Get-Command py -ErrorAction SilentlyContinue) {
            $pipRaw = py -3.14 -m pip list --format=json 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($pipRaw) {
                $pipPackages = $pipRaw | ForEach-Object { @{ Name = $_.name; Version = $_.version } }
                Write-SOKLog "  pip (py -3.14): $($pipPackages.Count) packages" -Level Ignore
            }
        }
        $invData['pip_packages'] = @{ Count = $pipPackages.Count; Packages = $pipPackages }
        $GlobalState['Inventory_PipPackages'] = $pipPackages

        # ── Language runtimes ─────────────────────────────────────────────────
        Write-SOKDivider "Language Runtimes"
        $runtimes = @{}
        @(
            @{ Name='python'; Cmd='py';      Args=@('--version') }
            @{ Name='node';   Cmd='node';    Args=@('--version') }
            @{ Name='go';     Cmd='go';      Args=@('version')   }
            @{ Name='rustc';  Cmd='rustc';   Args=@('--version') }
            @{ Name='dotnet'; Cmd='dotnet';  Args=@('--version') }
            @{ Name='java';   Cmd='java';    Args=@('-version')  }
            @{ Name='ruby';   Cmd='ruby';    Args=@('--version') }
        ) | ForEach-Object {
            if (Get-Command $_.Cmd -ErrorAction SilentlyContinue) {
                $ver = (& $_.Cmd @($_.Args) 2>&1 | Select-Object -First 1) -replace '\r?\n',''
                $runtimes[$_.Name] = $ver
                Write-SOKLog "  $($_.Name): $ver" -Level Ignore
            }
        }
        $invData['runtimes'] = $runtimes
        $GlobalState['Inventory_Runtimes'] = $runtimes

        # ── Running services snapshot ─────────────────────────────────────────
        # Captures all Running services with their start type. This is consumed by
        # ServiceOptimizer (PRESENT) for baseline comparison and by diagnostic runs.
        Write-SOKDivider "Running Services"
        $runningServices = Get-Service -ErrorAction SilentlyContinue |
            Where-Object { $_.Status -eq 'Running' } |
            Select-Object -Property Name, DisplayName, StartType |
            ForEach-Object { @{ Name = $_.Name; Display = $_.DisplayName; Start = $_.StartType.ToString() } }
        $invData['running_services'] = @{ Count = $runningServices.Count; Services = $runningServices }
        $GlobalState['Inventory_RunningServices'] = $runningServices
        Write-SOKLog "  Services running: $($runningServices.Count)" -Level Ignore
    }

    if ($ScanCaliber -ge 3) {
        # ── Key binary file hashes (Caliber 3 — forensic/baseline) ──────────
        # SHA-256 hashes of critical binaries. Useful for detecting silent replacements
        # (supply chain compromise, corrupted reinstall, malicious shim injection).
        # Run after a fresh BareMetal restore to establish a clean baseline.
        Write-SOKDivider "Binary Hashes (Caliber 3)"
        $hashTargets = @(
            'C:\Windows\System32\cmd.exe'
            'C:\Windows\System32\powershell.exe'
            (Get-Command pwsh.exe -ErrorAction SilentlyContinue)?.Source
            (Get-Command python.exe -ErrorAction SilentlyContinue)?.Source
            (Get-Command node.exe -ErrorAction SilentlyContinue)?.Source
            (Get-Command git.exe -ErrorAction SilentlyContinue)?.Source
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

    # ── Save to disk ─────────────────────────────────────────────────────────
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
            PipCount        = if ($invData['pip_packages']) { $invData['pip_packages'].Count } else { 0 }
        }
    } else {
        Write-SOKLog "[DRY] Inventory complete (${invDuration}s). In-memory only." -Level Warn
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# [3] SPACE AUDIT — Parallel Disk Classification
# ══════════════════════════════════════════════════════════════════════════════
# SpaceAudit answers "where does the storage debt live?" using 13 parallel threads
# to enumerate C:\ and classify each directory:
#   KEEP        — System or user essentials; never touch
#   CLEAN       — Safe-to-delete regenerating caches
#   OFFLOAD     — Large toolchains safe to junction to E:
#   DB_OFFLOAD  — Database data dirs (move carefully; services must be stopped first)
#   INVESTIGATE — Anomalous patterns needing human review
#   UNKNOWN     — Unclassified (review if large)
#
# IN-MEMORY OPTIMIZATION:
# If -TakeInventory ran in this same invocation, drive topology and junction map
# are already in $GlobalState. SpaceAudit reads them to skip re-enumerating
# known junction paths during classification — avoiding re-traversal of symlinked
# subtrees that could inflate size counts or cause loops.
#
# PARALLEL FUNCTION NOTE (fixed v1.1.0):
# PS7 ForEach-Object -Parallel runs each block in a separate runspace. Functions
# defined in the outer scope are NOT available in parallel runspaces. v1.0 used
# $using:function:Get-SpaceVerdict which silently returned null. The fix is to
# pass the pre-compiled regex objects via $using: and apply them inline.
if ($AuditSpace) {
    Write-SOKLog '━━━ [3] SPACE AUDIT: Parallel Disk Classification ━━━' -Level Section
    Write-SOKLog "Parameters: MinSize=$MinSizeKB KB | Depth=$ScanDepth | Threads=$ThrottleLimit" -Level Ignore

    # Compile regexes ONCE before the parallel block — this is the correct place.
    # Pre-compilation with RegexOptions.Compiled amortizes JIT cost across millions
    # of path evaluations. These objects ARE safely transferable via $using:.
    $rxSystemEssential  = [regex]::new('(?ix)^C:\\Windows|^C:\\Recovery|\\(System32|SysWOW64|WinSxS|assembly|Microsoft\.NET)([\\]|$)|^C:\\\$|^C:\\Boot|^C:\\EFI|^C:\\PerfLogs|^C:\\System\sVolume\sInformation', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxUserEssential    = [regex]::new('(?ix)\\(Documents|Desktop|AppData\\Roaming\\Microsoft|\.ssh|\.gnupg|Journal)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxOffloadable      = [regex]::new('(?ix)\\(node_modules|\.nuget\\packages|\.cargo\\registry|\.pyenv|JetBrains|scoop\\apps|chocolatey\\lib|Docker\\wsl|Insomnia|GitKraken|Logseq|GitHubDesktop|Postman|Discord\\app-|Slack\\app-)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxDeletable        = [regex]::new('(?ix)\\(Temp|tmp|INetCache|Code\sCache|GPUCache|ShaderCache|CacheStorage|Cache\\Cache_Data|Crash\sReports|pip\\cache|yarn\\cache|D3DSCache)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxDatabaseData     = [regex]::new('(?ix)\\(postgresql\d*|MongoDB\\Server|neo4j\\data|redis\\data|influxdb\\data|mysql\\data)([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxSkipEnumeration  = [regex]::new('(?ix)^C:\\Documents\sand\sSettings|^C:\\System\sVolume\sInformation|^C:\\\$Recycle\.Bin|^C:\\\$WINDOWS|WinSxS|WindowsApps|WinREAgent', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $rxPotentiallyStale = [regex]::new('(?ix)\\(Package\sCache|\.old$|_backup|deprecated|\.bak$|uninstall|NuGet\\packages(?!\\Microsoft))([\\]|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)

    # ── Phase 1: Parallel Directory Enumeration ─────────────────────────────
    Write-SOKLog "Phase 1: Enumerating C:\ (parallel, $ThrottleLimit threads)..." -Level Ignore
    $allDirs  = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
    $topDirs  = try { [System.IO.Directory]::GetDirectories('C:\') } catch { @() }

    $topDirs | ForEach-Object -Parallel {
        $topPath   = $_
        $bag       = $using:allDirs
        $rxSkip    = $using:rxSkipEnumeration
        $maxDepth  = $using:ScanDepth
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

    # ── Phase 2: Recursive Size + Classification ────────────────────────────
    # Each directory is sized RECURSIVELY (all descendant files) — this gives the
    # true storage footprint of the directory subtree. Classification uses the
    # pre-compiled $using:rx* variables inline (functions cannot cross runspace
    # boundaries in PS7 ForEach-Object -Parallel).
    Write-SOKLog "Phase 2: Recursive sizing and classification (threshold $MinSizeKB KB)..." -Level Ignore
    $classified = [System.Collections.Concurrent.ConcurrentBag[hashtable]]::new()
    $sizeErrors = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

    $allDirs | ForEach-Object -Parallel {
        $dirPath   = $_
        $minKB     = $using:MinSizeKB
        $results   = $using:classified
        $errs      = $using:sizeErrors
        # Inline classification — receives pre-compiled regex objects via $using:
        $rxSys     = $using:rxSystemEssential
        $rxUser    = $using:rxUserEssential
        $rxDel     = $using:rxDeletable
        $rxDB      = $using:rxDatabaseData
        $rxOff     = $using:rxOffloadable
        $rxStale   = $using:rxPotentiallyStale
        try {
            # Recursive size enumeration: count ALL files under this dir
            $totalSize = 0L
            $fileOpts  = [System.IO.EnumerationOptions]::new()
            $fileOpts.IgnoreInaccessible    = $true
            $fileOpts.RecurseSubdirectories = $true   # FIXED: was false in v1.0
            foreach ($f in [System.IO.Directory]::EnumerateFiles($dirPath, '*', $fileOpts)) {
                try { $totalSize += (New-Object System.IO.FileInfo($f)).Length } catch { }
            }
            $sizeKB = [math]::Round($totalSize / 1KB, 0)
            if ($sizeKB -ge $minKB) {
                # Inline verdict (replaces Get-SpaceVerdict function call)
                $verdict = if     ($rxSys.IsMatch($dirPath))   { 'KEEP' }
                           elseif ($rxUser.IsMatch($dirPath))   { 'KEEP' }
                           elseif ($rxDel.IsMatch($dirPath))    { 'CLEAN' }
                           elseif ($rxDB.IsMatch($dirPath))     { 'DB_OFFLOAD' }
                           elseif ($rxOff.IsMatch($dirPath))    { 'OFFLOAD' }
                           elseif ($rxStale.IsMatch($dirPath))  { 'INVESTIGATE' }
                           else                                  { 'UNKNOWN' }
                $results.Add(@{
                    Path    = $dirPath
                    SizeKB  = $sizeKB
                    Verdict = $verdict
                    Depth   = ($dirPath -split '\\').Count - 1
                })
            }
        } catch { $errs.Add("$dirPath : $_") }
    } -ThrottleLimit $ThrottleLimit

    # ── Phase 3: Aggregate + Report ──────────────────────────────────────────
    $byVerdict = $classified | Group-Object Verdict
    $summary   = @{}
    foreach ($grp in $byVerdict) {
        $totalGB = [math]::Round(($grp.Group | Measure-Object SizeKB -Sum).Sum / 1MB, 2)
        $summary[$grp.Name] = @{ Count = $grp.Count; TotalGB = $totalGB }
        Write-SOKLog "  $($grp.Name.PadRight(12)) $($grp.Count) dirs   $totalGB GB" `
            -Level $(if ($grp.Name -in 'CLEAN','OFFLOAD','DB_OFFLOAD') { 'Warn' } else { 'Ignore' })
    }

    # Deposit categorized results into GlobalState for FUTURE's Offload module.
    # If SOK-FUTURE -Offload runs in the same session, it can use these directly
    # instead of enumerating C:\ from scratch (~15-20 seconds saved).
    $offloadable = @($classified | Where-Object { $_.Verdict -in 'OFFLOAD','DB_OFFLOAD' } | Sort-Object SizeKB -Descending)
    $cleanable   = @($classified | Where-Object { $_.Verdict -eq 'CLEAN' } | Sort-Object SizeKB -Descending)
    $GlobalState['SpaceAudit_Offloadable'] = $offloadable
    $GlobalState['SpaceAudit_Cleanable']   = $cleanable
    Write-SOKLog "Pipeline: $($offloadable.Count) offloadable ($([math]::Round(($offloadable | Measure-Object SizeKB -Sum).Sum/1MB,1)) GB) + $($cleanable.Count) cleanable dirs in GlobalState." -Level Success

    if (-not $DryRun) {
        $auditOutDir = Get-ScriptLogDir -ScriptName 'SOK-SpaceAudit'
        $ts          = Get-Date -Format 'yyyyMMdd_HHmmss'
        $reportPath  = Join-Path $auditOutDir "SpaceAudit_Report_$ts.json"
        @{
            GeneratedAt        = (Get-Date -Format 'o')
            MinSizeKB          = $MinSizeKB
            ScanDepth          = $ScanDepth
            TotalDirsScanned   = $allDirs.Count
            TotalDirsClassified= $classified.Count
            Summary            = $summary
            Offloadable        = ($offloadable | Select-Object -First 100)
            Cleanable          = ($cleanable   | Select-Object -First 100)
            Errors             = @($sizeErrors  | Select-Object -First 50)
        } | ConvertTo-Json -Depth 6 | Out-File $reportPath -Encoding utf8 -Force
        Write-SOKLog "SpaceAudit report: $reportPath" -Level Success
        $GlobalState['SpaceAudit_ReportPath'] = $reportPath
        Save-SOKHistory -ScriptName 'SOK-SpaceAudit' -RunData @{
            Duration         = 0   # calculated in finally
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
# Backup storage accumulates structural debt: directories become excessively nested
# (Backup\Backup\2024_Seagate\Backup\...), folder names get flattened by robocopy
# path-length workarounds (C_Users_shelc_Documents_...), the same subfolder appears
# dozens of times across different backup roots, and the 2020-era Seagate backups
# contain entire development environment caches (Eclipse, Anaconda, MathJax).
# See SOK\Writings\Restructure-Analysis.md for the full case study.
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
    $nameMap     = [System.Collections.Generic.Dictionary[string, int]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $totalScanned = 0

    foreach ($target in $RestructureTargets) {
        if (-not (Test-Path $target)) {
            Write-SOKLog "SKIP: $target not found" -Level Warn; continue
        }
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

            # ── Excessive nesting ──────────────────────────────────────────
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

            # ── Recursive backup patterns ──────────────────────────────────
            if ($relative -match '(?i)(backup.*\\.*backup|C_\\|20\d{2}\s+(Seagate|Laptop|Desktop)\s+Backup)') {
                $restructureResults.RecursiveBackups.Add(@{ Path=$dir; Depth=$depth; Pattern=$Matches[0] })
                Write-SOKLog "  Recursive backup '$($Matches[0])': $dir" -Level Warn
            }

            # ── Flattened paths ────────────────────────────────────────────
            # Robocopy with /256 sometimes renames deeply-nested paths by replacing
            # backslashes with underscores. These are identifiable by the pattern.
            if ($dirName -match '^[A-Z]_' -or $dirName -match '_(Users|Program.Files|AppData|ProgramData)_') {
                $restructureResults.FlattenedPaths.Add(@{ Path=$dir; Name=$dirName })
                Write-SOKLog "  Flattened path: $dirName" -Level Annotate
            }

            # ── Duplicate name tracking ────────────────────────────────────
            $shortName = $dirName.ToLower()
            if ($nameMap.ContainsKey($shortName)) { $nameMap[$shortName]++ }
            else { $nameMap[$shortName] = 1 }
        }
    }

    # Names appearing 3+ times warrant review (likely backup redundancy)
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
# SOK-Comparator diffs two SOK-Archiver flat-file snapshots using a streaming
# 1MB-buffer approach to handle archives that can be 50MB+.
#
# Symbolic grammar:
#   [+] Addition  — file present in NEW only
#   [-] Subtraction — line removed
#   [x] Rescinded — file present in OLD only (deleted or renamed)
#   [*] Revision  — file appears in both, content differs
#   [~] Mixed     — both additions and deletions in the revision
#
# SAFETY: The AutoApproveThreshold (default 16.66%) gates automatic report writing.
# Volatility above this requires explicit operator confirmation — because 16.66%
# delta (1/6 of files changed) typically indicates architectural refactoring, not
# routine development, and should be reviewed before accepting as a baseline.
if ($CompareSnapshots) {
    Write-SOKLog '━━━ [5] COMPARE SNAPSHOTS: Archive Differential Analysis ━━━' -Level Section

    # Use do/while $false as a structured early-exit block.
    # This replaces the v1.0 goto endCompare (PowerShell has no goto statement).
    do {
        if (-not $OldSnapshot -or -not $NewSnapshot) {
            Write-SOKLog 'CompareSnapshots requires both -OldSnapshot and -NewSnapshot.' -Level Error
            Write-SOKLog 'Example: -OldSnapshot "...\SOK_Archive_v9.txt" -NewSnapshot "...\SOK_Archive_v10.txt"' -Level Warn
            break
        }
        if (-not (Test-Path $OldSnapshot)) {
            Write-SOKLog "OldSnapshot not found: $OldSnapshot" -Level Error; break
        }
        if (-not (Test-Path $NewSnapshot)) {
            Write-SOKLog "NewSnapshot not found: $NewSnapshot" -Level Error; break
        }

        Write-SOKLog "Old: $OldSnapshot ($([math]::Round((Get-Item $OldSnapshot).Length/1MB,1)) MB)" -Level Ignore
        Write-SOKLog "New: $NewSnapshot ($([math]::Round((Get-Item $NewSnapshot).Length/1MB,1)) MB)" -Level Ignore

        # Build index maps via streaming — avoids loading 50MB archives into memory.
        # Each archive has sections: # FILE: <path> ... (content lines) ...
        # We map file paths to {start, end} line ranges, then seek into the file
        # for specific chunks only when comparing a particular file.
        function Get-ArchiveIndex {
            param([string]$Path)
            $index = @{}; $currentFile = $null; $startLine = 0; $lineNum = 0
            $reader = [System.IO.StreamReader]::new($Path)
            try {
                while (($line = $reader.ReadLine()) -ne $null) {
                    $lineNum++
                    if ($line -match '^# FILE: (.+)$') {
                        if ($currentFile) { $index[$currentFile] = @{ Start = $startLine; End = $lineNum - 1 } }
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

        # ── Differential analysis ─────────────────────────────────────────────
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

        # ── Threshold gate ────────────────────────────────────────────────────
        $maxLines = [math]::Max($oldIdx.TotalLines, $newIdx.TotalLines)
        $pctDiff  = if ($maxLines -gt 0) { [math]::Round(($stats.TotalChanges / $maxLines) * 100, 2) } else { 0 }
        Write-SOKLog "Volatility: $pctDiff% ($($stats.TotalChanges) changes / $maxLines lines)" `
            -Level $(if ($pctDiff -gt $AutoApproveThreshold) {'Warn'} else {'Success'})

        if ($pctDiff -ge 100) {
            Write-SOKLog "ABORT: Archives appear completely disjoint (100% volatility). Verify file paths." -Level Error
            break
        }

        if ($pctDiff -gt $AutoApproveThreshold -and -not $DryRun) {
            $confirm = Read-Host "Volatility $pctDiff% exceeds threshold $AutoApproveThreshold%. Write report? (Y/N)"
            if ($confirm -notmatch '^[Yy]') { Write-SOKLog "Report cancelled by operator." -Level Warn; break }
        }

        if (-not $DryRun) {
            if (-not (Test-Path $ComparatorOutputDir)) {
                New-Item -Path $ComparatorOutputDir -ItemType Directory -Force | Out-Null
            }
            # Abbreviate snapshot names in diff filename to avoid MAX_PATH issues
            $oldShort = [System.IO.Path]::GetFileNameWithoutExtension($OldSnapshot) -replace '.{0,30}$','...'
            $newShort = [System.IO.Path]::GetFileNameWithoutExtension($NewSnapshot) -replace '.{0,30}$','...'
            # Safer approach: use timestamps instead of file names for the diff filename
            $diffPath = "$ComparatorOutputDir\SOK_Diff_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            $v = 1
            while (Test-Path $diffPath) { $diffPath = "$ComparatorOutputDir\SOK_Diff_$(Get-Date -Format 'yyyyMMdd_HHmmss')_v$v.txt"; $v++ }

            # M-6 (Cluster C) consistency 2026-04-22: 1MB → 128KB
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
# BackupRestructure transforms E:\Backup_Archive through three phases:
#   Phase 1: Delete raw (pre-extracted) folder duplicates — robocopy /MIR fast-delete
#   Phase 2: Extract .7z archives in-place — 7z with overwrite rules
#   Phase 3: Merge extracted content to E:\Backup_Merged with derivation tagging
#
# DERIVATION TAGS prevent merge collisions by encoding origin in folder names:
#   _a1 = 2020 Seagate backup #1 (Shelby's 2021 laptop backup)
#   _a2 = 2020 Seagate backup #2 (Shelby's 2021 desktop backup)
#   _b  = 2025 generic backup
#   _c  = 13JUL2025 timestamped backup
#   _d  = mommaddell backup (different origin machine)
#
# PHASE CONTROL:
#   -RunPhase1:      activate Phase 1 — SKIPPED BY DEFAULT (opt-in, matches BackupRestructure.ps1 v2.0.0)
#   -SkipExtraction: skip Phase 2
#   -SkipMerge:      skip Phase 3
#
# SAFETY: Phase 1 uses robocopy /MIR — it DELETES content that isn't in the
# source (an empty temp dir). Always -DryRun first. Confirm before Phase 1.
if ($RestructureBackups) {
    Write-SOKLog '━━━ [6] BACKUP RESTRUCTURE: Archive Extraction & Merge ━━━' -Level Section
    Write-SOKLog "Archive root: $ArchiveRoot | Merge target: $MergeTarget" -Level Ignore
    if ($DryRun) { Write-SOKLog '*** DRY RUN — no deletions or extractions ***' -Level Warn }

    # Locate 7-Zip binary — required for extraction
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

    # ── Phase 1: Delete raw folder duplicates ────────────────────────────────
    if ($RunPhase1 -and (Test-Path $ArchiveRoot)) {
        Write-SOKDivider "Phase 1: Delete Pre-Extracted Raw Folders"
        Write-SOKLog "Scanning $ArchiveRoot for raw folder duplicates..." -Level Ignore

        # A raw folder is one that has a corresponding .7z archive — it's a
        # pre-extraction artifact that wastes space by duplicating the archive content.
        $rawFolders = Get-ChildItem $ArchiveRoot -Directory -ErrorAction SilentlyContinue |
            Where-Object { -not $_.Name.EndsWith('.7z') }

        foreach ($folder in $rawFolders) {
            $sevenZ = Join-Path $ArchiveRoot "$($folder.Name).7z"
            if (Test-Path $sevenZ) {
                Write-SOKLog "  Raw (has .7z): $($folder.Name)" -Level Warn
                if ($DryRun) {
                    Write-SOKLog "  [DRY] Would delete: $($folder.FullName)" -Level Ignore
                } else {
                    # robocopy /MIR to empty temp = fastest reliable deep deletion.
                    # Avoids Remove-Item MAX_PATH failures on deeply nested backup trees.
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

    # ── Phase 2: Extract .7z archives ────────────────────────────────────────
    if (-not $SkipExtraction -and $sevenZip -and (Test-Path $ArchiveRoot)) {
        Write-SOKDivider "Phase 2: Extract .7z Archives"
        $archives = Get-ChildItem $ArchiveRoot -Filter '*.7z' -File -ErrorAction SilentlyContinue

        # Skip continuation volumes to avoid 7z double-processing multi-part archives
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
                } else {
                    Write-SOKLog "  7z exit ${LASTEXITCODE}: $($archive.Name)" -Level Error
                }
            }
        }
    }

    # ── Phase 3: Merge with derivation tagging ────────────────────────────────
    if (-not $SkipMerge -and (Test-Path $ArchiveRoot)) {
        Write-SOKDivider "Phase 3: Merge with Derivation Tags -> $MergeTarget"
        if (-not $DryRun -and -not (Test-Path $MergeTarget)) {
            New-Item -Path $MergeTarget -ItemType Directory -Force | Out-Null
        }

        $moved = 0; $renamed = 0; $failed = 0
        foreach ($src in (Get-ChildItem $ArchiveRoot -Directory -ErrorAction SilentlyContinue)) {
            $tag  = Get-DerivationTag $src.FullName
            $dest = Join-Path $MergeTarget $src.Name

            if (Test-Path $dest) {
                # Collision: append derivation tag, then counter if still colliding
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

# ══════════════════════════════════════════════════════════════════════════════
# END MODULES
# ══════════════════════════════════════════════════════════════════════════════
} catch {
    Write-SOKLog "TERMINATING ERROR in SOK-PAST: $($_.Exception.Message)" -Level Error
    Write-SOKLog "Stack trace: $($_.ScriptStackTrace)" -Level Debug
} finally {
    $duration = [math]::Round(((Get-Date) - $GlobalStartTime).TotalSeconds, 1)

    Write-SOKLog "━━━ SOK-PAST COMPLETE (${duration}s) ━━━" -Level Section
    if ($DryRun) { Write-SOKLog "DRY RUN — zero persistent disk changes." -Level Warn }

    # Surface GlobalState artifacts for operator review
    if ($GlobalState.ContainsKey('Inventory_OutputPath')) {
        Write-SOKLog "Inventory: $($GlobalState['Inventory_OutputPath'])" -Level Ignore
    }
    if ($GlobalState.ContainsKey('SpaceAudit_ReportPath')) {
        Write-SOKLog "SpaceAudit: $($GlobalState['SpaceAudit_ReportPath'])" -Level Ignore
    }
    if ($GlobalState.ContainsKey('SpaceAudit_Offloadable')) {
        $offGB = [math]::Round((($GlobalState['SpaceAudit_Offloadable'] | Measure-Object SizeKB -Sum).Sum) / 1MB, 2)
        Write-SOKLog "Offloadable capacity identified: $offGB GB — run SOK-FUTURE -Offload to act." -Level Warn
    }

    Write-SOKLog "Next: SOK-PRESENT -Optimize (live session) | SOK-FUTURE -Offload (act on SpaceAudit)" -Level Ignore

    Save-SOKHistory -ScriptName 'SOK-PAST' -RunData @{
        Duration   = $duration
        Modules    = $ActiveModules
        DryRun     = $DryRun.IsPresent
        ScanCalib  = $ScanCaliber
    }
}
