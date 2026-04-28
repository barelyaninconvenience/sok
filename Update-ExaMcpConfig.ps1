#Requires -Version 7.0
<#
.SYNOPSIS
    Update-ExaMcpConfig.ps1 — one-shot .claude.json edit to swap the Exa MCP entry
    from its plaintext-URL HTTP config to the DPAPI-backed stdio launcher.

.DESCRIPTION
    Final step of the Exa credential rotation runbook. Prerequisites:
      1. Exa API key rotated at https://dashboard.exa.ai (old key revoked)
      2. New key stored in DPAPI:
         Set-SOKSecret -Name 'EXA_API_KEY' -Plain '<new-key>'
      3. exa-mcp custom wrapper deployed to ~/.exa-mcp/:
         .\custom-mcps\deploy-custom-mcps.ps1 -OnlyMcp exa -Force
      4. Smoke-test the launcher (optional but recommended):
         pwsh -NoProfile -File ~/.exa-mcp/start-exa-mcp.ps1
         (will emit "Exa API key retrieved; bridge starting..." then idle on stdin)

    This script then rewrites the `exa` entry inside `.claude.json` mcpServers
    from the HTTP-type URL-embedded plaintext config to the stdio-launcher form.

    DryRun by default. -Apply required for actual write.

    Safety:
      - Backs up .claude.json to .claude.json.bak_<timestamp> before edit
      - Validates post-edit JSON parses successfully
      - Refuses to proceed if the expected launcher doesn't exist
      - Never echoes credential values (old or new) to stdout

.PARAMETER ConfigPath
    Path to .claude.json. Default: $env:USERPROFILE\.claude.json

.PARAMETER LauncherPath
    Path to the exa-mcp stdio launcher. Default: $env:USERPROFILE\.exa-mcp\start-exa-mcp.ps1

.PARAMETER DryRun
    Default behavior. Reports what would change. Never writes.

.PARAMETER Apply
    Perform the actual rewrite. Overrides DryRun default.

.PARAMETER Force
    Skip the PROCEED confirmation prompt (unattended use). Still creates backup.

.NOTES
    Author:  S. Clay Caddell
    Version: 1.0.0
    Date:    2026-04-22
    Domain:  Security — completes Exa Priority-1 credential remediation
    Pairs with: scripts/Migrate-PlaintextMCPCreds.ps1 (scanner),
                scripts/custom-mcps/exa-mcp/ (launcher + Python bridge),
                scripts/custom-mcps/deploy-custom-mcps.ps1 (deployer)

    Per CLAUDE.md §4 destructive-ops list: editing a config file is a destructive
    op. This helper emits a PRE-OP / ROLLBACK / REQUEST block and requires
    either -Force or explicit 'PROCEED' input before writing.
#>
[CmdletBinding()]
param(
    [string]$ConfigPath   = (Join-Path $env:USERPROFILE '.claude.json'),
    [string]$LauncherPath = (Join-Path $env:USERPROFILE '.exa-mcp\start-exa-mcp.ps1'),
    [switch]$DryRun,
    [switch]$Apply,
    [switch]$Force
)

$ErrorActionPreference = 'Continue'
if (-not $PSBoundParameters.ContainsKey('DryRun')) { $DryRun = -not $Apply }

# ── Sanity checks ────────────────────────────────────────────────────────────
if (-not (Test-Path $ConfigPath)) {
    Write-Host "[ERROR] Config file not found: $ConfigPath" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $LauncherPath)) {
    Write-Host "[ERROR] Exa MCP launcher not found: $LauncherPath" -ForegroundColor Red
    Write-Host "        Run custom-mcps\deploy-custom-mcps.ps1 -OnlyMcp exa -Force first." -ForegroundColor Yellow
    exit 2
}

# ── Parse ────────────────────────────────────────────────────────────────────
try {
    $rawConfig = Get-Content $ConfigPath -Raw -ErrorAction Stop
    # Preserve hashtable semantics for deterministic edit path
    $config = $rawConfig | ConvertFrom-Json -AsHashtable -Depth 64 -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Failed to parse $ConfigPath : $_" -ForegroundColor Red
    exit 3
}

if (-not $config.ContainsKey('mcpServers')) {
    Write-Host "[ERROR] No mcpServers section in $ConfigPath" -ForegroundColor Red
    exit 4
}

$mcpServers = $config['mcpServers']
$hasExa = $mcpServers -is [System.Collections.IDictionary] -and $mcpServers.Contains('exa')

if (-not $hasExa) {
    Write-Host "[INFO] No 'exa' entry in mcpServers. Nothing to migrate." -ForegroundColor Cyan
    exit 0
}

$currentExa = $mcpServers['exa']

