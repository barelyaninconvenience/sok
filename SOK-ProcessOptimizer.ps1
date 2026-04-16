<#
.SYNOPSIS
    SOK-ProcessOptimizer.ps1 — Smart process categorization and resource reclamation.

.DESCRIPTION
    Property-based process categorization (not list-based). Categorizes by:
    Session ID, executable path, window state, CPU usage, memory footprint,
    and company metadata. Config-driven protected process list.

    Modes control aggression — the categorization engine is always the same,
    only the kill decision threshold changes.

.PARAMETER Mode
    Conservative — Telemetry, updaters, crash reporters only
    Balanced     — Conservative + idle background, cloud sync, AppData (default)
    Aggressive   — Everything non-protected

.PARAMETER DryRun
    Preview without terminating.


.NOTES
    Author: S. Clay Caddell
    Version: 1.1.1 (SOK canonical)
    Date: March 2026 (v1.0.0); 2026-04-15 (v1.1.0 post-audit fixes, v1.1.1 auditor-agent fixes)
    Domain: PRESENT — categorizes and reclaims active process resources; mode-driven aggression
    Changelog:
      1.1.1 — Fixes from auditor-agent second-pair-of-eyes review (Agent_Architecture_First_Validation_20260415.md):
              (d) BloatProcess check MOVED to run BEFORE the regex heuristic rules
                  (DevTool, Shell, Security, AudioVideo). Config beats heuristics.
                  Previously a bloat app matching DevTool regex would survive.
              (e) DevTool regex hardened: 'node', 'cmd', 'conhost', 'bash' REMOVED
                  from window-independent protection. Only pwsh/powershell/claude/
                  windowsterminal/code/idea/pycharm/rider/datagrip/postman/dbeaver
                  are protected regardless of window. The removed names were
                  immortalizing every Electron app (Discord/Slack/Teams/etc ship as
                  node.exe children) and every backgrounded cmd.exe shell-out.
              (f) Config reader for BloatProcesses + ProtectedProcesses hardened:
                  force array via @(...), drop nulls, coerce to string. Handles
                  missing key, empty array, or scalar-instead-of-array.
              (g) $DryRun moved to first parameter per CLAUDE.md §2 (mandatory).
      1.1.0 — Post-audit fixes per writings/SOK_ProcessOptimizer_Audit_20260415.md:
              (a) Add BloatProcess category + $config.ProcessOptimizer.BloatProcesses
                  config reader. BloatProcess in Balanced and Aggressive kill tiers.
              (b) Drop $hasWindow requirement on DevTool rule [BUG: too broad in v1.1.0,
                  narrowed in v1.1.1].
              (c) Remove dead v4.3.2 filter.
      1.0.0 — Initial SOK canonical.
#>

[CmdletBinding()]
param(
    # v1.1.1: DryRun moved to first parameter per CLAUDE.md §2 "DryRun is Mandatory".
    [switch]$DryRun,
    [ValidateSet('Conservative', 'Balanced', 'Aggressive')]
    [string]$Mode = 'Balanced'
)

#Requires -Version 7.0
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else { Write-Error "SOK-Common.psm1 not found"; exit 1 }

Show-SOKBanner -ScriptName "ProcessOptimizer ($Mode)"
$logPath = Initialize-SOKLog -ScriptName 'SOK-ProcessOptimizer'
$config = Get-SOKConfig
$startTime = Get-Date

# Self-protection
$myPID = $PID
$myParentPID = try {
    (Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction Stop).ParentProcessId
} catch { 0 }

Write-SOKLog "Self-protected: PID $myPID (Parent: $myParentPID)" -Level Warn
if ($DryRun) { Write-SOKLog '*** DRY RUN — no processes will be terminated ***' -Level Warn }

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-ProcessOptimizer'
}

# Protected process list from config (normalized to lowercase)
# v1.1.1: hardened against missing key, empty array, and scalar-instead-of-array.
$configProtected = @($config.ProcessOptimizer.ProtectedProcesses) |
    Where-Object { $_ } |
    ForEach-Object { $_.ToString().ToLower() }
if ($null -eq $configProtected) { $configProtected = @() }

# ═══════════════════════════════════════════════════════════════
# CATEGORIZATION ENGINE
# ═══════════════════════════════════════════════════════════════

