#Requires -RunAsAdministrator
<#
.SYNOPSIS
    SOK-BareMetal v5.0.0 — Exhaustive Bare-Metal Environment Restoration
    Host: CLAY_PC (Zero-State Assumption) | D: & E: Disconnected
.DESCRIPTION
    Executes a complete reconstruction of the operator environment.
    Purges hostile applications. Installs 150+ tools across Choco, Winget, Scoop, Pip, NPM, and PSModules.
    Batched in ~66GB logical phases with strict Y/N continuations and JSON state logging.

    SUBSTRATE THESIS: Plug E: into new machine → run SOK-BareMetal → run SOK-BackupRestructure
    → environment fully restored. This script provisions the substrate (tools, languages, runtimes).

    NOTE: This script is intentionally interactive (batch Y/N prompts) and not integrated with
    SOK-Common. It predates the SOK family and is a special-case emergency recovery tool.
    Use -DryRun for test-sequencing: all installs are logged but not executed; batch pauses
    auto-continue; WMI uninstalls are skipped. Canonical version is SOK-BareMetal_v5.3.ps1.
    Do not schedule. Run only during bare-metal restoration.
.NOTES
    Author:  S. Clay Caddell
    Version: 5.0.1
    Date:    2026-04-03
    Domain:  Utility — emergency bare-metal substrate restoration; not scheduled; run manually
#>
[CmdletBinding()]
param([switch]$DryRun)

$ErrorActionPreference = "Continue"
$VerbosePreference = "Continue"
$logDir = "C:\Admin\Logs\V5_Restore_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path "$logDir\Verbose_Terminal_Output.txt" -Append

$state = @{
    ExecutionStart = (Get-Date -Format "o")
    Purged = [System.Collections.Generic.List[string]]::new()
    Success = [System.Collections.Generic.List[string]]::new()
    Failed = [System.Collections.Generic.List[string]]::new()
}

