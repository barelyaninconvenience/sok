#Requires -Version 7.0
# n8n-control MCP wrapper: fetches n8n API token from DPAPI and execs Python
# server that wraps n8n's REST API (list/trigger/monitor workflows, read
# execution history, etc.).
#
# Version 1.0.0 — 2026-04-21 — KLEM/OS v3 Part F custom-MCP roster

$ErrorActionPreference = 'Stop'

$secretsModule = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$bridgePackage = Join-Path $scriptDir 'n8n_control_mcp_server'

if (-not (Test-Path $secretsModule)) {
    Write-Error "SOK-Secrets module not found at $secretsModule"
    exit 1
}
if (-not (Test-Path $bridgePackage)) {
    Write-Error "Python package not found at $bridgePackage"
    exit 2
}

Import-Module $secretsModule -Force

$n8nUrl   = Get-SOKSecret -Name 'N8N_BASE_URL'
$n8nToken = Get-SOKSecret -Name 'N8N_API_TOKEN'

if ([string]::IsNullOrWhiteSpace($n8nUrl)) {
    Write-Error @"
N8N_BASE_URL not found in DPAPI.
Set via:
  Set-SOKSecret -Name 'N8N_BASE_URL' -Value 'http://localhost:5678'
  # or whatever your n8n instance URL is (self-hosted typical)
"@
    exit 3
}
if ([string]::IsNullOrWhiteSpace($n8nToken)) {
    Write-Error @"
N8N_API_TOKEN not found in DPAPI.
Generate in n8n: Settings → n8n API → Create API key, then:
  Set-SOKSecret -Name 'N8N_API_TOKEN' -Value '<token>'
"@
    exit 4
}

$env:N8N_BASE_URL  = $n8nUrl
$env:N8N_API_TOKEN = $n8nToken

$n8nUrl   = $null
$n8nToken = $null

try {
    & uvx --from $scriptDir n8n-control-mcp-server
    exit $LASTEXITCODE
}
catch {
    Write-Error "Failed to launch n8n-control MCP: $_"
    exit 5
}
