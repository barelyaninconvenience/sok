#Requires -Version 7.0
# Probe: does `uvx --from mcp-memory-service mcp-memory-service` resolve?

Write-Host "=== Probe: uvx mcp-memory-service --help ==="
$job = Start-Job -ScriptBlock {
    & uvx --from mcp-memory-service mcp-memory-service --help 2>&1
}
$finished = Wait-Job -Job $job -Timeout 120
if ($null -eq $finished) {
    Write-Host "STATE: STILL-RUNNING-AT-TIMEOUT (MCP server likely launched and waiting for stdin)"
    Stop-Job -Job $job -ErrorAction SilentlyContinue
} else {
    Write-Host "STATE: $($job.State)"
}
$output = Receive-Job -Job $job -Keep 2>&1 | Select-Object -First 30
foreach ($line in $output) { Write-Host "  | $line" }
Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Probe: uvx mcp-memory-service --version (alternate) ==="
$job2 = Start-Job -ScriptBlock {
    & uvx --from mcp-memory-service mcp-memory-service --version 2>&1
}
$finished2 = Wait-Job -Job $job2 -Timeout 90
if ($null -eq $finished2) {
    Write-Host "STATE: STILL-RUNNING"
    Stop-Job -Job $job2 -ErrorAction SilentlyContinue
} else {
    Write-Host "STATE: $($job2.State)"
}
$output2 = Receive-Job -Job $job2 -Keep 2>&1 | Select-Object -First 10
foreach ($line in $output2) { Write-Host "  | $line" }
Remove-Job -Job $job2 -Force -ErrorAction SilentlyContinue