function Write-Console {
    param([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    $colors = @{ "INFO"="Cyan"; "OK"="Green"; "ERROR"="Red"; "PURGE"="Magenta"; "WARN"="Yellow" }
    Write-Host "[$ts] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Export-State {
    $state.ExecutionLastUpdate = (Get-Date -Format "o")
    $jsonPath = "$logDir\v5_environment_state.json"
    $state | ConvertTo-Json -Depth 4 | Out-File $jsonPath -Encoding utf8
    Write-Console "State serialized to JSON: $jsonPath" "OK"
}

function Invoke-Package {
    param([string]$Manager, [string]$Package, [string]$Args = "")
    if ($DryRun) { Write-Console "DRY RUN: Would install $Manager`:$Package" "INFO"; return }
    Write-Console "Deploying via $Manager : $Package" "INFO"

    try {
        $exitCode = 0
        if ($Manager -eq "choco") { 
            $process = Start-Process -FilePath "choco" -ArgumentList "install $Package -y --verbose --ignore-checksums $Args" -Wait -PassThru 
            $exitCode = $process.ExitCode
        }
        elseif ($Manager -eq "winget") { 
            $process = Start-Process -FilePath "winget" -ArgumentList "install --id $Package --exact --silent --accept-package-agreements --accept-source-agreements $Args" -Wait -PassThru 
            $exitCode = $process.ExitCode
        }
        elseif ($Manager -eq "scoop") { 
            $process = Start-Process -FilePath "scoop" -ArgumentList "install $Package" -Wait -PassThru 
            $exitCode = $process.ExitCode
        }
        elseif ($Manager -eq "pip") { 
            $process = Start-Process -FilePath "py" -ArgumentList "-3.13 -m pip install --upgrade $Package" -Wait -PassThru 
            $exitCode = $process.ExitCode
        }
        elseif ($Manager -eq "npm") { 
            $process = Start-Process -FilePath "npm" -ArgumentList "install -g $Package" -Wait -PassThru 
            $exitCode = $process.ExitCode
        }
        elseif ($Manager -eq "psmodule") {
            Install-Module -Name $Package -Force -AllowClobber -Scope AllUsers -ErrorAction Stop
        }

        # 0=Success, 1641=Restart Init, 2359302=Already Installed
        if ($exitCode -in @(0, 1641, 2359302) -or $Manager -eq "psmodule") {
            $state.Success.Add("$Manager : $Package")
            Write-Console "SUCCESS : $Package" "OK"
        } else {
            throw "Exit Code $exitCode"
        }
    } catch {
        $state.Failed.Add("$Manager : $Package | $_")
        Write-Console "FAILED : $Package ($Manager) - $_" "ERROR"
    }
}

function Invoke-BatchPause {
    param([string]$BatchName)
    Export-State
    if ($DryRun) {
        Write-Console "DRY RUN: Auto-proceeding past batch '$BatchName'" "WARN"
        return
    }
    Write-Host "`n========================================================================" -ForegroundColor DarkCyan
    Write-Host " BATCH COMPLETE: $BatchName " -ForegroundColor White
    Write-Host "========================================================================" -ForegroundColor DarkCyan
    $ans = Read-Host "Proceed to next batch? (Y to continue, N/Exit to halt safely)"
    if ($ans -match "^[NnEe]") {
        Write-Console "Operator halted execution. State saved." "WARN"
        Stop-Transcript
        exit
    }
}

# =================================================================
# PHASE 0: HOSTILE ENVIRONMENT PURGE & DECOMMISSIONING
# =================================================================
Write-Console "PHASE 0: WMI Purge of Hostile/Deprecated Systems" "PURGE"

$deprecatedApps = @("Avast Free Antivirus", "AVG Protection", "Avira Security", "BlueStacks App Player", "Guardian Browser", "Docker Desktop")
foreach ($app in $deprecatedApps) {
    if ($DryRun) { Write-Console "DRY RUN: Would purge (WMI) $app" "PURGE"; continue }
    $appWmi = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -match $app }
    if ($appWmi) {
        Write-Console "Sending WMI kill signal to: $app" "PURGE"
        $appWmi.Uninstall() | Out-Null
        $state.Purged.Add($app)
    } else {
        Write-Console "$app not found. Clean." "OK"
    }
}

# =================================================================
# BATCH 1: CORE SUBSTRATE, LANGUAGES & BUILD TOOLS (~15GB)
# =================================================================
Write-Console "Initializing BATCH 1: Package Managers & Compilers" "INFO"

# Establish Package Managers
Set-ExecutionPolicy Bypass -Scope Process -Force
if (!(Get-Command choco -ErrorAction SilentlyContinue)) { Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) }
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) { Invoke-Expression "& {$(irm get.scoop.sh)} -RunAsAdmin" }

# Base Languages & VMs
Invoke-Package "choco" "git"
Invoke-Package "choco" "python313"
Invoke-Package "winget" "Rustlang.Rustup" # Bypasses Scoop GUI bug
Invoke-Package "choco" "nodejs-lts"
Invoke-Package "choco" "javaruntime"
Invoke-Package "choco" "jdk8"
Invoke-Package "choco" "jre8"
Invoke-Package "choco" "Temurin17"
Invoke-Package "choco" "Temurin21"
Invoke-Package "choco" "R.Project"
Invoke-Package "choco" "r.studio"
Invoke-Package "choco" "julia"
Invoke-Package "choco" "php"
Invoke-Package "choco" "dart-sdk"
Invoke-Package "choco" "flutter"

# Esoteric & Systems Languages
Invoke-Package "choco" "erlang"
Invoke-Package "choco" "elixir"
Invoke-Package "choco" "ghc"
Invoke-Package "choco" "cabal"
Invoke-Package "choco" "lua"
Invoke-Package "choco" "nim"
Invoke-Package "choco" "racket"
Invoke-Package "choco" "sbcl"
Invoke-Package "choco" "scala"

# C++ Build Toolchain
Invoke-Package "choco" "msys2"
Invoke-Package "choco" "mingw"
Invoke-Package "choco" "cmake"
Invoke-Package "choco" "make"
Invoke-Package "choco" "ninja"
Invoke-Package "choco" "llvm"
Invoke-Package "choco" "strawberryperl"

