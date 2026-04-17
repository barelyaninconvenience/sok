#Requires -Version 7.0
# Probe script for overnight MCP verification work 2026-04-14
# Tests whether each of the 4 "broken" MCP commands actually resolves + launches
# Every probe is bounded by a job timeout so nothing hangs forever
# Non-destructive: no file edits, no state change; just tries to start each command

function Probe-Command {
    param(
        [string]$Label,
        [scriptblock]$Command,
        [int]$TimeoutSec = 20
    )
    Write-Host ""
    Write-Host "=== $Label ==="
    $job = Start-Job -ScriptBlock $Command
    $finished = Wait-Job -Job $job -Timeout $TimeoutSec
    if ($null -eq $finished) {
        Write-Host "STATE: STILL-RUNNING-AT-TIMEOUT (likely stdio MCP server waiting for input = SUCCESS)"
        Stop-Job -Job $job -ErrorAction SilentlyContinue
    } else {
        Write-Host "STATE: $($job.State)"
    }
    $output = Receive-Job -Job $job -Keep 2>&1 | Select-Object -First 15
    foreach ($line in $output) { Write-Host "  | $line" }
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
}

Write-Host "================================================================"
Write-Host " MCP command probe run $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "================================================================"

# Probe 1: uvx binary exists and responds
Probe-Command -Label "uvx --version" -TimeoutSec 10 -Command { & uvx --version 2>&1 }

# Probe 2: uvx workspace-mcp — package resolution test
# If this works, it'll either print help or launch and hang waiting for stdin
Probe-Command -Label "uvx workspace-mcp --help" -TimeoutSec 30 -Command {
    $env:OAUTHLIB_INSECURE_TRANSPORT = "1"
    & uvx workspace-mcp --help 2>&1
}

# Probe 3: npx full-path filesystem
Probe-Command -Label "npx filesystem --help" -TimeoutSec 45 -Command {
    $env:NODE_NO_WARNINGS = "1"
    & "C:\Program Files\nodejs\npx.cmd" -y "@modelcontextprotocol/server-filesystem" --help 2>&1
}

# Probe 4: npx full-path puppeteer (no --help, will likely just launch)
Probe-Command -Label "npx puppeteer --help" -TimeoutSec 45 -Command {
    $env:NODE_NO_WARNINGS = "1"
    & "C:\Program Files\nodejs\npx.cmd" -y "@modelcontextprotocol/server-puppeteer" --help 2>&1
}

# Probe 5: npx full-path doobidoo/mcp-memory-service
Probe-Command -Label "npx memory --help" -TimeoutSec 60 -Command {
    $env:NODE_NO_WARNINGS = "1"
    & "C:\Program Files\nodejs\npx.cmd" -y "@doobidoo/mcp-memory-service" --help 2>&1
}

# Probe 6: bare cmd /c npx (the currently-broken pattern) — verify it IS broken
Probe-Command -Label "cmd /c npx filesystem (current broken pattern)" -TimeoutSec 20 -Command {
    & cmd /c npx -y "@modelcontextprotocol/server-filesystem" --help 2>&1
}

Write-Host ""
Write-Host "================================================================"
Write-Host " Probe run complete"
Write-Host "================================================================"