# Describe current state WITHOUT echoing key material
$currentType    = if ($currentExa -is [System.Collections.IDictionary] -and $currentExa.Contains('type')) { $currentExa['type'] } else { '<unspecified>' }
$currentHasUrl  = $currentExa -is [System.Collections.IDictionary] -and $currentExa.Contains('url') -and -not [string]::IsNullOrWhiteSpace($currentExa['url'])
$currentUrlLen  = if ($currentHasUrl) { $currentExa['url'].Length } else { 0 }

Write-Host "=== Current exa entry ===" -ForegroundColor Cyan
Write-Host "  type:             $currentType"
Write-Host "  url.length:       $currentUrlLen (value redacted — likely contains plaintext API key)"

# Desired new state
$newExa = [ordered]@{
    type    = 'stdio'
    command = 'pwsh'
    args    = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $LauncherPath
    )
}

Write-Host ""
Write-Host "=== Proposed new exa entry ===" -ForegroundColor Cyan
Write-Host "  type:    $($newExa.type)"
Write-Host "  command: $($newExa.command)"
Write-Host "  args:"
foreach ($a in $newExa.args) { Write-Host "    - $a" }

# Already-migrated detection
if ($currentType -eq 'stdio' -and -not $currentHasUrl) {
    Write-Host ""
    Write-Host "[INFO] Exa entry already appears to be stdio-type (no plaintext URL)." -ForegroundColor Yellow
    Write-Host "       No change needed. Confirm with /mcp in Claude Code that Exa connects." -ForegroundColor Yellow
    exit 0
}

$backupPath = "$ConfigPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

Write-Host ""
Write-Host "=== PRE-OP / ROLLBACK / REQUEST ===" -ForegroundColor Magenta
Write-Host "PRE-OP STATE:"
Write-Host "  $ConfigPath contains exa entry type=$currentType with url.length=$currentUrlLen"
Write-Host "ROLLBACK:"
Write-Host "  Copy-Item '$backupPath' '$ConfigPath' -Force"
Write-Host "REQUEST:"
Write-Host "  Rewrite exa entry to stdio-launcher form."
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] No changes written. Re-run with -Apply to proceed." -ForegroundColor Yellow
    exit 0
}

# ── PROCEED gate ─────────────────────────────────────────────────────────────
if (-not $Force) {
    if ([Console]::IsInputRedirected) {
        Write-Host "[ABORT] stdin redirected and -Force not set. Run interactively or pass -Force." -ForegroundColor Red
        exit 5
    }
    $answer = Read-Host "Type PROCEED to continue"
    if ($answer -ne 'PROCEED') {
        Write-Host "[ABORT] Did not receive 'PROCEED'. Nothing written." -ForegroundColor Yellow
        exit 6
    }
}

# ── Backup ───────────────────────────────────────────────────────────────────
try {
    Copy-Item -Path $ConfigPath -Destination $backupPath -Force -ErrorAction Stop
    Write-Host "[OK] Backup: $backupPath" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Backup failed: $_ — aborting" -ForegroundColor Red
    exit 7
}

# ── Rewrite ──────────────────────────────────────────────────────────────────
$mcpServers['exa'] = $newExa
$config['mcpServers'] = $mcpServers

try {
    $newJson = $config | ConvertTo-Json -Depth 64 -ErrorAction Stop
} catch {
    Write-Host "[ERROR] JSON serialization failed: $_ — original file unchanged" -ForegroundColor Red
    exit 8
}

# Validate round-trip before writing
try {
    $null = $newJson | ConvertFrom-Json -Depth 64 -ErrorAction Stop
} catch {
    Write-Host "[ERROR] Round-trip JSON parse failed: $_ — original file unchanged" -ForegroundColor Red
    exit 9
}

try {
    Set-Content -Path $ConfigPath -Value $newJson -Encoding utf8 -NoNewline -ErrorAction Stop
    Write-Host "[OK] $ConfigPath updated" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Write failed: $_ — restoring from backup" -ForegroundColor Red
    Copy-Item -Path $backupPath -Destination $ConfigPath -Force -ErrorAction SilentlyContinue
    exit 10
}

# ── Post-write verification ──────────────────────────────────────────────────
try {
    $verify = Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable -Depth 64 -ErrorAction Stop
    $verifyExa = $verify['mcpServers']['exa']
    $verifyType    = if ($verifyExa.Contains('type')) { $verifyExa['type'] } else { '<unspecified>' }
    $verifyHasUrl  = $verifyExa.Contains('url')
    if ($verifyType -eq 'stdio' -and -not $verifyHasUrl) {
        Write-Host "[OK] Verified: exa entry is now stdio-type with no url" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Post-write state unexpected. type=$verifyType hasUrl=$verifyHasUrl" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARN] Post-write verification failed: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next: restart Claude Code. Confirm exa appears in /mcp output." -ForegroundColor Cyan
Write-Host "If connection fails, rollback with:" -ForegroundColor Cyan
Write-Host "  Copy-Item '$backupPath' '$ConfigPath' -Force" -ForegroundColor Cyan
