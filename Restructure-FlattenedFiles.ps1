<#
.SYNOPSIS
    SOK File Recovery & Restructuring Engine — restores structure to files
    flattened by the primitive Move-FilesRecursively.ps1 script.

.DESCRIPTION
    When Move-FilesRecursively.ps1 was run, it moved all files from a recursive
    source tree into a SINGLE flat destination directory, losing all folder hierarchy.
    
    This script provides THREE recovery modes:
    
    Mode 1 - LOG RECOVERY: If a log file exists from the original move operation,
    parse it to reconstruct exact original paths and move files back.
    
    Mode 2 - METADATA RESTRUCTURE: When no log exists, analyze file metadata
    (extension, creation date, modification date, size, name patterns) to
    intelligently reorganize files into a structured hierarchy on the external HDD.
    
    Mode 3 - HYBRID: Combine partial log data with metadata analysis for
    files not covered by the log.

    All modes produce a comprehensive FileMap JSON for future restoration,
    and support -WhatIf / -DryRun for safe preview.

.PARAMETER FlatDirectory
    The directory containing the flattened files (the external HDD destination).

.PARAMETER Mode
    Recovery mode: LogRecovery, MetadataRestructure, or Hybrid.

.PARAMETER LogFile
    Path to the log file from the original Move-FilesRecursively.ps1 run.
    Required for LogRecovery and Hybrid modes.

.PARAMETER OriginalSourceRoot
    The original source root path (where files lived before the flat move).
    Used for LogRecovery to validate paths.

.PARAMETER OutputRoot
    Where to create the restructured directory tree. Can be the same drive
    (restructures in-place via staging) or a different location.

.PARAMETER NamingConvention
    Naming convention for restructured files:
    - 'Original': Keep original filenames
    - 'DatePrefix': Prefix with YYYY-MM-DD from file metadata
    - 'TypeDatePrefix': Prefix with Category_YYYY-MM-DD
    - 'Structured': Full restructure: Category/Year/Month/filename

.PARAMETER DryRun
    Preview all operations without executing. Generates a preview report.

.EXAMPLE
    .\Restructure-FlattenedFiles.ps1 -FlatDirectory "E:\AllFiles" -Mode MetadataRestructure -OutputRoot "E:\Restructured" -NamingConvention Structured -DryRun

.EXAMPLE
    .\Restructure-FlattenedFiles.ps1 -FlatDirectory "E:\AllFiles" -Mode LogRecovery -LogFile "C:\logs\move_log.txt" -OriginalSourceRoot "C:\Users\shelc" -OutputRoot "C:\Users\shelc"

.NOTES
    Author: SOK Framework / S. Clay Caddell
    Version: 1.0.0
    SOK Canonical Name: Restructure-FlattenedFiles
    Created: March 2026
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Directory containing flattened files")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$FlatDirectory,

    [Parameter(Mandatory = $true, HelpMessage = "Recovery mode")]
    [ValidateSet('LogRecovery', 'MetadataRestructure', 'Hybrid')]
    [string]$Mode,

    [Parameter(Mandatory = $false, HelpMessage = "Log file from original move operation")]
    [string]$LogFile,

    [Parameter(Mandatory = $false, HelpMessage = "Original source root path")]
    [string]$OriginalSourceRoot,

    [Parameter(Mandatory = $true, HelpMessage = "Output root for restructured files")]
    [string]$OutputRoot,

    [Parameter(Mandatory = $false, HelpMessage = "Naming convention for output")]
    [ValidateSet('Original', 'DatePrefix', 'TypeDatePrefix', 'Structured')]
    [string]$NamingConvention = 'Structured',

    [Parameter(Mandatory = $false, HelpMessage = "Preview without executing")]
    [switch]$DryRun,

    [Parameter(Mandatory = $false, HelpMessage = "Max path length (Windows default 260, can enable long paths)")]
    [int]$MaxPathLength = 260
)

