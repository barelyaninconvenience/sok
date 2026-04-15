
<#
.SYNOPSIS
    SON OF KLEM - Process Optimizer v1.0
    
.DESCRIPTION
    Smart categorical process management using Windows API properties instead of manual lists.
    Protection strategy:
    - Self-execution: Script's PowerShell/Terminal instance
    - Core Windows: Session 0 critical processes (System, csrss, lsass, dwm, etc.)
    - Security: Windows Defender, antivirus software
    - Audio/Video: Sound and display drivers
    - Shell: Explorer, desktop environment
    
    IGNORES active windows and foreground apps (all fair game unless explicitly protected above)
    
.PARAMETER Mode
    Conservative - Kill only obvious bloat (telemetry, updaters, crash reporters)
    Balanced     - Conservative + idle background, cloud sync, AppData processes (default)
    Aggressive   - Kill everything except explicitly protected categories
    
.PARAMETER DryRun
    Preview what would be terminated without actually killing processes
    
.EXAMPLE
    .\SON-OF-KLEM-ProcessOptimizer.ps1
    Run balanced optimization
    
.EXAMPLE
    .\SON-OF-KLEM-ProcessOptimizer.ps1 -Mode Aggressive -DryRun
    Preview aggressive optimization without executing
    
.NOTES
    Version: 1.0
    Project: SON OF KLEM System Automation Suite
    Integrates with Maintenance script's decision log
#>

[CmdletBinding()]
param(
    [ValidateSet('Conservative','Balanced','Aggressive')]
    [string]$Mode = 'Balanced',
    [switch]$DryRun
)

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"


$script:MyPID = $PID
$script:MyParentPID = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID").ParentProcessId
$ConfigDir = Join-Path $env:APPDATA "SON-OF-KLEM"
$MaintenanceDecisions = Join-Path $ConfigDir "maintenance-decisions.json"

$null = New-Item -ItemType Directory -Path $ConfigDir -Force

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "   ███████╗  ██████╗  ███╗   ██╗      ██████╗  ███████╗     ██╗  ██╗ ██╗      ███████╗ ███╗   ███╗" -ForegroundColor DarkCyan
    Write-Host "   ██╔════╝ ██╔═══██╗ ████╗  ██║     ██╔═══██╗ ██╔════╝     ██║ ██╔╝ ██║      ██╔════╝ ████╗ ████║" -ForegroundColor Cyan
    Write-Host "   ███████╗ ██║   ██║ ██╔██╗ ██║     ██║   ██║ █████╗       █████╔╝  ██║      █████╗   ██╔████╔██║" -ForegroundColor Cyan
    Write-Host "   ╚════██║ ██║   ██║ ██║╚██╗██║     ██║   ██║ ██╔══╝       ██╔═██╗  ██║      ██╔══╝   ██║╚██╔╝██║" -ForegroundColor DarkCyan
    Write-Host "   ███████║ ╚██████╔╝ ██║ ╚████║     ╚██████╔╝ ██║          ██║  ██╗ ███████╗ ███████╗ ██║ ╚═╝ ██║" -ForegroundColor Cyan
    Write-Host "   ╚══════╝  ╚═════╝  ╚═╝  ╚═══╝      ╚═════╝  ╚═╝          ╚═╝  ╚═╝ ╚══════╝ ╚══════╝ ╚═╝     ╚═╝" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "   [===]  PROCESS OPTIMIZER v1.0  [===]  Mode: $Mode  [===]  Self-Protected PID $script:MyPID  [===]  Smart Categorical  [===]" -ForegroundColor Gray
    Write-Host ""
}

function Write-Status {
    param([string]$Message, [string]$Level = 'Info')
    $colors = @{Info='Cyan'; Success='Green'; Warning='Yellow'; Error='Red'; Debug='DarkGray'}
    $symbols = @{Info='[*]'; Success='[+]'; Warning='[!]'; Error='[-]'; Debug='[.]'}
    $timestamp = Get-Date -Format 'HH:mm:ss'
    Write-Host "[$timestamp] $($symbols[$Level]) $Message" -ForegroundColor $colors[$Level]
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("   " + ("=" * 120)) -ForegroundColor DarkCyan
    Write-Host ("   " + $Title.ToUpper().PadRight(120)) -ForegroundColor Cyan
    Write-Host ("   " + ("=" * 120)) -ForegroundColor DarkCyan
    Write-Host ""
}

