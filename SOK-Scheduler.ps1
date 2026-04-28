#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    SOK-Scheduler v2.2.0 — Register/remove Windows Task Scheduler entries for all tactical SOK scripts.
.DESCRIPTION
    Synced against 14 daily tactical scripts + 1 weekly utility as of 17Apr2026.
    Backward-computed schedule ending at 05:35 with 160% avg-runtime spacing.
    Avg runtimes (seconds): InfraFix=20 Defender=16 Inventory=20 Maintenance=810
    SpaceAudit=4880 ProcOpt=26 SvcOpt=7 Offload=52 Cleanup=30
    LiveScan=1400 LiveDigest=106 Archiver=60 Backup=600. Total=~215min.

    Script param alignment (verified 02Apr2026):
    InfraFix          : -DryRun
    DefenderOptimizer : -DryRun  (added v1.3.0; scheduled runs omit -DryRun intentionally)
    Inventory         : -ScanCaliber [1-3]  -PreviousRunPath  -AllowRedundancy
    Maintenance       : -Mode [Quick|Standard|Deep|Thorough]  -DryRun
    SpaceAudit        : -MinSizeKB  -ScanDepth  -ThrottleLimit  -OutputDir
    ProcessOptimizer  : -Mode [Conservative|Balanced|Aggressive]  -DryRun
    ServiceOptimizer  : -Action [Auto|Interactive|Report]  -DryRun
    Offload           : -ExternalDrive  -InventoryPath  -MinSizeKB  -DryRun
    Cleanup           : -DryRun  -ExternalDrive
    LiveScan          : -SourcePath  -OutJson  -ErrorLog  -DirsOnly  -MinSizeKB  -ExcludeNoisyDirs
    LiveDigest        : -InputPath  -TopN  -OutputDir
    Archiver          : -SourceFolders  -BaseName  -OutputDir  -Extensions  -DryRun
    Backup            : -Sources  -Destination  -Incremental  -Threads  -DryRun
                        SCHEDULED WITH /E ONLY — -Incremental (/MIR) NEVER in scheduled runs.
                        /MIR deletes from destination. Additive-only is the safe nightly default.
    Vectorize         : --incremental  (weekly, Sunday 01:00 — py -3.14)

.PARAMETER ScriptDirectory
    Root dir containing SOK tactical scripts. Auto-detects from PSScriptRoot.
.PARAMETER MaintenanceMode
    Passed to SOK-Maintenance. Default: Quick (nightly). Use Standard/Deep/Thorough manually.
.PARAMETER Remove
    Unregister all SOK-Daily-* tasks.
.PARAMETER DryRun
    Preview registrations or removals without committing to Task Scheduler.
.NOTES
    Author: S. Clay Caddell
    Version: 2.2.0 — 17Apr2026: resolve schedule-time collisions (Defender 02:17→02:16,
                      Offload 04:51→04:52, LiveScan 04:53→04:54); add §4 confirmation
                      block on -Remove; BackupClaude brought into manifest (14 daily total);
                      #Requires moved to file top.
             2.1.0 — Apr 2026 interim: BackupClaude initial manifest entry (no collision
                      resolution yet; subsumed by 2.2.0 which handles schedule-time
                      collisions and adds the §4 confirmation block). Retained for
                      release-history continuity.
             2.0.0 — add InfraFix, Archiver, Backup; fix Inventory caliber (2 not 3);
                      fix LiveScan flags; add -Deep to MaintenanceMode; 3h exec limit.
    Date: 17Apr2026
    Domain: Utility — registers/removes Task Scheduler entries; not a temporal script itself
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$ScriptDirectory,
    [ValidateSet('Quick','Standard','Deep','Thorough')]
    [string]$MaintenanceMode = 'Quick',
    [switch]$Remove,
    # Cluster-A MEDIUM fix 2026-04-21: scope-down filter for -Remove. Default 'All'
    # preserves historical behavior. Use 'Daily' or 'Weekly' to target a subset if
    # future SOK task classes proliferate.
    [ValidateSet('All','Daily','Weekly')]
    [string]$RemoveScope = 'All'
)

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

