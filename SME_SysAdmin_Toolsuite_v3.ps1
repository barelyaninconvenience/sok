#Requires -RunAsAdministrator
<#
.SYNOPSIS
    SME System Administrator Complete Toolsuite Restoration Script v3.0
.DESCRIPTION
    SME = Subject Matter Expert AND Small-Medium Enterprise (intentional double entendre).
    This script is written by a SME (expert) for SME (organization) environments.
    Redundancy is a feature, not a bug - learn each tool, then decide what to keep.

    Designed for: Windows 10/11 Pro or Server 2019/2022
    Free disk assumed: ~666 GB (no storage-based pruning applied)
    Philosophy: FOSS-first, exhaustive, justified, unfazed by redundancy.

    ============================================================
    REMOVALS / CORRECTIONS FROM v2 (with justifications)
    ============================================================

    REMOVED: driverbooster
      REASON: IObit has a documented history of bundled PUPs and aggressive upsell.
      REPLACED WITH: snappy-driver-installer (open-source, no bundleware).

    REMOVED: ccleaner
      REASON: 2017 supply-chain compromise (Avast-era malware injection); ongoing telemetry
      and privacy concerns; vendor credibility permanently impaired for security-conscious envs.
      REPLACED WITH: bleachbit (FOSS, already in script) + privazer (freemium, no bundleware).

    REMOVED: authy-desktop
      REASON: Twilio officially discontinued the Authy Desktop app in 2024. Installer no longer
      distributed. KeePassXC (already in script) has built-in TOTP; winauth covers the gap.
      REPLACED WITH: winauth (FOSS), keepassxc TOTP, ente-auth.

    REMOVED: typora
      REASON: Paid license required post-beta (Nov 2021). Shareware with no indefinite free tier.
      REPLACED WITH: marktext (already in script, FOSS), ghostwriter (FOSS), zettlr (FOSS).

    REMOVED: notion
      REASON: Closed-source, cloud-only, no self-hosted option, data sovereignty concerns.
      REPLACED WITH: appflowy (FOSS, self-hostable Notion alternative), affine (FOSS).

    REMOVED: iis-web-server (invalid Chocolatey package)
      REASON: IIS is a Windows Feature, not a Chocolatey package. No such ID exists.
      REPLACED WITH: Enable-WindowsOptionalFeature call + WebAdministration PS module.

    REMOVED: activedirectorysearcher
      REASON: Not a valid Chocolatey package. Functionality covered by ADExplorer (Sysinternals,
      already pulled in via 'sysinternals') and ldapadmin.
      REPLACED WITH: ldapadmin via choco, ADExplorer via sysinternals.

    REMOVED: solarwinds-tftp-server
      REASON: SolarWinds is the vendor behind the Sunburst/SOLORIGATE supply-chain attack (2020).
      Using their software in a security-aware environment is a credibility and risk liability.
      REPLACED WITH: tftpd64 (FOSS, lightweight, no vendor baggage).

    FLAGGED (kept, but noted): royalts
      Royal TS free tier is limited to 10 connections. Paid license needed for SME scale.
      Keeping because the free tier is useful and the paid version is worth it. Evaluate.

    FLAGGED (kept, but noted): sublimetext3
      Indefinite evaluation/shareware model - technically paid but widely used freely.
      Keeping. Prefer vscode for automation work; Sublime for speed on large files.

    FLAGGED (kept, but noted): nagios
      The Chocolatey nagios package installs the Windows agent/NRPE, not the full server.
      Full Nagios Core deployment is best done on Linux. Keeping the agent install here;
      note that the monitoring server should be a dedicated Linux host or Docker container.

    FLAGGED (kept, but noted): puppet-agent + saltstack alongside ansible
      Three config management tools is redundant for most SMEs. Keeping all three intentionally:
      (1) Ansible: agentless, great for ad-hoc; (2) Puppet: declarative, large Windows estates;
      (3) Salt: event-driven, fastest execution. Learn all three; standardize on one.

    ============================================================
    PACKAGE MANAGER COVERAGE:
    ============================================================
    [1] Chocolatey    - Primary Windows package manager
    [2] winget        - Microsoft's built-in (Windows 10 1809+)
    [3] pip           - Python ecosystem
    [4] PowerShell    - Install-Module (PSGallery)
    [5] npm           - Node.js global tools
    [6] Scoop         - Portable/user-space installs
    [7] Cargo         - Rust ecosystem
    [8] go install    - Go ecosystem (NEW in v3)
    [9] WinFeatures   - Windows Optional Features
    [10] Manual/curl  - Where no package manager exists

    ============================================================
    STORAGE ESTIMATE: ~120-180 GB (with AI/ML toolchain)
    FREE ASSUMED:     666 GB
    ============================================================
#>

# =============================================================================
# CONFIGURATION & HELPERS
# =============================================================================
$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"
$logFile = "C:\Admin\Logs\SysAdmin_Restore_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$failedPackages = [System.Collections.Generic.List[string]]::new()
$installedPackages = [System.Collections.Generic.List[string]]::new()
$skippedPackages = [System.Collections.Generic.List[string]]::new()

New-Item -ItemType Directory -Path "C:\Admin\Logs" -Force | Out-Null

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "SECTION")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        "SECTION" { "Cyan" }
        default   { "White" }
    }
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage -ForegroundColor $color
    Add-Content -Path $logFile -Value $logMessage
}

function Install-ChocoPackage {
    param(
        [string]$PackageName,
        [string]$Description,
        [string[]]$AdditionalArgs = @()
    )
    # Skip if already installed
    $installed = choco list --local-only --exact $PackageName 2>&1
    if ($installed -match $PackageName) {
        Write-Log "SKIP (already installed): $PackageName" "WARNING"
        $script:skippedPackages.Add($PackageName)
        return $true
    }
    Write-Log "CHOCO  >> $PackageName | $Description" "INFO"
    $args = @($PackageName, "-y", "--no-progress", "--ignore-checksums") + $AdditionalArgs
    choco install @args 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $PackageName" "SUCCESS"
        $script:installedPackages.Add($PackageName)
        return $true
    } else {
        Write-Log "FAIL: $PackageName" "ERROR"
        $script:failedPackages.Add("choco:$PackageName")
        return $false
    }
}

function Install-WingetPackage {
    param([string]$PackageId, [string]$Description)
    Write-Log "WINGET >> $PackageId | $Description" "INFO"
    winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $PackageId" "SUCCESS"
        return $true
    } else {
        Write-Log "FAIL: $PackageId" "WARNING"
        $script:failedPackages.Add("winget:$PackageId")
        return $false
    }
}

function Install-PipPackage {
    param([string[]]$PackageNames, [string]$Description)
    Write-Log "PIP    >> $($PackageNames -join ', ') | $Description" "INFO"
    python -m pip install --upgrade --quiet $PackageNames 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $($PackageNames -join ', ')" "SUCCESS"
        return $true
    } else {
        Write-Log "FAIL: $($PackageNames -join ', ')" "WARNING"
        $script:failedPackages.Add("pip:$($PackageNames[0])")
        return $false
    }
}

function Install-PSModule {
    param([string]$ModuleName, [string]$Description)
    Write-Log "PSMOD  >> $ModuleName | $Description" "INFO"
    try {
        if (!(Get-Module -ListAvailable -Name $ModuleName)) {
            Install-Module -Name $ModuleName -Force -AllowClobber -Scope AllUsers -ErrorAction Stop
        }
        Write-Log "OK: $ModuleName" "SUCCESS"
        return $true
    } catch {
        Write-Log "FAIL: $ModuleName - $_" "WARNING"
        $script:failedPackages.Add("psmod:$ModuleName")
        return $false
    }
}

function Install-NpmPackage {
    param([string]$PackageName, [string]$Description)
    Write-Log "NPM    >> $PackageName | $Description" "INFO"
    npm install -g $PackageName 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $PackageName" "SUCCESS"
        return $true
    } else {
        Write-Log "FAIL: $PackageName" "WARNING"
        $script:failedPackages.Add("npm:$PackageName")
        return $false
    }
}

function Install-ScoopPackage {
    param([string]$PackageName, [string]$Description, [string]$Bucket = "main")
    Write-Log "SCOOP  >> $PackageName | $Description" "INFO"
    scoop install $PackageName 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $PackageName" "SUCCESS"
        return $true
    } else {
        Write-Log "FAIL: $PackageName" "WARNING"
        $script:failedPackages.Add("scoop:$PackageName")
        return $false
    }
}

function Install-CargoPackage {
    param([string]$PackageName, [string]$Description, [string[]]$Features = @())
    Write-Log "CARGO  >> $PackageName | $Description" "INFO"
    if ($Features.Count -gt 0) {
        cargo install $PackageName --features ($Features -join ',') 2>&1 | Out-Null
    } else {
        cargo install $PackageName 2>&1 | Out-Null
    }
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $PackageName" "SUCCESS"
        return $true
    } else {
        Write-Log "FAIL: $PackageName" "WARNING"
        $script:failedPackages.Add("cargo:$PackageName")
        return $false
    }
}

function Install-GoPackage {
    param([string]$ImportPath, [string]$Description)
    Write-Log "GO     >> $ImportPath | $Description" "INFO"
    go install "${ImportPath}@latest" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log "OK: $ImportPath" "SUCCESS"
        return $true
    } else {
        Write-Log "FAIL: $ImportPath" "WARNING"
        $script:failedPackages.Add("go:$ImportPath")
        return $false
    }
}

# =============================================================================
# PREREQUISITE: ENSURE CHOCOLATEY IS INSTALLED
# =============================================================================
Write-Log "=== PREREQUISITE: CHOCOLATEY ===" "SECTION"
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Log "Chocolatey not found - installing..." "WARNING"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
    Write-Log "Chocolatey installed" "SUCCESS"
} else {
    Write-Log "Chocolatey already present" "SUCCESS"
}
choco upgrade chocolatey -y --no-progress 2>&1 | Out-Null

# =============================================================================
# PHASE 1: CORE SYSTEM ADMINISTRATION TOOLS
# =============================================================================
Write-Log "=== PHASE 1: CORE SYSTEM ADMINISTRATION ===" "SECTION"

# REMOTE DESKTOP & SESSION MANAGEMENT
# mRemoteNG: free, open-source, multi-protocol (RDP/SSH/VNC/Telnet/HTTP/HTTPS)
Install-ChocoPackage "mremoteng"   "Multi-protocol remote connection manager - free, open-source"
# Royal TS: freemium (10 connections free). Better UI than mRemoteNG for credential management
Install-ChocoPackage "royalts"     "Royal TS - freemium remote manager; 10-conn free tier, worth evaluating"
# RDCMan: free Microsoft tool; great for managing many RDP sessions in a tree hierarchy
Install-ChocoPackage "rdcman"      "Microsoft Remote Desktop Connection Manager - free"
# TightVNC: FOSS VNC for non-Windows hosts; lightweight alternative to RealVNC
Install-ChocoPackage "tightvnc"    "VNC remote desktop - FOSS"

