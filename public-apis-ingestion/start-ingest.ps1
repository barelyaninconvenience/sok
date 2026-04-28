#Requires -Version 7.0
<#
.SYNOPSIS
  Launcher for public-apis catalog ingestion + optional Supabase upload.

.DESCRIPTION
  Runs the Python ingestion tool against the public-apis/public-apis repo,
  parses the catalog, scores MCP candidacy, and emits output in the specified
  format (JSON / Parquet / SQL INSERT). If -UploadToSupabase is specified,
  additionally executes the SQL against Supabase via psql or Supabase CLI.

.PARAMETER Format
  Output format: json (default), parquet, or sql

.PARAMETER Output
  Output file path. Default: staged-apis.<ext>

.PARAMETER FetchFresh
  Re-download README even if cached

.PARAMETER UploadToSupabase
  After ingestion (requires -Format sql), upload to Supabase. Requires
  SUPABASE_URL + SUPABASE_DB_PASSWORD in DPAPI + psql on PATH.

.EXAMPLE
  .\start-ingest.ps1
  # Default: JSON output to staged-apis.json

.EXAMPLE
  .\start-ingest.ps1 -Format sql -Output staged-apis.sql -UploadToSupabase
  # SQL output, uploaded to Supabase

.NOTES
  Version 1.0.0 — 2026-04-21 — KLEM/OS v3 Part E implementation
#>

[CmdletBinding()]
param(
    [ValidateSet("json", "parquet", "sql")]
    [string]$Format = "json",

    [string]$Output = "",

    [switch]$FetchFresh,

    [switch]$UploadToSupabase
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pythonTool = Join-Path $scriptDir 'ingest-public-apis.py'

if (-not (Test-Path $pythonTool)) {
    Write-Error "Python tool not found at $pythonTool"
    exit 1
}

# Default output path based on format
if ([string]::IsNullOrWhiteSpace($Output)) {
    $ext = switch ($Format) {
        "json" { "json" }
        "parquet" { "parquet" }
        "sql" { "sql" }
    }
    $Output = Join-Path $scriptDir "staged-apis.$ext"
}

Write-Host "=== public-apis catalog ingestion ===" -ForegroundColor Cyan
Write-Host "  Format: $Format"
Write-Host "  Output: $Output"
Write-Host "  Fetch fresh: $FetchFresh"
Write-Host ""

$pythonArgs = @("--format", $Format, "--output", $Output)
if ($FetchFresh) {
    $pythonArgs += "--fetch-fresh"
}

& py -3 $pythonTool @pythonArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "Ingestion failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

if ($UploadToSupabase) {
    if ($Format -ne "sql") {
        Write-Warning "-UploadToSupabase requires -Format sql. Skipping upload."
        exit 0
    }

    $secretsModule = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
    Import-Module $secretsModule -Force

    $supaUrl = Get-SOKSecret -Name 'SUPABASE_URL'
    $supaDbPassword = Get-SOKSecret -Name 'SUPABASE_DB_PASSWORD'

    if (-not $supaUrl -or -not $supaDbPassword) {
        Write-Error "Supabase credentials not in DPAPI. Set SUPABASE_URL and SUPABASE_DB_PASSWORD first."
        exit 3
    }

    # Extract host from SUPABASE_URL for direct DB connection
    # Typical: https://<project>.supabase.co → db.<project>.supabase.co for direct postgres
    $projectRef = ($supaUrl -replace 'https?://', '' -replace '\.supabase\.co.*', '')
    $dbHost = "db.$projectRef.supabase.co"

    Write-Host "Uploading to Supabase at $dbHost..." -ForegroundColor Cyan

    $env:PGPASSWORD = $supaDbPassword
    & psql -h $dbHost -U postgres -d postgres -p 5432 -f $Output
    $uploadExit = $LASTEXITCODE
    $env:PGPASSWORD = $null
    $supaDbPassword = $null

    if ($uploadExit -eq 0) {
        Write-Host "Upload complete." -ForegroundColor Green
    } else {
        Write-Error "Upload failed with exit code $uploadExit"
        exit $uploadExit
    }
}
