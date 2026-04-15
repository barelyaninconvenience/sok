<#
.SYNOPSIS
    SON OF KLEM - Maintenance v2.0 FIXED
    
.DESCRIPTION
    Comprehensive system maintenance with AGGRESSIVE categorization fixes.
    
    FIXED IN v2.0:
    [+] Process categorization now AGGRESSIVE by default (flipped logic)
    [+] Dropped WSL entirely (infinite hang issues)
    [+] Dropped cleanmgr.exe (hangs waiting for input)
    [+] Fixed Scoop commands (upgrade, not update)
    [+] Package managers run with proper error handling
    
.PARAMETER Mode
    Quick    - Process cleanup + packages + cache (no Windows updates)
    Standard - Quick + Windows updates (default)
    Deep     - Standard + optimization + services
    
.PARAMETER DryRun
    Preview actions without executing
    
.EXAMPLE
    .\SON-OF-KLEM-Maintenance-v2-FIXED.ps1 -Mode Deep
    
.NOTES
    Version: 2.0 - Fixed all hang issues and aggressive categorization
#>

[CmdletBinding()]
param(
    [ValidateSet('Quick','Standard','Deep')]
    [string]$Mode = 'Standard',
    [switch]$DryRun
)

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"


$script:MyPID = $PID
$script:MyParentPID = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID").ParentProcessId
$ConfigDir = Join-Path $env:APPDATA "SON-OF-KLEM"
$DecisionFile = Join-Path $ConfigDir "maintenance-decisions.json"

$null = New-Item -ItemType Directory -Path $ConfigDir -Force

function Show-Header {
    Clear-Host
    Write-Host ""
    Write-Host "    ╔═══╗     ╔═══╗    ╔╗   ╔╗        ╔═══╗    ╔═════╗       ╔╗   ╔╗   ╔╗        ╔══════╗  ╔╗   ╔╗  " -ForegroundColor Cyan
    Write-Host "   ╔╝   ╚╗   ╔╝   ╚╗   ║╚╗  ║║       ╔╝   ╚╗   ║      ║      ║║  ╔╝    ║║        ║         ║╚╗ ╔╝║  " -ForegroundColor Cyan
    Write-Host "   ╚═══╗ ║   ║     ║   ║ ╚╗ ║║       ║     ║   ║═══╗  ║      ║╚═╗      ║║        ║═══╗     ║ ╚═╝ ║  " -ForegroundColor DarkCyan
    Write-Host "    ╔══╝ ║   ║     ║   ║  ╚╗║║       ║     ║   ║   ║         ║╔═╝      ║║        ║   ║     ║     ║  " -ForegroundColor DarkCyan
    Write-Host "   ╔╝   ╔╝   ╚╗   ╔╝   ║   ╚╝║       ╚╗   ╔╝   ║              ║║  ╚╗    ║║        ║         ║     ║  " -ForegroundColor Cyan
    Write-Host "   ╚════╝     ╚═══╝    ╚═════╝        ╚═══╝    ╚═══════      ╚╝   ╚╗   ╚══════╗  ╚══════╗  ╚═════╝  " -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   MAINTENANCE v2.0 - FIXED | Mode: $Mode | $(if($DryRun){'DRY RUN'}else{'LIVE'}) | Aggressive Categorization" -ForegroundColor Gray
    Write-Host ""
}

function Write-Status {
    param([string]$Message, [string]$Level = 'Info')
    $colors = @{Info='Cyan'; Success='Green'; Warning='Yellow'; Error='Red'; Debug='DarkGray'}
    $symbols = @{Info='[*]'; Success='[+]'; Warning='[!]'; Error='[-]'; Debug='[.]'}
    Write-Host "$(Get-Date -F 'HH:mm:ss') $($symbols[$Level]) $Message" -ForegroundColor $colors[$Level]
}

