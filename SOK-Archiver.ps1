<#
.SYNOPSIS
    SOK-Archiver.ps1 — High-performance file merger for archive snapshots.
    (Formerly: TITAN DIRECT BUFFER STREAM)

.DESCRIPTION
    Scans source directories, builds a manifest in memory (preventing infinite
    recursion), then streams all matching files into a single versioned archive
    using 1MB buffered StreamWriter for maximal I/O throughput.

    Preserves: table of contents, file metadata, full content, error audit trail.

.PARAMETER SourceFolders
    Array of directories to archive. Defaults to SOK project directories.

.PARAMETER BaseName
    Base filename for the archive. Auto-versioned (_v1, _v2, etc).

.PARAMETER OutputDir
    Where to write the archive file.

.PARAMETER Extensions
    Regex pattern for file extensions to include.

.PARAMETER DryRun
    Scan and report without writing the archive.

.NOTES
    Author: S. Clay Caddell
    Version: 2.1.0 (SOK canonical — formerly TITAN Archiver)
    Date: 18Mar2026
    Domain: FUTURE — captures versioned source snapshot before Backup mirrors; runs second-to-last

    Engineering principles (preserved from TITAN):
    1. PRE-SCAN MANIFEST: Prevents reading the output file during write.
    2. DIRECT STREAMING: StreamWriter bypasses PowerShell object wrapping.
    3. 1MB BUFFER: Reduces disk I/O ops by ~250x vs default 4KB buffer.
    4. LINE-BY-LINE READING: Flat memory usage regardless of file size.
#>

#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [string[]]$SourceFolders = @(
        "$env:USERPROFILE\Documents\Journal\Projects\SOK",
        "$env:USERPROFILE\Documents\Journal\Projects\scripts"
    ),

    [string]$BaseName = 'SOK_Archive',

    [string]$OutputDir = "$env:USERPROFILE\Documents\Journal\Projects\SOK\Logs\Archives",

    [string]$Extensions = '(?i)\.(txt|md|ps1|psm1|psd1|py|json|log|yaml|yml|xml|conf|ini|sh|bat|css|js|jsx|ts|tsx|sql|toml|cfg|r|go|rs)$',

    [switch]$DryRun
)

# ── SYSTEM-CONTEXT PATH RESOLUTION ──
# When running as SYSTEM (scheduled tasks), $env:USERPROFILE resolves to
# C:\Windows\System32\config\systemprofile — remap to actual user profile
if ($env:USERPROFILE -like '*systemprofile*') {
    $actualProfile = 'C:\Users\shelc'
    $SourceFolders = $SourceFolders | ForEach-Object { $_ -replace [regex]::Escape($env:USERPROFILE), $actualProfile }
    $OutputDir = $OutputDir -replace [regex]::Escape($env:USERPROFILE), $actualProfile
    Write-Host "[SYSTEM-CONTEXT] Remapped paths from $env:USERPROFILE to $actualProfile"
}

# Import SOK-Common
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) }
    function Initialize-SOKLog { param([string]$ScriptName) return $null }
}

Show-SOKBanner -ScriptName 'SOK-Archiver' -Subheader "Sources: $($SourceFolders.Count) | Base: $BaseName"
$logPath = Initialize-SOKLog -ScriptName 'SOK-Archiver'

if ($DryRun) { Write-SOKLog '*** DRY RUN — no archive will be written ***' -Level Warn }

if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-Archiver'
}

# ── ENSURE OUTPUT DIR ──
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-SOKLog "Created output directory: $OutputDir" -Level Ignore
}

# ── INTELLIGENT VERSIONING ──
$version = 1
while (Test-Path "$OutputDir\$($BaseName)_v$version.txt") { $version++ }
$targetFile = "$OutputDir\$($BaseName)_v$version.txt"
Write-SOKLog "Target: $targetFile (v$version)" -Level Ignore

# ── MANIFEST GENERATION ──
Write-SOKLog 'MANIFEST SCAN' -Level Section

$manifest = @()
$folderCount = 0

foreach ($folder in $SourceFolders) {
    $folderCount++
    if (Test-Path $folder) {
        Write-Progress -Activity "SOK Archiver" -Status "Scanning: $folder" -PercentComplete (($folderCount / $SourceFolders.Count) * 100)
        try {
            $found = Get-ChildItem -Path $folder -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -match $Extensions }
            $manifest += $found
            Write-SOKLog "  $folder — $($found.Count) files" -Level Ignore
        }
        catch {
            Write-SOKLog "  Access error at $folder — $($_.Exception.Message)" -Level Warn
        }
    }
    else {
        Write-SOKLog "  $folder — NOT FOUND (skipped)" -Level Warn
    }
}
Write-Progress -Activity "SOK Archiver" -Completed

