#Requires -Version 7.0
<#
.SYNOPSIS
    Migrate-PlaintextMCPCreds.ps1 — Scan MCP/Claude config files for plaintext
    credentials and scaffold the DPAPI + stdio-wrapper migration path.

.DESCRIPTION
    Honors CLAUDE.md §2 credential storage standard: "no credentials in
    .mcp.json, .claude.json, settings.json, script source, environment
    variables, or any committed file."

    Workflow this helper supports:
      1. SCAN — detect plaintext credential patterns in target config files.
         Reports finding LOCATION + KEY-NAME only. Never echoes credential VALUE.
      2. SCAFFOLD — for each finding, emit a per-MCP stdio launcher template
         under ~/.<mcp-name>-mcp/start-<mcp-name>-mcp.ps1 that retrieves the
         credential via Get-SOKSecret at runtime.
      3. SUGGEST — emit a JSON snippet showing what the config entry SHOULD
         look like after migration (replacing inline env-var values with the
         stdio launcher invocation). Snippet is written to a separate file —
         Clay applies it manually after rotating credentials.
      4. REPORT — write a complete migration plan to SOK\Logs\MCPCredMigration\
         with all findings, scaffolds, and the operator runbook.

    NEVER overwrites the source config files. NEVER zeros plaintext from source
    config files. NEVER displays credential values in any output channel.
    Migration is a Clay-driven 5-step process documented in the report:
      a. Rotate credential at upstream (e.g., dashboard.exa.ai → revoke old + new key)
      b. Set-SOKSecret -Name '<name>' -Plain '<new-value>' (Clay types interactively)
      c. Test stdio launcher: pwsh -File ~/.<mcp>-mcp/start-<mcp>-mcp.ps1 (smoke)
      d. Edit config: replace inline env block with stdio launcher invocation
      e. Verify by restarting Claude Code; remove old plaintext after confirmation

.PARAMETER ConfigPaths
    Path(s) to config files to scan. Default: ~/.mcp.json + ~/.claude.json

.PARAMETER ReportDir
    Directory to write the migration plan + scaffolds. Default:
    SOK\Logs\MCPCredMigration\<timestamp>\

.PARAMETER DryRun
    Default behavior. Scans + emits report, never modifies anything.

.PARAMETER GenerateScaffolds
    Emit stdio launcher PS1 templates per finding into the report dir.
    Off by default — opt-in to surface what would be generated.

.PARAMETER Apply
    Reserved for future use. Currently a no-op (this helper is intentionally
    READ-ONLY against source config files; "apply" would mean Clay running the
    runbook in the report). Including the param keeps the SOP signature alive
    for any future automation.

.NOTES
    Author:  S. Clay Caddell
    Version: 1.0.0
    Date:    2026-04-21
    Domain:  Security utility — credential surface remediation
    Pairs with: SOK-Secrets.psm1 (Get-SOKSecret/Set-SOKSecret/Remove-SOKSecret)

    Output:
      - <ReportDir>/migration-plan.md     — full operator runbook + findings
      - <ReportDir>/findings.jsonl        — machine-readable findings (no values)
      - <ReportDir>/scaffolds/<mcp>.ps1   — generated stdio launcher per finding
      - <ReportDir>/snippets/<mcp>.json   — suggested config snippet per finding
#>
[CmdletBinding()]
param(
    [string[]]$ConfigPaths = @(
        (Join-Path $env:USERPROFILE '.mcp.json'),
        (Join-Path $env:USERPROFILE '.claude.json')
    ),
    [string]$ReportDir,
    [switch]$DryRun,
    [switch]$GenerateScaffolds,
    [switch]$Apply
)

$ErrorActionPreference = 'Continue'

# Default DryRun ON unless caller explicitly opted out
if (-not $PSBoundParameters.ContainsKey('DryRun')) { $DryRun = $true }

# ── MODULE LOAD ──────────────────────────────────────────────────────────────
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) {
    $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1'
}
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore')
        Write-Host "[$Level] $Message"
    }
}

