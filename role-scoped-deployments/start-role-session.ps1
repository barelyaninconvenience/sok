#Requires -Version 7.0
<#
.SYNOPSIS
  Launch a Claude Code session scoped to a specific role (Job A / Job B / etc.).

.DESCRIPTION
  Sets ROLE_CONTEXT env var + role-specific working directory + role-scoped
  .mcp.json path + role-scoped browser profile. Custom MCPs loaded for the
  session read ROLE_CONTEXT and filter their operations accordingly (e.g.,
  Supabase MCP queries the role-scoped tenancy; Gmail MCP loads the role's
  OAuth credentials).

  Designed for multi-concurrent-remote-role operating mode per KLEM/OS v3.1
  (`Writings/Overemployment_Stack_Integration_20260421.md` Part A two-layer
  model). Per-role compartmentalization of identity/credentials/calendar/
  communication channels; shared KLEM/OS backbone.

.PARAMETER Role
  Role identifier — case-sensitive. Must correspond to an entry in
  role-config.json. Example: 'joba', 'jobb', 'personal'.

.PARAMETER Config
  Override default role-config.json path.

.EXAMPLE
  .\start-role-session.ps1 -Role joba
  # Launches Claude Code with Job A context

.EXAMPLE
  .\start-role-session.ps1 -Role jobb
  # Launches Claude Code with Job B context

.NOTES
  Version 1.0.0 — 2026-04-21 — KLEM/OS v3.1 per-role compartmentalization

  Prerequisites:
    1. role-config.json populated with role definitions
    2. Per-role credentials stored in DPAPI with role-prefixed names
       (e.g., JOBA_SUPABASE_SERVICE_ROLE_KEY, JOBB_SUPABASE_SERVICE_ROLE_KEY)
    3. Per-role .mcp.json files at ~/.claude-<role>/.mcp.json if role-scoped
       MCP loading is desired
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Role,

    [string]$Config = ''
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Resolve config path ---
if ([string]::IsNullOrWhiteSpace($Config)) {
    $Config = Join-Path $scriptDir 'role-config.json'
}
if (-not (Test-Path $Config)) {
    Write-Error @"
Role config not found at $Config.

Create with the template provided at:
  $scriptDir\role-config.template.json

Then customize with your role definitions.
"@
    exit 1
}

# --- Load config ---
$roleConfig = Get-Content $Config -Raw | ConvertFrom-Json

if (-not $roleConfig.roles.$Role) {
    $availableRoles = $roleConfig.roles.PSObject.Properties.Name -join ', '
    Write-Error "Role '$Role' not defined in $Config. Available: $availableRoles"
    exit 2
}

$def = $roleConfig.roles.$Role

# --- Set role context env vars ---
$env:ROLE_CONTEXT      = $Role
$env:ROLE_DISPLAY_NAME = $def.display_name
$env:ROLE_WORKING_DIR  = $def.working_dir

# --- Launch sub-shell / Claude Code with role context ---
Write-Host "=== Launching Claude Code session for role: $($def.display_name) ===" -ForegroundColor Cyan
Write-Host "  Role context:   $Role" -ForegroundColor Green
Write-Host "  Working dir:    $($def.working_dir)" -ForegroundColor Green
Write-Host "  MCP config:     $($def.mcp_config_path)" -ForegroundColor Green
Write-Host "  Browser profile: $($def.browser_profile_name)" -ForegroundColor Green
Write-Host ""
Write-Host "ROLE_CONTEXT env var set for child processes." -ForegroundColor Yellow
Write-Host "Custom MCPs should read this var and filter accordingly." -ForegroundColor Yellow
Write-Host ""

# Change to role-specific working directory
if (Test-Path $def.working_dir) {
    Set-Location $def.working_dir
} else {
    Write-Warning "Working dir $($def.working_dir) does not exist — creating..."
    New-Item -ItemType Directory -Path $def.working_dir -Force | Out-Null
    Set-Location $def.working_dir
}

# Launch Claude Code with role-specific MCP config if configured
if ($def.mcp_config_path -and (Test-Path $def.mcp_config_path)) {
    # Set MCP config override if Claude Code supports it via env var
    $env:CLAUDE_MCP_CONFIG_PATH = $def.mcp_config_path
}

# Output reminder of workflow discipline (per v3.1 Part D)
Write-Host "--- Operating discipline reminders ---" -ForegroundColor Magenta
Write-Host "  1. Batch same-role work (minimize L-15 Role-Context Switching Cost)"
Write-Host "  2. Calendar-enforced time block for this role: $($def.time_block)"
Write-Host "  3. Async-first communication (Loom / ElevenLabs for cross-role coordination)"
Write-Host "  4. Protect deep-work blocks — decline meetings that break this block"
Write-Host ""
Write-Host "Session active. ROLE_CONTEXT=$Role. Exit shell to close role session." -ForegroundColor Green
Write-Host ""

# Drop into interactive pwsh shell with env vars preserved
# User can then launch Claude Code / other tools within the role-scoped environment
pwsh -NoExit
