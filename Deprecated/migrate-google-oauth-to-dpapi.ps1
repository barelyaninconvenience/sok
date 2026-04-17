#Requires -Version 7.0
# DPAPI migration of Google OAuth creds from .mcp.json workspace-mcp env block
# Clay authorized 2026-04-14 overnight. Closes last known plaintext-credential leak.

$ErrorActionPreference = 'Stop'

Import-Module 'C:/Users/shelc/Documents/Journal/Projects/scripts/common/SOK-Secrets.psm1' -Force

Write-Host "=== Reading workspace-mcp env from .mcp.json ==="
$mcp = Get-Content 'C:/Users/shelc/.mcp.json' -Raw | ConvertFrom-Json
$env = $mcp.mcpServers.'workspace-mcp'.env
$clientId = $env.GOOGLE_OAUTH_CLIENT_ID
$clientSecret = $env.GOOGLE_OAUTH_CLIENT_SECRET

if ([string]::IsNullOrWhiteSpace($clientId) -or [string]::IsNullOrWhiteSpace($clientSecret)) {
    Write-Host "  One or both values missing; aborting migration."
    Write-Host "  ClientId present: $(-not [string]::IsNullOrWhiteSpace($clientId))"
    Write-Host "  ClientSecret present: $(-not [string]::IsNullOrWhiteSpace($clientSecret))"
    exit 1
}

# Do NOT echo values — just confirm lengths and prefixes
Write-Host "  ClientId length: $($clientId.Length) (prefix: $($clientId.Substring(0,[Math]::Min(20,$clientId.Length)))...)"
Write-Host "  ClientSecret length: $($clientSecret.Length) (starts-with: $($clientSecret.Substring(0,[Math]::Min(7,$clientSecret.Length)))...)"

Write-Host ""
Write-Host "=== Storing secrets via Set-SOKSecret ==="
Set-SOKSecret -Name 'GoogleOAuthClientId'     -Plain $clientId     -Verbose
Set-SOKSecret -Name 'GoogleOAuthClientSecret' -Plain $clientSecret -Verbose

Write-Host ""
Write-Host "=== Verifying roundtrip ==="
$testId = Get-SOKSecret -Name 'GoogleOAuthClientId'
$testSecret = Get-SOKSecret -Name 'GoogleOAuthClientSecret'
$idMatch = ($testId -eq $clientId)
$secretMatch = ($testSecret -eq $clientSecret)
Write-Host "  ClientId roundtrip:    $idMatch"
Write-Host "  ClientSecret roundtrip: $secretMatch"

# Zero the local variables immediately after roundtrip check
$clientId = $null
$clientSecret = $null
$testId = $null
$testSecret = $null
[System.GC]::Collect()

if ($idMatch -and $secretMatch) {
    Write-Host ""
    Write-Host "=== Secret store inventory ==="
    Get-SOKSecretList | ForEach-Object { Write-Host "  - $_" }
    Write-Host ""
    Write-Host "MIGRATION SUCCESSFUL. Safe to update .mcp.json and zero the plaintext env block."
    exit 0
} else {
    Write-Host ""
    Write-Host "MIGRATION FAILED — roundtrip verification did not match. .mcp.json plaintext left intact."
    exit 1
}
