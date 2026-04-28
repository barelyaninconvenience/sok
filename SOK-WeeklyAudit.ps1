#Requires -Version 7.0
<#
.SYNOPSIS
    Weekly audit task — surfaces ML/ session activity + State_Snapshot Addenda from past 7 days.

.DESCRIPTION
    Part of the ENDEAVOR Continuous Improvement Loop (per Master_Log_Audit_Cadence_20260424.md).
    Each Sunday evening, scans the past 7 days for:
      - New session transcripts (ML/Session_*.md)
      - New Abstract_Oversight files (Learning/Abstract_Oversight_*.md)
      - State_Snapshot Addenda authored
      - Memory file changes
    Produces a draft Weekly Audit at Writings/Weekly_Audits/Weekly_Audit_<YYYY-WW>.md.

    The draft is a FACT CATALOG — Clay (or a follow-up endeavor agent dispatch) fills
    in the analytical sections (themes, drift flags, recurring deferrals).

    Single-layer-deep guard: this script does NOT investigate findings or pursue
    backlog items inline. Output is the input for the Monthly Audit.

.PARAMETER DryRun
    Preview what would be written without creating the audit file.

.PARAMETER WeekOffset
    Audit a different week than the current one. Default 0 (current week).
    -1 = last week, +1 = next week, etc.

.EXAMPLE
    pwsh -File SOK-WeeklyAudit.ps1 -DryRun

.EXAMPLE
    # Manually audit the prior week
    pwsh -File SOK-WeeklyAudit.ps1 -WeekOffset -1

.NOTES
    Registered as SOK-Weekly-Audit scheduled task (Sunday 18:00 weekly).
    Author: Shelby Clay Caddell with Claude Opus 4.7
    Created: 2026-04-24
    Anchored to: Writings/Master_Log_Audit_Cadence_20260424.md
    Template:    Writings/templates/Weekly_Audit_Template.md
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [int]$WeekOffset = 0
)

$ErrorActionPreference = 'Stop'
$ProjectsRoot = "C:\Users\shelc\Documents\Journal\Projects"
$WritingsRoot = "$ProjectsRoot\Writings"
$AuditDir     = "$WritingsRoot\Weekly_Audits"
$TemplatePath = "$WritingsRoot\templates\Weekly_Audit_Template.md"
$LogRoot      = "$ProjectsRoot\SOK\Logs"
$null = New-Item $LogRoot   -ItemType Directory -Force -ErrorAction SilentlyContinue
$null = New-Item $AuditDir  -ItemType Directory -Force -ErrorAction SilentlyContinue

# Compute audit window
$now = Get-Date
$targetSunday = $now.AddDays(($WeekOffset * 7) - [int]$now.DayOfWeek)  # most-recent Sunday + offset
$weekStart = $targetSunday.AddDays(-6).Date  # Monday before
$weekEnd   = $targetSunday.Date.AddHours(23).AddMinutes(59).AddSeconds(59)

