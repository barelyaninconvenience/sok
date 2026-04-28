#Requires -Version 7.0
<#
.SYNOPSIS
    Cross-class deadline aggregator for UC MS-IS Spring 2026 semester.

.DESCRIPTION
    Scans class folders under the Spring 2026 root, reads Canvas capture
    indices, extracts lines containing assignment-like patterns (months,
    due dates, point values), and produces a unified deadline dashboard.

    Forgiving-parse approach: grabs raw markdown lines that look assignment-
    shaped and presents them with light structure. Canvas is authoritative
    for submission status; this tool reports local-view only.

.PARAMETER SemesterRoot
    Path to the Spring 2026 semester folder.

.PARAMETER OutputDir
    Where to write the dashboard artifacts.

.PARAMETER DryRun
    Preview outputs without writing files.

.EXAMPLE
    pwsh -File Get-ClassDeadlineAggregator.ps1

.NOTES
    Built 2026-04-22 overnight. v1 — forgiving parse. Clay can iterate.
#>
[CmdletBinding()]
param(
    [string]$SemesterRoot = 'C:\Users\shelc\Documents\UC MS-IS\SPRING 2026',
    [string]$OutputDir = 'C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\DeadlineAggregator',
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$today = Get-Date
$null = New-Item $OutputDir -ItemType Directory -Force -ErrorAction SilentlyContinue
$runDir = Join-Path $OutputDir $timestamp
$null = New-Item $runDir -ItemType Directory -Force -ErrorAction SilentlyContinue

Write-Host "━━━ Deadline Aggregator v1 ━━━" -ForegroundColor Cyan
Write-Host "Today: $($today.ToString('yyyy-MM-dd dddd'))"
Write-Host ""

# Class discovery
$classFolders = @(Get-ChildItem $SemesterRoot -Directory -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match '^(IS|IT|MKTG|FIN|COMM|MATH|STAT)\s*\d{4}'
})
if (-not $classFolders) {
    Write-Host "No class folders under $SemesterRoot" -ForegroundColor Yellow
    exit 1
}
Write-Host "Classes: $($classFolders.Count)" -ForegroundColor Green
$classFolders | ForEach-Object { Write-Host "  $($_.Name)" }
Write-Host ""

$monthPattern = '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)(?:ruary|uary|ch|il|e|y|ust|tember|ober|ember)?\s+\d{1,2}'
$pointsPattern = '(\d+)\s*(?:/\s*\d+|\s*pts?|\s*points?)'

# Build dashboard
$md = [System.Text.StringBuilder]::new()
$null = $md.AppendLine("# Class Deadline Dashboard")
$null = $md.AppendLine("## Generated $($today.ToString('yyyy-MM-dd HH:mm dddd'))")
$null = $md.AppendLine("## By Get-ClassDeadlineAggregator.ps1 (v1, forgiving-parse)")
$null = $md.AppendLine("")
$null = $md.AppendLine("**Canvas is authoritative.** This report aggregates Canvas_Captures data — captures may be stale.")
$null = $md.AppendLine("")

