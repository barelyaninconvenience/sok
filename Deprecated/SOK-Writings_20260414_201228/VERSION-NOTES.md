# SON OF KLEM Version History

## What Changed from TITAN?

1. **Unified Flags:** All scripts use same parameters
   - `-Mode` (Quick/Standard/Deep OR Conservative/Balanced/Aggressive)
   - `-DryRun` (preview only)
   - NO complex flag combinations

2. **Packages Always Update:** Removed skip flags

3. **No Active Window Protection:** Ignores foreground apps except:
   - Script execution context
   - Core Windows processes
   - Security software
   - Audio/video drivers

4. **Rebranding:** SON OF KLEM throughout

5. **ASCII Art:** Large letter headers (attempted KaiserzeitGotisch style)

6. **No Emojis:** Replaced with ASCII symbols [*] [+] [!] [-] [.]

## PackageSync v1.0
**File:** PackageSync/v1.0.ps1

- 7 package managers (dropped vcpkg, Conan from TITAN)
- Hard timeout protection
- Fixed Chocolatey, Winget, WSL issues from TITAN
- Modes: Quick/Standard/Full (10/25/50 packages)

## ProcessOptimizer v1.0
**File:** ProcessOptimizer/v1.0.ps1

- Smart categorical (from TITAN v5.0)
- Unified modes: Conservative/Balanced/Aggressive
- NO active window special treatment
- Imports maintenance decisions

## Maintenance v1.0
**File:** Maintenance/v1.0.ps1

- 11 package managers (added back WSL)
- Smart process cleanup
- Unified modes: Quick/Standard/Deep
- Packages ALWAYS update (no skip flag)

**Issues:**
- 0 killable / 230 protected (too conservative)
- WSL hung for 11 hours
- cleanmgr.exe hung

## Maintenance v2.0 - FIXED
**File:** Maintenance/v2.0-fixed.ps1

**Fixes:**
- AGGRESSIVE categorization by default (flipped logic)
- DROPPED WSL entirely (too unpredictable)
- DROPPED cleanmgr.exe (hangs)
- Fixed Scoop commands (upgrade not update)
- Should now show 100+ killable processes

**Key Change:**
Unknown non-Session 0 processes are now KILLABLE by default
