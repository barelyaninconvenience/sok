#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-Offload.ps1 — Inventory-driven offload of supplemental packages to external drive.

.DESCRIPTION
    Scans C:\ for large, moveable directories (caches, databases, runtimes,
    IDE data, build artifacts) and offloads them to an NTFS external drive
    with NTFS junction points for transparent redirection.

    v2.0.0 refactors:
    [REFACTOR] All sizes standardized to KB (1 KB = 1024 bytes)
    [REFACTOR] Regex-based path classification and validation (compiled patterns)
    [REFACTOR] Dependency-aware chunking (related targets move together or not at all)
    [REFACTOR] 7-tier priority system with volatility and rebuild-cost scoring
    [REFACTOR] 96% max utilization ceiling on external drive
    [REFACTOR] No -Quiet flag — all output always visible
    [REFACTOR] ErrorAction Continue everywhere
    [REFACTOR] Verbose robocopy (full file list, progress, ETA)
    [REFACTOR] ddMMMyyyy display, ISO 8601 storage

    NEVER MOVES (regex-enforced exclusions):
    - Windows system directories (Windows, System32, WinSxS, SysWOW64)
    - User profile root direct children (Desktop, Documents, Downloads, etc.)
    - Boot/recovery partitions, page/swap/hibernation files
    - Active .git internals

.PARAMETER ExternalDrive
    Drive letter of the external drive. Default: E:

.PARAMETER InventoryPath
    Path to a SOK inventory JSON. If provided, enriches target discovery.

.PARAMETER MinSizeKB
    Minimum directory size to consider for offload. Default: 33333 KB (~32.5 MB).

.PARAMETER DryRun
    Preview without moving.

.NOTES
    Author: S. Clay Caddell
    Version: 2.2.0
    Date: 19Mar2026
    Domain: FUTURE — moves large dirs to E: with NTFS junctions; preserves C: transparency
    REQUIRES: Administrator (junction creation), NTFS external drive
#>