# Per-class section
$classSummaries = @()
foreach ($classFolder in $classFolders) {
    $className = ($classFolder.Name -split '\s+')[0]
    Write-Host "Processing $className..." -ForegroundColor Gray

    $captureIndex = Get-ChildItem $classFolder.FullName -Filter "_assignments*.md" -Recurse -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $null = $md.AppendLine("---")
    $null = $md.AppendLine("")
    $null = $md.AppendLine("## ${className}")
    $null = $md.AppendLine("")
    $null = $md.AppendLine("**Folder**: ``$($classFolder.Name)``")
    if ($captureIndex) {
        $captureAge = [int]((Get-Date) - $captureIndex.LastWriteTime).TotalDays
        $null = $md.AppendLine("**Capture**: ``$($captureIndex.Name)`` (age: ${captureAge} days)")
        $null = $md.AppendLine("")

        # Extract assignment-like lines
        $content = Get-Content $captureIndex.FullName -Raw
        $lines = $content -split "`n"
        $matchedLines = @()
        foreach ($line in $lines) {
            if ($line -match $monthPattern -and $line.Trim().Length -gt 20) {
                # Clean markdown pipes
                $cleaned = $line.Trim() -replace '^\|+\s*','' -replace '\s*\|+$','' -replace '\|', ' · '
                if ($cleaned -notmatch '^-+\s*·\s*-' -and $cleaned -notmatch '^Assignment\s*·') {
                    $matchedLines += $cleaned
                }
            }
        }

        if ($matchedLines) {
            $null = $md.AppendLine("**Deadline-bearing lines found**: $($matchedLines.Count)")
            $null = $md.AppendLine("")
            foreach ($ml in ($matchedLines | Select-Object -First 25)) {
                # Try to surface due date and urgency
                $dateMatch = [regex]::Match($ml, $monthPattern)
                $dateStr = if ($dateMatch.Success) { $dateMatch.Value } else { "?" }
                $parsed = $null
                try { $parsed = [datetime]::ParseExact("$dateStr $($today.Year)", 'MMM d yyyy', $null) } catch {}
                try { if (-not $parsed) { $parsed = [datetime]::ParseExact("$dateStr $($today.Year)", 'MMMM d yyyy', $null) } } catch {}

                $flag = ''
                if ($parsed) {
                    $daysUntil = [int]($parsed - $today).TotalDays
                    $flag = if ($daysUntil -lt 0) { "🔴 PAST ($([Math]::Abs($daysUntil))d ago)" }
                            elseif ($daysUntil -eq 0) { "🟠 TODAY" }
                            elseif ($daysUntil -le 2) { "🟡 in ${daysUntil}d" }
                            elseif ($daysUntil -le 7) { "🟢 in ${daysUntil}d" }
                            else { "🔵 in ${daysUntil}d" }
                }

                $null = $md.AppendLine("- ${flag} ${ml}")
            }
            if ($matchedLines.Count -gt 25) {
                $null = $md.AppendLine("- ... and $($matchedLines.Count - 25) more (truncated)")
            }
            $null = $md.AppendLine("")

            $classSummaries += [PSCustomObject]@{
                Class = $className
                LinesExtracted = $matchedLines.Count
                CaptureAgeDays = $captureAge
            }
        } else {
            $null = $md.AppendLine("*No deadline-bearing lines matched the pattern.*")
            $null = $md.AppendLine("")
        }
    } else {
        $null = $md.AppendLine("")
        $null = $md.AppendLine("*No Canvas capture index found. Visit Canvas to capture assignments master-index for this class.*")
        $null = $md.AppendLine("")
        $classSummaries += [PSCustomObject]@{
            Class = $className
            LinesExtracted = 0
            CaptureAgeDays = -1
        }
    }
}

# Summary footer
$null = $md.AppendLine("---")
$null = $md.AppendLine("")
$null = $md.AppendLine("## Summary")
$null = $md.AppendLine("")
$null = $md.AppendLine("| Class | Lines | Capture age |")
$null = $md.AppendLine("|-------|-------|-------------|")
foreach ($s in $classSummaries) {
    $age = if ($s.CaptureAgeDays -ge 0) { "${($s.CaptureAgeDays)}d" } else { "no capture" }
    $null = $md.AppendLine("| $($s.Class) | $($s.LinesExtracted) | $age |")
}
$null = $md.AppendLine("")
$null = $md.AppendLine("---")
$null = $md.AppendLine("")
$null = $md.AppendLine("*v1 forgiving-parse. Legend: 🔴 past · 🟠 today · 🟡 soon (≤2d) · 🟢 this week · 🔵 ahead.*")

$mdPath = Join-Path $runDir "deadline_dashboard.md"
$jsonPath = Join-Path $runDir "deadlines.json"

if ($DryRun) {
    Write-Host "DRY RUN — would write to ${mdPath}" -ForegroundColor Yellow
    Write-Host ""
    $md.ToString().Split("`n") | Select-Object -First 40 | ForEach-Object { Write-Host $_ }
} else {
    $md.ToString() | Set-Content -Path $mdPath -Encoding UTF8
    $classSummaries | ConvertTo-Json -Depth 3 | Set-Content -Path $jsonPath -Encoding UTF8
    Write-Host "Wrote:" -ForegroundColor Green
    Write-Host "  $mdPath"
    Write-Host "  $jsonPath"
    Write-Host ""
    Write-Host "Total classes: $($classSummaries.Count)"
    Write-Host "Total deadline lines: $(($classSummaries | Measure-Object -Property LinesExtracted -Sum).Sum)"
}

Write-Host ""
Write-Host "━━━ Done ━━━" -ForegroundColor Cyan
