#Requires -Version 7.0
<#
.SYNOPSIS
    Show-OvernightChanges.ps1 — Review tonight's SOK + MCP bridge + helper changes.

.DESCRIPTION
    Surfaces what was modified during the 2026-04-21/22 overnight autonomous
    session. Reads the Deprecated/ backup pairs, pairs each with its live
    sibling, reports parse-validation status, and prints concrete rollback
    commands. Non-destructive — read-only against the filesystem.

    Use cases:
    1. Pre-run audit: "what would be different from last week if I run SOK-PRESENT tonight?"
       → --category sok
    2. Security check: "what bridges got path-access/SQL/lifecycle hardening?"
       → --category mcp
    3. Rollback plan: "how do I revert just one file?"
       → Copy-paste the `Rollback:` line for the relevant row

.PARAMETER Category
    sok|mcp|helper|all  — filter to one category. Default: all.

.PARAMETER Since
    Date filter for Deprecated/ backups. Default: '20260421' (tonight's work).
    To see all historical pre-edit backups: 'all' or the earliest ISO-prefix.

.PARAMETER ShowRollback
    Include rollback Copy-Item command on each row (default true; pass -ShowRollback:$false to suppress).

.PARAMETER ValidateParse
    Parse-validate each LIVE file via [Parser]::ParseFile. Default true.
    Emits PARSE OK/FAIL alongside each row.

.EXAMPLE
    .\Show-OvernightChanges.ps1
    # Full report across SOK, MCP bridges, helpers

.EXAMPLE
    .\Show-OvernightChanges.ps1 -Category mcp
    # Just the custom-MCP Python bridges + their launchers

.EXAMPLE
    .\Show-OvernightChanges.ps1 -Category sok -ValidateParse:$false
    # Fast SOK-only list without parse checks

.NOTES
    Author:  S. Clay Caddell
    Version: 1.0.0
    Date:    2026-04-22
    Domain:  Review utility — post-overnight-session audit aid
    Pairs with: Writings/State_Snapshot_Current.md Addenda 23 + extensions
#>
[CmdletBinding()]
param(
    [ValidateSet('sok','mcp','helper','all')]
    [string]$Category = 'all',
    [string]$Since = '20260421',
    [bool]$ShowRollback = $true,
    [bool]$ValidateParse = $true,
    [string]$ScriptsRoot = 'C:\Users\shelc\Documents\Journal\Projects\scripts'
)

$ErrorActionPreference = 'Continue'

$deprDir = Join-Path $ScriptsRoot 'Deprecated'
if (-not (Test-Path $deprDir)) {
    Write-Host "[ERROR] No Deprecated/ dir at $deprDir" -ForegroundColor Red
    exit 1
}

# ── Collect backups matching date filter ────────────────────────────────────
$pattern = if ($Since -eq 'all') { '*_pre-*_*.ps1','*_pre-*_*.psm1','*_pre-*_*.py' } else { "*_pre-*_${Since}*.ps1","*_pre-*_${Since}*.psm1","*_pre-*_${Since}*.py" }
$backups = foreach ($pat in $pattern) { Get-ChildItem $deprDir -Filter $pat -File -ErrorAction SilentlyContinue }
$backups = $backups | Sort-Object Name -Unique

if (-not $backups -or $backups.Count -eq 0) {
    Write-Host "[INFO] No Deprecated/ backups matching *_pre-*_${Since}* — nothing to show." -ForegroundColor Yellow
    exit 0
}

# Parse each backup filename into (LiveName, FixTag, Timestamp)
# Naming convention: <LiveBaseName>_pre-<FixTag>_<YYYYMMDD>_<HHMM>.<ext>
# Example:           SOK-METICUL.OS_pre-c1c2-fix_20260421_0430.ps1
$rxBackup = '^(?<base>.+?)_pre-(?<tag>[^_]+(?:_fix)?)_(?<ts>\d{8}_\d{4,6})\.(?<ext>ps1|psm1|py)$'
$parsed = foreach ($b in $backups) {
    if ($b.Name -match $rxBackup) {
        [PSCustomObject]@{
            BackupPath = $b.FullName
            BackupName = $b.Name
            LiveBase   = $Matches['base']
            FixTag     = $Matches['tag']
            Timestamp  = $Matches['ts']
            Ext        = $Matches['ext']
            SizeKB     = [math]::Round($b.Length / 1KB, 1)
        }
    }
}

# Some backups in custom-mcps land flat in Deprecated/ with prefix patterns —
# include them too.
$mcpBackupPatterns = @('exa_mcp_*','supabase_mcp_*','ollama_mcp_*','unstructured_mcp_*','n8n_control_*','gamma_mcp_*')
$mcpBackups = foreach ($pat in $mcpBackupPatterns) {
    Get-ChildItem $deprDir -Filter "$pat${Since}*.py" -File -ErrorAction SilentlyContinue
    Get-ChildItem $deprDir -Filter "$pat*.py" -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match $Since }
}
$mcpBackups = $mcpBackups | Sort-Object Name -Unique

