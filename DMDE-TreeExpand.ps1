<#
.SYNOPSIS
    DMDE-TreeExpand v3 — Expand + capture via UI Automation.
.DESCRIPTION
    Uses Windows UI Automation API to read the currently focused tree item
    after each keystroke. No title parsing, no clipboard — reads the actual
    control text directly from DMDE's tree view.
.NOTES
    Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\DMDE-TreeExpand.ps1
    DMDE must have a volume open. Click the root node before starting.
    Version: 3.0.0 — 22Mar2026
#>
[CmdletBinding()]
param(
    [int]$MaxRows        = 666666,
    [int]$ExpandDepth    = 8,
    [int]$KeyDelayMs     = 10,
    [int]$RowDelayMs     = 12,
    [int]$ProgressEvery  = 100,
    [int]$FlushEvery     = 500,
    [int]$CountdownSec   = 5,
    [int]$MaxDupeStreak  = 300,
    [string]$OutJson     = "$env:USERPROFILE\Documents\SOK\DMDE_TreeMap_$(Get-Date -Format 'yyyyMMdd_HHmmss').json",
    [string]$LogFile     = "$env:USERPROFILE\Documents\SOK\DMDE_TreeExpand_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
)

$ErrorActionPreference = 'Continue'

# ═══════════════════════════════════════════════════
# LOAD UI AUTOMATION
# ═══════════════════════════════════════════════════
try {
    Add-Type -AssemblyName UIAutomationClient -ErrorAction Stop
    Add-Type -AssemblyName UIAutomationTypes -ErrorAction Stop
} catch {
    # PS 7 might need the full name
    try {
        Add-Type -AssemblyName 'UIAutomationClient, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35' -ErrorAction Stop
        Add-Type -AssemblyName 'UIAutomationTypes, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35' -ErrorAction Stop
    } catch {
        Write-Host "ERROR: Cannot load UI Automation assemblies." -ForegroundColor Red
        Write-Host "Try running with: powershell -NoProfile -ExecutionPolicy Bypass -File .\DMDE-TreeExpand.ps1" -ForegroundColor Yellow
        exit 1
    }
}

$wshell = New-Object -ComObject WScript.Shell

# Ensure output dirs
foreach ($f in @($OutJson, $LogFile)) {
    $d = Split-Path $f -Parent
    if (-not (Test-Path $d)) { New-Item -Path $d -ItemType Directory -Force | Out-Null }
}

function Log {
    param([string]$Msg)
    $ts = Get-Date -Format 'HH:mm:ss'
    $line = "[$ts] $Msg"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
}

function Get-FocusedItemName {
    try {
        $focused = [System.Windows.Automation.AutomationElement]::FocusedElement
        if ($focused) {
            $name = $focused.Current.Name
            # Some controls put extra info in other properties
            $controlType = $focused.Current.LocalizedControlType
            return @{ Name = $name; Type = $controlType }
        }
    } catch { }
    return @{ Name = ''; Type = '' }
}

# ═══════════════════════════════════════════════════
# COUNTDOWN
# ═══════════════════════════════════════════════════
Write-Host ""
Write-Host "  DMDE Tree Expander v3 — UI Automation Capture" -ForegroundColor Cyan
Write-Host "  Output: $OutJson" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  1. DMDE must have a volume OPEN (not just scanned)" -ForegroundColor Yellow
Write-Host "  2. Click the ROOT node in DMDE's left tree panel" -ForegroundColor Yellow
Write-Host "  3. Come back to this window and wait for countdown" -ForegroundColor Yellow
Write-Host ""

for ($i = $CountdownSec; $i -gt 0; $i--) {
    Write-Host "  Starting in $i..." -ForegroundColor DarkYellow
    [console]::Beep(666, 222)
    Start-Sleep -Seconds 1
}
[console]::Beep(1200, 300)

# Focus DMDE
$wshell.AppActivate('DMDE') | Out-Null
Start-Sleep -Milliseconds 444

# ═══════════════════════════════════════════════════
# PROBE — verify UI Automation is reading the tree
# ═══════════════════════════════════════════════════
$probe = Get-FocusedItemName
Log "PROBE: Focused element = '$($probe.Name)' (type: $($probe.Type))"

if (-not $probe.Name -or $probe.Name -eq 'DMDE') {
    Log "WARNING: UI Automation returned window name, not tree item."
    Log "Make sure you clicked a tree NODE (folder/file) in DMDE, not the window itself."
    Log "Continuing anyway — the first DOWN key should select a tree item..."
}

# ═══════════════════════════════════════════════════
# DATA STRUCTURES
# ═══════════════════════════════════════════════════
$treeItems = [System.Collections.Generic.List[object]]::new()
$seenNames = [System.Collections.Generic.HashSet[string]]::new()
$allNames  = [System.Collections.Generic.List[string]]::new()  # ordered, with dupes for path reconstruction
$lastName = ''
$duplicateStreak = 0

$expandKeys = '{RIGHT}' * $ExpandDepth

$startTime = Get-Date
Log "START: MaxRows=$MaxRows Depth=$ExpandDepth KeyDelay=${KeyDelayMs}ms RowDelay=${RowDelayMs}ms"
Log "JSON: $OutJson"
Log "Log:  $LogFile"

