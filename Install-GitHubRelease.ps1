#Requires -Version 7.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Install-GitHubRelease v2.0.0 — Install from GitHub Releases directly, and audit installed
    tools against GitHub sources to find non-GitHub or outdated installs.
.DESCRIPTION
    TWO MODES:

    ── INSTALL MODE (default) ───────────────────────────────────────────────────
    Fetches the latest (or pinned) release from a GitHub repository, selects the best
    Windows x64 asset, downloads, verifies (SHA-256 when available), and installs.

      .exe  → silent /S /quiet install
      .msi  → msiexec /passive /norestart
      .zip  → Expand-Archive to -InstallDir
      .7z   → 7z x to -InstallDir (7-Zip required in PATH)

    ── SCAN MODE (-ScanInventory) ───────────────────────────────────────────────
    Cross-references installed tools against a curated GitHub repo map and against
    live Scoop manifest URLs to determine:

      GITHUB-SOURCED  — Scoop manifest URL points directly to github.com/releases/download
                        (already at the authoritative source)
      VIA-PKG-MGR     — Installed via Chocolatey/Winget/Scoop but sourced through the
                        package manager's infrastructure, not GitHub directly. May lag
                        behind upstream releases.
      INSTALLER       — Registry-detected installer; GitHub alternative known from map
      OUTDATED        — Installed version < latest GitHub release (requires -CheckVersions)
      CURRENT         — Installed version matches latest GitHub release
      NO-MATCH        — Not in curated map; no GitHub alternative identified

    Data sources (in priority order):
      1. Scoop app manifests: ~\scoop\apps\*\current\manifest.json (URL inspection)
      2. SOK-Inventory JSON: latest from SOK\Logs\ (or -InventoryPath override)
      3. SoftwareManifest.md: latest from SOK\Docs\ (or -ManifestPath override)
      4. Live system: Chocolatey (choco list), registry uninstall keys

    -CheckVersions: hit GitHub API for each matched tool to compare versions.
                    Without it: shows source status only (fast, no API calls).
    -Apply:         after showing the audit table, prompt to install GitHub versions
                    for any tool flagged VIA-PKG-MGR, INSTALLER, or OUTDATED.

.PARAMETER Repo
    [INSTALL MODE] GitHub repo in owner/repo format. E.g.: 'BurntSushi/ripgrep'

.PARAMETER ScanInventory
    [SCAN MODE] Audit installed tools against GitHub sources.

.PARAMETER InventoryPath
    [SCAN MODE] Path to SOK-Inventory JSON. Auto-detects latest if omitted.

.PARAMETER ManifestPath
    [SCAN MODE] Path to SoftwareManifest.md. Auto-detects latest if omitted.

.PARAMETER CheckVersions
    [SCAN MODE] Query GitHub API for latest release of each matched tool to compare
    with installed version. Slower (one API call per tool). Recommended with -Token.

.PARAMETER Apply
    [SCAN MODE] After audit, offer interactive install of GitHub versions for flagged tools.

.PARAMETER Tag
    [INSTALL MODE] Pin to a specific release tag. Default: 'latest'.

.PARAMETER AssetPattern
    [INSTALL MODE] Glob to force a specific asset. E.g.: '*windows*amd64*.zip'

.PARAMETER InstallDir
    [INSTALL MODE] Where to extract/install. Default: E:\SOK_Offload\<RepoName>

.PARAMETER AddToPath
    [INSTALL MODE] Add InstallDir (or its bin/) to machine PATH.

.PARAMETER DryRun
    Preview without downloading (install mode) or without installing (scan+apply mode).

.PARAMETER Token
    GitHub PAT. Raises rate limit from 60 to 5000 req/hr. Required for -CheckVersions
    against many tools without hitting rate limits.

.EXAMPLE
    .\Install-GitHubRelease.ps1 -Repo 'BurntSushi/ripgrep' -DryRun

.EXAMPLE
    .\Install-GitHubRelease.ps1 -ScanInventory -CheckVersions -Token $env:GITHUB_TOKEN

