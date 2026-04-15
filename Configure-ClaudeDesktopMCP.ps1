#Requires -Version 7.0
<#
.SYNOPSIS
    Configures Claude Desktop MCP with Google Workspace credentials from User environment variables.
.DESCRIPTION
    Reads GOOGLE_OAUTH_CLIENT_ID and GOOGLE_OAUTH_CLIENT_SECRET from User-level env vars
    and writes them directly into the Claude Desktop config. Also sets GOOGLE_CLIENT_SECRET_PATH
    if the OAuth JSON file is found. No credentials are displayed on screen.
.PARAMETER DryRun
    Preview what would be written without modifying the config.
#>
param(
    [switch]$DryRun
)

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
