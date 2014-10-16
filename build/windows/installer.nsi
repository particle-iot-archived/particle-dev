Name "Spark IDE"
OutFile ${OUT_FILE}
InstallDir "$PROGRAMFILES\Spark IDE"

Page license
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

Section "Spark IDE (required)"
  SectionIn RO
  SetOutPath $INSTDIR

  File /r "\\?\${SOURCE}\*.*"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkIDE" "DisplayName" "Spark IDE"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkIDE" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkIDE" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkIDE" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
SectionEnd

Section "Start Menu Shortcuts"
  CreateDirectory "$SMPROGRAMS\Spark IDE"
  CreateShortcut "$SMPROGRAMS\Spark IDE\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortcut "$SMPROGRAMS\Spark IDE\Spark IDE.lnk" "$INSTDIR\atom.exe" "" "$INSTDIR\atom.exe" 0
SectionEnd

Section "Uninstall"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\SparkIDE"

  Delete $INSTDIR\*

  Delete "$SMPROGRAMS\Spark IDE\*.*"

  RMDir "$SMPROGRAMS\Spark IDE"
  RMDir "$INSTDIR"
SectionEnd