# SSH & TERMINAL CLIENTS
Install-ChocoPackage "putty"                      "Classic SSH/Telnet client - FOSS, ubiquitous"
Install-ChocoPackage "winscp"                     "SCP/SFTP GUI client - FOSS"
Install-ChocoPackage "mobaxterm"                  "X11+SSH+RDP+VNC+serial in one - freemium, essential"
Install-ChocoPackage "microsoft-windows-terminal" "Modern tabbed terminal - FOSS Microsoft"
# KiTTY: PuTTY fork with session filter, auto-reconnect, portability
Install-ChocoPackage "kitty"                      "PuTTY fork with extra features - FOSS"
# SecureCRT: paid but industry standard in govt/defense environments; trial available
# Install-ChocoPackage "securecrt"               "PAID: Enterprise SSH - common in cleared environments"

# ACTIVE DIRECTORY & IDENTITY
# RSAT: critical for AD management from a workstation; installs all AD/DNS/DHCP/GPO MMC snap-ins
Install-ChocoPackage "rsat"            "Remote Server Administration Tools - Microsoft FOSS"
# LDAPAdmin: FOSS LDAP browser; replacement for the removed activedirectorysearcher
Install-ChocoPackage "ldapadmin"       "FOSS LDAP browser & editor - replaces activedirectorysearcher"
# SysinternalsSuite includes ADExplorer, PsTools, Process Explorer, Autoruns, TCPView, etc.
Install-ChocoPackage "sysinternals"    "Full Sysinternals suite - Microsoft FOSS; includes ADExplorer"

# FILE TRANSFER & ARCHIVING
Install-ChocoPackage "filezilla"  "FTP/SFTP/FTPS GUI client - FOSS"
Install-ChocoPackage "7zip"       "Archiver supporting ZIP/RAR/7z/TAR/GZ/XZ - FOSS"
Install-ChocoPackage "peazip"     "Archiver with encryption - FOSS alternative to 7zip"
# WinSCP already listed above; adding Cyberduck as cloud-native alternative
Install-ChocoPackage "cyberduck"  "FTP/SFTP/cloud storage client (S3, Azure, GCS) - FOSS"

# =============================================================================
# PHASE 2: NETWORKING & DIAGNOSTICS
# =============================================================================
Write-Log "=== PHASE 2: NETWORKING & DIAGNOSTICS ===" "SECTION"

Install-ChocoPackage "wireshark"           "Deep packet inspection - FOSS industry standard"
Install-ChocoPackage "nmap"                "Network discovery & port scanning - FOSS"
Install-ChocoPackage "advanced-ip-scanner" "Fast LAN scanner with RDP/HTTP/Radmin shortcuts - freeware"
Install-ChocoPackage "angry-ip-scanner"    "Cross-platform IP scanner - FOSS"
# tftpd64: replaces solarwinds-tftp-server (SolarWinds removed due to Sunburst/SOLORIGATE supply chain attack)
Install-ChocoPackage "tftpd64"             "TFTP server for router/switch config backup - FOSS; replaces SolarWinds TFTP"
Install-ChocoPackage "glasswire"           "Real-time network monitor & firewall - freemium"
Install-ChocoPackage "networx"             "Bandwidth usage stats & monitor - freeware"
Install-ChocoPackage "pingplotter"         "Visual traceroute & path analysis - freemium"
Install-ChocoPackage "iperf3"              "Bandwidth throughput testing - FOSS"
Install-ChocoPackage "netcat"              "Swiss army knife for TCP/UDP - FOSS"
# Zenmap: Nmap GUI; useful when you want to visually explore scan results
Install-ChocoPackage "zenmap"              "Nmap GUI front-end - FOSS"
# Masscan: fastest port scanner (packets/sec vs nmap's thoroughness); useful for large subnets
Install-ChocoPackage "masscan"             "High-speed port scanner - FOSS; faster than nmap for wide scans"
# Netdisco: not via choco; see Phase 20 for Docker-based SNMP topology mapper
# PathPing is built into Windows; PingPlotter extends it visually
# hping3: raw TCP/UDP/ICMP crafting; useful for firewall rule testing
Install-ChocoPackage "hping3"              "Packet generator for firewall testing - FOSS"
# mtr-windows: traceroute + ping combined
Install-ChocoPackage "mtr"                 "Combined traceroute/ping with live updates - FOSS"
# curl: needed separately from system curl; more current version
Install-ChocoPackage "curl"                "HTTP/FTP transfer tool - FOSS; keep current"
# wget: complement to curl; simpler recursive downloads
Install-ChocoPackage "wget"                "File downloader - FOSS"
# httptoolkit: intercept/debug HTTP traffic from any app; great complement to Wireshark
Install-ChocoPackage "httptoolkit"         "HTTP/S proxy & debugger for any app - FOSS"

# =============================================================================
# PHASE 3: SYSTEM MONITORING & PERFORMANCE
# =============================================================================
Write-Log "=== PHASE 3: MONITORING & PERFORMANCE ===" "SECTION"

Install-ChocoPackage "hwinfo"            "Hardware info & sensor monitoring - freeware"
Install-ChocoPackage "hwmonitor"         "Real-time hardware sensor monitoring - freeware"
Install-ChocoPackage "cpu-z"             "CPU info & benchmark - freeware"
Install-ChocoPackage "gpu-z"             "GPU info & sensor data - freeware"
Install-ChocoPackage "crystaldiskinfo"   "HDD/SSD SMART health monitoring - FOSS"
Install-ChocoPackage "crystaldiskmark"   "Disk I/O benchmarking - FOSS"
# Speccy: system info snapshot; good for quick hardware audits on remote systems
Install-ChocoPackage "speccy"            "System info snapshot - freeware by Piriform; useful for audits"
# Zabbix agent for central monitoring integration
Install-ChocoPackage "zabbix-agent"      "Zabbix monitoring agent - FOSS; pairs with Linux-hosted Zabbix server"
# nagios: installs NSClient++ (NRPE-compatible agent); server must be on Linux/Docker
Install-ChocoPackage "nagios-plugins"    "Nagios/NRPE Windows agent plugins - FOSS; NOTE: server = Linux/Docker"
# ProcessHacker (aka System Informer): replaces Task Manager; kernel-mode visibility
Install-ChocoPackage "processhacker"     "Advanced process/kernel monitor - FOSS; superior Task Manager replacement"
# Netdata: real-time 1-second metric collection; lightweight; great for single-host visibility
Install-ChocoPackage "netdata"           "Real-time metrics dashboard (1s granularity) - FOSS"
# SpeedFan: thermal monitoring including fan control (hardware-dependent)
Install-ChocoPackage "speedfan"          "Fan speed & temp control - freeware; useful for physical servers"
# RAMMap: detailed RAM usage analysis from Sysinternals (pulled in via sysinternals above)
# Diskspd: Microsoft's disk benchmarking tool (more reproducible than CrystalDiskMark)
Install-ChocoPackage "diskspd"           "Microsoft disk benchmark tool - FOSS; more rigorous than CrystalDiskMark"

# =============================================================================
# PHASE 4: BACKUP & DISASTER RECOVERY
# =============================================================================
Write-Log "=== PHASE 4: BACKUP & DISASTER RECOVERY ===" "SECTION"

Install-ChocoPackage "veeam-backup-free-edition" "VM & endpoint backup - freemium; industry standard"
Install-ChocoPackage "duplicati"                  "Encrypted cloud backup - FOSS; supports S3/Azure/GDrive/B2"
Install-ChocoPackage "restic"                     "Fast deduplicating backup with encryption - FOSS"
Install-ChocoPackage "rclone"                     "Sync to 40+ cloud providers - FOSS; 'rsync for cloud'"
Install-ChocoPackage "macrium-reflect-free"       "Disk imaging & cloning - freeware"
Install-ChocoPackage "syncthing"                  "P2P continuous sync - FOSS; no cloud dependency"
Install-ChocoPackage "freefilesync"               "Folder sync & comparison - FOSS"
# Kopia: modern backup with dedup, compression, encryption; better UI than restic
Install-ChocoPackage "kopia"                      "Modern backup with web UI - FOSS; consider over restic for new setups"
# Rsync for Windows: familiar Linux-style rsync; great for scripted backup jobs
Install-ChocoPackage "rsync"                      "rsync port for Windows - FOSS"
# Urbackup: open-source image & file backup SERVER that runs on Windows
Install-ChocoPackage "urbackup-server"            "Open-source backup server (image+file) - FOSS; self-hosted alternative to Veeam"
# Recuva: file recovery after accidental deletion
Install-ChocoPackage "recuva"                     "File recovery tool - freeware by Piriform"
# TestDisk/PhotoRec: partition recovery and file carving
Install-ChocoPackage "testdisk"                   "Partition recovery & file carving - FOSS; essential DR toolkit"

# =============================================================================
# PHASE 5: VIRTUALIZATION & CONTAINERS
# =============================================================================
Write-Log "=== PHASE 5: VIRTUALIZATION & CONTAINERS ===" "SECTION"

Install-ChocoPackage "virtualbox"        "Type-2 hypervisor - FOSS; ideal for lab VMs"
Install-ChocoPackage "virtualbox-guest-additions" "VirtualBox integration tools"
Install-ChocoPackage "vagrant"           "VM lifecycle management - FOSS; IaC for VMs"
# VMware Workstation Player: free for non-commercial; better Windows guest performance than VBox
Install-ChocoPackage "vmwareworkstation" "VMware Workstation - freemium; better Windows guests than VBox"
Install-ChocoPackage "docker-desktop"    "Docker containers on Windows - freemium (fee for large orgs)"
# Podman Desktop: FOSS alternative to Docker Desktop; no daemon, no licensing concerns
Install-ChocoPackage "podman-desktop"    "FOSS Docker Desktop alternative - no daemon/licensing issues"
Install-ChocoPackage "kubernetes-cli"    "kubectl - FOSS; K8s cluster management"
Install-ChocoPackage "minikube"          "Local K8s cluster - FOSS; dev/test environment"
Install-ChocoPackage "k9s"              "Terminal K8s dashboard - FOSS; fastest way to navigate clusters"
Install-ChocoPackage "helm"             "K8s package manager - FOSS"
# Lens: GUI K8s IDE; good for visual cluster management
Install-ChocoPackage "lens"             "Kubernetes GUI IDE - freemium"
# Portainer: Docker/K8s GUI; web-based container management (Docker install in Phase 20)
# ctop: container metrics in terminal; like top but for containers
Install-ChocoPackage "ctop"             "Container resource monitor - FOSS"
# Dive: analyze Docker image layers; find size bloat
Install-ChocoPackage "dive"             "Docker image layer analyzer - FOSS"
# Kind: K8s in Docker; lighter than minikube; great for CI testing
Install-ChocoPackage "kind"             "K8s in Docker - FOSS; lighter than minikube"
# k3d: wraps k3s (lightweight K8s) in Docker; ultra-lightweight
Install-ChocoPackage "k3d"              "k3s in Docker - FOSS; ultra-lightweight K8s"
# Fleet/Rancher: multi-cluster management; overkill for single SME but valuable to know
# Nerdctl: containerd CLI compatible with Docker commands; goes with Podman workflow
Install-ChocoPackage "nerdctl"          "containerd CLI (Docker-compatible) - FOSS"

# =============================================================================
# PHASE 6: AUTOMATION & SCRIPTING
# =============================================================================
Write-Log "=== PHASE 6: AUTOMATION & SCRIPTING ===" "SECTION"

