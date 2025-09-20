Write-Host "== Aegis Installer ==" -ForegroundColor Cyan

$ErrorActionPreference = "Stop"

try {
    Write-Host " Kopiuję userscript..." -ForegroundColor Yellow
    Copy-Item ".\userscripts\grepolis-aegis.user.js" ".\" -Force

    Write-Host " Kopiuję assets..." -ForegroundColor Yellow
    Copy-Item ".\assets\branding\*" ".\" -Recurse -Force

    Write-Host " DONE ✓" -ForegroundColor Green
}
catch {
    Write-Host "Błąd podczas instalacji: $_" -ForegroundColor Red
    exit 1
}
