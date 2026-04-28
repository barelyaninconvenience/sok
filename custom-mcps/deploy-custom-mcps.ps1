#Requires -Version 7.0
<#
.SYNOPSIS
  Deploys the 6 v3 Part F custom MCPs from staging to production locations.

.DESCRIPTION
  Copies each <name>-mcp/ directory from Projects/scripts/custom-mcps/ (staging)
  to ~/.<name>-mcp/ (production). Required before .mcp.json registration.

  Respects CLAUDE.md §2 deprecate-never-delete: if destination already exists
  with content, backs up to ~/.<name>-mcp.deprecated.<timestamp>/ before
  overwriting. Gated on -Force or explicit confirmation.

.PARAMETER DryRun
  Print what would be done without copying anything.

.PARAMETER Force
  Skip confirmation prompts. Required for unattended deployment.

.PARAMETER OnlyMcp
  Deploy only the named MCP (e.g., 'exa'). Default: all 6.

.PARAMETER StagingRoot
  Source directory for MCP staging. Default:
  C:\Users\shelc\Documents\Journal\Projects\scripts\custom-mcps

.EXAMPLE
  .\deploy-custom-mcps.ps1 -DryRun
  # Report what would be deployed without changing anything

.EXAMPLE
  .\deploy-custom-mcps.ps1 -OnlyMcp exa -Force
  # Deploy only exa-mcp unattended

.EXAMPLE
  .\deploy-custom-mcps.ps1 -Force
  # Deploy all 6 MCPs unattended (post-credential-storage)

.NOTES
  Version 1.0.0 — 2026-04-21 — KLEM/OS v3 Part F deployment helper

  Prerequisites per MCP:
    exa          - Set-SOKSecret -Name 'EXA_API_KEY'
    supabase     - Set-SOKSecret -Name 'SUPABASE_URL' + 'SUPABASE_SERVICE_ROLE_KEY'
    n8n-control  - Set-SOKSecret -Name 'N8N_BASE_URL' + 'N8N_API_TOKEN'
    gamma        - Set-SOKSecret -Name 'GAMMA_API_KEY'
    ollama       - None (localhost by default)
    unstructured - None (local library); optional UNSTRUCTURED_API_KEY for hosted API

  Post-deployment:
    .\add-custom-mcps.ps1           # Print JSON blocks to paste into ~/.mcp.json
    .\add-custom-mcps.ps1 -ShowExisting  # Audit registration state
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [string]$OnlyMcp = '',
    [string]$StagingRoot = 'C:\Users\shelc\Documents\Journal\Projects\scripts\custom-mcps'
)

$ErrorActionPreference = 'Stop'

$mcpNames = @('exa', 'supabase', 'ollama', 'unstructured', 'n8n-control', 'gamma')

if ($OnlyMcp) {
    if ($mcpNames -notcontains $OnlyMcp) {
        Write-Host "Unknown MCP: $OnlyMcp" -ForegroundColor Red
        Write-Host "Known: $($mcpNames -join ', ')"
        exit 1
    }
    $mcpNames = @($OnlyMcp)
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'

Write-Host "=== v3 Part F custom-MCP deployment ===" -ForegroundColor Cyan
if ($DryRun) { Write-Host "DRY RUN — no files will be changed" -ForegroundColor Yellow }
Write-Host ""

foreach ($name in $mcpNames) {
    $stagingDir = Join-Path $StagingRoot "$name-mcp"
    $prodDir    = Join-Path $env:USERPROFILE ".$name-mcp"

    Write-Host "--- $name-mcp ---" -ForegroundColor Cyan

    if (-not (Test-Path $stagingDir)) {
        Write-Host "  STAGING MISSING: $stagingDir — skipping" -ForegroundColor Red
        continue
    }

    $stagingLauncher = Join-Path $stagingDir "start-$name-mcp.ps1"
    if (-not (Test-Path $stagingLauncher)) {
        Write-Host "  LAUNCHER MISSING in staging: $stagingLauncher — skipping" -ForegroundColor Red
        continue
    }

    Write-Host "  Source:      $stagingDir"
    Write-Host "  Destination: $prodDir"

    if (Test-Path $prodDir) {
        $existingFiles = @(Get-ChildItem $prodDir -Force -ErrorAction SilentlyContinue)
        if ($existingFiles.Count -gt 0) {
            $backupDir = "$prodDir.deprecated.$timestamp"
            Write-Host "  Production has $($existingFiles.Count) existing item(s). Will back up to:" -ForegroundColor Yellow
            Write-Host "    $backupDir" -ForegroundColor Yellow

            if (-not $Force -and -not $DryRun) {
                # 2026-04-22 polish: non-interactive guard (same pattern as SOK-Comparator C-L-5).
                # Read-Host blocks forever when stdin is redirected (scheduled task, pipeline,
                # unattended deployment). Abort safely with actionable message; operator can
                # pass -Force for unattended deployment.
                if ([Console]::IsInputRedirected) {
                    Write-Host "  SKIPPED (non-interactive context detected; re-run with -Force for unattended deployment)" -ForegroundColor Yellow
                    continue
                }
                $answer = Read-Host "  Proceed? [y/N]"
                if ($answer -ne 'y' -and $answer -ne 'Y') {
                    Write-Host "  SKIPPED by user" -ForegroundColor Yellow
                    continue
                }
            }

            if (-not $DryRun) {
                Rename-Item -Path $prodDir -NewName (Split-Path -Leaf $backupDir)
                Write-Host "  Backup complete" -ForegroundColor Green
            } else {
                Write-Host "  [DRY RUN] Would rename $prodDir → $backupDir"
            }
        } else {
            if (-not $DryRun) { Remove-Item -Path $prodDir -Force -Recurse }
        }
    }

    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $prodDir -Force | Out-Null
        Copy-Item -Path "$stagingDir\*" -Destination $prodDir -Recurse -Force
        Write-Host "  DEPLOYED" -ForegroundColor Green
    } else {
        Write-Host "  [DRY RUN] Would create $prodDir and copy contents from $stagingDir" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "=== Deployment complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Verify credentials stored in DPAPI for each MCP (see -Help for list)"
Write-Host "  2. Run .\add-custom-mcps.ps1 to print ~/.mcp.json registration blocks"
Write-Host "  3. Paste blocks into ~/.mcp.json mcpServers section"
Write-Host "  4. Restart Claude Code — verify MCPs appear in tool inventory"
Write-Host "  5. For EXA specifically: remove the old HTTP config from .claude.json top-level mcpServers"