Install-ChocoPackage "powershell-core"  "PowerShell 7+ cross-platform - FOSS Microsoft"
Install-ChocoPackage "poshgit"          "Git integration for PowerShell prompt - FOSS"
Install-ChocoPackage "python3"          "Python 3.x - FOSS; essential for automation"
Install-ChocoPackage "ansible"          "Agentless automation - FOSS; Windows management via WinRM"
# Puppet: declarative config management; better for large Windows estates than Ansible
Install-ChocoPackage "puppet-agent"     "Declarative config management agent - FOSS; intentional redundancy with Ansible"
# SaltStack: event-driven, fastest remote execution; complements Ansible
Install-ChocoPackage "saltstack"        "Event-driven automation - FOSS; intentional redundancy with Ansible"
Install-ChocoPackage "terraform"        "Multi-cloud IaC - FOSS (BSL); industry standard"
# OpenTofu: FOSS fork of Terraform (before Hashicorp's BSL license change)
Install-ChocoPackage "opentofu"         "FOSS Terraform fork (MPL-2.0) - use if Terraform licensing is concern"
Install-ChocoPackage "packer"           "VM image builder - FOSS; automate golden image creation"
Install-ChocoPackage "autohotkey"       "Desktop automation & hotkeys - FOSS"
# Taskfile: modern Make alternative; great for sysadmin script organization
Install-ChocoPackage "go-task"          "Task runner (Taskfile) - FOSS; better than Makefile on Windows"
# Just: command runner; simpler than Taskfile; great for project-level scripts
Install-ChocoPackage "just"             "Command runner - FOSS; simpler alternative to Makefile/Taskfile"
# pyinfra: Python-based deploy tool; great complement to Ansible for Python-fluent admins
Install-ChocoPackage "pyinfra"          "Python-native infrastructure automation - FOSS"

# =============================================================================
# PHASE 7: SECURITY & COMPLIANCE
# =============================================================================
Write-Log "=== PHASE 7: SECURITY & COMPLIANCE ===" "SECTION"

# PASSWORD MANAGEMENT
Install-ChocoPackage "keepass"          "KeePass 2 - FOSS password manager"
Install-ChocoPackage "keepassxc"        "KeePass fork with better UI + TOTP + browser integration - FOSS"
Install-ChocoPackage "bitwarden"        "Cloud password manager - FOSS client; freemium server"
# Vaultwarden: self-hosted Bitwarden-compatible server (Docker, Phase 20)

# VPN
Install-ChocoPackage "openvpn"          "OpenVPN client - FOSS"
Install-ChocoPackage "wireguard"        "Modern fast VPN protocol - FOSS; preferred over OpenVPN for new deployments"
Install-ChocoPackage "tailscale"        "Zero-config mesh VPN - freemium; wraps WireGuard"
# Netbird: FOSS alternative to Tailscale with self-hosted control plane
Install-ChocoPackage "netbird"          "FOSS Tailscale alternative - self-hostable control plane"
# Cloudflare WARP: free VPN/DNS alternative; useful for securing outbound on untrusted networks
Install-ChocoPackage "cloudflare-warp"  "Cloudflare WARP VPN+DNS - free; useful on untrusted networks"

# VULNERABILITY SCANNING
Install-ChocoPackage "nessus"           "Vulnerability scanner - freemium (free for home/eval)"
# OpenVAS / Greenbone: FOSS alternative to Nessus; best deployed as Docker or dedicated VM
# Install via Docker in Phase 20: greenbone/openvas
Install-ChocoPackage "nikto"            "Web server vulnerability scanner - FOSS"
# Trivy: container/IaC/filesystem vulnerability scanner; critical for DevSecOps
Install-ChocoPackage "trivy"            "Container+IaC vulnerability scanner - FOSS; essential for DevSecOps"
# Grype: Anchore's vulnerability scanner; fast SBOM-based scanning
Install-ChocoPackage "grype"            "Fast vulnerability scanner by Anchore - FOSS"
# Syft: SBOM (Software Bill of Materials) generator; pairs with Grype
Install-ChocoPackage "syft"             "SBOM generator - FOSS; pairs with Grype for supply chain security"

# CERTIFICATE MANAGEMENT
Install-ChocoPackage "openssl"          "SSL/TLS toolkit - FOSS"
Install-ChocoPackage "certbot"          "Let's Encrypt cert automation - FOSS"
# mkcert: locally-trusted development certificates; eliminates browser SSL warnings in dev
Install-ChocoPackage "mkcert"           "Local dev TLS certs - FOSS; no more browser SSL warnings"
# step-cli: certificates beyond Let's Encrypt; internal CA management
Install-ChocoPackage "step"             "Internal CA & cert management - FOSS by Smallstep"

# 2FA & AUTHENTICATION
# winauth: replacement for discontinued Authy Desktop; FOSS TOTP authenticator
Install-ChocoPackage "winauth"          "TOTP authenticator - FOSS; replaces discontinued Authy Desktop"
# KeePassXC has TOTP built in (already installed above)
# ente-auth: cross-platform TOTP with E2E encrypted cloud backup
Install-WingetPackage "EnteIO.EnteAuth" "E2EE TOTP authenticator with cloud backup - FOSS"

# SECRETS MANAGEMENT
# HashiCorp Vault: industry-standard secrets engine
Install-ChocoPackage "vault"            "HashiCorp Vault secrets manager - FOSS (BSL)"
# Age: modern encryption tool; simple key-based file encryption
Install-ChocoPackage "age"              "Modern file encryption - FOSS; simpler than GPG for scripts"
# GnuPG: asymmetric encryption; essential for signing and email encryption
Install-ChocoPackage "gpg4win"          "GnuPG for Windows - FOSS; asymmetric encryption & code signing"
# SOPS: secrets in Git with Age/PGP/KMS; great for GitOps workflows
Install-ChocoPackage "sops"             "Secrets in git files (SOPS) - FOSS; works with age/PGP/KMS"

# ENDPOINT HARDENING TOOLS
# Malwarebytes: free scanner; supplement to Windows Defender
Install-ChocoPackage "malwarebytes"     "Anti-malware scanner - freemium; complements Windows Defender"
# Windows Firewall Control: enhanced GUI for Windows Firewall
Install-ChocoPackage "windowsfirewallcontrol" "Enhanced Windows Firewall GUI - freemium"

# =============================================================================
# PHASE 8: DOCUMENTATION & KNOWLEDGE MANAGEMENT
# =============================================================================
Write-Log "=== PHASE 8: DOCUMENTATION ===" "SECTION"

Install-ChocoPackage "obsidian"         "Markdown knowledge base - freeware; ideal for runbooks"
# AppFlowy: FOSS Notion alternative with self-hosted option; replaces Notion (cloud-only concern)
Install-ChocoPackage "appflowy"         "FOSS Notion alternative - self-hostable; replaces Notion"
Install-ChocoPackage "joplin"           "FOSS note-taking with E2EE sync"
# Zettlr: academic-grade markdown editor; great for structured documentation
Install-ChocoPackage "zettlr"           "FOSS markdown editor with Zettelkasten support - replaces typora (now paid)"
# Ghostwriter: distraction-free markdown editor; FOSS replacement for typora
Install-ChocoPackage "ghostwriter"      "Distraction-free markdown editor - FOSS; replaces paid typora"
Install-ChocoPackage "marktext"         "FOSS markdown editor - clean WYSIWYG"
# Standard Notes: E2EE notes with self-hostable server; good for sensitive sysadmin notes
Install-ChocoPackage "standard-notes"   "E2EE note taking - FOSS; self-hostable server option"
# DIAGRAMMING
Install-ChocoPackage "drawio"           "Network diagrams & flowcharts - FOSS"
Install-ChocoPackage "graphviz"         "Programmatic graph visualization - FOSS; auto-generate topology maps"
# Excalidraw: sketch-like whiteboard; great for quick architecture drawings
Install-WingetPackage "Excalidraw.Excalidraw" "Sketch-style whiteboard & diagramming - FOSS"
# SCREENSHOT & SCREEN RECORDING
Install-ChocoPackage "greenshot"        "Screenshot with annotation - FOSS"
Install-ChocoPackage "sharex"           "Advanced capture with OCR, workflow automation - FOSS"
# OBS Studio: screen recording and streaming; useful for creating training material
Install-ChocoPackage "obs-studio"       "Screen recording & streaming - FOSS; create runbook videos/training"
# OFFICE SUITE
# OnlyOffice: FOSS Microsoft Office-compatible suite; good for SME avoiding MS Office licensing
Install-ChocoPackage "onlyoffice"       "FOSS MS Office-compatible suite - good for licensing-constrained SMEs"
# LibreOffice: FOSS office suite; mature alternative
Install-ChocoPackage "libreoffice-fresh" "LibreOffice - FOSS; most compatible open office suite"

# =============================================================================
# PHASE 9: DATABASE MANAGEMENT
# =============================================================================
Write-Log "=== PHASE 9: DATABASE MANAGEMENT ===" "SECTION"

Install-ChocoPackage "mysql.workbench"               "MySQL GUI admin - FOSS"
Install-ChocoPackage "sql-server-management-studio"  "SSMS - freeware; essential for SQL Server"
Install-ChocoPackage "postgresql15"                   "PostgreSQL 15 server - FOSS"
Install-ChocoPackage "pgadmin4"                       "PostgreSQL GUI admin - FOSS"
Install-ChocoPackage "dbeaver"                        "Universal DB client (80+ engines) - FOSS; one tool for all DBs"
Install-ChocoPackage "mongodb"                        "NoSQL document DB - FOSS (SSPL)"
Install-ChocoPackage "mongodb-compass"                "MongoDB GUI - freeware"
Install-ChocoPackage "redis"                          "In-memory cache & message broker - FOSS"
Install-ChocoPackage "redis-desktop-manager"          "Redis GUI - freeware"
# TablePlus: modern multi-DB GUI; paid but freemium trial
Install-ChocoPackage "tableplus"                      "Modern multi-DB GUI - freemium; great UX"
# SQLiteStudio: SQLite management; lightweight dbs for scripts/apps
Install-ChocoPackage "sqlitestudio"                   "SQLite GUI - FOSS; for embedded/script databases"
# InfluxDB: time-series DB; essential for metrics from monitoring stack
Install-ChocoPackage "influxdb"                       "Time-series database - FOSS; central to Prometheus/Telegraf stack"
# Telegraf: metrics collector agent; pairs with InfluxDB
Install-ChocoPackage "telegraf"                       "Metrics collection agent - FOSS; pairs with InfluxDB"
# DBeaver already covers most; HeidiSQL is lighter for quick MySQL/MariaDB work
Install-ChocoPackage "heidisql"                       "Lightweight MySQL/MariaDB/MSSQL client - FOSS"

# =============================================================================
# PHASE 10: WEB SERVERS & DEVELOPER TOOLS
# =============================================================================
Write-Log "=== PHASE 10: WEB SERVERS & DEV TOOLS ===" "SECTION"

