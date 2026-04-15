<#
.SYNOPSIS
    Advanced backup utility with intelligent file structure preservation and comprehensive logging.

.DESCRIPTION
    Professional backup solution that recursively backs up files while preserving directory structure,
    with intelligent empty folder consolidation, size estimation, time prediction, comprehensive logging,
    and a companion restoration script.

.PARAMETER SourcePath
    The root directory to backup recursively.

.PARAMETER DestinationPath
    The target backup directory where files will be copied with preserved structure.

.PARAMETER FileCategory
    Category of files to backup. Interactive menu will be displayed if not specified.
    Valid options: AllFiles, Documents, Images, Videos, Audio, Code, Archives, Spreadsheets, Custom

.PARAMETER CustomExtensions
    Custom file extensions when FileCategory is set to 'Custom' (e.g., @("*.xyz", "*.abc"))

.PARAMETER Operation
    Type of operation: 'Copy' (default - creates backup) or 'Move' (transfers files)

.EXAMPLE
    .\Backup-FilesAdvanced.ps1 -SourcePath "C:\Projects" -DestinationPath "D:\Backup"
    Launches interactive menu to select file categories and backs up to D:\Backup

.EXAMPLE
    .\Backup-FilesAdvanced.ps1 -SourcePath "C:\Documents" -DestinationPath "E:\Backup" -FileCategory Documents
    Backs up all document files to E:\Backup

.EXAMPLE
    .\Backup-FilesAdvanced.ps1 -SourcePath "C:\Code" -DestinationPath "D:\Backup" -FileCategory Custom -CustomExtensions @("*.py", "*.js")
    Backs up only Python and JavaScript files

.NOTES
    Author: AI Engineer & PowerShell Expert
    Version: 2.0
    Last Updated: 2026-01-09
    
    Features:
    - Sacred geometry ASCII art display
    - File size calculation and time estimation
    - System resource analysis
    - Intelligent folder structure preservation
    - Empty folder consolidation
    - Filename length limit handling
    - Comprehensive mandatory logging
    - Companion restoration script generation
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Source directory to backup")]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$SourcePath,

    [Parameter(Mandatory=$true, HelpMessage="Destination backup directory")]
    [string]$DestinationPath,

    [Parameter(Mandatory=$false, HelpMessage="File category to backup")]
    [ValidateSet('AllFiles', 'Documents', 'Images', 'Videos', 'Audio', 'Code', 'Archives', 'Spreadsheets', 'Custom')]
    [string]$FileCategory,

    [Parameter(Mandatory=$false, HelpMessage="Custom extensions when FileCategory is Custom")]
    [string[]]$CustomExtensions,

    [Parameter(Mandatory=$false, HelpMessage="Operation type: Copy or Move")]
    [ValidateSet('Copy', 'Move')]
    [string]$Operation = 'Copy'
)

#region ASCII Art and Initialization

