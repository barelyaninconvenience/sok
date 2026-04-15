#Requires -Version 7.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    SOK-PAST-Verbose.ps1 v1.0.0 — De-optimized, verbose reference implementation of the
    Son of Klem Preservation, Audit, Snapshot, and Transformation (PAST) meta-script.

.DESCRIPTION
    This is the "dumb it down first" version. Every module is self-contained, sequential,
    and written for maximum human readability. No shared global state, no parallel execution,
    no pre-compiled regex, no streaming I/O. Each module is activated by its own explicit
    switch and operates independently. The goal is correctness and clarity, not performance.

    Modules:
        InfraFix          — Repair 5 known broken environmental invariants
        Inventory         — Snapshot drives, junctions, packages, runtimes, services
        SpaceAudit        — Classify C:\ directories by storage verdict
        Restructure       — Scan backup dirs for structural debt
        CompareSnapshots  — Diff two SOK-Archiver flat-file snapshots
        BackupRestructure — Transform E:\Backup_Archive through 3 phases

.PARAMETER DryRun
    If set, no destructive operations are performed. All actions are logged as [DRYRUN].

.PARAMETER RunInfraFix
    Activate the InfraFix module.

.PARAMETER RunInventory
    Activate the Inventory module.

.PARAMETER RunSpaceAudit
    Activate the SpaceAudit module.

.PARAMETER RunRestructure
    Activate the Restructure module.

.PARAMETER RunCompareSnapshots
    Activate the CompareSnapshots module. Requires -OldSnapshot and -NewSnapshot.

.PARAMETER RunBackupRestructure
    Activate the BackupRestructure module.

.PARAMETER ScanCaliber
    Inventory depth: 1=drives+junctions, 2=+packages+services, 3=+binary SHA-256 hashes.

.PARAMETER InventoryOutputPath
    Override the default inventory output path.

.PARAMETER MinSizeKB
    Minimum size threshold (KB) for SpaceAudit flagging. Default: 21138 (~20 MB).

.PARAMETER OldSnapshot
    Path to the older SOK-Archiver snapshot .txt file (CompareSnapshots).

.PARAMETER NewSnapshot
    Path to the newer SOK-Archiver snapshot .txt file (CompareSnapshots).

.PARAMETER AutoApproveThreshold
    Percentage of lines changed that triggers operator confirmation (default: 16.66%).

.PARAMETER ComparatorOutputDir
    Directory to write CompareSnapshots diff reports.

.PARAMETER RestructureTargets
    Array of root directories to scan for structural debt.

.PARAMETER MaxDepth
    Maximum allowed nesting depth before flagging (Restructure).

.PARAMETER ArchiveRoot
    Source directory for BackupRestructure (default: E:\Backup_Archive).

.PARAMETER MergeTarget
    Destination directory for BackupRestructure merge phase (default: E:\Backup_Merged).

.PARAMETER RunPhase1
    Opt-in to Phase 1 of BackupRestructure (destructive: deletes raw pre-extracted duplicates).

.PARAMETER SkipExtraction
    Skip Phase 2 (7z extraction) of BackupRestructure.

.PARAMETER SkipMerge
    Skip Phase 3 (merge) of BackupRestructure.

.NOTES
    Author : SOK / CLAY_PC
    Version: 1.0.0
    Requires: PowerShell 7.0+, Run as Administrator
#>