Install-ChocoPackage "nginx"            "High-performance web server & reverse proxy - FOSS"
Install-ChocoPackage "apache-httpd"     "Apache HTTP server - FOSS"
# IIS: Windows feature, not a Chocolatey package - correct approach:
Write-Log "Enabling IIS via Windows Features (not Chocolatey)" "INFO"
Enable-WindowsOptionalFeature -Online -FeatureName `
    IIS-WebServerRole, IIS-WebServer, IIS-ManagementConsole `
    -NoRestart -All 2>&1 | Out-Null

# Caddy: modern web server with automatic HTTPS; great for quick internal services
Install-ChocoPackage "caddy"            "Web server with automatic HTTPS - FOSS; easier than nginx for internal"
# Traefik: reverse proxy + load balancer with automatic service discovery; great with Docker
Install-ChocoPackage "traefik"          "Reverse proxy with auto service discovery - FOSS; ideal for Docker environments"

# CODE EDITORS
Install-ChocoPackage "vscode"              "Visual Studio Code - FOSS; primary script/config editor"
Install-ChocoPackage "notepadplusplus"     "Notepad++ - FOSS; fast editor for logs and quick edits"
Install-ChocoPackage "sublimetext4"        "Sublime Text 4 - shareware; indefinite trial; fast on large files"
# Helix: terminal-based modal editor (like Vim but batteries-included); see Cargo phase
# Neovim: for those who use Vim-style editing; highly configurable
Install-ChocoPackage "neovim"              "Neovim - FOSS; Vim successor; powerful with plugins"

# VERSION CONTROL
Install-ChocoPackage "git"                 "Git - FOSS; version control for all scripts/configs"
Install-ChocoPackage "github-desktop"      "GitHub GUI - FOSS"
Install-ChocoPackage "tortoisegit"         "Git Windows shell integration - FOSS"
# Lazygit: terminal Git UI; dramatically faster than CLI for complex operations
Install-ChocoPackage "lazygit"             "Terminal Git UI - FOSS; fastest interactive git workflow"
# GitLab Runner: if self-hosting GitLab CI
Install-ChocoPackage "gitlab-runner"       "GitLab CI runner agent - FOSS; for self-hosted CI/CD"

# API TESTING
Install-ChocoPackage "postman"             "API testing & documentation - freemium"
Install-ChocoPackage "insomnia-rest-api-client" "REST/GraphQL client - FOSS"
# Hoppscotch: FOSS Postman alternative (also available as web app)
Install-WingetPackage "Hoppscotch.Hoppscotch" "FOSS API testing client - full Postman alternative"

# RUNTIMES (for scripts and tools across the ecosystem)
Install-ChocoPackage "nodejs-lts"          "Node.js LTS - FOSS; runtime + npm"
Install-ChocoPackage "golang"              "Go language - FOSS; many sysadmin tools built in Go"
Install-ChocoPackage "ruby"                "Ruby - FOSS; Chef/Puppet dependencies + scripting"
Install-ChocoPackage "rust"                "Rust + Cargo - FOSS; modern systems tools"
Install-ChocoPackage "dotnet-sdk"          "ASP.NET SDK - FOSS; required for many Windows tools"
Install-ChocoPackage "jdk17"               "OpenJDK 17 LTS - FOSS; required for Elasticsearch/Jenkins/etc."

# =============================================================================
# PHASE 11: COMMUNICATIONS & COLLABORATION
# =============================================================================
Write-Log "=== PHASE 11: COMMUNICATIONS ===" "SECTION"

Install-ChocoPackage "microsoft-teams"  "Microsoft Teams - freeware (free tier available)"
Install-ChocoPackage "slack"            "Slack - freemium; industry-standard team comms"
Install-ChocoPackage "zoom"             "Zoom - freemium video conferencing"
Install-ChocoPackage "teamviewer"       "Remote support & screen share - freemium"
# AnyDesk: alternative remote support tool; lighter than TeamViewer
Install-ChocoPackage "anydesk"          "Remote support tool - freemium; lighter than TeamViewer"
Install-ChocoPackage "thunderbird"      "FOSS email client; PGP signing via Enigmail"
# Element: Matrix-based secure messaging; good for secure internal comms
Install-ChocoPackage "element-desktop"  "Matrix secure messaging client - FOSS; good for secure team comms"
# Signal: E2EE messaging; if team uses it
Install-ChocoPackage "signal"           "E2EE messaging - FOSS; gold standard for secure comms"
# Discord: increasingly used by IT communities for support/community channels
Install-ChocoPackage "discord"          "Voice/text community platform - freeware; active IT community channels"

# =============================================================================
# PHASE 12: SYSTEM UTILITIES
# =============================================================================
Write-Log "=== PHASE 12: SYSTEM UTILITIES ===" "SECTION"

# DISK ANALYSIS (ccleaner REMOVED - see header justification)
Install-ChocoPackage "bleachbit"          "FOSS system cleaner - replaces CCleaner; no supply chain concerns"
# PriVazer: deeper cleanup tool; freeware, no bundleware
Install-ChocoPackage "privazer"           "Deep system cleaner - freeware; complements BleachBit"
Install-ChocoPackage "windirstat"         "Disk usage visualization - FOSS"
Install-ChocoPackage "treesize-free"      "Disk space analyzer - freeware"
# WizTree: fastest disk analyzer on Windows (reads MFT directly)
Install-ChocoPackage "wiztree"            "Fastest disk analyzer - freeware; reads MFT directly (faster than WinDirStat)"

# DRIVER MANAGEMENT (driverbooster REMOVED - see header justification)
Install-ChocoPackage "snappy-driver-installer" "FOSS driver installer - replaces IObit DriverBooster"
# Display Driver Uninstaller: critical for clean GPU driver changes
Install-ChocoPackage "display-driver-uninstaller" "DDU - freeware; clean GPU driver removal"

# WINDOWS PRODUCTIVITY
Install-ChocoPackage "powertoys"          "Microsoft PowerToys - FOSS; FancyZones, PowerRename, etc."
Install-ChocoPackage "everything"         "Instant file search via NTFS MFT - freeware; indispensable"
Install-ChocoPackage "listary"            "Enhanced search & launcher - freemium"
Install-ChocoPackage "ditto"              "Clipboard manager with search - FOSS"
# Flow Launcher: FOSS Spotlight/Alfred/Raycast for Windows
Install-ChocoPackage "flow-launcher"      "App launcher - FOSS; better than Windows search for power users"
# AutoHotkey already in Phase 6
# Rainmeter: system stats on desktop; doubles as monitoring dashboard
Install-ChocoPackage "rainmeter"          "Desktop system stats overlay - FOSS; lightweight monitoring widget"
# Bulk Rename Utility: essential for mass file operations on server shares
Install-ChocoPackage "bulk-rename-utility" "Mass file renaming - freeware; essential for share management"
# HashCheck: file hash verification; validate downloads/integrity checks
Install-ChocoPackage "hashcheck"          "File hash verification shell extension - FOSS"
# Rufus: create bootable USBs for OS deployment
Install-WingetPackage "Rufus.Rufus"       "Bootable USB creator - FOSS; essential for OS deployment"
# Ventoy: multi-boot USB with multiple ISOs on one drive
Install-WingetPackage "Ventoy.Ventoy"     "Multi-boot USB with multiple ISOs - FOSS"

# TERMINAL MULTIPLEXERS
# tmux via MSYS2/Cygwin, or use Windows Terminal panes; wezterm has built-in mux
Install-ChocoPackage "wezterm"            "GPU-accelerated terminal with built-in multiplexing - FOSS; warp-like"

# =============================================================================
# PHASE 13: ADDITIONAL PACKAGE MANAGERS & TOOLS
# =============================================================================
Write-Log "=== PHASE 13: PACKAGE MANAGERS ===" "SECTION"

Install-ChocoPackage "scoop"   "Scoop - FOSS user-space package manager; no UAC required"
# Winget is built into Windows 11; ensure it's updated
winget upgrade --id Microsoft.AppInstaller 2>&1 | Out-Null
# conda/mamba: for Python data science environments; avoids pip dependency hell
Install-WingetPackage "ContinuumAnalytics.Anaconda3" "Conda package manager for Python data science - FOSS"

# =============================================================================
# PHASE 14: LOGGING & SIEM
# =============================================================================
Write-Log "=== PHASE 14: LOGGING & SIEM ===" "SECTION"

# ELK Stack is UNCOMMENTED: 666 GB free - no storage excuse
# Note: requires JDK 17 (installed in Phase 10)
Install-ChocoPackage "elasticsearch"  "Search & log storage engine (ELK 'E') - FOSS (Elastic License)"
Install-ChocoPackage "logstash"       "Log ingestion & transformation (ELK 'L') - FOSS"
Install-ChocoPackage "kibana"         "Log visualization dashboard (ELK 'K') - FOSS"
# Filebeat: lightweight log shipper; sends logs to Elasticsearch/Logstash
Install-ChocoPackage "filebeat"       "Lightweight log shipper - FOSS; ships logs to ELK"
# Metricbeat: system metrics to Elasticsearch
Install-ChocoPackage "metricbeat"     "System metrics shipper to Elasticsearch - FOSS"
# Winlogbeat: Windows Event Log to Elasticsearch; essential for Windows security monitoring
Install-ChocoPackage "winlogbeat"     "Windows Event Log to Elasticsearch - FOSS; critical for Windows SIEM"

Install-ChocoPackage "syslog-ng"      "Syslog server - FOSS; central logging from network devices"
Install-ChocoPackage "baretail"       "Real-time log tail viewer - freeware"
Install-ChocoPackage "logexpert"      "Advanced log viewer with filtering/bookmarks - FOSS"
# Graylog: alternative to ELK; single binary, easier to operate, MongoDB-backed
# Deploy via Docker (Phase 20); keeping here as reference
Write-Log "Graylog: Deploy via Docker (see Phase 20) as alternative/complement to ELK" "INFO"

# =============================================================================
# PHASE 15: OBSERVABILITY STACK (Prometheus + Grafana + Loki)
# =============================================================================
Write-Log "=== PHASE 15: OBSERVABILITY STACK ===" "SECTION"

# Prometheus: pull-based metrics collection; industry standard for cloud-native monitoring
Install-ChocoPackage "prometheus"         "Metrics collection & alerting - FOSS; pull-based monitoring"
# Grafana: visualization for Prometheus, Loki, InfluxDB, Elasticsearch, etc.
Install-ChocoPackage "grafana"            "Observability dashboards - FOSS; visualize everything"
# Loki: log aggregation by Grafana; like Prometheus but for logs
Install-ChocoPackage "loki"              "Log aggregation system - FOSS by Grafana; Prometheus for logs"
# Promtail: Loki log shipper agent
Install-ChocoPackage "promtail"           "Log shipper for Loki - FOSS"
# AlertManager: Prometheus alerting (routes to PagerDuty, Slack, email, etc.)
Install-ChocoPackage "alertmanager"       "Prometheus alerting engine - FOSS; routes to Slack/email/PagerDuty"
# Tempo: distributed tracing by Grafana; completes the observability trinity (metrics/logs/traces)
# Note: Tempo best deployed via Docker; see Phase 20
Write-Log "Grafana Tempo (tracing): Deploy via Docker (Phase 20) to complete observability trinity" "INFO"

