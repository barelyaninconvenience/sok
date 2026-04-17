#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-ProjectsReorg.ps1 — One-shot cleanup of Journal\Projects and scripts\ root clutter.
.DESCRIPTION
    Addresses specific observed issues as of 02Apr2026:
    1. scripts\Users\ ghost tree — PS transcripts mis-landed inside scripts dir
    2. scripts\ empty dirs (1, 5, Redundancy) — safe to remove
    3. scripts\ duplicate BareMetal versions — deprecate non-canonical
    4. Projects root duplicate SOK-Common files — canonical is scripts\common\
    5. Projects root SME legacy scripts — deprecated predecessors of SOK
    6. Projects root SOK session carry-over docs — move to SOK\Docs
    7. Projects root academic/data files — sort to existing subdirs
    8. scripts\ standalone utility scripts — inventory and sort

    All moves follow deprecate-never-delete. Nothing is deleted.
    DryRun by default — run -Apply to execute.

.PARAMETER Apply
    Execute moves. Default: DryRun (preview only).
.PARAMETER ScriptsRoot
    Path to scripts directory. Auto-detects from PSScriptRoot.
.PARAMETER ProjectsRoot
    Path to Projects directory. Auto-detects from ScriptsRoot parent.
.NOTES
    Author: S. Clay Caddell
    Version: 1.0.0
    Date: 02Apr2026
    Domain: Utility — one-shot Projects directory reorganization; not scheduled
    Run -DryRun (default) first, review, then run -Apply.
#>
[CmdletBinding()]
param(
    [switch]$Apply,   # Execute moves. Default is DryRun preview.
    [string]$ScriptsRoot,
    [string]$ProjectsRoot
)

$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) Write-Host "$ScriptName — $Subheader" }
}

if (-not $ScriptsRoot)  { $ScriptsRoot  = if ($PSScriptRoot) { $PSScriptRoot } else { 'C:\Users\shelc\Documents\Journal\Projects\scripts' } }
if (-not $ProjectsRoot) { $ProjectsRoot = Split-Path $ScriptsRoot -Parent }

$DryRun = -not $Apply.IsPresent
$ts     = Get-Date -Format 'yyyyMMdd_HHmmss'

Show-SOKBanner -ScriptName 'SOK-ProjectsReorg' -Subheader "$(if ($DryRun) { 'DRY RUN — preview only' } else { 'APPLY — executing moves' })"
Write-SOKLog "ScriptsRoot:  $ScriptsRoot" -Level Ignore
Write-SOKLog "ProjectsRoot: $ProjectsRoot" -Level Ignore
if ($DryRun) { Write-SOKLog 'Run with -Apply to execute. Nothing will be moved in this run.' -Level Warn }

$moved = 0; $skipped = 0; $failed = 0

# ── helpers ───────────────────────────────────────────────────────────────────

function Move-ToTarget {
    param([string]$Source, [string]$Dest, [string]$Label)
    if (-not (Test-Path $Source)) { Write-SOKLog "  NOT FOUND — skip: $Label" -Level Debug; $script:skipped++; return }
    if (Test-Path $Dest) {
        Write-SOKLog "  DEST EXISTS — skip (would collide): $Label → $Dest" -Level Warn; $script:skipped++; return
    }
    Write-SOKLog "  MOVE: $Label" -Level Ignore
    Write-SOKLog "    $Source" -Level Debug
    Write-SOKLog "    → $Dest" -Level Debug
    if (-not $DryRun) {
        $destParent = Split-Path $Dest -Parent
        if (-not (Test-Path $destParent)) { New-Item -Path $destParent -ItemType Directory -Force | Out-Null }
        try {
            Move-Item -Path $Source -Destination $Dest -Force -ErrorAction Stop
            Write-SOKLog "    OK" -Level Success; $script:moved++
        } catch {
            Write-SOKLog "    FAILED: $_" -Level Error; $script:failed++
        }
    } else { $script:moved++ }  # count as "would move" in dry run
}