# Kill tiers by mode
# v1.1.0: BloatProcess added to Balanced and Aggressive — catches configured
# consumer apps (chrome, discord, slack, spotify, ms-teams, etc.) that used to
# land in Uncategorized regardless of window state.
$killTiers = @{
    Conservative = @('Telemetry', 'Updater', 'CrashReporter')
    Balanced     = @('Telemetry', 'Updater', 'CrashReporter', 'CloudSync',
                     'AppDataBackground', 'AppDataRoaming', 'HighCPUBackground',
                     'BloatProcess')
    Aggressive   = @('Telemetry', 'Updater', 'CrashReporter', 'CloudSync',
                     'AppDataBackground', 'AppDataRoaming', 'HighCPUBackground',
                     'BloatProcess', 'UserProcess')
}

# v1.1.0: Bloat process list from config (normalized to lowercase)
# v1.1.1: hardened against missing key, empty array, and scalar-instead-of-array.
$configBloat = @($config.ProcessOptimizer.BloatProcesses) |
    Where-Object { $_ } |
    ForEach-Object { $_.ToString().ToLower() }
if ($null -eq $configBloat) { $configBloat = @() }

$activeTier = $killTiers[$Mode]

function Get-ProcessCategory {
    param([System.Diagnostics.Process]$Proc)

    $name = $Proc.ProcessName
    $id = $Proc.Id
    $nameLower = $name.ToLower()

    # Self-protection
    if ($id -eq $myPID -or $id -eq $myParentPID) {
        return @{ Category = 'SelfProtected'; Reason = 'Script execution' }
    }

    # Config-protected
    if ($nameLower -in $configProtected) {
        return @{ Category = 'ConfigProtected'; Reason = "Protected in sok-config.json" }
    }

    # v1.1.1: BloatProcess check moved HERE — config beats heuristics. Previously ran
    # after DevTool/Shell/AudioVideo, meaning a bloat app whose name matched any earlier
    # rule would survive (especially lethal with 'node' in the old DevTool regex).
    if ($nameLower -in $configBloat) {
        return @{ Category = 'BloatProcess'; Reason = "Bloat app (configured): $name" }
    }

    try {
        $cimProc = Get-CimInstance Win32_Process -Filter "ProcessId=$id" -ErrorAction Stop
        $path = $cimProc.ExecutablePath
        $sessionId = $Proc.SessionId
        $company = try { $Proc.Company } catch { '' }
        $hasWindow = try { $Proc.MainWindowHandle -ne 0 } catch { $false }

        # Session 0 core processes
        if ($sessionId -eq 0 -and $nameLower -match '^(system|registry|smss|csrss|wininit|services|lsass|dwm|winlogon|fontdrvhost|logonui|svchost)$') {
            return @{ Category = 'WindowsCore'; Reason = "Session 0 critical: $name" }
        }

        # svchost always protected
        if ($nameLower -eq 'svchost') {
            return @{ Category = 'WindowsService'; Reason = 'svchost' }
        }

        # Security software
        if ($nameLower -match '^(msmpeng|nissrv|securityhealthservice|mpcmdrun)$') {
            return @{ Category = 'Security'; Reason = 'Windows Defender component' }
        }
        if ($company -and $company -match '(?i)symantec|mcafee|kaspersky|bitdefender|malwarebytes') {
            return @{ Category = 'Security'; Reason = "Security vendor: $company" }
        }

        # Audio/Video drivers
        if ($nameLower -match '^(audiodg|wavessyssvc|wavessvc|rtkaudioservice)' -or
            ($company -and $company -match '(?i)realtek|nvidia|amd|intel' -and $nameLower -match 'audio|display|gpu')) {
            return @{ Category = 'AudioVideo'; Reason = 'Hardware driver' }
        }

        # Shell components
        if ($nameLower -match '^(explorer|sihost|shellexperiencehost|startmenuexperiencehost|runtimebroker|textinputhost|searchhost)$') {
            return @{ Category = 'Shell'; Reason = 'Windows shell' }
        }

        # Development tools — NEVER kill (v1.1.1: narrowed)
        # v1.1.0 dropped $hasWindow for ALL dev tool names to protect headless pwsh
        # automation. v1.1.1 narrows the window-independent list: only pwsh/powershell/
        # claude/windowsterminal/code/idea/pycharm/rider/datagrip/postman/dbeaver get
        # unconditional protection. 'node', 'cmd', 'conhost', 'bash' REMOVED — 'node'
        # because Electron apps (Discord/Slack/Teams/etc) ship as node.exe or helpers
        # and were immortalizing every consumer app; 'cmd'/'conhost'/'bash' because
        # incidental shell-outs shouldn't gain dev-tool immortality.
        if ($nameLower -match '(?i)^(code|pwsh|powershell|windowsterminal|claude|idea|pycharm|rider|datagrip|postman|dbeaver)$') {
            return @{ Category = 'DevTool'; Reason = "Dev tool: $name" }
        }

        # === KILLABLE CATEGORIES ===

        # Telemetry
        if ($nameLower -match 'telemetry|diagtrack|census|compattelrunner|diagscap') {
            return @{ Category = 'Telemetry'; Reason = 'Telemetry process' }
        }

        # Third-party updaters
        if ($nameLower -match 'update' -and $company -and $company -notmatch '(?i)microsoft') {
            return @{ Category = 'Updater'; Reason = "Third-party updater: $company" }
        }

        # Crash reporters
        if ($nameLower -match 'crash|reporter|werfault|wermgr') {
            return @{ Category = 'CrashReporter'; Reason = 'Crash reporter' }
        }

        # Cloud sync background (no window)
        if ($path -and $path -match '(?i)\\(OneDrive|Dropbox|Google\s?Drive)\\' -and -not $hasWindow) {
            return @{ Category = 'CloudSync'; Reason = 'Cloud sync (background)' }
        }

        # AppData background processes (no window)
        if ($path -and $path -match '(?i)\\AppData\\Local\\' -and -not $hasWindow -and $sessionId -ne 0) {
            return @{ Category = 'AppDataBackground'; Reason = 'AppData\Local background' }
        }
        if ($path -and $path -match '(?i)\\AppData\\Roaming\\' -and -not $hasWindow -and $sessionId -ne 0) {
            return @{ Category = 'AppDataRoaming'; Reason = 'AppData\Roaming background' }
        }

        # High CPU background
        $cpuTime = try { $Proc.CPU } catch { 0 }
        if ($cpuTime -gt 10 -and -not $hasWindow -and $sessionId -ne 0) {
            return @{ Category = 'HighCPUBackground'; Reason = "CPU: $([math]::Round($cpuTime,1))s, no window" }
        }

        # Generic user process (Aggressive mode catches these)
        if ($sessionId -ne 0 -and -not $hasWindow) {
            return @{ Category = 'UserProcess'; Reason = 'Background user process' }
        }

        return @{ Category = 'Uncategorized'; Reason = 'No matching rule' }
    }
    catch {
        return @{ Category = 'Error'; Reason = "Categorization failed: $($_.Exception.Message)" }
    }
}

