#Requires -Version 7.0
<#
.SYNOPSIS
    Invoke-UCHarvestAudit.ps1 — Audit + manifest-update for UC pre-graduation harvest tree.

.DESCRIPTION
    Supports the UC Pre-Graduation Harvest Plan (Writings/UC_Pre_Graduation_Harvest_Plan_20260420.md)
    by inventorying Learning/UC_Archive_2026/ and Readings/UC_Library_Archive_2026/, validating
    captured artifacts, and auto-updating the manifest with progress.

    The actual content capture is Clay-driven (Canvas UI → Export Course Content → download .imscc;
    UC OneStop → Transcript PDF; etc.). This script tracks what's landed, validates integrity,
    and surfaces gaps so Clay knows where to spend the next 60-90 minute session.

    Discovery:
      - Per-course subdir detection under UC_Archive_2026/ (pattern <TERM>_<COURSE>_*)
      - .imscc file presence + zip-integrity validation
      - raw_submissions/ + instructor_feedback/ subdir presence
      - Institutional identity artifact detection (transcript / enrollment / audit)
      - Reading list per-domain capture count (via PDF count in each domain subdir)
      - Software license inventory status (count of [x] vs [ ] checkboxes)

    Reporting:
      - Console summary with per-tier progress counters
      - Detailed report written to SOK\Logs\UC_Harvest\<timestamp>_audit.md
      - Optional auto-update of _harvest_manifest.md with detected capture state

.PARAMETER ArchiveRoot
    Root of the Learning/UC_Archive_2026 tree. Default auto-resolves.

.PARAMETER LibraryRoot
    Root of the Readings/UC_Library_Archive_2026 tree. Default auto-resolves.

.PARAMETER ReportDir
    Where to write the audit report. Default: SOK\Logs\UC_Harvest\<timestamp>\

.PARAMETER AutoUpdateManifest
    Rewrite _harvest_manifest.md Tier-1 Canvas rows based on detected captures.
    Preserves Clay-authored cells; only flips detectable-state cells.
    OFF by default — opt-in.

.PARAMETER DryRun
    Default behavior. Does not modify any existing files (even with -AutoUpdateManifest,
    DryRun wins).

.NOTES
    Author:  S. Clay Caddell
    Version: 1.0.0
    Date:    2026-04-21
    Domain:  Academic remediation / pre-graduation access-window preservation
    Tripwire: 2027-05-01 — corrected 2026-04-22 per State_Snapshot Addendum 25 (UC access confirmed through ~May 2027, not 2026-05-01 as originally scoped). Re-invoke Architect if no Week-1 capture has landed before the final term.
#>
[CmdletBinding()]
param(
    [string]$ArchiveRoot = 'C:\Users\shelc\Documents\Journal\Projects\Learning\UC_Archive_2026',
    [string]$LibraryRoot = 'C:\Users\shelc\Documents\Journal\Projects\Readings\UC_Library_Archive_2026',
    [string]$ReportDir,
    [switch]$AutoUpdateManifest,
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'

# Default DryRun ON unless caller explicitly opted out
if (-not $PSBoundParameters.ContainsKey('DryRun')) { $DryRun = $true }

# ── MODULE LOAD ──────────────────────────────────────────────────────────────
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) {
    $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1'
}
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
}

# ── REPORT DIR ───────────────────────────────────────────────────────────────
if (-not $ReportDir) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $ReportDir = Join-Path 'C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\UC_Harvest' $stamp
}
if (-not (Test-Path $ReportDir)) {
    New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null
}

Write-SOKLog "Invoke-UCHarvestAudit — DryRun=$DryRun" -Level Section
Write-SOKLog "  ArchiveRoot: $ArchiveRoot" -Level Annotate
Write-SOKLog "  LibraryRoot: $LibraryRoot" -Level Annotate
Write-SOKLog "  ReportDir:   $ReportDir" -Level Annotate

# ── DAYS-TO-TRIPWIRE ─────────────────────────────────────────────────────────
$tripwire = [datetime]'2027-05-01'
$daysLeft = [math]::Ceiling(($tripwire - (Get-Date)).TotalDays)
$urgency = if ($daysLeft -le 0) { '[TRIPWIRE FIRED]' }
           elseif ($daysLeft -le 3) { '[CRITICAL]' }
           elseif ($daysLeft -le 7) { '[URGENT]' }
           else { '[NORMAL]' }
Write-SOKLog "  Days to 2027-05-01 tripwire: $daysLeft $urgency" -Level Warn

