#Requires -Version 7.0
# Probe: memory server subcommand (the actual stdio entry point)

Write-Host "=== uvx --from mcp-memory-service memory server --help ==="
$job = Start-Job -ScriptBlock {
    & uvx --from mcp-memory-service memory server --help 2>&1
}
$finished = Wait-Job -Job $job -Timeout 60
if ($null -eq $finished) {
    Write-Host "STATE: STILL-RUNNING (likely launched stdio server)"
    Stop-Job -Job $job -ErrorAction SilentlyContinue
} else {
    Write-Host "STATE: $($job.State)"
}
$output = Receive-Job -Job $job -Keep 2>&1 | Select-Object -First 40
foreach ($line in $output) { Write-Host "  | $line" }
Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== uvx --from mcp-memory-service memory --help ==="
$job2 = Start-Job -ScriptBlock {
    & uvx --from mcp-memory-service memory --help 2>&1
}
Wait-Job -Job $job2 -Timeout 30 | Out-Null
$output2 = Receive-Job -Job $job2 -Keep 2>&1 | Select-Object -First 30
foreach ($line in $output2) { Write-Host "  | $line" }
Remove-Job -Job $job2 -Force -ErrorAction SilentlyContinue
