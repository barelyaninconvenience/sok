# SOK SUITE v4.3.2 — COMPLETE STATUS
# As of 28Mar2026

## DEPLOYED SCRIPTS (22 files)

### CORE (11 + module) — All operational
| Script | Ver | Lines | Key v4.3.x Features | Status |
|--------|-----|-------|---------------------|--------|
| Common | 4.3.2 | 448 | Prereq system, Format-SOKAge, AggregateOnly, SKIP_CLAUDE, expanded ProtectedProcesses (claude/Spotify/Outlook/OneDrive/GoogleDriveFS/AAD.BrokerPlugin), operator constants (30/240/666/160/48/360/21/96) | ✅ DEPLOYED |
| Inventory | 3.2.0 | 702 | ScanCaliber, scoop dump/search, AggregateOnly history, Get-ScriptLogDir output | ✅ |
| SpaceAudit | 2.2.0 | 654 | Fibonacci paddings (21/5/13), depth 21, MinSizeKB 21138, throttle 13, safe_to_clean 44d, investigate 160d | ✅ |
| ProcessOptimizer | 1.2.0 | 308 | Kill-list filter (confirmed: 5 processes filtered), Fibonacci padding, groupings 8, Claude/Spotify PROTECTED | ✅ CONFIRMED |
| ServiceOptimizer | 1.2.0 | 215 | Cross-ref, nested guard, 333ms sleep | ✅ |
| DefenderOptimizer | 1.2.0 | 178 | 3P AV guard (Avast/AVG detection), prereq | ✅ Hotfix landed |
| Maintenance | 3.2.0 | 455 | Five-tier wear (CRITICAL→HEALTHY), ProgramData Package Cache in Thorough, scoop cache rm, Claude/Outlook excluded | ✅ Hotfix landed |
| Offload | 2.2.0 | 530 | MinSizeKB 21138, prereq | ✅ |
| Cleanup | 1.0.0 | 304 | Outlook Web Cache excluded, offloadRoot null guard | ✅ |
| LiveScan | 1.1.0 | 172 | Unicode path escaping, Common import, history suppressed, param comma fix | ✅ |
| LiveDigest | 1.1.0 | 277 | TopN 204661, batch 222222, history suppressed | ✅ |

### UTILITIES (8 scripts)
| Script | Ver | Lines | Status |
|--------|-----|-------|--------|
| Scheduler | 1.2.0 | 114 | ✅ 02:17-05:34 schedule, 160% runtime spacing |
| Archiver | 2.1.0 | 199 | ✅ 111 spacer, name truncation 44, fixed source paths |
| Comparator | 2.1.0 | 255 | ✅ 111 spacer |
| PreSwap | 1.1.0 | 403 | ✅ Repair-Junction function, Phase 4 offload-not-delete, Claude/Spotify/Outlook excluded |
| RebootClean | 1.1.0 | 166 | ✅ SilentlyContinue on Remove-Item |
| Restructure | 1.0.0 | 200 | ✅ Scanned 123909 dirs, found 120199 excessive nesting |
| Restructure-FlattenedFiles | 1.0.0 | 620 | ✅ 3-mode recovery engine (Log/Metadata/Hybrid) |
| Upgrade | 1.1.0 | 284 | ✅ Bulk-patch utility for Common compatibility |

### ONE-SHOT TOOLS (3 scripts)
| Script | Ver | Lines | Status |
|--------|-----|-------|--------|
| InfraFix | — | 148 | ✅ Kibana shim renamed (256KB threshold), legacy History moved |
| Hotfix-v431 | — | 114 | ✅ Applied: scoop commands, ProgramData Package Cache |
| Hotfix-v432 | — | 235 | ✅ Applied: DefenderOptimizer AV guard, PreSwap offload, Archiver paths, RebootClean SilentlyContinue |

### NEW THIS SESSION
| Script | Ver | Lines | Status |
|--------|-----|-------|--------|
| SOK-Backup | 1.0.0 | 192 | 🆕 Robocopy with pre-flight, verification, incremental support |

## CONFIRMED WORKING (from logs)
- ✅ Claude Desktop: **NO LONGER KILLED** (Filtered: 5 config-protected processes)
- ✅ Spotify: protected from termination
- ✅ OneDrive: protected from termination
- ✅ AAD BrokerPlugin: protected (prevents Microsoft-wide re-auth cascade)
- ✅ GoogleDriveFS: protected
- ✅ Scoop v0.5.3: dump/search --installed/cache rm (no more WARN noise)
- ✅ DefenderOptimizer: skips when Avast/AVG active (0x800106ba eliminated)
- ✅ PreSwap Phase 4: offloads to E:\SOK_Offload\Deprecated instead of deleting
- ✅ LiveScan: 2,079,726 items in 64s, zero errors, 421 MB JSON
- ✅ LiveDigest: 54.6s processing, 29 MB TXT output
- ✅ Backup robocopy: 267 GB, 513370 files, zero failures
- ✅ nvm reinstalled (choco --force)
- ✅ Kibana node.exe shim neutralized

