<#
.SYNOPSIS
    TITAN System Inventory - ULTIMATE Edition
.DESCRIPTION
    Comprehensive system auditing with thread-safe collections, file hashing,
    configurable scan depths, and granular error handling with beautiful ASCII.
.NOTES
    Version: ULTIMATE 1.0
    Compatibility: PowerShell 5.1 and 7+
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$env:USERPROFILE\Documents\Journal\Projects\TITAN\Inventory\TITAN_System_Inventory_$(Get-Date -Format 'ddMMMyyyy').json",
    [Parameter(Mandatory=$false)]
    [switch]$IncludeFileHashes,
    [Parameter(Mandatory=$false)]
    [ValidateRange(1,5)]
    [int]$ScanDepth = 2,
    [Parameter(Mandatory=$false)]
    [switch]$ExportCSV
)

#Requires -Version 5.1
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$script:ScanStartTime = Get-Date

# High Priority Execution
$proc = Get-Process -Id $PID
$proc.PriorityClass = "High"

# Ensure Output Directory
$OutDir = Split-Path $OutputPath -Parent
if (!(Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

# Thread-Safe Global Data Storage
$script:GlobalData = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()

# Visual Functions
function Show-Progress {
    param($Current, $Total, $Activity)
    if ($Total -eq 0) { $Total = 1 }
    $percent = [math]::Min(100, [math]::Round(($Current / $Total) * 100))
    $filled = [math]::Round(50 * ($percent / 100))
    $bar = "█" * $filled + "░" * (50 - $filled)
    Write-Host "`r  [$bar] $percent% - $Activity ($Current/$Total)" -NoNewline -ForegroundColor Cyan
}

function Write-Status {
    param($Message, $Status="INFO", $Color="Cyan")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor DarkGray
    Write-Host "[$Status] " -NoNewline -ForegroundColor $Color
    Write-Host $Message
}

Clear-Host
Write-Host ""
Write-Host "           ╔═══════════════════════════════════════════════╗" -ForegroundColor Blue
Write-Host "         ╔═╝░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒╚═╗" -ForegroundColor DarkCyan
Write-Host "       ╔═╝▒░                                            ░▒╚═╗" -ForegroundColor Cyan
Write-Host "      ║▓░   ████████╗██╗████████╗ █████╗ ███╗   ██╗     ░▓║" -ForegroundColor White
Write-Host "      ║░▒   ╚══██╔══╝██║╚══██╔══╝██╔══██╗████╗  ██║     ▒░║" -ForegroundColor White
Write-Host "      ║▒░      ██║   ██║   ██║   ███████║██╔██╗ ██║     ░▒║" -ForegroundColor Cyan
Write-Host "      ║░▓      ██║   ██║   ██║   ██╔══██║██║╚██╗██║     ▓░║" -ForegroundColor Cyan
Write-Host "      ║▓░      ██║   ██║   ██║   ██║  ██║██║ ╚████║     ░▓║" -ForegroundColor Blue
Write-Host "      ║░▒      ╚═╝   ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝     ▒░║" -ForegroundColor Blue
Write-Host "      ║▒░                                                ░▒║" -ForegroundColor DarkCyan
Write-Host "      ║░▓     ██╗███╗   ██╗██╗   ██╗███████╗███╗   ██╗  ▓░║" -ForegroundColor White
Write-Host "      ║▓░     ██║████╗  ██║██║   ██║██╔════╝████╗  ██║  ░▓║" -ForegroundColor White
Write-Host "      ║░▒     ██║██╔██╗ ██║██║   ██║█████╗  ██╔██╗ ██║  ▒░║" -ForegroundColor Cyan
Write-Host "      ║▒░     ██║██║╚██╗██║╚██╗ ██╔╝██╔══╝  ██║╚██╗██║  ░▒║" -ForegroundColor Cyan
Write-Host "      ║░▓     ██║██║ ╚████║ ╚████╔╝ ███████╗██║ ╚████║  ▓░║" -ForegroundColor Blue
Write-Host "      ║▓░     ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝  ░▓║" -ForegroundColor Blue
Write-Host "      ║░▒                                                ▒░║" -ForegroundColor DarkCyan
Write-Host "       ╚═╗▒░         SYSTEM INVENTORY                 ░▒╔═╝" -ForegroundColor Cyan
Write-Host "         ╚═╗░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒░▒▓❀▓▒╔═╝" -ForegroundColor DarkCyan
Write-Host "           ╚═══════════════════════════════════════════════╝" -ForegroundColor Blue
Write-Host ""
Write-Host "              Thread-Safe • High Priority • Comprehensive" -ForegroundColor Gray
Write-Status "Configuration: Depth=$ScanDepth | Hashing=$IncludeFileHashes" "CONF" "Gray"
Write-Host ""

# ============================================================================
# ROBUST COLLECTOR LOGIC (ScriptBlock)
# ============================================================================
$ScriptBlock_Collectors = {
    param($Context)
	
	    # Unpack Context
    $TaskName = $Context.TaskName
    $Depth    = $Context.ScanDepth
    $DoHash   = $Context.IncludeFileHashes

    # ------------------------------------------------------------------------
    # SAFETY HELPERS
    # ------------------------------------------------------------------------
    function Invoke-SafeBlock {
        param([scriptblock]$Action, [string]$Name, [object]$Default = @{})
        try {
            return & $Action
        } catch {
            return @{ Error = "Critical Failure in component '$Name': $($_.Exception.Message)" }
        }
    }

    function Get-SafeString {
        param($InputObject)
        if ($null -eq $InputObject) { return "" }
        return "$InputObject".Trim()
    }

    function Get-SafeMath {
        param($Value, $Divisor)
        try {
            if ($null -eq $Value -or $Value -eq 0) { return 0 }
            return [math]::Round($Value / $Divisor, 2)
        } catch { return 0 }
    }

    function Get-HashSafe {
        param($Path)
		if (!$DoHash -or !(Test-Path $Path)) { return $null }
		try { return (Get-FileHash -Path $Path -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
		} catch {
			return $null
		}
	}

    # ------------------------------------------------------------------------
    # COLLECTOR: SYSTEM METADATA
    # ------------------------------------------------------------------------
    if ($TaskName -eq "System_Meta") {
        return Invoke-SafeBlock -Name "System_Meta" -Action {
            $os   = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object -First 1
            $cs   = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue | Select-Object -First 1
            $cpu  = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
            
            # Safe Drive Mapping
            $drives = @()
            $rawDrives = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
            if ($rawDrives) {
                foreach ($d in $rawDrives) {
                    $drives += @{
                        DeviceID    = Get-SafeString $d.DeviceID
                        SizeGB      = Get-SafeMath $d.Size 1GB
                        FreeSpaceGB = Get-SafeMath $d.FreeSpace 1GB
                    }
                }
            }

            # Null-Safe Returns
            return @{
                hostname = $env:COMPUTERNAME
                os       = @{ 
                    Name    = Get-SafeString $os.Caption
                    Version = Get-SafeString $os.Version
                    Build   = Get-SafeString $os.BuildNumber
                }
                hardware = @{ 
                    cpu    = Get-SafeString $cpu.Name
                    ram_gb = Get-SafeMath $cs.TotalPhysicalMemory 1GB
                }
                storage  = $drives
            }
        }
    }

    # ------------------------------------------------------------------------
    # COLLECTOR: WINGET (Text Parsing)
    # ------------------------------------------------------------------------
    if ($TaskName -eq "Winget") {
        return Invoke-SafeBlock -Name "Winget" -Action {
            if (!(Get-Command winget -ErrorAction SilentlyContinue)) { return @{ Status = "Winget Not Found" } }
            
            # Force UTF8 to prevent encoding crashes
            [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
            
            $raw = winget list --accept-source-agreements 2>&1 | Out-String
            if ([string]::IsNullOrWhiteSpace($raw)) { return @{ count = 0; status = "No output from CLI" } }

            $pkgs = @()
            # Strict Regex with Safety Checks
			$regex = '(?m)^(.+?)\s{2,}([^\s]+)\s{2,}([^\s]+)'            
            try {
                $matches = [regex]::Matches($raw, $regex)
                foreach ($m in $matches) {
                    $n = "$(Get-SafeString $m.Groups[1].Value)".Trim()
                    $i = "$(Get-SafeString $m.Groups[2].Value)".Trim()
                    $v = "$(Get-SafeString $m.Groups[3].Value)".Trim()

                    # Filter out headers/separators
                    if ($i -ne "Id" -and $i -ne "------" -and $i.Length -gt 0) {
                        $pkgs += @{ Name = $n; Id = $i; Ver = $v }
                    }
                }
            } catch {
                return @{ Error = "Regex Parsing Failed"; Details = $_.Exception.Message }
            }

            return @{ count = $pkgs.Count; packages = $pkgs }
        }
    }
	
	# ------------------------------------------------------------------------
    # COLLECTOR: PS MODULES (Optimized & Safe)
    # ------------------------------------------------------------------------
    if ($TaskName -eq "PS_Modules") {
        return Invoke-SafeBlock -Name "PS_Modules" -Action {
            $modules = @()
            # Split path and filter out empty/null entries immediately
            $paths = ($env:PSModulePath -split ';') | Where-Object { ![string]::IsNullOrWhiteSpace($_) }
            
            foreach ($path in $paths) {
                if (Test-Path $path) {
                    try {
                        # Depth based on user param
                        $manifests = Get-ChildItem $path -Filter "*.psd1" -Recurse -Depth $Depth -ErrorAction SilentlyContinue
                    } catch { continue }

                    if (!$manifests) { continue }

                    foreach ($m in $manifests) {
                        try {
                            # Read Content Safely (Single Pass)
                            $content = [System.IO.File]::ReadAllText($m.FullName)
                            
                            # Regex Extraction
                            $verMatch  = [regex]::Match($content, "ModuleVersion\s*=\s*['""]([^'""]+)['""]")
                            $authMatch = [regex]::Match($content, "Author\s*=\s*['""]([^'""]+)['""]")
                            $descMatch = [regex]::Match($content, "Description\s*=\s*['""]([^'""]+)['""]")

                            $modData = @{
                                Name        = $m.BaseName
                                Version     = if ($verMatch.Success) { $verMatch.Groups[1].Value } else { "Unknown" }
                                Author      = if ($authMatch.Success) { $authMatch.Groups[1].Value } else { "" }
                                Description = if ($descMatch.Success) { $descMatch.Groups[1].Value } else { "" }
                                Path        = $m.FullName
                            }

                            if ($DoHash) {
                                $modData["FileHash"] = Get-HashSafe -Path $m.FullName
                            }

                            $modules += $modData

                        } catch {
                            # Log read failure but don't crash thread
                            $modules += @{ Name = $m.BaseName; Error = "Access Denied" }
                        }
                    }
                }
            }
            
            # De-duplicate logic
            try {
                $unique = $modules | Group-Object Name | ForEach-Object { 
                    $_.Group | Sort-Object Version -Descending | Select-Object -First 1 
                }
                return @{ count = $unique.Count; modules = $unique }
            } catch {
                return @{ count = $modules.Count; modules = $modules; Note = "De-duplication failed" }
            }
        }
    }

    # ------------------------------------------------------------------------
    # COLLECTOR: CHOCOLATEY
    # ------------------------------------------------------------------------
    if ($TaskName -eq "Chocolatey") {
        return Invoke-SafeBlock -Name "Chocolatey" -Action {
            if (!(Get-Command choco -ErrorAction SilentlyContinue)) { return @{ installed = $false } }
            $raw = choco list --local-only --limit-output 2>&1
            $pkgs = $raw | ForEach-Object {
                $parts = $_ -split '\|'
                if ($parts.Count -ge 2) { @{ Name = $parts[0]; Ver = $parts[1] } }
            }
            return @{ count = $pkgs.Count; packages = $pkgs }
        }
    }

    # ------------------------------------------------------------------------
    # COLLECTOR: REGISTRY APPS
    # ------------------------------------------------------------------------
    if ($TaskName -eq "Registry_Apps") {
        return Invoke-SafeBlock -Name "Registry_Apps" -Action {
            $roots = @('HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*', 
                       'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*')
            
            $apps = @()
            foreach ($root in $roots) {
                if (Test-Path $root) {
# ============================================================================
# PARALLEL EXECUTION ENGINE WITH DYNAMIC PROGRESS
# ============================================================================

Write-Status "Initializing parallel collection engine..." "INIT" "Cyan"

$BaseContext = @{
    ScanDepth         = $ScanDepth
    IncludeFileHashes = $IncludeFileHashes.IsPresent
}

try {
    $threads = $env:NUMBER_OF_PROCESSORS
    $Pool = [RunspaceFactory]::CreateRunspacePool(1, $threads)
    $Pool.Open()
    $Jobs = @()

    $Tasks = @("System_Meta", "Winget", "PS_Modules", "Chocolatey", "Registry_Apps", "Dev_Runtimes", "Environment", "Windows_Feat")
    $TotalTasks = $Tasks.Count
    $CompletedTasks = 0

    Write-Status "Spawning $TotalTasks collection threads..." "SCAN" "Cyan"
    Write-Host ""

    foreach ($Task in $Tasks) {
        Write-Status "  └─ Thread: $Task" "THRD" "DarkGray"
                    $apps += Get-ItemProperty $root -ErrorAction SilentlyContinue | 
                        Where-Object { ![string]::IsNullOrWhiteSpace($_.DisplayName) } | 
                        Select-Object @{N='Name';E={Get-SafeString $_.DisplayName}}, 
                                      @{N='Version';E={Get-SafeString $_.DisplayVersion}}, 
                                      Publisher
                }
            }
            return $apps
        }
    }
    
    # ------------------------------------------------------------------------
    # COLLECTOR: DEV RUNTIMES
    # ------------------------------------------------------------------------
    if ($TaskName -eq "Dev_Runtimes") {
        return Invoke-SafeBlock -Name "Dev_Runtimes" -Action {
            $data = @{}
            if (Get-Command python -ErrorAction SilentlyContinue) { 
                $data.Python = Get-SafeString (python --version 2>&1) 
            }
            if (Get-Command node -ErrorAction SilentlyContinue) { 
                $data.Node = Get-SafeString (node --version 2>&1) 
            }
            if (Get-Command git -ErrorAction SilentlyContinue) { 
                $data.Git = Get-SafeString (git --version 2>&1) 
            }
            return $data
        }
    }

    # ------------------------------------------------------------------------
    # COLLECTOR: ENVIRONMENT
    # ------------------------------------------------------------------------
    if ($TaskName -eq "Environment") {
        return Invoke-SafeBlock -Name "Environment" -Action {
            [Environment]::GetEnvironmentVariables([EnvironmentVariableTarget]::User)
        }
    }

    # ------------------------------------------------------------------------
    # COLLECTOR: WINDOWS FEATURES
    # ------------------------------------------------------------------------
    if ($TaskName -eq "Windows_Feat") {
        return Invoke-SafeBlock -Name "Windows_Feat" -Action {
            Get-WindowsOptionalFeature -Online -ErrorAction SilentlyContinue | 
                Where-Object {$_.State -eq "Enabled"} | 
                Select-Object FeatureName
        }
    }
}

# ============================================================================
# PARALLEL ORCHESTRATION
# ============================================================================

function Invoke-IroncladScan {
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host "   TITAN IRONCLAD SCAN - INITIALIZING SAFETY WRAPPERS   " -ForegroundColor Cyan
    Write-Host "=================================================================" -ForegroundColor Cyan

    # Inject User Flags into Context
    $BaseContext = @{
        ScanDepth         = $ScanDepth
        IncludeFileHashes = $IncludeFileHashes.IsPresent
    }

    try {
        $threads = $env:NUMBER_OF_PROCESSORS
        $Pool = [RunspaceFactory]::CreateRunspacePool(1, $threads)
        $Pool.Open()
        $Jobs = @()

        $Tasks = @("System_Meta", "Winget", "PS_Modules", "Chocolatey", "Registry_Apps", "Dev_Runtimes", "Environment", "Windows_Feat")

        foreach ($Task in $Tasks) {
            Write-Host "[+] Spawning Safe Thread: $Task" -ForegroundColor DarkGray
            
            $ThreadContext = $BaseContext.Clone()
            $ThreadContext["TaskName"] = $Task

            $Pipeline = [PowerShell]::Create().AddScript($ScriptBlock_Collectors).AddArgument($ThreadContext)
            $Pipeline.RunspacePool = $Pool
            $Jobs += New-Object PSObject -Property @{
                Name     = $Task
                Pipeline = $Pipeline
                Result   = $Pipeline.BeginInvoke()
            }
        }

        Write-Host "`n[*] Processing..." -ForegroundColor Yellow
        
        # Non-Blocking Wait Loop
        while (($Jobs | Where-Object { $_.Result.IsCompleted -eq $false }).Count -gt 0) {
            Write-Host "." -NoNewline -ForegroundColor DarkGray
            Start-Sleep -Milliseconds 250
        }
        Write-Host ""

        # Result Collection with Global Error Handling
        foreach ($Job in $Jobs) {
            try {
                $Data = $Job.Pipeline.EndInvoke($Job.Result)
                
                # Check for Thread-Level Exceptions
                if ($Job.Pipeline.HadErrors) {
                    Write-Host "[!] Thread Error in $($Job.Name)" -ForegroundColor Red
                    $Job.Pipeline.Error.ReadAll() | ForEach-Object { Write-Host "    ERROR: $_" -ForegroundColor Red }
                    $script:GlobalData[$Job.Name] = @{ Error = "Thread Crashed"; Logs = $Job.Pipeline.Error.ReadAll() }
                } 
                # Check for Null Data
                elseif ($null -ne $Data) {
                    # Unwrapping Logic for Single Objects
                    if ($Data.Count -eq 1 -and $Data.GetType().Name -ne "Hashtable") { 
                        $script:GlobalData[$Job.Name] = $Data[0] 
                    } else { 
                        $script:GlobalData[$Job.Name] = $Data 
                    }
                    
                    # Check if the Data itself contains an Error key from Invoke-SafeBlock
                    if ($script:GlobalData[$Job.Name].Keys -contains "Error") {
                        Write-Host "[!] Internal Error in $($Job.Name)" -ForegroundColor Yellow
                    } else {
                        Write-Host "[OK] $($Job.Name) Data Captured" -ForegroundColor Green
                    }
                } else {
                    Write-Host "[?] $($Job.Name) returned null data (Safety Catch)" -ForegroundColor Yellow
                    $script:GlobalData[$Job.Name] = @{ Status = "No Data returned" }
                }
            } catch {
                Write-Host "[!] Critical Orchestrator Failure for $($Job.Name): $($_.Exception.Message)" -ForegroundColor Red
            } finally {
                if ($Job.Pipeline) { $Job.Pipeline.Dispose() }
            }
        }

    } catch {
        Write-Host "`n[!!!!] CATASTROPHIC FAILURE IN RUNSPACE POOL: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        if ($Pool) { 
            $Pool.Close()
            $Pool.Dispose() 
        }
    }
}

# ============================================================================
# EXECUTION & EXPORT
# ============================================================================

Invoke-IroncladScan

$ScanDuration = [math]::Round(((Get-Date) - $script:ScanStartTime).TotalSeconds, 2)

try {
    $JsonContent = $script:GlobalData | ConvertTo-Json -Depth 5 -WarningAction SilentlyContinue
    
    if ([string]::IsNullOrWhiteSpace($JsonContent) -or $JsonContent -eq "{}") {
        Write-Host "`n[!] ERROR: JSON Content is empty. Thread(s) failed." -ForegroundColor Red
    } else {
        $JsonContent | Out-File -FilePath $OutputPath -Encoding UTF8
        
        if ($ExportCSV) {
            $csvPath = $OutputPath -replace '\.json$', '.csv'
            if ($script:GlobalData.Registry_Apps) {
                $script:GlobalData.Registry_Apps | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                Write-Host "   [+] CSV Exported (Registry Apps only)" -ForegroundColor Gray
            }
        }

        Write-Host "`n-----------------------------------------------------------------" -ForegroundColor Cyan
        Write-Host "   IRONCLAD SCAN COMPLETE: $ScanDuration Seconds" -ForegroundColor Green
        Write-Host "   Output: $OutputPath" -ForegroundColor Yellow
        Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    }
} catch {
    Write-Host "`n[!] EXPORT FAILURE: $($_.Exception.Message)" -ForegroundColor Red
}
# Progress monitoring loop
Write-Host ""
Write-Status "Monitoring collection progress..." "WAIT" "Cyan"
$spinChars = @('◐', '◓', '◑', '◒')
$spinIdx = 0

while ($Jobs | Where-Object { !$_.Task.IsCompleted }) {
    $completed = ($Jobs | Where-Object { $_.Task.IsCompleted }).Count
    Show-Progress -Current $completed -Total $TotalTasks -Activity "Collecting data"
    Start-Sleep -Milliseconds 100
    $spinIdx = ($spinIdx + 1) % 4
}

Show-Progress -Current $TotalTasks -Total $TotalTasks -Activity "Collection complete"
Write-Host "`n"
Write-Status "All threads completed successfully" "OK" "Green"
Write-Host ""

# Gather results with progress
Write-Status "Assembling results..." "PROC" "Cyan"
$FinalData = @{}
$taskNum = 0
foreach ($Job in $Jobs) {
    $taskNum++
    $Result = $Job.PS.EndInvoke($Job.Task)
    $FinalData[$Job.Name] = $Result
    Show-Progress -Current $taskNum -Total $TotalTasks -Activity "Processing: $($Job.Name)"
    Start-Sleep -Milliseconds 50
}

Write-Host "`n"
Write-Status "Data assembly complete" "OK" "Green"

# Export JSON
Write-Status "Exporting to JSON..." "SAVE" "Cyan"
$FinalData | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding UTF8
Write-Status "Saved: $OutputPath" "OK" "Green"

# Optional CSV export
if ($ExportCSV) {
    Write-Status "Exporting CSV files..." "CSV" "Cyan"
    $csvBase = $OutputPath -replace '\.json$', ''
    foreach ($key in $FinalData.Keys) {
        if ($FinalData[$key] -is [Array]) {
            $csvPath = "${csvBase}_${key}.csv"
            $FinalData[$key] | Export-Csv -Path $csvPath -NoTypeInformation
            Write-Status "  └─ Exported: ${key}.csv" "OK" "Gray"
        }
    }
}

$elapsed = ((Get-Date) - $script:ScanStartTime).TotalSeconds

# Beautiful completion box
Write-Host ""
Write-Host "  ╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║              ✓ INVENTORY COMPLETE                          ║" -ForegroundColor Green  
Write-Host "  ╠════════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "  ║  Scan Duration:  $([math]::Round($elapsed, 1)) seconds                              ║" -ForegroundColor Gray
Write-Host "  ║  Tasks Completed: $TotalTasks                                          ║" -ForegroundColor Gray
Write-Host "  ║  Output Format:   JSON$(if($ExportCSV){' + CSV'}else{'     '})                                     ║" -ForegroundColor Gray
Write-Host "  ║  Scan Depth:      $ScanDepth levels                                    ║" -ForegroundColor Gray
Write-Host "  ║  File Hashing:    $IncludeFileHashes                                        ║" -ForegroundColor Gray
Write-Host "  ╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Output: $OutputPath" -ForegroundColor DarkGray
Write-Host ""

} catch {
    Write-Status "Fatal error: $($_.Exception.Message)" "ERROR" "Red"
    exit 1
} finally {
    if ($Pool) { $Pool.Close(); $Pool.Dispose() }
}
