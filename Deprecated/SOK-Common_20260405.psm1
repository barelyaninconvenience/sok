<#
.SYNOPSIS
    SOK-Common.psm1 — Shared module for all SOK automation scripts.
.DESCRIPTION
    v4.3.0: Constants updated per operator spec. Format-SOKAge (HH:mm:ss).
    SKIP_CLAUDE flag. Fibonacci paddings/depths. Sixths thresholds.
.NOTES
    Author: S. Clay Caddell
    Version: 4.3.0
    Date: 27Mar2026
#>

# ═══════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════
$script:SOKVersion = '4.3.0'
$script:SOKName = 'SOK'
$script:DateDisplay = 'ddMMMyyyy HH:mm:ss'
$script:DateISO = 'yyyy-MM-dd HH:mm:ss'
$script:DateFile = 'yyyyMMdd_HHmmss'

$script:ProjectRoot = 'C:\Users\shelc\Documents\Journal\Projects'
$script:ScriptBase = Join-Path $script:ProjectRoot 'scripts'
$script:CommonPath = Join-Path $script:ScriptBase 'common\SOK-Common.psm1'
$script:ConfigPath = Join-Path $script:ScriptBase 'config\sok-config.json'
$script:SOKRoot = Join-Path $script:ProjectRoot 'SOK'
$script:DefaultLogBase = Join-Path $script:SOKRoot 'Logs'

# Operator-specified constants (27Mar2026)
$script:LOCK_TIMEOUT_SEC = 30
$script:LOCK_POLL_MS = 240
$script:HISTORY_CAP = 666
$script:DEFAULT_MAX_LOG_AGE_DAYS = 160
$script:DEFAULT_STALE_HOURS = 48
$script:DEFAULT_TIMEOUT_SEC = 360
$script:PREREQUISITE_NESTING_LIMIT = 21
$script:MAX_UTILIZATION_PCT = 96
$script:SKIP_CLAUDE = $true

$script:RunSequence = @(
    'SOK-Inventory'; 'SOK-SpaceAudit'; 'SOK-ProcessOptimizer'; 'SOK-ServiceOptimizer'
    'SOK-DefenderOptimizer'; 'SOK-Maintenance'; 'SOK-Offload'; 'SOK-Cleanup'
    'SOK-LiveScan'; 'SOK-LiveDigest'
)

$script:PrerequisiteMap = @{
    'SOK-Inventory'         = @('?SOK-Maintenance')
    'SOK-Maintenance'       = @('SOK-Inventory')
    'SOK-SpaceAudit'        = @('SOK-Inventory', '?SOK-Offload')
    'SOK-ProcessOptimizer'  = @('?SOK-ServiceOptimizer')
    'SOK-ServiceOptimizer'  = @('?SOK-ProcessOptimizer')
    'SOK-DefenderOptimizer' = @()
    'SOK-Offload'           = @('SOK-Inventory')
    'SOK-Cleanup'           = @('SOK-Maintenance')
    'SOK-LiveScan'          = @('?SOK-Inventory')
    'SOK-LiveDigest'        = @('SOK-LiveScan')
    'SOK-Scheduler'         = @('SOK-DefenderOptimizer')
    'SOK-Archiver'          = @(); 'SOK-Comparator' = @()
    'SOK-PreSwap'           = @('SOK-Offload', 'SOK-Inventory')
    'SOK-RebootClean'       = @(); 'SOK-Upgrade' = @()
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
        ProtectedProcesses    = @('explorer', 'svchost', 'csrss', 'wininit', 'winlogon',
                                   'lsass', 'services', 'smss', 'dwm', 'taskhostw',
                                   'RuntimeBroker', 'SecurityHealthService', 'SearchHost',
                                   'MsMpEng', 'NisSrv', 'WmiPrvSE',
                                   'Code', 'pwsh', 'powershell', 'WindowsTerminal', 'conhost',
                                   'claude', 'Spotify', 'olk', 'OUTLOOK',
                                   'neo4j', 'mongod', 'mysqld', 'postgres', 'redis-server',
                                   'tailscaled', 'docker', 'dockerd',
                                   'audiodg', 'WavesSysSvc64', 'WavesSvc64')
        AggressionMode        = 'Balanced'
        EnabledManagers       = @('chocolatey', 'scoop', 'winget', 'pip', 'npm',
                                   'cargo', 'dotnet', 'pipx', 'go', 'powershell')
        DisabledManagers      = @('wsl')
        PackageTimeoutSeconds = $script:DEFAULT_TIMEOUT_SEC
        StaleHours            = $script:DEFAULT_STALE_HOURS
        SkipWindowsUpdate     = $false
        SkipCleanmgr          = $true
    }
    if (Test-Path $ConfigPath) {
        try {
            $userConfig = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            foreach ($prop in $userConfig.PSObject.Properties) {
                if ($prop.Name -notmatch '^_') { $defaults[$prop.Name] = $prop.Value }
            }
            Write-SOKLog "Config loaded: $ConfigPath" -Level Ignore
        }
        catch { Write-SOKLog "Config parse failed ($ConfigPath) -- using defaults: $_" -Level Warn }
    }
    else { Write-SOKLog "No config file at $ConfigPath -- using defaults" -Level Ignore }
    return $defaults
}

