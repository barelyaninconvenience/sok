#Requires -Version 7.0
<#
.SYNOPSIS
    Recursive Reinvigoration trigger — writes notification to Scheduled_Audit_Inbox for next-session Clay/Claude pickup.

.DESCRIPTION
    Part of the ENDEAVOR Continuous Improvement Loop. Fires Sunday 03:17 weekly. Identifies
    insight-propagation opportunities across the Projects/ substrate — specifically where new
    insights from the past week's sessions haven't propagated to affected memory/, writings/,
    case_studies/, theory/, or essay artifacts.

    The recursive reinvigoration pattern:
      1. Scan session transcripts (`ML/Session_*.md`) + Abstract_Oversight (`Learning/Abstract_Oversight_*.md`) + State_Snapshot addenda from past 7 days
      2. Identify conceptual deltas (new vocabulary / frameworks / protocols / methodologies introduced)
      3. Cross-check each delta against affected artifacts — has the delta been propagated?
      4. For each non-propagated delta, produce a propagation action item
      5. For each artifact that has drifted from the delta, produce a refresh action item

    This script's role is to post the notification; Clay's next session cold-start surfaces
    the inbox and a Claude session acts on it (typically via the cartographer or endeavor subagent).

    Scheduled task: SOK-Recursive-Reinvig fires Sunday 03:17 weekly.

.PARAMETER DryRun
    Preview what would be written without creating the notification file.

.NOTES
    Author: Shelby Clay Caddell with Claude Opus 4.7
    Created: 2026-04-24 late evening
    Anchored to: memory/protocol_endeavor.md + memory/protocol_reconcile.md
    Registered via: Register-AuditCadenceTasks.ps1 -OnlyTask Reinvigoration
#>
[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProjectsRoot = "C:\Users\shelc\Documents\Journal\Projects"
$WritingsRoot = "$ProjectsRoot\Writings"
$InboxDir     = "$WritingsRoot\Scheduled_Audit_Inbox"
$LogRoot      = "$ProjectsRoot\SOK\Logs\Reinvigoration"

$null = New-Item $InboxDir -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item $LogRoot  -ItemType Directory -Force -ErrorAction SilentlyContinue

$now      = Get-Date
$weekTag  = $now.ToString('yyyy') + "-W" + [System.Globalization.ISOWeek]::GetWeekOfYear($now).ToString('D2')
$stamp    = $now.ToString('yyyyMMdd-HHmmss')

$inboxFile = "$InboxDir\Recursive_Reinvigoration_Pending_${weekTag}_${stamp}.md"
$logFile   = "$LogRoot\Reinvigoration_${stamp}.log"

$notification = @"
# Recursive Reinvigoration Pending — $weekTag

**Triggered:** $($now.ToString('yyyy-MM-dd HH:mm:ss'))
**Week tag:** $weekTag
**Output target:** `Writings/Recursive_Reinvigoration_${weekTag}.md`

---

## Action required (next Claude session)

Per `memory/protocol_endeavor.md` + `memory/protocol_reconcile.md`. This is a weekly propagation sweep: the ENDEAVOR Loop's mechanism for keeping new insights from decaying into isolated notes.

### 1. Scan past 7 days for conceptual deltas

Read (single-layer-deep):
- `ML/Session_*.md` from past 7 days — key exchanges, decisions, vocabulary introduced
- `Learning/Abstract_Oversight_*.md` from past 7 days — Tier-1 deliverables + emergent insights (Tier 1), outstanding items (Tier 2)
- `Writings/State_Snapshot_Current.md` Addenda from past 7 days — the official session-by-session delta record

### 2. Identify non-propagated deltas

For each new concept / protocol / methodology / framework introduced in the past week:
- Did it land in the correct `memory/` file (protocol / feedback / project / user)?
- Did dependent `Writings/` files get updated?
- Did case_studies / theory / essays reference it?
- Did `MEMORY.md` get an index entry?
- If CLAUDE.md was affected, did it get updated?

### 3. Identify drifted artifacts

Artifact drift: a file hasn't been touched in N weeks but should reflect a newer concept. Common suspects:
- `CLAUDE.md` — should reflect any new protocols or section-level policy changes
- `memory/MEMORY.md` — should index all current memory files
- `substrate-thesis-companion/README.md` — should reflect current companion-repo state
- Publishable variants (`operating_stack_publishable_v1.md`, `mcp_setup_guide_publishable_v1.md`) — should reflect latest theory/policy state

### 4. Produce action items

Write to `Writings/Recursive_Reinvigoration_${weekTag}.md`:
- **Propagations executed** — list of files updated during this reinvigoration pass
- **Propagations queued** — list of files that still need updates, with specific deltas to propagate
- **Drift observations** — artifacts that should be touched but weren't (why? is the reason valid?)
- **Feed to Reconcile Protocol** — any zero-touched streams identified should feed into the next Reconcile Protocol Trigger pass

### 5. Fire Reconcile Protocol Trigger 3 before session-close

Per `memory/protocol_reconcile.md`.

---

## Suggested subagent delegation

This work is naturally delegated to:
- **endeavor** subagent — if the scope is wide (whole-Projects/ sweep)
- **cartographer** subagent — if the scope is deep (specific subdirectory map + drift report)
- **scout** subagent — if the scope is exploratory (sampling-based survey)

See `.claude/agents/` for the current roster.

---

## Housekeeping

Move this notification file to `$InboxDir\Processed\Recursive_Reinvigoration_Pending_${weekTag}_${stamp}.md` once the reinvigoration pass is complete.
"@

if ($DryRun) {
    Write-Output "=== SOK-RecursiveReinvigoration (DryRun=`$true) ==="
    Write-Output "Would write notification to: $inboxFile"
    Write-Output ""
    Write-Output $notification
} else {
    Set-Content -Path $inboxFile -Value $notification -Encoding UTF8
    "$($now.ToString('yyyy-MM-dd HH:mm:ss')) Notification written: $inboxFile" | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Output "Recursive reinvigoration notification written: $inboxFile"
}
