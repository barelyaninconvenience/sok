<#
.SYNOPSIS
    SOK-ExtractSignal.ps1 — Extract personal files from E:\Backup_Archive, deduplicate, prepare for compression.
.DESCRIPTION
    Phase 1 of the E:\ restructure. Extracts "signal" files (documents, photos, code, media,
    select executables) from the 31-level-deep nested backup matryoshka on E:\, deduplicates by
    hash, and stages them on C:\ for 7z compression.

    Signal categories:
    - Documents: .docx, .doc, .pdf, .xlsx, .xls, .pptx, .ppt, .txt, .md, .csv
    - Photos: .jpg, .jpeg, .png, .gif, .bmp, .tiff, .heic, .raw, .cr2
    - Media: .mp4, .mov, .avi, .mkv, .mp3, .wav, .flac, .m4a
    - Code: .ps1, .py, .sql, .sh, .bat, .psm1, .psd1, .json, .xml, .yaml, .yml, .html, .htm
    - Archives: .7z, .zip, .rar, .tar, .gz (already compressed — move as-is)
    - Specialty: .psd, .ai, .svg, .msg, .eml, .ost, .pst, .kml, .kmz, .gpx
    - Keep-list EXEs: ArcGIS*, volatility*, (military-pattern matches)

    Noise (excluded): .dll, .exe (except keep-list), .vdi, .vhdx, .esd, .jar, .cab, .bin,
    .partial, .sys, .msi, .msp, .nupkg, .whl, extensionless system files

.PARAMETER SourcePath
    Root path to scan. Default: E:\Backup_Archive

.PARAMETER StagingPath
    Where to stage extracted signal files. Default: C:\Temp_Staging\E_Signal

.PARAMETER DryRun
    Preview extraction plan without copying any files.

.PARAMETER SkipDedup
    Skip hash-based deduplication (faster but may include duplicates).

.NOTES
    Author: S. Clay Caddell
    Date: 2026-04-08 (L-9 style normalization: 2026-04-22 — "Author: Claude + Clay" was the only SOK script not using Clay's canonical attribution; now consistent)
    Domain: Utility — one-shot E:\ restructure preparation
    Runtime: May take 30-60 min on 475 GB with deep nesting
    REQUIRES: Administrator (for accessing all backup paths)
#>
#Requires -Version 7.0
#Requires -RunAsAdministrator
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$SourcePath = 'E:\Backup_Archive',
    [string]$StagingPath = 'C:\Temp_Staging\E_Signal',
    [switch]$SkipDedup
)

$ErrorActionPreference = 'Continue'

# ─── CONFIGURATION ──────────────────────────────────────

$signalExtensions = @(
    # Documents
    '.docx','.doc','.pdf','.xlsx','.xls','.pptx','.ppt','.txt','.md','.csv','.rtf','.odt','.ods',
    # Photos
    '.jpg','.jpeg','.png','.gif','.bmp','.tiff','.tif','.heic','.raw','.cr2','.nef','.arw',
    # Media
    '.mp4','.mov','.avi','.mkv','.mp3','.wav','.flac','.m4a','.aac','.wma','.wmv',
    # Code & Config
    '.ps1','.py','.sql','.sh','.bat','.psm1','.psd1','.json','.xml','.yaml','.yml',
    '.html','.htm','.css','.js','.jsx','.ts','.tsx','.r','.go','.rs','.toml','.cfg','.ini','.conf',
    # Archives — EXCLUDED from staging (already compressed, leave in place on E:\)
    # '.7z','.zip','.rar','.tar','.gz','.bz2',
    # Specialty
    # L-2 (Cluster C) note 2026-04-22: .ost and .pst can reach 20-50 GB each
    # (Outlook data files). Currently staged as Signal; on a deep-nested tree
    # with multiple profiles, Phase 3 could fill C:\Temp_Staging faster than
    # expected. If the E:\ restructure ever hits C:-space pressure, revisit
    # splitting .ost/.pst into a $bulkySignal list with operator confirm gate.
    # Kept inline for now since current backup set is known-small on these exts.
    '.psd','.ai','.svg','.msg','.eml','.ost','.pst','.kml','.kmz','.gpx',
    # GIS
    '.shp','.dbf','.prj','.shx','.gdb','.mxd','.aprx','.lyr','.lyrx','.mpk',
    # Notebooks
    '.ipynb'
)

