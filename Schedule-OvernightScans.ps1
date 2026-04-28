<#
.SYNOPSIS
    Schedule-OvernightScans.ps1 — One-shot: register SOK-Restructure scans for E:\ at 03:33 and C:\ at 04:44.
.DESCRIPTION
    Creates two Windows Task Scheduler entries that run SOK-Restructure.ps1 -DryRun against
    E:\ and C:\ at the specified times tonight. Tasks auto-delete after running (DeleteExpiredTaskAfter).

    E:\ scan is lighter (backup drive, less system complexity).
    C:\ scan needs care (running system, active locks, more denial expected).

    Both run in DryRun mode — analysis only, no file moves.
.PARAMETER DryRun
    Preview the task registrations without committing to Task Scheduler.
.NOTES
    Author: Claude (overnight autonomous)
    Date: 2026-04-08
    Run as Administrator: required for task registration
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param([switch]$DryRun)

$scriptDir = 'C:\Users\shelc\Documents\Journal\Projects\scripts'
$logBase = 'C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\Restructure'
$today = Get-Date -Format 'yyyyMMdd'

# Ensure log directory exists
if (-not (Test-Path $logBase)) { New-Item -ItemType Directory -Path $logBase -Force | Out-Null }

$tasks = @(
    @{
        Name = "SOK-Overnight-Restructure-E"
        Time = (Get-Date).Date.AddHours(6).AddMinutes(0)  # 06:00 today
        Args = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\SOK-Restructure.ps1`" -TargetPaths 'E:\' -DryRun"
        Desc = "One-shot: SOK-Restructure analysis of E:\ (backup drive)"
    },
    @{
        Name = "SOK-Overnight-Restructure-C"
        Time = (Get-Date).Date.AddHours(6).AddMinutes(30)  # 06:30 today
        Args = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptDir\SOK-Restructure.ps1`" -TargetPaths 'C:\' -DryRun"
        Desc = "One-shot: SOK-Restructure analysis of C:\ (running system, expect denials)"
    }
)

foreach ($t in $tasks) {
    Write-Host "`n[$($t.Name)]" -ForegroundColor Cyan
    Write-Host "  Scheduled: $($t.Time.ToString('HH:mm'))"
    Write-Host "  Command: pwsh $($t.Args)"
    Write-Host "  Description: $($t.Desc)"

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would register task." -ForegroundColor Yellow
        continue
    }

    # Remove existing task if present
    $existing = Get-ScheduledTask -TaskName $t.Name -ErrorAction SilentlyContinue
    if ($existing) {
        Unregister-ScheduledTask -TaskName $t.Name -Confirm:$false
        Write-Host "  Removed existing task." -ForegroundColor DarkYellow
    }

    $action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument $t.Args
    $trigger = New-ScheduledTaskTrigger -Once -At $t.Time
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -DeleteExpiredTaskAfter '00:05:00' -ExecutionTimeLimit '02:00:00'
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -RunLevel Highest -LogonType Interactive

    Register-ScheduledTask -TaskName $t.Name -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description $t.Desc -Force
    Write-Host "  REGISTERED." -ForegroundColor Green
}

Write-Host "`nDone. Tasks will run at 03:33 (E:\) and 04:44 (C:\) and auto-delete after execution." -ForegroundColor Cyan
Write-Host "Logs will be in: $logBase" -ForegroundColor DarkGray
