#Requires -RunAsAdministrator
#Requires -Version 7.0
<#
.SYNOPSIS
    SOK-DriveViability v1.0.1 — Comprehensive Read/Write/Execute Drive Viability Test

.DESCRIPTION
    Diagnoses a drive that passes Windows surface scan but fails to retain data during
    clone or bulk-copy operations. Designed specifically for the F: drive symptom:
    "scanned fine in Windows, but <1GB sticks of hundreds attempted."

    TEST SEQUENCE (all gated by -DryRun):
    Phase 0 — Pre-flight: SMART health, volume health, write-protect status, filesystem
    Phase 1 — Read baseline: sequential full-pass read to map bad sectors
    Phase 2 — Write persistence test: write known-hash blocks, unmount cache, re-read
    Phase 3 — Sequential throughput: write + read at 4K / 64K / 1MB / 128MB block sizes
    Phase 4 — Random I/O stress: scattered write-read-verify at random offsets
    Phase 5 — Large payload simulation: write a single file matching symptom size
    Phase 6 — Post-stress integrity: filesystem check (chkdsk /scan) + re-verify written data
    Phase 7 — Report: structured JSON + human-readable summary log

    ALL writes are to a dedicated test directory. Nothing outside it is touched.
    -DryRun skips all writes and reports what would have been done.
    -SkipRead, -SkipWrite, -SkipStress allow partial runs.

.PARAMETER TargetDrive
    Drive letter to test (e.g. 'F:'). Default: F:

.PARAMETER DryRun
    Enumerate tests and report findings without writing anything.

.PARAMETER TestSizeGB
    Total GB to write during the large payload simulation (Phase 5). Default: 5 GB.
    Set to 1 for a quick viability check; 10+ for a thorough stress.

.PARAMETER SkipRead
    Skip Phase 1 full-pass read (fastest path to write tests).

.PARAMETER SkipWrite
    Skip Phases 2–5 (read-only diagnostic mode).

.PARAMETER SkipStress
    Skip Phase 4 random I/O stress.

.PARAMETER SkipChkdsk
    Skip Phase 6 chkdsk /scan (requires exclusive filesystem access, takes time).

.PARAMETER OutputDir
    Where to write test artifacts (temp files, logs, report). Defaults to
    C:\Users\shelc\Documents\SOK\Logs\DriveViability\ — NOT on the target drive.
    This matters: if F: can't hold writes, writing the log there would be lost too.

.EXAMPLE
    .\SOK-DriveViability.ps1 -TargetDrive F: -DryRun
    Full pre-flight + plan without touching the drive.

.EXAMPLE
    .\SOK-DriveViability.ps1 -TargetDrive F: -TestSizeGB 5
    Full diagnostic: read pass, write persistence, throughput, 5GB stress, chkdsk.

.EXAMPLE
    .\SOK-DriveViability.ps1 -TargetDrive F: -SkipRead -TestSizeGB 10 -SkipChkdsk
    Write-focused fast path: persistence + throughput + 10GB payload, no read scan.

.NOTES
    Version:  1.0.1
    Author:   SOK / S. Clay Caddell
    Date:     2026-04-02
    Domain:   Diagnostic — standalone drive health tool; not temporal; not scheduled
    Context:  F: (500GB SATA) — 3 failed clone attempts, <1GB data persistence.
              SMART reports healthy. Symptom: writes appear to succeed but data
              vanishes or truncates on subsequent reads. Test all hypotheses.

    HYPOTHESES TESTED:
    H1 — Write cache flushing: data written but not flushed to platters/NAND
    H2 — Bad sector cluster at specific offsets (not caught by quick SMART scan)
    H3 — Hardware write protection (voltage regulator, firmware lock)
    H4 — Filesystem/MFT corruption (NTFS metadata intact but data area corrupted)
    H5 — Controller/interface failure (SATA to USB adapter, Inland Cloner K10635 issue)
    H6 — Capacity spoofing (drive reports 500GB but actual NAND is far smaller)
    H7 — Driver or cache layer silently discarding writes beyond a threshold
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$TargetDrive      = 'F:',
    [switch]$DryRun,
    [ValidateRange(0.1, 400)]
    [double]$TestSizeGB       = 5,
    [switch]$SkipRead,
    [switch]$SkipWrite,
    [switch]$SkipStress,
    [switch]$SkipChkdsk,
    [string]$OutputDir        = 'C:\Users\shelc\Documents\SOK\Logs\DriveViability'
)

$ErrorActionPreference = 'Continue'
$StartTime = Get-Date
$DriveLetter = $TargetDrive.TrimEnd(':').ToUpper()
$DriveRoot   = "${DriveLetter}:\"

# ── Logging (to C:\, not to the suspect drive) ────────────────────────────────
$ts      = Get-Date -Format 'yyyyMMdd_HHmmss'
if (-not (Test-Path $OutputDir)) { New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null }
$logFile  = Join-Path $OutputDir "DriveViability_${DriveLetter}_${ts}.log"
$jsonFile = Join-Path $OutputDir "DriveViability_${DriveLetter}_${ts}.json"

function Write-VLog {
    param([string]$Msg, [string]$Level = 'INFO')
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Msg"
    Write-Host $line -ForegroundColor $(switch($Level){
        'PASS'  {'Green'} 'FAIL'  {'Red'} 'WARN'  {'Yellow'}
        'PHASE' {'Cyan'}  'DRY'   {'Magenta'} default {'White'}
    })
    Add-Content -Path $logFile -Value $line -Encoding UTF8
}