function Get-ProcessCategory {
    param($Process)
    
    $name = $Process.ProcessName
    $id = $Process.Id
    
    # CRITICAL: Self-protection
    if ($id -eq $script:MyPID -or $id -eq $script:MyParentPID) {
        return @{Category='ScriptExecution'; Kill=$false; Reason='Running this script'}
    }
    
    try {
        $wmiProc = Get-WmiObject Win32_Process -Filter "ProcessId=$id" -ErrorAction Stop
        $path = $wmiProc.ExecutablePath
        $sessionId = $Process.SessionId
        $company = $Process.Company
        
        # REGEX OPTIMIZATION: Exact match string anchors ^ $ for Core Windows
        if ($sessionId -eq 0 -and $name -match '(?i)^(System|Registry|smss|csrss|wininit|services|lsass|dwm|winlogon|fontdrvhost|LogonUI)$') {
            return @{Category='WindowsCore'; Kill=$false; Reason='Session 0 critical'}
        }
        
        # REGEX OPTIMIZATION: Negative lookahead for telemetry
        if ($name -eq 'svchost' -or ($sessionId -eq 0 -and $name -notmatch '(?i)telemetry')) {
            return @{Category='WindowsService'; Kill=$false; Reason='Windows service'}
        }
        
        # REGEX OPTIMIZATION: Grouped logical matches for Security
        if ($company -match '(?i)Microsoft|Symantec|McAfee' -and $name -match '(?i)Defender|MsMp|Niss') {
            return @{Category='Security'; Kill=$false; Reason='Security software'}
        }
        
        # REGEX OPTIMIZATION: Grouped logical matches for Audio/Video
        if ($company -match '(?i)Realtek|NVIDIA|AMD' -or $name -match '(?i)^audiodg|audio') {
            return @{Category='AudioVideo'; Kill=$false; Reason='Audio/Video driver'}
        }
        
        # REGEX OPTIMIZATION: Exact match string anchors for Shell
        if ($name -match '(?i)^(explorer|sihost|ShellExperienceHost|StartMenuExperienceHost|dwm|RuntimeBroker)$') {
            return @{Category='Shell'; Kill=$false; Reason='Windows shell/runtime'}
        }
        
        # AGGRESSIVE CATEGORIZATION - KILL THESE
        
        # REGEX OPTIMIZATION: Collapse 5 checks into 1 compiled pattern
        if ($name -match '(?i)telemetry|diag|census|CompatTelRunner|DiagsCap') {
            return @{Category='Telemetry'; Kill=$true; Reason='Telemetry'}
        }
        
        if ($name -match '(?i)update' -and $company -notmatch '(?i)microsoft') {
            return @{Category='Updater'; Kill=$true; Reason='Third-party updater'}
        }
        
        if ($name -match '(?i)crash|reporter') {
            return @{Category='CrashReporter'; Kill=$true; Reason='Crash reporter'}
        }
        
        # REGEX OPTIMIZATION: Directory path boundary matching
        if ($path -match '(?i)\\(OneDrive|Dropbox|Google\s?Drive)\\' -and $Process.MainWindowHandle -eq 0) {
            return @{Category='CloudSync'; Kill=$true; Reason='Cloud sync background'}
        }
        
        if ($path -match '(?i)\\AppData\\Local\\' -and $Process.MainWindowHandle -eq 0) {
            return @{Category='AppDataBackground'; Kill=$true; Reason='AppData background'}
        }
        
        if ($path -match '(?i)\\AppData\\Roaming\\' -and $Process.MainWindowHandle -eq 0) {
            return @{Category='AppDataRoaming'; Kill=$true; Reason='AppData roaming background'}
        }
        
        try {
            if ($Process.CPU -gt 5 -and $Process.MainWindowHandle -eq 0) {
                return @{Category='HighCPUBackground'; Kill=$true; Reason='High CPU background'}
            }
        } catch {}
        
        if ($sessionId -ne 0) {
            return @{Category='UserProcess'; Kill=$true; Reason='User process (aggressive mode)'}
        }
        
        return @{Category='Unknown'; Kill=$false; Reason='Unknown Session 0'}
        
    } catch {
        return @{Category='Unknown'; Kill=$false; Reason='Error getting info'}
    }
}
function Get-KillDecision {
    param($Process, $Category, $MaintenanceData, $Mode)
    
    $name = $Process.ProcessName
    
    if ($MaintenanceData.ContainsKey($name)) {
        $maint = $MaintenanceData[$name]
        if ($maint.MaintenanceCategory -eq 'Closable') {
            return @{Kill=$true; Reason='Maintenance: User marked closable'}
        }
        if ($maint.MaintenanceCategory -eq 'Essential' -or $maint.MaintenanceCategory -eq 'Critical') {
            return @{Kill=$false; Reason='Maintenance: Protected'}
        }
    }
    
    $neverKillCategories = @('ScriptExecution','WindowsCore','WindowsService','Security','AudioVideo','Shell')
    
    if ($Category.Category -in $neverKillCategories) {
        return @{Kill=$false; Reason=$Category.Reason}
    }
    
    switch ($Mode) {
        'Conservative' {
            $killCategories = @('Telemetry','Updater','CrashReporter')
            return @{Kill=($Category.Category -in $killCategories); Reason=$Category.Reason}
        }
        'Balanced' {
            $killCategories = @('Telemetry','Updater','CrashReporter','CloudSync','AppDataBackground','AppDataRoaming','HighCPUBackground')
            return @{Kill=($Category.Category -in $killCategories); Reason=$Category.Reason}
        }
        'Aggressive' {
            return @{Kill=$Category.Kill; Reason=$Category.Reason}
        }
    }
}