# ═══════════════════════════════════════════════════════════════
# LOGGING
# ═══════════════════════════════════════════════════════════════
$script:CurrentLogPath = $null
$script:CurrentLogDir = $null

function Get-ScriptLogDir {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ScriptName)
    $cleanName = $ScriptName -replace '^SOK-', ''
    $logDir = Join-Path $script:DefaultLogBase $cleanName
    if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
    return $logDir
}

function Initialize-SOKLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ScriptName)
    $logDir = Get-ScriptLogDir -ScriptName $ScriptName
    $script:CurrentLogDir = $logDir
    $ts = Get-Date -Format $script:DateFile
    $script:CurrentLogPath = Join-Path $logDir "${ScriptName}_${ts}.log"
    $header = @"
════════════════════════════════════════════════════════════
  $script:SOKName v$script:SOKVersion -- $ScriptName
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
        [ValidateSet('Ignore', 'Annotate', 'Warn', 'Error', 'Success', 'Debug', 'Section')]
        [string]$Level = 'Ignore'
    )
    if ($Level -eq 'Section') {
        Write-Host "`n━━━ $Message ━━━" -ForegroundColor Magenta
        $entry = "[$(Get-Date -Format $script:DateISO)] [SECTION ] $Message"
    }
    else {
        $entry = "[$(Get-Date -Format $script:DateISO)] [$($Level.ToUpper().PadRight(8))] $Message"
        switch ($Level) {
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
        $val = $Stats[$key]
        $level = switch -Regex ($key) {
            'fail|error' { if ($val -gt 0) { 'Error' } else { 'Ignore' } }
            'skip|warn'  { if ($val -gt 0) { 'Warn' } else { 'Ignore' } }
            'success|done' { 'Success' }
            default { 'Ignore' }
        }
        $entry = "  $($key.PadRight(34)) $val"
        switch ($level) {
            'Error' { Write-Host $entry -ForegroundColor Red }
            'Warn'  { Write-Host $entry -ForegroundColor Yellow }
            'Success' { Write-Host $entry -ForegroundColor Green }
            default { Write-Host $entry -ForegroundColor Cyan }
        }
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
    param([string]$ScriptName, [hashtable]$RunData, [switch]$AggregateOnly)
    $histDir = Get-ScriptLogDir -ScriptName $ScriptName
    $timestamp = Get-Date -Format $script:DateFile
    $entry = [ordered]@{
        Script    = $ScriptName
        Timestamp = Get-Date -Format $script:DateISO
        Duration  = $RunData.Duration
        Results   = $RunData.Results
    }
    if (-not $AggregateOnly) {
        $filePath = Join-Path $histDir "${ScriptName}_${timestamp}.json"
        $entry | ConvertTo-Json -Depth 8 | Set-Content -Path $filePath -Force -Encoding UTF8
    }
    $aggPath = Join-Path $histDir "${ScriptName}_history.json"
    $aggLock = "$aggPath.lock"
    $lockStart = Get-Date
    while (Test-Path $aggLock) {
        if (((Get-Date) - $lockStart).TotalSeconds -gt $script:LOCK_TIMEOUT_SEC) {
            Remove-Item $aggLock -Force -ErrorAction Continue; break
        }
        Start-Sleep -Milliseconds $script:LOCK_POLL_MS
    }
    Set-Content -Path $aggLock -Value $PID -Force
    try {
        $history = @()
        if (Test-Path $aggPath) {
            try {
                $raw = Get-Content $aggPath -Raw -ErrorAction Continue
                if ($raw -and $raw.Trim().Length -gt 2) {
                    $parsed = $raw | ConvertFrom-Json -ErrorAction Continue
                    if ($parsed -is [array]) { $history = @($parsed) } else { $history = @($parsed) }
                }
            }
            catch {
                Copy-Item $aggPath "$aggPath.corrupted_$(Get-Date -Format $script:DateFile)" -Force -ErrorAction Continue
                $history = @()
            }
        }
        $history += $entry
        if ($history.Count -gt $script:HISTORY_CAP) { $history = $history[-$($script:HISTORY_CAP)..-1] }
        if (Test-Path $aggPath) { Copy-Item $aggPath "$aggPath.bak" -Force -ErrorAction Continue }
        $history | ConvertTo-Json -Depth 8 | Set-Content -Path $aggPath -Force -Encoding UTF8
    }
    finally { Remove-Item $aggLock -Force -ErrorAction Continue }
    if (-not $AggregateOnly) { Write-SOKLog "History: $filePath" -Level Ignore }
}

# ═══════════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════════
function Show-SOKBanner {
    [CmdletBinding()]
    param([string]$ScriptName = 'SOK', [string]$Subheader = '')
    $banner = @"

    ╔═══════════════════════════════════════════════╗
    ║     ███████╗ ██████╗ ██╗  ██╗               ║
    ║     ██╔════╝██╔═══██╗██║ ██╔╝               ║
    ║     ███████╗██║   ██║█████╔╝                ║
    ║     ╚════██║██║   ██║██╔═██╗                ║
    ║     ███████║╚██████╔╝██║  ██╗               ║
    ║     ╚══════╝ ╚═════╝ ╚═╝  ╚═╝  v$($script:SOKVersion)       ║
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
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-SizeKB {
    param([long]$Bytes)
    return [math]::Round($Bytes / 1KB, 2)
}

function Get-HumanSize {
    <# DEPRECATED -- use Get-SizeKB. Emits KB only. #>
    param([long]$Bytes)
    return "$([math]::Round($Bytes / 1KB, 2)) KB"
}

function Invoke-WithTimeout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][scriptblock]$ScriptBlock,
        [int]$TimeoutSeconds = $script:DEFAULT_TIMEOUT_SEC,
        [string]$Description = 'Operation'
    )
    $job = Start-Job -ScriptBlock $ScriptBlock
    $completed = $job | Wait-Job -Timeout $TimeoutSeconds
    if ($null -eq $completed) {
        $job | Stop-Job; $job | Remove-Job -Force
        Write-SOKLog "$Description timed out after ${TimeoutSeconds}s" -Level Warn
        return @{ Success = $false; Error = "Timeout after ${TimeoutSeconds}s"; Output = $null }
    }
    $output = $job | Receive-Job 2>&1
    $hadErrors = $job.State -eq 'Failed'
    $job | Remove-Job -Force
    return @{ Success = -not $hadErrors; Error = if ($hadErrors) { "Job failed" } else { $null }; Output = $output }
}