if (-not $ScriptDirectory) {
    $ScriptDirectory = if (Test-Path (Join-Path $PSScriptRoot 'SOK-Inventory.ps1')) { $PSScriptRoot }
                       else { 'C:\Users\shelc\Documents\Journal\Projects\scripts' }
}

$pfx  = 'SOK'
# Cluster-A MEDIUM fix 2026-04-21: fail loudly if pwsh missing. Every scheduled
# SOK script has #Requires -Version 7.0, so silent fallback to powershell.exe
# produces tasks that fail at runtime with a confusing error rather than
# refusing to register.
if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    throw "pwsh.exe (PowerShell 7+) is required to register SOK scheduled tasks. All SOK scripts declare '#Requires -Version 7.0'; silent fallback to powershell.exe would yield tasks that fail at runtime. Install PowerShell 7+ and re-run."
}
$pwsh = 'pwsh.exe'

Write-Host "`n━━━ SOK-Scheduler v2.2.0 ━━━" -ForegroundColor Cyan
Write-Host "Dir: $ScriptDirectory | Shell: $pwsh" -ForegroundColor Gray

if ($Remove) {
    # Cluster-A MEDIUM fix 2026-04-21: honor -RemoveScope to narrow the blast radius.
    $scopePattern = switch ($RemoveScope) {
        'Daily'   { "${pfx}-Daily-*" }
        'Weekly'  { "${pfx}-Weekly-*" }
        default   { "${pfx}-*" }
    }
    $tasks = Get-ScheduledTask -TaskName $scopePattern -ErrorAction SilentlyContinue
    if ($DryRun) {
        $tasks | ForEach-Object { Write-Host "  [DRY] Would remove: $($_.TaskName)" -ForegroundColor Yellow }
        Write-Host "DryRun — no tasks unregistered." -ForegroundColor Yellow; exit 0
    }
    # §4 destructive-ops checkpoint: -Remove unregisters all SOK-* tasks en masse.
    # Require explicit typed confirmation to prevent accidental vaporization.
    if ($tasks -and @($tasks).Count -gt 0) {
        $names = @($tasks | ForEach-Object { $_.TaskName })
        Write-Host "`nAbout to unregister $($names.Count) scheduled task(s):" -ForegroundColor Red
        $names | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        Write-Host "`nThis is DESTRUCTIVE and cannot be undone without re-running the scheduler." -ForegroundColor Red
        $ans = Read-Host "Type 'PROCEED' (all caps, no quotes) to continue"
        if ($ans -ne 'PROCEED') { Write-Host "Aborted — no tasks unregistered." -ForegroundColor Yellow; exit 0 }
    } else {
        Write-Host "No SOK-* tasks found to remove." -ForegroundColor Yellow; exit 0
    }
    $tasks | ForEach-Object { Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false; Write-Host "  Removed: $($_.TaskName)" -ForegroundColor Green }
    Write-Host "Done." -ForegroundColor Green; exit 0
}

