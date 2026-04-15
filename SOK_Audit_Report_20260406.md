# SOK Audit Report — 2026-04-06
## Read-Only Comprehensive Audit | 30 scripts + 1 module

---

## SUMMARY

| Severity | Count |
|----------|-------|
| Critical | 6 |
| Warning | 15 |
| Info | 14 |

**DryRun:** Present on ALL scripts. No ungated destructive ops. 12 of 34 scripts have DryRun not as first param.

---

## CRITICAL (6)

**C-1: SOK-Common version mismatch** — constant is v4.5.0, description says v4.6.0
- `common/SOK-Common.psm1` lines 3-6 vs line 43

**C-2: Export-SoftwareManifest.ps1** — calls Invoke-SOKPrerequisite without Get-Command guard
- Line 64. Will crash if SOK-Common is missing.

**C-3: SOK-Maintenance.ps1** — Invoke-Expression for cache purges
- Line 227. `Invoke-Expression "$($cc.Cmd) $($cc.Args)"` — command injection vector. All other scripts use call operator `& $cmd @args`.

**C-4: SOK-BareMetal_v5.3.ps1** — Invoke-Expression on downloaded remote content
- Lines 440-441, 449. Chocolatey/Scoop bootstrappers use IEX on remote content. No hash verification. Known accepted risk but undocumented.

**C-5: SOK-Archiver.ps1 and SOK-Comparator.ps1** — default output to Documents\SOK\Archives
- Violates SOK write boundary (only SOK\Logs\ accepts writes). Triggered in fallback-only path.

**C-6: SOK-LiveScan.ps1** — default $OutJson path points to Documents\SOK\ (not Logs)
- Inconsistent fallback: $ErrorLog correctly falls back to SOK\Logs\ but $OutJson does not.

---

## TOP WARNINGS (selected)

**W-1/W-2:** Missing `#Requires -Version 7.0` on 9+ tactical scripts (Maintenance, Cleanup, SpaceAudit, InfraFix, Restructure, LiveScan, PreSwap, Archiver, BackupRestructure)

**W-3/W-4:** DryRun not first param in Maintenance, Cleanup, Restructure, InfraFix, PreSwap + others

**W-5:** SOK-ProcessOptimizer hardcoded absolute module path (no $PSScriptRoot fallback)

**W-7:** SOK-Maintenance CacheFreedKB accounting overwritten by drive-level delta (misleading metric)

**W-9:** SOK-Backup "Safe to delete source" message — dangerous UX for a backup tool

**W-11:** SOK-Comparator Get-ArchiveChunk is O(n) per chunk (reads from file start each time)

**W-12:** SOK-LiveDigest loads 525MB+ JSON into memory via ConvertFrom-Json

**W-14:** SOK-PAST default run activates BackupRestructure (destructive Phases 2/3) without explicit opt-in

---

## KEY INFO ITEMS

- SOK-FamilyPicture.ps1 is not a functional script (prose + embedded stub)
- SOK-Archiver reports sizes in MB (should be KB per standard)
- 3 orphaned PAST implementations (BlankSlate, Verbose, v2) — need disposition decision
- Get-HumanSize marked DEPRECATED but called by 12 scripts
- SOK-Cleanup missing Save-SOKHistory call
- Configure-ClaudeDesktopMCP hardcodes OAUTHLIB_INSECURE_TRANSPORT=1

---

## RECOMMENDED FIX PRIORITY

1. **C-1:** Bump SOK-Common version to 4.6.0 (or update description) — 1 line fix
2. **C-2:** Add Get-Command guard to Export-SoftwareManifest — 3 line fix
3. **C-3:** Replace Invoke-Expression with call operator in Maintenance — 1 line fix
4. **W-1/W-2:** Add `#Requires -Version 7.0` to all tactical scripts — batch find/replace
5. **C-5/C-6:** Fix fallback output paths to use SOK\Logs\ — 4 files, ~6 lines each
6. **W-3/W-4:** Reorder params to put DryRun first — 12 files, non-breaking

(Full audit report with all 35 findings, DryRun compliance matrix, #Requires compliance matrix, security concerns, and performance issues available in agent output)
