; Inno Setup 6.7 script for the Windows installer. Built by tool\build_windows_release.ps1, which
; passes /DSourceDir (the Flutter Release folder, with the VC runtime DLLs added), /DOutputDir and
; /DAppVersion (pubspec.yaml's YY.MM.patch, https://docs.btlabs.uk/developers/releases/). Per-user
; (PrivilegesRequired=lowest): everything goes in the user's profile.
;
; The wallet's data (%APPDATA%\com.blacktyger\EpicWallet) is never touched: there is no
; [UninstallDelete], [InstallDelete] names only old shortcut files, and Inno removes only the
; files it installed.
;
; Look (docs/feedback/designs/installer, the owner's OK of 2026-10-22): one dark wizard page with
; the landing-page hero behind it, one Install button, folder and shortcuts behind an "Options"
; link, a gold progress bar, "Open Epic Cash Desktop" at the end. Everything is stock Inno 6.7: the
; built-in dark style, WizardSetBackImage for the hero (dimmed while files copy), TNewStaticText
; and TBitmapImage controls on the stock pages, Montserrat loaded privately for the headings
; (OFL; the licence text is installed next to the app). Images come from make_images.sh.

#ifndef SourceDir
  #error Pass /DSourceDir=<Flutter Release folder>
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif
#ifndef AppVersion
  #error Pass /DAppVersion=<pubspec.yaml's version, without +build>
#endif
; The file version is YY.MM.patch.0; a test build's -rcN is left out (numbers only).
#if Pos("-", AppVersion) > 0
  #define FileVersion Copy(AppVersion, 1, Pos("-", AppVersion) - 1) + ".0"
#else
  #define FileVersion AppVersion + ".0"
#endif

[Setup]
; Fixed for good: a new GUID would make an upgrade install beside the old version.
AppId={{8810835E-6EE5-4989-AE20-C0D60E23800E}
AppName=Epic Cash Desktop
AppVersion={#AppVersion}
VersionInfoVersion={#FileVersion}
AppPublisher=BT Labs
; The app's single-instance mutex (windows\runner\main.cpp): Setup and the uninstaller wait for
; the app to close instead of replacing files under it.
AppMutex=Local\com.blacktyger.EpicWallet.single
DefaultDirName={%USERPROFILE}\Apps\EpicWallet
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
DisableWelcomePage=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\epic_wallet.exe
UninstallDisplayName=Epic Cash Desktop
OutputDir={#OutputDir}
OutputBaseFilename=epic-cash-desktop-{#AppVersion}-windows-x64-setup
Compression=lzma2
SolidCompression=yes
CloseApplications=no
; Dark, flat, no bevels; the hero is dark, so the appearance is forced rather than following
; Windows. WizardBackColor turns on the custom background that WizardSetBackImage needs.
WizardStyle=modern dark hidebevels
WizardBackColor=#08080A
WizardImageFile=
WizardSmallImageFile=images\icon.png
WizardSmallImageBackColor=#08080A
SetupIconFile=..\runner\resources\app_icon.ico

[Messages]
SetupWindowTitle=%1 Setup
UninstallAppFullTitle=%1 Uninstall
SetupAppRunningError=%1 is open.%n%nClose it, then click OK to continue, or Cancel to exit.
UninstallAppRunningError=%1 is open.%n%nClose it, then click OK to continue, or Cancel to exit.
ConfirmUninstall=Remove %1?%n%nRemoves the app from its folder and its shortcuts.%nWallet data in AppData\Roaming\com.blacktyger\EpicWallet stays.
UninstalledAll=%1 was removed.%n%nWallet data was kept.
StatusExtractFiles=Copying files...
StatusCreateIcons=Creating shortcuts...
StatusRunProgram=Finishing...
StatusRollback=Undoing...
StatusUninstalling=Removing files...

[Files]
; Setup's own images and font: extracted to {tmp}, never installed. Listed first (solid compression).
Source: "images\back-596x432.png"; Flags: dontcopy
Source: "images\back-994x720.png"; Flags: dontcopy
Source: "images\back-1272x922.png"; Flags: dontcopy
Source: "images\icon.png"; Flags: dontcopy
Source: "images\sheet.png"; Flags: dontcopy
Source: "images\sheet-update.png"; Flags: dontcopy
Source: "..\..\assets\fonts\Montserrat-SemiBold.ttf"; Flags: dontcopy
; Montserrat is OFL: its licence goes next to the app (the app itself carries a copy in its assets).
Source: "..\..\assets\fonts\OFL-Montserrat.txt"; DestDir: "{app}"; DestName: "LICENSE.Montserrat.txt"; Flags: ignoreversion
Source: "{#SourceDir}\*"; DestDir: "{app}"; Excludes: "*.lib,*.exp,*.pdb,*.ilk"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
; One shortcut per place; the runner's --impeller and --skia flags stay for a hand-made one.
; Both on by default, each behind a box on the welcome page's Options sheet (no [Tasks]: Inno fills
; its tasks list only when the Tasks page shows, and that page is not part of this wizard).
Name: "{userprograms}\Epic Cash Desktop"; Filename: "{app}\epic_wallet.exe"; IconFilename: "{app}\epic_wallet.exe"; WorkingDir: "{app}"; Check: WantStartMenu
Name: "{userdesktop}\Epic Cash Desktop"; Filename: "{app}\epic_wallet.exe"; IconFilename: "{app}\epic_wallet.exe"; WorkingDir: "{app}"; Check: WantDesktop

[InstallDelete]
; The 0.1.0 shortcuts, named by version and renderer. Only these exact files.
Type: files; Name: "{userprograms}\Epic Wallet 0.1.lnk"
Type: files; Name: "{userprograms}\Epic Wallet 0.1 (Skia).lnk"
Type: files; Name: "{userprograms}\Epic Wallet 0.1 (Impeller).lnk"
Type: files; Name: "{userdesktop}\Epic Wallet 0.1.lnk"
; An upgrade from 0.1.0 drops the old-named shortcuts; the new ones are "Epic Cash Desktop".
Type: files; Name: "{userprograms}\Epic Wallet.lnk"
Type: files; Name: "{userdesktop}\Epic Wallet.lnk"

[Run]
; "Open Epic Cash Desktop" on the finish page (the stock Finish button, renamed). The "Close" link
; unchecks this entry first. Never in a silent install.
Filename: "{app}\epic_wallet.exe"; WorkingDir: "{app}"; Description: "Open Epic Cash Desktop"; Flags: nowait postinstall skipifsilent

[Code]
const
  UninstKey = 'Software\Microsoft\Windows\CurrentVersion\Uninstall\{8810835E-6EE5-4989-AE20-C0D60E23800E}_is1';
  FontFile = 'Montserrat-SemiBold.ttf';
  FR_PRIVATE = $10;
  BM_CLICK = $F5;
  { TColor is BGR. The app's dark tokens. }
  ColText = $F9F9FF;   { #FFF9F9 }
  ColDim = $ADA4A4;    { #A4A4AD }
  ColFaint = $94948A;  { #8A8A94 }
  ColGold = $71D4F6;   { #F6D471 }
  ColTrack = $2B2222;  { #22222B }
  DimOpacity = 66;     { the hero at 26 % while files copy }
  BtnW = 92;           { the mockup's button size }
  BtnH = 30;

function AddFontResourceEx(Name: String; Flags: DWORD; Reserved: Integer): Integer;
  external 'AddFontResourceExW@gdi32.dll stdcall';
function RemoveFontResourceEx(Name: String; Flags: DWORD; Reserved: Integer): BOOL;
  external 'RemoveFontResourceExW@gdi32.dll stdcall';

var
  IsUpdate: Boolean;
  InstalledVersion, HeadFont, FontPath: String;
  BackImages: array of TGraphic;
  { welcome page }
  WelIcon, Sheet: TBitmapImage;
  WelHead, WelSub, WelSubGold, WelBody, WelPath, WelKeep: TNewStaticText;
  FolderLabel, FolderHint, ShortLabel, SpaceLabel, KeepLabel: TNewStaticText;
  FolderEdit: TNewEdit;
  BrowseBtn: TNewButton;
  StartChk, DeskChk: TNewCheckBox;
  OptLink, CloseLink: TNewStaticText;
  SheetOpen: Boolean;
  { installing page }
  BarTrack, BarFill: TBitmapImage;
  PctLabel, InstNote: TNewStaticText;
  { finished page }
  FinIcon: TBitmapImage;
  FinHead, FinSub, FinBody: TNewStaticText;

{ ---------- helpers ---------- }

function WantStartMenu: Boolean;
begin
  Result := (StartChk = nil) or StartChk.Checked;
end;

function WantDesktop: Boolean;
begin
  Result := (DeskChk = nil) or DeskChk.Checked;
end;

{ The 0.1.0 installer had a "desktopicon" task; Inno recorded the choice in the uninstall key. }
function PreviousDesktopChoice: Boolean;
var
  S: String;
begin
  Result := True;
  if IsUpdate and RegQueryStringValue(HKCU, UninstKey, 'Inno Setup: Selected Tasks', S) then
    Result := Pos('desktopicon', S) > 0
  else if IsUpdate and RegQueryStringValue(HKCU, UninstKey, 'Inno Setup: Deselected Tasks', S) then
    Result := Pos('desktopicon', S) = 0;
end;

{ /TASKS="startmenu,desktopicon" (the 0.1.0 task names) still picks the shortcuts, so a silent
  install can leave one out: /TASKS="" gives none, /TASKS="startmenu" no desktop one. }
function CmdTask(const Name: String; Default: Boolean): Boolean;
var
  T: String;
begin
  T := ExpandConstant('{param:TASKS|?}');
  if T = '?' then
    Result := Default
  else
    Result := Pos(Name, Lowercase(T)) > 0;
end;

function Lbl(Parent: TWinControl; L, T: Integer; const S, FontName: String; Size: Integer; Color: TColor): TNewStaticText;
begin
  Result := TNewStaticText.Create(WizardForm);
  Result.Parent := Parent;
  Result.Left := ScaleX(L);
  Result.Top := ScaleY(T);
  if FontName <> '' then
    Result.Font.Name := FontName;
  Result.Font.Size := Size;
  { Keep our own colour under the dark style (it would otherwise repaint every label). }
  Result.StyleElements := Result.StyleElements - [seFont];
  Result.Font.Color := Color;
  Result.Caption := S;
end;

function Png(Parent: TWinControl; const BaseName: String; L, T, W, H: Integer): TBitmapImage;
begin
  ExtractTemporaryFile(BaseName);
  Result := TBitmapImage.Create(WizardForm);
  Result.Parent := Parent;
  Result.BackColor := clNone;
  Result.Stretch := True;
  Result.Left := ScaleX(L);
  Result.Top := ScaleY(T);
  Result.Width := ScaleX(W);
  Result.Height := ScaleY(H);
  Result.PngImage.LoadFromFile(ExpandConstant('{tmp}\' + BaseName));
end;

{ A one-pixel bitmap stretched to the control: a flat colour the style cannot override. }
function Solid(Parent: TWinControl; Color: TColor; L, T, W, H: Integer): TBitmapImage;
begin
  Result := TBitmapImage.Create(WizardForm);
  Result.Parent := Parent;
  Result.Bitmap.Width := 1;
  Result.Bitmap.Height := 1;
  Result.Bitmap.Canvas.Pixels[0, 0] := Color;
  Result.Stretch := True;
  Result.Left := L;
  Result.Top := T;
  Result.Width := W;
  Result.Height := H;
end;

procedure SetBack(Opacity: Integer);
begin
  WizardSetBackImage(BackImages, True, False, Opacity);
end;

procedure LoadBackImages;
var
  Names: array of String;
  I: Integer;
  P: TPngImage;
begin
  Names := ['back-596x432.png', 'back-994x720.png', 'back-1272x922.png'];
  SetArrayLength(BackImages, GetArrayLength(Names));
  for I := 0 to GetArrayLength(Names) - 1 do begin
    ExtractTemporaryFile(Names[I]);
    P := TPngImage.Create;
    P.LoadFromFile(ExpandConstant('{tmp}\' + Names[I]));
    BackImages[I] := P;
  end;
end;

{ "At least 190,2 MB of free disk space is required." -> "Needs 190 MB" }
function SpaceLine: String;
var
  S, Digits: String;
  I: Integer;
begin
  S := WizardForm.DiskSpaceLabel.Caption;
  Digits := '';
  for I := 1 to Length(S) do begin
    if (S[I] >= '0') and (S[I] <= '9') then
      Digits := Digits + S[I]
    else if Digits <> '' then
      break;
  end;
  if Digits = '' then
    Result := ''
  else
    Result := 'Needs ' + Digits + ' MB';
end;

procedure ShowSheet(Open: Boolean);
begin
  SheetOpen := Open;
  Sheet.Visible := Open;
  FolderLabel.Visible := Open;
  FolderEdit.Visible := Open;
  BrowseBtn.Visible := Open and not IsUpdate;
  FolderHint.Visible := Open and IsUpdate;
  ShortLabel.Visible := Open;
  StartChk.Visible := Open;
  DeskChk.Visible := Open;
  SpaceLabel.Visible := Open and (SpaceLabel.Caption <> '');
  KeepLabel.Visible := Open;
  WelBody.Visible := not Open;
  WelPath.Visible := not Open;
  WelKeep.Visible := (not Open) and IsUpdate;
  if Open then begin
    WizardForm.ActiveControl := FolderEdit;
    FolderEdit.SelStart := Length(FolderEdit.Text);
    FolderEdit.SelLength := 0;
  end;
end;

procedure OptionsClick(Sender: TObject);
begin
  ShowSheet(not SheetOpen);
end;

procedure CloseClick(Sender: TObject);
begin
  { Finish without opening the app: uncheck the [Run] entry, then press Finish. }
  if WizardForm.RunList.Items.Count > 0 then
    WizardForm.RunList.Checked[0] := False;
  PostMessage(WizardForm.NextButton.Handle, BM_CLICK, 0, 0);
end;

procedure BrowseClick(Sender: TObject);
var
  D: String;
begin
  D := FolderEdit.Text;
  if BrowseForFolder('Folder for Epic Cash Desktop', D, True) then
    FolderEdit.Text := D;
end;

{ A link at the left end of the button bar, in line with the buttons: gold underlined text
  (a TNewLinkLabel is a SysLink, which the dark style paints blue whatever its font says).
  From the keyboard: Alt+O and Alt+C (WizardKeyDown). }
function BarLink(const Caption: String; OnClick: TNotifyEvent): TNewStaticText;
begin
  Result := Lbl(WizardForm, 0, 0, Caption, '', 10, ColGold);
  Result.Font.Style := [fsUnderline];
  Result.Cursor := crHand;
  Result.OnClick := OnClick;
  Result.Left := ScaleX(40);
  Result.Top := WizardForm.NextButton.Top + (WizardForm.NextButton.Height - Result.Height) div 2;
  Result.Visible := False;
end;

procedure WizardKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if not (ssAlt in Shift) then
    exit;
  if (Key = Ord('O')) and OptLink.Visible then begin
    OptionsClick(OptLink);
    Key := 0;
  end else if (Key = Ord('C')) and CloseLink.Visible then begin
    CloseClick(CloseLink);
    Key := 0;
  end;
end;

{ The mockup's 92 x 30 buttons, right-aligned as before, centred on the old line. }
procedure SizeButtons;
var
  N, C: TNewButton;
  Right, Mid: Integer;
begin
  N := WizardForm.NextButton;
  C := WizardForm.CancelButton;
  Right := C.Left + C.Width;
  Mid := C.Top + C.Height div 2;
  C.SetBounds(Right - ScaleX(BtnW), Mid - ScaleY(BtnH) div 2, ScaleX(BtnW), ScaleY(BtnH));
  N.SetBounds(C.Left - ScaleX(10) - ScaleX(BtnW), C.Top, ScaleX(BtnW), ScaleY(BtnH));
end;

{ The stock header label is one line of the default size: a 14 pt heading gets clipped. }
procedure FixHeader(NameLbl, DescLbl: TNewStaticText);
begin
  NameLbl.AutoSize := False;
  NameLbl.Left := DescLbl.Left;
  NameLbl.Top := ScaleY(8);
  NameLbl.Height := ScaleY(26);
  DescLbl.Top := NameLbl.Top + ScaleY(28);
  DescLbl.Height := ScaleY(18);
end;

{ ---------- pages ---------- }

procedure BuildWelcome;
var
  P: TNewNotebookPage;
  Dir: String;
  RowShort: Integer;
begin
  P := WizardForm.WelcomePage;
  WizardForm.WelcomeLabel1.Visible := False;
  WizardForm.WelcomeLabel2.Visible := False;
  WizardForm.WizardBitmapImage.Visible := False;
  Dir := WizardForm.DirEdit.Text;

  WelIcon := Png(P, 'icon.png', 40, 44, 56, 56);
  WelHead := Lbl(P, 40, 110, 'Epic Cash Desktop', HeadFont, 21, ColText);
  if IsUpdate then begin
    WelSubGold := Lbl(P, 40, 152, 'Update to {#AppVersion}', '', 10, ColGold);
    WelSubGold.Font.Style := [fsBold];
    WelSub := Lbl(P, 40, 152, #$00B7 + ' installed ' + InstalledVersion, '', 10, ColDim);
    WelSub.Left := WelSubGold.Left + WelSubGold.Width + ScaleX(6);
    WelBody := Lbl(P, 40, 186, 'Replaces the files in', '', 10, ColText);
  end else begin
    WelSub := Lbl(P, 40, 152, 'Version {#AppVersion} ' + #$00B7 + ' BT Labs', '', 10, ColDim);
    WelBody := Lbl(P, 40, 186, 'Installs for this user.', '', 10, ColText);
  end;
  WelPath := Lbl(P, 40, 206, Dir, 'Consolas', 9, ColDim);
  WelKeep := Lbl(P, 40, 228, 'Wallet data and settings stay.', '', 10, ColDim);
  WelKeep.Visible := IsUpdate;

  { The Options sheet: an alpha PNG panel with the folder and the two shortcut boxes on it. }
  { Rows as in the mockup: Folder, (update: the hint), Shortcuts, then the footer line. }
  if IsUpdate then begin
    RowShort := 254;
    Sheet := Png(P, 'sheet-update.png', 40, 196, 424, 122);
  end else begin
    RowShort := 244;
    Sheet := Png(P, 'sheet.png', 40, 196, 424, 104);
  end;
  FolderLabel := Lbl(P, 56, 214, 'Folder', '', 9, ColDim);
  FolderEdit := TNewEdit.Create(WizardForm);
  FolderEdit.Parent := P;
  FolderEdit.Left := ScaleX(136);
  FolderEdit.Top := ScaleY(210);
  FolderEdit.Height := ScaleY(25);
  FolderEdit.Font.Name := 'Consolas';
  FolderEdit.Text := Dir;
  BrowseBtn := TNewButton.Create(WizardForm);
  BrowseBtn.Parent := P;
  BrowseBtn.Caption := 'Browse...';
  BrowseBtn.Width := ScaleX(80);
  BrowseBtn.Height := ScaleY(25);
  BrowseBtn.Left := ScaleX(448) - BrowseBtn.Width;
  BrowseBtn.Top := FolderEdit.Top;
  BrowseBtn.OnClick := @BrowseClick;
  if IsUpdate then begin
    FolderEdit.ReadOnly := True;
    FolderEdit.Width := ScaleX(448) - FolderEdit.Left;
  end else
    FolderEdit.Width := BrowseBtn.Left - ScaleX(10) - FolderEdit.Left;
  FolderHint := Lbl(P, 136, 238, 'Set by the current install', '', 8, ColFaint);
  ShortLabel := Lbl(P, 56, RowShort + 2, 'Shortcuts', '', 9, ColDim);
  StartChk := TNewCheckBox.Create(WizardForm);
  StartChk.Parent := P;
  StartChk.Caption := 'Start Menu';
  StartChk.Left := ScaleX(136);
  StartChk.Top := ScaleY(RowShort);
  StartChk.Width := ScaleX(100);
  StartChk.Height := ScaleY(18);
  StartChk.Checked := CmdTask('startmenu', True);
  DeskChk := TNewCheckBox.Create(WizardForm);
  DeskChk.Parent := P;
  DeskChk.Caption := 'Desktop';
  DeskChk.Left := ScaleX(246);
  DeskChk.Top := ScaleY(RowShort);
  DeskChk.Width := ScaleX(100);
  DeskChk.Height := ScaleY(18);
  DeskChk.Checked := CmdTask('desktopicon', PreviousDesktopChoice);
  SpaceLabel := Lbl(P, 56, RowShort + 28, SpaceLine, '', 8, ColFaint);
  if IsUpdate then
    KeepLabel := Lbl(P, 56, RowShort + 28, 'Keeps wallet data', '', 8, ColFaint)
  else
    KeepLabel := Lbl(P, 56, RowShort + 28, 'Nothing outside this user', '', 8, ColFaint);
  KeepLabel.Left := ScaleX(448) - KeepLabel.Width;
  ShowSheet(False);
end;

procedure BuildInstalling;
var
  P: TNewNotebookPage;
  G: TNewProgressBar;
begin
  P := WizardForm.InstallingPage;
  G := WizardForm.ProgressGauge;
  G.Visible := False;
  WizardForm.StatusLabel.Font.Size := 10;
  WizardForm.StatusLabel.Top := WizardForm.StatusLabel.Top + ScaleY(40);
  WizardForm.FilenameLabel.Font.Name := 'Consolas';
  WizardForm.FilenameLabel.Font.Size := 9;
  WizardForm.FilenameLabel.StyleElements := WizardForm.FilenameLabel.StyleElements - [seFont];
  WizardForm.FilenameLabel.Font.Color := ColDim;
  WizardForm.FilenameLabel.Top := WizardForm.StatusLabel.Top + ScaleY(24);
  { The stock gauge takes the style's colour; a gold bar is two flat bitmaps. }
  BarTrack := Solid(P, ColTrack, G.Left, WizardForm.FilenameLabel.Top + ScaleY(44), G.Width - ScaleX(48), ScaleY(6));
  BarFill := Solid(P, ColGold, BarTrack.Left, BarTrack.Top, 0, BarTrack.Height);
  PctLabel := Lbl(P, 0, 0, '0%', 'Consolas', 9, ColDim);
  PctLabel.Left := BarTrack.Left + BarTrack.Width + ScaleX(12);
  PctLabel.Top := BarTrack.Top - ScaleY(5);
  InstNote := Lbl(P, 0, 0, 'Wallet data is not touched.', '', 9, ColFaint);
  InstNote.Left := BarTrack.Left;
  InstNote.Top := BarTrack.Top + ScaleY(36);
end;

procedure BuildFinished;
var
  P: TNewNotebookPage;
begin
  P := WizardForm.FinishedPage;
  WizardForm.FinishedHeadingLabel.Visible := False;
  WizardForm.FinishedLabel.Visible := False;
  WizardForm.WizardBitmapImage2.Visible := False;
  WizardForm.RunList.Visible := False;
  FinIcon := Png(P, 'icon.png', 40, 44, 56, 56);
  if IsUpdate then
    FinHead := Lbl(P, 40, 110, 'Updated', HeadFont, 21, ColText)
  else
    FinHead := Lbl(P, 40, 110, 'Installed', HeadFont, 21, ColText);
  FinSub := Lbl(P, 40, 152, 'Epic Cash Desktop {#AppVersion} is ready.', '', 10, ColDim);
  FinBody := Lbl(P, 40, 186, '', '', 10, ColDim);
end;

{ ---------- events ---------- }

function InitializeSetup: Boolean;
begin
  IsUpdate := RegQueryStringValue(HKCU, UninstKey, 'DisplayVersion', InstalledVersion) and (InstalledVersion <> '');
  { Montserrat for the headings, private to this process; Segoe UI Semibold if the load fails. }
  HeadFont := 'Segoe UI Semibold';
  try
    ExtractTemporaryFile(FontFile);
    FontPath := ExpandConstant('{tmp}\' + FontFile);
    if AddFontResourceEx(FontPath, FR_PRIVATE, 0) > 0 then
      HeadFont := 'Montserrat SemiBold';
  except
    Log('Montserrat not loaded: ' + GetExceptionMessage);
  end;
  Result := True;
end;

procedure DeinitializeSetup;
begin
  if HeadFont = 'Montserrat SemiBold' then
    RemoveFontResourceEx(FontPath, FR_PRIVATE, 0);
end;

procedure InitializeWizard;
begin
  LoadBackImages;
  SetBack(255);
  WizardForm.PageNameLabel.Font.Name := HeadFont;
  WizardForm.PageNameLabel.Font.Size := 14;
  WizardForm.PageNameLabel.Font.Style := [];
  WizardForm.PageDescriptionLabel.Font.Size := 9;
  WizardForm.PageDescriptionLabel.StyleElements := WizardForm.PageDescriptionLabel.StyleElements - [seFont];
  WizardForm.PageDescriptionLabel.Font.Color := ColDim;
  FixHeader(WizardForm.PageNameLabel, WizardForm.PageDescriptionLabel);
  SizeButtons;
  WizardForm.KeyPreview := True;
  WizardForm.OnKeyDown := @WizardKeyDown;
  BuildWelcome;
  BuildInstalling;
  BuildFinished;
  OptLink := BarLink('Options', @OptionsClick);
  CloseLink := BarLink('Close', @CloseClick);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
var
  D: String;
begin
  Result := True;
  if CurPageID = wpWelcome then begin
    if not IsUpdate then begin
      D := Trim(FolderEdit.Text);
      if (Length(D) < 3) or (D[2] <> ':') or (D[3] <> '\') then begin
        ShowSheet(True);
        MsgBox('Enter a full folder path, such as ' + ExpandConstant('{%USERPROFILE}\Apps\EpicWallet') + '.', mbError, MB_OK);
        Result := False;
        exit;
      end;
      WizardForm.DirEdit.Text := D;
    end;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  S: String;
  W: Integer;
begin
  OptLink.Visible := CurPageID = wpWelcome;
  CloseLink.Visible := CurPageID = wpFinished;
  case CurPageID of
    wpWelcome: begin
      SetBack(255);
      if IsUpdate then
        WizardForm.NextButton.Caption := 'Update'
      else
        WizardForm.NextButton.Caption := 'Install';
      WelPath.Caption := WizardForm.DirEdit.Text;
      if SpaceLabel.Caption = '' then
        SpaceLabel.Caption := SpaceLine;
    end;
    wpInstalling: begin
      SetBack(DimOpacity);
      if IsUpdate then begin
        WizardForm.PageNameLabel.Caption := 'Updating';
        WizardForm.PageDescriptionLabel.Caption := 'Replacing files';
      end else begin
        WizardForm.PageNameLabel.Caption := 'Installing';
        WizardForm.PageDescriptionLabel.Caption := 'Copying files';
      end;
    end;
    wpFinished: begin
      SetBack(255);
      S := '';
      if WantStartMenu then
        S := 'Start Menu';
      if WantDesktop then begin
        if S <> '' then S := S + ', ';
        S := S + 'Desktop';
      end;
      if S = '' then
        FinBody.Caption := 'No shortcuts.'
      else
        FinBody.Caption := 'Shortcuts: ' + S + '.';
      WizardForm.RunList.Visible := False;
      WizardForm.CancelButton.Visible := False;
      WizardForm.NextButton.Caption := 'Open Epic Cash Desktop';
      W := WizardForm.CalculateButtonWidth(['Open Epic Cash Desktop']) + ScaleX(24);
      WizardForm.NextButton.Left := WizardForm.NextButton.Left + WizardForm.NextButton.Width - W;
      WizardForm.NextButton.Width := W;
    end;
  end;
end;

procedure CurInstallProgressChanged(CurProgress, MaxProgress: Integer);
begin
  if MaxProgress > 0 then begin
    BarFill.Width := MulDiv(BarTrack.Width, CurProgress, MaxProgress);
    PctLabel.Caption := IntToStr(MulDiv(100, CurProgress, MaxProgress)) + '%';
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    Log('Installing to ' + ExpandConstant('{app}') + ' (update: ' + IntToStr(Ord(IsUpdate)) + ')');
end;

{ ---------- uninstaller ---------- }

procedure InitializeUninstallProgressForm;
var
  F: String;
  Note: TNewStaticText;
  B: TNewProgressBar;
  C: TNewButton;
  Right, Mid: Integer;
begin
  { The font the app itself ships, if it is still there. }
  F := ExpandConstant('{app}\data\flutter_assets\assets\fonts\Montserrat-SemiBold.ttf');
  if FileExists(F) and (AddFontResourceEx(F, FR_PRIVATE, 0) > 0) then
    UninstallProgressForm.PageNameLabel.Font.Name := 'Montserrat SemiBold'
  else
    UninstallProgressForm.PageNameLabel.Font.Name := 'Segoe UI Semibold';
  UninstallProgressForm.PageNameLabel.Font.Size := 14;
  UninstallProgressForm.PageNameLabel.Font.Style := [];
  UninstallProgressForm.PageNameLabel.Caption := 'Uninstalling';
  UninstallProgressForm.PageDescriptionLabel.Font.Size := 9;
  UninstallProgressForm.PageDescriptionLabel.Caption := 'Removing files';
  UninstallProgressForm.PageDescriptionLabel.StyleElements := UninstallProgressForm.PageDescriptionLabel.StyleElements - [seFont];
  UninstallProgressForm.PageDescriptionLabel.Font.Color := ColDim;
  FixHeader(UninstallProgressForm.PageNameLabel, UninstallProgressForm.PageDescriptionLabel);
  UninstallProgressForm.StatusLabel.Font.Size := 10;
  UninstallProgressForm.StatusLabel.Top := UninstallProgressForm.StatusLabel.Top + ScaleY(40);
  C := UninstallProgressForm.CancelButton;
  Right := C.Left + C.Width;
  Mid := C.Top + C.Height div 2;
  C.SetBounds(Right - ScaleX(BtnW), Mid - ScaleY(BtnH) div 2, ScaleX(BtnW), ScaleY(BtnH));
  B := UninstallProgressForm.ProgressBar;
  B.Top := UninstallProgressForm.StatusLabel.Top + ScaleY(44);
  Note := TNewStaticText.Create(UninstallProgressForm);
  Note.Parent := UninstallProgressForm.InstallingPage;
  Note.Left := UninstallProgressForm.ProgressBar.Left;
  Note.Top := UninstallProgressForm.ProgressBar.Top + UninstallProgressForm.ProgressBar.Height + ScaleY(16);
  Note.Font.Size := 9;
  Note.StyleElements := Note.StyleElements - [seFont];
  Note.Font.Color := ColFaint;
  Note.Caption := 'Wallet data is not touched.';
end;