# ═══════════════════════════════════════════════════════════════
# ANALYSIS PASS
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'PROCESS ANALYSIS' -Level Section

$toKill = [System.Collections.ArrayList]::new()
$protected = [System.Collections.ArrayList]::new()
$categoryStats = @{}

$allProcs = Get-Process
$i = 0

foreach ($proc in $allProcs) {
    $i++
    if ($i % 50 -eq 0) {
        Write-Progress -Activity 'Categorizing processes' -Status "$i / $($allProcs.Count)" `
            -PercentComplete ([math]::Round(($i / $allProcs.Count) * 100))
    }

    $cat = Get-ProcessCategory -Proc $proc
    $catName = $cat.Category

    if (-not $categoryStats.ContainsKey($catName)) {
        $categoryStats[$catName] = @{ Count = 0; Kill = 0; Protect = 0; MemKB = 0 }
    }
    $categoryStats[$catName].Count++

    $memKB = try { [math]::Round($proc.WorkingSet64 / 1KB, 0) } catch { 0 }
    $categoryStats[$catName].MemKB += $memKB

    $shouldKill = $catName -in $activeTier

    if ($shouldKill) {
        $toKill.Add(@{
            Process  = $proc
            Name     = $proc.ProcessName
            PID      = $proc.Id
            Category = $catName
            Reason   = $cat.Reason
            MemKB    = $memKB
        }) | Out-Null
        $categoryStats[$catName].Kill++
    }
    else {
        $protected.Add($proc.ProcessName) | Out-Null
        $categoryStats[$catName].Protect++
    }
}
Write-Progress -Activity 'Categorizing' -Completed

# Display category breakdown
Write-SOKLog "Category breakdown ($($allProcs.Count) processes):" -Level Ignore
foreach ($cat in $categoryStats.Keys | Sort-Object) {
    $s = $categoryStats[$cat]
    $killLabel = if ($s.Kill -gt 0) { " KILL:$($s.Kill)" } else { '' }
    $protLabel = if ($s.Protect -gt 0) { " KEEP:$($s.Protect)" } else { '' }
    $level = if ($s.Kill -gt 0) { 'Warn' } else { 'Ignore' }
    Write-SOKLog "  $($cat.PadRight(21)) Total:$($s.Count.ToString().PadLeft(5))  Mem:$($s.MemKB.ToString().PadLeft(10)) KB$killLabel$protLabel" -Level $level
}

$totalReclaimKB = ($toKill | Measure-Object -Property MemKB -Sum).Sum
Write-SOKLog "`nTargeted: $($toKill.Count) processes (~$totalReclaimKB KB)" -Level Warn
Write-SOKLog "Protected: $($protected.Count) processes" -Level Success

# v1.1.0: the v4.3.2 "ACTUAL kill exclusion" filter was deleted here. It read
# $config.ProtectedProcesses (top-level) instead of $config.ProcessOptimizer.ProtectedProcesses,
# making $protNames empty — it was a no-op filter. Even with the correct key path,
# it was redundant: categorization at line 95-97 already routes protected processes
# into ConfigProtected, which is never in any kill tier. Dead code, removed.

# ═══════════════════════════════════════════════════════════════
# TERMINATION PASS
# ═══════════════════════════════════════════════════════════════
if ($toKill.Count -eq 0) {
    Write-SOKLog 'No processes targeted for termination.' -Level Success
}
elseif ($DryRun) {
    Write-SOKLog 'TERMINATION TARGETS (DRY RUN)' -Level Section
    $grouped = $toKill | Group-Object -Property Category | Sort-Object Count -Descending
    foreach ($group in $grouped) {
        Write-SOKLog "  [$($group.Name)] — $($group.Count) processes" -Level Warn
        foreach ($item in ($group.Group | Sort-Object MemKB -Descending | Select-Object -First 8)) {
            Write-SOKLog "    $($item.Name) (PID $($item.PID), $($item.MemKB) KB) — $($item.Reason)" -Level Debug
        }
        if ($group.Count -gt 8) {
            Write-SOKLog "    ... and $($group.Count - 8) more" -Level Debug
        }
    }
}
else {
    Write-SOKLog 'TERMINATING' -Level Section
    $killed = 0; $failed = 0

    foreach ($item in $toKill) {
        try {
            Stop-Process -Id $item.PID -Force -ErrorAction Stop
            $killed++
            Write-SOKLog "Terminated: $($item.Name) (PID $($item.PID), $($item.MemKB) KB)" -Level Success
        }
        catch {
            $failed++
            Write-SOKLog "Failed: $($item.Name) — $($_.Exception.Message)" -Level Debug
        }
    }

    Write-SOKLog "`nTerminated: $killed | Failed: $failed" -Level $(if ($failed -gt 0) { 'Warn' } else { 'Success' })
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
Write-SOKSummary -Stats ([ordered]@{
    Mode              = $Mode
    DryRun            = $DryRun.IsPresent
    TotalProcesses    = $allProcs.Count
    Targeted          = $toKill.Count
    EstReclaimKB      = $totalReclaimKB
    Protected         = $protected.Count
    DurationSec       = $duration
}) -Title 'PROCESS OPTIMIZER COMPLETE'

Save-SOKHistory -ScriptName 'SOK-ProcessOptimizer' -RunData @{
    Duration = $duration
    Results  = @{ Mode = $Mode; Targeted = $toKill.Count; Protected = $protected.Count }
}