# ISO week number
$cal = [System.Globalization.CultureInfo]::CurrentCulture.Calendar
$weekNum = $cal.GetWeekOfYear($targetSunday, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
$year = $targetSunday.Year
$auditFile = Join-Path $AuditDir ("Weekly_Audit_{0}-W{1:D2}.md" -f $year, $weekNum)

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = Join-Path $LogRoot ("SOK-WeeklyAudit_{0}.log" -f $timestamp)

function Write-Log {
    param([string]$Message)
    $line = "{0} | {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logPath -Value $line
    Write-Output $line
}

Write-Log "=== SOK-WeeklyAudit start (DryRun=$DryRun) ==="
Write-Log "Audit window: $($weekStart.ToString('yyyy-MM-dd')) → $($weekEnd.ToString('yyyy-MM-dd'))"
Write-Log "Output file: $auditFile"

# Find session transcripts in window
$sessions = Get-ChildItem "$ProjectsRoot\ML" -Filter "Session_*.md" -File |
    Where-Object { $_.LastWriteTime -ge $weekStart -and $_.LastWriteTime -le $weekEnd } |
    Sort-Object LastWriteTime

# Find Abstract_Oversights in window
$oversights = Get-ChildItem "$ProjectsRoot\Learning" -Filter "Abstract_Oversight_*.md" -File |
    Where-Object { $_.LastWriteTime -ge $weekStart -and $_.LastWriteTime -le $weekEnd } |
    Sort-Object LastWriteTime

# State_Snapshot Addenda in window — check if file modified
$snapshot = Get-Item "$WritingsRoot\State_Snapshot_Current.md" -ErrorAction SilentlyContinue
$snapshotModified = $snapshot -and $snapshot.LastWriteTime -ge $weekStart -and $snapshot.LastWriteTime -le $weekEnd

# Memory file changes in window
$memoryRoot = "$env:USERPROFILE\.claude\projects\C--Users-shelc-Documents-Journal-Projects-scripts\memory"
$memoryChanges = if (Test-Path $memoryRoot) {
    Get-ChildItem $memoryRoot -Filter "*.md" -File |
        Where-Object { $_.LastWriteTime -ge $weekStart -and $_.LastWriteTime -le $weekEnd } |
        Sort-Object LastWriteTime
} else { @() }

Write-Log "Found: $($sessions.Count) sessions, $($oversights.Count) oversights, snapshot-modified=$snapshotModified, $($memoryChanges.Count) memory changes"

# Build the audit draft
$draft = @()
$draft += "# Weekly Audit — Week $($weekNum.ToString('D2')) of $year"
$draft += "## Window: $($weekStart.ToString('yyyy-MM-dd')) → $($weekEnd.ToString('yyyy-MM-dd'))"
$draft += "## Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') · Auto-drafted by SOK-WeeklyAudit.ps1"
$draft += "## Source: ML/ + Learning/ + Writings/State_Snapshot_Current.md + memory/ files modified in window"
$draft += ""
$draft += "**Anti-pattern guard:** This audit reaches one layer deep only. Findings that need investigation go to backlog (Section 4); the audit does NOT pursue them inline."
$draft += ""
$draft += "---"
$draft += ""
$draft += "## Section 1 — Sessions in window"
$draft += ""

if ($sessions.Count -eq 0) {
    $draft += "_No session transcripts modified in window._"
} else {
    foreach ($s in $sessions) {
        $relPath = "ML/$($s.Name)"
        $draft += "- **$($s.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))** — ``$relPath`` ($([math]::Round($s.Length / 1024, 1)) KB)"
    }
}

$draft += ""
$draft += "## Section 1b — Abstract_Oversights in window"
$draft += ""

if ($oversights.Count -eq 0) {
    $draft += "_No Abstract_Oversight files modified in window._"
} else {
    foreach ($o in $oversights) {
        $relPath = "Learning/$($o.Name)"
        $draft += "- **$($o.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))** — ``$relPath`` ($([math]::Round($o.Length / 1024, 1)) KB)"
    }
}

$draft += ""
$draft += "## Section 1c — State_Snapshot activity"
$draft += ""

if ($snapshotModified) {
    $draft += "- **State_Snapshot_Current.md** modified at $($snapshot.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) — examine for new Addenda"
} else {
    $draft += "_State_Snapshot_Current.md not modified in window._"
}

$draft += ""
$draft += "## Section 1d — Memory file changes"
$draft += ""

if ($memoryChanges.Count -eq 0) {
    $draft += "_No memory files modified in window._"
} else {
    foreach ($m in $memoryChanges) {
        $draft += "- **$($m.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))** — ``memory/$($m.Name)``"
    }
}

$draft += ""
$draft += "---"
$draft += ""
$draft += "## Section 2 — New undertakings started this week"
$draft += ""
$draft += "_Auto-drafter cannot determine this from filenames alone — requires content read._"
$draft += "_NEXT STEP: Clay or follow-up endeavor agent reviews the sessions above and fills this section._"
$draft += "_Format per Weekly_Audit_Template.md_"
$draft += ""
$draft += "## Section 3 — Undertakings completed this week"
$draft += ""
$draft += "_Same as Section 2 — requires content read._"
$draft += ""
$draft += "## Section 4 — New backlog items (added to Master Log Section 6)"
$draft += ""
$draft += "_Same as Section 2 — requires content read. Items surfaced by sessions above with priority hints._"
$draft += ""
$draft += "## Section 5 — Items still un-touched (recurring deferrals)"
$draft += ""
$draft += "_Carry-forward from Master Log Section 6 'Recurring multi-session deferrals'. Bump deferral count._"
$draft += ""
$draft += "Format: **[Item]** — first deferred [date], deferred [N] weeks running"
$draft += ""
$draft += "## Section 6 — Drift / deviation flags"
$draft += ""
$draft += "_Memory file changes above (Section 1d) are the leading indicator. Any change to protocol_*.md or feedback_*.md = drift flag worth surfacing._"
$draft += ""
$draft += "---"
$draft += ""
$draft += "## Stop condition"
$draft += ""
$draft += "After Section 6 is populated. Do NOT pursue findings inline. Do NOT regenerate Master Log. The Weekly Audit's job is to be the input for the Monthly Audit."
$draft += ""
$draft += "---"
$draft += ""
$draft += "*Auto-drafted by SOK-WeeklyAudit.ps1. Sections 2-6 require Clay's pen or endeavor agent follow-up to complete. Anchored to: ``Writings/Master_Log_Audit_Cadence_20260424.md``.*"

if ($DryRun) {
    Write-Log "DRY RUN — would write $($draft.Count) lines to $auditFile"
    Write-Log "Draft preview (first 30 lines):"
    $draft | Select-Object -First 30 | ForEach-Object { Write-Log "  $_" }
} else {
    if (Test-Path $auditFile) {
        $backupPath = $auditFile -replace '\.md$', "_backup_$timestamp.md"
        Copy-Item $auditFile $backupPath
        Write-Log "Existing audit found; backup saved to $backupPath"
    }
    $draft -join "`n" | Set-Content -Path $auditFile -Encoding UTF8
    Write-Log "Wrote audit draft: $auditFile ($([math]::Round((Get-Item $auditFile).Length / 1024, 1)) KB)"
}

Write-Log "=== SOK-WeeklyAudit complete ==="
