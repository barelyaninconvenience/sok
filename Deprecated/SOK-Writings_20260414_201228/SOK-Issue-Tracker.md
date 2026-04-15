# SOK SUITE — COMPREHENSIVE ISSUE TRACKER
# 28Mar2026 — Ordered by age (oldest first)

## ═══ LEGEND ═══
# ✅ CONFIRMED WORKING  🔧 FIX DELIVERED (deploy pending)  ❌ BROKEN  ⏳ BACKLOG  🗑️ RETIRE

## ═══ SCRIPT STATUS (22 scripts + 1 module) ═══

| # | Script | Deployed | Fix Delivered | Status | Notes |
|---|--------|----------|---------------|--------|-------|
| 1 | Common | v4.3.0 (457L) | v4.3.2 (448L) | ✅ | Banner shows v4.3.3 (hotfix bumped), prereq system working |
| 2 | Inventory | v3.2.0 (702L) | — | ✅ | 16 collectors, 0 errors, Node v25.7.0 |
| 3 | SpaceAudit | v2.2.0 (654L) | v2.3.0 (707L) | 🔧 | Leaf-only + string serialization. 3rd attempt. DEPLOY + TEST |
| 4 | ProcessOptimizer | v1.2.0 (308L) | — | ✅ | Kill filter working: 3 filtered, zero Claude kills |
| 5 | ServiceOptimizer | v1.2.0 (215L) | — | ✅ | Report mode OK, 540 MB targetable |
| 6 | DefenderOptimizer | v1.2.0 (178L) | — | ✅ | 3P AV guard working, Defender active, 12 exclusions |
| 7 | Maintenance | v3.2.0 (455L) | v3.2.1 (460L) | 🔧 | TRIM non-NTFS guard added. DEPLOY |
| 8 | Offload | v2.2.0 (530L) | — | ❌ | UWP Packages exit 11 (ACL restriction). See FIX below |
| 9 | Cleanup | v1.0.0 (304L) | v1.0.1 (304L) | 🔧 | SilentlyContinue on Remove-Item. DEPLOY |
| 10 | LiveScan | v1.1.0 (172L) | — | ✅ | 1.63M items, 73s, zero errors |
| 11 | LiveDigest | v1.1.0 (277L) | v1.1.1 (277L) | 🔧 | Sort fix (LastWriteTime not Length). DEPLOY |
| 12 | Scheduler | v1.2.0 (114L) | — | ✅ | Param is -MaintenanceMode (not -Mode) |
| 13 | Archiver | v2.1.0 (199L) | — | ✅ | Source paths correct, DryRun OK |
| 14 | Comparator | v2.1.0 (255L) | — | ✅ | Needs two snapshot paths to run |
| 15 | PreSwap | v1.1.0 (403L) | — | ✅* | Works correctly when invoked with bare -DryRun (not -DryRun $true) |
| 16 | RebootClean | v1.1.0 (166L) | — | ✅ | SilentlyContinue already applied, 18 junctions OK |
| 17 | Restructure | v1.0.0 (200L) | — | ✅ | Scan OK, Backup target gone (expected) |
| 18 | Restructure-FlattenedFiles | v1.0.0 (620L) | v1.0.1 (620L) | 🔧 | Missing comma in param block. DEPLOY |
| 19 | InfraFix | — (148L) | — | ✅ | Kibana shim done, nvm skip (target gone) |
| 20 | Upgrade | v1.1.0 (284L) | — | 🗑️ | One-shot migration complete. Deprecate. |
| 21 | Backup | v1.0.0 | v1.1.0 (143L) | 🔧 | Default source fixed. DEPLOY |
| 22 | Reinstall | v1.0.0 (196L) | — | 🔧 | Delivered. DEPLOY + RUN |

## ═══ OUTSTANDING ISSUES (ordered by age) ═══

### 1. OFFLOAD UWP Packages exit 11 (since 24Mar — 5 DAYS)
**Root cause**: Offload targets `C:\Users\shelc\AppData\Local\Packages` (UWP store data).
Windows applies restrictive ACLs to UWP app directories that block robocopy /MOVE.
**Fix**: Add UWP Packages to Offload skip list. These dirs can't be moved — they're
managed by Windows and need to stay at their original path.
**Script**: SOK-Offload.ps1, target filtering section.
**Status**: Fix included below.

### 2. SPACEAUDIT 0 RESULTS (since 28Mar AM — 3 attempts)
**Root cause**: PowerShell parallel serialization strips type info from hashtables.
**Fix v2.3.0**: Uses pipe-delimited strings in ConcurrentBag[string]. Delivered.
**Diagnostic**: Look for `C:\ aggregated total: ~382000000 KB` in output.
**Status**: 🔧 Delivered, awaiting deployment + test.

### 3. MAINTENANCE TRIM G: FAT32 ERROR (since 27Mar)
**Root cause**: Hotfix pattern didn't match actual variable name ($drive not $d).
**Fix**: Direct surgery in SOK-Maintenance.ps1. Delivered.
**Status**: 🔧 Delivered, awaiting deployment.

