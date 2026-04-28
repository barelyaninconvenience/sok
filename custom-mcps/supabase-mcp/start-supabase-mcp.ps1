#Requires -Version 7.0
# Supabase MCP wrapper: fetches Supabase URL + service-role key from DPAPI
# and execs the Python MCP server that wraps knowledge_assets / knowledge_chunks
# / projects / session_logs tables plus arbitrary RPC / SQL query capability.
#
# Invoked from ~/.mcp.json:
#   "supabase": {
#     "type": "stdio",
#     "command": "pwsh",
#     "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
#              "C:\\Users\\shelc\\.supabase-mcp\\start-supabase-mcp.ps1"]
#   }
#
# Version 1.0.0 — 2026-04-21 — KLEM/OS v3 Part F custom-MCP roster

$ErrorActionPreference = 'Stop'

$secretsModule = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$bridgePackage = Join-Path $scriptDir 'supabase_mcp_server'

if (-not (Test-Path $secretsModule)) {
    Write-Error "SOK-Secrets module not found at $secretsModule"
    exit 1
}
if (-not (Test-Path $bridgePackage)) {
    Write-Error "Python package not found at $bridgePackage"
    exit 2
}

Import-Module $secretsModule -Force

# Two credentials: project URL (non-sensitive but prefer DPAPI for topology hygiene)
# and service role key (highly sensitive — bypasses RLS)
$supaUrl = Get-SOKSecret -Name 'SUPABASE_URL'
$supaKey = Get-SOKSecret -Name 'SUPABASE_SERVICE_ROLE_KEY'

if ([string]::IsNullOrWhiteSpace($supaUrl)) {
    Write-Error @"
SUPABASE_URL not found in DPAPI.
Set via:
  Set-SOKSecret -Name 'SUPABASE_URL' -Value 'https://<project>.supabase.co'
"@
    exit 3
}
if ([string]::IsNullOrWhiteSpace($supaKey) -or $supaKey.Length -lt 40) {
    Write-Error @"
SUPABASE_SERVICE_ROLE_KEY not found or invalid in DPAPI.
Set via (find key in Supabase dashboard → Settings → API → service_role):
  Set-SOKSecret -Name 'SUPABASE_SERVICE_ROLE_KEY' -Value '<service-role-key>'

CAUTION: service-role key bypasses Row Level Security. Never expose publicly.
"@
    exit 4
}

$env:SUPABASE_URL                 = $supaUrl
$env:SUPABASE_SERVICE_ROLE_KEY    = $supaKey

$supaUrl = $null
$supaKey = $null

try {
    & uvx --from $scriptDir supabase-mcp-server
    exit $LASTEXITCODE
}
catch {
    Write-Error "Failed to launch Supabase MCP: $_"
    exit 5
}
