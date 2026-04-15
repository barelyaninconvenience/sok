#Requires -Version 7.0
<#
.SYNOPSIS
    Get-AcademicStatus.ps1 — Cross-reference academic deliverables on disk against due dates.

.DESCRIPTION
    Scans UC MS-IS SPRING 2026 course directories for completed deliverables,
    compares them against the canonical assignment schedule from syllabi,
    and generates a status report showing what's done, overdue, upcoming, and blocked.

.PARAMETER DryRun
    Preview mode — read-only, no report file written.

.PARAMETER Course
    Filter to a specific course (IS7034, IS7036, IS7066, IS8044, IT7021C).

.PARAMETER OutputPath
    Path for the status report. Defaults to SOK\Logs\AcademicStatus\

.NOTES
    Author: S. Clay Caddell / Claude Code
    Version: 1.0.0
    Date: 2026-04-05
    Domain: Academic automation — reads filesystem, compares against known schedule
    Assignment dates extracted from Canvas syllabi PDFs on 2026-04-04/05
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateSet('IS7034', 'IS7036', 'IS7066', 'IS8044', 'IT7021C', 'ALL')]
    [string]$Course = 'ALL',
    [string]$OutputPath
)

$ErrorActionPreference = 'Continue'
$Today = Get-Date

# --- Paths ---
$AcademicRoot = Join-Path $env:USERPROFILE "Documents\UC MS-IS\SPRING 2026"
$DefaultOutput = Join-Path $env:USERPROFILE "Documents\Journal\Projects\SOK\Logs\AcademicStatus"

if (-not $OutputPath) { $OutputPath = $DefaultOutput }