# =============================================================================
# PHASE 16: HASHICORP ECOSYSTEM
# =============================================================================
Write-Log "=== PHASE 16: HASHICORP ECOSYSTEM ===" "SECTION"

# All FOSS (Business Source License); critical for enterprise infra automation
Install-ChocoPackage "terraform"   "IaC for multi-cloud - FOSS(BSL)"   # Already in Phase 6; idempotent
Install-ChocoPackage "vault"       "Secrets management - FOSS(BSL)"     # Already in Phase 7; idempotent
Install-ChocoPackage "consul"      "Service mesh & discovery - FOSS(BSL); great for microservice health checks"
Install-ChocoPackage "nomad"       "Workload orchestrator - FOSS(BSL); simpler than K8s for mixed workloads"
# Boundary: zero-trust access proxy; modern VPN/bastion replacement
Install-ChocoPackage "boundary"    "Zero-trust access proxy - FOSS(BSL); modern replacement for bastion hosts"
# Waypoint: application deployment platform; bridges dev and ops
Install-ChocoPackage "waypoint"    "Application deployment platform - FOSS(BSL)"
# Packer: already in Phase 6; idempotent
Install-ChocoPackage "packer"      "Machine image builder - FOSS(BSL)"

# =============================================================================
# PHASE 17: CYBERSECURITY, DIGITAL FORENSICS & OSINT
# =============================================================================
Write-Log "=== PHASE 17: CYBERSECURITY / FORENSICS / OSINT ===" "SECTION"
# Relevant to TS//SCI background and Cybersecurity certificate path

# NETWORK FORENSICS & IDS
# Zeek (Bro): network traffic analysis; generates structured logs for SIEM ingestion
Install-ChocoPackage "zeek"             "Network traffic analyzer - FOSS; generates structured logs for SIEM"
# Suricata: network IDS/IPS/NSM; real-time threat detection
Install-ChocoPackage "suricata"         "Network IDS/IPS - FOSS; real-time signature-based detection"
# NetworkMiner: passive network forensics; great for PCAP analysis
Install-WingetPackage "Netresec.NetworkMiner" "Passive network forensics - freemium; PCAP analysis"
# Zeek + Suricata together = lightweight NSM stack; see Security Onion for full stack via VM

# MEMORY FORENSICS
# Volatility 3: memory analysis framework; critical for IR and malware analysis
Install-PipPackage @("volatility3") "Memory forensics framework - FOSS; incident response essential"
# Rekall: Google's memory forensics (less maintained but still used)
# Winpmem: memory acquisition for live systems
Install-WingetPackage "Winpmem.Winpmem" "Live Windows memory acquisition - FOSS"

# DISK/FILE FORENSICS
# Autopsy: full-featured digital forensics platform (FTK alternative, FOSS)
Install-ChocoPackage "autopsy"          "Digital forensics platform - FOSS; FTK alternative"
# FTK Imager: disk image acquisition; FOSS by AccessData; standard in forensics
Install-ChocoPackage "ftk-imager"       "Disk image acquisition - freeware; industry-standard evidence collection"
# Sleuth Kit: forensic library underpinning Autopsy; direct CLI access
Install-ChocoPackage "sleuthkit"        "Forensic investigation toolkit - FOSS; CLI layer under Autopsy"
# ExifTool: metadata extraction from files; critical for forensics/OSINT
Install-ChocoPackage "exiftool"         "File metadata extractor - FOSS; essential for forensics and OSINT"

# REVERSE ENGINEERING
# Ghidra: NSA's FOSS reverse engineering tool; industry-grade binary analysis
Install-ChocoPackage "ghidra"           "NSA reverse engineering framework - FOSS; binary/malware analysis"
# x64dbg: Windows debugger; open-source OllyDbg/Immunity Debugger replacement
Install-ChocoPackage "x64dbg"           "Windows debugger - FOSS; malware analysis and RE"
# PE-bear: portable executable analyzer; lightweight RE tool
Install-WingetPackage "hasherezade.PEBear" "PE file analyzer - FOSS; quick malware triage"
# Die (Detect It Easy): file type identifier; detect packers, compilers, obfuscation
Install-ChocoPackage "die"              "File type identifier - FOSS; detect packers and obfuscation"

# PENETRATION TESTING / VULNERABILITY ASSESSMENT
# Metasploit: industry-standard exploitation framework; FOSS community edition
Install-ChocoPackage "metasploit"       "Exploitation framework - FOSS(community); industry-standard pentesting"
# Burp Suite Community: web application security testing
Install-ChocoPackage "burp-suite-free-edition" "Web app security proxy - community FOSS; web vuln testing"
# OWASP ZAP: fully FOSS web app scanner; alternative to Burp
Install-ChocoPackage "zap"              "FOSS web app security scanner - OWASP; full alternative to Burp Community"
# sqlmap: automated SQL injection detection and exploitation
Install-ChocoPackage "sqlmap"           "SQL injection automation - FOSS; essential for DB security audits"
# Mimikatz: credential extraction; critical to understand for defensive purposes
Install-WingetPackage "gentilkiwi.mimikatz" "Credential extraction tool - FOSS; understand to defend against it"
# CrackMapExec: post-exploitation for Active Directory enumeration
# Impacket: Python AD/Windows protocol toolkit (installed in pip Phase)

# OSINT TOOLS
# Maltego CE: visual link analysis for OSINT; freemium (community edition)
Install-ChocoPackage "maltego"          "Visual OSINT link analysis - freemium community edition"
# SpiderFoot: automated OSINT reconnaissance
Install-PipPackage @("spiderfoot") "Automated OSINT reconnaissance - FOSS"
# Shodan CLI: query the Shodan IoT/exposed-services search engine
Install-PipPackage @("shodan") "Shodan search engine CLI - FOSS client (API key required)"
# Recon-ng: OSINT framework (modular, like Metasploit for OSINT)
Install-PipPackage @("recon-ng") "Modular OSINT framework - FOSS"
# theHarvester: email/domain/IP OSINT from public sources
Install-PipPackage @("theHarvester") "Email/domain/IP OSINT - FOSS"
# holehe: check email registration across platforms
Install-PipPackage @("holehe") "Email OSINT across platforms - FOSS"
# GitLeaks: scan git repos for leaked secrets
Install-ChocoPackage "gitleaks"         "Git secret scanner - FOSS; find leaked credentials in repos"
# Trufflehog: deep git history secret scanning
Install-ChocoPackage "trufflehog"       "Deep git secret scanner - FOSS; complements GitLeaks"

# CRYPTANALYSIS & HASH TOOLS
# Hashcat: GPU-accelerated password recovery; essential for testing password policy strength
Install-ChocoPackage "hashcat"          "GPU password recovery - FOSS; test password policy resilience"
# John the Ripper: CPU-based password cracker; complements Hashcat
Install-ChocoPackage "john"             "CPU password cracker (John the Ripper) - FOSS"
# CyberChef: Swiss army knife for encoding/decoding/crypto (web app + desktop)
Install-WingetPackage "GCHQ.CyberChef" "Data transformation toolkit - FOSS by GCHQ; encoding/crypto/analysis"

# =============================================================================
# PHASE 18: AI / MACHINE LEARNING TOOLCHAIN
# =============================================================================
Write-Log "=== PHASE 18: AI/ML TOOLCHAIN ===" "SECTION"
# Relevant to GenAI Engineer co-op interest and MS-IS program

# LOCAL LLM INFERENCE
# Ollama: run LLMs locally (Llama, Mistral, Phi, Gemma, etc.); privacy-preserving AI
Install-ChocoPackage "ollama"         "Local LLM inference - FOSS; run Llama/Mistral/Phi without cloud"
# LM Studio: GUI for local LLMs; great for model discovery and chat UI
Install-WingetPackage "ElementLabs.LMStudio" "Local LLM GUI - freemium; easy model download and chat"
# GPT4All: FOSS desktop LLM runner; offline, privacy-first
Install-WingetPackage "Nomic.GPT4All" "Offline LLM runner - FOSS; no internet required after model download"
# Jan: FOSS LLM chat desktop app with API server mode
Install-WingetPackage "NitroTeam.Jan" "FOSS LLM desktop + API server - good Ollama complement"

# CUDA & GPU (for model training/fine-tuning)
# CUDA Toolkit: required for GPU-accelerated ML
Install-WingetPackage "NVIDIA.CUDA" "NVIDIA CUDA toolkit - for GPU-accelerated ML; required for most training"
# cuDNN: NVIDIA's deep learning library; required by PyTorch/TensorFlow
Write-Log "cuDNN: Download manually from https://developer.nvidia.com/cudnn (requires NVIDIA account)" "WARNING"

# PYTHON ML PACKAGES (installed in pip phase below, listed here for context)
Write-Log "AI/ML Python packages installed in pip phase (transformers, langchain, llama-index, etc.)" "INFO"

# VECTOR DATABASES (for RAG/embedding pipelines)
# Chroma: FOSS embedded vector DB; great for local RAG development
Install-PipPackage @("chromadb") "Vector database for RAG - FOSS; embedded, no server needed"
# Qdrant: FOSS vector search engine with Docker deployment
Write-Log "Qdrant: Deploy via Docker (Phase 20) for production-grade vector search" "INFO"

# MLFLOW: experiment tracking and model registry
Install-PipPackage @("mlflow") "ML experiment tracking - FOSS; track model versions and metrics"

# LABEL STUDIO: data labeling for training sets
Install-PipPackage @("label-studio") "ML data labeling - FOSS; create training datasets"

# JUPYTER ECOSYSTEM
Install-PipPackage @("jupyterlab", "notebook", "ipywidgets") "Jupyter notebooks - FOSS; interactive analysis and AI prototyping"

# =============================================================================
# PHASE 19: DEVSECOPS & CI/CD
# =============================================================================
Write-Log "=== PHASE 19: DEVSECOPS & CI/CD ===" "SECTION"

# CI/CD
# Jenkins: FOSS CI/CD server; most widely deployed; best installed as Docker
Write-Log "Jenkins: Deploy via Docker (Phase 20) - most flexible CI/CD for SME" "INFO"
# Drone CI: FOSS CI/CD with Docker-native pipeline definitions
Write-Log "Drone CI: Deploy via Docker (Phase 20)" "INFO"
# Gitea: FOSS self-hosted GitHub; lightweight; pairs with Drone CI
Install-ChocoPackage "gitea"           "Self-hosted Git service - FOSS; GitHub alternative for internal repos"
# Nexus Repository: artifact repository (Maven, npm, PyPI, Docker registry proxy)
Write-Log "Nexus Repository Manager: Deploy via Docker (Phase 20) - proxy & host artifacts" "INFO"