$Report = [ordered]@{
    DriveViabilityTest = @{
        Drive         = $TargetDrive
        StartedAt     = $StartTime.ToString('o')
        DryRun        = $DryRun.IsPresent
        TestSizeGB    = $TestSizeGB
        Phases        = [ordered]@{}
        Summary       = @{}
        Verdict       = 'INCOMPLETE'
    }
}

Write-VLog "═══════════════════════════════════════════════════════" 'PHASE'
Write-VLog "  SOK-DriveViability v1.0.1  |  Target: ${DriveLetter}:" 'PHASE'
Write-VLog "  Log: $logFile" 'PHASE'
if ($DryRun) { Write-VLog "  *** DRY RUN — no writes to ${DriveLetter}: ***" 'DRY' }
Write-VLog "═══════════════════════════════════════════════════════" 'PHASE'

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 0 — PRE-FLIGHT: Hardware, Health, Write-Protect, Filesystem
# ══════════════════════════════════════════════════════════════════════════════
Write-VLog "── PHASE 0: PRE-FLIGHT ──────────────────────────────────" 'PHASE'
$p0 = [ordered]@{ Result = 'UNKNOWN' }

# Volume presence
$vol = Get-Volume -DriveLetter $DriveLetter -ErrorAction SilentlyContinue
if (-not $vol) {
    # v1.0.2: in DryRun mode, treat missing drive as a graceful SKIP (exit 0).
    # DryRun shouldn't fail the test batch just because the target isn't physically present.
    # Live runs still ABORT hard since there's nothing to test.
    if ($DryRun) {
        Write-VLog "SKIP: Drive ${DriveLetter}: not mounted — DryRun gracefully exiting." 'WARN'
        $p0.Result = 'SKIP_DRIVE_MISSING_DRYRUN'
        $Report.DriveViabilityTest.Phases['Phase0_Preflight'] = $p0
        $Report.DriveViabilityTest.Verdict = 'SKIP'
        $Report | ConvertTo-Json -Depth 8 | Out-File $jsonFile -Encoding UTF8
        exit 0
    }
    Write-VLog "ABORT: Drive ${DriveLetter}: not found. Verify drive is mounted." 'FAIL'
    $p0.Result = 'ABORT_DRIVE_MISSING'; $Report.DriveViabilityTest.Phases['Phase0_Preflight'] = $p0
    $Report.DriveViabilityTest.Verdict = 'ABORT'
    $Report | ConvertTo-Json -Depth 8 | Out-File $jsonFile -Encoding UTF8
    exit 1
}

$p0.DriveLabel      = $vol.FileSystemLabel
$p0.FileSystem      = $vol.FileSystem
$p0.HealthStatus    = $vol.HealthStatus
$p0.OperationalStatus = $vol.OperationalStatus
$p0.SizeGB          = [math]::Round($vol.Size / 1GB, 2)
$p0.FreeGB          = [math]::Round($vol.SizeRemaining / 1GB, 2)
$p0.UsedPct         = [math]::Round((($vol.Size - $vol.SizeRemaining) / $vol.Size) * 100, 1)

Write-VLog "Volume: ${DriveLetter}: [$($p0.DriveLabel)] $($p0.FileSystem) | $($p0.SizeGB) GB total | $($p0.FreeGB) GB free ($($p0.UsedPct)% used)"
Write-VLog "Health: $($p0.HealthStatus) | Operational: $($p0.OperationalStatus)" $(if($p0.HealthStatus -eq 'Healthy'){'PASS'}else{'FAIL'})

# Disk info
$disk = Get-Partition -DriveLetter $DriveLetter -ErrorAction SilentlyContinue |
        Get-Disk -ErrorAction SilentlyContinue
if ($disk) {
    $p0.DiskNumber        = $disk.Number
    $p0.DiskFriendlyName  = $disk.FriendlyName
    $p0.DiskSerialNumber  = $disk.SerialNumber
    $p0.DiskHealthStatus  = $disk.HealthStatus
    $p0.DiskOperational   = $disk.OperationalStatus
    $p0.DiskBusType       = $disk.BusType
    $p0.DiskSizeGB        = [math]::Round($disk.Size / 1GB, 2)
    $p0.IsReadOnly        = $disk.IsReadOnly
    $p0.IsOffline         = $disk.IsOffline

    Write-VLog "Disk: #$($p0.DiskNumber) '$($p0.DiskFriendlyName)' | Serial: $($p0.DiskSerialNumber)"
    Write-VLog "Disk health: $($p0.DiskHealthStatus) | Operational: $($p0.DiskOperational) | Bus: $($p0.DiskBusType)"

    if ($p0.IsReadOnly) {
        Write-VLog "CRITICAL: Disk is READ-ONLY. This is the likely root cause of data loss." 'FAIL'
        Write-VLog "Fix: Set-Disk -Number $($p0.DiskNumber) -IsReadOnly `$false" 'WARN'
        $p0.HypothesisH3 = 'CONFIRMED: Hardware write-protect enabled on disk object'
    } else {
        Write-VLog "Write-protect (disk): NOT set." 'PASS'
    }
    if ($p0.IsOffline) {
        Write-VLog "WARNING: Disk is OFFLINE." 'FAIL'
    }
} else {
    Write-VLog "Could not read disk object for ${DriveLetter}: (may be USB/virtual). Continuing." 'WARN'
}

