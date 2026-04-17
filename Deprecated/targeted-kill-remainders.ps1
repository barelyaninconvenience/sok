#Requires -Version 7.0
#Requires -RunAsAdministrator
# Overnight targeted kill of the protected-by-design items Clay listed as non-essential
# (malwarebytes, waves). The SOK-ProcessOptimizer spared these via the Security/AudioVideo
# categories. Clay's full authorization covers this.

$ErrorActionPreference = 'Continue'

Write-Host "=== Pre-kill inventory ==="
$targetNames = @('mbamservice', 'mbamtray', 'malwarebytes', 'MBAMServices', 'WavesSysSvc64', 'WavesSvc64', 'wavesaudioservice', 'Waves')
foreach ($name in $targetNames) {
    $found = Get-Process -Name $name -ErrorAction SilentlyContinue
    foreach ($p in $found) {
        Write-Host ("  Found: {0} (PID {1}, {2} MB)" -f $p.ProcessName, $p.Id, [int]($p.WorkingSet / 1MB))
    }
}

Write-Host ""
Write-Host "=== Broader name scan ==="
$pattern = 'mbam|malware|waves|squid|fnp'
$scan = Get-Process | Where-Object { $_.ProcessName -match "(?i)$pattern" }
foreach ($p in $scan) {
    Write-Host ("  Matched '$pattern': {0} (PID {1}, {2} MB)" -f $p.ProcessName, $p.Id, [int]($p.WorkingSet / 1MB))
}

Write-Host ""
Write-Host "=== Kill attempts ==="
foreach ($p in $scan) {
    try {
        Stop-Process -Id $p.Id -Force -ErrorAction Stop
        Write-Host ("  Killed: {0} (PID {1})" -f $p.ProcessName, $p.Id)
    } catch {
        Write-Host ("  Failed:  {0} (PID {1}) — {2}" -f $p.ProcessName, $p.Id, $_.Exception.Message)
    }
}

Write-Host ""
Write-Host "=== Final state ==="
$os = Get-CimInstance Win32_OperatingSystem
$totalKB = $os.TotalVisibleMemorySize
$freeKB = $os.FreePhysicalMemory
$usedKB = $totalKB - $freeKB
Write-Host "RAM: $([int]($usedKB/1024)) MB used / $([int]($totalKB/1024)) MB total ($([math]::Round($usedKB/$totalKB*100,1))%)"
$all = Get-Process
Write-Host "Total processes: $($all.Count)"