param(
    [switch]$DryRun,
    [switch]$RunInfraFix,
    [switch]$RunInventory,
    [switch]$RunSpaceAudit,
    [switch]$RunRestructure,
    [switch]$RunCompareSnapshots,
    [switch]$RunBackupRestructure,
    [ValidateRange(1,3)][int]$ScanCaliber = 2,
    [string]$InventoryOutputPath,
    [int]$MinSizeKB = 21138,
    [string]$OldSnapshot,
    [string]$NewSnapshot,
    [double]$AutoApproveThreshold = 16.66,
    [string]$ComparatorOutputDir = "$env:USERPROFILE\Documents\SOK\Archives",
    [string[]]$RestructureTargets = @("$env:USERPROFILE\Documents\Backup", "$env:USERPROFILE\Downloads"),
    [int]$MaxDepth = 13,
    [string]$ArchiveRoot = 'E:\Backup_Archive',
    [string]$MergeTarget = 'E:\Backup_Merged',
    [switch]$RunPhase1,
    [switch]$SkipExtraction,
    [switch]$SkipMerge
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# SOK-Common load — provides Write-SOKLog, Show-SOKBanner, Initialize-SOKLog,
# Get-ScriptLogDir, Save-SOKHistory. If the module is missing we define minimal
# stubs so the script degrades gracefully rather than dying at import time.
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
# Script-level constants — defined once here so every function can reference
# them without requiring global state or parameter threading.
# ---------------------------------------------------------------------------
$SCRIPT_NAME    = 'SOK-PAST-Verbose'
$SCRIPT_VERSION = '1.0.0'
$SOK_ROOT       = 'C:\Users\shelc\Documents\Journal\Projects\SOK'
$LOG_BASE       = "$SOK_ROOT\Logs"
$USER_PROFILE   = 'C:\Users\shelc'

# ---------------------------------------------------------------------------
#
#  MODULE 1 — InfraFix
#  Repair 5 known broken environmental invariants on CLAY_PC.
#  Each fix is its own explicit step so failures are isolated.
#
# ---------------------------------------------------------------------------
function Invoke-PASTInfraFix {
    [CmdletBinding()]
    param(
        [switch]$DryRun
    )

    Write-SOKLog "InfraFix: Starting. DryRun=$DryRun" 'INFO'

    # --- FIX-1: nvm4w junction ---
    # C:\nvm4w\nodejs should be a directory junction pointing at the currently
    # active versioned Node directory inside C:\ProgramData\nvm. When nvm
    # switches versions it updates this junction. If the junction is missing or
    # points nowhere we recreate it by finding the highest-versioned directory
    # under C:\ProgramData\nvm that contains node.exe.
    Write-SOKLog "InfraFix FIX-1: Checking nvm4w junction." 'INFO'
    $junctionPath = 'C:\nvm4w\nodejs'
    $nvmDataRoot  = 'C:\ProgramData\nvm'

    $junctionExists = Test-Path $junctionPath
    $junctionBroken = $false

    if ($junctionExists) {
        # Check if the junction target actually resolves. A broken junction shows
        # as a directory but Get-Item fails or LinkTarget is null/invalid.
        $junctionItem = Get-Item $junctionPath -ErrorAction SilentlyContinue
        if ($null -eq $junctionItem) {
            $junctionBroken = $true
        } elseif ($junctionItem.LinkType -eq 'Junction') {
            $target = $junctionItem.Target
            if (-not (Test-Path $target)) {
                $junctionBroken = $true
                Write-SOKLog "InfraFix FIX-1: Junction exists but target '$target' is missing." 'WARN'
            } else {
                Write-SOKLog "InfraFix FIX-1: Junction OK -> $target" 'INFO'
            }
        }
    } else {
        $junctionBroken = $true
        Write-SOKLog "InfraFix FIX-1: Junction does not exist at $junctionPath" 'WARN'
    }

    if ($junctionBroken) {
        # Find the best candidate: highest versioned node dir in ProgramData\nvm
        $bestNodeDir = $null
        if (Test-Path $nvmDataRoot) {
            $candidates = Get-ChildItem -Path $nvmDataRoot -Directory -ErrorAction SilentlyContinue |
                          Where-Object { Test-Path (Join-Path $_.FullName 'node.exe') } |
                          Sort-Object Name -Descending
            if ($candidates.Count -gt 0) {
                $bestNodeDir = $candidates[0].FullName
            }
        }

        if ($null -eq $bestNodeDir) {
            Write-SOKLog "InfraFix FIX-1: No valid node.exe dir found under $nvmDataRoot — cannot repair junction." 'WARN'
        } else {
            Write-SOKLog "InfraFix FIX-1: Best candidate node dir: $bestNodeDir" 'INFO'
            if ($DryRun) {
                Write-SOKLog "InfraFix FIX-1: [DRYRUN] Would remove $junctionPath and create junction -> $bestNodeDir" 'INFO'
            } else {
                # Remove the old junction/directory if it exists before recreating
                if (Test-Path $junctionPath) {
                    Remove-Item -Path $junctionPath -Force -Recurse -ErrorAction SilentlyContinue
                }
                New-Item -ItemType Junction -Path $junctionPath -Target $bestNodeDir -ErrorAction Stop | Out-Null
                Write-SOKLog "InfraFix FIX-1: Junction recreated $junctionPath -> $bestNodeDir" 'INFO'
            }
        }
    }

    # --- FIX-2: Orphaned UC OneDrive reparse point ---
    # The University of Cincinnati OneDrive folder can become an orphaned reparse
    # point after account changes. If the path exists as a reparse point but the
    # shell target is gone, we rename it to .bak (deprecate-never-delete).
    Write-SOKLog "InfraFix FIX-2: Checking UC OneDrive reparse point." 'INFO'
    $ucOneDrive = 'C:\Users\shelc\OneDrive - University of Cincinnati'

    if (Test-Path $ucOneDrive) {
        $ucItem = Get-Item $ucOneDrive -Force -ErrorAction SilentlyContinue
        $isReparsePoint = ($null -ne $ucItem) -and ($ucItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)

        if ($isReparsePoint) {
            # Try to enumerate the directory — if it throws, the reparse point is orphaned
            $accessible = $true
            try {
                Get-ChildItem -Path $ucOneDrive -ErrorAction Stop | Out-Null
            } catch {
                $accessible = $false
            }

            if (-not $accessible) {
                $bakPath = "$ucOneDrive.bak"
                Write-SOKLog "InfraFix FIX-2: Orphaned reparse point found. Will rename to .bak" 'WARN'
                if ($DryRun) {
                    Write-SOKLog "InfraFix FIX-2: [DRYRUN] Would rename '$ucOneDrive' to '$bakPath'" 'INFO'
                } else {
                    Rename-Item -Path $ucOneDrive -NewName "$($ucItem.Name).bak" -ErrorAction Stop
                    Write-SOKLog "InfraFix FIX-2: Renamed orphaned reparse point to $bakPath" 'INFO'
                }
            } else {
                Write-SOKLog "InfraFix FIX-2: UC OneDrive reparse point is accessible — OK." 'INFO'
            }
        } else {
            Write-SOKLog "InfraFix FIX-2: UC OneDrive path exists as a regular directory — OK." 'INFO'
        }
    } else {
        Write-SOKLog "InfraFix FIX-2: UC OneDrive path not found — nothing to do." 'INFO'
    }

    # --- FIX-3: Kibana node.exe shim ---
    # Chocolatey installs a shim (a tiny redirect executable) at
    # C:\ProgramData\chocolatey\bin\node.exe. The real node.exe is much larger.
    # If this file is under 256KB it is still a shim and will break Kibana.
    # We rename it to .bak so the real node.exe on PATH takes precedence.
    Write-SOKLog "InfraFix FIX-3: Checking Kibana node.exe shim." 'INFO'
    $kibanaNodPath = 'C:\ProgramData\chocolatey\bin\node.exe'
    $shimThresholdBytes = 256 * 1024  # 256 KB in bytes

    if (Test-Path $kibanaNodPath) {
        $nodeItem = Get-Item $kibanaNodPath -ErrorAction SilentlyContinue
        if ($null -ne $nodeItem) {
            if ($nodeItem.Length -lt $shimThresholdBytes) {
                $bakPath = "$kibanaNodPath.bak"
                Write-SOKLog "InfraFix FIX-3: node.exe at $kibanaNodPath is $($nodeItem.Length) bytes — shim detected." 'WARN'
                if ($DryRun) {
                    Write-SOKLog "InfraFix FIX-3: [DRYRUN] Would rename '$kibanaNodPath' to '$bakPath'" 'INFO'
                } else {
                    Rename-Item -Path $kibanaNodPath -NewName 'node.exe.bak' -ErrorAction Stop
                    Write-SOKLog "InfraFix FIX-3: Shim renamed to node.exe.bak" 'INFO'
                }
            } else {
                Write-SOKLog "InfraFix FIX-3: node.exe is $($nodeItem.Length) bytes — not a shim. OK." 'INFO'
            }
        }
    } else {
        Write-SOKLog "InfraFix FIX-3: $kibanaNodPath not found — nothing to do." 'INFO'
    }

    # --- FIX-4: Legacy SOK History directory ---
    # The old path SOK\History was relocated to SOK\Deprecated\History as part of
    # the deprecate-never-delete convention. If the old path still exists we move it.
    Write-SOKLog "InfraFix FIX-4: Checking legacy SOK History dir." 'INFO'
    $oldHistoryPath  = "$SOK_ROOT\History"
    $newHistoryPath  = "$SOK_ROOT\Deprecated\History"
    $deprecatedRoot  = "$SOK_ROOT\Deprecated"

    if (Test-Path $oldHistoryPath) {
        Write-SOKLog "InfraFix FIX-4: Legacy History dir found at $oldHistoryPath" 'WARN'
        if ($DryRun) {
            Write-SOKLog "InfraFix FIX-4: [DRYRUN] Would move '$oldHistoryPath' to '$newHistoryPath'" 'INFO'
        } else {
            # Ensure the Deprecated parent exists
            if (-not (Test-Path $deprecatedRoot)) {
                New-Item -ItemType Directory -Path $deprecatedRoot -Force | Out-Null
            }
            # Move (not delete) the directory — deprecate-never-delete
            Move-Item -Path $oldHistoryPath -Destination $newHistoryPath -ErrorAction Stop
            Write-SOKLog "InfraFix FIX-4: Moved History dir to $newHistoryPath" 'INFO'
        }
    } else {
        Write-SOKLog "InfraFix FIX-4: Legacy History dir not found — OK." 'INFO'
    }

    # --- FIX-5: Scoop shim repair ---
    # Scoop shims can become inconsistent after manual package changes. Running
    # `scoop update` regenerates shims and checks for broken installs. This is
    # the safest automated repair — it does not delete anything.
    Write-SOKLog "InfraFix FIX-5: Running scoop update to repair shims." 'INFO'
    $scoopExe = (Get-Command scoop -ErrorAction SilentlyContinue)

    if ($null -eq $scoopExe) {
        Write-SOKLog "InfraFix FIX-5: scoop not found on PATH — skipping." 'WARN'
    } else {
        if ($DryRun) {
            Write-SOKLog "InfraFix FIX-5: [DRYRUN] Would run: scoop update" 'INFO'
        } else {
            try {
                $scoopResult = & scoop update 2>&1
                Write-SOKLog "InfraFix FIX-5: scoop update completed. Output: $scoopResult" 'INFO'
            } catch {
                Write-SOKLog "InfraFix FIX-5: scoop update failed: $_" 'WARN'
            }
        }
    }

    Write-SOKLog "InfraFix: All 5 invariant checks complete." 'INFO'
}

# ---------------------------------------------------------------------------
#
#  MODULE 2 — Inventory
#  Snapshot the current system state: drives, junctions, packages, runtimes,
#  services. Output is written as JSON to SOK\Logs\Inventory\.
#
# ---------------------------------------------------------------------------
function Invoke-PASTInventory {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [ValidateRange(1,3)][int]$ScanCaliber = 2,
        [string]$OutputPath = ''
    )

    Write-SOKLog "Inventory: Starting. ScanCaliber=$ScanCaliber DryRun=$DryRun" 'INFO'

    # Build the output path now so we know where to write regardless of DryRun
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $inventoryLogDir = "$LOG_BASE\Inventory"

    if ($OutputPath -eq '') {
        $OutputPath = "$inventoryLogDir\SOK_Inventory_$timestamp.json"
    }

    # The inventory object we will build up section by section
    $inventory = [ordered]@{
        GeneratedAt  = (Get-Date -Format 'o')
        ScanCaliber  = $ScanCaliber
        MachineName  = $env:COMPUTERNAME
        Drives       = [System.Collections.Generic.List[hashtable]]::new()
        Junctions    = [System.Collections.Generic.List[hashtable]]::new()
        Packages     = [ordered]@{}
        Runtimes     = [ordered]@{}
        Services     = [System.Collections.Generic.List[hashtable]]::new()
        Hashes       = [ordered]@{}
    }

    # --- CALIBER 1+: Drives ---
    Write-SOKLog "Inventory: Collecting drives." 'INFO'
    $drives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue
    foreach ($drive in $drives) {
        $driveInfo = @{
            Name       = $drive.Name
            Root       = $drive.Root
            UsedGB     = [math]::Round($drive.Used / 1GB, 2)
            FreeGB     = [math]::Round($drive.Free / 1GB, 2)
            TotalGB    = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
        }
        $inventory.Drives.Add($driveInfo)
    }
    Write-SOKLog "Inventory: Found $($inventory.Drives.Count) drives." 'INFO'

    # --- CALIBER 1+: Junctions ---
    # We scan several key locations for directory junctions. This is done with a
    # simple recursive walk — no parallelism, just breadth-first through the tree.
    Write-SOKLog "Inventory: Collecting junctions (scanning common roots)." 'INFO'
    $junctionScanRoots = @('C:\', 'C:\Users\shelc', 'C:\ProgramData')

    foreach ($scanRoot in $junctionScanRoots) {
        if (-not (Test-Path $scanRoot)) { continue }

        # Get-ChildItem -Recurse can be very slow on C:\; we limit to depth 4
        # for the system root and go deeper for user dirs.
        $depthLimit = if ($scanRoot -eq 'C:\') { 3 } else { 5 }

        try {
            $items = Get-ChildItem -Path $scanRoot -Recurse -Directory -Depth $depthLimit `
                                   -ErrorAction SilentlyContinue -Force
            foreach ($item in $items) {
                if ($item.LinkType -eq 'Junction') {
                    $jEntry = @{
                        Path        = $item.FullName
                        Target      = $item.Target
                        TargetValid = (Test-Path $item.Target)
                    }
                    $inventory.Junctions.Add($jEntry)
                }
            }
        } catch {
            Write-SOKLog "Inventory: Error scanning $scanRoot for junctions: $_" 'WARN'
        }
    }
    Write-SOKLog "Inventory: Found $($inventory.Junctions.Count) junctions." 'INFO'

    # --- CALIBER 2+: Packages and Services ---
    if ($ScanCaliber -ge 2) {
        Write-SOKLog "Inventory: Caliber 2 — collecting packages and services." 'INFO'

        # Chocolatey packages
        $chocoList = [System.Collections.Generic.List[hashtable]]::new()
        $chocoCmd  = Get-Command choco -ErrorAction SilentlyContinue
        if ($null -ne $chocoCmd) {
            try {
                $chocoOutput = & choco list --local-only --no-color 2>&1
                foreach ($line in $chocoOutput) {
                    # Each line looks like "packagename 1.2.3"
                    if ($line -match '^([^\s]+)\s+([\d\.]+)') {
                        $chocoList.Add(@{ Name = $Matches[1]; Version = $Matches[2] })
                    }
                }
                Write-SOKLog "Inventory: Choco packages found: $($chocoList.Count)" 'INFO'
            } catch {
                Write-SOKLog "Inventory: choco list failed: $_" 'WARN'
            }
        } else {
            Write-SOKLog "Inventory: choco not found — skipping." 'INFO'
        }
        $inventory.Packages['Chocolatey'] = $chocoList

        # Scoop packages
        $scoopList = [System.Collections.Generic.List[hashtable]]::new()
        $scoopCmd  = Get-Command scoop -ErrorAction SilentlyContinue
        if ($null -ne $scoopCmd) {
            try {
                $scoopOutput = & scoop list 2>&1
                foreach ($line in $scoopOutput) {
                    # Scoop list output: "  name  version  bucket  updated"
                    if ($line -match '^\s+(\S+)\s+([\d\.\w\-]+)') {
                        $scoopList.Add(@{ Name = $Matches[1]; Version = $Matches[2] })
                    }
                }
                Write-SOKLog "Inventory: Scoop packages found: $($scoopList.Count)" 'INFO'
            } catch {
                Write-SOKLog "Inventory: scoop list failed: $_" 'WARN'
            }
        } else {
            Write-SOKLog "Inventory: scoop not found — skipping." 'INFO'
        }
        $inventory.Packages['Scoop'] = $scoopList

        # Winget packages
        $wingetList = [System.Collections.Generic.List[hashtable]]::new()
        $wingetCmd  = Get-Command winget -ErrorAction SilentlyContinue
        if ($null -ne $wingetCmd) {
            try {
                $wingetOutput = & winget list --accept-source-agreements 2>&1
                $headerPassed = $false
                foreach ($line in $wingetOutput) {
                    # Skip header lines (separator line starts with -)
                    if ($line -match '^-{3,}') { $headerPassed = $true; continue }
                    if (-not $headerPassed)     { continue }
                    if ($line.Trim() -eq '')    { continue }
                    # Winget line: "Name   Id   Version   Source"
                    # Use simple split — columns are space-separated with variable width
                    $parts = $line -split '\s{2,}' | Where-Object { $_ -ne '' }
                    if ($parts.Count -ge 3) {
                        $wingetList.Add(@{ Name = $parts[0]; Id = $parts[1]; Version = $parts[2] })
                    }
                }
                Write-SOKLog "Inventory: Winget packages found: $($wingetList.Count)" 'INFO'
            } catch {
                Write-SOKLog "Inventory: winget list failed: $_" 'WARN'
            }
        } else {
            Write-SOKLog "Inventory: winget not found — skipping." 'INFO'
        }
        $inventory.Packages['Winget'] = $wingetList

        # pip packages (global)
        $pipList = [System.Collections.Generic.List[hashtable]]::new()
        $pipCmd  = Get-Command pip -ErrorAction SilentlyContinue
        if ($null -ne $pipCmd) {
            try {
                $pipOutput = & pip list --format=columns 2>&1
                $headerPassed = $false
                foreach ($line in $pipOutput) {
                    if ($line -match '^-{3,}') { $headerPassed = $true; continue }
                    if (-not $headerPassed)    { continue }
                    if ($line.Trim() -eq '')   { continue }
                    $parts = $line -split '\s+' | Where-Object { $_ -ne '' }
                    if ($parts.Count -ge 2) {
                        $pipList.Add(@{ Name = $parts[0]; Version = $parts[1] })
                    }
                }
                Write-SOKLog "Inventory: pip packages found: $($pipList.Count)" 'INFO'
            } catch {
                Write-SOKLog "Inventory: pip list failed: $_" 'WARN'
            }
        } else {
            Write-SOKLog "Inventory: pip not found — skipping." 'INFO'
        }
        $inventory.Packages['Pip'] = $pipList

        # npm global packages
        $npmList = [System.Collections.Generic.List[hashtable]]::new()
        $npmCmd  = Get-Command npm -ErrorAction SilentlyContinue
        if ($null -ne $npmCmd) {
            try {
                $npmOutput = & npm list -g --depth=0 2>&1
                foreach ($line in $npmOutput) {
                    # npm list -g output: "+-- packagename@1.2.3"
                    if ($line -match '[+\\`]-{2}\s+(.+?)@([\d\.\w\-]+)') {
                        $npmList.Add(@{ Name = $Matches[1]; Version = $Matches[2] })
                    }
                }
                Write-SOKLog "Inventory: npm global packages found: $($npmList.Count)" 'INFO'
            } catch {
                Write-SOKLog "Inventory: npm list failed: $_" 'WARN'
            }
        } else {
            Write-SOKLog "Inventory: npm not found — skipping." 'INFO'
        }
        $inventory.Packages['Npm'] = $npmList

        # Runtime versions — collect version strings for key runtimes
        $runtimes = [ordered]@{}
        $runtimeChecks = @(
            @{ Name = 'Node';   Cmd = 'node';   Args = @('--version') },
            @{ Name = 'Python'; Cmd = 'python'; Args = @('--version') },
            @{ Name = 'Java';   Cmd = 'java';   Args = @('-version') },
            @{ Name = 'Ruby';   Cmd = 'ruby';   Args = @('--version') },
            @{ Name = 'Go';     Cmd = 'go';     Args = @('version')   },
            @{ Name = 'Rust';   Cmd = 'rustc';  Args = @('--version') },
            @{ Name = 'dotnet'; Cmd = 'dotnet'; Args = @('--version') }
        )

        foreach ($rt in $runtimeChecks) {
            $cmd = Get-Command $rt.Cmd -ErrorAction SilentlyContinue
            if ($null -ne $cmd) {
                try {
                    $versionOutput = & $rt.Cmd @($rt.Args) 2>&1
                    $runtimes[$rt.Name] = ($versionOutput | Out-String).Trim()
                } catch {
                    $runtimes[$rt.Name] = "ERROR: $_"
                }
            } else {
                $runtimes[$rt.Name] = 'not found'
            }
        }
        $inventory.Runtimes = $runtimes

        # Services — collect running services that are relevant to dev/SOK work
        Write-SOKLog "Inventory: Collecting services." 'INFO'
        $services = Get-Service -ErrorAction SilentlyContinue |
                    Where-Object { $_.Status -eq 'Running' }
        foreach ($svc in $services) {
            $svcEntry = @{
                Name        = $svc.Name
                DisplayName = $svc.DisplayName
                Status      = $svc.Status.ToString()
                StartType   = $svc.StartType.ToString()
            }
            $inventory.Services.Add($svcEntry)
        }
        Write-SOKLog "Inventory: Running services: $($inventory.Services.Count)" 'INFO'
    }

    # --- CALIBER 3: SHA-256 hashes of key binaries ---
    # This is the slowest scan. We hash a specific set of critical executables
    # rather than a recursive directory walk to keep it tractable.
    if ($ScanCaliber -ge 3) {
        Write-SOKLog "Inventory: Caliber 3 — computing SHA-256 hashes of key binaries." 'INFO'
        $hashTargets = @(
            'C:\nvm4w\nodejs\node.exe',
            'C:\ProgramData\chocolatey\bin\node.exe',
            'C:\Windows\System32\cmd.exe',
            'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
        )

        foreach ($target in $hashTargets) {
            if (Test-Path $target) {
                try {
                    $hashResult = Get-FileHash -Path $target -Algorithm SHA256 -ErrorAction Stop
                    $inventory.Hashes[$target] = $hashResult.Hash
                } catch {
                    $inventory.Hashes[$target] = "ERROR: $_"
                }
            } else {
                $inventory.Hashes[$target] = 'not found'
            }
        }
        Write-SOKLog "Inventory: Hashing complete." 'INFO'
    }

    # --- Write output ---
    $jsonOutput = $inventory | ConvertTo-Json -Depth 10

    if ($DryRun) {
        Write-SOKLog "Inventory: [DRYRUN] Would write inventory to $OutputPath" 'INFO'
    } else {
        $inventoryLogDirResolved = Split-Path $OutputPath -Parent
        if (-not (Test-Path $inventoryLogDirResolved)) {
            New-Item -ItemType Directory -Path $inventoryLogDirResolved -Force | Out-Null
        }
        $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8 -ErrorAction Stop
        Write-SOKLog "Inventory: Written to $OutputPath" 'INFO'
    }

    Write-SOKLog "Inventory: Complete." 'INFO'
    return $OutputPath
}

