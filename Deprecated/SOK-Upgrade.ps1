<#
.SYNOPSIS
    SOK-Upgrade.ps1 — Bulk-patches all SOK scripts for Common v4.0.0 compatibility.

.DESCRIPTION
    Run once after deploying SOK-Common.psm1 v4.0.0. Patches every .ps1 in the scripts directory.
    Backs up each modified file to scripts\deprecated\ before writing.

    Applied patches:
    [1] Invoke-SOKPrerequisite calls after initialization (command-checked, safe in fallback mode)
    [2] ErrorAction fixes (SilentlyContinue for existence checks)
    [3] Cross-references (ProcessOptimizer <-> ServiceOptimizer)
    [4] Non-interactive nested execution guard (ServiceOptimizer)
    [5] Temp file cleanup noise suppression (Maintenance)
    [6] Scheduler banner/log integration

.PARAMETER ScriptDir
    Directory containing SOK scripts. Default: C:\Users\shelc\Documents\Journal\Projects\scripts

.PARAMETER DryRun
    Preview changes without writing files.

.NOTES
    Author: S. Clay Caddell / Claude
    Version: 1.1.0
    Date: 25Mar2026
    Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Upgrade.ps1 -DryRun
    Then: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Upgrade.ps1
#>
[CmdletBinding()]
param(
    [string]$ScriptDir = 'C:\Users\shelc\Documents\Journal\Projects\scripts',
    [switch]$DryRun
)

$ErrorActionPreference = 'Continue'
$patchCount = 0
$fileCount = 0
$skipCount = 0
$errors = @()

function Apply-Patch {
    param([string]$FilePath, [string]$OldText, [string]$NewText, [string]$Description)
    $content = Get-Content $FilePath -Raw -ErrorAction Stop
    if ($content.Contains($NewText)) {
        Write-Host "  [SKIP] $Description (already applied)" -ForegroundColor DarkGray
        $script:skipCount++
        return $false
    }
    if ($content.Contains($OldText)) {
        $content = $content.Replace($OldText, $NewText)
        if (-not $DryRun) { Set-Content -Path $FilePath -Value $content -Force -Encoding UTF8 -NoNewline }
        Write-Host "  [PATCH] $Description" -ForegroundColor Green
        $script:patchCount++
        return $true
    }
    Write-Host "  [MISS] $Description (anchor not found)" -ForegroundColor Yellow
    return $false
}

function Backup-Script {
    param([string]$FilePath)
    if ($DryRun) { return }
    $deprecDir = Join-Path (Split-Path $FilePath -Parent) 'deprecated'
    if (-not (Test-Path $deprecDir)) { New-Item -Path $deprecDir -ItemType Directory -Force | Out-Null }
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $name = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    $ext = [System.IO.Path]::GetExtension($FilePath)
    Copy-Item $FilePath (Join-Path $deprecDir "${name}_pre-v4_${ts}${ext}") -Force
}

Write-Host "`n━━━ SOK-Upgrade v1.1.0: Patching all scripts for Common v4.0.0 ━━━" -ForegroundColor Cyan
if ($DryRun) { Write-Host "  *** DRY RUN ***`n" -ForegroundColor Yellow }
Write-Host "  Dir: $ScriptDir`n" -ForegroundColor Gray

# ═══════════════════════════════════════════════════════════════
# UNIVERSAL PREREQ SNIPPET — safe even if Common not loaded (checks command existence)
# ═══════════════════════════════════════════════════════════════
# This block is inserted after $startTime = Get-Date in each script.
# Invoke-SOKPrerequisite only runs if Common v4.0.0 is loaded.

function Get-PrereqSnippet {
    param([string]$ScriptName)
    return @"

# v4.0.0: Prerequisite check (safe — no-op if Common not loaded or function absent)
if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript '$ScriptName'
}
"@
}

# ═══════════════════════════════════════════════════════════════
# PER-SCRIPT PATCHES
# ═══════════════════════════════════════════════════════════════