function Import-MaintenanceCategories {
    if (-not (Test-Path $MaintenanceDecisions)) { 
        Write-Status "No maintenance decisions found (run SON-OF-KLEM-Maintenance.ps1 first)" "Debug"
        return @{} 
    }
    
    try {
        $data = Get-Content $MaintenanceDecisions -Raw | ConvertFrom-Json
        $categories = @{}
        foreach ($decision in $data.decisions) {
            $categories[$decision.process] = @{
                MaintenanceCategory = $decision.category
                Reason = $decision.reason
            }
        }
        Write-Status "Imported $($categories.Count) decisions from maintenance log" "Success"
        return $categories
    } catch {
        Write-Status "Failed to import maintenance decisions: $_" "Debug"
        return @{}
    }
}

Show-Header

$maintData = Import-MaintenanceCategories

Write-SectionHeader "PROCESS ANALYSIS"

Write-Status "Analyzing all running processes..." "Info"
Write-Host ""

$results = @{
    ByCategory = @{}
    ToKill = @()
    Protected = @()
}

foreach ($proc in Get-Process) {
    try {
        $category = Get-ProcessCategory $proc
        $decision = Get-KillDecision $proc $category $maintData $Mode
        
        if (-not $results.ByCategory.ContainsKey($category.Category)) {
            $results.ByCategory[$category.Category] = @{Count=0; Killed=0; Protected=0}
        }
        $results.ByCategory[$category.Category].Count++
        
        if ($decision.Kill) {
            $results.ToKill += @{Process=$proc; Category=$category.Category; Reason=$decision.Reason}
            $results.ByCategory[$category.Category].Killed++
        } else {
            $results.Protected += $proc.ProcessName
            $results.ByCategory[$category.Category].Protected++
        }
    } catch {}
}

Write-Host "   Category Analysis:" -ForegroundColor Cyan
Write-Host ("   " + ("-" * 120)) -ForegroundColor DarkCyan

foreach ($cat in $results.ByCategory.Keys | Sort-Object) {
    $info = $results.ByCategory[$cat]
    $color = if ($info.Killed -gt 0) { 'Red' } elseif ($info.Protected -gt 0) { 'Green' } else { 'Gray' }
    $killText = if ($info.Killed -gt 0) { "[KILL:$($info.Killed)]" } else { "" }
    $keepText = if ($info.Protected -gt 0) { "[KEEP:$($info.Protected)]" } else { "" }
    
    Write-Host ("   {0,-30} Total:{1,4}  {2,-12} {3,-12}" -f $cat, $info.Count, $killText, $keepText) -ForegroundColor $color
}

Write-Host ("   " + ("-" * 120)) -ForegroundColor DarkCyan
Write-Host ""

Write-SectionHeader "TERMINATION TARGETS"

Write-Status "Processes marked for termination: $($results.ToKill.Count)" "Warning"
Write-Host ""

$grouped = $results.ToKill | Group-Object Category | Sort-Object Count -Descending
foreach ($group in $grouped) {
    Write-Host "   [$($group.Name)] - $($group.Count) processes" -ForegroundColor Yellow
    $group.Group | Select-Object -First 8 | ForEach-Object {
        Write-Host "      > $($_.Process.ProcessName) - $($_.Reason)" -ForegroundColor DarkGray
    }
    if ($group.Count -gt 8) {
        Write-Host "      ... and $($group.Count - 8) more" -ForegroundColor DarkGray
    }
    Write-Host ""
}

if ($DryRun) {
    Write-Host ""
    Write-Status "DRY RUN: No processes terminated (preview only)" "Warning"
    Write-Host ""
} else {
    Write-Host ""
    Write-Status "Initiating termination sequence in 3 seconds..." "Warning"
    Start-Sleep -Seconds 3
    
    Write-SectionHeader "TERMINATION IN PROGRESS"
    
    $killed = 0
    $failed = 0
    
    foreach ($item in $results.ToKill) {
        try {
            $item.Process.Kill($true)
            $killed++
            Write-Status "Terminated: $($item.Process.ProcessName)" "Success"
        } catch {
            $failed++
            Write-Status "Failed: $($item.Process.ProcessName)" "Debug"
        }
    }
    
    Write-Host ""
    Write-Host ("   " + ("=" * 120)) -ForegroundColor Green
    Write-Host "   OPTIMIZATION COMPLETE" -ForegroundColor Green
    Write-Host ("   " + ("=" * 120)) -ForegroundColor Green
    Write-Host ""
    Write-Host "   Terminated: $killed processes  |  Failed: $failed  |  Protected: $($results.Protected.Count)" -ForegroundColor Cyan
    Write-Host ""
}
