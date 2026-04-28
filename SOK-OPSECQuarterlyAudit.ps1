<#
.SYNOPSIS
    SOK Quarterly OPSEC Audit — re-scans all public github repos for
    the 15 Public Artifact Discipline leakage categories. Catches drift
    since the last sweep before it accumulates.

.DESCRIPTION
    Per memory/feedback_public_artifact_discipline.md (15 categories as
    of 2026-04-28). The pre-commit + commit-msg hooks block new leakage
    at commit time; this audit catches leakage that pre-existed the hooks
    OR that slipped past via --no-verify overrides OR that emerged from
    auto-merge / external contributors.

    Cadence: quarterly, integrated with SOK audit cadence framework.
    Manual invocation: any time, on-demand.

.PARAMETER DryRun
    If set, only reports findings without staging any remediation.
    Default: TRUE (audit-only mode; never modifies files).

.PARAMETER Repos
    Optional override array of repo paths. If not provided, audits the
    standard 5 public-eligible repos.

.NOTES
    Author: SOK / Public Artifact Discipline cadence
    Version: 1.0 (2026-04-28)
    Companion: scripts/git-hooks/pre-commit-opsec-sweep + commit-msg-opsec-sweep
#>

#Requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$DryRun = $true,
    [string[]]$Repos = @(
        'C:\Users\shelc\Documents\Journal\Projects\substrate-thesis-companion',
        'C:\Users\shelc\Documents\Journal\Projects\structured-data-crawler-substrate',
        'C:\Users\shelc\Documents\Journal\Projects\scripts',
        'C:\Users\shelc\Documents\Journal\Projects\BS_IT_WGU',
        'C:\Users\shelc\Documents\Journal\Projects\matlab-radar-adaptive-waveform'
    )
)

$ErrorActionPreference = 'Continue'
$AuditDate = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$ReportDir = Join-Path $env:USERPROFILE 'Documents\Journal\Projects\SOK\Logs\OPSECAudit'
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
}
$ReportPath = Join-Path $ReportDir "OPSEC_Audit_${AuditDate}.md"

