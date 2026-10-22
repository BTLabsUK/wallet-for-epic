; Inno Setup 6 script for the Windows installer. Built by tool\build_windows_release.ps1, which
; passes /DSourceDir (the Flutter Release folder, with the VC runtime DLLs added), /DOutputDir and
; optionally /DAppVersion. Per-user: no admin rights, nothing outside the user's profile.
;
; The wallet's data (%APPDATA%\com.blacktyger\EpicWallet) is never touched: there is no
; [UninstallDelete], [InstallDelete] names only old shortcut files, and Inno removes only the
; files it installed.

#ifndef SourceDir
  #error Pass /DSourceDir=<Flutter Release folder>
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif
#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif

[Setup]
; Fixed for good: a new GUID would make an upgrade install beside the old version.
AppId={{8810835E-6EE5-4989-AE20-C0D60E23800E}
AppName=Epic Wallet
AppVersion={#AppVersion}
AppPublisher=BT Labs
DefaultDirName={%USERPROFILE}\Apps\EpicWallet
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\epic_wallet.exe
UninstallDisplayName=Epic Wallet
OutputDir={#OutputDir}
OutputBaseFilename=epic-wallet-{#AppVersion}-windows-x64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=no

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Excludes: "*.lib,*.exp,*.pdb,*.ilk"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
; One shortcut; the runner's --impeller and --skia flags stay for a hand-made one.
Name: "{userprograms}\Epic Wallet"; Filename: "{app}\epic_wallet.exe"; IconFilename: "{app}\epic_wallet.exe"; WorkingDir: "{app}"
Name: "{userdesktop}\Epic Wallet"; Filename: "{app}\epic_wallet.exe"; IconFilename: "{app}\epic_wallet.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[InstallDelete]
; The 0.1.0 shortcuts, named by version and renderer. Only these exact files.
Type: files; Name: "{userprograms}\Epic Wallet 0.1.lnk"
Type: files; Name: "{userprograms}\Epic Wallet 0.1 (Skia).lnk"
Type: files; Name: "{userprograms}\Epic Wallet 0.1 (Impeller).lnk"
Type: files; Name: "{userdesktop}\Epic Wallet 0.1.lnk"
