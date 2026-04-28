<#
.SYNOPSIS
    SOK-InfraFix.ps1 — One-shot infrastructure fixes from C: Restructuring Plan Tier 5.
.DESCRIPTION
    All fixes operator-approved. Run once, verify, retire to Deprecated when clean.
    1. Fix nvm4w broken junction
    2. Remove OneDrive UC orphan junction
    3. Neutralize Kibana node shim
    4. Move legacy History dir to Deprecated
    5. Fix Altair Python .py file association hijack
.NOTES
    Author: S. Clay Caddell
    Version: 1.1.0
    Date: 2026-04-04
    Domain: PAST — heals NTFS junctions and shims before Inventory/SpaceAudit read the filesystem
    Run as Administrator:
    pwsh -NoProfile -ExecutionPolicy Bypass -File .\SOK-InfraFix.ps1
    Add -DryRun to preview without changes.
#>
[CmdletBinding()]
param([switch]$DryRun)

#Requires -Version 7.0
#Requires -RunAsAdministrator

$modulePath = Join-Path $PSScriptRoot 'common\SOK-Common.psm1'
if (-not (Test-Path $modulePath)) { $modulePath = 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Common.psm1' }
if (Test-Path $modulePath) { Import-Module $modulePath -Force }

function Log { param([string]$Msg, [string]$Level = 'Ignore')
    if (Get-Command Write-SOKLog -ErrorAction SilentlyContinue) { Write-SOKLog $Msg -Level $Level }
    else { Write-Host "[$Level] $Msg" }
}

Write-Host "`n━━━ SOK INFRASTRUCTURE FIX ━━━" -ForegroundColor Cyan
if ($DryRun) { Log 'DRY RUN — no changes' -Level Warn }

# ── SYSTEM-CONTEXT PATH RESOLUTION ──
# H-8 fix 2026-04-21: Substrate Thesis portability via Resolve-RealUserProfile.
if ($env:USERPROFILE -like '*systemprofile*') {
    $realProfile = if (Get-Command Resolve-RealUserProfile -ErrorAction SilentlyContinue) {
        Resolve-RealUserProfile -Fallback 'C:\Users\shelc'
    } else { 'C:\Users\shelc' }
    $env:USERPROFILE  = $realProfile
    $env:LOCALAPPDATA = "$realProfile\AppData\Local"
    $env:APPDATA      = "$realProfile\AppData\Roaming"
    Log "[SYSTEM-CONTEXT] Remapped profile env vars to $realProfile" -Level Warn
}

$fixed = 0; $skipped = 0; $failed = 0

# ═══════════════════════════════════════════════════
# 1. nvm4w junction: C:\nvm4w\nodejs → C:\ProgramData\nvm\v24.14.0
# ═══════════════════════════════════════════════════
Log '1. nvm4w junction fix' -Level Section
$nvmSource = 'C:\nvm4w\nodejs'
$nvmTarget = 'C:\ProgramData\nvm\v24.14.0'
$nvmItem = Get-Item $nvmSource -ErrorAction SilentlyContinue
if ($nvmItem -and ($nvmItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
    $currentTarget = try { $nvmItem.Target } catch { 'unknown' }
    if (Test-Path $nvmTarget) {
        Log "  Already a junction → $currentTarget (target exists)" -Level Success
        $skipped++
    } else {
        Log "  Junction exists but target missing: $nvmTarget" -Level Warn
        if (-not $DryRun) {
            cmd /c "rmdir `"$nvmSource`"" 2>$null
            if (Test-Path $nvmTarget) {
                cmd /c "mklink /J `"$nvmSource`" `"$nvmTarget`"" 2>$null
                Log "  Repointed: $nvmSource → $nvmTarget" -Level Success; $fixed++
            } else { Log "  Target still missing after repoint" -Level Error; $failed++ }
        } else { Log "  [DRY] Would repoint junction" -Level Debug }
    }
} elseif ($nvmItem) {
    Log "  $nvmSource exists but is NOT a junction — removing and relinking" -Level Warn
    if (-not $DryRun) {
        Remove-Item $nvmSource -Recurse -Force -ErrorAction Continue
        if (-not (Test-Path $nvmSource) -and (Test-Path $nvmTarget)) {
            cmd /c "mklink /J `"$nvmSource`" `"$nvmTarget`"" 2>$null
            Log "  Junction created" -Level Success; $fixed++
        } else { Log "  Fix failed" -Level Error; $failed++ }
    } else { Log "  [DRY] Would delete + junction" -Level Debug }
} else {
    # Source doesn't exist — just create junction
    if (Test-Path $nvmTarget) {
        if (-not $DryRun) {
            $parent = Split-Path $nvmSource -Parent
            if (-not (Test-Path $parent)) { New-Item -Path $parent -ItemType Directory -Force | Out-Null }
            cmd /c "mklink /J `"$nvmSource`" `"$nvmTarget`"" 2>$null
            Log "  Created: $nvmSource → $nvmTarget" -Level Success; $fixed++
        } else { Log "  [DRY] Would create junction" -Level Debug }
    } else { Log "  Neither source nor target exist — skipping" -Level Annotate; $skipped++ }
}

# ═══════════════════════════════════════════════════
# 2. OneDrive UC orphan junction
# ═══════════════════════════════════════════════════
Log '2. OneDrive UC orphan' -Level Section
$oneDrivePath = 'C:\Users\shelc\OneDrive - University of Cincinnati'
if (Test-Path $oneDrivePath) {
    $odItem = Get-Item $oneDrivePath -ErrorAction SilentlyContinue
    if ($odItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        if (-not $DryRun) {
            cmd /c "rmdir `"$oneDrivePath`"" 2>$null
            if (-not (Test-Path $oneDrivePath)) {
                Log "  Removed orphan junction" -Level Success; $fixed++
            } else { Log "  rmdir failed — may need manual removal" -Level Error; $failed++ }
        } else { Log "  [DRY] Would remove orphan junction" -Level Debug }
    } else {
        Log "  Exists but is a real directory — NOT removing (manual review needed)" -Level Warn; $skipped++
    }
} else { Log "  Already gone" -Level Success; $skipped++ }

# ═══════════════════════════════════════════════════
# 3. Kibana node shim
# ═══════════════════════════════════════════════════
Log '3. Kibana node.exe shim' -Level Section
$kibanaShim = 'C:\ProgramData\chocolatey\bin\node.exe'
$kibanaShimBak = 'C:\ProgramData\chocolatey\bin\node.exe.bak'
if (Test-Path $kibanaShim) {
    # Verify it's the Kibana shim, not a real node
    $shimContent = try { Get-Content $kibanaShim -ErrorAction SilentlyContinue -TotalCount 1 } catch { $null }
    $isShim = $true  # chocolatey shims are always small executables
    $shimSize = (Get-Item $kibanaShim).Length
    if ($shimSize -gt 256KB) {
        Log "  node.exe is $([math]::Round($shimSize/1KB)) KB — too large for a shim, may be real node" -Level Warn
        $isShim = $false; $skipped++
    }
    if ($isShim) {
        if (-not $DryRun) {
            Rename-Item $kibanaShim $kibanaShimBak -Force -ErrorAction Continue
            if (Test-Path $kibanaShimBak) {
                Log "  Renamed: node.exe → node.exe.bak" -Level Success; $fixed++
            } else { Log "  Rename failed" -Level Error; $failed++ }
        } else { Log "  [DRY] Would rename node.exe → node.exe.bak" -Level Debug }
    }
} elseif (Test-Path $kibanaShimBak) {
    Log "  Already neutralized (node.exe.bak exists)" -Level Success; $skipped++
} else { Log "  Shim not found — nothing to do" -Level Success; $skipped++ }

# ═══════════════════════════════════════════════════
# 4. Legacy History dir → Deprecated
# ═══════════════════════════════════════════════════
Log '4. Legacy History dir' -Level Section
$legacyHistory = Join-Path $env:USERPROFILE 'Documents\Journal\Projects\SOK\History'
$deprecatedHistory = Join-Path $env:USERPROFILE 'Documents\Journal\Projects\SOK\Deprecated\History'
if (Test-Path $legacyHistory) {
    if (-not $DryRun) {
        $deprecatedParent = Split-Path $deprecatedHistory -Parent
        if (-not (Test-Path $deprecatedParent)) { New-Item -Path $deprecatedParent -ItemType Directory -Force | Out-Null }
        Move-Item $legacyHistory $deprecatedHistory -Force -ErrorAction Continue
        if (-not (Test-Path $legacyHistory)) {
            Log "  Moved: History → Deprecated\History" -Level Success; $fixed++
        } else { Log "  Move failed — files may be locked" -Level Warn; $failed++ }
    } else { Log "  [DRY] Would move to Deprecated\History" -Level Debug }
} else { Log "  Legacy History dir not found — already moved or never existed" -Level Success; $skipped++ }

# ═══════════════════════════════════════════════════
# 5. Altair Python .py file association hijack
#    Altair HyperWorks/MF registers its bundled python.exe as the default
#    handler for .py files, intercepting all Python script launches.
#    Fix: restore .py association to the py.exe launcher (PEP 397).
# ═══════════════════════════════════════════════════
Log '5. Altair Python .py file association' -Level Section
$altairPython = 'C:\Users\shelc\AppData\Local\Altair\MF\python.exe'
$pyLauncher   = (Get-Command py -ErrorAction SilentlyContinue)?.Source

# Check HKCU .py association (takes precedence over HKLM)
$pyAssocKey = 'HKCU:\Software\Classes\.py'
$pyAssoc    = (Get-ItemProperty $pyAssocKey -Name '(default)' -ErrorAction SilentlyContinue).'(default)'
$pyProgKey  = if ($pyAssoc) { "HKCU:\Software\Classes\$pyAssoc\shell\open\command" } else { $null }
$pyOpenCmd  = if ($pyProgKey -and (Test-Path $pyProgKey)) {
    (Get-ItemProperty $pyProgKey -Name '(default)' -ErrorAction SilentlyContinue).'(default)'
} else { $null }

$altairHijacked = $pyOpenCmd -and ($pyOpenCmd -match [regex]::Escape($altairPython))
$altairInPath   = $env:PATH -split ';' |
    Where-Object { $_ -match 'Altair' -and $_ -match 'MF' } |
    Select-Object -First 1

if ($altairHijacked) {
    Log "  .py association hijacked by Altair: $pyOpenCmd" -Level Warn
    if (-not $DryRun) {
        # Restore to py.exe launcher if available, otherwise bare py "%1" %*
        $correctCmd = if ($pyLauncher) { "`"$pyLauncher`" `"%1`" %*" } else { 'py.exe "%1" %*' }
        Set-ItemProperty $pyProgKey -Name '(default)' -Value $correctCmd -ErrorAction Continue
        $verify = (Get-ItemProperty $pyProgKey -Name '(default)' -ErrorAction SilentlyContinue).'(default)'
        if ($verify -eq $correctCmd) {
            Log "  Fixed .py association → $correctCmd" -Level Success; $fixed++
        } else {
            Log "  Set-ItemProperty ran but verify failed — check registry manually" -Level Error; $failed++
        }
    } else {
        Log "  [DRY] Would set HKCU .py association → py.exe launcher" -Level Debug
    }
} elseif ($pyOpenCmd) {
    Log "  .py association is OK: $pyOpenCmd" -Level Success; $skipped++
} else {
    Log "  .py association: no HKCU override found (using HKLM default)" -Level Success; $skipped++
}

if ($altairInPath) {
    Log "  Altair MF detected in PATH: $altairInPath" -Level Warn
    Log "  PATH order risk: Altair python.exe may intercept 'python' calls" -Level Warn
    Log "  Manual action: In System Properties > Environment Variables, move Altair MF entry" -Level Warn
    Log "                 below real Python in both User and System PATH." -Level Warn
    $skipped++
} else {
    Log "  Altair MF not in PATH — no PATH ordering risk" -Level Success; $skipped++
}

# ════════════════════════════════════════════��══════
# 6. Scoop shim availability check
#    Scoop installs apps to ~/scoop/apps/ but shims may be missing
#    if scoop was installed or updated in an unusual way.
# ═══════════════════════════════════════════════════
Log '6. Scoop shim availability' -Level Section
$scoopAppsDir = Join-Path $env:USERPROFILE 'scoop\apps'
$scoopShimsDir = Join-Path $env:USERPROFILE 'scoop\shims'
if (Test-Path $scoopAppsDir) {
    $scoopCmd = Join-Path $scoopShimsDir 'scoop.ps1'
    if (-not (Test-Path $scoopCmd)) {
        $scoopExe = Join-Path $env:USERPROFILE 'scoop\apps\scoop\current\bin\scoop.ps1'
        if (Test-Path $scoopExe) {
            Log "  Scoop apps present but shim missing at $scoopCmd" -Level Warn
            Log "  Fix: run 'Invoke-Expression (New-Object Net.WebClient).DownloadString(''https://get.scoop.sh'')' to repair" -Level Warn
            $failed++
        } else {
            Log "  Scoop apps dir exists but scoop binary not found — broken install" -Level Error; $failed++
        }
    } else {
        Log "  Scoop shim OK: $scoopCmd" -Level Success; $skipped++
    }
} else {
    Log "  Scoop not installed (no ~/scoop/apps/)" -Level Success; $skipped++
}

# ═══════════════════════════════════════════════════
# 7. Choco shim integrity (detect shims pointing to missing targets)
#    Choco shims are .exe stubs at C:\ProgramData\chocolatey\bin\
#    that redirect to the real executable. If the target is uninstalled
#    or moved, the shim errors with "Cannot find file at..."
# ═══════════════════════════════════════════════════
Log '7. Choco shim integrity spot-check' -Level Section
$chocoShimsDir = 'C:\ProgramData\chocolatey\bin'
if (Test-Path $chocoShimsDir) {
    $brokenShims = @()
    # Check the most common shims for broken targets
    $shimCheckList = @('pandoc.exe', 'node.exe', 'python.exe', 'ruby.exe')
    foreach ($shimName in $shimCheckList) {
        $shimPath = Join-Path $chocoShimsDir $shimName
        $shimGui = Join-Path $chocoShimsDir "$($shimName -replace '\.exe$', '.gui')"
        if (Test-Path $shimPath) {
            # Try to invoke with --version to test if target exists
            $result = try { & $shimPath --version 2>&1 | Select-Object -First 1; $true } catch { $false }
            if (-not $result -or ($result -is [System.Management.Automation.ErrorRecord])) {
                Log "  BROKEN shim: $shimName (target missing or error)" -Level Warn
                $brokenShims += $shimName
            }
        }
    }
    if ($brokenShims.Count -gt 0) {
        Log "  $($brokenShims.Count) broken shim(s) detected: $($brokenShims -join ', ')" -Level Warn
        Log "  Fix: choco uninstall <package> or verify target paths" -Level Warn
        $failed += $brokenShims.Count
    } else {
        Log "  Checked $($shimCheckList.Count) common shims — all OK or absent" -Level Success; $skipped++
    }
} else {
    Log "  Chocolatey not installed (no bin dir)" -Level Success; $skipped++
}

# ═══════════════════════════════════════════════════
# 8. Rust shim PATH append (FIX-6 candidate per project_sok.md, 2026-04-21)
#    Scoop's rustup/cargo shims at ~/scoop/shims/ fail --version under automation
#    (intermittent PATH resolution issue in Scoop 0.5.x+). Authoritative fix:
#    add Scoop's active-rust bin dir directly to the User PATH so cargo/rustc
#    resolve without the shim layer. Idempotent: does nothing if the path is
#    already on User PATH or if the rust dir doesn't exist.
# ═══════════════════════════════════════════════════
Log '8. Rust shim PATH append' -Level Section
$rustBin = Join-Path $env:USERPROFILE 'scoop\apps\rust\current\bin'
if (-not (Test-Path $rustBin)) {
    Log "  Rust scoop app not present at $rustBin — skipping" -Level Ignore; $skipped++
} else {
    # Read current User PATH (NOT the process PATH) — we want persistence
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $userPathSegments = @($userPath -split ';' | Where-Object { $_ })
    $alreadyPresent = $userPathSegments |
        Where-Object { $_.TrimEnd('\') -ieq $rustBin.TrimEnd('\') } |
        Select-Object -First 1
    if ($alreadyPresent) {
        Log "  Rust bin already on User PATH: $rustBin" -Level Success; $skipped++
    } else {
        if ($DryRun) {
            Log "  [DRY] Would append to User PATH: $rustBin" -Level Debug
        } else {
            try {
                $newPath = if ([string]::IsNullOrEmpty($userPath)) { $rustBin }
                           else { "$($userPath.TrimEnd(';'));$rustBin" }
                [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
                # Also update current process PATH so this session sees the change
                $env:Path = "$env:Path;$rustBin"
                Log "  Appended to User PATH: $rustBin" -Level Success; $fixed++
                Log "  Open a NEW terminal to pick up the PATH change in child processes." -Level Annotate
            } catch {
                Log "  PATH append FAILED: $($_.Exception.Message)" -Level Error; $failed++
            }
        }
    }
}

# ═══════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════
Log 'SUMMARY' -Level Section
Log 'INFRASTRUCTURE FIX COMPLETE' -Level Section
Log "  Fixed:   $fixed" -Level $(if ($fixed -gt 0) { 'Success' } else { 'Ignore' })
Log "  Skipped: $skipped" -Level Ignore
Log "  Failed:  $failed" -Level $(if ($failed -gt 0) { 'Error' } else { 'Success' })
if ($DryRun) { Log '  (DRY RUN — no changes were made)' -Level Warn }
