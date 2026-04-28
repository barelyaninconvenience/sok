<#
.SYNOPSIS
    SOK-ServiceOptimizer.ps1 — Database and service resource reclamation.

.DESCRIPTION
    Analyzes running services, their memory footprint, and port activity.
    Provides three action modes:
    - Auto:        Stop services marked STOP in the target list (non-interactive)
    - Interactive:  Prompt for each service
    - Report:      Analysis only, no changes

    Replaces both TITAN-ServiceOptimizer.ps1 and TITAN-TargetedReclamation.ps1.

.PARAMETER Action
    Auto, Interactive, or Report.

.PARAMETER DryRun
    Preview without stopping services.


.NOTES
    Author: S. Clay Caddell
    Version: 1.2.0
    Date: March 2026
    Domain: PRESENT — audits and reconfigures Windows services for dev workstation load profile
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateSet('Auto', 'Interactive', 'Report')]
    [string]$Action = 'Report'
)

#Requires -Version 7.0
#Requires -RunAsAdministrator
$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else { Write-Error "SOK-Common.psm1 not found"; exit 1 }

Show-SOKBanner -ScriptName "ServiceOptimizer ($Action)"
$logPath = Initialize-SOKLog -ScriptName 'SOK-ServiceOptimizer'
$startTime = Get-Date

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-ServiceOptimizer'
}
$procOptLog = if (Get-Command Get-LatestLog -ErrorAction SilentlyContinue) { Get-LatestLog -ScriptName 'SOK-ProcessOptimizer' } else { $null }
if ($procOptLog -and $procOptLog.Age.TotalHours -lt 48) {
    Write-SOKLog "ProcessOptimizer log: $(Format-SOKAge -Age $procOptLog.Age) old -- cross-referencing" -Level Annotate
}
if ($env:SOK_NESTED -eq '1' -and $Action -eq 'Interactive') {
    Write-SOKLog 'Nested execution detected -- forcing Report mode' -Level Warn
    $Action = 'Report'
}

if ($DryRun) { Write-SOKLog '*** DRY RUN ***' -Level Warn }

# H-6 fix 2026-04-21: database write-ahead-log corruption protection.
# Database services (Neo4j, MongoDB, MySQL, PostgreSQL, Redis/Memurai, InfluxDB)
# use WAL that is flushed on graceful stop but not on process kill. Immediate
# Stop-Process after Stop-Service (before SCM finishes draining the process)
# is a corruption surface. These process names are matched case-insensitively
# against target ProcessName and are never force-killed after Stop-Service;
# they get only the service-stop + graceful-drain-poll path.
$script:DatabaseProcessNames = @(
    'prunsrv-amd64',   # Neo4j (Apache Commons Daemon wrapper)
    'mongod',          # MongoDB
    'mysqld',          # MySQL
    'postgres',        # PostgreSQL
    'memurai',         # Redis-compat on Windows
    'redis-server',    # Redis native
    'influxd'          # InfluxDB
)

# Graceful-stop helper: stop service + poll for Stopped + optionally (non-DB)
# reap orphan process. Returns $true on clean stop.
function Stop-ServiceGracefully {
    param(
        [Parameter(Mandatory)][string]$ServiceName,
        [string]$ProcessName,
        [int]$PollTimeoutSec = 5
    )
    try {
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
    } catch {
        Write-SOKLog "  Stop-Service failed for $ServiceName : $($_.Exception.Message)" -Level Error
        return $false
    }
    # Poll until Status -eq Stopped (or timeout)
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $PollTimeoutSec) {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($null -eq $svc -or $svc.Status -eq 'Stopped') { break }
        Start-Sleep -Milliseconds 200
    }
    $sw.Stop()
    # Non-DB only: reap orphan process if still running after service stop
    $isDb = $ProcessName -and ($ProcessName.ToLower() -in ($script:DatabaseProcessNames | ForEach-Object { $_.ToLower() }))
    if ($ProcessName -and -not $isDb) {
        Stop-Process -Name $ProcessName -Force -ErrorAction Continue
    }
    if ($isDb -and $ProcessName) {
        $stillRunning = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($stillRunning) {
            Write-SOKLog "  Note: $ProcessName still running after service stop — NOT force-killing (DB; WAL corruption risk). SCM drain may still be in progress." -Level Warn
        }
    }
    return $true
}

