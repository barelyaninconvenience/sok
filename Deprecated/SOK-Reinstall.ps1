<#
.SYNOPSIS
    SOK-Reinstall.ps1 — Reinstall tools deleted by PreSwap Phase 4 to E:\SOK_Offload.
.DESCRIPTION
    PreSwap Phase 4 (27Mar2026) deleted the following instead of offloading:
      mingw64, nvm, Jenkins, MySQL, SquirrelMachineInstalls, Package Cache,
      Weka docs, Gephi JRE, SoapUI 5.8.0, Erlang OTP old versions.

    This script reinstalls each to E:\SOK_Offload with junctions from the
    original C: paths, matching the offload-not-delete pattern.

    Each item is presented for user confirmation before installation.
.PARAMETER DryRun
    Preview without installing.
.NOTES
    Author: S. Clay Caddell
    Version: 1.0.0
    Date: 28Mar2026
    Run: pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-Reinstall.ps1 -DryRun
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$TargetDrive = 'E:'
)

$ErrorActionPreference = 'Continue'
$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

$logPath = Initialize-SOKLog -ScriptName 'SOK-Reinstall'
Show-SOKBanner -ScriptName 'SOK-Reinstall' -Subheader "Target: $TargetDrive$(if ($DryRun) { ' | DRY RUN' })"

$offloadBase = Join-Path $TargetDrive 'SOK_Offload'
if (-not (Test-Path $offloadBase)) {
    if (-not $DryRun) { New-Item -Path $offloadBase -ItemType Directory -Force | Out-Null }
}

# ═══════════════════════════════════════════════════════════════
# ITEMS DELETED BY PRESWAP PHASE 4 (27Mar2026)
# ═══════════════════════════════════════════════════════════════
$deletedItems = @(
    @{
        Name       = 'MinGW-w64 (GCC toolchain)'
        OrigPath   = 'C:\ProgramData\mingw64'
        OffloadDir = 'C_ProgramData_mingw64'
        InstallCmd = 'choco install mingw -y --params "/installdir:OFFLOAD_PATH"'
        ChocoName  = 'mingw'
        StaleDays  = 122
        SizeEst    = '719 MB'
        Notes      = 'GCC compiler toolchain. Needed for C/C++ builds, Rust bindgen, Python C extensions.'
    }
    @{
        Name       = 'Jenkins CI Server'
        OrigPath   = 'C:\ProgramData\Jenkins'
        OffloadDir = 'C_ProgramData_Jenkins'
        InstallCmd = 'choco install jenkins -y'
        ChocoName  = 'jenkins'
        StaleDays  = 122
        SizeEst    = '106 MB'
        Notes      = 'CI/CD server. Was stale 122d. Installs to ProgramData by default.'
    }
    @{
        Name       = 'MySQL Server (data directory)'
        OrigPath   = 'C:\ProgramData\MySQL'
        OffloadDir = 'C_ProgramData_MySQL'
        InstallCmd = 'choco install mysql -y'
        ChocoName  = 'mysql'
        StaleDays  = 122
        SizeEst    = '191 MB'
        Notes      = 'Database data directory. Custom databases were LOST. Fresh install creates empty data dir.'
    }
    @{
        Name       = 'Weka 3.8.6 Documentation'
        OrigPath   = 'C:\Program Files\weka-3-8-6\doc'
        OffloadDir = 'C_Program_Files_weka-3-8-6_doc'
        InstallCmd = 'choco install weka -y'
        ChocoName  = 'weka'
        StaleDays  = 1522
        SizeEst    = '82 MB'
        Notes      = 'Data mining toolkit docs. Was 4+ years stale. Reinstall gets fresh docs.'
    }
    @{
        Name       = 'Gephi 0.10.1 Bundled JRE'
        OrigPath   = 'C:\Program Files\Gephi-0.10.1\jre-x64'
        OffloadDir = 'C_Program_Files_Gephi-0.10.1_jre-x64'
        InstallCmd = 'choco install gephi -y'
        ChocoName  = 'gephi'
        StaleDays  = 206
        SizeEst    = '119 MB'
        Notes      = 'Graph visualization. Bundled JRE auto-reinstalls with Gephi.'
    }
    @{
        Name       = 'SoapUI 5.8.0 (old version)'
        OrigPath   = 'C:\Program Files\SmartBear\SoapUI-5.8.0'
        OffloadDir = 'C_Program_Files_SmartBear_SoapUI-5.8.0'
        InstallCmd = 'choco install soapui -y'
        ChocoName  = 'soapui'
        StaleDays  = 0
        SizeEst    = '273 MB'
        Notes      = 'API testing. 5.8.0 was old duplicate — reinstall gets latest (5.9.x). Skip if 5.9 already present.'
    }
    @{
        Name       = 'Erlang OTP (old erts versions)'
        OrigPath   = 'C:\Program Files\Erlang OTP'
        OffloadDir = 'C_Program_Files_Erlang_OTP'
        InstallCmd = 'choco install erlang -y'
        ChocoName  = 'erlang'
        StaleDays  = 0
        SizeEst    = '340 MB (3 old versions deleted)'
        Notes      = 'Erlang runtime. Reinstall gets latest single version. Old 16.1.1/16.1.2/16.2 were duplicates.'
    }
    @{
        Name       = 'SquirrelMachineInstalls (installer cache)'
        OrigPath   = 'C:\ProgramData\SquirrelMachineInstalls'
        OffloadDir = 'C_ProgramData_SquirrelMachineInstalls'
        InstallCmd = $null  # Auto-regenerates
        ChocoName  = $null
        StaleDays  = 0
        SizeEst    = '118 MB'
        Notes      = 'Squirrel installer cache. Auto-regenerates on next app update. NO ACTION NEEDED.'
    }
)