# EXEs to explicitly KEEP (pattern match)
$keepExePatterns = @(
    'arcgis*', 'volatility*', 'analyst*', 'i2*', 'maltego*',
    'wireshark*', 'nmap*', 'autopsy*', 'ghidra*', 'binwalk*',
    'putty*', 'aida64*', 'cityengine*'
)

# ─── MODULE LOAD ────────────────────────────────────────

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) Write-Host "`n$ScriptName — $Subheader`n" }
}

if (Get-Command Show-SOKBanner -ErrorAction SilentlyContinue) {
    Show-SOKBanner -ScriptName 'SOK-ExtractSignal' -Subheader "$(Get-Date -Format 'yyyy-MM-dd HH:mm')$(if ($DryRun) { ' [DRY RUN]' })"
}
if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'SOK-ExtractSignal'
}
$script:StartTime = Get-Date

# ─── INITIALIZATION ─────────────────────────────────────

$logDir = 'C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\ExtractSignal'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile = Join-Path $logDir "ExtractSignal_${timestamp}.log"

function Log { param([string]$Msg, [string]$Level = 'Annotate')
    # Map friendly levels to SOK-Common ValidateSet: Ignore,Annotate,Warn,Error,Success,Debug,Section
    $sokLevel = switch ($Level) {
        'Info'    { 'Annotate' }
        'Warning' { 'Warn' }
        default   { $Level }
    }
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg"
    Add-Content -Path $logFile -Value $line
    if (Get-Command Write-SOKLog -ErrorAction SilentlyContinue) { Write-SOKLog $Msg -Level $sokLevel }
    else { Write-Host $line }
}

Log "Source: $SourcePath" -Level Section
Log "Staging: $StagingPath"
Log "DryRun: $DryRun"
Log "SkipDedup: $SkipDedup"

if (-not (Test-Path $SourcePath)) {
    Log "SOURCE NOT FOUND: $SourcePath" -Level Error
    exit 1
}

# ─── PHASE 1: SCAN & CLASSIFY ──────────────────────────

Log "PHASE 1: Scanning $SourcePath for signal files..." -Level Section
$signalFiles = [System.Collections.Generic.List[PSObject]]::new()
$noiseCount = 0
$noiseSize = 0
$scanErrors = 0

