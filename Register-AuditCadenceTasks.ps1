#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    Register SOK audit cadence scheduled tasks (ENDEAVOR Loop — Weekly / Monthly / Quarterly / Annual + Recursive Reinvigoration).

.DESCRIPTION
    Helper to register the recurring audit cadence per Master_Log_Audit_Cadence_20260424.md.
    Run ONCE (with admin elevation) to register all tasks; thereafter they fire automatically.

    Tasks registered:
      - SOK-Weekly-Audit          : Sunday 18:17         → SOK-WeeklyAudit.ps1
      - SOK-Monthly-Audit         : 1st of month 09:23   → SOK-MonthlyAudit.ps1
      - SOK-Quarterly-Audit       : 1st of quarter 09:23 → SOK-QuarterlyAudit.ps1  (Jan/Apr/Jul/Oct)
      - SOK-Annual-Audit          : Jan 1 09:23          → SOK-AnnualAudit.ps1
      - SOK-Recursive-Reinvig     : Sunday 03:17         → SOK-RecursiveReinvigoration.ps1

    Quarterly + Annual tasks still require Clay-pen execution during the triggered Claude session
    (they require interpretive judgment that warrants attention). The scheduled task's role is to
    write a dated notification into Writings/Scheduled_Audit_Inbox/ which Clay's next session
    cold-start will surface.

    Recursive Reinvigoration (.claude/ sweep for insight-propagation) similarly writes a dated
    notification for next-session pickup.

.PARAMETER DryRun
    Print the commands that would be executed without registering tasks.

.PARAMETER Unregister
    Remove the audit cadence tasks instead of registering.

.PARAMETER OnlyTask
    Register only the named task (e.g., 'Weekly', 'Monthly', 'Quarterly', 'Annual', 'Reinvigoration').
    Default: all five.

.EXAMPLE
    pwsh -File Register-AuditCadenceTasks.ps1 -DryRun

.EXAMPLE
    # Actually register all five (admin elevation required)
    pwsh -File Register-AuditCadenceTasks.ps1

.EXAMPLE
    # Register only the quarterly audit
    pwsh -File Register-AuditCadenceTasks.ps1 -OnlyTask Quarterly

.EXAMPLE
    # Remove all tasks
    pwsh -File Register-AuditCadenceTasks.ps1 -Unregister

.NOTES
    Author: Shelby Clay Caddell with Claude Opus 4.7
    Created: 2026-04-24
    Extended: 2026-04-24 late evening — added Quarterly + Annual + Recursive Reinvigoration coverage
    Anchored to: Writings/Master_Log_Audit_Cadence_20260424.md + memory/protocol_endeavor.md + memory/protocol_reconcile.md
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Unregister,
    [ValidateSet('All','Weekly','Monthly','Quarterly','Annual','Reinvigoration')]
    [string]$OnlyTask = 'All'
)

$ErrorActionPreference = 'Stop'
$ScriptsRoot = "C:\Users\shelc\Documents\Journal\Projects\scripts"
$WeeklyScript            = "$ScriptsRoot\SOK-WeeklyAudit.ps1"
$MonthlyScript           = "$ScriptsRoot\SOK-MonthlyAudit.ps1"
$QuarterlyScript         = "$ScriptsRoot\SOK-QuarterlyAudit.ps1"
$AnnualScript            = "$ScriptsRoot\SOK-AnnualAudit.ps1"
$ReinvigorationScript    = "$ScriptsRoot\SOK-RecursiveReinvigoration.ps1"

# Verify scripts exist (create stubs for missing ones if -Force-style scaffolding allowed via env)
$missingScripts = @()
foreach ($scriptInfo in @(
    @{ Name='Weekly';         Path=$WeeklyScript         },
    @{ Name='Monthly';        Path=$MonthlyScript        },
    @{ Name='Quarterly';      Path=$QuarterlyScript      },
    @{ Name='Annual';         Path=$AnnualScript         },
    @{ Name='Reinvigoration'; Path=$ReinvigorationScript }
)) {
    if (-not (Test-Path $scriptInfo.Path)) {
        $missingScripts += $scriptInfo
    }
}

