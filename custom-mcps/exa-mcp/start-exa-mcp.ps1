#Requires -Version 7.0
# Exa-MCP wrapper: fetches Exa API key from DPAPI store and execs the Python
# stdio-to-HTTP MCP bridge, which proxies Claude Code stdio requests to
# Exa's HTTP MCP endpoint (https://mcp.exa.ai/mcp) with Authorization header.
#
# The credential never touches .claude.json / .mcp.json / any config file —
# it lives in DPAPI-encrypted ~/.sok-secrets/EXA_API_KEY.sec and is retrieved
# fresh per session via Get-SOKSecret.
#
# Invoked from .mcp.json (or .claude.json top-level mcpServers) as:
#   "exa": {
#     "type": "stdio",
#     "command": "pwsh",
#     "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
#              "C:\\Users\\shelc\\.exa-mcp\\start-exa-mcp.ps1"]
#   }
#
# Replaces the previous plaintext-key HTTP config:
#   "exa": { "type": "http", "url": "https://mcp.exa.ai/mcp?exaApiKey=<KEY>&..." }
#
# Version 1.0.0 — 2026-04-21 — custom-MCP-wrap-APIs exemplar per KLEM/OS v3

$ErrorActionPreference = 'Stop'

# --- Resolve module + script paths ---
# When this script is deployed to ~/.exa-mcp/, SOK-Secrets lives at the canonical
# scripts location (not adjacent). Hardcode the canonical path since SOK scripts
# are always installed at this prefix per CLAUDE.md §1.

$secretsModule = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$bridgePackage = Join-Path $scriptDir 'exa_mcp_bridge'

if (-not (Test-Path $secretsModule)) {
    Write-Error "SOK-Secrets module not found at $secretsModule. Verify scripts project is present."
    exit 1
}
if (-not (Test-Path $bridgePackage)) {
    Write-Error "Python bridge package not found at $bridgePackage. Deploy the full exa-mcp/ directory."
    exit 2
}

Import-Module $secretsModule -Force

# --- Retrieve Exa API key from DPAPI ---
$exaKey = Get-SOKSecret -Name 'EXA_API_KEY'

if ([string]::IsNullOrWhiteSpace($exaKey)) {
    Write-Error @"
Exa API key not found in DPAPI store.

To set:
  Import-Module '$secretsModule' -Force
  Set-SOKSecret -Name 'EXA_API_KEY' -Value '<your-exa-api-key>'

To rotate (recommended after any exposure):
  1. Visit https://dashboard.exa.ai/ and generate a new key
  2. Revoke the old key
  3. Run the Set-SOKSecret command above with the new key
"@
    exit 3
}

if ($exaKey.Length -lt 20) {
    Write-Error "Exa API key in DPAPI store appears invalid (length < 20). Re-store a valid key."
    exit 4
}

# --- Set env var for the Python bridge to read ---
# Bridge reads EXA_API_KEY from env and injects Authorization: Bearer header
# into each forwarded request to mcp.exa.ai.
$env:EXA_API_KEY = $exaKey

# Tool list to expose — mirrors the original .claude.json exa config.
# Bridge passes this to Exa HTTP endpoint for server-side tool filtering.
$env:EXA_TOOLS = 'web_search_exa,web_search_advanced_exa,get_code_context_exa,crawling_exa,company_research_exa,people_search_exa,deep_researcher_start,deep_researcher_check'

# Upstream endpoint (parameterized for testing / alternative deployments)
$env:EXA_MCP_UPSTREAM = 'https://mcp.exa.ai/mcp'

# --- Zero our local reference — env var still carries value to child process ---
$exaKey = $null

# --- Hand off to Python bridge via uvx ---
# The `uvx --from <local-dir> <entrypoint>` pattern runs the package as if pip-installed
# from the local directory, which lets us iterate on bridge code without publishing.
# stdin/stdout passthrough is what Claude Code expects for an MCP stdio server.

try {
    & uvx --from $scriptDir exa-mcp-bridge
    exit $LASTEXITCODE
}
catch {
    Write-Error "Failed to launch Python bridge via uvx: $_"
    exit 5
}
