#Requires -Version 7.0
#Requires -RunAsAdministrator
# Overnight optimizer run 2026-04-14/15
# Clay's explicit ask: run the three optimizers to clear process contention
# Sequence per SOK-PRESENT header: Defender -> Process -> Service (Defender first so subsequent ops aren't throttled by AV)

$ErrorActionPreference = 'Continue'
$scriptDir = 'C:\Users\shelc\Documents\Journal\Projects\scripts'

Write-Host "================================================================"
Write-Host " Overnight SOK optimizer run $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "================================================================"

# Step 1: Identify and stop batch #4 runner if still alive
Write-Host ""
Write-Host "=== Step 1: Batch #4 runner cleanup ==="
$batchPids = Get-Process pwsh -ErrorAction SilentlyContinue | Where-Object {
    $_.StartTime -lt (Get-Date).AddMinutes(-30) -and $_.Id -ne $PID
}
if ($batchPids) {
    foreach ($proc in $batchPids) {
        Write-Host "  Stopping stale pwsh PID $($proc.Id) (started $($proc.StartTime))"
        try { Stop-Process -Id $proc.Id -Force -ErrorAction Stop } catch { Write-Host "    Stop failed: $_" }
    }
} else {
    Write-Host "  No stale pwsh procs found (batch runner either completed or already cleaned up)"
}

# Step 2: DefenderOptimizer (first so subsequent ops aren't throttled by AV scanning their work)
Write-Host ""
Write-Host "=== Step 2: SOK-DefenderOptimizer (live) ==="
$defStart = Get-Date
try {
    & "$scriptDir\SOK-DefenderOptimizer.ps1" 2>&1 | ForEach-Object { Write-Host "  $_" }
    Write-Host "  DefenderOptimizer finished in $([int]((Get-Date) - $defStart).TotalSeconds)s"
} catch {
    Write-Host "  DefenderOptimizer FAILED: $_"
}

# Step 3: ProcessOptimizer in Balanced mode (live)
Write-Host ""
Write-Host "=== Step 3: SOK-ProcessOptimizer -Mode Balanced (live) ==="
$procStart = Get-Date
try {
    & "$scriptDir\SOK-ProcessOptimizer.ps1" -Mode Balanced 2>&1 | ForEach-Object { Write-Host "  $_" }
    Write-Host "  ProcessOptimizer finished in $([int]((Get-Date) - $procStart).TotalSeconds)s"
} catch {
    Write-Host "  ProcessOptimizer FAILED: $_"
}

# Step 4: ServiceOptimizer in Auto mode (live — actually stops idle services)
Write-Host ""
Write-Host "=== Step 4: SOK-ServiceOptimizer -Action Auto (live) ==="
$svcStart = Get-Date
try {
    & "$scriptDir\SOK-ServiceOptimizer.ps1" -Action Auto 2>&1 | ForEach-Object { Write-Host "  $_" }
    Write-Host "  ServiceOptimizer finished in $([int]((Get-Date) - $svcStart).TotalSeconds)s"
} catch {
    Write-Host "  ServiceOptimizer FAILED: $_"
}

# Final state snapshot
Write-Host ""
Write-Host "=== Post-run state snapshot ==="
$os = Get-CimInstance Win32_OperatingSystem
$totalKB = $os.TotalVisibleMemorySize
$freeKB = $os.FreePhysicalMemory
$usedKB = $totalKB - $freeKB
Write-Host "RAM: $([int]($usedKB/1024)) MB used / $([int]($totalKB/1024)) MB total ($([math]::Round($usedKB/$totalKB*100,1))%)"
$allProc = Get-Process
Write-Host "Total processes: $($allProc.Count)"

Write-Host ""
Write-Host "================================================================"
Write-Host " Optimizer run complete $(Get-Date -Format 'HH:mm:ss')"
Write-Host "================================================================"
