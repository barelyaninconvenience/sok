
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        MASTER DEVELOPER ENVIRONMENT INSTALLATION             ║
║                                                              ║
║  This will install 200+ packages (~400GB storage)           ║
║  Estimated time: 6-10 hours                                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

[1/20] Foundation Layer - WSL, Terminals, Shell Enhancement
wsl: Using legacy distribution registration. Consider using a tar based distribution instead.
Downloading: Ubuntu 22.04 LTS
Ubuntu 22.04 LTS has been downloaded.
Distribution successfully installed. It can be launched via 'wsl.exe -d Ubuntu 22.04 LTS'
Launching Ubuntu 22.04 LTS...
Installing, this may take a few minutes...
Please create a default UNIX user account. The username does not need to match your Windows username.
For more information visit: https://aka.ms/wslusers
Enter new UNIX username: sccaddell
wsl: Failed to start the systemd user session for 'root'. See journalctl for more details.
New password:
Retype new password:
passwd: password updated successfully
Installation successful!
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 6.6.87.2-microsoft-standard-WSL2 x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Wed Nov 26 00:17:31 EST 2025

  System load:  0.32                Processes:             65
  Usage of /:   0.1% of 1006.85GB   Users logged in:       0
  Memory usage: 2%                  IPv4 address for eth0: 192.168.222.125
  Swap usage:   0%


This message is shown once a day. To disable it please create the
/home/sccaddell/.hushlogin file.
sccaddell@ClayPC:~$ ^C
sccaddell@ClayPC:~$ exit
logout
The installation process for distribution 'Ubuntu-22.04' failed with exit code: 130.
Error code: Wsl/WSL_E_INSTALL_PROCESS_FAILED
For information on key differences with WSL 2 please visit https://aka.ms/wsl2
The operation completed successfully.
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Updating Scoop...
Updating Buckets...
 * eabe07ba6f94 tinymist: Update to version 0.14.4                       main         49 minutes ago
 * 7e774a05fa81 slang: Update to version 2025.23.1                       main         49 minutes ago
 * 170840391017 mise: Update to version 2025.11.8                        main         49 minutes ago
 * 589b74a1dd39 metabase: Update to version 0.57.4                       main         49 minutes ago
 * e6a2b7c72d20 trid: Update to version 2.46-25.11.25                    main         5 hours ago
 * 908b1cadf3b0 ngrok: Update to version 3.33.1                          main         5 hours ago
 * a77653804a16 mysql-workbench: Update to version 8.0.45                main         5 hours ago
 * 07750111f0d2 marksman: Update to version 2025-11-25                   main         5 hours ago
 * a3087d6c0359 gitlab-runner: Update to version 18.6.2                  main         5 hours ago
 * 32e144bd1378 dolt: Update to version 1.78.4                           main         5 hours ago
 * 5836ed10f38a buf: Update to version 1.61.0                            main         5 hours ago
 * 04ce5b3959e2 yasb: Update to version 1.8.5                            extras       49 minutes ago
 * 306c0b54bf80 quickcpu: Update to version 6.0.0.0                      extras       49 minutes ago
 * 290ec9b33c03 cursor: Update to version 2.1.36                         extras       49 minutes ago
 * 10b0cf07a1e4 bitwarden: Update to version 2025.11.2                   extras       49 minutes ago
 * 05b28210e602 aimp@5.40.2700: Fix hash (Closes #16654)                 extras       4 hours ago
 * c0f9e8797253 psiphon3@186: Fix hash (Closes #16653)                   extras       5 hours ago
 * dd77363096f8 zed: Update to version 0.213.8                           extras       5 hours ago
 * 2361357f40a6 treesheets: Update to version 2779                       extras       5 hours ago
 * 769de9b74265 teamviewer: Update to version 15.72.3                    extras       5 hours ago
 * 14113fb1d3e3 teamviewer-qs: Update to version 15.72.3                 extras       5 hours ago
 * f8874b37e836 stirling-pdf: Update to version 2.0.0                    extras       5 hours ago
 * 08fbfaa2f338 opencode: Update to version 1.0.114                      extras       5 hours ago
 * 45500450ea5f mpv-git: Update to version 20251126                      extras       5 hours ago
 * f5a5bab766f2 zig-dev: Update to version 0.16.0-dev.1470               versions     35 minutes ago
 * 03ca7f60cd74 vlc-nightly: Update to version 20251126                  versions     35 minutes ago
 * 50496b1d5638 vlc-nightly-ucrt-llvm: Update to version 20251126        versions     35 minutes ago
 * b3bc0590ff65 swift-nightly: Update to version 20251125.3              versions     35 minutes ago
 * 0402478aa287 stash-dev: Update to version 0.29.3-62-ga8bb9ae4         versions     35 minutes ago
 * b287ef003405 oss-cad-suite-nightly: Update to version 2025-11-26      versions     35 minutes ago
 * 7a312d20bd69 freecad-weekly: Update to version 2025.11.26             versions     35 minutes ago
 * 6ba071bbf6f4 dbeaver-ea: Update to version 25.3.1-2025-11-26          versions     35 minutes ago
 * cc1cac3185b8 cursor-latest: Update to version 2.1.36                  versions     35 minutes ago
 * cf4a72c04f18 cmake-nightly: Update to version 4.2.20251125            versions     35 minutes ago
 * ee2a7e42dcf0 chromium-dev: Update to version 144.0.7547.0-r1550184    versions     35 minutes ago
 * 0a45a877dab1 brave-nightly: Update to version 1.87.14                 versions     35 minutes ago
 * f7357de26214 beef-nightly: Update to version 0.43.6.11252025          versions     35 minutes ago
 * 5657a92ee31e yazi-nightly: Update to version a1fb206                  versions     3 hours ago
 * 7a49931bc928 xournalpp-nightly: Update to version 1.2.8-20251126      versions     3 hours ago
 * 9bb7f3c8b474 vim-nightly: Update to version 9.1.1927                  versions     3 hours ago
 * d289516503eb systeminformer-nightly: Update to version 3.2.25330.121  versions     3 hours ago
 * aba04299e66d stash-dev: Update to version 0.29.3-60-gd14053b5         versions     3 hours ago
 * f26398c3c07a sqlitebrowser-nightly: Update to version 20251126        versions     3 hours ago
 * f4d53ce10d4e sharex-dev: Update to version 18.0.2.726                 versions     3 hours ago
 * 4fd971caea92 rustdesk-nightly: Update to version 1764118331           versions     3 hours ago
 * 69144a7cc15e ruffle-nightly: Update to version 2025-11-26             versions     3 hours ago
 * f271f5f02a95 micro-nightly: Update to version nightly-2025-11-26      versions     3 hours ago
 * b520aac67f5e kdeconnect-nightly: Update to version 5560               versions     3 hours ago
 * 688d1ec0498f firefox-nightly: Update to version 147.0a1.20251125204.. versions     3 hours ago
 * 7d94c9250c73 chromium-dev: Update to version 144.0.7547.0-r1550095    versions     3 hours ago
 * a2f62648f413 bottom-nightly: Update to version 19688451701            versions     3 hours ago
Scoop was updated successfully!
WARN  'starship' (1.24.1) is already installed.
Use 'scoop update starship' to install a new version.
Found PowerShell [Microsoft.PowerShell] Version 7.5.4.0
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Downloading https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/PowerShell-7.5.4-win-x64.msi
  ██████████████████████████████   107 MB /  107 MB
Successfully verified installer hash
Starting package install...
Successfully installed

[2/20] Version Control & Collaboration Tools
Chocolatey v2.5.1
Installing the following packages:
git
By installing, you accept licenses for the packages.
git v2.52.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - git - git v2.52.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
WARN  'lazygit' (0.56.0) is already installed.
Use 'scoop update lazygit' to install a new version.
Chocolatey v2.5.1
Installing the following packages:
gitkraken
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading gitkraken 11.6.0... 100%

gitkraken v11.6.0 [Approved]
gitkraken package files install completed. Performing other installation steps.
Downloading gitkraken 64 bit
  from 'https://api.gitkraken.dev/releases/production/windows/x64/active/GitKrakenSetup.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\gitkraken\11.6.0\GitKrakenSetup.exe (375.69 MB).
Download of GitKrakenSetup.exe (375.69 MB) completed.
Hashes match.
Installing gitkraken...
gitkraken has been installed.
 The install of gitkraken was successful.
  Software installed as 'exe', install location is likely default.

Chocolatey installed 1/1 packages.                                                                                                                            See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).                                                                                    Git LFS initialized.                                                                                                                                                                                                                                                                                                      [3/20] IDEs & Code Editors (This will take a while...)
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Chocolatey v2.5.1
Installing the following packages:
jetbrainstoolbox
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading jetbrainstoolbox 3.1.0.62320... 100%

jetbrainstoolbox v3.1.0.62320 [Approved]
jetbrainstoolbox package files install completed. Performing other installation steps.
Downloading jetbrainstoolbox
  from 'https://download.jetbrains.com/toolbox/jetbrains-toolbox-3.1.0.62320.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\jetbrainstoolbox\3.1.0.62320\jetbrains-toolbox-3.1.0.62320.exe (125.08 MB).
Download of jetbrains-toolbox-3.1.0.62320.exe (125.08 MB) completed.
Hashes match.
Installing jetbrainstoolbox...
jetbrainstoolbox has been installed.
  jetbrainstoolbox may be able to be automatically uninstalled.
 The install of jetbrainstoolbox was successful.
  Software installed as 'exe', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
WARN  'neovim' (0.11.5) is already installed.
Use 'scoop update neovim' to install a new version.
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Chocolatey v2.5.1
Installing the following packages:
sublimetext4
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading sublimetext4 4.0.0.420000... 100%

sublimetext4 v4.0.0.420000 [Approved]
sublimetext4 package files install completed. Performing other installation steps.
Downloading sublimetext4
  from 'https://download.sublimetext.com/sublime_text_build_4200_x64_setup.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\sublimetext4\4.0.0.420000\sublime_text_build_4200_x64_setup.exe (15.45 MB).
Download of sublime_text_build_4200_x64_setup.exe (15.45 MB) completed.
Hashes match.
Installing sublimetext4...
sublimetext4 has been installed.
Added C:\ProgramData\chocolatey\bin\subl.exe shim pointed to 'c:\program files\sublime text\subl.exe'.
  sublimetext4 can be automatically uninstalled.
 The install of sublimetext4 was successful.
  Deployed to 'C:\Program Files\Sublime Text\'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

[4/20] Programming Language Runtimes
Chocolatey v2.5.1
Installing the following packages:
nodejs-lts
By installing, you accept licenses for the packages.
nodejs-lts v24.11.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - nodejs-lts - nodejs-lts v24.11.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
nvm
By installing, you accept licenses for the packages.
nvm v1.2.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - nvm - nvm v1.2.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Python management via pyenv-win...
pyenv-win 3.1.1 installed.
No updates available.
Chocolatey v2.5.1
Installing the following packages:
temurin17;temurin21
By installing, you accept licenses for the packages.
Temurin17 v17.0.17.10 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading Temurin21 21.0.9.10... 100%

Temurin21 v21.0.9.10 [Approved]
Temurin21 package files install completed. Performing other installation steps.
Downloading Temurin21 64 bit
  from 'https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.9%2B10/OpenJDK21U-jdk_x64_windows_hotspot_21.0.9_10.msi'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\Temurin21\21.0.9.10\OpenJDK21U-jdk_x64_windows_hotspot_21.0.9_10.msi (170.95 MB).
Download of OpenJDK21U-jdk_x64_windows_hotspot_21.0.9_10.msi (170.95 MB) completed.
Hashes match.
Installing Temurin21...
Temurin21 has been installed.
  Temurin21 may be able to be automatically uninstalled.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of Temurin21 was successful.
  Deployed to 'C:\Program Files\Eclipse Adoptium\jdk-21.0.9.10-hotspot\'

Chocolatey installed 1/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - Temurin17 - Temurin17 v17.0.17.10 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
golang
By installing, you accept licenses for the packages.
golang v1.25.4 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - golang - golang v1.25.4 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Found Microsoft .NET SDK 7.0 [Microsoft.DotNet.SDK.7] Version 7.0.410
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Downloading https://builds.dotnet.microsoft.com/dotnet/Sdk/7.0.410/dotnet-sdk-7.0.410-win-x64.exe
  ██████████████████████████████   218 MB /  218 MB
Successfully verified installer hash
Starting package install...
Successfully installed
Chocolatey v2.5.1
Installing the following packages:
ruby
By installing, you accept licenses for the packages.
ruby v3.4.7.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - ruby - ruby v3.4.7.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Successfully installed bundler-2.7.2
1 gem installed

A new release of RubyGems is available: 3.6.9 → 3.7.2!
Run `gem update --system 3.7.2` to update your installation.

Chocolatey v2.5.1
Installing the following packages:
php;composer
By installing, you accept licenses for the packages.
php v8.5.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
composer v6.3.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - composer - composer v6.3.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - php - php v8.5.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
strawberryperl
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading StrawberryPerl 5.42.0.1... 100%

strawberryperl v5.42.0.1 [Approved]
strawberryperl package files install completed. Performing other installation steps.
Downloading strawberryperl 64 bit
  from 'https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54201_64bit/strawberry-perl-5.42.0.1-64bit.msi'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\StrawberryPerl\5.42.0.1\strawberry-perl-5.42.0.1-64bit.msi (198.4 MB).
Download of strawberry-perl-5.42.0.1-64bit.msi (198.4 MB) completed.
Hashes match.
Installing strawberryperl...
strawberryperl has been installed.
  strawberryperl may be able to be automatically uninstalled.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of strawberryperl was successful.
  Deployed to 'C:\Strawberry\'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
lua
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading vcredist2005 8.0.50727.619501... 100%

vcredist2005 v8.0.50727.619501 [Approved]
vcredist2005 package files install completed. Performing other installation steps.
Downloading vcredist2005 64 bit
  from 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\vcredist2005\8.0.50727.619501\vcredist_x64.EXE (3.03 MB).
Download of vcredist_x64.EXE (3.03 MB) completed.
Hashes match.
Installing vcredist2005...
vcredist2005 has been installed.
Downloading vcredist2005 32 bit
  from 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\vcredist2005\8.0.50727.619501\vcredist_x86.EXE (2.58 MB).
Download of vcredist_x86.EXE (2.58 MB) completed.
Hashes match.
Installing vcredist2005...
vcredist2005 has been installed.
  vcredist2005 may be able to be automatically uninstalled.
 The install of vcredist2005 was successful.
  Software installed as 'exe', install location is likely default.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading Lua 5.1.5.52... 100%

lua v5.1.5.52 [Approved]
lua package files install completed. Performing other installation steps.
Downloading lua
  from 'https://github.com/rjpcomputing/luaforwindows/releases/download/v5.1.5-52/LuaForWindows_v5.1.5-52.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\Lua\5.1.5.52\LuaForWindows_v5.1.5-52.exe (27.8 MB).
Download of LuaForWindows_v5.1.5-52.exe (27.8 MB) completed.
Hashes match.
Installing lua...
lua has been installed.
  lua can be automatically uninstalled.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of lua was successful.
  Deployed to 'C:\Program Files (x86)\Lua\5.1\'

Chocolatey installed 2/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
scala
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading scala 3.7.4... 100%

scala v3.7.4 [Approved]
scala package files install completed. Performing other installation steps.
Downloading scala 64 bit
  from 'https://github.com/scala/scala3/releases/download/3.7.4/scala3-3.7.4-x86_64-pc-win32.zip'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32.zip (74.07 MB).
Download of scala3-3.7.4-x86_64-pc-win32.zip (74.07 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\chocolatey\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32.zip to C:\ProgramData\chocolatey\lib\scala\tools\scala\3.7.4...
C:\ProgramData\chocolatey\lib\scala\tools\scala\3.7.4
Creating shims for .bat file from C:\ProgramData\chocolatey\lib\scala\tools\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32\bin
Creating shim for C:\ProgramData\chocolatey\lib\scala\tools\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32\bin\scala.bat...
Added C:\ProgramData\chocolatey\bin\scala.exe shim pointed to '..\lib\scala\tools\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32\bin\scala.bat'.
Creating shim for C:\ProgramData\chocolatey\lib\scala\tools\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32\bin\scalac.bat...
Added C:\ProgramData\chocolatey\bin\scalac.exe shim pointed to '..\lib\scala\tools\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32\bin\scalac.bat'.
Creating shim for C:\ProgramData\chocolatey\lib\scala\tools\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32\bin\scaladoc.bat...
Added C:\ProgramData\chocolatey\bin\scaladoc.exe shim pointed to '..\lib\scala\tools\scala\3.7.4\scala3-3.7.4-x86_64-pc-win32\bin\scaladoc.bat'.
 ShimGen has successfully created a shim for scala-cli.exe
 The install of scala was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\scala\tools\scala\3.7.4'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
kotlin
By installing, you accept licenses for the packages.
kotlin not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - kotlin - kotlin not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.
Chocolatey v2.5.1
Installing the following packages:
dart-sdk
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading dart-sdk 3.10.1... 100%

dart-sdk v3.10.1 [Approved]
dart-sdk package files install completed. Performing other installation steps.
PATH environment variable does not have C:\tools\dart-sdk\bin in it. Adding...
PATH environment variable does not have C:\Users\shelc\AppData\Local\Pub\Cache\bin in it. Adding...
Downloading dart-sdk 64 bit
  from 'https://storage.googleapis.com/dart-archive/channels/stable/release/3.10.1/sdk/dartsdk-windows-x64-release.zip'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\dart-sdk\3.10.1\dartsdk-windows-x64-release.zip (195.87 MB).
Download of dartsdk-windows-x64-release.zip (195.87 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\dart-sdk\3.10.1\dartsdk-windows-x64-release.zip to C:\tools...
C:\tools
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of dart-sdk was successful.
  Deployed to 'C:\tools'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
erlang;elixir
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading erlang 28.1.1... 100%

erlang v28.1.1 [Approved]
erlang package files install completed. Performing other installation steps.
Downloading erlang 64 bit
  from 'https://github.com/erlang/otp/releases/download/OTP-28.1.1/otp_win64_28.1.1.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\erlang\28.1.1\otp_win64_28.1.1.exe (141.44 MB).
Download of otp_win64_28.1.1.exe (141.44 MB) completed.
Hashes match.
Installing erlang...
erlang has been installed.
Added C:\ProgramData\chocolatey\bin\ct_run.exe shim pointed to 'c:\program files\erlang otp\erts-16.1.1\bin\ct_run.exe'.
Added C:\ProgramData\chocolatey\bin\erl.exe shim pointed to 'c:\program files\erlang otp\erts-16.1.1\bin\erl.exe'.
Added C:\ProgramData\chocolatey\bin\werl.exe shim pointed to 'c:\program files\erlang otp\erts-16.1.1\bin\werl.exe'.
Added C:\ProgramData\chocolatey\bin\erlc.exe shim pointed to 'c:\program files\erlang otp\erts-16.1.1\bin\erlc.exe'.
Added C:\ProgramData\chocolatey\bin\escript.exe shim pointed to 'c:\program files\erlang otp\erts-16.1.1\bin\escript.exe'.
Added C:\ProgramData\chocolatey\bin\dialyzer.exe shim pointed to 'c:\program files\erlang otp\erts-16.1.1\bin\dialyzer.exe'.
Added C:\ProgramData\chocolatey\bin\typer.exe shim pointed to 'c:\program files\erlang otp\erts-16.1.1\bin\typer.exe'.
  erlang may be able to be automatically uninstalled.
 The install of erlang was successful.
  Software installed as 'exe', install location is likely default.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading Elixir 1.19.3... 100%

elixir v1.19.3 [Approved]
elixir package files install completed. Performing other installation steps.
Downloading elixir
  from 'https://github.com/elixir-lang/elixir/releases/download/v1.19.3/elixir-otp-28.zip'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\Elixir\1.19.3\elixir-otp-28.zip (7.86 MB).
Download of elixir-otp-28.zip (7.86 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\chocolatey\Elixir\1.19.3\elixir-otp-28.zip to C:\ProgramData\chocolatey\lib\Elixir\tools...
C:\ProgramData\chocolatey\lib\Elixir\tools
------------------------------------------------------------------------
NOTE:

The Elixir commands have been installed to:

C:\ProgramData\chocolatey\lib\Elixir\tools\bin

Please add this directory to your PATH,
then your shell session to access these commands:

elixir
elixirc
mix
iex
------------------------------------------------------------------------
 The install of elixir was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\Elixir\tools'

Chocolatey installed 2/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
haskell-dev
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading cabal 3.10.2.0... 100%

cabal v3.10.2 [Approved]
cabal package files install completed. Performing other installation steps.
Downloading cabal 64 bit
  from 'https://downloads.haskell.org/cabal/cabal-install-3.10.2.0/cabal-install-3.10.2.0-x86_64-windows.zip'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\cabal\3.10.2\cabal-install-3.10.2.0-x86_64-windows.zip (14.93 MB).
Download of cabal-install-3.10.2.0-x86_64-windows.zip (14.93 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\chocolatey\cabal\3.10.2\cabal-install-3.10.2.0-x86_64-windows.zip to C:\ProgramData\chocolatey\lib\cabal\tools\cabal-3.10.2.0...
C:\ProgramData\chocolatey\lib\cabal\tools\cabal-3.10.2.0
Standalone msys2 detected. Using default paths.
Could not read cabal configuration key 'install-method'.
Updated cabal configuration.
PATH environment variable does not have C:\Users\shelc\AppData\Roaming\cabal\bin in it. Adding...
Finding cabal config file...
Detected config file: 'C:\Users\shelc\AppData\Roaming\cabal\config'.
Forcibly correct backwards incompatible cabal configurations.
Standalone msys2 detected. Using default paths.
Adding C:\ProgramData\chocolatey\bin\mingw64-pkg.bat and pointing it to powershell command C:\ProgramData\chocolatey\lib\cabal\tools\mingw64-pkg.ps1
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 ShimGen has successfully created a shim for cabal.exe
 The install of cabal was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\cabal\tools\cabal-3.10.2.0'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading ghc 9.8.2... 100%

ghc v9.8.2 [Approved] - Possibly broken
ghc package files install completed. Performing other installation steps.
Downloading ghc 64 bit
  from 'https://downloads.haskell.org/~ghc/9.8.2/ghc-9.8.2-x86_64-unknown-mingw32.tar.xz'
Progress: 100% - Completed download of C:\tools\ghc-9.8.2\tmp\ghcInstall (309.95 MB).
Download of ghcInstall (309.95 MB) completed.
Hashes match.
C:\tools\ghc-9.8.2\tmp\ghcInstall
Extracting C:\tools\ghc-9.8.2\tmp\ghcInstall to C:\tools...
C:\tools
Extracting C:\tools\ghcInstall~ to C:\tools...
C:\tools
Renamed C:\tools\ghc-9.8.2-x86_64-unknown-mingw32 to C:\tools\ghc-9.8.2
PATH environment variable does not have C:\tools\ghc-9.8.2\bin in it. Adding...
Hiding shims for 'C:\tools'.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of ghc was successful.
  Deployed to 'C:\tools'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading msys2 20250830.0.0... 100%

msys2 v20250830.0.0 [Approved]
msys2 package files install completed. Performing other installation steps.
Installing to: C:\tools\msys64
Extracting 64-bit C:\ProgramData\chocolatey\lib\msys2\tools\msys2-base-x86_64-20250830.tar.xz to C:\tools\msys64...
C:\tools\msys64
Extracting C:\tools\msys64\msys2-base-x86_64-20250830.tar to C:\tools\msys64...
C:\tools\msys64
Invoking first run to setup things like bash profile, gpg etc...
Invoking msys2 shell command: -defterm -no-start -c "ps -ef | grep '[?]' | awk '{print $2}' | xargs -r kill"
MSYS2 is starting for the first time. Executing the initial setup.
Copying skeleton files.
These files are for the users to personalise their msys2 experience.

They will never be overwritten nor automatically updated.

'./.bashrc' -> '/home/shelc/.bashrc'
'./.bash_profile' -> '/home/shelc/.bash_profile'
'./.profile' -> '/home/shelc/.profile'
'C:\WINDOWS\system32\drivers\etc\hosts' -> '/etc/hosts'
'C:\WINDOWS\system32\drivers\etc\protocol' -> '/etc/protocols'
'C:\WINDOWS\system32\drivers\etc\services' -> '/etc/services'
'C:\WINDOWS\system32\drivers\etc\networks' -> '/etc/networks'
gpg: /etc/pacman.d/gnupg/trustdb.gpg: trustdb created
gpg: no ultimately trusted keys found
gpg: starting migration from earlier GnuPG versions
gpg: porting secret keys from '/etc/pacman.d/gnupg/secring.gpg' to gpg-agent
gpg: migration succeeded
==> Generating pacman master key. This may take some time.
gpg: Generating pacman keyring master key...
gpg: directory '/etc/pacman.d/gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/etc/pacman.d/gnupg/openpgp-revocs.d/1F3664F0452C5BAFCDFFBD3D4D7FBE9C04683DD1.rev'
gpg: Done
==> Updating trust database...
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
==> Appending keys from msys2.gpg...
==> Locally signing trusted keys in keyring...
  -> Locally signed 5 keys.
==> Importing owner trust values...
gpg: setting ownertrust to 4
gpg: setting ownertrust to 4
gpg: setting ownertrust to 4
gpg: setting ownertrust to 4
gpg: setting ownertrust to 4
==> Disabling revoked keys in keyring...
  -> Disabled 4 keys.
==> Updating trust database...
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   5  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: depth: 1  valid:   5  signed:   7  trust: 0-, 0q, 0n, 5m, 0f, 0u
gpg: depth: 2  valid:   4  signed:   2  trust: 4-, 0q, 0n, 0m, 0f, 0u
gpg: next trustdb check due at 2025-12-16
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key F40D263ECA25678A: "Alexey Pavlov (Alexpux) <alexey.pawlow@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key 790AE56A1D3CFDDC: "David Macek (MSYS2 master key) <david.macek.0@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key DA7EF2ABAEEA755C: "Martell Malone (martell) <martellmalone@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key 755B8182ACD22879: "Christoph Reiter (MSYS2 master key) <reiter.christoph@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key 9F418C233E652008: "Ignacio Casal Quinteiro <icquinteiro@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key BBE514E53E0D0813: "Ray Donnelly (MSYS2 Developer - master key) <mingw.android@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key 5F92EFC1A47D45A1: "Alexey Pavlov (Alexpux) <alexpux@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key 974C8BE49078F532: "David Macek <david.macek.0@gmail.com>" 3 new signatures
gpg: key 974C8BE49078F532: "David Macek <david.macek.0@gmail.com>" 1 signature cleaned
gpg: Total number processed: 1
gpg:         new signatures: 3
gpg:     signatures cleaned: 1
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   1  signed:   5  trust: 0-, 0q, 0n, 0m, 0f, 1u
gpg: depth: 1  valid:   5  signed:   7  trust: 0-, 0q, 0n, 5m, 0f, 0u
gpg: depth: 2  valid:   4  signed:   2  trust: 4-, 0q, 0n, 0m, 0f, 0u
gpg: next trustdb check due at 2026-04-10
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key FA11531AA0AA7F57: "Christoph Reiter (MSYS2 development key) <reiter.christoph@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key 794DCF97F93FC717: "Martell Malone (martell) <me@martellmalone.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key D595C9AB2C51581E: "Martell Malone (MSYS2 Developer) <martellmalone@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
gpg: refreshing 1 key from hkps://keyserver.ubuntu.com
gpg: key 4DF3B7664CA56930: "Ray Donnelly (MSYS2 Developer) <mingw.android@gmail.com>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
Initial setup complete. MSYS2 is now ready to use.
kill: 1298: No such process
Repeating system update until there are no more updates or max 5 iterations
Output is recorded in: C:\tools\msys64\update.log

================= SYSTEM UPDATE 1 =================

Invoking msys2 shell command: -defterm -no-start -c "pacman --noconfirm -Syuu --disable-download-timeout | tee -a /update.log; ps -ef | grep '[?]' | awk '{print $2}' | xargs -r kill"
:: Synchronizing package databases...
 clangarm64 downloading...
 mingw32 downloading...
 mingw64 downloading...
 ucrt64 downloading...
 clang64 downloading...
 msys downloading...
:: Starting core system upgrade...
warning: terminate other MSYS2 programs before proceeding
resolving dependencies...
looking for conflicting packages...

Packages (3) mintty-1~3.8.1-1  msys2-runtime-3.6.5-1  pacman-6.1.0-20

Total Download Size:    8.61 MiB
Total Installed Size:  45.78 MiB
Net Upgrade Size:      -7.30 MiB

:: Proceed with installation? [Y/n]
:: Retrieving packages...
 pacman-6.1.0-20-x86_64 downloading...
 msys2-runtime-3.6.5-1-x86_64 downloading...
 mintty-1~3.8.1-1-x86_64 downloading...
checking keyring...
checking package integrity...
loading package files...
checking for file conflicts...
checking available disk space...
:: Processing package changes...
upgrading mintty...
upgrading msys2-runtime...
upgrading pacman...
:: To complete this update all MSYS2 processes including this terminal will be closed. Confirm to proceed [Y/n]
================= SYSTEM UPDATE 2 =================

Invoking msys2 shell command: -defterm -no-start -c "pacman --noconfirm -Syuu --disable-download-timeout | tee -a /update.log; ps -ef | grep '[?]' | awk '{print $2}' | xargs -r kill"
:: Synchronizing package databases...
 clangarm64 downloading...
 mingw32 downloading...
 mingw64 downloading...
 ucrt64 downloading...
 clang64 downloading...
 msys downloading...
:: Starting core system upgrade...
 there is nothing to do
:: Starting full system upgrade...
resolving dependencies...
looking for conflicting packages...

Packages (23) bash-completion-2.17.0-2  brotli-1.2.0-1  bsdtar-3.8.3-1  curl-8.17.0-1  less-685-1  libcurl-8.17.0-1  libexpat-2.7.3-1  libffi-3.5.2-1  libgnutls-3.8.11-1  libgpg-error-1.56-1  libnghttp2-1.68.0-1  libnghttp3-1.13.1-1  libngtcp2-1.18.0-1  libopenssl-3.6.0-1  libp11-kit-0.25.10-1  libpcre2_8-10.47-1  libsqlite-3.51.0-1  libxcrypt-4.5.2-1  msys2-keyring-1~20251012-1  nano-8.7-1  openssl-3.6.0-1  p11-kit-0.25.10-1  tar-1.35-3

Total Download Size:    9.95 MiB
Total Installed Size:  31.33 MiB
Net Upgrade Size:       0.57 MiB

:: Proceed with installation? [Y/n]
:: Retrieving packages...
 libopenssl-3.6.0-1-x86_64 downloading...
 libgnutls-3.8.11-1-x86_64 downloading...
 curl-8.17.0-1-x86_64 downloading...
 tar-1.35-3-x86_64 downloading...
 libsqlite-3.51.0-1-x86_64 downloading...
 openssl-3.6.0-1-x86_64 downloading...
 nano-8.7-1-x86_64 downloading...
 p11-kit-0.25.10-1-x86_64 downloading...
 brotli-1.2.0-1-x86_64 downloading...
 libcurl-8.17.0-1-x86_64 downloading...
 bsdtar-3.8.3-1-x86_64 downloading...
 libp11-kit-0.25.10-1-x86_64 downloading...
 bash-completion-2.17.0-2-any downloading...
 libgpg-error-1.56-1-x86_64 downloading...
 libngtcp2-1.18.0-1-x86_64 downloading...
 libpcre2_8-10.47-1-x86_64 downloading...
 less-685-1-x86_64 downloading...
 libxcrypt-4.5.2-1-x86_64 downloading...
 libnghttp3-1.13.1-1-x86_64 downloading...
 libnghttp2-1.68.0-1-x86_64 downloading...
 libexpat-2.7.3-1-x86_64 downloading...
 msys2-keyring-1~20251012-1-any downloading...
 libffi-3.5.2-1-x86_64 downloading...
checking keyring...
checking package integrity...
loading package files...
checking for file conflicts...
checking available disk space...
:: Processing package changes...
upgrading bash-completion...
upgrading brotli...
upgrading libexpat...
upgrading libopenssl...
upgrading bsdtar...
upgrading libnghttp3...
upgrading libngtcp2...
upgrading libnghttp2...
upgrading openssl...
upgrading libffi...
upgrading libxcrypt...
upgrading libpcre2_8...
upgrading less...
upgrading libp11-kit...
upgrading p11-kit...
upgrading libcurl...
upgrading curl...
upgrading libgnutls...
upgrading libgpg-error...
upgrading libsqlite...
upgrading msys2-keyring...
==> Appending keys from msys2.gpg...
==> Updating trust database...
gpg: next trustdb check due at 2026-04-10
upgrading nano...
upgrading tar...
:: Running post-transaction hooks...
(1/1) Updating the info directory file...
kill: 324: No such process

================= SYSTEM UPDATE 3 =================

Invoking msys2 shell command: -defterm -no-start -c "pacman --noconfirm -Syuu --disable-download-timeout | tee -a /update.log; ps -ef | grep '[?]' | awk '{print $2}' | xargs -r kill"
:: Synchronizing package databases...
 clangarm64 downloading...
 mingw32 downloading...
 mingw64 downloading...
 ucrt64 downloading...
 clang64 downloading...
 msys downloading...
:: Starting core system upgrade...
 there is nothing to do
:: Starting full system upgrade...
 there is nothing to do
kill: 294: No such process
PATH environment variable does not have C:\tools\msys64 in it. Adding...
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of msys2 was successful.
  Deployed to 'C:\tools\msys64'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading haskell-dev 0.0.1... 100%

haskell-dev v0.0.1 [Approved] - Possibly broken
haskell-dev package files install completed. Performing other installation steps.
 The install of haskell-dev was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\haskell-dev'

Chocolatey installed 4/4 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
julia
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading Julia 1.12.0... 100%

julia v1.12.0 [Approved]
julia package files install completed. Performing other installation steps.
Installing 64-bit Julia...
Julia has been installed.
Julia installed to 'C:\Users\shelc\AppData\Local\Programs\Julia-1.12.0\bin\julia.exe'
Added C:\ProgramData\chocolatey\bin\julia.exe shim pointed to 'c:\users\shelc\appdata\local\programs\julia-1.12.0\bin\julia.exe'.
  julia can be automatically uninstalled.
 The install of julia was successful.
  Deployed to 'C:\Users\shelc\AppData\Local\Programs\Julia-1.12.0\'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

[5/20] Node.js Global Packages

changed 10 packages in 15s

16 packages are looking for funding
  run `npm fund` for details

changed 2 packages in 9s

1 package is looking for funding
  run `npm fund` for details

changed 20 packages in 2s
npm warn EBADENGINE Unsupported engine {
npm warn EBADENGINE   package: '@achrinza/node-ipc@9.2.9',
npm warn EBADENGINE   required: {
npm warn EBADENGINE     node: '8 || 9 || 10 || 11 || 12 || 13 || 14 || 15 || 16 || 17 || 18 || 19 || 20 || 21 || 22'
npm warn EBADENGINE   },
npm warn EBADENGINE   current: { node: 'v24.11.1', npm: '11.6.4' }
npm warn EBADENGINE }
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated fstream-ignore@1.0.5: This package is no longer supported.
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated @babel/plugin-proposal-class-properties@7.18.6: This proposal has been merged to the ECMAScript standard and thus this plugin is no longer maintained. Please use @babel/plugin-transform-class-properties instead.
npm warn deprecated @babel/plugin-proposal-nullish-coalescing-operator@7.18.6: This proposal has been merged to the ECMAScript standard and thus this plugin is no longer maintained. Please use @babel/plugin-transform-nullish-coalescing-operator instead.
npm warn deprecated source-map-url@0.4.1: See https://github.com/lydell/source-map-url#deprecated
npm warn deprecated uid-number@0.0.6: This package is no longer supported.
npm warn deprecated rimraf@2.6.3: Rimraf versions prior to v4 are no longer supported
npm warn deprecated rimraf@2.7.1: Rimraf versions prior to v4 are no longer supported
npm warn deprecated @babel/plugin-proposal-optional-chaining@7.21.0: This proposal has been merged to the ECMAScript standard and thus this plugin is no longer maintained. Please use @babel/plugin-transform-optional-chaining instead.
npm warn deprecated urix@0.1.0: Please see https://github.com/lydell/urix#deprecated
npm warn deprecated rimraf@3.0.2: Rimraf versions prior to v4 are no longer supported
npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported
npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported
npm warn deprecated apollo-datasource@3.3.2: The `apollo-datasource` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated resolve-url@0.2.1: https://github.com/lydell/resolve-url#deprecated
npm warn deprecated apollo-server-errors@3.3.1: The `apollo-server-errors` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated source-map-resolve@0.5.3: See https://github.com/lydell/source-map-resolve#deprecated
npm warn deprecated apollo-server-plugin-base@3.7.2: The `apollo-server-plugin-base` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated apollo-server-types@3.8.0: The `apollo-server-types` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated apollo-server-express@3.13.0: The `apollo-server-express` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated apollo-reporting-protobuf@3.4.0: The `apollo-reporting-protobuf` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/usage-reporting-protobuf` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated apollo-server-env@4.2.1: The `apollo-server-env` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/utils.fetcher` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated fstream@1.0.12: This package is no longer supported.
npm warn deprecated subscriptions-transport-ws@0.11.0: The `subscriptions-transport-ws` package is no longer maintained. We recommend you use `graphql-ws` instead. For help migrating Apollo software to `graphql-ws`, see https://www.apollographql.com/docs/apollo-server/data/subscriptions/#switching-from-subscriptions-transport-ws    For general help using `graphql-ws`, see https://github.com/enisdenjo/graphql-ws/blob/master/README.md
npm warn deprecated tar@2.2.2: This version of tar is no longer supported, and will not receive security updates. Please upgrade asap.
npm warn deprecated apollo-server-core@3.13.0: The `apollo-server-core` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated vue@2.7.16: Vue 2 has reached EOL and is no longer actively maintained. See https://v2.vuejs.org/eol/ for more details.

changed 1222 packages in 35s

138 packages are looking for funding
  run `npm fund` for details
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated source-map-url@0.4.1: See https://github.com/lydell/source-map-url#deprecated
npm warn deprecated rimraf@2.7.1: Rimraf versions prior to v4 are no longer supported
npm warn deprecated urix@0.1.0: Please see https://github.com/lydell/urix#deprecated
npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported
npm warn deprecated request-promise-native@1.0.9: request-promise-native has been deprecated because it extends the now deprecated request package, see https://github.com/request/request/issues/3142
npm warn deprecated stable@0.1.8: Modern JS already guarantees Array#sort() is a stable sort, so this library is deprecated. See the compatibility table on MDN: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/sort#browser_compatibility
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated resolve-url@0.2.1: https://github.com/lydell/resolve-url#deprecated
npm warn deprecated source-map-resolve@0.5.3: See https://github.com/lydell/source-map-resolve#deprecated
npm warn deprecated abab@2.0.6: Use your platform's native atob() and btoa() methods instead
npm warn deprecated q@1.5.1: You or someone you depend on is using Q, the JavaScript Promise library that gave JavaScript developers strong feelings about promises. They can almost certainly migrate to the native JavaScript promise now. Thank you literally everyone for joining me in this bet against the odds. Be excellent to each other.
npm warn deprecated
npm warn deprecated (For a CapTP with native promises, see @endo/eventual-send and @endo/captp)
npm warn deprecated lodash.clone@4.5.0: This package is deprecated. Use structuredClone instead.
npm warn deprecated domexception@1.0.1: Use your platform's native DOMException instead
npm warn deprecated w3c-hr-time@1.0.2: Use your platform's native performance.now() and performance.timeOrigin.
npm warn deprecated uuid@3.4.0: Please upgrade  to version 7 or higher.  Older versions may use Math.random() in certain circumstances, which is known to be problematic.  See https://v8.dev/blog/math-random for details.
npm warn deprecated request@2.88.2: request has been deprecated, see https://github.com/request/request/issues/3142
npm warn deprecated svgo@1.3.2: This SVGO version is no longer supported. Upgrade to v2.x.x.
npm warn deprecated parcel-bundler@1.12.5: Parcel v1 is no longer maintained. Please migrate to v2, which is published under the 'parcel' package. See https://v2.parceljs.org/getting-started/migration for details.
npm warn deprecated core-js@2.6.12: core-js@<3.23.3 is no longer maintained and not recommended for usage due to the number of issues. Because of the V8 engine whims, feature detection in old core-js versions could cause a slowdown up to 100x even if nothing is polyfilled. Some versions have web compatibility issues. Please, upgrade your dependencies to the actual version of core-js.

added 826 packages, and changed 133 packages in 18s

122 packages are looking for funding
  run `npm fund` for details

added 115 packages, and changed 86 packages in 5s

46 packages are looking for funding
  run `npm fund` for details
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported

added 564 packages in 2m

84 packages are looking for funding
  run `npm fund` for details

added 136 packages in 2s

8 packages are looking for funding
  run `npm fund` for details

added 70 packages, and changed 210 packages in 8s

44 packages are looking for funding
  run `npm fund` for details
npm warn deprecated node-domexception@1.0.0: Use your platform's native DOMException instead
npm warn deprecated path-match@1.2.4: This package is archived and no longer maintained. For support, visit https://github.com/expressjs/express/discussions

added 1435 packages in 2m

279 packages are looking for funding
  run `npm fund` for details
npm warn deprecated node-domexception@1.0.0: Use your platform's native DOMException instead

added 755 packages in 18s

85 packages are looking for funding
  run `npm fund` for details

added 123 packages in 17s

27 packages are looking for funding
  run `npm fund` for details

added 600 packages in 18s

82 packages are looking for funding
  run `npm fund` for details

added 2 packages in 1s

changed 89 packages in 6s

13 packages are looking for funding
  run `npm fund` for details

added 98 packages, and changed 2 packages in 36s

7 packages are looking for funding
  run `npm fund` for details
npm warn deprecated yurnalist@2.1.0: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.

added 188 packages, and changed 294 packages in 52s

100 packages are looking for funding
  run `npm fund` for details
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported

added 183 packages in 8s

16 packages are looking for funding
  run `npm fund` for details
npm warn deprecated @apidevtools/swagger-cli@4.0.4: This package has been abandoned. Please switch to using the actively maintained @redocly/cli

added 51 packages in 6s

6 packages are looking for funding
  run `npm fund` for details
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated rimraf@3.0.2: Rimraf versions prior to v4 are no longer supported
npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated uuid@3.4.0: Please upgrade  to version 7 or higher.  Older versions may use Math.random() in certain circumstances, which is known to be problematic.  See https://v8.dev/blog/math-random for details.
npm warn deprecated request@2.88.2: request has been deprecated, see https://github.com/request/request/issues/3142
npm warn deprecated subscriptions-transport-ws@0.9.19: The `subscriptions-transport-ws` package is no longer maintained. We recommend you use `graphql-ws` instead. For help migrating Apollo software to `graphql-ws`, see https://www.apollographql.com/docs/apollo-server/data/subscriptions/#switching-from-subscriptions-transport-ws    For general help using `graphql-ws`, see https://github.com/enisdenjo/graphql-ws/blob/master/README.md

added 444 packages in 36s

83 packages are looking for funding
  run `npm fund` for details
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated glob@7.2.3: Glob versions prior to v9 are no longer supported

added 158 packages in 9s

38 packages are looking for funding
  run `npm fund` for details

added 1 package in 2s

[6/20] Python Packages (Data Science, ML, Web)
Requirement already satisfied: pip in c:\program files\python313\lib\site-packages (25.3)
Requirement already satisfied: setuptools in c:\program files\python313\lib\site-packages (80.9.0)
Requirement already satisfied: wheel in c:\program files\python313\lib\site-packages (0.45.1)
Requirement already satisfied: numpy in c:\program files\python313\lib\site-packages (2.3.5)
Requirement already satisfied: scipy in c:\program files\python313\lib\site-packages (1.16.3)
Requirement already satisfied: pandas in c:\program files\python313\lib\site-packages (2.3.3)
Requirement already satisfied: matplotlib in c:\program files\python313\lib\site-packages (3.10.7)
Requirement already satisfied: seaborn in c:\program files\python313\lib\site-packages (0.13.2)
Requirement already satisfied: plotly in c:\program files\python313\lib\site-packages (6.5.0)
Collecting bokeh
  Downloading bokeh-3.8.1-py3-none-any.whl.metadata (10 kB)
Requirement already satisfied: altair in c:\program files\python313\lib\site-packages (5.5.0)
Requirement already satisfied: python-dateutil>=2.8.2 in c:\program files\python313\lib\site-packages (from pandas) (2.9.0.post0)
Requirement already satisfied: pytz>=2020.1 in c:\program files\python313\lib\site-packages (from pandas) (2025.2)
Requirement already satisfied: tzdata>=2022.7 in c:\program files\python313\lib\site-packages (from pandas) (2025.2)
Requirement already satisfied: contourpy>=1.0.1 in c:\program files\python313\lib\site-packages (from matplotlib) (1.3.3)
Requirement already satisfied: cycler>=0.10 in c:\program files\python313\lib\site-packages (from matplotlib) (0.12.1)
Requirement already satisfied: fonttools>=4.22.0 in c:\program files\python313\lib\site-packages (from matplotlib) (4.60.1)
Requirement already satisfied: kiwisolver>=1.3.1 in c:\program files\python313\lib\site-packages (from matplotlib) (1.4.9)
Requirement already satisfied: packaging>=20.0 in c:\program files\python313\lib\site-packages (from matplotlib) (25.0)
Requirement already satisfied: pillow>=8 in c:\program files\python313\lib\site-packages (from matplotlib) (12.0.0)
Requirement already satisfied: pyparsing>=3 in c:\program files\python313\lib\site-packages (from matplotlib) (3.2.5)
Requirement already satisfied: narwhals>=1.15.1 in c:\program files\python313\lib\site-packages (from plotly) (2.12.0)
Requirement already satisfied: Jinja2>=2.9 in c:\program files\python313\lib\site-packages (from bokeh) (3.1.6)
Requirement already satisfied: PyYAML>=3.10 in c:\program files\python313\lib\site-packages (from bokeh) (6.0.3)
Requirement already satisfied: tornado>=6.2 in c:\program files\python313\lib\site-packages (from bokeh) (6.5.2)
Collecting xyzservices>=2021.09.1 (from bokeh)
  Downloading xyzservices-2025.11.0-py3-none-any.whl.metadata (4.3 kB)
Requirement already satisfied: jsonschema>=3.0 in c:\program files\python313\lib\site-packages (from altair) (4.25.1)
Requirement already satisfied: typing-extensions>=4.10.0 in c:\program files\python313\lib\site-packages (from altair) (4.15.0)
Requirement already satisfied: MarkupSafe>=2.0 in c:\program files\python313\lib\site-packages (from Jinja2>=2.9->bokeh) (3.0.3)
Requirement already satisfied: attrs>=22.2.0 in c:\program files\python313\lib\site-packages (from jsonschema>=3.0->altair) (25.4.0)
Requirement already satisfied: jsonschema-specifications>=2023.03.6 in c:\program files\python313\lib\site-packages (from jsonschema>=3.0->altair) (2025.9.1)
Requirement already satisfied: referencing>=0.28.4 in c:\program files\python313\lib\site-packages (from jsonschema>=3.0->altair) (0.37.0)
Requirement already satisfied: rpds-py>=0.7.1 in c:\program files\python313\lib\site-packages (from jsonschema>=3.0->altair) (0.29.0)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil>=2.8.2->pandas) (1.17.0)
Downloading bokeh-3.8.1-py3-none-any.whl (7.2 MB)
   ---------------------------------------- 7.2/7.2 MB 26.6 MB/s  0:00:00
Downloading xyzservices-2025.11.0-py3-none-any.whl (93 kB)
Installing collected packages: xyzservices, bokeh
Successfully installed bokeh-3.8.1 xyzservices-2025.11.0
Requirement already satisfied: jupyter in c:\program files\python313\lib\site-packages (1.1.1)
Requirement already satisfied: jupyterlab in c:\program files\python313\lib\site-packages (4.5.0)
Requirement already satisfied: notebook in c:\program files\python313\lib\site-packages (7.5.0)
Requirement already satisfied: ipython in c:\program files\python313\lib\site-packages (9.7.0)
Requirement already satisfied: ipykernel in c:\program files\python313\lib\site-packages (7.1.0)
Requirement already satisfied: ipywidgets in c:\program files\python313\lib\site-packages (8.1.8)
Requirement already satisfied: jupyter-console in c:\program files\python313\lib\site-packages (from jupyter) (6.6.3)
Requirement already satisfied: nbconvert in c:\program files\python313\lib\site-packages (from jupyter) (7.16.6)
Requirement already satisfied: async-lru>=1.0.0 in c:\program files\python313\lib\site-packages (from jupyterlab) (2.0.5)
Requirement already satisfied: httpx<1,>=0.25.0 in c:\program files\python313\lib\site-packages (from jupyterlab) (0.28.1)
Requirement already satisfied: jinja2>=3.0.3 in c:\program files\python313\lib\site-packages (from jupyterlab) (3.1.6)
Requirement already satisfied: jupyter-core in c:\program files\python313\lib\site-packages (from jupyterlab) (5.9.1)
Requirement already satisfied: jupyter-lsp>=2.0.0 in c:\program files\python313\lib\site-packages (from jupyterlab) (2.3.0)
Requirement already satisfied: jupyter-server<3,>=2.4.0 in c:\program files\python313\lib\site-packages (from jupyterlab) (2.17.0)
Requirement already satisfied: jupyterlab-server<3,>=2.28.0 in c:\program files\python313\lib\site-packages (from jupyterlab) (2.28.0)
Requirement already satisfied: notebook-shim>=0.2 in c:\program files\python313\lib\site-packages (from jupyterlab) (0.2.4)
Requirement already satisfied: packaging in c:\program files\python313\lib\site-packages (from jupyterlab) (25.0)
Requirement already satisfied: setuptools>=41.1.0 in c:\program files\python313\lib\site-packages (from jupyterlab) (80.9.0)
Requirement already satisfied: tornado>=6.2.0 in c:\program files\python313\lib\site-packages (from jupyterlab) (6.5.2)
Requirement already satisfied: traitlets in c:\program files\python313\lib\site-packages (from jupyterlab) (5.14.3)
Requirement already satisfied: anyio in c:\program files\python313\lib\site-packages (from httpx<1,>=0.25.0->jupyterlab) (4.11.0)
Requirement already satisfied: certifi in c:\program files\python313\lib\site-packages (from httpx<1,>=0.25.0->jupyterlab) (2025.11.12)
Requirement already satisfied: httpcore==1.* in c:\program files\python313\lib\site-packages (from httpx<1,>=0.25.0->jupyterlab) (1.0.9)
Requirement already satisfied: idna in c:\program files\python313\lib\site-packages (from httpx<1,>=0.25.0->jupyterlab) (3.11)
Requirement already satisfied: h11>=0.16 in c:\program files\python313\lib\site-packages (from httpcore==1.*->httpx<1,>=0.25.0->jupyterlab) (0.16.0)
Requirement already satisfied: argon2-cffi>=21.1 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (25.1.0)
Requirement already satisfied: jupyter-client>=7.4.4 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (8.6.3)
Requirement already satisfied: jupyter-events>=0.11.0 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (0.12.0)
Requirement already satisfied: jupyter-server-terminals>=0.4.4 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (0.5.3)
Requirement already satisfied: nbformat>=5.3.0 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (5.10.4)
Requirement already satisfied: prometheus-client>=0.9 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (0.23.1)
Requirement already satisfied: pywinpty>=2.0.1 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (3.0.2)
Requirement already satisfied: pyzmq>=24 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (27.1.0)
Requirement already satisfied: send2trash>=1.8.2 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (1.8.3)
Requirement already satisfied: terminado>=0.8.3 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (0.18.1)
Requirement already satisfied: websocket-client>=1.7 in c:\program files\python313\lib\site-packages (from jupyter-server<3,>=2.4.0->jupyterlab) (1.9.0)
Requirement already satisfied: babel>=2.10 in c:\program files\python313\lib\site-packages (from jupyterlab-server<3,>=2.28.0->jupyterlab) (2.17.0)
Requirement already satisfied: json5>=0.9.0 in c:\program files\python313\lib\site-packages (from jupyterlab-server<3,>=2.28.0->jupyterlab) (0.12.1)
Requirement already satisfied: jsonschema>=4.18.0 in c:\program files\python313\lib\site-packages (from jupyterlab-server<3,>=2.28.0->jupyterlab) (4.25.1)
Requirement already satisfied: requests>=2.31 in c:\program files\python313\lib\site-packages (from jupyterlab-server<3,>=2.28.0->jupyterlab) (2.32.4)
Requirement already satisfied: colorama>=0.4.4 in c:\program files\python313\lib\site-packages (from ipython) (0.4.6)
Requirement already satisfied: decorator>=4.3.2 in c:\program files\python313\lib\site-packages (from ipython) (5.2.1)
Requirement already satisfied: ipython-pygments-lexers>=1.0.0 in c:\program files\python313\lib\site-packages (from ipython) (1.1.1)
Requirement already satisfied: jedi>=0.18.1 in c:\program files\python313\lib\site-packages (from ipython) (0.19.2)
Requirement already satisfied: matplotlib-inline>=0.1.5 in c:\program files\python313\lib\site-packages (from ipython) (0.2.1)
Requirement already satisfied: prompt_toolkit<3.1.0,>=3.0.41 in c:\program files\python313\lib\site-packages (from ipython) (3.0.52)
Requirement already satisfied: pygments>=2.11.0 in c:\program files\python313\lib\site-packages (from ipython) (2.19.2)
Requirement already satisfied: stack_data>=0.6.0 in c:\program files\python313\lib\site-packages (from ipython) (0.6.3)
Requirement already satisfied: wcwidth in c:\program files\python313\lib\site-packages (from prompt_toolkit<3.1.0,>=3.0.41->ipython) (0.2.14)
Requirement already satisfied: comm>=0.1.1 in c:\program files\python313\lib\site-packages (from ipykernel) (0.2.3)
Requirement already satisfied: debugpy>=1.6.5 in c:\program files\python313\lib\site-packages (from ipykernel) (1.8.17)
Requirement already satisfied: nest-asyncio>=1.4 in c:\program files\python313\lib\site-packages (from ipykernel) (1.6.0)
Requirement already satisfied: psutil>=5.7 in c:\program files\python313\lib\site-packages (from ipykernel) (7.1.3)
Requirement already satisfied: widgetsnbextension~=4.0.14 in c:\program files\python313\lib\site-packages (from ipywidgets) (4.0.15)
Requirement already satisfied: jupyterlab_widgets~=3.0.15 in c:\program files\python313\lib\site-packages (from ipywidgets) (3.0.16)
Requirement already satisfied: sniffio>=1.1 in c:\program files\python313\lib\site-packages (from anyio->httpx<1,>=0.25.0->jupyterlab) (1.3.1)
Requirement already satisfied: argon2-cffi-bindings in c:\program files\python313\lib\site-packages (from argon2-cffi>=21.1->jupyter-server<3,>=2.4.0->jupyterlab) (25.1.0)
Requirement already satisfied: parso<0.9.0,>=0.8.4 in c:\program files\python313\lib\site-packages (from jedi>=0.18.1->ipython) (0.8.5)
Requirement already satisfied: MarkupSafe>=2.0 in c:\program files\python313\lib\site-packages (from jinja2>=3.0.3->jupyterlab) (3.0.3)
Requirement already satisfied: attrs>=22.2.0 in c:\program files\python313\lib\site-packages (from jsonschema>=4.18.0->jupyterlab-server<3,>=2.28.0->jupyterlab) (25.4.0)
Requirement already satisfied: jsonschema-specifications>=2023.03.6 in c:\program files\python313\lib\site-packages (from jsonschema>=4.18.0->jupyterlab-server<3,>=2.28.0->jupyterlab) (2025.9.1)
Requirement already satisfied: referencing>=0.28.4 in c:\program files\python313\lib\site-packages (from jsonschema>=4.18.0->jupyterlab-server<3,>=2.28.0->jupyterlab) (0.37.0)
Requirement already satisfied: rpds-py>=0.7.1 in c:\program files\python313\lib\site-packages (from jsonschema>=4.18.0->jupyterlab-server<3,>=2.28.0->jupyterlab) (0.29.0)
Requirement already satisfied: python-dateutil>=2.8.2 in c:\program files\python313\lib\site-packages (from jupyter-client>=7.4.4->jupyter-server<3,>=2.4.0->jupyterlab) (2.9.0.post0)
Requirement already satisfied: platformdirs>=2.5 in c:\program files\python313\lib\site-packages (from jupyter-core->jupyterlab) (4.5.0)
Requirement already satisfied: python-json-logger>=2.0.4 in c:\program files\python313\lib\site-packages (from jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (4.0.0)
Requirement already satisfied: pyyaml>=5.3 in c:\program files\python313\lib\site-packages (from jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (6.0.3)
Requirement already satisfied: rfc3339-validator in c:\program files\python313\lib\site-packages (from jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (0.1.4)
Requirement already satisfied: rfc3986-validator>=0.1.1 in c:\program files\python313\lib\site-packages (from jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (0.1.1)
Requirement already satisfied: fqdn in c:\program files\python313\lib\site-packages (from jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (1.5.1)
Requirement already satisfied: isoduration in c:\program files\python313\lib\site-packages (from jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (20.11.0)
Requirement already satisfied: jsonpointer>1.13 in c:\program files\python313\lib\site-packages (from jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (3.0.0)
Requirement already satisfied: rfc3987-syntax>=1.1.0 in c:\program files\python313\lib\site-packages (from jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (1.1.0)
Requirement already satisfied: uri-template in c:\program files\python313\lib\site-packages (from jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (1.3.0)
Requirement already satisfied: webcolors>=24.6.0 in c:\program files\python313\lib\site-packages (from jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (25.10.0)
Requirement already satisfied: beautifulsoup4 in c:\program files\python313\lib\site-packages (from nbconvert->jupyter) (4.14.2)
Requirement already satisfied: bleach!=5.0.0 in c:\program files\python313\lib\site-packages (from bleach[css]!=5.0.0->nbconvert->jupyter) (6.3.0)
Requirement already satisfied: defusedxml in c:\program files\python313\lib\site-packages (from nbconvert->jupyter) (0.7.1)
Requirement already satisfied: jupyterlab-pygments in c:\program files\python313\lib\site-packages (from nbconvert->jupyter) (0.3.0)
Requirement already satisfied: mistune<4,>=2.0.3 in c:\program files\python313\lib\site-packages (from nbconvert->jupyter) (3.1.4)
Requirement already satisfied: nbclient>=0.5.0 in c:\program files\python313\lib\site-packages (from nbconvert->jupyter) (0.10.2)
Requirement already satisfied: pandocfilters>=1.4.1 in c:\program files\python313\lib\site-packages (from nbconvert->jupyter) (1.5.1)
Requirement already satisfied: webencodings in c:\program files\python313\lib\site-packages (from bleach!=5.0.0->bleach[css]!=5.0.0->nbconvert->jupyter) (0.5.1)
Requirement already satisfied: tinycss2<1.5,>=1.1.0 in c:\program files\python313\lib\site-packages (from bleach[css]!=5.0.0->nbconvert->jupyter) (1.4.0)
Requirement already satisfied: fastjsonschema>=2.15 in c:\program files\python313\lib\site-packages (from nbformat>=5.3.0->jupyter-server<3,>=2.4.0->jupyterlab) (2.21.2)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil>=2.8.2->jupyter-client>=7.4.4->jupyter-server<3,>=2.4.0->jupyterlab) (1.17.0)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests>=2.31->jupyterlab-server<3,>=2.28.0->jupyterlab) (3.4.4)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests>=2.31->jupyterlab-server<3,>=2.28.0->jupyterlab) (2.5.0)
Requirement already satisfied: lark>=1.2.2 in c:\program files\python313\lib\site-packages (from rfc3987-syntax>=1.1.0->jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (1.3.1)
Requirement already satisfied: executing>=1.2.0 in c:\program files\python313\lib\site-packages (from stack_data>=0.6.0->ipython) (2.2.1)
Requirement already satisfied: asttokens>=2.1.0 in c:\program files\python313\lib\site-packages (from stack_data>=0.6.0->ipython) (3.0.1)
Requirement already satisfied: pure-eval in c:\program files\python313\lib\site-packages (from stack_data>=0.6.0->ipython) (0.2.3)
Requirement already satisfied: cffi>=1.0.1 in c:\program files\python313\lib\site-packages (from argon2-cffi-bindings->argon2-cffi>=21.1->jupyter-server<3,>=2.4.0->jupyterlab) (2.0.0)
Requirement already satisfied: pycparser in c:\program files\python313\lib\site-packages (from cffi>=1.0.1->argon2-cffi-bindings->argon2-cffi>=21.1->jupyter-server<3,>=2.4.0->jupyterlab) (2.23)
Requirement already satisfied: soupsieve>1.2 in c:\program files\python313\lib\site-packages (from beautifulsoup4->nbconvert->jupyter) (2.8)
Requirement already satisfied: typing-extensions>=4.0.0 in c:\program files\python313\lib\site-packages (from beautifulsoup4->nbconvert->jupyter) (4.15.0)
Requirement already satisfied: arrow>=0.15.0 in c:\program files\python313\lib\site-packages (from isoduration->jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (1.4.0)
Requirement already satisfied: tzdata in c:\program files\python313\lib\site-packages (from arrow>=0.15.0->isoduration->jsonschema[format-nongpl]>=4.18.0->jupyter-events>=0.11.0->jupyter-server<3,>=2.4.0->jupyterlab) (2025.2)
Requirement already satisfied: scikit-learn in c:\program files\python313\lib\site-packages (1.7.2)
Collecting xgboost
  Downloading xgboost-3.1.2-py3-none-win_amd64.whl.metadata (2.1 kB)
Collecting lightgbm
  Downloading lightgbm-4.6.0-py3-none-win_amd64.whl.metadata (17 kB)
Collecting catboost
  Downloading catboost-1.2.8-cp313-cp313-win_amd64.whl.metadata (1.5 kB)
Requirement already satisfied: statsmodels in c:\program files\python313\lib\site-packages (0.14.5)
Requirement already satisfied: numpy>=1.22.0 in c:\program files\python313\lib\site-packages (from scikit-learn) (2.3.5)
Requirement already satisfied: scipy>=1.8.0 in c:\program files\python313\lib\site-packages (from scikit-learn) (1.16.3)
Requirement already satisfied: joblib>=1.2.0 in c:\program files\python313\lib\site-packages (from scikit-learn) (1.5.2)
Requirement already satisfied: threadpoolctl>=3.1.0 in c:\program files\python313\lib\site-packages (from scikit-learn) (3.6.0)
Collecting graphviz (from catboost)
  Downloading graphviz-0.21-py3-none-any.whl.metadata (12 kB)
Requirement already satisfied: matplotlib in c:\program files\python313\lib\site-packages (from catboost) (3.10.7)
Requirement already satisfied: pandas>=0.24 in c:\program files\python313\lib\site-packages (from catboost) (2.3.3)
Requirement already satisfied: plotly in c:\program files\python313\lib\site-packages (from catboost) (6.5.0)
Requirement already satisfied: six in c:\program files\python313\lib\site-packages (from catboost) (1.17.0)
Requirement already satisfied: patsy>=0.5.6 in c:\program files\python313\lib\site-packages (from statsmodels) (1.0.2)
Requirement already satisfied: packaging>=21.3 in c:\program files\python313\lib\site-packages (from statsmodels) (25.0)
Requirement already satisfied: python-dateutil>=2.8.2 in c:\program files\python313\lib\site-packages (from pandas>=0.24->catboost) (2.9.0.post0)
Requirement already satisfied: pytz>=2020.1 in c:\program files\python313\lib\site-packages (from pandas>=0.24->catboost) (2025.2)
Requirement already satisfied: tzdata>=2022.7 in c:\program files\python313\lib\site-packages (from pandas>=0.24->catboost) (2025.2)
Requirement already satisfied: contourpy>=1.0.1 in c:\program files\python313\lib\site-packages (from matplotlib->catboost) (1.3.3)
Requirement already satisfied: cycler>=0.10 in c:\program files\python313\lib\site-packages (from matplotlib->catboost) (0.12.1)
Requirement already satisfied: fonttools>=4.22.0 in c:\program files\python313\lib\site-packages (from matplotlib->catboost) (4.60.1)
Requirement already satisfied: kiwisolver>=1.3.1 in c:\program files\python313\lib\site-packages (from matplotlib->catboost) (1.4.9)
Requirement already satisfied: pillow>=8 in c:\program files\python313\lib\site-packages (from matplotlib->catboost) (12.0.0)
Requirement already satisfied: pyparsing>=3 in c:\program files\python313\lib\site-packages (from matplotlib->catboost) (3.2.5)
Requirement already satisfied: narwhals>=1.15.1 in c:\program files\python313\lib\site-packages (from plotly->catboost) (2.12.0)
Downloading xgboost-3.1.2-py3-none-win_amd64.whl (72.0 MB)
   ---------------------------------------- 72.0/72.0 MB 46.3 MB/s  0:00:01
Downloading lightgbm-4.6.0-py3-none-win_amd64.whl (1.5 MB)
   ---------------------------------------- 1.5/1.5 MB 40.2 MB/s  0:00:00
Downloading catboost-1.2.8-cp313-cp313-win_amd64.whl (102.4 MB)
   ---------------------------------------- 102.4/102.4 MB 42.9 MB/s  0:00:02
Downloading graphviz-0.21-py3-none-any.whl (47 kB)
Installing collected packages: graphviz, xgboost, lightgbm, catboost
Successfully installed catboost-1.2.8 graphviz-0.21 lightgbm-4.6.0 xgboost-3.1.2
Looking in indexes: https://download.pytorch.org/whl/cu118
Requirement already satisfied: torch in c:\program files\python313\lib\site-packages (2.9.1+cpu)
Requirement already satisfied: torchvision in c:\program files\python313\lib\site-packages (0.24.1+cpu)
Requirement already satisfied: torchaudio in c:\program files\python313\lib\site-packages (2.9.1+cpu)
Requirement already satisfied: filelock in c:\program files\python313\lib\site-packages (from torch) (3.19.1)
Requirement already satisfied: typing-extensions>=4.10.0 in c:\program files\python313\lib\site-packages (from torch) (4.15.0)
Requirement already satisfied: sympy>=1.13.3 in c:\program files\python313\lib\site-packages (from torch) (1.14.0)
Requirement already satisfied: networkx>=2.5.1 in c:\program files\python313\lib\site-packages (from torch) (3.5)
Requirement already satisfied: jinja2 in c:\program files\python313\lib\site-packages (from torch) (3.1.6)
Requirement already satisfied: fsspec>=0.8.5 in c:\program files\python313\lib\site-packages (from torch) (2025.9.0)
Requirement already satisfied: setuptools in c:\program files\python313\lib\site-packages (from torch) (80.9.0)
Requirement already satisfied: numpy in c:\program files\python313\lib\site-packages (from torchvision) (2.3.5)
Requirement already satisfied: pillow!=8.3.*,>=5.3.0 in c:\program files\python313\lib\site-packages (from torchvision) (12.0.0)
Requirement already satisfied: mpmath<1.4,>=1.1.0 in c:\program files\python313\lib\site-packages (from sympy>=1.13.3->torch) (1.3.0)
Requirement already satisfied: MarkupSafe>=2.0 in c:\program files\python313\lib\site-packages (from jinja2->torch) (3.0.3)
Requirement already satisfied: tensorflow in c:\program files\python313\lib\site-packages (2.20.0)
Collecting tensorflow-datasets
  Downloading tensorflow_datasets-4.9.9-py3-none-any.whl.metadata (11 kB)
Requirement already satisfied: keras in c:\program files\python313\lib\site-packages (3.12.0)
Requirement already satisfied: absl-py>=1.0.0 in c:\program files\python313\lib\site-packages (from tensorflow) (2.3.1)
Requirement already satisfied: astunparse>=1.6.0 in c:\program files\python313\lib\site-packages (from tensorflow) (1.6.3)
Requirement already satisfied: flatbuffers>=24.3.25 in c:\program files\python313\lib\site-packages (from tensorflow) (25.9.23)
Requirement already satisfied: gast!=0.5.0,!=0.5.1,!=0.5.2,>=0.2.1 in c:\program files\python313\lib\site-packages (from tensorflow) (0.6.0)
Requirement already satisfied: google_pasta>=0.1.1 in c:\program files\python313\lib\site-packages (from tensorflow) (0.2.0)
Requirement already satisfied: libclang>=13.0.0 in c:\program files\python313\lib\site-packages (from tensorflow) (18.1.1)
Requirement already satisfied: opt_einsum>=2.3.2 in c:\program files\python313\lib\site-packages (from tensorflow) (3.4.0)
Requirement already satisfied: packaging in c:\program files\python313\lib\site-packages (from tensorflow) (25.0)
Requirement already satisfied: protobuf>=5.28.0 in c:\program files\python313\lib\site-packages (from tensorflow) (6.33.1)
Requirement already satisfied: requests<3,>=2.21.0 in c:\program files\python313\lib\site-packages (from tensorflow) (2.32.4)
Requirement already satisfied: setuptools in c:\program files\python313\lib\site-packages (from tensorflow) (80.9.0)
Requirement already satisfied: six>=1.12.0 in c:\program files\python313\lib\site-packages (from tensorflow) (1.17.0)
Requirement already satisfied: termcolor>=1.1.0 in c:\program files\python313\lib\site-packages (from tensorflow) (3.2.0)
Requirement already satisfied: typing_extensions>=3.6.6 in c:\program files\python313\lib\site-packages (from tensorflow) (4.15.0)
Requirement already satisfied: wrapt>=1.11.0 in c:\program files\python313\lib\site-packages (from tensorflow) (1.17.3)
Requirement already satisfied: grpcio<2.0,>=1.24.3 in c:\program files\python313\lib\site-packages (from tensorflow) (1.76.0)
Requirement already satisfied: tensorboard~=2.20.0 in c:\program files\python313\lib\site-packages (from tensorflow) (2.20.0)
Requirement already satisfied: numpy>=1.26.0 in c:\program files\python313\lib\site-packages (from tensorflow) (2.3.5)
Requirement already satisfied: h5py>=3.11.0 in c:\program files\python313\lib\site-packages (from tensorflow) (3.15.1)
Requirement already satisfied: ml_dtypes<1.0.0,>=0.5.1 in c:\program files\python313\lib\site-packages (from tensorflow) (0.5.4)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests<3,>=2.21.0->tensorflow) (3.4.4)
Requirement already satisfied: idna<4,>=2.5 in c:\program files\python313\lib\site-packages (from requests<3,>=2.21.0->tensorflow) (3.11)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests<3,>=2.21.0->tensorflow) (2.5.0)
Requirement already satisfied: certifi>=2017.4.17 in c:\program files\python313\lib\site-packages (from requests<3,>=2.21.0->tensorflow) (2025.11.12)
Requirement already satisfied: markdown>=2.6.8 in c:\program files\python313\lib\site-packages (from tensorboard~=2.20.0->tensorflow) (3.10)
Requirement already satisfied: pillow in c:\program files\python313\lib\site-packages (from tensorboard~=2.20.0->tensorflow) (12.0.0)
Requirement already satisfied: tensorboard-data-server<0.8.0,>=0.7.0 in c:\program files\python313\lib\site-packages (from tensorboard~=2.20.0->tensorflow) (0.7.2)
Requirement already satisfied: werkzeug>=1.0.1 in c:\program files\python313\lib\site-packages (from tensorboard~=2.20.0->tensorflow) (3.1.3)
Collecting dm-tree (from tensorflow-datasets)
  Downloading dm_tree-0.1.9-cp313-cp313-win_amd64.whl.metadata (2.5 kB)
Collecting etils>=1.9.1 (from etils[edc,enp,epath,epy,etree]>=1.9.1; python_version >= "3.11"->tensorflow-datasets)
  Downloading etils-1.13.0-py3-none-any.whl.metadata (6.5 kB)
Collecting immutabledict (from tensorflow-datasets)
  Downloading immutabledict-4.2.2-py3-none-any.whl.metadata (3.5 kB)
Collecting promise (from tensorflow-datasets)
  Downloading promise-2.3.tar.gz (19 kB)
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Requirement already satisfied: psutil in c:\program files\python313\lib\site-packages (from tensorflow-datasets) (7.1.3)
Requirement already satisfied: pyarrow in c:\program files\python313\lib\site-packages (from tensorflow-datasets) (21.0.0)
Collecting simple_parsing (from tensorflow-datasets)
  Downloading simple_parsing-0.1.7-py3-none-any.whl.metadata (7.3 kB)
Collecting tensorflow-metadata (from tensorflow-datasets)
  Downloading tensorflow_metadata-1.17.2-py3-none-any.whl.metadata (2.5 kB)
Requirement already satisfied: toml in c:\program files\python313\lib\site-packages (from tensorflow-datasets) (0.10.2)
Requirement already satisfied: tqdm in c:\program files\python313\lib\site-packages (from tensorflow-datasets) (4.67.1)
Requirement already satisfied: rich in c:\program files\python313\lib\site-packages (from keras) (14.2.0)
Requirement already satisfied: namex in c:\program files\python313\lib\site-packages (from keras) (0.1.0)
Requirement already satisfied: optree in c:\program files\python313\lib\site-packages (from keras) (0.18.0)
Requirement already satisfied: wheel<1.0,>=0.23.0 in c:\program files\python313\lib\site-packages (from astunparse>=1.6.0->tensorflow) (0.45.1)
Collecting einops (from etils[edc,enp,epath,epy,etree]>=1.9.1; python_version >= "3.11"->tensorflow-datasets)
  Downloading einops-0.8.1-py3-none-any.whl.metadata (13 kB)
Requirement already satisfied: fsspec in c:\program files\python313\lib\site-packages (from etils[edc,enp,epath,epy,etree]>=1.9.1; python_version >= "3.11"->tensorflow-datasets) (2025.9.0)
Collecting importlib_resources (from etils[edc,enp,epath,epy,etree]>=1.9.1; python_version >= "3.11"->tensorflow-datasets)
  Downloading importlib_resources-6.5.2-py3-none-any.whl.metadata (3.9 kB)
Requirement already satisfied: zipp in c:\program files\python313\lib\site-packages (from etils[edc,enp,epath,epy,etree]>=1.9.1; python_version >= "3.11"->tensorflow-datasets) (3.23.0)
Requirement already satisfied: MarkupSafe>=2.1.1 in c:\program files\python313\lib\site-packages (from werkzeug>=1.0.1->tensorboard~=2.20.0->tensorflow) (3.0.3)
Requirement already satisfied: attrs>=18.2.0 in c:\program files\python313\lib\site-packages (from dm-tree->tensorflow-datasets) (25.4.0)
Requirement already satisfied: markdown-it-py>=2.2.0 in c:\program files\python313\lib\site-packages (from rich->keras) (4.0.0)
Requirement already satisfied: pygments<3.0.0,>=2.13.0 in c:\program files\python313\lib\site-packages (from rich->keras) (2.19.2)
Requirement already satisfied: mdurl~=0.1 in c:\program files\python313\lib\site-packages (from markdown-it-py>=2.2.0->rich->keras) (0.1.2)
Collecting docstring-parser<1.0,>=0.15 (from simple_parsing->tensorflow-datasets)
  Downloading docstring_parser-0.17.0-py3-none-any.whl.metadata (3.5 kB)
Requirement already satisfied: googleapis-common-protos<2,>=1.56.4 in c:\program files\python313\lib\site-packages (from tensorflow-metadata->tensorflow-datasets) (1.72.0)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from tqdm->tensorflow-datasets) (0.4.6)
Downloading tensorflow_datasets-4.9.9-py3-none-any.whl (5.3 MB)
   ---------------------------------------- 5.3/5.3 MB 34.8 MB/s  0:00:00
Downloading etils-1.13.0-py3-none-any.whl (170 kB)
Downloading dm_tree-0.1.9-cp313-cp313-win_amd64.whl (102 kB)
Downloading einops-0.8.1-py3-none-any.whl (64 kB)
Downloading immutabledict-4.2.2-py3-none-any.whl (4.7 kB)
Downloading importlib_resources-6.5.2-py3-none-any.whl (37 kB)
Downloading simple_parsing-0.1.7-py3-none-any.whl (112 kB)
Downloading docstring_parser-0.17.0-py3-none-any.whl (36 kB)
Downloading tensorflow_metadata-1.17.2-py3-none-any.whl (31 kB)
Building wheels for collected packages: promise
  Building wheel for promise (pyproject.toml) ... done
  Created wheel for promise: filename=promise-2.3-py3-none-any.whl size=21644 sha256=463f2011d167e6c705c04bd1159064f411b82ce680a1a06d0b788e9e12992956
  Stored in directory: c:\users\shelc\appdata\local\pip\cache\wheels\8f\46\1c\1f4e5d73a20eb816ead5014e97cdeb3928cf314fc46c7bab61
Successfully built promise
Installing collected packages: promise, importlib_resources, immutabledict, etils, einops, docstring-parser, dm-tree, tensorflow-metadata, simple_parsing, tensorflow-datasets
Successfully installed dm-tree-0.1.9 docstring-parser-0.17.0 einops-0.8.1 etils-1.13.0 immutabledict-4.2.2 importlib_resources-6.5.2 promise-2.3 simple_parsing-0.1.7 tensorflow-datasets-4.9.9 tensorflow-metadata-1.17.2
Requirement already satisfied: transformers in c:\program files\python313\lib\site-packages (4.57.3)
Requirement already satisfied: spacy in c:\program files\python313\lib\site-packages (3.8.11)
Requirement already satisfied: nltk in c:\program files\python313\lib\site-packages (3.9.2)
Collecting gensim
  Downloading gensim-4.4.0-cp313-cp313-win_amd64.whl.metadata (8.6 kB)
Collecting sentence-transformers
  Downloading sentence_transformers-5.1.2-py3-none-any.whl.metadata (16 kB)
Requirement already satisfied: filelock in c:\program files\python313\lib\site-packages (from transformers) (3.19.1)
Requirement already satisfied: huggingface-hub<1.0,>=0.34.0 in c:\program files\python313\lib\site-packages (from transformers) (0.36.0)
Requirement already satisfied: numpy>=1.17 in c:\program files\python313\lib\site-packages (from transformers) (2.3.5)
Requirement already satisfied: packaging>=20.0 in c:\program files\python313\lib\site-packages (from transformers) (25.0)
Requirement already satisfied: pyyaml>=5.1 in c:\program files\python313\lib\site-packages (from transformers) (6.0.3)
Requirement already satisfied: regex!=2019.12.17 in c:\program files\python313\lib\site-packages (from transformers) (2025.11.3)
Requirement already satisfied: requests in c:\program files\python313\lib\site-packages (from transformers) (2.32.4)
Requirement already satisfied: tokenizers<=0.23.0,>=0.22.0 in c:\program files\python313\lib\site-packages (from transformers) (0.22.1)
Requirement already satisfied: safetensors>=0.4.3 in c:\program files\python313\lib\site-packages (from transformers) (0.7.0)
Requirement already satisfied: tqdm>=4.27 in c:\program files\python313\lib\site-packages (from transformers) (4.67.1)
Requirement already satisfied: fsspec>=2023.5.0 in c:\program files\python313\lib\site-packages (from huggingface-hub<1.0,>=0.34.0->transformers) (2025.9.0)
Requirement already satisfied: typing-extensions>=3.7.4.3 in c:\program files\python313\lib\site-packages (from huggingface-hub<1.0,>=0.34.0->transformers) (4.15.0)
Requirement already satisfied: spacy-legacy<3.1.0,>=3.0.11 in c:\program files\python313\lib\site-packages (from spacy) (3.0.12)
Requirement already satisfied: spacy-loggers<2.0.0,>=1.0.0 in c:\program files\python313\lib\site-packages (from spacy) (1.0.5)
Requirement already satisfied: murmurhash<1.1.0,>=0.28.0 in c:\program files\python313\lib\site-packages (from spacy) (1.0.15)
Requirement already satisfied: cymem<2.1.0,>=2.0.2 in c:\program files\python313\lib\site-packages (from spacy) (2.0.13)
Requirement already satisfied: preshed<3.1.0,>=3.0.2 in c:\program files\python313\lib\site-packages (from spacy) (3.0.12)
Requirement already satisfied: thinc<8.4.0,>=8.3.4 in c:\program files\python313\lib\site-packages (from spacy) (8.3.10)
Requirement already satisfied: wasabi<1.2.0,>=0.9.1 in c:\program files\python313\lib\site-packages (from spacy) (1.1.3)
Requirement already satisfied: srsly<3.0.0,>=2.4.3 in c:\program files\python313\lib\site-packages (from spacy) (2.5.2)
Requirement already satisfied: catalogue<2.1.0,>=2.0.6 in c:\program files\python313\lib\site-packages (from spacy) (2.0.10)
Requirement already satisfied: weasel<0.5.0,>=0.4.2 in c:\program files\python313\lib\site-packages (from spacy) (0.4.3)
Requirement already satisfied: typer-slim<1.0.0,>=0.3.0 in c:\program files\python313\lib\site-packages (from spacy) (0.20.0)
Requirement already satisfied: pydantic!=1.8,!=1.8.1,<3.0.0,>=1.7.4 in c:\program files\python313\lib\site-packages (from spacy) (2.12.4)
Requirement already satisfied: jinja2 in c:\program files\python313\lib\site-packages (from spacy) (3.1.6)
Requirement already satisfied: setuptools in c:\program files\python313\lib\site-packages (from spacy) (80.9.0)
Requirement already satisfied: annotated-types>=0.6.0 in c:\program files\python313\lib\site-packages (from pydantic!=1.8,!=1.8.1,<3.0.0,>=1.7.4->spacy) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in c:\program files\python313\lib\site-packages (from pydantic!=1.8,!=1.8.1,<3.0.0,>=1.7.4->spacy) (2.41.5)
Requirement already satisfied: typing-inspection>=0.4.2 in c:\program files\python313\lib\site-packages (from pydantic!=1.8,!=1.8.1,<3.0.0,>=1.7.4->spacy) (0.4.2)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests->transformers) (3.4.4)
Requirement already satisfied: idna<4,>=2.5 in c:\program files\python313\lib\site-packages (from requests->transformers) (3.11)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests->transformers) (2.5.0)
Requirement already satisfied: certifi>=2017.4.17 in c:\program files\python313\lib\site-packages (from requests->transformers) (2025.11.12)
Requirement already satisfied: blis<1.4.0,>=1.3.0 in c:\program files\python313\lib\site-packages (from thinc<8.4.0,>=8.3.4->spacy) (1.3.3)
Requirement already satisfied: confection<1.0.0,>=0.0.1 in c:\program files\python313\lib\site-packages (from thinc<8.4.0,>=8.3.4->spacy) (0.1.5)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from tqdm>=4.27->transformers) (0.4.6)
Requirement already satisfied: click>=8.0.0 in c:\program files\python313\lib\site-packages (from typer-slim<1.0.0,>=0.3.0->spacy) (8.3.1)
Requirement already satisfied: cloudpathlib<1.0.0,>=0.7.0 in c:\program files\python313\lib\site-packages (from weasel<0.5.0,>=0.4.2->spacy) (0.23.0)
Requirement already satisfied: smart-open<8.0.0,>=5.2.1 in c:\program files\python313\lib\site-packages (from weasel<0.5.0,>=0.4.2->spacy) (7.5.0)
Requirement already satisfied: wrapt in c:\program files\python313\lib\site-packages (from smart-open<8.0.0,>=5.2.1->weasel<0.5.0,>=0.4.2->spacy) (1.17.3)
Requirement already satisfied: joblib in c:\program files\python313\lib\site-packages (from nltk) (1.5.2)
Requirement already satisfied: scipy>=1.7.0 in c:\program files\python313\lib\site-packages (from gensim) (1.16.3)
Requirement already satisfied: torch>=1.11.0 in c:\program files\python313\lib\site-packages (from sentence-transformers) (2.9.1+cpu)
Requirement already satisfied: scikit-learn in c:\program files\python313\lib\site-packages (from sentence-transformers) (1.7.2)
Requirement already satisfied: Pillow in c:\program files\python313\lib\site-packages (from sentence-transformers) (12.0.0)
Requirement already satisfied: sympy>=1.13.3 in c:\program files\python313\lib\site-packages (from torch>=1.11.0->sentence-transformers) (1.14.0)
Requirement already satisfied: networkx>=2.5.1 in c:\program files\python313\lib\site-packages (from torch>=1.11.0->sentence-transformers) (3.5)
Requirement already satisfied: mpmath<1.4,>=1.1.0 in c:\program files\python313\lib\site-packages (from sympy>=1.13.3->torch>=1.11.0->sentence-transformers) (1.3.0)
Requirement already satisfied: MarkupSafe>=2.0 in c:\program files\python313\lib\site-packages (from jinja2->spacy) (3.0.3)
Requirement already satisfied: threadpoolctl>=3.1.0 in c:\program files\python313\lib\site-packages (from scikit-learn->sentence-transformers) (3.6.0)
Downloading gensim-4.4.0-cp313-cp313-win_amd64.whl (24.4 MB)
   ---------------------------------------- 24.4/24.4 MB 26.0 MB/s  0:00:01
Downloading sentence_transformers-5.1.2-py3-none-any.whl (488 kB)
Installing collected packages: gensim, sentence-transformers
Successfully installed gensim-4.4.0 sentence-transformers-5.1.2
Collecting en-core-web-sm==3.8.0
  Downloading https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl (12.8 MB)
     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 12.8/12.8 MB 47.8 MB/s  0:00:00
Installing collected packages: en-core-web-sm
Successfully installed en-core-web-sm-3.8.0
✔ Download and installation successful
You can now load the package via spacy.load('en_core_web_sm')
Collecting opencv-python
  Downloading opencv_python-4.12.0.88-cp37-abi3-win_amd64.whl.metadata (19 kB)
Requirement already satisfied: pillow in c:\program files\python313\lib\site-packages (12.0.0)
Collecting scikit-image
  Downloading scikit_image-0.25.2-cp313-cp313-win_amd64.whl.metadata (14 kB)
Collecting numpy<2.3.0,>=2 (from opencv-python)
  Downloading numpy-2.2.6-cp313-cp313-win_amd64.whl.metadata (60 kB)
Requirement already satisfied: scipy>=1.11.4 in c:\program files\python313\lib\site-packages (from scikit-image) (1.16.3)
Requirement already satisfied: networkx>=3.0 in c:\program files\python313\lib\site-packages (from scikit-image) (3.5)
Collecting imageio!=2.35.0,>=2.33 (from scikit-image)
  Downloading imageio-2.37.2-py3-none-any.whl.metadata (9.7 kB)
Collecting tifffile>=2022.8.12 (from scikit-image)
  Downloading tifffile-2025.10.16-py3-none-any.whl.metadata (31 kB)
Requirement already satisfied: packaging>=21 in c:\program files\python313\lib\site-packages (from scikit-image) (25.0)
Collecting lazy-loader>=0.4 (from scikit-image)
  Downloading lazy_loader-0.4-py3-none-any.whl.metadata (7.6 kB)
Downloading opencv_python-4.12.0.88-cp37-abi3-win_amd64.whl (39.0 MB)
   ---------------------------------------- 39.0/39.0 MB 61.9 MB/s  0:00:00
Downloading numpy-2.2.6-cp313-cp313-win_amd64.whl (12.6 MB)
   ---------------------------------------- 12.6/12.6 MB 71.1 MB/s  0:00:00
Downloading scikit_image-0.25.2-cp313-cp313-win_amd64.whl (12.9 MB)
   ---------------------------------------- 12.9/12.9 MB 75.6 MB/s  0:00:00
Downloading imageio-2.37.2-py3-none-any.whl (317 kB)
Downloading lazy_loader-0.4-py3-none-any.whl (12 kB)
Downloading tifffile-2025.10.16-py3-none-any.whl (231 kB)
Installing collected packages: numpy, lazy-loader, tifffile, opencv-python, imageio, scikit-image
  Attempting uninstall: numpy
    Found existing installation: numpy 2.3.5
    Uninstalling numpy-2.3.5:
      Successfully uninstalled numpy-2.3.5
Successfully installed imageio-2.37.2 lazy-loader-0.4 numpy-2.2.6 opencv-python-4.12.0.88 scikit-image-0.25.2 tifffile-2025.10.16
Collecting langchain
  Downloading langchain-1.1.0-py3-none-any.whl.metadata (4.9 kB)
Collecting openai
  Downloading openai-2.8.1-py3-none-any.whl.metadata (29 kB)
Collecting anthropic
  Downloading anthropic-0.75.0-py3-none-any.whl.metadata (28 kB)
Collecting llama-index
  Downloading llama_index-0.14.8-py3-none-any.whl.metadata (13 kB)
Collecting langchain-core<2.0.0,>=1.1.0 (from langchain)
  Downloading langchain_core-1.1.0-py3-none-any.whl.metadata (3.6 kB)
Collecting langgraph<1.1.0,>=1.0.2 (from langchain)
  Downloading langgraph-1.0.4-py3-none-any.whl.metadata (7.8 kB)
Requirement already satisfied: pydantic<3.0.0,>=2.7.4 in c:\program files\python313\lib\site-packages (from langchain) (2.12.4)
Collecting jsonpatch<2.0.0,>=1.33.0 (from langchain-core<2.0.0,>=1.1.0->langchain)
  Downloading jsonpatch-1.33-py2.py3-none-any.whl.metadata (3.0 kB)
Collecting langsmith<1.0.0,>=0.3.45 (from langchain-core<2.0.0,>=1.1.0->langchain)
  Downloading langsmith-0.4.48-py3-none-any.whl.metadata (14 kB)
Requirement already satisfied: packaging<26.0.0,>=23.2.0 in c:\program files\python313\lib\site-packages (from langchain-core<2.0.0,>=1.1.0->langchain) (25.0)
Requirement already satisfied: pyyaml<7.0.0,>=5.3.0 in c:\program files\python313\lib\site-packages (from langchain-core<2.0.0,>=1.1.0->langchain) (6.0.3)
Requirement already satisfied: tenacity!=8.4.0,<10.0.0,>=8.1.0 in c:\program files\python313\lib\site-packages (from langchain-core<2.0.0,>=1.1.0->langchain) (9.1.2)
Requirement already satisfied: typing-extensions<5.0.0,>=4.7.0 in c:\program files\python313\lib\site-packages (from langchain-core<2.0.0,>=1.1.0->langchain) (4.15.0)
Requirement already satisfied: jsonpointer>=1.9 in c:\program files\python313\lib\site-packages (from jsonpatch<2.0.0,>=1.33.0->langchain-core<2.0.0,>=1.1.0->langchain) (3.0.0)
Collecting langgraph-checkpoint<4.0.0,>=2.1.0 (from langgraph<1.1.0,>=1.0.2->langchain)
  Downloading langgraph_checkpoint-3.0.1-py3-none-any.whl.metadata (4.7 kB)
Collecting langgraph-prebuilt<1.1.0,>=1.0.2 (from langgraph<1.1.0,>=1.0.2->langchain)
  Downloading langgraph_prebuilt-1.0.5-py3-none-any.whl.metadata (5.2 kB)
Collecting langgraph-sdk<0.3.0,>=0.2.2 (from langgraph<1.1.0,>=1.0.2->langchain)
  Downloading langgraph_sdk-0.2.10-py3-none-any.whl.metadata (1.6 kB)
Collecting xxhash>=3.5.0 (from langgraph<1.1.0,>=1.0.2->langchain)
  Downloading xxhash-3.6.0-cp313-cp313-win_amd64.whl.metadata (13 kB)
Collecting ormsgpack>=1.12.0 (from langgraph-checkpoint<4.0.0,>=2.1.0->langgraph<1.1.0,>=1.0.2->langchain)
  Downloading ormsgpack-1.12.0-cp313-cp313-win_amd64.whl.metadata (1.2 kB)
Requirement already satisfied: httpx>=0.25.2 in c:\program files\python313\lib\site-packages (from langgraph-sdk<0.3.0,>=0.2.2->langgraph<1.1.0,>=1.0.2->langchain) (0.28.1)
Requirement already satisfied: orjson>=3.10.1 in c:\program files\python313\lib\site-packages (from langgraph-sdk<0.3.0,>=0.2.2->langgraph<1.1.0,>=1.0.2->langchain) (3.11.4)
Collecting requests-toolbelt>=1.0.0 (from langsmith<1.0.0,>=0.3.45->langchain-core<2.0.0,>=1.1.0->langchain)
  Downloading requests_toolbelt-1.0.0-py2.py3-none-any.whl.metadata (14 kB)
Requirement already satisfied: requests>=2.0.0 in c:\program files\python313\lib\site-packages (from langsmith<1.0.0,>=0.3.45->langchain-core<2.0.0,>=1.1.0->langchain) (2.32.4)
Collecting zstandard>=0.23.0 (from langsmith<1.0.0,>=0.3.45->langchain-core<2.0.0,>=1.1.0->langchain)
  Downloading zstandard-0.25.0-cp313-cp313-win_amd64.whl.metadata (3.3 kB)
Requirement already satisfied: anyio in c:\program files\python313\lib\site-packages (from httpx>=0.25.2->langgraph-sdk<0.3.0,>=0.2.2->langgraph<1.1.0,>=1.0.2->langchain) (4.11.0)
Requirement already satisfied: certifi in c:\program files\python313\lib\site-packages (from httpx>=0.25.2->langgraph-sdk<0.3.0,>=0.2.2->langgraph<1.1.0,>=1.0.2->langchain) (2025.11.12)
Requirement already satisfied: httpcore==1.* in c:\program files\python313\lib\site-packages (from httpx>=0.25.2->langgraph-sdk<0.3.0,>=0.2.2->langgraph<1.1.0,>=1.0.2->langchain) (1.0.9)
Requirement already satisfied: idna in c:\program files\python313\lib\site-packages (from httpx>=0.25.2->langgraph-sdk<0.3.0,>=0.2.2->langgraph<1.1.0,>=1.0.2->langchain) (3.11)
Requirement already satisfied: h11>=0.16 in c:\program files\python313\lib\site-packages (from httpcore==1.*->httpx>=0.25.2->langgraph-sdk<0.3.0,>=0.2.2->langgraph<1.1.0,>=1.0.2->langchain) (0.16.0)
Requirement already satisfied: annotated-types>=0.6.0 in c:\program files\python313\lib\site-packages (from pydantic<3.0.0,>=2.7.4->langchain) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in c:\program files\python313\lib\site-packages (from pydantic<3.0.0,>=2.7.4->langchain) (2.41.5)
Requirement already satisfied: typing-inspection>=0.4.2 in c:\program files\python313\lib\site-packages (from pydantic<3.0.0,>=2.7.4->langchain) (0.4.2)
Requirement already satisfied: distro<2,>=1.7.0 in c:\program files\python313\lib\site-packages (from openai) (1.9.0)
Collecting jiter<1,>=0.10.0 (from openai)
  Downloading jiter-0.12.0-cp313-cp313-win_amd64.whl.metadata (5.3 kB)
Requirement already satisfied: sniffio in c:\program files\python313\lib\site-packages (from openai) (1.3.1)
Requirement already satisfied: tqdm>4 in c:\program files\python313\lib\site-packages (from openai) (4.67.1)
Requirement already satisfied: docstring-parser<1,>=0.15 in c:\program files\python313\lib\site-packages (from anthropic) (0.17.0)
Collecting llama-index-cli<0.6,>=0.5.0 (from llama-index)
  Downloading llama_index_cli-0.5.3-py3-none-any.whl.metadata (1.4 kB)
Collecting llama-index-core<0.15.0,>=0.14.8 (from llama-index)
  Downloading llama_index_core-0.14.8-py3-none-any.whl.metadata (2.5 kB)
Collecting llama-index-embeddings-openai<0.6,>=0.5.0 (from llama-index)
  Downloading llama_index_embeddings_openai-0.5.1-py3-none-any.whl.metadata (400 bytes)
Collecting llama-index-indices-managed-llama-cloud>=0.4.0 (from llama-index)
  Downloading llama_index_indices_managed_llama_cloud-0.9.4-py3-none-any.whl.metadata (3.7 kB)
Collecting llama-index-llms-openai<0.7,>=0.6.0 (from llama-index)
  Downloading llama_index_llms_openai-0.6.9-py3-none-any.whl.metadata (3.0 kB)
Collecting llama-index-readers-file<0.6,>=0.5.0 (from llama-index)
  Downloading llama_index_readers_file-0.5.5-py3-none-any.whl.metadata (5.7 kB)
Collecting llama-index-readers-llama-parse>=0.4.0 (from llama-index)
  Downloading llama_index_readers_llama_parse-0.5.1-py3-none-any.whl.metadata (3.1 kB)
Requirement already satisfied: nltk>3.8.1 in c:\program files\python313\lib\site-packages (from llama-index) (3.9.2)
Requirement already satisfied: aiohttp<4,>=3.8.6 in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (3.13.2)
Collecting aiosqlite (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading aiosqlite-0.21.0-py3-none-any.whl.metadata (4.3 kB)
Collecting banks<3,>=2.2.0 (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading banks-2.2.0-py3-none-any.whl.metadata (12 kB)
Collecting dataclasses-json (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading dataclasses_json-0.6.7-py3-none-any.whl.metadata (25 kB)
Collecting deprecated>=1.2.9.3 (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading deprecated-1.3.1-py2.py3-none-any.whl.metadata (5.9 kB)
Collecting dirtyjson<2,>=1.0.8 (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading dirtyjson-1.0.8-py3-none-any.whl.metadata (11 kB)
Collecting filetype<2,>=1.2.0 (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading filetype-1.2.0-py2.py3-none-any.whl.metadata (6.5 kB)
Requirement already satisfied: fsspec>=2023.5.0 in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (2025.9.0)
Collecting llama-index-workflows!=2.9.0,<3,>=2 (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading llama_index_workflows-2.11.5-py3-none-any.whl.metadata (4.7 kB)
Requirement already satisfied: nest-asyncio<2,>=1.5.8 in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (1.6.0)
Requirement already satisfied: networkx>=3.0 in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (3.5)
Requirement already satisfied: numpy in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (2.2.6)
Requirement already satisfied: pillow>=9.0.0 in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (12.0.0)
Requirement already satisfied: platformdirs in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (4.5.0)
Requirement already satisfied: setuptools>=80.9.0 in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (80.9.0)
Collecting sqlalchemy>=1.4.49 (from sqlalchemy[asyncio]>=1.4.49->llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading sqlalchemy-2.0.44-cp313-cp313-win_amd64.whl.metadata (9.8 kB)
Collecting tiktoken>=0.7.0 (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading tiktoken-0.12.0-cp313-cp313-win_amd64.whl.metadata (6.9 kB)
Collecting typing-inspect>=0.8.0 (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading typing_inspect-0.9.0-py3-none-any.whl.metadata (1.5 kB)
Requirement already satisfied: wrapt in c:\program files\python313\lib\site-packages (from llama-index-core<0.15.0,>=0.14.8->llama-index) (1.17.3)
Requirement already satisfied: aiohappyeyeballs>=2.5.0 in c:\program files\python313\lib\site-packages (from aiohttp<4,>=3.8.6->llama-index-core<0.15.0,>=0.14.8->llama-index) (2.6.1)
Requirement already satisfied: aiosignal>=1.4.0 in c:\program files\python313\lib\site-packages (from aiohttp<4,>=3.8.6->llama-index-core<0.15.0,>=0.14.8->llama-index) (1.4.0)
Requirement already satisfied: attrs>=17.3.0 in c:\program files\python313\lib\site-packages (from aiohttp<4,>=3.8.6->llama-index-core<0.15.0,>=0.14.8->llama-index) (25.4.0)
Requirement already satisfied: frozenlist>=1.1.1 in c:\program files\python313\lib\site-packages (from aiohttp<4,>=3.8.6->llama-index-core<0.15.0,>=0.14.8->llama-index) (1.8.0)
Requirement already satisfied: multidict<7.0,>=4.5 in c:\program files\python313\lib\site-packages (from aiohttp<4,>=3.8.6->llama-index-core<0.15.0,>=0.14.8->llama-index) (6.7.0)
Requirement already satisfied: propcache>=0.2.0 in c:\program files\python313\lib\site-packages (from aiohttp<4,>=3.8.6->llama-index-core<0.15.0,>=0.14.8->llama-index) (0.4.1)
Requirement already satisfied: yarl<2.0,>=1.17.0 in c:\program files\python313\lib\site-packages (from aiohttp<4,>=3.8.6->llama-index-core<0.15.0,>=0.14.8->llama-index) (1.22.0)
Collecting griffe (from banks<3,>=2.2.0->llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading griffe-1.15.0-py3-none-any.whl.metadata (5.2 kB)
Requirement already satisfied: jinja2 in c:\program files\python313\lib\site-packages (from banks<3,>=2.2.0->llama-index-core<0.15.0,>=0.14.8->llama-index) (3.1.6)
Requirement already satisfied: beautifulsoup4<5,>=4.12.3 in c:\program files\python313\lib\site-packages (from llama-index-readers-file<0.6,>=0.5.0->llama-index) (4.14.2)
Requirement already satisfied: defusedxml>=0.7.1 in c:\program files\python313\lib\site-packages (from llama-index-readers-file<0.6,>=0.5.0->llama-index) (0.7.1)
Collecting pandas<2.3.0 (from llama-index-readers-file<0.6,>=0.5.0->llama-index)
  Downloading pandas-2.2.3-cp313-cp313-win_amd64.whl.metadata (19 kB)
Collecting pypdf<7,>=6.1.3 (from llama-index-readers-file<0.6,>=0.5.0->llama-index)
  Downloading pypdf-6.4.0-py3-none-any.whl.metadata (7.1 kB)
Collecting striprtf<0.0.27,>=0.0.26 (from llama-index-readers-file<0.6,>=0.5.0->llama-index)
  Downloading striprtf-0.0.26-py3-none-any.whl.metadata (2.1 kB)
Requirement already satisfied: soupsieve>1.2 in c:\program files\python313\lib\site-packages (from beautifulsoup4<5,>=4.12.3->llama-index-readers-file<0.6,>=0.5.0->llama-index) (2.8)
Collecting llama-index-instrumentation>=0.1.0 (from llama-index-workflows!=2.9.0,<3,>=2->llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading llama_index_instrumentation-0.4.2-py3-none-any.whl.metadata (1.1 kB)
Requirement already satisfied: python-dateutil>=2.8.2 in c:\program files\python313\lib\site-packages (from pandas<2.3.0->llama-index-readers-file<0.6,>=0.5.0->llama-index) (2.9.0.post0)
Requirement already satisfied: pytz>=2020.1 in c:\program files\python313\lib\site-packages (from pandas<2.3.0->llama-index-readers-file<0.6,>=0.5.0->llama-index) (2025.2)
Requirement already satisfied: tzdata>=2022.7 in c:\program files\python313\lib\site-packages (from pandas<2.3.0->llama-index-readers-file<0.6,>=0.5.0->llama-index) (2025.2)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from tqdm>4->openai) (0.4.6)
Collecting deprecated>=1.2.9.3 (from llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading Deprecated-1.2.18-py2.py3-none-any.whl.metadata (5.7 kB)
Collecting llama-cloud==0.1.35 (from llama-index-indices-managed-llama-cloud>=0.4.0->llama-index)
  Downloading llama_cloud-0.1.35-py3-none-any.whl.metadata (1.2 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.83-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.82 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.83-py3-none-any.whl.metadata (3.3 kB)
Requirement already satisfied: click<9,>=8.1.7 in c:\program files\python313\lib\site-packages (from llama-cloud-services>=0.6.82->llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index) (8.3.1)
INFO: pip is looking at multiple versions of llama-cloud-services to determine which version is compatible with other requirements. This could take a while.
  Downloading llama_cloud_services-0.6.82-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.82-py3-none-any.whl.metadata (6.6 kB)
  Downloading llama_parse-0.6.81-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.81 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.81-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.80-py3-none-any.whl.metadata (6.6 kB)
INFO: pip is still looking at multiple versions of llama-cloud-services to determine which version is compatible with other requirements. This could take a while.
Collecting llama-cloud-services>=0.6.80 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.80-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.79-py3-none-any.whl.metadata (6.6 kB)
INFO: This is taking longer than usual. You might need to provide the dependency resolver with stricter constraints to reduce runtime. See https://pip.pypa.io/warnings/backtracking for guidance. If you want to abort this run, press Ctrl + C.
Collecting llama-cloud-services>=0.6.79 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.79-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.78-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.78 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.78-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.77-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.77 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.77-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.76-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.76 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.76-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.75-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.75 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.75-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.74-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.74 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.74-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.73-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.73 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.73-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.72-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.72 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.72-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.71-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.71 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.71-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.70-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.70 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.70-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.69-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.69 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.69-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.68-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.68 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.68-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.67-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.67 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.67-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.66-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.66 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.66-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.65-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.64 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.65-py3-none-any.whl.metadata (3.3 kB)
  Downloading llama_cloud_services-0.6.64-py3-none-any.whl.metadata (3.3 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.64-py3-none-any.whl.metadata (6.6 kB)
  Downloading llama_parse-0.6.63-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.63 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.63-py3-none-any.whl.metadata (3.7 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.62-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.62 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.62-py3-none-any.whl.metadata (3.7 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.60-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.60 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.60-py3-none-any.whl.metadata (3.7 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.59-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.59 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.59-py3-none-any.whl.metadata (3.7 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.58-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.58 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.58-py3-none-any.whl.metadata (3.7 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.57-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.56 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.57-py3-none-any.whl.metadata (3.7 kB)
  Downloading llama_cloud_services-0.6.56-py3-none-any.whl.metadata (3.7 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.56-py3-none-any.whl.metadata (6.6 kB)
  Downloading llama_parse-0.6.55-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.55 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.55-py3-none-any.whl.metadata (3.7 kB)
Collecting llama-parse>=0.5.0 (from llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_parse-0.6.54-py3-none-any.whl.metadata (6.6 kB)
Collecting llama-cloud-services>=0.6.54 (from llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index)
  Downloading llama_cloud_services-0.6.54-py3-none-any.whl.metadata (3.6 kB)
Requirement already satisfied: python-dotenv<2,>=1.0.1 in c:\program files\python313\lib\site-packages (from llama-cloud-services>=0.6.54->llama-parse>=0.5.0->llama-index-readers-llama-parse>=0.4.0->llama-index) (1.2.1)
Requirement already satisfied: joblib in c:\program files\python313\lib\site-packages (from nltk>3.8.1->llama-index) (1.5.2)
Requirement already satisfied: regex>=2021.8.3 in c:\program files\python313\lib\site-packages (from nltk>3.8.1->llama-index) (2025.11.3)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil>=2.8.2->pandas<2.3.0->llama-index-readers-file<0.6,>=0.5.0->llama-index) (1.17.0)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests>=2.0.0->langsmith<1.0.0,>=0.3.45->langchain-core<2.0.0,>=1.1.0->langchain) (3.4.4)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests>=2.0.0->langsmith<1.0.0,>=0.3.45->langchain-core<2.0.0,>=1.1.0->langchain) (2.5.0)
Requirement already satisfied: greenlet>=1 in c:\program files\python313\lib\site-packages (from sqlalchemy>=1.4.49->sqlalchemy[asyncio]>=1.4.49->llama-index-core<0.15.0,>=0.14.8->llama-index) (3.2.4)
Requirement already satisfied: mypy-extensions>=0.3.0 in c:\program files\python313\lib\site-packages (from typing-inspect>=0.8.0->llama-index-core<0.15.0,>=0.14.8->llama-index) (1.1.0)
Collecting marshmallow<4.0.0,>=3.18.0 (from dataclasses-json->llama-index-core<0.15.0,>=0.14.8->llama-index)
  Downloading marshmallow-3.26.1-py3-none-any.whl.metadata (7.3 kB)
Requirement already satisfied: MarkupSafe>=2.0 in c:\program files\python313\lib\site-packages (from jinja2->banks<3,>=2.2.0->llama-index-core<0.15.0,>=0.14.8->llama-index) (3.0.3)
Downloading langchain-1.1.0-py3-none-any.whl (101 kB)
Downloading langchain_core-1.1.0-py3-none-any.whl (473 kB)
Downloading jsonpatch-1.33-py2.py3-none-any.whl (12 kB)
Downloading langgraph-1.0.4-py3-none-any.whl (157 kB)
Downloading langgraph_checkpoint-3.0.1-py3-none-any.whl (46 kB)
Downloading langgraph_prebuilt-1.0.5-py3-none-any.whl (35 kB)
Downloading langgraph_sdk-0.2.10-py3-none-any.whl (58 kB)
Downloading langsmith-0.4.48-py3-none-any.whl (410 kB)
Downloading openai-2.8.1-py3-none-any.whl (1.0 MB)
   ---------------------------------------- 1.0/1.0 MB 20.6 MB/s  0:00:00
Downloading jiter-0.12.0-cp313-cp313-win_amd64.whl (204 kB)
Downloading anthropic-0.75.0-py3-none-any.whl (388 kB)
Downloading llama_index-0.14.8-py3-none-any.whl (7.4 kB)
Downloading llama_index_cli-0.5.3-py3-none-any.whl (28 kB)
Downloading llama_index_core-0.14.8-py3-none-any.whl (11.9 MB)
   ---------------------------------------- 11.9/11.9 MB 23.1 MB/s  0:00:00
Downloading banks-2.2.0-py3-none-any.whl (29 kB)
Downloading dirtyjson-1.0.8-py3-none-any.whl (25 kB)
Downloading filetype-1.2.0-py2.py3-none-any.whl (19 kB)
Downloading llama_index_embeddings_openai-0.5.1-py3-none-any.whl (7.0 kB)
Downloading llama_index_llms_openai-0.6.9-py3-none-any.whl (26 kB)
Downloading llama_index_readers_file-0.5.5-py3-none-any.whl (51 kB)
Downloading llama_index_workflows-2.11.5-py3-none-any.whl (91 kB)
Downloading pandas-2.2.3-cp313-cp313-win_amd64.whl (11.5 MB)
   ---------------------------------------- 11.5/11.5 MB 43.1 MB/s  0:00:00
Downloading pypdf-6.4.0-py3-none-any.whl (329 kB)
Downloading striprtf-0.0.26-py3-none-any.whl (6.9 kB)
Downloading llama_index_indices_managed_llama_cloud-0.9.4-py3-none-any.whl (17 kB)
Downloading Deprecated-1.2.18-py2.py3-none-any.whl (10.0 kB)
Downloading llama_cloud-0.1.35-py3-none-any.whl (303 kB)
Downloading llama_index_instrumentation-0.4.2-py3-none-any.whl (15 kB)
Downloading llama_index_readers_llama_parse-0.5.1-py3-none-any.whl (3.2 kB)
Downloading llama_parse-0.6.54-py3-none-any.whl (4.9 kB)
Downloading llama_cloud_services-0.6.54-py3-none-any.whl (63 kB)
Downloading ormsgpack-1.12.0-cp313-cp313-win_amd64.whl (112 kB)
Downloading requests_toolbelt-1.0.0-py2.py3-none-any.whl (54 kB)
Downloading sqlalchemy-2.0.44-cp313-cp313-win_amd64.whl (2.1 MB)
   ---------------------------------------- 2.1/2.1 MB 31.3 MB/s  0:00:00
Downloading tiktoken-0.12.0-cp313-cp313-win_amd64.whl (879 kB)
   ---------------------------------------- 879.1/879.1 kB 52.0 MB/s  0:00:00
Downloading typing_inspect-0.9.0-py3-none-any.whl (8.8 kB)
Downloading xxhash-3.6.0-cp313-cp313-win_amd64.whl (31 kB)
Downloading zstandard-0.25.0-cp313-cp313-win_amd64.whl (506 kB)
Downloading aiosqlite-0.21.0-py3-none-any.whl (15 kB)
Downloading dataclasses_json-0.6.7-py3-none-any.whl (28 kB)
Downloading marshmallow-3.26.1-py3-none-any.whl (50 kB)
Downloading griffe-1.15.0-py3-none-any.whl (150 kB)
Installing collected packages: striprtf, filetype, dirtyjson, zstandard, xxhash, typing-inspect, sqlalchemy, pypdf, ormsgpack, marshmallow, jsonpatch, jiter, griffe, deprecated, aiosqlite, tiktoken, requests-toolbelt, pandas, dataclasses-json, openai, llama-index-instrumentation, llama-cloud, langsmith, langgraph-sdk, banks, anthropic, llama-index-workflows, langchain-core, llama-index-core, langgraph-checkpoint, llama-index-readers-file, llama-index-llms-openai, llama-index-indices-managed-llama-cloud, llama-index-embeddings-openai, llama-cloud-services, langgraph-prebuilt, llama-parse, llama-index-cli, langgraph, llama-index-readers-llama-parse, langchain, llama-index
  Attempting uninstall: pandas
    Found existing installation: pandas 2.3.3
    Uninstalling pandas-2.3.3:
      Successfully uninstalled pandas-2.3.3
Successfully installed aiosqlite-0.21.0 anthropic-0.75.0 banks-2.2.0 dataclasses-json-0.6.7 deprecated-1.2.18 dirtyjson-1.0.8 filetype-1.2.0 griffe-1.15.0 jiter-0.12.0 jsonpatch-1.33 langchain-1.1.0 langchain-core-1.1.0 langgraph-1.0.4 langgraph-checkpoint-3.0.1 langgraph-prebuilt-1.0.5 langgraph-sdk-0.2.10 langsmith-0.4.48 llama-cloud-0.1.35 llama-cloud-services-0.6.54 llama-index-0.14.8 llama-index-cli-0.5.3 llama-index-core-0.14.8 llama-index-embeddings-openai-0.5.1 llama-index-indices-managed-llama-cloud-0.9.4 llama-index-instrumentation-0.4.2 llama-index-llms-openai-0.6.9 llama-index-readers-file-0.5.5 llama-index-readers-llama-parse-0.5.1 llama-index-workflows-2.11.5 llama-parse-0.6.54 marshmallow-3.26.1 openai-2.8.1 ormsgpack-1.12.0 pandas-2.2.3 pypdf-6.4.0 requests-toolbelt-1.0.0 sqlalchemy-2.0.44 striprtf-0.0.26 tiktoken-0.12.0 typing-inspect-0.9.0 xxhash-3.6.0 zstandard-0.25.0
Collecting mlflow
  Downloading mlflow-3.6.0-py3-none-any.whl.metadata (31 kB)
Collecting wandb
  Downloading wandb-0.23.0-py3-none-win_amd64.whl.metadata (12 kB)
Requirement already satisfied: tensorboard in c:\program files\python313\lib\site-packages (2.20.0)
Requirement already satisfied: dvc in c:\program files\python313\lib\site-packages (3.64.0)
Collecting mlflow-skinny==3.6.0 (from mlflow)
  Downloading mlflow_skinny-3.6.0-py3-none-any.whl.metadata (31 kB)
Collecting mlflow-tracing==3.6.0 (from mlflow)
  Downloading mlflow_tracing-3.6.0-py3-none-any.whl.metadata (19 kB)
Requirement already satisfied: Flask-CORS<7 in c:\program files\python313\lib\site-packages (from mlflow) (6.0.1)
Requirement already satisfied: Flask<4 in c:\program files\python313\lib\site-packages (from mlflow) (3.1.2)
Collecting alembic!=1.10.0,<2 (from mlflow)
  Downloading alembic-1.17.2-py3-none-any.whl.metadata (7.2 kB)
Requirement already satisfied: cryptography<47,>=43.0.0 in c:\program files\python313\lib\site-packages (from mlflow) (43.0.3)
Collecting docker<8,>=4.0.0 (from mlflow)
  Downloading docker-7.1.0-py3-none-any.whl.metadata (3.8 kB)
Collecting graphene<4 (from mlflow)
  Downloading graphene-3.4.3-py2.py3-none-any.whl.metadata (6.9 kB)
Collecting huey<3,>=2.5.0 (from mlflow)
  Downloading huey-2.5.4-py3-none-any.whl.metadata (4.6 kB)
Requirement already satisfied: matplotlib<4 in c:\program files\python313\lib\site-packages (from mlflow) (3.10.7)
Requirement already satisfied: numpy<3 in c:\program files\python313\lib\site-packages (from mlflow) (2.2.6)
Requirement already satisfied: pandas<3 in c:\program files\python313\lib\site-packages (from mlflow) (2.2.3)
Requirement already satisfied: pyarrow<23,>=4.0.0 in c:\program files\python313\lib\site-packages (from mlflow) (21.0.0)
Requirement already satisfied: scikit-learn<2 in c:\program files\python313\lib\site-packages (from mlflow) (1.7.2)
Requirement already satisfied: scipy<2 in c:\program files\python313\lib\site-packages (from mlflow) (1.16.3)
Requirement already satisfied: sqlalchemy<3,>=1.4.0 in c:\program files\python313\lib\site-packages (from mlflow) (2.0.44)
Collecting waitress<4 (from mlflow)
  Downloading waitress-3.0.2-py3-none-any.whl.metadata (5.8 kB)
Requirement already satisfied: cachetools<7,>=5.0.0 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (6.2.2)
Requirement already satisfied: click<9,>=7.0 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (8.3.1)
Collecting cloudpickle<4 (from mlflow-skinny==3.6.0->mlflow)
  Downloading cloudpickle-3.1.2-py3-none-any.whl.metadata (7.1 kB)
Collecting databricks-sdk<1,>=0.20.0 (from mlflow-skinny==3.6.0->mlflow)
  Downloading databricks_sdk-0.73.0-py3-none-any.whl.metadata (40 kB)
Requirement already satisfied: fastapi<1 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (0.122.0)
Requirement already satisfied: gitpython<4,>=3.1.9 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (3.1.45)
Requirement already satisfied: importlib_metadata!=4.7.0,<9,>=3.7.0 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (8.7.0)
Collecting opentelemetry-api<3,>=1.9.0 (from mlflow-skinny==3.6.0->mlflow)
  Downloading opentelemetry_api-1.38.0-py3-none-any.whl.metadata (1.5 kB)
Collecting opentelemetry-proto<3,>=1.9.0 (from mlflow-skinny==3.6.0->mlflow)
  Downloading opentelemetry_proto-1.38.0-py3-none-any.whl.metadata (2.3 kB)
Collecting opentelemetry-sdk<3,>=1.9.0 (from mlflow-skinny==3.6.0->mlflow)
  Downloading opentelemetry_sdk-1.38.0-py3-none-any.whl.metadata (1.5 kB)
Requirement already satisfied: packaging<26 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (25.0)
Requirement already satisfied: protobuf<7,>=3.12.0 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (6.33.1)
Requirement already satisfied: pydantic<3,>=2.0.0 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (2.12.4)
Requirement already satisfied: python-dotenv<2,>=0.19.0 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (1.2.1)
Requirement already satisfied: pyyaml<7,>=5.1 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (6.0.3)
Requirement already satisfied: requests<3,>=2.17.3 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (2.32.4)
Requirement already satisfied: sqlparse<1,>=0.4.0 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (0.5.3)
Requirement already satisfied: typing-extensions<5,>=4.0.0 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (4.15.0)
Requirement already satisfied: uvicorn<1 in c:\program files\python313\lib\site-packages (from mlflow-skinny==3.6.0->mlflow) (0.38.0)
Collecting Mako (from alembic!=1.10.0,<2->mlflow)
  Downloading mako-1.3.10-py3-none-any.whl.metadata (2.9 kB)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from click<9,>=7.0->mlflow-skinny==3.6.0->mlflow) (0.4.6)
Requirement already satisfied: cffi>=1.12 in c:\program files\python313\lib\site-packages (from cryptography<47,>=43.0.0->mlflow) (2.0.0)
Requirement already satisfied: google-auth~=2.0 in c:\program files\python313\lib\site-packages (from databricks-sdk<1,>=0.20.0->mlflow-skinny==3.6.0->mlflow) (2.41.1)
Requirement already satisfied: pywin32>=304 in c:\program files\python313\lib\site-packages (from docker<8,>=4.0.0->mlflow) (307)
Requirement already satisfied: urllib3>=1.26.0 in c:\program files\python313\lib\site-packages (from docker<8,>=4.0.0->mlflow) (2.5.0)
Requirement already satisfied: starlette<0.51.0,>=0.40.0 in c:\program files\python313\lib\site-packages (from fastapi<1->mlflow-skinny==3.6.0->mlflow) (0.50.0)
Requirement already satisfied: annotated-doc>=0.0.2 in c:\program files\python313\lib\site-packages (from fastapi<1->mlflow-skinny==3.6.0->mlflow) (0.0.4)
Requirement already satisfied: blinker>=1.9.0 in c:\program files\python313\lib\site-packages (from Flask<4->mlflow) (1.9.0)
Requirement already satisfied: itsdangerous>=2.2.0 in c:\program files\python313\lib\site-packages (from Flask<4->mlflow) (2.2.0)
Requirement already satisfied: jinja2>=3.1.2 in c:\program files\python313\lib\site-packages (from Flask<4->mlflow) (3.1.6)
Requirement already satisfied: markupsafe>=2.1.1 in c:\program files\python313\lib\site-packages (from Flask<4->mlflow) (3.0.3)
Requirement already satisfied: werkzeug>=3.1.0 in c:\program files\python313\lib\site-packages (from Flask<4->mlflow) (3.1.3)
Requirement already satisfied: gitdb<5,>=4.0.1 in c:\program files\python313\lib\site-packages (from gitpython<4,>=3.1.9->mlflow-skinny==3.6.0->mlflow) (4.0.12)
Requirement already satisfied: smmap<6,>=3.0.1 in c:\program files\python313\lib\site-packages (from gitdb<5,>=4.0.1->gitpython<4,>=3.1.9->mlflow-skinny==3.6.0->mlflow) (5.0.2)
Requirement already satisfied: pyasn1-modules>=0.2.1 in c:\program files\python313\lib\site-packages (from google-auth~=2.0->databricks-sdk<1,>=0.20.0->mlflow-skinny==3.6.0->mlflow) (0.4.2)
Requirement already satisfied: rsa<5,>=3.1.4 in c:\program files\python313\lib\site-packages (from google-auth~=2.0->databricks-sdk<1,>=0.20.0->mlflow-skinny==3.6.0->mlflow) (4.9.1)
Collecting graphql-core<3.3,>=3.1 (from graphene<4->mlflow)
  Downloading graphql_core-3.2.7-py3-none-any.whl.metadata (11 kB)
Collecting graphql-relay<3.3,>=3.1 (from graphene<4->mlflow)
  Downloading graphql_relay-3.2.0-py3-none-any.whl.metadata (12 kB)
Requirement already satisfied: python-dateutil<3,>=2.7.0 in c:\program files\python313\lib\site-packages (from graphene<4->mlflow) (2.9.0.post0)
Requirement already satisfied: zipp>=3.20 in c:\program files\python313\lib\site-packages (from importlib_metadata!=4.7.0,<9,>=3.7.0->mlflow-skinny==3.6.0->mlflow) (3.23.0)
Requirement already satisfied: contourpy>=1.0.1 in c:\program files\python313\lib\site-packages (from matplotlib<4->mlflow) (1.3.3)
Requirement already satisfied: cycler>=0.10 in c:\program files\python313\lib\site-packages (from matplotlib<4->mlflow) (0.12.1)
Requirement already satisfied: fonttools>=4.22.0 in c:\program files\python313\lib\site-packages (from matplotlib<4->mlflow) (4.60.1)
Requirement already satisfied: kiwisolver>=1.3.1 in c:\program files\python313\lib\site-packages (from matplotlib<4->mlflow) (1.4.9)
Requirement already satisfied: pillow>=8 in c:\program files\python313\lib\site-packages (from matplotlib<4->mlflow) (12.0.0)
Requirement already satisfied: pyparsing>=3 in c:\program files\python313\lib\site-packages (from matplotlib<4->mlflow) (3.2.5)
Collecting opentelemetry-semantic-conventions==0.59b0 (from opentelemetry-sdk<3,>=1.9.0->mlflow-skinny==3.6.0->mlflow)
  Downloading opentelemetry_semantic_conventions-0.59b0-py3-none-any.whl.metadata (2.4 kB)
Requirement already satisfied: pytz>=2020.1 in c:\program files\python313\lib\site-packages (from pandas<3->mlflow) (2025.2)
Requirement already satisfied: tzdata>=2022.7 in c:\program files\python313\lib\site-packages (from pandas<3->mlflow) (2025.2)
Requirement already satisfied: annotated-types>=0.6.0 in c:\program files\python313\lib\site-packages (from pydantic<3,>=2.0.0->mlflow-skinny==3.6.0->mlflow) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in c:\program files\python313\lib\site-packages (from pydantic<3,>=2.0.0->mlflow-skinny==3.6.0->mlflow) (2.41.5)
Requirement already satisfied: typing-inspection>=0.4.2 in c:\program files\python313\lib\site-packages (from pydantic<3,>=2.0.0->mlflow-skinny==3.6.0->mlflow) (0.4.2)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil<3,>=2.7.0->graphene<4->mlflow) (1.17.0)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests<3,>=2.17.3->mlflow-skinny==3.6.0->mlflow) (3.4.4)
Requirement already satisfied: idna<4,>=2.5 in c:\program files\python313\lib\site-packages (from requests<3,>=2.17.3->mlflow-skinny==3.6.0->mlflow) (3.11)
Requirement already satisfied: certifi>=2017.4.17 in c:\program files\python313\lib\site-packages (from requests<3,>=2.17.3->mlflow-skinny==3.6.0->mlflow) (2025.11.12)
Requirement already satisfied: pyasn1>=0.1.3 in c:\program files\python313\lib\site-packages (from rsa<5,>=3.1.4->google-auth~=2.0->databricks-sdk<1,>=0.20.0->mlflow-skinny==3.6.0->mlflow) (0.6.1)
Requirement already satisfied: joblib>=1.2.0 in c:\program files\python313\lib\site-packages (from scikit-learn<2->mlflow) (1.5.2)
Requirement already satisfied: threadpoolctl>=3.1.0 in c:\program files\python313\lib\site-packages (from scikit-learn<2->mlflow) (3.6.0)
Requirement already satisfied: greenlet>=1 in c:\program files\python313\lib\site-packages (from sqlalchemy<3,>=1.4.0->mlflow) (3.2.4)
Requirement already satisfied: anyio<5,>=3.6.2 in c:\program files\python313\lib\site-packages (from starlette<0.51.0,>=0.40.0->fastapi<1->mlflow-skinny==3.6.0->mlflow) (4.11.0)
Requirement already satisfied: sniffio>=1.1 in c:\program files\python313\lib\site-packages (from anyio<5,>=3.6.2->starlette<0.51.0,>=0.40.0->fastapi<1->mlflow-skinny==3.6.0->mlflow) (1.3.1)
Requirement already satisfied: h11>=0.8 in c:\program files\python313\lib\site-packages (from uvicorn<1->mlflow-skinny==3.6.0->mlflow) (0.16.0)
Requirement already satisfied: platformdirs in c:\program files\python313\lib\site-packages (from wandb) (4.5.0)
Collecting sentry-sdk>=2.0.0 (from wandb)
  Downloading sentry_sdk-2.46.0-py2.py3-none-any.whl.metadata (10 kB)
Requirement already satisfied: absl-py>=0.4 in c:\program files\python313\lib\site-packages (from tensorboard) (2.3.1)
Requirement already satisfied: grpcio>=1.48.2 in c:\program files\python313\lib\site-packages (from tensorboard) (1.76.0)
Requirement already satisfied: markdown>=2.6.8 in c:\program files\python313\lib\site-packages (from tensorboard) (3.10)
Requirement already satisfied: setuptools>=41.0.0 in c:\program files\python313\lib\site-packages (from tensorboard) (80.9.0)
Requirement already satisfied: tensorboard-data-server<0.8.0,>=0.7.0 in c:\program files\python313\lib\site-packages (from tensorboard) (0.7.2)
Requirement already satisfied: attrs>=22.2.0 in c:\program files\python313\lib\site-packages (from dvc) (25.4.0)
Requirement already satisfied: celery in c:\program files\python313\lib\site-packages (from dvc) (5.5.3)
Requirement already satisfied: configobj>=5.0.9 in c:\program files\python313\lib\site-packages (from dvc) (5.0.9)
Requirement already satisfied: distro>=1.3 in c:\program files\python313\lib\site-packages (from dvc) (1.9.0)
Requirement already satisfied: dpath<3,>=2.1.0 in c:\program files\python313\lib\site-packages (from dvc) (2.2.0)
Requirement already satisfied: dulwich in c:\program files\python313\lib\site-packages (from dvc) (0.24.10)
Requirement already satisfied: dvc-data<3.17,>=3.16.2 in c:\program files\python313\lib\site-packages (from dvc) (3.16.12)
Requirement already satisfied: dvc-http>=2.29.0 in c:\program files\python313\lib\site-packages (from dvc) (2.32.0)
Requirement already satisfied: dvc-objects in c:\program files\python313\lib\site-packages (from dvc) (5.1.2)
Requirement already satisfied: dvc-render<2,>=1.0.1 in c:\program files\python313\lib\site-packages (from dvc) (1.0.2)
Requirement already satisfied: dvc-studio-client<1,>=0.21 in c:\program files\python313\lib\site-packages (from dvc) (0.22.0)
Requirement already satisfied: dvc-task<1,>=0.3.0 in c:\program files\python313\lib\site-packages (from dvc) (0.40.2)
Requirement already satisfied: flatten_dict<1,>=0.4.1 in c:\program files\python313\lib\site-packages (from dvc) (0.4.2)
Requirement already satisfied: flufl.lock<9,>=8.1.0 in c:\program files\python313\lib\site-packages (from dvc) (8.2.0)
Requirement already satisfied: fsspec>=2024.2.0 in c:\program files\python313\lib\site-packages (from dvc) (2025.9.0)
Requirement already satisfied: funcy>=1.14 in c:\program files\python313\lib\site-packages (from dvc) (2.0)
Requirement already satisfied: grandalf<1,>=0.7 in c:\program files\python313\lib\site-packages (from dvc) (0.8)
Requirement already satisfied: gto<2,>=1.6.0 in c:\program files\python313\lib\site-packages (from dvc) (1.9.0)
Requirement already satisfied: hydra-core>=1.1 in c:\program files\python313\lib\site-packages (from dvc) (1.3.2)
Requirement already satisfied: iterative-telemetry>=0.0.7 in c:\program files\python313\lib\site-packages (from dvc) (0.0.10)
Requirement already satisfied: kombu in c:\program files\python313\lib\site-packages (from dvc) (5.5.4)
Requirement already satisfied: networkx>=2.5 in c:\program files\python313\lib\site-packages (from dvc) (3.5)
Requirement already satisfied: omegaconf in c:\program files\python313\lib\site-packages (from dvc) (2.3.0)
Requirement already satisfied: pathspec>=0.10.3 in c:\program files\python313\lib\site-packages (from dvc) (0.12.1)
Requirement already satisfied: psutil>=5.8 in c:\program files\python313\lib\site-packages (from dvc) (7.1.3)
Requirement already satisfied: pydot>=1.2.4 in c:\program files\python313\lib\site-packages (from dvc) (4.0.1)
Requirement already satisfied: pygtrie>=2.3.2 in c:\program files\python313\lib\site-packages (from dvc) (2.5.0)
Requirement already satisfied: rich>=12 in c:\program files\python313\lib\site-packages (from dvc) (14.2.0)
Requirement already satisfied: ruamel.yaml>=0.17.11 in c:\program files\python313\lib\site-packages (from dvc) (0.18.16)
Requirement already satisfied: scmrepo<4,>=3.5.2 in c:\program files\python313\lib\site-packages (from dvc) (3.5.5)
Requirement already satisfied: shortuuid>=0.5 in c:\program files\python313\lib\site-packages (from dvc) (1.0.13)
Requirement already satisfied: shtab<2,>=1.3.4 in c:\program files\python313\lib\site-packages (from dvc) (1.8.0)
Requirement already satisfied: tabulate>=0.8.7 in c:\program files\python313\lib\site-packages (from dvc) (0.9.0)
Requirement already satisfied: tomlkit>=0.11.1 in c:\program files\python313\lib\site-packages (from dvc) (0.13.3)
Requirement already satisfied: tqdm<5,>=4.63.1 in c:\program files\python313\lib\site-packages (from dvc) (4.67.1)
Requirement already satisfied: voluptuous>=0.11.7 in c:\program files\python313\lib\site-packages (from dvc) (0.15.2)
Requirement already satisfied: zc.lockfile>=1.2.1 in c:\program files\python313\lib\site-packages (from dvc) (4.0)
Requirement already satisfied: dictdiffer>=0.8.1 in c:\program files\python313\lib\site-packages (from dvc-data<3.17,>=3.16.2->dvc) (0.9.0)
Requirement already satisfied: diskcache>=5.2.1 in c:\program files\python313\lib\site-packages (from dvc-data<3.17,>=3.16.2->dvc) (5.6.3)
Requirement already satisfied: sqltrie<1,>=0.11.0 in c:\program files\python313\lib\site-packages (from dvc-data<3.17,>=3.16.2->dvc) (0.11.2)
Requirement already satisfied: orjson<4,>=3 in c:\program files\python313\lib\site-packages (from dvc-data<3.17,>=3.16.2->dvc) (3.11.4)
Requirement already satisfied: billiard<5.0,>=4.2.1 in c:\program files\python313\lib\site-packages (from celery->dvc) (4.2.3)
Requirement already satisfied: vine<6.0,>=5.1.0 in c:\program files\python313\lib\site-packages (from celery->dvc) (5.1.0)
Requirement already satisfied: click-didyoumean>=0.3.0 in c:\program files\python313\lib\site-packages (from celery->dvc) (0.3.1)
Requirement already satisfied: click-repl>=0.2.0 in c:\program files\python313\lib\site-packages (from celery->dvc) (0.3.0)
Requirement already satisfied: click-plugins>=1.1.1 in c:\program files\python313\lib\site-packages (from celery->dvc) (1.1.1.2)
Requirement already satisfied: atpublic in c:\program files\python313\lib\site-packages (from flufl.lock<9,>=8.1.0->dvc) (6.0.2)
Requirement already satisfied: entrypoints in c:\program files\python313\lib\site-packages (from gto<2,>=1.6.0->dvc) (0.4)
Requirement already satisfied: pydantic-settings>=2 in c:\program files\python313\lib\site-packages (from gto<2,>=1.6.0->dvc) (2.12.0)
Requirement already satisfied: semver>=2.13.0 in c:\program files\python313\lib\site-packages (from gto<2,>=1.6.0->dvc) (3.0.4)
Requirement already satisfied: typer>=0.4.1 in c:\program files\python313\lib\site-packages (from gto<2,>=1.6.0->dvc) (0.20.0)
Requirement already satisfied: amqp<6.0.0,>=5.1.1 in c:\program files\python313\lib\site-packages (from kombu->dvc) (5.3.1)
Requirement already satisfied: pygit2>=1.14.0 in c:\program files\python313\lib\site-packages (from scmrepo<4,>=3.5.2->dvc) (1.19.0)
Requirement already satisfied: asyncssh<3,>=2.13.1 in c:\program files\python313\lib\site-packages (from scmrepo<4,>=3.5.2->dvc) (2.21.1)
Requirement already satisfied: aiohttp-retry>=2.5.0 in c:\program files\python313\lib\site-packages (from scmrepo<4,>=3.5.2->dvc) (2.9.1)
Requirement already satisfied: aiohttp in c:\program files\python313\lib\site-packages (from aiohttp-retry>=2.5.0->scmrepo<4,>=3.5.2->dvc) (3.13.2)
Requirement already satisfied: pycparser in c:\program files\python313\lib\site-packages (from cffi>=1.12->cryptography<47,>=43.0.0->mlflow) (2.23)
Requirement already satisfied: prompt-toolkit>=3.0.36 in c:\program files\python313\lib\site-packages (from click-repl>=0.2.0->celery->dvc) (3.0.52)
Requirement already satisfied: antlr4-python3-runtime==4.9.* in c:\program files\python313\lib\site-packages (from hydra-core>=1.1->dvc) (4.9.3)
Requirement already satisfied: appdirs in c:\program files\python313\lib\site-packages (from iterative-telemetry>=0.0.7->dvc) (1.4.4)
Requirement already satisfied: filelock in c:\program files\python313\lib\site-packages (from iterative-telemetry>=0.0.7->dvc) (3.19.1)
Requirement already satisfied: wcwidth in c:\program files\python313\lib\site-packages (from prompt-toolkit>=3.0.36->click-repl>=0.2.0->celery->dvc) (0.2.14)
Requirement already satisfied: markdown-it-py>=2.2.0 in c:\program files\python313\lib\site-packages (from rich>=12->dvc) (4.0.0)
Requirement already satisfied: pygments<3.0.0,>=2.13.0 in c:\program files\python313\lib\site-packages (from rich>=12->dvc) (2.19.2)
Requirement already satisfied: mdurl~=0.1 in c:\program files\python313\lib\site-packages (from markdown-it-py>=2.2.0->rich>=12->dvc) (0.1.2)
Requirement already satisfied: ruamel.yaml.clib>=0.2.7 in c:\program files\python313\lib\site-packages (from ruamel.yaml>=0.17.11->dvc) (0.2.15)
Requirement already satisfied: shellingham>=1.3.0 in c:\program files\python313\lib\site-packages (from typer>=0.4.1->gto<2,>=1.6.0->dvc) (1.5.4)
Requirement already satisfied: aiohappyeyeballs>=2.5.0 in c:\program files\python313\lib\site-packages (from aiohttp->aiohttp-retry>=2.5.0->scmrepo<4,>=3.5.2->dvc) (2.6.1)
Requirement already satisfied: aiosignal>=1.4.0 in c:\program files\python313\lib\site-packages (from aiohttp->aiohttp-retry>=2.5.0->scmrepo<4,>=3.5.2->dvc) (1.4.0)
Requirement already satisfied: frozenlist>=1.1.1 in c:\program files\python313\lib\site-packages (from aiohttp->aiohttp-retry>=2.5.0->scmrepo<4,>=3.5.2->dvc) (1.8.0)
Requirement already satisfied: multidict<7.0,>=4.5 in c:\program files\python313\lib\site-packages (from aiohttp->aiohttp-retry>=2.5.0->scmrepo<4,>=3.5.2->dvc) (6.7.0)
Requirement already satisfied: propcache>=0.2.0 in c:\program files\python313\lib\site-packages (from aiohttp->aiohttp-retry>=2.5.0->scmrepo<4,>=3.5.2->dvc) (0.4.1)
Requirement already satisfied: yarl<2.0,>=1.17.0 in c:\program files\python313\lib\site-packages (from aiohttp->aiohttp-retry>=2.5.0->scmrepo<4,>=3.5.2->dvc) (1.22.0)
Downloading mlflow-3.6.0-py3-none-any.whl (8.9 MB)
   ---------------------------------------- 8.9/8.9 MB 22.6 MB/s  0:00:00
Downloading mlflow_skinny-3.6.0-py3-none-any.whl (2.4 MB)
   ---------------------------------------- 2.4/2.4 MB 64.8 MB/s  0:00:00
Downloading mlflow_tracing-3.6.0-py3-none-any.whl (1.3 MB)
   ---------------------------------------- 1.3/1.3 MB 71.2 MB/s  0:00:00
Downloading alembic-1.17.2-py3-none-any.whl (248 kB)
Downloading cloudpickle-3.1.2-py3-none-any.whl (22 kB)
Downloading databricks_sdk-0.73.0-py3-none-any.whl (753 kB)
   ---------------------------------------- 753.9/753.9 kB 74.4 MB/s  0:00:00
Downloading docker-7.1.0-py3-none-any.whl (147 kB)
Downloading graphene-3.4.3-py2.py3-none-any.whl (114 kB)
Downloading graphql_core-3.2.7-py3-none-any.whl (207 kB)
Downloading graphql_relay-3.2.0-py3-none-any.whl (16 kB)
Downloading huey-2.5.4-py3-none-any.whl (76 kB)
Downloading opentelemetry_api-1.38.0-py3-none-any.whl (65 kB)
Downloading opentelemetry_proto-1.38.0-py3-none-any.whl (72 kB)
Downloading opentelemetry_sdk-1.38.0-py3-none-any.whl (132 kB)
Downloading opentelemetry_semantic_conventions-0.59b0-py3-none-any.whl (207 kB)
Downloading waitress-3.0.2-py3-none-any.whl (56 kB)
Downloading wandb-0.23.0-py3-none-win_amd64.whl (19.4 MB)
   ---------------------------------------- 19.4/19.4 MB 40.3 MB/s  0:00:00
Downloading sentry_sdk-2.46.0-py2.py3-none-any.whl (406 kB)
Downloading mako-1.3.10-py3-none-any.whl (78 kB)
Installing collected packages: huey, waitress, sentry-sdk, opentelemetry-proto, Mako, graphql-core, cloudpickle, opentelemetry-api, graphql-relay, docker, alembic, wandb, opentelemetry-semantic-conventions, graphene, databricks-sdk, opentelemetry-sdk, mlflow-tracing, mlflow-skinny, mlflow
Successfully installed Mako-1.3.10 alembic-1.17.2 cloudpickle-3.1.2 databricks-sdk-0.73.0 docker-7.1.0 graphene-3.4.3 graphql-core-3.2.7 graphql-relay-3.2.0 huey-2.5.4 mlflow-3.6.0 mlflow-skinny-3.6.0 mlflow-tracing-3.6.0 opentelemetry-api-1.38.0 opentelemetry-proto-1.38.0 opentelemetry-sdk-1.38.0 opentelemetry-semantic-conventions-0.59b0 sentry-sdk-2.46.0 waitress-3.0.2 wandb-0.23.0
Requirement already satisfied: django in c:\program files\python313\lib\site-packages (5.2.8)
Collecting djangorestframework
  Downloading djangorestframework-3.16.1-py3-none-any.whl.metadata (11 kB)
Requirement already satisfied: flask in c:\program files\python313\lib\site-packages (3.1.2)
Requirement already satisfied: fastapi in c:\program files\python313\lib\site-packages (0.122.0)
Requirement already satisfied: uvicorn in c:\program files\python313\lib\site-packages (0.38.0)
Requirement already satisfied: streamlit in c:\program files\python313\lib\site-packages (1.51.0)
Requirement already satisfied: dash in c:\program files\python313\lib\site-packages (3.3.0)
Requirement already satisfied: asgiref>=3.8.1 in c:\program files\python313\lib\site-packages (from django) (3.11.0)
Requirement already satisfied: sqlparse>=0.3.1 in c:\program files\python313\lib\site-packages (from django) (0.5.3)
Requirement already satisfied: tzdata in c:\program files\python313\lib\site-packages (from django) (2025.2)
Requirement already satisfied: blinker>=1.9.0 in c:\program files\python313\lib\site-packages (from flask) (1.9.0)
Requirement already satisfied: click>=8.1.3 in c:\program files\python313\lib\site-packages (from flask) (8.3.1)
Requirement already satisfied: itsdangerous>=2.2.0 in c:\program files\python313\lib\site-packages (from flask) (2.2.0)
Requirement already satisfied: jinja2>=3.1.2 in c:\program files\python313\lib\site-packages (from flask) (3.1.6)
Requirement already satisfied: markupsafe>=2.1.1 in c:\program files\python313\lib\site-packages (from flask) (3.0.3)
Requirement already satisfied: werkzeug>=3.1.0 in c:\program files\python313\lib\site-packages (from flask) (3.1.3)
Requirement already satisfied: starlette<0.51.0,>=0.40.0 in c:\program files\python313\lib\site-packages (from fastapi) (0.50.0)
Requirement already satisfied: pydantic!=1.8,!=1.8.1,!=2.0.0,!=2.0.1,!=2.1.0,<3.0.0,>=1.7.4 in c:\program files\python313\lib\site-packages (from fastapi) (2.12.4)
Requirement already satisfied: typing-extensions>=4.8.0 in c:\program files\python313\lib\site-packages (from fastapi) (4.15.0)
Requirement already satisfied: annotated-doc>=0.0.2 in c:\program files\python313\lib\site-packages (from fastapi) (0.0.4)
Requirement already satisfied: annotated-types>=0.6.0 in c:\program files\python313\lib\site-packages (from pydantic!=1.8,!=1.8.1,!=2.0.0,!=2.0.1,!=2.1.0,<3.0.0,>=1.7.4->fastapi) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in c:\program files\python313\lib\site-packages (from pydantic!=1.8,!=1.8.1,!=2.0.0,!=2.0.1,!=2.1.0,<3.0.0,>=1.7.4->fastapi) (2.41.5)
Requirement already satisfied: typing-inspection>=0.4.2 in c:\program files\python313\lib\site-packages (from pydantic!=1.8,!=1.8.1,!=2.0.0,!=2.0.1,!=2.1.0,<3.0.0,>=1.7.4->fastapi) (0.4.2)
Requirement already satisfied: anyio<5,>=3.6.2 in c:\program files\python313\lib\site-packages (from starlette<0.51.0,>=0.40.0->fastapi) (4.11.0)
Requirement already satisfied: idna>=2.8 in c:\program files\python313\lib\site-packages (from anyio<5,>=3.6.2->starlette<0.51.0,>=0.40.0->fastapi) (3.11)
Requirement already satisfied: sniffio>=1.1 in c:\program files\python313\lib\site-packages (from anyio<5,>=3.6.2->starlette<0.51.0,>=0.40.0->fastapi) (1.3.1)
Requirement already satisfied: h11>=0.8 in c:\program files\python313\lib\site-packages (from uvicorn) (0.16.0)
Requirement already satisfied: altair!=5.4.0,!=5.4.1,<6,>=4.0 in c:\program files\python313\lib\site-packages (from streamlit) (5.5.0)
Requirement already satisfied: cachetools<7,>=4.0 in c:\program files\python313\lib\site-packages (from streamlit) (6.2.2)
Requirement already satisfied: numpy<3,>=1.23 in c:\program files\python313\lib\site-packages (from streamlit) (2.2.6)
Requirement already satisfied: packaging<26,>=20 in c:\program files\python313\lib\site-packages (from streamlit) (25.0)
Requirement already satisfied: pandas<3,>=1.4.0 in c:\program files\python313\lib\site-packages (from streamlit) (2.2.3)
Requirement already satisfied: pillow<13,>=7.1.0 in c:\program files\python313\lib\site-packages (from streamlit) (12.0.0)
Requirement already satisfied: protobuf<7,>=3.20 in c:\program files\python313\lib\site-packages (from streamlit) (6.33.1)
Requirement already satisfied: pyarrow<22,>=7.0 in c:\program files\python313\lib\site-packages (from streamlit) (21.0.0)
Requirement already satisfied: requests<3,>=2.27 in c:\program files\python313\lib\site-packages (from streamlit) (2.32.4)
Requirement already satisfied: tenacity<10,>=8.1.0 in c:\program files\python313\lib\site-packages (from streamlit) (9.1.2)
Requirement already satisfied: toml<2,>=0.10.1 in c:\program files\python313\lib\site-packages (from streamlit) (0.10.2)
Requirement already satisfied: watchdog<7,>=2.1.5 in c:\program files\python313\lib\site-packages (from streamlit) (6.0.0)
Requirement already satisfied: gitpython!=3.1.19,<4,>=3.0.7 in c:\program files\python313\lib\site-packages (from streamlit) (3.1.45)
Requirement already satisfied: pydeck<1,>=0.8.0b4 in c:\program files\python313\lib\site-packages (from streamlit) (0.9.1)
Requirement already satisfied: tornado!=6.5.0,<7,>=6.0.3 in c:\program files\python313\lib\site-packages (from streamlit) (6.5.2)
Requirement already satisfied: jsonschema>=3.0 in c:\program files\python313\lib\site-packages (from altair!=5.4.0,!=5.4.1,<6,>=4.0->streamlit) (4.25.1)
Requirement already satisfied: narwhals>=1.14.2 in c:\program files\python313\lib\site-packages (from altair!=5.4.0,!=5.4.1,<6,>=4.0->streamlit) (2.12.0)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from click>=8.1.3->flask) (0.4.6)
Requirement already satisfied: gitdb<5,>=4.0.1 in c:\program files\python313\lib\site-packages (from gitpython!=3.1.19,<4,>=3.0.7->streamlit) (4.0.12)
Requirement already satisfied: smmap<6,>=3.0.1 in c:\program files\python313\lib\site-packages (from gitdb<5,>=4.0.1->gitpython!=3.1.19,<4,>=3.0.7->streamlit) (5.0.2)
Requirement already satisfied: python-dateutil>=2.8.2 in c:\program files\python313\lib\site-packages (from pandas<3,>=1.4.0->streamlit) (2.9.0.post0)
Requirement already satisfied: pytz>=2020.1 in c:\program files\python313\lib\site-packages (from pandas<3,>=1.4.0->streamlit) (2025.2)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests<3,>=2.27->streamlit) (3.4.4)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests<3,>=2.27->streamlit) (2.5.0)
Requirement already satisfied: certifi>=2017.4.17 in c:\program files\python313\lib\site-packages (from requests<3,>=2.27->streamlit) (2025.11.12)
Requirement already satisfied: plotly>=5.0.0 in c:\program files\python313\lib\site-packages (from dash) (6.5.0)
Requirement already satisfied: importlib-metadata in c:\program files\python313\lib\site-packages (from dash) (8.7.0)
Requirement already satisfied: retrying in c:\program files\python313\lib\site-packages (from dash) (1.4.2)
Requirement already satisfied: nest-asyncio in c:\program files\python313\lib\site-packages (from dash) (1.6.0)
Requirement already satisfied: setuptools in c:\program files\python313\lib\site-packages (from dash) (80.9.0)
Requirement already satisfied: attrs>=22.2.0 in c:\program files\python313\lib\site-packages (from jsonschema>=3.0->altair!=5.4.0,!=5.4.1,<6,>=4.0->streamlit) (25.4.0)
Requirement already satisfied: jsonschema-specifications>=2023.03.6 in c:\program files\python313\lib\site-packages (from jsonschema>=3.0->altair!=5.4.0,!=5.4.1,<6,>=4.0->streamlit) (2025.9.1)
Requirement already satisfied: referencing>=0.28.4 in c:\program files\python313\lib\site-packages (from jsonschema>=3.0->altair!=5.4.0,!=5.4.1,<6,>=4.0->streamlit) (0.37.0)
Requirement already satisfied: rpds-py>=0.7.1 in c:\program files\python313\lib\site-packages (from jsonschema>=3.0->altair!=5.4.0,!=5.4.1,<6,>=4.0->streamlit) (0.29.0)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil>=2.8.2->pandas<3,>=1.4.0->streamlit) (1.17.0)
Requirement already satisfied: zipp>=3.20 in c:\program files\python313\lib\site-packages (from importlib-metadata->dash) (3.23.0)
Downloading djangorestframework-3.16.1-py3-none-any.whl (1.1 MB)
   ---------------------------------------- 1.1/1.1 MB 14.2 MB/s  0:00:00
Installing collected packages: djangorestframework
Successfully installed djangorestframework-3.16.1
Requirement already satisfied: requests in c:\program files\python313\lib\site-packages (2.32.4)
Requirement already satisfied: beautifulsoup4 in c:\program files\python313\lib\site-packages (4.14.2)
Requirement already satisfied: lxml in c:\program files\python313\lib\site-packages (6.0.2)
Requirement already satisfied: scrapy in c:\program files\python313\lib\site-packages (2.13.4)
Requirement already satisfied: selenium in c:\program files\python313\lib\site-packages (4.38.0)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests) (3.4.4)
Requirement already satisfied: idna<4,>=2.5 in c:\program files\python313\lib\site-packages (from requests) (3.11)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests) (2.5.0)
Requirement already satisfied: certifi>=2017.4.17 in c:\program files\python313\lib\site-packages (from requests) (2025.11.12)
Requirement already satisfied: soupsieve>1.2 in c:\program files\python313\lib\site-packages (from beautifulsoup4) (2.8)
Requirement already satisfied: typing-extensions>=4.0.0 in c:\program files\python313\lib\site-packages (from beautifulsoup4) (4.15.0)
Requirement already satisfied: cryptography>=37.0.0 in c:\program files\python313\lib\site-packages (from scrapy) (43.0.3)
Requirement already satisfied: cssselect>=0.9.1 in c:\program files\python313\lib\site-packages (from scrapy) (1.3.0)
Requirement already satisfied: defusedxml>=0.7.1 in c:\program files\python313\lib\site-packages (from scrapy) (0.7.1)
Requirement already satisfied: itemadapter>=0.1.0 in c:\program files\python313\lib\site-packages (from scrapy) (0.12.2)
Requirement already satisfied: itemloaders>=1.0.1 in c:\program files\python313\lib\site-packages (from scrapy) (1.3.2)
Requirement already satisfied: packaging in c:\program files\python313\lib\site-packages (from scrapy) (25.0)
Requirement already satisfied: parsel>=1.5.0 in c:\program files\python313\lib\site-packages (from scrapy) (1.10.0)
Requirement already satisfied: protego>=0.1.15 in c:\program files\python313\lib\site-packages (from scrapy) (0.5.0)
Requirement already satisfied: pydispatcher>=2.0.5 in c:\program files\python313\lib\site-packages (from scrapy) (2.0.7)
Requirement already satisfied: pyopenssl>=22.0.0 in c:\program files\python313\lib\site-packages (from scrapy) (24.2.1)
Requirement already satisfied: queuelib>=1.4.2 in c:\program files\python313\lib\site-packages (from scrapy) (1.8.0)
Requirement already satisfied: service-identity>=18.1.0 in c:\program files\python313\lib\site-packages (from scrapy) (24.2.0)
Requirement already satisfied: tldextract in c:\program files\python313\lib\site-packages (from scrapy) (5.3.0)
Requirement already satisfied: twisted<=25.5.0,>=21.7.0 in c:\program files\python313\lib\site-packages (from scrapy) (25.5.0)
Requirement already satisfied: w3lib>=1.17.0 in c:\program files\python313\lib\site-packages (from scrapy) (2.3.1)
Requirement already satisfied: zope-interface>=5.1.0 in c:\program files\python313\lib\site-packages (from scrapy) (8.1.1)
Requirement already satisfied: attrs>=22.2.0 in c:\program files\python313\lib\site-packages (from twisted<=25.5.0,>=21.7.0->scrapy) (25.4.0)
Requirement already satisfied: automat>=24.8.0 in c:\program files\python313\lib\site-packages (from twisted<=25.5.0,>=21.7.0->scrapy) (25.4.16)
Requirement already satisfied: constantly>=15.1 in c:\program files\python313\lib\site-packages (from twisted<=25.5.0,>=21.7.0->scrapy) (23.10.4)
Requirement already satisfied: hyperlink>=17.1.1 in c:\program files\python313\lib\site-packages (from twisted<=25.5.0,>=21.7.0->scrapy) (21.0.0)
Requirement already satisfied: incremental>=24.7.0 in c:\program files\python313\lib\site-packages (from twisted<=25.5.0,>=21.7.0->scrapy) (24.7.2)
Requirement already satisfied: trio<1.0,>=0.31.0 in c:\program files\python313\lib\site-packages (from selenium) (0.32.0)
Requirement already satisfied: trio-websocket<1.0,>=0.12.2 in c:\program files\python313\lib\site-packages (from selenium) (0.12.2)
Requirement already satisfied: websocket-client<2.0,>=1.8.0 in c:\program files\python313\lib\site-packages (from selenium) (1.9.0)
Requirement already satisfied: sortedcontainers in c:\program files\python313\lib\site-packages (from trio<1.0,>=0.31.0->selenium) (2.4.0)
Requirement already satisfied: outcome in c:\program files\python313\lib\site-packages (from trio<1.0,>=0.31.0->selenium) (1.3.0.post0)
Requirement already satisfied: sniffio>=1.3.0 in c:\program files\python313\lib\site-packages (from trio<1.0,>=0.31.0->selenium) (1.3.1)
Requirement already satisfied: cffi>=1.14 in c:\program files\python313\lib\site-packages (from trio<1.0,>=0.31.0->selenium) (2.0.0)
Requirement already satisfied: wsproto>=0.14 in c:\program files\python313\lib\site-packages (from trio-websocket<1.0,>=0.12.2->selenium) (1.3.2)
Requirement already satisfied: pysocks!=1.5.7,<2.0,>=1.5.6 in c:\program files\python313\lib\site-packages (from urllib3[socks]<3.0,>=2.5.0->selenium) (1.7.1)
Requirement already satisfied: pycparser in c:\program files\python313\lib\site-packages (from cffi>=1.14->trio<1.0,>=0.31.0->selenium) (2.23)
Requirement already satisfied: setuptools>=61.0 in c:\program files\python313\lib\site-packages (from incremental>=24.7.0->twisted<=25.5.0,>=21.7.0->scrapy) (80.9.0)
Requirement already satisfied: jmespath>=0.9.5 in c:\program files\python313\lib\site-packages (from itemloaders>=1.0.1->scrapy) (0.10.0)
Requirement already satisfied: pyasn1 in c:\program files\python313\lib\site-packages (from service-identity>=18.1.0->scrapy) (0.6.1)
Requirement already satisfied: pyasn1-modules in c:\program files\python313\lib\site-packages (from service-identity>=18.1.0->scrapy) (0.4.2)
Requirement already satisfied: h11<1,>=0.16.0 in c:\program files\python313\lib\site-packages (from wsproto>=0.14->trio-websocket<1.0,>=0.12.2->selenium) (0.16.0)
Requirement already satisfied: requests-file>=1.4 in c:\program files\python313\lib\site-packages (from tldextract->scrapy) (3.0.1)
Requirement already satisfied: filelock>=3.0.8 in c:\program files\python313\lib\site-packages (from tldextract->scrapy) (3.19.1)
Collecting pyspark
  Downloading pyspark-4.0.1.tar.gz (434.2 MB)
     ---------------------------------------- 434.2/434.2 MB 70.6 MB/s  0:00:06
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Collecting apache-airflow
  Downloading apache_airflow-3.1.3-py3-none-any.whl.metadata (35 kB)
Collecting prefect
  Downloading prefect-3.6.4-py3-none-any.whl.metadata (13 kB)
Collecting dask
  Downloading dask-2025.11.0-py3-none-any.whl.metadata (3.8 kB)
Requirement already satisfied: sqlalchemy in c:\program files\python313\lib\site-packages (2.0.44)
Collecting py4j==0.10.9.9 (from pyspark)
  Downloading py4j-0.10.9.9-py2.py3-none-any.whl.metadata (1.3 kB)
Collecting apache-airflow-core==3.1.3 (from apache-airflow)
  Downloading apache_airflow_core-3.1.3-py3-none-any.whl.metadata (6.4 kB)
Collecting apache-airflow-task-sdk>=1.1.1 (from apache-airflow)
  Downloading apache_airflow_task_sdk-1.1.3-py3-none-any.whl.metadata (3.9 kB)
Collecting a2wsgi>=1.10.8 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading a2wsgi-1.10.10-py3-none-any.whl.metadata (4.0 kB)
Requirement already satisfied: aiosqlite>=0.20.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (0.21.0)
Requirement already satisfied: alembic<2.0,>=1.13.1 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (1.17.2)
Collecting apache-airflow-providers-common-compat>=1.7.4 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading apache_airflow_providers_common_compat-1.9.0-py3-none-any.whl.metadata (5.6 kB)
Collecting apache-airflow-providers-common-io>=1.6.3 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading apache_airflow_providers_common_io-1.6.5-py3-none-any.whl.metadata (5.6 kB)
Collecting apache-airflow-providers-common-sql>=1.28.1 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading apache_airflow_providers_common_sql-1.29.0-py3-none-any.whl.metadata (6.8 kB)
Collecting apache-airflow-providers-smtp>=2.3.1 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading apache_airflow_providers_smtp-2.3.2-py3-none-any.whl.metadata (5.2 kB)
Collecting apache-airflow-providers-standard>=1.9.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading apache_airflow_providers_standard-1.9.2-py3-none-any.whl.metadata (5.1 kB)
Requirement already satisfied: argcomplete>=1.10 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (3.6.3)
Requirement already satisfied: asgiref>=2.3.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (3.11.0)
Requirement already satisfied: attrs!=25.2.0,>=22.1.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (25.4.0)
Collecting cadwyn>=5.2.1 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading cadwyn-5.6.1-py3-none-any.whl.metadata (4.5 kB)
Collecting colorlog>=6.8.2 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading colorlog-6.10.1-py3-none-any.whl.metadata (11 kB)
Collecting cron-descriptor>=1.2.24 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading cron_descriptor-2.0.6-py3-none-any.whl.metadata (8.1 kB)
Collecting croniter>=2.0.2 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading croniter-6.0.0-py2.py3-none-any.whl.metadata (32 kB)
Requirement already satisfied: cryptography>=41.0.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (43.0.3)
Requirement already satisfied: deprecated>=1.2.13 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (1.2.18)
Collecting dill>=0.2.2 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading dill-0.4.0-py3-none-any.whl.metadata (10 kB)
Collecting fastapi<0.118.0,>=0.116.0 (from fastapi[standard-no-fastapi-cloud-cli]<0.118.0,>=0.116.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading fastapi-0.117.1-py3-none-any.whl.metadata (28 kB)
Requirement already satisfied: httpx>=0.25.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (0.28.1)
Requirement already satisfied: importlib-metadata>=7.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (8.7.0)
Requirement already satisfied: itsdangerous>=2.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (2.2.0)
Requirement already satisfied: jinja2>=3.1.5 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (3.1.6)
Requirement already satisfied: jsonschema>=4.19.1 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (4.25.1)
Collecting lazy-object-proxy>=1.2.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading lazy_object_proxy-1.12.0-cp313-cp313-win_amd64.whl.metadata (5.3 kB)
Collecting libcst>=1.8.2 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading libcst-1.8.6-cp313-cp313-win_amd64.whl.metadata (15 kB)
Collecting linkify-it-py>=2.0.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading linkify_it_py-2.0.3-py3-none-any.whl.metadata (8.5 kB)
Collecting lockfile>=0.12.2 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading lockfile-0.12.2-py2.py3-none-any.whl.metadata (2.4 kB)
Collecting methodtools>=0.4.7 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading methodtools-0.4.7-py2.py3-none-any.whl.metadata (3.0 kB)
Collecting msgspec>=0.19.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading msgspec-0.20.0-cp313-cp313-win_amd64.whl.metadata (5.6 kB)
Collecting natsort>=8.4.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading natsort-8.4.0-py3-none-any.whl.metadata (21 kB)
Requirement already satisfied: opentelemetry-api>=1.27.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (1.38.0)
Collecting opentelemetry-exporter-otlp>=1.27.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading opentelemetry_exporter_otlp-1.38.0-py3-none-any.whl.metadata (2.4 kB)
Requirement already satisfied: opentelemetry-proto<9999,>=1.27.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (1.38.0)
Requirement already satisfied: packaging>=25.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (25.0)
Requirement already satisfied: pathspec>=0.9.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (0.12.1)
Collecting pendulum>=3.1.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading pendulum-3.1.0-cp313-cp313-win_amd64.whl.metadata (6.9 kB)
Requirement already satisfied: pluggy>=1.5.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (1.6.0)
Requirement already satisfied: psutil>=5.8.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (7.1.3)
Requirement already satisfied: pydantic>=2.11.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (2.12.4)
Requirement already satisfied: pygments!=2.19.0,>=2.0.1 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (2.19.2)
Requirement already satisfied: pygtrie>=2.5.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (2.5.0)
Requirement already satisfied: pyjwt>=2.10.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (2.10.1)
Collecting python-daemon>=3.0.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading python_daemon-3.1.2-py3-none-any.whl.metadata (4.8 kB)
Requirement already satisfied: python-dateutil>=2.7.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (2.9.0.post0)
Collecting python-slugify>=5.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading python_slugify-8.0.4-py2.py3-none-any.whl.metadata (8.5 kB)
Requirement already satisfied: requests<3,>=2.32.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (2.32.4)
Collecting rich-argparse>=1.0.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading rich_argparse-1.7.2-py3-none-any.whl.metadata (14 kB)
Requirement already satisfied: rich>=13.6.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (14.2.0)
Collecting setproctitle>=1.3.3 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading setproctitle-1.3.7-cp313-cp313-win_amd64.whl.metadata (11 kB)
Collecting sqlalchemy-jsonfield>=1.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading SQLAlchemy_JSONField-1.0.2-py3-none-any.whl.metadata (5.2 kB)
Collecting sqlalchemy-utils>=0.41.2 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading sqlalchemy_utils-0.42.0-py3-none-any.whl.metadata (4.6 kB)
Requirement already satisfied: starlette>=0.45.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (0.50.0)
Collecting structlog>=25.4.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading structlog-25.5.0-py3-none-any.whl.metadata (9.5 kB)
Collecting svcs>=25.1.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading svcs-25.1.0-py3-none-any.whl.metadata (7.6 kB)
Requirement already satisfied: tabulate>=0.9.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (0.9.0)
Requirement already satisfied: tenacity>=8.3.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (9.1.2)
Requirement already satisfied: termcolor>=3.0.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (3.2.0)
Requirement already satisfied: typing-extensions>=4.14.1 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (4.15.0)
Collecting universal-pathlib<0.3.0,>=0.2.6 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading universal_pathlib-0.2.6-py3-none-any.whl.metadata (25 kB)
Collecting uuid6>=2024.7.10 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading uuid6-2025.0.1-py3-none-any.whl.metadata (10 kB)
Requirement already satisfied: uvicorn>=0.37.0 in c:\program files\python313\lib\site-packages (from apache-airflow-core==3.1.3->apache-airflow) (0.38.0)
Requirement already satisfied: babel>=2.17.0 in c:\program files\python313\lib\site-packages (from apache-airflow-task-sdk>=1.1.1->apache-airflow) (2.17.0)
Requirement already satisfied: fsspec>=2023.10.0 in c:\program files\python313\lib\site-packages (from apache-airflow-task-sdk>=1.1.1->apache-airflow) (2025.9.0)
Collecting greenback>=1.2.1 (from apache-airflow-task-sdk>=1.1.1->apache-airflow)
  Downloading greenback-1.2.1-py3-none-any.whl.metadata (9.5 kB)
Requirement already satisfied: Mako in c:\program files\python313\lib\site-packages (from alembic<2.0,>=1.13.1->apache-airflow-core==3.1.3->apache-airflow) (1.3.10)
Collecting starlette>=0.45.0 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading starlette-0.48.0-py3-none-any.whl.metadata (6.3 kB)
Collecting fastapi-cli>=0.0.8 (from fastapi-cli[standard-no-fastapi-cloud-cli]>=0.0.8; extra == "standard-no-fastapi-cloud-cli"->fastapi[standard-no-fastapi-cloud-cli]<0.118.0,>=0.116.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading fastapi_cli-0.0.16-py3-none-any.whl.metadata (6.4 kB)
Collecting python-multipart>=0.0.18 (from fastapi[standard-no-fastapi-cloud-cli]<0.118.0,>=0.116.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading python_multipart-0.0.20-py3-none-any.whl.metadata (1.8 kB)
Collecting email-validator>=2.0.0 (from fastapi[standard-no-fastapi-cloud-cli]<0.118.0,>=0.116.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading email_validator-2.3.0-py3-none-any.whl.metadata (26 kB)
Requirement already satisfied: anyio in c:\program files\python313\lib\site-packages (from httpx>=0.25.0->apache-airflow-core==3.1.3->apache-airflow) (4.11.0)
Requirement already satisfied: certifi in c:\program files\python313\lib\site-packages (from httpx>=0.25.0->apache-airflow-core==3.1.3->apache-airflow) (2025.11.12)
Requirement already satisfied: httpcore==1.* in c:\program files\python313\lib\site-packages (from httpx>=0.25.0->apache-airflow-core==3.1.3->apache-airflow) (1.0.9)
Requirement already satisfied: idna in c:\program files\python313\lib\site-packages (from httpx>=0.25.0->apache-airflow-core==3.1.3->apache-airflow) (3.11)
Requirement already satisfied: h11>=0.16 in c:\program files\python313\lib\site-packages (from httpcore==1.*->httpx>=0.25.0->apache-airflow-core==3.1.3->apache-airflow) (0.16.0)
Requirement already satisfied: protobuf<7.0,>=5.0 in c:\program files\python313\lib\site-packages (from opentelemetry-proto<9999,>=1.27.0->apache-airflow-core==3.1.3->apache-airflow) (6.33.1)
Requirement already satisfied: annotated-types>=0.6.0 in c:\program files\python313\lib\site-packages (from pydantic>=2.11.0->apache-airflow-core==3.1.3->apache-airflow) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in c:\program files\python313\lib\site-packages (from pydantic>=2.11.0->apache-airflow-core==3.1.3->apache-airflow) (2.41.5)
Requirement already satisfied: typing-inspection>=0.4.2 in c:\program files\python313\lib\site-packages (from pydantic>=2.11.0->apache-airflow-core==3.1.3->apache-airflow) (0.4.2)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests<3,>=2.32.0->apache-airflow-core==3.1.3->apache-airflow) (3.4.4)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests<3,>=2.32.0->apache-airflow-core==3.1.3->apache-airflow) (2.5.0)
Requirement already satisfied: sniffio>=1.1 in c:\program files\python313\lib\site-packages (from anyio->httpx>=0.25.0->apache-airflow-core==3.1.3->apache-airflow) (1.3.1)
Collecting apprise<2.0.0,>=1.1.0 (from prefect)
  Downloading apprise-1.9.5-py3-none-any.whl.metadata (56 kB)
Collecting asgi-lifespan<3.0,>=1.0 (from prefect)
  Downloading asgi_lifespan-2.1.0-py3-none-any.whl.metadata (10 kB)
Collecting asyncpg<1.0.0,>=0.23 (from prefect)
  Downloading asyncpg-0.31.0-cp313-cp313-win_amd64.whl.metadata (4.5 kB)
Requirement already satisfied: cachetools<7.0,>=5.3 in c:\program files\python313\lib\site-packages (from prefect) (6.2.2)
Requirement already satisfied: click<9,>=8.0 in c:\program files\python313\lib\site-packages (from prefect) (8.3.1)
Requirement already satisfied: cloudpickle<4.0,>=2.0 in c:\program files\python313\lib\site-packages (from prefect) (3.1.2)
Collecting coolname<3.0.0,>=1.0.4 (from prefect)
  Downloading coolname-2.2.0-py2.py3-none-any.whl.metadata (6.2 kB)
Collecting dateparser<2.0.0,>=1.1.1 (from prefect)
  Downloading dateparser-1.2.2-py3-none-any.whl.metadata (29 kB)
Requirement already satisfied: docker<8.0,>=4.0 in c:\program files\python313\lib\site-packages (from prefect) (7.1.0)
Collecting exceptiongroup>=1.0.0 (from prefect)
  Downloading exceptiongroup-1.3.1-py3-none-any.whl.metadata (6.7 kB)
Requirement already satisfied: graphviz>=0.20.1 in c:\program files\python313\lib\site-packages (from prefect) (0.21)
Requirement already satisfied: griffe<2.0.0,>=0.49.0 in c:\program files\python313\lib\site-packages (from prefect) (1.15.0)
Collecting humanize<5.0.0,>=4.9.0 (from prefect)
  Downloading humanize-4.14.0-py3-none-any.whl.metadata (7.8 kB)
Collecting jinja2-humanize-extension>=0.4.0 (from prefect)
  Downloading jinja2_humanize_extension-0.4.0-py3-none-any.whl.metadata (3.6 kB)
Requirement already satisfied: jsonpatch<2.0,>=1.32 in c:\program files\python313\lib\site-packages (from prefect) (1.33)
Requirement already satisfied: orjson<4.0,>=3.7 in c:\program files\python313\lib\site-packages (from prefect) (3.11.4)
Requirement already satisfied: prometheus-client>=0.20.0 in c:\program files\python313\lib\site-packages (from prefect) (0.23.1)
Collecting pydantic-extra-types<3.0.0,>=2.8.2 (from prefect)
  Downloading pydantic_extra_types-2.10.6-py3-none-any.whl.metadata (4.0 kB)
Requirement already satisfied: pydantic-settings!=2.9.0,<3.0.0,>2.2.1 in c:\program files\python313\lib\site-packages (from prefect) (2.12.0)
Collecting pydocket>=0.13.0 (from prefect)
  Downloading pydocket-0.15.0-py3-none-any.whl.metadata (6.2 kB)
Requirement already satisfied: pytz<2026,>=2021.1 in c:\program files\python313\lib\site-packages (from prefect) (2025.2)
Requirement already satisfied: pyyaml<7.0.0,>=5.4.1 in c:\program files\python313\lib\site-packages (from prefect) (6.0.3)
Collecting readchar<5.0.0,>=4.0.0 (from prefect)
  Downloading readchar-4.2.1-py3-none-any.whl.metadata (7.5 kB)
Requirement already satisfied: rfc3339-validator<0.2.0,>=0.1.4 in c:\program files\python313\lib\site-packages (from prefect) (0.1.4)
Requirement already satisfied: ruamel-yaml>=0.17.0 in c:\program files\python313\lib\site-packages (from prefect) (0.18.16)
Requirement already satisfied: semver>=3.0.4 in c:\program files\python313\lib\site-packages (from prefect) (3.0.4)
Requirement already satisfied: toml>=0.10.0 in c:\program files\python313\lib\site-packages (from prefect) (0.10.2)
Collecting typer<0.20.0,>=0.16.0 (from prefect)
  Downloading typer-0.19.2-py3-none-any.whl.metadata (16 kB)
Collecting uv>=0.6.0 (from prefect)
  Downloading uv-0.9.12-py3-none-win_amd64.whl.metadata (12 kB)
Requirement already satisfied: websockets<16.0,>=15.0.1 in c:\program files\python313\lib\site-packages (from prefect) (15.0.1)
Collecting whenever<0.10.0,>=0.7.3 (from prefect)
  Downloading whenever-0.9.3-cp313-cp313-win_amd64.whl.metadata (12 kB)
Requirement already satisfied: greenlet>=1 in c:\program files\python313\lib\site-packages (from sqlalchemy) (3.2.4)
Requirement already satisfied: requests-oauthlib in c:\program files\python313\lib\site-packages (from apprise<2.0.0,>=1.1.0->prefect) (2.0.0)
Requirement already satisfied: markdown in c:\program files\python313\lib\site-packages (from apprise<2.0.0,>=1.1.0->prefect) (3.10)
Requirement already satisfied: tzdata in c:\program files\python313\lib\site-packages (from apprise<2.0.0,>=1.1.0->prefect) (2025.2)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from click<9,>=8.0->prefect) (0.4.6)
Requirement already satisfied: regex>=2024.9.11 in c:\program files\python313\lib\site-packages (from dateparser<2.0.0,>=1.1.1->prefect) (2025.11.3)
Collecting tzlocal>=0.2 (from dateparser<2.0.0,>=1.1.1->prefect)
  Downloading tzlocal-5.3.1-py3-none-any.whl.metadata (7.6 kB)
Requirement already satisfied: pywin32>=304 in c:\program files\python313\lib\site-packages (from docker<8.0,>=4.0->prefect) (307)
Requirement already satisfied: MarkupSafe>=2.0 in c:\program files\python313\lib\site-packages (from jinja2>=3.1.5->apache-airflow-core==3.1.3->apache-airflow) (3.0.3)
Requirement already satisfied: jsonpointer>=1.9 in c:\program files\python313\lib\site-packages (from jsonpatch<2.0,>=1.32->prefect) (3.0.0)
Requirement already satisfied: jsonschema-specifications>=2023.03.6 in c:\program files\python313\lib\site-packages (from jsonschema>=4.19.1->apache-airflow-core==3.1.3->apache-airflow) (2025.9.1)
Requirement already satisfied: referencing>=0.28.4 in c:\program files\python313\lib\site-packages (from jsonschema>=4.19.1->apache-airflow-core==3.1.3->apache-airflow) (0.37.0)
Requirement already satisfied: rpds-py>=0.7.1 in c:\program files\python313\lib\site-packages (from jsonschema>=4.19.1->apache-airflow-core==3.1.3->apache-airflow) (0.29.0)
Requirement already satisfied: zipp>=3.20 in c:\program files\python313\lib\site-packages (from importlib-metadata>=7.0->apache-airflow-core==3.1.3->apache-airflow) (3.23.0)
Requirement already satisfied: python-dotenv>=0.21.0 in c:\program files\python313\lib\site-packages (from pydantic-settings!=2.9.0,<3.0.0,>2.2.1->prefect) (1.2.1)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil>=2.7.0->apache-airflow-core==3.1.3->apache-airflow) (1.17.0)
Collecting text-unidecode>=1.3 (from python-slugify>=5.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading text_unidecode-1.3-py2.py3-none-any.whl.metadata (2.4 kB)
Requirement already satisfied: markdown-it-py>=2.2.0 in c:\program files\python313\lib\site-packages (from rich>=13.6.0->apache-airflow-core==3.1.3->apache-airflow) (4.0.0)
Requirement already satisfied: shellingham>=1.3.0 in c:\program files\python313\lib\site-packages (from typer<0.20.0,>=0.16.0->prefect) (1.5.4)
Collecting partd>=1.4.0 (from dask)
  Downloading partd-1.4.2-py3-none-any.whl.metadata (4.6 kB)
Collecting toolz>=0.10.0 (from dask)
  Downloading toolz-1.1.0-py3-none-any.whl.metadata (5.1 kB)
Requirement already satisfied: sqlparse>=0.5.1 in c:\program files\python313\lib\site-packages (from apache-airflow-providers-common-sql>=1.28.1->apache-airflow-core==3.1.3->apache-airflow) (0.5.3)
Collecting more-itertools>=9.0.0 (from apache-airflow-providers-common-sql>=1.28.1->apache-airflow-core==3.1.3->apache-airflow)
  Downloading more_itertools-10.8.0-py3-none-any.whl.metadata (39 kB)
Collecting aiosmtplib>=0.1.6 (from apache-airflow-providers-smtp>=2.3.1->apache-airflow-core==3.1.3->apache-airflow)
  Downloading aiosmtplib-5.0.0-py3-none-any.whl.metadata (3.6 kB)
INFO: pip is looking at multiple versions of cadwyn to determine which version is compatible with other requirements. This could take a while.
Collecting cadwyn>=5.2.1 (from apache-airflow-core==3.1.3->apache-airflow)
  Downloading cadwyn-5.6.0-py3-none-any.whl.metadata (4.5 kB)
  Downloading cadwyn-5.5.0-py3-none-any.whl.metadata (4.5 kB)
  Downloading cadwyn-5.4.5-py3-none-any.whl.metadata (4.5 kB)
Requirement already satisfied: cffi>=1.12 in c:\program files\python313\lib\site-packages (from cryptography>=41.0.0->apache-airflow-core==3.1.3->apache-airflow) (2.0.0)
Requirement already satisfied: pycparser in c:\program files\python313\lib\site-packages (from cffi>=1.12->cryptography>=41.0.0->apache-airflow-core==3.1.3->apache-airflow) (2.23)
Requirement already satisfied: wrapt<2,>=1.10 in c:\program files\python313\lib\site-packages (from deprecated>=1.2.13->apache-airflow-core==3.1.3->apache-airflow) (1.17.3)
Collecting dnspython>=2.0.0 (from email-validator>=2.0.0->fastapi[standard-no-fastapi-cloud-cli]<0.118.0,>=0.116.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading dnspython-2.8.0-py3-none-any.whl.metadata (5.7 kB)
Collecting rich-toolkit>=0.14.8 (from fastapi-cli>=0.0.8->fastapi-cli[standard-no-fastapi-cloud-cli]>=0.0.8; extra == "standard-no-fastapi-cloud-cli"->fastapi[standard-no-fastapi-cloud-cli]<0.118.0,>=0.116.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading rich_toolkit-0.16.0-py3-none-any.whl.metadata (1.0 kB)
Requirement already satisfied: outcome in c:\program files\python313\lib\site-packages (from greenback>=1.2.1->apache-airflow-task-sdk>=1.1.1->apache-airflow) (1.3.0.post0)
Collecting h2<5,>=3 (from httpx[http2]!=0.23.2,>=0.23->prefect)
  Downloading h2-4.3.0-py3-none-any.whl.metadata (5.1 kB)
Collecting hyperframe<7,>=6.1 (from h2<5,>=3->httpx[http2]!=0.23.2,>=0.23->prefect)
  Downloading hyperframe-6.1.0-py3-none-any.whl.metadata (4.3 kB)
Collecting hpack<5,>=4.1 (from h2<5,>=3->httpx[http2]!=0.23.2,>=0.23->prefect)
  Downloading hpack-4.1.0-py3-none-any.whl.metadata (4.6 kB)
Collecting pyyaml-ft>=8.0.0 (from libcst>=1.8.2->apache-airflow-core==3.1.3->apache-airflow)
  Downloading pyyaml_ft-8.0.0-cp313-cp313-win_amd64.whl.metadata (8.6 kB)
Collecting uc-micro-py (from linkify-it-py>=2.0.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading uc_micro_py-1.0.3-py3-none-any.whl.metadata (2.0 kB)
Requirement already satisfied: mdurl~=0.1 in c:\program files\python313\lib\site-packages (from markdown-it-py>=2.2.0->rich>=13.6.0->apache-airflow-core==3.1.3->apache-airflow) (0.1.2)
Collecting wirerope>=0.4.7 (from methodtools>=0.4.7->apache-airflow-core==3.1.3->apache-airflow)
  Downloading wirerope-1.0.0-py2.py3-none-any.whl.metadata (3.3 kB)
Collecting opentelemetry-exporter-otlp-proto-grpc==1.38.0 (from opentelemetry-exporter-otlp>=1.27.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading opentelemetry_exporter_otlp_proto_grpc-1.38.0-py3-none-any.whl.metadata (2.4 kB)
Collecting opentelemetry-exporter-otlp-proto-http==1.38.0 (from opentelemetry-exporter-otlp>=1.27.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading opentelemetry_exporter_otlp_proto_http-1.38.0-py3-none-any.whl.metadata (2.3 kB)
Requirement already satisfied: googleapis-common-protos~=1.57 in c:\program files\python313\lib\site-packages (from opentelemetry-exporter-otlp-proto-grpc==1.38.0->opentelemetry-exporter-otlp>=1.27.0->apache-airflow-core==3.1.3->apache-airflow) (1.72.0)
Requirement already satisfied: grpcio<2.0.0,>=1.66.2 in c:\program files\python313\lib\site-packages (from opentelemetry-exporter-otlp-proto-grpc==1.38.0->opentelemetry-exporter-otlp>=1.27.0->apache-airflow-core==3.1.3->apache-airflow) (1.76.0)
Collecting opentelemetry-exporter-otlp-proto-common==1.38.0 (from opentelemetry-exporter-otlp-proto-grpc==1.38.0->opentelemetry-exporter-otlp>=1.27.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading opentelemetry_exporter_otlp_proto_common-1.38.0-py3-none-any.whl.metadata (1.8 kB)
Requirement already satisfied: opentelemetry-sdk~=1.38.0 in c:\program files\python313\lib\site-packages (from opentelemetry-exporter-otlp-proto-grpc==1.38.0->opentelemetry-exporter-otlp>=1.27.0->apache-airflow-core==3.1.3->apache-airflow) (1.38.0)
Requirement already satisfied: opentelemetry-semantic-conventions==0.59b0 in c:\program files\python313\lib\site-packages (from opentelemetry-sdk~=1.38.0->opentelemetry-exporter-otlp-proto-grpc==1.38.0->opentelemetry-exporter-otlp>=1.27.0->apache-airflow-core==3.1.3->apache-airflow) (0.59b0)
Collecting locket (from partd>=1.4.0->dask)
  Downloading locket-1.0.0-py2.py3-none-any.whl.metadata (2.8 kB)
Collecting fakeredis>=2.32.1 (from fakeredis[lua]>=2.32.1->pydocket>=0.13.0->prefect)
  Downloading fakeredis-2.32.1-py3-none-any.whl.metadata (4.5 kB)
Collecting opentelemetry-exporter-prometheus>=0.51b0 (from pydocket>=0.13.0->prefect)
  Downloading opentelemetry_exporter_prometheus-0.59b0-py3-none-any.whl.metadata (2.1 kB)
Collecting py-key-value-aio>=0.3.0 (from py-key-value-aio[memory,redis]>=0.3.0->pydocket>=0.13.0->prefect)
  Downloading py_key_value_aio-0.3.0-py3-none-any.whl.metadata (2.5 kB)
Requirement already satisfied: python-json-logger>=2.0.7 in c:\program files\python313\lib\site-packages (from pydocket>=0.13.0->prefect) (4.0.0)
Collecting redis>=5 (from pydocket>=0.13.0->prefect)
  Downloading redis-7.1.0-py3-none-any.whl.metadata (12 kB)
Requirement already satisfied: sortedcontainers>=2 in c:\program files\python313\lib\site-packages (from fakeredis>=2.32.1->fakeredis[lua]>=2.32.1->pydocket>=0.13.0->prefect) (2.4.0)
Collecting lupa>=2.1 (from fakeredis[lua]>=2.32.1->pydocket>=0.13.0->prefect)
  Downloading lupa-2.6-cp313-cp313-win_amd64.whl.metadata (60 kB)
Collecting py-key-value-shared==0.3.0 (from py-key-value-aio>=0.3.0->py-key-value-aio[memory,redis]>=0.3.0->pydocket>=0.13.0->prefect)
  Downloading py_key_value_shared-0.3.0-py3-none-any.whl.metadata (706 bytes)
Collecting beartype>=0.20.0 (from py-key-value-aio>=0.3.0->py-key-value-aio[memory,redis]>=0.3.0->pydocket>=0.13.0->prefect)
  Downloading beartype-0.22.6-py3-none-any.whl.metadata (36 kB)
Requirement already satisfied: ruamel.yaml.clib>=0.2.7 in c:\program files\python313\lib\site-packages (from ruamel-yaml>=0.17.0->prefect) (0.2.15)
Collecting httptools>=0.6.3 (from uvicorn[standard]>=0.12.0; extra == "standard-no-fastapi-cloud-cli"->fastapi[standard-no-fastapi-cloud-cli]<0.118.0,>=0.116.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading httptools-0.7.1-cp313-cp313-win_amd64.whl.metadata (3.6 kB)
Collecting watchfiles>=0.13 (from uvicorn[standard]>=0.12.0; extra == "standard-no-fastapi-cloud-cli"->fastapi[standard-no-fastapi-cloud-cli]<0.118.0,>=0.116.0->apache-airflow-core==3.1.3->apache-airflow)
  Downloading watchfiles-1.1.1-cp313-cp313-win_amd64.whl.metadata (5.0 kB)
Requirement already satisfied: oauthlib>=3.0.0 in c:\program files\python313\lib\site-packages (from requests-oauthlib->apprise<2.0.0,>=1.1.0->prefect) (3.3.1)
Downloading py4j-0.10.9.9-py2.py3-none-any.whl (203 kB)
Downloading apache_airflow-3.1.3-py3-none-any.whl (12 kB)
Downloading apache_airflow_core-3.1.3-py3-none-any.whl (5.3 MB)
   ---------------------------------------- 5.3/5.3 MB 40.6 MB/s  0:00:00
Downloading apache_airflow_task_sdk-1.1.3-py3-none-any.whl (302 kB)
Downloading fastapi-0.117.1-py3-none-any.whl (95 kB)
Downloading starlette-0.48.0-py3-none-any.whl (73 kB)
Downloading universal_pathlib-0.2.6-py3-none-any.whl (50 kB)
Downloading prefect-3.6.4-py3-none-any.whl (6.2 MB)
   ---------------------------------------- 6.2/6.2 MB 47.3 MB/s  0:00:00
Downloading apprise-1.9.5-py3-none-any.whl (1.4 MB)
   ---------------------------------------- 1.4/1.4 MB 64.0 MB/s  0:00:00
Downloading asgi_lifespan-2.1.0-py3-none-any.whl (10 kB)
Downloading asyncpg-0.31.0-cp313-cp313-win_amd64.whl (596 kB)
   ---------------------------------------- 596.6/596.6 kB 26.6 MB/s  0:00:00
Downloading coolname-2.2.0-py2.py3-none-any.whl (37 kB)
Downloading dateparser-1.2.2-py3-none-any.whl (315 kB)
Downloading humanize-4.14.0-py3-none-any.whl (132 kB)
Downloading pydantic_extra_types-2.10.6-py3-none-any.whl (40 kB)
Downloading python_slugify-8.0.4-py2.py3-none-any.whl (10 kB)
Downloading readchar-4.2.1-py3-none-any.whl (9.3 kB)
Downloading typer-0.19.2-py3-none-any.whl (46 kB)
Downloading whenever-0.9.3-cp313-cp313-win_amd64.whl (422 kB)
Downloading dask-2025.11.0-py3-none-any.whl (1.5 MB)
   ---------------------------------------- 1.5/1.5 MB 46.5 MB/s  0:00:00
Downloading a2wsgi-1.10.10-py3-none-any.whl (17 kB)
Downloading apache_airflow_providers_common_compat-1.9.0-py3-none-any.whl (37 kB)
Downloading apache_airflow_providers_common_io-1.6.5-py3-none-any.whl (19 kB)
Downloading apache_airflow_providers_common_sql-1.29.0-py3-none-any.whl (67 kB)
Downloading apache_airflow_providers_smtp-2.3.2-py3-none-any.whl (25 kB)
Downloading aiosmtplib-5.0.0-py3-none-any.whl (27 kB)
Downloading apache_airflow_providers_standard-1.9.2-py3-none-any.whl (144 kB)
Downloading cadwyn-5.4.5-py3-none-any.whl (59 kB)
Downloading colorlog-6.10.1-py3-none-any.whl (11 kB)
Downloading cron_descriptor-2.0.6-py3-none-any.whl (74 kB)
Downloading croniter-6.0.0-py2.py3-none-any.whl (25 kB)
Downloading dill-0.4.0-py3-none-any.whl (119 kB)
Downloading email_validator-2.3.0-py3-none-any.whl (35 kB)
Downloading dnspython-2.8.0-py3-none-any.whl (331 kB)
Downloading exceptiongroup-1.3.1-py3-none-any.whl (16 kB)
Downloading fastapi_cli-0.0.16-py3-none-any.whl (12 kB)
Downloading greenback-1.2.1-py3-none-any.whl (28 kB)
Downloading h2-4.3.0-py3-none-any.whl (61 kB)
Downloading hpack-4.1.0-py3-none-any.whl (34 kB)
Downloading hyperframe-6.1.0-py3-none-any.whl (13 kB)
Downloading jinja2_humanize_extension-0.4.0-py3-none-any.whl (4.8 kB)
Downloading lazy_object_proxy-1.12.0-cp313-cp313-win_amd64.whl (26 kB)
Downloading libcst-1.8.6-cp313-cp313-win_amd64.whl (2.1 MB)
   ---------------------------------------- 2.1/2.1 MB 45.6 MB/s  0:00:00
Downloading linkify_it_py-2.0.3-py3-none-any.whl (19 kB)
Downloading lockfile-0.12.2-py2.py3-none-any.whl (13 kB)
Downloading methodtools-0.4.7-py2.py3-none-any.whl (4.0 kB)
Downloading more_itertools-10.8.0-py3-none-any.whl (69 kB)
Downloading msgspec-0.20.0-cp313-cp313-win_amd64.whl (189 kB)
Downloading natsort-8.4.0-py3-none-any.whl (38 kB)
Downloading opentelemetry_exporter_otlp-1.38.0-py3-none-any.whl (7.0 kB)
Downloading opentelemetry_exporter_otlp_proto_grpc-1.38.0-py3-none-any.whl (19 kB)
Downloading opentelemetry_exporter_otlp_proto_common-1.38.0-py3-none-any.whl (18 kB)
Downloading opentelemetry_exporter_otlp_proto_http-1.38.0-py3-none-any.whl (19 kB)
Downloading partd-1.4.2-py3-none-any.whl (18 kB)
Downloading pendulum-3.1.0-cp313-cp313-win_amd64.whl (260 kB)
Downloading pydocket-0.15.0-py3-none-any.whl (56 kB)
Downloading fakeredis-2.32.1-py3-none-any.whl (118 kB)
Downloading lupa-2.6-cp313-cp313-win_amd64.whl (1.7 MB)
   ---------------------------------------- 1.7/1.7 MB 83.8 MB/s  0:00:00
Downloading opentelemetry_exporter_prometheus-0.59b0-py3-none-any.whl (13 kB)
Downloading py_key_value_aio-0.3.0-py3-none-any.whl (96 kB)
Downloading py_key_value_shared-0.3.0-py3-none-any.whl (19 kB)
Downloading beartype-0.22.6-py3-none-any.whl (1.3 MB)
   ---------------------------------------- 1.3/1.3 MB 56.3 MB/s  0:00:00
Downloading python_daemon-3.1.2-py3-none-any.whl (30 kB)
Downloading python_multipart-0.0.20-py3-none-any.whl (24 kB)
Downloading pyyaml_ft-8.0.0-cp313-cp313-win_amd64.whl (158 kB)
Downloading redis-7.1.0-py3-none-any.whl (354 kB)
Downloading rich_argparse-1.7.2-py3-none-any.whl (25 kB)
Downloading rich_toolkit-0.16.0-py3-none-any.whl (29 kB)
Downloading setproctitle-1.3.7-cp313-cp313-win_amd64.whl (13 kB)
Downloading SQLAlchemy_JSONField-1.0.2-py3-none-any.whl (10 kB)
Downloading sqlalchemy_utils-0.42.0-py3-none-any.whl (91 kB)
Downloading structlog-25.5.0-py3-none-any.whl (72 kB)
Downloading svcs-25.1.0-py3-none-any.whl (19 kB)
Downloading text_unidecode-1.3-py2.py3-none-any.whl (78 kB)
Downloading toolz-1.1.0-py3-none-any.whl (58 kB)
Downloading tzlocal-5.3.1-py3-none-any.whl (18 kB)
Downloading uuid6-2025.0.1-py3-none-any.whl (7.0 kB)
Downloading uv-0.9.12-py3-none-win_amd64.whl (21.7 MB)
   ---------------------------------------- 21.7/21.7 MB 66.1 MB/s  0:00:00
Downloading httptools-0.7.1-cp313-cp313-win_amd64.whl (85 kB)
Downloading watchfiles-1.1.1-cp313-cp313-win_amd64.whl (288 kB)
Downloading wirerope-1.0.0-py2.py3-none-any.whl (9.2 kB)
Downloading locket-1.0.0-py2.py3-none-any.whl (4.4 kB)
Downloading uc_micro_py-1.0.3-py3-none-any.whl (6.2 kB)
Building wheels for collected packages: pyspark
  Building wheel for pyspark (pyproject.toml) ... done
  Created wheel for pyspark: filename=pyspark-4.0.1-py2.py3-none-any.whl size=434813901 sha256=610523fd4006d77dd8fafad99584f27332d083a4cfd626ea58d55895d0c88bb0
  Stored in directory: c:\users\shelc\appdata\local\pip\cache\wheels\00\e3\92\8594f4cee2c9fd4ad82fe85e4bf2559ab8ea84ef19b1dd3d15
Successfully built pyspark
Installing collected packages: text-unidecode, py4j, lupa, lockfile, coolname, wirerope, uv, uuid6, universal-pathlib, uc-micro-py, tzlocal, toolz, svcs, structlog, setproctitle, redis, readchar, pyyaml-ft, python-slugify, python-multipart, python-daemon, pyspark, natsort, msgspec, more-itertools, locket, lazy-object-proxy, hyperframe, humanize, httptools, hpack, exceptiongroup, dnspython, dill, cron-descriptor, colorlog, beartype, asyncpg, asgi-lifespan, aiosmtplib, a2wsgi, whenever, watchfiles, starlette, sqlalchemy-utils, sqlalchemy-jsonfield, py-key-value-shared, pendulum, partd, opentelemetry-exporter-otlp-proto-common, methodtools, linkify-it-py, libcst, jinja2-humanize-extension, h2, greenback, fakeredis, email-validator, dateparser, croniter, typer, rich-toolkit, rich-argparse, pydantic-extra-types, py-key-value-aio, fastapi, dask, apprise, fastapi-cli, cadwyn, opentelemetry-exporter-prometheus, opentelemetry-exporter-otlp-proto-http, opentelemetry-exporter-otlp-proto-grpc, pydocket, opentelemetry-exporter-otlp, prefect, apache-airflow-providers-common-compat, apache-airflow-providers-standard, apache-airflow-providers-smtp, apache-airflow-providers-common-sql, apache-airflow-providers-common-io, apache-airflow-task-sdk, apache-airflow-core, apache-airflow
  Attempting uninstall: starlette
    Found existing installation: starlette 0.50.0
    Uninstalling starlette-0.50.0:
      Successfully uninstalled starlette-0.50.0
  Attempting uninstall: typer
    Found existing installation: typer 0.20.0
    Uninstalling typer-0.20.0:
      Successfully uninstalled typer-0.20.0
  Attempting uninstall: fastapi
    Found existing installation: fastapi 0.122.0
    Uninstalling fastapi-0.122.0:
      Successfully uninstalled fastapi-0.122.0
Successfully installed a2wsgi-1.10.10 aiosmtplib-5.0.0 apache-airflow-3.1.3 apache-airflow-core-3.1.3 apache-airflow-providers-common-compat-1.9.0 apache-airflow-providers-common-io-1.6.5 apache-airflow-providers-common-sql-1.29.0 apache-airflow-providers-smtp-2.3.2 apache-airflow-providers-standard-1.9.2 apache-airflow-task-sdk-1.1.3 apprise-1.9.5 asgi-lifespan-2.1.0 asyncpg-0.31.0 beartype-0.22.6 cadwyn-5.4.5 colorlog-6.10.1 coolname-2.2.0 cron-descriptor-2.0.6 croniter-6.0.0 dask-2025.11.0 dateparser-1.2.2 dill-0.4.0 dnspython-2.8.0 email-validator-2.3.0 exceptiongroup-1.3.1 fakeredis-2.32.1 fastapi-0.117.1 fastapi-cli-0.0.16 greenback-1.2.1 h2-4.3.0 hpack-4.1.0 httptools-0.7.1 humanize-4.14.0 hyperframe-6.1.0 jinja2-humanize-extension-0.4.0 lazy-object-proxy-1.12.0 libcst-1.8.6 linkify-it-py-2.0.3 locket-1.0.0 lockfile-0.12.2 lupa-2.6 methodtools-0.4.7 more-itertools-10.8.0 msgspec-0.20.0 natsort-8.4.0 opentelemetry-exporter-otlp-1.38.0 opentelemetry-exporter-otlp-proto-common-1.38.0 opentelemetry-exporter-otlp-proto-grpc-1.38.0 opentelemetry-exporter-otlp-proto-http-1.38.0 opentelemetry-exporter-prometheus-0.59b0 partd-1.4.2 pendulum-3.1.0 prefect-3.6.4 py-key-value-aio-0.3.0 py-key-value-shared-0.3.0 py4j-0.10.9.9 pydantic-extra-types-2.10.6 pydocket-0.15.0 pyspark-4.0.1 python-daemon-3.1.2 python-multipart-0.0.20 python-slugify-8.0.4 pyyaml-ft-8.0.0 readchar-4.2.1 redis-7.1.0 rich-argparse-1.7.2 rich-toolkit-0.16.0 setproctitle-1.3.7 sqlalchemy-jsonfield-1.0.2 sqlalchemy-utils-0.42.0 starlette-0.48.0 structlog-25.5.0 svcs-25.1.0 text-unidecode-1.3 toolz-1.1.0 typer-0.19.2 tzlocal-5.3.1 uc-micro-py-1.0.3 universal-pathlib-0.2.6 uuid6-2025.0.1 uv-0.9.12 watchfiles-1.1.1 whenever-0.9.3 wirerope-1.0.0
Requirement already satisfied: pytest in c:\program files\python313\lib\site-packages (9.0.1)
Requirement already satisfied: pytest-cov in c:\program files\python313\lib\site-packages (7.0.0)
Collecting pytest-xdist
  Downloading pytest_xdist-3.8.0-py3-none-any.whl.metadata (3.0 kB)
Requirement already satisfied: locust in c:\program files\python313\lib\site-packages (2.42.5)
Requirement already satisfied: colorama>=0.4 in c:\program files\python313\lib\site-packages (from pytest) (0.4.6)
Requirement already satisfied: iniconfig>=1.0.1 in c:\program files\python313\lib\site-packages (from pytest) (2.3.0)
Requirement already satisfied: packaging>=22 in c:\program files\python313\lib\site-packages (from pytest) (25.0)
Requirement already satisfied: pluggy<2,>=1.5 in c:\program files\python313\lib\site-packages (from pytest) (1.6.0)
Requirement already satisfied: pygments>=2.7.2 in c:\program files\python313\lib\site-packages (from pytest) (2.19.2)
Requirement already satisfied: coverage>=7.10.6 in c:\program files\python313\lib\site-packages (from coverage[toml]>=7.10.6->pytest-cov) (7.12.0)
Collecting execnet>=2.1 (from pytest-xdist)
  Downloading execnet-2.1.2-py3-none-any.whl.metadata (2.9 kB)
Requirement already satisfied: configargparse>=1.7.1 in c:\program files\python313\lib\site-packages (from locust) (1.7.1)
Requirement already satisfied: flask-cors>=3.0.10 in c:\program files\python313\lib\site-packages (from locust) (6.0.1)
Requirement already satisfied: flask-login>=0.6.3 in c:\program files\python313\lib\site-packages (from locust) (0.6.3)
Requirement already satisfied: flask>=2.0.0 in c:\program files\python313\lib\site-packages (from locust) (3.1.2)
Requirement already satisfied: gevent!=25.8.1,<26.0.0,>=24.10.1 in c:\program files\python313\lib\site-packages (from locust) (25.9.1)
Requirement already satisfied: geventhttpclient>=2.3.1 in c:\program files\python313\lib\site-packages (from locust) (2.3.5)
Requirement already satisfied: locust-cloud>=1.29.0 in c:\program files\python313\lib\site-packages (from locust) (1.29.2)
Requirement already satisfied: msgpack>=1.0.0 in c:\program files\python313\lib\site-packages (from locust) (1.1.2)
Requirement already satisfied: psutil>=5.9.1 in c:\program files\python313\lib\site-packages (from locust) (7.1.3)
Requirement already satisfied: python-engineio>=4.12.2 in c:\program files\python313\lib\site-packages (from locust) (4.12.3)
Requirement already satisfied: python-socketio>=5.13.0 in c:\program files\python313\lib\site-packages (from python-socketio[client]>=5.13.0->locust) (5.15.0)
Requirement already satisfied: pywin32 in c:\program files\python313\lib\site-packages (from locust) (307)
Requirement already satisfied: pyzmq>=25.0.0 in c:\program files\python313\lib\site-packages (from locust) (27.1.0)
Requirement already satisfied: requests<2.32.5,>=2.32.2 in c:\program files\python313\lib\site-packages (from locust) (2.32.4)
Requirement already satisfied: werkzeug>=2.0.0 in c:\program files\python313\lib\site-packages (from locust) (3.1.3)
Requirement already satisfied: greenlet>=3.2.2 in c:\program files\python313\lib\site-packages (from gevent!=25.8.1,<26.0.0,>=24.10.1->locust) (3.2.4)
Requirement already satisfied: cffi>=1.17.1 in c:\program files\python313\lib\site-packages (from gevent!=25.8.1,<26.0.0,>=24.10.1->locust) (2.0.0)
Requirement already satisfied: zope.event in c:\program files\python313\lib\site-packages (from gevent!=25.8.1,<26.0.0,>=24.10.1->locust) (6.1)
Requirement already satisfied: zope.interface in c:\program files\python313\lib\site-packages (from gevent!=25.8.1,<26.0.0,>=24.10.1->locust) (8.1.1)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests<2.32.5,>=2.32.2->locust) (3.4.4)
Requirement already satisfied: idna<4,>=2.5 in c:\program files\python313\lib\site-packages (from requests<2.32.5,>=2.32.2->locust) (3.11)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests<2.32.5,>=2.32.2->locust) (2.5.0)
Requirement already satisfied: certifi>=2017.4.17 in c:\program files\python313\lib\site-packages (from requests<2.32.5,>=2.32.2->locust) (2025.11.12)
Requirement already satisfied: pycparser in c:\program files\python313\lib\site-packages (from cffi>=1.17.1->gevent!=25.8.1,<26.0.0,>=24.10.1->locust) (2.23)
Requirement already satisfied: blinker>=1.9.0 in c:\program files\python313\lib\site-packages (from flask>=2.0.0->locust) (1.9.0)
Requirement already satisfied: click>=8.1.3 in c:\program files\python313\lib\site-packages (from flask>=2.0.0->locust) (8.3.1)
Requirement already satisfied: itsdangerous>=2.2.0 in c:\program files\python313\lib\site-packages (from flask>=2.0.0->locust) (2.2.0)
Requirement already satisfied: jinja2>=3.1.2 in c:\program files\python313\lib\site-packages (from flask>=2.0.0->locust) (3.1.6)
Requirement already satisfied: markupsafe>=2.1.1 in c:\program files\python313\lib\site-packages (from flask>=2.0.0->locust) (3.0.3)
Requirement already satisfied: brotli in c:\program files\python313\lib\site-packages (from geventhttpclient>=2.3.1->locust) (1.2.0)
Requirement already satisfied: platformdirs<5.0.0,>=4.3.6 in c:\program files\python313\lib\site-packages (from locust-cloud>=1.29.0->locust) (4.5.0)
Requirement already satisfied: bidict>=0.21.0 in c:\program files\python313\lib\site-packages (from python-socketio>=5.13.0->python-socketio[client]>=5.13.0->locust) (0.23.1)
Requirement already satisfied: websocket-client>=0.54.0 in c:\program files\python313\lib\site-packages (from python-socketio[client]>=5.13.0->locust) (1.9.0)
Requirement already satisfied: simple-websocket>=0.10.0 in c:\program files\python313\lib\site-packages (from python-engineio>=4.12.2->locust) (1.1.0)
Requirement already satisfied: wsproto in c:\program files\python313\lib\site-packages (from simple-websocket>=0.10.0->python-engineio>=4.12.2->locust) (1.3.2)
Requirement already satisfied: h11<1,>=0.16.0 in c:\program files\python313\lib\site-packages (from wsproto->simple-websocket>=0.10.0->python-engineio>=4.12.2->locust) (0.16.0)
Downloading pytest_xdist-3.8.0-py3-none-any.whl (46 kB)
Downloading execnet-2.1.2-py3-none-any.whl (40 kB)
Installing collected packages: execnet, pytest-xdist
Successfully installed execnet-2.1.2 pytest-xdist-3.8.0
Requirement already satisfied: black in c:\program files\python313\lib\site-packages (25.11.0)
Requirement already satisfied: flake8 in c:\program files\python313\lib\site-packages (7.3.0)
Requirement already satisfied: mypy in c:\program files\python313\lib\site-packages (1.18.2)
Collecting pylint
  Downloading pylint-4.0.3-py3-none-any.whl.metadata (12 kB)
Collecting autopep8
  Downloading autopep8-2.3.2-py2.py3-none-any.whl.metadata (16 kB)
Collecting isort
  Downloading isort-7.0.0-py3-none-any.whl.metadata (11 kB)
Requirement already satisfied: click>=8.0.0 in c:\program files\python313\lib\site-packages (from black) (8.3.1)
Requirement already satisfied: mypy-extensions>=0.4.3 in c:\program files\python313\lib\site-packages (from black) (1.1.0)
Requirement already satisfied: packaging>=22.0 in c:\program files\python313\lib\site-packages (from black) (25.0)
Requirement already satisfied: pathspec>=0.9.0 in c:\program files\python313\lib\site-packages (from black) (0.12.1)
Requirement already satisfied: platformdirs>=2 in c:\program files\python313\lib\site-packages (from black) (4.5.0)
Requirement already satisfied: pytokens>=0.3.0 in c:\program files\python313\lib\site-packages (from black) (0.3.0)
Requirement already satisfied: mccabe<0.8.0,>=0.7.0 in c:\program files\python313\lib\site-packages (from flake8) (0.7.0)
Requirement already satisfied: pycodestyle<2.15.0,>=2.14.0 in c:\program files\python313\lib\site-packages (from flake8) (2.14.0)
Requirement already satisfied: pyflakes<3.5.0,>=3.4.0 in c:\program files\python313\lib\site-packages (from flake8) (3.4.0)
Requirement already satisfied: typing_extensions>=4.6.0 in c:\program files\python313\lib\site-packages (from mypy) (4.15.0)
Collecting astroid<=4.1.dev0,>=4.0.2 (from pylint)
  Downloading astroid-4.0.2-py3-none-any.whl.metadata (4.4 kB)
Requirement already satisfied: colorama>=0.4.5 in c:\program files\python313\lib\site-packages (from pylint) (0.4.6)
Requirement already satisfied: dill>=0.3.6 in c:\program files\python313\lib\site-packages (from pylint) (0.4.0)
Requirement already satisfied: tomlkit>=0.10.1 in c:\program files\python313\lib\site-packages (from pylint) (0.13.3)
Downloading pylint-4.0.3-py3-none-any.whl (536 kB)
   ---------------------------------------- 536.2/536.2 kB 7.8 MB/s  0:00:00
Downloading isort-7.0.0-py3-none-any.whl (94 kB)
Downloading astroid-4.0.2-py3-none-any.whl (276 kB)
Downloading autopep8-2.3.2-py2.py3-none-any.whl (45 kB)
Installing collected packages: isort, autopep8, astroid, pylint
Successfully installed astroid-4.0.2 autopep8-2.3.2 isort-7.0.0 pylint-4.0.3
Requirement already satisfied: python-dotenv in c:\program files\python313\lib\site-packages (1.2.1)
Requirement already satisfied: click in c:\program files\python313\lib\site-packages (8.3.1)
Requirement already satisfied: typer in c:\program files\python313\lib\site-packages (0.19.2)
Requirement already satisfied: rich in c:\program files\python313\lib\site-packages (14.2.0)
Requirement already satisfied: tqdm in c:\program files\python313\lib\site-packages (4.67.1)
Requirement already satisfied: joblib in c:\program files\python313\lib\site-packages (1.5.2)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from click) (0.4.6)
Requirement already satisfied: typing-extensions>=3.7.4.3 in c:\program files\python313\lib\site-packages (from typer) (4.15.0)
Requirement already satisfied: shellingham>=1.3.0 in c:\program files\python313\lib\site-packages (from typer) (1.5.4)
Requirement already satisfied: markdown-it-py>=2.2.0 in c:\program files\python313\lib\site-packages (from rich) (4.0.0)
Requirement already satisfied: pygments<3.0.0,>=2.13.0 in c:\program files\python313\lib\site-packages (from rich) (2.19.2)
Requirement already satisfied: mdurl~=0.1 in c:\program files\python313\lib\site-packages (from markdown-it-py>=2.2.0->rich) (0.1.2)
Collecting psycopg2-binary
  Downloading psycopg2_binary-2.9.11-cp313-cp313-win_amd64.whl.metadata (5.1 kB)
Collecting pymongo
  Downloading pymongo-4.15.4-cp313-cp313-win_amd64.whl.metadata (22 kB)
Requirement already satisfied: redis in c:\program files\python313\lib\site-packages (7.1.0)
Requirement already satisfied: sqlalchemy in c:\program files\python313\lib\site-packages (2.0.44)
Requirement already satisfied: dnspython<3.0.0,>=1.16.0 in c:\program files\python313\lib\site-packages (from pymongo) (2.8.0)
Requirement already satisfied: greenlet>=1 in c:\program files\python313\lib\site-packages (from sqlalchemy) (3.2.4)
Requirement already satisfied: typing-extensions>=4.6.0 in c:\program files\python313\lib\site-packages (from sqlalchemy) (4.15.0)
Downloading psycopg2_binary-2.9.11-cp313-cp313-win_amd64.whl (2.7 MB)
   ---------------------------------------- 2.7/2.7 MB 26.3 MB/s  0:00:00
Downloading pymongo-4.15.4-cp313-cp313-win_amd64.whl (962 kB)
   ---------------------------------------- 962.6/962.6 kB 44.8 MB/s  0:00:00
Installing collected packages: pymongo, psycopg2-binary
Successfully installed psycopg2-binary-2.9.11 pymongo-4.15.4
Requirement already satisfied: httpx in c:\program files\python313\lib\site-packages (0.28.1)
Collecting httpie
  Downloading httpie-3.2.4-py3-none-any.whl.metadata (7.4 kB)
Requirement already satisfied: anyio in c:\program files\python313\lib\site-packages (from httpx) (4.11.0)
Requirement already satisfied: certifi in c:\program files\python313\lib\site-packages (from httpx) (2025.11.12)
Requirement already satisfied: httpcore==1.* in c:\program files\python313\lib\site-packages (from httpx) (1.0.9)
Requirement already satisfied: idna in c:\program files\python313\lib\site-packages (from httpx) (3.11)
Requirement already satisfied: h11>=0.16 in c:\program files\python313\lib\site-packages (from httpcore==1.*->httpx) (0.16.0)
Requirement already satisfied: pip in c:\program files\python313\lib\site-packages (from httpie) (25.3)
Requirement already satisfied: charset-normalizer>=2.0.0 in c:\program files\python313\lib\site-packages (from httpie) (3.4.4)
Requirement already satisfied: defusedxml>=0.6.0 in c:\program files\python313\lib\site-packages (from httpie) (0.7.1)
Requirement already satisfied: requests>=2.22.0 in c:\program files\python313\lib\site-packages (from requests[socks]>=2.22.0->httpie) (2.32.4)
Requirement already satisfied: Pygments>=2.5.2 in c:\program files\python313\lib\site-packages (from httpie) (2.19.2)
Requirement already satisfied: requests-toolbelt>=0.9.1 in c:\program files\python313\lib\site-packages (from httpie) (1.0.0)
Requirement already satisfied: multidict>=4.7.0 in c:\program files\python313\lib\site-packages (from httpie) (6.7.0)
Requirement already satisfied: setuptools in c:\program files\python313\lib\site-packages (from httpie) (80.9.0)
Requirement already satisfied: rich>=9.10.0 in c:\program files\python313\lib\site-packages (from httpie) (14.2.0)
Requirement already satisfied: colorama>=0.2.4 in c:\program files\python313\lib\site-packages (from httpie) (0.4.6)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests>=2.22.0->requests[socks]>=2.22.0->httpie) (2.5.0)
Requirement already satisfied: PySocks!=1.5.7,>=1.5.6 in c:\program files\python313\lib\site-packages (from requests[socks]>=2.22.0->httpie) (1.7.1)
Requirement already satisfied: markdown-it-py>=2.2.0 in c:\program files\python313\lib\site-packages (from rich>=9.10.0->httpie) (4.0.0)
Requirement already satisfied: mdurl~=0.1 in c:\program files\python313\lib\site-packages (from markdown-it-py>=2.2.0->rich>=9.10.0->httpie) (0.1.2)
Requirement already satisfied: sniffio>=1.1 in c:\program files\python313\lib\site-packages (from anyio->httpx) (1.3.1)
Downloading httpie-3.2.4-py3-none-any.whl (127 kB)
Installing collected packages: httpie
Successfully installed httpie-3.2.4
Requirement already satisfied: cryptography in c:\program files\python313\lib\site-packages (43.0.3)
Requirement already satisfied: pycryptodome in c:\program files\python313\lib\site-packages (3.23.0)
Requirement already satisfied: cffi>=1.12 in c:\program files\python313\lib\site-packages (from cryptography) (2.0.0)
Requirement already satisfied: pycparser in c:\program files\python313\lib\site-packages (from cffi>=1.12->cryptography) (2.23)
Requirement already satisfied: pydantic in c:\program files\python313\lib\site-packages (2.12.4)
Requirement already satisfied: marshmallow in c:\program files\python313\lib\site-packages (3.26.1)
Collecting cerberus
  Downloading cerberus-1.3.8-py3-none-any.whl.metadata (5.5 kB)
Requirement already satisfied: annotated-types>=0.6.0 in c:\program files\python313\lib\site-packages (from pydantic) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in c:\program files\python313\lib\site-packages (from pydantic) (2.41.5)
Requirement already satisfied: typing-extensions>=4.14.1 in c:\program files\python313\lib\site-packages (from pydantic) (4.15.0)
Requirement already satisfied: typing-inspection>=0.4.2 in c:\program files\python313\lib\site-packages (from pydantic) (0.4.2)
Requirement already satisfied: packaging>=17.0 in c:\program files\python313\lib\site-packages (from marshmallow) (25.0)
Downloading cerberus-1.3.8-py3-none-any.whl (30 kB)
Installing collected packages: cerberus
Successfully installed cerberus-1.3.8
Requirement already satisfied: sympy in c:\program files\python313\lib\site-packages (1.14.0)
Requirement already satisfied: networkx in c:\program files\python313\lib\site-packages (3.5)
Requirement already satisfied: mpmath<1.4,>=1.1.0 in c:\program files\python313\lib\site-packages (from sympy) (1.3.0)

[7/20] Docker, Kubernetes, VMs
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Chocolatey v2.5.1
Installing the following packages:
kubernetes-cli;kubernetes-helm;minikube
By installing, you accept licenses for the packages.
kubernetes-cli v1.34.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
kubernetes-helm v3.19.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Minikube v1.37.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - kubernetes-cli - kubernetes-cli v1.34.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - kubernetes-helm - kubernetes-helm v3.19.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - Minikube - Minikube v1.37.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
podman;podman-desktop
By installing, you accept licenses for the packages.
podman not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading podman-desktop 1.23.1... 100%

podman-desktop v1.23.1 [Approved]
podman-desktop package files install completed. Performing other installation steps.
Downloading podman-desktop 64 bit
  from 'https://github.com/podman-desktop/podman-desktop/releases/download/v1.23.1/podman-desktop-1.23.1-setup.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\podman-desktop\1.23.1\podman-desktop-1.23.1-setup.exe (282.81 MB).
Download of podman-desktop-1.23.1-setup.exe (282.81 MB) completed.
Hashes match.
Installing podman-desktop...
podman-desktop has been installed.
  podman-desktop can be automatically uninstalled.
 The install of podman-desktop was successful.
  Software installed as 'exe', install location is likely default.

Chocolatey installed 1/2 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - podman - podman not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.
Chocolatey v2.5.1
Installing the following packages:
vagrant
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading vagrant 2.4.9... 100%

vagrant v2.4.9 [Approved]
vagrant package files install completed. Performing other installation steps.
Downloading vagrant 64 bit
  from 'https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9_windows_amd64.msi'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\vagrant\2.4.9\vagrant_2.4.9_windows_amd64.msi (236.43 MB).
Download of vagrant_2.4.9_windows_amd64.msi (236.43 MB) completed.
Hashes match.
Installing vagrant...
vagrant has been installed.
Updating installed plugins...
All plugins are up to date.
Repairing currently installed global plugins. This may take a few minutes...
Installed plugins successfully repaired!
  vagrant may be able to be automatically uninstalled.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of vagrant was successful.
  Software installed as 'msi', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Packages requiring reboot:
 - vagrant (exit code 3010)

The recent package changes indicate a reboot is necessary.
 Please reboot at your earliest convenience.

[8/20] Database Systems
Chocolatey v2.5.1
Installing the following packages:
postgresql15
By installing, you accept licenses for the packages.
postgresql15 v15.15.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - postgresql15 - postgresql15 v15.15.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Enjoy using Chocolatey? Explore more amazing features to take your
experience to the next level at
 https://chocolatey.org/compare
Chocolatey v2.5.1
Installing the following packages:
mysql
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading mysql 9.2.0... 100%

mysql v9.2.0 [Approved] - Likely broken for FOSS users (due to download location changes)
mysql package files install completed. Performing other installation steps.
Adding 'C:\tools\mysql\current\bin' to the path and the current shell path
PATH environment variable does not have C:\tools\mysql\current\bin in it. Adding...
Downloading mysql 64 bit
  from 'https://cdn.mysql.com/Downloads/MySQL-9.2/mysql-9.2.0-winx64.zip'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\mysql\9.2.0\mysql-9.2.0-winx64.zip (290.11 MB).
Download of mysql-9.2.0-winx64.zip (290.11 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\mysql\9.2.0\mysql-9.2.0-winx64.zip to C:\tools\mysql...
C:\tools\mysql
Shutting down MySQL if it is running
#< CLIXML
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj S="progress" RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><Obj S="progress" RefId="1"><TNRef RefId="0" /><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><S S="debug">Host version is 5.1.26100.7019, PowerShell Version is '5.1.26100.7019' and CLR Version is '4.0.30319.42000'.</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\helpers\Chocolatey.PowerShell.dll'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Importing cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Importing cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Update-SessionEnvironment'.</S><S S="debug">Cmdlets exported from Chocolatey.PowerShell.dll</S><S S="debug">Get-EnvironmentVariable</S><S S="debug">Get-EnvironmentVariableNames</S><S S="debug">Install-ChocolateyPath</S><S S="debug">Set-EnvironmentVariable</S><S S="debug">Test-ProcessAdminRights</S><S S="debug">Uninstall-ChocolateyPath</S><S S="debug">Update-SessionEnvironment</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S><S S="debug">Loading community extensions</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'.</S><S S="debug">Function 'Get-PackageParameters' exists, ignoring export.</S><S S="debug">Function 'Get-UninstallRegistryKey' exists, ignoring export.</S><S S="debug">Exporting function 'Install-ChocolateyDesktopLink' for backwards compatibility</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="debug">Exporting function 'Write-ChocolateyFailure' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="debug">Exporting function 'Write-ChocolateySuccess' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="debug">Exporting function 'Write-FileUpdateLog' for backwards compatibility</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Importing function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Importing function 'Write-ChocolateyFailure'.</S><S S="verbose">Importing function 'Write-ChocolateySuccess'.</S><S S="verbose">Importing function 'Write-FileUpdateLog'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Importing function 'Get-AppInstallLocation'.</S><S S="verbose">Importing function 'Get-AvailableDriveLetter'.</S><S S="verbose">Importing function 'Get-EffectiveProxy'.</S><S S="verbose">Importing function 'Get-PackageCacheLocation'.</S><S S="verbose">Importing function 'Get-WebContent'.</S><S S="verbose">Importing function 'Register-Application'.</S><S S="verbose">Importing function 'Remove-Process'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetFramework'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Add-VisualStudioComponent'.</S><S S="verbose">Importing function 'Add-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Get-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Importing function 'Get-VisualStudioInstance'.</S><S S="verbose">Importing function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudio'.</S><S S="verbose">Importing function 'Install-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Remove-VisualStudioComponent'.</S><S S="verbose">Importing function 'Remove-VisualStudioProduct'.</S><S S="verbose">Importing function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Uninstall-VisualStudio'.</S><S S="verbose">Importing function 'Uninstall-VisualStudioVsixExtension'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Importing function 'Install-WindowsUpdate'.</S><S S="verbose">Importing function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="The service name is invalid.
Microsoft.PowerShell.Commands.WriteErrorException
More help is available by typing NET HELPMSG 2185.
Microsoft.PowerShell.Commands.WriteErrorException
verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S></Objs>
0
#< CLIXML
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj S="progress" RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><Obj S="progress" RefId="1"><TNRef RefId="0" /><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><S S="debug">Host version is 5.1.26100.7019, PowerShell Version is '5.1.26100.7019' and CLR Version is '4.0.30319.42000'.</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\helpers\Chocolatey.PowerShell.dll'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Importing cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Importing cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Update-SessionEnvironment'.</S><S S="debug">Cmdlets exported from Chocolatey.PowerShell.dll</S><S S="debug">Get-EnvironmentVariable</S><S S="debug">Get-EnvironmentVariableNames</S><S S="debug">Install-ChocolateyPath</S><S S="debug">Set-EnvironmentVariable</S><S S="debug">Test-ProcessAdminRights</S><S S="debug">Uninstall-ChocolateyPath</S><S S="debug">Update-SessionEnvironment</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S><S S="debug">Loading community extensions</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'.</S><S S="debug">Function 'Get-PackageParameters' exists, ignoring export.</S><S S="debug">Function 'Get-UninstallRegistryKey' exists, ignoring export.</S><S S="debug">Exporting function 'Install-ChocolateyDesktopLink' for backwards compatibility</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="debug">Exporting function 'Write-ChocolateyFailure' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="debug">Exporting function 'Write-ChocolateySuccess' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="debug">Exporting function 'Write-FileUpdateLog' for backwards compatibility</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Importing function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Importing function 'Write-ChocolateyFailure'.</S><S S="verbose">Importing function 'Write-ChocolateySuccess'.</S><S S="verbose">Importing function 'Write-FileUpdateLog'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Importing function 'Get-AppInstallLocation'.</S><S S="verbose">Importing function 'Get-AvailableDriveLetter'.</S><S S="verbose">Importing function 'Get-EffectiveProxy'.</S><S S="verbose">Importing function 'Get-PackageCacheLocation'.</S><S S="verbose">Importing function 'Get-WebContent'.</S><S S="verbose">Importing function 'Register-Application'.</S><S S="verbose">Importing function 'Remove-Process'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetFramework'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Add-VisualStudioComponent'.</S><S S="verbose">Importing function 'Add-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Get-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Importing function 'Get-VisualStudioInstance'.</S><S S="verbose">Importing function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudio'.</S><S S="verbose">Importing function 'Install-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Remove-VisualStudioComponent'.</S><S S="verbose">Importing function 'Remove-VisualStudioProduct'.</S><S S="verbose">Importing function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Uninstall-VisualStudio'.</S><S S="verbose">Importing function 'Uninstall-VisualStudioVsixExtension'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Importing function 'Install-WindowsUpdate'.</S><S S="verbose">Importing function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S></Objs>
0
Copying contents of 'C:\tools\mysql\mysql-9.2.0-winx64' to 'C:\tools\mysql\current'.
No existing my.ini. Creating default 'C:\tools\mysql\current\my.ini' with default locations for datadir.
Initializing MySQL if it hasn't already been initialized.
#< CLIXML
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj S="progress" RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><Obj S="progress" RefId="1"><TNRef RefId="0" /><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><S S="debug">Host version is 5.1.26100.7019, PowerShell Version is '5.1.26100.7019' and CLR Version is '4.0.30319.42000'.</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\helpers\Chocolatey.PowerShell.dll'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Importing cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Importing cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Update-SessionEnvironment'.</S><S S="debug">Cmdlets exported from Chocolatey.PowerShell.dll</S><S S="debug">Get-EnvironmentVariable</S><S S="debug">Get-EnvironmentVariableNames</S><S S="debug">Install-ChocolateyPath</S><S S="debug">Set-EnvironmentVariable</S><S S="debug">Test-ProcessAdminRights</S><S S="debug">Uninstall-ChocolateyPath</S><S S="debug">Update-SessionEnvironment</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S><S S="debug">Loading community extensions</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'.</S><S S="debug">Function 'Get-PackageParameters' exists, ignoring export.</S><S S="debug">Function 'Get-UninstallRegistryKey' exists, ignoring export.</S><S S="debug">Exporting function 'Install-ChocolateyDesktopLink' for backwards compatibility</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="debug">Exporting function 'Write-ChocolateyFailure' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="debug">Exporting function 'Write-ChocolateySuccess' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="debug">Exporting function 'Write-FileUpdateLog' for backwards compatibility</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Importing function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Importing function 'Write-ChocolateyFailure'.</S><S S="verbose">Importing function 'Write-ChocolateySuccess'.</S><S S="verbose">Importing function 'Write-FileUpdateLog'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Importing function 'Get-AppInstallLocation'.</S><S S="verbose">Importing function 'Get-AvailableDriveLetter'.</S><S S="verbose">Importing function 'Get-EffectiveProxy'.</S><S S="verbose">Importing function 'Get-PackageCacheLocation'.</S><S S="verbose">Importing function 'Get-WebContent'.</S><S S="verbose">Importing function 'Register-Application'.</S><S S="verbose">Importing function 'Remove-Process'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetFramework'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Add-VisualStudioComponent'.</S><S S="verbose">Importing function 'Add-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Get-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Importing function 'Get-VisualStudioInstance'.</S><S S="verbose">Importing function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudio'.</S><S S="verbose">Importing function 'Install-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Remove-VisualStudioComponent'.</S><S S="verbose">Importing function 'Remove-VisualStudioProduct'.</S><S S="verbose">Importing function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Uninstall-VisualStudio'.</S><S S="verbose">Importing function 'Uninstall-VisualStudioVsixExtension'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Importing function 'Install-WindowsUpdate'.</S><S S="verbose">Importing function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S></Objs>
0
Installing the mysql service
#< CLIXML
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj S="progress" RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><Obj S="progress" RefId="1"><TNRef RefId="0" /><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><S S="debug">Host version is 5.1.26100.7019, PowerShell Version is '5.1.26100.7019' and CLR Version is '4.0.30319.42000'.</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\helpers\Chocolatey.PowerShell.dll'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Importing cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Importing cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Update-SessionEnvironment'.</S><S S="debug">Cmdlets exported from Chocolatey.PowerShell.dll</S><S S="debug">Get-EnvironmentVariable</S><S S="debug">Get-EnvironmentVariableNames</S><S S="debug">Install-ChocolateyPath</S><S S="debug">Set-EnvironmentVariable</S><S S="debug">Test-ProcessAdminRights</S><S S="debug">Uninstall-ChocolateyPath</S><S S="debug">Update-SessionEnvironment</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S><S S="debug">Loading community extensions</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'.</S><S S="debug">Function 'Get-PackageParameters' exists, ignoring export.</S><S S="debug">Function 'Get-UninstallRegistryKey' exists, ignoring export.</S><S S="debug">Exporting function 'Install-ChocolateyDesktopLink' for backwards compatibility</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="debug">Exporting function 'Write-ChocolateyFailure' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="debug">Exporting function 'Write-ChocolateySuccess' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="debug">Exporting function 'Write-FileUpdateLog' for backwards compatibility</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Importing function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Importing function 'Write-ChocolateyFailure'.</S><S S="verbose">Importing function 'Write-ChocolateySuccess'.</S><S S="verbose">Importing function 'Write-FileUpdateLog'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Importing function 'Get-AppInstallLocation'.</S><S S="verbose">Importing function 'Get-AvailableDriveLetter'.</S><S S="verbose">Importing function 'Get-EffectiveProxy'.</S><S S="verbose">Importing function 'Get-PackageCacheLocation'.</S><S S="verbose">Importing function 'Get-WebContent'.</S><S S="verbose">Importing function 'Register-Application'.</S><S S="verbose">Importing function 'Remove-Process'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetFramework'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Add-VisualStudioComponent'.</S><S S="verbose">Importing function 'Add-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Get-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Importing function 'Get-VisualStudioInstance'.</S><S S="verbose">Importing function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudio'.</S><S S="verbose">Importing function 'Install-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Remove-VisualStudioComponent'.</S><S S="verbose">Importing function 'Remove-VisualStudioProduct'.</S><S S="verbose">Importing function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Uninstall-VisualStudio'.</S><S S="verbose">Importing function 'Uninstall-VisualStudioVsixExtension'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Importing function 'Install-WindowsUpdate'.</S><S S="verbose">Importing function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S></Objs>
0
#< CLIXML
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj S="progress" RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><Obj S="progress" RefId="1"><TNRef RefId="0" /><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><S S="debug">Host version is 5.1.26100.7019, PowerShell Version is '5.1.26100.7019' and CLR Version is '4.0.30319.42000'.</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\helpers\Chocolatey.PowerShell.dll'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Importing cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Importing cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Update-SessionEnvironment'.</S><S S="debug">Cmdlets exported from Chocolatey.PowerShell.dll</S><S S="debug">Get-EnvironmentVariable</S><S S="debug">Get-EnvironmentVariableNames</S><S S="debug">Install-ChocolateyPath</S><S S="debug">Set-EnvironmentVariable</S><S S="debug">Test-ProcessAdminRights</S><S S="debug">Uninstall-ChocolateyPath</S><S S="debug">Update-SessionEnvironment</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S><S S="debug">Loading community extensions</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'.</S><S S="debug">Function 'Get-PackageParameters' exists, ignoring export.</S><S S="debug">Function 'Get-UninstallRegistryKey' exists, ignoring export.</S><S S="debug">Exporting function 'Install-ChocolateyDesktopLink' for backwards compatibility</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="debug">Exporting function 'Write-ChocolateyFailure' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="debug">Exporting function 'Write-ChocolateySuccess' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="debug">Exporting function 'Write-FileUpdateLog' for backwards compatibility</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Importing function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Importing function 'Write-ChocolateyFailure'.</S><S S="verbose">Importing function 'Write-ChocolateySuccess'.</S><S S="verbose">Importing function 'Write-FileUpdateLog'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Importing function 'Get-AppInstallLocation'.</S><S S="verbose">Importing function 'Get-AvailableDriveLetter'.</S><S S="verbose">Importing function 'Get-EffectiveProxy'.</S><S S="verbose">Importing function 'Get-PackageCacheLocation'.</S><S S="verbose">Importing function 'Get-WebContent'.</S><S S="verbose">Importing function 'Register-Application'.</S><S S="verbose">Importing function 'Remove-Process'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetFramework'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Add-VisualStudioComponent'.</S><S S="verbose">Importing function 'Add-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Get-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Importing function 'Get-VisualStudioInstance'.</S><S S="verbose">Importing function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudio'.</S><S S="verbose">Importing function 'Install-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Remove-VisualStudioComponent'.</S><S S="verbose">Importing function 'Remove-VisualStudioProduct'.</S><S S="verbose">Importing function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Uninstall-VisualStudio'.</S><S S="verbose">Importing function 'Uninstall-VisualStudioVsixExtension'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Importing function 'Install-WindowsUpdate'.</S><S S="verbose">Importing function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S></Objs>
0
Only an exit code of non-zero will fail the package by default. Set
 `--failonstderr` if you want error messages to also fail a script. See
 `choco --help` for details.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of mysql was successful.
  Deployed to 'C:\tools\mysql'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
sqlite
By installing, you accept licenses for the packages.
SQLite v3.51.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - SQLite - SQLite v3.51.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
mariadb
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading mariadb.install 12.1.2... 100%

mariadb.install v12.1.2 [Approved]
mariadb.install package files install completed. Performing other installation steps.
Installing 64-bit mariadb.install...
WARNING: Generic MSI Error. This is a local environment error, not an issue with a package or the MSI itself - it could mean a pending reboot is necessary prior to install or something else (like the same version is already installed). Please see MSI log if available. If not, try again adding '--install-arguments="'/l*v c:\mariadb.install_msi_install.log'"'. Then search the MSI Log for "Return Value 3" and look above that for the error.
ERROR: Running ["C:\WINDOWS\System32\msiexec.exe" /i "C:\ProgramData\chocolatey\lib\mariadb.install\tools\mariadb-12.1.2-winx64.msi" SERVICENAME=MySQL /qn /norestart /l*v "C:\Users\shelc\AppData\Local\Temp\chocolatey\mariadb.install.12.1.2.MsiInstall.log"] was not successful. Exit code was '1603'. Exit code indicates the following: Generic MSI Error. This is a local environment error, not an issue with a package or the MSI itself - it could mean a pending reboot is necessary prior to install or something else (like the same version is already installed). Please see MSI log if available. If not, try again adding '--install-arguments="'/l*v c:\mariadb.install_msi_install.log'"'. Then search the MSI Log for "Return Value 3" and look above that for the error..
The install of mariadb.install was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\mariadb.install\tools\chocolateyInstall.ps1'.
 See log for details.
Failed to install mariadb because a previous dependency failed.

Chocolatey installed 0/2 packages. 2 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - mariadb - Failed to install mariadb because a previous dependency failed.
 - mariadb.install (exited 1603) - Error while running 'C:\ProgramData\chocolatey\lib\mariadb.install\tools\chocolateyInstall.ps1'.
 See log for details.
Chocolatey v2.5.1
Installing the following packages:
mongodb;mongodb-compass
By installing, you accept licenses for the packages.
mongodb v8.2.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
mongodb-compass v1.48.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - mongodb - mongodb v8.2.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - mongodb-compass - mongodb-compass v1.48.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
redis-64
By installing, you accept licenses for the packages.
redis-64 v3.1.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - redis-64 - redis-64 v3.1.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
memcached
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading memcached 1.4.4... 100%

memcached v1.4.4 [Approved] - Possibly broken
memcached package files install completed. Performing other installation steps.
#< CLIXML
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04"><Obj S="progress" RefId="0"><TN RefId="0"><T>System.Management.Automation.PSCustomObject</T><T>System.Object</T></TN><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><Obj S="progress" RefId="1"><TNRef RefId="0" /><MS><I64 N="SourceId">1</I64><PR N="Record"><AV>Preparing modules for first use.</AV><AI>0</AI><Nil /><PI>-1</PI><PC>-1</PC><T>Completed</T><SR>-1</SR><SD> </SD></PR></MS></Obj><S S="debug">Host version is 5.1.26100.7019, PowerShell Version is '5.1.26100.7019' and CLR Version is '4.0.30319.42000'.</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\helpers\Chocolatey.PowerShell.dll'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Importing cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Importing cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Importing cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Importing cmdlet 'Update-SessionEnvironment'.</S><S S="debug">Cmdlets exported from Chocolatey.PowerShell.dll</S><S S="debug">Get-EnvironmentVariable</S><S S="debug">Get-EnvironmentVariableNames</S><S S="debug">Install-ChocolateyPath</S><S S="debug">Set-EnvironmentVariable</S><S S="debug">Test-ProcessAdminRights</S><S S="debug">Uninstall-ChocolateyPath</S><S S="debug">Update-SessionEnvironment</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S><S S="debug">Loading community extensions</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\chocolatey-compatibility.psm1'.</S><S S="debug">Function 'Get-PackageParameters' exists, ignoring export.</S><S S="debug">Function 'Get-UninstallRegistryKey' exists, ignoring export.</S><S S="debug">Exporting function 'Install-ChocolateyDesktopLink' for backwards compatibility</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="debug">Exporting function 'Write-ChocolateyFailure' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="debug">Exporting function 'Write-ChocolateySuccess' for backwards compatibility</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="debug">Exporting function 'Write-FileUpdateLog' for backwards compatibility</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Importing function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Importing function 'Write-ChocolateyFailure'.</S><S S="verbose">Importing function 'Write-ChocolateySuccess'.</S><S S="verbose">Importing function 'Write-FileUpdateLog'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-core\chocolatey-core.psm1'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Importing function 'Get-AppInstallLocation'.</S><S S="verbose">Importing function 'Get-AvailableDriveLetter'.</S><S S="verbose">Importing function 'Get-EffectiveProxy'.</S><S S="verbose">Importing function 'Get-PackageCacheLocation'.</S><S S="verbose">Importing function 'Get-WebContent'.</S><S S="verbose">Importing function 'Register-Application'.</S><S S="verbose">Importing function 'Remove-Process'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-dotnetfx\chocolatey-dotnetfx.psm1'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetDevPack'.</S><S S="verbose">Importing function 'Install-DotNetFramework'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-visualstudio\chocolatey-visualstudio.extension.psm1'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Add-VisualStudioComponent'.</S><S S="verbose">Importing function 'Add-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Get-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Importing function 'Get-VisualStudioInstance'.</S><S S="verbose">Importing function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudio'.</S><S S="verbose">Importing function 'Install-VisualStudioInstaller'.</S><S S="verbose">Importing function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Importing function 'Remove-VisualStudioComponent'.</S><S S="verbose">Importing function 'Remove-VisualStudioProduct'.</S><S S="verbose">Importing function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Importing function 'Uninstall-VisualStudio'.</S><S S="verbose">Importing function 'Uninstall-VisualStudioVsixExtension'.</S><S S="debug">Importing 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'</S><S S="verbose">Loading module from path 'C:\ProgramData\chocolatey\extensions\chocolatey-windowsupdate\chocolatey-windowsupdate.psm1'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Importing function 'Install-WindowsUpdate'.</S><S S="verbose">Importing function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting function 'Format-FileSize'.</S><S S="verbose">Exporting function 'Get-ChecksumValid'.</S><S S="verbose">Exporting function 'Get-ChocolateyConfigValue'.</S><S S="verbose">Exporting function 'Get-ChocolateyPath'.</S><S S="verbose">Exporting function 'Get-ChocolateyUnzip'.</S><S S="verbose">Exporting function 'Get-ChocolateyWebFile'.</S><S S="verbose">Exporting function 'Get-FtpFile'.</S><S S="verbose">Exporting function 'Get-OSArchitectureWidth'.</S><S S="verbose">Exporting function 'Get-PackageParameters'.</S><S S="verbose">Exporting function 'Get-PackageParametersBuiltIn'.</S><S S="verbose">Exporting function 'Get-ToolsLocation'.</S><S S="verbose">Exporting function 'Get-UACEnabled'.</S><S S="verbose">Exporting function 'Get-UninstallRegistryKey'.</S><S S="verbose">Exporting function 'Get-VirusCheckValid'.</S><S S="verbose">Exporting function 'Get-WebFile'.</S><S S="verbose">Exporting function 'Get-WebFileName'.</S><S S="verbose">Exporting function 'Get-WebHeaders'.</S><S S="verbose">Exporting function 'Install-BinFile'.</S><S S="verbose">Exporting function 'Install-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Install-ChocolateyExplorerMenuItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyFileAssociation'.</S><S S="verbose">Exporting function 'Install-ChocolateyInstallPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyPinnedTaskBarItem'.</S><S S="verbose">Exporting function 'Install-ChocolateyPowershellCommand'.</S><S S="verbose">Exporting function 'Install-ChocolateyShortcut'.</S><S S="verbose">Exporting function 'Install-ChocolateyVsixPackage'.</S><S S="verbose">Exporting function 'Install-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Install-Vsix'.</S><S S="verbose">Exporting function 'Set-PowerShellExitCode'.</S><S S="verbose">Exporting function 'Start-ChocolateyProcessAsAdmin'.</S><S S="verbose">Exporting function 'Uninstall-BinFile'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyEnvironmentVariable'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyPackage'.</S><S S="verbose">Exporting function 'Uninstall-ChocolateyZipPackage'.</S><S S="verbose">Exporting function 'Write-FunctionCallLogMessage'.</S><S S="verbose">Exporting function 'Install-ChocolateyDesktopLink'.</S><S S="verbose">Exporting function 'Write-ChocolateyFailure'.</S><S S="verbose">Exporting function 'Write-ChocolateySuccess'.</S><S S="verbose">Exporting function 'Write-FileUpdateLog'.</S><S S="verbose">Exporting function 'Get-AppInstallLocation'.</S><S S="verbose">Exporting function 'Get-AvailableDriveLetter'.</S><S S="verbose">Exporting function 'Get-EffectiveProxy'.</S><S S="verbose">Exporting function 'Get-PackageCacheLocation'.</S><S S="verbose">Exporting function 'Get-WebContent'.</S><S S="verbose">Exporting function 'Register-Application'.</S><S S="verbose">Exporting function 'Remove-Process'.</S><S S="verbose">Exporting function 'Install-DotNetDevPack'.</S><S S="verbose">Exporting function 'Install-DotNetFramework'.</S><S S="verbose">Exporting function 'Add-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Add-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstallerHealth'.</S><S S="verbose">Exporting function 'Get-VisualStudioInstance'.</S><S S="verbose">Exporting function 'Get-VisualStudioVsixInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudio'.</S><S S="verbose">Exporting function 'Install-VisualStudioInstaller'.</S><S S="verbose">Exporting function 'Install-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Remove-VisualStudioComponent'.</S><S S="verbose">Exporting function 'Remove-VisualStudioProduct'.</S><S S="verbose">Exporting function 'Remove-VisualStudioWorkload'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudio'.</S><S S="verbose">Exporting function 'Uninstall-VisualStudioVsixExtension'.</S><S S="verbose">Exporting function 'Install-WindowsUpdate'.</S><S S="verbose">Exporting function 'Test-WindowsUpdate'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Get-EnvironmentVariableNames'.</S><S S="verbose">Exporting cmdlet 'Install-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Set-EnvironmentVariable'.</S><S S="verbose">Exporting cmdlet 'Test-ProcessAdminRights'.</S><S S="verbose">Exporting cmdlet 'Uninstall-ChocolateyPath'.</S><S S="verbose">Exporting cmdlet 'Update-SessionEnvironment'.</S><S S="verbose">Exporting alias 'Get-ProcessorBits'.</S><S S="verbose">Exporting alias 'Get-OSBitness'.</S><S S="verbose">Exporting alias 'Get-InstallRegistryKey'.</S><S S="verbose">Exporting alias 'Generate-BinFile'.</S><S S="verbose">Exporting alias 'Add-BinFile'.</S><S S="verbose">Exporting alias 'Start-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Invoke-ChocolateyProcess'.</S><S S="verbose">Exporting alias 'Remove-BinFile'.</S><S S="verbose">Exporting alias 'refreshenv'.</S><S S="debug">Running Write-ChocolateyFailure -packageName 'memcached' -failureMessage 'Cannot bind argument to parameter 'Path' because it is an empty string.' </S><S S="warning">Write-ChocolateyFailure was removed in Chocolatey CLI v1. If you are the package maintainer, please use 'throw $_.Exception' instead.</S><S S="warning">If you are not the maintainer, please contact the maintainer to update the memcached package.</S><S S="Error">Cannot bind argument to parameter 'Path' because it is an empty string._x000D__x000A_</S><S S="Error">At C:\ProgramData\chocolatey\extensions\chocolatey-compatibility\helpers\Write-ChocolateyFailure.ps1:65 char:3_x000D__x000A_</S><S S="Error">+   throw "$failureMessage"_x000D__x000A_</S><S S="Error">+   ~~~~~~~~~~~~~~~~~~~~~~~_x000D__x000A_</S><S S="Error">    + CategoryInfo          : OperationStopped: (Cannot bind arg...n empty string.:String) [], RuntimeException_x000D__x000A_</S><S S="Error">    + FullyQualifiedErrorId : Cannot bind argument to parameter 'Path' because it is an empty string._x000D__x000A_</S><S S="Error"> _x000D__x000A_</S></Objs>
WARNING: Write-ChocolateyFailure was removed in Chocolatey CLI v1. If you are the package maintainer, please use 'throw $_.Exception' instead.
WARNING: If you are not the maintainer, please contact the maintainer to update the memcached package.
ERROR: Running ["C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NonInteractive -NoProfile -ExecutionPolicy Bypass -InputFormat Text -OutputFormat Text -EncodedCommand IAAgACAAIAAgACAAJABuAG8AUwBsAGUAZQBwACAAPQAgACQARgBhAGwAcwBlAA0ACgAgACAAIAAgACAAIAAjACQAZQBuAHYAOgBDAGgAbwBjAG8AbABhAHQAZQB5AEUAbgB2AGkAcgBvAG4AbQBlAG4AdABEAGUAYgB1AGcAPQAnAGYAYQBsAHMAZQAnAA0ACgAgACAAIAAgACAAIAAjACQAZQBuAHYAOgBDAGgAbwBjAG8AbABhAHQAZQB5AEUAbgB2AGkAcgBvAG4AbQBlAG4AdABWAGUAcgBiAG8AcwBlAD0AJwBmAGEAbABzAGUAJwANAAoAIAAgACAAIAAgACAAJgAgAGkAbQBwAG8AcgB0AC0AbQBvAGQAdQBsAGUAIAAtAG4AYQBtAGUAIAAnAEMAOgBcAFAAcgBvAGcAcgBhAG0ARABhAHQAYQBcAGMAaABvAGMAbwBsAGEAdABlAHkAXABoAGUAbABwAGUAcgBzAFwAYwBoAG8AYwBvAGwAYQB0AGUAeQBJAG4AcwB0AGEAbABsAGUAcgAuAHAAcwBtADEAJwAgAC0AVgBlAHIAYgBvAHMAZQA6ACQAZgBhAGwAcwBlACAAfAAgAE8AdQB0AC0ATgB1AGwAbAA7AA0ACgAgACAAIAAgACAAIAB0AHIAeQB7AA0ACgAgACAAIAAgACAAIAAgACAAJABwAHIAbwBnAHIAZQBzAHMAUAByAGUAZgBlAHIAZQBuAGMAZQA9ACIAUwBpAGwAZQBuAHQAbAB5AEMAbwBuAHQAaQBuAHUAZQAiAA0ACgAgACAAIAAgACAAIAAgACAAJgAgAEMAOgBcAFAAcgBvAGcAcgBhAG0ARABhAHQAYQBcAGMAaABvAGMAbwBsAGEAdABlAHkAXABsAGkAYgBcAG0AZQBtAGMAYQBjAGgAZQBkAFwAdABvAG8AbABzAFwAaQBuAHMAdABhAGwAbABtAGUAbQBjAGEAYwBoAGUAZAAuAHAAcwAxAA0ACgAgACAAIAAgACAAIAAgACAAaQBmACgAIQAkAG4AbwBTAGwAZQBlAHAAKQB7AHMAdABhAHIAdAAtAHMAbABlAGUAcAAgADYAfQANAAoAIAAgACAAIAAgACAAfQANAAoAIAAgACAAIAAgACAAYwBhAHQAYwBoAHsADQAKACAAIAAgACAAIAAgACAAIABpAGYAKAAhACQAbgBvAFMAbABlAGUAcAApAHsAcwB0AGEAcgB0AC0AcwBsAGUAZQBwACAAOAB9AA0ACgAgACAAIAAgACAAIAAgACAAdABoAHIAbwB3AA0ACgAgACAAIAAgACAAIAB9AA==] was not successful. Exit code was '1'. See log for possible error messages.
The install of memcached was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\memcached\tools\chocolateyInstall.ps1'.
 See log for details.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - memcached (exited 1) - Error while running 'C:\ProgramData\chocolatey\lib\memcached\tools\chocolateyInstall.ps1'.
 See log for details.
Chocolatey v2.5.1
Installing the following packages:
influxdb
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading NSSM 2.24.101.20180116... 100%

nssm v2.24.101.20180116 [Approved]
nssm package files install completed. Performing other installation steps.
Installing 64 bit version
Extracting C:\ProgramData\chocolatey\lib\NSSM\tools\nssm-2.24-101-g897c7ad.zip to C:\ProgramData\chocolatey\lib\NSSM\tools...
C:\ProgramData\chocolatey\lib\NSSM\tools
 ShimGen has successfully created a shim for nssm.exe
 The install of nssm was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\NSSM\tools'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading influxdb1 1.8.10... 100%

influxdb1 v1.8.10 [Approved]
influxdb1 package files install completed. Performing other installation steps.
Extracting 64-bit C:\ProgramData\chocolatey\lib\influxdb1\tools\influxdb-1.8.10_windows_amd64.zip to C:\influxdata...
C:\influxdata
 The install of influxdb1 was successful.
  Deployed to 'C:\influxdata'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading influxdb 1.8.10... 100%

influxdb v1.8.10 [Approved]
influxdb package files install completed. Performing other installation steps.
 The install of influxdb was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\influxdb'

Chocolatey installed 3/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
dbeaver
By installing, you accept licenses for the packages.
dbeaver v25.2.5 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - dbeaver - dbeaver v25.2.5 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
No package found matching input criteria.
Chocolatey v2.5.1
Installing the following packages:
mysql.workbench
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading mysql.workbench 8.0.44... 100%

mysql.workbench v8.0.44 [Approved]
mysql.workbench package files install completed. Performing other installation steps.
Downloading mysql.workbench
  from 'https://cdn.mysql.com/Downloads/MySQLGUITools/mysql-workbench-community-8.0.44-winx64.msi'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\mysql.workbench\8.0.44\mysql-workbench-community-8.0.44-winx64.msi (252.09 MB).
Download of mysql-workbench-community-8.0.44-winx64.msi (252.09 MB) completed.
Hashes match.
Installing mysql.workbench...
mysql.workbench has been installed.
  mysql.workbench may be able to be automatically uninstalled.
 The install of mysql.workbench was successful.
  Software installed as 'msi', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
pgadmin4
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading pgadmin4 9.10.0... 100%

pgadmin4 v9.10.0 [Approved]
pgadmin4 package files install completed. Performing other installation steps.
Downloading pgadmin4 64 bit
  from 'https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v9.10/windows/pgadmin4-9.10-x64.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\pgadmin4\9.10.0\pgadmin4-9.10-x64.exe (211.47 MB).
Download of pgadmin4-9.10-x64.exe (211.47 MB) completed.
Hashes match.
Installing pgadmin4...
pgadmin4 has been installed.
  pgadmin4 can be automatically uninstalled.
 The install of pgadmin4 was successful.
  Deployed to 'C:\Program Files\pgAdmin 4\'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Enjoy using Chocolatey? Explore more amazing features to take your
experience to the next level at
 https://chocolatey.org/compare
Collecting mycli
  Downloading mycli-1.41.2-py3-none-any.whl.metadata (6.1 kB)
Collecting pgcli
  Downloading pgcli-4.3.0-py3-none-any.whl.metadata (13 kB)
Collecting litecli
  Downloading litecli-1.17.0-py3-none-any.whl.metadata (2.4 kB)
Requirement already satisfied: click>=8.3.1 in c:\program files\python313\lib\site-packages (from mycli) (8.3.1)
Requirement already satisfied: cryptography>=1.0.0 in c:\program files\python313\lib\site-packages (from mycli) (43.0.3)
Requirement already satisfied: Pygments>=1.6 in c:\program files\python313\lib\site-packages (from mycli) (2.19.2)
Requirement already satisfied: prompt_toolkit<4.0.0,>=3.0.6 in c:\program files\python313\lib\site-packages (from mycli) (3.0.52)
Collecting PyMySQL>=0.9.2 (from mycli)
  Downloading pymysql-1.1.2-py3-none-any.whl.metadata (4.3 kB)
Requirement already satisfied: sqlparse<0.6.0,>=0.3.0 in c:\program files\python313\lib\site-packages (from mycli) (0.5.3)
Collecting sqlglot==27.* (from sqlglot[rs]==27.*->mycli)
  Downloading sqlglot-27.29.0-py3-none-any.whl.metadata (20 kB)
Requirement already satisfied: configobj>=5.0.5 in c:\program files\python313\lib\site-packages (from mycli) (5.0.9)
Collecting cli_helpers>=2.7.0 (from cli_helpers[styles]>=2.7.0->mycli)
  Downloading cli_helpers-2.7.0-py3-none-any.whl.metadata (2.6 kB)
Collecting pyperclip>=1.8.1 (from mycli)
  Downloading pyperclip-1.11.0-py3-none-any.whl.metadata (2.4 kB)
Collecting pycryptodomex (from mycli)
  Downloading pycryptodomex-3.23.0-cp37-abi3-win_amd64.whl.metadata (3.5 kB)
Collecting pyfzf>=0.3.1 (from mycli)
  Downloading pyfzf-0.3.1-py3-none-any.whl.metadata (1.8 kB)
Requirement already satisfied: wcwidth in c:\program files\python313\lib\site-packages (from prompt_toolkit<4.0.0,>=3.0.6->mycli) (0.2.14)
Collecting sqlglotrs==0.7.3 (from sqlglot[rs]==27.*->mycli)
  Downloading sqlglotrs-0.7.3-cp313-cp313-win_amd64.whl.metadata (532 bytes)
Collecting pgspecial>=2.0.0 (from pgcli)
  Downloading pgspecial-2.2.1-py3-none-any.whl.metadata (2.9 kB)
Collecting psycopg-binary>=3.0.14 (from pgcli)
  Downloading psycopg_binary-3.2.13-cp313-cp313-win_amd64.whl.metadata (2.9 kB)
Requirement already satisfied: tzlocal>=5.2 in c:\program files\python313\lib\site-packages (from pgcli) (5.3.1)
Requirement already satisfied: mypy>=1.17.1 in c:\program files\python313\lib\site-packages (from litecli) (1.18.2)
Requirement already satisfied: setuptools in c:\program files\python313\lib\site-packages (from litecli) (80.9.0)
Requirement already satisfied: pip in c:\program files\python313\lib\site-packages (from litecli) (25.3)
Collecting llm>=0.25.0 (from litecli)
  Downloading llm-0.27.1-py3-none-any.whl.metadata (30 kB)
Requirement already satisfied: tabulate>=0.9.0 in c:\program files\python313\lib\site-packages (from tabulate[widechars]>=0.9.0->cli_helpers>=2.7.0->cli_helpers[styles]>=2.7.0->mycli) (0.9.0)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from click>=8.3.1->mycli) (0.4.6)
Requirement already satisfied: cffi>=1.12 in c:\program files\python313\lib\site-packages (from cryptography>=1.0.0->mycli) (2.0.0)
Requirement already satisfied: pycparser in c:\program files\python313\lib\site-packages (from cffi>=1.12->cryptography>=1.0.0->mycli) (2.23)
Collecting condense-json>=0.1.3 (from llm>=0.25.0->litecli)
  Downloading condense_json-0.1.3-py3-none-any.whl.metadata (4.4 kB)
Requirement already satisfied: openai>=1.55.3 in c:\program files\python313\lib\site-packages (from llm>=0.25.0->litecli) (2.8.1)
Collecting click-default-group>=1.2.3 (from llm>=0.25.0->litecli)
  Downloading click_default_group-1.2.4-py2.py3-none-any.whl.metadata (2.8 kB)
Collecting sqlite-utils>=3.37 (from llm>=0.25.0->litecli)
  Downloading sqlite_utils-3.39-py3-none-any.whl.metadata (7.7 kB)
Collecting sqlite-migrate>=0.1a2 (from llm>=0.25.0->litecli)
  Downloading sqlite_migrate-0.1b0-py3-none-any.whl.metadata (5.4 kB)
Requirement already satisfied: pydantic>=2.0.0 in c:\program files\python313\lib\site-packages (from llm>=0.25.0->litecli) (2.12.4)
Requirement already satisfied: PyYAML in c:\program files\python313\lib\site-packages (from llm>=0.25.0->litecli) (6.0.3)
Requirement already satisfied: pluggy in c:\program files\python313\lib\site-packages (from llm>=0.25.0->litecli) (1.6.0)
Collecting python-ulid (from llm>=0.25.0->litecli)
  Downloading python_ulid-3.1.0-py3-none-any.whl.metadata (5.8 kB)
Collecting pyreadline3 (from llm>=0.25.0->litecli)
  Downloading pyreadline3-3.5.4-py3-none-any.whl.metadata (4.7 kB)
Collecting puremagic (from llm>=0.25.0->litecli)
  Downloading puremagic-1.30-py3-none-any.whl.metadata (5.8 kB)
Requirement already satisfied: typing_extensions>=4.6.0 in c:\program files\python313\lib\site-packages (from mypy>=1.17.1->litecli) (4.15.0)
Requirement already satisfied: mypy_extensions>=1.0.0 in c:\program files\python313\lib\site-packages (from mypy>=1.17.1->litecli) (1.1.0)
Requirement already satisfied: pathspec>=0.9.0 in c:\program files\python313\lib\site-packages (from mypy>=1.17.1->litecli) (0.12.1)
Requirement already satisfied: anyio<5,>=3.5.0 in c:\program files\python313\lib\site-packages (from openai>=1.55.3->llm>=0.25.0->litecli) (4.11.0)
Requirement already satisfied: distro<2,>=1.7.0 in c:\program files\python313\lib\site-packages (from openai>=1.55.3->llm>=0.25.0->litecli) (1.9.0)
Requirement already satisfied: httpx<1,>=0.23.0 in c:\program files\python313\lib\site-packages (from openai>=1.55.3->llm>=0.25.0->litecli) (0.28.1)
Requirement already satisfied: jiter<1,>=0.10.0 in c:\program files\python313\lib\site-packages (from openai>=1.55.3->llm>=0.25.0->litecli) (0.12.0)
Requirement already satisfied: sniffio in c:\program files\python313\lib\site-packages (from openai>=1.55.3->llm>=0.25.0->litecli) (1.3.1)
Requirement already satisfied: tqdm>4 in c:\program files\python313\lib\site-packages (from openai>=1.55.3->llm>=0.25.0->litecli) (4.67.1)
Requirement already satisfied: idna>=2.8 in c:\program files\python313\lib\site-packages (from anyio<5,>=3.5.0->openai>=1.55.3->llm>=0.25.0->litecli) (3.11)
Requirement already satisfied: certifi in c:\program files\python313\lib\site-packages (from httpx<1,>=0.23.0->openai>=1.55.3->llm>=0.25.0->litecli) (2025.11.12)
Requirement already satisfied: httpcore==1.* in c:\program files\python313\lib\site-packages (from httpx<1,>=0.23.0->openai>=1.55.3->llm>=0.25.0->litecli) (1.0.9)
Requirement already satisfied: h11>=0.16 in c:\program files\python313\lib\site-packages (from httpcore==1.*->httpx<1,>=0.23.0->openai>=1.55.3->llm>=0.25.0->litecli) (0.16.0)
Requirement already satisfied: annotated-types>=0.6.0 in c:\program files\python313\lib\site-packages (from pydantic>=2.0.0->llm>=0.25.0->litecli) (0.7.0)
Requirement already satisfied: pydantic-core==2.41.5 in c:\program files\python313\lib\site-packages (from pydantic>=2.0.0->llm>=0.25.0->litecli) (2.41.5)
Requirement already satisfied: typing-inspection>=0.4.2 in c:\program files\python313\lib\site-packages (from pydantic>=2.0.0->llm>=0.25.0->litecli) (0.4.2)
Collecting psycopg>=3.0.10 (from pgspecial>=2.0.0->pgcli)
  Downloading psycopg-3.2.13-py3-none-any.whl.metadata (4.5 kB)
Requirement already satisfied: tzdata in c:\program files\python313\lib\site-packages (from psycopg>=3.0.10->pgspecial>=2.0.0->pgcli) (2025.2)
Collecting sqlite-fts4 (from sqlite-utils>=3.37->llm>=0.25.0->litecli)
  Downloading sqlite_fts4-1.0.3-py3-none-any.whl.metadata (6.6 kB)
Requirement already satisfied: python-dateutil in c:\program files\python313\lib\site-packages (from sqlite-utils>=3.37->llm>=0.25.0->litecli) (2.9.0.post0)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil->sqlite-utils>=3.37->llm>=0.25.0->litecli) (1.17.0)
Downloading mycli-1.41.2-py3-none-any.whl (84 kB)
Downloading sqlglot-27.29.0-py3-none-any.whl (526 kB)
   ---------------------------------------- 526.1/526.1 kB 7.3 MB/s  0:00:00
Downloading sqlglotrs-0.7.3-cp313-cp313-win_amd64.whl (195 kB)
Downloading pgcli-4.3.0-py3-none-any.whl (85 kB)
Downloading litecli-1.17.0-py3-none-any.whl (56 kB)
Downloading cli_helpers-2.7.0-py3-none-any.whl (20 kB)
Downloading llm-0.27.1-py3-none-any.whl (82 kB)
Downloading click_default_group-1.2.4-py2.py3-none-any.whl (4.1 kB)
Downloading condense_json-0.1.3-py3-none-any.whl (8.4 kB)
Downloading pgspecial-2.2.1-py3-none-any.whl (35 kB)
Downloading psycopg-3.2.13-py3-none-any.whl (206 kB)
Downloading psycopg_binary-3.2.13-cp313-cp313-win_amd64.whl (2.9 MB)
   ---------------------------------------- 2.9/2.9 MB 28.2 MB/s  0:00:00
Downloading pyfzf-0.3.1-py3-none-any.whl (4.3 kB)
Downloading pymysql-1.1.2-py3-none-any.whl (45 kB)
Downloading pyperclip-1.11.0-py3-none-any.whl (11 kB)
Downloading sqlite_migrate-0.1b0-py3-none-any.whl (10.0 kB)
Downloading sqlite_utils-3.39-py3-none-any.whl (68 kB)
Downloading puremagic-1.30-py3-none-any.whl (43 kB)
Downloading pycryptodomex-3.23.0-cp37-abi3-win_amd64.whl (1.8 MB)
   ---------------------------------------- 1.8/1.8 MB 16.5 MB/s  0:00:00
Downloading pyreadline3-3.5.4-py3-none-any.whl (83 kB)
Downloading python_ulid-3.1.0-py3-none-any.whl (11 kB)
Downloading sqlite_fts4-1.0.3-py3-none-any.whl (10.0 kB)
Installing collected packages: sqlite-fts4, pyperclip, pyfzf, puremagic, sqlglotrs, sqlglot, python-ulid, pyreadline3, PyMySQL, pycryptodomex, psycopg-binary, psycopg, condense-json, pgspecial, click-default-group, cli_helpers, sqlite-utils, sqlite-migrate, pgcli, mycli, llm, litecli
Successfully installed PyMySQL-1.1.2 cli_helpers-2.7.0 click-default-group-1.2.4 condense-json-0.1.3 litecli-1.17.0 llm-0.27.1 mycli-1.41.2 pgcli-4.3.0 pgspecial-2.2.1 psycopg-3.2.13 psycopg-binary-3.2.13 puremagic-1.30 pycryptodomex-3.23.0 pyfzf-0.3.1 pyperclip-1.11.0 pyreadline3-3.5.4 python-ulid-3.1.0 sqlglot-27.29.0 sqlglotrs-0.7.3 sqlite-fts4-1.0.3 sqlite-migrate-0.1b0 sqlite-utils-3.39

[9/20] Web Development Tools
Chocolatey v2.5.1
Installing the following packages:
googlechrome;firefox;brave
By installing, you accept licenses for the packages.
GoogleChrome v142.0.7444.176 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Firefox v145.0.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading brave 1.84.141... 100%

brave v1.84.141 [Approved]
brave package files install completed. Performing other installation steps.
Checking already installed version...
WARNING: No registry key found based on  'Brave*'
Installing 64-bit brave...
brave has been installed.
  brave may be able to be automatically uninstalled.
 The install of brave was successful.
  Deployed to 'C:\Users\shelc\AppData\Local\BraveSoftware\Brave-Browser\Application'

Chocolatey installed 1/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - Firefox - Firefox v145.0.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - GoogleChrome - GoogleChrome v142.0.7444.176 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Found Microsoft Edge Dev [Microsoft.Edge.Dev] Version 142.0.3581.0
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Downloading https://msedge.sf.dl.delivery.mp.microsoft.com/filestreamingservice/files/a9930a1a-2355-43d5-a4cb-6739ef6be877/MicrosoftEdgeDevEnterpriseX64.msi
  ██████████████████████████████   182 MB /  182 MB
Successfully verified installer hash
Starting package install...
Successfully installed
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Chocolatey v2.5.1
Installing the following packages:
insomnia-rest-api-client
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading insomnia-rest-api-client 2023.11.2... 100%

insomnia-rest-api-client v2023.11.2 [Approved] - Likely broken for FOSS users (due to download location changes)
insomnia-rest-api-client package files install completed. Performing other installation steps.
Downloading insomnia-rest-api-client
  from 'https://github.com/Kong/insomnia/releases/download/core%4011.2.0/Insomnia.Core-11.2.0.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\insomnia-rest-api-client\2023.11.2\Insomnia.Core-11.2.0.exe (159.9 MB).
Download of Insomnia.Core-11.2.0.exe (159.9 MB) completed.
Hashes match.
Installing insomnia-rest-api-client...
insomnia-rest-api-client has been installed.
  insomnia-rest-api-client can be automatically uninstalled.
 The install of insomnia-rest-api-client was successful.
  Deployed to 'C:\Users\shelc\AppData\Local\insomnia'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
soapui
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading soapui 5.8.0... 100%

soapui v5.8.0 [Approved]
soapui package files install completed. Performing other installation steps.
WARNING: No registry key found based on  'soapui*'
Downloading soapui 64 bit
  from 'https://dl.eviware.com/soapuios/5.8.0/SoapUI-x64-5.8.0.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\soapui\5.8.0\SoapUI-x64-5.8.0.exe (181.91 MB).
Download of SoapUI-x64-5.8.0.exe (181.91 MB) completed.
Hashes match.
Installing soapui...
soapui has been installed.
  soapui may be able to be automatically uninstalled.
 The install of soapui was successful.
  Deployed to 'C:\Program Files\SmartBear\SoapUI-5.8.0'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
npm warn deprecated source-map-url@0.4.1: See https://github.com/lydell/source-map-url#deprecated
npm warn deprecated opn@6.0.0: The package has been renamed to `open`
npm warn deprecated urix@0.1.0: Please see https://github.com/lydell/urix#deprecated
npm warn deprecated resolve-url@0.2.1: https://github.com/lydell/resolve-url#deprecated
npm warn deprecated source-map-resolve@0.5.3: See https://github.com/lydell/source-map-resolve#deprecated
npm warn deprecated uuid@3.4.0: Please upgrade  to version 7 or higher.  Older versions may use Math.random() in certain circumstances, which is known to be problematic.  See https://v8.dev/blog/math-random for details.

added 345 packages in 7s

13 packages are looking for funding
  run `npm fund` for details

[10/20] Data Science & AI/ML Tools
Chocolatey v2.5.1
Installing the following packages:
miniconda3
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading miniconda3 4.12.0... 100%

miniconda3 v4.12.0 [Approved]
miniconda3 package files install completed. Performing other installation steps.
Downloading miniconda3 64 bit
  from 'https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Windows-x86_64.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\miniconda3\4.12.0\Miniconda3-py39_4.12.0-Windows-x86_64.exe (71.23 MB).
Download of Miniconda3-py39_4.12.0-Windows-x86_64.exe (71.23 MB) completed.
Hashes match.
Installing miniconda3...
miniconda3 has been installed.
  miniconda3 can be automatically uninstalled.
 The install of miniconda3 was successful.
  Deployed to 'C:\tools\miniconda3'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
powerbi
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading DotNet4.5.2 4.5.2.20140902... 100%

DotNet4.5.2 v4.5.2.20140902 [Approved]
DotNet4.5.2 package files install completed. Performing other installation steps.
Microsoft .Net 4.5.2 Framework is already installed on your machine.
 The install of DotNet4.5.2 was successful.
  Software install location not explicitly set, it could be in package or
  default install location of installer.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading PowerBI 2.149.911... 100%

PowerBI v2.149.911 [Approved]
PowerBI package files install completed. Performing other installation steps.
Downloading PowerBI 64 bit
  from 'https://download.microsoft.com/download/8/8/0/880BCA75-79DD-466A-927D-1ABF1F5454B0/PBIDesktopSetup-2025-11_x64.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\PowerBI\2.149.911\PBIDesktopSetup-2025-11_x64.exe (831.32 MB).
Download of PBIDesktopSetup-2025-11_x64.exe (831.32 MB) completed.
Error - hashes do not match. Actual value was 'D2B14A3754CD0D0B577B3D44C6E75479B31709B48C6D85A9B2050B23ECB9D5AE'.
ERROR: Checksum for 'C:\Users\shelc\AppData\Local\Temp\chocolatey\PowerBI\2.149.911\PBIDesktopSetup-2025-11_x64.exe' did not meet 'E4E5630DBE6D86BC99E81C7615F736FFB9C0CE57B3C9F15BEB46233A6997DC2F' for checksum type 'SHA256'. Consider passing the actual checksums through with --checksum --checksum64 once you validate the checksums are appropriate. A less secure option is to pass --ignore-checksums if necessary.
The install of PowerBI was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\PowerBI\tools\ChocolateyInstall.ps1'.
 See log for details.

Chocolatey installed 1/2 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - PowerBI (exited -1) - Error while running 'C:\ProgramData\chocolatey\lib\PowerBI\tools\ChocolateyInstall.ps1'.
 See log for details.
Chocolatey v2.5.1
Installing the following packages:
r.project
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading R.Project 4.5.2... 100%

R.Project v4.5.2 [Approved]
R.Project package files install completed. Performing other installation steps.
Installing r.project...
r.project has been installed.
 The install of R.Project was successful.
  Software installed as 'exe', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
r.studio
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading R.Studio 2025.9.2... 100%

r.studio v2025.9.2 [Approved]
r.studio package files install completed. Performing other installation steps.
Downloading R.Studio 64 bit
  from 'https://download1.rstudio.org/electron/windows/RStudio-2025.09.2-418.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\R.Studio\2025.9.2\RStudio-2025.09.2-418.exe (283 MB).
Download of RStudio-2025.09.2-418.exe (283 MB) completed.
Hashes match.
Installing R.Studio...
R.Studio has been installed.
 The install of r.studio was successful.
  Software installed as 'exe', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Enjoy using Chocolatey? Explore more amazing features to take your
experience to the next level at
 https://chocolatey.org/compare
Chocolatey v2.5.1
Installing the following packages:
rapidminer-studio
By installing, you accept licenses for the packages.
rapidminer-studio not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - rapidminer-studio - rapidminer-studio not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Enjoy using Chocolatey? Explore more amazing features to take your
experience to the next level at
 https://chocolatey.org/compare
Collecting orange3
  Downloading orange3-3.39.0-cp313-cp313-win_amd64.whl.metadata (3.9 kB)
Collecting AnyQt>=0.2.0 (from orange3)
  Downloading anyqt-0.2.1-py3-none-any.whl.metadata (1.7 kB)
Collecting baycomp>=1.0.2 (from orange3)
  Downloading baycomp-1.0.3.tar.gz (15 kB)
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Collecting bottleneck>=1.3.4 (from orange3)
  Downloading bottleneck-1.6.0-cp313-cp313-win_amd64.whl.metadata (8.4 kB)
Collecting chardet>=3.0.2 (from orange3)
  Downloading chardet-5.2.0-py3-none-any.whl.metadata (3.4 kB)
Requirement already satisfied: httpx>=0.21.0 in c:\program files\python313\lib\site-packages (from orange3) (0.28.1)
Requirement already satisfied: joblib>=1.2.0 in c:\program files\python313\lib\site-packages (from orange3) (1.5.2)
Collecting keyring (from orange3)
  Downloading keyring-25.7.0-py3-none-any.whl.metadata (21 kB)
Collecting keyrings.alt (from orange3)
  Downloading keyrings.alt-5.0.2-py3-none-any.whl.metadata (3.6 kB)
Requirement already satisfied: matplotlib>=3.2.0 in c:\program files\python313\lib\site-packages (from orange3) (3.10.7)
Requirement already satisfied: networkx in c:\program files\python313\lib\site-packages (from orange3) (3.5)
Requirement already satisfied: numpy>=1.21.0 in c:\program files\python313\lib\site-packages (from orange3) (2.2.6)
Collecting openTSNE!=0.7.0,>=0.6.2 (from orange3)
  Downloading opentsne-1.0.4-cp313-cp313-win_amd64.whl.metadata (8.3 kB)
Collecting openpyxl>=3.1.3 (from orange3)
  Downloading openpyxl-3.1.5-py2.py3-none-any.whl.metadata (2.5 kB)
Collecting orange-canvas-core<0.3a,>=0.2.5 (from orange3)
  Downloading orange_canvas_core-0.2.6-py3-none-any.whl.metadata (2.3 kB)
Collecting orange-widget-base>=4.25.0 (from orange3)
  Downloading orange_widget_base-4.26.0-py3-none-any.whl.metadata (1.8 kB)
Requirement already satisfied: packaging in c:\program files\python313\lib\site-packages (from orange3) (25.0)
Requirement already satisfied: pandas!=1.5.0,!=2.0.0,>=1.4.0 in c:\program files\python313\lib\site-packages (from orange3) (2.2.3)
Requirement already satisfied: pip>=19.3 in c:\program files\python313\lib\site-packages (from orange3) (25.3)
Requirement already satisfied: pygments>=2.8.0 in c:\program files\python313\lib\site-packages (from orange3) (2.19.2)
Collecting pyqtgraph>=0.13.1 (from orange3)
  Downloading pyqtgraph-0.14.0-py3-none-any.whl.metadata (1.5 kB)
Collecting python-louvain>=0.13 (from orange3)
  Downloading python-louvain-0.16.tar.gz (204 kB)
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Requirement already satisfied: pyyaml in c:\program files\python313\lib\site-packages (from orange3) (6.0.3)
Collecting qtconsole>=4.7.2 (from orange3)
  Downloading qtconsole-5.7.0-py3-none-any.whl.metadata (5.4 kB)
Requirement already satisfied: requests in c:\program files\python313\lib\site-packages (from orange3) (2.32.4)
Requirement already satisfied: scikit-learn>=1.5.1 in c:\program files\python313\lib\site-packages (from orange3) (1.7.2)
Requirement already satisfied: scipy>=1.9 in c:\program files\python313\lib\site-packages (from orange3) (1.16.3)
Collecting serverfiles (from orange3)
  Downloading serverfiles-0.3.1.tar.gz (11 kB)
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Collecting xgboost<2.1,>=1.7.4 (from orange3)
  Downloading xgboost-2.0.3-py3-none-win_amd64.whl.metadata (2.0 kB)
Collecting xlrd>=1.2.0 (from orange3)
  Downloading xlrd-2.0.2-py2.py3-none-any.whl.metadata (3.5 kB)
Collecting xlsxwriter (from orange3)
  Downloading xlsxwriter-3.2.9-py3-none-any.whl.metadata (2.7 kB)
Collecting docutils (from orange-canvas-core<0.3a,>=0.2.5->orange3)
  Downloading docutils-0.22.3-py3-none-any.whl.metadata (15 kB)
Collecting commonmark>=0.8.1 (from orange-canvas-core<0.3a,>=0.2.5->orange3)
  Downloading commonmark-0.9.1-py2.py3-none-any.whl.metadata (5.7 kB)
Collecting requests-cache (from orange-canvas-core<0.3a,>=0.2.5->orange3)
  Downloading requests_cache-1.2.1-py3-none-any.whl.metadata (9.9 kB)
Requirement already satisfied: dictdiffer in c:\program files\python313\lib\site-packages (from orange-canvas-core<0.3a,>=0.2.5->orange3) (0.9.0)
Collecting qasync>=0.10.0 (from orange-canvas-core<0.3a,>=0.2.5->orange3)
  Downloading qasync-0.28.0-py3-none-any.whl.metadata (4.6 kB)
Requirement already satisfied: typing_extensions in c:\program files\python313\lib\site-packages (from orange-canvas-core<0.3a,>=0.2.5->orange3) (4.15.0)
Collecting truststore (from orange-canvas-core<0.3a,>=0.2.5->orange3)
  Downloading truststore-0.10.4-py3-none-any.whl.metadata (4.4 kB)
Requirement already satisfied: anyio in c:\program files\python313\lib\site-packages (from httpx>=0.21.0->orange3) (4.11.0)
Requirement already satisfied: certifi in c:\program files\python313\lib\site-packages (from httpx>=0.21.0->orange3) (2025.11.12)
Requirement already satisfied: httpcore==1.* in c:\program files\python313\lib\site-packages (from httpx>=0.21.0->orange3) (1.0.9)
Requirement already satisfied: idna in c:\program files\python313\lib\site-packages (from httpx>=0.21.0->orange3) (3.11)
Requirement already satisfied: h11>=0.16 in c:\program files\python313\lib\site-packages (from httpcore==1.*->httpx>=0.21.0->orange3) (0.16.0)
Requirement already satisfied: contourpy>=1.0.1 in c:\program files\python313\lib\site-packages (from matplotlib>=3.2.0->orange3) (1.3.3)
Requirement already satisfied: cycler>=0.10 in c:\program files\python313\lib\site-packages (from matplotlib>=3.2.0->orange3) (0.12.1)
Requirement already satisfied: fonttools>=4.22.0 in c:\program files\python313\lib\site-packages (from matplotlib>=3.2.0->orange3) (4.60.1)
Requirement already satisfied: kiwisolver>=1.3.1 in c:\program files\python313\lib\site-packages (from matplotlib>=3.2.0->orange3) (1.4.9)
Requirement already satisfied: pillow>=8 in c:\program files\python313\lib\site-packages (from matplotlib>=3.2.0->orange3) (12.0.0)
Requirement already satisfied: pyparsing>=3 in c:\program files\python313\lib\site-packages (from matplotlib>=3.2.0->orange3) (3.2.5)
Requirement already satisfied: python-dateutil>=2.7 in c:\program files\python313\lib\site-packages (from matplotlib>=3.2.0->orange3) (2.9.0.post0)
Collecting et-xmlfile (from openpyxl>=3.1.3->orange3)
  Downloading et_xmlfile-2.0.0-py3-none-any.whl.metadata (2.7 kB)
Requirement already satisfied: pytz>=2020.1 in c:\program files\python313\lib\site-packages (from pandas!=1.5.0,!=2.0.0,>=1.4.0->orange3) (2025.2)
Requirement already satisfied: tzdata>=2022.7 in c:\program files\python313\lib\site-packages (from pandas!=1.5.0,!=2.0.0,>=1.4.0->orange3) (2025.2)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from pyqtgraph>=0.13.1->orange3) (0.4.6)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil>=2.7->matplotlib>=3.2.0->orange3) (1.17.0)
Requirement already satisfied: traitlets!=5.2.1,!=5.2.2 in c:\program files\python313\lib\site-packages (from qtconsole>=4.7.2->orange3) (5.14.3)
Requirement already satisfied: jupyter_core in c:\program files\python313\lib\site-packages (from qtconsole>=4.7.2->orange3) (5.9.1)
Requirement already satisfied: jupyter_client>=4.1 in c:\program files\python313\lib\site-packages (from qtconsole>=4.7.2->orange3) (8.6.3)
Requirement already satisfied: ipykernel>=4.1 in c:\program files\python313\lib\site-packages (from qtconsole>=4.7.2->orange3) (7.1.0)
Requirement already satisfied: ipython_pygments_lexers in c:\program files\python313\lib\site-packages (from qtconsole>=4.7.2->orange3) (1.1.1)
Collecting qtpy>=2.4.0 (from qtconsole>=4.7.2->orange3)
  Downloading QtPy-2.4.3-py3-none-any.whl.metadata (12 kB)
Requirement already satisfied: comm>=0.1.1 in c:\program files\python313\lib\site-packages (from ipykernel>=4.1->qtconsole>=4.7.2->orange3) (0.2.3)
Requirement already satisfied: debugpy>=1.6.5 in c:\program files\python313\lib\site-packages (from ipykernel>=4.1->qtconsole>=4.7.2->orange3) (1.8.17)
Requirement already satisfied: ipython>=7.23.1 in c:\program files\python313\lib\site-packages (from ipykernel>=4.1->qtconsole>=4.7.2->orange3) (9.7.0)
Requirement already satisfied: matplotlib-inline>=0.1 in c:\program files\python313\lib\site-packages (from ipykernel>=4.1->qtconsole>=4.7.2->orange3) (0.2.1)
Requirement already satisfied: nest-asyncio>=1.4 in c:\program files\python313\lib\site-packages (from ipykernel>=4.1->qtconsole>=4.7.2->orange3) (1.6.0)
Requirement already satisfied: psutil>=5.7 in c:\program files\python313\lib\site-packages (from ipykernel>=4.1->qtconsole>=4.7.2->orange3) (7.1.3)
Requirement already satisfied: pyzmq>=25 in c:\program files\python313\lib\site-packages (from ipykernel>=4.1->qtconsole>=4.7.2->orange3) (27.1.0)
Requirement already satisfied: tornado>=6.2 in c:\program files\python313\lib\site-packages (from ipykernel>=4.1->qtconsole>=4.7.2->orange3) (6.5.2)
Requirement already satisfied: decorator>=4.3.2 in c:\program files\python313\lib\site-packages (from ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (5.2.1)
Requirement already satisfied: jedi>=0.18.1 in c:\program files\python313\lib\site-packages (from ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (0.19.2)
Requirement already satisfied: prompt_toolkit<3.1.0,>=3.0.41 in c:\program files\python313\lib\site-packages (from ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (3.0.52)
Requirement already satisfied: stack_data>=0.6.0 in c:\program files\python313\lib\site-packages (from ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (0.6.3)
Requirement already satisfied: wcwidth in c:\program files\python313\lib\site-packages (from prompt_toolkit<3.1.0,>=3.0.41->ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (0.2.14)
Requirement already satisfied: parso<0.9.0,>=0.8.4 in c:\program files\python313\lib\site-packages (from jedi>=0.18.1->ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (0.8.5)
Requirement already satisfied: platformdirs>=2.5 in c:\program files\python313\lib\site-packages (from jupyter_core->qtconsole>=4.7.2->orange3) (4.5.0)
Requirement already satisfied: threadpoolctl>=3.1.0 in c:\program files\python313\lib\site-packages (from scikit-learn>=1.5.1->orange3) (3.6.0)
Requirement already satisfied: executing>=1.2.0 in c:\program files\python313\lib\site-packages (from stack_data>=0.6.0->ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (2.2.1)
Requirement already satisfied: asttokens>=2.1.0 in c:\program files\python313\lib\site-packages (from stack_data>=0.6.0->ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (3.0.1)
Requirement already satisfied: pure-eval in c:\program files\python313\lib\site-packages (from stack_data>=0.6.0->ipython>=7.23.1->ipykernel>=4.1->qtconsole>=4.7.2->orange3) (0.2.3)
Requirement already satisfied: sniffio>=1.1 in c:\program files\python313\lib\site-packages (from anyio->httpx>=0.21.0->orange3) (1.3.1)
Collecting pywin32-ctypes>=0.2.0 (from keyring->orange3)
  Downloading pywin32_ctypes-0.2.3-py3-none-any.whl.metadata (3.9 kB)
Collecting jaraco.classes (from keyring->orange3)
  Downloading jaraco.classes-3.4.0-py3-none-any.whl.metadata (2.6 kB)
Collecting jaraco.functools (from keyring->orange3)
  Downloading jaraco_functools-4.3.0-py3-none-any.whl.metadata (2.9 kB)
Collecting jaraco.context (from keyring->orange3)
  Downloading jaraco.context-6.0.1-py3-none-any.whl.metadata (4.1 kB)
Requirement already satisfied: more-itertools in c:\program files\python313\lib\site-packages (from jaraco.classes->keyring->orange3) (10.8.0)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests->orange3) (3.4.4)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests->orange3) (2.5.0)
Requirement already satisfied: attrs>=21.2 in c:\program files\python313\lib\site-packages (from requests-cache->orange-canvas-core<0.3a,>=0.2.5->orange3) (25.4.0)
Collecting cattrs>=22.2 (from requests-cache->orange-canvas-core<0.3a,>=0.2.5->orange3)
  Downloading cattrs-25.3.0-py3-none-any.whl.metadata (8.4 kB)
Collecting url-normalize>=1.4 (from requests-cache->orange-canvas-core<0.3a,>=0.2.5->orange3)
  Downloading url_normalize-2.2.1-py3-none-any.whl.metadata (5.6 kB)
Downloading orange3-3.39.0-cp313-cp313-win_amd64.whl (3.6 MB)
   ---------------------------------------- 3.6/3.6 MB 6.4 MB/s  0:00:00
Downloading orange_canvas_core-0.2.6-py3-none-any.whl (535 kB)
   ---------------------------------------- 535.3/535.3 kB 26.0 MB/s  0:00:00
Downloading xgboost-2.0.3-py3-none-win_amd64.whl (99.8 MB)
   ---------------------------------------- 99.8/99.8 MB 33.4 MB/s  0:00:02
Downloading anyqt-0.2.1-py3-none-any.whl (56 kB)
Downloading bottleneck-1.6.0-cp313-cp313-win_amd64.whl (113 kB)
Downloading chardet-5.2.0-py3-none-any.whl (199 kB)
Downloading commonmark-0.9.1-py2.py3-none-any.whl (51 kB)
Downloading openpyxl-3.1.5-py2.py3-none-any.whl (250 kB)
Downloading opentsne-1.0.4-cp313-cp313-win_amd64.whl (437 kB)
Downloading orange_widget_base-4.26.0-py3-none-any.whl (270 kB)
Downloading pyqtgraph-0.14.0-py3-none-any.whl (1.9 MB)
   ---------------------------------------- 1.9/1.9 MB 54.3 MB/s  0:00:00
Downloading qasync-0.28.0-py3-none-any.whl (16 kB)
Downloading qtconsole-5.7.0-py3-none-any.whl (125 kB)
Downloading QtPy-2.4.3-py3-none-any.whl (95 kB)
Downloading xlrd-2.0.2-py2.py3-none-any.whl (96 kB)
Downloading docutils-0.22.3-py3-none-any.whl (633 kB)
   ---------------------------------------- 633.0/633.0 kB 44.1 MB/s  0:00:00
Downloading et_xmlfile-2.0.0-py3-none-any.whl (18 kB)
Downloading keyring-25.7.0-py3-none-any.whl (39 kB)
Downloading pywin32_ctypes-0.2.3-py3-none-any.whl (30 kB)
Downloading jaraco.classes-3.4.0-py3-none-any.whl (6.8 kB)
Downloading jaraco.context-6.0.1-py3-none-any.whl (6.8 kB)
Downloading jaraco_functools-4.3.0-py3-none-any.whl (10 kB)
Downloading keyrings.alt-5.0.2-py3-none-any.whl (17 kB)
Downloading requests_cache-1.2.1-py3-none-any.whl (61 kB)
Downloading cattrs-25.3.0-py3-none-any.whl (70 kB)
Downloading url_normalize-2.2.1-py3-none-any.whl (14 kB)
Downloading truststore-0.10.4-py3-none-any.whl (18 kB)
Downloading xlsxwriter-3.2.9-py3-none-any.whl (175 kB)
Building wheels for collected packages: baycomp, python-louvain, serverfiles
  Building wheel for baycomp (pyproject.toml) ... done
  Created wheel for baycomp: filename=baycomp-1.0.3-py3-none-any.whl size=18142 sha256=d3737865e3a7ad59ca28e28a0ec9e0146bdcd55ce56ae305b72f952da9d57b28
  Stored in directory: c:\users\shelc\appdata\local\pip\cache\wheels\6f\ee\34\0c3ca46d0614176bf1473c97c96cd293419a1d916d5a4d3f16
  Building wheel for python-louvain (pyproject.toml) ... done
  Created wheel for python-louvain: filename=python_louvain-0.16-py3-none-any.whl size=9473 sha256=2e3680c762fea11882fb9c81fa98a98f73b20e3a4931b5067e29449d6148c5b2
  Stored in directory: c:\users\shelc\appdata\local\pip\cache\wheels\ee\52\54\7ecd0f1ebf5f5a8466f70a27ed2b94d20b955376879d6159c5
  Building wheel for serverfiles (pyproject.toml) ... done
  Created wheel for serverfiles: filename=serverfiles-0.3.1-py3-none-any.whl size=6998 sha256=18f154e5c6a32f4e23bb463a0cadd7e3ad1465e0c9a2f6d03baae804f5f9a972
  Stored in directory: c:\users\shelc\appdata\local\pip\cache\wheels\c3\1a\05\e4a4e07a6f6a7acdf65ccb045d070961c2f1155a867147b137
Successfully built baycomp python-louvain serverfiles
Installing collected packages: commonmark, xlsxwriter, xlrd, url-normalize, truststore, qtpy, qasync, pywin32-ctypes, python-louvain, pyqtgraph, jaraco.functools, jaraco.context, jaraco.classes, et-xmlfile, docutils, chardet, cattrs, bottleneck, AnyQt, xgboost, serverfiles, requests-cache, openpyxl, keyrings.alt, keyring, orange-canvas-core, openTSNE, baycomp, qtconsole, orange-widget-base, orange3
  Attempting uninstall: xgboost
    Found existing installation: xgboost 3.1.2
    Uninstalling xgboost-3.1.2:
      Successfully uninstalled xgboost-3.1.2
Successfully installed AnyQt-0.2.1 baycomp-1.0.3 bottleneck-1.6.0 cattrs-25.3.0 chardet-5.2.0 commonmark-0.9.1 docutils-0.22.3 et-xmlfile-2.0.0 jaraco.classes-3.4.0 jaraco.context-6.0.1 jaraco.functools-4.3.0 keyring-25.7.0 keyrings.alt-5.0.2 openTSNE-1.0.4 openpyxl-3.1.5 orange-canvas-core-0.2.6 orange-widget-base-4.26.0 orange3-3.39.0 pyqtgraph-0.14.0 python-louvain-0.16 pywin32-ctypes-0.2.3 qasync-0.28.0 qtconsole-5.7.0 qtpy-2.4.3 requests-cache-1.2.1 serverfiles-0.3.1 truststore-0.10.4 url-normalize-2.2.1 xgboost-2.0.3 xlrd-2.0.2 xlsxwriter-3.2.9
Chocolatey v2.5.1
Installing the following packages:
knime
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading knime.install 4.6.0... 100%

knime.install v4.6.0 [Approved] - Likely broken for FOSS users (due to download location changes)
knime.install package files install completed. Performing other installation steps.
Attempt to get headers for https://download.knime.org/analytics-platform/win/KNIME%204.6.0%20Installer%20%2864bit%29.exe failed.
  The remote file either doesn't exist, is unauthorized, or is forbidden for url 'https://download.knime.org/analytics-platform/win/KNIME%204.6.0%20Installer%20%2864bit%29.exe'. Exception calling "GetResponse" with "0" argument(s): "The remote server returned an error: (403) Forbidden."
Downloading knime.install 64 bit
  from 'https://download.knime.org/analytics-platform/win/KNIME%204.6.0%20Installer%20%2864bit%29.exe'
ERROR: The remote file either doesn't exist, is unauthorized, or is forbidden for url 'https://download.knime.org/analytics-platform/win/KNIME%204.6.0%20Installer%20%2864bit%29.exe'. Exception calling "GetResponse" with "0" argument(s): "The remote server returned an error: (403) Forbidden."
This package is likely not broken for licensed users - see https://docs.chocolatey.org/en-us/features/private-cdn.
The install of knime.install was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\knime.install\tools\chocolateyInstall.ps1'.
 See log for details.
Failed to install knime because a previous dependency failed.

Chocolatey installed 0/2 packages. 2 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - knime - Failed to install knime because a previous dependency failed.
 - knime.install (exited 404) - Error while running 'C:\ProgramData\chocolatey\lib\knime.install\tools\chocolateyInstall.ps1'.
 See log for details.
Chocolatey v2.5.1
Installing the following packages:
weka
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading Weka 3.8.6... 100%

weka v3.8.6 [Approved]
weka package files install completed. Performing other installation steps.
Downloading Weka
  from 'https://prdownloads.sourceforge.net/weka/weka-3-8-6.zip'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\Weka\3.8.6\weka-3-8-6.zip (56.81 MB).
Download of weka-3-8-6.zip (56.81 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\chocolatey\Weka\3.8.6\weka-3-8-6.zip to C:\Program Files...
C:\Program Files
 The install of weka was successful.
  Deployed to 'C:\Program Files'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

[11/20] DevOps, CI/CD, Cloud Tools
Chocolatey v2.5.1
Installing the following packages:
terraform;packer;pulumi
By installing, you accept licenses for the packages.
terraform v1.14.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
packer v1.14.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading pulumi 3.207.0... 100%

pulumi v3.207.0 [Approved]
pulumi package files install completed. Performing other installation steps.
Attempt to use original download file name failed for 'C:\ProgramData\chocolatey\lib\pulumi\tools\pulumi-v3.207.0-windows-x64.zip'.
Copying pulumi
  from 'C:\ProgramData\chocolatey\lib\pulumi\tools\pulumi-v3.207.0-windows-x64.zip'
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\chocolatey\pulumi\3.207.0\pulumiInstall.zip to C:\ProgramData\chocolatey\lib\pulumi\tools...
C:\ProgramData\chocolatey\lib\pulumi\tools
PATH environment variable does not have C:\ProgramData\chocolatey\lib\pulumi\tools\Pulumi\bin in it. Adding...
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of pulumi was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\pulumi\tools'

Chocolatey installed 1/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - packer - packer v1.14.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - terraform - terraform v1.14.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Requirement already satisfied: ansible in c:\program files\python313\lib\site-packages (13.0.0)
Collecting ansible-lint
  Downloading ansible_lint-25.11.1-py3-none-any.whl.metadata (6.3 kB)
Requirement already satisfied: ansible-core~=2.20.0 in c:\program files\python313\lib\site-packages (from ansible) (2.20.0)
Requirement already satisfied: jinja2>=3.1.0 in c:\program files\python313\lib\site-packages (from ansible-core~=2.20.0->ansible) (3.1.6)
Requirement already satisfied: PyYAML>=5.1 in c:\program files\python313\lib\site-packages (from ansible-core~=2.20.0->ansible) (6.0.3)
Requirement already satisfied: cryptography in c:\program files\python313\lib\site-packages (from ansible-core~=2.20.0->ansible) (43.0.3)
Requirement already satisfied: packaging in c:\program files\python313\lib\site-packages (from ansible-core~=2.20.0->ansible) (25.0)
Requirement already satisfied: resolvelib<2.0.0,>=0.8.0 in c:\program files\python313\lib\site-packages (from ansible-core~=2.20.0->ansible) (1.2.1)
Collecting ansible-compat>=25.8.2 (from ansible-lint)
  Downloading ansible_compat-25.11.0-py3-none-any.whl.metadata (3.4 kB)
Requirement already satisfied: black>=24.3.0 in c:\program files\python313\lib\site-packages (from ansible-lint) (25.11.0)
Requirement already satisfied: cffi>=1.17.1 in c:\program files\python313\lib\site-packages (from ansible-lint) (2.0.0)
Requirement already satisfied: distro>=1.9.0 in c:\program files\python313\lib\site-packages (from ansible-lint) (1.9.0)
Requirement already satisfied: filelock>=3.8.2 in c:\program files\python313\lib\site-packages (from ansible-lint) (3.19.1)
Requirement already satisfied: importlib-metadata>=8.7.0 in c:\program files\python313\lib\site-packages (from ansible-lint) (8.7.0)
Requirement already satisfied: jsonschema>=4.10.0 in c:\program files\python313\lib\site-packages (from ansible-lint) (4.25.1)
Requirement already satisfied: pathspec>=0.10.3 in c:\program files\python313\lib\site-packages (from ansible-lint) (0.12.1)
Requirement already satisfied: referencing>=0.36.2 in c:\program files\python313\lib\site-packages (from ansible-lint) (0.37.0)
Requirement already satisfied: ruamel-yaml>=0.18.11 in c:\program files\python313\lib\site-packages (from ansible-lint) (0.18.16)
Requirement already satisfied: ruamel-yaml-clib>=0.2.12 in c:\program files\python313\lib\site-packages (from ansible-lint) (0.2.15)
Collecting subprocess-tee>=0.4.1 (from ansible-lint)
  Downloading subprocess_tee-0.4.2-py3-none-any.whl.metadata (3.3 kB)
Collecting wcmatch>=8.5.0 (from ansible-lint)
  Downloading wcmatch-10.1-py3-none-any.whl.metadata (5.1 kB)
Collecting yamllint>=1.34.0 (from ansible-lint)
  Downloading yamllint-1.37.1-py3-none-any.whl.metadata (4.3 kB)
Requirement already satisfied: click>=8.0.0 in c:\program files\python313\lib\site-packages (from black>=24.3.0->ansible-lint) (8.3.1)
Requirement already satisfied: mypy-extensions>=0.4.3 in c:\program files\python313\lib\site-packages (from black>=24.3.0->ansible-lint) (1.1.0)
Requirement already satisfied: platformdirs>=2 in c:\program files\python313\lib\site-packages (from black>=24.3.0->ansible-lint) (4.5.0)
Requirement already satisfied: pytokens>=0.3.0 in c:\program files\python313\lib\site-packages (from black>=24.3.0->ansible-lint) (0.3.0)
Requirement already satisfied: pycparser in c:\program files\python313\lib\site-packages (from cffi>=1.17.1->ansible-lint) (2.23)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from click>=8.0.0->black>=24.3.0->ansible-lint) (0.4.6)
Requirement already satisfied: zipp>=3.20 in c:\program files\python313\lib\site-packages (from importlib-metadata>=8.7.0->ansible-lint) (3.23.0)
Requirement already satisfied: MarkupSafe>=2.0 in c:\program files\python313\lib\site-packages (from jinja2>=3.1.0->ansible-core~=2.20.0->ansible) (3.0.3)
Requirement already satisfied: attrs>=22.2.0 in c:\program files\python313\lib\site-packages (from jsonschema>=4.10.0->ansible-lint) (25.4.0)
Requirement already satisfied: jsonschema-specifications>=2023.03.6 in c:\program files\python313\lib\site-packages (from jsonschema>=4.10.0->ansible-lint) (2025.9.1)
Requirement already satisfied: rpds-py>=0.7.1 in c:\program files\python313\lib\site-packages (from jsonschema>=4.10.0->ansible-lint) (0.29.0)
Collecting bracex>=2.1.1 (from wcmatch>=8.5.0->ansible-lint)
  Downloading bracex-2.6-py3-none-any.whl.metadata (3.6 kB)
Downloading ansible_lint-25.11.1-py3-none-any.whl (322 kB)
Downloading ansible_compat-25.11.0-py3-none-any.whl (27 kB)
Downloading subprocess_tee-0.4.2-py3-none-any.whl (5.2 kB)
Downloading wcmatch-10.1-py3-none-any.whl (39 kB)
Downloading bracex-2.6-py3-none-any.whl (11 kB)
Downloading yamllint-1.37.1-py3-none-any.whl (68 kB)
Installing collected packages: yamllint, subprocess-tee, bracex, wcmatch, ansible-compat, ansible-lint
Successfully installed ansible-compat-25.11.0 ansible-lint-25.11.1 bracex-2.6 subprocess-tee-0.4.2 wcmatch-10.1 yamllint-1.37.1
Chocolatey v2.5.1
Installing the following packages:
jenkins;gitlab-runner
By installing, you accept licenses for the packages.
jenkins v2.528.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
gitlab-runner v18.6.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - gitlab-runner - gitlab-runner v18.6.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - jenkins - jenkins v2.528.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Chocolatey v2.5.1
Installing the following packages:
awscli;gcloudsdk
By installing, you accept licenses for the packages.
awscli v2.32.4 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
gcloudsdk v548.0.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - awscli - awscli v2.32.4 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - gcloudsdk - gcloudsdk v548.0.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
docker-compose
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading docker-cli 29.0.4... 100%

docker-cli v29.0.4 [Approved]
docker-cli package files install completed. Performing other installation steps.
 ShimGen has successfully created a shim for docker.exe
 The install of docker-cli was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\docker-cli'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading docker-compose 2.40.3... 100%

docker-compose v2.40.3 [Approved]
docker-compose package files install completed. Performing other installation steps.
 The install of docker-compose was successful.
  Software install location not explicitly set, it could be in package or
  default install location of installer.

Chocolatey installed 2/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
grafana;prometheus
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading grafana 11.5.10... 100%

grafana v11.5.10 [Approved]
grafana package files install completed. Performing other installation steps.
Extracting C:\ProgramData\chocolatey\lib\grafana\tools\grafana-11.5.10.windows-amd64.zip to C:\ProgramData\chocolatey\lib\grafana\tools...
C:\ProgramData\chocolatey\lib\grafana\tools
 ShimGen has successfully created a shim for grafana-cli.exe
 ShimGen has successfully created a shim for grafana-server.exe
 ShimGen has successfully created a shim for grafana.exe
 The install of grafana was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\grafana\tools'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading prometheus 2.2.1... 100%

prometheus v2.2.1 [Approved]
prometheus package files install completed. Performing other installation steps.
Downloading prometheus 64 bit
  from 'https://github.com/prometheus/prometheus/releases/download/v2.2.1/prometheus-2.2.1.windows-amd64.tar.gz'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\prometheus\2.2.1\prometheus-2.2.1.windows-amd64.tar.gz (25.07 MB).
Download of prometheus-2.2.1.windows-amd64.tar.gz (25.07 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\chocolatey\prometheus\2.2.1\prometheus-2.2.1.windows-amd64.tar.gz to C:\ProgramData\chocolatey\lib\prometheus\tools...
C:\ProgramData\chocolatey\lib\prometheus\tools
Extracting C:\ProgramData\chocolatey\lib\prometheus\tools\prometheus-2.2.1.windows-amd64.tar to C:\ProgramData\chocolatey\lib\prometheus\tools\...
C:\ProgramData\chocolatey\lib\prometheus\tools\
Installing service
WARNING: May not be able to find 'nssm'. Please use full path for executables.
0
WARNING: May not be able to find 'nssm'. Please use full path for executables.
0
 ShimGen has successfully created a shim for prometheus.exe
 ShimGen has successfully created a shim for promtool.exe
 The install of prometheus was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\prometheus\tools\'

Chocolatey installed 2/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
istioctl
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading istioctl 1.28.0... 100%

istioctl v1.28.0 [Approved]
istioctl package files install completed. Performing other installation steps.
Downloading istioctl
  from 'https://github.com/istio/istio/releases/download/1.28.0/istioctl-1.28.0-win.zip'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\istioctl\1.28.0\istioctl-1.28.0-win.zip (28.95 MB).
Download of istioctl-1.28.0-win.zip (28.95 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\chocolatey\istioctl\1.28.0\istioctl-1.28.0-win.zip to C:\ProgramData\chocolatey\lib\istioctl\tools...
C:\ProgramData\chocolatey\lib\istioctl\tools
 ShimGen has successfully created a shim for istioctl.exe
 The install of istioctl was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\istioctl\tools'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
argocd-cli
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading argocd-cli 3.2.0... 100%

argocd-cli v3.2.0 [Approved]
argocd-cli package files install completed. Performing other installation steps.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 ShimGen has successfully created a shim for argocd.exe
 The install of argocd-cli was successful.
  Software install location not explicitly set, it could be in package or
  default install location of installer.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

[12/20] Build Tools, Compilers, Toolchains
Chocolatey v2.5.1
Installing the following packages:
cmake;ninja;make
By installing, you accept licenses for the packages.
cmake v4.2.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
ninja v1.13.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
make v4.4.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - cmake - cmake v4.2.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - make - make v4.4.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - ninja - ninja v1.13.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Did you know the proceeds of Pro (and some proceeds from other
 licensed editions) go into bettering the community infrastructure?
 Your support ensures an active community, keeps Chocolatey tip-top,
 plus it nets you some awesome features!
 https://chocolatey.org/compare
Chocolatey v2.5.1
Installing the following packages:
mingw;llvm
By installing, you accept licenses for the packages.
mingw v15.2.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
llvm v21.1.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - llvm - llvm v21.1.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - mingw - mingw v15.2.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
msys2
By installing, you accept licenses for the packages.
msys2 v20250830.0.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - msys2 - msys2 v20250830.0.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
bazel
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading bazel 8.4.2... 100%

bazel v8.4.2 [Approved]
bazel package files install completed. Performing other installation steps.
Content of C:\ProgramData\chocolatey\lib\bazel\tools\params.txt:
https://github.com/bazelbuild/bazel/releases/download/8.4.2/bazel-8.4.2-windows-x86_64.zip
23f0d0a634650e5b9c6cece98dc375d346c42cea1ead83f2040e7a954633ade1

url:  https://github.com/bazelbuild/bazel/releases/download/8.4.2/bazel-8.4.2-windows-x86_64.zip
hash: 23f0d0a634650e5b9c6cece98dc375d346c42cea1ead83f2040e7a954633ade1
Downloading bazel 64 bit
  from 'https://github.com/bazelbuild/bazel/releases/download/8.4.2/bazel-8.4.2-windows-x86_64.zip'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\bazel\8.4.2\bazel-8.4.2-windows-x86_64.zip (51.44 MB).
Download of bazel-8.4.2-windows-x86_64.zip (51.44 MB) completed.
Hashes match.
Extracting C:\Users\shelc\AppData\Local\Temp\chocolatey\bazel\8.4.2\bazel-8.4.2-windows-x86_64.zip to C:\ProgramData\chocolatey\lib\bazel...
C:\ProgramData\chocolatey\lib\bazel
bazel installed to C:\ProgramData\chocolatey\lib\bazel

See also https://bazel.build/docs/windows.html
 ShimGen has successfully created a shim for bazel.exe
 The install of bazel was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\bazel'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Collecting meson
  Downloading meson-1.9.1-py3-none-any.whl.metadata (1.8 kB)
Downloading meson-1.9.1-py3-none-any.whl (1.0 MB)
   ---------------------------------------- 1.0/1.0 MB 14.1 MB/s  0:00:00
Installing collected packages: meson
Successfully installed meson-1.9.1
Collecting conan
  Downloading conan-2.23.0.tar.gz (549 kB)
     ---------------------------------------- 549.7/549.7 kB 6.8 MB/s  0:00:00
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Requirement already satisfied: requests<3.0.0,>=2.25 in c:\program files\python313\lib\site-packages (from conan) (2.32.4)
Requirement already satisfied: urllib3<3.0,>=1.26.6 in c:\program files\python313\lib\site-packages (from conan) (2.5.0)
Requirement already satisfied: colorama<0.5.0,>=0.4.3 in c:\program files\python313\lib\site-packages (from conan) (0.4.6)
Requirement already satisfied: PyYAML<7.0,>=6.0 in c:\program files\python313\lib\site-packages (from conan) (6.0.3)
Collecting patch-ng<1.19,>=1.18.0 (from conan)
  Downloading patch-ng-1.18.1.tar.gz (17 kB)
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Collecting fasteners>=0.15 (from conan)
  Downloading fasteners-0.20-py3-none-any.whl.metadata (4.8 kB)
Requirement already satisfied: Jinja2<4.0.0,>=3.0 in c:\program files\python313\lib\site-packages (from conan) (3.1.6)
Requirement already satisfied: python-dateutil<3,>=2.8.0 in c:\program files\python313\lib\site-packages (from conan) (2.9.0.post0)
Requirement already satisfied: MarkupSafe>=2.0 in c:\program files\python313\lib\site-packages (from Jinja2<4.0.0,>=3.0->conan) (3.0.3)
Requirement already satisfied: six>=1.5 in c:\program files\python313\lib\site-packages (from python-dateutil<3,>=2.8.0->conan) (1.17.0)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests<3.0.0,>=2.25->conan) (3.4.4)
Requirement already satisfied: idna<4,>=2.5 in c:\program files\python313\lib\site-packages (from requests<3.0.0,>=2.25->conan) (3.11)
Requirement already satisfied: certifi>=2017.4.17 in c:\program files\python313\lib\site-packages (from requests<3.0.0,>=2.25->conan) (2025.11.12)
Downloading fasteners-0.20-py3-none-any.whl (18 kB)
Building wheels for collected packages: conan, patch-ng
  Building wheel for conan (pyproject.toml) ... done
  Created wheel for conan: filename=conan-2.23.0-py3-none-any.whl size=689527 sha256=d63dfa12009358b478be20f619d95ff6a28e547124511422271c6222ecc591ec
  Stored in directory: c:\users\shelc\appdata\local\pip\cache\wheels\f5\f9\ef\42ea463af57455f707572b41a6e32df4b97989a3c927fac5d3
  Building wheel for patch-ng (pyproject.toml) ... done
  Created wheel for patch-ng: filename=patch_ng-1.18.1-py3-none-any.whl size=17028 sha256=ca6c3d27535e3d55dafcd2824769decc71a98b1fcd7872422d892b2d047a3f07
  Stored in directory: c:\users\shelc\appdata\local\pip\cache\wheels\43\44\12\fd3f7633c824273d14b9a7ddee20d0b59e354ef6f6b9fe8ce1
Successfully built conan patch-ng
Installing collected packages: patch-ng, fasteners, conan
Successfully installed conan-2.23.0 fasteners-0.20 patch-ng-1.18.1

[13/20] Security & Penetration Testing Tools
Chocolatey v2.5.1
Installing the following packages:
nmap;wireshark
By installing, you accept licenses for the packages.
nmap v7.98.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
wireshark v4.6.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - nmap - nmap v7.98.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - wireshark - wireshark v4.6.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
burp-suite-free-edition
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading burp-suite-free-edition 2022.12.4... 100%

burp-suite-free-edition v2022.12.4 [Approved]
burp-suite-free-edition package files install completed. Performing other installation steps.
Downloading burp-suite-free-edition 64 bit
  from 'https://portswigger-cdn.net/burp/releases/download?product=community&version=2022.12.4&type=WindowsX64'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\burp-suite-free-edition\2022.12.4\burp-suite-free-editionInstall.exe (241.53 MB).
Download of burp-suite-free-editionInstall.exe (241.53 MB) completed.
Hashes match.
Installing burp-suite-free-edition...
burp-suite-free-edition has been installed.
  burp-suite-free-edition may be able to be automatically uninstalled.
 The install of burp-suite-free-edition was successful.
  Deployed to 'C:\Program Files\BurpSuiteCommunity'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
zap
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading zap 2.16.1... 100%

zap v2.16.1 [Approved]
zap package files install completed. Performing other installation steps.
Java installed and JAVA_HOME set to 'C:\Program Files\Eclipse Adoptium\jre-17.0.17.10-hotspot\'
Java major version is: 17
Downloading zap 64 bit
  from 'https://github.com/zaproxy/zaproxy/releases/download/v2.16.1/ZAP_2_16_1_windows.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\zap\2.16.1\ZAP_2_16_1_windows.exe (234.02 MB).
Download of ZAP_2_16_1_windows.exe (234.02 MB) completed.
Hashes match.
Installing zap...
zap has been installed.
  zap may be able to be automatically uninstalled.
 The install of zap was successful.
  Deployed to 'C:\Program Files\ZAP\Zed Attack Proxy'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
metasploit
By installing, you accept licenses for the packages.
metasploit not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - metasploit - metasploit not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.
Chocolatey v2.5.1
Installing the following packages:
john;hashcat
By installing, you accept licenses for the packages.
john not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 0/0 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Value cannot be null or an empty string.
Parameter name: value
Collecting sqlmap
  Downloading sqlmap-1.9.11.tar.gz (7.2 MB)
     ---------------------------------------- 7.2/7.2 MB 30.4 MB/s  0:00:00
  Installing build dependencies ... done
  Getting requirements to build wheel ... done
  Preparing metadata (pyproject.toml) ... done
Building wheels for collected packages: sqlmap
  Building wheel for sqlmap (pyproject.toml) ... done
  Created wheel for sqlmap: filename=sqlmap-1.9.11-py3-none-any.whl size=7524226 sha256=ccfce3a5ce9e9511c354121c859b8dc26e0c16e51c078db48cd1965805ffa8b6
  Stored in directory: c:\users\shelc\appdata\local\pip\cache\wheels\ba\d5\21\077de987623f4a34698d4eda30d5ad7dd49e8e332033f92a72
Successfully built sqlmap
Installing collected packages: sqlmap
Successfully installed sqlmap-1.9.11
Chocolatey v2.5.1
Installing the following packages:
putty;winscp;filezilla
By installing, you accept licenses for the packages.
putty v0.83.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
winscp v6.5.5 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
filezilla v3.69.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - filezilla - filezilla v3.69.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - putty - putty v0.83.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - winscp - winscp v6.5.5 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
ngrok
By installing, you accept licenses for the packages.
ngrok v3.22.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - ngrok - ngrok v3.22.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
fiddler
By installing, you accept licenses for the packages.
fiddler v5.0.20253.3311 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - fiddler - fiddler v5.0.20253.3311 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
openvpn
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading openvpn 2.6.16.1... 100%

openvpn v2.6.16.1 [Approved]
openvpn package files install completed. Performing other installation steps.
Installing 64-bit openvpn...
openvpn has been installed.
  openvpn may be able to be automatically uninstalled.
 The install of openvpn was successful.
  Software installed as 'msi', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
keepassxc;bitwarden
By installing, you accept licenses for the packages.
keepassxc v2.7.10 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading bitwarden 2025.11.1... 100%

bitwarden v2025.11.1 [Approved]
bitwarden package files install completed. Performing other installation steps.
Downloading bitwarden
  from 'https://github.com/bitwarden/clients/releases/download/desktop-v2025.11.1/Bitwarden-Installer-2025.11.1.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\bitwarden\2025.11.1\Bitwarden-Installer-2025.11.1.exe (714.81 KB).
Download of Bitwarden-Installer-2025.11.1.exe (714.81 KB) completed.
Hashes match.
Installing bitwarden...
bitwarden has been installed.
  bitwarden can be automatically uninstalled.
 The install of bitwarden was successful.
  Software installed as 'EXE', install location is likely default.

Chocolatey installed 1/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - keepassxc - keepassxc v2.7.10 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

[14/20] Networking & Sysadmin Tools
Chocolatey v2.5.1
Installing the following packages:
curl;wget;netcat
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading curl 8.17.0... 100%

curl v8.17.0 [Approved]
curl package files install completed. Performing other installation steps.
Extracting 64-bit C:\ProgramData\chocolatey\lib\curl\tools\curl-8.17.0_1-win64-mingw.zip to C:\ProgramData\chocolatey\lib\curl\tools...
C:\ProgramData\chocolatey\lib\curl\tools
 ShimGen has successfully created a shim for curl.exe
 ShimGen has successfully created a shim for trurl.exe
 The install of curl was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\curl\tools'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading Wget 1.21.4... 100%

Wget v1.21.4 [Approved]
Wget package files install completed. Performing other installation steps.
Getting x64 bit zip
Extracting C:\ProgramData\chocolatey\lib\Wget\tools\wget-1.21.4-win64_x64.zip to C:\ProgramData\chocolatey\lib\Wget\tools...
C:\ProgramData\chocolatey\lib\Wget\tools
 ShimGen has successfully created a shim for wget.exe
 The install of Wget was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\Wget\tools'
netcat not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 2/3 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - netcat - netcat not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.
No package found matching input criteria.
Couldn't find manifest for 'whois'.
Chocolatey v2.5.1
Installing the following packages:
advanced-port-scanner
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading advanced-port-scanner 2.5.3869... 100%

advanced-port-scanner v2.5.3869 [Approved]
advanced-port-scanner package files install completed. Performing other installation steps.
Downloading advanced-port-scanner
  from 'https://download.advanced-port-scanner.com/download/files/Advanced_Port_Scanner_2.5.3869.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\advanced-port-scanner\2.5.3869\Advanced_Port_Scanner_2.5.3869.exe (19.44 MB).
Download of Advanced_Port_Scanner_2.5.3869.exe (19.44 MB) completed.
Hashes match.
Installing advanced-port-scanner...
advanced-port-scanner has been installed.
Killing APS process
  advanced-port-scanner may be able to be automatically uninstalled.
 The install of advanced-port-scanner was successful.
  Deployed to 'C:\Program Files (x86)\Advanced Port Scanner\'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
angry-ip-scanner
By installing, you accept licenses for the packages.
angry-ip-scanner not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - angry-ip-scanner - angry-ip-scanner not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.
Chocolatey v2.5.1
Installing the following packages:
anydesk;teamviewer
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading anydesk.portable 9.6.5... 100%

anydesk.portable v9.6.5 [Approved]
anydesk.portable package files install completed. Performing other installation steps.
Downloading anydesk.portable
  from 'https://download.anydesk.com/AnyDesk.exe'
Progress: 100% - Completed download of C:\ProgramData\chocolatey\lib\anydesk.portable\tools\AnyDesk.exe (7.57 MB).
Download of AnyDesk.exe (7.57 MB) completed.
Hashes match.
C:\ProgramData\chocolatey\lib\anydesk.portable\tools\AnyDesk.exe
 ShimGen has successfully created a shim for AnyDesk.exe
 The install of anydesk.portable was successful.
  Software install location not explicitly set, it could be in package or
  default install location of installer.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading anydesk 9.6.4... 100%

anydesk v9.6.4 [Approved]
anydesk package files install completed. Performing other installation steps.
 The install of anydesk was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\anydesk'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading teamviewer 15.71.4... 100%

teamviewer v15.71.4 [Approved]
teamviewer package files install completed. Performing other installation steps.
Downloading teamviewer 64 bit
  from 'https://download.teamviewer.com/download/version_15x/TeamViewer_Setup_x64.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\teamviewer\15.71.4\TeamViewer_Setup_x64.exe (104.66 MB).
Download of TeamViewer_Setup_x64.exe (104.66 MB) completed.
Error - hashes do not match. Actual value was '68C763D1BF14C4E36045B0215DBE79155300CFED22D474E891155CA7DB476F82'.
ERROR: Checksum for 'C:\Users\shelc\AppData\Local\Temp\chocolatey\teamviewer\15.71.4\TeamViewer_Setup_x64.exe' did not meet '9882842974ce85027588b881aa9fb043bd3bdd6961262f518c4ad425ae82e708' for checksum type 'sha256'. Consider passing the actual checksums through with --checksum --checksum64 once you validate the checksums are appropriate. A less secure option is to pass --ignore-checksums if necessary.
The install of teamviewer was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\teamviewer\tools\chocolateyInstall.ps1'.
 See log for details.

Chocolatey installed 2/3 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - teamviewer (exited -1) - Error while running 'C:\ProgramData\chocolatey\lib\teamviewer\tools\chocolateyInstall.ps1'.
 See log for details.

[15/20] Documentation & Productivity Tools
Chocolatey v2.5.1
Installing the following packages:
obsidian;notion;joplin
By installing, you accept licenses for the packages.
obsidian v1.10.3 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading notion 4.24.0... 100%

notion v4.24.0 [Approved]
notion package files install completed. Performing other installation steps.
Downloading notion
  from 'https://www.notion.so/desktop/windows/download'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\notion\4.24.0\Notion Setup 4.24.0.exe (84.75 MB).
Download of Notion Setup 4.24.0.exe (84.75 MB) completed.
Hashes match.
Installing notion...
notion has been installed.
notion installed to 'C:\Users\shelc\AppData\Local\Programs\Notion'
  notion can be automatically uninstalled.
 The install of notion was successful.
  Software installed as 'exe', install location is likely default.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading joplin 3.4.12... 100%

joplin v3.4.12 [Approved]
joplin package files install completed. Performing other installation steps.
Downloading joplin 64 bit
  from 'https://github.com/laurent22/joplin/releases/download/v3.4.12/Joplin-Setup-3.4.12.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\joplin\3.4.12\Joplin-Setup-3.4.12.exe (219.43 MB).
Download of Joplin-Setup-3.4.12.exe (219.43 MB) completed.
Hashes match.
Installing joplin...
joplin has been installed.
  joplin can be automatically uninstalled.
 The install of joplin was successful.
  Software installed as 'exe', install location is likely default.

Chocolatey installed 2/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - obsidian - obsidian v1.10.3 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Enjoy using Chocolatey? Explore more amazing features to take your
experience to the next level at
 https://chocolatey.org/compare
Chocolatey v2.5.1
Installing the following packages:
typora;zettlr
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading typora 1.12.4... 100%

typora v1.12.4 [Approved]
typora package files install completed. Performing other installation steps.
Downloading typora 64 bit
  from 'https://downloads.typora.io/windows/typora-setup-x64-1.12.4.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\typora\1.12.4\typora-setup-x64-1.12.4.exe (93.9 MB).
Download of typora-setup-x64-1.12.4.exe (93.9 MB) completed.
Hashes match.
Installing typora...
typora has been installed.
  typora can be automatically uninstalled.
 The install of typora was successful.
  Deployed to 'C:\Program Files\Typora\'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading zettlr 3.6.0... 100%

zettlr v3.6.0 [Approved]
zettlr package files install completed. Performing other installation steps.
Installing zettlr...
zettlr has been installed.
  zettlr can be automatically uninstalled.
 The install of zettlr was successful.
  Software installed as 'exe', install location is likely default.

Chocolatey installed 2/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
pandoc
By installing, you accept licenses for the packages.
pandoc v3.8.2.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - pandoc - pandoc v3.8.2.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Enjoy using Chocolatey? Explore more amazing features to take your
experience to the next level at
 https://chocolatey.org/compare
Chocolatey v2.5.1
Installing the following packages:
miktex
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading miktex.install 25.3.0... 100%

miktex.install v25.3.0 [Approved]
miktex.install package files install completed. Performing other installation steps.
Extracting 64-bit C:\ProgramData\chocolatey\lib\miktex.install\tools\miktexsetup-5.5.0+1763023-x64.zip to C:\ProgramData\chocolatey\lib\miktex.install\tools...
Downloading a "Basic" package set to install.
WARNING: No registry key found based on  'miktex*'
Creating a temporary repository at 'C:\Users\shelc\AppData\Local\Temp\chocolatey\MiKTeX-repository'.
Installing from temporary MiKTeX repository for all users.
MiKTeX milestone 25.4 installed
  miktex.install may be able to be automatically uninstalled.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of miktex.install was successful.
  Deployed to 'C:\Program Files\MiKTeX'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading miktex 25.3.0... 100%

miktex v25.3.0 [Approved]
miktex package files install completed. Performing other installation steps.
 The install of miktex was successful.
  Software install location not explicitly set, it could be in package or
  default install location of installer.

Chocolatey installed 2/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
drawio
By installing, you accept licenses for the packages.
drawio v29.0.3.20251123 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - drawio - drawio v29.0.3.20251123 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
graphviz
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading Graphviz 14.0.4... 100%

graphviz v14.0.4 [Approved]
graphviz package files install completed. Performing other installation steps.
Attempt to use original download file name failed for 'C:\ProgramData\chocolatey\lib\Graphviz\tools\graphviz-14.0.4 (64-bit) EXE installer.exe'.
Copying graphviz
  from 'C:\ProgramData\chocolatey\lib\Graphviz\tools\graphviz-14.0.4 (64-bit) EXE installer.exe'
Installing graphviz...
graphviz has been installed.
graphviz installed to 'C:\Program Files\Graphviz'
Added C:\ProgramData\chocolatey\bin\acyclic.exe shim pointed to 'c:\program files\graphviz\bin\acyclic.exe'.
Added C:\ProgramData\chocolatey\bin\bcomps.exe shim pointed to 'c:\program files\graphviz\bin\bcomps.exe'.
Added C:\ProgramData\chocolatey\bin\ccomps.exe shim pointed to 'c:\program files\graphviz\bin\ccomps.exe'.
Added C:\ProgramData\chocolatey\bin\circo.exe shim pointed to 'c:\program files\graphviz\bin\circo.exe'.
Added C:\ProgramData\chocolatey\bin\cluster.exe shim pointed to 'c:\program files\graphviz\bin\cluster.exe'.
Added C:\ProgramData\chocolatey\bin\diffimg.exe shim pointed to 'c:\program files\graphviz\bin\diffimg.exe'.
Added C:\ProgramData\chocolatey\bin\dijkstra.exe shim pointed to 'c:\program files\graphviz\bin\dijkstra.exe'.
Added C:\ProgramData\chocolatey\bin\dot.exe shim pointed to 'c:\program files\graphviz\bin\dot.exe'.
Added C:\ProgramData\chocolatey\bin\dot2gxl.exe shim pointed to 'c:\program files\graphviz\bin\dot2gxl.exe'.
Added C:\ProgramData\chocolatey\bin\dot_builtins.exe shim pointed to 'c:\program files\graphviz\bin\dot_builtins.exe'.
Added C:\ProgramData\chocolatey\bin\edgepaint.exe shim pointed to 'c:\program files\graphviz\bin\edgepaint.exe'.
Added C:\ProgramData\chocolatey\bin\fdp.exe shim pointed to 'c:\program files\graphviz\bin\fdp.exe'.
Added C:\ProgramData\chocolatey\bin\gc.exe shim pointed to 'c:\program files\graphviz\bin\gc.exe'.
Added C:\ProgramData\chocolatey\bin\gml2gv.exe shim pointed to 'c:\program files\graphviz\bin\gml2gv.exe'.
Added C:\ProgramData\chocolatey\bin\graphml2gv.exe shim pointed to 'c:\program files\graphviz\bin\graphml2gv.exe'.
Added C:\ProgramData\chocolatey\bin\gv2gml.exe shim pointed to 'c:\program files\graphviz\bin\gv2gml.exe'.
Added C:\ProgramData\chocolatey\bin\gv2gxl.exe shim pointed to 'c:\program files\graphviz\bin\gv2gxl.exe'.
Added C:\ProgramData\chocolatey\bin\gvcolor.exe shim pointed to 'c:\program files\graphviz\bin\gvcolor.exe'.
Added C:\ProgramData\chocolatey\bin\gvgen.exe shim pointed to 'c:\program files\graphviz\bin\gvgen.exe'.
Added C:\ProgramData\chocolatey\bin\gvmap.exe shim pointed to 'c:\program files\graphviz\bin\gvmap.exe'.
Added C:\ProgramData\chocolatey\bin\gvpack.exe shim pointed to 'c:\program files\graphviz\bin\gvpack.exe'.
Added C:\ProgramData\chocolatey\bin\gvpr.exe shim pointed to 'c:\program files\graphviz\bin\gvpr.exe'.
Added C:\ProgramData\chocolatey\bin\gxl2dot.exe shim pointed to 'c:\program files\graphviz\bin\gxl2dot.exe'.
Added C:\ProgramData\chocolatey\bin\gxl2gv.exe shim pointed to 'c:\program files\graphviz\bin\gxl2gv.exe'.
Added C:\ProgramData\chocolatey\bin\mingle.exe shim pointed to 'c:\program files\graphviz\bin\mingle.exe'.
Added C:\ProgramData\chocolatey\bin\mm2gv.exe shim pointed to 'c:\program files\graphviz\bin\mm2gv.exe'.
Added C:\ProgramData\chocolatey\bin\neato.exe shim pointed to 'c:\program files\graphviz\bin\neato.exe'.
Added C:\ProgramData\chocolatey\bin\nop.exe shim pointed to 'c:\program files\graphviz\bin\nop.exe'.
Added C:\ProgramData\chocolatey\bin\osage.exe shim pointed to 'c:\program files\graphviz\bin\osage.exe'.
Added C:\ProgramData\chocolatey\bin\patchwork.exe shim pointed to 'c:\program files\graphviz\bin\patchwork.exe'.
Added C:\ProgramData\chocolatey\bin\prune.exe shim pointed to 'c:\program files\graphviz\bin\prune.exe'.
Added C:\ProgramData\chocolatey\bin\sccmap.exe shim pointed to 'c:\program files\graphviz\bin\sccmap.exe'.
Added C:\ProgramData\chocolatey\bin\sfdp.exe shim pointed to 'c:\program files\graphviz\bin\sfdp.exe'.
Added C:\ProgramData\chocolatey\bin\tred.exe shim pointed to 'c:\program files\graphviz\bin\tred.exe'.
Added C:\ProgramData\chocolatey\bin\twopi.exe shim pointed to 'c:\program files\graphviz\bin\twopi.exe'.
Added C:\ProgramData\chocolatey\bin\unflatten.exe shim pointed to 'c:\program files\graphviz\bin\unflatten.exe'.
  graphviz may be able to be automatically uninstalled.
 The install of graphviz was successful.
  Software installed as 'exe', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
npm warn deprecated puppeteer@23.11.1: < 24.15.0 is no longer supported

added 372 packages in 33s

45 packages are looking for funding
  run `npm fund` for details
Chocolatey v2.5.1
Installing the following packages:
trello
By installing, you accept licenses for the packages.
trello not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - trello - trello not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

[16/20] Specialized Development Tools
Chocolatey v2.5.1
Installing the following packages:
androidstudio
By installing, you accept licenses for the packages.
androidstudio v2025.2.1.8 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - androidstudio - androidstudio v2025.2.1.8 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
flutter
By installing, you accept licenses for the packages.
flutter v3.35.3 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - flutter - flutter v3.35.3 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
unity
By installing, you accept licenses for the packages.
unity v6000.2.13 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - unity - unity v6000.2.13 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
godot
By installing, you accept licenses for the packages.
godot v4.5.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - godot - godot v4.5.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
unrealengine
By installing, you accept licenses for the packages.
unrealengine not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - unrealengine - unrealengine not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.
Chocolatey v2.5.1
Installing the following packages:
arduino
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading arduino 2.3.6... 100%

arduino v2.3.6 [Approved]
arduino package files install completed. Performing other installation steps.
Downloading arduino
  from 'https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.6_Windows_64bit.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\arduino\2.3.6\arduino-ide_2.3.6_Windows_64bit.exe (150.2 MB).
Download of arduino-ide_2.3.6_Windows_64bit.exe (150.2 MB) completed.
Hashes match.
Installing arduino...
arduino has been installed.
  arduino can be automatically uninstalled.
 The install of arduino was successful.
  Software installed as 'EXE', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Collecting platformio
  Downloading platformio-6.1.18-py3-none-any.whl.metadata (7.1 kB)
Collecting bottle==0.13.* (from platformio)
  Downloading bottle-0.13.4-py2.py3-none-any.whl.metadata (1.6 kB)
Collecting click<8.1.8,>=8.0.4 (from platformio)
  Downloading click-8.1.7-py3-none-any.whl.metadata (3.0 kB)
Requirement already satisfied: colorama in c:\program files\python313\lib\site-packages (from platformio) (0.4.6)
Requirement already satisfied: marshmallow==3.* in c:\program files\python313\lib\site-packages (from platformio) (3.26.1)
Collecting pyelftools<1,>=0.27 (from platformio)
  Downloading pyelftools-0.32-py3-none-any.whl.metadata (372 bytes)
Collecting pyserial==3.5.* (from platformio)
  Downloading pyserial-3.5-py2.py3-none-any.whl.metadata (1.6 kB)
Requirement already satisfied: requests==2.* in c:\program files\python313\lib\site-packages (from platformio) (2.32.4)
Collecting semantic_version==2.10.* (from platformio)
  Downloading semantic_version-2.10.0-py2.py3-none-any.whl.metadata (9.7 kB)
Requirement already satisfied: tabulate==0.* in c:\program files\python313\lib\site-packages (from platformio) (0.9.0)
Collecting ajsonrpc==1.2.* (from platformio)
  Downloading ajsonrpc-1.2.0-py3-none-any.whl.metadata (6.9 kB)
Collecting starlette<0.47,>=0.19 (from platformio)
  Downloading starlette-0.46.2-py3-none-any.whl.metadata (6.2 kB)
Collecting uvicorn<0.35,>=0.16 (from platformio)
  Downloading uvicorn-0.34.3-py3-none-any.whl.metadata (6.5 kB)
Requirement already satisfied: wsproto==1.* in c:\program files\python313\lib\site-packages (from platformio) (1.3.2)
Requirement already satisfied: packaging>=17.0 in c:\program files\python313\lib\site-packages (from marshmallow==3.*->platformio) (25.0)
Requirement already satisfied: charset_normalizer<4,>=2 in c:\program files\python313\lib\site-packages (from requests==2.*->platformio) (3.4.4)
Requirement already satisfied: idna<4,>=2.5 in c:\program files\python313\lib\site-packages (from requests==2.*->platformio) (3.11)
Requirement already satisfied: urllib3<3,>=1.21.1 in c:\program files\python313\lib\site-packages (from requests==2.*->platformio) (2.5.0)
Requirement already satisfied: certifi>=2017.4.17 in c:\program files\python313\lib\site-packages (from requests==2.*->platformio) (2025.11.12)
Requirement already satisfied: anyio<5,>=3.6.2 in c:\program files\python313\lib\site-packages (from starlette<0.47,>=0.19->platformio) (4.11.0)
Requirement already satisfied: sniffio>=1.1 in c:\program files\python313\lib\site-packages (from anyio<5,>=3.6.2->starlette<0.47,>=0.19->platformio) (1.3.1)
Requirement already satisfied: h11>=0.8 in c:\program files\python313\lib\site-packages (from uvicorn<0.35,>=0.16->platformio) (0.16.0)
Downloading platformio-6.1.18-py3-none-any.whl (420 kB)
Downloading ajsonrpc-1.2.0-py3-none-any.whl (22 kB)
Downloading bottle-0.13.4-py2.py3-none-any.whl (103 kB)
Downloading click-8.1.7-py3-none-any.whl (97 kB)
Downloading pyelftools-0.32-py3-none-any.whl (188 kB)
Downloading pyserial-3.5-py2.py3-none-any.whl (90 kB)
Downloading semantic_version-2.10.0-py2.py3-none-any.whl (15 kB)
Downloading starlette-0.46.2-py3-none-any.whl (72 kB)
Downloading uvicorn-0.34.3-py3-none-any.whl (62 kB)
Installing collected packages: pyserial, pyelftools, bottle, semantic_version, click, ajsonrpc, uvicorn, starlette, platformio
  Attempting uninstall: click
    Found existing installation: click 8.3.1
    Uninstalling click-8.3.1:
      Successfully uninstalled click-8.3.1
  Attempting uninstall: uvicorn
    Found existing installation: uvicorn 0.38.0
    Uninstalling uvicorn-0.38.0:
      Successfully uninstalled uvicorn-0.38.0
  Attempting uninstall: starlette
    Found existing installation: starlette 0.48.0
    Uninstalling starlette-0.48.0:
      Successfully uninstalled starlette-0.48.0
ERROR: pip's dependency resolver does not currently take into account all the packages that are installed. This behaviour is the source of the following dependency conflicts.
apache-airflow-core 3.1.3 requires uvicorn>=0.37.0, but you have uvicorn 0.34.3 which is incompatible.
litecli 1.17.0 requires click!=8.1.*,>=4.1, but you have click 8.1.7 which is incompatible.
mycli 1.41.2 requires click>=8.3.1, but you have click 8.1.7 which is incompatible.
sqlite-utils 3.39 requires click>=8.3.1, but you have click 8.1.7 which is incompatible.
Successfully installed ajsonrpc-1.2.0 bottle-0.13.4 click-8.1.7 platformio-6.1.18 pyelftools-0.32 pyserial-3.5 semantic_version-2.10.0 starlette-0.46.2 uvicorn-0.34.3
Chocolatey v2.5.1
Installing the following packages:
blender
By installing, you accept licenses for the packages.
blender v5.0.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - blender - blender v5.0.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

[17/20] Media Processing & Graphics
Chocolatey v2.5.1
Installing the following packages:
gimp;inkscape
By installing, you accept licenses for the packages.
gimp v3.0.6.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
InkScape v1.4.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - gimp - gimp v3.0.6.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - InkScape - InkScape v1.4.2 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
vlc;audacity
By installing, you accept licenses for the packages.
vlc v3.0.21 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
audacity v3.7.5 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - audacity - audacity v3.7.5 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - vlc - vlc v3.0.21 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
ffmpeg;imagemagick
By installing, you accept licenses for the packages.
ffmpeg v8.0.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading imagemagick.app 7.1.2.800... 100%

imagemagick.app v7.1.2.800 [Approved]
imagemagick.app package files install completed. Performing other installation steps.
WARNING: No registry key found based on  'ImageMagick*'
Installing 64-bit imagemagick.app...
imagemagick.app has been installed.
  imagemagick.app can be automatically uninstalled.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of imagemagick.app was successful.
  Deployed to 'C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading imagemagick 7.1.2.800... 100%

imagemagick v7.1.2.800 [Approved]
imagemagick package files install completed. Performing other installation steps.
 The install of imagemagick was successful.
  Software install location not explicitly set, it could be in package or
  default install location of installer.

Chocolatey installed 2/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - ffmpeg - ffmpeg v8.0.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
obs-studio
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading vcredist2017 14.16.27052... 100%

vcredist2017 v14.16.27052 [Approved]
vcredist2017 package files install completed. Performing other installation steps.
 The install of vcredist2017 was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\vcredist2017'
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading obs-studio.install 32.0.2... 100%

obs-studio.install v32.0.2 [Approved]
obs-studio.install package files install completed. Performing other installation steps.
ERROR: The running command stopped because the preference variable "ErrorActionPreference" or common parameter is set to Stop: Please close Microsoft Teams before installing/updating OBS Studio.
The install of obs-studio.install was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\obs-studio.install\tools\chocolateyinstall.ps1'.
 See log for details.
Failed to install obs-studio because a previous dependency failed.

Chocolatey installed 1/3 packages. 2 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - obs-studio - Failed to install obs-studio because a previous dependency failed.
 - obs-studio.install (exited -1) - Error while running 'C:\ProgramData\chocolatey\lib\obs-studio.install\tools\chocolateyinstall.ps1'.
 See log for details.
Chocolatey v2.5.1
Installing the following packages:
handbrake
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading dotnet-8.0-desktopruntime 8.0.22... 100%

dotnet-8.0-desktopruntime v8.0.22 [Approved]
dotnet-8.0-desktopruntime package files install completed. Performing other installation steps.
Downloading dotnet-8.0-desktopruntime 64 bit
  from 'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.22/windowsdesktop-runtime-8.0.22-win-x64.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\dotnet-8.0-desktopruntime\8.0.22\windowsdesktop-runtime-8.0.22-win-x64.exe (55.79 MB).
Download of windowsdesktop-runtime-8.0.22-win-x64.exe (55.79 MB) completed.
Hashes match.
Installing dotnet-8.0-desktopruntime...
dotnet-8.0-desktopruntime has been installed.
Downloading dotnet-8.0-desktopruntime
  from 'https://builds.dotnet.microsoft.com/dotnet/WindowsDesktop/8.0.22/windowsdesktop-runtime-8.0.22-win-x86.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\dotnet-8.0-desktopruntime\8.0.22\windowsdesktop-runtime-8.0.22-win-x86.exe (51.21 MB).
Download of windowsdesktop-runtime-8.0.22-win-x86.exe (51.21 MB) completed.
Hashes match.
Installing dotnet-8.0-desktopruntime...
dotnet-8.0-desktopruntime has been installed.
  dotnet-8.0-desktopruntime can be automatically uninstalled.
 The install of dotnet-8.0-desktopruntime was successful.
  Software installed as 'exe', install location is likely default.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading handbrake.install 1.10.2... 100%

handbrake.install v1.10.2 [Approved]
handbrake.install package files install completed. Performing other installation steps.
WARNING: No registry key found based on  'HandBrake*'
Installing handbrake.install...
handbrake.install has been installed.
  handbrake.install may be able to be automatically uninstalled.
 The install of handbrake.install was successful.
  Software installed as 'exe', install location is likely default.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading handbrake 1.10.2... 100%

handbrake v1.10.2 [Approved]
handbrake package files install completed. Performing other installation steps.
 The install of handbrake was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\handbrake'

Chocolatey installed 3/3 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

[18/20] Developer Utilities & Productivity
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Chocolatey v2.5.1
Installing the following packages:
7zip;everything
By installing, you accept licenses for the packages.
7zip v25.1.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Everything v1.4.11030 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.

Chocolatey installed 0/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - 7zip - 7zip v25.1.0 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
 - Everything - Everything v1.4.11030 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
sharex;greenshot
By installing, you accept licenses for the packages.
sharex v18.0.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading greenshot 1.3.301... 100%

greenshot v1.3.301 [Approved]
greenshot package files install completed. Performing other installation steps.
Downloading greenshot
  from 'https://github.com/greenshot/greenshot/releases/download/v1.3.301/Greenshot-INSTALLER-1.3.301-RELEASE.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\greenshot\1.3.301\Greenshot-INSTALLER-1.3.301-RELEASE.exe (3.78 MB).
Download of Greenshot-INSTALLER-1.3.301-RELEASE.exe (3.78 MB) completed.
Hashes match.
Installing greenshot...
greenshot has been installed.
  greenshot can be automatically uninstalled.
 The install of greenshot was successful.
  Deployed to 'C:\Users\shelc\AppData\Local\Programs\Greenshot\'

Chocolatey installed 1/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Warnings:
 - sharex - sharex v18.0.1 already installed.
 Use --force to reinstall, specify a version to install, or try upgrade.
Chocolatey v2.5.1
Installing the following packages:
beyondcompare
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading beyondcompare 5.1.6.31527... 100%

beyondcompare v5.1.6.31527 [Approved]
beyondcompare package files install completed. Performing other installation steps.
Downloading beyondcompare
  from 'https://www.scootersoftware.com/files/BCompare-5.1.6.31527.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\beyondcompare\5.1.6.31527\BCompare-5.1.6.31527.exe (26.44 MB).
Download of BCompare-5.1.6.31527.exe (26.44 MB) completed.
Hashes match.
Installing beyondcompare...
beyondcompare has been installed.
  beyondcompare can be automatically uninstalled.
 The install of beyondcompare was successful.
  Deployed to 'C:\Program Files\Beyond Compare 5\'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Installing 'fd' (10.3.0) [64bit] from 'main' bucket
fd-v10.3.0-x86_64-pc-windows-msvc.zip (1.4 MB) [===================================================================================================] 100%
Checking hash of fd-v10.3.0-x86_64-pc-windows-msvc.zip ... ok.
Extracting fd-v10.3.0-x86_64-pc-windows-msvc.zip ... done.
Linking ~\scoop\apps\fd\current => ~\scoop\apps\fd\10.3.0
Creating shim for 'fd'.
'fd' (10.3.0) was installed successfully!
Couldn't find manifest for 'git-delta'.
Installing 'lazydocker' (0.24.2) [64bit] from 'main' bucket
lazydocker_0.24.2_Windows_x86_64.zip (4.6 MB) [====================================================================================================] 100%
Checking hash of lazydocker_0.24.2_Windows_x86_64.zip ... ok.
Extracting lazydocker_0.24.2_Windows_x86_64.zip ... done.
Linking ~\scoop\apps\lazydocker\current => ~\scoop\apps\lazydocker\0.24.2
Creating shim for 'lazydocker'.
'lazydocker' (0.24.2) was installed successfully!
Chocolatey v2.5.1
Installing the following packages:
go-task
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading go-task 3.44.1... 100%

go-task v3.44.1 [Approved]
go-task package files install completed. Performing other installation steps.
 ShimGen has successfully created a shim for task.exe
 The install of go-task was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\go-task'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
syncthing
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading syncthing 2.0.11... 100%

syncthing v2.0.11 [Approved]
syncthing package files install completed. Performing other installation steps.
Extracting 64-bit C:\ProgramData\chocolatey\lib\syncthing\tools\syncthing-windows-amd64-v2.0.11.zip to C:\ProgramData\chocolatey\lib\syncthing\tools...
C:\ProgramData\chocolatey\lib\syncthing\tools
 ShimGen has successfully created a shim for syncthing.exe
 The install of syncthing was successful.
  Deployed to 'C:\ProgramData\chocolatey\lib\syncthing\tools'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
ditto
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading ditto 3.25.113... 100%

ditto v3.25.113 [Approved]
ditto package files install completed. Performing other installation steps.
Installing ditto...
ditto has been installed.
  ditto can be automatically uninstalled.
 The install of ditto was successful.
  Deployed to 'C:\Program Files\Ditto\'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

[19/20] Collaboration Tools
Found Slack [SlackTechnologies.Slack] Version 4.47.65
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Downloading https://downloads.slack-edge.com/desktop-releases/windows/x64/4.47.65/SlackSetup.exe
  ██████████████████████████████   138 MB /  138 MB
Successfully verified installer hash
Starting package install...
Successfully installed
Found an existing package already installed. Trying to upgrade the installed package...
No available upgrade found.
No newer package versions are available from the configured sources.
Found Discord [Discord.Discord] Version 1.0.9216
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Downloading https://stable.dl2.discordapp.net/distro/app/stable/win/x64/1.0.9216/DiscordSetup.exe
  ██████████████████████████████   117 MB /  117 MB
Successfully verified installer hash
Starting package install...
Successfully installed
Found Zoom Workplace [Zoom.Zoom] Version 6.6.22255
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Downloading https://zoom.us/client/6.6.10.22255/ZoomInstallerFull.msi?archType=x64
  ██████████████████████████████   155 MB /  155 MB
Successfully verified installer hash
Starting package install...
Successfully installed
Chocolatey v2.5.1
Installing the following packages:
microsoft-teams
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading netfx-4.7.2 4.7.2.0... 100%

netfx-4.7.2 v4.7.2 [Approved]
netfx-4.7.2 package files install completed. Performing other installation steps.
Microsoft .NET Framework 4.7.2 or later is already installed.
 The install of netfx-4.7.2 was successful.
  Software install location not explicitly set, it could be in package or
  default install location of installer.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading microsoft-teams 1.8.0.27654... 100%

microsoft-teams v1.8.0.27654 [Approved]
microsoft-teams package files install completed. Performing other installation steps.
Downloading microsoft-teams 64 bit
  from 'https://statics.teams.cdn.office.net/production-windows-x64/1.8.00.27654/Teams_windows_x64.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\microsoft-teams\1.8.0.27654\Teams_windows_x64.exe (157.29 MB).
Download of Teams_windows_x64.exe (157.29 MB) completed.
Hashes match.
Installing microsoft-teams...
microsoft-teams has been installed.
 The install of microsoft-teams was successful.
  Software installed as 'EXE', install location is likely default.

Chocolatey installed 2/2 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Found Loom [Loom.Loom] Version 0.324.0
This application is licensed to you by its owner.
Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Downloading https://cdn.loom.com/desktop-packages/Loom%20Setup%200.324.0.exe
  ██████████████████████████████   219 MB /  219 MB
Successfully verified installer hash
Starting package install...
Installer failed with exit code: 3221225477

[20/20] Additional Languages & Tools
Chocolatey v2.5.1
Installing the following packages:
leiningen
By installing, you accept licenses for the packages.
leiningen not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - leiningen - leiningen not installed. The package was not found with the source(s) listed.
 Source(s): 'https://community.chocolatey.org/api/v2/'
 NOTE: When you specify explicit sources, it overrides default sources.
If the package version is a prerelease and you didn't specify `--pre`,
 the package may not be found.
Please see https://docs.chocolatey.org/en-us/troubleshooting for more
 assistance.
Installing 'crystal' (1.18.2) [64bit] from 'main' bucket
crystal-1.18.2-windows-x86_64-msvc-unsupported.zip (50.1 MB) [=====================================================================================] 100%
Checking hash of crystal-1.18.2-windows-x86_64-msvc-unsupported.zip ... ok.
Extracting crystal-1.18.2-windows-x86_64-msvc-unsupported.zip ... done.
Linking ~\scoop\apps\crystal\current => ~\scoop\apps\crystal\1.18.2
Creating shim for 'crystal'.
Creating shim for 'shards'.
Creating shortcut for Crystal (crystal.exe)
'crystal' (1.18.2) was installed successfully!
Chocolatey v2.5.1
Installing the following packages:
nim
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading nim 2.2.6... 100%

nim v2.2.6 [Approved]
nim package files install completed. Performing other installation steps.
Extracting 64-bit C:\ProgramData\chocolatey\lib\nim\tools\nim-2.2.6_x64.zip to C:\tools\Nim...
C:\tools\Nim
PATH environment variable does not have C:\tools\Nim\nim-2.2.6\bin in it. Adding...
PATH environment variable does not have C:\Users\shelc\.nimble\bin in it. Adding...
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of nim was successful.
  Deployed to 'C:\tools\Nim'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Installing 'zig' (0.15.2) [64bit] from 'main' bucket
zig-x86_64-windows-0.15.2.zip (88.3 MB) [==========================================================================================================] 100%
Checking hash of zig-x86_64-windows-0.15.2.zip ... ok.
Extracting zig-x86_64-windows-0.15.2.zip ... done.
Linking ~\scoop\apps\zig\current => ~\scoop\apps\zig\0.15.2
Creating shim for 'zig'.
'zig' (0.15.2) was installed successfully!
'zig' suggests installing 'extras/vcredist2022'.
Couldn't find manifest for 'vlang'.
Chocolatey v2.5.1
Installing the following packages:
ocaml
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading ocaml 4.00.1.20141015... 100%

ocaml v4.0.1.20141015
ocaml package files install completed. Performing other installation steps.
Attempt to get headers for http://yquem.inria.fr/~protzenk/caml-installer/ocaml-4.00.1-i686-mingw64-installer3.exe failed.
  The remote file either doesn't exist, is unauthorized, or is forbidden for url 'http://yquem.inria.fr/~protzenk/caml-installer/ocaml-4.00.1-i686-mingw64-installer3.exe'. Exception calling "GetResponse" with "0" argument(s): "The remote server returned an error: (403) Forbidden."
Downloading ocaml
  from 'http://yquem.inria.fr/~protzenk/caml-installer/ocaml-4.00.1-i686-mingw64-installer3.exe'
ERROR: The remote file either doesn't exist, is unauthorized, or is forbidden for url 'http://yquem.inria.fr/~protzenk/caml-installer/ocaml-4.00.1-i686-mingw64-installer3.exe'. Exception calling "GetResponse" with "0" argument(s): "The remote server returned an error: (403) Forbidden."
The install of ocaml was NOT successful.
Error while running 'C:\ProgramData\chocolatey\lib\ocaml\tools\chocolateyInstall.ps1'.
 See log for details.

Chocolatey installed 0/1 packages. 1 packages failed.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

Failures
 - ocaml (exited 404) - Error while running 'C:\ProgramData\chocolatey\lib\ocaml\tools\chocolateyInstall.ps1'.
 See log for details.
Chocolatey v2.5.1
Installing the following packages:
racket
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading racket 8.18.0... 100%

racket v8.18.0 [Approved]
racket package files install completed. Performing other installation steps.
Downloading racket 64 bit
  from 'https://download.racket-lang.org/releases/8.18/installers/racket-8.18-x86_64-win32-cs.exe'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\racket\8.18.0\racket-8.18-x86_64-win32-cs.exe (168.25 MB).
Download of racket-8.18-x86_64-win32-cs.exe (168.25 MB) completed.
Hashes match.
Installing racket...
racket has been installed.
  racket may be able to be automatically uninstalled.
 The install of racket was successful.
  Deployed to 'C:\Program Files\Racket'

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).
Chocolatey v2.5.1
Installing the following packages:
sbcl
By installing, you accept licenses for the packages.
Downloading package from source 'https://community.chocolatey.org/api/v2/'
Progress: Downloading sbcl 2.5.10... 100%

sbcl v2.5.10 [Approved]
sbcl package files install completed. Performing other installation steps.
WARNING: Url has SSL/TLS available, switching to HTTPS for download
Downloading sbcl
  from 'https://prdownloads.sourceforge.net/sbcl/sbcl-2.5.10-x86-64-windows-binary.msi'
Progress: 100% - Completed download of C:\Users\shelc\AppData\Local\Temp\chocolatey\sbcl\2.5.10\sbcl-2.5.10-x86-64-windows-binary.msi (13.42 MB).
Download of sbcl-2.5.10-x86-64-windows-binary.msi (13.42 MB) completed.
Hashes match.
Installing sbcl...
sbcl has been installed.
Added C:\ProgramData\chocolatey\bin\sbcl.exe shim pointed to 'c:\program files\steel bank common lisp\sbcl.exe'.
  sbcl may be able to be automatically uninstalled.
Environment Vars (like PATH) have changed. Close/reopen your shell to
 see the changes (or in powershell/cmd.exe just type `refreshenv`).
 The install of sbcl was successful.
  Software installed as 'MSI', install location is likely default.

Chocolatey installed 1/1 packages.
 See the log for details (C:\ProgramData\chocolatey\logs\chocolatey.log).

added 9 packages in 1s

1 package is looking for funding
  run `npm fund` for details
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated mkdirp-promise@5.0.1: This package is broken and no longer maintained. 'mkdirp' itself supports promises now, please switch to that.
npm warn deprecated testrpc@0.0.1: testrpc has been renamed to ganache-cli, please use this package from now on.
npm warn deprecated rimraf@2.7.1: Rimraf versions prior to v4 are no longer supported
npm warn deprecated @truffle/source-map-utils@1.3.119: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated glob@7.2.0: Glob versions prior to v9 are no longer supported
npm warn deprecated level-concat-iterator@3.1.0: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated memdown@1.4.1: Superseded by memory-level (https://github.com/Level/community#faq)
npm warn deprecated har-validator@5.1.5: this library is no longer supported
npm warn deprecated @truffle/promise-tracker@0.1.7: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated level-errors@2.0.1: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated apollo-datasource@3.3.2: The `apollo-datasource` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated apollo-server-errors@3.3.1: The `apollo-server-errors` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated @truffle/error@0.2.2: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated encoding-down@6.3.0: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated @truffle/db-loader@0.2.36: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated deferred-leveldown@5.3.0: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated apollo-server-plugin-base@3.7.2: The `apollo-server-plugin-base` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated apollo-server-types@3.8.0: The `apollo-server-types` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated @truffle/provider@0.3.13: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated level-concat-iterator@2.0.1: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated level-concat-iterator@2.0.1: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated yaeti@0.0.6: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated level-concat-iterator@2.0.1: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated level-concat-iterator@2.0.1: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated @truffle/spinners@0.2.5: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated levelup@4.4.0: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated level-js@5.0.2: Superseded by browser-level (https://github.com/Level/community#faq)
npm warn deprecated @truffle/dashboard-message-bus-common@0.1.7: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated apollo-server-express@3.13.0: The `apollo-server-express` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated level-codec@9.0.2: Superseded by level-transcoder (https://github.com/Level/community#faq)
npm warn deprecated level-packager@5.1.1: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated apollo-server@3.13.0: The `apollo-server` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated apollo-reporting-protobuf@3.4.0: The `apollo-reporting-protobuf` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/usage-reporting-protobuf` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated multicodec@1.0.4: This module has been superseded by the multiformats module
npm warn deprecated uuid@3.4.0: Please upgrade  to version 7 or higher.  Older versions may use Math.random() in certain circumstances, which is known to be problematic.  See https://v8.dev/blog/math-random for details.
npm warn deprecated uuid@2.0.1: Please upgrade  to version 7 or higher.  Older versions may use Math.random() in certain circumstances, which is known to be problematic.  See https://v8.dev/blog/math-random for details.
npm warn deprecated request@2.88.2: request has been deprecated, see https://github.com/request/request/issues/3142
npm warn deprecated multibase@0.6.1: This module has been superseded by the multiformats module
npm warn deprecated @truffle/events@0.1.25: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated multibase@0.7.0: This module has been superseded by the multiformats module
npm warn deprecated @truffle/config@1.3.61: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated multicodec@0.5.7: This module has been superseded by the multiformats module
npm warn deprecated @truffle/code-utils@3.0.4: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated apollo-server-env@4.2.1: The `apollo-server-env` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/utils.fetcher` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated abstract-leveldown@2.7.2: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated abstract-leveldown@6.3.0: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated abstract-leveldown@6.2.3: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated abstract-leveldown@6.2.3: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated abstract-leveldown@6.2.3: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated @truffle/dashboard-message-bus-client@0.1.12: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated abstract-leveldown@7.2.0: Superseded by abstract-level (https://github.com/Level/community#faq)
npm warn deprecated @truffle/compile-common@0.9.8: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated @truffle/interface-adapter@0.5.37: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated @truffle/abi-utils@1.0.3: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated @ensdomains/ens@0.4.5: Please use @ensdomains/ens-contracts
npm warn deprecated cids@0.7.5: This module has been superseded by the multiformats module
npm warn deprecated @ensdomains/resolver@0.2.4: Please use @ensdomains/ens-contracts
npm warn deprecated @truffle/debugger@12.1.5: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated apollo-server-core@3.13.0: The `apollo-server-core` package is part of Apollo Server v2 and v3, which are now end-of-life (as of October 22nd 2023 and October 22nd 2024, respectively). This package's functionality is now found in the `@apollo/server` package. See https://www.apollographql.com/docs/apollo-server/previous-versions/ for more details.
npm warn deprecated leveldown@5.6.0: Superseded by classic-level (https://github.com/Level/community#faq)
npm warn deprecated @truffle/db@2.0.36: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.
npm warn deprecated @truffle/codec@0.17.3: Package no longer supported. Contact Support at https://www.npmjs.com/support for more info.

added 1175 packages in 43s

105 packages are looking for funding
  run `npm fund` for details

added 59 packages in 7s

16 packages are looking for funding
  run `npm fund` for details

Installing VS Code Extensions...
Installing extension: ms-python.python
Installing extensions...
Updating the extension 'ms-python.python' to the version 2025.18.0
Installing extension 'ms-python.python'...
Extension 'ms-python.python' v2025.18.0 was successfully installed.
Installing extension: ms-python.vscode-pylance
Installing extensions...
Updating the extension 'ms-python.vscode-pylance' to the version 2025.10.1
Installing extension 'ms-python.vscode-pylance'...
Extension 'ms-python.vscode-pylance' v2025.10.1 was successfully installed.
Installing extension: ms-toolsai.jupyter
Installing extensions...
Updating the extension 'ms-toolsai.jupyter' to the version 2025.9.1
Installing extension 'ms-toolsai.jupyter'...
Extension 'ms-toolsai.jupyter' v2025.9.1 was successfully installed.
Installing extension: GitHub.copilot
Installing extensions...
Updating the extension 'github.copilot' to the version 1.388.0
Installing extension 'github.copilot'...
Extension 'github.copilot' v1.388.0 was successfully installed.
Installing extension: GitHub.copilot-chat
Installing extensions...
Updating the extension 'github.copilot-chat' to the version 0.33.2
Installing extension 'github.copilot-chat'...
Extension 'github.copilot-chat' v0.33.2 was successfully installed.
Installing extension: ms-vscode-remote.remote-wsl
Installing extensions...
Extension 'ms-vscode-remote.remote-wsl' is already installed.
Installing extension: ms-vscode-remote.remote-ssh
Installing extensions...
Installing extension 'ms-vscode-remote.remote-ssh'...
Extension 'ms-vscode.remote-explorer' v0.5.0 was successfully installed.
Extension 'ms-vscode-remote.remote-ssh-edit' v0.87.0 was successfully installed.
Extension 'ms-vscode-remote.remote-ssh' v0.120.0 was successfully installed.
Installing extension: ms-vscode-remote.remote-containers
Installing extensions...
Installing extension 'ms-vscode-remote.remote-containers'...
Extension 'ms-vscode-remote.remote-containers' v0.431.1 was successfully installed.
Installing extension: ms-azuretools.vscode-docker
Installing extensions...
Extension 'ms-azuretools.vscode-docker' is already installed.
Installing extension: ms-kubernetes-tools.vscode-kubernetes-tools
Installing extensions...
Installing extension 'ms-kubernetes-tools.vscode-kubernetes-tools'...
Extension 'redhat.vscode-yaml' v1.19.1 was successfully installed.
Extension 'ms-kubernetes-tools.vscode-kubernetes-tools' v1.3.27 was successfully installed.
Installing extension: eamodio.gitlens
Installing extensions...
Extension 'eamodio.gitlens' is already installed.
Installing extension: mhutchie.git-graph
Installing extensions...
Installing extension 'mhutchie.git-graph'...
Extension 'mhutchie.git-graph' v1.30.0 was successfully installed.
Installing extension: dbaeumer.vscode-eslint
Installing extensions...
Extension 'dbaeumer.vscode-eslint' is already installed.
Installing extension: esbenp.prettier-vscode
Installing extensions...
Extension 'esbenp.prettier-vscode' is already installed.
Installing extension: ms-vscode.cpptools
Installing extensions...
Updating the extension 'ms-vscode.cpptools' to the version 1.28.3
Installing extension 'ms-vscode.cpptools'...
Extension 'ms-vscode.cpptools' v1.28.3 was successfully installed.
Installing extension: ms-vscode.cmake-tools
Installing extensions...
Extension 'ms-vscode.cmake-tools' is already installed.
Installing extension: golang.go
Installing extensions...
Extension 'golang.go' is already installed.
Installing extension: rust-lang.rust-analyzer
Installing extensions...
Updating the extension 'rust-lang.rust-analyzer' to the version 0.3.2693
Installing extension 'rust-lang.rust-analyzer'...
Extension 'rust-lang.rust-analyzer' v0.3.2693 was successfully installed.
Installing extension: ms-dotnettools.csharp
Installing extensions...
Updating the extension 'ms-dotnettools.csharp' to the version 2.100.11
Installing extension 'ms-dotnettools.csharp'...
Extension 'ms-dotnettools.csharp' v2.100.11 was successfully installed.
Installing extension: ms-dotnettools.vscode-dotnet-runtime
Installing extensions...
Extension 'ms-dotnettools.vscode-dotnet-runtime' is already installed.
Installing extension: redhat.java
Installing extensions...
Updating the extension 'redhat.java' to the version 1.49.0
Installing extension 'redhat.java'...
Extension 'redhat.java' v1.49.0 was successfully installed.
Installing extension: vscjava.vscode-java-pack
Installing extensions...
Updating the extension 'vscjava.vscode-java-pack' to the version 0.30.5
Installing extension 'vscjava.vscode-java-pack'...
Extension 'vscjava.vscode-java-pack' v0.30.5 was successfully installed.
Installing extension: ms-azuretools.vscode-azurefunctions
Installing extensions...
Installing extension 'ms-azuretools.vscode-azurefunctions'...
Extension 'ms-azuretools.vscode-azureresourcegroups' v0.11.7 was successfully installed.
Extension 'ms-azuretools.vscode-azurefunctions' v1.20.2 was successfully installed.
Installing extension: ms-vscode.azurecli
Installing extensions...
Installing extension 'ms-vscode.azurecli'...
Extension 'ms-vscode.azurecli' v0.6.0 was successfully installed.
Installing extension: amazonwebservices.aws-toolkit-vscode
Installing extensions...
Installing extension 'amazonwebservices.aws-toolkit-vscode'...
Extension 'amazonwebservices.aws-toolkit-vscode' v3.89.0 was successfully installed.
Installing extension: googlecloudtools.cloudcode
Installing extensions...
Installing extension 'googlecloudtools.cloudcode'...
Extension 'google.geminicodeassist' v2.59.0 was successfully installed.
Extension 'googlecloudtools.cloudcode' v2.37.0 was successfully installed.
Installing extension: hashicorp.terraform
Installing extensions...
Installing extension 'hashicorp.terraform'...
Extension 'hashicorp.terraform' v2.37.6 was successfully installed.
Installing extension: ms-kubernetes-tools.vscode-aks-tools
Installing extensions...
Installing extension 'ms-kubernetes-tools.vscode-aks-tools'...
Extension 'ms-kubernetes-tools.vscode-aks-tools' v1.6.14 was successfully installed.
Installing extension: redhat.vscode-yaml
Installing extensions...
Extension 'redhat.vscode-yaml' is already installed.
Installing extension: redhat.vscode-xml
Installing extensions...
Installing extension 'redhat.vscode-xml'...
Extension 'redhat.vscode-xml' v0.29.0 was successfully installed.
Installing extension: tamasfe.even-better-toml
Installing extensions...
Installing extension 'tamasfe.even-better-toml'...
Extension 'tamasfe.even-better-toml' v0.21.2 was successfully installed.
Installing extension: ms-vscode.powershell
Installing extensions...
Updating the extension 'ms-vscode.powershell' to the version 2025.4.0
Installing extension 'ms-vscode.powershell'...
Extension 'ms-vscode.powershell' v2025.4.0 was successfully installed.
Installing extension: timonwong.shellcheck
Installing extensions...
Installing extension 'timonwong.shellcheck'...
Extension 'timonwong.shellcheck' v0.38.5 was successfully installed.
Installing extension: foxundermoon.shell-format
Installing extensions...
Installing extension 'foxundermoon.shell-format'...
Extension 'foxundermoon.shell-format' v7.2.8 was successfully installed.
Installing extension: ms-vscode.hexeditor
Installing extensions...
Installing extension 'ms-vscode.hexeditor'...
Extension 'ms-vscode.hexeditor' v1.11.1 was successfully installed.
Installing extension: streetsidesoftware.code-spell-checker
Installing extensions...
Installing extension 'streetsidesoftware.code-spell-checker'...
Extension 'streetsidesoftware.code-spell-checker' v4.3.2 was successfully installed.
Installing extension: wayou.vscode-todo-highlight
Installing extensions...
Installing extension 'wayou.vscode-todo-highlight'...
Extension 'wayou.vscode-todo-highlight' v1.0.5 was successfully installed.                                                                                   Installing extension: gruntfuggly.todo-tree                                                                                                                  Installing extensions...                                                                                                                                     Installing extension 'gruntfuggly.todo-tree'...                                                                                                              Extension 'gruntfuggly.todo-tree' v0.0.226 was successfully installed.                                                                                       Installing extension: usernamehw.errorlens                                                                                                                   Installing extensions...                                                                                                                                     Installing extension 'usernamehw.errorlens'...                                                                                                               Extension 'usernamehw.errorlens' v3.26.0 was successfully installed.                                                                                         Installing extension: oderwat.indent-rainbow                                                                                                                 Installing extensions...
Installing extension 'oderwat.indent-rainbow'...
Extension 'oderwat.indent-rainbow' v8.3.1 was successfully installed.
Installing extension: pkief.material-icon-theme
Installing extensions...
Installing extension 'pkief.material-icon-theme'...
Extension 'pkief.material-icon-theme' v5.29.0 was successfully installed.
Installing extension: zhuangtongfa.material-theme
Installing extensions...
Installing extension 'zhuangtongfa.material-theme'...
Extension 'zhuangtongfa.material-theme' v3.19.0 was successfully installed.
Installing extension: formulahendry.code-runner
Installing extensions...
Installing extension 'formulahendry.code-runner'...
Extension 'formulahendry.code-runner' v0.12.2 was successfully installed.
Installing extension: humao.rest-client
Installing extensions...
Installing extension 'humao.rest-client'...
Extension 'humao.rest-client' v0.25.1 was successfully installed.
Installing extension: rangav.vscode-thunder-client
Installing extensions...
Installing extension 'rangav.vscode-thunder-client'...
Extension 'rangav.vscode-thunder-client' v2.38.5 was successfully installed.
Installing extension: mtxr.sqltools
Installing extensions...
Installing extension 'mtxr.sqltools'...
Extension 'mtxr.sqltools' v0.28.5 was successfully installed.
Installing extension: ms-mssql.mssql
Installing extensions...
Installing extension 'ms-mssql.mssql'...
Extension 'ms-mssql.data-workspace-vscode' v0.6.3 was successfully installed.
Extension 'ms-mssql.sql-bindings-vscode' v0.4.1 was successfully installed.
Extension 'ms-mssql.mssql' v1.37.0 was successfully installed.
Extension 'ms-mssql.sql-database-projects-vscode' v1.5.5 was successfully installed.
Installing extension: ckolkman.vscode-postgres
Installing extensions...
Installing extension 'ckolkman.vscode-postgres'...
Extension 'ckolkman.vscode-postgres' v1.4.3 was successfully installed.
Installing extension: mongodb.mongodb-vscode
Installing extensions...
Installing extension 'mongodb.mongodb-vscode'...
Extension 'mongodb.mongodb-vscode' v1.14.2 was successfully installed.
Installing extension: ritwickdey.liveserver
Installing extensions...
Installing extension 'ritwickdey.liveserver'...
Extension 'ritwickdey.liveserver' v5.7.9 was successfully installed.
Installing extension: ms-playwright.playwright
Installing extensions...
Installing extension 'ms-playwright.playwright'...
Extension 'ms-playwright.playwright' v1.1.17 was successfully installed.
Installing extension: vscodevim.vim
Installing extensions...
Installing extension 'vscodevim.vim'...
Extension 'vscodevim.vim' v1.32.1 was successfully installed.
Installing extension: vspacecode.whichkey
Installing extensions...
Installing extension 'vspacecode.whichkey'...
Extension 'vspacecode.whichkey' v0.11.4 was successfully installed.
Installing extension: github.vscode-github-actions
Installing extensions...
Installing extension 'github.vscode-github-actions'...
Extension 'github.vscode-github-actions' v0.28.1 was successfully installed.
Installing extension: gitlab.gitlab-workflow
Installing extensions...
Installing extension 'gitlab.gitlab-workflow'...
Extension 'gitlab.gitlab-workflow' v6.58.0 was successfully installed.
Installing extension: ms-azuretools.vscode-bicep
Installing extensions...
Installing extension 'ms-azuretools.vscode-bicep'...
Extension 'ms-azuretools.vscode-bicep' v0.39.26 was successfully installed.

Configuring System Settings...


LongPathsEnabled : 1
PSPath           : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem
PSParentPath     : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control
PSChildName      : FileSystem
PSDrive          : HKLM
PSProvider       : Microsoft.PowerShell.Core\Registry

The operation completed successfully.

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║           INSTALLATION COMPLETE (WITH WARNINGS)              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

========== INSTALLED TOOLS VERIFICATION ==========
[✓] VS Code installed: 1.106.2
[✓] Ruby installed: ruby 3.4.7 (2025-10-08 revision 7a5688e2a2) +PRISM [x64-mingw-ucrt]
[✓] Terraform installed: Terraform v1.14.0
[✓] .NET installed: 9.0.308
[✓] Kubectl installed: Client Version: v1.34.2
[✓] Rust installed: rustc 1.91.1 (ed61e7d7e 2025-11-07)
[✓] Node.js installed: v24.11.1
[✓] Git installed: git version 2.52.0.windows.1
[✓] Docker installed: Docker version 29.0.4, build 3247a5a
[✓] Java installed:
[✓] Python installed: Python 3.13.9
[✓] PHP installed: PHP 8.5.0 (cli) (built: Nov 19 2025 09:56:40) (NTS Visual C++ 2022 x64)
[✓] Go installed: go version go1.25.4 windows/amd64

========== CRITICAL NEXT STEPS ==========
1. RESTART YOUR COMPUTER (Required for WSL2, Docker, environment variables)

2. After restart, configure Git:
   git config --global user.name "Your Name"
   git config --global user.email "your@email.com"

3. Install Python versions via pyenv:
   pyenv install 3.11.7
   pyenv install 3.10.13
   pyenv global 3.11.7

4. Authenticate services:
   gh auth login                    # GitHub CLI
   aws configure                    # AWS CLI
   az login                         # Azure CLI
   gcloud init                      # Google Cloud CLI

5. Start Docker Desktop:
   - Open Docker Desktop from Start Menu
   - Enable WSL2 integration in Settings
   - Configure resources (RAM, CPU limits)

6. Configure WSL2 Ubuntu:
   wsl
   sudo apt update && sudo apt upgrade -y

7. Test installations:
   docker run hello-world
   kubectl version
   python -c "import torch; print(torch.__version__)"

8. Review storage usage:
   Get-PSDrive C | Select Used, Free

9. Optional: Install JetBrains IDEs via Toolbox
   - Open JetBrains Toolbox from Start Menu
   - Install PyCharm, IntelliJ IDEA, WebStorm as needed

10. Clean up installer cache (after verifying everything works):
    choco cache remove
    npm cache clean --force

ESTIMATED STORAGE USED: ~350-400GB

========== TROUBLESHOOTING COMMON ISSUES ==========
- If Docker fails to start: Enable Hyper-V and restart
- If WSL2 not working: Run 'wsl --update' and restart
- If Node modules fail: Run 'npm config set strict-ssl false' (corporate networks)
- If Python packages fail: Use 'pip install --user <package>'
- If paths not recognized: Restart PowerShell or add to PATH manually
- Check logs: Most Chocolatey logs are in C:\ProgramData\chocolatey\logs

🎉 WELCOME TO YOUR COMPLETE DEVELOPER ARSENAL! 🎉
You now have 200+ tools installed. Time to build something amazing!


 shelc   system32    CONFIG ERROR 