
### LATEST
#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-BareMetal v5.3 FINAL — Exhaustive Bare-Metal Restoration
    Host: <HOST> | User: <USER> | Zero-State Assumption
    <DRIVE-TOPOLOGY>
.DESCRIPTION
    Complete reconstruction of the operator environment from a zero-state machine.
    Purges hostile/conflicting applications. Installs 220+ tools across Choco,
    Winget, Scoop, Pip, NPM, Cargo, Go, and PSModules. Generates all Docker
    Compose stacks, writes config files, starts services, and runs a verification
    pass with full JSON state logging.
    PREREQUISITE: Run from pwsh 7+ (NOT Windows PowerShell 5.1).
      Install PS7 first: winget install Microsoft.PowerShell
      Then: pwsh -ExecutionPolicy Bypass -File .\SOK-BareMetal_v5.3.ps1
    Run order: v3 -> v4 -> v5.3 (each is idempotent; safe to re-run in isolation).
    All Install-* calls are skip-if-present. All batches pause for operator Y/N.
    ================================================================
    CHANGELOG v5.3 (Rebuild Pass — 2026-04-02)
    Inherits all 75 fixes from v5.2. New in this pass:
    ================================================================
    FIX-77  try/catch/finally block properly closed.
            v5.2 opened try{ at init but never closed it. Export-State and
            Stop-Transcript were in the try body — a mid-script crash skipped
            both. The finally block is now the sole authoritative cleanup path
            on both clean exit and crash.
    FIX-78  Batch 6 (Docker stacks) implemented.
            New-DockerStack was defined in v5.2 but never called. All 10 stacks
            now written: Portainer, Vaultwarden, Observability, OpenVAS,
            Spark+Jupyter, Neo4j+APOC+GDS, Hive, Kafka+UI, Atlantis (.env
            template included per FIX-60), GitLab CE.
    FIX-79  Batch 7 (Verification pass) implemented.
            Command spot-checks, Python package spot-checks via pip show,
            Docker stack file existence checks, PostgreSQL service check,
            Ghidra file-presence check (FIX-57 pattern).
    FIX-80  Markdown prose stripped from .ps1 body.
            v5.2 lines 888-915 were markdown documentation embedded after the
            script body. The *** separator is invalid PS syntax — causes a
            parse error on script load before any execution. Historical context
            preserved inside this synopsis block only.
    FIX-81  Python version updated: 3.13 -> 3.14 throughout.
            <HOST> runs py -3.14; py -3.13 is uninstalled (stale launcher
            entry). Affects: winget install ID, all py -m pip invocations,
            NOTE-G, and Batch 7 verification.
    FIX-82  NPM global packages added to Batch 5.
            Batch 5 header declared NPM but no npm installs existed in v5.2.
    FIX-83  Cargo installs added to Batch 5.
            mise (version manager) via cargo, fulfilling FIX-63 intent.
    FIX-84  Go installs added to Batch 5.
            trufflehog authoritative path per FIX-74. go tooling suite added.
    FIX-85  ActiveDirectory + GroupPolicy: Install-Module -> Add-WindowsCapability.
            PSGallery ActiveDirectory is not a proper PS module — RSAT capability
            is the correct install path. FIX-09 documented this but left
            "ActiveDirectory" in $psMods, routing it through Install-Module.
            Both capabilities now handled via Add-WindowsCapability with
            optional $RSATSource for air-gapped machines.
    FIX-86  SecretManagement -> Microsoft.PowerShell.SecretManagement.
            Short name caused PSGallery ambiguity. FIX-10 documented this
            but the fix was never applied to the $psMods array.
    FIX-87  Invoke-BatchPause added to end of Batch 5.
            Batch 5 lacked operator pause, operator Y/N confirmation, and
            refreshenv call at batch close — inconsistent with all other batches.
    FIX-88  Duplicate Qemu removed from Batch 5.
            choco qemu already installed in Batch 4 (FIX-42). Case-variant
            duplicate Invoke-Package "choco" "Qemu" in Batch 5 is a no-op
            that signals copy-paste drift. Removed.
    FIX-89  Duplicate consul + packer removed from Batch 4.
            Both installed in Batch 2 (HashiCorp). Idempotency catches them
            but signals copy-paste origin. Removed from Batch 4.
    FIX-90  GitLab port conflicts resolved.
            Port 80:80 conflicts with IIS (enabled in pre-flight features).
            GitLab mapped to 8929:80, 8930:443, 2289:22.
    FIX-91  Vaultwarden port conflict resolved.
            Port 8080 conflicts with Kafka-UI (8090:8080) and Spark webui
            mapping. Vaultwarden shifted to 8081:80.
    FIX-92  jinja2 + dnspython deduplication in pip arrays.
            jinja2 in both $pipCore and $pipEng; dnspython in both $pipEng
            and $pipSec. Select-Object -Unique handled it at runtime but
            source arrays cleaned for clarity and intent.
    ================================================================
    DOCKER STACKS (Batch 6 — written to C:\Admin\Docker\):
    Stack              Path                          Access
    ------------------ ----------------------------- -------------------------
    Portainer          Docker\portainer\             https://localhost:9443
    Vaultwarden        Docker\vaultwarden\           http://localhost:8081
    Observability      Docker\observability\         http://localhost:3000
    OpenVAS            Docker\openvas\               https://localhost:9392
    Spark + Jupyter    Docker\spark\                 http://localhost:8888
    Neo4j + APOC/GDS   Docker\neo4j\                 http://localhost:7474
    Apache Hive        Docker\hive\                  :9083 / :10000
    Kafka + UI         Docker\kafka\                 http://localhost:8090
    Atlantis           Docker\atlantis\              http://localhost:4141
    GitLab CE          Docker\gitlab\                http://localhost:8929
    Start any stack: docker compose -f C:\Admin\Docker\<name>\docker-compose.yml up -d
    ================================================================
    NOTE-A  Notion excluded: data sovereignty on cleared/DoD-PKI machine.
            Manual install if personal-use only: winget install Notion.Notion
    NOTE-B  AV removal: if auto-purge fails, use vendor tools.
            Avast Clear: https://www.avast.com/uninstall-utility
            AVG Remover: https://www.avg.com/en-us/uninstallation-tool
    NOTE-C  torch installed CPU-only (safe default). Post-CUDA restore:
            py -3.14 -m pip install torch --index-url https://download.pytorch.org/whl/cu121
    NOTE-E  Ansible as CONTROL NODE does not support Windows. Use WSL2 for
            running playbooks. As a MANAGED NODE (target of Linux controller)
            it works via WinRM + pywinrm — those pip packages are in the stack.
    NOTE-F  docker-cli vs podman-docker: Podman 4.x ships a Docker-compatible
            shim. Both installed for maximum compatibility.
    NOTE-G  Python version management: script installs Python 3.14 via winget
            (Python.Python.3.14 — PSF official). The Python Launcher (py.exe)
            handles multi-version dispatch. All pip calls use py -3.14 -m pip.
            For additional versions: winget install Python.Python.3.X
#>
[CmdletBinding()]
param(
    # DryRun: enumerate all packages and stacks that WOULD be installed/written
    # without actually running installers, enabling/purging features, or writing files.
    # Batch pauses auto-continue. Use for test-sequencing validation.
    [switch]$DryRun
)
# =============================================================================
# INITIALIZATION
# =============================================================================
$ErrorActionPreference  = "Continue"
$VerbosePreference      = "Continue"
$ProgressPreference     = "SilentlyContinue"   # prevents progress bar in logs
$logDir = "C:\Admin\Logs\V5_Restore_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path "$logDir\Verbose_Terminal_Output.txt" -Append
$state = @{
    ExecutionStart = (Get-Date -Format "o")
    Purged  = [System.Collections.Generic.List[string]]::new()
    Success = [System.Collections.Generic.List[string]]::new()
    Failed  = [System.Collections.Generic.List[string]]::new()
    Skipped = [System.Collections.Generic.List[string]]::new()
}
# FIX-38: Set to WIM/local path for offline RSAT on air-gapped/cleared machine.
$RSATSource = $null
# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
function Write-Console {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $colors = @{ INFO="Cyan"; OK="Green"; ERROR="Red"; PURGE="Magenta"; WARN="Yellow"; SECTION="White" }
    # FIX-46: ?? is PS7+ only; #Requires -Version 7.0 enforces this above.
    Write-Host "[$ts] [$Level] $Message" -ForegroundColor ($colors[$Level] ?? "White")
}
function Export-State {
    $state.ExecutionLastUpdate = (Get-Date -Format "o")
    if (-not $DryRun) {
        $state | ConvertTo-Json -Depth 4 |
            Out-File "$logDir\v5_environment_state.json" -Encoding utf8 -Force
        Write-Console "State saved: $logDir\v5_environment_state.json" "OK"
    } else {
        Write-Console "DRY RUN: State not written (would save $logDir\v5_environment_state.json)" "WARN"
    }
}
# FIX-01: Registry-based detection — instant, no MSI reconfiguration side effects
function Get-InstalledAppByRegistry {
    param([string]$AppName)
    @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    ) | ForEach-Object {
        Get-ItemProperty $_ -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -match [regex]::Escape($AppName) } |
            Select-Object -First 1
    } | Where-Object { $_ } | Select-Object -First 1
}
# FIX-47: Creates parent directory before writing compose file
# FIX-93: Skip-if-exists — never overwrite customized compose files on re-run.
# Delete the file manually to force regeneration.
function New-DockerStack {
    param([string]$StackName, [string]$ComposeYaml, [string]$EnvTemplate = "")
    $stackDir = "C:\Admin\Docker\$StackName"
    if ($DryRun) {
        Write-Console "DRY RUN: Would write stack $StackName to $stackDir\docker-compose.yml" "WARN"
        return
    }
    New-Item -ItemType Directory -Path $stackDir -Force | Out-Null
    $composePath = "$stackDir\docker-compose.yml"
    if (Test-Path $composePath) {
        Write-Console "SKIP (exists): $composePath — delete to regenerate" "WARN"
    } else {
        $ComposeYaml | Out-File $composePath -Force -Encoding UTF8
        Write-Console "Stack written: $composePath" "OK"
    }
    if ($EnvTemplate) {
        $envPath = "$stackDir\.env.template"
        if (Test-Path $envPath) {
            Write-Console "SKIP (exists): $envPath" "WARN"
        } else {
            $EnvTemplate | Out-File $envPath -Force -Encoding UTF8
            Write-Console "Env template: $envPath  (copy to .env and populate)" "WARN"
        }
    }
}
# FIX-02/37: Vendor-aware + winget-path uninstall routing
function Invoke-AppPurge {
    param([string]$AppName, [string]$ChocoPackage = "", [string]$FallbackNote = "")
    if ($DryRun) { Write-Console "DRY RUN: Would purge $AppName" "PURGE"; return }
    Write-Console "PURGE: Checking for $AppName..." "PURGE"
    # Attempt 1: choco (fastest if choco-managed)
    if ($ChocoPackage -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        $chocoHit = (choco list $ChocoPackage --localonly --exact --no-color 2>&1) -split "\r?\n" |
                    Where-Object { $_ -match "^$([regex]::Escape($ChocoPackage))\s" }
        if ($chocoHit) {
            Write-Console "Removing via Chocolatey: $ChocoPackage" "PURGE"
            choco uninstall $ChocoPackage -y --no-progress 2>&1 | Out-Null
            $state.Purged.Add("choco:$ChocoPackage"); return
        }
    }
    # Attempt 2: winget (FIX-37; FIX-50: --no-upgrade removed — invalid flag)
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $wgHit = winget list --id $AppName --exact 2>&1
        if ($LASTEXITCODE -eq 0 -and ($wgHit -split "\r?\n") | Where-Object { $_ -match [regex]::Escape($AppName) }) {
            Write-Console "Removing via winget: $AppName" "PURGE"
            winget uninstall --id $AppName --exact --silent 2>&1 | Out-Null
            $state.Purged.Add("winget:$AppName"); return
        }
    }
    # Attempt 3: Registry -> QuietUninstallString
    $app = Get-InstalledAppByRegistry $AppName
    if ($app) {
        Write-Console "Found via registry: $($app.DisplayName)" "PURGE"
        $uStr = if ($app.QuietUninstallString) { $app.QuietUninstallString } else { $app.UninstallString }
        if ($uStr -match "msiexec" -and $uStr -match "\{[0-9A-Fa-f\-]+\}") {
            Start-Process "msiexec.exe" -ArgumentList "/x $($Matches[0]) /qn /norestart" -Wait -NoNewWindow
        } elseif ($uStr) {
            Start-Process "cmd.exe" -ArgumentList "/c `"$uStr`"" -Wait -NoNewWindow
        }
        $state.Purged.Add($AppName); Write-Console "Purged: $AppName" "OK"; return
    }
    Write-Console "$AppName not found. Clean." "OK"
    if ($FallbackNote) { Write-Console "  Note: $FallbackNote" "WARN" }
}
# Core install dispatcher — FIX-18 ($ExtraArgs), FIX-19 (per-line choco regex),
# FIX-50 (winget idempotency), FIX-36 (winget pre-check), FIX-81 (py -3.14)
function Invoke-Package {
    param([string]$Manager, [string]$Package, [string]$ExtraArgs = "")
    if ($DryRun) { Write-Console "DRY RUN: Would install $Manager`:$Package" "INFO"; return }
    Write-Console "$Manager >> $Package" "INFO"
    try {
        $success = $false
        if ($Manager -eq "choco") {
            # FIX-19: split on newlines; match per line to catch all installed entries
            $rawList = choco list $Package --localonly --exact --no-color 2>&1
            $alreadyInstalled = ($rawList -split "\r?\n") |
                Where-Object { $_ -match "^$([regex]::Escape($Package))\s" }
            if ($alreadyInstalled) {
                Write-Console "SKIP (installed): $Package" "OK"
                $state.Skipped.Add("choco:$Package"); return
            }
            $proc = Start-Process "choco" `
                -ArgumentList "install $Package -y --no-progress --ignore-checksums $ExtraArgs" `
                -Wait -PassThru -NoNewWindow
            $success = $proc.ExitCode -in @(0, 1641, 2359302)
            if (-not $success) { throw "Exit code $($proc.ExitCode)" }
        }
        elseif ($Manager -eq "winget") {
            # FIX-50: removed --no-upgrade (invalid flag); FIX-36: pre-check
            $wgList = winget list --id $Package --exact 2>&1
            if ($LASTEXITCODE -eq 0 -and
                (($wgList -split "\r?\n") | Where-Object { $_ -match [regex]::Escape($Package) })) {
                Write-Console "SKIP (installed): $Package" "OK"
                $state.Skipped.Add("winget:$Package"); return
            }
            $proc = Start-Process "winget" `
                -ArgumentList "install --id $Package --exact --silent --accept-package-agreements --accept-source-agreements $ExtraArgs" `
                -Wait -PassThru -NoNewWindow
            $success = $proc.ExitCode -eq 0
            if (-not $success) { throw "Exit code $($proc.ExitCode)" }
        }
        elseif ($Manager -eq "scoop") {
            if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                throw "Scoop not in PATH. Re-run Batch 1 to install Scoop first."
            }
            $proc = Start-Process "scoop" -ArgumentList "install $Package" -Wait -PassThru -NoNewWindow
            $success = $proc.ExitCode -eq 0
            if (-not $success) { throw "Exit code $($proc.ExitCode)" }
        }
        elseif ($Manager -eq "pip") {
            # FIX-81: py -3.14 (was py -3.13; <HOST> runs 3.14, 3.13 is uninstalled)
            # Avoids Altair embedded Python collision (v4 FLAG 5)
            $proc = Start-Process "py" `
                -ArgumentList "-3.14 -m pip install --upgrade --quiet $Package" `
                -Wait -PassThru -NoNewWindow
            $success = $proc.ExitCode -eq 0
            if (-not $success) { throw "pip exit code $($proc.ExitCode)" }
        }
        elseif ($Manager -eq "npm") {
            # FIX-21: @-scoped packages need inner quoting to survive ArgumentList tokenization
            $pkgArg = if ($Package.StartsWith("@")) { "`"$Package`"" } else { $Package }
            $proc = Start-Process "npm" -ArgumentList "install -g $pkgArg" -Wait -PassThru -NoNewWindow
            $success = $proc.ExitCode -eq 0
            if (-not $success) { throw "npm exit code $($proc.ExitCode)" }
        }
        elseif ($Manager -eq "cargo") {
            if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
                throw "cargo not in PATH. Open a new terminal after Rustup install, then re-run."
            }
            $proc = Start-Process "cargo" -ArgumentList "install $Package $ExtraArgs" -Wait -PassThru -NoNewWindow
            $success = $proc.ExitCode -eq 0
            if (-not $success) { throw "cargo exit code $($proc.ExitCode)" }
        }
        elseif ($Manager -eq "go") {
            if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
                throw "go not in PATH. PATH refresh required after golang install."
            }
            $proc = Start-Process "go" -ArgumentList "install ${Package}@latest" -Wait -PassThru -NoNewWindow
            $success = $proc.ExitCode -eq 0
            if (-not $success) { throw "go exit code $($proc.ExitCode)" }
        }
        elseif ($Manager -eq "psmodule") {
            # FIX-14: explicit success tracking
            $existing = Get-Module -ListAvailable -Name $Package -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Console "SKIP (installed): $Package" "OK"
                $state.Skipped.Add("psmodule:$Package"); return
            }
            Install-Module -Name $Package -Force -AllowClobber -Scope AllUsers -ErrorAction Stop
            $success = $true
        }
        $state.Success.Add("$Manager`:$Package")
        Write-Console "OK: $Package" "OK"
    } catch {
        $state.Failed.Add("$Manager`:$Package | $_")
        Write-Console "FAILED: $Package ($Manager) — $_" "ERROR"
    }
}
function Invoke-BatchPause {
    param([string]$BatchName)
    Export-State
    if ($DryRun) {
        Write-Console "DRY RUN: Auto-proceeding past batch '$BatchName'" "WARN"
        return
    }
    # FIX-12: Refresh PATH after each batch (propagates new installs into session)
    if (Get-Command refreshenv -ErrorAction SilentlyContinue) {
        refreshenv 2>&1 | Out-Null
        Write-Console "Environment variables refreshed." "OK"
    }
    Write-Host "`n$('=' * 72)" -ForegroundColor DarkCyan
    Write-Host "  BATCH COMPLETE : $BatchName" -ForegroundColor White
    Write-Host "  Success: $($state.Success.Count)  |  Skipped: $($state.Skipped.Count)  |  Failed: $($state.Failed.Count)" -ForegroundColor White
    Write-Host "$('=' * 72)" -ForegroundColor DarkCyan
    $ans = Read-Host "Proceed to next batch? (Y to continue / N or Exit to halt safely)"
    if ($ans -match "^[NnEe]") {
        Write-Console "Operator halted. State saved." "WARN"
        Export-State; Stop-Transcript; exit
    }
}
# =============================================================================
# MAIN BODY — try/finally guarantees Export-State + Stop-Transcript on crash
# =============================================================================
try {
# =============================================================================
# PRE-FLIGHT: DIRECTORY TREE + WINDOWS FEATURES
# =============================================================================
Write-Console "=== PRE-FLIGHT: Environment Bootstrap ===" "SECTION"
# Create full C:\Admin\ tree (FIX-25 from v5.1)
$adminDirs = @(
    "C:\Admin", "C:\Admin\Scripts", "C:\Admin\Logs", "C:\Admin\Backups",
    "C:\Admin\Documentation", "C:\Admin\Tools", "C:\Admin\Temp",
    "C:\Admin\Docker", "C:\Admin\Certs", "C:\Admin\Keys", "C:\Admin\ISOs",
    "C:\Admin\OSINT", "C:\Admin\Forensics", "C:\Admin\AI", "C:\Admin\IaC",
    "C:\Admin\Config"
)
foreach ($d in $adminDirs) {
    if ($DryRun) { Write-Console "DRY RUN: Would create dir $d" "INFO"; continue }
    New-Item -ItemType Directory -Path $d -Force | Out-Null
    Write-Console "Dir: $d" "OK"
}
# FIX-30 + FIX-72: Windows Features — MUST happen before Batch 4 containerization tools.
# IMPORTANT: These features require a reboot to fully activate.
# wsl --install is noted here but executed in Batch 4 with a clear reboot advisory.
Write-Console "Enabling Windows Features (reboot required to activate WSL2)..." "WARN"
$winFeatures = @(
    "Microsoft-Windows-Subsystem-Linux",   # WSL2 — required by nerdctl, podman, containerd
    "VirtualMachinePlatform",              # WSL2 second prerequisite
    "HypervisorPlatform",                  # Hyper-V platform (not full Hyper-V server role)
    "TelnetClient",                        # Basic network diagnostics
    "TFTP",                                # Router/switch TFTP config backup
    "IIS-WebServerRole",                   # IIS web server role
    "IIS-WebServer",
    "IIS-ManagementConsole"
)
foreach ($feat in $winFeatures) {
    $current = Get-WindowsOptionalFeature -Online -FeatureName $feat -ErrorAction SilentlyContinue
    if ($DryRun) {
        Write-Console "DRY RUN: Would enable feature $feat" "INFO"
    } elseif ($current -and $current.State -eq "Enabled") {
        Write-Console "SKIP (enabled): $feat" "OK"
    } else {
        try {
            Enable-WindowsOptionalFeature -Online -FeatureName $feat -NoRestart -All 2>&1 | Out-Null
            Write-Console "OK: $feat (reboot required to activate)" "OK"
        } catch {
            Write-Console "FAIL: $feat — $_" "ERROR"
        }
    }
}
# =============================================================================
# PHASE 0: HOSTILE ENVIRONMENT PURGE
# =============================================================================
Write-Console "=== PHASE 0: Hostile Application Purge ===" "SECTION"
Write-Console "Registry-based detection (not Win32_Product). See FIX-01 v5_QA." "INFO"
# AV conflicts — 5 products competing for kernel-level filesystem hooks.
# Avast/AVG/Avira use self-protection drivers that block generic MSI removal.
# If auto-purge fails: use vendor-specific removal tools (see NOTE-B).
Invoke-AppPurge "Avast Free Antivirus" -ChocoPackage "avast-free-antivirus" `
    -FallbackNote "Avast Clear: https://www.avast.com/uninstall-utility (standalone, USB-bootable)"
Invoke-AppPurge "AVG Protection" -ChocoPackage "avg-free" `
    -FallbackNote "AVG Remover: https://www.avg.com/en-us/uninstallation-tool"
Invoke-AppPurge "Avira Security" -ChocoPackage "avira-free-antivirus" `
    -FallbackNote "Avira uninstaller via Control Panel. Note: Avast owns AVG — both doubly redundant."
# Non-AV deprecations
Invoke-AppPurge "BlueStacks App Player" -ChocoPackage "bluestacks" `
    -FallbackNote "Unnecessary attack surface on cleared machine. Use Android Studio AVD or physical device."
Invoke-AppPurge "Guardian Browser" `
    -FallbackNote "Exam proctoring browser. Restore per-exam from Meazure Learning portal."
# Docker Desktop -> replaced by Podman Desktop (daemon-less, rootless, no licensing)
# NOTE-F: podman-docker shim provides 'docker' CLI alias after podman-desktop install.
Invoke-AppPurge "Docker Desktop" -ChocoPackage "docker-desktop" `
    -FallbackNote "Replaced by Podman Desktop in Batch 4. docker-cli also installed for full compat."
Write-Console "Phase 0 complete. Review console for any AV requiring manual removal." "WARN"
# =============================================================================
# BATCH 1: CORE SUBSTRATE — LANGUAGES, BUILD TOOLS, CORE SYSADMIN (~22 GB)
# =============================================================================
Write-Console "=== BATCH 1: Core Substrate, Languages & Foundation ===" "SECTION"
# Establish package managers first
Set-ExecutionPolicy Bypass -Scope Process -Force
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Console "Installing Chocolatey..." "INFO"
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
        'https://community.chocolatey.org/install.ps1'))
    Write-Console "Chocolatey installed." "OK"
} else {
    choco upgrade chocolatey -y --no-progress 2>&1 | Out-Null
    Write-Console "Chocolatey upgraded." "OK"
}
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Console "Installing Scoop (user-space, -RunAsAdmin for system shims)..." "INFO"
    Invoke-Expression "& {$(irm get.scoop.sh)} -RunAsAdmin"
} else { Write-Console "Scoop present." "OK" }
# FIX-58: PS7 — installs for subsequent restores; zero-state bootstrap must be manual.
# On zero-state: winget install Microsoft.PowerShell from PS5.1 terminal, then re-run this script in pwsh.
Invoke-Package "winget" "Microsoft.PowerShell"       # pwsh 7 — bootstraps future re-runs
# Languages — version-controlled, explicit versioning
# FIX-48/81: Python via winget (Python.Python.3.14) — PSF official. <HOST> runs 3.14; 3.13 uninstalled.
Invoke-Package "winget" "Python.Python.3.14"
Invoke-Package "winget" "Rustlang.Rustup"            # winget path avoids Scoop shim bug (v4 FIX)
Invoke-Package "choco"  "git"
Invoke-Package "choco"  "nodejs-lts"
Invoke-Package "choco"  "golang"
Invoke-Package "choco"  "ruby"
Invoke-Package "choco"  "dotnet-sdk"
# FIX-64: conda init after miniconda3 install — needed for conda to appear in PATH
Invoke-Package "choco" "miniconda3"
if (Get-Command conda -ErrorAction SilentlyContinue) {
    conda init pwsh 2>&1 | Out-Null
    Write-Console "conda init pwsh executed. PATH active after next shell session." "OK"
} else {
    Write-Console "WARN: conda not in PATH yet. Will check again in Batch 2 after refreshenv." "WARN"
}
# Java multi-version
# FIX-03: jre8 removed — stale alias of javaruntime. javaruntime + jdk8 are distinct.
Invoke-Package "choco" "javaruntime"    # Oracle JRE 8 — runtime only; legacy app compat
Invoke-Package "choco" "jdk8"          # Oracle JDK 8 — full SDK; Maven/compile targets
Invoke-Package "choco" "Temurin17"     # Eclipse Temurin LTS 17 — Jenkins, Spring Boot, Kafka
Invoke-Package "choco" "Temurin21"     # Eclipse Temurin LTS 21 — current LTS
# Scientific / functional / scripting languages
Invoke-Package "choco" "R.Project"
Invoke-Package "choco" "r.studio"
Invoke-Package "choco" "julia"
Invoke-Package "choco" "php"
Invoke-Package "choco" "dart-sdk"
Invoke-Package "choco" "flutter"
Invoke-Package "choco" "erlang"
Invoke-Package "choco" "elixir"
Invoke-Package "choco" "ghc"
Invoke-Package "choco" "cabal"
Invoke-Package "choco" "lua"
Invoke-Package "choco" "nim"
Invoke-Package "choco" "racket"
Invoke-Package "choco" "sbcl"
Invoke-Package "choco" "scala"
# C/C++/Systems build toolchain
Invoke-Package "choco" "msys2"
Invoke-Package "choco" "mingw"
Invoke-Package "choco" "cmake"
Invoke-Package "choco" "make"
Invoke-Package "choco" "ninja"
Invoke-Package "choco" "llvm"
Invoke-Package "choco" "strawberryperl"     # Required for some OpenSSL/C build chains
Invoke-Package "choco" "bazel"              # Google build system — Android/Java/Scala
# CORE SYSADMIN FOUNDATION
Invoke-Package "choco"  "7zip"
Invoke-Package "choco"  "everything"            # Instant NTFS MFT file search
Invoke-Package "choco"  "vscode"
Invoke-Package "choco"  "notepadplusplus"
Invoke-Package "choco"  "sublimetext4"          # Shareware — indefinite trial; keep for speed on large files
Invoke-Package "choco"  "putty"
Invoke-Package "choco"  "winscp"
Invoke-Package "choco"  "filezilla"
Invoke-Package "choco"  "keepassxc"
Invoke-Package "choco"  "bitwarden"
Invoke-Package "choco"  "crystaldiskinfo"
Invoke-Package "choco"  "crystaldiskmark"
Invoke-Package "choco"  "hwinfo"
Invoke-Package "choco"  "processhacker"         # Advanced process/kernel monitor — superior Task Manager
Invoke-Package "choco"  "windirstat"
Invoke-Package "choco"  "wiztree"               # Fastest disk analyzer — reads MFT directly
Invoke-Package "choco"  "mremoteng"             # Multi-protocol remote manager (RDP/SSH/VNC/Telnet)
Invoke-Package "choco"  "ditto"                 # Clipboard manager with search
Invoke-Package "choco"  "greenshot"             # Screenshot with annotation
Invoke-Package "choco"  "sharex"                # Advanced capture with OCR and workflows
Invoke-Package "choco"  "vlc"
Invoke-Package "choco"  "obs-studio"            # Screen recording — runbook videos, training material
Invoke-Package "choco"  "sysinternals"          # ADExplorer, PsTools, Autoruns, RAMMap, TCPView, etc.
Invoke-Package "choco"  "powertoys"
Invoke-Package "choco"  "neovim"
Invoke-Package "choco"  "lazygit"
# VPN tools
Invoke-Package "choco"  "openvpn"
Invoke-Package "choco"  "wireguard"
Invoke-Package "winget" "Tailscale.Tailscale"
# Cloud CLIs (FIX-29: pip SDKs without CLIs break most DevOps workflows)
Invoke-Package "choco"  "awscli"
Invoke-Package "choco"  "azure-cli"
Invoke-Package "winget" "Google.CloudSDK"
# Node version manager (FIX-53: only in Batch 1 — removed from Batch 4)
Invoke-Package "choco" "nvm"
# Certificate management (FIX-69: in v3, missing from v5.1)
Invoke-Package "choco" "certbot"    # Let's Encrypt cert automation
Invoke-Package "choco" "step"       # Smallstep internal CA management
# FIX-68: 2FA tools (replaced discontinued Authy Desktop, present in v3)
Invoke-Package "choco"  "winauth"              # FOSS TOTP authenticator
Invoke-Package "winget" "EnteIO.EnteAuth"      # E2EE TOTP with cloud backup
# Backup tools (FIX-66: in v3, critical for DR on zero-state restore)
Invoke-Package "choco" "restic"                # Fast deduplicating backup with encryption
Invoke-Package "choco" "rclone"                # Sync to 40+ cloud providers (rsync for cloud)
Invoke-Package "choco" "kopia"                 # Modern backup with web UI
# Communications (FIX-67: slack in v3 confirmed installed, absent from v5.1)
Invoke-Package "choco" "slack"
Invoke-Package "choco" "microsoft-teams"
Invoke-BatchPause "Batch 1: Core Substrate, Languages & Foundation"
# =============================================================================
# BATCH 2: DATA, ML, AI, GIS, DATABASES, ELK, OBSERVABILITY, HASHICORP (~42 GB)
# =============================================================================
Write-Console "=== BATCH 2: Data / ML / AI / Infra Convergence ===" "SECTION"
# Databases (FIX-70: pgadmin4 moved here from Batch 5 — belongs with DB tools)
Invoke-Package "choco"  "postgresql15"
# FIX-51: Array-safe PostgreSQL service check
# Get-Service with wildcard can return array; check each element for Running status
$pgRunning = Get-Service "postgresql*" -ErrorAction SilentlyContinue |
             Where-Object { $_.Status -eq "Running" }
