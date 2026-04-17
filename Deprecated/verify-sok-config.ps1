#Requires -Version 7.0
try {
    $j = Get-Content 'C:/Users/shelc/Documents/Journal/Projects/scripts/config/sok-config.json' -Raw | ConvertFrom-Json
    Write-Host "JSON VALID"
    Write-Host "BloatProcesses count:     $($j.ProcessOptimizer.BloatProcesses.Count)"
    Write-Host "ProtectedProcesses count: $($j.ProcessOptimizer.ProtectedProcesses.Count)"
    Write-Host ""
    Write-Host "Bloat list preview:"
    $j.ProcessOptimizer.BloatProcesses | Select-Object -First 15 | ForEach-Object { Write-Host "  - $_" }
    Write-Host ""
    Write-Host "Protected list (for precedence reference):"
    $j.ProcessOptimizer.ProtectedProcesses | ForEach-Object { Write-Host "  - $_" }
} catch {
    Write-Host "INVALID: $($_.Exception.Message)"
    exit 1
}
