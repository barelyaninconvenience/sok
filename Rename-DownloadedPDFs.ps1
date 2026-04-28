#Requires -Version 7.0
<#
.SYNOPSIS
    Auto-rename helper for PDFs landing in Downloads/ from multi-repository research traversal.

.DESCRIPTION
    Watches C:\Users\shelc\Downloads\ for newly-arrived PDF files, identifies their source
    (arxiv, DTIC, Scribd, IEEE, Internet Archive, ResearchGate, Government Publishing Office,
    Huntington/SoFi statements, Scribd-titled), proposes a structured rename, and applies it
    after batch confirmation.

    Naming convention:
        Author_Topic_Specific_Source_Year.pdf
        e.g. Richards_PrinciplesOfModernRadar_Vol1_BasicPrinciples.pdf

    Designed for Clay's research-acquisition workflow during the Scribd 30-day trial +
    parallel acquisition from DTIC, arxiv, OhioLINK, IEEE Xplore via UC, etc.

.PARAMETER DryRun
    Show proposed renames without executing.

.PARAMETER SinceMinutes
    Only process files modified in the last N minutes. Default: 60.

.PARAMETER LogPath
    Override default log location. Default: Downloads\_rename_log.txt

.EXAMPLE
    pwsh .\Rename-DownloadedPDFs.ps1 -DryRun
        Show what would be renamed (no execution).

.EXAMPLE
    pwsh .\Rename-DownloadedPDFs.ps1 -SinceMinutes 240
        Process anything from the last 4 hours.

.NOTES
    Author: Clay Caddell
    Created: 2026-04-27
    Pairs with: Writings/Radar_SIGINT_Professional_Ecosystem_Map_20260427.md (the priority download list)
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [int]$SinceMinutes = 60,
    [string]$DownloadsDir = "C:\Users\shelc\Downloads",
    [string]$LogPath = "C:\Users\shelc\Downloads\_rename_log.txt"
)

if (-not (Test-Path $DownloadsDir)) {
    Write-Error "Downloads directory not found: $DownloadsDir"
    exit 1
}

$cutoff = (Get-Date).AddMinutes(-$SinceMinutes)
$pdfs = Get-ChildItem -Path $DownloadsDir -Filter *.pdf -File |
    Where-Object { $_.LastWriteTime -gt $cutoff } |
    Sort-Object LastWriteTime

if ($pdfs.Count -eq 0) {
    Write-Host "[INFO] No PDFs modified in last $SinceMinutes minutes. Nothing to do." -ForegroundColor Yellow
    exit 0
}

Write-Host "[INFO] Found $($pdfs.Count) candidate PDF(s) in Downloads/" -ForegroundColor Cyan

function Get-ProposedName {
    param([System.IO.FileInfo]$file)

    $name = $file.Name
    $base = $file.BaseName

    # Already-renamed (matches our convention)
    if ($name -match '^[A-Z][a-zA-Z]+_[A-Za-z0-9_]+\.pdf$' -and $name -notmatch '^Module_\d+\.pdf$') {
        return $null  # Already renamed; skip
    }

    # arxiv pattern: NNNN.NNNNNvN.pdf or NNNN.NNNNN.pdf
    if ($base -match '^(\d{4})\.(\d{4,5})(v\d+)?$') {
        $year = "20" + $matches[1].Substring(0,2)
        $arxivId = $matches[1] + "_" + $matches[2]
        return "ARXIV_${arxivId}_NeedsTitleCheck_${year}.pdf"
    }

    # DTIC AD reference: ADAxxxxxx.pdf
    if ($base -match '^ADA\d{6,}$') {
        return "DTIC_${base}_NeedsTitleCheck.pdf"
    }

    # GOVPUB pattern
    if ($base -match '^GOVPUB-') {
        return "GovPub_${base}_NeedsTitleCheck.pdf"
    }

    # Huntington SOS document (UUID braces)
    if ($base -match '^DocumentSOS\d') {
        return "Huntington_Statement_NeedsPeriodCheck_${base}.pdf"
    }

    # Discover Statement
    if ($base -match '^Discover-Statement-(\d{8})-(\d+)$') {
        $date = $matches[1]
        $last4 = $matches[2]
        $formattedDate = "$($date.Substring(0,4))_$($date.Substring(4,2))_$($date.Substring(6,2))"
        return "Discover_CC_Statement_${formattedDate}_x${last4}.pdf"
    }

    # Bank statement pattern: YYYYMMDD_BANK
    if ($base -match '^(\d{8})_BANK$') {
        $date = $matches[1]
        $formattedDate = "$($date.Substring(0,4))_$($date.Substring(4,2))_$($date.Substring(6,2))"
        return "BankStatement_${formattedDate}.pdf"
    }

    # SoFi: UUID-style filename
    if ($base -match '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$') {
        return "UUID_${base}_NeedsContentCheck.pdf"
    }

    # InvoiceReport with timestamp
    if ($base -match '^InvoiceReport - (\d{4}-\d{2}-\d{2})T(\d+)\.\d+$') {
        $date = $matches[1] -replace '-','_'
        $time = $matches[2]
        return "InvoiceReport_${date}_T${time}.pdf"
    }

    # Scribd download (typical: Title-Author-Publisher-Year)
    # No reliable pattern; just check for spaces + capitalization
    if ($name -match '\s' -or $name -match '[a-z]+-[a-z]+') {
        # Replace problematic characters: spaces with underscores, drop curly braces, etc.
        $proposed = $base -replace '\s+','_' -replace '[\{\}\(\)]','' -replace '[^a-zA-Z0-9_\-\.]','_' -replace '_+','_'
        $proposed = $proposed.Trim('_')
        if ($proposed -ne $base) {
            return "${proposed}.pdf"
        }
    }

    return $null  # No clear pattern; flag for manual review
}