# --- Helper: apply prereq after $startTime = Get-Date ---
function Add-Prereq {
    param([string]$File, [string]$ScriptName)
    $filePath = Join-Path $ScriptDir $File
    if (-not (Test-Path $filePath)) {
        Write-Host "[$File] NOT FOUND" -ForegroundColor Red
        $script:errors += $File
        return
    }
    $script:fileCount++
    Write-Host "`n[$File]" -ForegroundColor Cyan
    Backup-Script -FilePath $filePath

    $snippet = Get-PrereqSnippet -ScriptName $ScriptName
    $anchor = '$startTime = Get-Date'
    Apply-Patch -FilePath $filePath `
        -OldText $anchor `
        -NewText ($anchor + $snippet) `
        -Description "Add prerequisite check for $ScriptName"
}

# Scripts with $startTime = Get-Date as anchor
Add-Prereq -File 'SOK-Inventory.ps1'        -ScriptName 'SOK-Inventory'
Add-Prereq -File 'SOK-Maintenance.ps1'       -ScriptName 'SOK-Maintenance'
Add-Prereq -File 'SOK-ProcessOptimizer.ps1'  -ScriptName 'SOK-ProcessOptimizer'
Add-Prereq -File 'SOK-SpaceAudit.ps1'        -ScriptName 'SOK-SpaceAudit'
Add-Prereq -File 'SOK-Offload.ps1'           -ScriptName 'SOK-Offload'
Add-Prereq -File 'SOK-Cleanup.ps1'           -ScriptName 'SOK-Cleanup'
Add-Prereq -File 'SOK-Archiver.ps1'          -ScriptName 'SOK-Archiver'
Add-Prereq -File 'SOK-Comparator.ps1'        -ScriptName 'SOK-Comparator'
Add-Prereq -File 'SOK-LiveDigest.ps1'        -ScriptName 'SOK-LiveDigest'

# --- SOK-Inventory: Fix ErrorAction on existence checks ---
$invPath = Join-Path $ScriptDir 'SOK-Inventory.ps1'
if (Test-Path $invPath) {
    Apply-Patch -FilePath $invPath `
        -OldText '$cmd = Get-Command $db.Cmd -ErrorAction Continue' `
        -NewText '$cmd = Get-Command $db.Cmd -ErrorAction SilentlyContinue' `
        -Description 'Fix mongod ErrorAction (existence check)'
    Apply-Patch -FilePath $invPath `
        -OldText '$gitCmd = Get-Command git -ErrorAction Continue' `
        -NewText '$gitCmd = Get-Command git -ErrorAction SilentlyContinue' `
        -Description 'Fix git ErrorAction (existence check)'
}

# --- SOK-Maintenance: Silence locked temp file noise ---
$maintPath = Join-Path $ScriptDir 'SOK-Maintenance.ps1'
if (Test-Path $maintPath) {
    Apply-Patch -FilePath $maintPath `
        -OldText 'Get-ChildItem -Path $item.Path -Force -ErrorAction Continue | Remove-Item -Recurse -Force -ErrorAction Continue' `
        -NewText 'Get-ChildItem -Path $item.Path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue' `
        -Description 'Silence locked temp file errors (expected, not actionable)'
}

# --- SOK-ProcessOptimizer: Add ServiceOptimizer cross-reference ---
$procPath = Join-Path $ScriptDir 'SOK-ProcessOptimizer.ps1'
if (Test-Path $procPath) {
    Write-Host "`n[SOK-ProcessOptimizer.ps1 — cross-ref]" -ForegroundColor Cyan
    Apply-Patch -FilePath $procPath `
        -OldText "Write-SOKLog `"Self-protected: PID `$myPID (Parent: `$myParentPID)`" -Level Warn" `
        -NewText @"
Write-SOKLog "Self-protected: PID `$myPID (Parent: `$myParentPID)" -Level Warn

# v4.0.0: Cross-reference ServiceOptimizer findings
`$svcOptLog = if (Get-Command Get-LatestLog -ErrorAction SilentlyContinue) { Get-LatestLog -ScriptName 'SOK-ServiceOptimizer' } else { `$null }
if (`$svcOptLog -and `$svcOptLog.Age.TotalHours -lt 48) {
    Write-SOKLog "ServiceOptimizer log: `$([math]::Round(`$svcOptLog.Age.TotalHours,1))h old -- cross-referencing" -Level Annotate
}
"@ `
        -Description 'Add ServiceOptimizer cross-reference'
}

# --- SOK-ServiceOptimizer: Add ProcessOptimizer cross-ref + nested guard ---
$svcPath = Join-Path $ScriptDir 'SOK-ServiceOptimizer.ps1'
if (Test-Path $svcPath) {
    $script:fileCount++
    Write-Host "`n[SOK-ServiceOptimizer.ps1]" -ForegroundColor Cyan
    Backup-Script -FilePath $svcPath

    # Insert after banner/log init, before first operational code
    Apply-Patch -FilePath $svcPath `
        -OldText "if (`$DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }" `
        -NewText @"
# v4.0.0: Prerequisite check
if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-ServiceOptimizer'
}

# v4.0.0: Cross-reference ProcessOptimizer findings
`$procOptLog = if (Get-Command Get-LatestLog -ErrorAction SilentlyContinue) { Get-LatestLog -ScriptName 'SOK-ProcessOptimizer' } else { `$null }
if (`$procOptLog -and `$procOptLog.Age.TotalHours -lt 48) {
    Write-SOKLog "ProcessOptimizer log: `$([math]::Round(`$procOptLog.Age.TotalHours,1))h old -- cross-referencing" -Level Annotate
}

