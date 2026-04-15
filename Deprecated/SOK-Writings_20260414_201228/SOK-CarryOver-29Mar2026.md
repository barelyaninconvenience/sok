# SOK CARRY-OVER DOCUMENT
# Snapshot: 29Mar2026 12:30
# Sessions: 25-29Mar2026 (4 sessions, ~40 hours cumulative)
# Transcripts: /mnt/transcripts/journal.txt (3 entries)

---

## SYSTEM STATE

### Drives
- C: 589 GB free (38.3% used) — Samsung PM9B1 1TB NVMe, healthy, Wear=0%
- E: ~0 GB free → recovering via ForceDelete. mommaddell raw deleted via fsutil usn + rd. Remaining raws: 2020 Seagate 1, 2020 Seagate 2, 2025, 13JUL2025. All E: now owned (takeown /R /A completed). SOK-BackupRestructure.ps1 delivered to handle delete→extract→merge pipeline.
  - E:\SOK_Offload: 40 items (junctions active)
  - E:\Backup_Archive: 4 raw folders + corresponding .7z files + fullscan log (moved to C:)
- G: Google Drive FAT32 (~41% used) — NO TRIM, no SOK_Offload
- D: 4TB HDD — invalid/unreadable, TestDisk recovered 648 GB partition

### Junctions
- 32 total, 10 cross-drive to E:, 1 broken (OneDrive UC — real directory, leave alone)
- .nuget\packages keeps detaching — RebootClean auto-repairs

### Key Software
- Node.js: v25.7.0 (nvm4w installed via winget)
- Python: 3.12.8 (136 pip packages)
- Git: 2.53.0.windows.2
- .NET: 8.0.419
- Chocolatey: v2.7.0 — **BROKEN**: git.install.nupkg corrupted, blocks all installs
  - Fix: `choco upgrade git git.install --force -y`
- Scoop: v0.5.3 — apps junction to E: (0 visible when E: was offline)
- Rust: broken shim (scoop apps junction)
- Docker: 0 images, 0 containers (4 GB installed, offload candidate)
- 3P Security: Avast/AVG uninstalled by operator, remnants may persist (Remove-3PSecurity.ps1 delivered)

---

## OUTSTANDING ITEMS (ordered by priority)

### IMMEDIATE (blocking)

| # | Item | Age | Notes |
|---|------|-----|-------|
| 1 | **E: Backup Restructure** | 29Mar | Run SOK-BackupRestructure.ps1: delete raws → extract .7z → merge with derivation tags. mommaddell already deleted. |
| 2 | **Fix Chocolatey** | 29Mar | `choco upgrade git git.install --force -y` to resolve nupkg corruption |
| 3 | **Verify SpaceAudit v2.3.0** | 28Mar | String serialization fix (attempt 3). Look for `C:\ aggregated total: ~382M KB`. |
| 4 | **D: recovery ingestion** | 29Mar | TestDisk found 648 GB. After E: restructure, split across E: + C:. Personal data selective recovery preferred |
| 5 | **Prune SOK logs** | 29Mar | LiveScan JSONs: ~2.7 GB. LiveDigest pairs: ~1.5 GB. Offload old logs to E:\SOK_Offload\Deprecated, don't delete |
| 6 | **Re-run failed reinstalls** | 29Mar | Jenkins, MySQL, Weka, Gephi, SoapUI all failed due to choco corruption. After choco fix. |

### MEDIUM (functional but needs attention)

| # | Item | Notes |
|---|------|-------|
| 7 | Offload Squid exit 10 | C:\Squid (23 MB) — robocopy fails, possibly ACL or Squid service lock. Stop Squid service first? |
| 8 | PreSwap stale threshold hardcoded | Ages baked in at write time. Should compute DaysSinceWrite at runtime vs 160d |
| 9 | E: backup restructuring | Extract personal data from matryoshka, compress smaller, interactive/user-decision, no auto-delete |
| 10 | Archiver output path | Still writes to Documents\SOK\Archives — should use Get-ScriptLogDir |
| 11 | Reinstall failed items | choco installed 0/0 for Jenkins, MySQL, Weka, Gephi, SoapUI due to git.install corruption. Re-run after choco fix |