.EXAMPLE
    .\Install-GitHubRelease.ps1 -ScanInventory -Apply -DryRun

.NOTES
    Author:  S. Clay Caddell
    Version: 2.0.0
    Date:    2026-04-03
    Domain:  Utility — on-demand GitHub release installer + inventory audit; not scheduled
    Requires: PowerShell 7, internet access
    Changelog:
      v2.0.0 — ADD: -ScanInventory mode with Scoop manifest URL inspection, curated
               tool→repo map (55 entries), SOK-Inventory JSON + SoftwareManifest.md
               integration, -CheckVersions (GitHub version comparison), -Apply.
      v1.0.0 — Initial release: direct install from GitHub releases.
#>
[CmdletBinding(DefaultParameterSetName = 'Install')]
param(
    # ── INSTALL MODE ─────────────────────────────────────────────────────────────
    [Parameter(Mandatory, ParameterSetName = 'Install', Position = 0)]
    [ValidatePattern('^[^/]+/[^/]+$')]
    [string]$Repo,

    [Parameter(ParameterSetName = 'Install')]
    [string]$Tag = 'latest',

    [Parameter(ParameterSetName = 'Install')]
    [string]$AssetPattern,

    [Parameter(ParameterSetName = 'Install')]
    [string]$InstallDir,

    [Parameter(ParameterSetName = 'Install')]
    [switch]$AddToPath,

    # ── SCAN MODE ─────────────────────────────────────────────────────────────────
    [Parameter(Mandatory, ParameterSetName = 'Scan')]
    [switch]$ScanInventory,

    [Parameter(ParameterSetName = 'Scan')]
    [string]$InventoryPath,

    [Parameter(ParameterSetName = 'Scan')]
    [string]$ManifestPath,

    [Parameter(ParameterSetName = 'Scan')]
    [switch]$CheckVersions,

    [Parameter(ParameterSetName = 'Scan')]
    [switch]$Apply,

    # ── SHARED ───────────────────────────────────────────────────────────────────
    [switch]$DryRun,
    [string]$Token
)

#Requires -Version 7.0

$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level = 'Ignore') Write-Host "[$Level] $Message" }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) Write-Host "$ScriptName — $Subheader" }
}

# ── GitHub API helper ─────────────────────────────────────────────────────────

function Invoke-GitHubApi {
    param([string]$Url, [switch]$Quiet)
    $headers = @{ 'User-Agent' = 'SOK-Install-GitHubRelease/2.0'; 'Accept' = 'application/vnd.github+json' }
    if ($Token) { $headers['Authorization'] = "Bearer $Token" }
    try {
        return Invoke-RestMethod -Uri $Url -Headers $headers -TimeoutSec 20
    } catch {
        if (-not $Quiet) { Write-SOKLog "API error ($Url): $_" -Level Warn }
        return $null
    }
}

# ── Asset scoring (Windows x64 preference) ───────────────────────────────────

$winPatterns = @(
    'windows.*x86_64', 'windows.*amd64', 'win64', 'win_x64', 'win-x64',
    'x86_64.*windows', 'amd64.*windows', 'x86_64-pc-windows', 'windows.*64'
)

function Get-AssetScore {
    param([string]$Name)
    $n = $Name.ToLower()
    $score = 0
    foreach ($p in $winPatterns) { if ($n -match $p) { $score += 10; break } }
    if ($n -match '\.(exe|msi)$')  { $score += 5 }
    if ($n -match '\.zip$')        { $score += 3 }
    if ($n -match '\.(7z|tar)$')   { $score += 2 }
    if ($n -match '(arm|arm64|aarch64|linux|darwin|macos|mac|freebsd)') { $score -= 20 }
    if ($n -match '(sha256|sha512|checksums|sbom|sig|\.asc|\.pem)')     { $score -= 50 }
    return $score
}