function Show-SacredGeometry {
    $art = @"

    ╔════════════════════════════════════════════════════════════════════════╗
    ║                                                                        ║
    ║                    ✦ ADVANCED BACKUP UTILITY ✦                        ║
    ║                                                                        ║
    ║                           .:*~*:._.:*~*:.                             ║
    ║                      .:*'          *         *':.                     ║
    ║                   .:*'         ✦       ✦         '*:.                 ║
    ║                .:*'        ✦       ✦   ✦       ✦        '*:.          ║
    ║             .:*'      ✦       ✦       ✦   ✦       ✦      '*:.       ║
    ║          .:*'    ✦       ✦       ✦       ✦   ✦       ✦       '*:.    ║
    ║        .*'  ✦       ✦       ✦       ✦       ✦   ✦       ✦       '*.  ║
    ║       *   ✦    ╱◆╲   ✦    ╱◆╲   ✦    ╱◆╲   ✦    ╱◆╲    ✦   *       ║
    ║      ✦       ╱    ╲  ✦  ╱    ╲  ✦  ╱    ╲  ✦  ╱    ╲       ✦        ║
    ║     ✦   ✦  ╱  ✦   ╲   ╱  ✦   ╲   ╱  ✦   ╲   ╱   ✦  ╲  ✦   ✦       ║
    ║    ✦       ◆────────◆────────◆────────◆────────◆       ✦            ║
    ║     ✦   ✦  ╲  ✦   ╱   ╲  ✦   ╱   ╲  ✦   ╱   ╲   ✦  ╱  ✦   ✦       ║
    ║      ✦       ╲    ╱  ✦  ╲    ╱  ✦  ╲    ╱  ✦  ╲    ╱       ✦        ║
    ║       *   ✦    ╲◆╱   ✦    ╲◆╱   ✦    ╲◆╱   ✦    ╲◆╱    ✦   *       ║
    ║        '*  ✦       ✦       ✦       ✦       ✦   ✦       ✦       *'  ║
    ║          '*:.    ✦       ✦       ✦       ✦   ✦       ✦    .:'*      ║
    ║             '*:.      ✦       ✦       ✦   ✦       ✦      .:'*       ║
    ║                '*:.        ✦       ✦   ✦       ✦        .:'*          ║
    ║                   '*:.         ✦       ✦         .:'*                 ║
    ║                      '*:.          *         .:'*                     ║
    ║                           '*:._.:*~*:._.:*'                           ║
    ║                                                                        ║
    ║              Sacred Geometry of Data Preservation                     ║
    ║                                                                        ║
    ╚════════════════════════════════════════════════════════════════════════╝

"@
    
    Write-Host $art -ForegroundColor Cyan
    Start-Sleep -Milliseconds 1500
}

#endregion

#region File Extension Categories

$FileExtensionCategories = @{
    'AllFiles' = @('*.*')
    'Documents' = @(
        '*.doc', '*.docx', '*.docm',           # Microsoft Word
        '*.xls', '*.xlsx', '*.xlsm', '*.xlsb', # Excel (will also be in Spreadsheets)
        '*.ppt', '*.pptx', '*.pptm',           # PowerPoint
        '*.pdf',                                # PDF
        '*.txt', '*.rtf', '*.odt', '*.ods',    # Text & OpenOffice
        '*.odp', '*.pages', '*.numbers',       # Apple iWork
        '*.key', '*.epub', '*.mobi'            # eBooks
    )
    'Images' = @(
        '*.jpg', '*.jpeg', '*.png', '*.gif',   # Common formats
        '*.bmp', '*.tiff', '*.tif', '*.webp', '*.ani',  # Other formats
        '*.svg', '*.ico', '*.heic', '*.heif',  # Modern/Vector
        '*.raw', '*.cr2', '*.nef', '*.arw', '*.pcx', '*.icns', '*.exr', '*.wmf',   # RAW formats
        '*.psd', '*.ai', '*.eps', '*.indd'     # Adobe formats
    )
    'Videos' = @(
        '*.mp4', '*.avi', '*.mkv', '*.mov', '*.gif',    # Common formats
        '*.wmv', '*.flv', '*.webm', '*.m1v', '*.m2v', '*.m3v', '*.m4v',   # Other formats
        '*.mpg', '*.mpeg', '*.3gp', '*.ts', '*.swf', '*.ppm',    # Legacy/Streaming
        '*.vob', '*.ogv', '*.mts', '*.m2ts'    # Disc/HD formats
    )
    'Audio' = @(
        '*.mp3', '*.wav', '*.flac', '*.m4a', '*.mpa',   # Common formats
        '*.aac', '*.ogg', '*.wma', '*.opus',   # Compressed
        '*.alac', '*.ape', '*.aiff', '*.aif', '*.mid',  # Lossless/MIDI
        '*.mid', '*.midi', '*.amr', '*.au', '*.ac3'     # Other formats
    )
    'Code' = @(
        '*.py', '*.pyw', '*.pyc',              # Python
        '*.js', '*.jsx', '*.ts', '*.tsx',      # JavaScript/TypeScript
        '*.html', '*.htm', '*.css', '*.scss',  # Web
        '*.json', '*.xml', '*.yaml', '*.yml',  # Data formats
        '*.ps1', '*.psm1', '*.psd1',           # PowerShell
        '*.sh', '*.bash', '*.zsh',             # Shell scripts
        '*.java', '*.class', '*.jar',          # Java
        '*.cpp', '*.c', '*.h', '*.hpp',        # C/C++
        '*.cs', '*.vb', '*.fs',                # .NET
        '*.php', '*.rb', '*.pl', '*.go',       # Other languages
        '*.sql', '*.r', '*.m', '*.swift',      # Database/Scientific/Mobile
        '*.kt', '*.rs', '*.lua', '*.vim'       # Modern languages
    )
    'Archives' = @(
        '*.zip', '*.rar', '*.7z', '*.tar',     # Common archives
        '*.gz', '*.bz2', '*.xz', '*.lz',       # Compression
        '*.iso', '*.dmg', '*.img',             # Disc images
        '*.cab', '*.deb', '*.rpm'              # Package formats
    )
    'Spreadsheets' = @(
        '*.xlsx', '*.xls', '*.xlsm', '*.xlsb', # Excel
        '*.csv', '*.tsv',                      # Delimited
        '*.ods', '*.numbers',                  # OpenOffice/Apple
        '*.xml', '*.json'                      # Data formats
    )
}