if ($pgRunning) {
    Invoke-Package "choco" "postgis"    # PostGIS — install AFTER pg15 is confirmed running
} else {
    Write-Console "WARN: postgresql15 not yet running. Skipping postgis." "WARN"
    Write-Console "       After pg15 starts: choco install postgis -y" "INFO"
    $state.Failed.Add("choco:postgis (dependency: postgresql15 not yet running — install manually)")
}
Invoke-Package "choco"  "mariadb"
Invoke-Package "choco"  "memurai-developer"    # Windows-native Redis compat (no WSL required)
Invoke-Package "choco"  "neo4j-community"
Invoke-Package "choco"  "mongodb"
Invoke-Package "choco"  "mongodb-compass"
Invoke-Package "choco"  "redis"
Invoke-Package "choco"  "influxdb"
Invoke-Package "choco"  "telegraf"             # InfluxDB metrics collector agent
Invoke-Package "choco"  "mysql"
Invoke-Package "choco"  "mysql.workbench"
Invoke-Package "winget" "dbeaver.dbeaver"
Invoke-Package "winget" "Oracle.SQLDeveloper"
Invoke-Package "choco"  "pgadmin4"             # FIX-70: moved from Batch 5
# Big Data & Analytics
Invoke-Package "choco"  "hadoop"
Invoke-Package "choco"  "weka"
Invoke-Package "choco"  "Tableau-Desktop"      # Requires institutional license at activation
# GIS
Invoke-Package "choco"  "qgis"
Invoke-Package "choco"  "gdal"
# ELK Stack (FIX-24: entirely absent in original v5; referenced in post-run checklist)
# CRITICAL: All Elastic stack components MUST share the same major version.
# choco pulls latest; pin versions after install if needed.
Write-Console "Installing ELK stack — all components must be same major version." "WARN"
Invoke-Package "choco" "elasticsearch"
Invoke-Package "choco" "logstash"
Invoke-Package "choco" "kibana"
Invoke-Package "choco" "filebeat"
Invoke-Package "choco" "metricbeat"
Invoke-Package "choco" "winlogbeat"
Write-Console "ELK: After install, verify: choco list elasticsearch; choco list winlogbeat — must match." "WARN"
# Observability
Invoke-Package "choco" "prometheus"
Invoke-Package "choco" "grafana"
Invoke-Package "choco" "syslog-ng"             # Central syslog for network devices
# HashiCorp Ecosystem (FIX-28: absent from v5)
Write-Console "Installing HashiCorp stack (vault/consul/nomad/boundary)..." "INFO"
Invoke-Package "choco" "vault"
Invoke-Package "choco" "consul"                # Service mesh & discovery
Invoke-Package "choco" "nomad"                 # Workload orchestrator — simpler than K8s for mixed workloads
Invoke-Package "choco" "boundary"              # Zero-trust access proxy — modern bastion replacement
Invoke-Package "choco" "packer"                # VM image builder — golden image automation
Invoke-Package "choco" "terraform"
Invoke-Package "choco" "opentofu"              # FOSS Terraform fork (MPL-2.0; before BSL change)
# AI / Local LLM (FIX-23: ollama missing from v5)
Invoke-Package "choco"  "ollama"
Invoke-Package "winget" "ElementLabs.LMStudio"     # GUI for local models + model discovery
Invoke-Package "winget" "Nomic.GPT4All"             # Offline, privacy-first LLM runner
# Python ML/Data Ecosystem
# NOTE-C: torch installed CPU-only (safe default). Post-CUDA restore: see NOTE-C.
# FIX-81: all pip calls use py -3.14 via Invoke-Package
# FIX-92: jinja2 removed from $pipEng (already in $pipCore); dnspython removed from
#         $pipEng (already in $pipSec). Select-Object -Unique still guards at runtime.
Write-Console "Installing Python ML/data packages (py -3.14)..." "INFO"
$pipCore  = @("pandas", "polars", "numpy", "openpyxl", "xlrd", "jinja2")
$pipViz   = @("matplotlib", "plotly", "rich", "seaborn")
$pipML    = @("scikit-learn", "torch", "transformers", "datasets",
              "accelerate", "sentence-transformers")
