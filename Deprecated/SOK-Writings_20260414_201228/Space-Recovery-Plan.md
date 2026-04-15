# SPACE RECOVERY FOR D: INGESTION
# 28Mar2026 — Need ~100 GB to fit 648 GB TestDisk recovery

## CURRENT STATE
C: 589 GB free (38% used) — need 648 GB = 59 GB SHORT
E: 111 GB free (78% used) — raw backup tree consuming ~185 GB redundantly

## FASTEST PATH: Delete raw tree on E: → recover D: to E:

The .7z files passed integrity. The raw C_\ tree is 100% redundant.
Delete it → E: goes from 111 GB free to ~296 GB free.
Then recover D: to E:\D_Recovery\ (648 GB won't fit on E: alone though).

```powershell
# Free 185 GB on E:
Remove-Item 'E:\Backup_Archive\C_' -Recurse -Force
# E: now has ~296 GB free
```

## BUT: 648 GB doesn't fit anywhere single-drive
- C: 589 GB < 648 GB
- E: 296 GB (after cleanup) < 648 GB

## OPTIONS

### Option A: Free 59 GB on C: → recover all to C:
Quick wins on C: to bridge the gap:
```
Unity 6000.2.13f1 + .14f1  (keep .15f1 only):  14.8 GB
  → Uninstall via Unity Hub
Anaconda3 offload to E:                         ~11 GB
  → robocopy C:\ProgramData\anaconda3 E:\SOK_Offload\C_ProgramData_anaconda3 /E /MOVE /MT:8 /XJ
Docker Program Files                              4 GB
  → Offload or uninstall if using Podman
Downloads purge                                  0.8 GB
glasswire + USOShared (stale)                    0.6 GB
3P security remnants (after Remove-3PSecurity)   ~2 GB
VS Package Cache rebuild                         ~1 GB
Chrome/pip/npm caches (run Maintenance Quick)     ~2 GB
                                          TOTAL: ~37 GB
```
Still ~22 GB short. Would need Pictures (20 GB) or Videos (8.6 GB) offloaded.

### Option B: Split recovery across C: + E: (RECOMMENDED)
1. Delete E: raw tree → 296 GB free on E:
2. Recover first 296 GB of D: to E:\D_Recovery\
3. Recover remainder to C:\D_Recovery\
4. Or: recover selectively (skip system images, drivers)

### Option C: Selective recovery (MOST PRACTICAL)
The 648 GB on D: is mostly old system images. From DMDE:
- 36,470 directory entries (structure, no space)
- "C Backup 2", "OldOS" = old Windows installs
- AMD/PCI/SMBUS drivers = reinstallable
- $SysReset/$WinREAgent = Windows recovery (recreatable)

Actual personal data is probably <50 GB.
Recover ONLY personal data directories:
- Users\*\Documents
- Users\*\Desktop
- Users\*\Pictures
- Users\*\Downloads
- Any project directories you know were on D:

```powershell
# After TestDisk makes D: readable, selective copy:
robocopy 'D:\Users' 'E:\D_Recovery\Users' /E /MT:8 /XJ /R:1 /W:1 /XD AppData
robocopy 'D:\Projects' 'E:\D_Recovery\Projects' /E /MT:8 /XJ /R:1 /W:1
# Skip system dirs entirely
```

### Option D: Free E: AND C: → full recovery to E:
1. Delete E: raw tree: +185 GB on E:
2. Offload Unity old versions from C: to E:\SOK_Offload: saves 14.8 GB on C:
3. Offload Anaconda3: saves ~11 GB on C:
4. E: now has 296 - 26 = 270 GB free... still not 648 GB.

## RECOMMENDATION: Option B or C
Delete the E: raw tree regardless (it's verified redundant).
Then either split the recovery or be selective about what you pull from D:.
You said you know what's on D: — if it's mostly system images, selective
recovery of just personal data to E: will fit easily.
