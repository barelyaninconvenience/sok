# SOK Carry-Over — 25 Mar 2026 05:30

## DELIVERED NOW
- SOK-Common.psm1 v4.1.0 — expanded prereq map (16 scripts, 5 optional/bidirectional deps, SOK_NESTED env var for non-interactive nesting)
- SOK-LiveScan.ps1 v1.1.0 — param comma fix, output paths to SOK\Logs\LiveScan\, Common integration, history saving
- SOK-LiveDigest.ps1 v1.1.0 — already deployed and working (15.8MB JSON + 10MB TXT output confirmed)

## DEPLOY
```
copy SOK-Common.psm1 C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1
copy SOK-LiveScan.ps1 C:\Users\shelc\Documents\Journal\Projects\scripts\SOK-LiveScan.ps1
```

## STILL NEEDED (next session — individual script rewrites)
Every script needs: Invoke-SOKPrerequisite call, ServiceOptimizer ErrorAction fixes (line 97-98), Cleanup ErrorAction fixes (line 94), DefenderOptimizer ErrorAction fix (line 48). The SOK-Upgrade.ps1 v1.1.0 already deployed handles most of these EXCEPT Archiver, Comparator, Scheduler (missed anchors). Those three need manual patches or a v1.2 upgrade script with correct anchors.

## E: DRIVE STATUS
E: showed "not found" despite user saying remounted. Inventory detected "Physical: 3 | Logical: 1". The Scoop `rmdir /s /q` also failed. Verify E: is actually mounted: `Get-CimInstance Win32_LogicalDisk` in PowerShell should show E: if it's there.

## KNOWN ISSUES (not fixed by these deliveries)
1. Scoop apps junction — needs E: confirmed mounted, then rmdir /s /q + mklink /J
2. Kibana node shim — needs E: for choco uninstall
3. nvm4w junction — C:\nvm4w\nodejs → C:\ProgramData\nvm\v24.14.0 broken
4. Inventory output path still goes to C:\Users\shelc\Documents\SOK\Inventory\ (hardcoded in script, not routed through Common)
5. Maintenance prior inventory lookup still searches C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\Inventory\ (set in script line 60)
6. Winget timeout every Thorough run (300s spinner) — consider increasing to 444s or running winget separately