# ═══════════════════════════════════════════════════
# MAIN LOOP
# ═══════════════════════════════════════════════════
for ($row = 0; $row -lt $MaxRows; $row++) {

    # Expand current node (all depth levels)
    $wshell.SendKeys($expandKeys)
    Start-Sleep -Milliseconds $KeyDelayMs

    # Move to next row
    $wshell.SendKeys('{DOWN}')
    Start-Sleep -Milliseconds $RowDelayMs

    # Read focused element via UI Automation
    $item = Get-FocusedItemName
    $itemName = $item.Name
    $itemType = $item.Type

    # Track in ordered list (every row, even dupes — for structure)
    $allNames.Add($itemName)

    # Dedup tracking
    if ($itemName -and $itemName -ne $lastName) {
        $duplicateStreak = 0

        if ($seenNames.Add($itemName)) {
            $entry = [ordered]@{
                row  = $row
                name = $itemName
                type = $itemType
                time = Get-Date -Format 'HH:mm:ss'
            }
            $treeItems.Add($entry)
        }
    }
    elseif ($itemName -eq $lastName) {
        $duplicateStreak++
        if ($duplicateStreak -ge $MaxDupeStreak) {
            Log "Item unchanged for $MaxDupeStreak rows - reached end of tree"
            break
        }
    }
    else {
        # Empty name — UI Automation lost focus
        $duplicateStreak++
        if ($row % 50 -eq 0) {
            $wshell.AppActivate('DMDE') | Out-Null
            Start-Sleep -Milliseconds 100
        }
    }
    $lastName = $itemName

    # Progress
    if ($row % $ProgressEvery -eq 0 -and $row -gt 0) {
        $elapsed = (Get-Date) - $startTime
        $rowsPerSec = $row / [Math]::Max($elapsed.TotalSeconds, 1)
        $etaHours = ($MaxRows - $row) / $rowsPerSec / 3600
        $elapsedMin = [Math]::Floor($elapsed.TotalMinutes)
        $elapsedSec = $elapsed.Seconds

        if ($row % ($ProgressEvery * 10) -eq 0) {
            $wshell.AppActivate('DMDE') | Out-Null
            Start-Sleep -Milliseconds 50
        }

        Log "Row $($row.ToString('N0')) | $([Math]::Round($rowsPerSec,1))/s | Unique: $($treeItems.Count) | Dupes: $duplicateStreak | ${elapsedMin}m${elapsedSec}s | ETA: $([Math]::Round($etaHours,1))h"
    }

    # Periodic JSON flush
    if ($row % $FlushEvery -eq 0 -and $row -gt 0 -and $treeItems.Count -gt 0) {
        $snapshot = [ordered]@{
            scan_timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            rows_processed = $row
            unique_items   = $treeItems.Count
            items          = $treeItems
        }
        $snapshot | ConvertTo-Json -Depth 4 | Set-Content -Path $OutJson -Encoding UTF8 -Force
    }
}

# ═══════════════════════════════════════════════════
# FINAL OUTPUT
# ═══════════════════════════════════════════════════
$totalTime = (Get-Date) - $startTime
$totalMin = [Math]::Floor($totalTime.TotalMinutes)
$totalSec = $totalTime.Seconds

$stoppedReason = 'unknown'
if ($duplicateStreak -ge $MaxDupeStreak) { $stoppedReason = 'end_of_tree' }
elseif ($row -ge $MaxRows) { $stoppedReason = 'max_rows' }

# Extension breakdown from unique items
$extCounts = @{}
foreach ($item in $treeItems) {
    $n = $item.name
    if ($n -match '\.(\w{1,10})$') {
        $ext = $Matches[1].ToLower()
    } else { $ext = '_folder' }
    if ($extCounts.ContainsKey($ext)) { $extCounts[$ext]++ }
    else { $extCounts[$ext] = 1 }
}
$topExts = $extCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 30

# Build final JSON
$finalOutput = [ordered]@{
    metadata = [ordered]@{
        scan_date       = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        total_rows      = $row
        unique_items    = $treeItems.Count
        unique_names    = $seenNames.Count
        duration        = "${totalMin}m${totalSec}s"
        rows_per_sec    = [Math]::Round($row / [Math]::Max($totalTime.TotalSeconds, 1), 1)
        stopped_reason  = $stoppedReason
        expand_depth    = $ExpandDepth
        key_delay_ms    = $KeyDelayMs
        row_delay_ms    = $RowDelayMs
    }
    extension_summary = $topExts | ForEach-Object {
        [ordered]@{ ext = ".$($_.Key)"; count = $_.Value }
    }
    items = $treeItems
}

$finalOutput | ConvertTo-Json -Depth 5 | Set-Content -Path $OutJson -Encoding UTF8 -Force

# Also save the full ordered traversal (with dupes) for path reconstruction
$traversalPath = $OutJson -replace '\.json$', '_traversal.txt'
$allNames | Set-Content -Path $traversalPath -Encoding UTF8 -Force

Log ""
Log "COMPLETE: $row rows, $($treeItems.Count) unique items in ${totalMin}m${totalSec}s"
Log "JSON: $OutJson ($([Math]::Round((Get-Item $OutJson).Length / 1KB)) KB)"
Log "Traversal: $traversalPath ($([Math]::Round((Get-Item $traversalPath).Length / 1KB)) KB)"
Log ""
Log "Top file types:"
foreach ($e in $topExts) { Log "  .$($e.Key): $($e.Value)" }

# Victory
1..3 | ForEach-Object { [console]::Beep(888, 222); Start-Sleep -Milliseconds 111 }
[console]::Beep(1332, 333)

Write-Host ""
Write-Host "  Done! $($treeItems.Count) unique items captured." -ForegroundColor Green
Write-Host "  JSON:      $OutJson" -ForegroundColor Cyan
Write-Host "  Traversal: $traversalPath" -ForegroundColor Cyan
Write-Host "  Log:       $LogFile" -ForegroundColor DarkGray
Write-Host ""