Invoke-BatchPause "Batch 1: Core Substrate & Compilers"

# =================================================================
# BATCH 2: DATA ENGINEERING, ML, GIS & DATABASES (~35GB)
# =================================================================
Write-Console "Initializing BATCH 2: Data, ML & GIS Convergence" "INFO"

# Databases & Graph
Invoke-Package "choco" "postgresql15"
Invoke-Package "choco" "postgis"      # The GIS Convergence requirement
Invoke-Package "choco" "mariadb"
Invoke-Package "choco" "memurai-developer" # Windows Redis
Invoke-Package "choco" "neo4j-community"
Invoke-Package "winget" "dbeaver.dbeaver"
Invoke-Package "winget" "Oracle.SQLDeveloper"

# Big Data & ML Frameworks
Invoke-Package "choco" "hadoop"
Invoke-Package "choco" "weka"
Invoke-Package "choco" "Tableau-Desktop"

# Geographic Information Systems (GIS)
Invoke-Package "choco" "qgis"
Invoke-Package "choco" "gdal"

# Python Exhaustive Data & ML Ecosystem (Pip)
$pipCore = @("pandas", "polars", "numpy", "openpyxl", "jinja2")
$pipViz = @("matplotlib", "plotly", "rich")
$pipGIS = @("geopandas", "shapely", "fiona", "rasterio")
$pipML = @("scikit-learn", "torch", "transformers", "datasets", "accelerate", "faiss-cpu", "sentence-transformers")
$pipGenAI = @("openai", "anthropic", "langchain", "llama-index", "chromadb", "instructor", "ollama", "tiktoken")
$pipEng = @("dbt-postgres", "dbt-bigquery", "jupyterlab", "mlflow", "psutil", "boto3", "azure-identity")

$allPip = $pipCore + $pipViz + $pipGIS + $pipML + $pipGenAI + $pipEng
foreach ($pkg in $allPip) { Invoke-Package "pip" $pkg }

Invoke-BatchPause "Batch 2: Data Engineering, ML, & GIS"

# =================================================================
# BATCH 3: CYBERSECURITY, SIGINT & FORENSICS (~25GB)
# =================================================================
Write-Console "Initializing BATCH 3: SIGINT & Forensics" "INFO"

# Reverse Engineering & Static Analysis
Invoke-Package "choco" "wireshark"
Invoke-Package "choco" "ghidra"
Invoke-Package "choco" "ida-free"
Invoke-Package "choco" "dnspy"
Invoke-Package "choco" "ilspy"
Invoke-Package "choco" "apimonitor"
Invoke-Package "choco" "apktool"
Invoke-Package "choco" "procmon"
Invoke-Package "choco" "autoruns"

# Forensics & NetSec
Invoke-Package "choco" "volatility3"
Invoke-Package "choco" "yara"
Invoke-Package "choco" "nmap"
Invoke-Package "choco" "burp-suite-free-edition"
Invoke-Package "choco" "fiddler"
Invoke-Package "choco" "soapui"

# Proxies, Anonymity & Tunnels
Invoke-Package "choco" "squid"
Invoke-Package "choco" "privoxy"
Invoke-Package "choco" "tor-browser"
Invoke-Package "choco" "zerotier-one"
Invoke-Package "winget" "Tailscale.Tailscale"
Invoke-Package "choco" "ngrok"
Invoke-Package "choco" "bind-toolsonly"
Invoke-Package "choco" "openssh"
Invoke-Package "winget" "OpenSC.OpenSC" # Smart card / DoD PKI

# Python Security Tools
$pipSec = @("shodan", "spiderfoot", "theHarvester", "impacket", "scapy", "dnspython", "semgrep", "checkov", "bandit")
foreach ($pkg in $pipSec) { Invoke-Package "pip" $pkg }

Invoke-BatchPause "Batch 3: Cybersecurity, Forensics & OSINT"

