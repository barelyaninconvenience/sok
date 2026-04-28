# Reformat-UCMSIS-Docx.ps1
# ========================
# Reformats .docx files under C:\Users\shelc\Documents\UC MS-IS\ to the explicit
# standard Clay established 2026-04-26.
#
# Uses Word COM automation (handles OneDrive sync natively, unlike python-docx).
#
# Standard:
#   - Arial 11pt, black, no bold (italic preserved)
#   - Line spacing 1.15, no space before/after, no first-line indent
#   - Replace em-dash, en-dash, smart quotes, ellipsis, NBSP with ASCII 0-127
#   - Preserve alignment, headers/footers, structure
#
# Skip rules: ~$* (Word lock files), _Archive_*, Deprecated/, the template itself,
#             files where ~$<name>.docx exists (already open in Word).
#
# Backup: relies on OneDrive's built-in version history per Clay 2026-04-26 directive.
#
# Usage:
#   pwsh -File Reformat-UCMSIS-Docx.ps1 -DryRun                 # preview
#   pwsh -File Reformat-UCMSIS-Docx.ps1                          # apply
#   pwsh -File Reformat-UCMSIS-Docx.ps1 -SingleFile <path>       # one file

param(
    [switch]$DryRun,
    [string]$SingleFile = $null,
    [int]$Limit = 0
)

$ErrorActionPreference = 'Stop'
$Root = "C:\Users\shelc\Documents\UC MS-IS"

# Word constants
$wdReplaceAll = 2
$wdFindContinue = 1
$wdLineSpaceMultiple = 5
$wdAlignParagraphLeft = 0

# Character replacements (non-ASCII to ASCII)
$Replacements = @(
    @{ Find = [char]0x2014; Replace = ' - ' },     # em dash
    @{ Find = [char]0x2013; Replace = '-' },        # en dash
    @{ Find = [char]0x2212; Replace = '-' },        # minus
    @{ Find = [char]0x201C; Replace = '"' },        # left double quote
    @{ Find = [char]0x201D; Replace = '"' },        # right double quote
    @{ Find = [char]0x2018; Replace = "'" },        # left single quote
    @{ Find = [char]0x2019; Replace = "'" },        # right single quote
    @{ Find = [char]0x2026; Replace = '...' },      # ellipsis
    @{ Find = [char]0x00A0; Replace = ' ' },        # non-breaking space
    @{ Find = [char]0x2022; Replace = '-' },        # bullet
    @{ Find = [char]0x2023; Replace = '-' },        # triangle bullet
    @{ Find = [char]0x25E6; Replace = '-' },        # white bullet
    @{ Find = [char]0x2043; Replace = '-' },        # hyphen bullet
    @{ Find = [char]0x2192; Replace = '->' },       # right arrow
    @{ Find = [char]0x2190; Replace = '<-' },       # left arrow
    @{ Find = [char]0x2194; Replace = '<->' },      # both arrows
    @{ Find = [char]0x2248; Replace = '~' },        # approximately
    @{ Find = [char]0x2260; Replace = '!=' },       # not equal
    @{ Find = [char]0x2264; Replace = '<=' },       # leq
    @{ Find = [char]0x2265; Replace = '>=' },       # geq
    @{ Find = [char]0x00D7; Replace = 'x' },        # mult
    @{ Find = [char]0x00B1; Replace = '+/-' },      # plus-minus
    @{ Find = [char]0x00B0; Replace = ' deg ' },    # degree
    @{ Find = [char]0x00A9; Replace = '(c)' },
    @{ Find = [char]0x00AE; Replace = '(R)' },
    @{ Find = [char]0x2122; Replace = '(TM)' }
)

function Test-SkipPath {
    param([System.IO.FileInfo]$File)
    $name = $File.Name
    $full = $File.FullName
    if ($name.StartsWith('~$')) { return 'word-lock' }
    if ($full -match '\\_Archive_') { return 'archive' }
    if ($full -match '\\Deprecated\\') { return 'deprecated' }
    if ($name -eq 'UC MS-IS Word Template.docx') { return 'template-itself' }
    # Check for Word lock file
    $lockPath = Join-Path $File.Directory.FullName ("~`$" + $name)
    if (Test-Path $lockPath) { return 'open-in-word' }
    return $null
}