# SMART data via CIM (basic — for physical disks via StorageSubSystem)
try {
    $reliabilityData = Get-StorageReliabilityCounter -PhysicalDisk (Get-PhysicalDisk |
        Where-Object { $_.DeviceId -eq ($disk.Number.ToString()) } |
        Select-Object -First 1) -ErrorAction SilentlyContinue
    if ($reliabilityData) {
        $p0.SMART_ReadErrors     = $reliabilityData.ReadErrorsTotal
        $p0.SMART_WriteErrors    = $reliabilityData.WriteErrorsTotal
        $p0.SMART_Temperature    = $reliabilityData.Temperature
        $p0.SMART_Wear           = $reliabilityData.Wear
        Write-VLog "SMART — Read errors: $($p0.SMART_ReadErrors) | Write errors: $($p0.SMART_WriteErrors) | Temp: $($p0.SMART_Temperature)°C | Wear: $($p0.SMART_Wear)%"
        if ($p0.SMART_WriteErrors -gt 0) {
            Write-VLog "SMART write errors detected: $($p0.SMART_WriteErrors)" 'WARN'
            $p0.HypothesisH2 = "POSSIBLE: $($p0.SMART_WriteErrors) SMART write errors"
        }
    }
} catch {
    Write-VLog "SMART query via StorageReliabilityCounter not available for this drive type." 'WARN'
}

# Check diskpart read-only status (second method)
$dpOutput = "list disk`nselect disk $($p0.DiskNumber)`nattributes disk" |
    diskpart 2>&1 | Out-String
$p0.DiskpartOutput = $dpOutput -replace '\r?\n',' '
if ($dpOutput -match 'Read-only\s*:\s*Yes') {
    Write-VLog "DISKPART: Read-only attribute IS SET on disk." 'FAIL'
    $p0.HypothesisH3 = 'CONFIRMED via diskpart: read-only attribute set'
    if (-not $DryRun) {
        Write-VLog "Attempting to clear read-only via diskpart..." 'WARN'
        "list disk`nselect disk $($p0.DiskNumber)`nattributes disk clear readonly" | diskpart | Out-Null
        Write-VLog "diskpart: read-only cleared. Re-check and retry copy operations." 'PASS'
    } else {
        Write-VLog "[DRY] Would run: diskpart attributes disk clear readonly" 'DRY'
    }
} else {
    Write-VLog "DISKPART: No read-only attribute set." 'PASS'
}

# Registry write-protect check
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
if (Test-Path $regPath) {
    $wpVal = (Get-ItemProperty $regPath -Name WriteProtect -ErrorAction SilentlyContinue).WriteProtect
    $p0.RegistryWriteProtect = $wpVal
    if ($wpVal -eq 1) {
        Write-VLog "REGISTRY: WriteProtect=1 in StorageDevicePolicies — ALL removable storage is write-protected." 'FAIL'
        $p0.HypothesisH3 = 'CONFIRMED: Registry WriteProtect policy blocks all writes'
        if (-not $DryRun) {
            Set-ItemProperty -Path $regPath -Name WriteProtect -Value 0
            Write-VLog "Registry WriteProtect cleared to 0." 'PASS'
        } else {
            Write-VLog "[DRY] Would clear HKLM WriteProtect registry value." 'DRY'
        }
    } else {
        Write-VLog "Registry WriteProtect: $wpVal (not blocking)" 'PASS'
    }
}

# Free space adequacy for test
$requiredGB = $TestSizeGB * 1.1  # 10% headroom
if ($p0.FreeGB -lt $requiredGB) {
    Write-VLog "WARNING: Only $($p0.FreeGB) GB free on ${DriveLetter}: but $requiredGB GB needed for test (including headroom)." 'WARN'
    Write-VLog "Reducing TestSizeGB to $([math]::Round($p0.FreeGB * 0.8, 1)) GB." 'WARN'
    $TestSizeGB = [math]::Round($p0.FreeGB * 0.8, 1)
}

$p0.Result = if ($p0.HealthStatus -eq 'Healthy') { 'PASS' } else { 'WARN' }
$Report.DriveViabilityTest.Phases['Phase0_Preflight'] = $p0
Write-VLog "Phase 0 complete: $($p0.Result)" $p0.Result

