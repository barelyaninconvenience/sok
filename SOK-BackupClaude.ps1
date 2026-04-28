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
    [string]$BackupDir = "$env:USERPROFILE\Documents\Journal\Projects\claude-backup",
    # HIGH-3 fix 2026-04-22: pre-commit credential scan gate.
    # Default: abort git commit if a high-confidence credential pattern is detected
    # in any copied config file. Pass -SkipCredentialScan to bypass (NOT recommended;
    # only use when you've manually confirmed the copied configs are clean).
    [switch]$SkipCredentialScan
)

$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

# SYSTEM-context fix — remap $env:USERPROFILE, then re-evaluate $BackupDir since
# its param-default bound to the systemprofile path BEFORE this block runs.
# Without the re-eval, scheduled-task runs under SYSTEM would create a ghost
# backup tree under C:\Windows\System32\config\systemprofile\... on cold start.
# H-8 fix 2026-04-21: query Resolve-RealUserProfile (Substrate Thesis portability)
# instead of hardcoding 'C:\Users\shelc'. Bootstrap fallback preserves behavior on
# this machine; substrate-recovery on a differently-named account now works.
if ($env:USERPROFILE -like '*systemprofile*') {
    $realProfile = if (Get-Command Resolve-RealUserProfile -ErrorAction SilentlyContinue) {
        Resolve-RealUserProfile -Fallback 'C:\Users\shelc'
    } else { 'C:\Users\shelc' }
    $env:USERPROFILE  = $realProfile
    $env:LOCALAPPDATA = "$realProfile\AppData\Local"
    $env:APPDATA      = "$realProfile\AppData\Roaming"
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

# HIGH-3 fix 2026-04-22: pre-commit credential scan.
# Before git add/commit, scan key config files for credential patterns. If any
# match, ABORT the commit — the files stay on disk for operator inspection, but
# nothing enters permanent git history. Pass -SkipCredentialScan to bypass only
# after manual confirmation that the configs are clean.
function Test-ConfigCredentialLeak {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return @() }
    $findings = [System.Collections.Generic.List[string]]::new()
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
    } catch {
        return @()
    }
    # Key-name patterns — JSON field names that strongly imply a secret
    # with a non-empty, moderately-long value
    $patterns = @(
        # "apiKey": "..." / "api_key": "..." / "api-key": "..." etc.
        '"[a-zA-Z_]*[aA]pi[_-]?[Kk]ey"\s*:\s*"([^"]{16,})"',
        '"[a-zA-Z_]*[Tt]oken"\s*:\s*"([^"]{20,})"',
        '"[a-zA-Z_]*[Ss]ecret"\s*:\s*"([^"]{16,})"',
        '"[a-zA-Z_]*[Pp]assword"\s*:\s*"([^"]{8,})"',
        '"[a-zA-Z_]*[Bb]earer"\s*:\s*"([^"]{16,})"',
        # URL-embedded credentials (same family as Migrate-PlaintextMCPCreds detector)
        '[?&](?:[a-zA-Z]+[Aa]pi[Kk]ey|api[_-]?key|token|access[_-]?token|secret)=[A-Za-z0-9_\-]{16,}',
        # Private key markers — catastrophic if committed
        '-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----',
        # AWS-style access key (AKIA + 16 alphanumeric)
        '\bAKIA[0-9A-Z]{16}\b',
        # GitHub PAT (ghp_, gho_, ghu_, ghs_, ghr_ + 36 chars)
        '\bgh[pousr]_[A-Za-z0-9]{36,}\b'
    )
    foreach ($pat in $patterns) {
        $m = [regex]::Matches($content, $pat)
        if ($m.Count -gt 0) {
            # Report WITHOUT echoing the captured value
            $findings.Add("pattern: $pat | $($m.Count) match(es)") | Out-Null
        }
    }
    return $findings
}

$credentialLeakDetected = $false
if (-not $DryRun -and -not $SkipCredentialScan) {
    Log 'PRE-COMMIT CREDENTIAL SCAN' -Level Section
    $filesToScan = @(
        Join-Path $BackupDir 'config\settings.json'
        Join-Path $BackupDir 'config\claude_desktop_config.json'
        Join-Path $BackupDir 'config\CLAUDE.md'
    )
    # Include any JSON files under the project-scripts-claude subtree
    $projectClaudeDir = Join-Path $BackupDir 'config\project-scripts-claude'
    if (Test-Path $projectClaudeDir) {
        $filesToScan += (Get-ChildItem $projectClaudeDir -Recurse -File -Filter '*.json' -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
    }
    foreach ($f in $filesToScan) {
        if (-not (Test-Path $f)) { continue }
        $leaks = Test-ConfigCredentialLeak -FilePath $f
        if ($leaks.Count -gt 0) {
            $credentialLeakDetected = $true
            Log "  LEAK in $f :" -Level Error
            foreach ($l in $leaks) { Log "    - $l" -Level Error }
        } else {
            Log "  clean: $(Split-Path $f -Leaf)" -Level Debug
        }
    }
    if ($credentialLeakDetected) {
        Log "CREDENTIAL LEAK DETECTED. Git commit ABORTED — files remain on disk for inspection." -Level Error
        Log "  Remediation:" -Level Error
        Log "    1. Inspect the flagged file(s) and redact or move credentials to DPAPI" -Level Error
        Log "    2. Re-run SOK-BackupClaude to pick up redacted copies" -Level Error
        Log "    3. -SkipCredentialScan is available for false-positive bypass (not recommended)" -Level Error
    } else {
        Log 'No credential patterns detected — safe to commit' -Level Success
    }
}

# Git commit (if not DryRun, not credential-leaked, and git is available)
if (-not $DryRun -and -not $credentialLeakDetected -and (Get-Command git -ErrorAction SilentlyContinue)) {
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