# --- Assignment Schedule (from syllabi, extracted 2026-04-04/05) ---
$Assignments = @(
    # IS7066 — Information Systems Project Management (2nd half, Mr. Kris Jones)
    @{ Course='IS7066'; Name='Quiz Question Suggestions 1.1';   Due='2026-03-04'; Type='Written';  FilePattern='*QuizQuestion*' }
    @{ Course='IS7066'; Name='CMM vs Agile';                    Due='2026-03-08'; Type='Written';  FilePattern='*CMM*Agile*' }
    @{ Course='IS7066'; Name='Quiz 1.1';                        Due='2026-03-10'; Type='Canvas';   FilePattern=$null }
    @{ Course='IS7066'; Name='Quiz Question Suggestions 2.1';   Due='2026-03-11'; Type='Written';  FilePattern='*QuizQuestion*' }
    @{ Course='IS7066'; Name='Sprint Tasks Specimen Screen';    Due='2026-03-22'; Type='Written';  FilePattern='*Sprint*Specimen*' }
    @{ Course='IS7066'; Name='Definition of Done/Ready';        Due='2026-03-22'; Type='Written';  FilePattern='*DoD*DoR*' }
    @{ Course='IS7066'; Name='Syllabus Quiz';                   Due='2026-03-22'; Type='Canvas';   FilePattern=$null }
    @{ Course='IS7066'; Name='Quiz 2.1';                        Due='2026-03-24'; Type='Canvas';   FilePattern=$null }
    @{ Course='IS7066'; Name='Quiz Question Suggestions 3.1';   Due='2026-03-25'; Type='Written';  FilePattern='*QuizQuestion*' }
    @{ Course='IS7066'; Name='Quiz 3.1';                        Due='2026-04-01'; Type='Canvas';   FilePattern=$null }
    @{ Course='IS7066'; Name='Quiz Question Suggestions 4.1';   Due='2026-04-01'; Type='Written';  FilePattern='*QuizQuestion*' }
    @{ Course='IS7066'; Name='Project Timeline';                Due='2026-04-05'; Type='Written';  FilePattern='*ProjectTimeline*' }
    @{ Course='IS7066'; Name='Quiz 4.1';                        Due='2026-04-07'; Type='Canvas';   FilePattern=$null }
    @{ Course='IS7066'; Name='Quiz Question Suggestions 5.1';   Due='2026-04-08'; Type='Written';  FilePattern='*QuizQuestion*' }
    @{ Course='IS7066'; Name='Car Manufacturer Payback and NPV';Due='2026-04-12'; Type='Written';  FilePattern='*CarManufacturer*Payback*' }
    @{ Course='IS7066'; Name='Quiz 5.1';                        Due='2026-04-14'; Type='Canvas';   FilePattern=$null }
    @{ Course='IS7066'; Name='Quiz Question Suggestions 6.1';   Due='2026-04-15'; Type='Written';  FilePattern='*QuizQuestion*' }
    @{ Course='IS7066'; Name='Final Project';                   Due='2026-04-22'; Type='Written';  FilePattern='*FinalProject*' }
    @{ Course='IS7066'; Name='Quiz 6.1';                        Due='2026-04-22'; Type='Canvas';   FilePattern=$null }
    @{ Course='IS7066'; Name='Successful vs Failed IS Projects';Due='2026-04-22'; Type='Written';  FilePattern='*Successful*Failed*' }

    # IS8044 — Information Systems Security (2nd half, Mr. Kris Jones)
    @{ Course='IS8044'; Name='Case Study: Stuxnet (Mod 1)';        Due='2026-03-12'; Type='Written'; FilePattern='*CaseStudy*Stuxnet*' }
    @{ Course='IS8044'; Name='Discussion Post (Mod 1)';            Due='2026-03-12'; Type='Written'; FilePattern='*DiscussionPost*' }
    @{ Course='IS8044'; Name='Attack IQ Training (Mod 1)';         Due='2026-03-12'; Type='Platform';FilePattern=$null }
    @{ Course='IS8044'; Name='Case Study: Columbus (Mod 2)';       Due='2026-03-26'; Type='Written'; FilePattern='*CaseStudy*Columbus*' }
    @{ Course='IS8044'; Name='Discussion Post (Mod 2)';            Due='2026-03-26'; Type='Written'; FilePattern='*DiscussionPost*' }
    @{ Course='IS8044'; Name='Attack IQ Training (Mod 2)';         Due='2026-03-26'; Type='Platform';FilePattern=$null }
    @{ Course='IS8044'; Name='Case Study: Snowflake (Mod 3)';      Due='2026-03-26'; Type='Written'; FilePattern='*CaseStudy*Snowflake*' }
    @{ Course='IS8044'; Name='Discussion Post (Mod 3)';            Due='2026-03-26'; Type='Written'; FilePattern='*DiscussionPost*' }
    @{ Course='IS8044'; Name='MidTerm Exam';                       Due='2026-03-26'; Type='Canvas';  FilePattern=$null }
    @{ Course='IS8044'; Name='Attack IQ Training (Mod 3)';         Due='2026-03-26'; Type='Platform';FilePattern=$null }
    @{ Course='IS8044'; Name='Case Study: CrowdStrike (Mod 4)';    Due='2026-04-09'; Type='Written'; FilePattern='*CaseStudy*CrowdStrike*' }
    @{ Course='IS8044'; Name='Discussion Post (Mod 4)';            Due='2026-04-09'; Type='Written'; FilePattern='*DiscussionPost*' }
    @{ Course='IS8044'; Name='Attack IQ Training (Mod 4)';         Due='2026-04-09'; Type='Platform';FilePattern=$null }
    @{ Course='IS8044'; Name='Case Study: UnitedHealth (Mod 5)';   Due='2026-04-16'; Type='Written'; FilePattern='*CaseStudy*UnitedHealth*' }
    @{ Course='IS8044'; Name='Discussion Post (Mod 5)';            Due='2026-04-16'; Type='Written'; FilePattern='*DiscussionPost*' }
    @{ Course='IS8044'; Name='Attack IQ Training (Mod 5)';         Due='2026-04-16'; Type='Platform';FilePattern=$null }
    @{ Course='IS8044'; Name='Case Study: AI Security (Mod 6)';    Due='2026-04-23'; Type='Written'; FilePattern='*CaseStudy*AI*Security*' }
    @{ Course='IS8044'; Name='Discussion Post (Mod 6)';            Due='2026-04-23'; Type='Written'; FilePattern='*DiscussionPost*' }
    @{ Course='IS8044'; Name='Blockchain Use Case Eval (Mod 7)';   Due='2026-04-23'; Type='Written'; FilePattern='*Blockchain*UseCase*' }
    @{ Course='IS8044'; Name='Case Study: FTX/Blockchain (Mod 7)'; Due='2026-04-23'; Type='Written'; FilePattern='*CaseStudy*Blockchain*FTX*' }
    @{ Course='IS8044'; Name='Discussion Post (Mod 7)';            Due='2026-04-23'; Type='Written'; FilePattern='*DiscussionPost*' }
    @{ Course='IS8044'; Name='Attack IQ Training (Mod 6)';         Due='2026-04-23'; Type='Platform';FilePattern=$null }
    @{ Course='IS8044'; Name='Attack IQ Training (Mod 7)';         Due='2026-04-23'; Type='Platform';FilePattern=$null }
    @{ Course='IS8044'; Name='Guest Expert: David C. Kelly';       Due='2026-04-14'; Type='Written'; FilePattern='*GuestExpert*Kelly*' }
    @{ Course='IS8044'; Name='Guest Expert: Ravi T.';              Due='2026-04-15'; Type='Written'; FilePattern='*GuestExpert*Ravi*' }
    @{ Course='IS8044'; Name='Final Exam';                         Due='2026-04-23'; Type='Canvas';  FilePattern=$null }

    # IT7021C — Enterprise Security Forensics (full semester, Dr. Chengcheng Li)
    @{ Course='IT7021C'; Name='Module 1 Assignment';       Due='2026-01-18'; Type='Written'; FilePattern='*Module1*CaseStudy*' }
    @{ Course='IT7021C'; Name='Module 1 Discussion';       Due='2026-01-18'; Type='Canvas';  FilePattern=$null }
    @{ Course='IT7021C'; Name='Module 2 Assignment';       Due='2026-01-25'; Type='Written'; FilePattern='*Module2*Lab*' }
    @{ Course='IT7021C'; Name='Module 3 Assignment';       Due='2026-02-01'; Type='Written'; FilePattern='*Assignment3*' }
    @{ Course='IT7021C'; Name='Module 4 Assignment';       Due='2026-02-15'; Type='Lab';     FilePattern=$null }
    @{ Course='IT7021C'; Name='Module 5 Assignment';       Due='2026-02-15'; Type='Lab';     FilePattern=$null }
    @{ Course='IT7021C'; Name='Project Proposal';          Due='2026-02-15'; Type='Written'; FilePattern='*ProjectProposal*' }
    @{ Course='IT7021C'; Name='Module 6 Assignment';       Due='2026-02-22'; Type='Lab';     FilePattern=$null }
    @{ Course='IT7021C'; Name='Midterm Check-in';          Due='2026-02-23'; Type='Canvas';  FilePattern=$null }
    @{ Course='IT7021C'; Name='Module 7 Assignment';       Due='2026-03-01'; Type='Lab';     FilePattern=$null }
    @{ Course='IT7021C'; Name='First Progress Report';     Due='2026-03-09'; Type='Written'; FilePattern='*FirstProgress*' }
    @{ Course='IT7021C'; Name='Module 8 Assignment';       Due='2026-03-09'; Type='Lab';     FilePattern=$null }
    @{ Course='IT7021C'; Name='Module 9 Assignment';       Due='2026-03-29'; Type='Lab';     FilePattern=$null }
    @{ Course='IT7021C'; Name='Second Progress Report';    Due='2026-04-05'; Type='Written'; FilePattern='*SecondProgress*' }
    @{ Course='IT7021C'; Name='Module 10 Assignment';      Due='2026-04-12'; Type='Lab';     FilePattern=$null }
    @{ Course='IT7021C'; Name='Project Presentation';      Due='2026-04-15'; Type='Written'; FilePattern='*ProjectPresentation*' }
    @{ Course='IT7021C'; Name='Module 11 Assignment';      Due='2026-04-19'; Type='Lab';     FilePattern=$null }
    @{ Course='IT7021C'; Name='Peer Evaluation';           Due='2026-04-26'; Type='Canvas';  FilePattern=$null }
    @{ Course='IT7021C'; Name='Project Report';            Due='2026-04-26'; Type='Written'; FilePattern='*ProjectReport*' }

    # IS7036 — Data Mining for BI (full semester, Mr. Kris Jones)
    @{ Course='IS7036'; Name='LinkedIn Learning Sec 1-2';        Due='2026-03-05'; Type='Platform'; FilePattern=$null }
    @{ Course='IS7036'; Name='Project Charter (SOW)';            Due='2026-03-10'; Type='Written';  FilePattern='*Project*Charter*' }
    @{ Course='IS7036'; Name='LinkedIn Learning Cert (100%)';    Due='2026-03-24'; Type='Platform'; FilePattern=$null }
    @{ Course='IS7036'; Name='Cleaned Master Dataset';           Due='2026-03-24'; Type='Written';  FilePattern='*clean*data*' }
    @{ Course='IS7036'; Name='Descriptive Insights Report';      Due='2026-03-31'; Type='Written';  FilePattern='*Descriptive*Insights*' }
    @{ Course='IS7036'; Name='Wage Predictor Lab (Regression)';  Due='2026-04-07'; Type='Written';  FilePattern='*Regression*Notebook*' }
    @{ Course='IS7036'; Name='Segmentation Strategy Memo';       Due='2026-04-14'; Type='Written';  FilePattern='*Segmentation*Memo*' }
    @{ Course='IS7036'; Name='Executive Slide Deck';             Due='2026-04-21'; Type='Written';  FilePattern='*SlideDeck*' }
    @{ Course='IS7036'; Name='Final Presentation (15 min)';      Due='2026-04-23'; Type='InPerson'; FilePattern=$null }
    @{ Course='IS7036'; Name='Peer Evaluations';                 Due='2026-04-25'; Type='Canvas';   FilePattern=$null }

    # IS7034 — Data Warehousing & BI (1st half, ended Mar 1, Mr. Kris Jones)
    @{ Course='IS7034'; Name='Lab 1';               Due='2026-01-19'; Type='Written'; FilePattern='*Lab1*' }
    @{ Course='IS7034'; Name='Lab 2';               Due='2026-01-26'; Type='Written'; FilePattern='*Lab2*' }
    @{ Course='IS7034'; Name='ERD in 3NF';          Due='2026-01-26'; Type='Written'; FilePattern='*ERD*3NF*' }
    @{ Course='IS7034'; Name='Lab 3';               Due='2026-02-02'; Type='Written'; FilePattern='*Lab3*' }
    @{ Course='IS7034'; Name='Dimensional Modeling'; Due='2026-02-09'; Type='Written'; FilePattern='*Dimensional*Model*' }
    @{ Course='IS7034'; Name='Lab 4';               Due='2026-02-16'; Type='Written'; FilePattern='*Lab4*' }
    @{ Course='IS7034'; Name='Lab 5';               Due='2026-02-16'; Type='Written'; FilePattern='*Lab5*' }
    @{ Course='IS7034'; Name='Lab 6';               Due='2026-02-23'; Type='Written'; FilePattern='*Lab6*' }
    @{ Course='IS7034'; Name='Final Project (dbt)'; Due='2026-03-01'; Type='Written'; FilePattern='*dbt*Presentation*' }
    @{ Course='IS7034'; Name='Revised Paper';       Due='2026-04-04'; Type='Written'; FilePattern='*RevisedPaper*' }
)