# =================================================================
# BATCH 4: INFRASTRUCTURE, OCI & DEV-OPS (~20GB)
# =================================================================
Write-Console "Initializing BATCH 4: OCI & IaC" "INFO"

# Containerization (Docker Replacement)
Invoke-Package "choco" "podman-desktop"
Invoke-Package "choco" "nerdctl"
Invoke-Package "choco" "kubernetes-cli"
Invoke-Package "choco" "minikube"
Invoke-Package "choco" "kubernetes-kompose"
Invoke-Package "choco" "kubectx"
Invoke-Package "choco" "istioctl"
Invoke-Package "choco" "skaffold"
Invoke-Package "choco" "tilt"

# Infrastructure as Code (IaC) & CI/CD
Invoke-Package "choco" "terraform"
Invoke-Package "choco" "terraform-docs"
Invoke-Package "choco" "terragrunt"
Invoke-Package "choco" "tflint"
Invoke-Package "choco" "pulumi"
Invoke-Package "choco" "circleci-cli"
Invoke-Package "choco" "concourse"
Invoke-Package "choco" "databricks-cli"
Invoke-Package "choco" "nssm"

Invoke-BatchPause "Batch 4: OCI Containers & DevOps"

# =================================================================
# BATCH 5: KNOWLEDGE MGMT, UTILITIES & PS-MODULES (~15GB)
# =================================================================
Write-Console "Initializing BATCH 5: Knowledge Mgmt & PowerShell" "INFO"

# Knowledge Management & Publishing (Sovereignty Split)
Invoke-Package "winget" "Notion.Notion"
Invoke-Package "winget" "AppFlowy.AppFlowy" # The local-first enclave
Invoke-Package "winget" "Obsidian.Obsidian"
Invoke-Package "winget" "Posit.Quarto"
Invoke-Package "winget" "Logseq.Logseq"
Invoke-Package "winget" "calibre.calibre"
Invoke-Package "choco" "pandoc"
Invoke-Package "choco" "miktex"
Invoke-Package "choco" "hugo"

# Comet / Perplexity Note
# Comet is currently an early-access PWA without a stable package manager GUID. 
Write-Console "NOTE: Install Perplexity/Comet manually as an Edge/Chrome PWA." "WARN"

# System Utilities & CLI Modernization
Invoke-Package "winget" "Anysphere.Cursor"
Invoke-Package "winget" "CodeSector.TeraCopy"
Invoke-Package "winget" "WinMerge.WinMerge"
Invoke-Package "winget" "ScooterSoftware.BeyondCompare5"
Invoke-Package "winget" "Gephi.Gephi"
Invoke-Package "winget" "Doppler.doppler"
Invoke-Package "winget" "VivaldiTechnologies.Vivaldi"
Invoke-Package "winget" "Telegram.TelegramDesktop"
Invoke-Package "winget" "k6.k6"
Invoke-Package "choco" "imagemagick"
Invoke-Package "choco" "ffmpeg"
Invoke-Package "choco" "handbrake"
Invoke-Package "choco" "Qemu"

# Scoop CLI Tools
scoop bucket add extras; scoop bucket add nerd-fonts; scoop bucket add versions
$scoopTools = @("fzf", "ripgrep", "fd", "bat", "jq", "yq", "delta", "zoxide", "starship", "gping", "doggo", "xh", "fx", "tldr", "lazygit", "lazydocker", "btop", "glow", "age", "mkcert", "FiraCode-NF")
foreach ($tool in $scoopTools) { Invoke-Package "scoop" $tool }

# Core PowerShell Modules
$psMods = @("ActiveDirectory", "GroupPolicy", "Az", "Microsoft.Graph", "ImportExcel", "Pester", "SecretManagement", "Posh-SSH", "Carbon", "BurntToast")
foreach ($mod in $psMods) { Invoke-Package "psmodule" $mod }

Export-State
Stop-Transcript
Write-Host "`n[+] V5 EXHAUSTIVE SUBSTRATE RESTORATION COMPLETE." -ForegroundColor Green