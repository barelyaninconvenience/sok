<#
.SYNOPSIS
    Recursively searches a directory for files and moves them to a destination folder.

.DESCRIPTION
    This script searches through a source directory and all its subdirectories for files 
    matching specified extensions (or all files if no filter is specified). It then moves 
    all matching files to a single destination directory, preserving original filenames 
    and handling naming conflicts.

.PARAMETER SourcePath
    The root directory to search recursively for files.

.PARAMETER DestinationPath
    The target directory where all found files will be moved.

.PARAMETER FileExtensions
    Optional array of file extensions to filter (e.g., @("*.txt", "*.pdf", "*.docx")).
    If not specified, all files will be processed.

.PARAMETER CreateDestination
    If specified, creates the destination directory if it doesn't exist.

.PARAMETER HandleConflicts
    Specifies how to handle filename conflicts:
    - 'Skip': Skip files with duplicate names (default)
    - 'Rename': Rename conflicting files by adding a number suffix
    - 'Overwrite': Overwrite existing files (use with caution)

.PARAMETER WhatIf
    Shows what would happen if the script runs without actually moving files.

.PARAMETER LogPath
    Optional path to write a log file of all operations.

.EXAMPLE
    .\Move-FilesRecursively.ps1 -SourcePath "C:\Projects" -DestinationPath "C:\AllFiles" -CreateDestination
    Moves all files from C:\Projects and subdirectories to C:\AllFiles

.EXAMPLE
    .\Move-FilesRecursively.ps1 -SourcePath "C:\Documents" -DestinationPath "C:\PDFs" -FileExtensions @("*.pdf")
    Moves only PDF files to the destination

.EXAMPLE
    .\Move-FilesRecursively.ps1 -SourcePath "C:\Data" -DestinationPath "C:\Archive" -HandleConflicts Rename -WhatIf
    Shows what would happen when moving files with conflict renaming

.NOTES
    Author: AI Engineer
    Version: 1.0
    Last Updated: 2026-01-08
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true, HelpMessage="Source directory to search")]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$SourcePath,

    [Parameter(Mandatory=$true, HelpMessage="Destination directory for moved files")]
    [string]$DestinationPath,

    [Parameter(Mandatory=$false, HelpMessage="File extensions to filter (e.g., @('*.txt', '*.pdf'))")]
    [string[]]$FileExtensions = @("*.*"),

    [Parameter(Mandatory=$false, HelpMessage="Create destination directory if it doesn't exist")]
    [switch]$CreateDestination,

    [Parameter(Mandatory=$false, HelpMessage="How to handle filename conflicts")]
    [ValidateSet('Skip', 'Rename', 'Overwrite')]
    [string]$HandleConflicts = 'Skip',

    [Parameter(Mandatory=$true, HelpMessage="Path to write operation log")]
    [string]$LogPath
)

#region Functions

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "dd-MMM-YYYY HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console output with color
    switch ($Level) {
        'Info'    { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
    
    # File output if log path specified
    if ($LogPath) {
        Add-Content -Path $LogPath -Value $logMessage
    }
}

function Get-UniqueFileName {
    param(
        [string]$DestinationPath,
        [string]$FileName
    )
    
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $extension = [System.IO.Path]::GetExtension($FileName)
    $counter = 1
    $newFileName = $FileName
    
    while (Test-Path (Join-Path $DestinationPath $newFileName)) {
        $newFileName = "${baseName}_$counter$extension"
        $counter++
    }
    
    return $newFileName
}

#endregion

#region Main Script

try {
    Write-Log "=== File Move Operation Started ===" -Level Info
    Write-Log "Source Path: $SourcePath" -Level Info
    Write-Log "Destination Path: $DestinationPath" -Level Info
    Write-Log "File Extensions: $($FileExtensions -join ', ')" -Level Info
    Write-Log "Conflict Handling: $HandleConflicts" -Level Info
    
    # Validate and create destination directory
    if (-not (Test-Path $DestinationPath)) {
        if ($CreateDestination) {
            Write-Log "Creating destination directory: $DestinationPath" -Level Info
            New-Item -Path $DestinationPath -ItemType Directory -Force
        } else {
            throw "Destination path does not exist. Use -CreateDestination to create it automatically."
        }
    }
    
    # Initialize counters
    $stats = @{
        TotalFound = 0
        Moved = 0
        Skipped = 0
        Failed = 0
    }
    
    # Get all files recursively based on extension filters
    Write-Log "Searching for files..." -Level Info
    $files = @()
    
    foreach ($extension in $FileExtensions) {
        $foundFiles = Get-ChildItem -Path $SourcePath -Filter $extension -File -Recurse
        $files += $foundFiles
    }
    
    $stats.TotalFound = $files.Count
    Write-Log "Found $($stats.TotalFound) file(s) matching criteria" -Level Info
    
    if ($stats.TotalFound -eq 0) {
        Write-Log "No files found matching the specified criteria." -Level Warning
        return
    }
    
    # Process each file
    $progressCounter = 0
    foreach ($file in $files) {
        $progressCounter++
        $percentComplete = [math]::Round(($progressCounter / $stats.TotalFound) * 100, 2)
        
        Write-Progress -Activity "Moving Files" `
                       -Status "Processing: $($file.Name)" `
                       -PercentComplete $percentComplete `
                       -CurrentOperation "$progressCounter of $($stats.TotalFound)"
        
        try {
            $destinationFile = Join-Path $DestinationPath $file.Name
            $shouldMove = $true
            $targetFileName = $file.Name
            
            # Handle filename conflicts
            if (Test-Path $destinationFile) {
                switch ($HandleConflicts) {
                    'Skip' {
                        Write-Log "Skipping duplicate file: $($file.Name)" -Level Warning
                        $stats.Skipped++
                        $shouldMove = $false
                    }
                    'Rename' {
                        $targetFileName = Get-UniqueFileName -DestinationPath $DestinationPath -FileName $file.Name
                        $destinationFile = Join-Path $DestinationPath $targetFileName
                        Write-Log "Renaming conflicting file: $($file.Name) -> $targetFileName" -Level Info
                    }
                    'Overwrite' {
                        Write-Log "Overwriting existing file: $($file.Name)" -Level Warning
                    }
                }
            }
            
            # Move the file
            if ($shouldMove) {
                if ($PSCmdlet.ShouldProcess($file.FullName, "Move to $destinationFile")) {
                    Move-Item -Path $file.FullName -Destination $destinationFile -Force:($HandleConflicts -eq 'Overwrite')
                    Write-Log "Moved: $($file.FullName) -> $destinationFile" -Level Success
                    $stats.Moved++
                }
            }
            
        } catch {
            Write-Log "Failed to move $($file.FullName): $($_.Exception.Message)" -Level Error
            $stats.Failed++
        }
    }
    
    Write-Progress -Activity "Moving Files" -Completed
    
    # Display summary
    Write-Log "`n=== Operation Summary ===" -Level Info
    Write-Log "Total files found: $($stats.TotalFound)" -Level Info
    Write-Log "Successfully moved: $($stats.Moved)" -Level Success
    Write-Log "Skipped (duplicates): $($stats.Skipped)" -Level Warning
    Write-Log "Failed: $($stats.Failed)" -Level $(if ($stats.Failed -gt 0) { 'Error' } else { 'Info' })
    Write-Log "=== Operation Completed ===" -Level Info
    
} catch {
    Write-Log "Critical error: $($_.Exception.Message)" -Level Error
    throw
}

#endregion