$pipGenAI = @("openai", "anthropic", "langchain", "langchain-community",
              "llama-index", "llama-index-core", "chromadb", "instructor",
              "ollama", "tiktoken", "mlflow", "jupyterlab", "ipywidgets")
# FIX-49: python-nmap (correct PyPI name; was 'nmap-python')
# FIX-62: elasticsearch>=9.0.0 for ES 9.x client compatibility
# FIX-92: jinja2 removed (in $pipCore); dnspython kept here (removed from $pipSec)
$pipEng   = @("dbt-postgres", "dbt-bigquery", "psutil", "boto3",
              "azure-identity", "azure-mgmt-compute", "azure-mgmt-resource",
              "google-cloud-storage", "google-api-python-client",
              "prometheus-client", "influxdb-client", "elasticsearch>=9.0.0",
              "paramiko", "fabric", "pywinrm", "pypsrp", "pywin32",
              "netmiko", "napalm", "ldap3", "msldap",
              "python-nmap",        # FIX-49: was 'nmap-python' — wrong package name
              "dnspython", "netaddr", "click", "typer", "pyyaml", "toml",
              "python-dotenv", "schedule", "apscheduler", "watchdog",
              "cryptography", "pynacl", "pyotp", "keyring", "pre-commit",
              "requests", "httpx")