function Remove-EmptyDir {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) { Write-SOKLog "  NOT FOUND — skip: $Label" -Level Debug; $script:skipped++; return }
    $children = Get-ChildItem $Path -Force -ErrorAction SilentlyContinue
    if ($children) { Write-SOKLog "  NOT EMPTY — skip: $Label ($($children.Count) items)" -Level Warn; $script:skipped++; return }
    Write-SOKLog "  REMOVE empty dir: $Label" -Level Ignore
    if (-not $DryRun) {
        try { Remove-Item $Path -Force -ErrorAction Stop; Write-SOKLog "    OK" -Level Success; $script:moved++ }
        catch { Write-SOKLog "    FAILED: $_" -Level Error; $script:failed++ }
    } else { $script:moved++ }
}

# ═══════════════════════════════════════════════════════════════
# ITEM 1: scripts\Users\ ghost PS transcript tree
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 1: scripts\Users\ ghost PS transcript tree' -Level Section

$ghostRoot    = Join-Path $ScriptsRoot 'Users'
$transcriptSrc = Join-Path $ghostRoot 'shelc\Documents\WindowsPowershell\Logs\PowerShellTranscripts'
$transcriptDst = Join-Path $env:USERPROFILE 'Documents\WindowsPowershell\Logs\PowerShellTranscripts'

if (Test-Path $transcriptSrc) {
    # Move each date folder individually to avoid overwriting if dst already exists
    $dateFolders = Get-ChildItem $transcriptSrc -Directory -ErrorAction SilentlyContinue
    foreach ($df in $dateFolders) {
        $dst = Join-Path $transcriptDst $df.Name
        if (Test-Path $dst) {
            # Merge: move individual files
            $txFiles = Get-ChildItem $df.FullName -File -ErrorAction SilentlyContinue
            foreach ($tf in $txFiles) {
                $dstFile = Join-Path $dst $tf.Name
                Move-ToTarget -Source $tf.FullName -Dest $dstFile -Label "Transcript: $($tf.Name)"
            }
        } else {
            Move-ToTarget -Source $df.FullName -Dest $dst -Label "Transcript dir: $($df.Name)"
        }
    }
}
# Deprecate the empty ghost tree after transcript extraction
$ghostDeprecated = Join-Path $ScriptsRoot "Deprecated\Users_ghost_$ts"
if (Test-Path $ghostRoot) {
    $remaining = Get-ChildItem $ghostRoot -Force -Recurse -ErrorAction SilentlyContinue
    if ($remaining) {
        Move-ToTarget -Source $ghostRoot -Dest $ghostDeprecated -Label 'scripts\Users ghost tree (residual)'
    } else {
        Remove-EmptyDir -Path $ghostRoot -Label 'scripts\Users ghost tree (empty after transcript extraction)'
    }
}

# ═══════════════════════════════════════════════════════════════
# ITEM 2: scripts\ empty directories (1, 5, Redundancy)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 2: scripts\ empty directories' -Level Section

Remove-EmptyDir -Path (Join-Path $ScriptsRoot '1')         -Label 'scripts\1'
Remove-EmptyDir -Path (Join-Path $ScriptsRoot '5')         -Label 'scripts\5'
Remove-EmptyDir -Path (Join-Path $ScriptsRoot 'Redundancy') -Label 'scripts\Redundancy'

# ═══════════════════════════════════════════════════════════════
# ITEM 3: scripts\ duplicate BareMetal versions
# Keep SOK-BareMetal.ps1 (canonical). Deprecate versioned copies.
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 3: scripts\ duplicate BareMetal versions' -Level Section

$bmVersions = @(
    'SOK-BareMetal_v5.1_Final.ps1'
    'SOK-BareMetal_v5.2.ps1'
    'SOK-BareMetal_v5.3.ps1'
    'SOK-BareMetal_v5_QA.ps1'
)
foreach ($bm in $bmVersions) {
    $src  = Join-Path $ScriptsRoot $bm
    $name = [System.IO.Path]::GetFileNameWithoutExtension($bm)
    $dst  = Join-Path $ScriptsRoot "Deprecated\${name}_$ts.ps1"
    Move-ToTarget -Source $src -Dest $dst -Label "Deprecated BareMetal: $bm"
}