### BACKLOG (cosmetic / low priority)

| # | Item | Notes |
|---|------|-------|
| B1 | Rust shim broken | Scoop apps junction to E: — rustc.exe can't launch |
| B2 | Chrome History Capture | New script triggered by Maintenance Thorough |
| B3 | Fibonacci paddings remaining scripts | Done in SpaceAudit + ProcessOptimizer |
| B4 | Name truncation remaining scripts | Done in Archiver (44+...) |
| B5 | TITAN deprecated cleanup | 170+ files, ~18 MB. Archive to .7z, offload |
| B6 | Upgrade.ps1 retirement | One-shot v4.0 migration. Move to Deprecated/ |
| B7 | SpaceAudit output still in Documents\SOK\Audit | v2.3.0 has fix but old files remain |

---

## CONFIRMED WORKING (from latest logs 28Mar2026)

| Script | Evidence |
|--------|----------|
| ProcessOptimizer | Filtered 3 protected, 30 terminated, 0 failed. Zero Claude kills. |
| DefenderOptimizer | Defender active, 12 exclusions, defs v1.447.51.0, RealTimeProtection=True |
| Maintenance | 1.6 GB freed, 28 junctions 0 broken, 3 drives scanned, TRIM G: still erroring (fix delivered) |
| LiveScan | 1.637M items, 76s, zero errors, 293 MB JSON |
| LiveDigest | Auto-found newest file (sort fix deployed), 61.7s, 204661 entries |
| Inventory | 16 collectors, 0 errors, 3 drives, Node v25.7.0 confirmed |
| Archiver | DryRun OK, 423 files (5.1 GB), correct source paths |
| RebootClean | 18 junctions OK + 1 fixed, temp cleanup clean |
| PreSwap | DryRun OK (with bare -DryRun flag), Phase 4 offload-not-delete confirmed |
| Restructure | Backup target gone (expected), Downloads clean |
| Backup | DryRun OK, 701 files, 5.6 GB from Journal\Projects |
| Reinstall | Ran but choco failures due to git.install corruption |
| Cleanup | DryRun clean. Live run: error walls suppressed (SilentlyContinue deployed) |

## CONFIRMED BROKEN

| Script | Issue | Fix Status |
|--------|-------|------------|
| SpaceAudit | 0 results across 3+ runs | v2.3.0 delivered (string serialization), unverified |
| Offload | Failed=1 (UWP exit 11) + Squid exit 10 | UWP fix delivered, Squid unresolved |
| Maintenance | TRIM G: FAT32 error | Fix delivered, unverified |
| Chocolatey | All installs fail (git.install.nupkg corruption) | Manual fix needed |

---

## KEY DECISIONS MADE THIS SESSION

| Decision | Rationale |
|----------|-----------|
| Claude kill protection via kill-list filter | ProcessOptimizer was terminating claude.exe since Dec 2025 (TITAN era) |
| Auth token preservation (OneDrive/Google/AAD) | Cache purge destroying session stores caused Microsoft-wide re-auth |
| PreSwap offload-not-delete | Phase 4 permanently deleted tools below 160d stale threshold |
| Backup deleted from C: | 267 GB recovered. Verified on E: via robocopy (513K files, 0 failures) + .7z integrity |
| 3P security tools removed | Avast/AVG causing Defender 0x800106ba + temp file locks + `_avast_`/`_avg_` remnants |
| UWP Packages skipped in Offload | Windows ACLs block robocopy /MOVE on AppData\Local\Packages |
| SpaceAudit leaf-only sizing | Old recursive approach: O(files × depth) = 4880s. New: O(files + dirs), target <500s |
| LiveDigest sort by date not size | Larger pre-cleanup scans always won over newer post-cleanup scans |
| Logs should be offloaded not deleted | Operator preference: deprecate-never-delete applies to logs too |
| SOK-Common.psm1 was v2.0.0 until 28Mar | Never replaced from TITAN era. Full v4.3.2 rebuild deployed. |

