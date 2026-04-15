# SOK CARRY-OVER DOCUMENT
# Snapshot: 29Mar2026 21:00
# Sessions: 25-29Mar2026 (4 sessions, ~40 hours)
# Aligned with: SOK-MetaPrompt-v3.md

---

## SYSTEM STATE

### Drives
- **C:** 589 GB free (38.3% used) — Samsung PM9B1 1TB NVMe, healthy
- **E:** ~11 GB free (97.8% used) — JMicron PCIe581 500GB USB SSD
  - E:\SOK_Offload: 40 items (junctions active from C:)
  - E:\Backup_Archive: 4 raw extracted folders + 5 .7z files + fullscan log
  - mommaddell raw deleted (freed ~60 GB, then .7z extractions consumed it)
  - All E: contents now owned by operator (takeown /R /A completed)
- **G:** Google Drive FAT32 (~41% used) — NO TRIM, no SOK_Offload
- **D:** 4TB HDD — invalid/unreadable, TestDisk recovered 648 GB partition

### E:\Backup_Archive Contents (from screenshot 29Mar)
| Name | Type | Size | Notes |
|------|------|------|-------|
| 2020 Seagate 1 Backup | Folder | — | Extracted raw (may be incomplete from stalemate) |
| 2020 Seagate 2 Backup | Folder | — | Extracted raw (may be incomplete) |
| 2025 | Folder | — | Extracted raw (may be incomplete) |
| 13JUL2025 | Folder | — | Extracted raw (may be incomplete) |
| 2020 Seagate 1 Backup.7z | File | 75.6 GB | Compressed source |
| 2020 Seagate 2 Backup.7z | File | 130.4 GB | Compressed source |
| 2025.7z | File | 36.3 GB | Compressed source |
| 13JUL2025.7z | File | 12.3 GB | Compressed source |
| mommaddell backup CAO 06JUN2025.7z | File | 66.5 GB | Compressed source (raw already deleted) |
| fullscan855NFTS.log | File | 7.9 MB | Old scan log (moved to C:) |

### Key Software
- Chocolatey v2.7.0 — **BROKEN**: `choco upgrade git git.install --force -y` needed
- Node.js v25.7.0, Python 3.12.8, Git 2.53.0, .NET 8.0.419
- Rust: broken shim (scoop apps junction)
- 32 junctions, 10 cross-drive, 1 broken (OneDrive UC — leave alone)

---

## OUTSTANDING ITEMS (priority order)

### IMMEDIATE

| # | Item | Status |
|---|------|--------|
| 1 | **E: Backup Restructure** | SOK-BackupRestructure.ps1 delivered. Need to: re-extract .7z over existing raws (-aoa), verify completeness, delete .7z, merge with derivation tags (_a1, _a2, _b, _c, _d), consolidate _a1+_a2 → _a for non-duplicates, recompress. |
| 2 | **Fix Chocolatey** | `choco upgrade git git.install --force -y` |
| 3 | **Verify SpaceAudit v2.3.0** | 3rd fix attempt (string serialization). Look for `C:\ aggregated total: ~382M KB` |
| 4 | **D: recovery ingestion** | 648 GB from TestDisk. Split across E: (after restructure) + C:. Selective personal data preferred. |
| 5 | **Prune SOK logs** | LiveScan ~2.7 GB, LiveDigest ~1.5 GB. Offload to deprecated, not delete. |
| 6 | **Re-run failed reinstalls** | Jenkins, MySQL, Weka, Gephi, SoapUI — after choco fix |

### MEDIUM

| # | Item |
|---|------|
| 7 | Offload Squid exit 10 (ACL or service lock on C:\Squid) |
| 8 | PreSwap stale threshold: compute DaysSinceWrite at runtime vs hardcoded ages |
| 9 | Archiver output path → Get-ScriptLogDir |
| 10 | ProcessOptimizer: comment out priority/affinity manipulation (operator managing manually) |

### BACKLOG

| # | Item |
|---|------|
| B1 | Rust shim broken (scoop apps junction) |
| B2 | TITAN deprecated cleanup (~18 MB → archive to .7z) |
| B3 | Focus-window affinity boost script (set target to AboveNormal + P-cores only) |
| B4 | Chrome History Capture script |
| B5 | Fibonacci paddings + name truncation in remaining scripts |

---

## DEPLOYED SUITE (v4.3.3 — 23 scripts + 1 module)

### Confirmed Working
ProcessOptimizer, DefenderOptimizer, LiveScan, LiveDigest, Inventory, Maintenance (except TRIM guard unverified), Archiver, RebootClean, PreSwap (with bare -DryRun), Restructure, Backup, Reinstall (but choco broken), Cleanup (SilentlyContinue deployed)

### Confirmed Broken / Unverified
- SpaceAudit: 0 results (v2.3.0 fix delivered, unverified)
- Offload: Squid exit 10 unresolved; UWP fix deployed
- Maintenance TRIM: non-NTFS guard delivered, unverified
- Chocolatey: all installs fail (git.install.nupkg corruption)

---

## KEY DECISIONS THIS SESSION

| Decision | Rationale |
|----------|-----------|
| SOK reclassified Active Maintenance → Active Sprint | 40+ hours, 12 bugs, complete Common rebuild — not maintenance |
| Claude process protection via kill-list filter | 4-month TITAN-era bricking bug |
| Auth token preservation (OneDrive/Google/AAD) | Cache purge destroying session stores |
| PreSwap offload-not-delete | Phase 4 permanently deleted tools below threshold |
| SpaceAudit leaf-only + string serialization | O(files×depth) → O(files+dirs); ConcurrentBag[string] for type fidelity |
| UWP Packages skipped in Offload | Windows ACLs block robocopy /MOVE |
| E: full-disk recovery via NTFS journal deletion | takeown fails on full disk; fsutil usn deletejournal freed space |
| robocopy /MIR /B for force-delete | Single-pass ACL bypass via SeBackupPrivilege; 10x faster than takeown+icacls+rd |
| Derivation tagging for backup merge | _a1/_a2/_b/_c/_d suffix on collisions; first arrival also tagged |
| Manual priority/affinity management | Decommission automated priority/affinity in ProcessOptimizer |

---

## NEXT SESSION START SEQUENCE

```powershell
# 1. Fix choco
choco upgrade git git.install --force -y

# 2. E: backup restructure (interactive)
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-BackupRestructure.ps1 -SkipPhase1

# 3. Verify SpaceAudit
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-SpaceAudit.ps1

# 4. D: recovery (after E: has space)
# Selective robocopy of personal data directories

# 5. Re-run reinstalls
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Reinstall.ps1

# 6. Full suite validation
```