# ═══════════════════════════════════════════════════════════════
# SERVICE TARGET DEFINITIONS
# ═══════════════════════════════════════════════════════════════
# Recommendation: STOP = always safe to stop, CONDITIONAL = depends on use
$targets = @(
    @{ Name='Neo4j';            ServiceName='neo4j';                 ProcessName='prunsrv-amd64';    Port=7474;  Rec='STOP';        Reason='800+ MB, rarely used interactively' }
    @{ Name='MongoDB';          ServiceName='MongoDB';               ProcessName='mongod';           Port=27017; Rec='CONDITIONAL'; Reason='Stop if no apps connect' }
    @{ Name='MySQL';            ServiceName='MySQL';                 ProcessName='mysqld';           Port=3306;  Rec='CONDITIONAL'; Reason='Stop if no active databases' }
    @{ Name='PostgreSQL';       ServiceName='postgresql-x64-15';     ProcessName='postgres';         Port=5432;  Rec='CONDITIONAL'; Reason='Stop if no active databases' }
    @{ Name='Redis/Memurai';    ServiceName='Memurai';               ProcessName='memurai';          Port=6379;  Rec='CONDITIONAL'; Reason='Stop if no caching needed' }
    @{ Name='Waves Audio';      ServiceName='WavesSysSvc64';         ProcessName='WavesSysSvc64';    Port=0;     Rec='STOP';        Reason='500+ MB audio enhancement bloat' }
    @{ Name='Waves Audio 2';    ServiceName='WavesSvc64';            ProcessName='WavesSvc64';       Port=0;     Rec='STOP';        Reason='Secondary Waves service' }
    @{ Name='ZeroTier';         ServiceName='ZeroTierOneService';    ProcessName='zerotier-one_x64'; Port=9993;  Rec='CONDITIONAL'; Reason='Redundant with Tailscale?' }
    @{ Name='TeamViewer';       ServiceName='TeamViewer';            ProcessName='TeamViewer_Service';Port=5938;  Rec='CONDITIONAL'; Reason='Redundant with RDP/Tailscale?' }
    @{ Name='Adobe ARM';        ServiceName='AdobeARMservice';       ProcessName='armsvc';           Port=0;     Rec='STOP';        Reason='Manual updates are fine' }
    @{ Name='Jenkins';          ServiceName='jenkins';               ProcessName='jenkins';          Port=8080;  Rec='CONDITIONAL'; Reason='Stop if not doing CI/CD' }
    @{ Name='Nginx';            ServiceName='nginx';                 ProcessName='nginx';            Port=80;    Rec='CONDITIONAL'; Reason='Stop if not running web dev' }
    @{ Name='Puppet';           ServiceName='puppet';                ProcessName='ruby';             Port=0;     Rec='CONDITIONAL'; Reason='Stop if not managing infra' }
)

# ═══════════════════════════════════════════════════════════════
# ANALYSIS
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'SERVICE ANALYSIS' -Level Section

$analysisResults = [System.Collections.ArrayList]::new()
$totalMemMB = 0

foreach ($tgt in $targets) {
    $proc = Get-Process -Name $tgt.ProcessName -ErrorAction SilentlyContinue
    $svc = Get-Service -Name $tgt.ServiceName -ErrorAction SilentlyContinue

    $memMB = 0
    $isRunning = $false

    if ($proc) {
        $memMB = [math]::Round(($proc | Measure-Object -Property WorkingSet -Sum).Sum / 1MB, 0)
        $isRunning = $true
    }

    $portActive = $false
    if ($tgt.Port -gt 0) {
        $portActive = try {
            $null = Get-NetTCPConnection -LocalPort $tgt.Port -State Listen -ErrorAction Stop
            $true
        } catch { $false }
    }

    $analysisResults.Add([ordered]@{
        Name        = $tgt.Name
        ServiceName = $tgt.ServiceName
        ProcessName = $tgt.ProcessName
        Running     = $isRunning
        MemMB       = $memMB
        Port        = $tgt.Port
        PortActive  = $portActive
        Rec         = $tgt.Rec
        Reason      = $tgt.Reason
    }) | Out-Null

    if ($isRunning) { $totalMemMB += $memMB }
}

# Display
$running = $analysisResults | Where-Object { $_.Running }
$stopped = $analysisResults | Where-Object { -not $_.Running }

