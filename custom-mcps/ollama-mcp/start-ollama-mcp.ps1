#Requires -Version 7.0
# Ollama MCP wrapper: launches the Python MCP server that wraps the local
# Ollama HTTP API (default http://localhost:11434).
#
# No credential needed — Ollama is localhost-only by default. Custom URL
# supported via env var OLLAMA_BASE_URL if Ollama runs remotely.
#
# Invoked from ~/.mcp.json:
#   "ollama": {
#     "type": "stdio",
#     "command": "pwsh",
#     "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
#              "C:\\Users\\shelc\\.ollama-mcp\\start-ollama-mcp.ps1"]
#   }
#
# Version 1.0.0 — 2026-04-21 — KLEM/OS v3 Part F custom-MCP roster

$ErrorActionPreference = 'Stop'

$scriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$bridgePackage = Join-Path $scriptDir 'ollama_mcp_server'

if (-not (Test-Path $bridgePackage)) {
    Write-Error "Python package not found at $bridgePackage"
    exit 2
}

# Default Ollama URL; override via env if remote/alternative host
if (-not $env:OLLAMA_BASE_URL) {
    $env:OLLAMA_BASE_URL = 'http://localhost:11434'
}

try {
    & uvx --from $scriptDir ollama-mcp-server
    exit $LASTEXITCODE
}
catch {
    Write-Error "Failed to launch Ollama MCP: $_"
    exit 5
}
