# SOK SESSION META-PROMPT v2.0
# For: S. Clay Caddell (Klem) — SOK/CLAY_PC PowerShell Automation
# Generated: 29Mar2026 from 4 sessions (25-29Mar2026)
# Usage: Paste this at the start of a new Claude session for full context continuity.

---

## OPERATOR IDENTITY

S. Clay Caddell (Klem/Clay). MS-IS candidate, University of Cincinnati Lindner College of Business (graduation Aug 2027). Currently enrolled in Data Driven Cybersecurity Graduate Certificate. ~10 years experience across IT, cybersecurity, SIGINT, and solutions architecture. Army Reserves, military intelligence capacity with clearance eligibility. Career targets: SIGINT Data Architect, AI Data Engineer for Intelligence Systems. Employer targets: NSA, DIA, Cyber Command, Booz Allen Hamilton, Leidos, CACI, Palantir, L3Harris.

Based in Milford, Ohio. Parent to daughter Violet. Spouse Jasmine: ICS/OT practitioner (Honeywell, Emerson, GE Aero). FIRE orientation. Interests: homesteading, permaculture, composting, woodworking, restorative craft. Practices "Liminal Hops" — deliberate cross-domain synthesis as a core intellectual method.

GitHub: barelyaninconvenience.

## SYSTEM: CLAY_PC

Dell Inspiron 16 Plus 7630, Intel i7-13700H, 32GB RAM, Windows 11 Education.
- C: NVMe Samsung PM9B1 1TB — NTFS, primary
- E: JMicron PCIe581 500GB USB SSD — NTFS, offload/backup
- G: Google Drive — FAT32 (NO TRIM, NO robocopy /MOVE)
- D: JMicron SATA581 4TB USB HDD — invalid/unreadable, TestDisk recovery in progress (648 GB discovered)

## PROJECT: SOK (Son of Klem) — System Operations Kit