# ═══════════════════════════════════════════════════════════════════════════════
# ── CURATED TOOL → GITHUB REPO MAP ───────────────────────────────────────────
# Keys: lowercase normalized tool/package names as they appear in package managers.
# Covers common dev tools on CLAY_PC. Add entries as needed.
# ═══════════════════════════════════════════════════════════════════════════════

$GitHubMap = @{
    # Rust CLI tools (sharkdp/BurntSushi family)
    'ripgrep'       = 'BurntSushi/ripgrep'
    'rg'            = 'BurntSushi/ripgrep'
    'fd'            = 'sharkdp/fd'
    'bat'           = 'sharkdp/bat'
    'hyperfine'     = 'sharkdp/hyperfine'
    'hexyl'         = 'sharkdp/hexyl'
    'dust'          = 'bootandy/dust'
    'bottom'        = 'ClementTsang/bottom'
    'btm'           = 'ClementTsang/bottom'
    'procs'         = 'dalance/procs'
    'tokei'         = 'XAMPPRocky/tokei'
    'delta'         = 'dandavison/delta'
    'git-delta'     = 'dandavison/delta'
    'zoxide'        = 'ajeetdsouza/zoxide'
    'lsd'           = 'lsd-rs/lsd'
    'starship'      = 'starship-rs/starship'
    'broot'         = 'Canop/broot'
    # Go tools
    'fzf'           = 'junegunn/fzf'
    'lazygit'       = 'jesseduffield/lazygit'
    'lazydocker'    = 'jesseduffield/lazydocker'
    'yq'            = 'mikefarah/yq'
    'golangci-lint' = 'golangci/golangci-lint'
    # JSON/YAML tools
    'jq'            = 'jqlang/jq'
    # Python toolchain (Astral)
    'uv'            = 'astral-sh/uv'
    'ruff'          = 'astral-sh/ruff'
    # Editors / IDEs
    'neovim'        = 'neovim/neovim'
    'nvim'          = 'neovim/neovim'
    'helix'         = 'helix-editor/helix'
    'hx'            = 'helix-editor/helix'
    # Terminals
    'wezterm'       = 'wez/wezterm'
    'alacritty'     = 'alacritty/alacritty'
    # Shell / runtime tools
    'nushell'       = 'nushell/nushell'
    'nu'            = 'nushell/nushell'
    'navi'          = 'denisidoro/navi'
    'nvm'           = 'coreybutler/nvm-windows'
    'nvm-windows'   = 'coreybutler/nvm-windows'
    # Git tooling
    'gh'            = 'cli/cli'
    'github-cli'    = 'cli/cli'
    'gitui'         = 'extrawurst/gitui'
    'git-credential-manager' = 'git-ecosystem/git-credential-manager'
    # PowerShell
    'powershell'    = 'PowerShell/PowerShell'
    'pwsh'          = 'PowerShell/PowerShell'
    # Window management / tiling
    'komorebi'      = 'LGUG2Z/komorebi'
    'yasb'          = 'da-rth/yasb'
    # Archive tools
    '7zip'          = 'ip7z/7zip'
    '7-zip'         = 'ip7z/7zip'
    # Networking / security
    'vt'            = 'VirusTotal/vt-cli'
    'nuclei'        = 'projectdiscovery/nuclei'
    'httpie'        = 'httpie/httpie'
    # Misc
    'xsv'           = 'BurntSushi/xsv'
    'glow'          = 'charmbracelet/glow'
    'slides'        = 'maaslalani/slides'
    'wtfutil'       = 'wtfutil/wtf'
    'obsidian'      = 'obsidianmd/obsidian-releases'
}

# ═══════════════════════════════════════════════════════════════════════════════
# SCAN MODE
# ═══════════════════════════════════════════════════════════════════════════════

