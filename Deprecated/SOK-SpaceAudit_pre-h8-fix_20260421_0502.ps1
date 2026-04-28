<#
.SYNOPSIS
    SOK-SpaceAudit.ps1 — Full system space audit with parallel scanning.

.DESCRIPTION
    Recursively scans C:\ to find ALL directories above a size threshold,
    classifies each as KEEP/OFFLOAD/CLEAN/INVESTIGATE, and produces
    a report JSON + separate error log JSON.

    v2.0.0 performance optimizations:
    [PERF] .NET EnumerateFiles/Directories instead of Get-ChildItem (10-50x)
    [PERF] Single-pass sizing (one enumeration per directory, not three)
    [PERF] ForEach-Object -Parallel for concurrent size calculation (PS 7+)
    [PERF] Early skip of known-inaccessible paths (regex gate)
    [PERF] IgnoreInaccessible enumeration option (silent access-denied)
    [PERF] HashSet-based O(1) deduplication instead of nested loops
    [PERF] Compiled regex classification (8 patterns, built once)
    [FIX]  Junction/ReparsePoint directories skipped during enumeration
           (prevents infinite loops from legacy junctions like
           "Documents and Settings" → "Users", "Application Data" →
           "AppData\Roaming", "Local Settings" → "AppData\Local", etc.)
    [FIX]  Access denied → captured in error log JSON, not console
    [FIX]  Separate report JSON and error log JSON outputs
    [FIX]  All sizes in KB. Levels use Ignore/Annotate hierarchy.

.PARAMETER MinSizeKB
    Minimum directory size to report. Default: 33333 KB (~32.5 MB).

.PARAMETER ScanDepth
    Maximum directory depth. Default: 66 (effectively unlimited).

.PARAMETER ThrottleLimit
    Parallel thread count. Default: 8.

.PARAMETER OutputDir
    Output directory for JSON files. Defaults to Documents\Journal\Projects\SOK\Audit\

.NOTES
    Author: S. Clay Caddell
    Version: 2.3.1
    Date: 02Apr2026
    Domain: PAST — read-only space analysis; classifies directories; produces report for Cleanup/Offload
    SAFE: Read-only scan. Does not modify anything.
    REQUIRES: PowerShell 7+ (ForEach-Object -Parallel)
    Changelog: 2.3.1 — add -DryRun for SOP compliance (no behavioral effect — scan is read-only)
#>

#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$DryRun,  # SOP compliance only — no ops are gated (scan is read-only)
    [int]$MinSizeKB = 21138,
    [int]$ScanDepth = 21,
    [int]$ThrottleLimit = 13,
    [string]$OutputDir
)

$ErrorActionPreference = 'Continue'

# ═══════════════════════════════════════════════════════════════
# MODULE LOAD
# ═══════════════════════════════════════════════════════════════
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    function Write-SOKLog {
        param([string]$Message, [string]$Level = 'Ignore')
        $color = switch ($Level) {
            'Error'    { 'Red' }
            'Warn'     { 'Yellow' }
            'Annotate' { 'DarkCyan' }
            'Success'  { 'Green' }
            'Debug'    { 'DarkGray' }
            'Section'  { 'Magenta' }
            default    { 'Cyan' }
        }
        if ($Level -eq 'Section') { Write-Host "`n━━━ $Message ━━━" -ForegroundColor Magenta }
        else { Write-Host "[$(Get-Date -Format 'ddMMMyyyy HH:mm:ss')] [$($Level.ToUpper().PadRight(8))] $Message" -ForegroundColor $color }
    }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) }
    function Initialize-SOKLog { param([string]$ScriptName) return $null }
    function Get-HumanSize {
        param([double]$Bytes)
        if ($Bytes -ge 1GB) { return "$([math]::Round($Bytes/1GB, 2)) GB" }
        if ($Bytes -ge 1MB) { return "$([math]::Round($Bytes/1MB, 2)) MB" }
        return "$([math]::Round($Bytes/1KB, 2)) KB"
    }
}

Show-SOKBanner -ScriptName 'SOK-SpaceAudit' -Subheader "Min: $(Get-HumanSize ($MinSizeKB * 1KB)) | Depth: $ScanDepth | Threads: $ThrottleLimit | READ-ONLY$(if ($DryRun) { ' | DRY RUN' })"
$logPath = Initialize-SOKLog -ScriptName 'SOK-SpaceAudit'
$startTime = Get-Date

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-SpaceAudit'
}