# Exclude previous archives and sort deterministically
$manifest = $manifest | Where-Object { $_.Name -notmatch $BaseName } | Sort-Object FullName

$totalSizeKB = [math]::Round(($manifest | Measure-Object -Property Length -Sum).Sum / 1KB, 2)
Write-SOKLog "Manifest: $($manifest.Count) files, $totalSizeKB KB" -Level Success

if ($manifest.Count -eq 0) {
    Write-SOKLog 'No matching files found. Aborting.' -Level Error
    exit
}

if ($DryRun) {
    Write-SOKLog "`nDRY RUN — would archive $($manifest.Count) files ($totalSizeKB KB) to $targetFile" -Level Warn
    foreach ($item in $manifest | Select-Object -First 20) {
        Write-SOKLog "  $($item.FullName) ($("$([math]::Round($item.Length / 1KB, 2)) KB"))" -Level Debug
    }
    if ($manifest.Count -gt 20) { Write-SOKLog "  ... +$($manifest.Count - 20) more" -Level Debug }
    exit
}

# ── STREAM EXECUTION ──
Write-SOKLog 'ARCHIVING' -Level Section

$utf8 = [System.Text.Encoding]::UTF8
$bufferSize = 1048576  # 1MB
$stream = [System.IO.FileStream]::new($targetFile, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read, $bufferSize)
$writer = [System.IO.StreamWriter]::new($stream, $utf8)
$errors = 0

try {
    # Header + TOC
    $writer.WriteLine("# " + ("=" * 111))
    $writer.WriteLine("# SOK ARCHIVE SNAPSHOT: v$version")
    $writer.WriteLine("# DATE: $(Get-Date -Format 'ddMMMyyyy HH:mm:ss')")
    $writer.WriteLine("# TOTAL FILES: $($manifest.Count)")
    $writer.WriteLine("# TOTAL SIZE: $totalSizeKB KB")
    $writer.WriteLine("# SOURCES: $($SourceFolders -join ' | ')")
    $writer.WriteLine("# " + ("=" * 111))

    $tocFormat = "# {0,-50} | {1,12} | {2,20} | {3}"
    $writer.WriteLine(($tocFormat -f "FILE NAME", "SIZE", "MODIFIED", "ATTRIBUTES"))
    $writer.WriteLine("# " + ("-" * 111))

    foreach ($item in $manifest) {
        $name = if ($item.Name.Length -gt 48) { $item.Name.Substring(0, 44) + "..." } else { $item.Name }
        $size = "$([math]::Round($item.Length / 1KB, 2)) KB"
        $mod = $item.LastWriteTime.ToString("ddMMMyyyy HH:mm")
        $writer.WriteLine(($tocFormat -f $name, $size, $mod, $item.Attributes))
    }
    $writer.WriteLine("# " + ("=" * 111) + "`n")

    # Content
    $i = 0
    foreach ($file in $manifest) {
        $i++
        $pct = [math]::Round(($i / $manifest.Count) * 100)
        Write-Progress -Activity "Archiving" -Status "$($file.Name)" -PercentComplete $pct -CurrentOperation "$i of $($manifest.Count)"

        $writer.WriteLine("`n# " + ("-" * 111))
        $writer.WriteLine("# FILE: $($file.FullName)")
        $writer.WriteLine("# SIZE: $("$([math]::Round($file.Length / 1KB, 2)) KB") | MODIFIED: $($file.LastWriteTime.ToString('ddMMMyyyy HH:mm:ss'))")
        $writer.WriteLine("# " + ("-" * 111))

        $reader = $null
        try {
            $reader = [System.IO.StreamReader]::new($file.FullName)
            while (($line = $reader.ReadLine()) -ne $null) {
                $writer.WriteLine($line)
            }
        }
        catch {
            $writer.WriteLine("# !!! READ ERROR: $($_.Exception.Message) !!!")
            $writer.WriteLine("# !!! STATUS: Content Skipped !!!")
            $errors++
            Write-SOKLog "Read error: $($file.Name) — $($_.Exception.Message)" -Level Error
        }
        finally {
            if ($reader) { $reader.Dispose(); $reader = $null }
        }
    }
}
finally {
    Write-Progress -Activity "Archiving" -Completed
    if ($writer) { $writer.Flush(); $writer.Dispose() }
    if ($stream) { $stream.Dispose() }
    [System.GC]::Collect()
}

$archiveSize = "$([math]::Round((Get-Item $targetFile).Length / 1KB, 2)) KB"
Write-SOKLog "Archive written: $targetFile ($archiveSize)" -Level Success
Write-SOKLog "Files: $($manifest.Count) | Errors: $errors" -Level $(if ($errors -gt 0) { 'Warn' } else { 'Success' })