# v4.0.0: Nested execution guard — force Report mode if called by prerequisite chain
if (`$Action -eq 'Interactive') {
    # Check if we're inside a prerequisite chain (parent is another SOK script)
    `$parentCmd = try { (Get-CimInstance Win32_Process -Filter "ProcessId=`$((Get-CimInstance Win32_Process -Filter "ProcessId=`$PID").ParentProcessId)" -ErrorAction SilentlyContinue).CommandLine } catch { '' }
    if (`$parentCmd -match 'SOK-') {
        Write-SOKLog 'Nested execution detected -- forcing Report mode (no user input hang)' -Level Warn
        `$Action = 'Report'
    }
}

if (`$DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }
"@ `
        -Description 'Add prereq + ProcessOptimizer cross-ref + nested execution guard'
}

# --- SOK-DefenderOptimizer: Insert prereq after log init ---
$defPath = Join-Path $ScriptDir 'SOK-DefenderOptimizer.ps1'
if (Test-Path $defPath) {
    $script:fileCount++
    Write-Host "`n[SOK-DefenderOptimizer.ps1]" -ForegroundColor Cyan
    Backup-Script -FilePath $defPath
    Apply-Patch -FilePath $defPath `
        -OldText "$('$')logPath = Initialize-SOKLog -ScriptName 'SOK-DefenderOptimizer'" `
        -NewText @"
`$logPath = Initialize-SOKLog -ScriptName 'SOK-DefenderOptimizer'

# v4.0.0: Prerequisite check
if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-DefenderOptimizer'
}
"@ `
        -Description 'Add prerequisite check'
}

# --- SOK-Scheduler: Add banner + log init ---
$schedPath = Join-Path $ScriptDir 'SOK-Scheduler.ps1'
if (Test-Path $schedPath) {
    $script:fileCount++
    Write-Host "`n[SOK-Scheduler.ps1]" -ForegroundColor Cyan
    Backup-Script -FilePath $schedPath
    Apply-Patch -FilePath $schedPath `
        -OldText "Write-Host `"`n━━━ SOK TASK SCHEDULER ━━━`" -ForegroundColor Cyan" `
        -NewText @"
if (Get-Command Show-SOKBanner -ErrorAction SilentlyContinue) {
    Show-SOKBanner -ScriptName 'SOK-Scheduler'
    Initialize-SOKLog -ScriptName 'SOK-Scheduler' | Out-Null
}
Write-Host "`n━━━ SOK TASK SCHEDULER ━━━" -ForegroundColor Cyan
"@ `
        -Description 'Add banner and log initialization'
}

# --- SOK-LiveScan: Add Common integration ---
$lsPath = Join-Path $ScriptDir 'SOK-LiveScan.ps1'
if (Test-Path $lsPath) {
    $script:fileCount++
    Write-Host "`n[SOK-LiveScan.ps1]" -ForegroundColor Cyan
    Backup-Script -FilePath $lsPath
    Apply-Patch -FilePath $lsPath `
        -OldText "`$ErrorActionPreference = 'Continue'" `
        -NewText @"
`$ErrorActionPreference = 'Continue'

# v4.0.0: Common module integration (optional — script works standalone for raw speed)
`$_modulePath = Join-Path `$PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path `$_modulePath)) { `$_modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path `$_modulePath) {
    Import-Module `$_modulePath -Force
    Show-SOKBanner -ScriptName 'SOK-LiveScan' -Subheader "Source: `$SourcePath | DirsOnly: `$DirsOnly"
    Initialize-SOKLog -ScriptName 'SOK-LiveScan' | Out-Null
}
"@ `
        -Description 'Add Common module integration (banner, logging)'
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
Write-Host "`n$('═' * 60)" -ForegroundColor Magenta
Write-Host "  SOK-UPGRADE COMPLETE" -ForegroundColor Cyan
Write-Host "$('═' * 60)" -ForegroundColor Magenta
Write-Host "  Files processed:    $fileCount" -ForegroundColor $(if ($fileCount -gt 0) { 'Green' } else { 'Yellow' })
Write-Host "  Patches applied:    $patchCount" -ForegroundColor $(if ($patchCount -gt 0) { 'Green' } else { 'Yellow' })
Write-Host "  Already applied:    $skipCount" -ForegroundColor DarkGray
Write-Host "  Errors:             $($errors.Count)" -ForegroundColor $(if ($errors.Count -gt 0) { 'Red' } else { 'Green' })
if ($errors.Count -gt 0) { Write-Host "  Missing: $($errors -join ', ')" -ForegroundColor Red }
if ($DryRun) {
    Write-Host "`n  *** DRY RUN — run without -DryRun to apply ***" -ForegroundColor Yellow
}
else {
    Write-Host "`n  Backups: scripts\deprecated\*_pre-v4_*" -ForegroundColor DarkCyan
    Write-Host "  Validate: SOK-Inventory -ScanDepth 3, then SOK-Maintenance -Mode Quick" -ForegroundColor Gray
}
Write-Host "$('═' * 60)`n" -ForegroundColor Magenta
