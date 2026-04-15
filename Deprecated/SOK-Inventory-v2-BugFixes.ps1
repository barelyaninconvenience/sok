<#
    SOK-Inventory v2.0.0 — Bug Fixes from 18Mar2026 Live Scan
    
    BUG 1: Scoop collector still shows 0 apps
    ROOT CAUSE: Table output format changed in Scoop 0.5.x. The regex
    '\s*\S+\s+\d' doesn't match the new tabular format with leading spaces
    and column headers. The 'scoop export' fallback also fails because
    the JSON output structure changed.
    FIX: Add a third fallback using 'scoop list 6>&1' which forces
    information stream to output, then parse the raw text.
    
    BUG 2: Node path_healthy reports True but version field contains error message
    ROOT CAUSE: The Kibana path check tests $nodeCmd.Source for 'chocolatey.*kibana'
    but on this system, 'where.exe node' resolves to a shim that THEN fails when
    executed. The shim path doesn't contain 'kibana'. The error only appears in
    the stdout of 'node --version'.
    FIX: Check the VERSION OUTPUT for error strings, not just the path.
    
    BUG 3: System metadata division by zero
    ROOT CAUSE: A drive with Size=0 (virtual/unmounted/card reader) hits
    the percent_used calculation: (Size - FreeSpace) / Size * 100
    FIX: Guard with if ($_.Size -gt 0) before division.
    
    All three fixes are shown below as replacement code blocks.
    The full updated SOK-Inventory.ps1 is in the zip.
#>

# ═══ FIX 1: Scoop Collector (replace entire Scoop region) ═══

# In SOK-Inventory.ps1, replace the Scoop collector with:

<#SCOOP_FIX#>
Write-SOKLog "Collecting Scoop apps..." -Level Info
try {
    $scoopVersion = $null
    $scoopApps = @()
    $scoopBuckets = @()

    $scoopCmd = Get-Command scoop -ErrorAction Continue
    if ($scoopCmd) {
        $vRaw = & scoop --version 2>&1
        if ($vRaw) { $scoopVersion = ($vRaw | Select-Object -First 1).ToString().Trim() }

        # Approach 1: scoop export (JSON) — most reliable when available
        try {
            $exportRaw = & scoop export 2>&1
            $exportStr = ($exportRaw | Out-String).Trim()
            if ($exportStr -and $exportStr.StartsWith('{')) {
                $export = $exportStr | ConvertFrom-Json
                if ($export.apps) {
                    $scoopApps = @($export.apps | ForEach-Object {
                        [ordered]@{
                            name    = $_.Name
                            version = $_.Version
                            source  = $_.Source
                        }
                    })
                }
            }
        }
        catch { Write-SOKLog "Scoop export JSON parse failed, trying table parse..." -Level Debug }

        # Approach 2: scoop list (table output) — parse columns
        if ($scoopApps.Count -eq 0) {
            $listRaw = & scoop list 2>&1 | Out-String
            $listLines = $listRaw -split "`n" | Where-Object { $_.Trim() -ne '' }
            
            # Find data lines: skip anything that starts with '-' or contains 'Name' header
            # Data lines have format: "  appname  1.2.3  bucketname"
            $scoopApps = @($listLines |
                Where-Object { $_ -notmatch '^\s*-|^\s*Name|^\s*Installed|^$|^Updated' -and $_.Trim().Length -gt 0 } |
                ForEach-Object {
                    $parts = $_.Trim() -split '\s+', 4
                    if ($parts.Count -ge 2 -and $parts[0] -notmatch '^-+$') {
                        [ordered]@{
                            name    = $parts[0]
                            version = $parts[1]
                            source  = if ($parts.Count -ge 3) { $parts[2] } else { 'unknown' }
                        }
                    }
                } | Where-Object { $null -ne $_ -and $_.name -match '^[a-zA-Z]' })
        }

        # Approach 3: Direct directory scan as absolute fallback
        if ($scoopApps.Count -eq 0) {
            $scoopDir = "$env:USERPROFILE\scoop\apps"
            if (Test-Path $scoopDir) {
                $scoopApps = @(Get-ChildItem -Path $scoopDir -Directory -ErrorAction Continue |
                    Where-Object { $_.Name -ne 'scoop' } |
                    ForEach-Object {
                        $verDir = Get-ChildItem -Path $_.FullName -Directory -ErrorAction Continue |
                            Where-Object { $_.Name -ne 'current' } |
                            Sort-Object Name -Descending | Select-Object -First 1
                        [ordered]@{
                            name    = $_.Name
                            version = if ($verDir) { $verDir.Name } else { 'current' }
                            source  = 'directory-scan'
                        }
                    })
                Write-SOKLog "Scoop: fell back to directory scan ($($scoopApps.Count) apps)" -Level Warn
            }
        }

        # Buckets
        $bucketDir = "$env:USERPROFILE\scoop\buckets"
        if (Test-Path $bucketDir) {
            $scoopBuckets = @(Get-ChildItem -Path $bucketDir -Directory -ErrorAction Continue |
                Select-Object -ExpandProperty Name)
        }

        Write-SOKLog "Scoop — $($scoopApps.Count) apps, $($scoopBuckets.Count) buckets" -Level $(if ($scoopApps.Count -gt 0) { 'Success' } else { 'Warn' })
    }
    else {
        Write-SOKLog "Scoop not found in PATH" -Level Warn
    }

    $inventory['scoop_apps'] = [ordered]@{
        installed    = $null -ne $scoopCmd
        version      = $scoopVersion
        app_count    = $scoopApps.Count
        apps         = $scoopApps
        bucket_count = $scoopBuckets.Count
        buckets      = $scoopBuckets
    }
}
catch {
    $errors.Add("scoop: $($_.Exception.Message)") | Out-Null
    $inventory['scoop_apps'] = @{ installed = $false; error = $_.Exception.Message }
}