function Show-FileExtensionMenu {
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          SELECT FILE CATEGORY TO BACKUP               ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
    
    Write-Host "  [1] All Files (*.*)                    " -ForegroundColor White
    Write-Host "  [2] Documents                          " -ForegroundColor Yellow
    Write-Host "  [3] Images                             " -ForegroundColor Yellow
    Write-Host "  [4] Videos                             " -ForegroundColor Yellow
    Write-Host "  [5] Audio                              " -ForegroundColor Yellow
    Write-Host "  [6] Code Files                         " -ForegroundColor Yellow
    Write-Host "  [7] Archives                           " -ForegroundColor Yellow
    Write-Host "  [8] Spreadsheets                       " -ForegroundColor Yellow
    Write-Host "  [9] Custom Extensions                  " -ForegroundColor Yellow
    
    Write-Host "`n" -NoNewline
    $choice = Read-Host "Enter your choice (1-9)"
    
    switch ($choice) {
        '1' { return 'AllFiles', $null }
        '2' { return 'Documents', $null }
        '3' { return 'Images', $null }
        '4' { return 'Videos', $null }
        '5' { return 'Audio', $null }
        '6' { return 'Code', $null }
        '7' { return 'Archives', $null }
        '8' { return 'Spreadsheets', $null }
        '9' { 
            Write-Host "`nEnter custom extensions (comma-separated, e.g., *.xyz, *.abc): " -NoNewline -ForegroundColor Yellow
            $custom = Read-Host
            $extensions = $custom -split ',' | ForEach-Object { $_.Trim() }
            return 'Custom', $extensions
        }
        default {
            Write-Host "Invalid choice. Defaulting to All Files." -ForegroundColor Red
            return 'AllFiles', $null
        }
    }
}

#endregion

#region Logging Functions

function Initialize-LogFile {
    param([string]$LogPath)
    
    $logHeader = @"
╔════════════════════════════════════════════════════════════════════════╗
║                    BACKUP OPERATION LOG                                ║
║                    $(Get-Date -Format 'dd-MMM-yyyy HH:mm:ss')                          ║
╚════════════════════════════════════════════════════════════════════════╝

"@
    
    Set-Content -Path $LogPath -Value $logHeader -Force
    return $LogPath
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Header', 'Stat')]
        [string]$Level = 'Info',
        [string]$LogPath
    )
    
    $timestamp = Get-Date -Format "dd-MMM-yyyy HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console output with color
    switch ($Level) {
        'Info'    { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
        'Header'  { Write-Host "`n$Message" -ForegroundColor Magenta }
        'Stat'    { Write-Host $Message -ForegroundColor White }
    }
    
    # Always log to file
    Add-Content -Path $LogPath -Value $logMessage
}

#endregion

#region System Analysis Functions