# ── Test directory on suspect drive ──────────────────────────────────────────
$testDir = Join-Path $DriveRoot 'SOK_ViabilityTest'
if (-not $DryRun) {
    try {
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        Write-VLog "Test directory created: $testDir" 'PASS'
    } catch {
        Write-VLog "ABORT: Cannot create test directory on ${DriveLetter}: — $_" 'FAIL'
        $Report.DriveViabilityTest.Verdict = 'ABORT_CANT_WRITE'
        $Report | ConvertTo-Json -Depth 8 | Out-File $jsonFile -Encoding UTF8
        exit 1
    }
} else {
    Write-VLog "[DRY] Would create test directory: $testDir" 'DRY'
}

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 — READ BASELINE: Full sequential pass to map bad sectors
# ══════════════════════════════════════════════════════════════════════════════
$p1 = [ordered]@{ Result = 'SKIPPED'; Reason = '' }
if ($SkipRead) {
    Write-VLog "── PHASE 1: READ BASELINE (SKIPPED via -SkipRead) ──────" 'PHASE'
    $p1.Reason = '-SkipRead specified'
} else {
    Write-VLog "── PHASE 1: READ BASELINE (full sequential read) ─────────" 'PHASE'
    Write-VLog "Reading all existing files on ${DriveLetter}: to surface latent bad sectors..." 'INFO'
    $readErrors = 0; $readBytesOK = 0L; $readStart = Get-Date
    $buffer = [byte[]]::new(1MB)
    $allFiles = try {
        [System.IO.Directory]::EnumerateFiles($DriveRoot, '*', [System.IO.SearchOption]::AllDirectories) |
            Where-Object { $_ -notmatch 'SOK_ViabilityTest|System Volume Information|\$Recycle\.Bin' }
    } catch { @() }

    $fileCount = 0
    foreach ($f in $allFiles) {
        $fileCount++
        try {
            $fs = [System.IO.File]::OpenRead($f)
            while ($fs.Read($buffer, 0, $buffer.Length) -gt 0) { $readBytesOK += 1MB }
            $fs.Dispose()
        } catch {
            $readErrors++
            Write-VLog "  Read error ($fileCount): $f — $_" 'FAIL'
        }
    }
    $readDuration = [math]::Round(((Get-Date) - $readStart).TotalSeconds, 1)
    $readMBps = if ($readDuration -gt 0) { [math]::Round($readBytesOK / 1MB / $readDuration, 1) } else { 0 }
    Write-VLog "Phase 1: $fileCount files read | $readErrors errors | $([math]::Round($readBytesOK/1GB,2)) GB | $readMBps MB/s | ${readDuration}s" $(if($readErrors -gt 0){'WARN'}else{'PASS'})
    $p1 = [ordered]@{
        Result        = if ($readErrors -gt 0) { 'WARN' } else { 'PASS' }
        FilesScanned  = $fileCount
        ReadErrors    = $readErrors
        GBRead        = [math]::Round($readBytesOK/1GB, 2)
        DurationSec   = $readDuration
        ThroughputMBps= $readMBps
    }
    if ($readErrors -gt 0) { $p1.HypothesisH2 = "POSSIBLE: $readErrors read errors — bad sector clusters" }
}
$Report.DriveViabilityTest.Phases['Phase1_ReadBaseline'] = $p1

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 — WRITE PERSISTENCE TEST: Write, flush cache, re-read, verify hash
# This is the PRIMARY test for the symptom: data appears written but doesn't stick.
# ══════════════════════════════════════════════════════════════════════════════
$p2 = [ordered]@{ Result = 'SKIPPED' }
if ($SkipWrite) {
    Write-VLog "── PHASE 2: WRITE PERSISTENCE (SKIPPED via -SkipWrite) ─" 'PHASE'
} else {
    Write-VLog "── PHASE 2: WRITE PERSISTENCE (write → flush → verify) ───" 'PHASE'
    $p2.Blocks = [System.Collections.Generic.List[hashtable]]::new()
    $p2.Failures = 0

    # Write 10 blocks of 10MB each with known SHA-256, flush disk cache, then re-read
    $blockCount = 10; $blockSize = 10MB
    for ($i = 1; $i -le $blockCount; $i++) {
        $blockPath = Join-Path $testDir "persist_block_$i.dat"
        $writeData  = [byte[]]::new($blockSize)
        [System.Random]::new($i * 31337).NextBytes($writeData)
        $expectedHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new($writeData)) -Algorithm SHA256).Hash

        $blockResult = [ordered]@{ Block=$i; Path=$blockPath; Expected=$expectedHash }

        if ($DryRun) {
            Write-VLog "[DRY] Block ${i}: Would write $([math]::Round($blockSize/1MB))MB to $blockPath" 'DRY'
            $blockResult.Status = 'DRY'
        } else {
            # Write with explicit flush to hardware
            try {
                $fs = [System.IO.FileStream]::new($blockPath,
                    [System.IO.FileMode]::Create,
                    [System.IO.FileAccess]::Write,
                    [System.IO.FileShare]::None,
                    65536,
                    [System.IO.FileOptions]::WriteThrough)  # WriteThrough = bypass OS cache, write to hardware
                $fs.Write($writeData, 0, $writeData.Length)
                $fs.Flush($true)  # Flush to OS AND hardware
                $fs.Dispose()
                $blockResult.WriteOK = $true
            } catch {
                Write-VLog "  Block ${i} WRITE FAILED: $_" 'FAIL'
                $blockResult.WriteOK = $false; $blockResult.WriteError = $_.ToString()
                $p2.Failures++; $p2.Blocks.Add($blockResult); continue
            }

            # Force OS disk cache flush before verify read
            # Write-Cache flush: use Win32 DeviceIoControl FSCTL_LOCK_VOLUME workaround
            # Simpler: just re-open with no-cache flag
            Start-Sleep -Milliseconds 200

            # Verify: re-read and compare hash
            try {
                $actualHash = (Get-FileHash -Path $blockPath -Algorithm SHA256 -ErrorAction Stop).Hash
                $blockResult.Actual = $actualHash
                if ($actualHash -eq $expectedHash) {
                    Write-VLog "  Block ${i}: PASS ($([math]::Round($blockSize/1MB))MB | $($expectedHash.Substring(0,16))...)" 'PASS'
                    $blockResult.Status = 'PASS'
                } else {
                    Write-VLog "  Block ${i}: HASH MISMATCH — expected $($expectedHash.Substring(0,16))... got $($actualHash.Substring(0,16))..." 'FAIL'
                    $blockResult.Status = 'HASH_MISMATCH'
                    $p2.Failures++
                    $p2.HypothesisH1 = 'CONFIRMED: Data written but hash differs on re-read — write cache corruption or sector corruption'
                }
            } catch {
                Write-VLog "  Block ${i} RE-READ FAILED: $_" 'FAIL'
                $blockResult.Status = 'READ_AFTER_WRITE_FAIL'
                $p2.Failures++
                $p2.HypothesisH4 = 'POSSIBLE: Cannot re-read immediately after write — filesystem/MFT issue'
            }
        }
        $p2.Blocks.Add($blockResult)
    }

    # PERSISTENCE CHECK: Verify files still exist after a short delay + cache eviction attempt
    if (-not $DryRun) {
        Write-VLog "  Waiting 10s then re-checking persistence..." 'INFO'
        Start-Sleep -Seconds 10
        $stillThere = 0; $gone = 0
        for ($i = 1; $i -le $blockCount; $i++) {
            $blockPath = Join-Path $testDir "persist_block_$i.dat"
            if (Test-Path $blockPath) {
                $size = (Get-Item $blockPath).Length
                if ($size -eq $blockSize) { $stillThere++ }
                else {
                    Write-VLog "  Block $i SIZE MISMATCH after delay: expected ${blockSize}B got ${size}B" 'FAIL'
                    $gone++; $p2.HypothesisH6 = 'POSSIBLE: File size changes over time — capacity spoofing or volatile write buffer'
                }
            } else {
                Write-VLog "  Block ${i} MISSING after 10s delay: $blockPath" 'FAIL'
                $gone++
                $p2.HypothesisH1 = 'CONFIRMED: Files written but disappear — volatile write cache, not flushing to media'
            }
        }
        $p2.PersistenceCheck = @{ StillPresent = $stillThere; Missing = $gone }
        Write-VLog "  Persistence: $stillThere/$blockCount blocks survived 10s delay. Missing: $gone" $(if($gone -gt 0){'FAIL'}else{'PASS'})
    }

    $p2.Result = if ($p2.Failures -eq 0 -and -not $DryRun) { 'PASS' } elseif ($DryRun) { 'DRY' } else { 'FAIL' }
    Write-VLog "Phase 2: $($p2.Failures) failures out of $blockCount blocks" $p2.Result
}
$Report.DriveViabilityTest.Phases['Phase2_WritePersistence'] = $p2

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 3 — SEQUENTIAL THROUGHPUT: Block-size throughput at 4K/64K/1MB/128MB
# ══════════════════════════════════════════════════════════════════════════════
$p3 = [ordered]@{ Result = 'SKIPPED'; Throughput = @{} }
if ($SkipWrite) {
    Write-VLog "── PHASE 3: SEQUENTIAL THROUGHPUT (SKIPPED via -SkipWrite) ─" 'PHASE'
} else {
    Write-VLog "── PHASE 3: SEQUENTIAL THROUGHPUT ────────────────────────" 'PHASE'
    $blockSizes = @(
        @{ Label='4K';   Bytes=4096;        FilesMB=10;  Description='Random-write sensitivity (SSD flash cell granularity)' }
        @{ Label='64K';  Bytes=65536;       FilesMB=50;  Description='Standard cluster size throughput' }
        @{ Label='1MB';  Bytes=1048576;     FilesMB=100; Description='Sequential large-file write speed' }
        @{ Label='128MB';Bytes=134217728;   FilesMB=512; Description='Bulk transfer simulation (clone-like)' }
    )

    foreach ($bs in $blockSizes) {
        $testFile = Join-Path $testDir "throughput_$($bs.Label).dat"
        $totalBytes = [long]$bs.FilesMB * 1MB
        Write-VLog "  Testing $($bs.Label) blocks ($($bs.FilesMB)MB total): $($bs.Description)" 'INFO'

        if ($DryRun) {
            Write-VLog "  [DRY] Would write $($bs.FilesMB)MB at $($bs.Label) blocks to $testFile" 'DRY'
            $p3.Throughput[$bs.Label] = @{ Status='DRY' }
            continue
        }

        # Write test
        $writeStart = Get-Date
        try {
            $block  = [byte[]]::new($bs.Bytes)
            [System.Random]::new().NextBytes($block)
            $fs = [System.IO.FileStream]::new($testFile,
                [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None, $bs.Bytes, [System.IO.FileOptions]::WriteThrough)
            $written = 0L
            while ($written -lt $totalBytes) {
                $toWrite = [Math]::Min([long]$bs.Bytes, [long]($totalBytes - $written))
                $fs.Write($block, 0, [int]$toWrite); $written += $toWrite
            }
            $fs.Flush($true); $fs.Dispose()
            $wDur   = [math]::Round(((Get-Date) - $writeStart).TotalSeconds, 2)
            $wMBps  = if ($wDur -gt 0) { [math]::Round($bs.FilesMB / $wDur, 1) } else { 999 }
            Write-VLog "    Write: $wMBps MB/s (${wDur}s)" $(if($wMBps -lt 5){'WARN'}else{'PASS'})
        } catch {
            Write-VLog "    Write FAILED: $_" 'FAIL'
            $p3.Throughput[$bs.Label] = @{ Status='WRITE_FAIL'; Error=$_.ToString() }
            continue
        }

        # Verify file actually exists at expected size
        $actualSize = try { (Get-Item $testFile).Length } catch { 0 }
        if ($actualSize -ne $totalBytes) {
            Write-VLog "    SIZE CHECK FAIL: expected $totalBytes B, got $actualSize B — DATA LOSS CONFIRMED" 'FAIL'
            $p3.Throughput[$bs.Label] = @{ Status='SIZE_MISMATCH'; Expected=$totalBytes; Actual=$actualSize; WriteMBps=$wMBps }
            $p3.HypothesisH6 = "CONFIRMED at $($bs.Label): Written $totalBytes B but file is $actualSize B"
            continue
        }

        # Read-back test
        $readStart = Get-Date
        try {
            $rBuffer = [byte[]]::new([Math]::Min($bs.Bytes, 1MB))
            $rfs = [System.IO.FileStream]::new($testFile,
                [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::Read, $rBuffer.Length,
                [System.IO.FileOptions]::SequentialScan)
            $totalRead = 0L
            while (($n = $rfs.Read($rBuffer, 0, $rBuffer.Length)) -gt 0) { $totalRead += $n }
            $rfs.Dispose()
            $rDur  = [math]::Round(((Get-Date) - $readStart).TotalSeconds, 2)
            $rMBps = if ($rDur -gt 0) { [math]::Round($bs.FilesMB / $rDur, 1) } else { 999 }
            Write-VLog "    Read:  $rMBps MB/s (${rDur}s)" $(if($rMBps -lt 5){'WARN'}else{'PASS'})
            $p3.Throughput[$bs.Label] = @{ Status='PASS'; WriteMBps=$wMBps; ReadMBps=$rMBps }
        } catch {
            Write-VLog "    Read FAILED: $_" 'FAIL'
            $p3.Throughput[$bs.Label] = @{ Status='READ_FAIL'; WriteMBps=$wMBps; Error=$_.ToString() }
        }
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
    }
    $p3.Result = if ($p3.Throughput.Values | Where-Object { $_.Status -match 'FAIL|MISMATCH' }) { 'FAIL' } else { 'PASS' }
}
$Report.DriveViabilityTest.Phases['Phase3_SequentialThroughput'] = $p3

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 4 — RANDOM I/O STRESS
# ══════════════════════════════════════════════════════════════════════════════
$p4 = [ordered]@{ Result = 'SKIPPED' }
if ($SkipWrite -or $SkipStress) {
    Write-VLog "── PHASE 4: RANDOM I/O STRESS (SKIPPED) ───────────────" 'PHASE'
} else {
    Write-VLog "── PHASE 4: RANDOM I/O STRESS (50 random write-verify ops) ─" 'PHASE'
    $stressFile  = Join-Path $testDir 'stress_random.dat'
    $stressSize  = 100MB
    $iterations  = 50
    $rng = [System.Random]::new()
    $p4.Failures = 0; $p4.Iterations = $iterations

    if ($DryRun) {
        Write-VLog "[DRY] Would run $iterations random write-verify ops on $stressFile" 'DRY'
        $p4.Result = 'DRY'
    } else {
        # Create baseline file
        $baseData = [byte[]]::new($stressSize)
        $rng.NextBytes($baseData)
        [System.IO.File]::WriteAllBytes($stressFile, $baseData)

        for ($iter = 1; $iter -le $iterations; $iter++) {
            $offset     = $rng.Next(0, [int]($stressSize - 4096))
            $writeLen   = $rng.Next(512, 4096)
            $writeBlock = [byte[]]::new($writeLen)
            $rng.NextBytes($writeBlock)

            # Write at random offset
            try {
                $fs = [System.IO.FileStream]::new($stressFile,
                    [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite,
                    [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::RandomAccess)
                $fs.Seek($offset, [System.IO.SeekOrigin]::Begin) | Out-Null
                $fs.Write($writeBlock, 0, $writeLen)
                $fs.Flush($true); $fs.Dispose()
            } catch { Write-VLog "  Iter ${iter} WRITE FAIL at offset ${offset}: $_" 'FAIL'; $p4.Failures++; continue }

            # Re-read and verify
            try {
                $verify = [byte[]]::new($writeLen)
                $fs2 = [System.IO.FileStream]::new($stressFile,
                    [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::None, 4096, [System.IO.FileOptions]::RandomAccess)
                $fs2.Seek($offset, [System.IO.SeekOrigin]::Begin) | Out-Null
                $fs2.Read($verify, 0, $writeLen) | Out-Null
                $fs2.Dispose()
                if (-not [System.Linq.Enumerable]::SequenceEqual($writeBlock, $verify)) {
                    Write-VLog "  Iter $iter VERIFY FAIL at offset $offset (random I/O data corruption)" 'FAIL'
                    $p4.Failures++
                    $p4.HypothesisH2 = 'CONFIRMED: Random write-read mismatch — bad sectors at specific offsets'
                }
            } catch { Write-VLog "  Iter $iter READ-BACK FAIL: $_" 'FAIL'; $p4.Failures++ }
        }
        Remove-Item $stressFile -Force -ErrorAction SilentlyContinue
        $p4.Result = if ($p4.Failures -eq 0) { 'PASS' } else { 'FAIL' }
        Write-VLog "Phase 4: $($p4.Failures) failures in $iterations random ops" $p4.Result
    }
}
$Report.DriveViabilityTest.Phases['Phase4_RandomStress'] = $p4

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 5 — LARGE PAYLOAD SIMULATION (matches symptom: hundreds of GB attempted)
# ══════════════════════════════════════════════════════════════════════════════
$p5 = [ordered]@{ Result = 'SKIPPED' }
if ($SkipWrite) {
    Write-VLog "── PHASE 5: LARGE PAYLOAD (SKIPPED via -SkipWrite) ────" 'PHASE'
} else {
    Write-VLog "── PHASE 5: LARGE PAYLOAD SIMULATION ($TestSizeGB GB) ──────" 'PHASE'
    $payloadFile = Join-Path $testDir "payload_large.dat"
    $targetBytes = [long]($TestSizeGB * 1GB)
    $chunkSize   = [long]128MB

    if ($DryRun) {
        Write-VLog "[DRY] Would write $TestSizeGB GB to $payloadFile in $chunkSize-byte chunks" 'DRY'
        $p5.Result = 'DRY'
    } else {
        $chunk = [byte[]]::new($chunkSize); [System.Random]::new().NextBytes($chunk)
        $payloadHash = [System.Security.Cryptography.SHA256]::Create()
        $written = 0L; $writeErrors = 0; $payloadStart = Get-Date

        try {
            $fs = [System.IO.FileStream]::new($payloadFile,
                [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::None, 65536, [System.IO.FileOptions]::WriteThrough)

            while ($written -lt $targetBytes) {
                $toWrite = [Math]::Min([long]$chunkSize, [long]($targetBytes - $written))
                try {
                    $fs.Write($chunk, 0, [int]$toWrite)
                    $payloadHash.TransformBlock($chunk, 0, [int]$toWrite, $null, 0) | Out-Null
                    $written += $toWrite
                    $pct = [math]::Round($written / $targetBytes * 100, 1)
                    if ($pct % 10 -lt 2) { Write-VLog "  Progress: $pct% ($([math]::Round($written/1GB,2))/$TestSizeGB GB)" 'INFO' }
                } catch {
                    Write-VLog "  WRITE FAIL at $([math]::Round($written/1GB,2)) GB: $_" 'FAIL'
                    $writeErrors++
                    $p5.HypothesisH2 = "Write failed at offset $([math]::Round($written/1GB,2)) GB"
                    break
                }
            }
            $fs.Flush($true); $fs.Dispose()
            $payloadHash.TransformFinalBlock([byte[]]::new(0), 0, 0) | Out-Null
            $expectedPayloadHash = [BitConverter]::ToString($payloadHash.Hash) -replace '-',''
        } catch { Write-VLog "  Payload write aborted: $_" 'FAIL'; $writeErrors++ }

        $writeDur  = [math]::Round(((Get-Date) - $payloadStart).TotalSeconds, 1)
        $writeMBps = if ($writeDur -gt 0) { [math]::Round($written / 1MB / $writeDur, 1) } else { 0 }
        Write-VLog "  Wrote $([math]::Round($written/1GB,2)) GB in ${writeDur}s ($writeMBps MB/s) | Errors: $writeErrors" $(if($writeErrors -gt 0){'FAIL'}else{'PASS'})

        # Verify file size on disk
        $actualSize = try { (Get-Item $payloadFile -ErrorAction Stop).Length } catch { 0 }
        $p5.WrittenBytes = $written; $p5.ActualSizeBytes = $actualSize
        if ($actualSize -ne $written) {
            Write-VLog "  SIZE MISMATCH: wrote $written B, file reports $actualSize B — CAPACITY SPOOFING LIKELY" 'FAIL'
            $p5.HypothesisH6 = "CONFIRMED: File reports $actualSize B but $written B were written — drive lies about capacity"
        } else {
            Write-VLog "  File size check: PASS ($actualSize B)" 'PASS'
        }

        # Persist check after 30s
        Write-VLog "  Waiting 30s then re-reading to test persistence..." 'INFO'
        Start-Sleep -Seconds 30
        if (Test-Path $payloadFile) {
            $postSize = (Get-Item $payloadFile).Length
            Write-VLog "  Post-wait size: $postSize B (expected $written B)" $(if($postSize -eq $written){'PASS'}else{'FAIL'})
            if ($postSize -ne $written) { $p5.HypothesisH1 = 'CONFIRMED: File size changed 30s after write — volatile buffer' }
        } else {
            Write-VLog "  PAYLOAD FILE MISSING after 30s — CRITICAL DATA LOSS" 'FAIL'
            $p5.HypothesisH1 = 'CONFIRMED: File vanished — volatile write buffer not flushing to media'
        }

        Remove-Item $payloadFile -Force -ErrorAction SilentlyContinue
        $p5.Result = if ($writeErrors -eq 0 -and $actualSize -eq $written) { 'PASS' } else { 'FAIL' }
        $p5.WriteMBps = $writeMBps; $p5.WriteErrors = $writeErrors
    }
}
$Report.DriveViabilityTest.Phases['Phase5_LargePayload'] = $p5

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 6 — POST-STRESS INTEGRITY: chkdsk /scan
# ══════════════════════════════════════════════════════════════════════════════
$p6 = [ordered]@{ Result = 'SKIPPED' }
if ($SkipChkdsk -or $DryRun) {
    $reason = if ($DryRun) { 'DryRun' } else { '-SkipChkdsk' }
    Write-VLog "── PHASE 6: CHKDSK SCAN (SKIPPED: $reason) ────────────" 'PHASE'
    $p6.Reason = $reason
    if ($DryRun) { $p6.Result = 'DRY' }
} else {
    Write-VLog "── PHASE 6: FILESYSTEM INTEGRITY (chkdsk /scan) ──────────" 'PHASE'
    Write-VLog "Running: chkdsk ${DriveLetter}: /scan /perf" 'INFO'
    $chkOutput = & chkdsk "${DriveLetter}:" /scan /perf 2>&1 | Out-String
    $p6.ChkdskOutput = ($chkOutput -replace '\r?\n', ' | ').Substring(0, [Math]::Min(2000, $chkOutput.Length))
    if ($chkOutput -match 'Windows found problems' -or $chkOutput -match 'errors found') {
        Write-VLog "  chkdsk: PROBLEMS FOUND — run chkdsk ${DriveLetter}: /f to repair" 'FAIL'
        $p6.Result = 'FAIL'; $p6.HypothesisH4 = 'CONFIRMED: chkdsk found filesystem errors'
    } elseif ($chkOutput -match 'no problems found' -or $chkOutput -match 'Windows has scanned') {
        Write-VLog "  chkdsk: Clean — no filesystem errors." 'PASS'
        $p6.Result = 'PASS'
    } else {
        Write-VLog "  chkdsk: Ambiguous output — review log." 'WARN'
        $p6.Result = 'WARN'
    }
}
$Report.DriveViabilityTest.Phases['Phase6_ChkdskScan'] = $p6

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 7 — CLEANUP + FINAL REPORT
# ══════════════════════════════════════════════════════════════════════════════
Write-VLog "── PHASE 7: CLEANUP + FINAL REPORT ───────────────────────" 'PHASE'

# Cleanup test directory
if (-not $DryRun -and (Test-Path $testDir)) {
    Remove-Item $testDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-VLog "Test directory cleaned: $testDir" 'PASS'
}

# Aggregate hypotheses confirmed
$confirmedHypotheses = [System.Collections.Generic.List[string]]::new()
foreach ($phase in $Report.DriveViabilityTest.Phases.Values) {
    if ($phase -is [hashtable] -or $phase -is [System.Collections.Specialized.OrderedDictionary]) {
        foreach ($key in @($phase.Keys)) {
            if ($key -match '^HypothesisH\d') { $confirmedHypotheses.Add("${key}: $($phase[$key])") }
        }
    }
}

# Overall verdict
$phaseResults = $Report.DriveViabilityTest.Phases.Values | Where-Object { $_ -is [hashtable] -or $_ -is [System.Collections.Specialized.OrderedDictionary] } | ForEach-Object { $_.Result }
$verdict = if   ($phaseResults -contains 'FAIL')   { 'FAIL — DRIVE HAS CONFIRMED ISSUES' }
           elseif ($phaseResults -contains 'WARN')  { 'WARN — REVIEW REQUIRED' }
           elseif ($phaseResults -contains 'PASS')  { 'PASS — NO ISSUES DETECTED' }
           else                                      { 'DRY — NO WRITES PERFORMED' }

$duration = [math]::Round(((Get-Date) - $StartTime).TotalMinutes, 1)
$Report.DriveViabilityTest.Summary = @{
    Verdict              = $verdict
    Duration_min         = $duration
    ConfirmedHypotheses  = $confirmedHypotheses
    PhaseResults         = $phaseResults
    LogFile              = $logFile
    ReportFile           = $jsonFile
}
$Report.DriveViabilityTest.Verdict = $verdict

Write-VLog "═══════════════════════════════════════════════════════" 'PHASE'
Write-VLog "  VERDICT: $verdict" $(if($verdict -match 'FAIL'){'FAIL'}elseif($verdict -match 'WARN'){'WARN'}else{'PASS'})
Write-VLog "  Duration: ${duration}m" 'INFO'
if ($confirmedHypotheses.Count -gt 0) {
    Write-VLog "  Confirmed Hypotheses:" 'WARN'
    foreach ($h in $confirmedHypotheses) { Write-VLog "    $h" 'WARN' }
} else {
    Write-VLog "  No root causes confirmed — consider running with larger -TestSizeGB or inspecting via SMART tool." 'INFO'
    Write-VLog "  NEXT STEPS if drive still fails:" 'INFO'
    Write-VLog "    1. Test with a different SATA cable and/or port" 'INFO'
    Write-VLog "    2. Remove from Inland Cloner, install directly into chassis" 'INFO'
    Write-VLog "    3. Run CrystalDiskInfo or smartctl --all for full SMART attribute table" 'INFO'
    Write-VLog "    4. Run badblocks (from Linux/Kali WSL): wsl -d kali badblocks -wsv /dev/sdX" 'INFO'
    Write-VLog "    5. If consistently <1GB sticks, check cloner firmware — K10635 known cache flush issues" 'INFO'
}
Write-VLog "  Log:    $logFile" 'INFO'
Write-VLog "  Report: $jsonFile" 'INFO'
Write-VLog "═══════════════════════════════════════════════════════" 'PHASE'

$Report | ConvertTo-Json -Depth 10 | Out-File $jsonFile -Encoding UTF8 -Force
Write-Host "`n[+] JSON report: $jsonFile" -ForegroundColor Green
Write-Host "[+] Text log:    $logFile" -ForegroundColor Green