# ═══════════════════════════════════════════════════════════════
# INTERACTIVE REINSTALL
# ═══════════════════════════════════════════════════════════════
Write-SOKLog 'DELETED ITEMS REVIEW' -Level Section

$installed = 0; $skipped = 0; $failed = 0

foreach ($item in $deletedItems) {
    Write-Host ""
    Write-Host "  ┌─ $($item.Name)" -ForegroundColor Cyan
    Write-Host "  │  Original: $($item.OrigPath)" -ForegroundColor Gray
    Write-Host "  │  Size:     $($item.SizeEst) | Stale: $($item.StaleDays)d" -ForegroundColor Gray
    Write-Host "  │  Notes:    $($item.Notes)" -ForegroundColor Gray

    if (-not $item.InstallCmd) {
        Write-Host "  │  Action:   SKIP (auto-regenerates)" -ForegroundColor DarkGray
        Write-SOKLog "SKIP: $($item.Name) — auto-regenerates" -Level Debug
        $skipped++
        continue
    }

    # Check if already installed
    $alreadyExists = Test-Path $item.OrigPath
    $offloadExists = Test-Path (Join-Path $offloadBase $item.OffloadDir)
    if ($alreadyExists) {
        Write-Host "  │  Status:   ALREADY EXISTS at $($item.OrigPath)" -ForegroundColor Green
        Write-SOKLog "EXISTS: $($item.Name) — already at $($item.OrigPath)" -Level Success
        $skipped++
        continue
    }
    if ($offloadExists) {
        Write-Host "  │  Status:   ALREADY ON E: at $offloadBase\$($item.OffloadDir)" -ForegroundColor Green
        Write-SOKLog "EXISTS: $($item.Name) — already offloaded" -Level Success
        $skipped++
        continue
    }

    Write-Host "  │  Install:  $($item.InstallCmd)" -ForegroundColor Yellow
    Write-Host "  └─ Reinstall to $TargetDrive with junction? [Y/N/S(kip)]" -ForegroundColor White -NoNewline

    if ($DryRun) {
        Write-Host " → DRY RUN (would prompt)" -ForegroundColor DarkGray
        Write-SOKLog "[DRY] Would reinstall: $($item.Name)" -Level Debug
        continue
    }

    $response = Read-Host " "
    switch ($response.ToUpper()) {
        'Y' {
            Write-SOKLog "Installing: $($item.Name)" -Level Ignore

            # Step 1: Install via choco (installs to default C: location)
            if ($item.ChocoName) {
                Write-SOKLog "  choco install $($item.ChocoName) -y" -Level Debug
                & choco install $item.ChocoName -y 2>&1 | ForEach-Object {
                    $line = "$_".Trim()
                    if ($line -match 'successful|installed|error|fail') {
                        Write-SOKLog "  [choco] $line" -Level Debug
                    }
                }
            }

            # Step 2: If installed to C:, offload to E: with junction
            if (Test-Path $item.OrigPath) {
                $destPath = Join-Path $offloadBase $item.OffloadDir
                Write-SOKLog "  Offloading: $($item.OrigPath) → $destPath" -Level Ignore

                $roboArgs = @($item.OrigPath, $destPath, '/E', '/MOVE', '/R:1', '/W:2', '/MT:8', '/XJ', '/NP', '/NFL', '/NDL')
                & robocopy @roboArgs 2>&1 | Out-Null
                $roboExit = $LASTEXITCODE

                if ($roboExit -le 3 -and -not (Test-Path $item.OrigPath)) {
                    # Create junction
                    cmd /c "mklink /J `"$($item.OrigPath)`" `"$destPath`"" 2>&1 | Out-Null
                    if (Test-Path $item.OrigPath) {
                        Write-SOKLog "  Junction: $($item.OrigPath) → $destPath" -Level Success
                        $installed++
                    }
                    else {
                        Write-SOKLog "  Junction creation FAILED" -Level Error
                        $failed++
                    }
                }
                elseif (Test-Path $item.OrigPath) {
                    # Robocopy didn't fully move — items remain at source
                    # Remove source remnants and retry junction
                    Remove-Item $item.OrigPath -Recurse -Force -ErrorAction SilentlyContinue
                    if (-not (Test-Path $item.OrigPath)) {
                        cmd /c "mklink /J `"$($item.OrigPath)`" `"$destPath`"" 2>&1 | Out-Null
                        Write-SOKLog "  Junction (after cleanup): $($item.OrigPath) → $destPath" -Level Success
                        $installed++
                    }
                    else {
                        Write-SOKLog "  Robocopy exit $roboExit — source not fully moved" -Level Warn
                        $failed++
                    }
                }
                else {
                    Write-SOKLog "  Installed but source missing — choco may use different path" -Level Warn
                    $installed++
                }
            }
            else {
                Write-SOKLog "  choco installed but not at expected path — check manually" -Level Warn
                $installed++
            }
        }
        'S' {
            Write-SOKLog "SKIPPED: $($item.Name)" -Level Debug
            $skipped++
        }
        default {
            Write-SOKLog "SKIPPED: $($item.Name)" -Level Debug
            $skipped++
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
$results = [ordered]@{
    Installed = $installed
    Skipped   = $skipped
    Failed    = $failed
    DryRun    = $DryRun.IsPresent
}

Write-SOKSummary -Stats $results -Title 'REINSTALL COMPLETE'

if (Get-Command Save-SOKHistory -ErrorAction SilentlyContinue) {
    Save-SOKHistory -ScriptName 'SOK-Reinstall' -RunData @{
        Duration = [math]::Round(((Get-Date) - (Get-Date).AddSeconds(-1)).TotalSeconds, 1)
        Results  = $results
    }
}