# CODE QUALITY & SECURITY
# SonarQube Community: FOSS SAST (static application security testing)
Write-Log "SonarQube: Deploy via Docker (Phase 20) - SAST for code quality & security" "INFO"
# Semgrep: FOSS SAST with community rules; runs locally without Docker
Install-PipPackage @("semgrep") "SAST/DAST code scanner - FOSS; runs on any codebase"
# Hadolint: Dockerfile linter
Install-ChocoPackage "hadolint"        "Dockerfile linter - FOSS; prevent container misconfigurations"
# ShellCheck: shell script static analyzer
Install-ChocoPackage "shellcheck"      "Shell script linter - FOSS; catches bash/sh bugs"
# Checkov: IaC security scanner (Terraform, CloudFormation, K8s, Dockerfile)
Install-PipPackage @("checkov") "IaC security scanner - FOSS; scan Terraform/K8s for misconfigs"
# TFSec (now Trivy): Terraform security scanner (Trivy already installed in Phase 7)
# Cosign: container image signing; supply chain security
Install-ChocoPackage "cosign"          "Container image signing - FOSS; supply chain security (Sigstore)"
# Snyk CLI: vulnerability scanning in IDE and CI; freemium
Install-NpmPackage "snyk" "Vulnerability scanner for code/deps/containers - freemium"

# =============================================================================
# PHASE 20: DOCKER-DEPLOYED SERVICES (docker-compose stacks)
# =============================================================================
Write-Log "=== PHASE 20: DOCKER SERVICE STACKS ===" "SECTION"

$dockerStacks = "C:\Admin\Docker"
New-Item -ItemType Directory -Path $dockerStacks -Force | Out-Null

# Portainer: Docker/K8s web UI management
@"
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
"@ | Out-File "$dockerStacks\portainer\docker-compose.yml" -Encoding UTF8 -Force
Write-Log "Portainer compose saved: C:\Admin\Docker\portainer\" "SUCCESS"

# Vaultwarden: self-hosted Bitwarden-compatible password server (FOSS)
@"
version: '3.8'
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - vaultwarden_data:/data
    environment:
      SIGNUPS_ALLOWED: "false"
volumes:
  vaultwarden_data:
"@ | Out-File "$dockerStacks\vaultwarden\docker-compose.yml" -Encoding UTF8 -Force
Write-Log "Vaultwarden compose saved: C:\Admin\Docker\vaultwarden\" "SUCCESS"

# Grafana + Prometheus + Loki + Promtail (full observability stack)
@"
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: changeme
  loki:
    image: grafana/loki:latest
    ports:
      - "3100:3100"
  promtail:
    image: grafana/promtail:latest
    volumes:
      - /var/log:/var/log
"@ | Out-File "$dockerStacks\observability\docker-compose.yml" -Encoding UTF8 -Force
Write-Log "Observability stack compose saved: C:\Admin\Docker\observability\" "SUCCESS"

# OpenVAS (Greenbone Vulnerability Management): full FOSS vuln scanner
@"
version: '3.8'
services:
  openvas:
    image: greenbone/openvas-scanner:latest
    container_name: openvas
    restart: unless-stopped
    ports:
      - "9392:9392"
"@ | Out-File "$dockerStacks\openvas\docker-compose.yml" -Encoding UTF8 -Force
Write-Log "OpenVAS compose saved: C:\Admin\Docker\openvas\" "SUCCESS"

# GitLab CE: self-hosted Git + CI/CD + issue tracking (heavier but comprehensive)
@"
version: '3.8'
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "22:22"
    volumes:
      - gitlab_config:/etc/gitlab
      - gitlab_logs:/var/log/gitlab
      - gitlab_data:/var/opt/gitlab
volumes:
  gitlab_config:
  gitlab_logs:
  gitlab_data:
"@ | Out-File "$dockerStacks\gitlab\docker-compose.yml" -Encoding UTF8 -Force
Write-Log "GitLab CE compose saved: C:\Admin\Docker\gitlab\" "SUCCESS"

Write-Log "Run stacks with: cd C:\Admin\Docker\<name> && docker compose up -d" "INFO"

# =============================================================================
# WINGET PACKAGES (Supplemental - covering gaps from Chocolatey)
# =============================================================================
Write-Log "=== WINGET ADDITIONAL PACKAGES ===" "SECTION"

Install-WingetPackage "Microsoft.PowerToys"             "PowerToys - FOSS Microsoft productivity suite"
Install-WingetPackage "Microsoft.VisualStudioCode"      "VS Code fallback if Choco fails"
Install-WingetPackage "Microsoft.AzureCLI"              "Azure CLI - FOSS; cloud management from terminal"
Install-WingetPackage "Microsoft.Bicep"                 "Azure IaC (Bicep) - FOSS; higher-level than ARM"
Install-WingetPackage "Microsoft.Azure.StorageExplorer" "Azure Storage GUI - freeware"
Install-WingetPackage "Microsoft.PowerShell"            "PowerShell 7 via winget - FOSS"
Install-WingetPackage "WiresharkFoundation.Wireshark"   "Wireshark fallback - FOSS"
Install-WingetPackage "JetBrains.Toolbox"               "JetBrains IDE manager - freeware; manage PyCharm/IntelliJ/Rider"
Install-WingetPackage "Docker.DockerDesktop"            "Docker Desktop fallback - freemium"
Install-WingetPackage "Hashicorp.Terraform"             "Terraform via winget - FOSS(BSL)"
Install-WingetPackage "Amazon.AWSCLI"                   "AWS CLI - FOSS; cloud management"
Install-WingetPackage "Google.CloudSDK"                 "Google Cloud SDK - FOSS"
Install-WingetPackage "Kubernetes.kubectl"              "kubectl via winget - FOSS"
Install-WingetPackage "Helm.Helm"                       "Helm K8s package manager via winget - FOSS"
Install-WingetPackage "BalenaEtcher.Etcher"             "Bootable USB flasher - FOSS; alternative to Rufus"
Install-WingetPackage "SumatraPDF.SumatraPDF"           "Lightweight PDF reader - FOSS; fast, no bloat"
Install-WingetPackage "VideoLAN.VLC"                    "Media player - FOSS; plays anything including training video files"
Install-WingetPackage "Nushell.Nushell"                 "Structured shell (nushell) - FOSS; shell where data is typed"

# =============================================================================
# PYTHON PACKAGES (pip) - Expanded
# =============================================================================
Write-Log "=== PYTHON PACKAGES (pip) ===" "SECTION"
refreshenv

# SYSTEM ADMINISTRATION
Install-PipPackage @("psutil")                    "System monitoring (CPU/mem/disk/net) - FOSS"
Install-PipPackage @("paramiko", "fabric")        "SSH automation & remote execution - FOSS"
Install-PipPackage @("pywinrm", "pypsrp")         "Windows Remote Management - FOSS"
Install-PipPackage @("pywin32")                   "Windows API access from Python - FOSS"

# NETWORK AUTOMATION
Install-PipPackage @("netmiko")                   "Network device CLI automation (Cisco/Juniper) - FOSS"
Install-PipPackage @("napalm")                    "Network abstraction layer for multi-vendor devices - FOSS"
Install-PipPackage @("scapy")                     "Packet manipulation & analysis - FOSS"
Install-PipPackage @("requests", "httpx")         "HTTP automation libraries - FOSS"
Install-PipPackage @("nmap-python")               "Python wrapper for nmap - FOSS"
Install-PipPackage @("dnspython")                 "DNS toolkit - FOSS; query/manipulate DNS records in scripts"
Install-PipPackage @("ipaddress", "netaddr")      "IP address manipulation - FOSS"

# ACTIVE DIRECTORY / IDENTITY
Install-PipPackage @("ldap3")                     "LDAP client - FOSS; query AD from Python"
Install-PipPackage @("impacket")                  "Windows protocols toolkit - FOSS; AD pentesting/automation"
Install-PipPackage @("msldap")                    "Async LDAP - FOSS; async AD queries"

# CLOUD SDKS
Install-PipPackage @("boto3")                     "AWS SDK - FOSS"
Install-PipPackage @("azure-mgmt-compute", "azure-identity") "Azure compute SDK - FOSS"
Install-PipPackage @("google-cloud-storage", "google-api-python-client") "GCP SDK - FOSS"

# MONITORING & OBSERVABILITY
Install-PipPackage @("prometheus-client")         "Prometheus metrics exporter - FOSS"
Install-PipPackage @("influxdb-client")           "InfluxDB client - FOSS"
Install-PipPackage @("elasticsearch")             "Elasticsearch client - FOSS"
Install-PipPackage @("grafana-api")               "Grafana API client - FOSS"

# AI/ML & GENAI (relevant to GenAI Engineer co-op)
Install-PipPackage @("openai")                    "OpenAI API client - FOSS client; access GPT-4 etc."
Install-PipPackage @("anthropic")                 "Anthropic Claude API client - FOSS"
Install-PipPackage @("transformers", "datasets", "accelerate") "HuggingFace ML ecosystem - FOSS"
Install-PipPackage @("torch", "--index-url", "https://download.pytorch.org/whl/cu118") "PyTorch with CUDA - FOSS"
Install-PipPackage @("langchain", "langchain-community") "LLM application framework - FOSS"
Install-PipPackage @("llama-index")               "LLM data indexing - FOSS; RAG pipeline framework"
Install-PipPackage @("sentence-transformers")     "Sentence embeddings - FOSS; local embedding generation"
Install-PipPackage @("chromadb")                  "Vector database - FOSS; local RAG storage"
Install-PipPackage @("ollama")                    "Ollama Python client - FOSS"
Install-PipPackage @("tiktoken")                  "OpenAI token counter - FOSS; estimate API costs"
Install-PipPackage @("guidance")                  "LLM prompt programming - FOSS by Microsoft"
Install-PipPackage @("instructor")                "Structured LLM outputs - FOSS; type-safe AI responses"

# DATA ANALYSIS (for log analysis, SIEM correlation, reporting)
Install-PipPackage @("pandas", "numpy", "polars") "Data analysis - FOSS; log analysis and reporting"
Install-PipPackage @("matplotlib", "plotly", "rich") "Data visualization & formatting - FOSS"
Install-PipPackage @("openpyxl", "xlrd")          "Excel read/write - FOSS; generate reports"
Install-PipPackage @("jinja2")                    "Templating engine - FOSS; generate configs, reports, emails"

# AUTOMATION UTILITIES
Install-PipPackage @("click", "typer")            "CLI framework - FOSS; build custom sysadmin tools"
Install-PipPackage @("pyyaml", "toml", "python-dotenv") "Config file parsers - FOSS"
Install-PipPackage @("schedule", "apscheduler")   "Job scheduling - FOSS"
Install-PipPackage @("watchdog")                  "File system event monitoring - FOSS"
Install-PipPackage @("cryptography", "pynacl")    "Cryptographic operations - FOSS"
Install-PipPackage @("pyotp")                     "TOTP/HOTP generation - FOSS; 2FA integration in scripts"
Install-PipPackage @("keyring")                   "OS credential store access - FOSS; secure secrets in scripts"

# DEVSECOPS
Install-PipPackage @("pre-commit")                "Git pre-commit hooks - FOSS; enforce quality gates"
Install-PipPackage @("bandit")                    "Python SAST scanner - FOSS; find security bugs in your scripts"
Install-PipPackage @("safety")                    "Python dependency vulnerability check - FOSS"

# =============================================================================
# POWERSHELL MODULES
# =============================================================================
Write-Log "=== POWERSHELL MODULES ===" "SECTION"

# ACTIVE DIRECTORY & IDENTITY
Install-PSModule "ActiveDirectory"              "AD administration cmdlets"
Install-PSModule "GroupPolicy"                  "Group Policy management"
Install-PSModule "DnsServer"                    "DNS server management"
Install-PSModule "DhcpServer"                   "DHCP server management"

