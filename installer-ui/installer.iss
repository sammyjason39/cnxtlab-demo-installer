; ConextLab NVIDIA Demo Installer - Inno Setup script
; Build with: iscc.exe installer-ui\installer.iss
; Output: installer-ui\Output\ConextLabDemoInstallerSetup.exe

#define MyAppName "ConextLab NVIDIA Demo Installer"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "ConextLab"
#define MyAppExeName "ConextLabDemoInstaller.exe"

[Setup]
AppId={{8F3C1A2E-7B4D-4E5F-9A6B-CNXTLABDEMO01}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\ConextLabDemoInstaller
DefaultGroupName=ConextLab Demo Installer
DisableProgramGroupPage=yes
OutputDir=Output
OutputBaseFilename=ConextLabDemoInstallerSetup
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Compiled UI EXE (build it first with: dotnet publish -c Release -r win-x64)
Source: "bin\Release\net8.0-windows\win-x64\publish\ConextLabDemoInstaller.exe"; DestDir: "{app}"; Flags: ignoreversion
; PowerShell scripts
Source: "..\scripts\*.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "..\scripts\lib\*.ps1"; DestDir: "{app}\scripts\lib"; Flags: ignoreversion
; Config
Source: "..\config\demo-config.json"; DestDir: "{app}\config"; Flags: ignoreversion onlyifdoesntexist
; README
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
; Empty logs folder
Source: "..\logs\.gitkeep"; DestDir: "{app}\logs"; Flags: ignoreversion

[Icons]
Name: "{group}\ConextLab Demo Installer"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall ConextLab Demo Installer"; Filename: "{uninstallexe}"
Name: "{commondesktop}\ConextLab Demo Installer"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch ConextLab Demo Installer"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
end;