# SON OF KLEM System Automation Suite

**Version 1.0** - Property-Based Smart Automation

---

## Overview

SON OF KLEM is a comprehensive Windows system automation suite featuring:

- **Smart Categorical Processing** - No manual process lists, uses Windows API properties
- **Self-Protected** - Won't terminate its own execution context
- **Unified Interface** - Consistent flags across all scripts
- **Multi-Manager Support** - 11 package managers with intelligent timeout protection
- **No Sacred Cows** - Aggressive optimization with explicit protections only

---

## The Suite

### 1. **SON-OF-KLEM-Maintenance.ps1**
Comprehensive system maintenance script.

**Features:**
- Smart process cleanup (property-based categorization)
- 11 package managers (always updates - no skip flag)
- Intelligent cache cleanup
- Windows updates
- System optimization
- Service tuning

**Usage:**
```powershell
# Quick maintenance (cleanup + packages)
.\SON-OF-KLEM-Maintenance.ps1 -Mode Quick

# Standard (+ Windows updates) [DEFAULT]
.\SON-OF-KLEM-Maintenance.ps1

# Deep (+ optimization + services)
.\SON-OF-KLEM-Maintenance.ps1 -Mode Deep

# Preview without executing
.\SON-OF-KLEM-Maintenance.ps1 -DryRun
```

**Package Managers Updated:**
- Chocolatey
- Scoop
- Winget
- Pip
- npm
- Cargo (if cargo-update installed)
- RubyGems
- Composer
- WSL Ubuntu-24.04

---

### 2. **SON-OF-KLEM-ProcessOptimizer.ps1**
Smart process termination based on Windows properties.

**Features:**
- Property-based categorization (no manual lists)
- Imports decisions from Maintenance script
- Self-protected execution
- Ignores active windows (no special treatment)

**Protection Levels:**
- **Conservative** - Kill only telemetry, updaters, crash reporters
- **Balanced** - + Cloud sync, AppData background, high CPU [DEFAULT]
- **Aggressive** - Kill everything except explicitly protected

**Explicit Protections:**
1. Script execution (PowerShell/Terminal running the script)
2. Windows Core (Session 0: System, csrss, lsass, dwm, etc.)
3. Security software (Defender, antivirus)
4. Audio/Video drivers (Realtek, NVIDIA, AMD)
5. Windows Shell (explorer, sihost)

**Usage:**
```powershell
# Balanced optimization
.\SON-OF-KLEM-ProcessOptimizer.ps1

# Conservative (safe)
.\SON-OF-KLEM-ProcessOptimizer.ps1 -Mode Conservative

# Aggressive (maximum cleanup)
.\SON-OF-KLEM-ProcessOptimizer.ps1 -Mode Aggressive

# Preview without killing
.\SON-OF-KLEM-ProcessOptimizer.ps1 -DryRun
```

---

### 3. **SON-OF-KLEM-PackageSync.ps1**
Exhaustive package installation across 7 package managers.

**Features:**
- Hard timeout protection (no 15-hour hangs!)
- Fixed Chocolatey silent failures
- Fixed WSL infinite hangs
- Fixed Winget detection issues
- Research-based package rankings

**Package Counts by Mode:**
- **Quick** - 10 packages per manager (fast validation)
- **Standard** - 25 packages per manager [DEFAULT]
- **Full** - 50+ packages per manager (comprehensive)

**Supported Managers:**
- Chocolatey (Windows apps)
- Scoop (CLI tools)
- Winget (Microsoft Store)
- Pip (Python packages)
- npm (Node.js global)
- Cargo (Rust crates - builds from source)
- WSL/apt (Ubuntu 24.04)

**Usage:**
```powershell
# Standard install
.\SON-OF-KLEM-PackageSync.ps1

# Quick validation
.\SON-OF-KLEM-PackageSync.ps1 -Mode Quick

# Full installation
.\SON-OF-KLEM-PackageSync.ps1 -Mode Full

# Preview packages
.\SON-OF-KLEM-PackageSync.ps1 -DryRun

# Custom timeout (default 60s, Cargo uses 600s)
.\SON-OF-KLEM-PackageSync.ps1 -TimeoutSeconds 120
```

---

## Unified Flag System

All scripts use consistent flags:

| Flag | Values | Description |
|------|--------|-------------|
| `-Mode` | Quick/Standard/Deep (Maintenance)<br>Conservative/Balanced/Aggressive (Optimizer)<br>Quick/Standard/Full (PackageSync) | Operation intensity |
| `-DryRun` | Switch | Preview without executing |