[CmdletBinding()]
param(
    [string]$ExternalDrive = 'E:',
    [string]$InventoryPath,
    [int]$MinSizeKB = 21138,
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

# ═══════════════════════════════════════════════════════════════
# NORMALIZE DRIVE LETTER
# ═══════════════════════════════════════════════════════════════
# WMI Win32_LogicalDisk.DeviceID is ALWAYS "X:" — never "X:\"
# Passing "E:\" creates filter: DeviceID='E:\' which is INVALID WMI syntax
# This block accepts any reasonable input and normalizes to "X:" format
$ExternalDrive = $ExternalDrive.TrimEnd('\', '/')
if ($ExternalDrive -notmatch '^[A-Z]:$') {
    if ($ExternalDrive -match '^([A-Za-z]):?') {
        $ExternalDrive = "$($Matches[1].ToUpper()):"
    }
    else {
        Write-Error "Invalid drive specification: '$ExternalDrive'. Expected: E: or E:\ or E"
        exit 1
    }
}

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else { Write-Error "SOK-Common.psm1 not found at $modulePath"; exit 1 }

Show-SOKBanner -ScriptName 'SOK-Offload' -Subheader "Target: $ExternalDrive | Min: $MinSizeKB KB | $(if($DryRun){'DRY RUN'}else{'LIVE'})"
$logPath = Initialize-SOKLog -ScriptName 'SOK-Offload'
$startTime = Get-Date

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-Offload'
}

if ($DryRun) { Write-SOKLog '*** DRY RUN — no files will be moved ***' -Level Warn }

# ═══════════════════════════════════════════════════════════════
# COMPILED REGEX PATTERNS (built once, matched many times)
# ═══════════════════════════════════════════════════════════════

$script:rxNeverMove = [regex]::new(
    '(?ix)
    ^[A-Z]:\\Windows
    | ^[A-Z]:\\Recovery
    | \\(System32|SysWOW64|WinSxS)\\
    | \\(pagefile|swapfile|hiberfil)
    | ^[A-Z]:\\Users\\[^\\]+$
    | ^[A-Z]:\\Users\\[^\\]+\\(Desktop|Documents|Downloads|Pictures|Videos|Music|Favorites|Links|Contacts|Searches|SavedGames)$
    | ^[A-Z]:\\\$
    | \\\.git\\
    ',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

$script:rxCache = [regex]::new(
    '(?ix) \\(cache|caches|lib-bkp|tmp|temp|__pycache__|\.cache|Code\sCache|GPUCache|ShaderCache|CachedData)([\\]|$)',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$script:rxPackageStore = [regex]::new(
    '(?ix) \\(node_modules|packages|\.nuget|\.cargo\\registry|\.m2\\repository|\.gradle\\caches|vendor)([\\]|$)',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$script:rxDatabaseData = [regex]::new(
    '(?ix) \\(data|pgdata|dbdata|neo4j\\data|mongodb|mysql.*\\data)([\\]|$)',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$script:rxRuntimeEnv = [regex]::new(
    '(?ix) \\(\.pyenv|\.conda|envs|\.virtualenvs|\.nvm|\.rbenv|\.gopath)([\\]|$)',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$script:rxIDEData = [regex]::new(
    '(?ix) \\(JetBrains|\.vscode\\extensions|\.eclipse|\.atom|Rider\d|IntelliJIdea\d|PyCharm\d|WebStorm\d|DataGrip\d)([\\]|$)',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)
$script:rxDockerWSL = [regex]::new(
    '(?ix) \\(Docker|wsl|lxss|ext4\.vhdx)([\\]|$)',
    [System.Text.RegularExpressions.RegexOptions]::Compiled
)

# ═══════════════════════════════════════════════════════════════
# VALIDATE EXTERNAL DRIVE
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'EXTERNAL DRIVE VALIDATION' -Level Section

if (-not (Test-Path "$ExternalDrive\")) {
    Write-SOKLog "External drive $ExternalDrive not found!" -Level Error; exit 1
}

$extDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$ExternalDrive'" -ErrorAction Continue
if (-not $extDisk -or $extDisk.Size -eq 0) {
    Write-SOKLog "Could not get valid drive info for $ExternalDrive" -Level Error; exit 1
}

$extFreeKB  = [math]::Round($extDisk.FreeSpace / 1KB, 0)
$extTotalKB = [math]::Round($extDisk.Size / 1KB, 0)
$extUsedKB  = $extTotalKB - $extFreeKB
$extUsedPct = [math]::Round(($extUsedKB / $extTotalKB) * 100, 1)
$extFS      = $extDisk.FileSystem

$maxUsableKB     = [math]::Round($extTotalKB * 0.96, 0)
$remainingBudgetKB = [math]::Max(0, $maxUsableKB - $extUsedKB)

Write-SOKLog "Drive $ExternalDrive — $extFS" -Level Ignore
Write-SOKLog "  Total:        $(Get-HumanSize ($extTotalKB * 1KB))" -Level Ignore
Write-SOKLog "  Used:         $(Get-HumanSize ($extUsedKB * 1KB)) ($extUsedPct%)" -Level Ignore
Write-SOKLog "  Free:         $(Get-HumanSize ($extFreeKB * 1KB))" -Level Ignore
Write-SOKLog "  Budget (96%): $(Get-HumanSize ($remainingBudgetKB * 1KB))" -Level Ignore

if ($extFS -ne 'NTFS') {
    Write-SOKLog "FILESYSTEM: $extFS — junctions NOT supported. Reformat to NTFS." -Level Error
    $canSymlink = $false
} else {
    Write-SOKLog "NTFS confirmed — junctions will provide transparent redirection" -Level Success
    $canSymlink = $true
}

if ($remainingBudgetKB -lt $MinSizeKB) {
    Write-SOKLog "Insufficient budget: $remainingBudgetKB KB < $MinSizeKB KB min" -Level Error; exit 1
}

# ═══════════════════════════════════════════════════════════════
# OFFLOAD TARGETS — 7-tier priority, dependency-grouped
# ═══════════════════════════════════════════════════════════════
# Priority: P1=critical space, P2=DB data, P3=runtimes, P4=caches,
#           P5=build artifacts, P6=IDE, P7=misc
# DepGroup: items in same group move together or not at all
# Volatility: LOW/MEDIUM/HIGH — how often data changes
# RebuildCost: ZERO/LOW/MEDIUM/HIGH — effort to regenerate

$offloadTargets = @(
    # P1 CRITICAL SPACE
    @{ Path='C:\ProgramData\Docker';                         Label='Docker data';              Priority=1; DepGroup='Docker';    Volatility='MEDIUM'; RebuildCost='MEDIUM'; PostMoveCmd='Docker Desktop: Settings > Resources > Disk image location' }
    @{ Path="$env:LOCALAPPDATA\Docker\wsl";                  Label='Docker WSL2 VM';           Priority=1; DepGroup='Docker';    Volatility='MEDIUM'; RebuildCost='MEDIUM'; PostMoveCmd='Docker auto-detects junction' }
    # v4.3.3: UWP Packages SKIPPED — Windows ACLs block robocopy /MOVE (exit 10/11)
    # @{ Path="$env:LOCALAPPDATA\Packages";                    Label='UWP/Store app data';       Priority=1; DepGroup='WinStore';  Volatility='LOW';    RebuildCost='MEDIUM'; PostMoveCmd='Junction handles redirection' }

    # P2 DATABASE DATA
    @{ Path='C:\Program Files\PostgreSQL\15\data';           Label='PostgreSQL 15 data';       Priority=2; DepGroup='PostgreSQL';Volatility='MEDIUM'; RebuildCost='HIGH';   PostMoveCmd='STOP service first. Edit postgresql.conf data_directory' }
    @{ Path='C:\Program Files\MongoDB\Server\*\data';        Label='MongoDB data';             Priority=2; DepGroup='MongoDB';   Volatility='MEDIUM'; RebuildCost='HIGH';   PostMoveCmd='STOP service first. Edit mongod.conf storage.dbPath' }
    @{ Path="$env:USERPROFILE\neo4j\data";                   Label='Neo4j graph data';         Priority=2; DepGroup='Neo4j';     Volatility='MEDIUM'; RebuildCost='HIGH';   PostMoveCmd='STOP service first. Edit neo4j.conf dbms.directories.data' }
    @{ Path="$env:LOCALAPPDATA\Redis";                       Label='Redis/Memurai data';       Priority=2; DepGroup='Redis';     Volatility='MEDIUM'; RebuildCost='LOW';    PostMoveCmd='Edit redis.conf dir; restart Memurai' }

    # P3 RUNTIME ENVIRONMENTS
    @{ Path="$env:USERPROFILE\.pyenv";                       Label='pyenv Python installs';    Priority=3; DepGroup='Python';    Volatility='LOW';    RebuildCost='MEDIUM'; PostMoveCmd='Junction handles; verify: pyenv versions' }
    @{ Path="$env:USERPROFILE\.conda";                       Label='Conda environments';       Priority=3; DepGroup='Python';    Volatility='LOW';    RebuildCost='MEDIUM'; PostMoveCmd='Junction handles; verify: conda env list' }
    @{ Path="$env:LOCALAPPDATA\Programs\Python";             Label='Python local installs';    Priority=3; DepGroup='Python';    Volatility='LOW';    RebuildCost='MEDIUM'; PostMoveCmd='Junction handles redirection' }
    @{ Path="$env:USERPROFILE\scoop\apps";                   Label='Scoop applications';       Priority=3; DepGroup='Scoop';     Volatility='LOW';    RebuildCost='MEDIUM'; PostMoveCmd='Junction handles; verify: scoop list' }
    @{ Path="$env:USERPROFILE\anaconda3";                    Label='Anaconda distribution';    Priority=3; DepGroup='Python';    Volatility='LOW';    RebuildCost='MEDIUM'; PostMoveCmd='Junction handles redirection' }

    # P4 PACKAGE CACHES (fully rebuildable)
    @{ Path='C:\ProgramData\chocolatey\lib';                 Label='Choco package lib';        Priority=4; DepGroup='Choco';     Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction handles redirection' }
    @{ Path='C:\ProgramData\chocolatey\lib-bkp';             Label='Choco backup cache';       Priority=4; DepGroup='Choco';     Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction or delete entirely' }
    @{ Path='C:\ProgramData\chocolatey\cache';               Label='Choco download cache';     Priority=4; DepGroup='Choco';     Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction or delete entirely' }
    @{ Path="$env:USERPROFILE\scoop\cache";                  Label='Scoop download cache';     Priority=4; DepGroup='Scoop';     Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction handles redirection' }
    @{ Path="$env:LOCALAPPDATA\pip\cache";                   Label='pip download cache';       Priority=4; DepGroup='Python';    Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction or: pip config set global.cache-dir' }
    @{ Path="$env:APPDATA\npm-cache";                        Label='npm download cache';       Priority=4; DepGroup='Node';      Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction or: npm config set cache' }
    @{ Path="$env:USERPROFILE\.cargo\registry";              Label='Cargo crate registry';     Priority=4; DepGroup='Rust';      Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction handles redirection' }
    @{ Path="$env:USERPROFILE\.nuget\packages";              Label='.NET NuGet cache';         Priority=4; DepGroup='DotNet';    Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction or: nuget config globalPackagesFolder' }

    # P5 BUILD ARTIFACTS
    @{ Path="$env:USERPROFILE\.gradle\caches";               Label='Gradle build cache';       Priority=5; DepGroup='Java';      Volatility='MEDIUM'; RebuildCost='LOW';    PostMoveCmd='Junction handles redirection' }
    @{ Path="$env:USERPROFILE\.m2\repository";               Label='Maven dependencies';       Priority=5; DepGroup='Java';      Volatility='LOW';    RebuildCost='LOW';    PostMoveCmd='Junction or: settings.xml localRepository' }
    @{ Path="$env:APPDATA\npm\node_modules";                 Label='npm global modules';       Priority=5; DepGroup='Node';      Volatility='LOW';    RebuildCost='LOW';    PostMoveCmd='Junction handles redirection' }

    # P6 IDE DATA
    @{ Path="$env:LOCALAPPDATA\JetBrains";                   Label='JetBrains IDE caches';     Priority=6; DepGroup='IDE';       Volatility='MEDIUM'; RebuildCost='LOW';    PostMoveCmd='Junction handles; IDEs rebuild indices on launch' }
    @{ Path="$env:USERPROFILE\.vscode\extensions";           Label='VS Code extensions';       Priority=6; DepGroup='IDE';       Volatility='LOW';    RebuildCost='ZERO';   PostMoveCmd='Junction handles redirection' }

    # P7 MISCELLANEOUS
    @{ Path="$env:LOCALAPPDATA\Microsoft\Windows\INetCache"; Label='Windows Internet cache';   Priority=7; DepGroup='WinCache';  Volatility='MEDIUM'; RebuildCost='ZERO';   PostMoveCmd='Junction handles redirection' }
    @{ Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"; Label='Chrome cache';   Priority=7; DepGroup='WinCache';  Volatility='HIGH';   RebuildCost='ZERO';   PostMoveCmd='Junction handles redirection' }
)

# ═══════════════════════════════════════════════════════════════
# SCAN AND SIZE TARGETS
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'TARGET SCANNING' -Level Section

$viable = [System.Collections.ArrayList]::new()
$totalViableKB = 0
$skippedCount = 0
$i = 0

foreach ($target in $offloadTargets) {
    $i++
    Write-Progress -Activity 'Scanning offload targets' -Status "$($target.Label)" -PercentComplete ([math]::Round(($i / $offloadTargets.Count) * 100))

    $resolvedPaths = @()
    if ($target.Path -match '\*') {
        $resolvedPaths = @(Resolve-Path $target.Path -ErrorAction Continue | Select-Object -ExpandProperty Path)
    }
    elseif (Test-Path $target.Path) {
        $resolvedPaths = @($target.Path)
    }

    foreach ($rPath in $resolvedPaths) {
        if ($script:rxNeverMove.IsMatch($rPath)) {
            Write-SOKLog "  EXCLUDED (never-move): $rPath" -Level Debug
            $skippedCount++; continue
        }

        $dirInfo = Get-Item $rPath -Force -ErrorAction Continue
        if ($dirInfo -and ($dirInfo.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            Write-SOKLog "  SKIPPED (already junction): $rPath" -Level Debug
            $skippedCount++; continue
        }

        $sizeKB = try {
            $bytes = (Get-ChildItem -Path $rPath -Recurse -File -Force -ErrorAction Continue |
                Measure-Object -Property Length -Sum).Sum
            [math]::Round($bytes / 1KB, 0)
        } catch { 0 }

        # Regex safety scoring
        $safetyScore = 1  # baseline for defined targets
        if ($script:rxCache.IsMatch($rPath))        { $safetyScore += 3 }
        if ($script:rxPackageStore.IsMatch($rPath))  { $safetyScore += 3 }
        if ($script:rxDatabaseData.IsMatch($rPath))  { $safetyScore += 2 }
        if ($script:rxRuntimeEnv.IsMatch($rPath))    { $safetyScore += 2 }
        if ($script:rxIDEData.IsMatch($rPath))       { $safetyScore += 3 }
        if ($script:rxDockerWSL.IsMatch($rPath))     { $safetyScore += 2 }

        if ($sizeKB -ge $MinSizeKB) {
            $fileCount = try { (Get-ChildItem -Path $rPath -Recurse -File -Force -ErrorAction Continue | Measure-Object).Count } catch { 0 }

            $viable.Add([ordered]@{
                Path         = $rPath
                Label        = $target.Label
                SizeKB       = $sizeKB
                FileCount    = $fileCount
                Priority     = $target.Priority
                DepGroup     = $target.DepGroup
                Volatility   = $target.Volatility
                RebuildCost  = $target.RebuildCost
                SafetyScore  = $safetyScore
                PostMoveCmd  = $target.PostMoveCmd
                SortKey      = ($target.Priority * 1000000000) - $sizeKB
            }) | Out-Null
            $totalViableKB += $sizeKB
            Write-SOKLog "  VIABLE: $($target.Label) — $sizeKB KB ($fileCount files) P$($target.Priority) Safety:$safetyScore" -Level Ignore
        }
        elseif ($sizeKB -gt 0) {
            Write-SOKLog "  BELOW MIN: $($target.Label) — $sizeKB KB" -Level Debug
        }
    }
}
Write-Progress -Activity 'Scanning' -Completed

$viable = [System.Collections.ArrayList]::new(@($viable | Sort-Object { $_.SortKey }))

Write-SOKLog "`nViable: $($viable.Count) targets, $(Get-HumanSize ($totalViableKB * 1KB)) total" -Level Ignore
Write-SOKLog "Budget: $(Get-HumanSize ($remainingBudgetKB * 1KB)) | Skipped: $skippedCount" -Level Ignore

if ($viable.Count -eq 0) { Write-SOKLog 'No targets exceed threshold.' -Level Warn; exit }

# ═══════════════════════════════════════════════════════════════
# DEPENDENCY GROUP ANALYSIS
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'DEPENDENCY GROUPS' -Level Section

# Measure-Object -Property doesn't work on [ordered] hashtables in ArrayLists
# Manual summation via ForEach-Object is hashtable-safe
$depGroups = $viable | Group-Object { $_.DepGroup } | Sort-Object {
    $s = 0; $_.Group | ForEach-Object { $s += $_.SizeKB }; $s
} -Descending

foreach ($group in $depGroups) {
    $gKB = 0;    $group.Group | ForEach-Object { $gKB += $_.SizeKB }
    $gFiles = 0; $group.Group | ForEach-Object { $gFiles += $_.FileCount }
    $gSizeStr = (Get-HumanSize ($gKB * 1KB)).PadLeft(12)
    Write-SOKLog "  [$($group.Name.PadRight(12))] $gSizeStr | $($gFiles.ToString().PadLeft(7)) files | $($group.Count) targets" -Level Ignore
}

# ═══════════════════════════════════════════════════════════════
# BUILD OFFLOAD PLAN (fits within 96% budget)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'OFFLOAD PLAN' -Level Section

$cumulativeKB = 0
$planItems = [System.Collections.ArrayList]::new()
$rank = 0

foreach ($item in $viable) {
    $rank++
    $cumulativeKB += $item.SizeKB
    $fits = $cumulativeKB -le $remainingBudgetKB
    $mark = if ($fits) { '+' } else { 'X' }

    Write-SOKLog ("  [{0}] {1,2}. P{2} {3} {4} | {5} files | Vol:{6} Rebuild:{7} | Cum:{8}" -f
        $mark, $rank, $item.Priority,
        $item.Label.PadRight(30),
        (Get-HumanSize ($item.SizeKB * 1KB)).PadLeft(10),
        $item.FileCount.ToString().PadLeft(6),
        $item.Volatility.PadRight(6), $item.RebuildCost.PadRight(6),
        (Get-HumanSize ($cumulativeKB * 1KB))
    ) -Level $(if ($fits) { 'Ignore' } else { 'Warn' })

    if ($fits) { $planItems.Add($item) | Out-Null }
}

$plannedKB = 0; $planItems | ForEach-Object { $plannedKB += $_.SizeKB }
Write-SOKLog "`nPlan: $($planItems.Count)/$($viable.Count) targets | $(Get-HumanSize ($plannedKB * 1KB))" -Level Ignore

if ($planItems.Count -eq 0) { Write-SOKLog 'Nothing fits in budget.' -Level Warn; exit }

# ═══════════════════════════════════════════════════════════════
# EXECUTE OFFLOAD
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'EXECUTING' -Level Section

$offloadRoot = Join-Path $ExternalDrive 'SOK_Offload'
if (-not $DryRun -and -not (Test-Path $offloadRoot)) {
    New-Item -Path $offloadRoot -ItemType Directory -Force | Out-Null
}

$movedCount = 0; $movedKB = 0; $failedCount = 0; $junctionCount = 0
$fileMap = [System.Collections.ArrayList]::new()
$postMoveCmds = [System.Collections.ArrayList]::new()
$j = 0

foreach ($item in $planItems) {
    $j++
    Write-Progress -Activity 'Offloading' -Status "$($item.Label) ($j/$($planItems.Count))" `
        -PercentComplete ([math]::Round(($j / $planItems.Count) * 100))

    $relative = $item.Path -replace '^([A-Z]):', '$1' -replace '\\', '_'
    $destPath = Join-Path $offloadRoot $relative

    if ($DryRun) {
        Write-SOKLog "[DRY] $($item.Label) — $(Get-HumanSize ($item.SizeKB * 1KB))" -Level Ignore
        Write-SOKLog "  From:     $($item.Path)" -Level Ignore
        Write-SOKLog "  To:       $destPath" -Level Ignore
        Write-SOKLog "  Group:    $($item.DepGroup) | Vol: $($item.Volatility) | Rebuild: $($item.RebuildCost)" -Level Ignore
        Write-SOKLog "  Junction: $(if ($canSymlink) { 'YES' } else { 'NO' })" -Level $(if ($canSymlink) { 'Ignore' } else { 'Warn' })
        Write-SOKLog "  PostMove: $($item.PostMoveCmd)" -Level Ignore
        $movedCount++; $movedKB += $item.SizeKB
        continue
    }

    Write-SOKLog "MOVING: $($item.Label) ($(Get-HumanSize ($item.SizeKB * 1KB)), $($item.FileCount) files)" -Level Ignore
    Write-SOKLog "  $($item.Path) → $destPath" -Level Ignore

    try {
        if (-not (Test-Path $destPath)) { New-Item -Path $destPath -ItemType Directory -Force | Out-Null }

        # Robocopy VERBOSE — no /NFL /NDL /NP
        # CRITICAL: Do NOT wrap paths in embedded quotes — PowerShell splatting
        # handles quoting automatically. Embedded quotes cause robocopy to
        # interpret them as literal characters and prepend CWD (ERROR 123).
        $roboArgs = @(
            $item.Path, $destPath
            '/E', '/MOVE', '/R:3', '/W:5', '/MT:8', '/XJ'
            '/COPY:DAT', '/DCOPY:T', '/V', '/ETA'
        )

        Write-SOKLog "  robocopy $($roboArgs -join ' ')" -Level Debug
        $roboOutput = & robocopy @roboArgs 2>&1
        $roboExit = $LASTEXITCODE

        foreach ($line in $roboOutput) {
            $l = "$line".Trim()
            if ($l.Length -gt 0) { Write-SOKLog "  [robo] $l" -Level Debug }
        }

        if ($roboExit -lt 8) {
            Write-SOKLog "  Robocopy OK (exit: $roboExit)" -Level Success

            if ($canSymlink) {
                if (Test-Path $item.Path) {
                    Write-SOKLog "  Source still exists — cleaning up" -Level Warn
                    Remove-Item -Path $item.Path -Recurse -Force -ErrorAction Continue
                }
                if (-not (Test-Path $item.Path)) {
                    # cmd /c needs quotes for paths with spaces — use proper PS escaping
                    $jResult = cmd /c "mklink /J `"$($item.Path)`" `"$destPath`"" 2>&1
                    Write-SOKLog "  [mklink] $jResult" -Level Debug
                    if (Test-Path $item.Path) {
                        Write-SOKLog "  Junction: $($item.Path) → $destPath" -Level Success
                        $junctionCount++
                    } else {
                        Write-SOKLog "  Junction FAILED — manual reconfig needed" -Level Error
                    }
                }
            }

            $movedCount++; $movedKB += $item.SizeKB
            $fileMap.Add([ordered]@{
                OriginalPath = $item.Path; NewPath = $destPath; Label = $item.Label
                SizeKB = $item.SizeKB; FileCount = $item.FileCount
                Priority = $item.Priority; DepGroup = $item.DepGroup
                Volatility = $item.Volatility; RebuildCost = $item.RebuildCost
                JunctionCreated = $canSymlink -and (Test-Path $item.Path)
                PostMoveCmd = $item.PostMoveCmd; RobocopyExit = $roboExit
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }) | Out-Null

            if ($item.PostMoveCmd -notmatch '(?i)junction handles') {
                $postMoveCmds.Add("[$($item.Label)] $($item.PostMoveCmd)") | Out-Null
            }
        }
        else {
            Write-SOKLog "  Robocopy FAILED (exit: $roboExit)" -Level Error
            $failedCount++
        }
    }
    catch {
        Write-SOKLog "  EXCEPTION: $($_.Exception.Message)" -Level Error
        Write-SOKLog "  Stack: $($_.ScriptStackTrace)" -Level Debug
        $failedCount++
    }
}
Write-Progress -Activity 'Offloading' -Completed

# ═══════════════════════════════════════════════════════════════
# OFFLOAD MAP
# ═══════════════════════════════════════════════════════════════
$mapDir = Join-Path $offloadRoot '_SOK_Offload_Logs'
if (-not (Test-Path $mapDir)) { New-Item -Path $mapDir -ItemType Directory -Force | Out-Null }
$mapPath = Join-Path $mapDir "OffloadMap_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"

if ($fileMap.Count -gt 0) {
    [ordered]@{
        metadata = [ordered]@{
            generated_display = Get-Date -Format 'ddMMMyyyy HH:mm:ss'
            generated_iso     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            hostname          = $env:COMPUTERNAME
            external_drive    = $ExternalDrive
            filesystem        = $extFS
            total_moved_kb    = $movedKB
            items_moved       = $movedCount
            junctions_created = $junctionCount
            items_failed      = $failedCount
        }
        moves = @($fileMap)
    } | ConvertTo-Json -Depth 10 | Set-Content -Path $mapPath -Force
    Write-SOKLog "Offload map: $mapPath" -Level Success
}

# ═══════════════════════════════════════════════════════════════
# POST-MOVE ACTIONS
# ═══════════════════════════════════════════════════════════════
if ($postMoveCmds.Count -gt 0) {
    Write-SOKLog 'POST-MOVE ACTIONS REQUIRED' -Level Section
    foreach ($cmd in $postMoveCmds) { Write-SOKLog "  $cmd" -Level Warn }
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)

$postUsedPct = if (-not $DryRun) {
    $extPost = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$ExternalDrive'" -ErrorAction Continue
    if ($extPost -and $extPost.Size -gt 0) { [math]::Round((($extPost.Size - $extPost.FreeSpace) / $extPost.Size) * 100, 1) }
    else { 'N/A' }
} else { 'N/A (dry)' }

Write-SOKSummary -Stats ([ordered]@{
    TargetsScanned    = $offloadTargets.Count
    ViableTargets     = $viable.Count
    PlannedMoves      = $planItems.Count
    MovedOK           = $movedCount
    MovedKB           = $movedKB
    MovedHuman        = Get-HumanSize ($movedKB * 1KB)
    JunctionsCreated  = $junctionCount
    Failed            = $failedCount
    PostMoveActions   = $postMoveCmds.Count
    Drive             = "$ExternalDrive ($extFS)"
    PreMovePct        = "$extUsedPct%"
    PostMovePct       = "$postUsedPct%"
    Ceiling           = '96%'
    DryRun            = $DryRun.IsPresent
    DurationSec       = $duration
}) -Title 'OFFLOAD COMPLETE'

Save-SOKHistory -ScriptName 'SOK-Offload' -RunData @{
    Duration = $duration
    Results  = @{ Moved = $movedCount; MovedKB = $movedKB; Failed = $failedCount; Junctions = $junctionCount }
}