$pipStdAll = $pipCore + $pipViz + $pipML + $pipGenAI + $pipEng
$pipStdAll = $pipStdAll | Select-Object -Unique   # dedup cross-array
foreach ($pkg in $pipStdAll) { Invoke-Package "pip" $pkg }
# FIX-22: faiss-cpu — pip attempt first; conda-forge fallback documented
Write-Console "Attempting faiss-cpu via pip (may fail without BLAS/LAPACK)..." "WARN"
Write-Console "  Fallback: conda install -c conda-forge faiss-cpu" "WARN"
Invoke-Package "pip" "faiss-cpu"
# FIX-22/06: GIS Python stack — GDAL Python bindings NOT provided by choco gdal.
# FIX-64: After Batch 1 refreshenv and conda init, conda should now be in PATH.
Write-Console "GIS Python stack: preferring conda-forge (handles GDAL C bindings on Windows)..." "INFO"
$gisPackages = @("geopandas", "shapely", "fiona", "rasterio")
if (Get-Command conda -ErrorAction SilentlyContinue) {
    foreach ($pkg in $gisPackages) {
        Write-Console "conda-forge >> $pkg" "INFO"
        $condaResult = conda install -c conda-forge $pkg -y 2>&1
        if ($LASTEXITCODE -eq 0) {
            $state.Success.Add("conda:$pkg"); Write-Console "OK: $pkg" "OK"
        } else {
            Write-Console "conda failed for $pkg, attempting pip fallback..." "WARN"
            Invoke-Package "pip" $pkg
        }
    }
} else {
    Write-Console "WARN: conda still not in PATH. GIS packages via pip (may fail on Windows)." "WARN"
    Write-Console "  After this script: conda init pwsh, restart pwsh, then:" "WARN"
    Write-Console "  conda install -c conda-forge geopandas shapely fiona rasterio" "WARN"
    foreach ($pkg in $gisPackages) { Invoke-Package "pip" $pkg }
}
Invoke-BatchPause "Batch 2: Data/ML/AI, Databases, ELK, HashiCorp, Observability"
# =============================================================================
# BATCH 3: CYBERSECURITY, SIGINT & FORENSICS (~25 GB)
# =============================================================================
Write-Console "=== BATCH 3: Cybersecurity, SIGINT & Forensics ===" "SECTION"
# Static Analysis & Reverse Engineering
Invoke-Package "choco" "wireshark"
Invoke-Package "choco" "ghidra"            # NSA FOSS RE framework — industry-grade binary analysis
Invoke-Package "choco" "ida-free"          # IDA Freeware — industry static analysis standard
Invoke-Package "choco" "dnspy"             # .NET decompiler/debugger — critical for Windows malware RE
Invoke-Package "choco" "ilspy"             # FOSS .NET decompiler — complement to dnSpy
Invoke-Package "choco" "apimonitor"        # Windows API call tracing — behavioral malware analysis
Invoke-Package "choco" "apktool"           # Android APK RE — decompile/recompile
# FIX-75: x64dbg IS in choco community. Verified. May need elevated setup.
Invoke-Package "choco" "x64dbg"            # Windows debugger — FOSS OllyDbg/Immunity replacement
# FIX-56: 'die' -> 'detect-it-easy' (correct choco package ID)
Invoke-Package "choco" "detect-it-easy"    # Detect It Easy — file type + packer + compiler detection
# Sysinternals forensics
Invoke-Package "choco" "procmon"           # Real-time file/registry/network activity
Invoke-Package "choco" "autoruns"          # All auto-start locations — find persistence mechanisms
# Digital Forensics & IR
Invoke-Package "choco" "autopsy"           # Digital forensics platform — FOSS FTK alternative
Invoke-Package "choco" "ftk-imager"        # Disk image acquisition — standard evidence collection
Invoke-Package "choco" "sleuthkit"         # Forensic toolkit — CLI layer under Autopsy
Invoke-Package "choco" "exiftool"          # File metadata extractor — critical for forensics/OSINT
# Pattern matching & password recovery
Invoke-Package "choco" "yara"              # Malware signature language and scanner
Invoke-Package "choco" "hashcat"           # GPU password recovery — test password policy resilience
Invoke-Package "choco" "john"              # CPU password cracker (John the Ripper)
# Network security & scanning
Invoke-Package "choco" "nmap"
Invoke-Package "choco" "masscan"           # High-speed port scanner — complement to nmap for wide scans
Invoke-Package "choco" "nikto"             # Web server vulnerability scanner
Invoke-Package "choco" "sqlmap"            # SQL injection automation
Invoke-Package "choco" "gitleaks"          # Git secret scanner
# FIX-74: trufflehog — choco package version-lagged; go install is authoritative (Batch 5).
Write-Console "trufflehog: choco install (convenience fallback — go install in Batch 5 is authoritative)..." "WARN"
Invoke-Package "choco" "trufflehog"
# Web application security
Invoke-Package "choco" "burp-suite-free-edition"
Invoke-Package "choco" "zap"               # OWASP ZAP — FOSS full alternative to Burp Community
Invoke-Package "choco" "fiddler"
Invoke-Package "choco" "soapui"
# OSINT tools (FIX-59: Gephi removed from here — it's in Batch 5)
Invoke-Package "choco" "maltego"           # Visual link analysis — FOSS community edition
Invoke-Package "winget" "GCHQ.CyberChef"  # Encoding/decoding/crypto Swiss army knife — GCHQ
# Proxies, anonymity & tunnels
Invoke-Package "choco" "squid"             # Caching forward proxy — active service in inventory
Invoke-Package "choco" "privoxy"           # HTTP filtering proxy — active service in inventory
Invoke-Package "choco" "tor-browser"
Invoke-Package "choco" "zerotier-one"      # Layer-2 SDN VPN — complements Tailscale (layer 3)
Invoke-Package "choco" "ngrok"             # Secure tunnel for local dev — webhook testing
Invoke-Package "choco" "bind-toolsonly"    # dig, nslookup, host — essential DNS toolkit
Invoke-Package "choco" "openssh"
Invoke-Package "winget" "OpenSC.OpenSC"    # Smart card middleware — CAC/PIV (DoD PKI context)
# Penetration testing
Invoke-Package "choco" "metasploit"
# Python Security & OSINT (FIX-06: theharvester lowercase; holehe + recon-ng added)
# FIX-92: dnspython removed (already in $pipEng — deduplication at source)
$pipSec = @(
    "shodan",           # Shodan IoT/exposed-services search CLI (requires API key)
    "spiderfoot",       # Automated OSINT reconnaissance
    "theharvester",     # FIX-06: lowercase — email/domain/IP OSINT from public sources
    "impacket",         # Windows protocol toolkit — AD pentesting/automation
    "scapy",            # FIX-71: Packet manipulation — added to spot-check in Batch 7
    "semgrep",          # SAST — community rules for many languages
    "checkov",          # IaC security scanner — Terraform/K8s/Dockerfile
    "bandit",           # Python SAST — find security bugs in scripts
    "safety",           # Python dependency vulnerability scan
    "volatility3",      # FIX-04: Memory forensics — pip ONLY; no choco package exists
    "holehe",           # Email-across-platforms OSINT
    "recon-ng"          # Modular OSINT framework (like Metasploit for OSINT)
    # NOTE: recon-ng execution on Windows has unresolved native deps. Use via WSL2.
)
$pipSec = $pipSec | Select-Object -Unique
foreach ($pkg in $pipSec) { Invoke-Package "pip" $pkg }
Invoke-BatchPause "Batch 3: Cybersecurity, Forensics, SIGINT & OSINT"
# =============================================================================
# BATCH 4: INFRASTRUCTURE, OCI, DEVOPS (~20 GB)
# =============================================================================
Write-Console "=== BATCH 4: Infrastructure, Containers & DevOps ===" "SECTION"
# Containerization — Podman replaces Docker Desktop (FIX-08)
# NOTE-F: Podman Desktop includes docker<->podman shim. docker-cli adds full binary.
Invoke-Package "choco" "podman-desktop"
# FIX-65: docker-cli for Podman Docker compatibility
Invoke-Package "choco" "docker-cli"        # Docker CLI binary — works via Podman's docker shim
Invoke-Package "choco" "docker-compose"    # Docker Compose v2 plugin
# FIX-07: nerdctl installs CLI only. containerd requires WSL2 or nerdctl-full.
Write-Console "NOTE: nerdctl CLI installed. containerd requires WSL2 or nerdctl-full bundle." "WARN"
Invoke-Package "choco" "nerdctl"
# Kubernetes ecosystem
Invoke-Package "choco" "kubernetes-cli"
Invoke-Package "choco" "minikube"
Invoke-Package "choco" "kubernetes-kompose"    # Translate docker-compose -> K8s YAML
Invoke-Package "choco" "kubectx"               # Fast kubectl context/namespace switching
Invoke-Package "choco" "istioctl"              # Istio service mesh CLI
Invoke-Package "choco" "skaffold"              # K8s inner-loop dev automation
Invoke-Package "choco" "tilt"                  # K8s dev dashboard
Invoke-Package "choco" "k9s"                   # Terminal K8s dashboard
# FIX-20: kubernetes-helm (choco ID) — 'helm' does not exist in community repo
Invoke-Package "choco" "kubernetes-helm"
# IaC ecosystem
Invoke-Package "choco" "terraform-docs"    # Auto-generate README for Terraform modules
Invoke-Package "choco" "terragrunt"        # Terraform wrapper for DRY configs
Invoke-Package "choco" "tflint"            # Terraform linter
Invoke-Package "choco" "pulumi"            # IaC with Python/Go/TypeScript
Invoke-Package "choco" "argocd-cli"        # GitOps CD for K8s
# CI/CD
# FIX-43: concourse installs fly CLI only — not the Concourse server
Write-Console "NOTE: 'concourse' installs fly CLI only. Concourse server -> docker-compose (Batch 6)." "INFO"
Invoke-Package "choco" "concourse"         # fly CLI
Invoke-Package "choco" "circleci-cli"      # Validate .circleci configs locally
Invoke-Package "choco" "databricks-cli"    # Manage Databricks workspaces from terminal
Invoke-Package "choco" "nssm"              # Non-Sucking Service Manager — wrap any exe as Windows service
# FIX-53: nvm removed from here — already installed in Batch 1
# FIX-89: consul + packer removed from here — both already installed in Batch 2 (HashiCorp section)
# Config management
# FIX-73: Ansible on Windows — NOT a control node. See NOTE-E.
Write-Console "NOTE: Ansible on Windows = managed NODE only, not control node. See NOTE-E." "WARN"
Write-Console "       For Ansible control: WSL2 -> Ubuntu -> apt install ansible" "WARN"
Invoke-Package "choco" "ansible"           # Retained for docs; actual use requires WSL2
Invoke-Package "choco" "puppet-agent"      # Declarative config management agent
# Source control hosting
Invoke-Package "choco" "gitea"             # Self-hosted Git service — lightweight GitHub alternative
# QEMU (FIX-42: lowercase package ID)
Invoke-Package "choco" "qemu"              # Full system emulator — ARM/RISC-V/MIPS
# WSL2 Ubuntu (FIX-72: features were enabled in Pre-flight; wsl --install completes on reboot)
Write-Console "Queuing WSL2 Ubuntu install (will complete after reboot if features just enabled)..." "INFO"
Write-Console "  If WSL features were already active from a prior boot, this installs immediately." "INFO"
wsl --set-default-version 2 2>&1 | Out-Null
wsl --install -d Ubuntu 2>&1 | Out-Null
Invoke-BatchPause "Batch 4: Infrastructure, OCI, DevOps"
# =============================================================================
# BATCH 5: KNOWLEDGE, UTILITIES, SCOOP, NPM, CARGO, GO, PSMODULES (~22 GB)
# =============================================================================
Write-Console "=== BATCH 5: Knowledge, CLI Tools & PowerShell ===" "SECTION"
# Knowledge Management — Sovereignty Split (FIX-08: Notion excluded; NOTE-A)
Write-Console "NOTE: Notion excluded (data sovereignty on cleared-environment machine)." "WARN"
Write-Console "       Manual install if personal-use: winget install Notion.Notion" "INFO"
Invoke-Package "winget" "AppFlowy.AppFlowy"         # FOSS, local-first Notion alternative
# FIX-55: obsidian winget only (choco duplicate removed in v5.2)
Invoke-Package "winget" "Obsidian.Obsidian"
Invoke-Package "winget" "Posit.Quarto"              # Scientific publishing — Python/R/Julia -> PDF/HTML/Word
Invoke-Package "winget" "Logseq.Logseq"             # Local-first graph knowledge base
Invoke-Package "winget" "calibre.calibre"           # Ebook management & format conversion
Invoke-Package "choco" "pandoc"
Invoke-Package "choco" "miktex"
Invoke-Package "choco" "hugo"
# Comet / Perplexity Note
Write-Console "NOTE: Install Perplexity/Comet manually as an Edge/Chrome PWA." "WARN"
# System Utilities & CLI Modernization
Invoke-Package "winget" "Anysphere.Cursor"
Invoke-Package "winget" "CodeSector.TeraCopy"
Invoke-Package "winget" "WinMerge.WinMerge"
Invoke-Package "winget" "ScooterSoftware.BeyondCompare5"
# FIX-59: Gephi here from Batch 3 (OSINT visualization — utilities context)
Invoke-Package "winget" "Gephi.Gephi"
Invoke-Package "winget" "Doppler.doppler"           # Team secrets manager
Invoke-Package "winget" "VivaldiTechnologies.Vivaldi"
Invoke-Package "winget" "Telegram.TelegramDesktop"
Invoke-Package "winget" "k6.k6"                     # Developer load testing
Invoke-Package "choco" "imagemagick"
Invoke-Package "choco" "ffmpeg"
Invoke-Package "choco" "handbrake"
# FIX-88: Qemu removed — already installed in Batch 4 (FIX-42)
# Scoop CLI Tools
scoop bucket add extras 2>&1 | Out-Null
scoop bucket add nerd-fonts 2>&1 | Out-Null
scoop bucket add versions 2>&1 | Out-Null
$scoopTools = @(
    "fzf", "ripgrep", "fd", "bat", "jq", "yq", "delta", "zoxide",
    "starship", "gping", "doggo", "xh", "fx", "tldr", "lazygit",
    "lazydocker", "btop", "glow", "age", "mkcert", "FiraCode-NF"
)
foreach ($tool in $scoopTools) { Invoke-Package "scoop" $tool }
# NPM Global Tools (FIX-82: was declared in header but absent from v5.2)
Write-Console "Installing NPM global packages..." "INFO"
$npmGlobal = @(
    "typescript", "ts-node", "@angular/cli", "nx", "nodemon", "pm2",
    "eslint", "prettier", "webpack-cli", "vite", "jest",
    "@playwright/test", "http-server", "serve",
    "netlify-cli", "vercel", "wrangler",
    "@anthropic-ai/sdk", "openai"
)
foreach ($pkg in $npmGlobal) { Invoke-Package "npm" $pkg }
# Cargo Tools (FIX-83: was declared in header but absent from v5.2)
# FIX-63: mise via cargo — version manager for runtime environments
Write-Console "Installing Cargo tools (requires Rustup from Batch 1 + new terminal session)..." "WARN"
$cargoTools = @("mise")
foreach ($pkg in $cargoTools) { Invoke-Package "cargo" $pkg }
# FIX-63: Configure mise activation in PowerShell profile (persistent across sessions)
$miseActivationLine = "`nmise activate pwsh | Out-String | Invoke-Expression"
if (Test-Path $PROFILE) {
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($profileContent -notmatch "mise activate") {
        Add-Content -Path $PROFILE -Value $miseActivationLine
        Write-Console "mise activation added to profile: $PROFILE" "OK"
        $state.Success.Add("config:mise-activate-profile")
    } else {
        Write-Console "SKIP: mise activation already in profile." "OK"
        $state.Skipped.Add("config:mise-activate-profile")
    }
} else {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Add-Content -Path $PROFILE -Value $miseActivationLine
    Write-Console "Profile created with mise activation: $PROFILE" "OK"
    $state.Success.Add("config:mise-activate-profile-new")
}
# Go Tools (FIX-84: was declared in header but absent from v5.2)
# FIX-74: trufflehog authoritative path — go install supersedes choco (version-lagged)
Write-Console "Installing Go tools (requires golang from Batch 1 + PATH refresh)..." "INFO"
$goTools = @(
    "github.com/trufflesecurity/trufflehog/v3",   # FIX-74: authoritative; choco in Batch 3 is fallback
    "github.com/aquasecurity/trivy",              # Container/IaC vulnerability scanner
    "github.com/go-task/task/v3/cmd/task"         # Modern Makefile replacement
)
foreach ($pkg in $goTools) { Invoke-Package "go" $pkg }
# Core PowerShell Modules
# FIX-85: ActiveDirectory + GroupPolicy removed from $psMods — must use Add-WindowsCapability
# FIX-86: SecretManagement -> Microsoft.PowerShell.SecretManagement (full name, no ambiguity)
$psMods = @(
    "Az",
    "Microsoft.Graph",
    "ImportExcel",
    "Pester",
    "Microsoft.PowerShell.SecretManagement",   # FIX-86: full name (was 'SecretManagement')
    "Posh-SSH",
    "Carbon",
    "BurntToast"
)
foreach ($mod in $psMods) { Invoke-Package "psmodule" $mod }
# FIX-85: RSAT — ActiveDirectory + GroupPolicy via Add-WindowsCapability (not PSGallery)
# PSGallery does not provide a proper ActiveDirectory PS module; RSAT is the correct path.
# $RSATSource can be set to a WIM path at the top of the script for air-gapped machines.
Write-Console "Installing RSAT capabilities (ActiveDirectory + GroupPolicy)..." "INFO"
$rsatCaps = @(
    "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0",
    "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
)
foreach ($cap in $rsatCaps) {
    try {
        $capState = Get-WindowsCapability -Online -Name $cap -ErrorAction SilentlyContinue
        if ($capState -and $capState.State -eq "Installed") {
            Write-Console "SKIP (installed): $cap" "OK"
            $state.Skipped.Add("rsat:$cap")
        } else {
            $addArgs = @{ Online = $true; Name = $cap; ErrorAction = "Stop" }
            if ($RSATSource) { $addArgs.Source = $RSATSource }
            Add-WindowsCapability @addArgs | Out-Null
            Write-Console "OK: $cap" "OK"
            $state.Success.Add("rsat:$cap")
        }
    } catch {
        Write-Console "FAILED: $cap — $_" "ERROR"
        $state.Failed.Add("rsat:$cap | $_")
    }
}
# FIX-87: Invoke-BatchPause added (was absent in v5.2 — no operator pause, no refreshenv)
Invoke-BatchPause "Batch 5: Knowledge, CLI Tools, NPM, Cargo, Go & PowerShell"
# =============================================================================
# BATCH 6: DOCKER COMPOSE STACKS (FIX-78: entirely absent in v5.2)
# =============================================================================
Write-Console "=== BATCH 6: Docker Compose Stacks ===" "SECTION"
Write-Console "Writing all compose stacks to C:\Admin\Docker\..." "INFO"
Write-Console "NOTE: docker / podman must be running before 'docker compose up -d'." "WARN"
# --- Portainer: Docker/K8s web management UI ---
New-DockerStack -StackName "portainer" -ComposeYaml @'
version: '3.8'
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "8000:8000"
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
volumes:
  portainer_data:
'@
# --- Vaultwarden: self-hosted Bitwarden-compatible password server ---
# FIX-91: port 8081:80 (8080 conflicts with Kafka-UI and Spark webui mappings)
New-DockerStack -StackName "vaultwarden" -ComposeYaml @'
version: '3.8'
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    ports:
      - "8081:80"
    volumes:
      - vaultwarden_data:/data
    environment:
      SIGNUPS_ALLOWED: "false"
volumes:
  vaultwarden_data:
'@
# --- Observability: Grafana + Prometheus + Loki + Promtail ---
New-DockerStack -StackName "observability" -ComposeYaml @'
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    restart: unless-stopped
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: changeme
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    restart: unless-stopped
  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - /var/log:/var/log
    restart: unless-stopped
volumes:
  grafana_data:
'@
# --- OpenVAS / Greenbone: FOSS vulnerability scanner ---
New-DockerStack -StackName "openvas" -ComposeYaml @'
version: '3.8'
services:
  openvas:
    image: greenbone/openvas-scanner:latest
    container_name: openvas
    restart: unless-stopped
    ports:
      - "9392:9392"
'@
# --- Apache Spark + Jupyter ---
# FIX-76: Spark worker webui shifted off :8080
New-DockerStack -StackName "spark" -ComposeYaml @'
version: '3.8'
services:
  spark-master:
    image: bitnami/spark:latest
    container_name: spark-master
    environment:
      SPARK_MODE: master
      SPARK_RPC_AUTHENTICATION_ENABLED: "no"
      SPARK_RPC_ENCRYPTION_ENABLED: "no"
    ports:
      - "7077:7077"
      - "8082:8080"
    restart: unless-stopped
  spark-worker:
    image: bitnami/spark:latest
    container_name: spark-worker
    environment:
      SPARK_MODE: worker
      SPARK_MASTER_URL: spark://spark-master:7077
      SPARK_WORKER_WEBUI_PORT: "8083"
    ports:
      - "8083:8083"
    depends_on:
      - spark-master
    restart: unless-stopped
  jupyter:
    image: jupyter/pyspark-notebook:latest
    container_name: jupyter
    ports:
      - "8888:8888"
    environment:
      JUPYTER_ENABLE_LAB: "yes"
    volumes:
      - jupyter_data:/home/jovyan/work
    restart: unless-stopped
