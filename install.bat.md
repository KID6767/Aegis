@echo off

setlocal

cd /d "%~dp0"

echo == Aegis Installer (BAT) ==

powershell -NoProfile -ExecutionPolicy Bypass -File ".\\install.ps1"

if %ERRORLEVEL% NEQ 0 (

&nbsp; echo PowerShell install.ps1 zwrocil blad %ERRORLEVEL%

&nbsp; pause

&nbsp; exit /b %ERRORLEVEL%

)

echo == DONE ==

pause



