# SOK RECOVERY STEPS — 27Mar2026
# Items deleted by PreSwap Phase 4 that should have been offloaded

## DELETED ITEMS (PreSwap Phase 4 bug — used Remove-Item instead of offload)
| Item | Size | Recovery |
|------|------|----------|
| C:\ProgramData\mingw64 | 719 MB | `choco install mingw` (if needed, was 122d stale) |
| C:\ProgramData\nvm | 117 MB | `choco install nvm` then `nvm install 24.14.0` |
| C:\ProgramData\Jenkins | 106 MB | `choco install jenkins` (if needed, was 122d stale) |
| C:\ProgramData\MySQL | 191 MB | Data loss if custom DBs existed. `choco install mysql`. Config was stale 122d. |
| C:\ProgramData\SquirrelMachineInstalls | 118 MB | Squirrel installer cache. Auto-regenerates on next Squirrel app update. No action. |
| C:\ProgramData\Package Cache | 4.72 GB | VS installer cache. Auto-downloads on next VS modify/repair. Operator approved this deletion. |
| C:\Program Files\weka-3-8-6\doc | 82 MB | `choco install weka` docs reinstall. Was 1522d stale. |
| C:\Program Files\Gephi-0.10.1\jre-x64 | 119 MB | Gephi bundled JRE. `choco install gephi` to restore. Was 206d stale. |
| C:\Program Files\SmartBear\SoapUI-5.8.0 | 273 MB | Old duplicate of 5.9.1. No recovery needed. |
| C:\Program Files\Erlang OTP\erts-16.1.1 | 113 MB | Old version. 16.3 is latest. No recovery needed. |
| C:\Program Files\Erlang OTP\erts-16.1.2 | 113 MB | Old version. No recovery needed. |
| C:\Program Files\Erlang OTP\erts-16.2 | 114 MB | Old version. No recovery needed. |

## IMMEDIATE RECOVERY ACTIONS
```powershell
# 1. Reinstall nvm (operator needs Node.js)
choco install nvm -y
nvm install lts
nvm use lts

# 2. Fix nvm4w junction (after nvm reinstall creates the target)
# The junction C:\nvm4w\nodejs should point to wherever nvm installed
# Check: nvm root
# Then: cmd /c "rmdir C:\nvm4w\nodejs & mklink /J C:\nvm4w\nodejs <nvm_root>\<version>"

# 3. Verify Kibana shim is neutralized (run InfraFix after hotfix v4.3.2)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-InfraFix.ps1

# 4. OneDrive UC junction — this is a REAL DIRECTORY, not an orphan junction
# Do NOT delete. It was created by OneDrive sync for UC files.
# If the sync is working after re-auth, leave it alone.
```

## AUTH RE-AUTHENTICATION NEEDED
PreSwap/Maintenance cache purge wiped session tokens for:
- OneDrive (re-authed by operator)
- Google Drive FS (re-auth via Google Drive app)
- Microsoft 365 apps (Teams, Outlook — re-login on next launch)
- Any Chromium-based app that stores tokens in AppData\Local\*\EBWebView

## PREVENTION (applied in Hotfix v4.3.2)
- OneDrive and GoogleDriveFS added to ProtectedProcesses
- PreSwap Phase 4 now offloads to E:\SOK_Offload\Deprecated instead of deleting
- Auth-bearing EBWebView paths excluded from cache purge
- PreSwap stale threshold should respect the 160d operator setting (items at 114d should NOT have been flagged)

## PRESWAP STALE LIST AUDIT
The PreSwap stale list was HARDCODED with items and ages from the SpaceAudit snapshot.
This is brittle — ages are baked in at script-write time, not computed at runtime.
PreSwap should either:
1. Read from the latest SpaceAudit report JSON, or
2. Compute DaysSinceWrite at runtime and check against $DEFAULT_STALE_HOURS (160d)
Currently it just has `@{ Name = 'ProgramData nvm (114d stale)'; Path = '...' }` with
no runtime age verification. Items below the 160d threshold got deleted.