# ---------------------------------------------------------------------------
#
#  MODULE 3 — SpaceAudit
#  Classify top-level and second-level directories on C:\ by storage verdict.
#  Each directory gets one of: KEEP, CLEAN, OFFLOAD, DB_OFFLOAD, INVESTIGATE, UNKNOWN
#
# ---------------------------------------------------------------------------
function Invoke-PASTSpaceAudit {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [int]$MinSizeKB = 21138
    )

    Write-SOKLog "SpaceAudit: Starting. MinSizeKB=$MinSizeKB DryRun=$DryRun" 'INFO'

    $timestamp    = Get-Date -Format 'yyyyMMdd_HHmmss'
    $auditLogDir  = "$LOG_BASE\SpaceAudit"
    $outputPath   = "$auditLogDir\SOK_SpaceAudit_$timestamp.json"

    # Verdict classification patterns.
    # We use simple -match tests (no pre-compiled regex) for readability.
    # KEEP: Paths that are essential system or user infrastructure — do not touch.
    $keepPatterns = @(
        'Windows', 'Program Files', 'Users\\shelc\\AppData\\Roaming',
        'Users\\shelc\\Documents', 'ProgramData\\Microsoft',
        'System Volume Information', '\$Recycle\.Bin'
    )

    # CLEAN: Caches, temp files, build artifacts that can be deleted safely.
    $cleanPatterns = @(
        'Temp', 'tmp', '\.cache', 'node_modules', '__pycache__',
        'dist\\', '\.gradle', '\.m2', 'AppData\\Local\\Temp',
        'AppData\\Local\\pip', 'AppData\\Local\\npm-cache'
    )

    # OFFLOAD: Large toolchains that could be moved to another drive via junction.
    $offloadPatterns = @(
        'nvm4w', 'ProgramData\\nvm', 'ProgramData\\chocolatey',
        'scoop', 'miniconda', 'anaconda', 'sdk', 'Android'
    )

    # DB_OFFLOAD: Database directories — should live on fast dedicated storage.
    $dbOffloadPatterns = @(
        'MongoDB', 'PostgreSQL', 'MySQL', 'elasticsearch', 'kibana',
        'ProgramData\\MongoDB', 'ProgramData\\PostgreSQL'
    )

    # INVESTIGATE: Stale, anomalous, or unexpectedly large dirs.
    $investigatePatterns = @(
        'Backup', 'Archive', 'OLD', 'old_', '_old', 'bak', '\.bak'
    )

    # Function to classify a single path string against our pattern lists.
    # Returns the verdict string.
    function Get-SpaceVerdict {
        param([string]$Path)

        foreach ($pat in $dbOffloadPatterns) {
            if ($Path -match $pat) { return 'DB_OFFLOAD' }
        }
        foreach ($pat in $offloadPatterns) {
            if ($Path -match $pat) { return 'OFFLOAD' }
        }
        foreach ($pat in $cleanPatterns) {
            if ($Path -match $pat) { return 'CLEAN' }
        }
        foreach ($pat in $investigatePatterns) {
            if ($Path -match $pat) { return 'INVESTIGATE' }
        }
        foreach ($pat in $keepPatterns) {
            if ($Path -match $pat) { return 'KEEP' }
        }
        return 'UNKNOWN'
    }

    $results = [System.Collections.Generic.List[hashtable]]::new()

    # We scan the top two levels of C:\ — going deeper would be too slow for a
    # simple sequential scan and the verdicts are most meaningful at this level.
    $topDirs = Get-ChildItem -Path 'C:\' -Directory -Force -ErrorAction SilentlyContinue

    foreach ($topDir in $topDirs) {
        # Measure size using robocopy /L (list-only, no copy) which is much faster
        # than Get-ChildItem -Recurse for large trees. Fall back to 0 on error.
        $sizeMB = 0
        try {
            # Use robocopy to count bytes: /L = list only, /S = subdirs, /NP = no progress
            # /BYTES = byte counts, /NFL /NDL = no file/dir lists, /NJH /NJS = no headers
            $roboOutput = & robocopy $topDir.FullName 'C:\NUL' /L /S /NP /BYTES /NFL /NDL /NJH 2>&1
            foreach ($roboLine in $roboOutput) {
                if ($roboLine -match 'Bytes\s*:\s*([\d\.]+)\s*([\w]*)') {
                    # Robocopy reports in bytes; convert to MB
                    $rawVal  = [double]$Matches[1]
                    $rawUnit = $Matches[2].ToLower()
                    $sizeMB  = switch ($rawUnit) {
                        'g'  { $rawVal * 1024 }
                        'm'  { $rawVal }
                        'k'  { $rawVal / 1024 }
                        default { $rawVal / 1MB }
                    }
                    break
                }
            }
        } catch {
            Write-SOKLog "SpaceAudit: Could not measure size of $($topDir.FullName): $_" 'WARN'
        }

        $sizeKB  = $sizeMB * 1024
        $verdict = Get-SpaceVerdict -Path $topDir.FullName

        # Only include in results if above the minimum size threshold OR if verdict
        # is actionable (not KEEP/UNKNOWN) — we always want to see CLEAN/OFFLOAD/DB_OFFLOAD
        if ($sizeKB -ge $MinSizeKB -or $verdict -in @('CLEAN', 'OFFLOAD', 'DB_OFFLOAD', 'INVESTIGATE')) {
            $entry = @{
                Path    = $topDir.FullName
                SizeMB  = [math]::Round($sizeMB, 2)
                Verdict = $verdict
            }
            $results.Add($entry)
            Write-SOKLog "SpaceAudit: $($topDir.Name) → $verdict ($([math]::Round($sizeMB,1)) MB)" 'INFO'
        }
    }

    # Build summary counts by verdict
    $summary = [ordered]@{
        GeneratedAt  = (Get-Date -Format 'o')
        MinSizeKB    = $MinSizeKB
        TotalScanned = $results.Count
        ByVerdict    = [ordered]@{
            KEEP        = ($results | Where-Object { $_.Verdict -eq 'KEEP' }).Count
            CLEAN       = ($results | Where-Object { $_.Verdict -eq 'CLEAN' }).Count
            OFFLOAD     = ($results | Where-Object { $_.Verdict -eq 'OFFLOAD' }).Count
            DB_OFFLOAD  = ($results | Where-Object { $_.Verdict -eq 'DB_OFFLOAD' }).Count
            INVESTIGATE = ($results | Where-Object { $_.Verdict -eq 'INVESTIGATE' }).Count
            UNKNOWN     = ($results | Where-Object { $_.Verdict -eq 'UNKNOWN' }).Count
        }
        Entries = $results
    }

    $jsonOutput = $summary | ConvertTo-Json -Depth 10

    if ($DryRun) {
        Write-SOKLog "SpaceAudit: [DRYRUN] Would write audit report to $outputPath" 'INFO'
    } else {
        if (-not (Test-Path $auditLogDir)) {
            New-Item -ItemType Directory -Path $auditLogDir -Force | Out-Null
        }
        $jsonOutput | Out-File -FilePath $outputPath -Encoding UTF8 -ErrorAction Stop
        Write-SOKLog "SpaceAudit: Written to $outputPath" 'INFO'
    }

    Write-SOKLog "SpaceAudit: Complete. $($results.Count) entries classified." 'INFO'
    return $outputPath
}

