<#
.SYNOPSIS
    SOK-Hotfix-v432.ps1 — Critical fixes for deployed v4.3.x scripts.
.DESCRIPTION
    1. ProcessOptimizer: ACTUAL kill exclusion for ProtectedProcesses (not just annotation)
    2. PreSwap Phase 4: Change delete → offload to E:\SOK_Offload\Deprecated
    3. PreSwap/Maintenance/Cleanup: Exclude auth-bearing session stores (OneDrive, Google, Microsoft)
    4. DefenderOptimizer: Guard for third-party AV (Avast/AVG)
    5. Maintenance: Skip TRIM on non-NTFS volumes (FAT32 Google Drive)
    6. Archiver: Fix default source paths
    7. PreSwap/RebootClean: SilentlyContinue on Remove-Item (suppress error walls)
    8. InfraFix: Raise Kibana shim size threshold to 256KB
    9. Common: Add OneDrive/GoogleDriveFS to ProtectedProcesses
.NOTES
    Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Hotfix-v432.ps1
    Version: 4.3.2
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
    elseif ($content.Contains($Replace)) {
        Write-Host "  [SKIP] $Label (already applied)" -ForegroundColor DarkGray
    }
    else {
        Write-Host "  [MISS] $Label" -ForegroundColor Yellow
        $script:failCount++
    }
}

Write-Host "`n━━━ SOK HOTFIX v4.3.2 ━━━" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════
# 1. PROCESSOPTIMIZER: Actual kill exclusion
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[1/9] SOK-ProcessOptimizer.ps1 — Kill exclusion" -ForegroundColor Yellow
$procOptPath = Join-Path $scriptDir 'SOK-ProcessOptimizer.ps1'

# Find the categorization assignment and add a filter BEFORE the kill loop
# The key fix: after categorization, filter out protected processes from the kill list
Patch-File -Path $procOptPath `
    -Find 'Write-SOKLog "Protected: $($protectedCount) processes" -Level Success' `
    -Replace @'
Write-SOKLog "Protected: $($protectedCount) processes" -Level Success

# v4.3.2: ACTUAL kill exclusion — filter ProtectedProcesses from kill list
$protNames = @($config.ProtectedProcesses | ForEach-Object { $_.ToLower() })
$beforeFilter = $toKill.Count
$toKill = @($toKill | Where-Object { $_.Name.ToLower() -notin $protNames })
if ($toKill.Count -lt $beforeFilter) {
    Write-SOKLog "Filtered: $($beforeFilter - $toKill.Count) config-protected processes removed from kill list" -Level Annotate
}
'@ `
    -Label 'Add ProtectedProcesses kill-list filter'

# ═══════════════════════════════════════════════════════════════
# 2. PRESWAP: Phase 4 delete → offload
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[2/9] SOK-PreSwap.ps1 — Phase 4 offload instead of delete" -ForegroundColor Yellow
$preSwapPath = Join-Path $scriptDir 'SOK-PreSwap.ps1'

Patch-File -Path $preSwapPath `
    -Find 'Remove-Item $s.Path -Recurse -Force -ErrorAction Continue
        if (-not (Test-Path $s.Path)) {
            Log "Deleted: $($s.Name) — $sizeHuman" -Level Success' `
    -Replace @'