if ($missingScripts.Count -gt 0 -and -not $Unregister) {
    Write-Warning "The following audit scripts do not exist yet:"
    $missingScripts | ForEach-Object { Write-Warning "  - $($_.Name): $($_.Path)" }
    Write-Warning ""
    Write-Warning "Quarterly + Annual + Reinvigoration scripts are stub-generator-pending. Their task registrations"
    Write-Warning "will still be created, but the tasks will fail at fire time until the scripts are authored."
    Write-Warning ""
    Write-Warning "Companion scaffolding task: author SOK-QuarterlyAudit.ps1 / SOK-AnnualAudit.ps1 /"
    Write-Warning "SOK-RecursiveReinvigoration.ps1 using the Weekly/Monthly audit scripts as templates."
    Write-Warning "Expected behavior: each writes a dated notification to Writings/Scheduled_Audit_Inbox/"
    Write-Warning "which Clay's next session cold-start surfaces."
    Write-Warning ""
}

$taskDefinitions = @{
    'Weekly' = @{
        TaskName    = 'SOK-Weekly-Audit'
        Description = 'Weekly audit of past 7 days'' session activity. Drafts Writings/Weekly_Audits/Weekly_Audit_<YYYY-WW>.md. Single-layer-deep per ENDEAVOR Loop.'
        Script      = $WeeklyScript
        TriggerFunc = {
            New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "6:17PM"
        }
    }
    'Monthly' = @{
        TaskName    = 'SOK-Monthly-Audit'
        Description = 'Monthly audit on 1st of month. Aggregates 4 weekly audits into Writings/Monthly_Audits/Monthly_Audit_<YYYY-MM>.md. Single-layer-deep per ENDEAVOR Loop.'
        Script      = $MonthlyScript
        TriggerFunc = {
            New-CimInstance -CimClass (Get-CimClass MSFT_TaskMonthlyTrigger -Namespace ROOT\Microsoft\Windows\TaskScheduler) -ClientOnly -Property @{
                DaysOfMonth   = 1
                StartBoundary = (Get-Date -Hour 9 -Minute 23 -Second 0).ToString('s')
                Enabled       = $true
            }
        }
    }
    'Quarterly' = @{
        TaskName    = 'SOK-Quarterly-Audit'
        Description = 'Quarterly audit on 1st of quarter (Jan/Apr/Jul/Oct). Aggregates 3 monthly audits into Writings/Quarterly_Audits/Quarterly_Audit_<YYYY-Q>.md + Master_Log delta. Also fires Publication+IP Audit per Clay 2026-04-24 directive. Trigger fires monthly on the 1st; SOK-QuarterlyAudit.ps1 has a month-of-year guard that no-ops on non-Jan/Apr/Jul/Oct fires.'
        Script      = $QuarterlyScript
        TriggerFunc = {
            # Fires on 1st of every month; script itself guards for Jan/Apr/Jul/Oct only
            New-CimInstance -CimClass (Get-CimClass MSFT_TaskMonthlyTrigger -Namespace ROOT\Microsoft\Windows\TaskScheduler) -ClientOnly -Property @{
                DaysOfMonth   = 1
                StartBoundary = (Get-Date -Hour 9 -Minute 23 -Second 0).ToString('s')
                Enabled       = $true
            }
        }
    }
    'Annual' = @{
        TaskName    = 'SOK-Annual-Audit'
        Description = 'Annual audit on Jan 1. Aggregates 4 quarterly audits into Writings/Annual_Audits/Annual_Audit_<YYYY>.md + regenerates Master_Log_<YYYY>.md (previous year to Deprecated/). Trigger fires monthly on the 1st; SOK-AnnualAudit.ps1 has a month-of-year guard that no-ops on non-January fires.'
        Script      = $AnnualScript
        TriggerFunc = {
            # Fires on 1st of every month; script itself guards for January only
            New-CimInstance -CimClass (Get-CimClass MSFT_TaskMonthlyTrigger -Namespace ROOT\Microsoft\Windows\TaskScheduler) -ClientOnly -Property @{
                DaysOfMonth   = 1
                StartBoundary = (Get-Date -Hour 9 -Minute 23 -Second 0).ToString('s')
                Enabled       = $true
            }
        }
    }
    'Reinvigoration' = @{
        TaskName    = 'SOK-Recursive-Reinvig'
        Description = '.claude/ recursive reinvigoration sweep: propagate week''s insights across affected memory/writings/case_studies/theory artifacts. Produces Writings/Recursive_Reinvigoration_<YYYY-WW>.md with propagation actions taken + candidates for next week.'
        Script      = $ReinvigorationScript
        TriggerFunc = {
            New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "3:17AM"
        }
    }
}