Write-SOKLog "Running services ($($running.Count)):" -Level Ignore
foreach ($r in ($running | Sort-Object MemMB -Descending)) {
    $recColor = if ($r.Rec -eq 'STOP') { 'Warn' } else { 'Ignore' }
    $portStr = if ($r.Port -gt 0) {
        if ($r.PortActive) { " | Port $($r.Port): ACTIVE" } else { " | Port $($r.Port): idle" }
    } else { '' }
    Write-SOKLog "  [$($r.Rec.PadRight(11))] $($r.Name.PadRight(20)) $($r.MemMB.ToString().PadLeft(6)) MB$portStr — $($r.Reason)" -Level $recColor
}

Write-SOKLog "`nAlready stopped: $($stopped.Count) services" -Level Debug
Write-SOKLog "Total memory in targetable services: $totalMemMB MB" -Level Ignore

# ═══════════════════════════════════════════════════════════════
# ACTION
# ═══════════════════════════════════════════════════════════════
$stoppedCount = 0; $freedMB = 0

if ($Action -eq 'Report') {
    Write-SOKLog "`nReport mode — no changes made. Use -Action Auto or Interactive to optimize." -Level Ignore
}
elseif ($Action -eq 'Auto') {
    Write-SOKLog 'AUTO-STOP (STOP-recommended services only)' -Level Section
    $autoTargets = $running | Where-Object { $_.Rec -eq 'STOP' }

    foreach ($tgt in $autoTargets) {
        if ($DryRun) {
            Write-SOKLog "[DRY] Would stop: $($tgt.Name) (~$($tgt.MemMB) MB)" -Level Debug
            $stoppedCount++; $freedMB += $tgt.MemMB
            continue
        }
        try {
            # H-6 fix 2026-04-21: graceful stop with DB-protection (no force-kill of DB processes)
            $ok = Stop-ServiceGracefully -ServiceName $tgt.ServiceName -ProcessName $tgt.ProcessName -PollTimeoutSec 5
            if ($ok) {
                Set-Service -Name $tgt.ServiceName -StartupType Manual -ErrorAction Continue
                Write-SOKLog "Stopped: $($tgt.Name) (~$($tgt.MemMB) MB freed, set to Manual)" -Level Success
                $stoppedCount++; $freedMB += $tgt.MemMB
            } else {
                Write-SOKLog "Stop-Service failed for $($tgt.Name) — skipping startup-type change" -Level Error
            }
        }
        catch {
            Write-SOKLog "Failed to stop $($tgt.Name): $($_.Exception.Message)" -Level Error
        }
    }
}
elseif ($Action -eq 'Interactive') {
    Write-SOKLog 'INTERACTIVE MODE' -Level Section
    foreach ($tgt in $running) {
        $prompt = "$($tgt.Name) ($($tgt.MemMB) MB, $($tgt.Rec)) — Stop? [y/N]"
        Write-Host "  $prompt " -NoNewline -ForegroundColor Yellow
        $response = Read-Host

        if ($response -eq 'y' -or $response -eq 'Y') {
            if ($DryRun) {
                Write-SOKLog "[DRY] Would stop $($tgt.Name)" -Level Debug
            }
            else {
                try {
                    # H-6 fix 2026-04-21: graceful stop with DB-protection
                    $ok = Stop-ServiceGracefully -ServiceName $tgt.ServiceName -ProcessName $tgt.ProcessName -PollTimeoutSec 5
                    if ($ok) {
                        Set-Service -Name $tgt.ServiceName -StartupType Manual -ErrorAction Continue
                        Write-SOKLog "  Stopped: $($tgt.Name)" -Level Success
                    } else {
                        Write-SOKLog "  Failed to stop $($tgt.Name)" -Level Error
                    }
                }
                catch { Write-SOKLog "  Failed: $_" -Level Error }
            }
            $stoppedCount++; $freedMB += $tgt.MemMB
        }
        else {
            Write-SOKLog "  Skipped: $($tgt.Name)" -Level Debug
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
Write-SOKSummary -Stats ([ordered]@{
    Action          = $Action
    ServicesStopped = $stoppedCount
    MemoryFreedMB   = $freedMB
    DryRun          = $DryRun.IsPresent
    DurationSec     = $duration
}) -Title 'SERVICE OPTIMIZER COMPLETE'

Write-SOKLog "`nTo restart a service: Start-Service <Name>; Set-Service <Name> -StartupType Automatic" -Level Ignore

Save-SOKHistory -ScriptName 'SOK-ServiceOptimizer' -RunData @{
    Duration = $duration; Results = @{ Stopped = $stoppedCount; FreedMB = $freedMB }
}