**NO OTHER FLAGS** - Simplified for clarity and consistency.

---

## Smart Categorization

Instead of maintaining manual process lists (200+ names), SON OF KLEM uses **Windows API properties**:

### Property Detection
```powershell
# Session ID (0 = system, 1+ = user)
$sessionId = $Process.SessionId

# Executable path
$path = $wmiProc.ExecutablePath

# Company/Publisher
$company = $Process.Company

# Window presence
$hasWindow = $Process.MainWindowHandle -ne 0

# CPU usage
$cpu = $Process.CPU
```

### Categorization Logic
- **Session 0 + critical name** → WindowsCore (never kill)
- **Microsoft + Defender** → Security (never kill)
- **Realtek/NVIDIA/AMD** → AudioVideo (never kill)
- **\*Telemetry\*** → Telemetry (killable)
- **\*Update\* + non-Microsoft** → Updater (killable)
- **AppData + no window** → AppDataBackground (killable)
- **High CPU + no window** → HighCPUBackground (killable)

**Benefits:**
- No BSOD risk from missing critical processes
- Automatically adapts to new Windows versions
- No manual list maintenance

---

## Integration

The scripts work together:

```
1. Run Maintenance → Creates maintenance-decisions.json
2. Run ProcessOptimizer → Imports decisions from Maintenance
3. PackageSync → Standalone, can run anytime
```

**Recommended Order:**
1. **SON-OF-KLEM-PackageSync.ps1** (install tools first)
2. **SON-OF-KLEM-Maintenance.ps1** (comprehensive cleanup)
3. **SON-OF-KLEM-ProcessOptimizer.ps1** (targeted optimization)

---

## Safety Features

### Self-Protection
All scripts detect their execution context:
```powershell
$script:MyPID = $PID
$script:MyParentPID = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID").ParentProcessId
```

Won't kill:
- PowerShell executing the script
- Windows Terminal hosting the session
- Parent process tree

### Timeout Protection
PackageSync uses hard timeouts:
- **60 seconds** per package (default)
- **600 seconds** for Cargo (builds from source)
- Job-based termination (force-kills hung processes)

### Conservative Defaults
- **Maintenance**: Standard mode (Windows updates included)
- **ProcessOptimizer**: Balanced mode (reasonable aggression)
- **PackageSync**: Standard mode (25 packages per manager)

---

## File Locations

### Configuration
```
%APPDATA%\SON-OF-KLEM\
├── maintenance-decisions.json    # Process decisions for Optimizer
└── Logs\                         # Future log storage
```

### Scripts
```
C:\Users\<user>\Downloads\        # Or your preferred location
├── SON-OF-KLEM-Maintenance.ps1
├── SON-OF-KLEM-ProcessOptimizer.ps1
└── SON-OF-KLEM-PackageSync.ps1
```

---

## Troubleshooting

### "Script won't run"
```powershell
# Unblock downloaded scripts
Unblock-File -Path .\SON-OF-KLEM-*.ps1

# Or run as admin
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Package manager not found"
Scripts skip missing package managers gracefully.

Install missing managers:
```powershell
# Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Scoop
iwr -useb get.scoop.sh | iex

# Winget (included in Windows 11, App Installer on Windows 10)
```

### "WSL hangs during PackageSync"
Hard timeout protection prevents infinite hangs. If a package consistently times out:
```powershell
# Increase timeout
.\SON-OF-KLEM-PackageSync.ps1 -TimeoutSeconds 120

# Or skip WSL by using Quick mode (fewer packages)
.\SON-OF-KLEM-PackageSync.ps1 -Mode Quick
```

---

## Version History

### v1.0 (2026-02-03)
- Initial release
- Smart categorical processing
- 11 package managers
- Unified flag system
- Self-protection
- Timeout protection
- No emojis, ASCII art only

---

## Philosophy

**SON OF KLEM** follows these principles:

1. **Property over Names** - Categorize by what a process IS, not what it's called
2. **Explicit over Implicit** - Only protect what's explicitly identified as critical
3. **Aggressive by Choice** - Default to reasonable, offer maximum on request
4. **Self-Aware** - Scripts protect their own execution
5. **User Control** - Clear modes, no hidden behaviors

**No Sacred Cows** - Active windows, browsers, dev tools are all fair game unless you're literally running the script in that terminal.

---

## Credits

**Project:** SON OF KLEM System Automation Suite  
**Version:** 1.0  
**Date:** February 2026  
**Purpose:** Maximum system optimization with minimum BSOD risk

---

## License

Use freely, modify as needed, no warranty provided.
