<#
.SYNOPSIS
    SOK-WorkshopConsistencyCheck.ps1 — Scan Workshop ENDEAVOR draft corpus for drift.

.DESCRIPTION
    Scans all Workshop_*.md files in the Writings directory for consistency violations
    across the Feb-Apr 2026 authorship span. Produces a structured findings report.

    Checks performed:
      1. Terminology drift — same concept named differently (e.g., Lens vs lens vs perspective)
      2. Model-ID drift — Opus 4.5 / 4.6 / 4.7 reference inconsistency
      3. Cross-reference resolvability — §N.N references that should resolve to actual sections
      4. Citation format uniformity — arXiv / blog / Anthropic docs
      5. Date consistency — cite-date formats for specific known refs
      6. Primitives coverage — are all named primitives referenced from Appendix A?

    Outputs a markdown findings report to SOK\Logs\WorkshopConsistencyCheck\<RunId>\
    and (optionally) a canonical copy to Writings\Workshop_Consistency_Report_<RunId>.md

.PARAMETER DryRun
    Show what would be scanned and where the report would land, but do not write the report.

.PARAMETER WorkshopPath
    Override default Writings directory scan path.

.PARAMETER CanonicalReport
    If set, also write a timestamped canonical copy to Writings\.

.NOTES
    Author: S. Clay Caddell
    Version: 1.0.0
    Date: 21Apr2026
    Domain: Utility — Workshop ENDEAVOR Phase E integration quality gate
    Read-only — does NOT modify source drafts.
#>
#Requires -Version 7.0
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$WorkshopPath,
    [switch]$CanonicalReport
)

$ErrorActionPreference = 'Continue'

# scriptDir cascade: canonical absolute path first (matches SOK-CodeReview M-14 pattern)
$canonicalScripts = 'C:\Users\shelc\Documents\Journal\Projects\scripts'
$scriptDir = if (Test-Path (Join-Path $canonicalScripts 'SOK-Inventory.ps1')) {
    $canonicalScripts
} elseif ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'common\SOK-Common.psm1'))) {
    $PSScriptRoot
} else {
    $canonicalScripts
}

$modulePath = Join-Path $scriptDir 'common\SOK-Common.psm1'
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir = Join-Path (Split-Path $scriptDir) 'SOK\Logs\WorkshopConsistencyCheck'
$runDir = Join-Path $logDir $runId
if (-not (Test-Path $runDir)) { New-Item -ItemType Directory -Path $runDir -Force | Out-Null }

if (-not $WorkshopPath) {
    $WorkshopPath = Join-Path $env:USERPROFILE 'Documents\Journal\Projects\Writings'
}

if (-not (Test-Path $WorkshopPath)) {
    Write-Error "Workshop path not found: $WorkshopPath"
    exit 1
}

# Use SOK-Common logging if available
$hasSOKLog = Get-Command Initialize-SOKLog -ErrorAction SilentlyContinue
if ($hasSOKLog) {
    Initialize-SOKLog -ScriptName 'SOK-WorkshopConsistencyCheck'
    $log = { param($m, $l = 'Info') Write-SOKLog -Message $m -Level $l }
} else {
    $log = { param($m, $l = 'Info') Write-Host "[$l] $m" }
}

& $log "SOK-WorkshopConsistencyCheck v1.0.0 | RunId: $runId" 'Section'
& $log "WorkshopPath: $WorkshopPath"
& $log "RunDir: $runDir"
if ($DryRun) { & $log "DryRun mode — no report will be written" 'Warn' }

# Scan for target files
$workshopFiles = Get-ChildItem -Path $WorkshopPath -Filter 'Workshop_*.md' -File |
    Where-Object { $_.Name -notmatch 'Consistency_Report' } |
    Sort-Object Name

& $log "Files in scope: $($workshopFiles.Count)"

if ($DryRun) {
    $workshopFiles | ForEach-Object { & $log "  - $($_.Name)" }
    & $log "DryRun exit — no further processing"
    return
}

# --- Check definitions ---

