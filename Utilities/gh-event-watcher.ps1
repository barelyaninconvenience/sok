#Requires -Version 7.0
<#
.SYNOPSIS
    Polls the GitHub API for new events on barelyaninconvenience/sok and emits
    one line per relevant event to stdout (Monitor-compatible) and to a SOK log.

.DESCRIPTION
    Uses GitHub's conditional GET (ETag + If-None-Match) to poll efficiently and
    respect the X-Poll-Interval server hint. Only surfaces events matching the
    configured TypeFilter (default: PR, Issues, Comments, Pushes).

    Two modes:
      - Running standalone: loops indefinitely with -PollInterval spacing.
      - Monitor-compatible: each new event is emitted as a single stdout line,
        making it suitable for `claude monitor` or any line-based observer.

    Log location: C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\GhEventWatcher\

.PARAMETER PollInterval
    Seconds between polls. Minimum enforced by GitHub's X-Poll-Interval header
    (typically 60s for public repos). Default: 300 (5 minutes).

.PARAMETER DryRun
    Parse and format events but do not write to the log file. Stdout still emits.

.PARAMETER MaxRuns
    Stop after this many poll cycles. 0 = run forever. Default: 0.

.PARAMETER TypeFilter
    Array of GitHub event types to surface. Others are silently dropped.
    Defaults to the four most relevant types for PR/issue/comment tracking.

.EXAMPLE
    # Run as a Monitor-compatible background watcher (5-minute default interval):
    pwsh -NoProfile -File gh-event-watcher.ps1

.EXAMPLE
    # Quick smoke test: 2 polls, 65-second interval, dry run:
    pwsh -NoProfile -File gh-event-watcher.ps1 -MaxRuns 2 -PollInterval 65 -DryRun

.NOTES
    Requires: gh CLI authenticated (gh auth status)
    Repo:     barelyaninconvenience/sok
    Author:   Scout / Clay Caddell | 2026-04-16
#>