# ── SYSTEM-CONTEXT PATH RESOLUTION ──
if ($env:USERPROFILE -like '*systemprofile*') {
    $env:USERPROFILE  = 'C:\Users\shelc'
    $env:LOCALAPPDATA = 'C:\Users\shelc\AppData\Local'
    $env:APPDATA      = 'C:\Users\shelc\AppData\Roaming'
    if (Get-Command Write-SOKLog -ErrorAction SilentlyContinue) {
        Write-SOKLog '[SYSTEM-CONTEXT] Remapped profile env vars to C:\Users\shelc' -Level Warn
    }
}

if (-not $OutputDir) {
    $OutputDir = if (Get-Command Get-ScriptLogDir -ErrorAction SilentlyContinue) { Get-ScriptLogDir -ScriptName 'SOK-SpaceAudit' } else { Join-Path $env:USERPROFILE 'Documents\Journal\Projects\SOK\Audit' }
}
if (-not (Test-Path $OutputDir)) { New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null }

$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$reportPath   = Join-Path $OutputDir "SpaceAudit_Report_${ts}.json"
$errorLogPath = Join-Path $OutputDir "SpaceAudit_Errors_${ts}.json"

# ═══════════════════════════════════════════════════════════════
# COMPILED REGEX PATTERNS (8 patterns, built once)
# ═══════════════════════════════════════════════════════════════