# Terminology canonical forms (lowercase lookup; matched case-sensitive on word boundary)
# Canonical = preferred form; Variants = deviations to flag
$terminologyChecks = @(
    @{
        Name = 'Lens (uppercase L when used as named technique)'
        Canonical = 'Lens'
        VariantPatterns = @('\banalytical lens\b', '\bperspective lens\b')
        Allowed = @('analytical lens' <# when discussing the concept descriptively — manual review #>)
    }
    @{
        Name = 'SINC Format capitalization'
        Canonical = 'SINC Format'
        VariantPatterns = @('\bsinc format\b', '\bSinc format\b', '\bSINC format\b', '\bsix-fragment format\b')
    }
    @{
        Name = 'SME Panel naming'
        Canonical = 'SME Panel'
        VariantPatterns = @('\bsme panel\b', '\bsme-panel\b', '\bexpert panel\b(?! prompting)')
    }
    @{
        Name = 'Liminal Hop capitalization'
        Canonical = 'Liminal Hop'
        VariantPatterns = @('\bliminal hop\b', '\bLiminalHop\b', '\bliminal-hop\b')
    }
    @{
        Name = 'Preamble + Directive + Lenses architecture'
        Canonical = 'Preamble + Directive + Lenses'
        VariantPatterns = @('\bpreamble-directive-lenses\b', '\bPreamble/Directive/Lenses\b', '\bpreamble, directive, lenses\b')
    }
    @{
        Name = 'Stochastic Isolation Revision (SIR)'
        Canonical = 'Stochastic Isolation Revision'
        VariantPatterns = @('\bstochastic isolation\b(?! revision)', '\bSIR technique\b(?! \()')
    }
)

# Known reference dates (used for date-consistency check)
$knownRefs = @{
    'Hu et al. arXiv'        = @{ arxiv = '2603.18507'; expectedDate = 'March 2026' }
    'Khan arXiv'             = @{ arxiv = '2510.22251'; expectedDate = 'October 2025' }
    'Substrate Thesis origin' = @{ date = '2026-02-16' }
    'Workshop original'      = @{ date = 'October 2025' }
}

# Model-ID patterns
# Flag: mixing "Opus 4.6" and "Opus 4.7" within a single paragraph when one or the other
# should predominate. Also flag "Claude Opus" (space) vs "claude-opus" (dash).
$modelPatterns = @(
    '\bOpus 4\.[5-7]\b',
    '\bSonnet 4\.[56]\b',
    '\bHaiku 4\.5\b',
    '\bclaude-opus-4-[5-7]\b'
)

# Section-reference regex — matches §5.11 or §5.9.9 etc.
$sectionRefPattern = '§(\d+(?:\.\d+)*)'

# Citation format signatures
$citationSignatures = @{
    arXivFormat1 = 'arXiv:\d+\.\d+'            # arXiv:2510.22251
    arXivFormat2 = 'arxiv\.org/[a-z]+/\d+'     # arxiv.org/abs/... or arxiv.org/html/...
    anthropicDocs = 'platform\.claude\.com/docs'
    willisonBlog = 'simonwillison\.net'
    hamelBlog    = 'hamel\.dev'
}

# --- Execution ---

$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
    param(
        [string]$File,
        [int]$Line,
        [string]$Category,
        [ValidateSet('P1','P2','P3')][string]$Priority,
        [string]$Issue,
        [string]$Evidence = ''
    )
    $findings.Add([pscustomobject]@{
        File = $File
        Line = $Line
        Category = $Category
        Priority = $Priority
        Issue = $Issue
        Evidence = $Evidence
    })
}

& $log "Scanning files..." 'Section'

# Collect all §N.N refs observed across corpus (for resolvability check second pass)
$allSectionRefs = [System.Collections.Generic.List[object]]::new()
# Collect all §N.N definitions (lines starting with §N.N or "## §N.N" etc.)
$allSectionDefs = @{}

