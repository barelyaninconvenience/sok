#Requires -Version 7.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    SOK-PAST-v2.ps1 v2.0.0 — Meta-level refactor of the PAST temporal meta-script.

.DESCRIPTION
    This version introduces abstractions native to the meta-level: temporal state,
    reconciliation, and historical truth. Rather than running tactical scripts, it asks:
    "What is the current state of this system?" (TruthSnapshot), "What debt has
    accumulated?" (DebtAnalysis), and "What happened this run?" (ReconciliationRecord).

    The pipeline is:
        TruthSnapshot → DebtAnalysis → ReconciliationRecord

    Meta-level abstractions introduced:

        Get-SystemTruth         — Collect the current observable state of the system
                                  (drives, junctions, packages, services, runtimes).
                                  Returns a single structured object. Replaces Inventory.

        Measure-AccumulatedDebt — Measure structural and storage debt across both
                                  SpaceAudit and Restructure domains. Returns a unified
                                  debt summary. "Debt" is a meta-level concept that spans
                                  storage and structure.

        New-HistoricalRecord    — Create a timestamped reconciliation record: what was
                                  found, what was fixed, what was flagged. This is the
                                  durable output artifact of a PAST run.

    Progressive enclosure is implemented at the meta-level. The question is:
    "Which aspects of historical truth are you capturing?" — not "which scripts run?"

    -All activates: ResolveInvariants + CaptureSystemTruth + MeasureDebt
    Skip flags exclude individual aspects from an -All run.
    CompareSnapshots and ConsolidateBackups are always explicit opt-in.

.PARAMETER DryRun
    If set, no destructive operations are performed.

.PARAMETER ResolveInvariants
    Fix known broken environmental invariants (InfraFix equivalent).

.PARAMETER CaptureSystemTruth
    Snapshot current system state via Get-SystemTruth.

.PARAMETER MeasureDebt
    Quantify accumulated storage + structural debt via Measure-AccumulatedDebt.

.PARAMETER All
    Activate all core aspects: ResolveInvariants + CaptureSystemTruth + MeasureDebt.

.PARAMETER SkipInvariantCheck
    When used with -All, skip ResolveInvariants.

.PARAMETER SkipTruthCapture
    When used with -All, skip CaptureSystemTruth.

.PARAMETER SkipDebtMeasurement
    When used with -All, skip MeasureDebt.

.PARAMETER CompareSnapshots
    Diff two SOK-Archiver flat-file snapshots. Requires -OldSnapshot and -NewSnapshot.

.PARAMETER ConsolidateBackups
    Transform E:\Backup_Archive through extraction and merge phases.

.PARAMETER ScanCaliber
    Truth capture depth: 1=drives+junctions, 2=+packages+services, 3=+SHA-256 hashes.

.PARAMETER InventoryOutputPath
    Override path for the system truth JSON output.

.PARAMETER MinSizeKB
    Minimum size for debt classification (default: 21138 KB ~= 20 MB).

.PARAMETER OldSnapshot
    Path to older SOK-Archiver snapshot file.

.PARAMETER NewSnapshot
    Path to newer SOK-Archiver snapshot file.

.PARAMETER AutoApproveThreshold
    % change that triggers confirmation gate (default: 16.66).

.PARAMETER ComparatorOutputDir
    Directory for CompareSnapshots diff output.

.PARAMETER RestructureTargets
    Directories to scan for structural debt.

.PARAMETER MaxDepth
    Maximum directory nesting depth threshold (default: 13).

.PARAMETER ArchiveRoot
    Source for ConsolidateBackups (default: E:\Backup_Archive).

.PARAMETER MergeTarget
    Merge destination for ConsolidateBackups (default: E:\Backup_Merged).

.PARAMETER RunPhase1
    Opt-in to Phase 1 of ConsolidateBackups (destructive).

.PARAMETER SkipExtraction
    Skip Phase 2 (extraction) of ConsolidateBackups.

.PARAMETER SkipMerge
    Skip Phase 3 (merge) of ConsolidateBackups.

.NOTES
    Author : SOK / <HOST>
    Version: 2.0.0
    Requires: PowerShell 7.0+, Run as Administrator
#>