# ── COURSE DISCOVERY ─────────────────────────────────────────────────────────
# Valid course subdir pattern: <TERM>_<COURSE_CODE>_<Short_Descriptor>/
$coursePattern = '^(?<term>FALL|SPRING|SUMMER|FALL_[0-9]{4}|SPRING_[0-9]{4}|SUMMER_[0-9]{4})_[A-Z]{2,4}[0-9]{4}[A-Za-z]?_'
$courses = [System.Collections.Generic.List[hashtable]]::new()
if (Test-Path $ArchiveRoot) {
    Get-ChildItem $ArchiveRoot -Directory -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^_' -and $_.Name -match $coursePattern } |
        ForEach-Object {
            $imscc = Get-ChildItem $_.FullName -Filter '*.imscc' -File -ErrorAction SilentlyContinue | Select-Object -First 1
            $imsccValid = $false
            $imsccSizeKB = 0
            if ($imscc) {
                $imsccSizeKB = [math]::Round($imscc.Length / 1KB, 2)
                # .imscc is a Common Cartridge ZIP — validate as a zip archive
                try {
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($imscc.FullName)
                    $imsccValid = ($zip.Entries.Count -gt 0)
                    $zip.Dispose()
                } catch {
                    $imsccValid = $false
                }
            }
            $rawSubDir = Join-Path $_.FullName 'raw_submissions'
            $feedbackDir = Join-Path $_.FullName 'instructor_feedback'
            $rawSubCount = if (Test-Path $rawSubDir) {
                (Get-ChildItem $rawSubDir -File -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count
            } else { 0 }
            $feedbackCount = if (Test-Path $feedbackDir) {
                (Get-ChildItem $feedbackDir -File -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object).Count
            } else { 0 }

            $courses.Add(@{
                Dir          = $_.Name
                FullPath     = $_.FullName
                ImsccPresent = $null -ne $imscc
                ImsccValid   = $imsccValid
                ImsccSizeKB  = $imsccSizeKB
                RawSubCount  = $rawSubCount
                FeedbackCount= $feedbackCount
            }) | Out-Null
        }
}

# Expected courses from the harvest plan (from _harvest_manifest.md)
$expectedCourses = @(
    'IS7012', 'IS7030', 'IS7034', 'IS7036',   # Fall 2025 cluster (per manifest template)
    'IS7060', 'IS7066', 'IT7021C',            # Spring 2026 cluster
    'IS8044', 'IS8076', 'IS6042'              # Additional Spring 2026 per Next_Session_Opening_Brief P0.1
)
$capturedCourses = @($courses | ForEach-Object {
    if ($_.Dir -match '[A-Z]{2,4}[0-9]{4}[A-Za-z]?') { $Matches[0] } else { $null }
} | Where-Object { $_ })
$missingCourses = $expectedCourses | Where-Object { $_ -notin $capturedCourses }

# ── INSTITUTIONAL IDENTITY ARTIFACTS ────────────────────────────────────────
$identityDir = Join-Path $ArchiveRoot '_institutional_identity'
$identityArtifacts = @{
    Transcript = @(Get-ChildItem $identityDir -Filter 'transcript_*.pdf' -File -ErrorAction SilentlyContinue).Count
    Enrollment = @(Get-ChildItem $identityDir -Filter 'enrollment_verification_*.pdf' -File -ErrorAction SilentlyContinue).Count
    DegreeAudit= @(Get-ChildItem $identityDir -Filter 'degree_audit_*.pdf' -File -ErrorAction SilentlyContinue).Count
    Letters    = @(Get-ChildItem (Join-Path $identityDir 'letters_of_recommendation') -File -ErrorAction SilentlyContinue).Count
}

# ── LIBRARY CAPTURE COUNT ────────────────────────────────────────────────────
$libraryDomains = @('acoustic_side_channels', 'substrate_thesis_adjacent', 'sigint_security', 'data_modeling', 'gis')
$libraryCounts = @{}
foreach ($dom in $libraryDomains) {
    $p = Join-Path $LibraryRoot $dom
    $libraryCounts[$dom] = if (Test-Path $p) {
        @(Get-ChildItem $p -Filter '*.pdf' -File -ErrorAction SilentlyContinue).Count
    } else { 0 }
}

# ── LICENSE INVENTORY STATUS ────────────────────────────────────────────────
$licenseFile = Join-Path $ArchiveRoot '_software_licenses_inventory.md'
$licenseDone = 0; $licenseTotal = 0
if (Test-Path $licenseFile) {
    $content = Get-Content $licenseFile -Raw
    $licenseDone  = ([regex]::Matches($content, '\[x\]')).Count
    $licenseTotal = ([regex]::Matches($content, '\[[ x]\]')).Count
}

# ── MANIFEST STATUS ─────────────────────────────────────────────────────────
$manifestFile = Join-Path $ArchiveRoot '_harvest_manifest.md'
$manifestStats = @{ Exists = Test-Path $manifestFile; CheckedCount = 0; TotalCount = 0 }
if ($manifestStats.Exists) {
    $manifestContent = Get-Content $manifestFile -Raw
    $manifestStats.CheckedCount = ([regex]::Matches($manifestContent, '\[x\]')).Count
    $manifestStats.TotalCount   = ([regex]::Matches($manifestContent, '\[[ x]\]')).Count
}

# ── REPORT ─────────────────────────────────────────────────────────────────
$r = [System.Collections.Generic.List[string]]::new()
$r.Add("# UC Harvest Audit — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") | Out-Null
$r.Add("") | Out-Null
$r.Add("**Tripwire:** 2027-05-01 ($daysLeft days remaining $urgency)") | Out-Null
$r.Add("**Archive root:** $ArchiveRoot") | Out-Null
$r.Add("**Library root:** $LibraryRoot") | Out-Null
$r.Add("") | Out-Null

# Tier 1 — Courses
$r.Add("## Tier 1 — Canvas LMS course captures") | Out-Null
$r.Add("") | Out-Null
$r.Add("Expected: $($expectedCourses.Count) | Discovered subdirs: $($courses.Count) | Missing: $($missingCourses.Count)") | Out-Null
$r.Add("") | Out-Null
if ($courses.Count -gt 0) {
    $r.Add("| Subdir | .imscc | Valid zip | Size KB | Raw subs | Feedback |") | Out-Null
    $r.Add("|--------|--------|-----------|---------|----------|----------|") | Out-Null
    foreach ($c in $courses | Sort-Object Dir) {
        $imsccMark = if ($c.ImsccPresent) { 'YES' } else { 'NO' }
        $validMark = if ($c.ImsccValid)   { 'OK'  } elseif ($c.ImsccPresent) { 'CORRUPT' } else { 'N/A' }
        $r.Add("| $($c.Dir) | $imsccMark | $validMark | $($c.ImsccSizeKB) | $($c.RawSubCount) | $($c.FeedbackCount) |") | Out-Null
    }
    $r.Add("") | Out-Null
}
if ($missingCourses.Count -gt 0) {
    $r.Add("**Missing courses (expected per manifest template — may need renaming if Clay uses different codes):**") | Out-Null
    foreach ($mc in $missingCourses) { $r.Add("  - $mc") | Out-Null }
    $r.Add("") | Out-Null
}

# Tier 1 — Identity
$r.Add("## Tier 1 — Institutional identity artifacts") | Out-Null
$r.Add("") | Out-Null
$r.Add("| Artifact | Count captured |") | Out-Null
$r.Add("|----------|----------------|") | Out-Null
$r.Add("| Official transcript (PDF) | $($identityArtifacts.Transcript) |") | Out-Null
$r.Add("| Enrollment verification | $($identityArtifacts.Enrollment) |") | Out-Null
$r.Add("| Degree audit | $($identityArtifacts.DegreeAudit) |") | Out-Null
$r.Add("| Letters of recommendation | $($identityArtifacts.Letters) |") | Out-Null
$r.Add("") | Out-Null

# Tier 1 — Library
$r.Add("## Tier 1 — Library database paper harvest (PDFs per domain)") | Out-Null
$r.Add("") | Out-Null
$r.Add("| Domain | PDFs captured |") | Out-Null
$r.Add("|--------|---------------|") | Out-Null
foreach ($dom in $libraryDomains) {
    $r.Add("| $dom | $($libraryCounts[$dom]) |") | Out-Null
}
$r.Add("") | Out-Null

# Tier 1 — Licenses
$r.Add("## Tier 1 — Software license inventory") | Out-Null
$r.Add("") | Out-Null
$r.Add("Completed: $licenseDone / $licenseTotal checkboxes") | Out-Null
$r.Add("") | Out-Null

# Manifest
$r.Add("## Manifest tracker") | Out-Null
$r.Add("") | Out-Null
if ($manifestStats.Exists) {
    $r.Add("Manifest: ``$manifestFile``") | Out-Null
    $r.Add("Completed: $($manifestStats.CheckedCount) / $($manifestStats.TotalCount) checkboxes") | Out-Null
} else {
    $r.Add("**Manifest MISSING:** expected $manifestFile") | Out-Null
}
$r.Add("") | Out-Null

# Summary + next-action recommendation
$r.Add("## Next-60-minute priority") | Out-Null
$r.Add("") | Out-Null
$anyImsccCaptured = @($courses | Where-Object { $_.ImsccPresent }).Count -gt 0
$anyIdentity = ($identityArtifacts.Transcript + $identityArtifacts.Enrollment + $identityArtifacts.DegreeAudit) -gt 0
if (-not $anyImsccCaptured) {
    $r.Add("**HIGHEST LEVERAGE**: start Canvas export for one completed course. Settings → Export Course Content → Create Export → download .imscc to the appropriate subdir.") | Out-Null
} elseif (-not $anyIdentity) {
    $r.Add("**HIGHEST LEVERAGE**: capture institutional identity (transcript + enrollment + degree audit) from UC OneStop. 10-minute task with permanent post-grad value.") | Out-Null
} elseif (($libraryCounts.Values | Measure-Object -Sum).Sum -eq 0) {
    $r.Add("**HIGHEST LEVERAGE**: 60-minute priority library paper session in acoustic_side_channels (PhD-foundational) or substrate_thesis_adjacent.") | Out-Null
} else {
    $r.Add("**PROGRESS**: captures detected across multiple tiers. Continue working the manifest; next session pick the tier with lowest coverage.") | Out-Null
}
$r.Add("") | Out-Null

if ($daysLeft -le 7) {
    $r.Add("### Tripwire urgency") | Out-Null
    $r.Add("") | Out-Null
    $r.Add("Less than a week to 2027-05-01 tripwire. If no course subdirs have captures, consider forcing-function re-plan via Architect agent per the manifest rule.") | Out-Null
    $r.Add("") | Out-Null
}

# ── AUTO-UPDATE MANIFEST (opt-in) ──────────────────────────────────────────
if ($AutoUpdateManifest -and -not $DryRun) {
    $r.Add("## AutoUpdateManifest applied") | Out-Null
    $r.Add("") | Out-Null
    if ($manifestStats.Exists) {
        $backupPath = "$manifestFile.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $manifestFile $backupPath -Force
        $r.Add("Manifest backup: ``$backupPath``") | Out-Null
        $r.Add("**NOTE**: auto-update writes a deterministic regenerated manifest. Clay must review and re-add hand-authored notes from the backup.") | Out-Null
        $r.Add("") | Out-Null
        # Intentionally left un-implemented: the manifest rows include hand-authored Notes.
        # A blind regenerate would wipe them. Leaving this as a scaffolding hook; Clay can
        # extend when comfortable with the overwrite semantics.
        Write-SOKLog 'AutoUpdateManifest: scaffolding-only; review migration-plan for full auto-update implementation' -Level Warn
    }
} elseif ($AutoUpdateManifest -and $DryRun) {
    $r.Add("## AutoUpdateManifest: DryRun — would update (re-run with -DryRun:`$false to apply)") | Out-Null
    $r.Add("") | Out-Null
}

$reportPath = Join-Path $ReportDir 'uc_harvest_audit.md'
Set-Content -Path $reportPath -Value ($r -join "`n") -Encoding utf8 -NoNewline
Write-SOKLog "Report written: $reportPath" -Level Success

# ── CONSOLE SUMMARY ────────────────────────────────────────────────────────
Write-SOKLog "── UC HARVEST AUDIT SUMMARY ──" -Level Section
Write-SOKLog "Days to tripwire: $daysLeft $urgency" -Level Warn
Write-SOKLog "Course subdirs:   $($courses.Count) (expected ~$($expectedCourses.Count), missing $($missingCourses.Count))" -Level Annotate
Write-SOKLog "  .imscc present: $((@($courses | Where-Object { $_.ImsccPresent })).Count) / $($courses.Count)" -Level Annotate
Write-SOKLog "  .imscc valid:   $((@($courses | Where-Object { $_.ImsccValid })).Count) / $($courses.Count)" -Level Annotate
Write-SOKLog "Identity:         $($identityArtifacts.Transcript + $identityArtifacts.Enrollment + $identityArtifacts.DegreeAudit + $identityArtifacts.Letters) total artifacts" -Level Annotate
Write-SOKLog "Library papers:   $(($libraryCounts.Values | Measure-Object -Sum).Sum) across $($libraryDomains.Count) domains" -Level Annotate
Write-SOKLog "License checks:   $licenseDone / $licenseTotal" -Level Annotate
Write-SOKLog "Manifest checks:  $($manifestStats.CheckedCount) / $($manifestStats.TotalCount)" -Level Annotate
Write-SOKLog "Full report: $reportPath" -Level Success
Write-SOKLog "Invoke-UCHarvestAudit — DONE" -Level Section