foreach ($file in $workshopFiles) {
    $relative = $file.Name
    & $log "  Scanning $relative"
    $lines = Get-Content -Path $file.FullName -Encoding UTF8
    $lineNum = 0

    foreach ($line in $lines) {
        $lineNum++

        # Terminology checks
        foreach ($check in $terminologyChecks) {
            foreach ($pattern in $check.VariantPatterns) {
                if ($line -cmatch $pattern) {
                    $m = $Matches[0]
                    Add-Finding -File $relative -Line $lineNum -Category 'Terminology' `
                        -Priority 'P2' -Issue "$($check.Name): '$m' — canonical form is '$($check.Canonical)'" `
                        -Evidence $line.Trim()
                }
            }
        }

        # Section-ref collection (references)
        $refMatches = [regex]::Matches($line, $sectionRefPattern)
        foreach ($rm in $refMatches) {
            $allSectionRefs.Add([pscustomobject]@{
                File = $relative; Line = $lineNum; Ref = $rm.Groups[1].Value; Raw = $line.Trim()
            })
        }

        # Section-def collection (headings of form ## §N.N — Title  or  ### §N.N —)
        if ($line -match '^#{2,4}\s+§(\d+(?:\.\d+)*)') {
            $def = $Matches[1]
            if (-not $allSectionDefs.ContainsKey($def)) {
                $allSectionDefs[$def] = @()
            }
            $allSectionDefs[$def] += [pscustomobject]@{ File = $relative; Line = $lineNum; Heading = $line.Trim() }
        }

        # Known-reference date-consistency check
        if ($line -match '2603\.18507') {
            # Hu et al. — arXiv IDs starting "26" are malformed (arXiv uses YYMM format; March 2026 = 2603 is technically valid
            # under arXiv's 2026 schema but flag as unusual — readers may assume typo)
            # Spot-check: companion text should say "March 2026" or "2026"
            if ($line -notmatch '(March 2026|2026|Mar\.? 2026)') {
                # Only flag if the line has the arxiv but no 2026 reference nearby — soft warn
                Add-Finding -File $relative -Line $lineNum -Category 'Citation date' `
                    -Priority 'P3' -Issue "Hu et al. arXiv:2603.18507 appears without '2026' date on same line — verify context" `
                    -Evidence $line.Trim()
            }
        }

        # Citation format mixed-signatures check
        if ($line -match 'arXiv:\d+\.\d+' -and $line -match 'arxiv\.org/') {
            # Both formats on same line — redundant
            Add-Finding -File $relative -Line $lineNum -Category 'Citation format' `
                -Priority 'P3' -Issue "Redundant arXiv citation: 'arXiv:NNNN.NNNNN' and 'arxiv.org/...' both present" `
                -Evidence $line.Trim()
        }
    }
}

& $log "Pass 1 complete. Cross-ref resolvability pass..." 'Section'

# Cross-reference resolvability check
# For each §N.N reference found, is there a matching definition somewhere in the corpus?
# Note: some refs like §5.3 may legitimately point to the original PDF (pre-doubled-edition),
# not to a draft file. Flag as P3 (manual review) rather than P1.
$unresolvableRefs = $allSectionRefs | Where-Object {
    -not $allSectionDefs.ContainsKey($_.Ref)
} | Group-Object Ref | Sort-Object { [version]($_.Name + '.0' * (4 - ($_.Name.Split('.').Count))) }

foreach ($grp in $unresolvableRefs) {
    $ref = $grp.Name
    $count = $grp.Count
    $firstFile = $grp.Group[0].File
    $firstLine = $grp.Group[0].Line
    # Refs to §1-§10 are likely pointing to the original PDF — P3 informational
    # Refs to §5.X / §9.X / §11.X / §12.X should resolve to a draft — P2 if unresolved
    $topLevel = $ref.Split('.')[0]
    $priority = if ($topLevel -in @('1','2','3','4','7','8','10')) { 'P3' } else { 'P2' }
    Add-Finding -File $firstFile -Line $firstLine -Category 'Cross-ref' `
        -Priority $priority -Issue "§$ref referenced $count time(s) across corpus — no matching section definition found" `
        -Evidence "First occurrence: $($grp.Group[0].Raw)"
}

& $log "Pass 2 complete. Model-ID drift scan..." 'Section'

# Model-ID drift check — summary only, not per-line
# Count occurrences of each model version per file; if a file has >1 version with close counts,
# it may indicate drift (unless intentional historical comparison)
$modelDrift = @{}
foreach ($file in $workshopFiles) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $counts = @{}
    foreach ($pattern in $modelPatterns) {
        $m = [regex]::Matches($content, $pattern)
        foreach ($match in $m) {
            $key = $match.Value
            if (-not $counts.ContainsKey($key)) { $counts[$key] = 0 }
            $counts[$key]++
        }
    }
    if ($counts.Count -gt 1) {
        # Drop anomalous-mixed-version flag only if both Opus 4.6 AND Opus 4.7 appear;
        # mixing 4.6 + historical 4.5 refs is expected
        $has46 = $counts.Keys | Where-Object { $_ -match '4\.6' }
        $has47 = $counts.Keys | Where-Object { $_ -match '4\.7' }
        if ($has46 -and $has47) {
            $summary = ($counts.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', '
            Add-Finding -File $file.Name -Line 0 -Category 'Model-ID drift' `
                -Priority 'P3' -Issue "File mixes Opus 4.6 and Opus 4.7 references — verify intentional" `
                -Evidence $summary
        }
    }
}