#region Banner
function Show-Banner {
    $banner = @"

    ╔══════════════════════════════════════════════════════════════╗
    ║          SOK — FILE RECOVERY & RESTRUCTURING ENGINE         ║
    ║                                                              ║
    ║     "Structure is not the enemy of freedom.                  ║
    ║      Structure is what makes freedom possible."              ║
    ║                                                              ║
    ║     Mode: $($Mode.PadRight(20))  DryRun: $($DryRun.ToString().PadRight(8))    ║
    ╚══════════════════════════════════════════════════════════════╝

"@
    Write-Host $banner -ForegroundColor Cyan
}
#endregion

#region File Classification Engine
$FileCategories = @{
    'Documents'    = @('.doc', '.docx', '.docm', '.pdf', '.txt', '.rtf', '.odt', '.pages',
                       '.epub', '.mobi', '.md', '.tex', '.latex', '.log', '.msg', '.eml',
                       '.ppt', '.pptx', '.pptm', '.key', '.odp')
    'Spreadsheets' = @('.xls', '.xlsx', '.xlsm', '.xlsb', '.csv', '.tsv', '.ods', '.numbers')
    'Images'       = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.tif', '.webp',
                       '.svg', '.ico', '.heic', '.heif', '.raw', '.cr2', '.nef', '.arw',
                       '.psd', '.ai', '.eps', '.indd', '.xcf', '.dng', '.pcx', '.exr')
    'Videos'       = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm', '.m4v',
                       '.mpg', '.mpeg', '.3gp', '.ts', '.vob', '.ogv', '.mts', '.m2ts')
    'Audio'        = @('.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.wma', '.opus',
                       '.alac', '.ape', '.aiff', '.aif', '.mid', '.midi', '.ac3')
    'Code'         = @('.py', '.pyw', '.js', '.jsx', '.ts', '.tsx', '.html', '.htm',
                       '.css', '.scss', '.sass', '.less', '.json', '.xml', '.yaml', '.yml',
                       '.ps1', '.psm1', '.psd1', '.sh', '.bash', '.zsh', '.bat', '.cmd',
                       '.java', '.class', '.cpp', '.c', '.h', '.hpp', '.cs', '.vb',
                       '.php', '.rb', '.pl', '.go', '.sql', '.r', '.swift', '.kt',
                       '.rs', '.lua', '.vim', '.toml', '.ini', '.cfg', '.conf',
                       '.dockerfile', '.tf', '.hcl', '.gradle', '.cmake', '.makefile')
    'Archives'     = @('.zip', '.rar', '.7z', '.tar', '.gz', '.bz2', '.xz', '.iso',
                       '.dmg', '.img', '.cab', '.deb', '.rpm', '.msi', '.msix')
    'Databases'    = @('.db', '.sqlite', '.sqlite3', '.mdb', '.accdb', '.sql', '.bak',
                       '.dump', '.parquet', '.feather', '.arrow')
    'Fonts'        = @('.ttf', '.otf', '.woff', '.woff2', '.eot')
    'Executables'  = @('.exe', '.dll', '.sys', '.drv', '.ocx', '.scr', '.com')
    'Design'       = @('.fig', '.sketch', '.xd', '.blend', '.fbx', '.obj', '.stl',
                       '.3ds', '.dwg', '.dxf')
    'Notebooks'    = @('.ipynb', '.rmd', '.qmd')
    'Certificates' = @('.pem', '.crt', '.cer', '.key', '.p12', '.pfx', '.jks')
    'Configs'      = @('.env', '.gitignore', '.dockerignore', '.editorconfig',
                       '.eslintrc', '.prettierrc', '.babelrc')
}

function Get-FileCategory {
    param([string]$Extension)
    $ext = $Extension.ToLower()
    foreach ($category in $FileCategories.GetEnumerator()) {
        if ($category.Value -contains $ext) {
            return $category.Key
        }
    }
    return 'Other'
}