# ExecutionTimeLimit 3h: SpaceAudit(~81min) + LiveScan(~23min) + Backup(~10min+) need headroom.
#
# Cluster-A MEDIUM note 2026-04-21: SYSTEM principal — implications for tactical scripts
# ══════════════════════════════════════════════════════════════════════════════════════
# Tasks below run as `-User 'SYSTEM'`. SYSTEM has its own $env:USERPROFILE at
# C:\Windows\system32\config\systemprofile — NOT the user's profile. Tactical
# scripts that depend on any of the following WILL MISBEHAVE under SYSTEM:
#
#   - $HOME / $env:USERPROFILE        → resolves to SYSTEM's profile, not user
#   - $env:APPDATA / $env:LOCALAPPDATA → SYSTEM's, not user's
#   - OneDrive env vars               → empty / user-scoped only
#   - User-scope DPAPI secrets (~/.sok-secrets/*.sec) → unreadable by SYSTEM
#   - Per-user Credential Manager (gh auth token) → empty under SYSTEM
#
# Tactical scripts MUST either:
#   (a) use absolute paths anchored at the operator's profile (via Resolve-RealUserProfile
#       in SOK-Common which reads the original user from WMIC / CIM), OR
#   (b) avoid user-scope credentials entirely in scheduled-path execution
#
# If any new tactical reads user-scope state, test it BOTH interactively and via
# `schtasks /run /tn <name>` before declaring it substrate-safe.
#
$sched = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -Priority 4 `
    -ExecutionTimeLimit (New-TimeSpan -Hours 3)

# TASK MANIFEST — 14 tasks, 02:15–05:35, 160% runtime spacing.
# InfraFix FIRST: broken junctions corrupt downstream Inventory/SpaceAudit results.
# Maintenance AFTER Inventory: package updates use Inventory baseline via GlobalState.
# SpaceAudit AFTER Maintenance: sizes reflect post-cleanup state (avoid stale cache counts).
# LiveDigest AFTER LiveScan: depends on its JSON. Min 23min gap enforced by times below.
# Archiver + Backup LAST: daily snapshot preserves final nightly state.
# Inventory: ScanCaliber 2 (not 3). Caliber 3 = SHA-256 hashes = ~90s = use manually only.
# LiveScan: -DirsOnly -ExcludeNoisyDirs shaves ~60% noise and ~900s off runtime.
# Backup: no -Incremental = /E (additive). /MIR never runs unattended — deletes from dest.
$tasks = @(
    [pscustomobject]@{Name='InfraFix';         Script='SOK-InfraFix.ps1';         Args='';                          Time='02:15'}
    [pscustomobject]@{Name='DefenderOptimizer';Script='SOK-DefenderOptimizer.ps1'; Args='';                          Time='02:16'}
    [pscustomobject]@{Name='Inventory';        Script='SOK-Inventory.ps1';         Args='-ScanCaliber 2';            Time='02:17'}
    [pscustomobject]@{Name='Maintenance';      Script='SOK-Maintenance.ps1';       Args="-Mode $MaintenanceMode";    Time='02:19'}
    [pscustomobject]@{Name='SpaceAudit';       Script='SOK-SpaceAudit.ps1';        Args='';                          Time='02:40'}
    [pscustomobject]@{Name='ProcessOptimizer'; Script='SOK-ProcessOptimizer.ps1';  Args='-Mode Balanced';            Time='04:50'}
    [pscustomobject]@{Name='ServiceOptimizer'; Script='SOK-ServiceOptimizer.ps1';  Args='-Action Auto';              Time='04:51'}
    [pscustomobject]@{Name='Offload';          Script='SOK-Offload.ps1';           Args='';                          Time='04:52'}
    [pscustomobject]@{Name='Cleanup';          Script='SOK-Cleanup.ps1';           Args='';                          Time='04:53'}
    [pscustomobject]@{Name='LiveScan';         Script='SOK-LiveScan.ps1';          Args='-DirsOnly -ExcludeNoisyDirs';Time='04:54'}
    [pscustomobject]@{Name='LiveDigest';       Script='SOK-LiveDigest.ps1';        Args='';                          Time='05:18'}
    [pscustomobject]@{Name='Archiver';         Script='SOK-Archiver.ps1';          Args='';                          Time='05:20'}
    [pscustomobject]@{Name='Backup';           Script='SOK-Backup.ps1';            Args='';                          Time='05:22'}
    [pscustomobject]@{Name='BackupClaude';    Script='SOK-BackupClaude.ps1';      Args='';                          Time='05:35'}
)

if ($DryRun) { Write-Host "[DRY RUN] No tasks will be registered." -ForegroundColor Yellow }

$ok = 0; $skip = 0
foreach ($t in $tasks) {
    $path = Join-Path $ScriptDirectory $t.Script
    if (-not (Test-Path $path)) { Write-Host "  SKIP (not found): $($t.Script)" -ForegroundColor Yellow; $skip++; continue }
    $argStr = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$path`""
    if ($t.Args) { $argStr += " $($t.Args)" }
    if ($DryRun) {
        Write-Host "  [DRY] Would register: ${pfx}-Daily-$($t.Name) at $($t.Time)" -ForegroundColor Yellow; $ok++; continue
    }
    Register-ScheduledTask `
        -TaskName  "${pfx}-Daily-$($t.Name)" `
        -Action    (New-ScheduledTaskAction -Execute $pwsh -Argument $argStr) `
        -Trigger   (New-ScheduledTaskTrigger -Daily -At $t.Time) `
        -Settings  $sched `
        -User      'SYSTEM' `
        -RunLevel  Highest `
        -Force | Out-Null
    Write-Host "  [+] ${pfx}-Daily-$($t.Name) at $($t.Time)" -ForegroundColor Green; $ok++
}

# ═══════════════════════════════════════════════════════════════
# WEEKLY TASKS — Python utilities, chunker, etc.
# Run Sunday 01:00 — ahead of the nightly daily suite (02:15+).
# ═══════════════════════════════════════════════════════════════
$py = if (Get-Command 'py' -ErrorAction SilentlyContinue) { 'py.exe' } else { 'python.exe' }
$weeklyTasks = @(
    [pscustomobject]@{
        Name   = 'Vectorize'
        Script = 'SOK-Vectorize.py'
        Args   = '--incremental'
        Day    = 'Sunday'
        Time   = '01:00'
        Exe    = $py
        ExeArgs = '-3.14'
    }
)
$weeklyOk = 0
foreach ($wt in $weeklyTasks) {
    $scriptPath = Join-Path $ScriptDirectory $wt.Script
    if (-not (Test-Path $scriptPath)) {
        Write-Host "  SKIP (not found): $($wt.Script)" -ForegroundColor Yellow; continue
    }
    $argStr = "$($wt.ExeArgs) `"$scriptPath`" $($wt.Args)".Trim()
    if ($DryRun) {
        Write-Host "  [DRY] Would register: ${pfx}-Weekly-$($wt.Name) on $($wt.Day) at $($wt.Time)" -ForegroundColor Yellow
        $weeklyOk++; continue
    }
    Register-ScheduledTask `
        -TaskName  "${pfx}-Weekly-$($wt.Name)" `
        -Action    (New-ScheduledTaskAction -Execute $wt.Exe -Argument $argStr) `
        -Trigger   (New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek $wt.Day -At $wt.Time) `
        -Settings  $sched `
        -User      'SYSTEM' `
        -RunLevel  Highest `
        -Force | Out-Null
    Write-Host "  [+] ${pfx}-Weekly-$($wt.Name) on $($wt.Day) at $($wt.Time)" -ForegroundColor Green
    $weeklyOk++
}

Write-Host "`n━━━ VERIFICATION ($ok daily + $weeklyOk weekly registered | $skip skipped) ━━━" -ForegroundColor Cyan
Get-ScheduledTask -TaskName "${pfx}-*" -ErrorAction SilentlyContinue | ForEach-Object {
    $info = Get-ScheduledTaskInfo -TaskName $_.TaskName -ErrorAction SilentlyContinue
    $next = if ($info?.NextRunTime) { $info.NextRunTime.ToString('yyyy-MM-dd HH:mm') } else { 'N/A' }
    Write-Host "  $($_.TaskName.PadRight(36)) $($_.State.ToString().PadRight(8)) Next: $next" `
        -ForegroundColor $(if ($_.State -eq 'Ready') { 'Green' } else { 'Yellow' })
}
Write-Host "`nSchedule:" -ForegroundColor Yellow
Write-Host "  Weekly (Sun 01:00): Vectorize" -ForegroundColor DarkGray
Write-Host "  Daily  (02:15-05:35, 160% runtime spacing):" -ForegroundColor DarkGray
$tasks | ForEach-Object { Write-Host "    $($_.Time)  $($_.Name)" -ForegroundColor Gray }
Write-Host "    05:35  [complete]" -ForegroundColor DarkGray
