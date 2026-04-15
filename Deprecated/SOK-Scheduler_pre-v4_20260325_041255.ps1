<#
.SYNOPSIS
    SOK-Scheduler.ps1 — Configure Windows Task Scheduler for automated SOK runs.

.DESCRIPTION
    Creates scheduled tasks for:
    - SOK-Inventory: 3:00 AM daily (read-only scan)
    - SOK-Maintenance: 4:00 AM daily (Quick mode by default)
    
    Tasks run as SYSTEM with highest privileges, allow battery operation,
    and have a 2-hour execution time limit.

.PARAMETER ScriptDirectory
    Path where SOK scripts live. Defaults to the parent of this script's directory.

.PARAMETER MaintenanceMode
    Mode for the automated maintenance run. Default: Quick (safest for unattended).

.PARAMETER Remove
    Remove existing SOK scheduled tasks instead of creating them.

.NOTES
    Author: S. Clay Caddell
    Version: 1.0.0 (SOK canonical — replaces TITAN-Scheduler)
    Date: March 2026
#>

[CmdletBinding()]
param(
    [string]$ScriptDirectory,
    [ValidateSet('Quick', 'Standard', 'Deep')]
    [string]$MaintenanceMode = 'Quick',
    [switch]$Remove
)

#Requires -RunAsAdministrator

$modulePath = "C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1"
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

if (-not $ScriptDirectory) {
    $ScriptDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) 'scripts'
    if (-not (Test-Path $ScriptDirectory)) { $ScriptDirectory = $PSScriptRoot }
}

$inventoryScript = Join-Path $ScriptDirectory 'SOK-Inventory.ps1'
$maintenanceScript = Join-Path $ScriptDirectory 'SOK-Maintenance.ps1'

$taskPrefix = 'SOK'

Write-Host "`n━━━ SOK TASK SCHEDULER ━━━" -ForegroundColor Cyan
Write-Host "Script directory: $ScriptDirectory" -ForegroundColor Gray

# Remove mode
if ($Remove) {
    Write-Host "`nRemoving SOK scheduled tasks..." -ForegroundColor Yellow
    Get-ScheduledTask -TaskName "${taskPrefix}-*" -ErrorAction Continue | ForEach-Object {
        Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false
        Write-Host "  Removed: $($_.TaskName)" -ForegroundColor Green
    }
    Write-Host "Done." -ForegroundColor Green
    exit
}

# Validate scripts exist
foreach ($script in @($inventoryScript, $maintenanceScript)) {
    if (-not (Test-Path $script)) {
        Write-Warning "Script not found: $script"
        Write-Host "Ensure SOK scripts are in: $ScriptDirectory" -ForegroundColor Yellow
        exit 1
    }
}

# Detect PowerShell executable (prefer pwsh over powershell)
$pwshExe = if (Get-Command pwsh -ErrorAction Continue) { 'pwsh.exe' } else { 'powershell.exe' }

# Shared settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -Priority 4 `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2)

# Task 1: Inventory (3:00 AM)
Write-Host "`n[1/2] Inventory task (3:00 AM daily)..." -ForegroundColor Cyan

$action1 = New-ScheduledTaskAction `
    -Execute $pwshExe `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$inventoryScript`""

$trigger1 = New-ScheduledTaskTrigger -Daily -At 3:00AM

Register-ScheduledTask `
    -TaskName "${taskPrefix}-Daily-Inventory" `
    -Action $action1 `
    -Trigger $trigger1 `
    -Settings $settings `
    -User 'SYSTEM' `
    -RunLevel Highest `
    -Force | Out-Null

Write-Host "  Created: ${taskPrefix}-Daily-Inventory (3:00 AM)" -ForegroundColor Green

# Task 2: Maintenance (4:00 AM)
Write-Host "[2/2] Maintenance task (4:00 AM daily, $MaintenanceMode mode)..." -ForegroundColor Cyan

$action2 = New-ScheduledTaskAction `
    -Execute $pwshExe `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$maintenanceScript`" -Mode $MaintenanceMode"

$trigger2 = New-ScheduledTaskTrigger -Daily -At 4:00AM

Register-ScheduledTask `
    -TaskName "${taskPrefix}-Daily-Maintenance" `
    -Action $action2 `
    -Trigger $trigger2 `
    -Settings $settings `
    -User 'SYSTEM' `
    -RunLevel Highest `
    -Force | Out-Null

Write-Host "  Created: ${taskPrefix}-Daily-Maintenance (4:00 AM, $MaintenanceMode)" -ForegroundColor Green

# Verify
Write-Host "`n━━━ VERIFICATION ━━━" -ForegroundColor Cyan
Get-ScheduledTask -TaskName "${taskPrefix}-*" -ErrorAction Continue | ForEach-Object {
    $info = Get-ScheduledTaskInfo -TaskName $_.TaskName -ErrorAction Continue
    $nextRun = if ($info.NextRunTime) { $info.NextRunTime.ToString('yyyy-MM-dd HH:mm') } else { 'N/A' }
    Write-Host "  $($_.TaskName.PadRight(30)) State: $($_.State.ToString().PadRight(10)) Next: $nextRun" -ForegroundColor $(
        if ($_.State -eq 'Ready') { 'Green' } else { 'Yellow' }
    )
}

Write-Host "`nManual run commands:" -ForegroundColor Yellow
Write-Host "  $pwshExe -File `"$inventoryScript`"" -ForegroundColor Gray
Write-Host "  $pwshExe -File `"$maintenanceScript`" -Mode Standard" -ForegroundColor Gray
Write-Host "  Abort reboot: shutdown /a" -ForegroundColor DarkGray
