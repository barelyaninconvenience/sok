<#
.SYNOPSIS
    SOK-Hotfix-v431.ps1 — Patches deployed v4.3.0 scripts in-place.
.DESCRIPTION
    Fixes:
    1. Inventory: Scoop v0.5.3 commands (export→dump, list→search --installed, 2>$null noise suppression)
    2. Maintenance: Scoop cache (cleanup→cache rm), VS Installer Package Cache (C:\ProgramData\Package Cache)
    3. Maintenance: Remaining HumanSize→KB in deep cache log line
.NOTES
    Run from the scripts directory:
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Hotfix-v431.ps1
    Version: 4.3.1
#>

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = 'C:\Users\shelc\Documents\Journal\Projects\scripts' }

$patchCount = 0
$failCount = 0

function Patch-File {
    param([string]$Path, [string]$Find, [string]$Replace, [string]$Label)
    if (-not (Test-Path $Path)) { Write-Host "  SKIP: $Path not found" -ForegroundColor Yellow; return }
    $content = Get-Content $Path -Raw
    if ($content -match [regex]::Escape($Find)) {
        $content = $content.Replace($Find, $Replace)
        Set-Content -Path $Path -Value $content -Force -NoNewline
        Write-Host "  [OK] $Label" -ForegroundColor Green
        $script:patchCount++
    }
    elseif ($content -match [regex]::Escape($Replace)) {
        Write-Host "  [SKIP] $Label (already applied)" -ForegroundColor DarkGray
    }
    else {
        Write-Host "  [MISS] $Label" -ForegroundColor Yellow
        $script:failCount++
    }
}

Write-Host "`n━━━ SOK HOTFIX v4.3.1 ━━━" -ForegroundColor Cyan

# ═══════════════════════════════════════════════════════════════
# INVENTORY: Scoop v0.5.3 command fixes
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[1/3] SOK-Inventory.ps1 — Scoop v0.5.3" -ForegroundColor Yellow
$invPath = Join-Path $scriptDir 'SOK-Inventory.ps1'

# export → dump (with 2>$null)
Patch-File -Path $invPath `
    -Find '$exportRaw = & scoop export 2>&1' `
    -Replace '$exportRaw = & scoop dump 2>$null' `
    -Label 'scoop export → dump'

# list → search --installed (with 2>$null)
Patch-File -Path $invPath `
    -Find '$listRaw = & scoop list 2>&1' `
    -Replace '$listRaw = & scoop search --installed 2>$null' `
    -Label 'scoop list → search --installed'

# ═══════════════════════════════════════════════════════════════
# MAINTENANCE: Scoop cache + VS Package Cache + HumanSize
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[2/3] SOK-Maintenance.ps1 — Scoop cache + VS Installer" -ForegroundColor Yellow
$maintPath = Join-Path $scriptDir 'SOK-Maintenance.ps1'

# cleanup → cache rm
Patch-File -Path $maintPath `
    -Find "@{ Name = 'Scoop';  Cmd = 'scoop';  Args = 'cleanup *' }" `
    -Replace "@{ Name = 'Scoop';  Cmd = 'scoop';  Args = 'cache rm *' }" `
    -Label 'scoop cleanup → cache rm'

# Add C:\ProgramData\Package Cache to Thorough deep purge
Patch-File -Path $maintPath `
    -Find "@{ Path = `"`$env:LOCALAPPDATA\Package Cache`";                    Label = 'Local Package Cache' }" `
    -Replace "@{ Path = `"`$env:LOCALAPPDATA\Package Cache`";                    Label = 'Local Package Cache' }`n            @{ Path = 'C:\ProgramData\Package Cache';                       Label = 'VS Installer Package Cache' }" `
    -Label 'Add ProgramData Package Cache to Thorough'

# HumanSize → KB in deep cache log line
Patch-File -Path $maintPath `
    -Find 'Cleaned: $($dp.Label) — $(Get-HumanSize ($sizeKB * 1KB))' `
    -Replace 'Cleaned: $($dp.Label) — $sizeKB KB' `
    -Label 'HumanSize → KB in deep cache'

# HumanSize → KB in C: space freed
Patch-File -Path $maintPath `
    -Find 'C: space freed: $(Get-HumanSize ($freedKB * 1KB))' `
    -Replace 'C: space freed: $freedKB KB' `
    -Label 'HumanSize → KB in space freed'

# ═══════════════════════════════════════════════════════════════
# COMMON: Version bump
# ═══════════════════════════════════════════════════════════════
Write-Host "`n[3/3] SOK-Common.psm1 — Version" -ForegroundColor Yellow
$commonPath = Join-Path $scriptDir 'common\SOK-Common.psm1'

Patch-File -Path $commonPath `
    -Find "`$script:SOKVersion = '4.3.0'" `
    -Replace "`$script:SOKVersion = '4.3.1'" `
    -Label 'Version bump 4.3.0 → 4.3.1'

# Add Restructure to prerequisite map
Patch-File -Path $commonPath `
    -Find "'SOK-Upgrade' = @()" `
    -Replace "'SOK-Upgrade' = @(); 'SOK-Restructure' = @('SOK-Inventory')" `
    -Label 'Add SOK-Restructure to prereq map'

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
Write-Host "`n━━━ HOTFIX COMPLETE ━━━" -ForegroundColor Cyan
Write-Host "  Applied: $patchCount" -ForegroundColor Green
Write-Host "  Missed:  $failCount" -ForegroundColor $(if ($failCount -gt 0) { 'Yellow' } else { 'Green' })
Write-Host "  Run a quick Inventory test to verify scoop:" -ForegroundColor Gray
Write-Host "  pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Inventory.ps1 -ScanCaliber 3" -ForegroundColor Gray