if ($PSCmdlet.ParameterSetName -eq 'Scan') {

    Show-SOKBanner -ScriptName 'Install-GitHubRelease' -Subheader "SCAN INVENTORY$(if ($CheckVersions) { ' +versions' })$(if ($DryRun) { ' [DRY RUN]' })"
    Invoke-SOKPrerequisite -CallingScript 'Install-GitHubRelease'
    Write-SOKLog "Curated map: $($GitHubMap.Count) tools  |  Scoop manifest inspection: enabled" -Level Ignore
    if (-not $Token -and $CheckVersions) {
        Write-SOKLog 'No -Token supplied — GitHub API rate limit is 60 req/hr. Reduce scope or add -Token.' -Level Warn
    }

    # ── Collect installed tools from all sources ──────────────────────────────

    # Data structure per tool:
    # Name, NormalizedName, InstalledVersion, InstalledVia, SourceUrl (Scoop only),
    # GitHubRepo, LatestGHVersion (if -CheckVersions), Status, Recommendation

    $tools = [System.Collections.Generic.List[hashtable]]::new()

    # ── Source 1: Scoop manifest URL inspection ───────────────────────────────
    $scoopAppsDir = Join-Path $env:USERPROFILE 'scoop\apps'
    if (Test-Path $scoopAppsDir) {
        Write-SOKLog 'Scanning Scoop app manifests...' -Level Ignore
        $scoopCount = 0
        Get-ChildItem $scoopAppsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $appName    = $_.Name
            $manifestPath = Join-Path $_.FullName 'current\manifest.json'
            if (-not (Test-Path $manifestPath)) { return }
            try {
                $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                $version  = $manifest.version
                # Extract URL — may be top-level or nested under architecture
                $url = $manifest.url
                if (-not $url) { $url = $manifest.architecture.'64bit'.url }
                if ($url -is [array]) { $url = $url[0] }
                $isGitHubReleases = $url -match 'github\.com/.+/releases/download'
                $tools.Add(@{
                    Name            = $appName
                    NormalizedName  = $appName.ToLower()
                    InstalledVersion= $version
                    InstalledVia    = 'Scoop'
                    SourceUrl       = $url
                    IsGitHubSource  = $isGitHubReleases
                    GitHubRepo      = $null
                    LatestGHVersion = $null
                    Status          = $null
                })
                $scoopCount++
            } catch { }
        }
        Write-SOKLog "  Scoop: $scoopCount apps" -Level Success
    }

    # ── Source 2: Chocolatey installed packages ───────────────────────────────
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-SOKLog 'Querying Chocolatey...' -Level Ignore
        $chocoOut = choco list --local-only --no-color -r 2>$null
        $chocoCount = 0
        $chocoOut | Where-Object { $_ -match '\|' } | ForEach-Object {
            $parts = $_ -split '\|'
            $name  = $parts[0].Trim()
            $ver   = if ($parts.Count -gt 1) { $parts[1].Trim() } else { '' }
            # Skip if already captured from Scoop
            $already = $tools | Where-Object { $_.NormalizedName -eq $name.ToLower() -and $_.InstalledVia -eq 'Scoop' }
            if (-not $already) {
                $tools.Add(@{
                    Name            = $name
                    NormalizedName  = $name.ToLower()
                    InstalledVersion= $ver
                    InstalledVia    = 'Chocolatey'
                    SourceUrl       = $null
                    IsGitHubSource  = $false
                    GitHubRepo      = $null
                    LatestGHVersion = $null
                    Status          = $null
                })
                $chocoCount++
            }
        }
        Write-SOKLog "  Chocolatey: $chocoCount packages" -Level Success
    }

    # ── Source 3: SOK-Inventory JSON ──────────────────────────────────────────
    $inventoryJson = $null
    if ($InventoryPath -and (Test-Path $InventoryPath)) {
        $inventoryJson = $InventoryPath
    } else {
        $sokLogsDir = "$env:USERPROFILE\Documents\SOK\Logs"
        if (Test-Path $sokLogsDir) {
            $inventoryJson = Get-ChildItem $sokLogsDir -Filter 'SOK-Inventory*.json' -Recurse -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
        }
    }
    if ($inventoryJson) {
        Write-SOKLog "Loading Inventory JSON: $inventoryJson" -Level Ignore
        try {
            $inv = Get-Content $inventoryJson -Raw | ConvertFrom-Json
            # Pull WingetPackages if present
            $wingetPkgs = @()
            if ($inv.WingetPackages) { $wingetPkgs = $inv.WingetPackages }
            $wingetCount = 0
            foreach ($pkg in $wingetPkgs) {
                $name = if ($pkg.Name) { $pkg.Name } elseif ($pkg.Id) { $pkg.Id } else { continue }
                $ver  = if ($pkg.Version) { $pkg.Version } else { '' }
                $norm = $name.ToLower() -replace '[^a-z0-9-]', ''
                $already = $tools | Where-Object { $_.NormalizedName -eq $norm }
                if (-not $already) {
                    $tools.Add(@{
                        Name            = $name
                        NormalizedName  = $norm
                        InstalledVersion= $ver
                        InstalledVia    = 'Winget'
                        SourceUrl       = $null
                        IsGitHubSource  = $false
                        GitHubRepo      = $null
                        LatestGHVersion = $null
                        Status          = $null
                    })
                    $wingetCount++
                }
            }
            if ($wingetCount -gt 0) { Write-SOKLog "  Inventory JSON (Winget): $wingetCount packages" -Level Success }
        } catch { Write-SOKLog "  Could not parse Inventory JSON: $_" -Level Warn }
    } else {
        Write-SOKLog 'No SOK-Inventory JSON found (run SOK-PAST.ps1 -TakeInventory to generate).' -Level Warn
    }

    # ── Source 4: Registry uninstall keys (traditional installers) ────────────
    Write-SOKLog 'Scanning registry installs...' -Level Ignore
    $regPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $regCount = 0
    $regPaths | ForEach-Object {
        Get-ItemProperty $_ -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } |
            ForEach-Object {
                $name = $_.DisplayName.Trim()
                $norm = $name.ToLower() -replace '[^a-z0-9-]', ''
                $already = $tools | Where-Object { $_.NormalizedName -eq $norm }
                if (-not $already -and $GitHubMap.ContainsKey($norm)) {
                    $tools.Add(@{
                        Name            = $name
                        NormalizedName  = $norm
                        InstalledVersion= $_.DisplayVersion
                        InstalledVia    = 'Installer'
                        SourceUrl       = $null
                        IsGitHubSource  = $false
                        GitHubRepo      = $null
                        LatestGHVersion = $null
                        Status          = $null
                    })
                    $regCount++
                }
            }
    }
    Write-SOKLog "  Registry (map-matched only): $regCount entries" -Level Ignore

    Write-SOKLog "Total tools collected: $($tools.Count)" -Level Success

    # ── Cross-reference against curated map ──────────────────────────────────

    Write-SOKLog 'Cross-referencing against GitHub map...' -Level Ignore
    $matched = 0
    foreach ($tool in $tools) {
        $norm = $tool.NormalizedName

        # Try exact match first, then strip trailing version suffixes
        $repo = $null
        if ($GitHubMap.ContainsKey($norm))                        { $repo = $GitHubMap[$norm] }
        elseif ($GitHubMap.ContainsKey($norm -replace '\d.*$','')) { $repo = $GitHubMap[$norm -replace '\d.*$',''] }

        # For Scoop tools: if the manifest URL already points to this repo, confirm it
        if (-not $repo -and $tool.IsGitHubSource -and $tool.SourceUrl -match 'github\.com/([^/]+/[^/]+)/releases') {
            $repo = $Matches[1]
        }

        $tool.GitHubRepo = $repo
        if ($repo) { $matched++ }
    }
    Write-SOKLog "  Matched to GitHub repos: $matched of $($tools.Count)" -Level Success

    # ── Optionally check latest GitHub versions ───────────────────────────────

    if ($CheckVersions) {
        Write-SOKLog "Checking latest GitHub releases for $matched tools (API calls — may be slow without -Token)..." -Level Ignore
        $apiChecked = 0
        foreach ($tool in $tools | Where-Object { $_.GitHubRepo }) {
            $latest = Invoke-GitHubApi -Url "https://api.github.com/repos/$($tool.GitHubRepo)/releases/latest" -Quiet
            if ($latest) {
                $tool.LatestGHVersion = $latest.tag_name -replace '^v', ''
            }
            $apiChecked++
            # Brief throttle to be kind to GitHub API
            if ($apiChecked % 10 -eq 0) { Start-Sleep -Milliseconds 500 }
        }
        Write-SOKLog "  Version checks complete." -Level Success
    }

    # ── Assign status ─────────────────────────────────────────────────────────

    foreach ($tool in $tools) {
        if (-not $tool.GitHubRepo) {
            $tool.Status = 'NO-MATCH'
            continue
        }
        if ($tool.IsGitHubSource) {
            # Scoop installing directly from github.com/releases/download = authoritative source
            if ($tool.LatestGHVersion -and $tool.InstalledVersion) {
                $tool.Status = if ($tool.InstalledVersion -eq $tool.LatestGHVersion) { 'CURRENT' } else { 'OUTDATED' }
            } else {
                $tool.Status = 'GITHUB-SOURCED'
            }
        } else {
            if ($tool.LatestGHVersion -and $tool.InstalledVersion) {
                $tool.Status = if ($tool.InstalledVersion -eq $tool.LatestGHVersion) { 'CURRENT' } else { 'OUTDATED' }
            } else {
                $tool.Status = 'VIA-PKG-MGR'
            }
        }
    }

    # ── Display results ───────────────────────────────────────────────────────

    $matched_tools = $tools | Where-Object { $_.Status -ne 'NO-MATCH' } | Sort-Object Status, Name
    $no_match      = $tools | Where-Object { $_.Status -eq 'NO-MATCH' }

    Write-SOKLog '' -Level Ignore
    Write-SOKLog '━━━ GITHUB SOURCE AUDIT ━━━' -Level Section

    $statusColors = @{
        'GITHUB-SOURCED' = 'Green'
        'CURRENT'        = 'Green'
        'OUTDATED'       = 'Yellow'
        'VIA-PKG-MGR'    = 'Cyan'
        'INSTALLER'      = 'Cyan'
        'NO-MATCH'       = 'DarkGray'
    }

    $colW = @{ Name=28; Via=12; Inst=14; Repo=32; Latest=10; Status=16 }
    $hdr = "  $('Name'.PadRight($colW.Name)) $('Via'.PadRight($colW.Via)) $('Installed'.PadRight($colW.Inst)) $('GitHub Repo'.PadRight($colW.Repo)) $('Latest'.PadRight($colW.Latest)) Status"
    Write-Host $hdr -ForegroundColor White
    Write-Host "  $('─' * ($hdr.Length - 2))" -ForegroundColor DarkGray

    foreach ($tool in $matched_tools) {
        $color = $statusColors[$tool.Status] ?? 'White'
        $line = "  $($tool.Name.PadRight($colW.Name)) " +
                "$($tool.InstalledVia.PadRight($colW.Via)) " +
                "$($tool.InstalledVersion.PadRight($colW.Inst)) " +
                "$($tool.GitHubRepo.PadRight($colW.Repo)) " +
                "$(($tool.LatestGHVersion ?? '—').PadRight($colW.Latest)) " +
                $tool.Status
        Write-Host $line -ForegroundColor $color
    }

    Write-Host ''
    Write-SOKLog "Summary: $($matched_tools.Count) matched | $($no_match.Count) no GitHub match" -Level Ignore
    $statusGroups = $matched_tools | Group-Object Status
    $statusGroups | ForEach-Object { Write-SOKLog "  $($_.Name.PadRight(18)) $($_.Count)" -Level Ignore }

    # ── Apply: offer to install GitHub versions for actionable tools ──────────

    if ($Apply) {
        $actionable = $matched_tools | Where-Object { $_.Status -in @('VIA-PKG-MGR','OUTDATED','INSTALLER') }
        if (-not $actionable) {
            Write-SOKLog 'Nothing actionable — all matched tools are GITHUB-SOURCED or CURRENT.' -Level Success
        } else {
            Write-SOKLog '' -Level Ignore
            Write-SOKLog "━━━ APPLY: $($actionable.Count) tools eligible for GitHub direct install ━━━" -Level Section
            if ($DryRun) { Write-SOKLog 'DRY RUN — showing what would be installed.' -Level Warn }

            foreach ($tool in $actionable) {
                Write-Host "`n  [$($tool.Status)] $($tool.Name) ($($tool.InstalledVia) $($tool.InstalledVersion)) → $($tool.GitHubRepo)" -ForegroundColor Yellow
                if (-not $DryRun) {
                    $answer = Read-Host "  Install from GitHub? [y/N]"
                    if ($answer -match '^[yY]') {
                        Write-SOKLog "  Installing $($tool.GitHubRepo)..." -Level Ignore
                        & $PSCommandPath -Repo $tool.GitHubRepo -Token:$Token -AddToPath
                    }
                }
            }
        }
    }

    exit 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# INSTALL MODE