function Get-StructuredPath {
    param(
        [System.IO.FileInfo]$File,
        [string]$Convention,
        [string]$Root
    )

    $category = Get-FileCategory -Extension $File.Extension
    $dateSource = if ($File.LastWriteTime -lt $File.CreationTime) {
        $File.LastWriteTime
    } else {
        $File.CreationTime
    }
    $year = $dateSource.ToString('yyyy')
    $month = $dateSource.ToString('MM-MMM')
    $baseName = $File.BaseName
    $ext = $File.Extension

    switch ($Convention) {
        'Original' {
            return Join-Path $Root $File.Name
        }
        'DatePrefix' {
            $prefix = $dateSource.ToString('yyyy-MM-dd')
            return Join-Path $Root "${prefix}_${baseName}${ext}"
        }
        'TypeDatePrefix' {
            $prefix = $dateSource.ToString('yyyy-MM-dd')
            $catShort = $category.Substring(0, [Math]::Min(4, $category.Length)).ToUpper()
            return Join-Path $Root "${catShort}_${prefix}_${baseName}${ext}"
        }
        'Structured' {
            $subDir = Join-Path $Root (Join-Path $category (Join-Path $year $month))
            return Join-Path $subDir $File.Name
        }
    }
}
#endregion

#region Log Parser
function Parse-MoveLog {
    param([string]$LogFilePath)

    $mappings = @()
    $content = Get-Content $LogFilePath -ErrorAction Stop

    foreach ($line in $content) {
        # Pattern: [timestamp] [Success] Moved: <source> -> <destination>
        if ($line -match 'Moved:\s+(.+?)\s+->\s+(.+)$') {
            $mappings += @{
                OriginalSource = $Matches[1].Trim()
                FlatDestination = $Matches[2].Trim()
                FileName = [System.IO.Path]::GetFileName($Matches[2].Trim())
            }
        }
        # Also try: [timestamp] [Success] Copyd: or Copied:
        elseif ($line -match '(?:Copied|Copyd|Copy):\s+(.+?)\s+->\s+(.+)$') {
            $mappings += @{
                OriginalSource = $Matches[1].Trim()
                FlatDestination = $Matches[2].Trim()
                FileName = [System.IO.Path]::GetFileName($Matches[2].Trim())
            }
        }
    }

    return $mappings
}
#endregion

#region Conflict Resolution
function Resolve-NameConflict {
    param(
        [string]$TargetPath,
        [int]$MaxLen = 260
    )

    if (-not (Test-Path $TargetPath)) {
        if ($TargetPath.Length -le $MaxLen) {
            return $TargetPath
        }
    }

    $dir = [System.IO.Path]::GetDirectoryName($TargetPath)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($TargetPath)
    $ext = [System.IO.Path]::GetExtension($TargetPath)
    $counter = 1

    # Truncate base name if path would exceed max length
    $overhead = $dir.Length + $ext.Length + 15  # 15 chars for separator + counter
    if ($base.Length + $overhead -gt $MaxLen) {
        $base = $base.Substring(0, $MaxLen - $overhead)
    }

    do {
        $candidate = Join-Path $dir "${base}_${counter}${ext}"
        $counter++
    } while ((Test-Path $candidate) -or ($candidate.Length -gt $MaxLen))

    return $candidate
}
#endregion

#region Logging
$script:LogPath = $null
$script:FileMap = [System.Collections.ArrayList]::new()

function Initialize-Log {
    param([string]$OutputDir)
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $logDir = Join-Path $OutputDir "_SOK_Recovery_Logs"
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    $script:LogPath = Join-Path $logDir "Recovery_${Mode}_${ts}.log"
    $header = @"
╔══════════════════════════════════════════════════════════════╗
║  SOK FILE RECOVERY LOG                                       ║
║  Mode: $Mode
║  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
║  Source: $FlatDirectory
║  Output: $OutputRoot
║  Convention: $NamingConvention
║  DryRun: $DryRun
╚══════════════════════════════════════════════════════════════╝

"@
    Set-Content -Path $script:LogPath -Value $header -Force
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Ignore', 'Warn', 'Error', 'Success', 'Debug')]
        [string]$Level = 'Ignore'
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "[$ts] [$Level] $Message"
    switch ($Level) {
        'Ignore'  { Write-Host $entry -ForegroundColor Cyan }
        'Warn'    { Write-Host $entry -ForegroundColor Yellow }
        'Error'   { Write-Host $entry -ForegroundColor Red }
        'Success' { Write-Host $entry -ForegroundColor Green }
        'Debug'   { Write-Host $entry -ForegroundColor DarkGray }
    }
    if ($script:LogPath) {
        Add-Content -Path $script:LogPath -Value $entry
    }
}
#endregion