# ═══════════════════════════════════════════════════════════════
# ITEM 4: Projects root duplicate SOK-Common files
# Canonical: scripts\common\SOK-Common.psm1
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 4: Projects root duplicate SOK-Common files' -Level Section

$projDeprDir = Join-Path $ProjectsRoot 'Deprecated'
foreach ($fname in @('SOK-Common.psm1', 'SOK-Common_1.psm1', 'SOK-Common_2.psm1')) {
    $src = Join-Path $ProjectsRoot $fname
    $dst = Join-Path $projDeprDir "${fname}_root_dup_$ts"
    Move-ToTarget -Source $src -Dest $dst -Label "Dup Common: $fname"
}

# ═══════════════════════════════════════════════════════════════
# ITEM 5: Projects root legacy SME scripts (SOK predecessors)
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 5: Projects root legacy SME scripts' -Level Section

foreach ($fname in @('SME_SysAdmin_Toolsuite_v3.ps1', 'SME_SysAdmin_v4_Reconciliation.ps1')) {
    $src = Join-Path $ProjectsRoot $fname
    $dst = Join-Path $projDeprDir "${fname}_$ts"
    Move-ToTarget -Source $src -Dest $dst -Label "Legacy SME: $fname"
}

# ═══════════════════════════════════════════════════════════════
# ITEM 6: SOK session carry-over and meta documents → SOK\Docs
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 6: SOK session documents → SOK\Docs' -Level Section

$sokDocsDir = Join-Path $ProjectsRoot 'SOK\Docs'
$sokDocs = @(
    'SOK-CarryOver-29Mar2026-v3.md'
    'SOK-CarryOver-Status.md'
    'SOK-CarryOver-Status_1.md'
    'SOK-CarryOver-Status_2.md'
    'SOK-CarryOver-Status_3.md'
    'SOK-MetaPrompt-v3.md'
)
# SOK-FamilyPicture.ps1 is a Gemini conversation transcript (design doc), not a script.
# It contains the CAS/monolith analysis and the SOK_OS_Master prototype (METICUL.OS genesis).
# Move to SOK\Docs as .md.
$familyPictureSrc = Join-Path $ScriptsRoot 'SOK-FamilyPicture.ps1'
$familyPictureDst = Join-Path $sokDocsDir 'SOK-FamilyPicture-GeminiTranscript.md'
Move-ToTarget -Source $familyPictureSrc -Dest $familyPictureDst -Label 'SOK-FamilyPicture.ps1 → SOK\Docs (design doc, not script)'
foreach ($fname in $sokDocs) {
    $src = Join-Path $ProjectsRoot $fname
    $dst = Join-Path $sokDocsDir $fname
    Move-ToTarget -Source $src -Dest $dst -Label "SOK doc: $fname"
}

# ═══════════════════════════════════════════════════════════════
# ITEM 7: Academic and thesis files → Learning\
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 7: Academic files → Learning\' -Level Section

$learningDir = Join-Path $ProjectsRoot 'Learning'
$academic = @(
    'IT Capstone ZTA 06AUG2025 Caddell.txt'
    'Management Control Systems.pdf'
    'ZTA_Thesis_Markdown.md'
    'ZTA_Thesis_Critical_Feedback.md'
)
foreach ($fname in $academic) {
    $src = Join-Path $ProjectsRoot $fname
    $dst = Join-Path $learningDir $fname
    Move-ToTarget -Source $src -Dest $dst -Label "Academic: $fname"
}

# ═══════════════════════════════════════════════════════════════
# ITEM 8: Data/snapshot files → _Data\ or Financial\
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 8: Data files → _Data\ / Financial\' -Level Section

$dataDir      = Join-Path $ProjectsRoot '_Data'
$financialDir = Join-Path $ProjectsRoot 'Financial'

# System snapshots → _Data\
$dataFiles = @(
    '20260323_SystemInfo.json'
    'system-info.txt'
)
foreach ($fname in $dataFiles) {
    $src = Join-Path $ProjectsRoot $fname
    $dst = Join-Path $dataDir $fname
    Move-ToTarget -Source $src -Dest $dst -Label "Data: $fname"
}

