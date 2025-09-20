@echo off
title Aegis Installer (BAT)
color 0C
echo == Aegis Installer ==
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
