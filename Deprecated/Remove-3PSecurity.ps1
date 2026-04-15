<#
.SYNOPSIS
    Remove-3PSecurity.ps1 — Thorough removal of Avast, AVG, and Avira remnants.
.DESCRIPTION
    These tools embed services, drivers, scheduled tasks, temp locks, and registry
    entries that survive normal uninstall. This script hunts all of them.
.PARAMETER DryRun
    Preview without removing.
.NOTES
    Run as ADMIN: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Remove-3PSecurity.ps1 -DryRun
    Then: pwsh -NoProfile -ExecutionPolicy Bypass -File .\Remove-3PSecurity.ps1
    REBOOT AFTER running live.
#>
[CmdletBinding()]
param([switch]$DryRun)

$ErrorActionPreference = 'Continue'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
    Write-Host "ERROR: Run as Administrator" -ForegroundColor Red; exit 1
}

Write-Host "`n━━━ 3P SECURITY REMOVAL ━━━$(if ($DryRun) { ' [DRY RUN]' })" -ForegroundColor Cyan
$removed = 0; $skipped = 0

function Try-Remove {
    param([string]$Path, [string]$Label)
    if (Test-Path $Path) {
        if ($DryRun) { Write-Host "  [DRY] Would remove: $Label — $Path" -ForegroundColor Yellow }
        else {
            Remove-Item $Path -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path $Path) { Write-Host "  [PARTIAL] Locked files remain: $Label" -ForegroundColor DarkYellow }
            else { Write-Host "  [OK] Removed: $Label" -ForegroundColor Green; $script:removed++ }
        }
    } else { $script:skipped++ }
}

# ═══════════════════════════════════════════════════
# 1. STOP SERVICES
# ═══════════════════════════════════════════════════
Write-Host "`n[1/6] Stopping services..." -ForegroundColor Yellow
$svcNames = @('avast*', 'avg*', 'avira*', 'aswbIDSAgent', 'AvastWscReporter', 'AVGSvc')
foreach ($pattern in $svcNames) {
    Get-Service -Name $pattern -ErrorAction SilentlyContinue | ForEach-Object {
        if ($DryRun) { Write-Host "  [DRY] Would stop: $($_.Name) ($($_.Status))" -ForegroundColor Yellow }
        else {
            Stop-Service $_.Name -Force -ErrorAction SilentlyContinue
            Set-Service $_.Name -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "  [OK] Stopped + disabled: $($_.Name)" -ForegroundColor Green
        }
    }
}

# ═══════════════════════════════════════════════════
# 2. KILL PROCESSES
# ═══════════════════════════════════════════════════
Write-Host "`n[2/6] Killing processes..." -ForegroundColor Yellow
$procNames = @('AvastUI', 'AvastSvc', 'aswEngSrv', 'AVGUI', 'AVGSvc',
               'avira*', 'Avira.Spotlight*', 'Avira.ServiceHost',
               'aswToolsSvc', 'wsc_proxy', 'AvastBrowserCrashHandler',
               'SDTray', 'instup', 'overseer')
foreach ($name in $procNames) {
    Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object {
        if ($DryRun) { Write-Host "  [DRY] Would kill: $($_.Name) (PID $($_.Id))" -ForegroundColor Yellow }
        else { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue; Write-Host "  [OK] Killed: $($_.Name)" -ForegroundColor Green }
    }
}

# ═══════════════════════════════════════════════════
# 3. UNINSTALL VIA WMIC/WINGET
# ═══════════════════════════════════════════════════
Write-Host "`n[3/6] Uninstalling packages..." -ForegroundColor Yellow
$uninstallNames = @('Avast Free Antivirus', 'AVG AntiVirus FREE', 'Avira',
                     'Avast Cleanup', 'AVG TuneUp', 'Avast Secure Browser',
                     'AVG Secure Browser', 'Avira System Speedup')
foreach ($name in $uninstallNames) {
    $pkg = Get-Package -Name "*$name*" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pkg) {
        if ($DryRun) { Write-Host "  [DRY] Would uninstall: $($pkg.Name)" -ForegroundColor Yellow }
        else {
            Write-Host "  Uninstalling: $($pkg.Name)..." -ForegroundColor Gray
            try { $pkg | Uninstall-Package -Force -ErrorAction SilentlyContinue }
            catch { Write-Host "  [WARN] Package manager failed, trying winget..." -ForegroundColor DarkYellow }
        }
    }
}
# Winget fallback
foreach ($name in @('Avast', 'AVG', 'Avira')) {
    $found = winget list --name $name 2>$null | Where-Object { $_ -match $name }
    if ($found) {
        if ($DryRun) { Write-Host "  [DRY] Would winget uninstall: $name" -ForegroundColor Yellow }
        else { winget uninstall --name $name --silent --accept-source-agreements 2>$null }
    }
}