# Nasdaq screener exports → Financial\ (domain-correct; Financial\ already exists)
$nasdaqFiles = @(
    'nasdaq_screener_001-6666_202511211111.csv'
    'nasdaq_screener_1763741720887.csv'
)
foreach ($fname in $nasdaqFiles) {
    $src = Join-Path $ProjectsRoot $fname
    $dst = Join-Path $financialDir $fname
    Move-ToTarget -Source $src -Dest $dst -Label "Financial data: $fname"
}

# ═══════════════════════════════════════════════════════════════
# ITEM 9: Loose scripts in Projects root → scripts\utils\ or Deprecated
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 9: Loose root-level scripts' -Level Section

$utilsDir  = Join-Path $ScriptsRoot 'utils'
# scripts that are plausibly still useful
$utilScripts = @(
    @{ File = 'DMDE-TreeExpand.ps1';              Dest = $utilsDir }
    @{ File = 'explorer_config_optimized.ps1';    Dest = $utilsDir }
    @{ File = 'explorer_config_optimized.txt';    Dest = $utilsDir }
    @{ File = 'html_to_chrome.py';                Dest = $utilsDir }
    @{ File = 'down-right-1.ahk';                 Dest = $utilsDir }
)
foreach ($item in $utilScripts) {
    $src = Join-Path $ProjectsRoot $item.File
    $dst = Join-Path $item.Dest $item.File
    Move-ToTarget -Source $src -Dest $dst -Label "Util: $($item.File)"
}

# scripts in scripts\ root that should be deprecated
$scriptsToDepr = @(
    'Invoke-BackupRestructure.ps1'
    'Restructure-FlattenedFiles.ps1'
    'Move-FilesRecursively.ps1'
    'generate-ascii-art.py'
    'generate-ascii-art_1.py'
    'new5..aspx'
    'new5..cs'
    'new5..ps1'
)
foreach ($fname in $scriptsToDepr) {
    $src = Join-Path $ScriptsRoot $fname
    $name = [System.IO.Path]::GetFileNameWithoutExtension($fname)
    $ext  = [System.IO.Path]::GetExtension($fname)
    $dst  = Join-Path $ScriptsRoot "Deprecated\${name}_$ts${ext}"
    Move-ToTarget -Source $src -Dest $dst -Label "Deprecate script: $fname"
}

# ═══════════════════════════════════════════════════════════════
# ITEM 10: Projects root scratch/prompt files → Deprecated
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'ITEM 10: Scratch / prompt files → Deprecated' -Level Section

$rootScratch = @(
    'new 11.txt'
    'prompt & framework 2b.txt'
    'ai_condesed.txt'
    'claude-cli-latest.txt'
    'settings.json'
    'KLEM_Personal_OS_MetaPrompt.docx'
    'Project-Portfolio-Review.html'
)
foreach ($fname in $rootScratch) {
    $src  = Join-Path $ProjectsRoot $fname
    $name = [System.IO.Path]::GetFileNameWithoutExtension($fname)
    $ext  = [System.IO.Path]::GetExtension($fname)
    $dst  = Join-Path $projDeprDir "${name}_$ts${ext}"
    Move-ToTarget -Source $src -Dest $dst -Label "Scratch/prompt: $fname"
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'SUMMARY' -Level Section
Write-SOKLog "  Moved:   $moved" -Level $(if ($moved -gt 0) { 'Success' } else { 'Ignore' })
Write-SOKLog "  Skipped: $skipped" -Level Ignore
Write-SOKLog "  Failed:  $failed" -Level $(if ($failed -gt 0) { 'Error' } else { 'Success' })
Write-SOKLog "  DryRun:  $DryRun" -Level Ignore
if ($DryRun) {
    Write-SOKLog '' -Level Ignore
    Write-SOKLog 'Review the above, then run: .\SOK-ProjectsReorg.ps1 -Apply' -Level Warn
}