PowerShell 7.6 automation suite. 23 scripts + 1 module at `C:\Users\shelc\Documents\Journal\Projects\scripts\` with `common\SOK-Common.psm1`. Config: `scripts\config\sok-config.json`. Output: `C:\Users\shelc\Documents\Journal\Projects\SOK\`.

### Deployed Suite (v4.3.3)

**Core (11 + module)**:
Common (v4.3.3, 448L), Inventory (v3.2.0, 702L), SpaceAudit (v2.3.0, 691L — leaf-only optimization), ProcessOptimizer (v1.2.0, 308L — kill-list filter), ServiceOptimizer (v1.2.0, 215L), DefenderOptimizer (v1.2.0, 178L — 3P AV guard), Maintenance (v3.2.1, 460L — TRIM non-NTFS guard), Offload (v2.2.1, 532L — UWP skip), Cleanup (v1.0.1, 304L — SilentlyContinue), LiveScan (v1.1.0, 172L), LiveDigest (v1.1.1, 277L — sort fix)

**Utilities (8)**: Scheduler (v1.2.0, 114L), Archiver (v2.1.0, 199L), Comparator (v2.1.0, 255L), PreSwap (v1.1.0, 403L), RebootClean (v1.1.0, 166L), Restructure (v1.0.0, 200L), Restructure-FlattenedFiles (v1.0.1, 620L), Upgrade (v1.1.0, 284L — RETIRED)

**New/One-shot**: Backup (v1.1.0, 143L), Reinstall (v1.0.0, 196L), Remove-3PSecurity (v1.0.0, 167L), InfraFix (148L), ForceDelete (v2.0, 180L — robocopy/parallel/nuclear auto-escalation), BackupRestructure (v1.0.0, 398L — delete→extract→merge with derivation tags)

### Operator Constants (deployed in Common)
```
LOCK_TIMEOUT_SEC = 30       LOCK_POLL_MS = 240
HISTORY_CAP = 666           DEFAULT_MAX_LOG_AGE_DAYS = 160
DEFAULT_STALE_HOURS = 48    DEFAULT_TIMEOUT_SEC = 360
PREREQUISITE_NESTING_LIMIT = 21    MAX_UTILIZATION_PCT = 96
SKIP_CLAUDE = $true
MemoryThresholdMB = 2048    CPUThresholdPercent = 83.33
Percentages in sixths: 16.66/33.33/50/66.66/83.33/100
All paddings Fibonacci. All depths nearest Fibonacci rounding up.
KB consistently (never humanized). MinSizeKB = 21138. ThreadCount = 13.
```

### Protected Processes (kill-list excluded)
claude, Spotify, olk, OUTLOOK, OneDrive, GoogleDriveFS, Microsoft.AAD.BrokerPlugin, explorer, svchost, csrss, wininit, winlogon, lsass, services, smss, dwm, taskhostw, RuntimeBroker, SecurityHealthService, SearchHost, MsMpEng, NisSrv, WmiPrvSE, Code, pwsh, powershell, WindowsTerminal, conhost, neo4j, mongod, mysqld, postgres, redis-server, tailscaled, docker, dockerd, audiodg, WavesSysSvc64, WavesSvc64

## OPERATOR PREFERENCES (HARD RULES)

### Scripting
- **Complete file deliveries only** — no patches/snippets when a full file is feasible. Hotfixes acceptable for surgical multi-file fixes.
- When hitting response/context limit, **stop and say so**; operator will say "continue"
- **No re-providing unchanged scripts** between responses
- **Deprecate never delete** — Move-ToDeprecated, not Remove-Item on operator files
- PowerShell 7.6 primary, PS 5.1 compat required
- All scripts run via: `pwsh -NoProfile -ExecutionPolicy Bypass -File .\<script>.ps1`
- **Switch params take no value**: `-DryRun` ✅ `-DryRun $true` ❌ (breaks positional params)
- Verbose human- AND machine-readable output. KB sizing (not humanized). Numerological constants over round numbers.
- Maximum script interdependency through Common module

### System Safety
- **Claude Desktop: ALWAYS PROTECTED** from process termination (was the bricking cause — 4-month TITAN-era bug)
- **Outlook Web Cache: NEVER DELETE** (causes re-login + full mailbox re-sync)
- **Spotify: EXCLUDE from cache clearing** (Chromium LevelDB session store destruction)
- **OneDrive/GoogleDriveFS/AAD.BrokerPlugin: PROTECTED** (killing causes Microsoft-wide re-auth cascade)
- **Auth-bearing EBWebView paths: EXCLUDED** from all cache purge operations
- **PreSwap Phase 4: OFFLOAD to E:\SOK_Offload\Deprecated, NEVER Remove-Item**
- **Stale threshold: 160 days** — items below this MUST NOT be deleted or offloaded automatically

### Delivery Quality
- Every file output must be accessible via `present_files` tool
- Check for corrupted/unviewable artifacts — re-deliver if suspected
- Consolidate small fixes into hotfix scripts rather than 7 separate files
- Avoid output redundancy — don't re-state information already acknowledged
- When the operator says "continue" after standby, don't repeat status unless asked
- Track all outstanding items explicitly; oldest first priority

## KNOWN BUGS / HAZARDS (learned the hard way)

| Bug | Root Cause | Status |
|-----|-----------|--------|
| Claude Desktop bricking | ProcessOptimizer killed claude.exe processes | ✅ Fixed: kill-list filter |
| Auth cascade from cache clearing | EBWebView session tokens for OneDrive/Google/Microsoft deleted | ✅ Fixed: exclusion list |
| PreSwap deleting instead of offloading | Phase 4 used Remove-Item, items below 160d threshold in hardcoded list | ✅ Fixed: robocopy to Deprecated |
| SpaceAudit 0 results | PowerShell parallel serialization strips type info from hashtables | ✅ Fixed: pipe-delimited strings in ConcurrentBag[string] |
| LiveDigest picking wrong file | Sort-Object Length (largest) instead of LastWriteTime (newest) | ✅ Fixed |
| Offload Failed=1 (6 runs) | UWP Packages ACLs block robocopy /MOVE | ✅ Fixed: commented out |
| Cleanup console flood | ErrorAction Continue on Remove-Item for locked files | ✅ Fixed: SilentlyContinue |
| Maintenance TRIM on FAT32 | No filesystem check before Optimize-Volume | ✅ Fixed: non-NTFS guard |
| Restructure-FlattenedFiles parser error | Missing comma in param block | ✅ Fixed |
| Choco 0 packages (E: dismounted) | chocolatey\lib junction broken when E: offline | Known, cosmetic |
| Choco installs failing | Corrupted git.install.nupkg blocking dependency resolution | 🔧 Fix: choco upgrade git git.install --force -y |
| Offload Squid exit 10 | C:\Squid ACL or service lock | Investigate |
| PreSwap stale list hardcoded | Ages baked at script-write time, not computed at runtime | Backlog |
| E: full disk stalemate | Overnight .7z extraction filled E: to 0 bytes; takeown fails on full disk | ✅ Fixed: fsutil usn deletejournal /d E: freed journal space, then rd |
| Extracted backup ACL locks | Old user profiles (Shelby/shala) ACLs block delete/modify | ✅ Fixed: takeown /R /A + icacls grant, or robocopy /MIR /B bypass |

## INVOCATION REFERENCE

```powershell
# Core pipeline
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Inventory.ps1 -ScanCaliber 3 -AllowRedundancy
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-SpaceAudit.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-ProcessOptimizer.ps1 -Mode Balanced -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-ProcessOptimizer.ps1 -Mode Balanced
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-ServiceOptimizer.ps1 -Action Report
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-DefenderOptimizer.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Maintenance.ps1 -Mode Thorough
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Offload.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Cleanup.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-LiveScan.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-LiveDigest.ps1 -TopN 204661

# Utilities
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-PreSwap.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-RebootClean.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Archiver.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Scheduler.ps1 -MaintenanceMode Standard
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Backup.ps1 -DryRun
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Backup.ps1 -Incremental
pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Reinstall.ps1 -DryRun
```

## SESSION PROTOCOL

1. On session start: operator pastes this meta-prompt + the carry-over document
2. Claude reads both, acknowledges the current state, asks what's priority
3. Work proceeds from the outstanding items list (oldest first unless operator redirects)
4. On session end or near context limit: Claude produces updated carry-over document
5. Operator saves carry-over for next session