# ── REPORT DIR ───────────────────────────────────────────────────────────────
if (-not $ReportDir) {
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $ReportDir = Join-Path 'C:\Users\shelc\Documents\Journal\Projects\SOK\Logs\MCPCredMigration' $stamp
}
if (-not (Test-Path $ReportDir)) {
    New-Item -Path $ReportDir -ItemType Directory -Force | Out-Null
}
$scaffoldDir = Join-Path $ReportDir 'scaffolds'
$snippetDir  = Join-Path $ReportDir 'snippets'
if ($GenerateScaffolds) {
    foreach ($d in @($scaffoldDir, $snippetDir)) {
        if (-not (Test-Path $d)) { New-Item -Path $d -ItemType Directory -Force | Out-Null }
    }
}

Write-SOKLog "Migrate-PlaintextMCPCreds — DryRun=$DryRun — Report dir: $ReportDir" -Level Section

# ── DETECTION RULES ──────────────────────────────────────────────────────────
# Each rule returns @{ MatchPath; KeyName; ValueLength; Confidence; Reason }
# We never include the actual VALUE in any output — only metadata about it.

# Key-name patterns: env-var keys whose name strongly implies a secret
$secretKeyPatterns = @(
    '^[A-Z][A-Z0-9_]*_API_KEY$',
    '^[A-Z][A-Z0-9_]*_KEY$',
    '^[A-Z][A-Z0-9_]*_TOKEN$',
    '^[A-Z][A-Z0-9_]*_SECRET$',
    '^[A-Z][A-Z0-9_]*_PASSWORD$',
    '^[A-Z][A-Z0-9_]*_BEARER$',
    '^[A-Z][A-Z0-9_]*_OAUTH.*$',
    '^[A-Z][A-Z0-9_]*_PAT$',
    '^[Aa]pi[Kk]ey$',
    '^[Aa]piKey$',
    '^api[_-]?key$',
    '^token$',
    '^secret$',
    '^password$',
    '^bearer$',
    '^client[_-]?secret$',
    '^client_id$'
)

# URL credential patterns (e.g., ?api_key=... or ?exaApiKey=... in command args or URLs).
# v1.0.1 fix 2026-04-21: broadened to catch camelCase variants (exaApiKey, authToken,
# clientSecret, etc.) that Exa's MCP HTTP endpoint uses. Prior regex only matched
# snake_case and hyphenated names, which missed the Exa Priority-1 exposure.
$urlCredentialPattern = '(?:[?&](?:[a-zA-Z][a-zA-Z0-9]*(?:[Aa]pi[Kk]ey|[Aa]ccess[Tt]oken|[Aa]uth[Tt]oken|[Cc]lient[Ss]ecret|[Bb]earer|api[_-]?key|token|secret|password)|api[_-]?key|token|access[_-]?token|secret|password|bearer)=)([A-Za-z0-9_\-]{16,})'

# Generic high-entropy short string heuristic (bounded — do not mass-flag)
function Test-LooksLikeCredential {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    if ($Value.Length -lt 20)                  { return $false }   # too short
    if ($Value.Length -gt 4096)                { return $false }   # likely not a key
    # Excludes obvious non-secret strings:
    if ($Value -match '^[A-Z]:\\|^/|^https?://|^\$\{|^\$env:') { return $false }   # paths / vars / urls
    if ($Value -match '^\d{1,5}$') { return $false }                                  # ports / counts
    if ($Value -notmatch '[A-Za-z]') { return $false }                                # numeric only
    # Crude entropy check: mix of upper/lower/digit/symbol
    $hasUpper = $Value -cmatch '[A-Z]'
    $hasLower = $Value -cmatch '[a-z]'
    $hasDigit = $Value -cmatch '\d'
    $score = ([int]$hasUpper + [int]$hasLower + [int]$hasDigit)
    return ($score -ge 2)
}

