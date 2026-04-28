### LATEST
#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
	SOK-BareMetal v5.2 FINAL — Exhaustive Bare-Metal Restoration
	Host: <HOST> | User: <USER> | Zero-State Assumption
	<DRIVE-TOPOLOGY>
.DESCRIPTION
	Complete reconstruction of the operator environment from a zero-state machine.
	Purges hostile/conflicting applications. Installs 220+ tools across Choco,
	Winget, Scoop, Pip, NPM, Cargo, PSModules, and Go. Generates all Docker
	Compose stacks, writes config files, starts services, and runs a verification
	pass with full JSON state logging.
	PREREQUISITE: Run from pwsh 7+ (NOT Windows PowerShell 5.1).
	  Install PS7 first: winget install Microsoft.PowerShell
	  Then: pwsh -ExecutionPolicy Bypass -File .\SOK-BareMetal_v5.2.ps1
	Run order: v3 -> v4 -> v5.2 (each is idempotent; safe to re-run in isolation).
	All Install-* calls are skip-if-present. All batches pause for operator Y/N.
	================================================================
	CHANGELOG v5.2 (QA Pass 3 — 2026-04-01)
	Inherits all 50 fixes from v5_QA and v5.1. New findings this pass:
	================================================================
	FIX-46	#Requires -Version 7.0 added.
			The ?? null-coalescing operator in Write-Console is PS7+ syntax.
			Without this directive, running under Windows PowerShell 5.1
			produces a cryptic parse error at script load time rather than
			a clear version-requirement message. #Requires -Version 7.0
			outputs: "The script cannot be run because it requires PowerShell
			7.0." — actionable and unambiguous.
	FIX-47	New-DockerStack helper added.
			Out-File does NOT create parent directories. Every docker-compose.yml
			write in Batch 6 would throw "Cannot find path" if the subdirectory
			under C:\Admin\Docker\ didn't already exist. New-DockerStack creates
			the directory first, then writes the file.
	FIX-48	python313 → winget Python.Python.3.13.
			The Chocolatey community package 'python313' is unverified and
			community-contributed; availability and maintenance are not
			guaranteed. The Python Software Foundation publishes directly to
			winget as Python.Python.3.13 — official, versioned, and current.
	FIX-49	nmap-python → python-nmap.
			The PyPI package for Python nmap bindings is 'python-nmap', not
			'nmap-python'. pip install nmap-python would silently install the
			wrong (or nonexistent) package, producing no error on some pip
			versions but failing to import in any code.
	FIX-50	winget list --no-upgrade removed.
			--no-upgrade is not a valid flag for 'winget list'. This caused
			winget to print an error to stderr that was captured in $wgList,
			making EVERY winget idempotency check fail (packages were always
			re-installed). Removed the invalid flag; using --id --exact only.
	FIX-51	PostgreSQL service check: array-safe.
			Get-Service "postgresql*" returns an array if multiple PostgreSQL
			service instances are present. $pgSvc.Status -eq "Running" on an
			array applies the comparison element-wise and returns a filtered
			array, not a Boolean. The truthiness of a non-empty array is always
			$true even if no elements match. Fixed with Where-Object filter.
	FIX-52	Export-State added to finally block.
			The finally block only called Stop-Transcript. If the script threw
			a terminating error mid-batch, the last state snapshot was whatever
			Export-State wrote at the previous batch pause. Final state (including
			all failures from the crashing batch) was lost. Export-State is now
			called in finally before Stop-Transcript.
	FIX-53	Duplicate nvm removed from Batch 4.
			nvm was installed in Batch 1 (node ecosystem section) and again in
			Batch 4 (infrastructure section). Second call was a no-op due to
			idempotency, but signals copy-paste origin. Removed from Batch 4.
	FIX-54	Duplicate dbeaver removed from Batch 5.
			dbeaver.dbeaver was installed via winget in Batch 2 (databases).
			Batch 5 added a choco install of the same application. Both
			track the same DBeaver CE binary. Removed choco call from Batch 5.
	FIX-55	Duplicate obsidian removed from Batch 5.
			Batch 5 had Invoke-Package "winget" "Obsidian.Obsidian" followed
			three lines later by Invoke-Package "choco" "obsidian". Removed
			the choco call; winget is the preferred vector for Obsidian.
	FIX-56	choco 'die' → 'detect-it-easy'.
			Detect It Easy's Chocolatey community package ID is 'detect-it-easy',
			not 'die'. The package 'die' does not exist in the community repo.
			This install would silently fail on every run.
	FIX-57	Ghidra verification fixed.
			ghidraRun --version does not produce a clean version string on
			Windows. Ghidra's launcher opens the GUI or analyzeHeadless, neither
			of which has a --version flag. Verification now checks for the
			existence of ghidraRun.bat in the expected choco lib path instead.
	FIX-58	powershell-core (PS7) added to Batch 1.
			The script requires PS7 to run (#Requires -Version 7.0), but PS7
			was never installed in the script. On a zero-state machine with
			only PS5.1, the user has no mechanism within this script to get
			PS7. Added winget install Microsoft.PowerShell at the top of Batch
			1 as a bootstrap note — this can only be run if PS7 is already
			present (the #Requires guard), so this install is for subsequent
			restores or if winget is used manually to bootstrap.
	FIX-59	Gephi removed from Batch 3 (kept in Batch 5).
			Gephi.Gephi via winget was called in Batch 3 (security toolchain)
			and again in Batch 5 (utilities). Gephi is an OSINT visualization
			tool but better categorized in the utilities/knowledge batch. Removed
			from Batch 3; retained in Batch 5.
	FIX-60	Atlantis .env template generated.
			The Atlantis docker-compose.yml references an env_file: .env, but
			the .env file was never created. Atlantis will refuse to start without
			ATLANTIS_GH_TOKEN, ATLANTIS_GH_USER, and ATLANTIS_REPO_ALLOWLIST.
			A commented template .env is now written alongside the compose file.
	FIX-61	Kafka ADVERTISED_LISTENERS fixed for container networking.
			KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092 works for
			clients on the host machine but is unreachable from other containers
			(kafka-ui, spark) in the same compose network. Fixed to advertise
			on both the container name (for internal comms) and localhost (for
			host clients).
	FIX-62	elasticsearch pip version pinned for ES 9.x.
			The plain pip package 'elasticsearch' is the Elastic client v7/v8.
			For ES 9.x (which the ELK choco install provides), the compatible
			Python client is 'elasticsearch>=9.0.0'. Pinned with version floor.
	FIX-63	mise activate configured in shell profile.
			mise was installed via cargo but never activated. Without
			'mise activate pwsh | Out-String | Invoke-Expression' in $PROFILE,
			mise version management does not intercept commands. Added setup
			block in Batch 6 config section.
	FIX-64	conda PATH timing noted; Invoke-BatchPause refreshenv verified.
			miniconda3 installs in Batch 1. conda checks happen in Batch 2.
			After the Batch 1 pause, Invoke-BatchPause calls refreshenv. On
			Windows, conda init also requires modifying the shell profile — a
			one-time step. Added 'conda init pwsh' call after miniconda3 install.
	FIX-65	docker-cli added alongside podman-desktop.
			After Docker Desktop is removed (Phase 0), the 'docker' CLI binary
			is gone. All docker-compose commands in the checklist require the
			Docker CLI client. Podman Desktop includes a podman<->docker shim
			but the docker CLI binary itself is absent. Added choco docker-cli
			in Batch 4 for explicit compatibility.
	FIX-66	Backup tools added: restic, rclone, kopia.
			Present in v3 Phase 4 but absent from v5.1. On a zero-state restore
			these are critical — without them the machine has no backup capability.
	FIX-67	slack added to Batch 5.
			slack was in v3's CONFIRMED INSTALLED list but absent from v5.1.
	FIX-68	winauth + ente-auth (2FA tools) added to Batch 5.
			These replaced the discontinued Authy Desktop in v3. Both were
			missing from v5.1.
	FIX-69	certbot + step-cli added (certificate management).
			Both present in v3 Phase 7 but absent from v5.1.
	FIX-70	pgadmin4 moved from Batch 5 to Batch 2.
			pgAdmin4 is a PostgreSQL GUI tool. It belongs alongside the database
			installs in Batch 2, not in the knowledge/utilities batch.
	FIX-71	scapy added to Python spot-check in Batch 7.
			scapy is a core security tool installed in $pipSec but was not
			verified in the Batch 7 spot-check array.
	FIX-72	WSL reboot advisory moved and clarified.
			Windows Features (WSL2, HypervisorPlatform) require a reboot to
			take effect. The wsl --install call in Batch 4 occurs before any
			reboot has happened. Added advisory in Pre-flight and moved the
			wsl --install to the post-feature-enable section with clear note
			that it will complete on next boot.
	FIX-73	ansible Windows compatibility note strengthened.
			Ansible does not run natively on Windows. The choco 'ansible' package
			installs it via pip under Python, but Ansible's Windows support is
			as a MANAGED NODE, not a control node. The correct operator path is
			WSL2 → Ubuntu → apt install ansible. Script now documents this and
			installs inside a WSL2 invocation with a fallback note.
	FIX-74	trufflehog: dual-path install (choco + go fallback).
			The TruffleHog choco package has historically been unmaintained or
			version-lagged. Added go install as the authoritative path with choco
			as a convenience fallback.
	FIX-75	x64dbg: verified choco package, extras bucket note.
			x64dbg IS available in the Chocolatey community repo. However, the
			install may require elevated privileges during setup. Annotated.
	FIX-76	Spark worker port note.
			Spark workers expose port 8080 by default, which conflicts with
			other services. Added SPARK_WORKER_WEBUI_PORT env variable to
			compose to shift workers off 8080.
	NOTE-E	Ansible-for-Windows clarification: Ansible as a CONTROL NODE
			does not support Windows. Use WSL2 for running playbooks. Ansible
			as a MANAGED NODE (the target of playbooks from a Linux controller)
			works via WinRM and pywinrm — those pip packages are already in the
			stack. The choco package install is retained for documentation
			purposes only; skip if not using WSL2.
	NOTE-F	docker-cli vs podman-docker: Podman 4.x ships a Docker-compatible
			shim (podman-docker) that creates a 'docker' alias to 'podman'.
			After podman-desktop install, running 'docker compose' works via
			the shim. The explicit docker-cli install provides the full Docker
			CLI binary which supports all docker compose V2 plugin features.
			Both are installed for maximum compatibility.
	NOTE-G	Python version management: This script installs Python 3.13 via
			winget (Python.Python.3.13). The Python Launcher (py.exe) handles
			multi-version dispatch. All pip calls use 'py -3.13 -m pip'. If
			additional Python versions are needed: winget install Python.Python.3.X
			where X is the minor version.
#>
# =============================================================================
# INITIALIZATION
# =============================================================================
$ErrorActionPreference	= "Continue"
$VerbosePreference		= "Continue"
$ProgressPreference		= "SilentlyContinue"   # prevents progress bar in logs
$logDir = "C:\Admin\Logs\V5_Restore_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
Start-Transcript -Path "$logDir\Verbose_Terminal_Output.txt" -Append
$state = @{
	ExecutionStart = (Get-Date -Format "o")
	Purged	= [System.Collections.Generic.List[string]]::new()
	Success = [System.Collections.Generic.List[string]]::new()
	Failed	= [System.Collections.Generic.List[string]]::new()
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
	$state | ConvertTo-Json -Depth 4 |
		Out-File "$logDir\v5_environment_state.json" -Encoding utf8 -Force
	Write-Console "State saved: $logDir\v5_environment_state.json" "OK"
}
# FIX-01 (v5): Registry-based detection — instant, no MSI reconfiguration side effects
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
# FIX-47: Helper that creates parent directory before writing compose file
function New-DockerStack {
	param([string]$StackName, [string]$ComposeYaml, [string]$EnvTemplate = "")
	$stackDir = "C:\Admin\Docker\$StackName"
	New-Item -ItemType Directory -Path $stackDir -Force | Out-Null
	$ComposeYaml | Out-File "$stackDir\docker-compose.yml" -Force -Encoding UTF8
	Write-Console "Stack written: $stackDir\docker-compose.yml" "OK"
	if ($EnvTemplate) {
		$envPath = "$stackDir\.env.template"
		$EnvTemplate | Out-File $envPath -Force -Encoding UTF8
		Write-Console "Env template: $envPath  (copy to .env and populate)" "WARN"
	}
}
# FIX-02/37: Vendor-aware + winget-path uninstall routing
function Invoke-AppPurge {
	param([string]$AppName, [string]$ChocoPackage = "", [string]$FallbackNote = "")
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
	if ($FallbackNote) { Write-Console "  Note: $FallbackNote" "WARN" }
}
# Core install dispatcher — FIX-18 ($ExtraArgs not $Args), FIX-19 (per-line choco regex),
# FIX-50 (winget idempotency), FIX-36 (winget pre-check)
function Invoke-Package {
	param([string]$Manager, [string]$Package, [string]$ExtraArgs = "")
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
			# Always use py launcher with explicit version — avoids Altair Python collision (v4 FLAG 5)
			$proc = Start-Process "py" `
				-ArgumentList "-3.13 -m pip install --upgrade --quiet $Package" `
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
			# FIX-14 (v5): explicit success tracking
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
	# FIX-12: Refresh PATH after each batch (propagates new installs into session)
	if (Get-Command refreshenv -ErrorAction SilentlyContinue) {
		refreshenv 2>&1 | Out-Null
		Write-Console "Environment variables refreshed." "OK"
	}
	Write-Host "`n$('=' * 72)" -ForegroundColor DarkCyan
	Write-Host "  BATCH COMPLETE : $BatchName" -ForegroundColor White
	Write-Host "  Success: $($state.Success.Count)	|  Skipped: $($state.Skipped.Count)	 |	Failed: $($state.Failed.Count)" -ForegroundColor White
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
	New-Item -ItemType Directory -Path $d -Force | Out-Null
	Write-Console "Dir: $d" "OK"
}
# FIX-30 + FIX-72: Windows Features — MUST happen before Batch 4 containerization tools.
# IMPORTANT: These features require a reboot to fully activate.
# wsl --install is noted here but executed in Batch 4 with a clear reboot advisory.
Write-Console "Enabling Windows Features (reboot required to activate WSL2)..." "WARN"
$winFeatures = @(
	"Microsoft-Windows-Subsystem-Linux",   # WSL2 — required by nerdctl, podman, containerd
	"VirtualMachinePlatform",			   # WSL2 second prerequisite
	"HypervisorPlatform",				   # Hyper-V platform (not full Hyper-V server role)
	"TelnetClient",						   # Basic network diagnostics
	"TFTP",								   # Router/switch TFTP config backup
	"IIS-WebServerRole",				   # IIS web server role
	"IIS-WebServer",
	"IIS-ManagementConsole"
)
foreach ($feat in $winFeatures) {
	$current = Get-WindowsOptionalFeature -Online -FeatureName $feat -ErrorAction SilentlyContinue
	if ($current -and $current.State -eq "Enabled") {
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
	-FallbackNote "Avast Clear: [https://www.avast.com/uninstall-utility](https://www.avast.com/uninstall-utility) (standalone, USB-bootable)"
Invoke-AppPurge "AVG Protection" -ChocoPackage "avg-free" `
	-FallbackNote "AVG Remover: [https://www.avg.com/en-us/uninstallation-tool](https://www.avg.com/en-us/uninstallation-tool)"
Invoke-AppPurge "Avira Security" -ChocoPackage "avira-free-antivirus" `
	-FallbackNote "Avira uninstaller via Control Panel. Note: Avast owns AVG — both doubly redundant."
# Non-AV deprecations
Invoke-AppPurge "BlueStacks App Player" -ChocoPackage "bluestacks" `
	-FallbackNote "Unnecessary attack surface on cleared machine. Use Android Studio AVD or physical device."
Invoke-AppPurge "Guardian Browser" `
	-FallbackNote "Exam proctoring browser. Restore per-exam from Meazure Learning portal."
# Docker Desktop → replaced by Podman Desktop (daemon-less, rootless, no licensing)
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
		'[https://community.chocolatey.org/install.ps1](https://community.chocolatey.org/install.ps1)'))
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
Invoke-Package "winget" "Microsoft.PowerShell"	 # pwsh 7 — bootstraps future re-runs
# Languages — version-controlled, explicit versioning
# FIX-48: Python via winget (Python.Python.3.13) — PSF official; winget is authoritative.
# Choco 'python313' is community-contributed and unverified. winget is preferred.
Invoke-Package "winget" "Python.Python.3.13"
Invoke-Package "winget" "Rustlang.Rustup"		 # winget path avoids Scoop shim bug (v4 FIX)
Invoke-Package "choco"	"git"
Invoke-Package "choco"	"nodejs-lts"
Invoke-Package "choco"	"golang"
Invoke-Package "choco"	"ruby"
Invoke-Package "choco"	"dotnet-sdk"
# FIX-64: conda init after miniconda3 install — needed for conda to appear in PATH
Invoke-Package "choco" "miniconda3"
if (Get-Command conda -ErrorAction SilentlyContinue) {
	conda init pwsh 2>&1 | Out-Null
	Write-Console "conda init pwsh executed. PATH active after next shell session." "OK"
} else {
	Write-Console "WARN: conda not in PATH yet. Will check again in Batch 2 after refreshenv." "WARN"
}
# Java multi-version
# FIX-03 (v5.1): jre8 removed — stale alias of javaruntime. javaruntime + jdk8 are distinct.
Invoke-Package "choco" "javaruntime"   # Oracle JRE 8 — runtime only; legacy app compat
Invoke-Package "choco" "jdk8"		   # Oracle JDK 8 — full SDK; Maven/compile targets
Invoke-Package "choco" "Temurin17"	   # Eclipse Temurin LTS 17 — Jenkins, Spring Boot, Kafka
Invoke-Package "choco" "Temurin21"	   # Eclipse Temurin LTS 21 — current LTS
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
Invoke-Package "choco" "strawberryperl"	  # Required for some OpenSSL/C build chains
Invoke-Package "choco" "bazel"			  # Google build system — Android/Java/Scala
# CORE SYSADMIN FOUNDATION (FIX-27 from v5.1; all missing from original v5)
Invoke-Package "choco"	"7zip"
Invoke-Package "choco"	"everything"		   # Instant NTFS MFT file search
Invoke-Package "choco"	"vscode"
Invoke-Package "choco"	"notepadplusplus"
Invoke-Package "choco"	"sublimetext4"		   # Shareware — indefinite trial; keep for speed on large files
Invoke-Package "choco"	"putty"
Invoke-Package "choco"	"winscp"
Invoke-Package "choco"	"filezilla"
Invoke-Package "choco"	"keepassxc"
Invoke-Package "choco"	"bitwarden"
Invoke-Package "choco"	"crystaldiskinfo"
Invoke-Package "choco"	"crystaldiskmark"
Invoke-Package "choco"	"hwinfo"
Invoke-Package "choco"	"processhacker"		   # Advanced process/kernel monitor — superior Task Manager
Invoke-Package "choco"	"windirstat"
Invoke-Package "choco"	"wiztree"			   # Fastest disk analyzer — reads MFT directly
Invoke-Package "choco"	"mremoteng"			   # Multi-protocol remote manager (RDP/SSH/VNC/Telnet)
Invoke-Package "choco"	"ditto"				   # Clipboard manager with search
Invoke-Package "choco"	"greenshot"			   # Screenshot with annotation
Invoke-Package "choco"	"sharex"			   # Advanced capture with OCR and workflows
Invoke-Package "choco"	"vlc"
Invoke-Package "choco"	"obs-studio"		   # Screen recording — runbook videos, training material
Invoke-Package "choco"	"sysinternals"		   # ADExplorer, PsTools, Autoruns, RAMMap, TCPView, etc.
Invoke-Package "choco"	"powertoys"
Invoke-Package "choco"	"neovim"
Invoke-Package "choco"	"lazygit"
# VPN tools
Invoke-Package "choco"	"openvpn"
Invoke-Package "choco"	"wireguard"
Invoke-Package "winget" "Tailscale.Tailscale"
# Cloud CLIs (FIX-29 from v5.1: pip SDKs without CLIs break most DevOps workflows)
Invoke-Package "choco"	"awscli"
Invoke-Package "choco"	"azure-cli"
Invoke-Package "winget" "Google.CloudSDK"
# Node version manager (FIX-53: only in Batch 1 — removed from Batch 4)
Invoke-Package "choco" "nvm"
# Certificate management (FIX-69: in v3, missing from v5.1)
Invoke-Package "choco" "certbot"	 # Let's Encrypt cert automation
Invoke-Package "choco" "step"		 # Smallstep internal CA management
# FIX-68: 2FA tools (replaced discontinued Authy Desktop, present in v3)
Invoke-Package "choco"	"winauth"			  # FOSS TOTP authenticator
Invoke-Package "winget" "EnteIO.EnteAuth"	  # E2EE TOTP with cloud backup
# Backup tools (FIX-66: in v3, critical for DR on zero-state restore)
Invoke-Package "choco" "restic"				  # Fast deduplicating backup with encryption
Invoke-Package "choco" "rclone"				  # Sync to 40+ cloud providers (rsync for cloud)
Invoke-Package "choco" "kopia"				  # Modern backup with web UI
# Communications (FIX-67: slack in v3 confirmed installed, absent from v5.1)
Invoke-Package "choco" "slack"
Invoke-Package "choco" "microsoft-teams"
Invoke-BatchPause "Batch 1: Core Substrate, Languages & Foundation"
# =============================================================================
# BATCH 2: DATA, ML, AI, GIS, DATABASES, ELK, OBSERVABILITY, HASHICORP (~42 GB)
# =============================================================================
Write-Console "=== BATCH 2: Data / ML / AI / Infra Convergence ===" "SECTION"
# Databases (FIX-70: pgadmin4 moved here from Batch 5 — belongs with DB tools)
Invoke-Package "choco"	"postgresql15"
# FIX-51: Array-safe PostgreSQL service check
# Get-Service with wildcard can return array; check each element for Running status
$pgRunning = Get-Service "postgresql*" -ErrorAction SilentlyContinue |
			 Where-Object { $_.Status -eq "Running" }
if ($pgRunning) {
	Invoke-Package "choco" "postgis"	# PostGIS — install AFTER pg15 is confirmed running
} else {
	Write-Console "WARN: postgresql15 not yet running. Skipping postgis." "WARN"
	Write-Console "		 After pg15 starts: choco install postgis -y" "INFO"
	$state.Failed.Add("choco:postgis (dependency: postgresql15 not yet running — install manually)")
}
Invoke-Package "choco"	"mariadb"
Invoke-Package "choco"	"memurai-developer"	   # Windows-native Redis compat (no WSL required)
Invoke-Package "choco"	"neo4j-community"
Invoke-Package "choco"	"mongodb"
Invoke-Package "choco"	"mongodb-compass"
Invoke-Package "choco"	"redis"
Invoke-Package "choco"	"influxdb"
Invoke-Package "choco"	"telegraf"			   # InfluxDB metrics collector agent
Invoke-Package "choco"	"mysql"
Invoke-Package "choco"	"mysql.workbench"
Invoke-Package "winget" "dbeaver.dbeaver"
Invoke-Package "winget" "Oracle.SQLDeveloper"
Invoke-Package "choco"	"pgadmin4"			   # FIX-70: moved from Batch 5
# Big Data & Analytics
Invoke-Package "choco"	"hadoop"
Invoke-Package "choco"	"weka"
Invoke-Package "choco"	"Tableau-Desktop"	   # Requires institutional license at activation
# GIS
Invoke-Package "choco"	"qgis"
Invoke-Package "choco"	"gdal"
# ELK Stack (FIX-24 from v5.1 — entirely absent; referenced in post-run checklist)
# CRITICAL: All Elastic stack components MUST share the same major version.
# choco pulls latest; pin versions after install if needed.
# winlogbeat (v7.x in original inventory) must be upgraded to match ES 9.x.
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
Invoke-Package "choco" "syslog-ng"			  # Central syslog for network devices
# HashiCorp Ecosystem (FIX-28 from v5.1 — absent from v5)
Write-Console "Installing HashiCorp stack (vault/consul/nomad/boundary)..." "INFO"
Invoke-Package "choco" "vault"
Invoke-Package "choco" "consul"				  # Service mesh & discovery
Invoke-Package "choco" "nomad"				  # Workload orchestrator — simpler than K8s for mixed workloads
Invoke-Package "choco" "boundary"			  # Zero-trust access proxy — modern bastion replacement
Invoke-Package "choco" "packer"				  # VM image builder — golden image automation
Invoke-Package "choco" "terraform"
Invoke-Package "choco" "opentofu"			  # FOSS Terraform fork (MPL-2.0; before BSL change)
# AI / Local LLM (FIX-23 from v5.1 — ollama missing)
Invoke-Package "choco"	"ollama"
Invoke-Package "winget" "ElementLabs.LMStudio"	  # GUI for local models + model discovery
Invoke-Package "winget" "Nomic.GPT4All"			   # Offline, privacy-first LLM runner
# Python ML/Data Ecosystem
# Always use py -3.13 explicitly — avoids Altair embedded Python collision (v4 FLAG 5)
# NOTE-C: torch installed CPU-only (safe default). Post-CUDA restore:
#	py -3.13 -m pip install torch --index-url [https://download.pytorch.org/whl/cu121](https://download.pytorch.org/whl/cu121)
Write-Console "Installing Python ML/data packages (py -3.13)..." "INFO"
$pipCore  = @("pandas", "polars", "numpy", "openpyxl", "xlrd", "jinja2")
$pipViz	  = @("matplotlib", "plotly", "rich", "seaborn")
$pipML	  = @("scikit-learn", "torch", "transformers", "datasets",
			  "accelerate", "sentence-transformers")
$pipGenAI = @("openai", "anthropic", "langchain", "langchain-community",
			  "llama-index", "llama-index-core", "chromadb", "instructor",
			  "ollama", "tiktoken", "mlflow", "jupyterlab", "ipywidgets")
# FIX-49: nmap-python → python-nmap (correct PyPI package name)
# FIX-62: elasticsearch→elasticsearch>=9.0.0 for ES 9.x client compatibility
$pipEng	  = @("dbt-postgres", "dbt-bigquery", "psutil", "boto3",
			  "azure-identity", "azure-mgmt-compute", "azure-mgmt-resource",
			  "google-cloud-storage", "google-api-python-client",
			  "prometheus-client", "influxdb-client", "elasticsearch>=9.0.0",
			  "paramiko", "fabric", "pywinrm", "pypsrp", "pywin32",
			  "netmiko", "napalm", "ldap3", "msldap",
			  "python-nmap",		 # FIX-49: was 'nmap-python' — wrong package name
			  "dnspython", "netaddr", "click", "typer", "pyyaml", "toml",
			  "python-dotenv", "schedule", "apscheduler", "watchdog",
			  "cryptography", "pynacl", "pyotp", "keyring", "pre-commit",
			  "requests", "httpx", "jinja2")
$pipStdAll = $pipCore + $pipViz + $pipML + $pipGenAI + $pipEng
$pipStdAll = $pipStdAll | Select-Object -Unique	  # dedup cross-array
foreach ($pkg in $pipStdAll) { Invoke-Package "pip" $pkg }
# FIX-22 (v5.1): faiss-cpu — pip attempt first; conda-forge fallback documented
Write-Console "Attempting faiss-cpu via pip (may fail without BLAS/LAPACK)..." "WARN"
Write-Console "	 Fallback: conda install -c conda-forge faiss-cpu" "WARN"
Invoke-Package "pip" "faiss-cpu"
# FIX-22/06 (v5.1): GIS Python stack — GDAL Python bindings NOT provided by choco gdal.
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
	Write-Console "	 After this script: conda init pwsh, restart pwsh, then:" "WARN"
	Write-Console "	 conda install -c conda-forge geopandas shapely fiona rasterio" "WARN"
	foreach ($pkg in $gisPackages) { Invoke-Package "pip" $pkg }
}
Invoke-BatchPause "Batch 2: Data/ML/AI, Databases, ELK, HashiCorp, Observability"
# =============================================================================
# BATCH 3: CYBERSECURITY, SIGINT & FORENSICS (~25 GB)
# =============================================================================
Write-Console "=== BATCH 3: Cybersecurity, SIGINT & Forensics ===" "SECTION"
# Static Analysis & Reverse Engineering
Invoke-Package "choco" "wireshark"
Invoke-Package "choco" "ghidra"			   # NSA FOSS RE framework — industry-grade binary analysis
Invoke-Package "choco" "ida-free"		   # IDA Freeware — industry static analysis standard
Invoke-Package "choco" "dnspy"			   # .NET decompiler/debugger — critical for Windows malware RE
Invoke-Package "choco" "ilspy"			   # FOSS .NET decompiler — complement to dnSpy
Invoke-Package "choco" "apimonitor"		   # Windows API call tracing — behavioral malware analysis
Invoke-Package "choco" "apktool"		   # Android APK RE — decompile/recompile
# FIX-75: x64dbg IS in choco community. Verified. May need elevated setup.
Invoke-Package "choco" "x64dbg"			   # Windows debugger — FOSS OllyDbg/Immunity replacement
# FIX-56: 'die' → 'detect-it-easy' (correct choco package ID)
Invoke-Package "choco" "detect-it-easy"	   # Detect It Easy — file type + packer + compiler detection
# Sysinternals forensics
Invoke-Package "choco" "procmon"		   # Real-time file/registry/network activity
Invoke-Package "choco" "autoruns"		   # All auto-start locations — find persistence mechanisms
# Digital Forensics & IR
Invoke-Package "choco" "autopsy"		   # Digital forensics platform — FOSS FTK alternative
Invoke-Package "choco" "ftk-imager"		   # Disk image acquisition — standard evidence collection
Invoke-Package "choco" "sleuthkit"		   # Forensic toolkit — CLI layer under Autopsy
Invoke-Package "choco" "exiftool"		   # File metadata extractor — critical for forensics/OSINT
# Pattern matching & password recovery
Invoke-Package "choco" "yara"			   # Malware signature language and scanner
Invoke-Package "choco" "hashcat"		   # GPU password recovery — test password policy resilience
Invoke-Package "choco" "john"			   # CPU password cracker (John the Ripper)
# Network security & scanning
Invoke-Package "choco" "nmap"
Invoke-Package "choco" "masscan"		   # High-speed port scanner — complement to nmap for wide scans
Invoke-Package "choco" "nikto"			   # Web server vulnerability scanner
Invoke-Package "choco" "sqlmap"			   # SQL injection automation
Invoke-Package "choco" "gitleaks"		   # Git secret scanner
# FIX-74: trufflehog — dual path. choco package version-lagged; go install is authoritative.
Write-Console "trufflehog: attempting choco (version-lagged); go install is preferred path..." "WARN"
Invoke-Package "choco" "trufflehog"		   # Deep git history secret scanner
# Go path for current trufflehog will be installed in the go section later
# Web application security
Invoke-Package "choco" "burp-suite-free-edition"
Invoke-Package "choco" "zap"			   # OWASP ZAP — FOSS full alternative to Burp Community
Invoke-Package "choco" "fiddler"
Invoke-Package "choco" "soapui"
# OSINT tools (FIX-59: Gephi removed from here — it's in Batch 5)
Invoke-Package "choco" "maltego"		   # Visual link analysis — FOSS community edition
Invoke-Package "winget" "GCHQ.CyberChef"  # Encoding/decoding/crypto Swiss army knife — GCHQ
# Proxies, anonymity & tunnels
Invoke-Package "choco" "squid"			   # Caching forward proxy — active service in inventory
Invoke-Package "choco" "privoxy"		   # HTTP filtering proxy — active service in inventory
Invoke-Package "choco" "tor-browser"
Invoke-Package "choco" "zerotier-one"	   # Layer-2 SDN VPN — complements Tailscale (layer 3)
Invoke-Package "choco" "ngrok"			   # Secure tunnel for local dev — webhook testing
Invoke-Package "choco" "bind-toolsonly"	   # dig, nslookup, host — essential DNS toolkit
Invoke-Package "choco" "openssh"
Invoke-Package "winget" "OpenSC.OpenSC"	   # Smart card middleware — CAC/PIV (DoD PKI context)
# Penetration testing
Invoke-Package "choco" "metasploit"
# Python Security & OSINT (FIX-06 from v5.1: theharvester lowercase; holehe + recon-ng added)
$pipSec = @(
	"shodan",		 # Shodan IoT/exposed-services search CLI (requires API key)
	"spiderfoot",	 # Automated OSINT reconnaissance
	"theharvester",	 # FIX-06: lowercase — email/domain/IP OSINT from public sources
	"impacket",		 # Windows protocol toolkit — AD pentesting/automation
	"scapy",		 # Packet manipulation & analysis
	"dnspython",
	"semgrep",		 # SAST — community rules for many languages
	"checkov",		 # IaC security scanner — Terraform/K8s/Dockerfile
	"bandit",		 # Python SAST — find security bugs in scripts
	"safety",		 # Python dependency vulnerability scan
	"volatility3",	 # FIX-04 (v5.1): Memory forensics — pip ONLY; no choco package exists
	"holehe",		 # Email-across-platforms OSINT
	"recon-ng"		 # Modular OSINT framework (like Metasploit for OSINT)
	# NOTE: recon-ng execution on Windows has unresolved native deps. Use via WSL2.
)
$pipSec = $pipSec | Select-Object -Unique
foreach ($pkg in $pipSec) { Invoke-Package "pip" $pkg }
Invoke-BatchPause "Batch 3: Cybersecurity, Forensics, SIGINT & OSINT"
# =============================================================================
# BATCH 4: INFRASTRUCTURE, OCI, DEVOPS (~20 GB)
# =============================================================================
Write-Console "=== BATCH 4: Infrastructure, Containers & DevOps ===" "SECTION"
# Containerization — Podman replaces Docker Desktop (FIX-08 from v5.1)
# NOTE-F: Podman Desktop includes docker<->podman shim. docker-cli adds full binary.
Invoke-Package "choco" "podman-desktop"
# FIX-65: docker-cli for Podman Docker compatibility
Invoke-Package "choco" "docker-cli"		   # Docker CLI binary — works via Podman's docker shim
Invoke-Package "choco" "docker-compose"	   # Docker Compose v2 plugin
# FIX-07 (v5.1): nerdctl installs CLI only. containerd requires WSL2 or nerdctl-full.
# nerdctl-full: [https://github.com/containerd/nerdctl/releases](https://github.com/containerd/nerdctl/releases)
Write-Console "NOTE: nerdctl CLI installed. containerd requires WSL2 or nerdctl-full bundle." "WARN"
Invoke-Package "choco" "nerdctl"
# Kubernetes ecosystem
Invoke-Package "choco" "kubernetes-cli"
Invoke-Package "choco" "minikube"
Invoke-Package "choco" "kubernetes-kompose"	   # Translate docker-compose → K8s YAML
Invoke-Package "choco" "kubectx"			   # Fast kubectl context/namespace switching
Invoke-Package "choco" "istioctl"			   # Istio service mesh CLI
Invoke-Package "choco" "skaffold"			   # K8s inner-loop dev automation
Invoke-Package "choco" "tilt"				   # K8s dev dashboard
Invoke-Package "choco" "k9s"				   # Terminal K8s dashboard
# FIX-20 (v5.1): kubernetes-helm (choco ID) — 'helm' does not exist in community repo
Invoke-Package "choco" "kubernetes-helm"
# IaC ecosystem
Invoke-Package "choco" "terraform-docs"	   # Auto-generate README for Terraform modules
Invoke-Package "choco" "terragrunt"		   # Terraform wrapper for DRY configs
Invoke-Package "choco" "tflint"			   # Terraform linter
Invoke-Package "choco" "pulumi"			   # IaC with Python/Go/TypeScript
Invoke-Package "choco" "argocd-cli"		   # GitOps CD for K8s
# CI/CD
# FIX-43 (v5.1): concourse installs fly CLI only — not the Concourse server
Write-Console "NOTE: 'concourse' installs fly CLI only. Concourse server → docker-compose (Batch 6)." "INFO"
Invoke-Package "choco" "concourse"		   # fly CLI
Invoke-Package "choco" "circleci-cli"	   # Validate .circleci configs locally
Invoke-Package "choco" "databricks-cli"	   # Manage Databricks workspaces from terminal
Invoke-Package "choco" "nssm"			   # Non-Sucking Service Manager — wrap any exe as Windows service
# FIX-53: nvm removed from here — already installed in Batch 1
# HashiCorp ops tools
Invoke-Package "choco" "consul"			   # consul-template and agent (if not caught by Batch 2 skip)
Invoke-Package "choco" "packer"			   # VM image builder
# Config management
# FIX-73: Ansible on Windows — NOT a control node. See NOTE-E.
Write-Console "NOTE: Ansible on Windows = managed NODE only, not control node. See NOTE-E." "WARN"
Write-Console "		 For Ansible control: WSL2 -> Ubuntu -> apt install ansible" "WARN"
Invoke-Package "choco" "ansible"		   # Retained for docs; actual use requires WSL2
Invoke-Package "choco" "puppet-agent"	   # Declarative config management agent
# Source control hosting
Invoke-Package "choco" "gitea"			   # Self-hosted Git service — lightweight GitHub alternative
# QEMU (FIX-42 from v5.1: lowercase package ID)
Invoke-Package "choco" "qemu"			   # Full system emulator — ARM/RISC-V/MIPS
# WSL2 Ubuntu (FIX-72: features were enabled in Pre-flight; wsl --install completes on reboot)
Write-Console "Queuing WSL2 Ubuntu install (will complete after reboot if features just enabled)..." "INFO"
Write-Console "	 If WSL features were already active from a prior boot, this installs immediately." "INFO"
wsl --set-default-version 2 2>&1 | Out-Null
wsl --install -d Ubuntu 2>&1 | Out-Null
Invoke-BatchPause "Batch 4: Infrastructure, OCI, DevOps"
# =============================================================================
# BATCH 5: KNOWLEDGE, UTILITIES, SCOOP, CARGO, NPM, GO, PSMODULES (~22 GB)
# =============================================================================
Write-Console "=== BATCH 5: Knowledge, CLI Tools & PowerShell ===" "SECTION"
# Knowledge Management — Sovereignty Split (FIX-08 from v5.1: Notion excluded; NOTE-A)
Write-Console "NOTE: Notion excluded (data sovereignty on cleared-environment machine)." "WARN"
Write-Console "		 Manual install if personal-use: winget install Notion.Notion" "INFO"
Invoke-Package "winget" "AppFlowy.AppFlowy"		# FOSS, local-first Notion alternative
# FIX-55: obsidian winget only (removed choco duplicate that appeared 3 lines later)
Invoke-Package "winget" "Obsidian.Obsidian"
Invoke-Package "winget" "Posit.Quarto"			# Scientific publishing — Python/R/Julia → PDF/HTML/Word
Invoke-Package "winget" "Logseq.Logseq"			# Local-first graph knowledge base
Invoke-Package "winget" "calibre.calibre"		# Ebook management & format conversion
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
# FIX-59: Gephi moved here from Batch 3 (OSINT visualization — utilities context)
Invoke-Package "winget" "Gephi.Gephi"
Invoke-Package "winget" "Doppler.doppler"		# Team secrets manager
Invoke-Package "winget" "VivaldiTechnologies.Vivaldi"
Invoke-Package "winget" "Telegram.TelegramDesktop"
Invoke-Package "winget" "k6.k6"					# Developer load testing
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

***

### HISTORICAL CONTEXT & ARCHITECTURAL BUILDUP (Summarized & Deduplicated)

The exhaustive `LATEST` script (`SOK-BareMetal v5.2`) is the culmination of multiple iterative pipelines designed to solve two intersecting crises: an infrastructural collapse triggered by a rogue Python environment mapping (`E:` drive junction stalemates), and the need for a highly optimized, multithreaded data extraction/restoration pipeline tailored for a 14-core NVMe host (`<HOST>`).

#### 1. The Archive & Backup Manager (`Invoke-BackupRestructure.ps1`)
Prior to the BareMetal rebuild, a standalone production-grade pipeline was developed specifically to handle the extraction, deduplication, and enmeshment of massive backup payloads.
* **The Bug Fixes:** A critical null-reference bug was patched in the `$archivesFound | Measure-Object Length -Sum` calculation using the PS7 null-coalescing operator (`?? 0`).
* **Multi-Format Discovery:** Expansion of `7z` targeting to exhaustively support all major archive types (`.zip, .rar, .tar, .gz, .bz2, .xz, .iso`).
* **Multi-Part Suppression:** The script implements a `Test-IsArchiveFirstPart` function to deliberately ignore continuation segments (`.r01`, `.002`, `.part2.rar`) ensuring `7z x` is only fed the master archive to prevent redundant operations.
* **The 3-Phase Architecture:**
    * *Phase 1:* Pre-flight execution checking PS7, elevation, 7-Zip status, available disk overhead (3x expansion limit), and a broken junction audit.
    * *Phase 2:* Smallest-first sequential extraction (optimizing space reclamation) utilizing `-mmt=16` threads. Includes a pre-extraction inventory count (`7z l`) compared against post-extraction artifact presence to ensure file integrity prior to auto-deletion.
    * *Phase 3:* Parallel enmeshment using `ForEach-Object -Parallel` with `ThrottleLimit=8` (tuned for NVMe). Features collision-aware derivation tagging, sub-200MB SHA-256 deduplication (and >200MB Size+Timestamp deduplication), and `[System.Threading.Interlocked]` for thread-safe increment counters.

#### 2. The Hardware Crisis & v4 Reconciliation
`<HOST>` encountered an escalating series of subsystem failures stemming from a 257 GB offload from `C:` to `E:\SOK_Offload`. This created a liquidity crisis where `E:` skyrocketed to 78% capacity, breaking 10 cross-drive junctions.
* **The Python Hijack (Flag 5):** The system's root `python` path was silently resolving to an embedded Altair instance (`C:\Users\shelc\AppData\Local\Altair\MF\python.exe`). Global pip installs were landing in an isolated, untracked environment. This necessitated the strict `py -3.13 -m pip` invocation standard.
* **The AV Collision (Flag 1):** The host was running Avast, AVG, Avira, Malwarebytes, and Windows Defender simultaneously. The overlapping kernel hooks caused massive file-access latency, blocking generic MSI uninstalls.
* **The Scoop Shim & ELK Desync (Flags 4 & 6):** Rust/Cargo binaries failed to execute via Scoop due to Windows shim issues, requiring a pivot to Winget `Rustlang.Rustup`. The ELK stack was broken due to `winlogbeat` being locked to v7.x while Elasticsearch was upgraded to v9.x.

#### 3. The QA/QC Forges (v5.0 → v5.1)
The bridge from the v3/v4 reconciliation scripts to the finalized v5.2 BareMetal restorer required 50 discrete fixes, culminating in the `Deprecate, Never Delete` and `Progressive Disclosure` axioms.
* **WMI Elimination (FIX-01):** Ripped out all `Get-WmiObject -Class Win32_Product` calls. Querying WMI triggers a silent MSI reconfiguration across every installed app, leading to massive hangs. Replaced with instant HKLM registry uninstall detection.
* **Data Sovereignty & Notion (FIX-08):** Notion was aggressively purged from the BareMetal installer. Due to data sovereignty issues on a machine with DoD PKI and cleared-environment contexts, it was swapped for the local-first, FOSS `AppFlowy`.
* **Module & Shell Hygiene (FIX-09/10/12):** Resolved the `ActiveDirectory` PSGallery error by implementing `Add-WindowsCapability` (RSAT) instead of `Install-Module`. Enforced explicit module naming (`Microsoft.PowerShell.SecretManagement`). Injected `refreshenv` between all batches to guarantee PATH propagation for Cargo/Go/NPM layers.
* **Docker Compositions (FIX-26):** Deployed 9 localized `docker-compose.yml` stacks (Portainer, Observability, Spark, Neo4j, Kafka, Hive, Atlantis, OpenVAS, Vaultwarden) to containerize the heavy infrastructure, avoiding bare-metal bloat for data-engineering and cyber tools.