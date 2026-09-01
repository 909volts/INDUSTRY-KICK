[Setup]
AppName=INDUSTRY KICK
AppVersion=1.0
AppPublisher=909Volts
AppPublisherURL=https://909volts.gumroad.com
DefaultDirName={autopf}\INDUSTRY KICK
DefaultGroupName=INDUSTRY KICK
OutputDir=E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Distribution
OutputBaseFilename=INDUSTRY_KICK_v1.0_Setup
Compression=lzma2/ultra64
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
UninstallDisplayName=INDUSTRY KICK

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[InstallDelete]
Type: filesandordirs; Name: "{commoncf}\VST3\INDUSTRY KICK.vst3"

[Files]
Source: "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\build\KICKCRAFTER_artefacts\Release\VST3\INDUSTRY KICK.vst3\*"; DestDir: "{commoncf}\VST3\INDUSTRY KICK.vst3"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "E:\909Volts\Vsts\INDUSTRY KICK 1.0 by 909Volts\Project\build\KICKCRAFTER_artefacts\Release\Standalone\INDUSTRY KICK.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\INDUSTRY KICK"; Filename: "{app}\INDUSTRY KICK.exe"
Name: "{group}\Uninstall INDUSTRY KICK"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\INDUSTRY KICK.exe"; Description: "Avvia INDUSTRY KICK ora"; Flags: nowait postinstall skipifsilent