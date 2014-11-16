Name "Spark IDE"
OutFile ${OUT_FILE}
InstallDir "$PROGRAMFILES\Spark Dev"

Page license
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

Section "Spark Dev (required)"
  SectionIn RO
  SetOutPath $INSTDIR

  File /r "\\?\${SOURCE}\*.*"

  CreateShortCut "$DESKTOP\Spark Dev.lnk" "$INSTDIR\atom.exe" ""

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkDev" "DisplayName" "Spark Dev"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkDev" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkDev" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkDev" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
SectionEnd

Section "Start Menu Shortcuts"
  CreateDirectory "$SMPROGRAMS\Spark Dev"
  CreateShortcut "$SMPROGRAMS\Spark Dev\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortcut "$SMPROGRAMS\Spark Dev\Spark Dev.lnk" "$INSTDIR\atom.exe" "" "$INSTDIR\atom.exe" 0
SectionEnd

Section "Uninstall"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkDev"

  Delete $INSTDIR\*

  Delete "$DESKTOP\Spark Dev.lnk"

  Delete "$SMPROGRAMS\Spark Dev\*.*"

  RMDir "$SMPROGRAMS\Spark Dev"
  RMDir "$INSTDIR"
SectionEnd
