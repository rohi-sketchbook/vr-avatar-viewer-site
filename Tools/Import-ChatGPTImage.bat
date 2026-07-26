@echo off
setlocal
set "SCRIPT=%~dp0Import-ChatGPTImage.ps1"
if not exist "%SCRIPT%" (
  echo [ChatGPTImageImport] Script not found: %SCRIPT%
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