# --- Course directory mapping ---
$CourseDirs = @{
    'IS7034'  = 'IS7034 DATA WAREHOUSING & BUSINESS INTELLIGENCE'
    'IS7036'  = 'IS7036 DATA MINING FOR BUSINESS INTELLIGENCE'
    'IS7066'  = 'IS7066 INFORMATION SYSTEMS PROJECT MANAGEMENT'
    'IS8044'  = 'IS8044 INFORMATION SYSTEMS SECURITY'
    'IT7021C' = 'IT7021C ENTERPRISE SECURITY FORENSICS'
}

# --- Filter by course ---
$filtered = if ($Course -eq 'ALL') { $Assignments } else { $Assignments | Where-Object { $_.Course -eq $Course } }

# --- Check each assignment ---
$results = foreach ($a in $filtered) {
    $courseDir = Join-Path $AcademicRoot $CourseDirs[$a.Course]
    $dueDate = [datetime]$a.Due
    $daysUntilDue = ($dueDate - $Today).Days

    # Determine file status
    $fileFound = $false
    $fileName = ''
    if ($a.FilePattern -and (Test-Path $courseDir)) {
        $matches = Get-ChildItem -Path $courseDir -Force -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like $a.FilePattern -and $_.Name -notlike '~`$*' }
        if ($matches) {
            # Prefer Caddell_ prefix, then .docx/.pdf over other formats
            $caddellMatch = $matches | Where-Object { $_.Name -like 'Caddell_*' }
            $docMatch = $matches | Where-Object { $_.Extension -in @('.docx', '.pdf', '.md') }
            $best = if ($caddellMatch) { $caddellMatch | Select-Object -First 1 }
                    elseif ($docMatch) { $docMatch | Select-Object -First 1 }
                    else { $matches | Select-Object -First 1 }
            $fileFound = $true
            $fileName = $best.Name
        }
    }

    # Determine status
    $status = if ($a.Type -in @('Canvas', 'Platform', 'Lab', 'InPerson')) {
        if ($daysUntilDue -lt 0) { 'BLOCKED-OVERDUE' } else { 'BLOCKED' }
    } elseif ($fileFound) {
        'ON-DISK'
    } elseif ($daysUntilDue -lt 0) {
        'MISSING-OVERDUE'
    } else {
        'MISSING'
    }

    [PSCustomObject]@{
        Course      = $a.Course
        Assignment  = $a.Name
        Due         = $dueDate.ToString('yyyy-MM-dd')
        DaysLeft    = $daysUntilDue
        Type        = $a.Type
        Status      = $status
        File        = $fileName
    }
}