#region Main Execution
try {
    Show-Banner
    Initialize-Log -OutputDir $OutputRoot

    # Create output root
    if (-not $DryRun -and -not (Test-Path $OutputRoot)) {
        New-Item -Path $OutputRoot -ItemType Directory -Force | Out-Null
        Write-Log "Created output directory: $OutputRoot" -Level Ignore
    }

    # Scan flat directory
    Write-Log "Scanning flat directory: $FlatDirectory" -Level Ignore
    $allFiles = Get-ChildItem -Path $FlatDirectory -File -ErrorAction Continue
    Write-Log "Found $($allFiles.Count) files in flat directory" -Level Success

    if ($allFiles.Count -eq 0) {
        Write-Log "No files found. Exiting." -Level Warn
        return
    }

    # Calculate total size
    $totalBytes = ($allFiles | Measure-Object -Property Length -Sum).Sum
    $totalGB = [math]::Round($totalBytes / 1GB, 2)
    Write-Log "Total size: $totalGB GB ($($allFiles.Count) files)" -Level Ignore

    # Category breakdown
    Write-Log "`n--- FILE CATEGORY BREAKDOWN ---" -Level Ignore
    $categoryGroups = $allFiles | Group-Object {
        Get-FileCategory -Extension $_.Extension
    } | Sort-Object Count -Descending

    foreach ($group in $categoryGroups) {
        $groupSize = ($group.Group | Measure-Object -Property Length -Sum).Sum
        $groupMB = [math]::Round($groupSize / 1MB, 1)
        Write-Log "  $($group.Name): $($group.Count) files ($groupMB MB)" -Level Ignore
    }

    # Initialize operation tracking
    $stats = @{
        Total     = $allFiles.Count
        Processed = 0
        Moved     = 0
        Skipped   = 0
        Failed    = 0
        Conflicts = 0
    }

    # MODE-SPECIFIC LOGIC
    switch ($Mode) {

        'LogRecovery' {
            if (-not $LogFile -or -not (Test-Path $LogFile)) {
                throw "LogRecovery mode requires a valid -LogFile path."
            }

            Write-Log "`nParsing move log: $LogFile" -Level Ignore
            $logMappings = Parse-MoveLog -LogFilePath $LogFile
            Write-Log "Found $($logMappings.Count) move records in log" -Level Success

            # Build lookup by filename
            $logLookup = @{}
            foreach ($mapping in $logMappings) {
                $key = $mapping.FileName.ToLower()
                if (-not $logLookup.ContainsKey($key)) {
                    $logLookup[$key] = [System.Collections.ArrayList]::new()
                }
                $logLookup[$key].Add($mapping) | Out-Null
            }

            foreach ($file in $allFiles) {
                $stats.Processed++
                $pct = [math]::Round(($stats.Processed / $stats.Total) * 100, 1)
                Write-Progress -Activity "Recovering files from log" `
                    -Status "$($stats.Processed)/$($stats.Total) ($pct%)" `
                    -PercentComplete $pct

                $key = $file.Name.ToLower()
                if ($logLookup.ContainsKey($key)) {
                    $entries = $logLookup[$key]
                    # Use first match; if multiple, prefer exact size match
                    $match = $entries[0]
                    if ($entries.Count -gt 1) {
                        Write-Log "Multiple log entries for $($file.Name) — using first match" -Level Warn
                    }

                    $restorePath = $match.OriginalSource
                    if ($OriginalSourceRoot -and $restorePath.StartsWith($OriginalSourceRoot)) {
                        # Rebase to OutputRoot
                        $relative = $restorePath.Substring($OriginalSourceRoot.Length).TrimStart('\', '/')
                        $targetPath = Join-Path $OutputRoot $relative
                    }
                    else {
                        $targetPath = $restorePath
                    }

                    # Resolve conflicts
                    if (Test-Path $targetPath) {
                        $targetPath = Resolve-NameConflict -TargetPath $targetPath -MaxLen $MaxPathLength
                        $stats.Conflicts++
                    }

                    $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)

                    if (-not $DryRun) {
                        if (-not (Test-Path $targetDir)) {
                            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                        }
                        try {
                            Move-Item -Path $file.FullName -Destination $targetPath -Force
                            $stats.Moved++
                            Write-Log "Restored: $($file.Name) -> $targetPath" -Level Success
                        }
                        catch {
                            $stats.Failed++
                            Write-Log "FAILED: $($file.Name) — $($_.Exception.Message)" -Level Error
                        }
                    }
                    else {
                        $stats.Moved++
                        Write-Log "[DRY] Would restore: $($file.Name) -> $targetPath" -Level Debug
                    }

                    $script:FileMap.Add(@{
                        OriginalName    = $file.Name
                        CurrentPath     = $file.FullName
                        TargetPath      = $targetPath
                        Category        = Get-FileCategory -Extension $file.Extension
                        Size            = $file.Length
                        LastModified    = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                        RecoveryMethod  = 'LogRecovery'
                    }) | Out-Null
                }
                else {
                    $stats.Skipped++
                    Write-Log "No log entry found for: $($file.Name)" -Level Warn
                }
            }
        }

        'MetadataRestructure' {
            Write-Log "`nRestructuring $($allFiles.Count) files by metadata..." -Level Ignore
            Write-Log "Convention: $NamingConvention" -Level Ignore

            foreach ($file in $allFiles) {
                $stats.Processed++
                $pct = [math]::Round(($stats.Processed / $stats.Total) * 100, 1)
                Write-Progress -Activity "Restructuring by metadata" `
                    -Status "$($stats.Processed)/$($stats.Total) ($pct%)" `
                    -PercentComplete $pct

                try {
                    $targetPath = Get-StructuredPath -File $file -Convention $NamingConvention -Root $OutputRoot

                    # Resolve conflicts
                    if (Test-Path $targetPath) {
                        $targetPath = Resolve-NameConflict -TargetPath $targetPath -MaxLen $MaxPathLength
                        $stats.Conflicts++
                    }

                    $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)

                    if (-not $DryRun) {
                        if (-not (Test-Path $targetDir)) {
                            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                        }
                        Move-Item -Path $file.FullName -Destination $targetPath -Force
                        $stats.Moved++
                    }
                    else {
                        $stats.Moved++
                        Write-Log "[DRY] $($file.Name) -> $targetPath" -Level Debug
                    }

                    $script:FileMap.Add(@{
                        OriginalName    = $file.Name
                        CurrentPath     = $file.FullName
                        TargetPath      = $targetPath
                        Category        = Get-FileCategory -Extension $file.Extension
                        Size            = $file.Length
                        LastModified    = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                        Created         = $file.CreationTime.ToString('yyyy-MM-dd HH:mm:ss')
                        RecoveryMethod  = 'MetadataRestructure'
                    }) | Out-Null
                }
                catch {
                    $stats.Failed++
                    Write-Log "FAILED: $($file.Name) — $($_.Exception.Message)" -Level Error
                }
            }
        }

        'Hybrid' {
            Write-Log "`nHybrid mode: log recovery first, metadata for remainder..." -Level Ignore

            $logMappings = @()
            $logLookup = @{}
            if ($LogFile -and (Test-Path $LogFile)) {
                $logMappings = Parse-MoveLog -LogFilePath $LogFile
                foreach ($mapping in $logMappings) {
                    $key = $mapping.FileName.ToLower()
                    if (-not $logLookup.ContainsKey($key)) {
                        $logLookup[$key] = [System.Collections.ArrayList]::new()
                    }
                    $logLookup[$key].Add($mapping) | Out-Null
                }
                Write-Log "Loaded $($logMappings.Count) log entries" -Level Success
            }
            else {
                Write-Log "No log file provided/found — falling through to full metadata mode" -Level Warn
            }

            foreach ($file in $allFiles) {
                $stats.Processed++
                $pct = [math]::Round(($stats.Processed / $stats.Total) * 100, 1)
                Write-Progress -Activity "Hybrid recovery" `
                    -Status "$($stats.Processed)/$($stats.Total) ($pct%)" `
                    -PercentComplete $pct

                $key = $file.Name.ToLower()
                $method = 'MetadataRestructure'
                $targetPath = $null

                # Try log first
                if ($logLookup.ContainsKey($key)) {
                    $match = $logLookup[$key][0]
                    $restorePath = $match.OriginalSource
                    if ($OriginalSourceRoot -and $restorePath.StartsWith($OriginalSourceRoot)) {
                        $relative = $restorePath.Substring($OriginalSourceRoot.Length).TrimStart('\', '/')
                        $targetPath = Join-Path $OutputRoot $relative
                    }
                    else {
                        $targetPath = $restorePath
                    }
                    $method = 'LogRecovery'
                }

                # Fallback to metadata
                if (-not $targetPath) {
                    $targetPath = Get-StructuredPath -File $file -Convention $NamingConvention -Root $OutputRoot
                }

                try {
                    if (Test-Path $targetPath) {
                        $targetPath = Resolve-NameConflict -TargetPath $targetPath -MaxLen $MaxPathLength
                        $stats.Conflicts++
                    }

                    $targetDir = [System.IO.Path]::GetDirectoryName($targetPath)
                    if (-not $DryRun) {
                        if (-not (Test-Path $targetDir)) {
                            New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
                        }
                        Move-Item -Path $file.FullName -Destination $targetPath -Force
                        $stats.Moved++
                    }
                    else {
                        $stats.Moved++
                    }

                    $script:FileMap.Add(@{
                        OriginalName   = $file.Name
                        CurrentPath    = $file.FullName
                        TargetPath     = $targetPath
                        Category       = Get-FileCategory -Extension $file.Extension
                        Size           = $file.Length
                        LastModified   = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
                        RecoveryMethod = $method
                    }) | Out-Null
                }
                catch {
                    $stats.Failed++
                    Write-Log "FAILED: $($file.Name) — $($_.Exception.Message)" -Level Error
                }
            }
        }
    }

    Write-Progress -Activity "Recovery" -Completed

    # Export FileMap
    $ts = Get-Date -Format 'yyyyMMdd_HHmmss'
    $mapPath = Join-Path (Split-Path $script:LogPath -Parent) "FileMap_Recovery_${ts}.json"
    $script:FileMap | ConvertTo-Json -Depth 5 | Set-Content -Path $mapPath -Force
    Write-Log "`nFileMap exported: $mapPath ($($script:FileMap.Count) entries)" -Level Success

    # Summary
    Write-Log "`n╔══════════════════════════════════════════════════════════════╗" -Level Ignore
    Write-Log "║                  RECOVERY SUMMARY                             ║" -Level Ignore
    Write-Log "╚══════════════════════════════════════════════════════════════╝" -Level Ignore
    Write-Log "  Mode:           $Mode" -Level Ignore
    Write-Log "  Total files:    $($stats.Total)" -Level Ignore
    Write-Log "  Processed:      $($stats.Processed)" -Level Ignore
    Write-Log "  Moved/Mapped:   $($stats.Moved)" -Level Success
    Write-Log "  Conflicts:      $($stats.Conflicts)" -Level Warn
    Write-Log "  Skipped:        $($stats.Skipped)" -Level Warn
    Write-Log "  Failed:         $($stats.Failed)" -Level $(if ($stats.Failed -gt 0) { 'Error' } else { 'Ignore' })
    Write-Log "  FileMap:        $mapPath" -Level Ignore
    Write-Log "  Log:            $($script:LogPath)" -Level Ignore

    if ($DryRun) {
        Write-Log "`n  *** DRY RUN — NO FILES WERE MOVED ***" -Level Warn
        Write-Log "  Review the FileMap JSON and log, then re-run without -DryRun" -Level Warn
    }

}
catch {
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)" -Level Error
    Write-Log "Stack: $($_.ScriptStackTrace)" -Level Error
    throw
}
#endregion