# ── Categorize ───────────────────────────────────────────────────────────────
function Get-Category {
    param([string]$liveBase, [string]$path)
    if ($path -match 'custom-mcps' -or $liveBase -match 'mcp') { return 'mcp' }
    if ($liveBase -match '^SOK-' -or $liveBase -match '^SOK_') { return 'sok' }
    if ($liveBase -match '^Migrate-|^Invoke-|^Update-|^Install-|^Configure-|^Show-|^deploy-|^add-custom|^start-') { return 'helper' }
    return 'helper'  # default fallback
}

# ── Resolve live file path ───────────────────────────────────────────────────
function Find-LivePath {
    param([string]$LiveBase, [string]$Ext)
    $candidates = @(
        Join-Path $ScriptsRoot "$LiveBase.$Ext"
        Join-Path (Join-Path $ScriptsRoot 'common') "$LiveBase.$Ext"
    )
    # Custom MCP bridge paths (the backup name uses underscores; live uses dashes)
    $mcpName = ($LiveBase -replace '_', '-') -replace '^([a-z]+)-mcp-main$', '$1-mcp'
    $candidates += Join-Path $ScriptsRoot "custom-mcps\$mcpName\$($mcpName -replace '-','_')_server\__main__.py"
    $candidates += Join-Path $ScriptsRoot "custom-mcps\$mcpName\$($mcpName -replace '-','_')_bridge\__main__.py"
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    return $null
}

# ── Parse-validate ──────────────────────────────────────────────────────────
function Test-ParseFile {
    param([string]$Path)
    if (-not $Path -or -not (Test-Path $Path)) { return 'MISSING' }
    if ($Path -match '\.py$') {
        $r = py -c "import ast; ast.parse(open(r'$Path', encoding='utf-8').read())" 2>&1
        if ($LASTEXITCODE -eq 0) { return 'OK' } else { return 'FAIL' }
    } else {
        $errs = $null
        try {
            $null = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$errs)
            if ($errs -and $errs.Count -gt 0) { return 'FAIL' } else { return 'OK' }
        } catch {
            return 'FAIL'
        }
    }
}

# ── Present ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══ Overnight Changes Review — $Since → now ═══" -ForegroundColor Cyan
Write-Host "  Backup dir:  $deprDir"
Write-Host "  Category:    $Category"
Write-Host "  Parse check: $ValidateParse"
Write-Host ""

$byCategory = @{ sok = @(); mcp = @(); helper = @() }
foreach ($p in $parsed) {
    $livePath = Find-LivePath -LiveBase $p.LiveBase -Ext $p.Ext
    $cat = Get-Category -liveBase $p.LiveBase -path $livePath
    $parseStatus = if ($ValidateParse) { Test-ParseFile -Path $livePath } else { '—' }
    $row = [PSCustomObject]@{
        LiveBase   = $p.LiveBase
        FixTag     = $p.FixTag
        Timestamp  = $p.Timestamp
        LivePath   = $livePath
        BackupPath = $p.BackupPath
        ParseStatus= $parseStatus
        SizeKB     = $p.SizeKB
    }
    $byCategory[$cat] += $row
}