volumes:
  jupyter_data:
'@
# --- Neo4j + APOC + Graph Data Science + Bloom ---
New-DockerStack -StackName "neo4j" -ComposeYaml @'
version: '3.8'
services:
  neo4j:
    image: neo4j:latest
    container_name: neo4j
    restart: unless-stopped
    ports:
      - "7474:7474"
      - "7687:7687"
    environment:
      NEO4J_AUTH: neo4j/changeme
      NEO4J_PLUGINS: '["apoc", "graph-data-science", "bloom"]'
    volumes:
      - neo4j_data:/data
      - neo4j_logs:/logs
volumes:
  neo4j_data:
  neo4j_logs:
'@
# --- Apache Hive Metastore + HiveServer2 ---
New-DockerStack -StackName "hive" -ComposeYaml @'
version: '3.8'
services:
  hive-metastore:
    image: apache/hive:4.0.0
    container_name: hive-metastore
    ports:
      - "9083:9083"
    environment:
      SERVICE_NAME: metastore
    restart: unless-stopped
  hiveserver2:
    image: apache/hive:4.0.0
    container_name: hiveserver2
    ports:
      - "10000:10000"
      - "10002:10002"
    environment:
      SERVICE_NAME: hiveserver2
    depends_on:
      - hive-metastore
    restart: unless-stopped