# ═══════════════════════════════════════════════════════════════
# DEPRECATED FILE MANAGEMENT
# ═══════════════════════════════════════════════════════════════
function Move-ToDeprecated {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$FilePath)
    if (-not (Test-Path $FilePath)) { return }
    $parentDir = Split-Path $FilePath -Parent
    $deprecatedDir = Join-Path $parentDir 'deprecated'
    if (-not (Test-Path $deprecatedDir)) { New-Item -Path $deprecatedDir -ItemType Directory -Force | Out-Null }
    $fileName = Split-Path $FilePath -Leaf
    $destPath = Join-Path $deprecatedDir $fileName
    if (Test-Path $destPath) {
        $ts = Get-Date -Format $script:DateFile
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        $ext = [System.IO.Path]::GetExtension($fileName)
        $destPath = Join-Path $deprecatedDir "${baseName}_${ts}${ext}"
    }
    Move-Item -Path $FilePath -Destination $destPath -Force -ErrorAction Continue
    Write-SOKLog "Deprecated: $fileName" -Level Debug
}

function Remove-StaleLogFiles {
    [CmdletBinding()]
    param(
        [string]$LogDirectory = $script:DefaultLogBase,
        [int]$MaxAgeDays = $script:DEFAULT_MAX_LOG_AGE_DAYS
    )
    if (-not (Test-Path $LogDirectory)) { return }
    $cutoff = (Get-Date).AddDays(-$MaxAgeDays)
    $stale = Get-ChildItem -Path $LogDirectory -File -Recurse -ErrorAction Continue |
        Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Name -notmatch '_history\.json$' -and $_.Name -notmatch '\.lock$' }
    if ($stale.Count -gt 0) {
        foreach ($file in $stale) { Move-ToDeprecated -FilePath $file.FullName }
        Write-SOKLog "Deprecated $($stale.Count) stale files (older than ${MaxAgeDays}d)" -Level Ignore
    }
}