$script:rxSystemEssential = [regex]::new('(?ix)
    ^C:\\Windows
    | ^C:\\Recovery
    | ^C:\\\$
    | ^C:\\Boot
    | ^C:\\EFI
    | ^C:\\System\sVolume\sInformation
    | ^C:\\PerfLogs
    | \\(System32|SysWOW64|WinSxS|assembly|Microsoft\.NET\\Framework)
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$script:rxUserEssential = [regex]::new('(?ix)
    ^C:\\Users\\[^\\]+\\(Documents|Desktop|Pictures|Videos|Music|Downloads)([\\]|$)
    | ^C:\\Users\\[^\\]+\\OneDrive
    | ^C:\\Users\\[^\\]+\\\.ssh
    | ^C:\\Users\\[^\\]+\\\.gnupg
    | \\(Journal|Projects|repos|git)([\\]|$)
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$script:rxAppBinaries = [regex]::new('(?ix)
    # Direct children of Program Files (top-level app dirs)
    ^C:\\Program\sFiles([^\\]*)?\\[^\\]+$
    # Standard binary/library subdirectories
    | ^C:\\Program\sFiles([^\\]*)?\\[^\\]+\\(bin|lib|runtime|jre|jdk|Editor|app|Release)([\\]|$)
    # Microsoft ecosystem
    | \\(Microsoft\sVisual\sStudio|Visual\sStudio\s\d)
    | \\(Microsoft\sOffice|Microsoft\sSQL|Microsoft\sOneDrive)
    | \\(EdgeCore|Edge\\|Edge\sDev\\|EdgeWebView)
    | \\(Windows\sKits|Microsoft\sSDKs|UWPNuGet|Reference\sAssemblies|Merge\sModules)
    | \\dotnet\\(packs|shared|sdk|host)([\\]|$)
    | ^C:\\ProgramData\\Microsoft
    | ^C:\\Windows\\(Installer|SoftwareDistribution)
    # Development tools
    | \\(Unity\s\d|Android\sStudio|AndroidNDK)
    | \\(PostgreSQL|MySQL\sWorkbench|MongoDB\sCompass)
    | \\(Tableau|Autopsy|Vagrant|RapidMiner|Altair)
    | \\(Neovim|OpenShot|IDA\sFreeware|Blender)
    | \\(MiKTeX|RStudio|Calibre2|BurpSuite)
    | \\(GitHub\sCLI|OpenSSL|qemu)
    # Adobe
    | \\(Adobe|Acrobat|Common\sFiles\\Adobe)
    # Java runtimes
    | \\(Java\\jdk|Eclipse\sAdoptium|OpenJDK)([\\]|$)
    # Electron app resources
    | \\resources\\(app\.asar|electron\.asar)
    # Google/Amazon
    | \\(Google\\Chrome\\Application|Google\\Cloud\sSDK|GoogleUpdater)([\\]|$)
    | \\(Amazon\\Kindle)([\\]|$)
    # Other installed apps
    | \\(Steam|BlueStacks|Zoom|Slack\\app-|Discord\\app-)
    | \\(Joplin|draw\.io|Lens|Typora)\\resources
    | \\(Advanced\sPort\sScanner)
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Standalone tool installs at C:\ root (not in Program Files)
$script:rxToolInstall = [regex]::new('(?ix)
    ^C:\\(tools|msys64|Hadoop|Strawberry|influxdata|vcpkg|gitlab-runner|Squid|CocosDashboard|MinGW|Go|Ruby|Perl)([\\]|$)
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Top-level container directories (not actionable themselves, just aggregation points)
$script:rxContainer = [regex]::new('(?ix)
    ^C:\\(Users|Program\sFiles|Program\sFiles\s\(x86\)|ProgramData)$
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$script:rxOffloadable = [regex]::new('(?ix)
    \\(cache|caches|lib-bkp|\.cache|CachedData|GPUCache|ShaderCache|Code\sCache)([\\]|$)
    | \\(node_modules|packages|\.nuget|\.cargo\\registry|\.m2\\repository|\.gradle\\caches)([\\]|$)
    | \\(\.pyenv|\.conda|envs|\.virtualenvs|anaconda)([\\]|$)
    | \\(JetBrains|\.vscode\\extensions|\.eclipse)([\\]|$)
    | \\(Docker|wsl\\data)([\\]|$)
    | \\scoop\\(apps|cache)([\\]|$)
    | \\chocolatey\\(lib|lib-bkp|cache)([\\]|$)
    | \\(npm-cache|npm\\node_modules)([\\]|$)
    | \\AppData\\Local\\Packages([\\]|$)
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$script:rxDeletable = [regex]::new('(?ix)
    \\(Temp|tmp)([\\]|$)
    | \\(INetCache|INetCookies)([\\]|$)
    | \\Chrome\\User\sData\\[^\\]+\\(Cache|Code\sCache|GPUCache)([\\]|$)
    | \\(Firefox|Mozilla)\\[^\\]+\\cache2([\\]|$)
    | \\(Edge|msedge)\\[^\\]+\\Cache([\\]|$)
    | \\Crash\s?Reports([\\]|$)
    | \\(ElevatedDiagnostics|DiagOutputDir)([\\]|$)
    | \\Windows\\Temp([\\]|$)
    | \\Spotify\\Data\\[^\\]+\\cache([\\]|$)
    | \\pip\\cache([\\]|$)
    | \\yarn\\cache([\\]|$)
    | \\thumbnails([\\]|$)
    | \\\.tmp([\\]|$)
    | \\D3DSCache([\\]|$)
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$script:rxDatabaseData = [regex]::new('(?ix)
    \\(PostgreSQL|MongoDB|MySQL|MariaDB|neo4j|Redis|Memurai)\\.*\\data([\\]|$)
    | \\(pgdata|dbdata|mongodb)([\\]|$)
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$script:rxPotentiallyStale = [regex]::new('(?ix)
    \\(\.?old|backup|\.bak|archive|deprecated|unused|uninstall)([\\]|$)
    | \\Installer\\\{[0-9A-F-]+\}([\\]|$)
    | \\Package\sCache([\\]|$)
    | \\Microsoft\\Visual\sStudio\\Packages([\\]|$)
    | \\NuGet\\v3-cache([\\]|$)
    | \\\.Trash([\\]|$)
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Early-skip: known-inaccessible or system-only paths
$script:rxSkipEnumeration = [regex]::new('(?ix)
    ^C:\\Documents\sand\sSettings
    | ^C:\\System\sVolume\sInformation
    | ^C:\\Config\.Msi
    | ^C:\\\$Recycle\.Bin
    | ^C:\\\$WinREAgent
    | ^C:\\\$WINDOWS
    | ^C:\\\$SysReset
    | \\WindowsApps([\\]|$)
    | \\WinSxS([\\]|$)
    | \\Windows\sDefender\sAdvanced\sThreat\sProtection
    | \\DRM\\[^\\]*$
', [System.Text.RegularExpressions.RegexOptions]::Compiled)

function Get-Classification {
    param([string]$Path)
    if ($script:rxContainer.IsMatch($Path))         { return 'CONTAINER' }
    if ($script:rxSystemEssential.IsMatch($Path))   { return 'SYSTEM_ESSENTIAL' }
    if ($script:rxDeletable.IsMatch($Path))         { return 'SAFE_TO_CLEAN' }
    if ($script:rxDatabaseData.IsMatch($Path))      { return 'DB_OFFLOAD' }
    if ($script:rxOffloadable.IsMatch($Path))       { return 'OFFLOADABLE' }
    if ($script:rxPotentiallyStale.IsMatch($Path))  { return 'INVESTIGATE' }
    if ($script:rxUserEssential.IsMatch($Path))     { return 'USER_DATA' }
    if ($script:rxToolInstall.IsMatch($Path))       { return 'TOOL_INSTALL' }
    if ($script:rxAppBinaries.IsMatch($Path))       { return 'APP_BINARY' }
    return 'UNKNOWN'
}

function Get-Verdict {
    param([string]$Classification)
    switch ($Classification) {
        'CONTAINER'        { 'SKIP — top-level aggregation directory' }
        'SYSTEM_ESSENTIAL' { 'KEEP — Windows system requirement' }
        'USER_DATA'        { 'KEEP — personal files' }
        'APP_BINARY'       { 'KEEP — application needs this to run' }
        'TOOL_INSTALL'     { 'KEEP — standalone tool install (review for staleness)' }
        'SAFE_TO_CLEAN'    { 'CLEAN — pure temp/cache, safe to delete' }
        'OFFLOADABLE'      { 'OFFLOAD — move to external drive with junction' }
        'DB_OFFLOAD'       { 'OFFLOAD — stop service first, move, update config' }
        'INVESTIGATE'      { 'INVESTIGATE — may be stale/orphaned, verify before action' }
        'UNKNOWN'          { 'INVESTIGATE — unclassified, manual review needed' }
    }
}

# ═══════════════════════════════════════════════════════════════
# DRIVE OVERVIEW
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'DRIVE OVERVIEW' -Level Section

$cDisk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Continue
$cTotalKB = [math]::Round($cDisk.Size / 1KB, 0)
$cFreeKB  = [math]::Round($cDisk.FreeSpace / 1KB, 0)
$cUsedKB  = $cTotalKB - $cFreeKB
$cUsedPct = [math]::Round(($cUsedKB / $cTotalKB) * 100, 2)

Write-SOKLog "C: Drive — $(Get-HumanSize ($cTotalKB * 1KB)) total" -Level Ignore
Write-SOKLog "  Used: $(Get-HumanSize ($cUsedKB * 1KB)) ($cUsedPct%)" -Level $(if ($cUsedPct -gt 83.33) { 'Error' } elseif ($cUsedPct -gt 66.66) { 'Warn' } elseif ($cUsedPct -gt 44) { 'Annotate' } else { 'Ignore' })
Write-SOKLog "  Free: $(Get-HumanSize ($cFreeKB * 1KB))" -Level Ignore
Write-SOKLog "  Threshold: $(Get-HumanSize ($MinSizeKB * 1KB))" -Level Ignore

# ═══════════════════════════════════════════════════════════════
# PHASE 1: DIRECTORY ENUMERATION (.NET, parallel per top-level)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PHASE 1: ENUMERATING DIRECTORIES' -Level Section

$allDirs    = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
$enumErrors = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
$enumStart  = Get-Date

Write-SOKLog "  .NET EnumerateDirectories | Depth $ScanDepth | IgnoreInaccessible | $ThrottleLimit threads" -Level Ignore

$topDirs = try {
    [System.IO.Directory]::GetDirectories('C:\')
} catch {
    $enumErrors.Add([ordered]@{ Path = 'C:\'; Error = $_.Exception.Message; Phase = 'TopEnum' })
    @()
}

$topDirs | ForEach-Object -Parallel {
    $topPath = $_
    $bag     = $using:allDirs
    $errBag  = $using:enumErrors
    $rxSkip  = $using:rxSkipEnumeration
    $depth   = $using:ScanDepth

    if ($rxSkip.IsMatch($topPath)) {
        $errBag.Add([ordered]@{ Path = $topPath; Error = 'Skipped (known inaccessible)'; Phase = 'EnumSkip' })
        return
    }

    # Skip top-level junctions (e.g., "Documents and Settings" → "Users")
    # These cause infinite recursion and double-counting
    try {
        $topAttr = [System.IO.File]::GetAttributes($topPath)
        if (($topAttr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            $errBag.Add([ordered]@{ Path = $topPath; Error = 'Skipped (junction/symlink)'; Phase = 'EnumJunction' })
            return
        }
    }
    catch {
        $errBag.Add([ordered]@{ Path = $topPath; Error = $_.Exception.Message; Phase = 'EnumAttrCheck' })
        return
    }

    $bag.Add($topPath)

    try {
        $opts = [System.IO.EnumerationOptions]::new()
        $opts.RecurseSubdirectories = $true
        $opts.MaxRecursionDepth = $depth
        $opts.IgnoreInaccessible = $true
        $opts.ReturnSpecialDirectories = $false
        # CRITICAL: Skip ReparsePoint directories during recursion.
        # This prevents following junctions like "Application Data" → "AppData\Roaming",
        # "Local Settings" → "AppData\Local", "My Documents" → "Documents", etc.
        # Without this, EnumerateDirectories follows junctions into their targets,
        # causing infinite loops and double-counting.
        # We keep Hidden visible (.pyenv, .cargo, .nuget are hidden) but skip System.
        $opts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint -bor [System.IO.FileAttributes]::System

        foreach ($d in [System.IO.Directory]::EnumerateDirectories($topPath, '*', $opts)) {
            if (-not $rxSkip.IsMatch($d)) { $bag.Add($d) }
        }
    }
    catch {
        $errBag.Add([ordered]@{ Path = $topPath; Error = $_.Exception.Message; Phase = 'EnumRecurse' })
    }
} -ThrottleLimit $ThrottleLimit

$enumDuration = [math]::Round(((Get-Date) - $enumStart).TotalSeconds, 1)
$junctionSkips = @($enumErrors.ToArray() | Where-Object { $_.Phase -eq 'EnumJunction' }).Count
$regexSkips    = @($enumErrors.ToArray() | Where-Object { $_.Phase -eq 'EnumSkip' }).Count
$otherErrors   = $enumErrors.Count - $junctionSkips - $regexSkips
Write-SOKLog "  $($allDirs.Count) directories in ${enumDuration}s" -Level Success
Write-SOKLog "  Skipped: $junctionSkips junctions, $regexSkips known-inaccessible, $otherErrors errors" -Level Annotate

# ═══════════════════════════════════════════════════════════════
# PHASE 2: LEAF-ONLY SIZING + BOTTOM-UP AGGREGATION (v2.3.0)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PHASE 2: SIZING (leaf-only + bottom-up aggregation)' -Level Section

$sizeStart  = Get-Date
$directBag  = [System.Collections.Concurrent.ConcurrentBag[string]]::new()
$sizeErrors = [System.Collections.Concurrent.ConcurrentBag[string]]::new()

$dirArray = $allDirs.ToArray()
$totalDirCount = $dirArray.Count
Write-SOKLog "  Sizing $totalDirCount directories (direct files only) across $ThrottleLimit threads..." -Level Ignore

$dirArray | ForEach-Object -Parallel {
    $dirPath = $_
    $bag     = $using:directBag
    $errBag  = $using:sizeErrors

    $totalBytes = [long]0
    $fileCount  = [long]0

    try {
        $opts = [System.IO.EnumerationOptions]::new()
        $opts.RecurseSubdirectories = $false
        $opts.IgnoreInaccessible = $true
        $opts.ReturnSpecialDirectories = $false
        $opts.AttributesToSkip = [System.IO.FileAttributes]::ReparsePoint -bor [System.IO.FileAttributes]::System

        foreach ($fi in [System.IO.Directory]::EnumerateFiles($dirPath, '*', $opts)) {
            try {
                $totalBytes += ([System.IO.FileInfo]::new($fi)).Length
                $fileCount++
            }
            catch { }
        }
    }
    catch {
        $errBag.Add("$dirPath|$($_.Exception.Message)")
        return
    }

    $bag.Add("$dirPath|$totalBytes|$fileCount")
} -ThrottleLimit $ThrottleLimit

$directDuration = [math]::Round(((Get-Date) - $sizeStart).TotalSeconds, 1)
Write-SOKLog "  Direct sizing: ${directDuration}s ($($directBag.Count) dirs, $($sizeErrors.Count) errors)" -Level Annotate

$aggStart = Get-Date
$aggBytes     = [System.Collections.Generic.Dictionary[string, long]]::new([System.StringComparer]::OrdinalIgnoreCase)
$aggFileCount = [System.Collections.Generic.Dictionary[string, long]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($line in $directBag.ToArray()) {
    $parts = $line.Split('|')
    if ($parts.Count -ge 3) {
        $p = $parts[0]
        $b = [long]0; $fc = [long]0
        [void][long]::TryParse($parts[1], [ref]$b)
        [void][long]::TryParse($parts[2], [ref]$fc)
        $aggBytes[$p] = $b
        $aggFileCount[$p] = $fc
    }
}

$sortedPaths = $dirArray | Sort-Object { $_.Length } -Descending
foreach ($dirPath in $sortedPaths) {
    $myBytes = if ($aggBytes.ContainsKey($dirPath)) { $aggBytes[$dirPath] } else { [long]0 }
    $myFiles = if ($aggFileCount.ContainsKey($dirPath)) { $aggFileCount[$dirPath] } else { [long]0 }
    $parent = try { [System.IO.Path]::GetDirectoryName($dirPath) } catch { $null }
    if ($parent -and $parent.Length -ge 3) {
        if (-not $aggBytes.ContainsKey($parent))     { $aggBytes[$parent] = [long]0 }
        if (-not $aggFileCount.ContainsKey($parent))  { $aggFileCount[$parent] = [long]0 }
        $aggBytes[$parent]     += $myBytes
        $aggFileCount[$parent] += $myFiles
    }
}

$aggDuration = [math]::Round(((Get-Date) - $aggStart).TotalSeconds, 1)
$cTotalAgg = if ($aggBytes.ContainsKey('C:\')) { [math]::Round($aggBytes['C:\'] / 1KB, 0) } else { 0 }
Write-SOKLog "  Aggregation: ${aggDuration}s (C:\ aggregated total: $cTotalAgg KB)" -Level Annotate

$sizedDirs = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
foreach ($dirPath in $dirArray) {
    $sizeBytes = if ($aggBytes.ContainsKey($dirPath)) { $aggBytes[$dirPath] } else { [long]0 }
    $sizeKB = [math]::Round($sizeBytes / 1KB, 0)
    if ($sizeKB -ge $MinSizeKB) {
        $lastWrite = try { [System.IO.Directory]::GetLastWriteTime($dirPath) } catch { [datetime]::MinValue }
        $isJunction = try {
            ([System.IO.File]::GetAttributes($dirPath) -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
        } catch { $false }
        $fileCount = if ($aggFileCount.ContainsKey($dirPath)) { $aggFileCount[$dirPath] } else { [long]0 }
        $sizedDirs.Add([ordered]@{
            Path           = $dirPath
            SizeKB         = $sizeKB
            FileCount      = $fileCount
            IsJunction     = $isJunction
            LastWriteTime  = $lastWrite.ToString('yyyy-MM-dd')
            DaysSinceWrite = [math]::Round(([datetime]::Now - $lastWrite).TotalDays, 0)
        })
    }
}

$sizeDuration = [math]::Round(((Get-Date) - $sizeStart).TotalSeconds, 1)
Write-SOKLog "  $($sizedDirs.Count) above threshold in ${sizeDuration}s (direct: ${directDuration}s + agg: ${aggDuration}s)" -Level Success

# ═══════════════════════════════════════════════════════════════
# PHASE 3: CLASSIFICATION (regex, sequential — already fast)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PHASE 3: CLASSIFYING' -Level Section

$classStart = Get-Date
$classified = [System.Collections.ArrayList]::new()

foreach ($item in $sizedDirs.ToArray()) {
    $classification = Get-Classification -Path $item.Path
    $item['Classification'] = $classification
    $item['Verdict'] = Get-Verdict -Classification $classification
    $classified.Add($item) | Out-Null
}

$classified = [System.Collections.ArrayList]::new(
    @($classified | Sort-Object { $_.SizeKB } -Descending)
)

$classDuration = [math]::Round(((Get-Date) - $classStart).TotalSeconds, 1)
Write-SOKLog "  $($classified.Count) entries classified in ${classDuration}s" -Level Success

# ═══════════════════════════════════════════════════════════════
# PHASE 4: DEDUPLICATION (classification-aware)
# ═══════════════════════════════════════════════════════════════
# Only absorb a child if its parent has the SAME classification.
# This prevents C:\Users (UNKNOWN) from swallowing
# C:\Users\shelc\scoop\apps (OFFLOADABLE).
Write-SOKLog 'PHASE 4: DEDUPLICATING' -Level Section

$sorted = $classified | Sort-Object { $_.Path.Length }
$deduped = [System.Collections.ArrayList]::new()

# Dictionary: path → classification (for same-class parent lookup)
$parentMap = [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($item in $sorted) {
    $isChild = $false
    $check = $item.Path
    while ($check.Length -gt 3) {
        $check = [System.IO.Path]::GetDirectoryName($check)
        if ($null -eq $check) { break }
        if ($parentMap.ContainsKey($check)) {
            # Only absorb if parent has SAME classification
            if ($parentMap[$check] -eq $item.Classification) {
                $isChild = $true
            }
            break
        }
    }
    if (-not $isChild) {
        $deduped.Add($item) | Out-Null
        $parentMap[$item.Path] = $item.Classification
    }
}

$deduped = [System.Collections.ArrayList]::new(
    @($deduped | Sort-Object { $_.SizeKB } -Descending)
)

Write-SOKLog "  $($deduped.Count) unique entries (removed $($classified.Count - $deduped.Count) children)" -Level Success

# ═══════════════════════════════════════════════════════════════
# CLASSIFICATION SUMMARY
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'CLASSIFICATION SUMMARY' -Level Section

$byStat = [ordered]@{}
foreach ($item in $deduped) {
    $c = $item.Classification
    if (-not $byStat.Contains($c)) { $byStat[$c] = @{ Count = 0; SizeKB = [long]0 } }
    $byStat[$c].Count++
    $byStat[$c].SizeKB += $item.SizeKB
}

foreach ($class in $byStat.Keys) {
    $s = $byStat[$class]
    $level = switch ($class) {
        'SAFE_TO_CLEAN' { 'Success' }
        'OFFLOADABLE'   { 'Success' }
        'DB_OFFLOAD'    { 'Annotate' }
        'TOOL_INSTALL'  { 'Annotate' }
        'CONTAINER'     { 'Debug' }
        'INVESTIGATE'   { 'Warn' }
        'UNKNOWN'       { 'Warn' }
        default         { 'Ignore' }
    }
    Write-SOKLog ("  {0}  {1} items  {2}" -f
        $class.PadRight(21),
        $s.Count.ToString().PadLeft(5),
        "$($s.SizeKB) KB".PadLeft(13)
    ) -Level $level
}

# ═══════════════════════════════════════════════════════════════
# ACTIONABLE REPORTS
# ═══════════════════════════════════════════════════════════════

function Get-ByClass { param([string[]]$Classes)
    @($deduped | Where-Object { $_.Classification -in $Classes } | Sort-Object { $_.SizeKB } -Descending)
}

$cleanable = Get-ByClass 'SAFE_TO_CLEAN'
if ($cleanable.Count -gt 0) {
    $cleanKB = 0; $cleanable | ForEach-Object { $cleanKB += $_.SizeKB }
    Write-SOKLog "`nSAFE TO CLEAN — $(Get-HumanSize ($cleanKB * 1KB)) recoverable" -Level Section
    foreach ($item in $cleanable) {
        $stale = if ($item.DaysSinceWrite -gt 44) { " (stale: $($item.DaysSinceWrite)d)" } else { '' }
        Write-SOKLog "  $("$($item.SizeKB) KB".PadLeft(13))  $($item.Path)$stale" -Level Success
    }
}

$offloadable = Get-ByClass 'OFFLOADABLE', 'DB_OFFLOAD'
if ($offloadable.Count -gt 0) {
    $offKB = 0; $offloadable | ForEach-Object { $offKB += $_.SizeKB }
    Write-SOKLog "`nOFFLOADABLE — $(Get-HumanSize ($offKB * 1KB)) moveable to E:" -Level Section
    foreach ($item in $offloadable) {
        $jNote  = if ($item.IsJunction) { ' [JUNCTION]' } else { '' }
        $dbNote = if ($item.Classification -eq 'DB_OFFLOAD') { ' [STOP SVC]' } else { '' }
        Write-SOKLog "  $("$($item.SizeKB) KB".PadLeft(13))  $($item.Path)$jNote$dbNote" -Level Ignore
    }
}

$investigate = Get-ByClass 'INVESTIGATE', 'UNKNOWN'
if ($investigate.Count -gt 0) {
    $invKB = 0; $investigate | ForEach-Object { $invKB += $_.SizeKB }
    Write-SOKLog "`nINVESTIGATE — $(Get-HumanSize ($invKB * 1KB)) needs review" -Level Section
    foreach ($item in $investigate) {
        $stale = if ($item.DaysSinceWrite -gt 160) { " [STALE: $($item.DaysSinceWrite)d]" } else { '' }
        Write-SOKLog "  $("$($item.SizeKB) KB".PadLeft(13))  $($item.Path)$stale" -Level Warn
    }
}

$keepers = @($deduped | Where-Object { $_.Classification -in @('SYSTEM_ESSENTIAL', 'USER_DATA', 'APP_BINARY', 'TOOL_INSTALL', 'CONTAINER') } |
    Sort-Object { $_.SizeKB } -Descending | Select-Object -First 20)
if ($keepers.Count -gt 0) {
    Write-SOKLog "`nLARGEST KEEPERS (top 20)" -Level Section
    foreach ($item in $keepers) {
        Write-SOKLog "  $("$($item.SizeKB) KB".PadLeft(13))  [$($item.Classification.PadRight(21))] $($item.Path)" -Level Debug
    }
}

# ═══════════════════════════════════════════════════════════════
# SPACE RECOVERY ESTIMATE
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'SPACE RECOVERY' -Level Section

$cleanKB = 0; $cleanable   | ForEach-Object { $cleanKB += $_.SizeKB }
$offKB   = 0; $offloadable | ForEach-Object { $offKB   += $_.SizeKB }
$invKB   = 0; $investigate | ForEach-Object { $invKB   += $_.SizeKB }

$immediateKB   = $cleanKB
$withOffloadKB = $cleanKB + $offKB
$maxPossibleKB = $cleanKB + $offKB + $invKB

Write-SOKLog "  Immediate (clean):        $(Get-HumanSize ($immediateKB * 1KB))" -Level Success
Write-SOKLog "  With offload:             $(Get-HumanSize ($withOffloadKB * 1KB))" -Level Ignore
Write-SOKLog "  Max (incl. investigate):   $(Get-HumanSize ($maxPossibleKB * 1KB))" -Level Warn

$newFreePct = [math]::Round((($cFreeKB + $withOffloadKB) / $cTotalKB) * 100, 1)
Write-SOKLog " " -Level Ignore
Write-SOKLog "  Current C: free:     $(Get-HumanSize ($cFreeKB * 1KB)) ($([math]::Round(100 - $cUsedPct, 1))%)" -Level Ignore
Write-SOKLog "  After clean+offload: $(Get-HumanSize (($cFreeKB + $withOffloadKB) * 1KB)) ($newFreePct%)" -Level Success

# ═══════════════════════════════════════════════════════════════
# EXPORT REPORT JSON
# ═══════════════════════════════════════════════════════════════
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)

$report = [ordered]@{
    metadata = [ordered]@{
        generated_display = Get-Date -Format 'ddMMMyyyy HH:mm:ss'
        generated_iso     = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        hostname          = $env:COMPUTERNAME
        c_drive_total_kb  = $cTotalKB
        c_drive_free_kb   = $cFreeKB
        c_drive_used_pct  = $cUsedPct
        min_size_kb       = $MinSizeKB
        scan_depth        = $ScanDepth
        throttle_limit    = $ThrottleLimit
        dirs_enumerated   = $totalDirCount
        dirs_above_threshold = $sizedDirs.Count
        dirs_after_dedup  = $deduped.Count
        duration_total    = $duration
        duration_enum     = $enumDuration
        duration_sizing   = $sizeDuration
        duration_classify = $classDuration
    }
    summary = [ordered]@{
        cleanable_kb       = $cleanKB
        offloadable_kb     = $offKB
        investigate_kb     = $invKB
        recovery_clean     = Get-HumanSize ($immediateKB * 1KB)
        recovery_offload   = Get-HumanSize ($withOffloadKB * 1KB)
        recovery_max       = Get-HumanSize ($maxPossibleKB * 1KB)
        projected_free_pct = $newFreePct
    }
    classifications = $byStat
    cleanable       = @($cleanable)
    offloadable     = @($offloadable)
    investigate     = @($investigate)
    keepers_top20   = @($keepers)
    all_results     = @($deduped)
}

$report | ConvertTo-Json -Depth 8 | Set-Content -Path $reportPath -Force -Encoding UTF8
Write-SOKLog "Report: $reportPath" -Level Success

# ═══════════════════════════════════════════════════════════════
# EXPORT ERROR LOG JSON
# ═══════════════════════════════════════════════════════════════
$allErrors = @($enumErrors.ToArray()) + @($sizeErrors.ToArray())

[ordered]@{
    metadata = [ordered]@{
        generated_iso = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        total_errors  = $allErrors.Count
        enum_errors   = $enumErrors.Count
        size_errors   = $sizeErrors.Count
    }
    errors = $allErrors
} | ConvertTo-Json -Depth 8 | Set-Content -Path $errorLogPath -Force -Encoding UTF8

Write-SOKLog "Errors: $errorLogPath ($($allErrors.Count) entries)" -Level $(if ($allErrors.Count -gt 0) { 'Warn' } else { 'Success' })

# ═══════════════════════════════════════════════════════════════
# TIMING SUMMARY
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'TIMING' -Level Section
Write-SOKLog "  Phase 1 (enumerate): ${enumDuration}s" -Level Ignore
Write-SOKLog "  Phase 2 (sizing):    ${sizeDuration}s" -Level Ignore
Write-SOKLog "  Phase 3 (classify):  ${classDuration}s" -Level Ignore
Write-SOKLog "  Total:               ${duration}s" -Level Success