'@
# --- Kafka + Zookeeper + Kafka-UI ---
# FIX-61: ADVERTISED_LISTENERS fixed for container networking
# kafka:29092 for internal container comms; localhost:9092 for host clients
New-DockerStack -StackName "kafka" -ComposeYaml @'
version: '3.8'
services:
  zookeeper:
    image: confluentinc/cp-zookeeper:latest
    container_name: zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
    restart: unless-stopped
  kafka:
    image: confluentinc/cp-kafka:latest
    container_name: kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
    environment:
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
    restart: unless-stopped
  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: kafka-ui
    depends_on:
      - kafka
    ports:
      - "8090:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: local
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092
    restart: unless-stopped
'@
# --- Atlantis: Terraform PR automation ---
# FIX-60: .env template generated (required; Atlantis won't start without credentials)
New-DockerStack -StackName "atlantis" -ComposeYaml @'
version: '3.8'
services:
  atlantis:
    image: ghcr.io/runatlantis/atlantis:latest
    container_name: atlantis
    restart: unless-stopped
    ports:
      - "4141:4141"
    env_file:
      - .env
    command: server
'@ -EnvTemplate @'
# Copy this file to .env and populate before running docker compose up
# ATLANTIS_GH_TOKEN=<github-personal-access-token>
# ATLANTIS_GH_USER=<github-username>
# ATLANTIS_REPO_ALLOWLIST=github.com/<your-org>/*
# ATLANTIS_ATLANTIS_URL=http://localhost:4141
'@
# --- GitLab CE: self-hosted Git + CI/CD ---
# FIX-90: ports shifted off 80/443/22 — conflicts with IIS (enabled in pre-flight) + Windows SSH
# Web: 8929:80, HTTPS: 8930:443, SSH: 2289:22
New-DockerStack -StackName "gitlab" -ComposeYaml @'
version: '3.8'
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: unless-stopped
    ports:
      - "8929:80"
      - "8930:443"
      - "2289:22"
    volumes:
      - gitlab_config:/etc/gitlab
      - gitlab_logs:/var/log/gitlab
      - gitlab_data:/var/opt/gitlab
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://localhost:8929'
        gitlab_rails['gitlab_shell_ssh_port'] = 2289