# --- Display ---
Write-Host "=== Academic Status Report ===" -ForegroundColor Cyan
Write-Host "Date: $($Today.ToString('yyyy-MM-dd HH:mm'))"
Write-Host "Scope: $Course"
Write-Host ""

# Summary counts
$onDisk = ($results | Where-Object Status -eq 'ON-DISK').Count
$missing = ($results | Where-Object Status -eq 'MISSING').Count
$missingOverdue = ($results | Where-Object Status -eq 'MISSING-OVERDUE').Count
$blocked = ($results | Where-Object Status -eq 'BLOCKED').Count
$blockedOverdue = ($results | Where-Object Status -eq 'BLOCKED-OVERDUE').Count
$total = $results.Count

Write-Host "  ON-DISK:          $onDisk" -ForegroundColor Green
Write-Host "  MISSING:          $missing" -ForegroundColor Yellow
Write-Host "  MISSING-OVERDUE:  $missingOverdue" -ForegroundColor Red
Write-Host "  BLOCKED:          $blocked" -ForegroundColor DarkGray
Write-Host "  BLOCKED-OVERDUE:  $blockedOverdue" -ForegroundColor DarkGray
Write-Host "  TOTAL:            $total"
Write-Host ""

# Group by course
foreach ($c in ($results | Group-Object Course | Sort-Object Name)) {
    Write-Host "--- $($c.Name) ---" -ForegroundColor Cyan
    foreach ($r in $c.Group | Sort-Object Due) {
        $color = switch ($r.Status) {
            'ON-DISK'         { 'Green' }
            'MISSING'         { 'Yellow' }
            'MISSING-OVERDUE' { 'Red' }
            'BLOCKED'         { 'DarkGray' }
            'BLOCKED-OVERDUE' { 'DarkGray' }
        }
        $dueLabel = if ($r.DaysLeft -lt 0) { "($([Math]::Abs($r.DaysLeft))d ago)" }
                    elseif ($r.DaysLeft -eq 0) { "(TODAY)" }
                    else { "(in $($r.DaysLeft)d)" }

        $line = "  [{0,-15}] {1,-45} {2}  {3}" -f $r.Status, $r.Assignment, $r.Due, $dueLabel
        if ($r.File) { $line += "  -> $($r.File)" }
        Write-Host $line -ForegroundColor $color
    }
    Write-Host ""
}

# --- Upcoming (next 14 days) ---
$upcoming = $results | Where-Object { $_.DaysLeft -ge 0 -and $_.DaysLeft -le 14 -and $_.Status -ne 'ON-DISK' } | Sort-Object Due
if ($upcoming) {
    Write-Host "=== ACTION ITEMS (next 14 days) ===" -ForegroundColor Magenta
    foreach ($u in $upcoming) {
        $urgency = if ($u.DaysLeft -le 2) { 'Red' } elseif ($u.DaysLeft -le 7) { 'Yellow' } else { 'White' }
        Write-Host "  $($u.Due) ($($u.DaysLeft)d) [$($u.Course)] $($u.Assignment) ($($u.Type))" -ForegroundColor $urgency
    }
    Write-Host ""
}

# --- Write report file ---
if (-not $DryRun) {
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    $reportFile = Join-Path $OutputPath "AcademicStatus_$($Today.ToString('yyyyMMdd-HHmmss')).csv"
    $results | Export-Csv -Path $reportFile -NoTypeInformation
    Write-Host "Report written to: $reportFile" -ForegroundColor Green
} else {
    Write-Host "[DRY RUN] No report file written." -ForegroundColor Yellow
}
