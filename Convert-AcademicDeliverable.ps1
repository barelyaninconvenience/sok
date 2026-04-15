#Requires -Version 7.0
<#
.SYNOPSIS
    Convert-AcademicDeliverable.ps1 — Batch convert .md academic deliverables to .docx via Pandoc.

.DESCRIPTION
    Scans UC MS-IS course directories for .md files matching the Caddell_* naming convention,
    converts them to .docx using Pandoc, and skips files that already have an up-to-date .docx.

    Uses modification time comparison: if the .docx exists and is newer than the .md, skip.

.PARAMETER DryRun
    Preview what would be converted without actually running Pandoc.

.PARAMETER CoursePath
    Path to a specific course directory. If omitted, scans all SPRING 2026 courses.

.PARAMETER Force
    Re-convert all files even if .docx already exists and is newer.

.NOTES
    Author: S. Clay Caddell / Claude Code
    Version: 1.0.0
    Date: 2026-04-05
    Domain: Academic automation — read .md, write .docx via Pandoc
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$CoursePath,
    [switch]$Force
)

$ErrorActionPreference = 'Continue'

# --- Configuration ---
# Try multiple known Pandoc locations
$PandocCandidates = @(
    "C:\Program Files\Pandoc\pandoc.exe",
    (Join-Path $env:USERPROFILE "scoop\apps\pandoc\current\pandoc.exe"),
    (Join-Path $env:USERPROFILE "scoop\apps\pandoc\3.8.3\pandoc.exe"),
    (Get-Command pandoc -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
$PandocPath = if ($PandocCandidates) { $PandocCandidates } else { "pandoc" }
$AcademicRoot = Join-Path $env:USERPROFILE "Documents\UC MS-IS\SPRING 2026"
$FilePattern = "Caddell_*.md"

# --- Validation ---
if (-not (Test-Path $PandocPath)) {
    Write-Error "Pandoc not found at $PandocPath. Install via: scoop install pandoc"
    exit 1
}

if ($CoursePath -and -not (Test-Path $CoursePath)) {
    Write-Error "Course path not found: $CoursePath"
    exit 1
}

# --- Gather source files ---
$searchPath = if ($CoursePath) { $CoursePath } else { $AcademicRoot }
$mdFiles = Get-ChildItem -Path $searchPath -Recurse -Force -File |
    Where-Object { $_.Name -like $FilePattern -and $_.Extension -eq '.md' }

if ($mdFiles.Count -eq 0) {
    Write-Host "No matching .md files found in $searchPath" -ForegroundColor Yellow
    exit 0
}

Write-Host "=== Academic Deliverable Converter ===" -ForegroundColor Cyan
Write-Host "Source: $searchPath"
Write-Host "Pandoc: $PandocPath"
Write-Host "Files found: $($mdFiles.Count)"
Write-Host ""

# --- Process each file ---
$converted = 0
$skipped = 0
$failed = 0

foreach ($md in $mdFiles) {
    $docx = Join-Path $md.DirectoryName ($md.BaseName + ".docx")
    $relativePath = $md.FullName.Replace($AcademicRoot, '').TrimStart('\')

    # Skip if .docx exists and is newer (unless -Force)
    if (-not $Force -and (Test-Path $docx)) {
        $docxItem = Get-Item $docx
        if ($docxItem.LastWriteTime -ge $md.LastWriteTime) {
            Write-Host "  SKIP  $relativePath (.docx is current)" -ForegroundColor DarkGray
            $skipped++
            continue
        }
    }

    if ($DryRun) {
        Write-Host "  [DRY] Would convert: $relativePath" -ForegroundColor Yellow
        $converted++
        continue
    }

    # Convert
    try {
        $args = @(
            $md.FullName
            '-o', $docx
            '--from', 'markdown'
            '--to', 'docx'
        )
        & $PandocPath @args 2>&1
        if ($LASTEXITCODE -eq 0) {
            $docxSize = [math]::Round((Get-Item $docx).Length / 1KB, 1)
            Write-Host "  OK    $relativePath -> .docx (${docxSize} KB)" -ForegroundColor Green
            $converted++
        } else {
            Write-Host "  FAIL  $relativePath (exit code $LASTEXITCODE)" -ForegroundColor Red
            $failed++
        }
    }
    catch {
        Write-Host "  FAIL  $relativePath ($_)" -ForegroundColor Red
        $failed++
    }
}

# --- Summary ---
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$verb = if ($DryRun) { "Would convert" } else { "Converted" }
Write-Host "  $verb`: $converted"
Write-Host "  Skipped: $skipped"
if ($failed -gt 0) {
    Write-Host "  Failed: $failed" -ForegroundColor Red
}
Write-Host ""

if ($DryRun) {
    Write-Host "[DRY RUN] No files were modified." -ForegroundColor Yellow
}
