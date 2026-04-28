<#
.SYNOPSIS
    SOK-DefenderOptimizer.ps1 — Windows Defender performance tuning for dev workstations.

.DESCRIPTION
    Configures Defender for minimal impact on development workflows:
    - CPU throttling during scans
    - Low-priority scanning
    - Development path exclusions
    - Archive scanning disabled
    - Scheduled scan timing (3 AM)

    Does NOT disable real-time protection or tamper protection.

.PARAMETER DryRun
    Show what would change without applying.


.NOTES
    Author: S. Clay Caddell
    Version: 1.3.0
    Date: 02Apr2026
    Domain: PRESENT — configures Defender for dev workstation; safe for nightly unattended runs
    Changelog: 1.3.0 — add param([switch]$DryRun) — was missing entirely;
               $DryRun was used throughout body but never bound from CLI (live bug).
#>

[CmdletBinding()]
param([switch]$DryRun)

#Requires -Version 7.0
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else { Write-Error "SOK-Common.psm1 not found"; exit 1 }

Show-SOKBanner -ScriptName 'DefenderOptimizer'
$logPath = Initialize-SOKLog -ScriptName 'SOK-DefenderOptimizer'

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-DefenderOptimizer'
}

# ── SYSTEM-CONTEXT PATH RESOLUTION ──
if ($env:USERPROFILE -like '*systemprofile*') {
    $env:USERPROFILE  = 'C:\Users\shelc'
    $env:LOCALAPPDATA = 'C:\Users\shelc\AppData\Local'
    $env:APPDATA      = 'C:\Users\shelc\AppData\Roaming'
    Write-SOKLog '[SYSTEM-CONTEXT] Remapped profile env vars to C:\Users\shelc' -Level Warn
}

if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

# ═══════════════════════════════════════════════════════════════
# STOP ACTIVE SCANS
# ═══════════════════════════════════════════════════════════════
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
$scanProcs = Get-Process MpCmdRun -ErrorAction SilentlyContinue
if ($scanProcs) {
    if (-not $DryRun) {
        $scanProcs | Stop-Process -Force -ErrorAction Continue
        Write-SOKLog "Stopped $($scanProcs.Count) active scan process(es)" -Level Success
    }
    else {
        Write-SOKLog "[DRY] Would stop $($scanProcs.Count) scan process(es)" -Level Debug
    }
}
else {
    Write-SOKLog 'No active scans running' -Level Ignore
}

# ═══════════════════════════════════════════════════════════════
# PERFORMANCE SETTINGS
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PERFORMANCE CONFIGURATION' -Level Section

$settings = @(
    @{ Cmd = { Set-MpPreference -ScanAvgCPULoadFactor 20 };                Desc = 'CPU load factor: 20%' }
    @{ Cmd = { Set-MpPreference -EnableLowCpuPriority $true };             Desc = 'Low CPU priority: enabled' }
    @{ Cmd = { Set-MpPreference -DisableArchiveScanning $true };           Desc = 'Archive scanning: disabled' }
    @{ Cmd = { Set-MpPreference -ScanScheduleQuickScanTime 180 };          Desc = 'Quick scan time: 3:00 AM' }
    @{ Cmd = { Set-MpPreference -MAPSReporting Basic };                    Desc = 'Cloud reporting: Basic' }
    @{ Cmd = { Set-MpPreference -SubmitSamplesConsent 2 };                 Desc = 'Sample submission: NeverSend' }
)

foreach ($s in $settings) {
    if ($DryRun) {
        Write-SOKLog "[DRY] Would set: $($s.Desc)" -Level Debug
    }
    else {
        try {
            & $s.Cmd
            Write-SOKLog "Set: $($s.Desc)" -Level Success
        }
        catch { Write-SOKLog "Failed: $($s.Desc) — $_" -Level Warn }
    }
}

# ═══════════════════════════════════════════════════════════════
# DEVELOPMENT PATH EXCLUSIONS
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PATH EXCLUSIONS' -Level Section

$exclusionPaths = @(
    "$env:USERPROFILE\Documents\Journal\Projects"
    "$env:USERPROFILE\Documents\Journal\Projects\SOK"
    "$env:USERPROFILE\.cargo"
    "$env:USERPROFILE\.npm"
    "$env:USERPROFILE\.pyenv"
    "$env:USERPROFILE\scoop"
    "$env:LOCALAPPDATA\Programs\Python"
    'C:\ProgramData\chocolatey'
    'C:\tools'
    'C:\Program Files\Git'
    'C:\Program Files\Docker'
    'C:\ProgramData\Docker'
    'C:\Program Files\PostgreSQL'
    'C:\Program Files\MongoDB'
    "$env:USERPROFILE\AppData\Local\JetBrains"
)

$added = 0
foreach ($path in $exclusionPaths) {
    if (Test-Path $path) {
        if (-not $DryRun) {
            try {
                Add-MpPreference -ExclusionPath $path -ErrorAction Stop
                Write-SOKLog "  Excluded: $path" -Level Success
                $added++
            }
            catch { Write-SOKLog "  Failed: $path — $_" -Level Warn }
        }
        else {
            Write-SOKLog "  [DRY] Would exclude: $path" -Level Debug
            $added++
        }
    }
}
Write-SOKLog "Exclusion paths added: $added" -Level Ignore

# ═══════════════════════════════════════════════════════════════
# DEFINITION UPDATE
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'DEFINITION UPDATE' -Level Section
if (-not $DryRun) {
    try {
        Update-MpSignature -ErrorAction Stop
        Write-SOKLog 'Malware definitions updated' -Level Success
    }
    catch { Write-SOKLog "Definition update failed: $_" -Level Warn }
}

# ═══════════════════════════════════════════════════════════════
# STATUS REPORT
# ═══════════════════════════════════════════════════════════════
$status = Get-MpComputerStatus -ErrorAction Continue
if ($status) {
    Write-SOKSummary -Stats ([ordered]@{
        RealTimeProtection = $status.RealTimeProtectionEnabled
        QuickScanAgeDays   = $status.QuickScanAge
        DefVersion         = $status.AntivirusSignatureVersion
        ExclusionsAdded    = $added
    }) -Title 'DEFENDER OPTIMIZED'
}
