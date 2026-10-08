Unicode True
Name "QATU: El Reino Compilado"
OutFile "..\..\dist\QATU-Windows-Setup.exe"
InstallDir "$PROGRAMFILES64\QATU"
RequestExecutionLevel admin

Page directory
Page instfiles

Section "Install"
  SetOutPath "$INSTDIR"
  File "..\..\dist\windows\QATU.exe"
  File "..\..\dist\windows\QATU.pck"
  CreateDirectory "$SMPROGRAMS\QATU"
  CreateShortcut "$SMPROGRAMS\QATU\QATU.lnk" "$INSTDIR\QATU.exe"
  CreateShortcut "$DESKTOP\QATU.lnk" "$INSTDIR\QATU.exe"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

Section "Uninstall"
  Delete "$DESKTOP\QATU.lnk"
  Delete "$SMPROGRAMS\QATU\QATU.lnk"
  RMDir "$SMPROGRAMS\QATU"
  Delete "$INSTDIR\QATU.exe"
  Delete "$INSTDIR\QATU.pck"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
SectionEnd