function Reformat-Document {
    param(
        $Word,
        [string]$FilePath,
        [bool]$Apply
    )

    $stats = @{
        chars_replaced = 0
        ran_full_format = $false
        error = $null
    }

    try {
        $doc = $Word.Documents.Open($FilePath, $false, $true)  # ReadOnly=$true initially? No, we need write
        # Actually open writable
        $doc.Close($false)  # Close read-only attempt
        $doc = $Word.Documents.Open($FilePath)

        # 1. Character replacements via Find/Replace
        $find = $doc.Content.Find
        $find.ClearFormatting()
        $find.Replacement.ClearFormatting()
        foreach ($r in $Replacements) {
            $found = $find.Execute(
                [string]$r.Find,    # FindText
                $false,             # MatchCase
                $false,             # MatchWholeWord
                $false,             # MatchWildcards
                $false,             # MatchSoundsLike
                $false,             # MatchAllWordForms
                $true,              # Forward
                $wdFindContinue,    # Wrap
                $false,             # Format
                [string]$r.Replace, # ReplaceWith
                $wdReplaceAll       # Replace
            )
            if ($found) {
                $stats.chars_replaced++
            }
        }

        # 2. Apply font/color/size/bold to entire document
        $allRange = $doc.Content
        $allRange.Font.Name = 'Arial'
        $allRange.Font.Size = 11
        $allRange.Font.Color = 0       # wdColorAutomatic = 0; Black = 0 RGB
        $allRange.Font.Bold = $false
        $allRange.Font.ColorIndex = 1  # Black

        # 3. Apply paragraph format (preserve alignment)
        # Iterate paragraphs to preserve alignment but set spacing/indent
        $paragraphs = $doc.Paragraphs
        $count = $paragraphs.Count
        for ($i = 1; $i -le $count; $i++) {
            $p = $paragraphs.Item($i)
            $pf = $p.Format
            $pf.LineSpacingRule = $wdLineSpaceMultiple
            $pf.LineSpacing = 13.8  # 1.15 * 12pt = 13.8 points (Word default base)
            $pf.SpaceBefore = 0
            $pf.SpaceAfter = 0
            $pf.FirstLineIndent = 0
            # Preserve LeftIndent only if part of a list (heuristic)
            # Otherwise zero it
            if ($pf.OutlineLevel -eq 10) {  # Body Text level (not heading)
                $pf.LeftIndent = 0
            }
        }

        # 4. Tables: apply same to all cells
        $tables = $doc.Tables
        $tableCount = $tables.Count
        for ($t = 1; $t -le $tableCount; $t++) {
            $table = $tables.Item($t)
            $table.Range.Font.Name = 'Arial'
            $table.Range.Font.Size = 11
            $table.Range.Font.ColorIndex = 1
            $table.Range.Font.Bold = $false
        }

        $stats.ran_full_format = $true

        # 5. Save (only if applying)
        if ($Apply) {
            $doc.Save()
        }
        $doc.Close($false)  # Don't re-save on close
    } catch {
        $stats.error = $_.Exception.Message
        try { $doc.Close($false) } catch {}
    }

    return $stats
}

# === Main ===
Write-Output "Mode: $(if ($DryRun) { 'DRYRUN' } else { 'APPLY' })"

if ($SingleFile) {
    $files = @(Get-Item $SingleFile)
} else {
    $files = Get-ChildItem -Path $Root -Recurse -Filter "*.docx" -File -ErrorAction SilentlyContinue
    if ($Limit -gt 0) {
        $files = $files | Select-Object -First $Limit
    }
}

Write-Output "Files in scope: $($files.Count)"
Write-Output "Standard: Arial 11pt, black, line-spacing 1.15, ASCII 0-127, no bold"
Write-Output ("=" * 80)

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0

$results = @()
$idx = 0
foreach ($file in $files) {
    $idx++
    $skipReason = Test-SkipPath -File $file
    if ($skipReason) {
        Write-Output "[$idx/$($files.Count)] SKIP ($skipReason): $($file.Name)"
        $results += @{ Name = $file.Name; Skipped = $true; SkipReason = $skipReason }
        continue
    }

    try {
        $stats = Reformat-Document -Word $word -FilePath $file.FullName -Apply (-not $DryRun)
        if ($stats.error) {
            Write-Output "[$idx/$($files.Count)] ERROR: $($file.Name) -- $($stats.error)"
            $results += @{ Name = $file.Name; Error = $stats.error }
        } else {
            $tag = if ($DryRun) { 'PREVIEW' } else { 'APPLIED' }
            Write-Output "[$idx/$($files.Count)] $tag : $($file.Name)"
            $results += @{ Name = $file.Name; Applied = (-not $DryRun); Stats = $stats }
        }
    } catch {
        Write-Output "[$idx/$($files.Count)] EXCEPTION: $($file.Name) -- $($_.Exception.Message)"
        $results += @{ Name = $file.Name; Error = $_.Exception.Message }
    }
}

# Cleanup
$word.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()

Write-Output ("=" * 80)
$total = $results.Count
$skipped = ($results | Where-Object { $_.Skipped -eq $true }).Count
$errored = ($results | Where-Object { $_.Error }).Count
$applied = ($results | Where-Object { $_.Applied -eq $true }).Count
Write-Output "SUMMARY: Total=$total Skipped=$skipped Errored=$errored Applied=$applied"
