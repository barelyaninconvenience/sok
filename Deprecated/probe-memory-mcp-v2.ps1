#Requires -Version 7.0
# Probe v2: try the three actual executable names from the mcp-memory-service package

$execs = @('mcp-memory-server', 'memory-server', 'memory')
foreach ($exe in $execs) {
    Write-Host ""
    Write-Host "=== Probe: uvx --from mcp-memory-service $exe --help ==="
    $job = Start-Job -ScriptBlock {
        param($e)
        & uvx --from mcp-memory-service $e --help 2>&1
    } -ArgumentList $exe
    $finished = Wait-Job -Job $job -Timeout 60
    if ($null -eq $finished) {
        Write-Host "STATE: STILL-RUNNING-AT-TIMEOUT (likely server waiting for stdin = SUCCESS)"
        Stop-Job -Job $job -ErrorAction SilentlyContinue
    } else {
        Write-Host "STATE: $($job.State)"
    }
    $output = Receive-Job -Job $job -Keep 2>&1 | Select-Object -First 12
    foreach ($line in $output) { Write-Host "  | $line" }
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
}
