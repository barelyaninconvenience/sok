# SOK Carry-Over Status — 25 Mar 2026 (Post-Upgrade)

### Legend: ✅ COMPLETE | 🔧 DELIVERED | ⏳ QUEUED | ❌ BLOCKED | 📋 OPERATOR

---

## THIS SESSION

| Item | Status |
|------|--------|
| Common v4.0.0 parse fix + deploy | ✅ |
| LiveDigest v1.1.0 (datetime + property mapping fixes) | 🔧 DEPLOY |
| SOK-Upgrade.ps1 (bulk patcher for all 14 scripts) | 🔧 DEPLOY |
| Inventory + Maintenance confirmed running under v4.0.0 | ✅ |
| LiveDigest confirmed running (2.47M entries, 94.8s, 31MB output) | ✅ |
| Project Portfolio v2 (profile, assessment, risks, categories) | ✅ |
| sok-config.json relocation to scripts\config\ | ✅ |

## DEPLOY NOW

```
1. Copy SOK-LiveDigest.ps1 to scripts\
2. Copy SOK-Upgrade.ps1 to scripts\
3. Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Upgrade.ps1 -DryRun
4. Review output. If clean:
5. Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Upgrade.ps1
6. Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Inventory.ps1 -ScanDepth 3
7. Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Maintenance.ps1 -Mode Quick
```

## REMAINING

| # | Item | Status | Notes |
|---|------|--------|-------|
| 1 | Scoop/Choco junction fix | ❌ BLOCKED | E: must be mounted. All E:-target junctions expected broken when offline. |
| 2 | Kibana node shim | ❌ BLOCKED | choco uninstall fails without E: (lib junction). Mount E: first. |
| 3 | nvm4w junction | ⏳ | `C:\nvm4w\nodejs → C:\ProgramData\nvm\v24.14.0` — verify nvm4w install |
| 4 | Legacy History dir cleanup | 📋 | Move `SOK\History\` → `SOK\Deprecated\History\` |
| 5 | LiveScan: missing comma line 19 param block | ⏳ | `$MinSizeKB` and `$ExcludeNoisyDirs` may lack separator — verify on disk |
| 6 | SystemInfo.json quarterly validation in Inventory | ⏳ | Next build cycle |
| 7 | Thorough mode web discovery | ⏳ DEFERRED | Significant feature, not this sprint |
| 8 | DMDE recovery automation | ⏳ DEFERRED | E: required |

## SYSTEM STATE

C: 59.4% used, E: unmounted, 32 junctions (10 broken = 9 E:-target + nvm4w), Common v4.0.0 deployed, LiveDigest v1.1.0 pending deploy, SOK-Upgrade pending deploy.