Get-ChildItem $SourcePath -Recurse -File -Force -ErrorAction SilentlyContinue | ForEach-Object {
    $ext = $_.Extension.ToLower()
    $name = $_.Name.ToLower()
    $isSignal = $false

    # Check signal extensions
    if ($ext -in $signalExtensions) { $isSignal = $true }

    # Check keep-list EXEs
    if ($ext -eq '.exe') {
        foreach ($pattern in $keepExePatterns) {
            if ($name -like $pattern) { $isSignal = $true; break }
        }
    }

    if ($isSignal) {
        $signalFiles.Add([PSCustomObject]@{
            FullName = $_.FullName
            Name     = $_.Name
            Extension = $ext
            Size     = $_.Length
            LastWrite = $_.LastWriteTime
            RelPath  = $_.FullName.Replace($SourcePath, '').TrimStart('\')
        })
    } else {
        $noiseCount++
        $noiseSize += $_.Length
    }
}

$signalSizeGB = [math]::Round(($signalFiles | Measure-Object -Property Size -Sum).Sum / 1GB, 2)
$noiseSizeGB = [math]::Round($noiseSize / 1GB, 2)

Log "Scan complete." -Level Success
Log "  Signal: $($signalFiles.Count) files ($signalSizeGB GB)"
Log "  Noise:  $noiseCount files ($noiseSizeGB GB)"
Log "  Ratio:  $([math]::Round($signalSizeGB / ($signalSizeGB + $noiseSizeGB) * 100, 1))% signal"

# ─── PHASE 2: DEDUPLICATE BY HASH ──────────────────────

if (-not $SkipDedup -and $signalFiles.Count -gt 0) {
    Log "PHASE 2: Deduplicating by SHA256 hash..." -Level Section
    $hashMap = @{}
    $duplicates = [System.Collections.Generic.List[PSObject]]::new()
    $uniqueFiles = [System.Collections.Generic.List[PSObject]]::new()
    $hashProgress = 0

    # H-3 fix 2026-04-21: two-tier triage for large files instead of blanket auto-unique.
    # Prior behavior: files >500MB added directly to uniqueFiles. Camera RAW/MOV backups
    # with identical size would both be staged, double-consuming C:\Temp_Staging and
    # breaking the dedup contract. New: group large files by size first; a same-size
    # group gets forwarded to hash dedup (ensures correctness on the worst-case twin-file
    # scenario). Small (<1KB) files remain auto-unique since hashing them costs more
    # than the dedup they'd yield.
    $hashCandidates = [System.Collections.Generic.List[PSObject]]::new()
    $autoUnique = 0
    $largeFiles = [System.Collections.Generic.List[PSObject]]::new()
    foreach ($f in $signalFiles) {
        if ($f.Size -lt 1KB) {
            $uniqueFiles.Add($f)
            $autoUnique++
        } elseif ($f.Size -gt 500MB) {
            $largeFiles.Add($f)
        } else {
            $hashCandidates.Add($f)
        }
    }
    # Large-file second pass: group by size. Solo sizes skip hashing (auto-unique
    # since no file can dedup against itself). Multi-file sizes forward to hash
    # pool to disambiguate true duplicates from same-size-but-different content.
    $largeGroups = $largeFiles | Group-Object Size
    $largeAutoUnique = 0
    $largeForHash = 0
    foreach ($grp in $largeGroups) {
        if ($grp.Count -eq 1) {
            $uniqueFiles.Add($grp.Group[0])
            $largeAutoUnique++
        } else {
            foreach ($gf in $grp.Group) { $hashCandidates.Add($gf); $largeForHash++ }
        }
    }
    $autoUnique += $largeAutoUnique
    Log "  Size triage: $autoUnique auto-unique (<1KB or solo-size-large) | $largeForHash large-files-forwarded-to-hash (same-size groups) | $($hashCandidates.Count) total to hash"

    # ── Parallel hashing with ForEach-Object -Parallel (PS7+) ──
    $hashThrottle = [Math]::Min(8, [Environment]::ProcessorCount - 2)
    Log "  Hashing $($hashCandidates.Count) files with $hashThrottle parallel threads..."

    $hashResults = $hashCandidates | ForEach-Object -Parallel {
        try {
            $h = (Get-FileHash -Path $_.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
            [PSCustomObject]@{
                FullName  = $_.FullName
                Name      = $_.Name
                Extension = $_.Extension
                Size      = $_.Size
                LastWrite = $_.LastWrite
                RelPath   = $_.RelPath
                Hash      = $h
                Error     = $false
            }
        } catch {
            [PSCustomObject]@{
                FullName  = $_.FullName
                Name      = $_.Name
                Extension = $_.Extension
                Size      = $_.Size
                LastWrite = $_.LastWrite
                RelPath   = $_.RelPath
                Hash      = $null
                Error     = $true
            }
        }
    } -ThrottleLimit $hashThrottle

    # ── Deduplicate from parallel results ──
    $seen = @{}
    $hashErrors = 0
    foreach ($r in $hashResults) {
        if ($r.Error -or -not $r.Hash) {
            $uniqueFiles.Add($r)  # Can't hash → keep
            $hashErrors++
        } elseif ($seen.ContainsKey($r.Hash)) {
            $duplicates.Add($r)
        } else {
            $seen[$r.Hash] = $r.FullName
            $uniqueFiles.Add($r)
        }
    }
    if ($hashErrors -gt 0) { Log "  Hash errors (files kept): $hashErrors" -Level Warn }

    $dupSizeGB = [math]::Round(($duplicates | Measure-Object -Property Size -Sum).Sum / 1GB, 2)
    Log "Dedup complete." -Level Success
    Log "  Unique: $($uniqueFiles.Count) files"
    Log "  Duplicates removed: $($duplicates.Count) files ($dupSizeGB GB saved)"
} else {
    $uniqueFiles = $signalFiles
    Log "PHASE 2: Skipped (SkipDedup=$SkipDedup)" -Level Warn
}

# ─── PHASE 3: STAGE FILES ──────────────────────────────

Log "PHASE 3: Staging $($uniqueFiles.Count) files to $StagingPath..." -Level Section

$staged = 0
$stageErrors = 0
$stageSizeKB = 0

function Get-Category { param([string]$ext)
    switch -Wildcard ($ext) {
        '.doc*' { 'Documents' } '.pdf' { 'Documents' } '.xls*' { 'Documents' } '.ppt*' { 'Documents' }
        '.txt' { 'Documents' } '.md' { 'Documents' } '.csv' { 'Documents' } '.rtf' { 'Documents' }
        '.jpg' { 'Photos' } '.jpeg' { 'Photos' } '.png' { 'Photos' } '.gif' { 'Photos' }
        '.bmp' { 'Photos' } '.tif*' { 'Photos' } '.heic' { 'Photos' } '.raw' { 'Photos' } '.cr2' { 'Photos' }
        '.mp4' { 'Media' } '.mov' { 'Media' } '.avi' { 'Media' } '.mkv' { 'Media' }
        '.mp3' { 'Media' } '.wav' { 'Media' } '.flac' { 'Media' } '.m4a' { 'Media' }
        '.ps1' { 'Code' } '.py' { 'Code' } '.sql' { 'Code' } '.sh' { 'Code' }
        '.json' { 'Code' } '.xml' { 'Code' } '.yaml' { 'Code' } '.yml' { 'Code' }
        '.html' { 'Code' } '.htm' { 'Code' } '.css' { 'Code' } '.js' { 'Code' }
        '.ipynb' { 'Code' } '.r' { 'Code' } '.go' { 'Code' }
        '.7z' { 'Archives' } '.zip' { 'Archives' } '.rar' { 'Archives' } '.tar' { 'Archives' } '.gz' { 'Archives' }
        '.exe' { 'Executables' }
        '.shp' { 'GIS' } '.gdb' { 'GIS' } '.mxd' { 'GIS' } '.aprx' { 'GIS' } '.kml' { 'GIS' }
        '.psd' { 'Design' } '.ai' { 'Design' } '.svg' { 'Design' }
        '.msg' { 'Email' } '.eml' { 'Email' } '.pst' { 'Email' } '.ost' { 'Email' }
        default { 'Other' }
    }
}

foreach ($f in $uniqueFiles) {
    $category = Get-Category $f.Extension
    $destDir = Join-Path $StagingPath $category
    $destFile = Join-Path $destDir $f.Name

    # Handle name collisions
    if (Test-Path $destFile) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        $ext = [System.IO.Path]::GetExtension($f.Name)
        $counter = 1
        do {
            $destFile = Join-Path $destDir "${base}_${counter}${ext}"
            $counter++
        } while (Test-Path $destFile)
    }

    if ($DryRun) {
        $staged++
        $stageSizeKB += [math]::Round($f.Size / 1KB)
    } else {
        try {
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -Path $f.FullName -Destination $destFile -Force
            $staged++
            $stageSizeKB += [math]::Round($f.Size / 1KB)
        } catch {
            $stageErrors++
            Log "  ERROR copying: $($f.FullName) — $_" -Level Warn
        }
    }
}

Log "Staging complete." -Level Success
Log "  Files staged: $staged"
Log "  Size: $([math]::Round($stageSizeKB / 1KB / 1KB, 2)) GB"
Log "  Errors: $stageErrors"

# ─── SUMMARY ────────────────────────────────────────────

Log "" -Level Section
Log "=== EXTRACTION SUMMARY ===" -Level Section
Log "  Source: $SourcePath"
Log "  Total scanned: $($signalFiles.Count + $noiseCount) files"
Log "  Signal: $($signalFiles.Count) files ($signalSizeGB GB)"
Log "  Noise:  $noiseCount files ($noiseSizeGB GB)"
if (-not $SkipDedup) {
    Log "  Duplicates removed: $($duplicates.Count) files ($dupSizeGB GB)"
}
Log "  Files staged: $staged ($([math]::Round($stageSizeKB / 1KB / 1KB, 2)) GB)"
Log "  Staging location: $StagingPath"
Log "  Log: $logFile"
if ($DryRun) {
    Log ""
    Log "  [DRY RUN] No files were copied. Remove -DryRun to execute." -Level Warn
}
Log ""
Log "Next step: Compress staged files with 7z, then clean E:\" -Level Section

# ─── SAVE HISTORY ───────────────────────────────────────

$duration = (Get-Date) - $script:StartTime
$results = @{
    Source        = $SourcePath
    SignalFiles   = $signalFiles.Count
    SignalGB      = $signalSizeGB
    NoiseFiles    = $noiseCount
    NoiseGB       = $noiseSizeGB
    DuplicatesRemoved = if ($duplicates) { $duplicates.Count } else { 0 }
    FilesStaged   = $staged
    StagedGB      = [math]::Round($stageSizeKB / 1KB / 1KB, 2)
    StageErrors   = $stageErrors
    DryRun        = [bool]$DryRun
    Duration      = $duration.ToString('hh\:mm\:ss')
}
if (Get-Command Save-SOKHistory -ErrorAction SilentlyContinue) {
    Save-SOKHistory -ScriptName 'SOK-ExtractSignal' -RunData @{
        Duration = $duration
        Results  = $results
    }
}