# 15-category pattern set (mirrors pre-commit-opsec-sweep)
$Patterns = @(
    @{ Pattern = '\bHII Mission Tech(nologies)?\b';                      Label = 'Cat 9: HII Mission Tech reference';        Severity = 'HIGH' }
    @{ Pattern = '\bSCIF[ -]round\b';                                    Label = 'Cat 9: SCIF-round reference';              Severity = 'HIGH' }
    @{ Pattern = '\b(ATSP5|SHIELD contract)\b';                          Label = 'Cat 9: HII contract reference';            Severity = 'HIGH' }
    @{ Pattern = '\b(DeGraff|Madison Zamzow|Joe Rawlings|Renee Neidigh)\b'; Label = 'Cat 4: HII panel personnel name';       Severity = 'HIGH' }
    @{ Pattern = '\b(Akwei|Menard|Cohen)\b';                             Label = 'Cat 4: IT7021 teammate name';              Severity = 'MEDIUM' }
    @{ Pattern = '\b(Navedita|Archana|Harshita)\b';                      Label = 'Cat 4: IS7036 teammate name';              Severity = 'MEDIUM' }
    @{ Pattern = '\b(ENDEAVOR Loop|Reconcile Protocol|Master Log|Backburner Inventory|Operating Stack v[0-9])\b'; Label = 'Cat 5: Internal vocabulary'; Severity = 'HIGH' }
    @{ Pattern = '\bClay-pen\b|\bClay-decision\b|\bClay-judgment\b';     Label = 'Cat 5: Clay-pen pattern';                  Severity = 'HIGH' }
    @{ Pattern = '~/\.claude/CLAUDE\.md';                                Label = 'Cat 6: ~/.claude/CLAUDE.md private path';  Severity = 'HIGH' }
    @{ Pattern = 'Writings/[A-Z][a-zA-Z_0-9]+\.md';                      Label = 'Cat 6: Writings/ private path';            Severity = 'HIGH' }
    @{ Pattern = 'memory/(MEMORY\.md|feedback_|protocol_|user_|project_)'; Label = 'Cat 6: memory/ directory reference';     Severity = 'HIGH' }
    @{ Pattern = 'Master_Log_[0-9]{8}|State_Snapshot_(Current|[0-9])';   Label = 'Cat 6: Master_Log/State_Snapshot reference'; Severity = 'MEDIUM' }
    @{ Pattern = '\boveremployment\b|\bDetection Risk (multiplier|score)\b'; Label = 'Cat 10: Overemployment vocabulary';   Severity = 'HIGH' }
    @{ Pattern = '\bSync Oversight\b|\b1099-stack';                      Label = 'Cat 10: Concurrent-employment vocabulary'; Severity = 'HIGH' }
    @{ Pattern = '\bJasmine\b.*\b(Honeywell|Emerson|GE Aero|ICS|OT engineer)\b'; Label = 'Cat 11: Spouse employer chain'; Severity = 'HIGH' }
    @{ Pattern = '\bJMicron PCIe[0-9]+\b';                               Label = 'Cat 13: Specific SSD controller';          Severity = 'HIGH' }
    @{ Pattern = '\bIntel(64)? Family [0-9]+ Model [0-9]+ Stepping';     Label = 'Cat 13: CPUID granular fingerprint';       Severity = 'HIGH' }
    @{ Pattern = '\bi7-13700H\b';                                        Label = 'Cat 13: Specific CPU model';               Severity = 'MEDIUM' }
    @{ Pattern = 'D: unmounted \| E: USB-SSD';                           Label = 'Cat 14: Drive-topology pattern';           Severity = 'HIGH' }
    @{ Pattern = '\bCLAY_PC\b';                                          Label = 'Cat 12: CLAY_PC machine name';             Severity = 'HIGH' }
    @{ Pattern = '\bUser: shelc\b';                                      Label = 'Cat 12: User: shelc fingerprint';          Severity = 'HIGH' }
    @{ Pattern = '\bshelcaddell@(gmail\.com|mail\.uc\.edu)\b';           Label = 'Cat 4: Personal email plaintext';          Severity = 'HIGH' }
    @{ Pattern = '\bcaddelsc@mail\.uc\.edu\b';                           Label = 'Cat 4: UC institutional email plaintext';  Severity = 'HIGH' }
    @{ Pattern = '\bcaddellhomestead@gmail\.com\b';                      Label = 'Cat 4: Anthropic-account email plaintext'; Severity = 'HIGH' }
    @{ Pattern = '\bshalala773@(gmail|yahoo)\.com\b';                    Label = 'Cat 4: Backup email plaintext';            Severity = 'HIGH' }
    @{ Pattern = 'Polygraph.*(Full Scope|Counterintelligence) \([0-9]{4}\)'; Label = 'Cat 2: Polygraph specificity';        Severity = 'HIGH' }
    @{ Pattern = '\$30M\+? in classified';                               Label = 'Cat 10: SCIF asset quantification';        Severity = 'HIGH' }
    @{ Pattern = '\bSpecial Access Programs?\b';                         Label = 'Cat 9: SAP language';                      Severity = 'HIGH' }
    @{ Pattern = '\(513\) 293-1215';                                     Label = 'Cat 4: Personal phone number';             Severity = 'HIGH' }
)

# Output collectors
$AllFindings = @()
$RepoSummaries = @()

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  SOK Quarterly OPSEC Audit — $AuditDate" -ForegroundColor Cyan
Write-Host "  Mode: $($DryRun ? 'DRY-RUN (audit-only)' : 'LIVE (would not modify; reporting only)')" -ForegroundColor Cyan
Write-Host "  Patterns: $($Patterns.Count) leakage categories" -ForegroundColor Cyan
Write-Host "  Repos:    $($Repos.Count) public-eligible" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

