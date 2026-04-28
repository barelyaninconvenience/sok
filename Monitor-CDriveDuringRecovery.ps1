# C: drive continuous monitor — runs until PhotoRec PID 14092 stops or C: drops below 50GB
$photorecId = 14092
$thresholdGB = 50
$logPath = "C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\C_Monitor_20260422.log"
$null = New-Item (Split-Path $logPath) -ItemType Directory -Force -ErrorAction SilentlyContinue
$iter = 0
while ($true) {
    $iter++
    $photorec = Get-Process -Id $photorecId -ErrorAction SilentlyContinue
    $vol = Get-Volume -DriveLetter C
    $freeGB = [math]::Round($vol.SizeRemaining/1GB, 2)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $recoveryRoot = "C:\SOK_Recovery"
    $recoveryBytes = 0
    if (Test-Path $recoveryRoot) {
        $recoveryBytes = (Get-ChildItem $recoveryRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    }
    $recoveryGB = [math]::Round($recoveryBytes/1GB, 2)
    $prStatus = if ($photorec) { "RUNNING PID=$photorecId CPU=$([math]::Round($photorec.CPU,1))" } else { "STOPPED" }
    $line = "$ts | iter=$iter | C_freeGB=$freeGB | recoveryGB=$recoveryGB | photorec=$prStatus"
    Add-Content -Path $logPath -Value $line
    if ($freeGB -lt $thresholdGB) {
        $alert = "ALERT $ts — C: free dropped below ${thresholdGB}GB (=$freeGB GB). Stopping PhotoRec may be required."
        Add-Content -Path $logPath -Value $alert
        # Don't kill automatically — alert only
    }
    if (-not $photorec) {
        Add-Content -Path $logPath -Value "$ts — PhotoRec PID $photorecId no longer running. Monitor exiting."
        break
    }
    Start-Sleep -Seconds 300
}