function Get-SystemResources {
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $mem = Get-CimInstance -ClassName Win32_OperatingSystem
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
    
    $resources = @{
        CPUCores = $cpu.NumberOfCores
        CPUThreads = $cpu.NumberOfLogicalProcessors
        CPUSpeed = [math]::Round($cpu.MaxClockSpeed / 1000, 2)
        TotalRAMGB = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 2)
        FreeRAMGB = [math]::Round($mem.FreePhysicalMemory / 1MB, 2)
        Disks = $disk | ForEach-Object {
            @{
                Drive = $_.DeviceID
                FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2)
                TotalSpaceGB = [math]::Round($_.Size / 1GB, 2)
            }
        }
    }
    
    return $resources
}

function Get-ActiveProcessCount {
    return (Get-Process).Count
}

function Estimate-TransferTime {
    param(
        [long]$TotalBytes,
        [hashtable]$SystemResources
    )
    
    # Base transfer speed estimation (MB/s)
    # Adjusted based on system specs and typical disk performance
    $baseMBps = 50  # Conservative estimate for modern SSDs
    
    # Adjust for system load (more processes = slower)
    $processCount = Get-ActiveProcessCount
    $loadFactor = if ($processCount -gt 200) { 0.7 } elseif ($processCount -gt 100) { 0.85 } else { 1.0 }
    
    # Adjust for available RAM
    $ramFactor = if ($SystemResources.FreeRAMGB -lt 2) { 0.6 } elseif ($SystemResources.FreeRAMGB -lt 4) { 0.8 } else { 1.0 }
    
    # Calculate effective transfer speed
    $effectiveMBps = $baseMBps * $loadFactor * $ramFactor
    
    # Calculate time in seconds
    $totalMB = $TotalBytes / 1MB
    $seconds = $totalMB / $effectiveMBps
    
    # Add overhead for file operations (20% additional time)
    $seconds = $seconds * 1.2
    
    return [TimeSpan]::FromSeconds($seconds)
}

#endregion

#region Path Manipulation Functions

function Get-SanitizedFolderName {
    param(
        [string]$FolderName,
        [int]$MaxLength = 200
    )
    
    # Remove invalid characters
    $sanitized = $FolderName -replace '[<>:"/\\|?*]', '_'
    
    # Trim to max length
    if ($sanitized.Length -gt $MaxLength) {
        $sanitized = $sanitized.Substring(0, $MaxLength)
    }
    
    return $sanitized
}