[CmdletBinding()]
param(
    [switch]$DryRun,

    [ValidateRange(60, 3600)]
    [int]$PollInterval = 300,

    [ValidateRange(0, [int]::MaxValue)]
    [int]$MaxRuns = 0,

    [string[]]$TypeFilter = @(
        'PullRequestEvent',
        'PullRequestReviewEvent',
        'PullRequestReviewCommentEvent',
        'IssuesEvent',
        'IssueCommentEvent',
        'PushEvent',
        'CommitCommentEvent'
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── Constants ────────────────────────────────────────────────────────────────
$Repo       = 'barelyaninconvenience/sok'
$ApiBase    = "repos/$Repo/events"
$LogRoot    = 'C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\GhEventWatcher'
$ScriptName = 'GhEventWatcher'

# ── Helpers ──────────────────────────────────────────────────────────────────
function Initialize-Log {
    if ($DryRun) { return $null }
    if (-not (Test-Path $LogRoot)) {
        New-Item -Path $LogRoot -ItemType Directory -Force | Out-Null
    }
    $ts      = Get-Date -Format 'yyyyMMdd-HHmmss'
    $logPath = Join-Path $LogRoot "${ScriptName}_${ts}.log"
    $header  = @"
════════════════════════════════════════════════════════════
  gh-event-watcher — $Repo
  Started:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  Host:       $env:COMPUTERNAME | User: $env:USERNAME
  Interval:   ${PollInterval}s | Filters: $($TypeFilter -join ', ')
  DryRun:     $DryRun
════════════════════════════════════════════════════════════

"@
    Set-Content -Path $logPath -Value $header -Force
    return $logPath
}

function Write-Log {
    param([string]$LogPath, [string]$Level, [string]$Message)
    $ts    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$ts] [$($Level.PadRight(7))] $Message"
    # Always emit to stdout (Monitor-compatible — one line)
    Write-Output $entry
    # Write to log file unless DryRun
    if ($LogPath -and -not $DryRun) {
        Add-Content -Path $LogPath -Value $entry -ErrorAction Continue
    }
}

function Format-EventLine {
    param([hashtable]$Evt)
    $type  = $Evt.type
    $actor = $Evt.actor.login
    $ts    = $Evt.created_at
    $pl    = $Evt.payload

    $detail = switch ($type) {
        'PullRequestEvent' {
            $action = $pl.action
            $pr     = $pl.pull_request
            $num    = $pr.number
            $title  = $pr.title
            "PR #$num [$action] — $title"
        }
        'PullRequestReviewEvent' {
            $action = $pl.action
            $pr     = $pl.pull_request
            "PR #($($pr.number)) review [$action]"
        }
        'PullRequestReviewCommentEvent' {
            $pr = $pl.pull_request
            "PR #($($pr.number)) review comment by $actor"
        }
        'IssuesEvent' {
            $action = $pl.action
            $issue  = $pl.issue
            "Issue #$($issue.number) [$action] — $($issue.title)"
        }
        'IssueCommentEvent' {
            $issue = $pl.issue
            "Issue #$($issue.number) comment by $actor"
        }
        'PushEvent' {
            $count = $pl.commits.Count
            $ref   = $pl.ref -replace '^refs/heads/', ''
            "$count commit(s) pushed to [$ref]"
        }
        'CommitCommentEvent' {
            "Commit comment by $actor"
        }
        default { "Event: $type" }
    }

    return "[EVENT] $ts | $actor | $detail"
}

function Invoke-Poll {
    param(
        [string]$ETag,
        [string]$LastModified
    )

    # Build gh api call with conditional headers to respect GitHub polling protocol
    $ghArgs = @($ApiBase, '--method', 'GET')
    if ($ETag) {
        $ghArgs += @('-H', "If-None-Match: $ETag")
    }
    elseif ($LastModified) {
        $ghArgs += @('-H', "If-Modified-Since: $LastModified")
    }
    # Request headers in response so we can extract ETag and X-Poll-Interval
    $ghArgs += @('-i')  # include response headers

    $raw = gh api @ghArgs 2>&1
    $exitCode = $LASTEXITCODE

    # gh returns exit 1 on HTTP 304 (Not Modified) — that's fine, means no new events
    $responseText = $raw -join "`n"

    # Parse HTTP status line
    $statusLine = ($responseText -split "`n" | Where-Object { $_ -match '^HTTP/' } | Select-Object -First 1)
    $statusCode = if ($statusLine -match 'HTTP/\S+\s+(\d+)') { [int]$Matches[1] } else { $exitCode * -1 }

    # Extract new ETag
    $newETag = ''
    if ($responseText -match '(?im)^etag:\s*(.+)$') {
        $newETag = $Matches[1].Trim()
    }

    # Extract X-Poll-Interval hint (GitHub may throttle slower under load)
    $serverInterval = $PollInterval
    if ($responseText -match '(?im)^x-poll-interval:\s*(\d+)') {
        $serverInterval = [int]$Matches[1]
    }

    # 304 = nothing changed
    if ($statusCode -eq 304) {
        return [PSCustomObject]@{
            Status        = 304
            Events        = @()
            ETag          = $newETag
            PollInterval  = $serverInterval
        }
    }

    # Parse JSON body — it follows the blank line after headers
    $jsonBody = ''
    if ($responseText -match '(?s)\r?\n\r?\n(.+)$') {
        $jsonBody = $Matches[1].Trim()
    }

    $events = @()
    if ($jsonBody -and $statusCode -eq 200) {
        try {
            $parsed = $jsonBody | ConvertFrom-Json -AsHashtable
            $events = @($parsed)
        }
        catch {
            $events = @()
        }
    }

    return [PSCustomObject]@{
        Status       = $statusCode
        Events       = $events
        ETag         = $newETag
        PollInterval = $serverInterval
    }
}

# ── Main loop ────────────────────────────────────────────────────────────────
$logPath       = Initialize-Log
$currentETag   = ''
$seenIds       = [System.Collections.Generic.HashSet[string]]::new()
$runCount      = 0
$effectiveWait = $PollInterval

if ($DryRun) {
    Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [DRYRUN ] DryRun active — log writes suppressed"
}

Write-Log -LogPath $logPath -Level 'START' -Message "Watching $Repo | interval=${PollInterval}s | filters=$($TypeFilter -join ',')"

while ($true) {
    $runCount++
    Write-Log -LogPath $logPath -Level 'POLL' -Message "Poll #$runCount (ETag: $(if ($currentETag) { $currentETag.Substring(0, [Math]::Min(20,$currentETag.Length)) + '...' } else { 'none' }))"

    try {
        $result = Invoke-Poll -ETag $currentETag

        # Update ETag for next conditional poll
        if ($result.ETag) { $currentETag = $result.ETag }

        # Respect server's poll interval hint (never go below it)
        $effectiveWait = [Math]::Max($PollInterval, $result.PollInterval)

        if ($result.Status -eq 304) {
            Write-Log -LogPath $logPath -Level 'NOCHANGE' -Message "304 Not Modified — no new events"
        }
        elseif ($result.Status -eq 200) {
            $filtered = @($result.Events | Where-Object { $TypeFilter -contains $_.type })
            $newEvents = @($filtered | Where-Object { -not $seenIds.Contains($_.id) })

            foreach ($evt in $newEvents) {
                $seenIds.Add($evt.id) | Out-Null
                $line = Format-EventLine -Evt $evt
                Write-Log -LogPath $logPath -Level 'EVENT' -Message $line
            }

            if ($newEvents.Count -eq 0) {
                Write-Log -LogPath $logPath -Level 'INFO' -Message "200 OK — $($result.Events.Count) total events, 0 new after filter"
            }
            else {
                Write-Log -LogPath $logPath -Level 'SUCCESS' -Message "$($newEvents.Count) new event(s) surfaced"
            }
        }
        else {
            Write-Log -LogPath $logPath -Level 'WARN' -Message "Unexpected HTTP $($result.Status) — skipping cycle"
        }
    }
    catch {
        Write-Log -LogPath $logPath -Level 'ERROR' -Message "Poll failed: $_"
    }

    # Exit after MaxRuns if set
    if ($MaxRuns -gt 0 -and $runCount -ge $MaxRuns) {
        Write-Log -LogPath $logPath -Level 'STOP' -Message "MaxRuns=$MaxRuns reached — exiting"
        break
    }

    Write-Log -LogPath $logPath -Level 'WAIT' -Message "Sleeping ${effectiveWait}s until next poll..."
    Start-Sleep -Seconds $effectiveWait
}