volumes:
  gitlab_config:
  gitlab_logs:
  gitlab_data:
'@
Write-Console "All 10 Docker stacks written to C:\Admin\Docker\" "OK"
Write-Console "Start any stack: docker compose -f C:\Admin\Docker\<name>\docker-compose.yml up -d" "INFO"
Invoke-BatchPause "Batch 6: Docker Compose Stacks"
# =============================================================================
# BATCH 7: VERIFICATION PASS (FIX-79: entirely absent in v5.2)
# =============================================================================
Write-Console "=== BATCH 7: Spot-Check Verification ===" "SECTION"
# --- Command-in-PATH checks ---
Write-Console "--- CLI spot-checks ---" "INFO"
$cmdChecks = @(
    "git", "python", "py", "node", "npm", "go", "cargo", "rustup",
    "choco", "scoop", "winget", "pwsh", "docker", "podman",
    "kubectl", "helm", "terraform", "vault", "consul",
    "conda", "ollama", "mise"
)
foreach ($cmd in $cmdChecks) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $ver = (& $cmd --version 2>&1 | Select-Object -First 1) -replace "\r?\n", ""
        Write-Console "  $cmd : $ver" "OK"
        $state.Success.Add("verify:cmd:$cmd")
    } else {
        Write-Console "  MISSING: $cmd" "ERROR"
        $state.Failed.Add("verify:cmd:$cmd")
    }
}
# --- Python package spot-checks (py -3.14 -m pip show) ---
# FIX-71: scapy included here (was missing from v5.2 spot-checks)
Write-Console "--- Python package spot-checks (py -3.14) ---" "INFO"
$pyPkgChecks = @(
    "pandas", "numpy", "scikit-learn", "torch", "anthropic",
    "langchain", "faiss-cpu", "elasticsearch", "python-nmap",
    "scapy", "volatility3", "impacket", "dbt-postgres"
)
foreach ($pkg in $pyPkgChecks) {
    py -3.14 -m pip show $pkg 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Console "  py pkg OK: $pkg" "OK"
        $state.Success.Add("verify:py:$pkg")
    } else {
        Write-Console "  py pkg MISSING: $pkg" "WARN"
        $state.Failed.Add("verify:py:$pkg")
    }
}
# --- Docker stack file checks ---
Write-Console "--- Docker stack file checks ---" "INFO"
$stackNames = @(
    "portainer", "vaultwarden", "observability", "openvas",
    "spark", "neo4j", "hive", "kafka", "atlantis", "gitlab"
)
foreach ($stack in $stackNames) {
    $composePath = "C:\Admin\Docker\$stack\docker-compose.yml"
    if (Test-Path $composePath) {
        Write-Console "  Stack OK: $stack" "OK"
        $state.Success.Add("verify:stack:$stack")
    } else {
        Write-Console "  Stack MISSING: $composePath" "ERROR"
        $state.Failed.Add("verify:stack:$stack")
    }
}
# --- Service checks ---
Write-Console "--- Service checks ---" "INFO"
# FIX-51 pattern: array-safe
$pgSvc = Get-Service "postgresql*" -ErrorAction SilentlyContinue |
         Where-Object { $_.Status -eq "Running" }
if ($pgSvc) {
    Write-Console "  PostgreSQL: RUNNING" "OK"
    $state.Success.Add("verify:svc:postgresql")
} else {
    Write-Console "  PostgreSQL: NOT RUNNING (start manually after install)" "WARN"
    $state.Failed.Add("verify:svc:postgresql")
}
# FIX-57: Ghidra — check file existence, not --version (no CLI version flag on Windows)
$ghidraPath = "C:\ProgramData\chocolatey\lib\ghidra\tools"
if (Test-Path $ghidraPath) {
    Write-Console "  Ghidra: installed at $ghidraPath" "OK"
    $state.Success.Add("verify:ghidra")
} else {
    Write-Console "  Ghidra: not found at $ghidraPath (may be in alternate choco lib path)" "WARN"
    $state.Failed.Add("verify:ghidra")
}
# --- RSAT capability checks ---
Write-Console "--- RSAT capability checks ---" "INFO"
foreach ($cap in $rsatCaps) {
    $capState = Get-WindowsCapability -Online -Name $cap -ErrorAction SilentlyContinue
    if ($capState -and $capState.State -eq "Installed") {
        Write-Console "  RSAT OK: $cap" "OK"
        $state.Success.Add("verify:rsat:$cap")
    } else {
        Write-Console "  RSAT NOT INSTALLED: $cap" "WARN"
        $state.Failed.Add("verify:rsat:$cap")
    }
}
Write-Console "=== VERIFICATION COMPLETE. Review any WARN/ERROR above. ===" "SECTION"
Write-Console "Final state: Success=$($state.Success.Count) | Skipped=$($state.Skipped.Count) | Failed=$($state.Failed.Count) | Purged=$($state.Purged.Count)" "INFO"
Invoke-BatchPause "Batch 7: Verification Pass"
# =============================================================================
# END OF MAIN BODY
# =============================================================================
} catch {
    # Catch terminating errors — log them and let finally handle cleanup
    Write-Console "TERMINATING ERROR: $_" "ERROR"
    $state.Failed.Add("FATAL: $_")
} finally {
    # FIX-52/77: finally block is the sole authoritative cleanup path.
    # Runs on both clean completion AND crash — Export-State is never skipped.
    Export-State
    Stop-Transcript
    Write-Host "`n[+] SOK-BareMetal v5.3 EXECUTION COMPLETE." -ForegroundColor Green
    Write-Host "    State log : $logDir\v5_environment_state.json" -ForegroundColor Cyan
    Write-Host "    Transcript: $logDir\Verbose_Terminal_Output.txt" -ForegroundColor Cyan
}