param(
    [switch]$DryRun,

    # Meta-level aspect flags
    [switch]$ResolveInvariants,
    [switch]$CaptureSystemTruth,
    [switch]$MeasureDebt,
    [switch]$All,

    # Progressive enclosure skip flags (used with -All)
    [switch]$SkipInvariantCheck,
    [switch]$SkipTruthCapture,
    [switch]$SkipDebtMeasurement,

    # Explicit opt-in only (require external inputs or are destructive)
    [switch]$CompareSnapshots,
    [switch]$ConsolidateBackups,

    # Inventory / truth capture parameters
    [ValidateRange(1,3)][int]$ScanCaliber = 2,
    [string]$InventoryOutputPath = '',

    # Debt measurement parameters
    [int]$MinSizeKB = 21138,
    [string[]]$RestructureTargets = @("$env:USERPROFILE\Documents\Backup", "$env:USERPROFILE\Downloads"),
    [int]$MaxDepth = 13,

    # Snapshot comparison parameters
    [string]$OldSnapshot = '',
    [string]$NewSnapshot = '',
    [double]$AutoApproveThreshold = 16.66,
    [string]$ComparatorOutputDir = "$env:USERPROFILE\Documents\SOK\Archives",

    # Backup consolidation parameters
    [string]$ArchiveRoot   = 'E:\Backup_Archive',
    [string]$MergeTarget   = 'E:\Backup_Merged',
    [switch]$RunPhase1,
    [switch]$SkipExtraction,
    [switch]$SkipMerge
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# SOK-Common load — provides Write-SOKLog, Show-SOKBanner, Initialize-SOKLog,
# Get-ScriptLogDir, Save-SOKHistory. Inline stubs used as fallback.
# ---------------------------------------------------------------------------
$SOKCommonPath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1'

if (Test-Path $SOKCommonPath) {
    Import-Module $SOKCommonPath -Force -ErrorAction Stop
} else {
    Write-Warning "SOK-Common not found at $SOKCommonPath — using inline stubs."

    function Write-SOKLog {
        param([string]$Message, [string]$Level = 'INFO')
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Write-Host "[$ts][$Level] $Message"
    }
    function Show-SOKBanner   { param([string]$Title) Write-Host "=== $Title ===" }
    function Initialize-SOKLog { param([string]$ScriptName, [string]$LogDir) }
    function Get-ScriptLogDir  { return 'C:\Users\shelc\Documents\Journal\Projects\SOK\Logs' }
    function Save-SOKHistory   { param([string]$ScriptName, [hashtable]$Summary) }
}

# ---------------------------------------------------------------------------
# Script-level constants
# ---------------------------------------------------------------------------
$SCRIPT_NAME    = 'SOK-PAST-v2'
$SCRIPT_VERSION = '2.0.0'
$SOK_ROOT       = 'C:\Users\shelc\Documents\Journal\Projects\SOK'
$LOG_BASE       = "$SOK_ROOT\Logs"
$USER_PROFILE   = 'C:\Users\shelc'

# ---------------------------------------------------------------------------
# Progressive enclosure resolution
# If -All is set, activate all core aspects unless a Skip flag overrides them.
# This is the meta-level version of progressive enclosure: we are deciding which
# dimensions of historical truth this run will capture, not which scripts to run.
# ---------------------------------------------------------------------------
if ($All) {
    if (-not $SkipInvariantCheck)   { $ResolveInvariants  = $true }
    if (-not $SkipTruthCapture)     { $CaptureSystemTruth = $true }
    if (-not $SkipDebtMeasurement)  { $MeasureDebt        = $true }
}

# ===========================================================================
#
#  META-LEVEL ABSTRACTION 1: Get-SystemTruth
#
#  Collects the current observable state of the system without optimization.
#  This is the factual present-tense record of what the system IS right now.
#  It is the starting point for everything else in a PAST run.
#
#  Unlike Inventory (which is a module that writes a file), Get-SystemTruth
#  is a function that RETURNS a structured object. The caller decides what to
#  do with it. This separates observation from persistence.
#
#  The junction map is computed here once. Both Repair-SystemInvariants and
#  the output written by Save-TruthSnapshot can use the same junction map
#  without re-scanning. This is a meta-level optimization: the observation
#  "InfraFix and Inventory both need junctions" belongs at the meta-level.
#
# ===========================================================================
function Get-SystemTruth {
    [CmdletBinding()]
    param(
        [ValidateRange(1,3)][int]$ScanCaliber = 2
    )

    Write-SOKLog "Get-SystemTruth: Collecting system state. Caliber=$ScanCaliber" 'INFO'

    $truth = [ordered]@{
        CollectedAt   = (Get-Date -Format 'o')
        MachineName   = $env:COMPUTERNAME
        ScanCaliber   = $ScanCaliber
        Drives        = [System.Collections.Generic.List[hashtable]]::new()
        Junctions     = [System.Collections.Generic.List[hashtable]]::new()
        Packages      = [ordered]@{}
        Runtimes      = [ordered]@{}
        Services      = [System.Collections.Generic.List[hashtable]]::new()
        Hashes        = [ordered]@{}
    }

    # --- Drives ---
    $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue
    foreach ($drive in $drives) {
        $truth.Drives.Add(@{
            Name    = $drive.Name
            Root    = $drive.Root
            UsedGB  = [math]::Round($drive.Used / 1GB, 2)
            FreeGB  = [math]::Round($drive.Free / 1GB, 2)
            TotalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
        })
    }

    # --- Junctions ---
    # Collected once here. Both Repair-SystemInvariants and Save-TruthSnapshot
    # will reference this same map from the TruthSnapshot object.
    $junctionScanRoots = @('C:\', 'C:\Users\shelc', 'C:\ProgramData')
    foreach ($scanRoot in $junctionScanRoots) {
        if (-not (Test-Path $scanRoot)) { continue }
        $depthLimit = if ($scanRoot -eq 'C:\') { 3 } else { 5 }
        try {
            $items = Get-ChildItem -Path $scanRoot -Recurse -Directory -Depth $depthLimit `
                                   -ErrorAction SilentlyContinue -Force
            foreach ($item in $items) {
                if ($item.LinkType -eq 'Junction') {
                    $truth.Junctions.Add(@{
                        Path        = $item.FullName
                        Target      = $item.Target
                        TargetValid = (Test-Path $item.Target)
                    })
                }
            }
        } catch {
            Write-SOKLog "Get-SystemTruth: Junction scan error on $scanRoot : $_" 'WARN'
        }
    }
    Write-SOKLog "Get-SystemTruth: Junctions found: $($truth.Junctions.Count)" 'INFO'

    if ($ScanCaliber -ge 2) {
        # Packages
        $packageManagers = @(
            @{ Name = 'Chocolatey'; Cmd = 'choco';  Args = @('list','--local-only','--no-color');
               Parser = { param($lines)
                   $list = [System.Collections.Generic.List[hashtable]]::new()
                   foreach ($l in $lines) {
                       if ($l -match '^([^\s]+)\s+([\d\.]+)') {
                           $list.Add(@{ Name = $Matches[1]; Version = $Matches[2] })
                       }
                   }
                   $list
               }
            },
            @{ Name = 'Scoop'; Cmd = 'scoop'; Args = @('list');
               Parser = { param($lines)
                   $list = [System.Collections.Generic.List[hashtable]]::new()
                   foreach ($l in $lines) {
                       if ($l -match '^\s+(\S+)\s+([\d\.\w\-]+)') {
                           $list.Add(@{ Name = $Matches[1]; Version = $Matches[2] })
                       }
                   }
                   $list
               }
            },
            @{ Name = 'Pip'; Cmd = 'pip'; Args = @('list','--format=columns');
               Parser = { param($lines)
                   $list = [System.Collections.Generic.List[hashtable]]::new()
                   $headerPassed = $false
                   foreach ($l in $lines) {
                       if ($l -match '^-{3,}') { $headerPassed = $true; continue }
                       if (-not $headerPassed)  { continue }
                       $parts = $l -split '\s+' | Where-Object { $_ -ne '' }
                       if ($parts.Count -ge 2) { $list.Add(@{ Name = $parts[0]; Version = $parts[1] }) }
                   }
                   $list
               }
            },
            @{ Name = 'Npm'; Cmd = 'npm'; Args = @('list','-g','--depth=0');
               Parser = { param($lines)
                   $list = [System.Collections.Generic.List[hashtable]]::new()
                   foreach ($l in $lines) {
                       if ($l -match '[+\\`]-{2}\s+(.+?)@([\d\.\w\-]+)') {
                           $list.Add(@{ Name = $Matches[1]; Version = $Matches[2] })
                       }
                   }
                   $list
               }
            }
        )

        foreach ($pm in $packageManagers) {
            $cmd = Get-Command $pm.Cmd -ErrorAction SilentlyContinue
            if ($null -ne $cmd) {
                try {
                    $output = & $pm.Cmd @($pm.Args) 2>&1
                    $truth.Packages[$pm.Name] = & $pm.Parser $output
                    Write-SOKLog "Get-SystemTruth: $($pm.Name) packages: $($truth.Packages[$pm.Name].Count)" 'INFO'
                } catch {
                    Write-SOKLog "Get-SystemTruth: $($pm.Name) query failed: $_" 'WARN'
                    $truth.Packages[$pm.Name] = @()
                }
            } else {
                $truth.Packages[$pm.Name] = @()
            }
        }

        # Winget (separate handling due to header-skipping logic)
        $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
        $wingetList = [System.Collections.Generic.List[hashtable]]::new()
        if ($null -ne $wingetCmd) {
            try {
                $wgOutput     = & winget list --accept-source-agreements 2>&1
                $headerPassed = $false
                foreach ($wl in $wgOutput) {
                    if ($wl -match '^-{3,}') { $headerPassed = $true; continue }
                    if (-not $headerPassed -or $wl.Trim() -eq '') { continue }
                    $parts = $wl -split '\s{2,}' | Where-Object { $_ -ne '' }
                    if ($parts.Count -ge 3) {
                        $wingetList.Add(@{ Name = $parts[0]; Id = $parts[1]; Version = $parts[2] })
                    }
                }
            } catch {
                Write-SOKLog "Get-SystemTruth: winget query failed: $_" 'WARN'
            }
        }
        $truth.Packages['Winget'] = $wingetList

        # Runtimes
        $runtimeChecks = @(
            @{ Name = 'Node';   Cmd = 'node';   Args = @('--version') },
            @{ Name = 'Python'; Cmd = 'python'; Args = @('--version') },
            @{ Name = 'Java';   Cmd = 'java';   Args = @('-version')  },
            @{ Name = 'Ruby';   Cmd = 'ruby';   Args = @('--version') },
            @{ Name = 'Go';     Cmd = 'go';     Args = @('version')   },
            @{ Name = 'Rust';   Cmd = 'rustc';  Args = @('--version') },
            @{ Name = 'dotnet'; Cmd = 'dotnet'; Args = @('--version') }
        )
        foreach ($rt in $runtimeChecks) {
            $rtCmd = Get-Command $rt.Cmd -ErrorAction SilentlyContinue
            $truth.Runtimes[$rt.Name] = if ($null -ne $rtCmd) {
                try { (& $rt.Cmd @($rt.Args) 2>&1 | Out-String).Trim() }
                catch { "ERROR: $_" }
            } else { 'not found' }
        }

        # Services
        $services = Get-Service -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Running' }
        foreach ($svc in $services) {
            $truth.Services.Add(@{
                Name        = $svc.Name
                DisplayName = $svc.DisplayName
                Status      = $svc.Status.ToString()
                StartType   = $svc.StartType.ToString()
            })
        }
        Write-SOKLog "Get-SystemTruth: Running services: $($truth.Services.Count)" 'INFO'
    }

    if ($ScanCaliber -ge 3) {
        $hashTargets = @(
            'C:\nvm4w\nodejs\node.exe',
            'C:\ProgramData\chocolatey\bin\node.exe',
            'C:\Windows\System32\cmd.exe',
            'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
        )
        foreach ($ht in $hashTargets) {
            $truth.Hashes[$ht] = if (Test-Path $ht) {
                try { (Get-FileHash -Path $ht -Algorithm SHA256 -ErrorAction Stop).Hash }
                catch { "ERROR: $_" }
            } else { 'not found' }
        }
    }

    Write-SOKLog "Get-SystemTruth: Collection complete." 'INFO'
    return $truth
}

