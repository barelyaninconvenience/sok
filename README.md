# SOK — Son of Klem

> System Operations Kit: A PowerShell 7 automation suite for Windows workstation management.

[![PowerShell 7+](https://img.shields.io/badge/PowerShell-7.0%2B-blue)](https://github.com/PowerShell/PowerShell)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## What SOK Does

SOK manages the complete lifecycle of a Windows development workstation through three temporal phases:

| Phase | Scripts | Purpose |
|-------|---------|---------|
| **PAST** | InfraFix, Inventory, SpaceAudit, Restructure, CompareSnapshots, BackupRestructure | Diagnose, audit, and repair existing state |
| **PRESENT** | DefenderOptimizer, ProcessOptimizer, ServiceOptimizer, Maintenance, Cleanup | Optimize running system performance |
| **FUTURE** | Offload, Backup, Archiver | Protect against data loss and disk exhaustion |

Plus meta-orchestrators (`SOK-PAST.ps1`, `SOK-PRESENT.ps1`, `SOK-FUTURE.ps1`) and the monolith (`SOK-METICUL.OS.ps1`) that inlines all 18 modules.

## Key Principles

- **DryRun is mandatory.** Every script accepts `[switch]$DryRun` as its first parameter. DryRun gates ALL destructive operations.
- **Deprecate, never delete.** Old scripts go to `Deprecated/`, never the void.
- **KB units throughout.** All size reporting uses kilobytes for consistency.
- **SYSTEM-context safe.** All 13 scheduled scripts detect and handle execution under the SYSTEM account (Windows Task Scheduler).

## Quick Start

```powershell
# Smoke test (DryRun, skip slow scripts):
Start-Process pwsh -ArgumentList "-NoProfile -File `"SOK-TestBatch.ps1`" -SkipSlow" -Verb RunAs

# Full batch test:
Start-Process pwsh -ArgumentList "-NoProfile -File `"SOK-TestBatch.ps1`"" -Verb RunAs

# Interactive full run (all phases):
Start-Process pwsh -ArgumentList "-NoProfile -File `"SOK-METICUL.OS.ps1`" -DryRun" -Verb RunAs
```

## Architecture

```
scripts/
  SOK-METICUL.OS.ps1          # Monolith (18 modules inlined)
  SOK-PAST.ps1                # Meta-orchestrator: diagnostic phase
  SOK-PRESENT.ps1             # Meta-orchestrator: optimization phase
  SOK-FUTURE.ps1              # Meta-orchestrator: protection phase
  SOK-Common.psm1             # Shared module (logging, config, history, banners)
  SOK-Scheduler.ps1           # Task Scheduler registration (13 daily + 1 weekly)
  SOK-TestBatch.ps1           # Exhaustive DryRun test harness
  SOK-Vectorize.py            # Project chunker for AI/ML retrieval (JSONL)
  SOK-CodeReview.ps1          # Claude Code /review + /security-review integration
  config/sok-config.json      # Central configuration
  common/SOK-Common.psm1      # Shared module
  common/SOK-Secrets.psm1     # DPAPI credential helper
  Utilities/                  # Standalone tools (Teams chat extractors, GitHub watcher)
  Deprecated/                 # Archived prior versions (never deleted)
  clay-voice/                 # Voice assistant project (stalled)
```

## Nightly Schedule

SOK-Scheduler registers 13 daily tasks (02:15-05:35) + 1 weekly (Vectorize, Sunday 01:00):

| Time | Script | Phase |
|------|--------|-------|
| 02:15 | InfraFix | PAST |
| 02:17 | DefenderOptimizer | PRESENT |
| 02:17 | Inventory | PAST |
| 02:19 | Maintenance | PRESENT |
| 02:40 | SpaceAudit | PAST |
| 04:50 | ProcessOptimizer | PRESENT |
| 04:51 | ServiceOptimizer | PRESENT |
| 04:51 | Offload | FUTURE |
| 04:53 | Cleanup | PRESENT |
| 04:53 | LiveScan | PRESENT |
| 05:18 | LiveDigest | PRESENT |
| 05:20 | Archiver | FUTURE |
| 05:22 | Backup | FUTURE |

## Testing

```
TestBatch: 23 PASS / 0 FAIL / 2 TIMEOUT / 5 SKIPPED (as of 2026-04-16)
```

## Requirements

- PowerShell 7.0+ (`pwsh`)
- Windows 11 (tested on 10.0.26200)
- Administrator context (most scripts require elevation)
- E: drive for Backup/Offload targets (graceful degradation when offline)

## Related Projects

- **meticulos-agents** — 25-agent Claude Code architecture (8 strategic advisors + 14 tactical stone-turners + 2 specialized + 1 wakeup)
- **meticulos-voice** — Python voice assistant with local STT/TTS and Claude API

## Author

**S. Clay Caddell** — MS-IS, University of Cincinnati | Former 160th SOAR SIGINT

## License

[MIT](LICENSE)
