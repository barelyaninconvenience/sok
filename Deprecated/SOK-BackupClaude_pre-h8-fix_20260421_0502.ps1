#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-BackupClaude.ps1 — Backup all irreplaceable Claude Code context to a local git repo.

.DESCRIPTION
    Copies memory files, agent definitions, settings, hooks, commands, CLAUDE.md,
    session transcripts, Abstract Oversight files, and state snapshots to a
    dedicated backup directory with git versioning.

    Designed for disaster recovery: if the Anthropic account is deleted or the
    machine is lost, this backup enables full reconstruction of the collaboration.

.PARAMETER DryRun
    Preview what would be backed up without copying or committing.

.PARAMETER BackupDir
    Target directory. Default: Projects\claude-backup

.NOTES
    Author: S. Clay Caddell
    Version: 1.0.0
    Date: 16Apr2026
    Domain: FUTURE — preserves Claude collaboration context for disaster recovery
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$BackupDir = "$env:USERPROFILE\Documents\Journal\Projects\claude-backup"
)

$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

# SYSTEM-context fix — remap $env:USERPROFILE, then re-evaluate $BackupDir since
# its param-default bound to the systemprofile path BEFORE this block runs.
# Without the re-eval, scheduled-task runs under SYSTEM would create a ghost
# backup tree under C:\Windows\System32\config\systemprofile\... on cold start.
if ($env:USERPROFILE -like '*systemprofile*') {
    $env:USERPROFILE  = 'C:\Users\shelc'
    $env:LOCALAPPDATA = 'C:\Users\shelc\AppData\Local'
    $env:APPDATA      = 'C:\Users\shelc\AppData\Roaming'
    if (-not $PSBoundParameters.ContainsKey('BackupDir')) {
        $BackupDir = "$env:USERPROFILE\Documents\Journal\Projects\claude-backup"
    }
}

$startTime = Get-Date
$copied = 0; $errors = 0

function Log { param([string]$Msg, [string]$Level = 'Ignore')
    if (Get-Command Write-SOKLog -ErrorAction SilentlyContinue) { Write-SOKLog $Msg -Level $Level }
    else { Write-Host "[$Level] $Msg" }
}

Log "SOK-BackupClaude — $(if ($DryRun) {'DRY RUN'} else {'LIVE'}) — Target: $BackupDir" -Level Section

# Define backup sources
$sources = @(
    # Memory files (canonical scope)
    @{ Source = "$env:USERPROFILE\.claude\projects\C--Users-shelc-Documents-Journal-Projects-scripts\memory"; Dest = 'memory'; Label = 'Memory files (canonical)' }
    @{ Source = "$env:USERPROFILE\.claude\projects\C--Windows-System32\memory"; Dest = 'memory-system32'; Label = 'Memory files (System32 scope)' }
    @{ Source = "$env:USERPROFILE\.claude\projects\C--Users-shelc\memory"; Dest = 'memory-home'; Label = 'Memory files (HOME scope)' }

    # Agent definitions
    @{ Source = "$env:USERPROFILE\.claude\agents"; Dest = 'agents'; Label = 'Agent definitions (25 agents)' }

    # Config
    @{ Source = "$env:USERPROFILE\.claude\CLAUDE.md"; Dest = 'config\CLAUDE.md'; Label = 'Global CLAUDE.md'; IsFile = $true }
    @{ Source = "$env:USERPROFILE\.claude\settings.json"; Dest = 'config\settings.json'; Label = 'Settings + hooks'; IsFile = $true }
    @{ Source = "$env:USERPROFILE\.claude\claude_desktop_config.json"; Dest = 'config\claude_desktop_config.json'; Label = 'Desktop config'; IsFile = $true }
    @{ Source = "$env:USERPROFILE\.claude\hooks"; Dest = 'config\hooks'; Label = 'Hook scripts' }
    @{ Source = "$env:USERPROFILE\.claude\commands"; Dest = 'config\commands'; Label = 'Custom commands/skills' }

    # Session records
    @{ Source = "$env:USERPROFILE\Documents\Journal\Projects\ML"; Dest = 'sessions\ML'; Label = 'Session transcripts' }
    @{ Source = "$env:USERPROFILE\Documents\Journal\Projects\Learning"; Dest = 'sessions\Learning'; Label = 'Abstract Oversight files' }

    # State
    @{ Source = "$env:USERPROFILE\Documents\Journal\Projects\Writings\State_Snapshot_Current.md"; Dest = 'state\State_Snapshot_Current.md'; Label = 'Current state snapshot'; IsFile = $true }

    # Writings (full corpus)
    @{ Source = "$env:USERPROFILE\Documents\Journal\Projects\Writings"; Dest = 'writings'; Label = 'Writings corpus (194+ files)' }

    # Project-scope CLAUDE.md files
    @{ Source = "$env:USERPROFILE\Documents\Journal\Projects\scripts\.claude"; Dest = 'config\project-scripts-claude'; Label = 'Scripts project CLAUDE.md + settings' }
)

# Ensure backup dir
if (-not $DryRun) {
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
        Log "Created backup dir: $BackupDir" -Level Success
    }
}

# Copy each source
foreach ($src in $sources) {
    $srcPath = $src.Source
    $destPath = Join-Path $BackupDir $src.Dest

    if (-not (Test-Path $srcPath)) {
        Log "  SKIP (not found): $($src.Label) — $srcPath" -Level Debug
        continue
    }

    if ($DryRun) {
        if ($src.IsFile) {
            $size = [math]::Round((Get-Item $srcPath).Length / 1KB, 1)
            Log "  [DRY] Would copy: $($src.Label) ($size KB)" -Level Debug
        } else {
            $count = (Get-ChildItem $srcPath -Recurse -File -ErrorAction SilentlyContinue).Count
            Log "  [DRY] Would copy: $($src.Label) ($count files)" -Level Debug
        }
        $copied++
        continue
    }

    try {
        if ($src.IsFile) {
            $destDir = Split-Path $destPath -Parent
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item $srcPath $destPath -Force
        } else {
            if (-not (Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }
            Copy-Item "$srcPath\*" $destPath -Recurse -Force -ErrorAction Continue
        }
        $copied++
        Log "  OK: $($src.Label)" -Level Success
    } catch {
        $errors++
        Log "  FAIL: $($src.Label) — $($_.Exception.Message)" -Level Error
    }
}

# Git commit (if not DryRun and git is available)
if (-not $DryRun -and (Get-Command git -ErrorAction SilentlyContinue)) {
    Push-Location $BackupDir
    try {
        if (-not (Test-Path '.git')) {
            git init 2>&1 | Out-Null
            Log "Initialized git repo in $BackupDir" -Level Success
        }
        git add -A 2>&1 | Out-Null
        $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        git commit -m "Claude context backup — $ts" --allow-empty 2>&1 | Out-Null
        Log "Git committed: $ts" -Level Success
    } catch {
        Log "Git error: $($_.Exception.Message)" -Level Warn
    } finally {
        Pop-Location
    }
}

$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
Log "Backup complete: $copied sources, $errors errors, ${duration}s" -Level $(if ($errors -gt 0) {'Warn'} else {'Success'})
