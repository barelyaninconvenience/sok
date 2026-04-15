<#
.SYNOPSIS
    SOK-RebootClean — Run IMMEDIATELY after reboot to finish locked-file cleanup.
    Throwaway script. Run once, verify, delete.
.DESCRIPTION
    1. Fixes any junctions that failed due to locked files
    2. Cleans temp dirs that were locked by running processes
    3. Removes the persistent locked temp GUIDs
    4. Final state verification
.NOTES
    REQUIRES: Run as Administrator, IMMEDIATELY after fresh reboot (before launching apps)
    Version: 1.1.0 — 20Mar2026
#>
[CmdletBinding()]
param([switch]$DryRun)

$ErrorActionPreference = 'Continue'
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else { Write-Host "WARNING: SOK-Common not found" -ForegroundColor Yellow }

function Log { param([string]$Msg, [string]$Level = 'Ignore')
    if (Get-Command Write-SOKLog -ErrorAction SilentlyContinue) { Write-SOKLog $Msg -Level $Level }
    else { Write-Host "[$Level] $Msg" }
}

$startFree = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" ).FreeSpace / 1GB
Log "POST-REBOOT CLEANUP — C: free: $([math]::Round($startFree, 2)) GB" -Level Warn

# ═══════════════════════════════════════════════════
# 1. PERSISTENT TEMP LOCKS (the GUIDs that survive everything)
# ═══════════════════════════════════════════════════
Log "Cleaning persistent temp locks..." -Level Section
$tempDirs = @("$env:TEMP", "$env:WINDIR\Temp")
foreach ($td in $tempDirs) {
    if (-not (Test-Path $td)) { continue }
    $items = Get-ChildItem $td -Force -ErrorAction SilentlyContinue
    $beforeCount = $items.Count
    if (-not $DryRun) {
        $items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    $afterCount = (Get-ChildItem $td -Force -ErrorAction SilentlyContinue).Count
    Log "  $td — removed $($beforeCount - $afterCount) of $beforeCount items" -Level Success
}

# ═══════════════════════════════════════════════════
# 2. JUNCTION VERIFICATION & FIX
# ═══════════════════════════════════════════════════
Log "Verifying all SOK junctions..." -Level Section

$expectedJunctions = @(
    @{ Source = 'C:\Users\shelc\.pyenv';                              Target = 'E:\SOK_Offload\C_Users_shelc_.pyenv' }
    @{ Source = 'C:\Users\shelc\scoop\cache';                         Target = 'E:\SOK_Offload\C_Users_shelc_scoop_cache' }
    @{ Source = 'C:\Users\shelc\scoop\apps';                          Target = 'E:\SOK_Offload\C_Users_shelc_scoop_apps' }
    @{ Source = 'C:\Users\shelc\.nuget\packages';                     Target = 'E:\SOK_Offload\C_Users_shelc_.nuget_packages' }
    @{ Source = 'C:\Users\shelc\.cargo\registry';                     Target = 'E:\SOK_Offload\C_Users_shelc_.cargo_registry' }
    @{ Source = 'C:\Users\shelc\.vscode\extensions';                  Target = 'E:\SOK_Offload\C_Users_shelc_.vscode_extensions' }
    @{ Source = 'C:\Users\shelc\AppData\Local\JetBrains';             Target = 'E:\SOK_Offload\C_Users_shelc_AppData_Local_JetBrains' }
    @{ Source = 'C:\tools\flutter';                                    Target = 'E:\SOK_Offload\C_tools_flutter' }
    @{ Source = 'C:\Program Files\JetBrains';                          Target = 'E:\SOK_Offload\C_Program Files_JetBrains' }
    @{ Source = 'C:\ProgramData\chocolatey\lib';                       Target = 'E:\SOK_Offload\C_ProgramData_chocolatey_lib' }
    @{ Source = 'C:\Users\shelc\AppData\Local\Microsoft\WinGet\Packages'; Target = 'E:\SOK_Offload\C_Users_shelc_AppData_Local_Microsoft_WinGet_Packages' }
    @{ Source = 'C:\Users\shelc\scoop\persist\rustup\.cargo\registry'; Target = 'E:\SOK_Offload\C_Users_shelc_scoop_persist_rustup_.cargo_registry' }
    @{ Source = 'C:\Hadoop';                                           Target = 'E:\SOK_Offload\C_Hadoop' }
    @{ Source = 'C:\Strawberry';                                       Target = 'E:\SOK_Offload\C_Strawberry' }
    @{ Source = 'C:\influxdata';                                       Target = 'E:\SOK_Offload\C_influxdata' }
    @{ Source = 'C:\gitlab-runner';                                    Target = 'E:\SOK_Offload\C_gitlab-runner' }
    @{ Source = 'C:\CocosDashboard';                                   Target = 'E:\SOK_Offload\C_CocosDashboard' }
    @{ Source = 'C:\Users\shelc\AppData\Local\Google\Chrome\User Data\Default\Cache'; Target = 'E:\SOK_Offload\C_Users_shelc_AppData_Local_Google_Chrome_User Data_Default_Cache' }
)

$okCount = 0; $fixCount = 0; $failCount = 0
foreach ($j in $expectedJunctions) {
    $item = Get-Item $j.Source -ErrorAction SilentlyContinue
    if ($item -and $item.Attributes -match 'ReparsePoint') {
        $okCount++
        continue
    }

    # Junction missing or source is a real directory — attempt fix
    Log "  MISSING JUNCTION: $($j.Source)" -Level Warn
    if (-not $DryRun) {
        if (Test-Path $j.Source) {
            # Handle scoop-style internal junctions
            $internalJunctions = Get-ChildItem $j.Source -Recurse -Directory -Force -ErrorAction SilentlyContinue |
                Where-Object { $_.Attributes -match 'ReparsePoint' }
            foreach ($ij in $internalJunctions) {
                cmd /c "rmdir `"$($ij.FullName)`"" 2>$null
            }
            Remove-Item $j.Source -Recurse -Force -ErrorAction Continue
        }
        if (-not (Test-Path $j.Source)) {
            # Ensure parent exists
            $parent = Split-Path $j.Source -Parent
            if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }
            cmd /c "mklink /J `"$($j.Source)`" `"$($j.Target)`"" 2>$null
            if ((Get-Item $j.Source -ErrorAction SilentlyContinue).Attributes -match 'ReparsePoint') {
                Log "  FIXED: $($j.Source)" -Level Success
                $fixCount++
            } else {
                Log "  FAILED: $($j.Source)" -Level Error
                $failCount++
            }
        } else {
            Log "  STILL LOCKED: $($j.Source) — files still in use" -Level Error
            $failCount++
        }
    }
}

Log "Junctions: $okCount OK, $fixCount fixed, $failCount failed" -Level $(if ($failCount -eq 0) { 'Success' } else { 'Warn' })

# ═══════════════════════════════════════════════════
# 3. JetBrains ETW Host — only killable after reboot
# ═══════════════════════════════════════════════════
$jbEtw = 'C:\Program Files\JetBrains'
if ((Test-Path $jbEtw) -and -not ((Get-Item $jbEtw).Attributes -match 'ReparsePoint')) {
    Log "JetBrains ETW Host: still a real directory — attempting post-reboot fix" -Level Warn
    if (-not $DryRun) {
        Get-Service *JetBrains* -ErrorAction SilentlyContinue | Stop-Service -Force -ErrorAction Continue
        Get-Process *JetBrains* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Continue
        Start-Sleep 2
        Remove-Item $jbEtw -Recurse -Force -ErrorAction Continue
        if (-not (Test-Path $jbEtw)) {
            cmd /c "mklink /J `"$jbEtw`" `"E:\SOK_Offload\C_Program Files_JetBrains`"" 2>$null
            Log "JetBrains junction created after reboot" -Level Success
        }
    }
}

# ═══════════════════════════════════════════════════
# 4. FINAL STATE
# ═══════════════════════════════════════════════════
$endFree = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" ).FreeSpace / 1GB
$gained = $endFree - $startFree

Log " " -Level Section
Log "REBOOT CLEANUP COMPLETE" -Level Section
Log "  C: free:   $([math]::Round($endFree, 2)) GB" -Level $(if ($endFree -gt 200) { 'Success' } else { 'Warn' })
Log "  Gained:    $([math]::Round($gained, 2)) GB (post-reboot)" -Level Ignore
Log "  Junctions: $okCount OK + $fixCount fixed = $($okCount + $fixCount) working" -Level Success

# Quick tool verification
Log " " -Level Ignore
Log "Tool verification:" -Level Section
$tools = @(
    @{ Name = 'Scoop';  Cmd = 'scoop --version' }
    @{ Name = 'Choco';  Cmd = 'choco --version' }
    @{ Name = 'Rust';   Cmd = 'rustc --version' }
    @{ Name = 'Node';   Cmd = 'node --version' }
    @{ Name = 'Python'; Cmd = 'python --version' }
    @{ Name = 'Git';    Cmd = 'git --version' }
    @{ Name = 'Dotnet'; Cmd = 'dotnet --version' }
)
foreach ($tool in $tools) {
    try {
        $ver = Invoke-Expression $tool.Cmd 2>&1
        if ($LASTEXITCODE -eq 0 -or $ver -match '\d+\.\d+') {
            Log "  $($tool.Name): $($ver -join ' ' | Select-Object -First 1)" -Level Success
        } else { Log "  $($tool.Name): ERROR — $ver" -Level Error }
    } catch { Log "  $($tool.Name): NOT FOUND" -Level Error }
}

Log " " -Level Ignore
Log "Ready to swap E: for recovery NVMe." -Level Success
