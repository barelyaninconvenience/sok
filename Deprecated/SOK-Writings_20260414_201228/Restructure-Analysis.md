# RESTRUCTURE ANALYSIS — Documents\Backup
# From SOK-Restructure_20260327_215718
# 123,909 directories scanned in 213.7s

## THE PROBLEM
271 GB in C:\Users\shelc\Documents\Backup is a backup-of-a-backup matryoshka:

```
Documents\Backup\
  └── C_\Users\shelc\Documents\Backup\
      └── 2020 Seagate 1 Backup\
          ├── Shelby\20211019 Desktop Backup\  (87,352 nested dirs)
          │   └── Users\Shelby\AppData\Local\...  (depth 30)
          └── Shelby\20210922 Laptop Backup\   (35,107 nested dirs)
              └── Users\shala\AppData\Local\...  (depth 30)
      └── 2020 Seagate 2 Backup\               (1,385 nested dirs)
```

120,199 directories exceed depth 13. Most are Eclipse .cp folders,
Jupyter MathJax fonts, and Anaconda package caches — all from the
2020/2021 laptop/desktop backups embedded inside the Seagate backup.

## STRUCTURE
- Root: `C:\Users\shelc\Documents\Backup`
- Layer 1: `C_\` (flattened drive letter from the Seagate backup tool)
- Layer 2: `Users\shelc\Documents\Backup\2020 Seagate * Backup`
- Layer 3: `Shelby\2021* Backup\Users\{shala,Shelby}\AppData\...`

This is a Seagate backup of a drive that CONTAINED previous backups.
The actual unique user data is buried under 4-5 layers of backup wrappers.

## RECOVERY PLAN
When D: or an empty NVMe is available:

1. **Robocopy the entire Backup folder** to external storage as-is (preserve structure)
   ```powershell
   robocopy "C:\Users\shelc\Documents\Backup" "E:\Backup_Archive" /E /MT:8 /XJ /R:1 /W:1
   ```

2. **Do NOT attempt to flatten or restructure** the backup in place.
   The nested Eclipse/Anaconda/MathJax directories are from old development
   environments. They have no current value but are harmless on external storage.

3. **After verified copy**, delete from C: to recover 271 GB.

4. **Unique data worth extracting** (before bulk archive):
   - Personal documents from `Users\Shelby\Documents` and `Users\shala\Documents`
   - Photos from `Users\*\Pictures`
   - Any project files from `Users\*\Desktop`
   - Browser bookmarks from `Users\*\AppData\Local\*\User Data\Default\Bookmarks`

## CONSOLE VERBOSITY
The error walls from PreSwap (60+ Remove-Item errors for locked files) exceed
PowerShell's default console buffer (9999 lines). Solutions:
1. `ErrorAction SilentlyContinue` on all Remove-Item calls (applied in Hotfix v4.3.2)
2. Redirect stderr: `2>$null` on robocopy and Remove-Item calls
3. Consider a `-Quiet` switch on PreSwap/RebootClean that suppresses per-file errors
   and only reports aggregate counts