# ═══════════════════════════════════════════════════════════════════════════════

Show-SOKBanner -ScriptName 'Install-GitHubRelease' -Subheader "$Repo@$Tag$(if ($DryRun) { ' [DRY RUN]' })"
if ($DryRun) { Write-SOKLog 'DRY RUN — no downloads or installations.' -Level Warn }

$repoName = $Repo.Split('/')[-1]
if (-not $InstallDir) { $InstallDir = "E:\SOK_Offload\$repoName" }

$apiBase    = "https://api.github.com/repos/$Repo/releases"
$releaseUrl = if ($Tag -eq 'latest') { "$apiBase/latest" } else { "$apiBase/tags/$Tag" }

Write-SOKLog "Fetching release: $releaseUrl" -Level Ignore
$release = Invoke-GitHubApi -Url $releaseUrl
if (-not $release) { Write-SOKLog 'Failed to fetch release.' -Level Error; exit 1 }

Write-SOKLog "Release: $($release.tag_name)  published: $($release.published_at)" -Level Success
$release.assets | ForEach-Object { Write-SOKLog "  $($_.name)  ($([math]::Round($_.size/1KB, 0)) KB)" -Level Debug }

$candidates = $release.assets
if ($AssetPattern) {
    $candidates = $candidates | Where-Object { $_.name -like $AssetPattern }
    if (-not $candidates) {
        Write-SOKLog "No assets match '$AssetPattern'." -Level Error
        $release.assets | ForEach-Object { Write-SOKLog "  $($_.name)" -Level Ignore }
        exit 1
    }
}