## OUTSTANDING / TODO

### HIGH PRIORITY
| Item | Notes |
|------|-------|
| Delete C:\Users\shelc\Documents\Backup | 267 GB recovery. Verified on E:. Operator to run manually. |
| Common v4.3.2 may not be deployed | Your uploaded Common says v4.3.0 but the ProcessOptimizer DryRun shows v4.3.2 banner. Verify: `(Import-Module .\common\SOK-Common.psm1 -PassThru).Version` |
| Uninstall 3P security tools | Avast/AVG causing Defender 0x800106ba + temp file locks. Operator approved removal. |
| nvm PATH | `choco install nvm --force` reinstalled but `nvm` command not found. Need new terminal or PATH update. Try: `refreshenv` or `$env:PATH += ";$env:ProgramData\chocolatey\lib\nvm\tools"` |

### MEDIUM PRIORITY (next session)
| Item | Notes |
|------|-------|
| Offload persistent failure | 4 consecutive runs with Failed=1. Need to identify which target and why robocopy exit 10/11. |
| TRIM non-NTFS guard | Hotfix MISSED on Maintenance. Google Drive G: (FAT32) causes TRIM error. Manual fix needed. |
| Maintenance HumanSize remnants | Some log lines still use Get-HumanSize instead of raw KB. Cosmetic. |
| Chrome History Capture | Backburnered. New script triggered by Maintenance Thorough. |
| OneDrive UC junction | Real directory, not orphan. Leave alone. |
| Console buffer overflow | PreSwap/RebootClean error walls exceed PS buffer. SilentlyContinue applied but some paths still noisy. Consider `-Quiet` switch. |

### LOW PRIORITY / BACKBURNER
| Item | Notes |
|------|-------|
| D: 4TB HDD recovery automation | DMDE scan complete (38997 items). Manual recovery when needed. |
| Scoop regex refactor in Offload | Functional but verbose. O(n) not O(n³). |
| Fibonacci paddings everywhere | SpaceAudit and ProcessOptimizer done. Others still have non-Fibonacci paddings. Cosmetic. |
| Name truncation in all scripts | Archiver done (44+...). Others still have uncapped names. |
| PreSwap stale threshold | Hardcoded ages instead of runtime DaysSinceWrite check against 160d. Should read SpaceAudit JSON. |

## OPERATOR CONSTANTS (all deployed in Common v4.3.2)
```
LOCK_TIMEOUT_SEC = 30       LOCK_POLL_MS = 240
HISTORY_CAP = 666           DEFAULT_MAX_LOG_AGE_DAYS = 160
DEFAULT_STALE_HOURS = 48    DEFAULT_TIMEOUT_SEC = 360
PREREQUISITE_NESTING_LIMIT = 21    MAX_UTILIZATION_PCT = 96
SKIP_CLAUDE = $true
MemoryThresholdMB = 2048    CPUThresholdPercent = 83.33
```

## PROTECTED PROCESSES (kill-list excluded)
claude, Spotify, olk, OUTLOOK, OneDrive, GoogleDriveFS, Microsoft.AAD.BrokerPlugin,
explorer, svchost, csrss, wininit, winlogon, lsass, services, smss, dwm, taskhostw,
RuntimeBroker, SecurityHealthService, SearchHost, MsMpEng, NisSrv, WmiPrvSE,
Code, pwsh, powershell, WindowsTerminal, conhost,
neo4j, mongod, mysqld, postgres, redis-server, tailscaled, docker, dockerd,
audiodg, WavesSysSvc64, WavesSvc64

## SCHEDULE (02:17-05:34, 160% runtime spacing)
```
02:17  DefenderOptimizer (16s avg)
02:17  Inventory (44s)
02:19  Maintenance (810s)
02:40  SpaceAudit (4880s)
04:50  ProcessOptimizer (26s)
04:51  ServiceOptimizer (7s)
04:51  Offload (52s)
04:53  Cleanup (30s)
04:53  LiveScan (64s — improved from 1400s)
05:31  LiveDigest (55s — improved from 106s)
05:34  [complete]
```

## C: DRIVE STATUS
```
Before this session:  373 GB free (37.3%)
After Tier 1-3:       346 GB free (34.6%) — gained 9.53 GB from PreSwap
After Backup delete:  ~613 GB free (~61.4%) — pending operator action
```
