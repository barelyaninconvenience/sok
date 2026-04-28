#Requires -Version 7.0
<#
.SYNOPSIS
    Quarterly audit trigger — writes notification to Scheduled_Audit_Inbox for next-session Clay pickup.

.DESCRIPTION
    Part of the ENDEAVOR Continuous Improvement Loop. Fires on the 1st of each quarter
    (Jan/Apr/Jul/Oct). Reads the past 3 monthly audits and produces a notification file
    at Writings/Scheduled_Audit_Inbox/ describing the pending quarterly audit with:
      - The 3 monthly audits to be aggregated
      - The Publication+IP audit sub-component (per Clay 2026-04-24 directive)
      - Reminder to write to Writings/Quarterly_Audits/Quarterly_Audit_<YYYY-Q>.md + Master_Log delta

    Per Master_Log_Audit_Cadence_20260424.md, the quarterly audit requires interpretive
    judgment that warrants Clay attention. This script's role is to post the notification;
    Clay's next session cold-start surfaces the inbox and triggers the actual audit work.

    Scheduled task: SOK-Quarterly-Audit fires 1st of Jan/Apr/Jul/Oct at 09:23.

.PARAMETER DryRun
    Preview what would be written without creating the notification file.

.NOTES
    Author: Shelby Clay Caddell with Claude Opus 4.7
    Created: 2026-04-24 late evening
    Anchored to: Writings/Master_Log_Audit_Cadence_20260424.md + memory/protocol_endeavor.md
    Registered via: Register-AuditCadenceTasks.ps1 -OnlyTask Quarterly
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProjectsRoot = "C:\Users\shelc\Documents\Journal\Projects"
$WritingsRoot = "$ProjectsRoot\Writings"
$InboxDir     = "$WritingsRoot\Scheduled_Audit_Inbox"
$MonthlyDir   = "$WritingsRoot\Monthly_Audits"
$LogRoot      = "$ProjectsRoot\SOK\Logs\QuarterlyAudit"

# Month-of-year guard — scheduled task fires monthly on 1st; only produce notification
# on the 1st of a quarter (January / April / July / October). Silent no-op otherwise.
$currentMonth = (Get-Date).Month
if ($currentMonth -notin @(1, 4, 7, 10) -and -not $DryRun) {
    # Non-quarter-start month; no action needed. Silent exit.
    exit 0
}

$null = New-Item $InboxDir -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item $LogRoot  -ItemType Directory -Force -ErrorAction SilentlyContinue

$now       = Get-Date
$year      = $now.Year
$quarter   = [math]::Ceiling($now.Month / 3)
$stamp     = $now.ToString('yyyyMMdd-HHmmss')
$quarterTag = "${year}-Q${quarter}"

$inboxFile = "$InboxDir\Quarterly_Audit_Pending_${quarterTag}_${stamp}.md"
$logFile   = "$LogRoot\QuarterlyAudit_${stamp}.log"

# Identify the 3 monthly audits to be aggregated (past 3 months)
$priorMonths = @()
for ($i = 1; $i -le 3; $i++) {
    $m = $now.AddMonths(-$i)
    $tag = $m.ToString('yyyy-MM')
    $path = "$MonthlyDir\Monthly_Audit_${tag}.md"
    $priorMonths += [PSCustomObject]@{
        Tag    = $tag
        Path   = $path
        Exists = Test-Path $path
    }
}

$notification = @"
# Quarterly Audit Pending — $quarterTag

**Triggered:** $($now.ToString('yyyy-MM-dd HH:mm:ss'))
**Quarter tag:** $quarterTag
**Output target:** `Writings/Quarterly_Audits/Quarterly_Audit_${quarterTag}.md`
**Master_Log delta target:** `Writings/Master_Log_Deltas/${quarterTag}_delta.md`

---

## Action required (next Claude session)

Per Master_Log_Audit_Cadence_20260424.md §Quarterly:

1. Read the past 3 monthly audits (ONLY — single-layer-deep discipline):
$(foreach ($m in $priorMonths) {
    if ($m.Exists) {
        "   - $($m.Tag): ``$($m.Path)``"
    } else {
        "   - $($m.Tag): ``$($m.Path)`` ⚠️ NOT FOUND — check if monthly audit was run"
    }
})

2. Produce `Writings/Quarterly_Audits/Quarterly_Audit_${quarterTag}.md` with:
   - Cross-monthly patterns
   - Backlog progression across the quarter
   - Priority-queue state changes
   - Drift signals at the quarterly scale
   - Calibration observations

3. Produce `Writings/Master_Log_Deltas/${quarterTag}_delta.md` capturing what changed this quarter relative to the current Master_Log.

4. **Publication+IP Audit sub-component** (per Clay 2026-04-24 directive):
   - Substrate Thesis publication progression
   - Essay series venue-commitment state
   - Academic paper submission readiness
   - Patent / prior-art filing calendar check

5. Fire `memory/protocol_reconcile.md` Trigger 3 (end-of-session) before the session that produces this audit closes.

---

## Housekeeping

Move this notification file to `$InboxDir\Processed\Quarterly_Audit_Pending_${quarterTag}_${stamp}.md` once the audit is complete, per deprecate-never-delete discipline.
"@

if ($DryRun) {
    Write-Output "=== SOK-QuarterlyAudit (DryRun=`$true) ==="
    Write-Output "Would write notification to: $inboxFile"
    Write-Output ""
    Write-Output $notification
} else {
    Set-Content -Path $inboxFile -Value $notification -Encoding UTF8
    "$($now.ToString('yyyy-MM-dd HH:mm:ss')) Notification written: $inboxFile" | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Output "Quarterly audit notification written: $inboxFile"
}
