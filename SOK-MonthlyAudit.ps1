#Requires -Version 7.0
<#
.SYNOPSIS
    Monthly audit task — aggregates the past month's weekly audits into a monthly draft.

.DESCRIPTION
    Part of the ENDEAVOR Continuous Improvement Loop. On the first Sunday of each
    month, gathers the 4 weekly audits from the past month and produces a draft
    Monthly Audit at Writings/Monthly_Audits/Monthly_Audit_<YYYY-MM>.md.

    Single-layer-deep guard: ONLY new + completed undertakings get attention.
    Open ongoing undertakings appear in Section 4 backlog state but do NOT get
    inline investigation. The Monthly Audit's job is the input for the Quarterly Audit.

.PARAMETER DryRun
    Preview what would be written without creating the audit file.

.PARAMETER MonthOffset
    Audit a different month than the current one. Default 0 (current month).
    -1 = last month, +1 = next month, etc.

.EXAMPLE
    pwsh -File SOK-MonthlyAudit.ps1 -DryRun

.EXAMPLE
    # Manually audit the prior month
    pwsh -File SOK-MonthlyAudit.ps1 -MonthOffset -1

.NOTES
    Registered as SOK-Monthly-Audit scheduled task (1st of month, 09:00).
    Author: Shelby Clay Caddell with Claude Opus 4.7
    Created: 2026-04-24
    Anchored to: Writings/Master_Log_Audit_Cadence_20260424.md
    Template:    Writings/templates/Monthly_Audit_Template.md
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [int]$MonthOffset = 0
)

$ErrorActionPreference = 'Stop'
$ProjectsRoot = "C:\Users\shelc\Documents\Journal\Projects"
$WritingsRoot = "$ProjectsRoot\Writings"
$WeeklyDir    = "$WritingsRoot\Weekly_Audits"
$MonthlyDir   = "$WritingsRoot\Monthly_Audits"
$LogRoot      = "$ProjectsRoot\SOK\Logs"
$null = New-Item $LogRoot     -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item $MonthlyDir  -ItemType Directory -Force -ErrorAction SilentlyContinue

# Compute audit window
$now = Get-Date
$targetMonth = $now.AddMonths($MonthOffset)
$monthStart = Get-Date -Year $targetMonth.Year -Month $targetMonth.Month -Day 1 -Hour 0 -Minute 0 -Second 0
$monthEnd   = $monthStart.AddMonths(1).AddSeconds(-1)

$year = $targetMonth.Year
$month = $targetMonth.Month
$auditFile = Join-Path $MonthlyDir ("Monthly_Audit_{0}-{1:D2}.md" -f $year, $month)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $LogRoot ("SOK-MonthlyAudit_{0}.log" -f $timestamp)

function Write-Log {
    param([string]$Message)
    $line = "{0} | {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logPath -Value $line
    Write-Output $line
}

Write-Log "=== SOK-MonthlyAudit start (DryRun=$DryRun) ==="
Write-Log "Audit window: $($monthStart.ToString('yyyy-MM-dd')) → $($monthEnd.ToString('yyyy-MM-dd'))"
Write-Log "Output file: $auditFile"

# Find weekly audits whose window falls within this month
$weeklyAudits = Get-ChildItem $WeeklyDir -Filter "Weekly_Audit_*.md" -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $monthStart -and $_.LastWriteTime -le $monthEnd } |
    Sort-Object Name

Write-Log "Found $($weeklyAudits.Count) weekly audits in window"

# Build the monthly audit draft
$monthName = $targetMonth.ToString('MMMM yyyy')
$draft = @()
$draft += "# Monthly Audit — $monthName"
$draft += "## Window: $($monthStart.ToString('yyyy-MM-dd')) → $($monthEnd.ToString('yyyy-MM-dd'))"
$draft += "## Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') · Auto-drafted by SOK-MonthlyAudit.ps1"
$draft += "## Source: $($weeklyAudits.Count) weekly audits in window"
$draft += ""
$draft += "**Anti-pattern guard:** ONLY new + completed undertakings get attention. Open ongoing undertakings appear in Section 4 backlog state but do NOT get inline investigation."
$draft += ""
$draft += "---"
$draft += ""
$draft += "## Source weekly audits"
$draft += ""

