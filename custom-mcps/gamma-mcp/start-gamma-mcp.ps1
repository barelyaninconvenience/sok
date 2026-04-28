#Requires -Version 7.0
# Gamma MCP wrapper: fetches Gamma API key from DPAPI and execs Python MCP server
# that generates presentations via Gamma API.
#
# Gamma's API is evolving; this wrapper assumes v1 REST endpoints. Adjust
# endpoint URLs in the Python server if Gamma's API surface changes.
#
# Version 1.0.0 — 2026-04-21 — KLEM/OS v3 Part F custom-MCP roster

$ErrorActionPreference = 'Stop'

$secretsModule = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$bridgePackage = Join-Path $scriptDir 'gamma_mcp_server'

if (-not (Test-Path $secretsModule)) {
    Write-Error "SOK-Secrets module not found at $secretsModule"
    exit 1
}
if (-not (Test-Path $bridgePackage)) {
    Write-Error "Python package not found at $bridgePackage"
    exit 2
}

Import-Module $secretsModule -Force

$gammaKey = Get-SOKSecret -Name 'GAMMA_API_KEY'

if ([string]::IsNullOrWhiteSpace($gammaKey) -or $gammaKey.Length -lt 20) {
    Write-Error @"
GAMMA_API_KEY not found or invalid in DPAPI.
Gamma API is in beta as of early 2026; if you don't have access yet:
  1. Apply for Gamma API beta access at https://gamma.app/
  2. Once issued, store the key:
     Set-SOKSecret -Name 'GAMMA_API_KEY' -Value '<key>'
"@
    exit 3
}

$env:GAMMA_API_KEY = $gammaKey
$gammaKey = $null

try {
    & uvx --from $scriptDir gamma-mcp-server
    exit $LASTEXITCODE
}
catch {
    Write-Error "Failed to launch Gamma MCP: $_"
    exit 5
}
