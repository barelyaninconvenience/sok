#Requires -RunAsAdministrator
#Requires -Version 7.0

<#
.SYNOPSIS
    SOK-TestBatch.ps1 v1.0.0 — Exhaustive DryRun test of all active SOK scripts.

.DESCRIPTION
    Runs every active script in C:\Users\shelc\Documents\Journal\Projects\scripts\
    in DryRun/preview mode as child processes, captures stdout+stderr per script,
    and generates a summary report.

    DESIGNED FOR BACKGROUND EXECUTION — all output goes to per-script log files.
    No interactive prompts. Unattended safe.

    Each script gets its own log file at:
        SOK\Logs\TestBatch\<runId>\<ScriptName>.log

    Final summary written to:
        SOK\Logs\TestBatch\<runId>\summary.md
        SOK\Logs\TestBatch\<runId>\summary.json

    NOT TESTED:
        SOK-FamilyPicture.ps1  — Conversation notes, not a PowerShell script.
                                  Pending move to SOK\Docs via SOK-ProjectsReorg -Apply.
        SOK-Vectorize.py       — Python script, tested separately.
        Deprecated\*           — All deprecated scripts excluded by design.

    SLOW SCRIPTS (marked [SLOW]):
        SOK-SpaceAudit.ps1      — Read-only scan but always runs full C:\; ~8-15 min
        SOK-BareMetal_v5.3.ps1  — Phase previews; ~5-10 min in DryRun
        SOK-PAST-BlankSlate.ps1 — File system traversal; ~10-20 min (scoped to Documents)
    These are skipped when -SkipSlow is set.

    MONOLITH (separate flag):
        SOK-METICUL.OS.ps1      — 18 inlined modules; ~45-90 min even in DryRun.
                                  Only included when -IncludeMonolith is set.

.PARAMETER TimeoutSec
    Per-script timeout in seconds. Default: 333 (5 min). Timed-out scripts are killed
    and marked TIMEOUT. Set higher (e.g., 1333) for slow scripts.

.PARAMETER SlowTimeoutSec
    Timeout for scripts marked [SLOW]. Default: 1333 (22 min).

.PARAMETER SkipSlow
    Skip SOK-SpaceAudit, SOK-BareMetal_v5.3, and SOK-PAST-BlankSlate.
    Use for quick smoke-test runs.

.PARAMETER IncludeMonolith
    Include SOK-METICUL.OS.ps1. Adds +-96 min. Off by default.

.PARAMETER MonolithTimeoutSec
    Timeout for SOK-METICUL.OS.ps1 when -IncludeMonolith is set. Default: 5760 (96 min).