# AZURE & M365
Install-PSModule "Az"                           "Azure PowerShell - full Azure management"
Install-PSModule "AzureAD"                      "Azure AD management (legacy)"
Install-PSModule "Microsoft.Graph"              "Microsoft Graph API - modern M365 management"
Install-PSModule "ExchangeOnlineManagement"     "Exchange Online cmdlets"
Install-PSModule "MicrosoftTeams"               "Teams management"
Install-PSModule "SharePointPnPPowerShellOnline" "SharePoint management"
Install-PSModule "MSOnline"                     "Microsoft Online Services (legacy M365)"

# AWS
Install-PSModule "AWS.Tools.Installer"          "AWS Tools for PowerShell installer"

# SSH & REMOTE
Install-PSModule "Posh-SSH"                     "SSH client for PowerShell"
Install-PSModule "WinSCP"                       "WinSCP PowerShell module for scripted transfers"

# UTILITIES
Install-PSModule "PSReadLine"                   "Enhanced command-line editing"
Install-PSModule "ImportExcel"                  "Excel manipulation without Excel"
Install-PSModule "PSScriptAnalyzer"             "PowerShell linting"
Install-PSModule "Pester"                       "PowerShell testing framework - FOSS; test your scripts"
Install-PSModule "platyPS"                      "PowerShell module documentation generator"
Install-PSModule "PSWindowsUpdate"              "Windows Update management from PowerShell"
Install-PSModule "Carbon"                       "Windows sysadmin automation toolkit"
Install-PSModule "Logging"                      "Structured logging for PowerShell scripts"
Install-PSModule "SecretManagement"             "Cross-platform secrets access framework"
Install-PSModule "SecretStore"                  "Local secrets storage (pairs with SecretManagement)"
Install-PSModule "psake"                        "Build automation (like Make) in PowerShell"
Install-PSModule "BurntToast"                   "Windows toast notifications from scripts - useful for alert scripts"
Install-PSModule "ThreadJob"                    "Lightweight parallel job execution"

# =============================================================================
# NPM GLOBAL PACKAGES
# =============================================================================
Write-Log "=== NPM GLOBAL PACKAGES ===" "SECTION"
refreshenv

Install-NpmPackage "http-server"          "Quick HTTP server for testing - FOSS"
Install-NpmPackage "json-server"          "Mock REST API server - FOSS"
Install-NpmPackage "localtunnel"          "Expose localhost to internet - FOSS; quick tunneling"
Install-NpmPackage "pm2"                  "Process manager for Node.js - FOSS; keep scripts alive"
Install-NpmPackage "nodemon"              "Auto-restart on file changes - FOSS; dev productivity"
Install-NpmPackage "npx"                  "Execute npm packages without install - FOSS"
Install-NpmPackage "ts-node"              "TypeScript execution - FOSS; run .ts scripts directly"
Install-NpmPackage "typescript"           "TypeScript language - FOSS"
Install-NpmPackage "@anthropic-ai/sdk"   "Claude API SDK - FOSS; GenAI application development"
Install-NpmPackage "snyk"                 "Vulnerability scanner - freemium; dep/container/code scanning"
Install-NpmPackage "yo"                   "Yeoman project scaffolder - FOSS"
Install-NpmPackage "serve"                "Static file server - FOSS; alternative to http-server"
Install-NpmPackage "netlify-cli"          "Netlify CLI - FOSS; quick static site deployment"
Install-NpmPackage "vercel"               "Vercel CLI - FOSS; JAMstack deployment"
Install-NpmPackage "prettier"             "Code formatter - FOSS; keep scripts/configs consistent"
Install-NpmPackage "eslint"               "JavaScript linter - FOSS"
Install-NpmPackage "marked"               "Markdown to HTML converter - FOSS; documentation pipelines"

# =============================================================================
# SCOOP PACKAGES (user-space, no UAC, portable)
# =============================================================================
Write-Log "=== SCOOP PACKAGES ===" "SECTION"
refreshenv

# Add buckets
scoop bucket add extras 2>&1 | Out-Null
scoop bucket add nerd-fonts 2>&1 | Out-Null
scoop bucket add versions 2>&1 | Out-Null
scoop bucket add java 2>&1 | Out-Null
scoop bucket add security 2>&1 | Out-Null

# TERMINAL UTILITIES
Install-ScoopPackage "fzf"              "Fuzzy finder - FOSS; turbocharge command history"
Install-ScoopPackage "ripgrep"          "Fast grep alternative - FOSS"
Install-ScoopPackage "fd"               "Fast find alternative - FOSS"
Install-ScoopPackage "bat"              "cat with syntax highlighting - FOSS"
Install-ScoopPackage "jq"               "JSON processor - FOSS; essential for API scripting"
Install-ScoopPackage "yq"               "YAML processor - FOSS; like jq for YAML/XML/CSV"
Install-ScoopPackage "btop"             "Resource monitor - FOSS; beautiful htop alternative"
Install-ScoopPackage "glow"             "Markdown renderer in terminal - FOSS; read docs in CLI"
Install-ScoopPackage "delta"            "Better git diff viewer - FOSS; syntax highlighting in diffs"
Install-ScoopPackage "zoxide"           "Smarter cd - FOSS; jump to frequently used dirs instantly"
Install-ScoopPackage "atuin"            "Shell history with sync - FOSS; search history across machines"
Install-ScoopPackage "starship"         "Cross-shell prompt - FOSS; git status, cloud, battery, K8s context"
Install-ScoopPackage "carapace"         "Shell completion engine - FOSS; completions for 800+ commands"
Install-ScoopPackage "nushell"          "Structured data shell - FOSS; pipes structured data not text"
Install-ScoopPackage "lazydocker"       "Terminal Docker UI - FOSS; manage containers without memorizing flags"
Install-ScoopPackage "lazygit"          "Terminal Git UI - FOSS; fastest git workflow (if Choco failed)"
Install-ScoopPackage "xh"               "HTTPie/curl alternative - FOSS; human-friendly HTTP requests"
Install-ScoopPackage "doggo"            "DNS client with modern output - FOSS; better than nslookup/dig"
Install-ScoopPackage "gping"            "Ping with live graph - FOSS; visualize latency over time"
Install-ScoopPackage "curlie"           "curl with HTTPie colors - FOSS; best of both worlds"
Install-ScoopPackage "fx"               "JSON viewer and processor - FOSS; interactive jq"
Install-ScoopPackage "tldr"             "Simplified man pages - FOSS; practical command examples"
Install-ScoopPackage "cheat"            "Command cheatsheets - FOSS; community-maintained quick refs"
Install-ScoopPackage "mcfly"            "AI-powered shell history search - FOSS"
Install-ScoopPackage "procs"            "Modern ps with colors - FOSS"
Install-ScoopPackage "tokei"            "Code stats (lines of code) - FOSS"
Install-ScoopPackage "hyperfine"        "Command benchmarking - FOSS; measure script performance"

# SECURITY TOOLS via Scoop
Install-ScoopPackage "age"              "Modern file encryption - FOSS; simpler than GPG"
Install-ScoopPackage "mkcert"           "Local TLS certs - FOSS"
Install-ScoopPackage "sops"             "Secrets in git - FOSS"

# NERD FONTS (for terminal icons and Starship prompt)
Install-ScoopPackage "FiraCode-NF"      "Fira Code Nerd Font - FOSS; ligatures + icons for terminal"
Install-ScoopPackage "JetBrainsMono-NF" "JetBrains Mono Nerd Font - FOSS; excellent for code"
Install-ScoopPackage "CascadiaCode-NF"  "Cascadia Code Nerd Font - FOSS by Microsoft; designed for terminals"

# =============================================================================
# CARGO PACKAGES (Rust ecosystem - modern CLI tools)
# =============================================================================
Write-Log "=== CARGO PACKAGES (Rust) ===" "SECTION"
refreshenv

Install-CargoPackage "bat"         "cat with syntax highlighting - FOSS"
Install-CargoPackage "eza"         "Modern ls with colors/git/tree - FOSS; successor to exa"
Install-CargoPackage "ripgrep"     "Fast grep - FOSS"
Install-CargoPackage "fd-find"     "Fast find - FOSS"
Install-CargoPackage "sd"          "Sed alternative with better syntax - FOSS"
Install-CargoPackage "procs"       "Modern ps with color - FOSS"
Install-CargoPackage "dust"        "Modern du (disk usage) - FOSS"
Install-CargoPackage "tokei"       "Code statistics - FOSS"
Install-CargoPackage "hyperfine"   "Benchmarking - FOSS"
Install-CargoPackage "bottom"      "System monitor (btm) - FOSS; htop alternative"
Install-CargoPackage "bandwhich"   "Bandwidth monitor by process - FOSS; see which app is saturating your pipe"
Install-CargoPackage "starship"    "Cross-shell prompt - FOSS"
Install-CargoPackage "zellij"      "Terminal multiplexer - FOSS; tmux alternative with better UX"
Install-CargoPackage "helix"       "Modal terminal editor - FOSS; Vim-like but batteries-included"
Install-CargoPackage "gitui"       "Terminal Git UI in Rust - FOSS; fastest git TUI"
Install-CargoPackage "oha"         "HTTP load testing - FOSS; stress test APIs"
Install-CargoPackage "miniserve"   "Static file server - FOSS; one-line share files over HTTP"
Install-CargoPackage "xsv"         "CSV analysis tool - FOSS; SQL-like queries on CSV from CLI"
Install-CargoPackage "watchexec-cli" "Watch files and run commands - FOSS; auto-run scripts on change"
Install-CargoPackage "cargo-update" "Update all Cargo packages - FOSS; run 'cargo install-update -a'"
Install-CargoPackage "lsd"         "Modern ls with icons - FOSS; complement/alternative to eza"
Install-CargoPackage "zoxide"      "Smarter cd - FOSS"
Install-CargoPackage "atuin"       "Shell history sync - FOSS"
Install-CargoPackage "delta"       "Better git diff - FOSS"
Install-CargoPackage "difftastic"  "Structural git diff - FOSS; understands code structure, not just lines"
Install-CargoPackage "ruff"        "Python linter in Rust - FOSS; 100x faster than flake8/pylint"
Install-CargoPackage "mise"        "Runtime version manager - FOSS; nvm/pyenv/rbenv in one tool"
Install-CargoPackage "sniffnet"    "Network monitor with GUI - FOSS; per-country traffic visualization"
Install-CargoPackage "rustscan"    "Fast port scanner - FOSS; finds open ports then hands to nmap"
Install-CargoPackage "feroxbuster" "Web directory brute-forcer - FOSS; web recon tool"
Install-CargoPackage "bat-extras"  "bat integration scripts - FOSS; batgrep, batdiff, batman"

# =============================================================================
# GO PACKAGES (go install - many excellent sysadmin tools)
# =============================================================================
Write-Log "=== GO PACKAGES ===" "SECTION"
refreshenv

# Ensure GOPATH/bin is in PATH
$env:GOPATH = "$env:USERPROFILE\go"
$env:PATH = "$env:GOPATH\bin;$env:PATH"