# ── SCAN ─────────────────────────────────────────────────────────────────────
$findings = [System.Collections.Generic.List[hashtable]]::new()
function Add-Finding {
    param([string]$ConfigFile, [string]$Path, [string]$KeyName, [int]$ValueLength,
          [string]$Confidence, [string]$Reason, [string]$McpName)
    # ValueLength is the raw character count — useful operator hint without value
    $findings.Add(@{
        ConfigFile  = $ConfigFile
        Path        = $Path
        KeyName     = $KeyName
        ValueLength = $ValueLength
        Confidence  = $Confidence
        Reason      = $Reason
        McpName     = $McpName
    }) | Out-Null
}

# Recursive walker over a parsed JSON object (PSCustomObject / hashtable / array)
function Invoke-Walk {
    param(
        $Node,
        [string]$Path = '$',
        [string]$ConfigFile,
        [string]$ParentMcpName = ''
    )
    if ($null -eq $Node) { return }

    $type = $Node.GetType().FullName
    if ($type -match 'PSCustomObject|Hashtable|OrderedDictionary') {
        # Identify "we just descended into mcpServers.X" — capture X as the McpName.
        # v1.0.1 fix 2026-04-21: match .mcpServers.<anything> at the END of path
        # regardless of what came before. Prior regex required a single-segment
        # project path, which failed on .claude.json's Windows-style paths that
        # contain dots (e.g., "C--Users-shelc-..." or literal dots in subkeys).
        $mcpName = $ParentMcpName
        if ($Path -match '\.mcpServers\.([^\.\[]+)$') { $mcpName = $Matches[1] }

        $props = if ($Node -is [System.Collections.IDictionary]) { $Node.Keys } else { $Node.PSObject.Properties.Name }
        foreach ($k in $props) {
            $v = if ($Node -is [System.Collections.IDictionary]) { $Node[$k] } else { $Node.$k }
            $childPath = "$Path.$k"

            if ($v -is [string]) {
                # Rule 1: secret key name + non-empty value
                $matchedKeyRule = $false
                foreach ($pat in $secretKeyPatterns) {
                    if ($k -match $pat -and -not [string]::IsNullOrWhiteSpace($v)) {
                        Add-Finding -ConfigFile $ConfigFile -Path $childPath -KeyName $k `
                                    -ValueLength $v.Length -Confidence 'High' `
                                    -Reason "Key name matches secret pattern: $pat" -McpName $mcpName
                        $matchedKeyRule = $true
                        break
                    }
                }

                # Rule 2: URL-embedded credentials in args[] string
                if ($v -match $urlCredentialPattern) {
                    $credLen = $Matches[1].Length
                    Add-Finding -ConfigFile $ConfigFile -Path $childPath -KeyName "url-embedded:$k" `
                                -ValueLength $credLen -Confidence 'High' `
                                -Reason 'URL parameter looks like an embedded API key/token' `
                                -McpName $mcpName
                }

                # Rule 3: bearer-token-like value in any string field (low confidence)
                if (-not $matchedKeyRule -and (Test-LooksLikeCredential -Value $v) -and $childPath -match '(?i)(env|args|url|key|token|secret|password|auth|bearer)') {
                    Add-Finding -ConfigFile $ConfigFile -Path $childPath -KeyName $k `
                                -ValueLength $v.Length -Confidence 'Low' `
                                -Reason 'High-entropy string in security-context path' -McpName $mcpName
                }
            }
            elseif ($v -is [System.Collections.IEnumerable] -and -not ($v -is [string])) {
                $i = 0
                foreach ($item in $v) {
                    $arrPath = "$childPath[$i]"
                    if ($item -is [string]) {
                        if ($item -match $urlCredentialPattern) {
                            $credLen = $Matches[1].Length
                            Add-Finding -ConfigFile $ConfigFile -Path $arrPath -KeyName "url-embedded:$k[$i]" `
                                        -ValueLength $credLen -Confidence 'High' `
                                        -Reason 'URL parameter looks like an embedded API key/token in args[]' `
                                        -McpName $mcpName
                        }
                    } else {
                        Invoke-Walk -Node $item -Path $arrPath -ConfigFile $ConfigFile -ParentMcpName $mcpName
                    }
                    $i++
                }
            }
            else {
                Invoke-Walk -Node $v -Path $childPath -ConfigFile $ConfigFile -ParentMcpName $mcpName
            }
        }
    }
}