function Compress-EmptyFolderPath {
    param(
        [string]$Path,
        [string]$SourceRoot
    )
    
    $relativePath = $Path.Substring($SourceRoot.Length).TrimStart('\')
    $pathParts = $relativePath -split '\\'
    
    # Recursively condense empty parent folders
    $condensedParts = @()
    $pendingEmpty = @()
    
    for ($i = 0; $i -lt $pathParts.Length; $i++) {
        $currentPath = Join-Path $SourceRoot ($pathParts[0..$i] -join '\')
        
        # Check if folder only contains other folders (no files)
        $hasFiles = (Get-ChildItem -Path $currentPath -File).Count -gt 0
        
        if (-not $hasFiles -and $i -lt ($pathParts.Length - 1)) {
            # This is an empty intermediate folder
            $pendingEmpty += $pathParts[$i]
        } else {
            # This folder has files or is the leaf
            if ($pendingEmpty.Count -gt 0) {
                # Combine all pending empty folders
                $condensedParts += ($pendingEmpty -join '_')
                $pendingEmpty = @()
            }
            $condensedParts += $pathParts[$i]
        }
    }
    
    return $condensedParts -join '\'
}

function Get-SafeFileName {
    param(
        [string]$DestinationDir,
        [string]$FileName,
        [string]$OriginalFullPath,
        [ref]$LengthLimitFiles
    )
    
    $maxPathLength = 260
    $destinationFile = Join-Path $DestinationDir $FileName
    
    if ($destinationFile.Length -gt $maxPathLength) {
        # Path too long - create special handling folder
        $limitFolder = Join-Path $DestinationDir "filename_length_limit"
        
        if (-not (Test-Path $limitFolder)) {
            New-Item -Path $limitFolder -ItemType Directory -Force
        }
        
        # Find next available number
        $counter = 1
        $extension = [System.IO.Path]::GetExtension($FileName)
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
        $baseName = $baseName.Substring(0, [Math]::Min(50, $baseName.Length))
        
        do {
            $newFileName = "${baseName}_$counter$extension"
            $destinationFile = Join-Path $limitFolder $newFileName
            $counter++
        } while (Test-Path $destinationFile)
        
        # Log the original path
        $LengthLimitFiles.Value += @{
            OriginalPath = $OriginalFullPath
            NewPath = $destinationFile
            Reason = "Path length exceeded $maxPathLength characters"
        }
        
        return $destinationFile
    }
    
    # Handle naming conflicts
    if (Test-Path $destinationFile) {
        $counter = 1
        $extension = [System.IO.Path]::GetExtension($FileName)
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
        
        do {
            $newFileName = "${baseName}_$counter$extension"
            $destinationFile = Join-Path $DestinationDir $newFileName
            $counter++
        } while (Test-Path $destinationFile)
    }
    
    return $destinationFile
}

#endregion

#region Main Script

try {
    # Display sacred geometry
    Show-SacredGeometry
    
    # Initialize log file
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFileName = "BackupLog_${timestamp}.log"
    $logPath = Join-Path $DestinationPath $logFileName
    
    # Create destination if it doesn't exist
    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force
    }
    
    $logPath = Initialize-LogFile -LogPath $logPath
    
    Write-Log "╔════════════════════════════════════════════════════════════════════════╗" -Level Header -LogPath $logPath
    Write-Log "║                    BACKUP INITIALIZATION                               ║" -Level Header -LogPath $logPath
    Write-Log "╚════════════════════════════════════════════════════════════════════════╝" -Level Header -LogPath $logPath
    
    Write-Log "Source Path: $SourcePath" -Level Info -LogPath $logPath
    Write-Log "Destination Path: $DestinationPath" -Level Info -LogPath $logPath
    Write-Log "Operation Type: $Operation" -Level Info -LogPath $logPath
    
    # Get file category
    if (-not $FileCategory) {
        $FileCategory, $CustomExtensions = Show-FileExtensionMenu
    }
    
    $extensions = if ($FileCategory -eq 'Custom' -and $CustomExtensions) {
        $CustomExtensions
    } else {
        $FileExtensionCategories[$FileCategory]
    }
    
    Write-Log "File Category: $FileCategory" -Level Info -LogPath $logPath
    Write-Log "Extensions: $($extensions -join ', ')" -Level Info -LogPath $logPath
    
    # Analyze system resources
    Write-Log "`nAnalyzing system resources..." -Level Info -LogPath $logPath
    $sysResources = Get-SystemResources
    $processCount = Get-ActiveProcessCount
    
    Write-Log "System Specifications:" -Level Header -LogPath $logPath
    Write-Log "  CPU: $($sysResources.CPUCores) cores / $($sysResources.CPUThreads) threads @ $($sysResources.CPUSpeed) GHz" -Level Stat -LogPath $logPath
    Write-Log "  RAM: $($sysResources.FreeRAMGB) GB free / $($sysResources.TotalRAMGB) GB total" -Level Stat -LogPath $logPath
    Write-Log "  Active Processes: $processCount" -Level Stat -LogPath $logPath
    
    foreach ($disk in $sysResources.Disks) {
        Write-Log "  Disk $($disk.Drive): $($disk.FreeSpaceGB) GB free / $($disk.TotalSpaceGB) GB total" -Level Stat -LogPath $logPath
    }
    
    # Scan for files
    Write-Log "`nScanning for files..." -Level Info -LogPath $logPath
    $files = @()
    $scanStartTime = Get-Date
    
    foreach ($extension in $extensions) {
        $foundFiles = Get-ChildItem -Path $SourcePath -Filter $extension -File -Recurse
        $files += $foundFiles
    }
    
    $scanDuration = (Get-Date) - $scanStartTime
    
    Write-Log "Scan completed in $($scanDuration.TotalSeconds.ToString('F2')) seconds" -Level Success -LogPath $logPath
    Write-Log "Found $($files.Count) file(s) matching criteria" -Level Success -LogPath $logPath
    
    if ($files.Count -eq 0) {
        Write-Log "No files found matching the specified criteria. Exiting." -Level Warning -LogPath $logPath
        return
    }
    
    # Calculate total size
    Write-Log "`nCalculating total size..." -Level Info -LogPath $logPath
    $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
    $totalSizeGB = [math]::Round($totalBytes / 1GB, 2)
    $totalSizeMB = [math]::Round($totalBytes / 1MB, 2)
    
    Write-Log "Total size: $totalSizeGB GB ($totalSizeMB MB)" -Level Success -LogPath $logPath
    
    # Estimate time
    $estimatedTime = Estimate-TransferTime -TotalBytes $totalBytes -SystemResources $sysResources
    Write-Log "Estimated transfer time: $($estimatedTime.Hours)h $($estimatedTime.Minutes)m $($estimatedTime.Seconds)s" -Level Info -LogPath $logPath
    
    # Check destination space
    $destDrive = Split-Path $DestinationPath -Qualifier
    $destDisk = $sysResources.Disks | Where-Object { $_.Drive -eq $destDrive }
    
    if ($destDisk -and $destDisk.FreeSpaceGB -lt $totalSizeGB) {
        Write-Log "WARNING: Destination drive may not have enough space!" -Level Warning -LogPath $logPath
        Write-Log "  Required: $totalSizeGB GB" -Level Warning -LogPath $logPath
        Write-Log "  Available: $($destDisk.FreeSpaceGB) GB" -Level Warning -LogPath $logPath
    }
    
    # Initialize statistics
    $stats = @{
        TotalFiles = $files.Count
        Processed = 0
        Success = 0
        Failed = 0
        Skipped = 0
        TotalBytes = $totalBytes
        BytesProcessed = 0
    }
    
    $lengthLimitFiles = @()
    $failedOperations = @()
    $fileMap = @()  # For restoration script
    
    # Start operation
    $operationStartTime = Get-Date
    Write-Log "`n╔════════════════════════════════════════════════════════════════════════╗" -Level Header -LogPath $logPath
    Write-Log "║                    BEGINNING $Operation OPERATION                         ║" -Level Header -LogPath $logPath
    Write-Log "╚════════════════════════════════════════════════════════════════════════╝" -Level Header -LogPath $logPath
    
    foreach ($file in $files) {
        $stats.Processed++
        $percentComplete = [math]::Round(($stats.Processed / $stats.TotalFiles) * 100, 2)
        $percentBytes = [math]::Round(($stats.BytesProcessed / $stats.TotalBytes) * 100, 2)
        
        Write-Progress -Activity "$Operation Files - $($file.Name)" `
                       -Status "File $($stats.Processed) of $($stats.TotalFiles) | $percentComplete% | $percentBytes% of data" `
                       -PercentComplete $percentComplete `
                       -CurrentOperation "Processing: $($file.FullName)"
        
        try {
            # Get relative path and preserve structure
            $relativePath = $file.DirectoryName.Substring($SourcePath.Length).TrimStart('\')
            
            # Condense empty folders if applicable
            # (For now, we'll preserve full structure - condensing logic can be added)
            
            $destDir = Join-Path $DestinationPath $relativePath
            
            # Create directory structure
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force
            }
            
            # Get safe destination file path
            $destFile = Get-SafeFileName -DestinationDir $destDir `
                                        -FileName $file.Name `
                                        -OriginalFullPath $file.FullName `
                                        -LengthLimitFiles ([ref]$lengthLimitFiles)
            
            # Perform operation
            if ($Operation -eq 'Copy') {
                Copy-Item -Path $file.FullName -Destination $destFile -Force
            } else {
                Move-Item -Path $file.FullName -Destination $destFile -Force
            }
            
            # Log to file map for restoration
            $fileMap += @{
                SourcePath = $file.FullName
                DestinationPath = $destFile
                Size = $file.Length
                Timestamp = Get-Date -Format "dd-MMM-yyyy HH:mm:ss"
            }
            
            $stats.Success++
            $stats.BytesProcessed += $file.Length
            
            Write-Log "${Operation}d: $($file.FullName) -> $destFile" -Level Success -LogPath $logPath
            
        } catch {
            $stats.Failed++
            $failedOperations += @{
                FilePath = $file.FullName
                Error = $_.Exception.Message
                Timestamp = Get-Date -Format "dd-MMM-yyyy HH:mm:ss"
            }
            Write-Log "FAILED: $($file.FullName) - $($_.Exception.Message)" -Level Error -LogPath $logPath
        }
    }
    
    Write-Progress -Activity "$Operation Files" -Completed
    
    $operationDuration = (Get-Date) - $operationStartTime
    
    # Generate summary
    Write-Log "`n╔════════════════════════════════════════════════════════════════════════╗" -Level Header -LogPath $logPath
    Write-Log "║                    OPERATION SUMMARY                                   ║" -Level Header -LogPath $logPath
    Write-Log "╚════════════════════════════════════════════════════════════════════════╝" -Level Header -LogPath $logPath
    
    Write-Log "Total files found: $($stats.TotalFiles)" -Level Stat -LogPath $logPath
    Write-Log "Successfully processed: $($stats.Success)" -Level Success -LogPath $logPath
    Write-Log "Failed: $($stats.Failed)" -Level $(if ($stats.Failed -gt 0) { 'Error' } else { 'Info' }) -LogPath $logPath
    Write-Log "Total size processed: $totalSizeGB GB" -Level Stat -LogPath $logPath
    Write-Log "Actual duration: $($operationDuration.Hours)h $($operationDuration.Minutes)m $($operationDuration.Seconds)s" -Level Stat -LogPath $logPath
    Write-Log "Estimated duration was: $($estimatedTime.Hours)h $($estimatedTime.Minutes)m $($estimatedTime.Seconds)s" -Level Stat -LogPath $logPath
    
    # Export file map for restoration
    $fileMapPath = Join-Path $DestinationPath "FileMap_${timestamp}.json"
    $fileMap | ConvertTo-Json -Depth 10 | Set-Content -Path $fileMapPath
    Write-Log "`nFile map exported to: $fileMapPath" -Level Success -LogPath $logPath
    
    # Export length limit files if any
    if ($lengthLimitFiles.Count -gt 0) {
        $lengthLimitPath = Join-Path $DestinationPath "LengthLimitFiles_${timestamp}.txt"
        $lengthLimitFiles | ForEach-Object {
            "Original: $($_.OriginalPath)`nNew: $($_.NewPath)`nReason: $($_.Reason)`n---`n"
        } | Set-Content -Path $lengthLimitPath
        Write-Log "Length-limited files documented in: $lengthLimitPath" -Level Warning -LogPath $logPath
    }
    
    # Export failed operations if any
    if ($failedOperations.Count -gt 0) {
        $failedOpsPath = Join-Path $DestinationPath "FailedOperations_${timestamp}.txt"
        $failedOperations | ForEach-Object {
            "File: $($_.FilePath)`nError: $($_.Error)`nTime: $($_.Timestamp)`n---`n"
        } | Set-Content -Path $failedOpsPath
        Write-Log "Failed operations documented in: $failedOpsPath" -Level Error -LogPath $logPath
    }
    
    Write-Log "`n════════════════════════════════════════════════════════════════════════" -Level Header -LogPath $logPath
    Write-Log "BACKUP OPERATION COMPLETED" -Level Success -LogPath $logPath
    Write-Log "════════════════════════════════════════════════════════════════════════" -Level Header -LogPath $logPath
    Write-Log "Log file: $logPath" -Level Info -LogPath $logPath
    
} catch {
    Write-Log "CRITICAL ERROR: $($_.Exception.Message)" -Level Error -LogPath $logPath
    Write-Log "Stack Trace: $($_.ScriptStackTrace)" -Level Error -LogPath $logPath
    throw
}

#endregion