# ===========================================================================
#
#  META-LEVEL ABSTRACTION 2: Measure-AccumulatedDebt
#
#  Measures structural and storage debt across BOTH SpaceAudit and Restructure
#  domains and returns a unified DebtSummary. "Debt" is a genuine meta-level
#  concept: it spans both "how much space has accumulated that shouldn't be here"
#  (storage debt) and "how badly has the directory structure degraded" (structural
#  debt). Combining them into a single debt object is meaningful at the meta-level
#  because a PAST run wants to answer: "how much does this system owe cleanup-wise?"
#
# ===========================================================================
function Measure-AccumulatedDebt {
    [CmdletBinding()]
    param(
        [int]$MinSizeKB = 21138,
        [string[]]$RestructureTargets = @(),
        [int]$MaxDepth = 13,
        [System.Collections.Generic.List[hashtable]]$KnownJunctions = $null
    )

    Write-SOKLog "Measure-AccumulatedDebt: Starting debt measurement." 'INFO'

    $debtSummary = [ordered]@{
        MeasuredAt       = (Get-Date -Format 'o')
        StorageDebt      = [ordered]@{
            TotalClassified  = 0
            CleanableEntries = [System.Collections.Generic.List[hashtable]]::new()
            OffloadCandidates= [System.Collections.Generic.List[hashtable]]::new()
            DbOffloadTargets = [System.Collections.Generic.List[hashtable]]::new()
            InvestigateItems = [System.Collections.Generic.List[hashtable]]::new()
            EstimatedCleanMB = 0.0
        }
        StructuralDebt   = [ordered]@{
            TotalFindings        = 0
            ExcessiveNesting     = [System.Collections.Generic.List[hashtable]]::new()
            RecursiveBackups     = [System.Collections.Generic.List[hashtable]]::new()
            FlattenedPaths       = [System.Collections.Generic.List[hashtable]]::new()
            DuplicateNames       = [System.Collections.Generic.List[hashtable]]::new()
        }
        OverallDebtScore = 0.0   # Composite score: 0=clean, higher=more debt
        ActionableSummary= [System.Collections.Generic.List[string]]::new()
    }

    # ------------------------------------------------------------------
    # STORAGE DEBT — classify C:\ directories
    # ------------------------------------------------------------------
    Write-SOKLog "Measure-AccumulatedDebt: Classifying C:\ for storage debt." 'INFO'

    # Classification patterns (inline, no pre-compiled regex)
    $cleanPatterns      = @('Temp','tmp','\.cache','node_modules','__pycache__','dist\\',
                             '\.gradle','\.m2','AppData\\Local\\Temp','AppData\\Local\\pip',
                             'AppData\\Local\\npm-cache')
    $offloadPatterns    = @('nvm4w','ProgramData\\nvm','ProgramData\\chocolatey',
                             'scoop','miniconda','anaconda','sdk','Android')
    $dbOffloadPatterns  = @('MongoDB','PostgreSQL','MySQL','elasticsearch','kibana',
                             'ProgramData\\MongoDB','ProgramData\\PostgreSQL')
    $investigatePatterns= @('Backup','Archive','OLD','old_','_old','\.bak')
    $keepPatterns       = @('Windows','Program Files','Users\\shelc\\AppData\\Roaming',
                             'Users\\shelc\\Documents','ProgramData\\Microsoft',
                             'System Volume Information','\$Recycle\.Bin')

    function Get-DebtVerdict {
        param([string]$Path)
        foreach ($p in $dbOffloadPatterns)   { if ($Path -match $p) { return 'DB_OFFLOAD'  } }
        foreach ($p in $offloadPatterns)     { if ($Path -match $p) { return 'OFFLOAD'     } }
        foreach ($p in $cleanPatterns)       { if ($Path -match $p) { return 'CLEAN'       } }
        foreach ($p in $investigatePatterns) { if ($Path -match $p) { return 'INVESTIGATE' } }
        foreach ($p in $keepPatterns)        { if ($Path -match $p) { return 'KEEP'        } }
        return 'UNKNOWN'
    }

    $cDirs = Get-ChildItem -Path 'C:\' -Directory -Force -ErrorAction SilentlyContinue
    foreach ($dir in $cDirs) {
        $sizeMB = 0.0
        try {
            $roboOut = & robocopy $dir.FullName 'C:\NUL' /L /S /NP /BYTES /NFL /NDL /NJH 2>&1
            foreach ($rl in $roboOut) {
                if ($rl -match 'Bytes\s*:\s*([\d\.]+)\s*([\w]*)') {
                    $rawVal  = [double]$Matches[1]
                    $rawUnit = $Matches[2].ToLower()
                    $sizeMB  = switch ($rawUnit) {
                        'g'     { $rawVal * 1024 }
                        'm'     { $rawVal }
                        'k'     { $rawVal / 1024 }
                        default { $rawVal / 1MB }
                    }
                    break
                }
            }
        } catch { $sizeMB = 0.0 }

        $sizeKB  = $sizeMB * 1024
        $verdict = Get-DebtVerdict -Path $dir.FullName

        if ($sizeKB -ge $MinSizeKB -or $verdict -in @('CLEAN','OFFLOAD','DB_OFFLOAD','INVESTIGATE')) {
            $entry = @{ Path = $dir.FullName; SizeMB = [math]::Round($sizeMB, 2); Verdict = $verdict }
            switch ($verdict) {
                'CLEAN'      {
                    $debtSummary.StorageDebt.CleanableEntries.Add($entry)
                    $debtSummary.StorageDebt.EstimatedCleanMB += $sizeMB
                }
                'OFFLOAD'    { $debtSummary.StorageDebt.OffloadCandidates.Add($entry) }
                'DB_OFFLOAD' { $debtSummary.StorageDebt.DbOffloadTargets.Add($entry) }
                'INVESTIGATE'{ $debtSummary.StorageDebt.InvestigateItems.Add($entry)  }
            }
            $debtSummary.StorageDebt.TotalClassified++
        }
    }

    $debtSummary.StorageDebt.EstimatedCleanMB = [math]::Round($debtSummary.StorageDebt.EstimatedCleanMB, 2)
    Write-SOKLog "Measure-AccumulatedDebt: Storage debt — $($debtSummary.StorageDebt.CleanableEntries.Count) cleanable, $($debtSummary.StorageDebt.OffloadCandidates.Count) offload candidates." 'INFO'

    # ------------------------------------------------------------------
    # STRUCTURAL DEBT — scan Restructure targets
    # ------------------------------------------------------------------
    Write-SOKLog "Measure-AccumulatedDebt: Scanning for structural debt." 'INFO'

    foreach ($targetRoot in $RestructureTargets) {
        if (-not (Test-Path $targetRoot)) { continue }

        $allDirs = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
        try {
            $found = Get-ChildItem -Path $targetRoot -Recurse -Directory -Depth ($MaxDepth + 3) `
                                   -ErrorAction SilentlyContinue -Force
            foreach ($d in $found) { $allDirs.Add($d) }
        } catch {
            Write-SOKLog "Measure-AccumulatedDebt: Scan error on $targetRoot : $_" 'WARN'
            continue
        }

        $rootDepth = ($targetRoot -split '\\').Count

        # Excessive nesting
        foreach ($dir in $allDirs) {
            $relDepth = ($dir.FullName -split '\\').Count - $rootDepth
            if ($relDepth -gt $MaxDepth) {
                $debtSummary.StructuralDebt.ExcessiveNesting.Add(@{
                    Path = $dir.FullName; Depth = $relDepth; Threshold = $MaxDepth; Root = $targetRoot
                })
            }
        }

        # Recursive backup patterns
        foreach ($dir in $allDirs) {
            if ($dir.Name.ToLower() -match 'backup|archive|bak') {
                $parentPath = $dir.Parent.FullName
                $ancestorIsBackup = $false
                while ($parentPath.Length -gt $targetRoot.Length) {
                    if ((Split-Path $parentPath -Leaf).ToLower() -match 'backup|archive|bak') {
                        $ancestorIsBackup = $true; break
                    }
                    $parentPath = Split-Path $parentPath -Parent
                }
                if ($ancestorIsBackup) {
                    $debtSummary.StructuralDebt.RecursiveBackups.Add(@{
                        Path   = $dir.FullName
                        Reason = 'Nested backup/archive inside backup/archive'
                        Root   = $targetRoot
                    })
                }
            }
        }

        # Flattened paths
        foreach ($dir in $allDirs) {
            $substantiveParts = ($dir.Name -split '_') | Where-Object { $_.Length -ge 2 }
            if ($substantiveParts.Count -ge 5) {
                $debtSummary.StructuralDebt.FlattenedPaths.Add(@{
                    Path     = $dir.FullName
                    SegCount = $substantiveParts.Count
                    Root     = $targetRoot
                })
            }
        }

        # Duplicate dir names (3+ occurrences)
        $nameFreq = [ordered]@{}
        foreach ($dir in $allDirs) {
            $n = $dir.Name.ToLower()
            $nameFreq[$n] = if ($nameFreq.Contains($n)) { $nameFreq[$n] + 1 } else { 1 }
        }
        foreach ($n in ($nameFreq.Keys | Where-Object { $nameFreq[$_] -ge 3 })) {
            $instances = $allDirs | Where-Object { $_.Name.ToLower() -eq $n }
            $debtSummary.StructuralDebt.DuplicateNames.Add(@{
                Name      = $n
                Count     = $nameFreq[$n]
                Instances = @($instances | ForEach-Object { $_.FullName })
                Root      = $targetRoot
            })
        }
    }

    $debtSummary.StructuralDebt.TotalFindings =
        $debtSummary.StructuralDebt.ExcessiveNesting.Count +
        $debtSummary.StructuralDebt.RecursiveBackups.Count +
        $debtSummary.StructuralDebt.FlattenedPaths.Count +
        $debtSummary.StructuralDebt.DuplicateNames.Count

    # ------------------------------------------------------------------
    # Composite debt score (heuristic)
    # The score is not meant for comparison across machines — it is an
    # internal PAST signal for "how much work is outstanding this run."
    # Formula: (CleanableMB / 1024) + (StructuralFindings * 0.5) +
    #          (OffloadCandidates * 2) + (DbOffloadTargets * 3)
    # ------------------------------------------------------------------
    $debtSummary.OverallDebtScore = [math]::Round(
        ($debtSummary.StorageDebt.EstimatedCleanMB / 1024) +
        ($debtSummary.StructuralDebt.TotalFindings * 0.5) +
        ($debtSummary.StorageDebt.OffloadCandidates.Count * 2) +
        ($debtSummary.StorageDebt.DbOffloadTargets.Count * 3),
        2
    )

    # Build actionable summary strings
    if ($debtSummary.StorageDebt.CleanableEntries.Count -gt 0) {
        $debtSummary.ActionableSummary.Add(
            "$($debtSummary.StorageDebt.CleanableEntries.Count) CLEAN dirs (~$($debtSummary.StorageDebt.EstimatedCleanMB) MB recoverable)"
        )
    }
    if ($debtSummary.StorageDebt.OffloadCandidates.Count -gt 0) {
        $debtSummary.ActionableSummary.Add(
            "$($debtSummary.StorageDebt.OffloadCandidates.Count) OFFLOAD candidates (large toolchains on C:\)"
        )
    }
    if ($debtSummary.StorageDebt.DbOffloadTargets.Count -gt 0) {
        $debtSummary.ActionableSummary.Add(
            "$($debtSummary.StorageDebt.DbOffloadTargets.Count) DB_OFFLOAD targets"
        )
    }
    if ($debtSummary.StructuralDebt.ExcessiveNesting.Count -gt 0) {
        $debtSummary.ActionableSummary.Add(
            "$($debtSummary.StructuralDebt.ExcessiveNesting.Count) dirs exceed max nesting depth ($MaxDepth)"
        )
    }
    if ($debtSummary.StructuralDebt.RecursiveBackups.Count -gt 0) {
        $debtSummary.ActionableSummary.Add(
            "$($debtSummary.StructuralDebt.RecursiveBackups.Count) recursive backup patterns found"
        )
    }
    if ($debtSummary.StructuralDebt.DuplicateNames.Count -gt 0) {
        $debtSummary.ActionableSummary.Add(
            "$($debtSummary.StructuralDebt.DuplicateNames.Count) duplicate directory name groups (3+)"
        )
    }

    Write-SOKLog "Measure-AccumulatedDebt: DebtScore=$($debtSummary.OverallDebtScore). Structural=$($debtSummary.StructuralDebt.TotalFindings) findings." 'INFO'
    return $debtSummary
}

# ===========================================================================
#
#  META-LEVEL ABSTRACTION 3: New-HistoricalRecord
#
#  Creates a timestamped reconciliation record that answers:
#   "What did PAST find, fix, and flag this run?"
#
#  This is the durable output artifact. Unlike a module log or a raw inventory
#  JSON, a HistoricalRecord is a unified document of one temporal observation:
#  the invariant state before and after this run, the debt snapshot, and the
#  set of changes made. It is written to SOK\Logs\PASTRecords\ and is the
#  primary input to future CompareSnapshots runs.
#
# ===========================================================================
function New-HistoricalRecord {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [hashtable]$TruthSnapshot    = @{},
        [hashtable]$DebtAnalysis     = @{},
        [hashtable]$InvariantReport  = @{},
        [string]$RunLabel            = ''
    )

    Write-SOKLog "New-HistoricalRecord: Creating reconciliation record." 'INFO'

    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $label     = if ($RunLabel -ne '') { "_$RunLabel" } else { '' }
    $recordDir = "$LOG_BASE\PASTRecords"
    $recordPath= "$recordDir\SOK_PASTRecord_${timestamp}${label}.json"

    $record = [ordered]@{
        RecordVersion    = '2.0.0'
        CreatedAt        = (Get-Date -Format 'o')
        MachineName      = $env:COMPUTERNAME
        RunLabel         = $RunLabel
        DryRun           = $DryRun.IsPresent

        # What the system IS right now
        TruthSnapshot    = $TruthSnapshot

        # What debt has accumulated
        DebtAnalysis     = $DebtAnalysis

        # What invariants were found broken and what was done
        InvariantReport  = $InvariantReport

        # Summary for quick human review
        RunSummary       = [ordered]@{
            JunctionCount       = if ($TruthSnapshot.ContainsKey('Junctions'))  { $TruthSnapshot.Junctions.Count } else { 0 }
            DriveCount          = if ($TruthSnapshot.ContainsKey('Drives'))     { $TruthSnapshot.Drives.Count    } else { 0 }
            OverallDebtScore    = if ($DebtAnalysis.ContainsKey('OverallDebtScore')) { $DebtAnalysis.OverallDebtScore } else { 0 }
            ActionableSummary   = if ($DebtAnalysis.ContainsKey('ActionableSummary')) {
                                      @($DebtAnalysis.ActionableSummary)
                                  } else { @() }
            InvariantsChecked   = if ($InvariantReport.ContainsKey('ChecksRun')) { $InvariantReport.ChecksRun } else { 0 }
            InvariantsFixed     = if ($InvariantReport.ContainsKey('Fixed'))     { $InvariantReport.Fixed      } else { 0 }
        }
    }

    $jsonOutput = $record | ConvertTo-Json -Depth 15

    if ($DryRun) {
        Write-SOKLog "New-HistoricalRecord: [DRYRUN] Would write record to $recordPath" 'INFO'
    } else {
        if (-not (Test-Path $recordDir)) {
            New-Item -ItemType Directory -Path $recordDir -Force | Out-Null
        }
        $jsonOutput | Out-File -FilePath $recordPath -Encoding UTF8 -ErrorAction Stop
        Write-SOKLog "New-HistoricalRecord: Record written to $recordPath" 'INFO'
    }

    return $recordPath
}

# ===========================================================================
#
#  Repair-SystemInvariants
#
#  The InfraFix logic, refactored to:
#  (a) Accept the pre-collected junction map from Get-SystemTruth so we do
#      not re-scan (meta-level optimization: one collection shared by all)
#  (b) Return a structured InvariantReport rather than just logging
#
# ===========================================================================
function Repair-SystemInvariants {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [System.Collections.Generic.List[hashtable]]$JunctionMap = $null
    )

    Write-SOKLog "Repair-SystemInvariants: Starting. DryRun=$DryRun" 'INFO'

    $report = [ordered]@{
        ChecksRun    = 5
        Fixed        = 0
        Skipped      = 0
        Checks       = [System.Collections.Generic.List[hashtable]]::new()
    }

    # Helper: record the outcome of a check
    function Add-CheckResult {
        param([string]$FixId, [string]$Status, [string]$Detail)
        $report.Checks.Add(@{ Fix = $FixId; Status = $Status; Detail = $Detail })
        if ($Status -eq 'Fixed')   { $report.Fixed++   }
        if ($Status -eq 'Skipped') { $report.Skipped++ }
    }

    # --- FIX-1: nvm4w junction ---
    # Use the pre-collected junction map if available — avoids re-scanning.
    $junctionPath    = 'C:\nvm4w\nodejs'
    $nvmDataRoot     = 'C:\ProgramData\nvm'
    $junctionBroken  = $true

    if ($null -ne $JunctionMap) {
        $existingEntry = $JunctionMap | Where-Object { $_.Path -eq $junctionPath } | Select-Object -First 1
        if ($null -ne $existingEntry) {
            $junctionBroken = -not $existingEntry.TargetValid
        }
    } else {
        # Fallback: check directly
        $ji = Get-Item $junctionPath -ErrorAction SilentlyContinue
        if ($null -ne $ji -and $ji.LinkType -eq 'Junction' -and (Test-Path $ji.Target)) {
            $junctionBroken = $false
        }
    }

    if (-not $junctionBroken) {
        Add-CheckResult 'FIX-1' 'OK' "nvm4w junction is valid."
    } else {
        $bestNodeDir = $null
        if (Test-Path $nvmDataRoot) {
            $candidates = Get-ChildItem -Path $nvmDataRoot -Directory -ErrorAction SilentlyContinue |
                          Where-Object { Test-Path (Join-Path $_.FullName 'node.exe') } |
                          Sort-Object Name -Descending
            if ($candidates.Count -gt 0) { $bestNodeDir = $candidates[0].FullName }
        }

        if ($null -eq $bestNodeDir) {
            Add-CheckResult 'FIX-1' 'Skipped' "No valid node.exe found in $nvmDataRoot"
        } elseif ($DryRun) {
            Add-CheckResult 'FIX-1' 'DryRun' "Would recreate junction -> $bestNodeDir"
        } else {
            try {
                if (Test-Path $junctionPath) { Remove-Item -Path $junctionPath -Force -Recurse -ErrorAction SilentlyContinue }
                New-Item -ItemType Junction -Path $junctionPath -Target $bestNodeDir -ErrorAction Stop | Out-Null
                Add-CheckResult 'FIX-1' 'Fixed' "Junction recreated -> $bestNodeDir"
                Write-SOKLog "Repair-SystemInvariants FIX-1: Recreated junction -> $bestNodeDir" 'INFO'
            } catch {
                Add-CheckResult 'FIX-1' 'Error' "$_"
            }
        }
    }

    # --- FIX-2: UC OneDrive orphaned reparse point ---
    $ucOneDrive = 'C:\Users\shelc\OneDrive - University of Cincinnati'
    if (Test-Path $ucOneDrive) {
        $ucItem = Get-Item $ucOneDrive -Force -ErrorAction SilentlyContinue
        $isReparse = $null -ne $ucItem -and ($ucItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
        if ($isReparse) {
            $accessible = $true
            try { Get-ChildItem -Path $ucOneDrive -ErrorAction Stop | Out-Null } catch { $accessible = $false }
            if (-not $accessible) {
                if ($DryRun) {
                    Add-CheckResult 'FIX-2' 'DryRun' "Would rename orphaned reparse point to .bak"
                } else {
                    try {
                        Rename-Item -Path $ucOneDrive -NewName "$($ucItem.Name).bak" -ErrorAction Stop
                        Add-CheckResult 'FIX-2' 'Fixed' "Renamed to $ucOneDrive.bak"
                        Write-SOKLog "Repair-SystemInvariants FIX-2: Orphaned reparse point renamed." 'INFO'
                    } catch {
                        Add-CheckResult 'FIX-2' 'Error' "$_"
                    }
                }
            } else {
                Add-CheckResult 'FIX-2' 'OK' "UC OneDrive reparse point is accessible."
            }
        } else {
            Add-CheckResult 'FIX-2' 'OK' "UC OneDrive is a regular directory."
        }
    } else {
        Add-CheckResult 'FIX-2' 'OK' "UC OneDrive path not present."
    }

    # --- FIX-3: Kibana node.exe shim ---
    $kibanaNodPath     = 'C:\ProgramData\chocolatey\bin\node.exe'
    $shimThresholdBytes = 256 * 1024
    if (Test-Path $kibanaNodPath) {
        $nodeItem = Get-Item $kibanaNodPath -ErrorAction SilentlyContinue
        if ($null -ne $nodeItem -and $nodeItem.Length -lt $shimThresholdBytes) {
            if ($DryRun) {
                Add-CheckResult 'FIX-3' 'DryRun' "Would rename shim ($($nodeItem.Length) bytes) to .bak"
            } else {
                try {
                    Rename-Item -Path $kibanaNodPath -NewName 'node.exe.bak' -ErrorAction Stop
                    Add-CheckResult 'FIX-3' 'Fixed' "Shim renamed to node.exe.bak"
                    Write-SOKLog "Repair-SystemInvariants FIX-3: Shim renamed." 'INFO'
                } catch {
                    Add-CheckResult 'FIX-3' 'Error' "$_"
                }
            }
        } else {
            Add-CheckResult 'FIX-3' 'OK' "node.exe is $($nodeItem.Length) bytes — not a shim."
        }
    } else {
        Add-CheckResult 'FIX-3' 'OK' "Kibana node.exe path not present."
    }

    # --- FIX-4: Legacy SOK History dir ---
    $oldHistoryPath = "$SOK_ROOT\History"
    $newHistoryPath = "$SOK_ROOT\Deprecated\History"
    if (Test-Path $oldHistoryPath) {
        if ($DryRun) {
            Add-CheckResult 'FIX-4' 'DryRun' "Would move $oldHistoryPath to $newHistoryPath"
        } else {
            try {
                $deprecatedRoot = "$SOK_ROOT\Deprecated"
                if (-not (Test-Path $deprecatedRoot)) {
                    New-Item -ItemType Directory -Path $deprecatedRoot -Force | Out-Null
                }
                Move-Item -Path $oldHistoryPath -Destination $newHistoryPath -ErrorAction Stop
                Add-CheckResult 'FIX-4' 'Fixed' "Moved to $newHistoryPath"
                Write-SOKLog "Repair-SystemInvariants FIX-4: History dir moved." 'INFO'
            } catch {
                Add-CheckResult 'FIX-4' 'Error' "$_"
            }
        }
    } else {
        Add-CheckResult 'FIX-4' 'OK' "Legacy History dir not present."
    }

    # --- FIX-5: Scoop shim repair ---
    $scoopCmd = Get-Command scoop -ErrorAction SilentlyContinue
    if ($null -eq $scoopCmd) {
        Add-CheckResult 'FIX-5' 'Skipped' "scoop not found on PATH"
    } elseif ($DryRun) {
        Add-CheckResult 'FIX-5' 'DryRun' "Would run: scoop update"
    } else {
        try {
            $scoopOut = & scoop update 2>&1
            Add-CheckResult 'FIX-5' 'Fixed' "scoop update ran: $($scoopOut | Out-String | Select-Object -First 1)"
            Write-SOKLog "Repair-SystemInvariants FIX-5: scoop update completed." 'INFO'
        } catch {
            Add-CheckResult 'FIX-5' 'Error' "$_"
        }
    }

    Write-SOKLog "Repair-SystemInvariants: Complete. Fixed=$($report.Fixed)" 'INFO'
    return $report
}

# ===========================================================================
#
#  Invoke-SnapshotComparison  (explicit opt-in)
#
# ===========================================================================
function Invoke-SnapshotComparison {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [string]$OldSnapshot,
        [string]$NewSnapshot,
        [double]$AutoApproveThreshold = 16.66,
        [string]$OutputDir
    )

    Write-SOKLog "SnapshotComparison: Starting. DryRun=$DryRun" 'INFO'

    if ([string]::IsNullOrWhiteSpace($OldSnapshot) -or [string]::IsNullOrWhiteSpace($NewSnapshot)) {
        Write-SOKLog "SnapshotComparison: -OldSnapshot and -NewSnapshot are required." 'WARN'
        return $null
    }
    if (-not (Test-Path $OldSnapshot)) { Write-SOKLog "SnapshotComparison: OldSnapshot not found." 'WARN'; return $null }
    if (-not (Test-Path $NewSnapshot)) { Write-SOKLog "SnapshotComparison: NewSnapshot not found." 'WARN'; return $null }

    $timestamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
    $outputPath = "$OutputDir\SOK_Compare_$timestamp.txt"

    $oldLines = Get-Content -Path $OldSnapshot -Encoding UTF8 -ErrorAction Stop
    $newLines = Get-Content -Path $NewSnapshot  -Encoding UTF8 -ErrorAction Stop

    $oldSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $newSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($l in $oldLines) { $oldSet.Add($l) | Out-Null }
    foreach ($l in $newLines) { $newSet.Add($l) | Out-Null }

    $additions    = [System.Collections.Generic.List[string]]::new()
    $subtractions = [System.Collections.Generic.List[string]]::new()

    foreach ($l in $newLines) { if (-not $oldSet.Contains($l)) { $additions.Add("[+] $l") } }
    foreach ($l in $oldLines) { if (-not $newSet.Contains($l)) { $subtractions.Add("[-] $l") } }

    $totalChanged  = $additions.Count + $subtractions.Count
    $changePercent = if ($oldLines.Count -gt 0) {
        [math]::Round(($totalChanged / $oldLines.Count) * 100, 2)
    } else { 0.0 }

    Write-SOKLog "SnapshotComparison: +$($additions.Count) -$($subtractions.Count) = $changePercent%" 'INFO'

    if ($changePercent -gt $AutoApproveThreshold -and -not $DryRun) {
        Write-Host ""
        Write-Host "WARNING: $changePercent% of lines changed (threshold: $AutoApproveThreshold%)"
        $confirm = Read-Host "Proceed? [y/N]"
        if ($confirm.ToLower() -ne 'y') {
            Write-SOKLog "SnapshotComparison: Operator declined." 'WARN'
            return $null
        }
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# SOK Snapshot Comparison")
    $lines.Add("# Generated: $(Get-Date -Format 'o')")
    $lines.Add("# Old: $OldSnapshot ($($oldLines.Count) lines)")
    $lines.Add("# New: $NewSnapshot ($($newLines.Count) lines)")
    $lines.Add("# +$($additions.Count) -$($subtractions.Count) ($changePercent%)")
    $lines.Add("# [+]=Addition [-]=Subtraction [*]=Revision [~]=Mixed")
    $lines.Add("")
    $lines.Add("## ADDITIONS ($($additions.Count))")
    foreach ($a in $additions) { $lines.Add($a) }
    $lines.Add("")
    $lines.Add("## SUBTRACTIONS ($($subtractions.Count))")
    foreach ($s in $subtractions) { $lines.Add($s) }

    if ($DryRun) {
        Write-SOKLog "SnapshotComparison: [DRYRUN] Would write to $outputPath" 'INFO'
    } else {
        if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
        $lines | Out-File -FilePath $outputPath -Encoding UTF8 -ErrorAction Stop
        Write-SOKLog "SnapshotComparison: Written to $outputPath" 'INFO'
    }

    return $outputPath
}

# ===========================================================================
#
#  Invoke-BackupConsolidation  (explicit opt-in)
#
# ===========================================================================
function Invoke-BackupConsolidation {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [string]$ArchiveRoot,
        [string]$MergeTarget,
        [switch]$RunPhase1,
        [switch]$SkipExtraction,
        [switch]$SkipMerge
    )

    Write-SOKLog "BackupConsolidation: Starting. ArchiveRoot=$ArchiveRoot DryRun=$DryRun" 'INFO'

    if (-not (Test-Path $ArchiveRoot)) {
        Write-SOKLog "BackupConsolidation: ArchiveRoot '$ArchiveRoot' not found. Aborting." 'WARN'
        return
    }

    # Phase 1 (opt-in): delete raw pre-extracted duplicates
    if ($RunPhase1) {
        Write-SOKLog "BackupConsolidation: Phase 1 — removing raw pre-extracted duplicates." 'INFO'
        $archives7z = Get-ChildItem -Path $ArchiveRoot -Recurse -File -ErrorAction SilentlyContinue |
                      Where-Object { $_.Extension -eq '.7z' -and $_.Name -notmatch '\.\d{3}$' }

        foreach ($arc in $archives7z) {
            $rawDir = Join-Path $arc.DirectoryName ([System.IO.Path]::GetFileNameWithoutExtension($arc.FullName))
            if (Test-Path $rawDir -PathType Container) {
                if ($DryRun) {
                    Write-SOKLog "BackupConsolidation: Phase 1 [DRYRUN] Would delete $rawDir" 'INFO'
                } else {
                    try {
                        $emptyTemp = Join-Path ([System.IO.Path]::GetTempPath()) 'SOK_EmptyMirrorSource'
                        if (-not (Test-Path $emptyTemp)) { New-Item -ItemType Directory -Path $emptyTemp -Force | Out-Null }
                        & robocopy $emptyTemp $rawDir /MIR /NFL /NDL /NJH /NJS /NP 2>&1 | Out-Null
                        Remove-Item -Path $rawDir -Force -Recurse -ErrorAction Stop
                        Write-SOKLog "BackupConsolidation: Phase 1 — deleted $rawDir" 'INFO'
                    } catch {
                        Write-SOKLog "BackupConsolidation: Phase 1 — failed on $rawDir : $_" 'WARN'
                    }
                }
            }
        }
    }

    # Phase 2: Extract .7z archives in-place
    if (-not $SkipExtraction) {
        Write-SOKLog "BackupConsolidation: Phase 2 — extracting archives." 'INFO'
        $sevenZipExe = (Get-Command '7z' -ErrorAction SilentlyContinue)?.Source
        if ($null -eq $sevenZipExe) {
            $sevenZipExe = 'C:\Program Files\7-Zip\7z.exe'
            if (-not (Test-Path $sevenZipExe)) { $sevenZipExe = $null }
        }

        if ($null -ne $sevenZipExe) {
            $toExtract = Get-ChildItem -Path $ArchiveRoot -Recurse -File -ErrorAction SilentlyContinue |
                         Where-Object { $_.Name -match '\.7z$' -and $_.Name -notmatch '\.\d{3,}\.7z$' }

            foreach ($arc in $toExtract) {
                $extractDir = Join-Path $arc.DirectoryName ([System.IO.Path]::GetFileNameWithoutExtension($arc.FullName))
                if (Test-Path $extractDir) { continue }

                if ($DryRun) {
                    Write-SOKLog "BackupConsolidation: Phase 2 [DRYRUN] Would extract $($arc.Name) to $extractDir" 'INFO'
                } else {
                    try {
                        & $sevenZipExe x $arc.FullName "-o$extractDir" -y 2>&1 | Out-Null
                        if ($LASTEXITCODE -eq 0) {
                            Write-SOKLog "BackupConsolidation: Phase 2 — extracted $($arc.Name)" 'INFO'
                        } else {
                            Write-SOKLog "BackupConsolidation: Phase 2 — 7z error $LASTEXITCODE on $($arc.Name)" 'WARN'
                        }
                    } catch {
                        Write-SOKLog "BackupConsolidation: Phase 2 — failed on $($arc.Name): $_" 'WARN'
                    }
                }
            }
        } else {
            Write-SOKLog "BackupConsolidation: Phase 2 — 7z not found; skipping extraction." 'WARN'
        }
    }

    # Phase 3: Merge to MergeTarget with derivation tags
    if (-not $SkipMerge) {
        Write-SOKLog "BackupConsolidation: Phase 3 — merging to $MergeTarget." 'INFO'

        if (-not $DryRun -and -not (Test-Path $MergeTarget)) {
            New-Item -ItemType Directory -Path $MergeTarget -Force | Out-Null
        }

        $topDirs   = Get-ChildItem -Path $ArchiveRoot -Directory -ErrorAction SilentlyContinue
        $seenNames = [ordered]@{}

        foreach ($dir in $topDirs) {
            $baseName   = $dir.Name
            $archivePath= Join-Path $dir.Parent.FullName "$baseName.7z"
            $relDepth   = ($dir.FullName -split '\\').Count - ($ArchiveRoot -split '\\').Count

            $tag = '_b'
            if (Test-Path $archivePath) {
                $tag = if ($seenNames.Contains($baseName)) { '_a2' } else { '_a1' }
            } elseif ($relDepth -gt 3) {
                $tag = '_d'
            }

            $mergedName = if ($seenNames.Contains($baseName)) {
                $seenNames[$baseName]++
                "$baseName${tag}_$($seenNames[$baseName])"
            } else {
                $seenNames[$baseName] = 1
                "$baseName$tag"
            }

            $dest = Join-Path $MergeTarget $mergedName

            if ($DryRun) {
                Write-SOKLog "BackupConsolidation: Phase 3 [DRYRUN] $baseName → $mergedName" 'INFO'
            } else {
                try {
                    & robocopy $dir.FullName $dest /E /NFL /NDL /NJH /NJS /NP | Out-Null
                    if ($LASTEXITCODE -lt 8) {
                        Write-SOKLog "BackupConsolidation: Phase 3 — $baseName → $mergedName" 'INFO'
                    } else {
                        Write-SOKLog "BackupConsolidation: Phase 3 — robocopy error $LASTEXITCODE on $baseName" 'WARN'
                    }
                } catch {
                    Write-SOKLog "BackupConsolidation: Phase 3 — failed on $baseName : $_" 'WARN'
                }
            }
        }
    }

    Write-SOKLog "BackupConsolidation: All phases complete." 'INFO'
}

# ===========================================================================
#
#  MAIN BODY — Meta-level pipeline
#
#  Pipeline: TruthSnapshot → DebtAnalysis → ReconciliationRecord
#
#  The GlobalState here is genuinely meta-level: we carry forward what we
#  learned about the system (truth) so that subsequent stages do not need to
#  re-observe it. This is NOT shared tactical state — it is the accumulated
#  knowledge of this PAST run.
#
# ===========================================================================

$runSummary = [ordered]@{
    ScriptName   = $SCRIPT_NAME
    Version      = $SCRIPT_VERSION
    StartTime    = (Get-Date -Format 'o')
    DryRun       = $DryRun.IsPresent
    AspectsRun   = [System.Collections.Generic.List[string]]::new()
    RecordPath   = ''
    Errors       = [System.Collections.Generic.List[string]]::new()
}

# Meta-pipeline state — flows forward through the run
$globalTruthSnapshot  = $null
$globalDebtAnalysis   = $null
$globalInvariantReport= $null

try {
    Show-SOKBanner -Title "$SCRIPT_NAME v$SCRIPT_VERSION"
    Write-SOKLog "$SCRIPT_NAME v$SCRIPT_VERSION starting. DryRun=$DryRun" 'INFO'

    if ($DryRun) {
        Write-SOKLog "DryRun mode ACTIVE — no destructive operations will be performed." 'WARN'
    }

    $anyAspectRequested = $ResolveInvariants -or $CaptureSystemTruth -or $MeasureDebt -or
                          $CompareSnapshots  -or $ConsolidateBackups

    if (-not $anyAspectRequested) {
        Write-SOKLog "No aspects selected. Use -All or individual flags like -ResolveInvariants, -CaptureSystemTruth, -MeasureDebt." 'WARN'
        Write-Host ""
        Write-Host "Usage examples:"
        Write-Host "  .\SOK-PAST-v2.ps1 -All -DryRun"
        Write-Host "  .\SOK-PAST-v2.ps1 -All -SkipDebtMeasurement"
        Write-Host "  .\SOK-PAST-v2.ps1 -CaptureSystemTruth -ScanCaliber 3"
        Write-Host "  .\SOK-PAST-v2.ps1 -CompareSnapshots -OldSnapshot C:\old.txt -NewSnapshot C:\new.txt"
        Write-Host ""
    }

    # ------------------------------------------------------------------
    # STEP 1: Collect System Truth
    # If we need truth for ANY of the core aspects, collect it once here.
    # Both ResolveInvariants (needs junction map) and CaptureSystemTruth
    # (needs full truth) benefit from this single collection pass.
    # ------------------------------------------------------------------
    $needsTruth = $ResolveInvariants -or $CaptureSystemTruth -or $MeasureDebt

    if ($needsTruth) {
        Write-SOKLog "Pipeline: Collecting system truth (needed by one or more aspects)." 'INFO'
        try {
            $globalTruthSnapshot = Get-SystemTruth -ScanCaliber $ScanCaliber
            Write-SOKLog "Pipeline: TruthSnapshot collected. Drives=$($globalTruthSnapshot.Drives.Count) Junctions=$($globalTruthSnapshot.Junctions.Count)" 'INFO'
        } catch {
            $errMsg = "TruthSnapshot collection failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
            # A failed TruthSnapshot is a fundamental pipeline problem — we can
            # still proceed with other aspects but log it prominently.
            $globalTruthSnapshot = @{ CollectedAt = (Get-Date -Format 'o'); Error = $errMsg }
        }
    }

    # ------------------------------------------------------------------
    # STEP 2: Resolve Invariants
    # Uses the junction map from TruthSnapshot — no re-scan needed.
    # ------------------------------------------------------------------
    if ($ResolveInvariants) {
        $runSummary.AspectsRun.Add('ResolveInvariants')
        Write-SOKLog "Pipeline: Resolving invariants." 'INFO'
        try {
            $junctionMap = if ($null -ne $globalTruthSnapshot -and $globalTruthSnapshot.ContainsKey('Junctions')) {
                $globalTruthSnapshot.Junctions
            } else { $null }

            $globalInvariantReport = Repair-SystemInvariants -DryRun:$DryRun -JunctionMap $junctionMap
            Write-SOKLog "Pipeline: InvariantReport — Fixed=$($globalInvariantReport.Fixed)" 'INFO'
        } catch {
            $errMsg = "ResolveInvariants failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
            $globalInvariantReport = @{ Error = $errMsg; ChecksRun = 0; Fixed = 0 }
        }
    }

    # ------------------------------------------------------------------
    # STEP 3: Capture System Truth to disk
    # The truth was already collected above; this step persists it to JSON.
    # ------------------------------------------------------------------
    if ($CaptureSystemTruth -and $null -ne $globalTruthSnapshot) {
        $runSummary.AspectsRun.Add('CaptureSystemTruth')
        $timestamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
        $invLogDir   = "$LOG_BASE\Inventory"
        $invOutPath  = if ($InventoryOutputPath -ne '') { $InventoryOutputPath } else {
            "$invLogDir\SOK_Inventory_$timestamp.json"
        }

        if ($DryRun) {
            Write-SOKLog "Pipeline: [DRYRUN] Would write TruthSnapshot to $invOutPath" 'INFO'
        } else {
            try {
                if (-not (Test-Path $invLogDir)) { New-Item -ItemType Directory -Path $invLogDir -Force | Out-Null }
                ($globalTruthSnapshot | ConvertTo-Json -Depth 10) |
                    Out-File -FilePath $invOutPath -Encoding UTF8 -ErrorAction Stop
                Write-SOKLog "Pipeline: TruthSnapshot written to $invOutPath" 'INFO'
            } catch {
                $errMsg = "CaptureSystemTruth write failed: $_"
                Write-SOKLog $errMsg 'ERROR'
                $runSummary.Errors.Add($errMsg)
            }
        }
    }

    # ------------------------------------------------------------------
    # STEP 4: Measure Accumulated Debt
    # ------------------------------------------------------------------
    if ($MeasureDebt) {
        $runSummary.AspectsRun.Add('MeasureDebt')
        Write-SOKLog "Pipeline: Measuring accumulated debt." 'INFO'
        try {
            $junctionMap = if ($null -ne $globalTruthSnapshot -and $globalTruthSnapshot.ContainsKey('Junctions')) {
                $globalTruthSnapshot.Junctions
            } else { $null }

            $globalDebtAnalysis = Measure-AccumulatedDebt `
                                    -MinSizeKB $MinSizeKB `
                                    -RestructureTargets $RestructureTargets `
                                    -MaxDepth $MaxDepth `
                                    -KnownJunctions $junctionMap

            Write-SOKLog "Pipeline: DebtScore=$($globalDebtAnalysis.OverallDebtScore)" 'INFO'
            foreach ($actionItem in $globalDebtAnalysis.ActionableSummary) {
                Write-SOKLog "  [DEBT] $actionItem" 'INFO'
            }

            # Write the debt report to disk
            $debtLogDir  = "$LOG_BASE\SpaceAudit"
            $debtOutPath = "$debtLogDir\SOK_DebtReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

            if ($DryRun) {
                Write-SOKLog "Pipeline: [DRYRUN] Would write DebtAnalysis to $debtOutPath" 'INFO'
            } else {
                if (-not (Test-Path $debtLogDir)) { New-Item -ItemType Directory -Path $debtLogDir -Force | Out-Null }
                ($globalDebtAnalysis | ConvertTo-Json -Depth 10) |
                    Out-File -FilePath $debtOutPath -Encoding UTF8 -ErrorAction Stop
                Write-SOKLog "Pipeline: DebtAnalysis written to $debtOutPath" 'INFO'
            }
        } catch {
            $errMsg = "MeasureDebt failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
            $globalDebtAnalysis = @{ Error = $errMsg; OverallDebtScore = -1 }
        }
    }

    # ------------------------------------------------------------------
    # STEP 5: Create Historical Record
    # The HistoricalRecord consolidates what we found, fixed, and flagged.
    # Only created if at least one core aspect ran.
    # ------------------------------------------------------------------
    $coreAspectRan = $ResolveInvariants -or $CaptureSystemTruth -or $MeasureDebt

    if ($coreAspectRan) {
        $runSummary.AspectsRun.Add('NewHistoricalRecord')
        try {
            $recordPath = New-HistoricalRecord `
                            -DryRun:$DryRun `
                            -TruthSnapshot    ($null -ne $globalTruthSnapshot ? $globalTruthSnapshot : @{}) `
                            -DebtAnalysis     ($null -ne $globalDebtAnalysis  ? $globalDebtAnalysis  : @{}) `
                            -InvariantReport  ($null -ne $globalInvariantReport ? $globalInvariantReport : @{}) `
                            -RunLabel         'PAST-v2'

            $runSummary['RecordPath'] = $recordPath
            Write-SOKLog "Pipeline: HistoricalRecord -> $recordPath" 'INFO'
        } catch {
            $errMsg = "New-HistoricalRecord failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
        }
    }

    # ------------------------------------------------------------------
    # STEP 6: CompareSnapshots (explicit opt-in)
    # ------------------------------------------------------------------
    if ($CompareSnapshots) {
        $runSummary.AspectsRun.Add('CompareSnapshots')
        try {
            $compareOut = Invoke-SnapshotComparison `
                            -DryRun:$DryRun `
                            -OldSnapshot $OldSnapshot `
                            -NewSnapshot $NewSnapshot `
                            -AutoApproveThreshold $AutoApproveThreshold `
                            -OutputDir $ComparatorOutputDir
            if ($compareOut) {
                Write-SOKLog "Pipeline: Compare report -> $compareOut" 'INFO'
            }
        } catch {
            $errMsg = "CompareSnapshots failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
        }
    }

    # ------------------------------------------------------------------
    # STEP 7: ConsolidateBackups (explicit opt-in)
    # ------------------------------------------------------------------
    if ($ConsolidateBackups) {
        $runSummary.AspectsRun.Add('ConsolidateBackups')
        try {
            Invoke-BackupConsolidation `
                -DryRun:$DryRun `
                -ArchiveRoot $ArchiveRoot `
                -MergeTarget $MergeTarget `
                -RunPhase1:$RunPhase1 `
                -SkipExtraction:$SkipExtraction `
                -SkipMerge:$SkipMerge
        } catch {
            $errMsg = "ConsolidateBackups failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
        }
    }

} catch {
    $fatalMsg = "FATAL ERROR in $SCRIPT_NAME : $_"
    Write-SOKLog $fatalMsg 'ERROR'
    $runSummary.Errors.Add($fatalMsg)
} finally {
    $runSummary['EndTime']      = (Get-Date -Format 'o')
    $runSummary['AspectsCount'] = $runSummary.AspectsRun.Count
    $runSummary['ErrorCount']   = $runSummary.Errors.Count

    Write-SOKLog "$SCRIPT_NAME complete. Aspects: $($runSummary.AspectsRun -join ', '). Errors: $($runSummary.Errors.Count)." 'Annotate'

    if ($globalDebtAnalysis -ne $null -and $globalDebtAnalysis.ContainsKey('OverallDebtScore')) {
        Write-SOKLog "DebtScore this run: $($globalDebtAnalysis.OverallDebtScore)" 'Annotate'
    }

    Save-SOKHistory -ScriptName $SCRIPT_NAME -RunData $runSummary
}