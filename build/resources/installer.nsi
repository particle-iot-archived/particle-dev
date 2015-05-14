Name "Particle IDE"
OutFile ${OUT_FILE}
InstallDir "$PROGRAMFILES\Particle Dev"

LicenseData "..\..\LICENSE"

Page license
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

Section "Particle Dev (required)"
  SectionIn RO
  SetOutPath $INSTDIR

  RMDir /r "$INSTDIR"
  File /r "\\?\${SOURCE}\*.*"

  CreateShortCut "$DESKTOP\Particle Dev.lnk" "$INSTDIR\atom.exe" ""

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ParticleDev" "DisplayName" "Particle Dev"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ParticleDev" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ParticleDev" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
SectionEnd

Section "Start Menu Shortcuts"
  CreateDirectory "$SMPROGRAMS\Particle Dev"
  CreateShortcut "$SMPROGRAMS\Particle Dev\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortcut "$SMPROGRAMS\Particle Dev\Particle Dev.lnk" "$INSTDIR\atom.exe" "" "$INSTDIR\atom.exe" 0
SectionEnd

Section "Uninstall"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ParticleDev"

  Delete $INSTDIR\*

  Delete "$DESKTOP\Particle Dev.lnk"

  Delete "$SMPROGRAMS\Particle Dev\*.*"

  RMDir /r "$SMPROGRAMS\Particle Dev"
  RMDir /r "$INSTDIR"
SectionEnd