.EXAMPLE
    # Run in background (quick mode — skip slow scripts):
    Start-Process pwsh -ArgumentList "-NoProfile -File `"$PSScriptRoot\SOK-TestBatch.ps1`" -SkipSlow" -Verb RunAs

    # Full batch in background:
    Start-Process pwsh -ArgumentList "-NoProfile -File `"$PSScriptRoot\SOK-TestBatch.ps1`"" -Verb RunAs

    # Include monolith (very long):
    Start-Process pwsh -ArgumentList "-NoProfile -File `"$PSScriptRoot\SOK-TestBatch.ps1`" -IncludeMonolith" -Verb RunAs

.NOTES
    Author:  S. Clay Caddell
    Version: 1.0.0
    Date:    2026-04-04
    Domain:  Utility — exhaustive test harness for all active SOK scripts
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec         = 333,
    [int]$SlowTimeoutSec     = 1333,
    [switch]$SkipSlow,
    [switch]$IncludeMonolith,
    [int]$MonolithTimeoutSec = 5760
)

$ErrorActionPreference = 'Continue'

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
$SCRIPTS_DIR = 'C:\Users\shelc\Documents\Journal\Projects\scripts'
$SOK_ROOT    = 'C:\Users\shelc\Documents\Journal\Projects\SOK'
$RunId       = Get-Date -Format 'yyyyMMdd-HHmmss'
$OutDir      = Join-Path $SOK_ROOT "Logs\TestBatch\$RunId"
$BatchLog    = Join-Path $OutDir '_batch-runner.log'

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
Start-Transcript -Path $BatchLog -Append | Out-Null

Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "║  SOK-TestBatch v1.0.0  |  Run: $RunId" -ForegroundColor White
Write-Host "║  SkipSlow: $SkipSlow  |  IncludeMonolith: $IncludeMonolith" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Magenta

# ─────────────────────────────────────────────────────────────────────────────
# TEST CASE DEFINITIONS
#   Group       — temporal domain or category for report grouping
#   Script      — filename relative to SCRIPTS_DIR
#   Args        — array of CLI arguments (DryRun or equivalent)
#   Slow        — if $true, skipped when -SkipSlow is set
#   TimeoutSec  — $null = use global default; otherwise per-script override
#   Note        — human note shown in summary
# ─────────────────────────────────────────────────────────────────────────────
$Tests = @(

    # ── META: PAST ────────────────────────────────────────────────────────────
    @{
        Group  = 'Meta-PAST'
        Script = 'SOK-PAST.ps1'
        Args   = @('-DryRun', '-All')
        Note   = 'All 6 PAST modules in DryRun. No disk mutations.'
    }
    @{
        Group      = 'Meta-PAST'
        Script     = 'SOK-PAST-Verbose.ps1'
        Args       = @('-DryRun', '-RunInfraFix', '-RunInventory', '-RunSpaceAudit', '-RunRestructure')
        Slow       = $true
        TimeoutSec = 2400
        Note       = '[SLOW] De-optimized verbose PAST wraps the full SpaceAudit internally, so its budget tracks SpaceAudit + overhead. Skipping CompareSnapshots (needs snapshot files).'
    }
    @{
        Group  = 'Meta-PAST'
        Script = 'SOK-PAST-v2.ps1'
        Args   = @('-DryRun', '-All')
        Note   = 'Meta-level refactor with Get-SystemTruth / Measure-AccumulatedDebt abstractions.'
    }
    @{
        Group     = 'Meta-PAST'
        Script    = 'SOK-PAST-BlankSlate.ps1'
        Args      = @('-DryRun', '-SnapshotOnly', '-ScanRoots', 'C:\Users\shelc\Documents')
        Slow      = $true
        TimeoutSec = 1333
        Note      = '[SLOW] Blank-slate implementation. ScanRoots scoped to Documents for test speed.'
    }

    # ── META: PRESENT / FUTURE / MONOLITH ────────────────────────────────────
    @{
        Group  = 'Meta-PRESENT'
        Script = 'SOK-PRESENT.ps1'
        Args   = @('-DryRun')
        Note   = 'Full PRESENT suite (all core modules). Progressive Enclosure default.'
    }
    @{
        Group  = 'Meta-FUTURE'
        Script = 'SOK-FUTURE.ps1'
        Args   = @('-DryRun')
        Note   = 'Full FUTURE suite (Offload, Backup, Archive). Always DryRun first.'
    }

    # ── INFRASTRUCTURE ────────────────────────────────────────────────────────
    @{
        Group  = 'Infrastructure'
        Script = 'SOK-InfraFix.ps1'
        Args   = @('-DryRun')
        Note   = '5 FIX entries: nvm4w junction, OneDrive orphan, Kibana shim, History dir, Altair Python.'
    }
    @{
        Group      = 'Infrastructure'
        Script     = 'SOK-BareMetal_v5.3.ps1'
        Args       = @('-DryRun')
        Slow       = $true
        TimeoutSec = 666
        Note       = '[SLOW] Canonical BareMetal. Previews full provisioning sequence without installs.'
    }

    # ── PAST TACTICAL ────────────────────────────────────────────────────────
    @{
        Group  = 'PAST-Tactical'
        Script = 'SOK-Inventory.ps1'
        Args   = @('-DryRun')
        Note   = 'System snapshot. DryRun: scan runs but JSON not written.'
    }
    @{
        Group      = 'PAST-Tactical'
        Script     = 'SOK-SpaceAudit.ps1'
        Args       = @('-DryRun')
        Slow       = $true
        TimeoutSec = 2100
        Note       = '[SLOW] Read-only full C:\ scan. 727GB / 317K dirs legitimately takes ~16-20 min; budget 35 min to be safe.'
    }
    @{
        Group  = 'PAST-Tactical'
        Script = 'SOK-Restructure.ps1'
        Args   = @('-DryRun')
        Note   = 'Structural debt analysis. DryRun: report not written.'
    }
    @{
        Group  = 'PAST-Tactical'
        Script = 'SOK-Comparator.ps1'
        Args   = @('-DryRun')
        Note   = 'DryRun placeholder: exits with stub output. No snapshot files required.'
    }
    @{
        Group  = 'PAST-Tactical'
        Script = 'SOK-BackupRestructure.ps1'
        Args   = @('-DryRun')
        Note   = 'Phase 1 is opt-in (-RunPhase1). Default DryRun is safe. Phases 2+3 previewed.'
    }

    # ── PRESENT TACTICAL ─────────────────────────────────────────────────────
    @{
        Group  = 'PRESENT-Tactical'
        Script = 'SOK-DefenderOptimizer.ps1'
        Args   = @('-DryRun')
        Note   = 'v1.3.0 fixed missing param block. DryRun now correctly gates all Set-MpPreference calls.'
    }
    @{
        Group  = 'PRESENT-Tactical'
        Script = 'SOK-ProcessOptimizer.ps1'
        Args   = @('-DryRun', '-Mode', 'Conservative')
        Note   = 'Conservative mode for test. DryRun: no processes killed.'
    }
    @{
        Group  = 'PRESENT-Tactical'
        Script = 'SOK-ServiceOptimizer.ps1'
        Args   = @('-DryRun', '-Action', 'Report')
        Note   = 'Report mode = read-only analysis. DryRun: no services stopped.'
    }
    @{
        Group  = 'PRESENT-Tactical'
        Script = 'SOK-Maintenance.ps1'
        Args   = @('-DryRun', '-Mode', 'Quick')
        Note   = 'Quick mode: junction check + cache cleanup + recycle bin. Fastest mode for test.'
    }
    @{
        Group  = 'PRESENT-Tactical'
        Script = 'SOK-Cleanup.ps1'
        Args   = @('-DryRun')
        Note   = 'Cache/temp purge + offload preview. DryRun: no deletes, no offloads.'
    }
    @{
        Group  = 'PRESENT-Tactical'
        Script = 'SOK-LiveScan.ps1'
        Args   = @('-DryRun', '-SourcePath', 'C:\Users\shelc', '-ExcludeNoisyDirs')
        Note   = 'DryRun exits early (scan skipped). SourcePath scoped to user profile.'
    }
    @{
        Group  = 'PRESENT-Tactical'
        Script = 'SOK-LiveDigest.ps1'
        Args   = @('-DryRun')
        Note   = 'DryRun exits before writing output files. Auto-detects most recent LiveScan JSON.'
    }
    @{
        Group  = 'PRESENT-Tactical'
        Script = 'SOK-PreSwap.ps1'
        Args   = @('-DryRun')
        Note   = '5-phase C: space maximization preview. DryRun: no junction changes, no offloads.'
    }

    # ── FUTURE TACTICAL ───────────────────────────────────────────────────────
    @{
        Group  = 'FUTURE-Tactical'
        Script = 'SOK-Offload.ps1'
        Args   = @('-DryRun')
        Note   = 'Inventory-driven offload preview. DryRun: no files moved, no junctions created.'
    }
    @{
        Group  = 'FUTURE-Tactical'
        Script = 'SOK-Backup.ps1'
        Args   = @('-DryRun')
        Note   = 'Robocopy /E /L preview. Additive-only. -Incremental (/MIR) never in test batch.'
    }
    @{
        Group  = 'FUTURE-Tactical'
        Script = 'SOK-Archiver.ps1'
        Args   = @('-DryRun')
        Note   = 'TITAN Archiver. DryRun: manifest built, no archive file written.'
    }

    # ── SYSTEM ────────────────────────────────────────────────────────────────
    @{
        Group  = 'System'
        Script = 'SOK-Scheduler.ps1'
        Args   = @('-DryRun')
        Note   = 'Previews 13 daily + 1 weekly task registrations. No Task Scheduler writes.'
    }
    @{
        Group  = 'System'
        Script = 'SOK-DriveViability.ps1'
        Args   = @('-DryRun', '-TargetDrive', 'F:')
        Note   = 'DryRun: pre-flight + test plan without writing to F:. F: may be absent (graceful).'
    }

    # ── UTILITY ───────────────────────────────────────────────────────────────
    @{
        Group      = 'Utility'
        Script     = 'Export-SoftwareManifest.ps1'
        Args       = @('-DryRun', '-SkipSlowSources')
        TimeoutSec = 900
        Note       = 'DryRun: lists sources only, no Markdown written. -SkipSlowSources skips Winget+Store. pip 3.14 query can still be slow.'
    }
    @{
        Group  = 'Utility'
        Script = 'Install-GitHubRelease.ps1'
        Args   = @('-DryRun', '-ScanInventory')
        Note   = 'ScanInventory mode: cross-references installed tools vs GitHub sources. No downloads.'
    }
    @{
        Group  = 'Utility'
        Script = 'SOK-ProjectsReorg.ps1'
        Args   = @()
        Note   = 'Default (no -Apply) = DryRun preview. Lists all planned moves, nothing executed.'
    }
    @{
        Group  = 'Utility'
        Script = 'Restructure-FlattenedFiles.ps1'
        Args   = @(
            '-FlatDirectory', 'C:\Users\shelc\Downloads',
            '-Mode',          'MetadataRestructure',
            # v1.0.2 (2026-04-14): resolve under $OutDir (canonical
            # Journal\Projects\SOK\Logs\TestBatch\<RunId>) instead of the legacy
            # Documents\SOK\Logs\... path per CLAUDE.md §9.
            '-OutputRoot',    (Join-Path $OutDir 'FlattenedRecovery'),
            '-DryRun'
        )
        Note   = 'DryRun: metadata classification of Downloads + FileMap preview. No files moved.'
    }
)

# ── MONOLITH (opt-in) ─────────────────────────────────────────────────────────
if ($IncludeMonolith) {
    $Tests += @{
        Group      = 'Monolith'
        Script     = 'SOK-METICUL.OS.ps1'
        Args       = @('-DryRun')
        TimeoutSec = $MonolithTimeoutSec
        Note       = 'TRUE MONOLITH: 18 inlined modules. DryRun: zero disk mutations. Very long.'
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# TEST EXECUTION ENGINE
# ─────────────────────────────────────────────────────────────────────────────

function Invoke-TestCase {
    param(
        [string]   $Script,
        [string[]] $ScriptArgs,  # v1.0.1 — renamed from $Args (reserved PS automatic variable)
        [int]      $TimeoutMs,
        [string]   $Note
    )

    $scriptPath = Join-Path $SCRIPTS_DIR $Script
    $baseName   = $Script -replace '\.ps1$', ''
    $logPath    = Join-Path $OutDir "$baseName.log"
    $errPath    = Join-Path $OutDir "$baseName.err.log"

    if (-not (Test-Path $scriptPath)) {
        return [pscustomobject]@{
            Script    = $Script
            Status    = 'NOT_FOUND'
            ExitCode  = $null
            Duration  = 0
            LogPath   = $null
            Note      = $Note
        }
    }

    # Build pwsh argument list as array — let Start-Process handle quoting.
    # Avoid manual quote-embedding ($quotedPath) which can break switch parameter binding
    # when -ArgumentList joins into a single string (known PS issue with -File + switches).
    $argParts = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptPath) + $ScriptArgs

    Write-Host "  [$Script] " -NoNewline -ForegroundColor Cyan
    Write-Host "args: $($ScriptArgs -join ' ')" -ForegroundColor DarkGray

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    $proc = Start-Process `
        -FilePath    'pwsh' `
        -ArgumentList $argParts `
        -RedirectStandardOutput $logPath `
        -RedirectStandardError  $errPath `
        -WorkingDirectory       $SCRIPTS_DIR `
        -NoNewWindow `
        -PassThru

    $completed = $proc.WaitForExit($TimeoutMs)

    $sw.Stop()

    $timedOut = -not $completed
    if ($timedOut) {
        try { $proc.Kill($true) } catch { try { $proc.Kill() } catch {} }
        $exitCode = -999
        $status   = 'TIMEOUT'
        Write-Host "    TIMEOUT after $([math]::Round($sw.Elapsed.TotalSeconds,1))s" -ForegroundColor Red
    } else {
        $exitCode = $proc.ExitCode
        $status   = if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' }
        $color    = if ($status -eq 'PASS') { 'Green' } else { 'Red' }
        Write-Host "    $status  ($exitCode)  $([math]::Round($sw.Elapsed.TotalSeconds,1))s" -ForegroundColor $color
    }

    # Merge stderr into main log with separator
    if ((Test-Path $errPath) -and (Get-Item $errPath).Length -gt 0) {
        $errContent = Get-Content $errPath -Raw -ErrorAction SilentlyContinue
        if ($errContent) {
            "`n`n════════════════ STDERR ════════════════`n$errContent" |
                Add-Content -Path $logPath -Encoding utf8
        }
    }
    if (Test-Path $errPath) { Remove-Item $errPath -Force -ErrorAction SilentlyContinue }

    return [pscustomobject]@{
        Script    = $Script
        Status    = $status
        ExitCode  = $exitCode
        DurationS = [math]::Round($sw.Elapsed.TotalSeconds, 1)
        LogPath   = $logPath
        Note      = $Note
        TimedOut  = $timedOut
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# MAIN LOOP
# ─────────────────────────────────────────────────────────────────────────────

$Results     = [System.Collections.Generic.List[pscustomobject]]::new()
$BatchStart  = Get-Date
$Skipped     = [System.Collections.Generic.List[pscustomobject]]::new()

$testCount = ($Tests | Where-Object { -not ($SkipSlow -and $_.Slow) }).Count
Write-Host "Running $testCount tests  (SkipSlow=$SkipSlow  IncludeMonolith=$IncludeMonolith)" -ForegroundColor White
Write-Host "Output directory: $OutDir`n" -ForegroundColor DarkGray

$index = 0
foreach ($t in $Tests) {
    $isSlow = $t.Slow -eq $true

    if ($SkipSlow -and $isSlow) {
        $Skipped.Add([pscustomobject]@{
            Script = $t.Script
            Reason = 'SkipSlow'
            Note   = $t.Note
        }) | Out-Null
        Write-Host "  [$($t.Script)] SKIPPED (slow)" -ForegroundColor DarkYellow
        continue
    }

    $index++
    $pct  = [math]::Round($index / $testCount * 100, 0)
    $timeoutMs = if ($t.TimeoutSec) { $t.TimeoutSec * 1000 } else { $TimeoutSec * 1000 }
    if ($isSlow -and -not $t.TimeoutSec) { $timeoutMs = $SlowTimeoutSec * 1000 }

    Write-Host "[$index/$testCount  $pct%]  Group: $($t.Group)" -ForegroundColor Magenta

    $result = Invoke-TestCase `
        -Script     $t.Script `
        -ScriptArgs ($t.Args ?? @()) `
        -TimeoutMs  $timeoutMs `
        -Note       $t.Note

    $Results.Add($result) | Out-Null
}

$BatchDurationS = [math]::Round(((Get-Date) - $BatchStart).TotalSeconds, 1)

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY REPORT — JSON
# ─────────────────────────────────────────────────────────────────────────────
$pass    = ($Results | Where-Object { $_.Status -eq 'PASS'     }).Count
$fail    = ($Results | Where-Object { $_.Status -eq 'FAIL'     }).Count
$timeout = ($Results | Where-Object { $_.Status -eq 'TIMEOUT'  }).Count
$notFound= ($Results | Where-Object { $_.Status -eq 'NOT_FOUND'}).Count

$summaryObj = [ordered]@{
    RunId         = $RunId
    GeneratedAt   = (Get-Date -Format 'o')
    BatchDurationS = $BatchDurationS
    SkipSlow      = $SkipSlow.IsPresent
    IncludeMonolith = $IncludeMonolith.IsPresent
    Totals        = [ordered]@{
        Ran      = $Results.Count
        Pass     = $pass
        Fail     = $fail
        Timeout  = $timeout
        NotFound = $notFound
        Skipped  = $Skipped.Count
    }
    Results       = $Results
    Skipped       = $Skipped
}

$jsonPath = Join-Path $OutDir 'summary.json'
$summaryObj | ConvertTo-Json -Depth 6 | Set-Content $jsonPath -Encoding utf8

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY REPORT — MARKDOWN
# ─────────────────────────────────────────────────────────────────────────────
$md = [System.Text.StringBuilder]::new()

[void]$md.AppendLine("# SOK Test Batch Summary")
[void]$md.AppendLine("")
[void]$md.AppendLine("**Run ID:** $RunId  ")
[void]$md.AppendLine("**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  ")
[void]$md.AppendLine("**Duration:** ${BatchDurationS}s  ")
[void]$md.AppendLine("**SkipSlow:** $($SkipSlow.IsPresent) | **IncludeMonolith:** $($IncludeMonolith.IsPresent)  ")
[void]$md.AppendLine("")
[void]$md.AppendLine("---")
[void]$md.AppendLine("")
[void]$md.AppendLine("## Result Overview")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Outcome | Count |")
[void]$md.AppendLine("|---------|-------|")
[void]$md.AppendLine("| PASS | $pass |")
[void]$md.AppendLine("| FAIL | $fail |")
[void]$md.AppendLine("| TIMEOUT | $timeout |")
[void]$md.AppendLine("| NOT FOUND | $notFound |")
[void]$md.AppendLine("| Skipped (-SkipSlow) | $($Skipped.Count) |")
[void]$md.AppendLine("")

# Group results by Group for the detail table
$byGroup = $Results | Group-Object { $_ | Select-Object -ExpandProperty Note -ErrorAction SilentlyContinue; return $null } -ErrorAction SilentlyContinue

[void]$md.AppendLine("## Test Results")
[void]$md.AppendLine("")
[void]$md.AppendLine("| Script | Status | Exit | Duration | Notes |")
[void]$md.AppendLine("|--------|--------|------|----------|-------|")

foreach ($r in $Results) {
    $statusIcon = switch ($r.Status) {
        'PASS'      { ':white_check_mark:' }
        'FAIL'      { ':x:' }
        'TIMEOUT'   { ':hourglass:' }
        'NOT_FOUND' { ':warning:' }
        default     { '?' }
    }
    $shortNote = if ($r.Note.Length -gt 80) { $r.Note.Substring(0, 77) + '...' } else { $r.Note }
    [void]$md.AppendLine("| ``$($r.Script)`` | $statusIcon $($r.Status) | $($r.ExitCode) | $($r.DurationS)s | $shortNote |")
}

[void]$md.AppendLine("")

if ($fail -gt 0 -or $timeout -gt 0) {
    [void]$md.AppendLine("## Failures & Timeouts")
    [void]$md.AppendLine("")
    foreach ($r in $Results | Where-Object { $_.Status -in @('FAIL','TIMEOUT') }) {
        [void]$md.AppendLine("### $($r.Script) — $($r.Status)")
        [void]$md.AppendLine("")
        [void]$md.AppendLine("- Exit code: ``$($r.ExitCode)``")
        [void]$md.AppendLine("- Duration: $($r.DurationS)s")
        [void]$md.AppendLine("- Log: ``$($r.LogPath)``")
        [void]$md.AppendLine("- Note: $($r.Note)")
        [void]$md.AppendLine("")
        # Include tail of log if it exists
        if ($r.LogPath -and (Test-Path $r.LogPath)) {
            $tail = Get-Content $r.LogPath -Tail 30 -ErrorAction SilentlyContinue
            if ($tail) {
                [void]$md.AppendLine("``````text")
                [void]$md.AppendLine("... (last 30 lines of log)")
                foreach ($line in $tail) { [void]$md.AppendLine($line) }
                [void]$md.AppendLine("``````")
                [void]$md.AppendLine("")
            }
        }
    }
}

if ($Skipped.Count -gt 0) {
    [void]$md.AppendLine("## Skipped (SkipSlow)")
    [void]$md.AppendLine("")
    foreach ($s in $Skipped) {
        [void]$md.AppendLine("- ``$($s.Script)`` — $($s.Note)")
    }
    [void]$md.AppendLine("")
}

[void]$md.AppendLine("## Not Tested")
[void]$md.AppendLine("")
[void]$md.AppendLine("- ``SOK-FamilyPicture.ps1`` — Conversation notes (Gemini CAS architecture session), not executable PowerShell.")
[void]$md.AppendLine("  Pending move to ``SOK\Docs\`` via ``SOK-ProjectsReorg.ps1 -Apply``.")
[void]$md.AppendLine("- ``SOK-Vectorize.py`` — Python script. Test separately with: ``py -3.14 SOK-Vectorize.py --search test``")
[void]$md.AppendLine("- ``Deprecated\*`` — All deprecated scripts excluded by design.")
[void]$md.AppendLine("")
[void]$md.AppendLine("---")
[void]$md.AppendLine("*Generated by SOK-TestBatch.ps1 v1.0.0  |  $RunId*")

$mdPath = Join-Path $OutDir 'summary.md'
$md.ToString() | Set-Content $mdPath -Encoding utf8

# ─────────────────────────────────────────────────────────────────────────────
# CONSOLE FINAL SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor $(if ($fail -gt 0 -or $timeout -gt 0) { 'Red' } else { 'Green' })
Write-Host "║  BATCH COMPLETE  |  $RunId" -ForegroundColor White
Write-Host "║  Duration: ${BatchDurationS}s" -ForegroundColor White
Write-Host "║  PASS: $pass  FAIL: $fail  TIMEOUT: $timeout  NOTFOUND: $notFound  SKIPPED: $($Skipped.Count)" -ForegroundColor White
Write-Host "╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor $(if ($fail -gt 0 -or $timeout -gt 0) { 'Red' } else { 'Green' })
Write-Host ""
Write-Host "JSON : $jsonPath" -ForegroundColor DarkGray
Write-Host "MD   : $mdPath"   -ForegroundColor DarkGray
Write-Host "Log  : $BatchLog" -ForegroundColor DarkGray
Write-Host ""

Stop-Transcript | Out-Null
