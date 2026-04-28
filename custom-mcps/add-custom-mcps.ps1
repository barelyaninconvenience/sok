#Requires -Version 7.0
<#
.SYNOPSIS
  Helper to register the v3 Part F custom MCPs into ~/.mcp.json or ~/.claude.json.

.DESCRIPTION
  Generates the JSON block for all 6 scaffolded custom MCPs (exa / supabase /
  ollama / unstructured / n8n-control / gamma) assuming they've been deployed
  to ~/.<name>-mcp/ production locations.

  Does NOT modify .mcp.json automatically — prints the block for Clay to paste
  manually (safer than risking corruption of the hand-curated config).

  Optional -DryRun mode prints the block; -ShowExisting reads current ~/.mcp.json
  and shows which entries already exist.

.PARAMETER ShowExisting
  Read current ~/.mcp.json and report which custom MCPs are already registered.

.PARAMETER OnlyMcp
  Restrict output to a single named MCP (e.g., 'exa', 'supabase').

.EXAMPLE
  .\add-custom-mcps.ps1
  # Prints the full block for all 6 custom MCPs

.EXAMPLE
  .\add-custom-mcps.ps1 -ShowExisting
  # Reports current .mcp.json registration status

.EXAMPLE
  .\add-custom-mcps.ps1 -OnlyMcp exa
  # Prints only the exa MCP block

.NOTES
  Version 1.0.0 — 2026-04-21 — KLEM/OS v3 Part F deployment helper
#>

param(
    [switch]$ShowExisting,
    [string]$OnlyMcp = ''
)

$mcpDefinitions = @{
    'exa' = @{
        Type         = 'stdio'
        LauncherPath = 'C:\Users\shelc\.exa-mcp\start-exa-mcp.ps1'
        Purpose      = 'Exa semantic web search (replaces plaintext-key HTTP config)'
        Priority     = 'P1'
    }
    'supabase' = @{
        Type         = 'stdio'
        LauncherPath = 'C:\Users\shelc\.supabase-mcp\start-supabase-mcp.ps1'
        Purpose      = 'L1 data access (knowledge_assets / chunks / projects / session_logs + pgvector)'
        Priority     = 'P1'
    }
    'ollama' = @{
        Type         = 'stdio'
        LauncherPath = 'C:\Users\shelc\.ollama-mcp\start-ollama-mcp.ps1'
        Purpose      = 'L3 local inference fallback (localhost Ollama)'
        Priority     = 'P3'
    }
    'unstructured' = @{
        Type         = 'stdio'
        LauncherPath = 'C:\Users\shelc\.unstructured-mcp\start-unstructured-mcp.ps1'
        Purpose      = 'L2 document parsing (PDF/DOCX/PPTX/HTML/OCR/email)'
        Priority     = 'P3'
    }
    'n8n-control' = @{
        Type         = 'stdio'
        LauncherPath = 'C:\Users\shelc\.n8n-control-mcp\start-n8n-control-mcp.ps1'
        Purpose      = 'L4 n8n workflow control from Claude Code'
        Priority     = 'P2'
    }
    'gamma' = @{
        Type         = 'stdio'
        LauncherPath = 'C:\Users\shelc\.gamma-mcp\start-gamma-mcp.ps1'
        Purpose      = 'L5 Gamma presentation generation (beta API)'
        Priority     = 'P2'
    }
}

function Format-McpBlock {
    param([string]$Name, [hashtable]$Def)
    # 2026-04-22 polish: renamed local var $args → $argArray to avoid shadowing
    # PowerShell's $args automatic variable. Functional behavior unchanged (named
    # params prevent access to $args here), but aesthetically cleaner.
    $argArray = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Def.LauncherPath) | ForEach-Object { '"' + ($_ -replace '\\', '\\') + '"' }
    return @"
    "$Name": {
      "type": "$($Def.Type)",
      "command": "pwsh",
      "args": [$($argArray -join ', ')]
    }
"@
}

if ($ShowExisting) {
    $mcpJson = "$env:USERPROFILE\.mcp.json"
    if (-not (Test-Path $mcpJson)) {
        Write-Host "~/.mcp.json not found at $mcpJson" -ForegroundColor Yellow
        exit 1
    }
    try {
        $current = Get-Content $mcpJson -Raw | ConvertFrom-Json
        $existingNames = @()
        if ($current.mcpServers) {
            $existingNames = $current.mcpServers.PSObject.Properties.Name
        }

        Write-Host "=== Current ~/.mcp.json registered MCPs ===" -ForegroundColor Cyan
        foreach ($n in $existingNames) {
            Write-Host "  [PRESENT]  $n"
        }

        Write-Host "`n=== v3 Part F custom MCPs status ===" -ForegroundColor Cyan
        foreach ($kvp in $mcpDefinitions.GetEnumerator() | Sort-Object { $_.Value.Priority + $_.Key }) {
            $status = if ($existingNames -contains $kvp.Key) { '[PRESENT]' } else { '[MISSING]' }
            $color = if ($existingNames -contains $kvp.Key) { 'Green' } else { 'Yellow' }
            Write-Host ("  {0,-10}  {1,-14}  {2,-4}  {3}" -f $status, $kvp.Key, $kvp.Value.Priority, $kvp.Value.Purpose) -ForegroundColor $color
        }
    } catch {
        Write-Host "Failed to parse ~/.mcp.json: $_" -ForegroundColor Red
        exit 2
    }
    exit 0
}

# Output mode: print JSON block for paste
if ($OnlyMcp) {
    if (-not $mcpDefinitions.ContainsKey($OnlyMcp)) {
        Write-Host "Unknown MCP: $OnlyMcp" -ForegroundColor Red
        Write-Host "Known: $($mcpDefinitions.Keys -join ', ')"
        exit 1
    }
    Write-Host "// Paste into ~/.mcp.json mcpServers block:"
    Write-Host (Format-McpBlock -Name $OnlyMcp -Def $mcpDefinitions[$OnlyMcp])
    exit 0
}

Write-Host "// v3 Part F custom-MCP roster — paste into ~/.mcp.json mcpServers block"
Write-Host "// Prerequisites:"
Write-Host "//   1. Each ~/.<name>-mcp/ production directory deployed"
Write-Host "//   2. Each MCP's required DPAPI secret stored via Set-SOKSecret"
Write-Host "//   3. uvx available on PATH"
Write-Host ""
Write-Host "{"
Write-Host "  `"mcpServers`": {"

$first = $true
foreach ($kvp in $mcpDefinitions.GetEnumerator() | Sort-Object { $_.Value.Priority + $_.Key }) {
    if (-not $first) { Write-Host "," }
    $first = $false
    Write-Host ("    // Priority {0}: {1}" -f $kvp.Value.Priority, $kvp.Value.Purpose)
    Write-Host (Format-McpBlock -Name $kvp.Key -Def $kvp.Value) -NoNewline
}
Write-Host ""
Write-Host "  }"
Write-Host "}"
Write-Host ""
Write-Host "// Deprecation candidates (per MCP audit 2026-04-21):"
Write-Host "//   - Remove 'puppeteer' from ~/.mcp.json (claude-in-chrome displaces)"
Write-Host "//   - Remove duplicate google_workspace from .claude.json top-level (workspace-mcp authoritative)"
Write-Host "//   - Remove google_workspace from ~/.claude/claude_desktop_config.json (pre-convergence)"
Write-Host "//   - Remove exa HTTP config from .claude.json top-level AFTER deploying exa stdio MCP"