### 4. CLEANUP CONSOLE ERROR FLOOD (since 27Mar)
**Root cause**: ErrorAction Continue on Remove-Item for locked temp files.
**Fix**: Changed to SilentlyContinue. Delivered.
**Status**: 🔧 Delivered, awaiting deployment.

### 5. REINSTALL DELETED TOOLS TO E: (since 27Mar)
**Root cause**: PreSwap Phase 4 used Remove-Item instead of offload.
**Fix**: SOK-Reinstall.ps1 — interactive choco install → offload to E: with junction.
**Items**: mingw64, Jenkins, MySQL, Weka, Gephi, SoapUI, Erlang OTP.
**Status**: 🔧 Delivered, awaiting deployment.

### 6. LIVEDIGEST SORT BUG (since 27Mar — worked around by -InputPath)
**Root cause**: Sort-Object Length picks largest file, not newest.
**Fix**: Sort-Object LastWriteTime. Delivered.
**Status**: 🔧 Delivered, awaiting deployment.

### 7. BACKUP DEFAULT SOURCE (since 28Mar)
**Root cause**: Default was Documents\Backup which was deleted.
**Fix**: Changed to Documents\Journal\Projects. Delivered.
**Status**: 🔧 Delivered, awaiting deployment.

### 8. RESTRUCTURE-FLATTENEDFILES PARSER ERROR (since 28Mar)
**Root cause**: Missing comma between [switch]$DryRun and [int]$MaxPathLength.
**Fix**: Added comma. Delivered.
**Status**: 🔧 Delivered, awaiting deployment.

## ═══ BACKLOG (not blocking, address when convenient) ═══

| # | Item | Age | Priority | Notes |
|---|------|-----|----------|-------|
| B1 | PreSwap stale threshold hardcoded | 27Mar | Medium | Should compute DaysSinceWrite at runtime vs 160d |
| B2 | Rust shim broken | 25Mar | Low | Scoop apps junction to E: — rustc.exe can't launch |
| B3 | Choco 0 packages (E: unmounted) | 27Mar | Cosmetic | chocolatey\lib junction broken when E: offline |
| B4 | Chrome History Capture | 25Mar | Low | New script triggered by Maintenance Thorough |
| B5 | Fibonacci paddings remaining scripts | 25Mar | Cosmetic | Done in SpaceAudit+ProcessOptimizer, others pending |
| B6 | Name truncation remaining scripts | 25Mar | Cosmetic | Done in Archiver (44+...) |
| B7 | Archiver output → Documents\SOK\Archives | 28Mar | Low | Should use Get-ScriptLogDir like everything else |
| B8 | E: backup restructure (matryoshka cleanup) | 28Mar | Medium | Interactive script to extract personal data, re-compress |
| B9 | D: recovery pipeline wrapper | 28Mar | Low | User handling TestDisk manually |
| B10 | ProcessOptimizer history.json.bak | 28Mar | Cosmetic | Backup created from corruption recovery — harmless |

## ═══ DEPLOYMENT CHECKLIST ═══

Deploy these files (all delivered in this or previous responses):

```powershell
# Copy each from Downloads to scripts dir, then:
Get-ChildItem .\*.ps1 | Unblock-File
Get-ChildItem .\common\*.psm1 | Unblock-File
```

| File | Replaces | Critical? |
|------|----------|-----------|
| SOK-SpaceAudit.ps1 | v2.2.0 → v2.3.0 | YES — 0 results bug |
| SOK-Maintenance.ps1 | v3.2.0 → v3.2.1 | YES — TRIM error |
| SOK-Cleanup.ps1 | v1.0.0 → v1.0.1 | YES — console flood |
| SOK-LiveDigest.ps1 | v1.1.0 → v1.1.1 | YES — wrong file picked |
| SOK-Backup.ps1 | v1.0.0 → v1.1.0 | YES — default source broken |
| Restructure-FlattenedFiles.ps1 | v1.0.0 → v1.0.1 | YES — parser error |
| SOK-Reinstall.ps1 | NEW | Run when ready |
| SOK-Offload.ps1 | pending fix below | Fixes Failed=1 |

## ═══ POST-DEPLOYMENT VALIDATION ═══

```powershell
# 1. SpaceAudit (the big one — verify "C:\ aggregated total" is ~382M KB)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-SpaceAudit.ps1

# 2. Offload (should show 0 failures after UWP skip)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Offload.ps1

# 3. Maintenance (should show "TRIM skipped: G:" not error)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Maintenance.ps1 -Mode Quick

# 4. Cleanup DryRun (no error wall)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Cleanup.ps1 -DryRun

# 5. LiveDigest (should auto-find latest scan without -InputPath)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-LiveDigest.ps1 -TopN 204661

# 6. Reinstall (interactive — review each item)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Reinstall.ps1 -DryRun
```