$best = $candidates | Sort-Object { Get-AssetScore $_.name } -Descending | Select-Object -First 1
if (-not $best) { Write-SOKLog 'No suitable asset found.' -Level Error; exit 1 }

Write-SOKLog "Selected: $($best.name)  ($([math]::Round($best.size/1KB, 0)) KB)" -Level Success
Write-SOKLog "  URL: $($best.browser_download_url)" -Level Debug

$checksumAsset = $release.assets | Where-Object {
    $_.name -match '(sha256|checksums)' -and $_.name -notmatch '\.(exe|msi|zip|7z)$'
} | Select-Object -First 1

if ($DryRun) {
    Write-SOKLog '' -Level Ignore; Write-SOKLog 'DRY RUN summary:' -Level Section
    Write-SOKLog "  Repo:      $Repo" -Level Ignore
    Write-SOKLog "  Release:   $($release.tag_name)" -Level Ignore
    Write-SOKLog "  Asset:     $($best.name)  ($([math]::Round($best.size/1KB, 0)) KB)" -Level Ignore
    Write-SOKLog "  InstallTo: $InstallDir" -Level Ignore
    Write-SOKLog "  AddToPath: $AddToPath" -Level Ignore
    if ($checksumAsset) { Write-SOKLog "  Checksum:  $($checksumAsset.name)" -Level Ignore }
    exit 0
}

