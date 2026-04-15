$sourceDrive = "C:\"
$jsonOutput  = "C:\Users\shelc\Documents\Journal\Projects\20260323_SystemFileStructure.json"
$errorLog    = "C:\Users\shelc\Documents\Journal\Projects\20260323_ScanErrors.log"

Write-Host "Starting bottomless scan of $sourceDrive..." -ForegroundColor Cyan

# 1. THE FILE SCAN
# -Recurse replaces -Depth. It will go as deep as the file system allows.
$files = Get-ChildItem -Path $sourceDrive -Force -File -Recurse -ErrorAction Continue -ErrorVariable scanErrors

Write-Host "Scan finished. Found $($files.Count) files. Compiling JSON stream..." -ForegroundColor Cyan

# 2. STREAMING JSON OUTPUT (Memory Optimization)
$stream = [System.IO.StreamWriter]::new($jsonOutput, $false, [System.Text.Encoding]::UTF8)
$stream.WriteLine("[")

$isFirst = $true

foreach ($file in $files) {
    if (-not $isFirst) { $stream.WriteLine(",") }
    $isFirst = $false

    $sizeKB = [math]::Round(($file.Length / 1KB), 2)
    
    # Escape characters to prevent JSON formatting breaks
    $safePath = $file.FullName.Replace('\', '\\').Replace('"', '\"')
    $creation = $file.CreationTime.ToString("yyyy-MM-dd HH:mm:ss")
    $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")

    $jsonBlock = @"
  {
    "AbsolutePath": "$safePath",
    "SizeKB": $sizeKB,
    "Creation": "$creation",
    "LastModified": "$modified"
  }
"@
    $stream.Write($jsonBlock)
}

$stream.WriteLine()
$stream.WriteLine("]")
$stream.Close()
$stream.Dispose()

# 3. VERBOSE ERROR LOGGING
if ($scanErrors.Count -gt 0) {
    Write-Host "Logging $($scanErrors.Count) access/system errors to log file..." -ForegroundColor Yellow
    $errorStream = [System.IO.StreamWriter]::new($errorLog, $false, [System.Text.Encoding]::UTF8)
    
    foreach ($err in $scanErrors) {
        $errorStream.WriteLine("[$($err.CategoryInfo.Category)] $($err.TargetObject) - $($err.Exception.Message)")
    }
    
    $errorStream.Close()
    $errorStream.Dispose()
}

Write-Host "Task Complete! Check your Projects folder." -ForegroundColor Green