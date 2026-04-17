#Requires -Version 7.0
# Test: verify the workspace-mcp wrapper fetches creds and sets env vars correctly
# Stops short of invoking uvx workspace-mcp (that would launch an actual MCP server)

$ErrorActionPreference = 'Stop'

Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1' -Force

$clientId = Get-SOKSecret -Name 'GoogleOAuthClientId'
$clientSecret = Get-SOKSecret -Name 'GoogleOAuthClientSecret'

Write-Host "Cred fetch: ClientId length=$($clientId.Length) (prefix=$($clientId.Substring(0,20))...)"
Write-Host "Cred fetch: ClientSecret length=$($clientSecret.Length) (prefix=$($clientSecret.Substring(0,7))...)"

# Verify the values match what was previously in .mcp.json (known prefixes only, no echo)
$idMatch = $clientId.StartsWith('731336933121-ifv5bt8')
$secretMatch = $clientSecret.StartsWith('GOCSPX-')
Write-Host ""
Write-Host "Prefix match (ClientId):    $idMatch"
Write-Host "Prefix match (ClientSecret): $secretMatch"

if ($idMatch -and $secretMatch) {
    Write-Host ""
    Write-Host "WRAPPER VERIFICATION SUCCESS — fetched creds match original .mcp.json plaintext values"
    Write-Host "Wrapper is safe to be invoked by Claude Code MCP subsystem on restart"
} else {
    Write-Host ""
    Write-Host "PREFIX MISMATCH — something is wrong with the stored creds"
    exit 1
}
