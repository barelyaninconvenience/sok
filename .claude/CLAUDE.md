# CLAUDE.md — SOK Project Scope
# Applies when working directory is scripts/

## SOK Conventions (mandatory)
- `[switch]$DryRun` as first parameter on every script
- DryRun gates ALL destructive operations
- `#Requires -RunAsAdministrator` and `#Requires -Version 7.0` on all scripts
- All sizes reported in KB
- Logs to `SOK\Logs\` via Initialize-SOKLog — NEVER write to `SOK\` directly
- Each script has exactly one job (microservice delineation)
- Deprecate to `Deprecated\`, never delete
- Read every file exhaustively before proposing changes

## SOK-Common Module
- Location: `common/SOK-Common.psm1` (v4.6.0)
- All scripts load it via `Join-Path $PSScriptRoot 'common\SOK-Common.psm1'` with hardcoded fallback
- Use `Get-Command` guard before calling `Invoke-SOKPrerequisite`

## Test Pattern
```powershell
Start-Process pwsh -ArgumentList "-NoProfile -File `"$PSScriptRoot\SOK-TestBatch.ps1`" -SkipSlow" -Verb RunAs
```

## Audit Reference
See `SOK_Audit_Report_20260406.md` in this directory for known findings.

## Temporal Architecture
- PAST: InfraFix → Inventory → SpaceAudit → Restructure → Comparator → BackupRestructure
- PRESENT: DefenderOptimizer → ProcessOptimizer → ServiceOptimizer → Maintenance → Cleanup → PreSwap → LiveScan → LiveDigest
- FUTURE: Offload → Backup → Archive