$selectedTasks = if ($OnlyTask -eq 'All') { $taskDefinitions.Keys } else { @($OnlyTask) }

if ($Unregister) {
    Write-Output "=== Unregistering audit cadence tasks ==="
    foreach ($key in $selectedTasks) {
        $taskName = $taskDefinitions[$key].TaskName
        $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($existing) {
            if ($DryRun) {
                Write-Output "  DRY RUN: would Unregister-ScheduledTask -TaskName '$taskName'"
            } else {
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
                Write-Output "  Removed: $taskName"
            }
        } else {
            Write-Output "  Not found: $taskName"
        }
    }
    Write-Output "=== Unregister complete ==="
    return
}

Write-Output "=== Registering audit cadence tasks (DryRun=$DryRun, OnlyTask=$OnlyTask) ==="

# Common task settings
$pwshPath = (Get-Command pwsh).Source

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopIfGoingOnBatteries `
    -AllowStartIfOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10)

$principal = New-ScheduledTaskPrincipal `
    -UserId "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel Highest

foreach ($key in $selectedTasks) {
    $def = $taskDefinitions[$key]

    $action = New-ScheduledTaskAction `
        -Execute $pwshPath `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$($def.Script)`""

    $trigger = & $def.TriggerFunc

    $task = New-ScheduledTask `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -Principal $principal `
        -Description $def.Description

    if ($DryRun) {
        Write-Output "  DRY RUN: would Register-ScheduledTask -TaskName '$($def.TaskName)' — $key cadence"
    } else {
        try {
            Register-ScheduledTask -TaskName $def.TaskName -InputObject $task -Force | Out-Null
            Write-Output "  Registered: $($def.TaskName) — $key cadence"
        } catch {
            Write-Warning "Registration failed for $($def.TaskName): $_"
        }
    }
}

Write-Output ""
Write-Output "=== Registration complete ==="
Write-Output ""
Write-Output "Verify all registered:"
Write-Output "  Get-ScheduledTask -TaskName 'SOK-Weekly-Audit', 'SOK-Monthly-Audit', 'SOK-Quarterly-Audit', 'SOK-Annual-Audit', 'SOK-Recursive-Reinvig' | Format-Table TaskName, State, @{Name='NextRun';Expression={(Get-ScheduledTaskInfo -TaskName `$_.TaskName).NextRunTime}}"
Write-Output ""
Write-Output "Manual trigger (test):"
Write-Output "  Start-ScheduledTask -TaskName 'SOK-Weekly-Audit'"
Write-Output ""
if ($missingScripts.Count -gt 0) {
    Write-Warning "REMINDER: $($missingScripts.Count) audit script(s) still need to be authored:"
    $missingScripts | ForEach-Object { Write-Warning "  - $($_.Path)" }
    Write-Warning "Until authored, the corresponding scheduled tasks will fire-and-fail. No harm; just won't produce audit output."
}