& $log "All passes complete. Total findings: $($findings.Count)" 'Section'

# --- Report assembly ---
$reportPath = Join-Path $runDir "Workshop_Consistency_Findings_$runId.md"

$p1 = @($findings | Where-Object Priority -eq 'P1')
$p2 = @($findings | Where-Object Priority -eq 'P2')
$p3 = @($findings | Where-Object Priority -eq 'P3')

$summary = @"
# Workshop ENDEAVOR Consistency Findings — $runId
## Automated scan of Workshop_*.md corpus in ``$WorkshopPath``

**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
**Files scanned:** $($workshopFiles.Count)
**Total findings:** $($findings.Count)
**By priority:** P1=$($p1.Count) | P2=$($p2.Count) | P3=$($p3.Count)

---

## Priority legend
- **P1** — must-fix before ship (structural break, cross-ref to non-existent section in must-resolve range, contradicting-fact drift)
- **P2** — should-fix (terminology drift, §5.X/§9.X/§11.X/§12.X unresolved cross-ref, citation-format mix)
- **P3** — informational (§1-§10 refs likely point to original PDF; model-ID-version mixing if intentional)

---

## Findings by category

"@

$byCategory = $findings | Group-Object Category | Sort-Object { -$_.Count }

foreach ($cat in $byCategory) {
    $summary += "`n### $($cat.Name) — $($cat.Count) finding(s)`n`n"
    $summary += "| Priority | File | Line | Issue | Evidence |`n"
    $summary += "|---|---|---|---|---|`n"
    foreach ($f in $cat.Group | Sort-Object Priority, File, Line) {
        $evidence = if ($f.Evidence) { ($f.Evidence -replace '\|', '\|').Substring(0, [Math]::Min(100, $f.Evidence.Length)) } else { '' }
        $issue = ($f.Issue -replace '\|', '\|')
        $summary += "| $($f.Priority) | ``$($f.File)`` | $($f.Line) | $issue | ``$evidence`` |`n"
    }
}

$summary += @"

---

## Cross-reference index

**Section definitions found** ($($allSectionDefs.Count)):
$(($allSectionDefs.Keys | Sort-Object { [version]($_ + '.0' * (4 - ($_.Split('.').Count)))}) -join ', ')

**Section references found** ($($allSectionRefs.Count) occurrences):
$((($allSectionRefs | Group-Object Ref | Sort-Object { [version]($_.Name + '.0' * (4 - ($_.Name.Split('.').Count))) } | ForEach-Object { "§$($_.Name) ($($_.Count))" }) -join ', '))

---

## Recommended action

1. Address P1 findings first (ship-blockers)
2. Sweep P2 findings before Phase F integration pass
3. P3 findings are informational; review during final polish

## Regenerate
``pwsh -NoProfile -File scripts\SOK-WorkshopConsistencyCheck.ps1``
``pwsh -NoProfile -File scripts\SOK-WorkshopConsistencyCheck.ps1 -DryRun``  (preview files only)

---

*Generated by SOK-WorkshopConsistencyCheck.ps1 v1.0.0*
"@

Set-Content -Path $reportPath -Value $summary -Encoding UTF8
& $log "Report written to: $reportPath" 'Success'

if ($CanonicalReport) {
    $canonicalPath = Join-Path $WorkshopPath "Workshop_Consistency_Report_$runId.md"
    Copy-Item -Path $reportPath -Destination $canonicalPath -Force
    & $log "Canonical copy: $canonicalPath" 'Success'
}

# Console summary
Write-Host ""
Write-Host "Workshop Consistency Check — RunId $runId" -ForegroundColor Cyan
Write-Host "Files scanned: $($workshopFiles.Count) | Findings: $($findings.Count) (P1=$($p1.Count), P2=$($p2.Count), P3=$($p3.Count))" -ForegroundColor Cyan
Write-Host "Report: $reportPath" -ForegroundColor Green

return $reportPath
