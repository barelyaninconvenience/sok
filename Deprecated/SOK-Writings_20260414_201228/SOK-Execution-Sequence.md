# SOK EXHAUSTIVE EXECUTION SEQUENCE v4.3.3
# 28Mar2026 — All 23 scripts, optimal flags, full validation

## STEP 0: PREREQUISITES (run once)
```powershell
# Fix digital signatures
Get-ChildItem C:\Users\shelc\Documents\Journal\Projects\scripts\*.ps1 | Unblock-File
Get-ChildItem C:\Users\shelc\Documents\Journal\Projects\scripts\common\*.psm1 | Unblock-File
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Fix nvm
winget install --id CoreyButler.NVMforWindows --accept-source-agreements
# Then NEW TERMINAL:
# nvm install lts
# nvm use lts

# Deploy new files (copy from downloads to scripts dir)
# SOK-SpaceAudit.ps1 (v2.3.0 — leaf-only optimization)
# SOK-LiveDigest.ps1 (sort fix)
# SOK-Backup.ps1 (new)
# SOK-Hotfix-v433.ps1 (SpaceAudit path, TRIM guard)
```

## STEP 1: HOTFIX + INFRA
```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Hotfix-v433.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-InfraFix.ps1
```

## STEP 2: FULL SUITE VALIDATION (DryRun first where available)
```powershell
# ── Core pipeline ──
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Inventory.ps1 -ScanCaliber 3 -AllowRedundancy
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-SpaceAudit.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-ProcessOptimizer.ps1 -Mode Balanced -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-ProcessOptimizer.ps1 -Mode Balanced
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-ServiceOptimizer.ps1 -Action Report
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-DefenderOptimizer.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Maintenance.ps1 -Mode Thorough
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Offload.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Cleanup.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Cleanup.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-LiveScan.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-LiveDigest.ps1 -TopN 204661

# ── Utilities ──
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-PreSwap.ps1 -DryRun $true
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-RebootClean.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Archiver.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Restructure.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Scheduler.ps1 -Mode Standard
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Restructure-FlattenedFiles.ps1 -FlatDirectory D: -Mode MetadataRestructure -OriginalSourceRoot C: -OutputRoot C: -DryRun

# ── One-shots (verify, don't re-run) ──
# SOK-Upgrade.ps1 — already applied, no need to re-run
# Restructure-FlattenedFiles.ps1 — D: recovery tool, run when D: mounted
# SOK-Comparator.ps1 — needs two snapshots:
#   pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Comparator.ps1 `
#     -OldSnapshot <path-to-pre-cleanup-inventory.json> `
#     -NewSnapshot <path-to-post-cleanup-inventory.json>

# ── New ──
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Backup.ps1 -DryRun
```

## STEP 3: E: BACKUP RESTRUCTURING
```powershell
# 1. Verify .7z integrity
& 'C:\Program Files\7-Zip\7z.exe' t 'E:\Backup_Archive\13JUL2025.7z'
& 'C:\Program Files\7-Zip\7z.exe' t 'E:\Backup_Archive\2020 Seagate 1 Backup.7z'

# 2. If both pass, the raw C_\ tree is fully redundant
#    The .7z files ARE the restructured, compressed backup
#    No need to re-zip — they're already zipped
#    Delete the raw tree to free ~185 GB on E:
Remove-Item 'E:\Backup_Archive\C_' -Recurse -Force

# 3. What remains on E:\Backup_Archive:
#    13JUL2025.7z                       (~11.7 MB)
#    2020 Seagate 1 Backup.7z           (~70.3 GB)
#    = ~70 GB total, canonical compressed backup
```

## STEP 4: D: RECOVERY
```powershell
# Mount D: (JMicron SATA581 4TB HDD)
# DMDE already scanned 38997 items

# If D: is mountable and has content:
pwsh -NoProfile -ExecutionPolicy Bypass -File .\Restructure-FlattenedFiles.ps1 `
  -FlatDirectory 'D:\' -Mode MetadataRestructure -DryRun

# Or if DMDE recovery files are on another path:
# Copy recovered files to E:\D_Recovery\ first, then restructure
```

## OPTIMAL COMMON SEQUENCE (daily, via Scheduler)
```
TIME   SCRIPT                FLAGS
02:17  DefenderOptimizer     (no flags)
02:17  Inventory             -ScanCaliber 3
02:19  Maintenance           -Mode Quick
04:50  ProcessOptimizer      -Mode Balanced
04:51  ServiceOptimizer      -Action Auto
04:51  Offload               (no flags)
04:53  Cleanup               (no flags)
04:53  LiveScan              (no flags)
05:31  LiveDigest            -TopN 204661
05:34  [complete]
```

## WEEKLY (Sunday, manual or scheduled)
```
Maintenance      -Mode Thorough
SpaceAudit       (no flags — now ~5 min with leaf-only)
Backup           -Incremental
Archiver         (no flags)
```

## SCRIPTS READY FOR RETIREMENT REVIEW
| Script | Status | Notes |
|--------|--------|-------|
| SOK-Upgrade | RETIRE | One-shot v4.0 migration tool. All patches applied. Keep in deprecated/. |
| SOK-Hotfix-v431 | RETIRE | Applied. Keep in deprecated/. |
| SOK-Hotfix-v432 | RETIRE | Applied. Keep in deprecated/. |
| SOK-Hotfix-v433 | RETIRE AFTER RUN | Apply then deprecate. |
| SOK-InfraFix | KEEP | Useful for junction repair after drive swaps. |
| Restructure-FlattenedFiles | KEEP | D: recovery tool. Run when needed. |