if ($weeklyAudits.Count -eq 0) {
    $draft += "_No weekly audits found in window. Cannot produce monthly synthesis without weekly inputs._"
    $draft += ""
    $draft += "**Action:** investigate why weekly audits are missing — was SOK-Weekly-Audit scheduled task firing? Check $LogRoot for SOK-WeeklyAudit_*.log files in the window."
} else {
    foreach ($w in $weeklyAudits) {
        $relPath = "Weekly_Audits/$($w.Name)"
        $draft += "- ``$relPath`` ($([math]::Round($w.Length / 1024, 1)) KB, $($w.LastWriteTime.ToString('yyyy-MM-dd')))"
    }
}

$draft += ""
$draft += "---"
$draft += ""
$draft += "## Section 1 — Major themes of the month"
$draft += ""
$draft += "_Auto-drafter cannot synthesize themes — requires content read of weekly audits above._"
$draft += "_NEXT STEP: Clay or follow-up endeavor agent reads the weekly audits and fills this section._"
$draft += "_Format per Monthly_Audit_Template.md_"
$draft += ""
$draft += "## Section 2 — Reinvigoration candidates surfaced"
$draft += ""
$draft += "_Cross-reference Master_Log_<latest>.md Section 2. Add new candidates from this month's weekly audits._"
$draft += ""
$draft += "## Section 3 — Interconnections noticed"
$draft += ""
$draft += "_Cross-reference Master_Log_<latest>.md Section 3._"
$draft += ""
$draft += "## Section 4 — Backlog state delta"
$draft += ""
$draft += "| Backlog state | Start of month | End of month | Delta | Notes |"
$draft += "|---|---|---|---|---|"
$draft += "| P0 items open | TBD | TBD | TBD | |"
$draft += "| P1 items open | TBD | TBD | TBD | |"
$draft += "| P2 items open | TBD | TBD | TBD | |"
$draft += "| P3 items open | TBD | TBD | TBD | |"
$draft += ""
$draft += "## Section 5 — Recurring multi-week deferrals (4+ weeks running)"
$draft += ""
$draft += "_Items that have been on the backlog 4+ weeks. Trigger for quarterly escalation if 12+ weeks._"
$draft += ""
$draft += "## Section 6 — Pacing / calibration observations"
$draft += ""
$draft += "_Did the operating-stack pacing thresholds hold this month? Any calibration drift?_"
$draft += "_Aggregate Section 6 of weekly audits._"
$draft += ""
$draft += "---"
$draft += ""
$draft += "## Stop condition"
$draft += ""
$draft += "After all weekly audits integrated. Do NOT regenerate Master Log; that's annual-only. Do NOT pursue reinvigoration inline."
$draft += ""
$draft += "---"
$draft += ""
$draft += "*Auto-drafted by SOK-MonthlyAudit.ps1. Sections 1-6 require Clay's pen or endeavor agent follow-up to complete. Anchored to: ``Writings/Master_Log_Audit_Cadence_20260424.md``.*"

if ($DryRun) {
    Write-Log "DRY RUN — would write $($draft.Count) lines to $auditFile"
} else {
    if (Test-Path $auditFile) {
        $backupPath = $auditFile -replace '\.md$', "_backup_$timestamp.md"
        Copy-Item $auditFile $backupPath
        Write-Log "Existing audit found; backup saved to $backupPath"
    }
    $draft -join "`n" | Set-Content -Path $auditFile -Encoding UTF8
    Write-Log "Wrote audit draft: $auditFile ($([math]::Round((Get-Item $auditFile).Length / 1024, 1)) KB)"
}

Write-Log "=== SOK-MonthlyAudit complete ==="
