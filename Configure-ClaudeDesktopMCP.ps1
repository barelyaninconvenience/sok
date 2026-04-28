#Requires -Version 7.0
<#
.SYNOPSIS
    [DEPRECATED 2026-04-22] Configures Claude Desktop MCP with Google Workspace
    credentials from User environment variables.

.DESCRIPTION
    ─────────────────────────────────────────────────────────────────────────
    DEPRECATION NOTICE — this script violates CLAUDE.md §2 credential storage
    standard by (a) reading credentials from plaintext User env vars (registry
    HKCU:\Environment) and (b) writing them into claude_desktop_config.json as
    plaintext JSON. Both are disallowed under "no credentials in plaintext...
    environment variables exported in profile, or any committed file."

    SUPERSEDED BY — use the DPAPI + stdio-wrapper pattern instead:

      1. Store Google OAuth credentials in DPAPI:
           Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
           Set-SOKSecret -Name 'GoogleOAuthClientId'     -Plain '<id>'
           Set-SOKSecret -Name 'GoogleOAuthClientSecret' -Plain '<secret>'

      2. Configure claude_desktop_config.json to launch the DPAPI-retrieval wrapper:
           "google_workspace": {
             "command": "cmd",
             "args": ["/c", "C:\\Users\\shelc\\Documents\\Journal\\Projects\\scripts\\launch-workspace-mcp.cmd"]
           }

      3. Zero the User env vars:
           [Environment]::SetEnvironmentVariable('GOOGLE_OAUTH_CLIENT_ID', $null, 'User')
           [Environment]::SetEnvironmentVariable('GOOGLE_OAUTH_CLIENT_SECRET', $null, 'User')

    Full rationale + variants: Writings/MCP_Config_Consolidation_Plan_20260421.md
    ─────────────────────────────────────────────────────────────────────────

    Original behavior: Reads GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET
    from User-level env vars and writes them directly into the Claude Desktop
    config. Also sets GOOGLE_CLIENT_SECRET_PATH if the OAuth JSON file is found.
    No credentials are displayed on screen (DryRun redacts).

.PARAMETER DryRun
    Preview what would be written without modifying the config.

.PARAMETER AcknowledgeDeprecation
    Required as of 2026-04-22. Operators must pass this switch to confirm they
    understand the supersession path before the script will write anything.
    Without the switch, the script prints the deprecation notice and exits 2.
#>
param(
    [switch]$DryRun,
    [switch]$AcknowledgeDeprecation
)

# 2026-04-22 deprecation gate
if (-not $AcknowledgeDeprecation) {
    Write-Host ""
    Write-Host "━━━ DEPRECATION NOTICE ━━━" -ForegroundColor Red
    Write-Host "This script writes plaintext Google OAuth credentials into claude_desktop_config.json."
    Write-Host "Per CLAUDE.md §2 credential storage standard: 'no credentials in plaintext... any committed file'."
    Write-Host ""
    Write-Host "Migrate instead via the DPAPI + stdio-wrapper pattern:" -ForegroundColor Yellow
    Write-Host "  See comment-block in this script header OR Writings/MCP_Config_Consolidation_Plan_20260421.md"
    Write-Host ""
    Write-Host "If you have already verified you still need to run this (e.g., backward-compat emergency)," -ForegroundColor Yellow
    Write-Host "re-run with -AcknowledgeDeprecation to proceed."
    Write-Host ""
    exit 2
}

$configPath = Join-Path $env:APPDATA "Claude\claude_desktop_config.json"

# Read credentials from User environment (never display them)
$clientId = [Environment]::GetEnvironmentVariable("GOOGLE_OAUTH_CLIENT_ID", "User")
$clientSecret = [Environment]::GetEnvironmentVariable("GOOGLE_OAUTH_CLIENT_SECRET", "User")

# Find the OAuth JSON file
$oauthDir = "C:\Users\shelc\Documents\Journal\Household Management\Clay\PII\Important Documents\OAuth"
$secretFile = Get-ChildItem $oauthDir -Filter "client_secret_*.json" -ErrorAction SilentlyContinue | Select-Object -First 1

Write-Host "=== Claude Desktop MCP Configuration ===" -ForegroundColor Cyan
Write-Host "Config path: $configPath"
Write-Host "CLIENT_ID:     $(if ($clientId) { 'SET (' + $clientId.Length + ' chars)' } else { 'NOT SET - run Set-GoogleOAuthEnvVars first' })"
Write-Host "CLIENT_SECRET: $(if ($clientSecret) { 'SET (' + $clientSecret.Length + ' chars)' } else { 'NOT SET' })"
Write-Host "SECRET_FILE:   $(if ($secretFile) { 'FOUND' } else { 'NOT FOUND in OAuth dir' })"

if (-not $clientId -or -not $clientSecret) {
    Write-Host "`nERROR: Environment variables not set. Run these first:" -ForegroundColor Red
    Write-Host '  [Environment]::SetEnvironmentVariable("GOOGLE_OAUTH_CLIENT_ID", "your-id", "User")'
    Write-Host '  [Environment]::SetEnvironmentVariable("GOOGLE_OAUTH_CLIENT_SECRET", "your-secret", "User")'
    exit 1
}

# Build the config
$env = @{
    GOOGLE_OAUTH_CLIENT_ID     = $clientId
    GOOGLE_OAUTH_CLIENT_SECRET = $clientSecret
    OAUTHLIB_INSECURE_TRANSPORT = "1"
    MCP_SINGLE_USER_MODE        = "true"
}

if ($secretFile) {
    $env["GOOGLE_CLIENT_SECRET_PATH"] = $secretFile.FullName
}

$config = @{
    preferences = @{
        coworkWebSearchEnabled       = $true
        coworkScheduledTasksEnabled  = $true
        ccdScheduledTasksEnabled     = $true
        sidebarMode                  = "chat"
    }
    mcpServers = @{
        google_workspace = @{
            command = "uvx"
            args    = @("workspace-mcp")
            env     = $env
        }
    }
}

$json = $config | ConvertTo-Json -Depth 5

if ($DryRun) {
    # Redact credentials in preview
    $redacted = $json -replace '"GOOGLE_OAUTH_CLIENT_ID":\s*"[^"]*"', '"GOOGLE_OAUTH_CLIENT_ID": "***REDACTED***"'
    $redacted = $redacted -replace '"GOOGLE_OAUTH_CLIENT_SECRET":\s*"[^"]*"', '"GOOGLE_OAUTH_CLIENT_SECRET": "***REDACTED***"'
    $redacted = $redacted -replace '"GOOGLE_CLIENT_SECRET_PATH":\s*"[^"]*"', '"GOOGLE_CLIENT_SECRET_PATH": "***REDACTED***"'
    Write-Host "`n[DRY RUN] Would write to $configPath :" -ForegroundColor Yellow
    Write-Host $redacted
} else {
    # Backup existing config
    if (Test-Path $configPath) {
        $backup = "${configPath}.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $configPath $backup
        Write-Host "`nBackup: $backup" -ForegroundColor DarkGray
    }

    $json | Set-Content $configPath -Encoding UTF8
    Write-Host "`nConfig written to: $configPath" -ForegroundColor Green
    Write-Host "Restart Claude Desktop to apply." -ForegroundColor Yellow
    Write-Host "`nNOTE: Credentials are stored in this config file (local only, not synced)."
    Write-Host "The file is at: $configPath"
}
