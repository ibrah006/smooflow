; -- Example3.iss --
; Same as Example1.iss, but creates some registry entries too and allows the end
; use to choose the install mode (administrative or non administrative).

; SEE THE DOCUMENTATION FOR DETAILS ON CREATING .ISS SCRIPT FILES!

[Setup]
AppId={{C26B6610-8C5F-4E3F-AEE7-E6AAA1E99E82}
AppName=Smooflow
AppVersion=1.6
WizardStyle=modern
DefaultDirName={autopf}\Smooflow
DefaultGroupName=Smooflow
UninstallDisplayIcon={app}\smooflow.exe
Compression=lzma2
SolidCompression=yes
OutputDir=userdocs:Inno Setup Examples Output
ChangesAssociations=yes
UserInfoPage=no
PrivilegesRequiredOverridesAllowed=dialog
SetupIconFile=C:\Users\Ibrahim\Desktop\Code\smooflow\windows\runner\resources\app_icon.ico

[Files]
Source: "C:\Users\Ibrahim\Desktop\Code\smooflow\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional icons:"; Flags: unchecked

[Icons]
Name: "{group}\Smooflow"; Filename: "{app}\smooflow.exe"

Name: "{autodesktop}\Smooflow"; Filename: "{app}\smooflow.exe"; Tasks: desktopicon

; NOTE: Most apps do not need registry entries to be pre-created. If you
; don't know what the registry is or if you need to use it, then chances are
; you don't need a [Registry] section.

[Run]
Filename: "{app}\smooflow.exe"; Description: "Launch Smooflow"; Flags: nowait postinstall skipifsilent

[Registry]
; Create "Software\Ibrahim\Smooflow" keys under CURRENT_USER or
; LOCAL_MACHINE depending on administrative or non administrative install
; mode. The flags tell it to always delete the "Smooflow" key upon
; uninstall, and delete the "My Company" key if there is nothing left in it.
Root: HKA; Subkey: "Software\My Company"; Flags: uninsdeletekeyifempty
Root: HKA; Subkey: "Software\My Company\Smooflow"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\My Company\Smooflow\Settings"; ValueType: string; ValueName: "Language"; ValueData: "{language}"
; Associate .myp files with Smooflow (requires ChangesAssociations=yes)
Root: HKA; Subkey: "Software\Classes\.myp"; ValueType: string; ValueName: ""; ValueData: "MyProgramFile.myp"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\.myp\OpenWithProgids"; ValueType: string; ValueName: "MyProgramFile.myp"; ValueData: ""; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\Classes\MyProgramFile.myp"; ValueType: string; ValueName: ""; ValueData: "Smooflow File"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\Classes\MyProgramFile.myp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\smooflow.exe,0"
Root: HKA; Subkey: "Software\Classes\MyProgramFile.myp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\smooflow.exe"" ""%1"""
; HKA (and HKCU) should only be used for settings which are compatible with
; roaming profiles so settings like paths should be written to HKLM, which
; is only possible in administrative install mode.
Root: HKLM; Subkey: "Software\My Company"; Flags: uninsdeletekeyifempty; Check: IsAdminInstallMode
Root: HKLM; Subkey: "Software\My Company\Smooflow"; Flags: uninsdeletekey; Check: IsAdminInstallMode
Root: HKLM; Subkey: "Software\My Company\Smooflow\Settings"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Check: IsAdminInstallMode
; User specific settings should always be written to HKCU, which should only
; be done in non administrative install mode.
Root: HKCU; Subkey: "Software\My Company\Smooflow\Settings"; ValueType: string; ValueName: "UserName"; ValueData: "{userinfoname}"; Check: not IsAdminInstallMode
Root: HKCU; Subkey: "Software\My Company\Smooflow\Settings"; ValueType: string; ValueName: "UserOrganization"; ValueData: "{userinfoorg}"; Check: not IsAdminInstallMode

[Code]
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  // User specific pages should be skipped in administrative install mode
  Result := IsAdminInstallMode and (PageID = wpUserInfo);
end;