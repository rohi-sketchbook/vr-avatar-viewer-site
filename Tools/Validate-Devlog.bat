@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Validate-Devlog.ps1" %*
exit /b %ERRORLEVEL%
