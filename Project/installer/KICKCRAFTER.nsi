Unicode true
SetCompressor /SOLID lzma

!define PRODUCT_NAME "INDUSTRY KICK"
!define PRODUCT_VERSION "0.7.0"
!define PRODUCT_PUBLISHER "909VOLTS"
!define VST3_SOURCE "..\outputs\INDUSTRY KICK.vst3"

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "..\outputs\INDUSTRY-KICK-Setup-Windows-x64.exe"
InstallDir "$COMMONFILES64\VST3"
InstallDirRegKey HKLM "Software\${PRODUCT_PUBLISHER}\${PRODUCT_NAME}" "VST3Path"
RequestExecutionLevel admin
ShowInstDetails show
ShowUninstDetails show
BrandingText "${PRODUCT_NAME} by ${PRODUCT_PUBLISHER}"

VIProductVersion "0.7.0.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} VST3 Installer"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "LegalCopyright" "Copyright 909VOLTS"

Page directory
Page instfiles
UninstPage uninstConfirm
UninstPage instfiles

Section "INDUSTRY KICK VST3" SecMain
  SetShellVarContext all
  RMDir /r "$INSTDIR\KICKCRAFTER.vst3"
  RMDir /r "$INSTDIR\INDUSTRY KICK.vst3"
  SetOutPath "$INSTDIR\INDUSTRY KICK.vst3"
  File /r "${VST3_SOURCE}\*.*"

  WriteRegStr HKLM "Software\${PRODUCT_PUBLISHER}\${PRODUCT_NAME}" "VST3Path" "$INSTDIR"
  WriteUninstaller "$INSTDIR\INDUSTRY-KICK-Uninstall.exe"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_NAME} VST3"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString" '"$INSTDIR\INDUSTRY-KICK-Uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetShellVarContext all
  RMDir /r "$INSTDIR\INDUSTRY KICK.vst3"
  Delete "$INSTDIR\INDUSTRY-KICK-Uninstall.exe"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
  DeleteRegKey HKLM "Software\${PRODUCT_PUBLISHER}\${PRODUCT_NAME}"
SectionEnd
