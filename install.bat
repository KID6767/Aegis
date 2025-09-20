@echo off
cd /d "C:\Users\macie\Documents\GitHub\Aegis"

echo == Dekodowanie base64 -> ZIP ==
certutil -decode aegis.b64 Aegis-1.0.0.zip

echo == Wypakowywanie paczki ==
powershell -Command "Expand-Archive -Path '.\Aegis-1.0.0.zip' -DestinationPath . -Force"

echo == Uruchamianie instalatora ==
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1

echo.
echo == DONE! ==
pause
