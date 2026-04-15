# Complete Changelog - TITAN to SON OF KLEM

## Timeline Overview

### TITAN Era (v3.0 - v5.0)
**Focus:** Build comprehensive automation with manual lists
**Issues:** Process list maintenance, WSL hangs, categorization risk

### SON OF KLEM Era (v1.0 - v2.0)
**Focus:** Smart categorization, unified interface, no manual lists
**Issues:** Initially too conservative, still had WSL/cleanmgr hangs

---

## Critical Issues Across All Versions

### 1. WSL Package Installation
**Problem:** apt hangs indefinitely (11+ hours observed)
**Attempted Fixes:**
- v4.1: Added timeout with job wrapper
- v1.0: Kept WSL with "better" timeout
- v2.0: **DROPPED WSL ENTIRELY**

**Status:** UNRESOLVED - WSL is too unpredictable for automation

### 2. Windows Disk Cleanup (cleanmgr.exe)
**Problem:** Hangs waiting for UI input
**Fix:** v2.0 dropped cleanmgr.exe, manual cache cleanup only

### 3. Process Categorization
**Problem:** Balance between safety and aggression
**Evolution:**
- TITAN v4.0: Manual list of ~50 processes
- TITAN v4.1: Manual list of 200+ processes  
- TITAN v5.0: Smart categorical but conservative
- SOK v1.0: Smart categorical, still conservative (0 killable!)
- SOK v2.0: **AGGRESSIVE by default** (should show 100+ killable)

### 4. Package Manager Commands
**Scoop Commands Fixed in v2.0:**
- Wrong: `scoop update *` (not a command)
- Right: `scoop update` (update scoop), then `scoop upgrade *` (update apps)

**Chocolatey Fixed in v4.1:**
- Wrong: Job wrapper suppressed errors
- Right: Direct execution with output parsing

---

## What Actually Works

### PackageSync (TITAN v4.1 / SOK v1.0)
✓ Chocolatey - Fixed in v4.1
✓ Scoop - Works
✓ Winget - Fixed in v4.1
✓ Pip - Works with individual package updates
✓ npm - Works
✓ Cargo - Works (slow, builds from source)
✗ WSL - AVOID (infinite hangs)

### ProcessOptimizer
✓ Self-protection - Works since v4.0
✓ Smart categorization - Works in v5.0 / SOK v1.0
? Aggression level - Still tuning in SOK v2.0

### Maintenance
✓ Package updates - Works (all managers except WSL)
✓ Cache cleanup - Works (manual paths, no cleanmgr)
? Process cleanup - Needs testing in SOK v2.0
✗ Windows updates - Requires PSWindowsUpdate module
✗ cleanmgr.exe - AVOID (hangs)

---

## Recommended Approach for Fresh Start

1. **Start with TITAN v4.1 PackageSync**
   - Most battle-tested for package installation
   - Skip WSL packages manually

2. **Review TITAN v5.0 ProcessOptimizer**
   - Smart categorization logic is sound
   - Adjust aggression mode as needed

3. **Use SOK v2.0 Maintenance as template**
   - Aggressive categorization (can tune down)
   - No WSL, no cleanmgr
   - Fixed Scoop commands

4. **Manual Testing Checklist:**
   - Test process categorization with -DryRun first
   - Verify package managers individually
   - Skip Windows updates if PSWindowsUpdate issues
   - Never trust WSL automation

---

## Files You Should Focus On

**Most Stable:**
- TITAN/PackageSync/v4.1-fixes.ps1
- TITAN/ProcessOptimizer/v5.0-smart-categorical.ps1

**Most Recent:**
- SON-OF-KLEM/Maintenance/v2.0-fixed.ps1

**For Reference:**
- TITAN/ProcessOptimizer/v4.1-ultra-aggressive.ps1 (shows 200+ manual kill list)
- All VERSION-NOTES.md files (explain evolution)

---

## Known Good Configurations

### Conservative Setup
```powershell
# Process cleanup with smart categorization
.\ProcessOptimizer.ps1 -Mode Conservative -DryRun

# Package updates without WSL
.\PackageSync.ps1 -Mode Quick  # Fewer packages, faster

# Maintenance without risky operations
.\Maintenance.ps1 -Mode Quick
```

### Aggressive Setup  
```powershell
# Maximum process cleanup
.\ProcessOptimizer.ps1 -Mode Aggressive

# Full package installation
.\PackageSync.ps1 -Mode Full

# Deep maintenance
.\Maintenance.ps1 -Mode Deep
```

Always test with -DryRun first!
