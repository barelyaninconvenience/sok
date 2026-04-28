#Requires -Version 7.0
# Unstructured MCP wrapper: launches Python MCP server that wraps the
# unstructured Python library for document parsing.
#
# No credential needed — unstructured runs entirely local via Python library.
# Optional hosted-API fallback supported via UNSTRUCTURED_API_KEY env var
# (retrieved from DPAPI if stored).
#
# Version 1.0.0 — 2026-04-21 — KLEM/OS v3 Part F custom-MCP roster

$ErrorActionPreference = 'Stop'

$secretsModule = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$bridgePackage = Join-Path $scriptDir 'unstructured_mcp_server'

if (-not (Test-Path $bridgePackage)) {
    Write-Error "Python package not found at $bridgePackage"
    exit 2
}

# Optional: if UNSTRUCTURED_API_KEY secret exists in DPAPI, use hosted API.
# If not, library runs entirely locally.
if (Test-Path $secretsModule) {
    Import-Module $secretsModule -Force
    try {
        $apiKey = Get-SOKSecret -Name 'UNSTRUCTURED_API_KEY' -ErrorAction SilentlyContinue
        if ($apiKey) {
            $env:UNSTRUCTURED_API_KEY = $apiKey
            $apiKey = $null
        }
    } catch {
        # No secret stored — use local mode. Silent fallback.
    }
}

try {
    & uvx --from $scriptDir unstructured-mcp-server
    exit $LASTEXITCODE
}
catch {
    Write-Error "Failed to launch Unstructured MCP: $_"
    exit 5
}
