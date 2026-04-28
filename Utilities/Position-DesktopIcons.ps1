#Requires -Version 7.0
<#
.SYNOPSIS
  Position Windows Desktop icons at specific grid coordinates via Win32 LVM_SETITEMPOSITION.

.DESCRIPTION
  Finds the SysListView32 behind the Desktop (Progman -> SHELLDLL_DefView -> SysListView32 or
  under a WorkerW fallback on Win10+), enumerates all visible icons by name, and sets their
  positions from a JSON layout spec. Designed for post-2026-04-18 Operating_Stack compliance:
  main-thread reusable tool, DryRun-first, rollback via saved-layout JSON.

.PARAMETER LayoutFile
  Path to JSON mapping icon names to {col, row, zone}. Coordinates computed from CellSize + Origin.

.PARAMETER CellSize
  Grid cell size in pixels. Default 80 matches typical desktop icon spacing.

.PARAMETER OriginX
  Left-edge offset in pixels. Default 10.

.PARAMETER OriginY
  Top-edge offset in pixels. Default 10.

.PARAMETER DryRun
  Enumerate and report intended positions without applying.

.PARAMETER BackupFile
  Path to save the CURRENT icon positions before changes (rollback artifact). Auto-created
  with timestamp if omitted but Backup switch supplied.

.PARAMETER Backup
  Save current positions to a timestamped JSON before applying new positions.

.EXAMPLE
  ./Position-DesktopIcons.ps1 -LayoutFile Desktop_Layout_Default.json -Backup
    Backs up current positions, then applies the default layout.

.EXAMPLE
  ./Position-DesktopIcons.ps1 -LayoutFile Desktop_Layout_Default.json -DryRun
    Shows what would change, applies nothing.

.NOTES
  CLAUDE.md §2 compliance: DryRun-first; Deprecate-never-delete (original layout saved to JSON
  before overwrite). CLAUDE.md §4: icon repositioning is near-reversible — saved layout is the
  rollback artifact.

  Operating_Stack compliance: task class = mechanical; L-01 = medium; L-05 = 1 (main-thread);
  L-06 = bounded (explicit JSON spec); runaway-regime product = ~1.0. Safe.

  Explorer restart invalidates positions. Re-run the script after restart to restore layout.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$LayoutFile,
  [int]$CellSize = 80,
  [int]$OriginX = 10,
  [int]$OriginY = 10,
  [switch]$DryRun,
  [switch]$Backup,
  [string]$BackupFile
)

# ---------- Win32 interop ----------
if (-not ('DesktopIcons' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class DesktopIcons {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll", SetLastError=true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, uint dwProcessId);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool VirtualFreeEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint dwFreeType);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out uint lpNumberOfBytesWritten);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out uint lpNumberOfBytesRead);
    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr hObject);

    public const uint PROCESS_VM_READ = 0x0010;
    public const uint PROCESS_VM_WRITE = 0x0020;
    public const uint PROCESS_VM_OPERATION = 0x0008;
    public const uint PROCESS_QUERY_INFORMATION = 0x0400;
    public const uint MEM_COMMIT = 0x1000;
    public const uint MEM_RESERVE = 0x2000;
    public const uint MEM_RELEASE = 0x8000;
    public const uint PAGE_READWRITE = 0x04;

    public const uint LVM_FIRST = 0x1000;
    public const uint LVM_GETITEMCOUNT = LVM_FIRST + 4;
    public const uint LVM_GETITEMTEXTW = LVM_FIRST + 115;
    public const uint LVM_GETITEMPOSITION = LVM_FIRST + 16;
    public const uint LVM_SETITEMPOSITION = LVM_FIRST + 15;

    public static IntPtr FindDesktopListView() {
        IntPtr progman = FindWindow("Progman", null);
        IntPtr defView = FindWindowEx(progman, IntPtr.Zero, "SHELLDLL_DefView", null);
        if (defView == IntPtr.Zero) {
            IntPtr hwnd = IntPtr.Zero;
            do {
                hwnd = FindWindowEx(IntPtr.Zero, hwnd, "WorkerW", null);
                defView = FindWindowEx(hwnd, IntPtr.Zero, "SHELLDLL_DefView", null);
            } while (hwnd != IntPtr.Zero && defView == IntPtr.Zero);
        }
        return FindWindowEx(defView, IntPtr.Zero, "SysListView32", null);
    }
}
'@
}