# ═══ FIX 2: Node.js path_healthy detection (replace Node collector) ═══

<#NODE_FIX#>
# The key change: check the VERSION STRING for error patterns, not just the command path
$nodeVersion = & node --version 2>&1 | Out-String
$nodeVersionStr = $nodeVersion.Trim()

if ($nodeVersionStr -match '^v\d+\.\d+\.\d+') {
    # Clean version number — path is healthy
    $nodeInfo.path_healthy = $true
    $nodeInfo.version = $nodeVersionStr
}
elseif ($nodeVersionStr -match 'Cannot find|not found|error|missing') {
    # The "version" output is actually an error message
    $nodeInfo.path_healthy = $false
    $nodeInfo.version = $null
    $nodeInfo.path_issue = "node --version returned error: $($nodeVersionStr.Substring(0, [Math]::Min(200, $nodeVersionStr.Length)))"
    $warnings.Add("Node.js broken: $($nodeInfo.path_issue)") | Out-Null
    Write-SOKLog "NODE PATH BROKEN: $($nodeInfo.path_issue)" -Level Error
}
else {
    # Unknown output
    $nodeInfo.path_healthy = $false
    $nodeInfo.version = $nodeVersionStr
    $nodeInfo.path_issue = "Unexpected node --version output"
}


# ═══ FIX 3: System metadata division by zero (replace storage section) ═══

<#STORAGE_FIX#>
storage = @{
    drives = $disk | ForEach-Object {
        $percentUsed = if ($_.Size -gt 0) {
            [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
        } else { 0 }
        
        [ordered]@{
            device_id    = $_.DeviceID
            volume_name  = $_.VolumeName
            filesystem   = $_.FileSystem
            total_gb     = if ($_.Size -gt 0) { [math]::Round($_.Size / 1GB, 2) } else { 0 }
            free_gb      = if ($_.FreeSpace) { [math]::Round($_.FreeSpace / 1GB, 2) } else { 0 }
            used_gb      = if ($_.Size -gt 0) { [math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2) } else { 0 }
            percent_used = $percentUsed
        }
    }
}