# ---------------------------------------------------------------------------
#
#  MODULE 4 — Restructure
#  Scan backup and user directories for structural debt:
#   - Excessive nesting depth
#   - Recursive backup patterns (backup-of-backup)
#   - Flattened paths (dir names that encode path separators as underscores)
#   - Duplicate directory names (same name 3+ times under a root)
#
# ---------------------------------------------------------------------------
function Invoke-PASTRestructure {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [string[]]$Targets,
        [int]$MaxDepth = 13
    )

    Write-SOKLog "Restructure: Starting. MaxDepth=$MaxDepth Targets=$($Targets -join ', ') DryRun=$DryRun" 'INFO'

    $timestamp       = Get-Date -Format 'yyyyMMdd_HHmmss'
    $restructureLogDir = "$LOG_BASE\Restructure"
    $outputPath      = "$restructureLogDir\SOK_Restructure_$timestamp.json"

    $allFindings = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($targetRoot in $Targets) {
        if (-not (Test-Path $targetRoot)) {
            Write-SOKLog "Restructure: Target '$targetRoot' not found — skipping." 'WARN'
            continue
        }

        Write-SOKLog "Restructure: Scanning $targetRoot" 'INFO'

        # Collect all directories under this root (up to MaxDepth + some buffer for detection)
        $allDirs = [System.Collections.Generic.List[System.IO.DirectoryInfo]]::new()
        try {
            $found = Get-ChildItem -Path $targetRoot -Recurse -Directory -Depth ($MaxDepth + 3) `
                                   -ErrorAction SilentlyContinue -Force
            foreach ($d in $found) { $allDirs.Add($d) }
        } catch {
            Write-SOKLog "Restructure: Error during recursive scan of $targetRoot : $_" 'WARN'
        }

        # --- Check 1: Excessive nesting depth ---
        # Calculate the nesting depth relative to the target root.
        # We count path separators rather than doing filesystem calls.
        $rootDepth = ($targetRoot -split '\\').Count

        foreach ($dir in $allDirs) {
            $dirDepth = ($dir.FullName -split '\\').Count
            $relativeDepth = $dirDepth - $rootDepth

            if ($relativeDepth -gt $MaxDepth) {
                $finding = @{
                    Type      = 'ExcessiveNesting'
                    Path      = $dir.FullName
                    Depth     = $relativeDepth
                    Threshold = $MaxDepth
                    Root      = $targetRoot
                }
                $allFindings.Add($finding)
            }
        }

        # --- Check 2: Recursive backup patterns ---
        # A "backup of a backup" is when a directory name contains the word "backup"
        # AND one of its ancestor directories also contains "backup".
        foreach ($dir in $allDirs) {
            $dirNameLower = $dir.Name.ToLower()
            $isBackupName = $dirNameLower -match 'backup|archive|bak'

            if ($isBackupName) {
                # Walk up the path segments to see if an ancestor is also a backup
                $parentPath  = $dir.Parent.FullName
                $ancestorIsBackup = $false

                while ($parentPath.Length -gt $targetRoot.Length) {
                    $parentName = Split-Path $parentPath -Leaf
                    if ($parentName.ToLower() -match 'backup|archive|bak') {
                        $ancestorIsBackup = $true
                        break
                    }
                    $parentPath = Split-Path $parentPath -Parent
                }

                if ($ancestorIsBackup) {
                    $finding = @{
                        Type   = 'RecursiveBackupPattern'
                        Path   = $dir.FullName
                        Reason = 'Backup/archive directory nested inside another backup/archive'
                        Root   = $targetRoot
                    }
                    $allFindings.Add($finding)
                }
            }
        }

        # --- Check 3: Flattened paths ---
        # A "flattened" directory is one whose name contains sequences of multiple
        # underscores or contains what looks like path separators encoded as underscores.
        # The heuristic: name has 4+ underscore-separated segments that each look like
        # directory name fragments (no spaces, mixed case, reasonable length).
        foreach ($dir in $allDirs) {
            $nameParts = $dir.Name -split '_'
            # Heuristic: if splitting on _ gives 5+ non-trivial segments, likely flattened
            $substantiveParts = $nameParts | Where-Object { $_.Length -ge 2 }
            if ($substantiveParts.Count -ge 5) {
                $finding = @{
                    Type     = 'FlattenedPath'
                    Path     = $dir.FullName
                    SegCount = $substantiveParts.Count
                    Reason   = 'Directory name contains many underscore-separated segments (possible encoded path)'
                    Root     = $targetRoot
                }
                $allFindings.Add($finding)
            }
        }

        # --- Check 4: Duplicate directory names ---
        # Count occurrences of each directory name under this root.
        # If any name appears 3+ times, flag all instances.
        $nameFrequency = [ordered]@{}
        foreach ($dir in $allDirs) {
            $name = $dir.Name.ToLower()
            if ($nameFrequency.Contains($name)) {
                $nameFrequency[$name] += 1
            } else {
                $nameFrequency[$name] = 1
            }
        }

        $duplicateNames = $nameFrequency.Keys | Where-Object { $nameFrequency[$_] -ge 3 }

        foreach ($dupName in $duplicateNames) {
            # Collect all paths with this name
            $instances = $allDirs | Where-Object { $_.Name.ToLower() -eq $dupName }
            $finding = @{
                Type      = 'DuplicateDirName'
                Name      = $dupName
                Count     = $nameFrequency[$dupName]
                Instances = @($instances | ForEach-Object { $_.FullName })
                Root      = $targetRoot
            }
            $allFindings.Add($finding)
        }
    }

    # Build output
    $report = [ordered]@{
        GeneratedAt  = (Get-Date -Format 'o')
        Targets      = $Targets
        MaxDepth     = $MaxDepth
        TotalFindings = $allFindings.Count
        ByType       = [ordered]@{
            ExcessiveNesting      = ($allFindings | Where-Object { $_.Type -eq 'ExcessiveNesting' }).Count
            RecursiveBackupPattern= ($allFindings | Where-Object { $_.Type -eq 'RecursiveBackupPattern' }).Count
            FlattenedPath         = ($allFindings | Where-Object { $_.Type -eq 'FlattenedPath' }).Count
            DuplicateDirName      = ($allFindings | Where-Object { $_.Type -eq 'DuplicateDirName' }).Count
        }
        Findings = $allFindings
    }

    $jsonOutput = $report | ConvertTo-Json -Depth 10

    if ($DryRun) {
        Write-SOKLog "Restructure: [DRYRUN] Would write report to $outputPath" 'INFO'
        Write-SOKLog "Restructure: Found $($allFindings.Count) total findings." 'INFO'
    } else {
        if (-not (Test-Path $restructureLogDir)) {
            New-Item -ItemType Directory -Path $restructureLogDir -Force | Out-Null
        }
        $jsonOutput | Out-File -FilePath $outputPath -Encoding UTF8 -ErrorAction Stop
        Write-SOKLog "Restructure: Written to $outputPath" 'INFO'
    }

    Write-SOKLog "Restructure: Complete. $($allFindings.Count) findings across $($Targets.Count) targets." 'INFO'
    return $outputPath
}

# ---------------------------------------------------------------------------
#
#  MODULE 5 — CompareSnapshots
#  Diff two SOK-Archiver flat-file .txt snapshots using symbolic grammar:
#   [+] Addition  — line in new, not in old
#   [-] Subtraction — line in old, not in new
#   [x] Rescinded — was an addition in old diff, now removed (not implemented here:
#                   applies when chaining diffs; we flag as [-] for simplicity)
#   [*] Revision  — same path, different metadata on same line prefix
#   [~] Mixed     — section has both additions and subtractions
#
# ---------------------------------------------------------------------------
function Invoke-PASTCompareSnapshots {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [string]$OldSnapshot,
        [string]$NewSnapshot,
        [double]$AutoApproveThreshold = 16.66,
        [string]$OutputDir = ''
    )

    Write-SOKLog "CompareSnapshots: Starting. DryRun=$DryRun" 'INFO'

    # Validate inputs
    if ([string]::IsNullOrWhiteSpace($OldSnapshot) -or [string]::IsNullOrWhiteSpace($NewSnapshot)) {
        Write-SOKLog "CompareSnapshots: -OldSnapshot and -NewSnapshot are required." 'WARN'
        return
    }
    if (-not (Test-Path $OldSnapshot)) {
        Write-SOKLog "CompareSnapshots: OldSnapshot not found: $OldSnapshot" 'WARN'
        return
    }
    if (-not (Test-Path $NewSnapshot)) {
        Write-SOKLog "CompareSnapshots: NewSnapshot not found: $NewSnapshot" 'WARN'
        return
    }

    $timestamp  = Get-Date -Format 'yyyyMMdd_HHmmss'
    $resolvedOutputDir = if ($OutputDir -eq '') { $ComparatorOutputDir } else { $OutputDir }
    $outputPath = "$resolvedOutputDir\SOK_Compare_$timestamp.txt"

    # Read both snapshot files with Get-Content (simple, not StreamReader).
    # Note: for very large snapshots (>500k lines) this will be slow and memory-heavy.
    # That is acceptable for the verbose reference implementation.
    Write-SOKLog "CompareSnapshots: Reading old snapshot from $OldSnapshot" 'INFO'
    $oldLines = Get-Content -Path $OldSnapshot -Encoding UTF8 -ErrorAction Stop

    Write-SOKLog "CompareSnapshots: Reading new snapshot from $NewSnapshot" 'INFO'
    $newLines = Get-Content -Path $NewSnapshot -Encoding UTF8 -ErrorAction Stop

    Write-SOKLog "CompareSnapshots: Old=$($oldLines.Count) lines, New=$($newLines.Count) lines." 'INFO'

    # Build hash sets for O(1) membership checks.
    # We use a hashtable rather than HashSet[string] to stay readable.
    $oldSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $newSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

    foreach ($line in $oldLines) { $oldSet.Add($line) | Out-Null }
    foreach ($line in $newLines) { $newSet.Add($line) | Out-Null }

    # Compute diff
    $additions    = [System.Collections.Generic.List[string]]::new()
    $subtractions = [System.Collections.Generic.List[string]]::new()

    # Lines in new but not in old = additions
    foreach ($line in $newLines) {
        if (-not $oldSet.Contains($line)) {
            $additions.Add("[+] $line")
        }
    }

    # Lines in old but not in new = subtractions
    foreach ($line in $oldLines) {
        if (-not $newSet.Contains($line)) {
            $subtractions.Add("[-] $line")
        }
    }

    $totalChangedLines = $additions.Count + $subtractions.Count
    $totalBaseLines    = $oldLines.Count
    $changePercent     = if ($totalBaseLines -gt 0) {
        [math]::Round(($totalChangedLines / $totalBaseLines) * 100, 2)
    } else { 0.0 }

    Write-SOKLog "CompareSnapshots: +$($additions.Count) -$($subtractions.Count) = $changePercent% change" 'INFO'

    # Gate on AutoApproveThreshold — if change is large, require confirmation
    if ($changePercent -gt $AutoApproveThreshold -and -not $DryRun) {
        Write-Host ""
        Write-Host "WARNING: $changePercent% of lines changed (threshold: $AutoApproveThreshold%)"
        Write-Host "Additions:    $($additions.Count)"
        Write-Host "Subtractions: $($subtractions.Count)"
        Write-Host ""
        $confirm = Read-Host "Proceed with writing diff report? [y/N]"
        if ($confirm.ToLower() -ne 'y') {
            Write-SOKLog "CompareSnapshots: Operator declined — aborting." 'WARN'
            return
        }
    }

    # Build the diff report lines
    $reportLines = [System.Collections.Generic.List[string]]::new()
    $reportLines.Add("# SOK Snapshot Comparison Report")
    $reportLines.Add("# Generated: $(Get-Date -Format 'o')")
    $reportLines.Add("# Old: $OldSnapshot ($($oldLines.Count) lines)")
    $reportLines.Add("# New: $NewSnapshot ($($newLines.Count) lines)")
    $reportLines.Add("# Changes: +$($additions.Count) -$($subtractions.Count) ($changePercent%)")
    $reportLines.Add("# Symbol grammar: [+]=Addition [-]=Subtraction [*]=Revision [~]=Mixed")
    $reportLines.Add("")
    $reportLines.Add("## ADDITIONS ($($additions.Count))")
    foreach ($a in $additions) { $reportLines.Add($a) }
    $reportLines.Add("")
    $reportLines.Add("## SUBTRACTIONS ($($subtractions.Count))")
    foreach ($s in $subtractions) { $reportLines.Add($s) }

    if ($DryRun) {
        Write-SOKLog "CompareSnapshots: [DRYRUN] Would write diff report to $outputPath" 'INFO'
    } else {
        if (-not (Test-Path $resolvedOutputDir)) {
            New-Item -ItemType Directory -Path $resolvedOutputDir -Force | Out-Null
        }
        $reportLines | Out-File -FilePath $outputPath -Encoding UTF8 -ErrorAction Stop
        Write-SOKLog "CompareSnapshots: Diff report written to $outputPath" 'INFO'
    }

    Write-SOKLog "CompareSnapshots: Complete." 'INFO'
    return $outputPath
}

# ---------------------------------------------------------------------------
#
#  MODULE 6 — BackupRestructure
#  Transform E:\Backup_Archive through 3 phases:
#   Phase 1 (opt-in): Delete raw pre-extracted folder duplicates via robocopy /MIR
#   Phase 2: Extract .7z archives in-place (7-Zip, skip continuation volumes)
#   Phase 3: Merge to E:\Backup_Merged with derivation tags (_a1, _a2, _b, _c, _d)
#
# ---------------------------------------------------------------------------
function Invoke-PASTBackupRestructure {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [string]$ArchiveRoot    = 'E:\Backup_Archive',
        [string]$MergeTarget    = 'E:\Backup_Merged',
        [switch]$RunPhase1,
        [switch]$SkipExtraction,
        [switch]$SkipMerge
    )

    Write-SOKLog "BackupRestructure: Starting. ArchiveRoot=$ArchiveRoot MergeTarget=$MergeTarget DryRun=$DryRun" 'INFO'

    if (-not (Test-Path $ArchiveRoot)) {
        Write-SOKLog "BackupRestructure: ArchiveRoot '$ArchiveRoot' not found. Aborting." 'WARN'
        return
    }

    # -----------------------------------------------------------------------
    # PHASE 1 (opt-in): Delete raw pre-extracted folder duplicates
    # A "pre-extracted duplicate" is a directory that has the same name as a
    # .7z archive in the same parent (e.g., "MyDocs" alongside "MyDocs.7z").
    # These are the raw folders that were archived and then not cleaned up.
    # We use robocopy /MIR against an empty temp dir to delete the contents,
    # then remove the now-empty directory.
    # -----------------------------------------------------------------------
    if ($RunPhase1) {
        Write-SOKLog "BackupRestructure: Phase 1 — deleting raw pre-extracted duplicates." 'INFO'

        # Find all .7z files (non-continuation, i.e., not .7z.001, .7z.002, etc.)
        $sevenZipFiles = Get-ChildItem -Path $ArchiveRoot -Recurse -File -ErrorAction SilentlyContinue |
                         Where-Object { $_.Extension -eq '.7z' -and $_.Name -notmatch '\.\d{3}$' }

        foreach ($archiveFile in $sevenZipFiles) {
            # The raw duplicate would be a directory with the same name (minus .7z)
            $rawDirName = [System.IO.Path]::GetFileNameWithoutExtension($archiveFile.FullName)
            $rawDirPath = Join-Path $archiveFile.DirectoryName $rawDirName

            if (Test-Path $rawDirPath -PathType Container) {
                Write-SOKLog "BackupRestructure: Phase 1 — found duplicate raw dir: $rawDirPath" 'WARN'

                if ($DryRun) {
                    Write-SOKLog "BackupRestructure: Phase 1 [DRYRUN] Would delete $rawDirPath" 'INFO'
                } else {
                    # Use robocopy /MIR to empty the directory (more reliable than Remove-Item -Recurse
                    # on long paths), then remove the empty shell.
                    $emptyTemp = [System.IO.Path]::GetTempPath() + 'SOK_EmptyMirrorSource'
                    if (-not (Test-Path $emptyTemp)) {
                        New-Item -ItemType Directory -Path $emptyTemp -Force | Out-Null
                    }

                    try {
                        & robocopy $emptyTemp $rawDirPath /MIR /NFL /NDL /NJH /NJS /NP 2>&1 | Out-Null
                        Remove-Item -Path $rawDirPath -Force -Recurse -ErrorAction Stop
                        Write-SOKLog "BackupRestructure: Phase 1 — deleted $rawDirPath" 'INFO'
                    } catch {
                        Write-SOKLog "BackupRestructure: Phase 1 — failed to delete $rawDirPath : $_" 'WARN'
                    }
                }
            }
        }
        Write-SOKLog "BackupRestructure: Phase 1 complete." 'INFO'
    } else {
        Write-SOKLog "BackupRestructure: Phase 1 skipped (use -RunPhase1 to enable)." 'INFO'
    }

    # -----------------------------------------------------------------------
    # PHASE 2: Extract .7z archives in-place
    # For each .7z archive (non-continuation volume), extract into a sibling
    # directory named the same as the archive (minus .7z extension).
    # Skip if the extraction directory already exists (idempotent).
    # -----------------------------------------------------------------------
    if (-not $SkipExtraction) {
        Write-SOKLog "BackupRestructure: Phase 2 — extracting .7z archives in-place." 'INFO'

        $sevenZipExe = Get-Command '7z' -ErrorAction SilentlyContinue
        if ($null -eq $sevenZipExe) {
            # Try the default install path
            $sevenZipExe = 'C:\Program Files\7-Zip\7z.exe'
            if (-not (Test-Path $sevenZipExe)) {
                Write-SOKLog "BackupRestructure: Phase 2 — 7z not found. Skipping extraction." 'WARN'
                $sevenZipExe = $null
            }
        } else {
            $sevenZipExe = $sevenZipExe.Source
        }

        if ($null -ne $sevenZipExe) {
            # Collect .7z files again (phase 1 may have removed some duplicates)
            $archivesToExtract = Get-ChildItem -Path $ArchiveRoot -Recurse -File -ErrorAction SilentlyContinue |
                                 Where-Object { $_.Name -match '\.7z$' -and $_.Name -notmatch '\.\d{3,}\.7z$' }

            foreach ($archive in $archivesToExtract) {
                $extractDir = Join-Path $archive.DirectoryName `
                                        ([System.IO.Path]::GetFileNameWithoutExtension($archive.FullName))

                if (Test-Path $extractDir) {
                    Write-SOKLog "BackupRestructure: Phase 2 — $($archive.Name) already extracted, skipping." 'INFO'
                    continue
                }

                Write-SOKLog "BackupRestructure: Phase 2 — extracting $($archive.Name) to $extractDir" 'INFO'

                if ($DryRun) {
                    Write-SOKLog "BackupRestructure: Phase 2 [DRYRUN] Would run: 7z x '$($archive.FullName)' -o'$extractDir'" 'INFO'
                } else {
                    try {
                        $extractResult = & $sevenZipExe x $archive.FullName "-o$extractDir" -y 2>&1
                        if ($LASTEXITCODE -eq 0) {
                            Write-SOKLog "BackupRestructure: Phase 2 — extracted $($archive.Name)" 'INFO'
                        } else {
                            Write-SOKLog "BackupRestructure: Phase 2 — 7z returned $LASTEXITCODE for $($archive.Name)" 'WARN'
                        }
                    } catch {
                        Write-SOKLog "BackupRestructure: Phase 2 — extraction failed for $($archive.Name): $_" 'WARN'
                    }
                }
            }
        }
        Write-SOKLog "BackupRestructure: Phase 2 complete." 'INFO'
    } else {
        Write-SOKLog "BackupRestructure: Phase 2 skipped (-SkipExtraction)." 'INFO'
    }

    # -----------------------------------------------------------------------
    # PHASE 3: Merge to E:\Backup_Merged with derivation tags
    # Derivation tags encode source characteristics:
    #   _a1 = first archive extraction from a .7z
    #   _a2 = second or subsequent extraction (collision)
    #   _b  = raw directory (no corresponding archive)
    #   _c  = continuation volume extraction
    #   _d  = deeply nested (>3 levels below ArchiveRoot)
    # We merge by copying each top-level directory from ArchiveRoot to MergeTarget.
    # -----------------------------------------------------------------------
    if (-not $SkipMerge) {
        Write-SOKLog "BackupRestructure: Phase 3 — merging to $MergeTarget." 'INFO'

        if ($DryRun) {
            Write-SOKLog "BackupRestructure: Phase 3 [DRYRUN] Would create $MergeTarget and merge." 'INFO'
        } else {
            if (-not (Test-Path $MergeTarget)) {
                New-Item -ItemType Directory -Path $MergeTarget -Force | Out-Null
            }
        }

        # Get top-level directories from ArchiveRoot
        $topDirs = Get-ChildItem -Path $ArchiveRoot -Directory -ErrorAction SilentlyContinue

        # Track seen names for collision (_a1, _a2 disambiguation)
        $seenNames = [ordered]@{}

        foreach ($dir in $topDirs) {
            $baseName = $dir.Name

            # Determine derivation tag
            $relativeDepth = ($dir.FullName -split '\\').Count - ($ArchiveRoot -split '\\').Count
            $tag = '_b'  # default: raw directory

            # Check if this directory was extracted from an archive
            $correspondingArchive = Join-Path $dir.Parent.FullName "$($dir.Name).7z"
            if (Test-Path $correspondingArchive) {
                if ($seenNames.Contains($baseName)) {
                    $tag = '_a2'
                } else {
                    $tag = '_a1'
                }
            } elseif ($relativeDepth -gt 3) {
                $tag = '_d'
            }

            # Handle name collisions
            if ($seenNames.Contains($baseName)) {
                $seenNames[$baseName] += 1
                $mergedName = "$baseName${tag}_$($seenNames[$baseName])"
            } else {
                $seenNames[$baseName] = 1
                $mergedName = "$baseName$tag"
            }

            $mergeDestination = Join-Path $MergeTarget $mergedName

            Write-SOKLog "BackupRestructure: Phase 3 — $baseName → $mergedName" 'INFO'

            if ($DryRun) {
                Write-SOKLog "BackupRestructure: Phase 3 [DRYRUN] Would copy '$($dir.FullName)' to '$mergeDestination'" 'INFO'
            } else {
                try {
                    # Use robocopy for reliable large-dir copy with long path support
                    $roboArgs = @($dir.FullName, $mergeDestination, '/E', '/NFL', '/NDL', '/NJH', '/NJS', '/NP')
                    & robocopy @roboArgs | Out-Null
                    # Robocopy exit codes 0-7 are success/partial success; 8+ are errors
                    if ($LASTEXITCODE -lt 8) {
                        Write-SOKLog "BackupRestructure: Phase 3 — merged $baseName → $mergedName" 'INFO'
                    } else {
                        Write-SOKLog "BackupRestructure: Phase 3 — robocopy error $LASTEXITCODE for $baseName" 'WARN'
                    }
                } catch {
                    Write-SOKLog "BackupRestructure: Phase 3 — failed to merge $baseName : $_" 'WARN'
                }
            }
        }
        Write-SOKLog "BackupRestructure: Phase 3 complete." 'INFO'
    } else {
        Write-SOKLog "BackupRestructure: Phase 3 skipped (-SkipMerge)." 'INFO'
    }

    Write-SOKLog "BackupRestructure: All phases complete." 'INFO'
}

