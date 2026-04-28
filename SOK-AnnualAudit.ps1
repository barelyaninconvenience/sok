#Requires -Version 7.0
<#
.SYNOPSIS
    Annual audit trigger — writes notification to Scheduled_Audit_Inbox for next-session Clay pickup.

.DESCRIPTION
    Part of the ENDEAVOR Continuous Improvement Loop. Fires on January 1st each year. Reads the
    past 4 quarterly audits and produces a notification file at Writings/Scheduled_Audit_Inbox/
    describing the pending annual audit with:
      - The 4 quarterly audits to be aggregated
      - The Master_Log full regeneration requirement (previous year to Deprecated/)
      - Framework-refinement reflection component (year-over-year patterns)
      - Multi-year trajectory state assessment

    Per Master_Log_Audit_Cadence_20260424.md, the annual audit is the most interpretive of the
    four cadences and requires sustained Clay attention (typically a focused session). This script's
    role is to post the notification; Clay's next session cold-start surfaces the inbox and
    triggers the actual audit work.

    Scheduled task: SOK-Annual-Audit fires January 1 at 09:23.

.PARAMETER DryRun
    Preview what would be written without creating the notification file.

.NOTES
    Author: Shelby Clay Caddell with Claude Opus 4.7
    Created: 2026-04-24 late evening
    Anchored to: Writings/Master_Log_Audit_Cadence_20260424.md + memory/protocol_endeavor.md
    Registered via: Register-AuditCadenceTasks.ps1 -OnlyTask Annual
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProjectsRoot = "C:\Users\shelc\Documents\Journal\Projects"
$WritingsRoot = "$ProjectsRoot\Writings"
$InboxDir     = "$WritingsRoot\Scheduled_Audit_Inbox"
$QuarterlyDir = "$WritingsRoot\Quarterly_Audits"
$LogRoot      = "$ProjectsRoot\SOK\Logs\AnnualAudit"

# Month guard — scheduled task fires monthly on 1st; only produce annual notification
# on January 1st. Silent no-op otherwise.
if ((Get-Date).Month -ne 1 -and -not $DryRun) {
    exit 0
}

$null = New-Item $InboxDir -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item $LogRoot  -ItemType Directory -Force -ErrorAction SilentlyContinue

$now      = Get-Date
$year     = $now.Year
$priorYear = $year - 1
$stamp    = $now.ToString('yyyyMMdd-HHmmss')

$inboxFile = "$InboxDir\Annual_Audit_Pending_${priorYear}_${stamp}.md"
$logFile   = "$LogRoot\AnnualAudit_${stamp}.log"

# Identify the 4 quarterly audits to be aggregated (past 4 quarters = full prior year)
$priorQuarters = @()
foreach ($q in 1..4) {
    $tag = "${priorYear}-Q${q}"
    $path = "$QuarterlyDir\Quarterly_Audit_${tag}.md"
    $priorQuarters += [PSCustomObject]@{
        Tag    = $tag
        Path   = $path
        Exists = Test-Path $path
    }
}

$notification = @"
# Annual Audit Pending — $priorYear

**Triggered:** $($now.ToString('yyyy-MM-dd HH:mm:ss'))
**Year being audited:** $priorYear
**Output target:** `Writings/Annual_Audits/Annual_Audit_${priorYear}.md`
**Master_Log regeneration target:** `Writings/Master_Log_${year}.md` (previous `Master_Log_${priorYear}.md` to `Deprecated/`)

---

## Action required (next Claude session)

Per Master_Log_Audit_Cadence_20260424.md §Annual. This is the highest-interpretive cadence — expect a focused session of substantial duration.

### 1. Read the past 4 quarterly audits (ONLY — single-layer-deep discipline)

$(foreach ($q in $priorQuarters) {
    if ($q.Exists) {
        "   - $($q.Tag): ``$($q.Path)``"
    } else {
        "   - $($q.Tag): ``$($q.Path)`` ⚠️ NOT FOUND — check if quarterly audit was run"
    }
})

### 2. Produce `Writings/Annual_Audits/Annual_Audit_${priorYear}.md`

Must cover:
- Year-over-year patterns
- Substrate Thesis framework refinement (what changed in the framework itself; what v2 or v3 theory expansions occurred)
- Multi-year trajectory state (position relative to 2027 MS graduation; PhD application state; career trajectory; fund + fiduciary trajectory)
- Reinvigoration cycle retrospective (how many v1→v2 reinvigorations this year; which artifact types; what compounded, what decayed)
- Cross-practitioner + cross-domain observations (Case Study 07 prevalence study progress; Multi-Domain Crawler Substrate deployment state)
- Lessons learned that should become new `memory/feedback_*.md` or `memory/protocol_*.md` entries

### 3. Regenerate Master_Log

Per deprecate-never-delete:
1. Move current `Writings/Master_Log_${priorYear}.md` → `Writings/Deprecated/Master_Log_${priorYear}.md`
2. Author new `Writings/Master_Log_${year}.md` incorporating the annual audit's findings + current-state as of audit date

### 4. Fire Reconcile Protocol Trigger 3 before session-close

Per `memory/protocol_reconcile.md` the end-of-session reconcile is a prerequisite pillar of session-close.

---

## Housekeeping

Move this notification file to `$InboxDir\Processed\Annual_Audit_Pending_${priorYear}_${stamp}.md` once the audit is complete.
"@

if ($DryRun) {
    Write-Output "=== SOK-AnnualAudit (DryRun=`$true) ==="
    Write-Output "Would write notification to: $inboxFile"
    Write-Output ""
    Write-Output $notification
} else {
    Set-Content -Path $inboxFile -Value $notification -Encoding UTF8
    "$($now.ToString('yyyy-MM-dd HH:mm:ss')) Notification written: $inboxFile" | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Output "Annual audit notification written: $inboxFile"
}
