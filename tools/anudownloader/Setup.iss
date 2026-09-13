#define MyAppName "AnuDownloader"
#define MyAppVersion "2.1.2"
#define MyAppPublisher "Anubis"
#define MyAppExeName "AnuDownloader.exe"

[Setup]
AppId={{9F2C7C3E-6B7C-4E5A-9C3D-8B1F6A2D0E11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}
OutputBaseFilename=AnuDownloader-Setup
OutputDir=.
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
SetupIconFile=AnuDownloader.ico
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Masaustune kisayol olustur"; GroupDescription: "Ek kisayollar:"

[Files]
Source: "AnuDownloader.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "AnuDownloader.ico"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{#MyAppName} Kaldir"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{#MyAppName} baslat"; Flags: nowait postinstall
