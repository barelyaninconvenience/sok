<#
.SYNOPSIS
    SOK-Hotfix-v433.ps1 — SpaceAudit output path, TRIM guard, digital signature notes.
.NOTES
    Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Hotfix-v433.ps1
    Version: 4.3.3
#>

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = 'C:\Users\shelc\Documents\Journal\Projects\scripts' }
$patchCount = 0; $failCount = 0

function Patch-File {
    param([string]$Path, [string]$Find, [string]$Replace, [string]$Label)
    if (-not (Test-Path $Path)) { Write-Host "  SKIP: $Path not found" -ForegroundColor Yellow; return }
    $content = Get-Content $Path -Raw
    if ($content.Contains($Find)) {
        $content = $content.Replace($Find, $Replace)
        Set-Content -Path $Path -Value $content -Force -NoNewline
        Write-Host "  [OK] $Label" -ForegroundColor Green
        $script:patchCount++
    }
    elseif ($content.Contains($Replace)) { Write-Host "  [SKIP] $Label (already applied)" -ForegroundColor DarkGray }
    else { Write-Host "  [MISS] $Label" -ForegroundColor Yellow; $script:failCount++ }
}

Write-Host "`n━━━ SOK HOTFIX v4.3.3 ━━━" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════
# 1. SPACEAUDIT: Route output through Get-ScriptLogDir
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[1/4] SOK-SpaceAudit.ps1 — Output path fix" -ForegroundColor Yellow
$saPath = Join-Path $scriptDir 'SOK-SpaceAudit.ps1'

Patch-File -Path $saPath `
    -Find "    `$OutputDir = Join-Path `$env:USERPROFILE 'Documents\SOK\Audit'" `
    -Replace "    `$OutputDir = if (Get-Command Get-ScriptLogDir -ErrorAction SilentlyContinue) { Get-ScriptLogDir -ScriptName 'SOK-SpaceAudit' } else { Join-Path `$env:USERPROFILE 'Documents\SOK\Audit' }" `
    -Label 'SpaceAudit output via Get-ScriptLogDir'

# ═══════════════════════════════════════════════════════════════
# 2. MAINTENANCE: TRIM non-NTFS skip
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[2/4] SOK-Maintenance.ps1 — TRIM filesystem guard" -ForegroundColor Yellow
$maintPath = Join-Path $scriptDir 'SOK-Maintenance.ps1'

# Find the TRIM section and add filesystem check
# The pattern is: foreach drive, call Optimize-Volume
Patch-File -Path $maintPath `
    -Find "Write-SOKLog `"  TRIM: `$(`$d.DeviceID)" `
    -Replace @'
# v4.3.3: Skip TRIM on non-NTFS (FAT32 Google Drive etc.)
        $volFs = (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($d.DeviceID)'" -ErrorAction SilentlyContinue).FileSystem
        if ($volFs -and $volFs -ne 'NTFS') {
            Write-SOKLog "  TRIM skipped: $($d.DeviceID) ($volFs — TRIM requires NTFS)" -Level Debug
            continue
        }
        Write-SOKLog "  TRIM: $($d.DeviceID)
'@ `
    -Label 'TRIM non-NTFS guard'

# ═══════════════════════════════════════════════════════════════
# 3. COMMON: Ensure OneDrive+GoogleDriveFS in ProtectedProcesses
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[3/4] SOK-Common.psm1 — Verify ProtectedProcesses" -ForegroundColor Yellow
$commonPath = Join-Path $scriptDir 'common\SOK-Common.psm1'

# Check if it needs the additions
if (Test-Path $commonPath) {
    $cc = Get-Content $commonPath -Raw
    if ($cc -match 'OneDrive.*GoogleDriveFS.*AAD') {
        Write-Host "  [SKIP] ProtectedProcesses already has OneDrive+GoogleDriveFS+AAD" -ForegroundColor DarkGray
    }
    elseif ($cc -match "'claude'") {
        # v4.3.2 Common but missing the new additions
        Patch-File -Path $commonPath `
            -Find "'claude', 'Spotify', 'olk', 'OUTLOOK'," `
            -Replace "'claude', 'Spotify', 'olk', 'OUTLOOK', 'OneDrive', 'GoogleDriveFS', 'Microsoft.AAD.BrokerPlugin'," `
            -Label 'Add OneDrive+GoogleDriveFS+AAD to ProtectedProcesses'
    }
    else {
        Write-Host "  [SKIP] Common doesn't have claude in ProtectedProcesses — likely v4.3.2 with full list" -ForegroundColor DarkGray
    }
}

# ═══════════════════════════════════════════════════════════════
# 4. VERSION BUMP
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[4/4] Version bump" -ForegroundColor Yellow
Patch-File -Path $commonPath `
    -Find "`$script:SOKVersion = '4.3.2'" `
    -Replace "`$script:SOKVersion = '4.3.3'" `
    -Label 'Version 4.3.2 → 4.3.3'

# ═══════════════════════════════════════════════════════════════
# DIGITAL SIGNATURE FIX
# ═══════════════════════════════════════════════════════════════
Write-Host "`n━━━ DIGITAL SIGNATURE FIX ━━━" -ForegroundColor Cyan
Write-Host @"
The 'not digitally signed' error occurs when importing modules
interactively without -NoProfile or Bypass. Three fixes:

  Option A (recommended): Always use the SOK invocation pattern:
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\<script>.ps1

  Option B (per-session): Run once in your terminal:
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

  Option C (unblock the file): Run once:
    Unblock-File -Path .\common\SOK-Common.psm1
    Get-ChildItem .\*.ps1 | Unblock-File

  Option C is the fastest fix — files downloaded from the internet
  get a Zone.Identifier alternate data stream that PS treats as
  'untrusted'. Unblock-File removes that stream.
"@ -ForegroundColor Gray

Write-Host "`n━━━ HOTFIX v4.3.3 COMPLETE ━━━" -ForegroundColor Cyan
Write-Host "  Applied: $patchCount" -ForegroundColor Green
Write-Host "  Missed:  $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Yellow' } else { 'Green' })