# ═══════════════════════════════════════════════════
# 4. REMOVE FILE REMNANTS
# ═══════════════════════════════════════════════════
Write-Host "`n[4/6] Removing file remnants..." -ForegroundColor Yellow
$paths = @(
    @{ Path = 'C:\Program Files\Avast Software';           Label = 'Avast Program Files' }
    @{ Path = 'C:\Program Files\AVG';                      Label = 'AVG Program Files' }
    @{ Path = 'C:\Program Files\Common Files\Avast';       Label = 'Avast Common Files' }
    @{ Path = 'C:\Program Files (x86)\Avast Software';     Label = 'Avast x86' }
    @{ Path = 'C:\Program Files (x86)\AVG';                Label = 'AVG x86' }
    @{ Path = 'C:\ProgramData\Avast Software';             Label = 'Avast ProgramData' }
    @{ Path = 'C:\ProgramData\AVG';                        Label = 'AVG ProgramData' }
    @{ Path = 'C:\ProgramData\AVAST Software';             Label = 'Avast ProgramData (alt)' }
    @{ Path = "$env:LOCALAPPDATA\Avast Software";          Label = 'Avast LocalAppData' }
    @{ Path = "$env:LOCALAPPDATA\AVG";                     Label = 'AVG LocalAppData' }
    @{ Path = "$env:APPDATA\Avast Software";               Label = 'Avast Roaming' }
    @{ Path = "$env:APPDATA\AVG";                          Label = 'AVG Roaming' }
    @{ Path = 'C:\Windows\Temp\_avast_';                   Label = 'Avast temp locks' }
    @{ Path = 'C:\Windows\Temp\_avg_';                     Label = 'AVG temp locks' }
    @{ Path = "$env:LOCALAPPDATA\Avira";                   Label = 'Avira LocalAppData' }
    @{ Path = "$env:APPDATA\Avira";                        Label = 'Avira Roaming' }
    @{ Path = 'C:\ProgramData\Avira';                      Label = 'Avira ProgramData' }
    @{ Path = 'C:\Program Files (x86)\Avira';              Label = 'Avira x86' }
    @{ Path = 'C:\Program Files\Avira';                    Label = 'Avira Program Files' }
)
foreach ($p in $paths) { Try-Remove -Path $p.Path -Label $p.Label }

# ═══════════════════════════════════════════════════
# 5. REMOVE SCHEDULED TASKS
# ═══════════════════════════════════════════════════
Write-Host "`n[5/6] Removing scheduled tasks..." -ForegroundColor Yellow
Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -match 'avast|avg|avira' -or $_.TaskPath -match 'avast|avg|avira'
} | ForEach-Object {
    if ($DryRun) { Write-Host "  [DRY] Would remove task: $($_.TaskName)" -ForegroundColor Yellow }
    else {
        Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  [OK] Removed task: $($_.TaskName)" -ForegroundColor Green
        $script:removed++
    }
}

# ═══════════════════════════════════════════════════
# 6. CLEAN REGISTRY (keys only, not values in system hives)
# ═══════════════════════════════════════════════════
Write-Host "`n[6/6] Cleaning registry..." -ForegroundColor Yellow
$regPaths = @(
    'HKLM:\SOFTWARE\Avast Software', 'HKLM:\SOFTWARE\AVG', 'HKLM:\SOFTWARE\AVAST Software'
    'HKLM:\SOFTWARE\WOW6432Node\Avast Software', 'HKLM:\SOFTWARE\WOW6432Node\AVG'
    'HKCU:\SOFTWARE\Avast Software', 'HKCU:\SOFTWARE\AVG', 'HKCU:\SOFTWARE\Avira'
    'HKLM:\SOFTWARE\Avira'
)
foreach ($rp in $regPaths) {
    if (Test-Path $rp) {
        if ($DryRun) { Write-Host "  [DRY] Would remove: $rp" -ForegroundColor Yellow }
        else {
            Remove-Item $rp -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  [OK] Removed: $rp" -ForegroundColor Green
            $removed++
        }
    }
}

# ═══════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════
Write-Host "`n━━━ REMOVAL COMPLETE ━━━" -ForegroundColor Cyan
Write-Host "  Removed: $removed" -ForegroundColor Green
Write-Host "  Skipped: $skipped (not found)" -ForegroundColor DarkGray
if (-not $DryRun) {
    Write-Host "`n  REBOOT REQUIRED to release kernel-level drivers." -ForegroundColor Red
    Write-Host "  After reboot, run again to catch any survivors." -ForegroundColor Yellow
}