# ═══════════════════════════════════════════════════════════════
# PREREQUISITE SYSTEM
# ═══════════════════════════════════════════════════════════════
function Get-LatestLog {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ScriptName, [string]$Filter = '*.json')
    $logDir = Get-ScriptLogDir -ScriptName $ScriptName
    if (-not (Test-Path $logDir)) { return $null }
    # SilentlyContinue: directory may be empty on first run — expected, not an error
    $latest = Get-ChildItem -Path $logDir -Filter $Filter -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '_history\.json$' -and $_.Name -notmatch '\.lock$' -and $_.Name -notmatch '\.bak$' -and $_.Name -notmatch '\.corrupted_' } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) { return $null }
    $age = (Get-Date) - $latest.LastWriteTime
    $data = $null
    try { $data = Get-Content $latest.FullName -Raw -ErrorAction Continue | ConvertFrom-Json -ErrorAction Continue }
    catch { Write-SOKLog "Failed to parse $($latest.Name): $_" -Level Warn }
    return [PSCustomObject]@{ Path = $latest.FullName; Name = $latest.Name; Age = $age; Data = $data }
}

function Invoke-SOKPrerequisite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CallingScript,
        [int]$StaleHours = $script:DEFAULT_STALE_HOURS,
        [int]$NestingDepth = 0
    )
    if ($NestingDepth -ge $script:PREREQUISITE_NESTING_LIMIT) {
        Write-SOKLog "Prerequisite nesting limit ($script:PREREQUISITE_NESTING_LIMIT) -- skipping" -Level Annotate
        return
    }
    $prereqs = $script:PrerequisiteMap[$CallingScript]
    if (-not $prereqs -or $prereqs.Count -eq 0) { return }
    foreach ($raw in $prereqs) {
        $optional = $false; $prereqName = $raw
        if ($raw.StartsWith('?')) { $optional = $true; $prereqName = $raw.Substring(1) }
        $latest = Get-LatestLog -ScriptName $prereqName
        $fresh = $false
        if ($latest -and $latest.Age.TotalHours -lt $StaleHours) {
            Write-SOKLog "Prerequisite ${prereqName}: fresh ($(Format-SOKAge -Age $latest.Age) old)" -Level Success
            $fresh = $true
        }
        if (-not $fresh) {
            $ageStr = if ($latest) { "$(Format-SOKAge -Age $latest.Age) old" } else { "no log found" }
            if ($optional) {
                Write-SOKLog "Optional prerequisite ${prereqName}: stale ($ageStr) -- skipping" -Level Annotate
                continue
            }
            Write-SOKLog "Prerequisite ${prereqName}: STALE ($ageStr) -- triggering..." -Level Warn
            $scriptPath = Join-Path $script:ScriptBase "${prereqName}.ps1"
            if (-not (Test-Path $scriptPath)) { Write-SOKLog "Cannot find: $scriptPath" -Level Error; continue }
            try {
                $env:SOK_NESTED = '1'; $env:SOK_NESTING_DEPTH = $NestingDepth + 1
                Write-SOKLog "Executing: $scriptPath (depth $($NestingDepth + 1))" -Level Annotate
                & $scriptPath
                Write-SOKLog "Prerequisite $prereqName completed" -Level Success
            }
            catch { Write-SOKLog "Prerequisite $prereqName FAILED: $_" -Level Error }
            finally {
                if ($NestingDepth -eq 0) {
                    Remove-Item Env:\SOK_NESTED -ErrorAction SilentlyContinue
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
    'Show-SOKBanner'; 'Test-IsAdmin'; 'Get-SizeKB'; 'Get-HumanSize'; 'Format-SOKAge'
    'Invoke-WithTimeout'; 'Remove-StaleLogFiles'; 'Move-ToDeprecated'
    'Get-LatestLog'; 'Get-ScriptLogDir'; 'Invoke-SOKPrerequisite'
)
Export-ModuleMember -Variable @(
    'SOKVersion', 'SOKName', 'ProjectRoot', 'ScriptBase', 'SOKRoot',
    'DefaultLogBase', 'ConfigPath', 'RunSequence', 'PrerequisiteMap',
    'MAX_UTILIZATION_PCT', 'DEFAULT_STALE_HOURS', 'DEFAULT_TIMEOUT_SEC',
    'PREREQUISITE_NESTING_LIMIT', 'HISTORY_CAP', 'DEFAULT_MAX_LOG_AGE_DAYS',
    'SKIP_CLAUDE'
)