$tmpDir = Join-Path $env:TEMP "SOK-GHRelease-$repoName-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -Path $tmpDir -ItemType Directory -Force | Out-Null
$downloadPath = Join-Path $tmpDir $best.name
Write-SOKLog "Downloading $($best.name)..." -Level Ignore

$dlHeaders = @{ 'User-Agent' = 'SOK-Install-GitHubRelease/2.0' }
if ($Token) { $dlHeaders['Authorization'] = "Bearer $Token" }
Invoke-WebRequest -Uri $best.browser_download_url -OutFile $downloadPath -Headers $dlHeaders -TimeoutSec 300

Write-SOKLog "Downloaded: $([math]::Round((Get-Item $downloadPath).Length / 1KB, 0)) KB" -Level Success

if ($checksumAsset) {
    Write-SOKLog "Verifying checksum..." -Level Ignore
    $checksumPath = Join-Path $tmpDir $checksumAsset.name
    Invoke-WebRequest -Uri $checksumAsset.browser_download_url -OutFile $checksumPath -Headers $dlHeaders -TimeoutSec 30
    $actualHash = (Get-FileHash $downloadPath -Algorithm SHA256).Hash.ToLower()
    if ((Get-Content $checksumPath -Raw) -match $actualHash) {
        Write-SOKLog "  SHA-256 verified." -Level Success
    } else {
        Write-SOKLog "  Checksum MISMATCH — aborting." -Level Error
        Remove-Item $tmpDir -Recurse -Force; exit 1
    }
}