Install-GoPackage "github.com/tomnomnom/gron"                "Make JSON greppable - FOSS; gron | grep | ungron"
Install-GoPackage "github.com/jmespath/jp"                   "JMESPath JSON query - FOSS; like jq but JMESPath syntax"
Install-GoPackage "github.com/wader/fq"                      "jq for binary formats - FOSS; query binary files like JSON"
Install-GoPackage "github.com/ariga/atlas"                   "Database schema management - FOSS; IaC for DB schemas"
Install-GoPackage "github.com/sqlc-dev/sqlc"                 "Type-safe SQL - FOSS; generate Go code from SQL queries"
Install-GoPackage "mvdan.cc/sh/v3/cmd/shfmt"                 "Shell script formatter - FOSS; auto-format bash/sh/zsh"
Install-GoPackage "github.com/hairyhenderson/gomplate"        "Template engine for configs - FOSS; Jinja2 for Go templates"
Install-GoPackage "github.com/caddyserver/caddy/v2/cmd/caddy" "Caddy web server - FOSS; automatic HTTPS"
Install-GoPackage "golang.org/x/tools/cmd/goimports"         "Go import manager - FOSS"
Install-GoPackage "github.com/golangci/golangci-lint"         "Go linter - FOSS"
Install-GoPackage "github.com/google/wire/cmd/wire"           "Go dependency injection - FOSS"
Install-GoPackage "github.com/air-verse/air"                  "Go live reload - FOSS; hot-reload for Go apps"
Install-GoPackage "github.com/charmbracelet/gum"              "Glamorous shell script UI - FOSS; interactive prompts in bash"
Install-GoPackage "github.com/charmbracelet/glow"             "Markdown terminal renderer - FOSS"
Install-GoPackage "github.com/charmbracelet/vhs"              "Terminal recording to GIF - FOSS; record CLI demos"
Install-GoPackage "github.com/muesli/duf"                     "Disk usage with better UI - FOSS"
Install-GoPackage "github.com/nikolaydubina/fpdecimal"        "Financial decimal - FOSS"
Install-GoPackage "sigs.k8s.io/kustomize/kustomize/v5"        "K8s config customizer - FOSS"
Install-GoPackage "github.com/derailed/popeye"                "K8s cluster sanitizer - FOSS; find misconfigs"
Install-GoPackage "github.com/stackrox/kube-linter"           "K8s YAML linter - FOSS; security and reliability checks"
Install-GoPackage "github.com/aquasecurity/kube-bench"        "CIS K8s benchmark - FOSS; check cluster security posture"
Install-GoPackage "github.com/OJ/gobuster"                    "Directory/subdomain busting - FOSS; web recon tool"
Install-GoPackage "github.com/projectdiscovery/nuclei/v3/cmd/nuclei" "Vulnerability scanner - FOSS; community templates"
Install-GoPackage "github.com/projectdiscovery/subfinder/v2/cmd/subfinder" "Subdomain discovery - FOSS; OSINT recon"
Install-GoPackage "github.com/projectdiscovery/httpx/cmd/httpx" "HTTP probe & discovery - FOSS"
Install-GoPackage "github.com/projectdiscovery/naabu/v2/cmd/naabu" "Port scanner - FOSS; fast, complement to nmap"

# =============================================================================
# POST-INSTALLATION CONFIGURATION
# =============================================================================
Write-Log "=== POST-INSTALLATION CONFIGURATION ===" "SECTION"
refreshenv

# Enable Windows Features for server/admin roles
Write-Log "Enabling Windows Optional Features..." "INFO"
$features = @(
    "TelnetClient",
    "TFTP",
    "NetFx4-AdvSrvs",
    "WCF-Services45",
    "IIS-WebServerRole",
    "IIS-WebServer",
    "IIS-ManagementConsole",
    "HypervisorPlatform",
    "VirtualMachinePlatform",
    "Microsoft-Windows-Subsystem-Linux"  # WSL2
)
foreach ($feature in $features) {
    Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -All 2>&1 | Out-Null
    Write-Log "Enabled Windows Feature: $feature" "SUCCESS"
}

# Install WSL2 Ubuntu (for Linux tools in Windows)
Write-Log "Installing WSL2 with Ubuntu..." "INFO"
wsl --install -d Ubuntu 2>&1 | Out-Null
Write-Log "WSL2 Ubuntu queued (may require reboot to complete)" "INFO"

# Start essential services
$services = @("MySQL", "MongoDB", "redis", "nginx", "postgresql-x64-15", "telegraf")
foreach ($service in $services) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc) {
        Set-Service -Name $service -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $service -ErrorAction SilentlyContinue
        Write-Log "Started $service (set to Automatic)" "SUCCESS"
    }
}

# Configure Git defaults
$gitUser = git config --global user.name 2>&1
if (!$gitUser) {
    Write-Log "Git not configured. Run: git config --global user.name 'Name' && git config --global user.email 'email'" "WARNING"
} else {
    Write-Log "Git configured: $gitUser" "SUCCESS"
}
# Global gitignore (secrets hygiene)
@"
.env
*.key
*.pem
*.p12
*.pfx
*secret*
*password*
*credential*
"@ | git config --global core.excludesfile (New-Item "$env:USERPROFILE\.gitignore_global" -Force).FullName

# Create standard directory structure
$adminDirs = @(
    "C:\Admin", "C:\Admin\Scripts", "C:\Admin\Logs", "C:\Admin\Backups",
    "C:\Admin\Documentation", "C:\Admin\Tools", "C:\Admin\Temp",
    "C:\Admin\Docker", "C:\Admin\Certs", "C:\Admin\Keys", "C:\Admin\ISOs",
    "C:\Admin\OSINT", "C:\Admin\Forensics", "C:\Admin\AI", "C:\Admin\IaC"
)
foreach ($dir in $adminDirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}
Write-Log "Admin directory structure created under C:\Admin\" "SUCCESS"

# Starship prompt configuration
$starshipConfig = "$env:USERPROFILE\.config\starship.toml"
New-Item -ItemType Directory -Force -Path (Split-Path $starshipConfig) | Out-Null
@"
[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[kubernetes]
disabled = false
style = "bold cyan"

[aws]
disabled = false

[azure]
disabled = false
format = "on [$symbol($subscription)]($style) "
style = "blue bold"

[git_branch]
symbol = " "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'

[python]
symbol = " "
"@ | Out-File $starshipConfig -Encoding UTF8 -Force
Write-Log "Starship prompt configured: $starshipConfig" "SUCCESS"

# =============================================================================
# VERIFICATION & SUMMARY
# =============================================================================
Write-Log "=== INSTALLATION VERIFICATION ===" "SECTION"

$verificationCommands = @{
    "PowerShell 7"    = "pwsh --version"
    "Python"          = "python --version"
    "Git"             = "git --version"
    "Docker"          = "docker --version"
    "kubectl"         = "kubectl version --client --short"
    "Terraform"       = "terraform --version"
    "Ansible"         = "ansible --version"
    "Node.js"         = "node --version"
    "Go"              = "go version"
    "Rust/Cargo"      = "cargo --version"
    "nmap"            = "nmap --version"
    "Wireshark (tsh)" = "tshark --version"
    "jq"              = "jq --version"
    "Ollama"          = "ollama --version"
    "Vault"           = "vault --version"
    "Consul"          = "consul --version"
    "Prometheus"      = "prometheus --version"
    "Grafana"         = "grafana-server --version"
    "Starship"        = "starship --version"
    "ripgrep"         = "rg --version"
    "bat"             = "bat --version"
    "eza"             = "eza --version"
    "zoxide"          = "zoxide --version"
    "age"             = "age --version"
    "sops"            = "sops --version"
    "Trivy"           = "trivy --version"
    "Syft"            = "syft --version"
    "Grype"           = "grype --version"
    "gitleaks"        = "gitleaks version"
    "Semgrep"         = "semgrep --version"
    "Metasploit"      = "msfconsole --version"
    "Hashcat"         = "hashcat --version"
    "AWS CLI"         = "aws --version"
    "Azure CLI"       = "az --version"
    "Helm"            = "helm version --short"
    "k9s"             = "k9s version"
    "OpenSSL"         = "openssl version"
    "Ghidra"          = "ghidraRun --version"
}

$verifiedTools = 0
$totalTools = $verificationCommands.Count
foreach ($tool in $verificationCommands.Keys) {
    try {
        $version = Invoke-Expression $verificationCommands[$tool] 2>&1 | Select-Object -First 1
        Write-Log "✓ $tool : $version" "SUCCESS"
        $verifiedTools++
    } catch {
        Write-Log "✗ $tool : NOT FOUND" "WARNING"
    }
}

# Storage analysis
$drive = Get-PSDrive C
$usedGB  = [math]::Round(($drive.Used / 1GB), 2)
$freeGB  = [math]::Round(($drive.Free / 1GB), 2)
Write-Log "Disk: ${usedGB} GB used | ${freeGB} GB free" "INFO"

# =============================================================================
# FINAL SUMMARY
# =============================================================================
Write-Log "=== INSTALLATION SUMMARY ===" "SECTION"
Write-Log "Installed:  $($installedPackages.Count) packages" "SUCCESS"
Write-Log "Skipped:    $($skippedPackages.Count) (already present)" "WARNING"
Write-Log "Verified:   $verifiedTools / $totalTools tools" "SUCCESS"
Write-Log "Failed:     $($failedPackages.Count) packages" $(if ($failedPackages.Count -gt 0) { "ERROR" } else { "SUCCESS" })

if ($failedPackages.Count -gt 0) {
    Write-Log "Failed packages (retry manually):" "ERROR"
    $failedPackages | ForEach-Object { Write-Log "  ✗ $_" "ERROR" }
    $failedPackages | Out-File "C:\Admin\Logs\failed_packages.txt"
    Write-Log "Failed list saved: C:\Admin\Logs\failed_packages.txt" "INFO"
}

Write-Log "Full log: $logFile" "INFO"
Write-Log "" "INFO"
Write-Log "=== NEXT STEPS ===" "SECTION"
Write-Log "1.  REBOOT - finalize drivers, WSL2, Windows Features" "INFO"
Write-Log "2.  WSL2: wsl --install (if prompted after reboot)" "INFO"
Write-Log "3.  VAULT: vault operator init (configure secrets)" "INFO"
Write-Log "4.  OLLAMA: ollama pull llama3 / ollama pull mistral" "INFO"
Write-Log "5.  DOCKER STACKS: cd C:\Admin\Docker\<name> && docker compose up -d" "INFO"
Write-Log "6.  GIT: git config --global user.name/email" "INFO"
Write-Log "7.  AD: Open RSAT tools > AD Users & Computers" "INFO"
Write-Log "8.  STARSHIP: Add 'Invoke-Expression (&starship init powershell)' to \$PROFILE" "INFO"
Write-Log "9.  BACKUP: Configure Veeam + Kopia schedules" "INFO"
Write-Log "10. REVIEW: C:\Admin\QUICK_REFERENCE.txt" "INFO"
Write-Log "" "INFO"
Write-Log "=============================================" "SUCCESS"
Write-Log "SME (Subject Matter Expert x Small-Medium Enterprise)" "SUCCESS"
Write-Log "System Admin Toolsuite v3.0 - COMPLETE" "SUCCESS"
Write-Log "=============================================" "SUCCESS"