# Build proposal table
$proposals = @()
$alreadyClean = @()
$needsManual = @()

foreach ($file in $pdfs) {
    $proposed = Get-ProposedName -file $file
    if ($null -eq $proposed) {
        if ($file.Name -match '^[A-Z][a-zA-Z]+_') {
            $alreadyClean += $file
        } else {
            $needsManual += $file
        }
    } else {
        $proposals += [PSCustomObject]@{
            Old = $file.Name
            New = $proposed
            Path = $file.FullName
        }
    }
}

Write-Host ""
Write-Host "=== Already cleanly named (skipping) ===" -ForegroundColor Green
$alreadyClean | ForEach-Object { Write-Host "  $($_.Name)" }

Write-Host ""
Write-Host "=== Proposed renames ($($proposals.Count)) ===" -ForegroundColor Cyan
foreach ($p in $proposals) {
    Write-Host "  $($p.Old)" -ForegroundColor White
    Write-Host "    -> $($p.New)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Needs manual identification ($($needsManual.Count)) ===" -ForegroundColor Magenta
$needsManual | ForEach-Object { Write-Host "  $($_.Name) ($([math]::Round($_.Length/1KB,1)) KB, $($_.LastWriteTime))" }

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY RUN] No renames executed. Re-run without -DryRun to apply." -ForegroundColor Yellow
    exit 0
}

if ($proposals.Count -eq 0) {
    Write-Host ""
    Write-Host "[INFO] No proposed renames. Nothing to apply." -ForegroundColor Yellow
    exit 0
}

# Apply renames
Write-Host ""
$confirm = Read-Host "Apply $($proposals.Count) proposed rename(s)? [y/N]"
if ($confirm -notmatch '^[yY]') {
    Write-Host "[ABORT] User declined." -ForegroundColor Red
    exit 0
}

$logEntries = @()
$logEntries += "=== Rename batch $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

$successCount = 0
$failCount = 0
foreach ($p in $proposals) {
    $newPath = Join-Path $DownloadsDir $p.New
    if (Test-Path -LiteralPath $newPath) {
        $logEntries += "SKIP $($p.Old) -> $($p.New) (target exists)"
        Write-Host "  SKIP $($p.Old) -> $($p.New) (target exists)" -ForegroundColor Yellow
        continue
    }
    try {
        Rename-Item -LiteralPath $p.Path -NewName $p.New -ErrorAction Stop
        $logEntries += "OK   $($p.Old) -> $($p.New)"
        Write-Host "  OK   $($p.Old) -> $($p.New)" -ForegroundColor Green
        $successCount++
    } catch {
        $logEntries += "FAIL $($p.Old) -> $($p.New) : $($_.Exception.Message)"
        Write-Host "  FAIL $($p.Old) -> $($p.New) : $($_.Exception.Message)" -ForegroundColor Red
        $failCount++
    }
}

$logEntries += "Result: $successCount OK, $failCount FAIL"
$logEntries += ""
$logEntries -join [Environment]::NewLine | Add-Content -Path $LogPath -Encoding UTF8

Write-Host ""
Write-Host "[DONE] Renamed: $successCount  Failed: $failCount" -ForegroundColor Cyan
Write-Host "Log: $LogPath" -ForegroundColor Gray