# ===========================================================================
#  MAIN BODY
#  Each module is called only when its switch is explicitly set.
#  No default full-run behavior — you must opt in.
# ===========================================================================

$runSummary = [ordered]@{
    ScriptName  = $SCRIPT_NAME
    Version     = $SCRIPT_VERSION
    StartTime   = (Get-Date -Format 'o')
    DryRun      = $DryRun.IsPresent
    ModulesRun  = [System.Collections.Generic.List[string]]::new()
    Outputs     = [ordered]@{}
    Errors      = [System.Collections.Generic.List[string]]::new()
}

try {
    Show-SOKBanner -ScriptName "$SCRIPT_NAME v$SCRIPT_VERSION"
    Write-SOKLog "$SCRIPT_NAME v$SCRIPT_VERSION starting." 'INFO'

    if ($DryRun) {
        Write-SOKLog "DryRun mode ACTIVE — no destructive operations will be performed." 'WARN'
    }

    # Verify at least one module was requested — if none, print usage hint.
    $anyModuleRequested = $RunInfraFix -or $RunInventory -or $RunSpaceAudit -or
                          $RunRestructure -or $RunCompareSnapshots -or $RunBackupRestructure

    if (-not $anyModuleRequested) {
        Write-SOKLog "No modules selected. Use -RunInfraFix, -RunInventory, -RunSpaceAudit, -RunRestructure, -RunCompareSnapshots, or -RunBackupRestructure." 'WARN'
        Write-Host ""
        Write-Host "Usage example:"
        Write-Host "  .\SOK-PAST-Verbose.ps1 -DryRun -RunInfraFix -RunInventory -ScanCaliber 2"
        Write-Host ""
    }

    # --- Module 1: InfraFix ---
    if ($RunInfraFix) {
        $runSummary.ModulesRun.Add('InfraFix')
        try {
            Invoke-PASTInfraFix -DryRun:$DryRun
        } catch {
            $errMsg = "InfraFix failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
        }
    }

    # --- Module 2: Inventory ---
    if ($RunInventory) {
        $runSummary.ModulesRun.Add('Inventory')
        try {
            $invOut = Invoke-PASTInventory -DryRun:$DryRun -ScanCaliber $ScanCaliber -OutputPath $InventoryOutputPath
            $runSummary.Outputs['Inventory'] = $invOut
        } catch {
            $errMsg = "Inventory failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
        }
    }

    # --- Module 3: SpaceAudit ---
    if ($RunSpaceAudit) {
        $runSummary.ModulesRun.Add('SpaceAudit')
        try {
            $auditOut = Invoke-PASTSpaceAudit -DryRun:$DryRun -MinSizeKB $MinSizeKB
            $runSummary.Outputs['SpaceAudit'] = $auditOut
        } catch {
            $errMsg = "SpaceAudit failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
        }
    }

    # --- Module 4: Restructure ---
    if ($RunRestructure) {
        $runSummary.ModulesRun.Add('Restructure')
        try {
            $restructureOut = Invoke-PASTRestructure -DryRun:$DryRun -Targets $RestructureTargets -MaxDepth $MaxDepth
            $runSummary.Outputs['Restructure'] = $restructureOut
        } catch {
            $errMsg = "Restructure failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
        }
    }

    # --- Module 5: CompareSnapshots ---
    if ($RunCompareSnapshots) {
        $runSummary.ModulesRun.Add('CompareSnapshots')
        try {
            $compareOut = Invoke-PASTCompareSnapshots -DryRun:$DryRun `
                                                      -OldSnapshot $OldSnapshot `
                                                      -NewSnapshot $NewSnapshot `
                                                      -AutoApproveThreshold $AutoApproveThreshold `
                                                      -OutputDir $ComparatorOutputDir
            $runSummary.Outputs['CompareSnapshots'] = $compareOut
        } catch {
            $errMsg = "CompareSnapshots failed: $_"
            Write-SOKLog $errMsg 'ERROR'
            $runSummary.Errors.Add($errMsg)
        }
    }

    # --- Module 6: BackupRestructure ---
    if ($RunBackupRestructure) {
        $runSummary.ModulesRun.Add('BackupRestructure')
        try {
            Invoke-PASTBackupRestructure -DryRun:$DryRun `
                                         -ArchiveRoot $ArchiveRoot `
                                         -MergeTarget $MergeTarget `
                                         -RunPhase1:$RunPhase1 `
                                         -SkipExtraction:$SkipExtraction `
                                         -SkipMerge:$SkipMerge
        } catch {
            $errMsg = "BackupRestructure failed: $_"
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
    $runSummary['ModulesRunCount'] = $runSummary.ModulesRun.Count
    $runSummary['ErrorCount']   = $runSummary.Errors.Count

    Write-SOKLog "$SCRIPT_NAME complete. Modules run: $($runSummary.ModulesRun -join ', '). Errors: $($runSummary.Errors.Count)" 'Annotate'

    # Save history entry via SOK-Common
    Save-SOKHistory -ScriptName $SCRIPT_NAME -RunData $runSummary
}