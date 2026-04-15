<#
.SYNOPSIS
    SOK-Hotfix-v434.ps1 — Applies: TRIM guard, Cleanup noise, LiveDigest sort,
    Backup source, FlattenedFiles parser fix.
.NOTES
    Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Hotfix-v434.ps1
#>
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = 'C:\Users\shelc\Documents\Journal\Projects\scripts' }
$ok = 0; $miss = 0

function Patch {
    param([string]$Path, [string]$Find, [string]$Replace, [string]$Label)
    if (-not (Test-Path $Path)) { Write-Host "  SKIP: $Path not found" -ForegroundColor Yellow; return }
    $c = Get-Content $Path -Raw
    if ($c.Contains($Find)) {
        Set-Content -Path $Path -Value $c.Replace($Find, $Replace) -Force -NoNewline
        Write-Host "  [OK] $Label" -ForegroundColor Green; $script:ok++
    } elseif ($c.Contains($Replace)) { Write-Host "  [SKIP] $Label (already applied)" -ForegroundColor DarkGray }
    else { Write-Host "  [MISS] $Label" -ForegroundColor Yellow; $script:miss++ }
}

Write-Host "`n━━━ SOK HOTFIX v4.3.4 ━━━" -ForegroundColor Cyan

# 1. MAINTENANCE: TRIM non-NTFS guard
Write-Host "`n[1/5] Maintenance — TRIM guard" -ForegroundColor Yellow
Patch -Path (Join-Path $scriptDir 'SOK-Maintenance.ps1') `
    -Find @'
        $driveLetter = $drive.DeviceID.TrimEnd(':')
        if (-not $DryRun) {
'@ `
    -Replace @'
        $driveLetter = $drive.DeviceID.TrimEnd(':')
        if ($drive.FileSystem -and $drive.FileSystem -ne 'NTFS') {
            Write-SOKLog "  TRIM skipped: $($drive.DeviceID) ($($drive.FileSystem) — requires NTFS)" -Level Debug
            continue
        }
        if (-not $DryRun) {
'@ `
    -Label 'TRIM non-NTFS guard'

# 2. CLEANUP: SilentlyContinue on Remove-Item
Write-Host "`n[2/5] Cleanup — Error suppression" -ForegroundColor Yellow
$cleanPath = Join-Path $scriptDir 'SOK-Cleanup.ps1'
if (Test-Path $cleanPath) {
    $c = Get-Content $cleanPath -Raw
    $count = ([regex]'Remove-Item[^|]*-ErrorAction Continue').Matches($c).Count
    if ($count -gt 0) {
        $c = $c -replace '(Remove-Item[^|]*)-ErrorAction Continue', '$1-ErrorAction SilentlyContinue'
        Set-Content -Path $cleanPath -Value $c -Force -NoNewline
        Write-Host "  [OK] Fixed $count Remove-Item ErrorAction entries" -ForegroundColor Green; $ok++
    } else { Write-Host "  [SKIP] Already applied" -ForegroundColor DarkGray }
}

# 3. LIVEDIGEST: Sort by date not size
Write-Host "`n[3/5] LiveDigest — Sort fix" -ForegroundColor Yellow
Patch -Path (Join-Path $scriptDir 'SOK-LiveDigest.ps1') `
    -Find 'Sort-Object Length -Descending' `
    -Replace 'Sort-Object LastWriteTime -Descending' `
    -Label 'Sort newest not largest'

# 4. BACKUP: Default source
Write-Host "`n[4/5] Backup — Default source" -ForegroundColor Yellow
Patch -Path (Join-Path $scriptDir 'SOK-Backup.ps1') `
    -Find '"$env:USERPROFILE\Documents\Backup"' `
    -Replace '"$env:USERPROFILE\Documents\Journal\Projects"' `
    -Label 'Default source → Journal\Projects'

# 5. RESTRUCTURE-FLATTENEDFILES: Missing comma
Write-Host "`n[5/5] FlattenedFiles — Parser fix" -ForegroundColor Yellow
Patch -Path (Join-Path $scriptDir 'Restructure-FlattenedFiles.ps1') `
    -Find @'
    [switch]$DryRun

    [Parameter(Mandatory = $false
'@ `
    -Replace @'
    [switch]$DryRun,

    [Parameter(Mandatory = $false
'@ `
    -Label 'Missing comma in param block'

Write-Host "`n━━━ HOTFIX v4.3.4 COMPLETE ━━━" -ForegroundColor Cyan
Write-Host "  Applied: $ok" -ForegroundColor Green
Write-Host "  Missed:  $miss" -ForegroundColor $(if ($miss -gt 0) { 'Yellow' } else { 'Green' })