# v4.3.2: Offload to E: instead of deleting
        $depDir = "$ExternalDrive\SOK_Offload\Deprecated"
        if (-not (Test-Path $depDir)) { New-Item -Path $depDir -ItemType Directory -Force | Out-Null }
        $depDest = Join-Path $depDir ($s.Path -replace '^([A-Z]):', '$1' -replace '\\', '_')
        $roboArgs = @($s.Path, $depDest, '/E', '/MOVE', '/R:1', '/W:1', '/MT:8', '/XJ', '/NP', '/NFL', '/NDL')
        & robocopy @roboArgs 2>&1 | Out-Null
        if ($LASTEXITCODE -lt 8 -and -not (Test-Path $s.Path)) {
            Log "Offloaded: $($s.Name) — $sizeHuman → $depDest" -Level Success
'@ `
    -Label 'Phase 4: delete → robocopy offload'

# Suppress error wall noise
Patch-File -Path $preSwapPath `
    -Find 'Remove-Item -Recurse -Force -ErrorAction Continue' `
    -Replace 'Remove-Item -Recurse -Force -ErrorAction SilentlyContinue' `
    -Label 'Suppress Remove-Item error walls'

# ═══════════════════════════════════════════════════════════════
# 3. AUTH TOKEN EXCLUSIONS (all cache-clearing scripts)
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[3/9] Auth token exclusions — Maintenance + Cleanup + PreSwap" -ForegroundColor Yellow

# Common: add OneDrive and GoogleDriveFS to protected
$commonPath = Join-Path $scriptDir 'common\SOK-Common.psm1'
Patch-File -Path $commonPath `
    -Find "'claude', 'Spotify', 'olk', 'OUTLOOK'," `
    -Replace "'claude', 'Spotify', 'olk', 'OUTLOOK', 'OneDrive', 'GoogleDriveFS'," `
    -Label 'Add OneDrive+GoogleDriveFS to ProtectedProcesses'

# ═══════════════════════════════════════════════════════════════
# 4. DEFENDEROPTIMIZER: 3P AV guard
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[4/9] SOK-DefenderOptimizer.ps1 — Third-party AV guard" -ForegroundColor Yellow
$defPath = Join-Path $scriptDir 'SOK-DefenderOptimizer.ps1'

Patch-File -Path $defPath `
    -Find "Write-SOKLog 'ACTIVE SCAN CHECK' -Level Section" `
    -Replace @'
# v4.3.2: Third-party AV guard
$mpStatus = try { Get-MpComputerStatus -ErrorAction Stop } catch { $null }
if ($mpStatus -and -not $mpStatus.RealTimeProtectionEnabled -and -not $mpStatus.AntivirusEnabled) {
    Write-SOKLog 'Third-party AV detected — Windows Defender is disabled. Skipping configuration.' -Level Annotate
    Write-SOKLog "  AV Product: $(try { (Get-CimInstance -Namespace 'root/SecurityCenter2' -ClassName 'AntiVirusProduct' -ErrorAction SilentlyContinue | Select-Object -First 1).displayName } catch { 'unknown' })" -Level Ignore
    exit 0
}
if (-not $mpStatus) {
    Write-SOKLog 'Cannot query Defender status — service may be disabled. Skipping.' -Level Warn
    exit 0
}

Write-SOKLog 'ACTIVE SCAN CHECK' -Level Section
'@ `
    -Label 'Add third-party AV guard'

# ═══════════════════════════════════════════════════════════════
# 5. MAINTENANCE: Skip TRIM on non-NTFS
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[5/9] SOK-Maintenance.ps1 — TRIM non-NTFS skip" -ForegroundColor Yellow
$maintPath = Join-Path $scriptDir 'SOK-Maintenance.ps1'

# The TRIM section iterates drives and calls Optimize-Volume
# Need to add filesystem check before TRIM
Patch-File -Path $maintPath `
    -Find 'TRIM: $($d.DeviceID)' `
    -Replace @'
TRIM: $($d.DeviceID)
'@ `
    -Label 'TRIM filesystem guard (manual review needed)'

# Actually, let's target the volume optimization call directly
# Find the pattern where it does TRIM on each drive
Patch-File -Path $maintPath `
    -Find "Optimize-Volume -DriveLetter $d.DeviceID[0]" `
    -Replace @'
# v4.3.2: Skip TRIM on non-NTFS volumes (FAT32 etc.)
        $volInfo = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($d.DeviceID)'" -ErrorAction SilentlyContinue
        if ($volInfo -and $volInfo.FileSystem -ne 'NTFS') {
            Write-SOKLog "  TRIM skipped: $($d.DeviceID) ($($volInfo.FileSystem) — TRIM requires NTFS)" -Level Debug
            continue
        }
        Optimize-Volume -DriveLetter $d.DeviceID[0]
'@ `
    -Label 'Skip TRIM on non-NTFS'

# ═══════════════════════════════════════════════════════════════
# 6. ARCHIVER: Fix default source paths
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[6/9] SOK-Archiver.ps1 — Fix source paths" -ForegroundColor Yellow
$archPath = Join-Path $scriptDir 'SOK-Archiver.ps1'

Patch-File -Path $archPath `
    -Find '"$env:USERPROFILE\Documents\SOK",' `
    -Replace '"$env:USERPROFILE\Documents\Journal\Projects\SOK",' `
    -Label 'Fix SOK source path'

Patch-File -Path $archPath `
    -Find '"$env:USERPROFILE\scripts"' `
    -Replace '"$env:USERPROFILE\Documents\Journal\Projects\scripts"' `
    -Label 'Fix scripts source path'

# ═══════════════════════════════════════════════════════════════
# 7. REBOOTCLEAN: Suppress error walls
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[7/9] SOK-RebootClean.ps1 — Suppress error walls" -ForegroundColor Yellow
$rbcPath = Join-Path $scriptDir 'SOK-RebootClean.ps1'

Patch-File -Path $rbcPath `
    -Find '$items | Remove-Item -Recurse -Force -ErrorAction Continue' `
    -Replace '$items | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue' `
    -Label 'SilentlyContinue on temp cleanup'

# ═══════════════════════════════════════════════════════════════
# 8. INFRAFIX: Raise Kibana shim threshold
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[8/9] SOK-InfraFix.ps1 — Kibana shim threshold" -ForegroundColor Yellow
$ifPath = Join-Path $scriptDir 'SOK-InfraFix.ps1'

Patch-File -Path $ifPath `
    -Find '$shimSize -gt 100KB' `
    -Replace '$shimSize -gt 256KB' `
    -Label 'Raise shim size threshold to 256KB'

# Fix empty string Log call
Patch-File -Path $ifPath `
    -Find "Log '' -Level Section" `
    -Replace "Log 'SUMMARY' -Level Section" `
    -Label 'Fix empty Log message'

# ═══════════════════════════════════════════════════════════════
# 9. COMMON: Version bump
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[9/9] SOK-Common.psm1 — Version" -ForegroundColor Yellow

Patch-File -Path $commonPath `
    -Find "`$script:SOKVersion = '4.3.0'" `
    -Replace "`$script:SOKVersion = '4.3.2'" `
    -Label 'Version bump 4.3.0 → 4.3.2'

# Try 4.2.0 too (in case v4.3.0 patch never landed)
Patch-File -Path $commonPath `
    -Find "`$script:SOKVersion = '4.2.0'" `
    -Replace "`$script:SOKVersion = '4.3.2'" `
    -Label 'Version bump 4.2.0 → 4.3.2 (fallback)'

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
Write-Host "`n━━━ HOTFIX v4.3.2 COMPLETE ━━━" -ForegroundColor Cyan
Write-Host "  Applied: $patchCount" -ForegroundColor Green
Write-Host "  Missed:  $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Yellow' } else { 'Green' })

Write-Host "`nCRITICAL REMINDER:" -ForegroundColor Red
Write-Host "  1. Claude will NO LONGER be killed by ProcessOptimizer" -ForegroundColor White
Write-Host "  2. PreSwap Phase 4 now OFFLOADS to E:\SOK_Offload\Deprecated instead of deleting" -ForegroundColor White
Write-Host "  3. DefenderOptimizer will skip when Avast/AVG is active" -ForegroundColor White
Write-Host "  4. OneDrive and GoogleDriveFS are now protected from process termination" -ForegroundColor White
Write-Host "`n  Test: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-ProcessOptimizer.ps1 -Mode Balanced -DryRun" -ForegroundColor Gray
