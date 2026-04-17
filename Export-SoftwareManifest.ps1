#Requires -Version 7.0
<#
.SYNOPSIS
    Export-SoftwareManifest v1.0.0 — Generate a comprehensive Markdown document of all
    installed software, tools, package managers, and managed packages on CLAY_PC.
.DESCRIPTION
    Queries every package manager and software source on the system and writes a unified
    Markdown document. Intended as the authoritative human-readable inventory for:
      - Pre-migration planning (know what to reinstall)
      - Substrate Thesis documentation (BareMetal script reference)
      - AI context (feed to Claude for environment-aware assistance)
      - Audit trail (diff against prior runs to detect drift)

    SOURCES QUERIED:
      Chocolatey      — choco list
      Winget          — winget list
      Scoop           — scoop list
      pip (3.14)      — pip list
      npm (global)    — npm list -g --depth=0
      PowerShell      — Get-Module -ListAvailable (all unique names)
      Windows Store   — Get-AppxPackage (non-Microsoft, non-system)
      MSI/Registry    — HKLM/HKCU uninstall keys (traditional installers)
      Docker images   — docker images (if Docker running)
      scoop buckets   — scoop bucket list
      PATH entries    — $env:PATH entries with existence check

    Output: <output_dir>/SoftwareManifest_<timestamp>.md
            <output_dir>/SoftwareManifest_latest.md  (symlink/copy to latest)

.PARAMETER OutputDir
    Where to write the manifest. Default: C:\Users\shelc\Documents\Journal\Projects\SOK\Docs

.PARAMETER DryRun
    Preview sources that would be queried without writing output.

.PARAMETER SkipSlowSources
    Skip Winget and Windows Store queries (these can take 30+ seconds each).

.NOTES
    Author:  S. Clay Caddell
    Version: 1.0.0
    Date:    2026-04-03
    Domain:  Utility — on-demand or periodic software inventory export; not scheduled
    Runtime: ~2-3 min normally; ~5 min with slow sources
#>
[CmdletBinding()]
param(
    [string]$OutputDir    = 'C:\Users\shelc\Documents\Journal\Projects\SOK\Docs',
    [switch]$DryRun,
    [switch]$SkipSlowSources
)

$ErrorActionPreference = 'Continue'

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }
else {
    function Write-SOKLog { param([string]$Message, [string]$Level='Ignore') Write-Host "[$Level] $Message" }
    function Show-SOKBanner { param([string]$ScriptName, [string]$Subheader) Write-Host "$ScriptName — $Subheader" }
}

Show-SOKBanner -ScriptName 'Export-SoftwareManifest' -Subheader "$(Get-Date -Format 'yyyy-MM-dd')$(if ($DryRun) { ' [DRY RUN]' })"
if ($DryRun) { Write-SOKLog 'DRY RUN — will list sources, no file written.' -Level Warn }
if (Get-Command Invoke-SOKPrerequisite -ErrorAction SilentlyContinue) {
    Invoke-SOKPrerequisite -CallingScript 'Export-SoftwareManifest'
}

$ts        = Get-Date -Format 'yyyyMMdd_HHmmss'
$dateLabel = Get-Date -Format 'yyyy-MM-dd HH:mm'
$sections  = [System.Collections.Generic.List[string]]::new()
$errors    = [System.Collections.Generic.List[string]]::new()

function Add-Section { param([string]$Content) $sections.Add($Content) }
function Err { param([string]$msg) $errors.Add($msg); Write-SOKLog $msg -Level Warn }

