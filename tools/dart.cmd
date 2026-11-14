@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0dart.ps1" %*
exit /b %ERRORLEVEL%