# Also include MCP python backups (separate naming convention)
foreach ($mb in $mcpBackups) {
    if ($mb.Name -match '^(?<prefix>[a-z_]+)_mcp_(main|bridge)_pre-(?<tag>[^_]+)_(?<ts>\d{8}_\d{4,6})\.py$') {
        $mcpShortName = ($Matches['prefix'] -replace '_','-') + '-mcp'
        $livePath = Find-LivePath -LiveBase "${mcpShortName}-main" -Ext 'py'
        # Fallback: direct path construction
        if (-not $livePath) {
            $livePath = Join-Path $ScriptsRoot "custom-mcps\$mcpShortName\$($Matches['prefix'])_mcp_server\__main__.py"
            if (-not (Test-Path $livePath)) {
                $livePath = Join-Path $ScriptsRoot "custom-mcps\$mcpShortName\$($Matches['prefix'])_mcp_bridge\__main__.py"
            }
        }
        $parseStatus = if ($ValidateParse -and $livePath -and (Test-Path $livePath)) { Test-ParseFile -Path $livePath } else { '—' }
        $row = [PSCustomObject]@{
            LiveBase   = "$mcpShortName (bridge)"
            FixTag     = $Matches['tag']
            Timestamp  = $Matches['ts']
            LivePath   = $livePath
            BackupPath = $mb.FullName
            ParseStatus= $parseStatus
            SizeKB     = [math]::Round($mb.Length / 1KB, 1)
        }
        $byCategory.mcp += $row
    }
}

function Write-Section {
    param([string]$Title, [array]$Rows, [string]$Color)
    if ($Rows.Count -eq 0) { return }
    Write-Host ""
    Write-Host "── $Title ($($Rows.Count) changes) ──" -ForegroundColor $Color
    foreach ($r in ($Rows | Sort-Object Timestamp, LiveBase)) {
        $parseColor = switch ($r.ParseStatus) {
            'OK'      { 'Green' }
            'FAIL'    { 'Red' }
            'MISSING' { 'Yellow' }
            default   { 'Gray' }
        }
        Write-Host ("  [{0,-8}] " -f $r.Timestamp) -NoNewline -ForegroundColor DarkGray
        Write-Host ("{0,-45}" -f $r.LiveBase) -NoNewline -ForegroundColor White
        Write-Host ("  {0,-28}" -f $r.FixTag) -NoNewline -ForegroundColor Cyan
        Write-Host ("  parse:{0,-8}" -f $r.ParseStatus) -ForegroundColor $parseColor
        if ($r.LivePath) {
            Write-Host ("              live:     {0}" -f $r.LivePath) -ForegroundColor DarkGray
        } else {
            Write-Host ("              live:     <no matching live file found>") -ForegroundColor Yellow
        }
        Write-Host ("              backup:   {0}" -f $r.BackupPath) -ForegroundColor DarkGray
        if ($ShowRollback -and $r.LivePath) {
            Write-Host ("              rollback: Copy-Item '{0}' '{1}' -Force" -f $r.BackupPath, $r.LivePath) -ForegroundColor DarkYellow
        }
        Write-Host ""
    }
}

if ($Category -in 'sok','all')    { Write-Section -Title 'SOK scripts + foundational modules'      -Rows $byCategory.sok    -Color Magenta }
if ($Category -in 'mcp','all')    { Write-Section -Title 'Custom MCP bridges + launchers'          -Rows $byCategory.mcp    -Color Blue }
if ($Category -in 'helper','all') { Write-Section -Title 'Utility scripts (new + modified helpers)' -Rows $byCategory.helper -Color Cyan }

# ── Summary ──────────────────────────────────────────────────────────────────
$total = $byCategory.sok.Count + $byCategory.mcp.Count + $byCategory.helper.Count
$okCount = 0; $failCount = 0; $missCount = 0
foreach ($cat in 'sok','mcp','helper') {
    foreach ($r in $byCategory[$cat]) {
        switch ($r.ParseStatus) {
            'OK'      { $okCount++ }
            'FAIL'    { $failCount++ }
            'MISSING' { $missCount++ }
        }
    }
}

Write-Host ""
Write-Host "── Summary ──" -ForegroundColor Cyan
Write-Host "  Total changes shown: $total"
Write-Host "  Parse OK:            $okCount" -ForegroundColor Green
if ($failCount -gt 0) { Write-Host "  Parse FAIL:          $failCount" -ForegroundColor Red }
if ($missCount -gt 0) { Write-Host "  Live file MISSING:   $missCount" -ForegroundColor Yellow }
Write-Host ""
Write-Host "Next step suggestions:" -ForegroundColor Cyan
Write-Host "  1. DryRun any SOK script you plan to invoke tonight (e.g., SOK-PRESENT.ps1 -DryRun -ProcessMode Balanced)"
Write-Host "  2. For custom-MCP hardening, no nightly impact — only affects live MCP sessions post-deployment"
Write-Host "  3. Rollback any individual change via the 'rollback:' Copy-Item line above"
Write-Host ""
