# C: DRIVE RESTRUCTURING PLAN v2 — CLAY_PC
# Generated: 27Mar2026 | C: 62.8% used (626 GB / 999 GB)
# Operator decisions applied 27Mar2026

## CURRENT STATE
- C: 999 GB NVMe (Samsung PM9B1), 373 GB free (37.3%)
- E: 500 GB USB SSD (JMicron PCIe581), 22.3% used — offload target (DISMOUNTED)
- D: 4 TB USB HDD (JMicron SATA581) — DMDE scan complete (38997 items recovered)
- 32 junctions (9 cross-drive, 2 broken: OneDrive UC, nvm4w)

## TIER 1: AUTOMATED (SOK-Maintenance handles this)
~2.8 GB per Thorough run. No operator action needed.

## TIER 2: OFFLOAD TO E: (operator-approved)
Already offloaded: 40 items on E:\SOK_Offload.
Visual Studio: STAYS on C: (operator decision).

New offloads approved:
| Path | Size | Notes |
|------|------|-------|
| C:\Program Files\Docker | 4.1 GB | Stop Docker service, junction back |
| C:\Users\shelc\AppData\Local\Packages | 1.8 GB | UWP app data |
| C:\Program Files\MongoDB + ProgramData\MongoDB | 1.5 GB | Stop mongod first |
| C:\Program Files (x86)\Microsoft Visual Studio\Shared\Packages | 430 MB | VS shared NuGet |
| C:\Users\shelc\AppData\LocalLow\Adobe\AcroCef | 450 MB | Acrobat cache |
**Action: Add to SOK-Offload target list. Total: ~8.3 GB**

## TIER 3: STALE CLEANUP (operator-approved for offload)
All to E:\SOK_Offload (deprecate, don't delete):
| Path | Size | Stale |
|------|------|-------|
| C:\ProgramData\mingw64 | 719 MB | 122d |
| C:\ProgramData\glasswire | 524 MB | 121d |
| C:\ProgramData\Jenkins | 106 MB | 122d |
| C:\ProgramData\MySQL | 190 MB | 122d |
| C:\ProgramData\USOShared | 84 MB | 725d |
| C:\ProgramData\SquirrelMachineInstalls | 118 MB | 122d |
| C:\ProgramData\ChocolateyHttpCache | 21 MB | 204d |
| C:\Program Files\Java\jdk1.8.0_211 | 376 MB | 121d — JDK 25 downloaded |
| C:\Program Files\Java\jdk-17 | 291 MB | 54d — JDK 25 replaces |
| C:\Program Files\Java\jdk-21.0.10 | 316 MB | 54d — JDK 25 replaces |
| C:\Program Files\Java\jre1.8.0_481 | 126 MB | 56d — obsolete |
| C:\Program Files (x86)\Java\jre1.8.0_471 | 113 MB | 121d — obsolete |
| C:\Program Files\SmartBear\SoapUI-5.8.0 | 273 MB | 122d — duplicate of 5.9.1 |
| C:\Program Files\Erlang OTP\erts-16.1.* | 464 MB | 122d — keep 16.3 only |
| C:\Program Files\Erlang OTP\erts-16.2 | 113 MB | 104d |
| C:\Program Files\Gephi-0.10.1 | 255 MB | 206d |
| C:\Program Files\Waves\InferenceEngine | 79 MB | 246d |
| C:\Program Files\weka-3-8-6\doc | 81 MB | 1522d |
**Action: Add to SOK-Offload or SOK-Cleanup. Total: ~4.4 GB**

## TIER 4: BIG-TICKET (operator decisions)
| Path | Size | Decision |
|------|------|----------|
| C:\Users\shelc\Documents\Backup | 271 GB | **MOVE TO E: or empty NVMe** |
| C:\Program Files\Unity 6000.2.* (3 ver) | 23.3 GB | **CONDENSE to latest only via Unity Hub** |
| C:\ProgramData\Package Cache | 4.5 GB | **CLEAR — 80%+ internet available for re-download** |
| C:\ProgramData\anaconda3 | 11.3 GB | KEEP for now |
| C:\Program Files\Docker | 4.1 GB | KEEP (offload via Tier 2 junction) |
| C:\Program Files\Android | 3.2 GB | KEEP for now |
| C:\Program Files\Microsoft Power BI Desktop | 3.2 GB | KEEP for now |
| C:\Program Files\LLVM | 2.4 GB | KEEP for now |
**Actionable now: Backup (271 GB) + Unity condense (~15.5 GB) + Package Cache (4.5 GB) = ~291 GB**

VS Installer Package Cache: With 80%+ consistent internet, safe to clear. VS can re-download on repair/modify.
Worst case: ~30 min re-download on next VS modify. Run: `vs_installer.exe --clean` or delete `C:\ProgramData\Package Cache` manually.

## TIER 5: INFRASTRUCTURE FIXES (all approved)
| Fix | Command |
|-----|---------|
| nvm4w junction | `cmd /c "rmdir C:\nvm4w\nodejs" && mklink /J C:\nvm4w\nodejs C:\ProgramData\nvm\v24.14.0` |
| OneDrive UC orphan | `cmd /c "rmdir \"C:\Users\shelc\OneDrive - University of Cincinnati\""` |
| Kibana node shim | `ren "C:\ProgramData\chocolatey\bin\node.exe" "node.exe.bak"` |
| Scoop v0.5.3 commands | Update Inventory/Maintenance: `export`→`dump`, `list`→`search --installed`, `cleanup`→`cache rm` |
| Legacy History dir | `Move-Item "$env:USERPROFILE\Documents\Journal\Projects\SOK\History" "$env:USERPROFILE\Documents\Journal\Projects\SOK\Deprecated\History"` |

## D: RECOVERY (DMDE scan complete)
DMDE TreeMap: 206212 rows, 38997 unique items scanned 22Mar2026.
Top-level structure includes: C Backup 2, $Recycle.Bin, $SysReset, AMD drivers, OldOS.
This is a previous system image + backup data. Recovery target: move C:\Users\shelc\Documents\Backup here.
**Action: Mount D:, verify DMDE recoverable content, then robocopy Backup → D:\Backup**

## PROJECTED OUTCOME
| Phase | C: Free | % Free |
|-------|---------|--------|
| Current | 373 GB | 37.3% |
| Tier 1 (Maintenance) | 376 GB | 37.6% |
| Tier 2 (offload) | 384 GB | 38.4% |
| Tier 3 (stale offload) | 389 GB | 38.9% |
| Tier 4 (Unity + PkgCache) | 409 GB | 40.9% |
| Tier 4 (+ Backup move) | 680 GB | 68.1% |