function Get-DesktopIconMap {
    [CmdletBinding()]
    param([IntPtr]$ListViewHandle)

    $count = [DesktopIcons]::SendMessage($ListViewHandle, [DesktopIcons]::LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero).ToInt32()
    if ($count -le 0) {
        throw "LVM_GETITEMCOUNT returned $count — is the desktop ListView accessible?"
    }

    # Open Explorer's process for cross-process buffer allocation
    # Note: $pid is a PowerShell automatic variable (current PS PID); use $explorerPid instead
    $explorerPid = 0
    [void][DesktopIcons]::GetWindowThreadProcessId($ListViewHandle, [ref]$explorerPid)
    $access = [DesktopIcons]::PROCESS_VM_READ -bor [DesktopIcons]::PROCESS_VM_WRITE -bor [DesktopIcons]::PROCESS_VM_OPERATION -bor [DesktopIcons]::PROCESS_QUERY_INFORMATION
    $hProc = [DesktopIcons]::OpenProcess($access, $false, $explorerPid)
    if ($hProc -eq [IntPtr]::Zero) { throw "OpenProcess failed on Explorer PID $explorerPid (are you running as admin?)" }

    # Allocate LVITEMW struct (60 bytes on x64) + text buffer (520 bytes = 260 wchars) in remote process
    $bufferSize = 1024
    $remoteBuffer = [DesktopIcons]::VirtualAllocEx($hProc, [IntPtr]::Zero, $bufferSize, [DesktopIcons]::MEM_COMMIT -bor [DesktopIcons]::MEM_RESERVE, [DesktopIcons]::PAGE_READWRITE)
    if ($remoteBuffer -eq [IntPtr]::Zero) { [DesktopIcons]::CloseHandle($hProc) | Out-Null; throw "VirtualAllocEx failed" }

    $map = @{}
    try {
        for ($i = 0; $i -lt $count; $i++) {
            # Build LVITEMW in local buffer: mask=LVIF_TEXT(1), iItem=i, iSubItem=0, pszText=remoteBuffer+60, cchTextMax=260
            $lvitem = New-Object byte[] 60
            [BitConverter]::GetBytes(1).CopyTo($lvitem, 0)         # mask = LVIF_TEXT
            [BitConverter]::GetBytes($i).CopyTo($lvitem, 4)        # iItem
            [BitConverter]::GetBytes(0).CopyTo($lvitem, 8)         # iSubItem
            $textPtr = [IntPtr]::Add($remoteBuffer, 60)
            [BitConverter]::GetBytes($textPtr.ToInt64()).CopyTo($lvitem, 24)   # pszText (x64 offset)
            [BitConverter]::GetBytes(260).CopyTo($lvitem, 32)      # cchTextMax

            $written = 0
            [DesktopIcons]::WriteProcessMemory($hProc, $remoteBuffer, $lvitem, $lvitem.Length, [ref]$written) | Out-Null

            [void][DesktopIcons]::SendMessage($ListViewHandle, [DesktopIcons]::LVM_GETITEMTEXTW, [IntPtr]$i, $remoteBuffer)

            # Read back the text buffer
            $textBytes = New-Object byte[] 520
            $read = 0
            [DesktopIcons]::ReadProcessMemory($hProc, $textPtr, $textBytes, 520, [ref]$read) | Out-Null
            $nameFull = [System.Text.Encoding]::Unicode.GetString($textBytes)
            $nullIdx = $nameFull.IndexOf([char]0)
            if ($nullIdx -ge 0) { $name = $nameFull.Substring(0, $nullIdx) } else { $name = $nameFull }

            # Get current position
            $posBytes = New-Object byte[] 8
            $posPtr = [IntPtr]::Add($remoteBuffer, 600)
            [void][DesktopIcons]::SendMessage($ListViewHandle, [DesktopIcons]::LVM_GETITEMPOSITION, [IntPtr]$i, $posPtr)
            [DesktopIcons]::ReadProcessMemory($hProc, $posPtr, $posBytes, 8, [ref]$read) | Out-Null
            $curX = [BitConverter]::ToInt32($posBytes, 0)
            $curY = [BitConverter]::ToInt32($posBytes, 4)

            if ($name) {
                $map[$name] = @{Index=$i; X=$curX; Y=$curY}
            }
        }
    }
    finally {
        [DesktopIcons]::VirtualFreeEx($hProc, $remoteBuffer, 0, [DesktopIcons]::MEM_RELEASE) | Out-Null
        [DesktopIcons]::CloseHandle($hProc) | Out-Null
    }

    return $map
}