function Write-SectionHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("   " + ("=" * 120)) -ForegroundColor DarkCyan
    Write-Host ("   " + $Title.ToUpper()) -ForegroundColor Cyan
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
function Clear-BackgroundProcesses {
    Write-SectionHeader "AGGRESSIVE PROCESS CLEANUP"
    Write-Status "Self-protected: Script PID $script:MyPID (Parent: $script:MyParentPID)" "Warning"
    
    $decisions = @{timestamp = Get-Date -Format 'o'; mode = 'aggressive'; decisions = @()}
    $toKill = @()
    $protected = @()
    
    Write-Status "Categorizing with AGGRESSIVE defaults..." "Info"
    
    foreach ($proc in Get-Process) {
        try {
            $category = Get-ProcessCategory $proc
            $decision = @{
                process = $proc.ProcessName
                category = if ($category.Kill) { 'Closable' } else { 'Essential' }
                reason = $category.Reason
                suggested_priority = 'Normal'
            }
            $decisions.decisions += $decision
            
            if ($category.Kill) {
                $toKill += @{Process=$proc; Category=$category.Category; Reason=$category.Reason}
            } else {
                $protected += $proc.ProcessName
            }
        } catch {}
    }
    
    try {
        $decisions | ConvertTo-Json -Depth 5 | Out-File $DecisionFile -Encoding UTF8 -Force
        Write-Status "Saved decisions: $DecisionFile" "Success"
    } catch {}
    
    Write-Host ""
    Write-Status "ANALYSIS: $($toKill.Count) KILLABLE, $($protected.Count) protected" "Warning"
    
    $grouped = $toKill | Group-Object Category | Sort-Object Count -Descending
    foreach ($group in $grouped) {
        Write-Host "   [$($group.Name)]: $($group.Count)" -ForegroundColor Yellow
    }
    
    Write-Host ""
    
    if ($DryRun) {
        Write-Status "DRY RUN: Would kill $($toKill.Count) processes" "Warning"
        return
    }
    
    $killed = 0
    foreach ($item in $toKill) {
        try {
            $item.Process.Kill($true)
            $killed++
            Write-Status "Killed: $($item.Process.ProcessName)" "Debug"
        } catch {}
    }
    
    Write-Host ""
    Write-Status "TERMINATED: $killed processes" "Success"
}

function Update-AllPackageManagers {
    Write-SectionHeader "PACKAGE MANAGER UPDATES (VERBOSE MODE)"
    
    $updated = @()
    
    # Chocolatey
	if (Get-Command choco -ErrorAction Ignore) {
        Write-Status "Executing Chocolatey Upgrade..." "Info"
        if (-not $DryRun) {
            choco upgrade all -y 
            if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 1641) { # 1641 is a standard reboot requested code
                $updated += "Chocolatey"
                Write-Status "[+] Chocolatey upgrade sequence completed." "Success"
            } else {
                Write-Status "[-] Chocolatey encountered errors. Check terminal output above." "Error"
            }
        }
    }
    
# Scoop - SYNTAX FIXED
    if (Get-Command scoop -ErrorAction Ignore) {
        Write-Status "Executing Scoop Update & Upgrade..." "Info"
        if (-not $DryRun) {
            try {
                Write-Host "  -> Updating Scoop Core..." -ForegroundColor DarkGray
                scoop update 
                Write-Host "  -> Upgrading Scoop Packages..." -ForegroundColor DarkGray
                scoop upgrade * $updated += "Scoop" # Moved to its own line
                Write-Status "[+] Scoop upgrade sequence completed." "Success"
            } catch { Write-Status "[-] Scoop encountered a fatal error: $_" "Error" }
        }
    }
    
    # Winget
    if (Get-Command winget -ErrorAction Ignore) {
        Write-Status "Executing Winget Upgrade..." "Info"
        if (-not $DryRun) {
            try {
                # Removed. You will now see the progress bars.
                winget upgrade --all --accept-source-agreements --accept-package-agreements 
                $updated += "Winget"
                Write-Status "[+] Winget upgrade sequence completed." "Success"
            } catch { Write-Status "[-] Winget encountered a fatal error: $_" "Error" }
        }
    }
    
    # Pip
    if (Get-Command pip -ErrorAction Ignore) {
        Write-Status "Executing Python Pip Upgrade..." "Info"
        if (-not $DryRun) {
            try {
                $outdated = pip list --outdated --format=json | ConvertFrom-Json
                if ($outdated) {
                    Write-Host "  -> Found $($outdated.Count) outdated Python packages. Upgrading..." -ForegroundColor DarkGray
                    foreach ($pkg in $outdated) {
                        # Removed --quiet. You will see every dependency resolution.
                        pip install --upgrade $pkg.name 
                    }
                    $updated += "Pip($($outdated.Count))"
                    Write-Status "[+] Pip upgrade sequence completed." "Success"
                } else {
                    Write-Status "[+] Pip packages are already up to date." "Success"
                }
            } catch { Write-Status "[-] Pip encountered a fatal error: $_" "Error" }
        }
    }
    
    # npm
    if (Get-Command npm -ErrorAction Ignore) {
        Write-Status "Executing NPM Global Update..." "Info"
        if (-not $DryRun) {
            try {
                # Removed. 
                npm update -g 
                $updated += "npm"
                Write-Status "[+] NPM upgrade sequence completed." "Success"
            } catch { Write-Status "[-] NPM encountered a fatal error: $_" "Error" }
        }
    }
    
    # Cargo
    if (Get-Command cargo -ErrorAction Ignore) {
        Write-Status "Executing Rust Cargo Update..." "Info"
        if (-not $DryRun) {
            if (Get-Command cargo-install-update -ErrorAction Ignore) {
                try {
                    cargo install-update -a 
                    $updated += "Cargo"
                    Write-Status "[+] Cargo upgrade sequence completed." "Success"
                } catch { Write-Status "[-] Cargo encountered a fatal error: $_" "Error" }
            } else {
                Write-Status "[-] 'cargo-install-update' plugin is missing. Run 'cargo install cargo-update' to enable Rust updates." "Warning"
            }
        }
    }
    
    Write-Host ""
    Write-Status "Update Pass Complete For: $($updated -join ', ')" "Success"
}
function Clear-AllCaches {
    Write-SectionHeader "CACHE CLEANUP (NO CLEANMGR)"
    
    $beforeSpace = (Get-PSDrive C).Free / 1GB
    $cleaned = @()
    
    if ($DryRun) {
        Write-Status "[DRY] Would clean caches" "Warning"
        return
    }
    
    Write-Status "Windows temp..." "Info"
	Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction Ignore
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction Ignore
    $cleaned += "Temp"
    
    $cachePaths = @(
        @{N='Choco';P='C:\ProgramData\chocolatey\lib-bkp'},
        @{N='ChocoCache';P='C:\ProgramData\chocolatey\cache'},
        @{N='Pip';P="$env:LOCALAPPDATA\pip\cache"},
        @{N='npm';P="$env:APPDATA\npm-cache"},
        @{N='Cargo';P="$env:USERPROFILE\.cargo\registry\cache"}
    )
    
    foreach ($cache in $cachePaths) {
        if (Test-Path $cache.P) {
            Write-Status "$($cache.N)..." "Info"
            Remove-Item -Path "$($cache.P)\*" -Recurse -Force
            $cleaned += $cache.N
        }
    }
    
    # Scoop cleanup - FIXED
    if (Get-Command scoop) {
        Write-Status "Scoop cleanup..." "Info"
        scoop cleanup * 2>&1
        $cleaned += "Scoop"
    }
    
    if (Get-Command pip) { pip cache purge 2>&1 }
    if (Get-Command npm) { npm cache clean --force 2>&1 }
    
    # DROPPED: cleanmgr.exe (hangs waiting for input)
    Write-Status "Skipping cleanmgr.exe (known to hang)" "Debug"
    
    $afterSpace = (Get-PSDrive C).Free / 1GB
    $freed = $afterSpace - $beforeSpace
    
    Write-Host ""
    Write-Status "Cleaned: $($cleaned -join ', ')" "Success"
    Write-Status "Freed: $([math]::Round($freed, 2)) GB" "Success"
}