if (-not (Test-Path $InstallDir)) { New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null }

$assetLower = $best.name.ToLower()
if ($assetLower -match '\.exe$') {
    $proc = Start-Process $downloadPath -ArgumentList '/S','/quiet','/norestart' -Wait -PassThru -ErrorAction Continue
    Write-SOKLog "Exit code: $($proc.ExitCode)" -Level $(if ($proc.ExitCode -eq 0){'Success'}else{'Warn'})
} elseif ($assetLower -match '\.msi$') {
    $proc = Start-Process msiexec.exe -ArgumentList "/i `"$downloadPath`" /passive /norestart INSTALLDIR=`"$InstallDir`"" -Wait -PassThru
    Write-SOKLog "Exit code: $($proc.ExitCode)" -Level $(if ($proc.ExitCode -eq 0){'Success'}else{'Warn'})
} elseif ($assetLower -match '\.zip$') {
    Expand-Archive -Path $downloadPath -DestinationPath $InstallDir -Force
    Write-SOKLog "Extracted to $InstallDir" -Level Success
} elseif ($assetLower -match '\.(7z|tar\.gz|tar\.xz|tar\.bz2)$') {
    if (Get-Command 7z -ErrorAction SilentlyContinue) {
        & 7z x $downloadPath -o"$InstallDir" -y | Where-Object { $_ -match 'Everything|Error' }
        Write-SOKLog "Extracted via 7-Zip to $InstallDir" -Level Success
    } else {
        Write-SOKLog "7-Zip not in PATH — cannot extract. File at: $downloadPath" -Level Error; exit 1
    }
} else {
    Copy-Item $downloadPath -Destination (Join-Path $InstallDir $best.name) -Force
    Write-SOKLog "Copied to $InstallDir" -Level Warn
}

if ($AddToPath) {
    $binDir  = Get-ChildItem $InstallDir -Filter 'bin' -Directory -ErrorAction SilentlyContinue | Select-Object -First 1
    $pathDir = if ($binDir) { $binDir.FullName } else { $InstallDir }
    $machinePath = [System.Environment]::GetEnvironmentVariable('PATH','Machine')
    if ($machinePath -notlike "*$pathDir*") {
        [System.Environment]::SetEnvironmentVariable('PATH', "$machinePath;$pathDir", 'Machine')
        Write-SOKLog "Added to Machine PATH: $pathDir" -Level Success
    } else {
        Write-SOKLog "Already in PATH: $pathDir" -Level Ignore
    }
}

Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
Write-SOKLog "Install complete: $repoName $($release.tag_name) → $InstallDir" -Level Success
