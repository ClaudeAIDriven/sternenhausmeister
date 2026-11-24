; Sternenhausmeister - NSIS-Installer (B-02)
; Aufruf: makensis installer.nsi   (erwartet build/Sternenhausmeister.exe und .pck)
Unicode true
!define APP "Sternenhausmeister"
!define VERSION "0.1.0"
!define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP}"

Name "${APP}"
OutFile "build\${APP}-Setup.exe"
InstallDir "$PROGRAMFILES64\${APP}"
InstallDirRegKey HKLM "Software\${APP}" "InstallDir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma

!include "MUI2.nsh"
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_TITLE "Fast fertig"
!define MUI_FINISHPAGE_TEXT "Mehrspieler: Wer ein Spiel hostet, muss in der Windows-Firewall beim ersten Start den Zugriff erlauben (privates Netzwerk) und UDP-Port 24680 ggf. im Router freigeben. Wer nur beitritt, braucht nichts."
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP}.exe"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "German"

Section "Install"
  SetOutPath "$INSTDIR"
  File "build\${APP}.exe"
  File "build\${APP}.pck"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  CreateDirectory "$SMPROGRAMS\${APP}"
  CreateShortcut "$SMPROGRAMS\${APP}\${APP}.lnk" "$INSTDIR\${APP}.exe"
  CreateShortcut "$SMPROGRAMS\${APP}\Deinstallieren.lnk" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKLM "Software\${APP}" "InstallDir" "$INSTDIR"
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayName" "${APP}"
  WriteRegStr HKLM "${UNINST_KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKLM "${UNINST_KEY}" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegDWORD HKLM "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKLM "${UNINST_KEY}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\${APP}.exe"
  Delete "$INSTDIR\${APP}.pck"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$SMPROGRAMS\${APP}\${APP}.lnk"
  Delete "$SMPROGRAMS\${APP}\Deinstallieren.lnk"
  RMDir "$SMPROGRAMS\${APP}"
  DeleteRegKey HKLM "${UNINST_KEY}"
  DeleteRegKey HKLM "Software\${APP}"
SectionEnd
