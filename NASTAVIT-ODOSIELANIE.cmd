@echo off
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0windows-smtp-setup.ps1"
exit /b %ERRORLEVEL%
