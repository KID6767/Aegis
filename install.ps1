Write-Host "== Aegis Installer ==" -ForegroundColor Cyan
$Here = Split-Path -Parent $PSCommandPath
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Here 'build_aegis.ps1')
Write-Host ("Banner SVG: " + (Join-Path $Here 'assets/branding/banner.svg'))
Write-Host "DONE ✓" -ForegroundColor Green