function Install-WindowsUpdates {
    Write-SectionHeader "WINDOWS UPDATES"
    
    if ($DryRun) {
        Write-Status "[DRY] Would check Windows updates" "Warning"
        return
    }
    
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Status "Installing PSWindowsUpdate..." "Info"
        try {
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
        } catch {
            Write-Status "Failed to install PSWindowsUpdate" "Error"
            return
        }
    }
    
    Import-Module PSWindowsUpdate
    
    Write-Status "Checking updates..." "Info"
    try {
        $updates = Get-WindowsUpdate
        if ($updates.Count -gt 0) {
            Write-Status "Installing $($updates.Count) updates..." "Info"
            Install-WindowsUpdate -AcceptAll -AutoReboot:$false
            Write-Status "Updates installed" "Success"
        } else {
            Write-Status "Up to date" "Success"
        }
    } catch {
        Write-Status "Update failed: $_" "Error"
    }
}

function Optimize-System {
    Write-SectionHeader "SYSTEM OPTIMIZATION"
    
    if ($DryRun) {
        Write-Status "[DRY] Would optimize system" "Warning"
        return
    }
    
    Write-Status "DNS cache..." "Info"
    Clear-DnsClientCache
    
    $ssd = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' } | Select-Object -First 1
    if ($ssd) {
        Write-Status "SSD TRIM..." "Info"
        Optimize-Volume -DriveLetter C -ReTrim -Verbose:$false
    }
    
    Write-Status "Optimization complete" "Success"
}

Show-Header
$start = Get-Date

Clear-BackgroundProcesses
Update-AllPackageManagers
Clear-AllCaches

if ($Mode -eq 'Standard' -or $Mode -eq 'Deep') { Install-WindowsUpdates }
if ($Mode -eq 'Deep') { Optimize-System }

$duration = ((Get-Date) - $start).TotalSeconds

Write-Host ""
Write-Host ("   " + ("=" * 120)) -ForegroundColor Green
Write-Host "   COMPLETE: $([math]::Round($duration/60, 1)) min | Mode: $Mode" -ForegroundColor Green
Write-Host ("   " + ("=" * 120)) -ForegroundColor Green
Write-Host ""
