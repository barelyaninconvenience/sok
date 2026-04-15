# SOK Carry-Over Status — 25 Mar 2026 (Post-Deployment)
## Megasession 19–24 Mar → 25 Mar Deployment → Current

### Legend
- ✅ COMPLETE (verified on machine)
- 🔧 DELIVERED (needs deploy/copy)
- ⏳ QUEUED (scoped, not yet built)
- ❌ BLOCKED (dependency)
- 📋 OPERATOR ACTION

---

## SESSION RESULTS — 25 Mar 2026

**Common v4.0.0**: ✅ DEPLOYED & RUNNING. Parse error from v1.0 delivery (`$prereqName:` scope bug) was fixed. Both Inventory and Maintenance ran successfully under v4.0.0. History routing to per-script log subdirs confirmed. Config loaded from new `scripts\config\` path.

**Inventory v3.0.0**: ✅ RUNNING. 10.6s, 15 collectors, 0 errors. Detected 32 junctions, 10 broken (9 E:-target with E: unmounted + 1 nvm4w + 1 OneDrive UC). Chocolatey shows 0 packages (lib junction broken when E: offline). Known issues: `Get-Command mongod` and `Get-Command git` still use `-ErrorAction Continue` (should be `SilentlyContinue`), Kibana node shim still intercepts.

**Maintenance v3.0.0**: ✅ RUNNING. 1.4s Quick mode. 469 MB freed (System Temp 929MB was the big one). 28 junctions checked, 8 broken (all E:-target). Config loaded. History written to `SOK\Logs\Maintenance\`.

**LiveDigest v1.0.0**: ❌ TWO BUGS FOUND & FIXED.
  - Bug 1: `$script:DateFile` is module-scoped, not accessible from script scope → `Get-Date -Format $null` → produced `03/25/2026 03:31:01` with slashes/colons → Windows treated as alternate data stream path. Fix: literal `$DateFile = 'yyyyMMdd_HHmmss'` in script scope.
  - Bug 2: Property mapping wrong. LiveScan uses shorthand `"p"` (path), `"s"` (sizeKB), `"m"` (modified). LiveDigest was looking for `.Path`, `.SizeKB`, `.LastWriteTime` → 0 results despite 2.47M entries. Fix: map to `.p`, `.s`, `.m`.
  - v1.1.0 delivered this session.

---

## CRITICAL

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | SOK-Common.psm1 v4.0.0 | ✅ DEPLOYED | Parse error fixed, running on machine. Config at `scripts\config\sok-config.json`. Nesting limit: 11. |
| 2 | Scoop apps junction | ❌ BLOCKED | E: must be mounted. Choco `lib` junction also broken when E: offline → choco reports 0 packages. All 9 E:-target junctions show broken when E: unmounted. This is expected behavior, not a bug — junctions work when E: is present. |
| 3 | sok-config.json relocation | ✅ COMPLETE | `scripts\config\` created, config moved. |
| 4 | Legacy History dir | 📋 OPERATOR | Move `Documents\SOK\History\` → `SOK\Deprecated\History\` |
| 5 | SOK-LiveDigest.ps1 v1.1.0 | 🔧 DELIVERED | Fixes both datetime and property mapping bugs. Copy to `scripts\`. |

---

## PENDING — Script Updates

| # | Item | Status | Notes |
|---|------|--------|-------|
| 6 | Inventory: `mongod`/`git` ErrorAction | ⏳ QUEUED | Line 522 & 538: change `-ErrorAction Continue` to `-ErrorAction SilentlyContinue` (checking existence, not doing work) |
| 7 | Inventory: Kibana node shim | ❌ BLOCKED | `choco uninstall kibana` fails because `C:\ProgramData\chocolatey\lib` junction is broken (E: offline). Mount E:, fix junction, then uninstall. |
| 8 | Inventory: nvm4w junction | ⏳ NEW | `C:\nvm4w\nodejs → C:\ProgramData\nvm\v24.14.0` broken. Verify nvm4w installation and fix target path. |
| 9 | All scripts: interdependent web | ⏳ QUEUED | Add `Invoke-SOKPrerequisite` calls. Map defined in Common v4.0.0. |
| 10 | Maintenance: temp file locked errors | ⏳ QUEUED | Line 202 `Remove-Item` produces 30+ "used by another process" errors per run. Fix: add `-ErrorAction SilentlyContinue` specifically for temp file removal (locked files are expected, not errors). |
| 11 | ServiceOptimizer ↔ ProcessOptimizer | ⏳ QUEUED | Cross-reference via `Get-LatestLog`. |
| 12 | SystemInfo.json quarterly validation | ⏳ QUEUED | Inventory compares current state against stored metadata. |
| 13 | Restructure banner → Show-SOKBanner | ⏳ QUEUED | Minor. |
| 14 | LiveScan: integrate with Common | ⏳ QUEUED | Currently standalone (no Common import, no banner, no history). Should use Common for consistency. |

---

## CLEANUP

| # | Item | Status |
|---|------|--------|
| 15 | Stray scripts in log dirs | 📋 OPERATOR |
| 16 | fullscan.log relocation | 📋 OPERATOR |
| 17 | PackageSync → TITAN (deprecated) | ✅ CONFIRMED (per user) |

---

## SYSTEM STATE — 25 Mar 2026

| Metric | Value |
|--------|-------|
| C: Used | 59.4% (E: unmounted this session) |
| Drives | 3 physical, 1 logical (E: offline) |
| Junctions | 32 total, 10 broken (9 E:-target + nvm4w) |
| Scoop Apps Junction | WORKING when E: mounted; BROKEN when E: offline |
| Common Version | v4.0.0 ✅ DEPLOYED |
| Inventory | 10.6s, 15 collectors, 0 errors |
| Maintenance | 1.4s Quick, 469 MB freed, 0 errors |
| LiveDigest | v1.1.0 🔧 NEEDS DEPLOY |
| LiveScan data | 524 MB, 2.47M entries (full mode, 23 Mar) |