---

## FILES DELIVERED THIS SESSION (for re-download if needed)

| File | Version | Lines | Key Change |
|------|---------|-------|------------|
| SOK-Common.psm1 | 4.3.2 | 448 | Complete rebuild: prereq system, Format-SOKAge, expanded ProtectedProcesses |
| SOK-ProcessOptimizer.ps1 | 1.2.0 | 308 | Kill-list filter before termination loop |
| SOK-SpaceAudit.ps1 | 2.3.0 | 691 | Leaf-only + bottom-up aggregation, string serialization |
| SOK-Maintenance.ps1 | 3.2.1 | 460 | TRIM non-NTFS guard |
| SOK-Offload.ps1 | 2.2.1 | 532 | UWP Packages commented out |
| SOK-Cleanup.ps1 | 1.0.1 | 304 | SilentlyContinue on Remove-Item |
| SOK-LiveDigest.ps1 | 1.1.1 | 277 | Sort LastWriteTime not Length |
| SOK-Backup.ps1 | 1.1.0 | 143 | Default source → Journal\Projects |
| Restructure-FlattenedFiles.ps1 | 1.0.1 | 620 | Missing comma in param block |
| SOK-Reinstall.ps1 | 1.0.0 | 196 | Interactive choco install → offload to E: |
| Remove-3PSecurity.ps1 | 1.0.0 | 167 | Services, processes, files, tasks, registry |
| SOK-Hotfix-v434.ps1 | — | 86 | TRIM guard, Cleanup noise, LiveDigest sort, Backup source, FlattenedFiles comma |
| SOK-ForceDelete.ps1 | 2.0 | 180 | Three strategies: Fast (robocopy /MIR /B), Parallel (concurrent takeown+delete), Nuclear (.NET) |
| SOK-BackupRestructure.ps1 | 1.0 | 398 | Comprehensive: delete raws → extract .7z in-place → merge with derivation tags |
| SOK-Execution-Sequence.md | — | 127 | All scripts with correct flags |
| SOK-Issue-Tracker.md | — | 137 | Every script status + outstanding items |
| SOK-Corrected-Invocations.md | — | 68 | Switch param bugs, correct flag names |
| Space-Recovery-Plan.md | — | 82 | Options for fitting 648 GB D: recovery |
| Recovery-Guide.md | — | 129 | D: pipeline + E: restructuring steps |

---

## SCHEDULE (deployed in Scheduler)

```
02:17  DefenderOptimizer
02:17  Inventory -ScanCaliber 3
02:19  Maintenance -Mode Quick (or -MaintenanceMode Quick)
04:50  ProcessOptimizer -Mode Balanced
04:51  ServiceOptimizer -Action Auto
04:51  Offload
04:53  Cleanup
04:53  LiveScan
05:31  LiveDigest -TopN 204661
05:34  [complete]
```

Weekly (Sunday): Maintenance -Mode Thorough, SpaceAudit, Backup -Incremental, Archiver
Monthly: SpaceAudit -MinSizeKB 21138, Restructure, Comparator

---

## NEXT SESSION START SEQUENCE

```powershell
# 1. Fix choco
choco upgrade git git.install --force -y

# 2. Verify SpaceAudit
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-SpaceAudit.ps1
# Must show "C:\ aggregated total: ~382000000 KB" and >0 entries above threshold

# 3. Assess E:\Backup_Archive
Get-ChildItem 'E:\Backup_Archive' -Recurse -Depth 2 | Select-Object FullName, Length, PSIsContainer | Format-Table -AutoSize

# 4. Delete raw tree if .7z covers it
# Remove-Item 'E:\Backup_Archive\<raw_tree_name>' -Recurse -Force

# 5. D: recovery to E: then C:
# (After TestDisk, once D: is readable or files extracted)

# 6. Re-run failed reinstalls
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Reinstall.ps1

# 7. Full suite validation
# (use invocations from meta-prompt)
```
