; Webglobe Mail Connector - per-user Windows installer.
; Original author: Mgr. Peter Adámek | AI konzultant
; https://ai-konzultant.sk/
; Build with Inno Setup 6: ISCC.exe installer\webglobe.iss

#define MyAppName "Webglobe Mail Connector"
#define MyAppVersion "0.9.2"
#define MyPublisher "Mgr. Peter Adámek | AI konzultant"
#define MyURL "https://ai-konzultant.sk/"

[Setup]
AppId={{F19A74D4-EC8D-4ADC-A9E9-59EA96F6D3BC}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyPublisher}
AppPublisherURL={#MyURL}
AppSupportURL={#MyURL}
AppUpdatesURL=https://github.com/aaaadamek-a11y/chatgpt-email-connector/releases
DefaultDirName={localappdata}\WebglobeMailConnector\InstallerSource
DefaultGroupName={#MyAppName}
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
UninstallDisplayName={#MyAppName} (installation files)
OutputDir=..\dist
OutputBaseFilename=Webglobe-Mail-Connector-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ShowLanguageDialog=no
; Do not delete the OS keychain, installed Python runtime or account settings on uninstall.
; This installer contains no mailbox credentials; network access is needed on first setup.

[Files]
Source: "..\NASTAVIT.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\NASTAVIT-UCET.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\NASTAVIT-ODOSIELANIE.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\windows-easy-setup.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\windows-setup.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\windows-smtp-setup.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\windows-connect.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\launch.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\server.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\account_setup.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\pop3_reader.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\smtp_sender.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\smtp_server.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\draft_store.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\sending_setup.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\send_confirmation.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\package_local.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\smtp_package_local.py"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\launch-webglobe-mcp.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\requirements.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\installer\wheelhouse\*.whl"; DestDir: "{app}\wheelhouse"; Flags: ignoreversion
Source: "..\firma.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\README.sk.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\SMTP.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\SECURITY.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\NOTICE"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autodesktop}\Webglobe Mail - Nastavenie"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -STA -ExecutionPolicy Bypass -File ""{app}\windows-easy-setup.ps1"""; WorkingDir: "{app}"

; Intentionally no [Run] step: Inno Setup RedirectionGuard can be inherited by
; PowerShell/uv launched before Setup exits, triggering WinError 448 on user-created
; junctions. Run the desktop shortcut AFTER closing Setup instead.
; We preserve Inno Setup's default RedirectionGuard protection.