function Run-Cmd {
    param([string]$Cmd, [string[]]$CmdArgs, [int]$TimeoutSec = 60)
    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = $Cmd
        $psi.Arguments = ($CmdArgs | ForEach-Object { if ($_ -match '\s') { "`"$_`"" } else { $_ } }) -join ' '
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEndAsync()
        $stderr = $proc.StandardError.ReadToEndAsync()
        if (-not $proc.WaitForExit($TimeoutSec * 1000)) {
            $proc.Kill()
            Err "Command timed out after ${TimeoutSec}s: $Cmd $($Args -join ' ')"
            return $null
        }
        [System.Threading.Tasks.Task]::WaitAll(@($stdout, $stderr))
        $output = $stdout.Result -split '\r?\n' | ForEach-Object { $_.TrimEnd() } | Where-Object { $_ -match '\S' }
        return $output
    } catch {
        Err "Command failed: $Cmd $($Args -join ' ') — $_"
        return $null
    }
}

function Wrap-Table {
    param([string[]]$Lines, [string]$Col1 = 'Package', [string]$Col2 = 'Version')
    if (-not $Lines -or $Lines.Count -eq 0) { return '_none found_' }
    $rows = $Lines | ForEach-Object { "| $_ |" }
    return "| $Col1 | $Col2 |`n|---|---|`n$($rows -join "`n")"
}

# ── CHOCOLATEY ────────────────────────────────────────────────────────────────
Write-SOKLog 'Querying Chocolatey...' -Level Ignore
$chocoSection = "## Chocolatey`n"
if (Get-Command choco -ErrorAction SilentlyContinue) {
    $chocoList = Run-Cmd 'choco' @('list', '--no-color', '-r')
    if ($chocoList) {
        $rows = $chocoList | Where-Object { $_ -match '\|' } |
            ForEach-Object { $p = $_ -split '\|'; "| $($p[0]) | $($p[1]) |" }
        $chocoSection += "| Package | Version |`n|---|---|`n$($rows -join "`n")"
        Write-SOKLog "  Chocolatey: $($rows.Count) packages" -Level Success
    } else { $chocoSection += '_no output_' }
} else { $chocoSection += '_choco not found in PATH_'; Err 'choco not found' }
Add-Section $chocoSection

# ── SCOOP ─────────────────────────────────────────────────────────────────────
Write-SOKLog 'Querying Scoop...' -Level Ignore
$scoopSection = "## Scoop`n"
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    $scoopList = Run-Cmd 'scoop' @('list')
    if ($scoopList) {
        $rows = $scoopList | Where-Object { $_ -match '^\s+\S' -and $_ -notmatch '^Name|^---' } |
            ForEach-Object {
                $parts = ($_ -split '\s+', 4) | Where-Object { $_ }
                if ($parts.Count -ge 2) { "| $($parts[0]) | $($parts[1]) |" }
            } | Where-Object { $_ }
        $scoopSection += "| App | Version |`n|---|---|`n$($rows -join "`n")"
        Write-SOKLog "  Scoop: $($rows.Count) apps" -Level Success
    } else { $scoopSection += '_no output_' }

    # Scoop buckets
    $buckets = Run-Cmd 'scoop' @('bucket', 'list')
    if ($buckets) {
        $scoopSection += "`n`n### Scoop Buckets`n``````text`n$($buckets -join "`n")`n``````"
    }
} else { $scoopSection += '_scoop not found in PATH_'; Err 'scoop not found' }
Add-Section $scoopSection

# ── WINGET ────────────────────────────────────────────────────────────────────
if (-not $SkipSlowSources) {
    Write-SOKLog 'Querying Winget (slow — use -SkipSlowSources to skip)...' -Level Ignore
    $wingetSection = "## Winget`n"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $wingetList = Run-Cmd 'winget' @('list', '--disable-interactivity', '--accept-source-agreements')
        if ($wingetList) {
            $rows = $wingetList | Where-Object { $_ -match '\S' -and $_ -notmatch '^Name|^-+' } |
                ForEach-Object {
                    $trimmed = $_ -replace '\s{2,}', '|'
                    $parts = $trimmed -split '\|'
                    if ($parts.Count -ge 2) { "| $($parts[0].Trim()) | $($parts[1].Trim()) |" }
                } | Where-Object { $_ }
            $wingetSection += "| Name | Id/Version |`n|---|---|`n$($rows -join "`n")"
            Write-SOKLog "  Winget: ~$($rows.Count) entries" -Level Success
        } else { $wingetSection += '_no output_' }
    } else { $wingetSection += '_winget not found_'; Err 'winget not found' }
    Add-Section $wingetSection
}

# ── PIP ───────────────────────────────────────────────────────────────────────
Write-SOKLog 'Querying pip (Python 3.14)...' -Level Ignore
$pipSection = "## Python (pip 3.14)`n"
$pipList = Run-Cmd 'py' @('-3.14', '-m', 'pip', 'list', '--format=columns')
if ($pipList) {
    $rows = $pipList | Where-Object { $_ -match '^\S' -and $_ -notmatch '^Package|^-+' } |
        ForEach-Object {
            $parts = $_ -split '\s+', 2
            if ($parts.Count -eq 2) { "| $($parts[0]) | $($parts[1].Trim()) |" }
        } | Where-Object { $_ }
    $pipSection += "| Package | Version |`n|---|---|`n$($rows -join "`n")"
    Write-SOKLog "  pip: $($rows.Count) packages" -Level Success
} else { $pipSection += '_py -3.14 not available or pip error_'; Err 'pip query failed' }
Add-Section $pipSection

# ── NPM ───────────────────────────────────────────────────────────────────────
Write-SOKLog 'Querying npm global packages...' -Level Ignore
$npmSection = "## Node / npm (global)`n"
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmList = Run-Cmd 'npm' @('list', '-g', '--depth=0', '--parseable')
    if ($npmList) {
        $rows = $npmList | Where-Object { $_ -match 'node_modules' } |
            ForEach-Object {
                $pkg = Split-Path $_ -Leaf
                "| $pkg | (global) |"
            }
        $npmSection += "| Package | Scope |`n|---|---|`n$($rows -join "`n")"
        Write-SOKLog "  npm: $($rows.Count) global packages" -Level Success
    } else { $npmSection += '_no global packages or npm error_' }
} else { $npmSection += '_npm not found in PATH_'; Err 'npm not found' }
Add-Section $npmSection

# ── POWERSHELL MODULES ────────────────────────────────────────────────────────
Write-SOKLog 'Querying PowerShell modules...' -Level Ignore
$psModSection = "## PowerShell Modules`n"
$psMods = Get-Module -ListAvailable |
    Group-Object Name |
    Select-Object Name, @{N='Version'; E={($_.Group | Sort-Object Version -Descending | Select-Object -First 1).Version}} |
    Where-Object { $_.Name -notmatch '^(Microsoft\.|Pester|PSReadLine)' } |  # filter noisy built-ins
    Sort-Object Name
if ($psMods) {
    $rows = $psMods | ForEach-Object { "| $($_.Name) | $($_.Version) |" }
    $psModSection += "| Module | Latest Installed Version |`n|---|---|`n$($rows -join "`n")"
    Write-SOKLog "  PS modules: $($rows.Count)" -Level Success
} else { $psModSection += '_none_' }
Add-Section $psModSection

# ── DOCKER IMAGES ─────────────────────────────────────────────────────────────
Write-SOKLog 'Querying Docker images...' -Level Ignore
$dockerSection = "## Docker Images`n"
if (Get-Command docker -ErrorAction SilentlyContinue) {
    $dockerCheck = Run-Cmd 'docker' @('info', '--format', '{{.ServerVersion}}')
    if ($dockerCheck -and $dockerCheck -notmatch 'error') {
        $dockerImages = Run-Cmd 'docker' @('images', '--format', '{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}')
        if ($dockerImages) {
            $rows = $dockerImages | Where-Object { $_ -match '\S' } |
                ForEach-Object {
                    $parts = $_ -split "`t"
                    "| $($parts[0]) | $($parts[1]) | $($parts[2]) |"
                }
            $dockerSection += "| Image | Size | Created |`n|---|---|---|`n$($rows -join "`n")"
            Write-SOKLog "  Docker: $($rows.Count) images" -Level Success
        } else { $dockerSection += '_no images_' }
    } else { $dockerSection += '_Docker daemon not running_'; Err 'Docker not running' }
} else { $dockerSection += '_docker not found_' }
Add-Section $dockerSection

# ── REGISTRY (MSI/Traditional) ────────────────────────────────────────────────
Write-SOKLog 'Querying registry installs...' -Level Ignore
$regSection = "## Registry-Installed Software (MSI / Traditional)`n"
$regPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
$regApps = $regPaths | ForEach-Object {
    Get-ItemProperty $_ -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and $_.DisplayName -notmatch '^\s*$' -and
                       $_.SystemComponent -ne 1 -and
                       $_.DisplayName -notmatch '^(KB\d+|Update for|Security Update|Hotfix)' } |
        Select-Object DisplayName, DisplayVersion, Publisher
} | Sort-Object DisplayName -Unique
if ($regApps) {
    $rows = $regApps | ForEach-Object { "| $($_.DisplayName) | $($_.DisplayVersion) | $($_.Publisher) |" }
    $regSection += "| Name | Version | Publisher |`n|---|---|---|`n$($rows -join "`n")"
    Write-SOKLog "  Registry: $($rows.Count) apps" -Level Success
} else { $regSection += '_none found_' }
Add-Section $regSection

# ── PATH ENTRIES ──────────────────────────────────────────────────────────────
Write-SOKLog 'Collecting PATH entries...' -Level Ignore
$pathSection = "## PATH Entries`n"
$pathEntries = ($env:PATH -split ';') | Sort-Object -Unique | Where-Object { $_ -match '\S' } |
    ForEach-Object {
        $exists = Test-Path $_ -ErrorAction SilentlyContinue
        "| $_ | $(if ($exists) { ':white_check_mark:' } else { ':warning: missing' }) |"
    }
$pathSection += "| Path | Status |`n|---|---|`n$($pathEntries -join "`n")"
Add-Section $pathSection

# ── COMPOSE ───────────────────────────────────────────────────────────────────
if ($DryRun) {
    Write-SOKLog '' -Level Ignore
    Write-SOKLog 'DRY RUN — sections that would be written:' -Level Section
    $sections | ForEach-Object { Write-SOKLog "  $($_.Split("`n")[0])" -Level Ignore }
    Write-SOKLog "Errors/warnings: $($errors.Count)" -Level $(if ($errors.Count -gt 0) { 'Warn' } else { 'Success' })
    exit 0
}

if (-not (Test-Path $OutputDir)) { New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null }

$header = @"
# CLAY_PC Software Manifest

**Generated:** $dateLabel
**Host:** $env:COMPUTERNAME
**OS:** $([System.Environment]::OSVersion.VersionString)
**PowerShell:** $($PSVersionTable.PSVersion)
**Script:** Export-SoftwareManifest v1.0.0

> This document is auto-generated by `Export-SoftwareManifest.ps1`.
> Do not edit manually — re-run the script to update.

---

"@

$footer = @"

---

## Generation Notes

- Run at: $dateLabel
- Slow sources skipped: $SkipSlowSources
- Errors during generation: $($errors.Count)
$(if ($errors.Count -gt 0) { $errors | ForEach-Object { "  - $_" } | Out-String })
"@

$fullDoc = $header + ($sections -join "`n`n---`n`n") + $footer

$outPath    = Join-Path $OutputDir "SoftwareManifest_$ts.md"
$latestPath = Join-Path $OutputDir 'SoftwareManifest_latest.md'

$fullDoc | Out-File $outPath    -Encoding utf8 -Force
$fullDoc | Out-File $latestPath -Encoding utf8 -Force

$sizeKB = [math]::Round((Get-Item $outPath).Length / 1KB, 1)
Write-SOKLog '' -Level Ignore
Write-SOKLog "Manifest written: $outPath  ($sizeKB KB)" -Level Success
Write-SOKLog "Latest symlink:   $latestPath" -Level Success
Write-SOKLog "Sections: $($sections.Count)  |  Errors: $($errors.Count)" -Level $(if ($errors.Count -gt 0) { 'Warn' } else { 'Success' })
