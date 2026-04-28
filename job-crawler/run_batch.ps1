# Run the Handshake batch scrape + scoring pipeline.
# Assumes Chrome is running with --remote-debugging-port=9222 and Clay is logged into Handshake.
#
# Usage: .\run_batch.ps1 -SearchUrl "https://app.joinhandshake.com/..." -MaxJobs 1000

param(
    [Parameter(Mandatory=$true)][string]$SearchUrl,
    [int]$MaxJobs = 1000,
    [double]$Delay = 2.5,
    [string]$LlmModel = "claude-sonnet-4-6",
    [switch]$NoLlm
)

$ErrorActionPreference = 'Continue'
$Root = $PSScriptRoot
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogDir = Join-Path $Root "data\logs"
New-Item $LogDir -ItemType Directory -Force | Out-Null
$Log = Join-Path $LogDir "batch_${Timestamp}.log"

function Write-Log($Message) {
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | $Message"
    Add-Content -Path $Log -Value $line
    Write-Host $line
}

Write-Log "=== Handshake Batch Pipeline — ${Timestamp} ==="
Write-Log "SearchUrl: $SearchUrl"
Write-Log "MaxJobs: $MaxJobs | Delay: $Delay | LlmModel: $LlmModel | NoLlm: $NoLlm"
Write-Log ""

# Stage 1: Scrape
Write-Log "[1/5] Scraping Handshake via Playwright (CDP)..."
$scrapeArgs = @(
    "-3.14",
    "$Root\lib\sources\handshake_playwright.py",
    "--search-url", $SearchUrl,
    "--max-jobs", $MaxJobs,
    "--delay", $Delay
)
py @scrapeArgs 2>&1 | ForEach-Object { Write-Log $_ }
if ($LASTEXITCODE -ne 0) {
    Write-Log "SCRAPE FAILED (exit $LASTEXITCODE). Aborting."
    exit $LASTEXITCODE
}

# Stage 2: Dry score
Write-Log ""
Write-Log "[2/5] Dry-scoring..."
py -3.14 "$Root\bin\dry_score.py" --threshold 7 2>&1 | ForEach-Object { Write-Log $_ }

# Stage 3: LLM score
if (-not $NoLlm) {
    Write-Log ""
    Write-Log "[3/5] LLM scoring..."
    py -3.14 "$Root\bin\score.py" --model $LlmModel 2>&1 | ForEach-Object { Write-Log $_ }
} else {
    Write-Log "[3/5] Skipping LLM scoring (--NoLlm)"
}

# Stage 4: Dedupe
Write-Log ""
Write-Log "[4/5] Deduplicating..."
py -3.14 "$Root\bin\dedupe.py" 2>&1 | ForEach-Object { Write-Log $_ }

# Stage 5: Shortlist
Write-Log ""
Write-Log "[5/5] Exporting shortlist..."
$shortlistCsv = Join-Path $Root "data\shortlist_${Timestamp}.csv"
py -3.14 "$Root\bin\shortlist.py" --min-score 9 --out $shortlistCsv 2>&1 | ForEach-Object { Write-Log $_ }

Write-Log ""
Write-Log "=== Pipeline complete ==="
Write-Log "Log:       $Log"
Write-Log "Shortlist: $shortlistCsv"

# Final stats
Write-Log ""
Write-Log "=== Corpus Stats ==="
py -3.14 "$Root\bin\stats.py" 2>&1 | ForEach-Object { Write-Log $_ }