function Set-DesktopIconPosition {
    [CmdletBinding()]
    param([IntPtr]$ListViewHandle, [int]$Index, [int]$X, [int]$Y)
    $lParam = [IntPtr](($Y -shl 16) -bor ($X -band 0xFFFF))
    [void][DesktopIcons]::SendMessage($ListViewHandle, [DesktopIcons]::LVM_SETITEMPOSITION, [IntPtr]$Index, $lParam)
}

# ---------- Main ----------
Write-Host ""
Write-Host "Position-DesktopIcons v1 — Operating_Stack compliant"
Write-Host "===================================================="
Write-Host "Layout file : $LayoutFile"
Write-Host "Cell size   : $CellSize px"
Write-Host "Origin      : ($OriginX, $OriginY)"
Write-Host "DryRun      : $DryRun"
Write-Host "Backup      : $Backup"
Write-Host ""

if (-not (Test-Path $LayoutFile)) { throw "Layout file not found: $LayoutFile" }
$layout = Get-Content $LayoutFile -Raw | ConvertFrom-Json

$lv = [DesktopIcons]::FindDesktopListView()
if ($lv -eq [IntPtr]::Zero) { throw "Could not find desktop SysListView32 — abort." }
Write-Host "Desktop ListView handle: $lv"

Write-Host "Enumerating current icons..."
$iconMap = Get-DesktopIconMap -ListViewHandle $lv
Write-Host "Found $($iconMap.Count) named icons"

# Backup current positions
if ($Backup -or $BackupFile) {
    if (-not $BackupFile) {
        $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
        $BackupFile = Join-Path (Split-Path $LayoutFile -Parent) "Desktop_Layout_Before_$ts.json"
    }
    $backupData = @{}
    foreach ($k in $iconMap.Keys) { $backupData[$k] = @{X=$iconMap[$k].X; Y=$iconMap[$k].Y} }
    $backupData | ConvertTo-Json -Depth 5 | Set-Content $BackupFile -Encoding UTF8
    Write-Host "Backup written: $BackupFile"
}

# Apply layout
# Build a normalized lookup so ".lnk" extension mismatch doesn't cause false-misses.
# Windows ListView strips ".lnk" from display names by default.
$normalizedMap = @{}
foreach ($k in $iconMap.Keys) {
    $normalizedMap[$k] = $iconMap[$k]
    $stripped = $k -replace '\.lnk$',''
    if ($stripped -ne $k -and -not $normalizedMap.ContainsKey($stripped)) {
        $normalizedMap[$stripped] = $iconMap[$k]
    }
    $appended = "$k.lnk"
    if (-not $normalizedMap.ContainsKey($appended)) {
        $normalizedMap[$appended] = $iconMap[$k]
    }
}

$applied = 0; $missing = @(); $skipped = @()
foreach ($prop in $layout.PSObject.Properties) {
    $iconName = $prop.Name
    if ($iconName.StartsWith('_comment')) { continue }   # skip comment keys
    $spec = $prop.Value
    $lookupKey = $null
    if ($normalizedMap.ContainsKey($iconName)) { $lookupKey = $iconName }
    elseif ($normalizedMap.ContainsKey(($iconName -replace '\.lnk$',''))) { $lookupKey = $iconName -replace '\.lnk$','' }
    if (-not $lookupKey) {
        $missing += $iconName
        continue
    }
    $idx = $normalizedMap[$lookupKey].Index
    $x = $OriginX + ([int]$spec.col) * $CellSize
    $y = $OriginY + ([int]$spec.row) * $CellSize

    if ($DryRun) {
        Write-Host ("  [DryRun] {0,-50} -> col={1,-3} row={2,-3} px=({3},{4}) zone={5}" -f $iconName, $spec.col, $spec.row, $x, $y, $spec.zone)
    } else {
        Set-DesktopIconPosition -ListViewHandle $lv -Index $idx -X $x -Y $y
        $applied++
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Applied   : $applied"
Write-Host "Missing   : $($missing.Count) (in layout but not on desktop)"
$missing | ForEach-Object { Write-Host "  - $_" }
Write-Host "Untouched : $($iconMap.Count - $applied - $missing.Count) (on desktop but no layout entry)"
Write-Host ""
if (-not $DryRun -and $applied -gt 0) {
    Write-Host "NOTE: Explorer restart invalidates positions. Re-run this script after restart to restore."
}