foreach ($cf in $ConfigPaths) {
    if (-not (Test-Path $cf)) {
        Write-SOKLog "  Config not found (skipping): $cf" -Level Debug
        continue
    }
    Write-SOKLog "  Scanning: $cf" -Level Annotate
    try {
        $parsed = Get-Content $cf -Raw | ConvertFrom-Json -Depth 32 -ErrorAction Stop
    } catch {
        Write-SOKLog "  Parse FAILED for $cf : $_" -Level Error
        continue
    }
    Invoke-Walk -Node $parsed -ConfigFile $cf
}

Write-SOKLog "Scan complete: $($findings.Count) findings across $($ConfigPaths.Count) config(s)" -Level Success

# ── SCAFFOLD GENERATION ──────────────────────────────────────────────────────
function New-StdioLauncher {
    param(
        [string]$McpName,
        [string[]]$RequiredSecretNames,
        [string]$Command,
        [string[]]$Args
    )
    $launcherDir  = "C:\Users\shelc\.${McpName}-mcp"
    $launcherFile = Join-Path $launcherDir "start-${McpName}-mcp.ps1"
    $envBlock = ($RequiredSecretNames | ForEach-Object {
        "`$env:$_ = Get-SOKSecret -Name '${_}'"
    }) -join "`n"
    $argLines = ($Args | ForEach-Object { "        '$_'" }) -join ",`n"

    $content = @"
#Requires -Version 7.0
<#
    Generated by Migrate-PlaintextMCPCreds.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss').

    Stdio launcher wrapper for MCP '${McpName}'.

    Replaces a plaintext credential entry in .mcp.json/.claude.json with a stdio
    pwsh -File invocation that retrieves credentials via DPAPI at launch time.

    Required DPAPI secrets (set via Set-SOKSecret -Name <name> -Plain <value>):
$(($RequiredSecretNames | ForEach-Object { "      - $_" }) -join "`n")

    Usage in config:
      "command": "pwsh",
      "args": ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$launcherFile"]

    Workflow:
      1. Rotate credential at the upstream provider (e.g., dashboard.exa.ai)
      2. Set-SOKSecret -Name '<name>' -Plain '<new-value>' for each required secret
      3. Smoke-test: pwsh -File '$launcherFile' (verify no immediate error)
      4. Update .mcp.json / .claude.json to use this launcher
      5. Restart Claude Code; verify MCP connects
      6. Zero the original plaintext value in the config file
#>

`$ErrorActionPreference = 'Stop'

# Import DPAPI credential helper
`$secretsModule = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1'
if (-not (Test-Path `$secretsModule)) {
    Write-Error "SOK-Secrets module not found at `$secretsModule — cannot retrieve credentials."
    exit 1
}
Import-Module `$secretsModule -Force

# Retrieve required credentials at launch
$envBlock

# Validate
foreach (`$req in @($(($RequiredSecretNames | ForEach-Object { "'$_'" }) -join ', '))) {
    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable(`$req))) {
        Write-Error "Required credential `$req not retrievable from DPAPI store. Run Set-SOKSecret -Name `$req -Plain '<value>' first."
        exit 1
    }
}

# Exec the underlying MCP server
& '$Command' @(
$argLines
)
"@
    return @{ Path = $launcherFile; Content = $content; Dir = $launcherDir }
}

# ── REPORT ───────────────────────────────────────────────────────────────────
$findingsByMcp = $findings | Group-Object { $_.McpName }
$report = [System.Collections.Generic.List[string]]::new()

$report.Add("# MCP Credential Migration Plan") | Out-Null
$report.Add("") | Out-Null
$report.Add("**Generated:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") | Out-Null
$report.Add("**Scanned configs:** $($ConfigPaths -join ', ')") | Out-Null
$report.Add("**Total findings:** $($findings.Count)") | Out-Null
$report.Add("**MCPs affected:** $($findingsByMcp.Count)") | Out-Null
$report.Add("") | Out-Null
$report.Add("---") | Out-Null
$report.Add("") | Out-Null

if ($findings.Count -eq 0) {
    $report.Add("## Result: NO FINDINGS") | Out-Null
    $report.Add("") | Out-Null
    $report.Add("No plaintext credential patterns detected. Either:") | Out-Null
    $report.Add("  - All credentials already migrated to DPAPI + stdio launchers") | Out-Null
    $report.Add("  - Detection rules need broadening (review " + '$secretKeyPatterns' + " in this script)") | Out-Null
    $report.Add("  - Configs use other secret-injection mechanisms (worth verifying)") | Out-Null
} else {
    $report.Add("## Findings (NO VALUES — metadata only)") | Out-Null
    $report.Add("") | Out-Null
    $report.Add("**Confidence levels:**") | Out-Null
    $report.Add("- **High** = pattern strongly indicates a credential (key-name match or URL credential parameter)") | Out-Null
    $report.Add("- **Low** = high-entropy string in a security-adjacent path; likely false-positive for account metadata (UUIDs, org names). Review before acting.") | Out-Null
    $report.Add("") | Out-Null
    $report.Add("| MCP | Config | JSONPath | KeyName | ValueLength | Confidence | Reason |") | Out-Null
    $report.Add("|-----|--------|----------|---------|-------------|------------|--------|") | Out-Null
    foreach ($f in $findings) {
        $cfShort = Split-Path $f.ConfigFile -Leaf
        $report.Add("| $($f.McpName) | $cfShort | $($f.Path) | $($f.KeyName) | $($f.ValueLength) | $($f.Confidence) | $($f.Reason) |") | Out-Null
    }
    $report.Add("") | Out-Null
    $report.Add("---") | Out-Null
    $report.Add("") | Out-Null

    $report.Add("## Per-MCP Migration Steps") | Out-Null
    $report.Add("") | Out-Null

    foreach ($g in $findingsByMcp) {
        # v1.0.1 fix 2026-04-21: use filesystem-safe placeholder for blank MCP names
        # (prior <top-level-or-non-mcp> had angle brackets which are invalid in
        # Windows filenames, causing New-Item + Set-Content failures during scaffold
        # emit).
        $mcp = if ([string]::IsNullOrWhiteSpace($g.Name)) { '__unattributed__' } else { $g.Name }
        # Sanitize: any character invalid in Windows filenames becomes underscore
        $mcp = ($mcp -replace '[\\/:*?"<>|]', '_')
        $report.Add("### $mcp") | Out-Null
        $report.Add("") | Out-Null
        $secretNames = @()
        foreach ($f in $g.Group) {
            # v1.0.1 fix 2026-04-21: generate clean DPAPI secret names even for URL-embedded
            # findings. Prior logic produced 'EXA_url-embedded:url' (colon invalid). New:
            #   - Strip 'url-embedded:' prefix if present
            #   - For MCP-scoped URL-embedded secrets, default to <MCP>_API_KEY
            #   - Sanitize to [A-Z0-9_] only
            $rawName = $f.KeyName -replace '^url-embedded:', ''
            if ([string]::IsNullOrWhiteSpace($rawName) -or $rawName -in @('url','uri','endpoint')) {
                $rawName = 'API_KEY'
            }
            $envName = ($rawName -replace '[^A-Za-z0-9]', '_').ToUpper().Trim('_')
            $secretName = if ($f.McpName) { "$(($f.McpName -replace '[^A-Za-z0-9]', '_').ToUpper())_$envName" } else { $envName }
            $secretName = ($secretName -replace '_{2,}', '_').Trim('_')
            $secretNames += $secretName
            $report.Add("- Path: ``$($f.Path)`` → DPAPI secret name: ``$secretName``") | Out-Null
        }
        $secretNames = $secretNames | Select-Object -Unique
        $report.Add("") | Out-Null
        $report.Add("**Operator runbook:**") | Out-Null
        $report.Add("") | Out-Null
        $report.Add('1. Rotate credential at upstream provider (revoke old key after new key is active).') | Out-Null
        $report.Add('2. Store new value(s) in DPAPI:') | Out-Null
        foreach ($sn in $secretNames) {
            $report.Add('   ```powershell') | Out-Null
            $report.Add("   Set-SOKSecret -Name '$sn' -Plain '<paste-rotated-value-here>'") | Out-Null
            $report.Add('   ```') | Out-Null
        }
        $report.Add("3. Smoke-test the stdio launcher (created at ``C:\Users\shelc\.${mcp}-mcp\start-${mcp}-mcp.ps1`` if -GenerateScaffolds was passed).") | Out-Null
        $report.Add("4. Update the relevant config file. Replace the inline ``env`` block with:") | Out-Null
        $report.Add('   ```json') | Out-Null
        $report.Add('   "command": "pwsh",') | Out-Null
        $report.Add("   `"args`": [`"-NoProfile`", `"-ExecutionPolicy`", `"Bypass`", `"-File`", `"C:\\\\Users\\\\shelc\\\\.${mcp}-mcp\\\\start-${mcp}-mcp.ps1`"]") | Out-Null
        $report.Add('   ```') | Out-Null
        $report.Add('5. Restart Claude Code; verify MCP connects (`/mcp` in CLI).') | Out-Null
        $report.Add('6. Zero the original plaintext value in the config file once new path verified.') | Out-Null
        $report.Add("") | Out-Null

        if ($GenerateScaffolds) {
            $launcher = New-StdioLauncher -McpName $mcp -RequiredSecretNames $secretNames `
                                          -Command 'TODO_SET_REAL_COMMAND' -Args @('TODO_SET_REAL_ARGS')
            if (-not (Test-Path $launcher.Dir)) { New-Item -Path $launcher.Dir -ItemType Directory -Force | Out-Null }
            $scaffoldOut = Join-Path $scaffoldDir "start-${mcp}-mcp.ps1"
            Set-Content -Path $scaffoldOut -Value $launcher.Content -Encoding utf8 -NoNewline
            $report.Add("Scaffold written: ``$scaffoldOut`` — Clay must update Command + Args before deployment.") | Out-Null
            $report.Add("") | Out-Null
        }
    }
}

# Findings JSONL (machine-readable, value-free)
$findingsJsonlPath = Join-Path $ReportDir 'findings.jsonl'
$sw = [System.IO.StreamWriter]::new($findingsJsonlPath, $false, [System.Text.Encoding]::UTF8)
foreach ($f in $findings) {
    $sw.WriteLine(($f | ConvertTo-Json -Compress -Depth 4))
}
$sw.Close()

$reportPath = Join-Path $ReportDir 'migration-plan.md'
Set-Content -Path $reportPath -Value ($report -join "`n") -Encoding utf8 -NoNewline

Write-SOKLog "Report written: $reportPath" -Level Success
Write-SOKLog "Findings JSONL: $findingsJsonlPath" -Level Success
if ($GenerateScaffolds) {
    Write-SOKLog "Scaffolds at: $scaffoldDir (review/edit Command + Args before deploying)" -Level Warn
}

if ($Apply) {
    Write-SOKLog '-Apply requested. This helper is read-only against source configs by design.' -Level Warn
    Write-SOKLog '   The migration is Clay-driven per the runbook in migration-plan.md.' -Level Warn
    Write-SOKLog '   No automatic config rewrite will occur.' -Level Warn
}

Write-SOKLog 'Migrate-PlaintextMCPCreds — DONE' -Level Section
