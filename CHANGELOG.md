# Changelog

All notable changes to SOK are documented here.

## [2026-04-16] — Infrastructure Hardening Marathon

### Added
- `SOK-CodeReview.ps1` — Claude Code /review + /security-review integration for SOK lifecycle
- `launch-workspace-mcp.cmd` — DPAPI credential launcher for Google Workspace MCP
- `Utilities/gh-event-watcher.ps1` — GitHub event polling with ETag-aware rate limiting
- SOK-InfraFix Fix 6: Scoop shim availability detection
- SOK-InfraFix Fix 7: Chocolatey shim integrity spot-check
- SYSTEM-context path resolution in 10 scheduled scripts
- 26 Deprecated/ artifacts now tracked in git

### Fixed
- Export-SoftwareManifest: `$Args` automatic variable shadowing (root cause of Chocolatey returning 0 packages AND pip returning null). Renamed to `$CmdArgs`.
- Export-SoftwareManifest: `Run-Cmd` `$TimeoutSec` parameter was dead code (declared but never used). Replaced `&` invocation with `System.Diagnostics.Process` + async stream reads.
- Export-SoftwareManifest: Removed deprecated `--local-only` flag from Chocolatey query.
- SOK-Vectorize.py: `global` declaration syntax error under Python 3.14 scoping rules. Fixed with `globals()` dict pattern.
- SOK-Vectorize.py: Unicode encoding error in search output on Windows cp1252 terminals.
- Install-GitHubRelease.ps1: Missing `#Requires -RunAsAdministrator` (writes Machine PATH without elevation check).

### Changed
- SOK-ProcessOptimizer: MB units converted to KB throughout (6 references)
- SOK-Archiver: MB units converted to KB (3 references) + output directory changed to canonical path
- DryRun convention: All 16 scripts now have `[switch]$DryRun` as first parameter
- `sok-config.json`: ProcessLasso + ProcessGovernor moved to ProtectedProcesses
- `settings.local.json`: Cleaned 53 dead permission entries
- `#Requires` added to Export-SoftwareManifest.ps1, SOK-ProjectsReorg.ps1
- SOK-TestBatch: Install-GitHubRelease marked as Slow (proper timeout category)
- clay-voice/config.yaml: Memory path updated to canonical scripts scope

### TestBatch Results
```
23 PASS / 0 FAIL / 2 TIMEOUT / 5 SKIPPED
```

## [2026-04-14] — Initial Import

### Added
- Initial import of SOK working state
- 33 tactical scripts + 3 meta-orchestrators + 1 monolith
- SOK-Common.psm1 v4.6.1
- SOK-Secrets.psm1 v1.0.0
- SOK-Scheduler.ps1 v2.1.0 (13 daily + 1 weekly)
- SOK-TestBatch.ps1 (27 PASS / 0 FAIL / 3 TIMEOUT)
- SOK-Vectorize.py v1.0.0