foreach ($repo in $Repos) {
    $repoName = Split-Path $repo -Leaf

    if (-not (Test-Path $repo)) {
        Write-Host "SKIP: $repoName (path not found)" -ForegroundColor Yellow
        $RepoSummaries += [PSCustomObject]@{
            Repo = $repoName
            Status = 'SKIP-NOTFOUND'
            FindingCount = 0
            HighCount = 0
            MediumCount = 0
        }
        continue
    }

    Write-Host "Auditing: $repoName" -ForegroundColor Green

    Push-Location $repo
    try {
        $repoFindings = @()
        foreach ($p in $Patterns) {
            # Use git grep — only scans tracked files; respects .gitignore; faster than Get-ChildItem
            $matches = & git grep -n -E "$($p.Pattern)" 2>$null
            if ($matches) {
                foreach ($m in $matches) {
                    $repoFindings += [PSCustomObject]@{
                        Repo = $repoName
                        Severity = $p.Severity
                        Category = $p.Label
                        Match = $m
                    }
                }
            }
        }

        $highCount = ($repoFindings | Where-Object { $_.Severity -eq 'HIGH' }).Count
        $mediumCount = ($repoFindings | Where-Object { $_.Severity -eq 'MEDIUM' }).Count

        $RepoSummaries += [PSCustomObject]@{
            Repo = $repoName
            Status = if ($repoFindings.Count -eq 0) { 'CLEAN' } else { 'FINDINGS' }
            FindingCount = $repoFindings.Count
            HighCount = $highCount
            MediumCount = $mediumCount
        }

        $AllFindings += $repoFindings

        if ($repoFindings.Count -eq 0) {
            Write-Host "  CLEAN: zero findings across all $($Patterns.Count) categories" -ForegroundColor Green
        } else {
            Write-Host "  FINDINGS: $($repoFindings.Count) total ($highCount HIGH / $mediumCount MEDIUM)" -ForegroundColor Yellow
            $repoFindings | Group-Object Category | ForEach-Object {
                Write-Host "    [$($_.Group[0].Severity)] $($_.Name): $($_.Count) hit(s)" -ForegroundColor DarkYellow
            }
        }
    } finally {
        Pop-Location
    }
}

# Write report to disk
$report = @"
# SOK Quarterly OPSEC Audit Report

**Audit timestamp:** $AuditDate
**Mode:** $($DryRun ? 'DRY-RUN (audit-only)' : 'LIVE')
**Pattern set:** 15 Public Artifact Discipline categories (per `memory/feedback_public_artifact_discipline.md`)
**Repos audited:** $($Repos.Count)

---

## Summary

| Repo | Status | Findings | HIGH | MEDIUM |
|---|---|---|---|---|
$( $RepoSummaries | ForEach-Object { "| $($_.Repo) | $($_.Status) | $($_.FindingCount) | $($_.HighCount) | $($_.MediumCount) |" } )

**Total findings across all repos:** $($AllFindings.Count) ($(($AllFindings | Where-Object { $_.Severity -eq 'HIGH' }).Count) HIGH + $(($AllFindings | Where-Object { $_.Severity -eq 'MEDIUM' }).Count) MEDIUM)

---

## Detail (all findings)

$( if ($AllFindings.Count -eq 0) { "All audited repos are clean. No drift detected since last sweep." } else {
    $AllFindings | Group-Object Repo | ForEach-Object {
        "### $($_.Name)`n`n" + ( $_.Group | Group-Object Category | ForEach-Object {
            "**[$($_.Group[0].Severity)] $($_.Name)** ($($_.Count) hits)`n`n" + ( $_.Group | ForEach-Object { "- ``$($_.Match)``" } | Join-String -Separator "`n" )
        } | Join-String -Separator "`n`n" )
    } | Join-String -Separator "`n`n---`n`n"
})

---

## Next steps

$( if ($AllFindings.Count -eq 0) { "No remediation needed. Schedule next quarterly audit per cadence." } else { @"
1. Review findings above; classify each as TRUE-POSITIVE (real leakage) vs FALSE-POSITIVE (legitimate use, regex needs refinement)
2. For TRUE-POSITIVES: apply the standard sanitization patterns from `Writings/HII_OPSEC_Master_Remediation_Runbook_20260428.md`
3. For FALSE-POSITIVES: amend `pre-commit-opsec-sweep` regex to exclude the false-positive class
4. Re-run this audit after remediation to verify clean state
"@ })

---

*Generated by SOK-OPSECQuarterlyAudit.ps1. Companion: pre-commit-opsec-sweep + commit-msg-opsec-sweep hooks (in scripts/git-hooks/).*
"@

Set-Content -Path $ReportPath -Value $report -Encoding UTF8

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "  Audit complete." -ForegroundColor Cyan
Write-Host "  Report: $ReportPath" -ForegroundColor Cyan
Write-Host "  Total findings: $($AllFindings.Count) ($(($AllFindings | Where-Object { $_.Severity -eq 'HIGH' }).Count) HIGH / $(($AllFindings | Where-Object { $_.Severity -eq 'MEDIUM' }).Count) MEDIUM)" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# Exit code: 0 if clean, 1 if any HIGH findings (signals "drift detected")
if (($AllFindings | Where-Object { $_.Severity -eq 'HIGH' }).Count -gt 0) {
    exit 1
}
exit 0
