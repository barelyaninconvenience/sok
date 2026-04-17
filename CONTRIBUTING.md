# Contributing to SOK

SOK is primarily a personal automation suite, but contributions are welcome.

## Standards

All contributions must follow these SOK engineering standards:

1. **DryRun is mandatory.** Every script must accept `[switch]$DryRun` as its **first** parameter. DryRun must gate ALL destructive operations.

2. **KB units throughout.** All size reporting in kilobytes. No mixed MB/GB units in output.

3. **`#Requires` statements.** Every script must have `#Requires -Version 7.0` and `#Requires -RunAsAdministrator` (if elevation is needed) before the `<#` comment block or at the top of the file.

4. **SYSTEM-context safety.** If a script uses `$env:USERPROFILE`, `$env:LOCALAPPDATA`, or `$env:APPDATA` and may run under Task Scheduler (SYSTEM account), it must include the SYSTEM-context path resolution block.

5. **Deprecate, never delete.** Old versions go to `Deprecated/` with a timestamp suffix.

6. **ErrorAction Continue.** All scripts use `$ErrorActionPreference = 'Continue'`. Errors surface to console and log; nothing is silently swallowed.

7. **SOK-Common integration.** Import `common/SOK-Common.psm1` for logging, configuration, and history. Fallback functions must be defined if the module is unavailable.

## Testing

Run TestBatch before submitting:

```powershell
Start-Process pwsh -ArgumentList "-NoProfile -File SOK-TestBatch.ps1 -SkipSlow" -Verb RunAs
```

All existing tests must pass. New scripts should be added to the TestBatch manifest.

## Code Review

SOK-CodeReview.ps1 integrates Claude Code's /review and /security-review skills. Run it against your changes:

```powershell
.\SOK-CodeReview.ps1 -Files .\YourNewScript.ps1 -DryRun
```

## Commit Messages

Use descriptive commit messages that explain **why**, not just what:

```
SYSTEM-context fix across 10 scheduled scripts, KB compliance, bug fixes

- Added $env:USERPROFILE detection for SYSTEM account in all scheduled scripts
- Why: overnight runs under Task Scheduler resolved paths to C:\Windows\System32\config\systemprofile
```
