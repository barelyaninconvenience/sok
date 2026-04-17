#Requires -Version 7.0
# Overnight probe: admin context + process state + batch runner detection
# Non-destructive

$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$p = New-Object System.Security.Principal.WindowsPrincipal($id)
$isAdmin = $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "IsAdmin: $isAdmin"
Write-Host "UserName: $($id.Name)"
Write-Host ""

Write-Host "=== Top 15 processes by working set ==="
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 15 `
    @{n='PID';e={$_.Id}},
    @{n='WS_KB';e={[int]($_.WorkingSet/1KB)}},
    @{n='CPU_s';e={[int]$_.CPU}},
    ProcessName | Format-Table -AutoSize

Write-Host "=== pwsh process inventory ==="
$pwshProcs = Get-Process pwsh -ErrorAction SilentlyContinue
$pwshProcs | Select-Object Id, `
    @{n='WS_KB';e={[int]($_.WorkingSet/1KB)}},
    @{n='CPU_s';e={[int]$_.CPU}},
    StartTime | Format-Table -AutoSize

Write-Host "=== Memory / CPU overall ==="
$os = Get-CimInstance Win32_OperatingSystem
$totalKB = $os.TotalVisibleMemorySize
$freeKB = $os.FreePhysicalMemory
$usedKB = $totalKB - $freeKB
Write-Host "RAM: $([int]($usedKB/1024)) MB used / $([int]($totalKB/1024)) MB total ($([math]::Round($usedKB/$totalKB*100,1))%)"

Write-Host ""
Write-Host "=== Process count ==="
$all = Get-Process
Write-Host "Total processes: $($all.Count)"
Write-Host "Process count by name (top 10):"
$all | Group-Object ProcessName | Sort-Object Count -Descending | Select-Object -First 10 | Format-Table Count, Name -AutoSize
