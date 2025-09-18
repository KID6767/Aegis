@echo off
powershell -Command "Compress-Archive -Path * -DestinationPath Aegis-0.3-complete.zip -Force"
echo [*] Spakowano do: Aegis-0.3-complete.zip
pause
