# install.ps1 – uproszczona wersja (tylko 1 ZIP)
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSCommandPath
$Build = Join-Path $Root 'build_aegis.ps1'

try {
  Write-Host "== Aegis Installer ==" -ForegroundColor Cyan

  if (!(Test-Path $Build)) {
    throw "Brak pliku build_aegis.ps1 w katalogu $Root"
  }

  # Odpalamy build_aegis.ps1 (to on generuje ZIPa w dist/)
  & powershell -NoProfile -ExecutionPolicy Bypass -File $Build

  # Szukamy najnowszego ZIPa w dist/
  $Dist = Join-Path $Root 'dist'
  $Zip = Get-ChildItem $Dist -Filter 'Aegis-*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1

  if ($Zip) {
    Write-Host "ZIP: $($Zip.FullName)" -ForegroundColor Green
    $Hash = (Get-FileHash -Algorithm SHA256 $Zip.FullName).Hash
    Write-Host "SHA-256: $Hash" -ForegroundColor Yellow
  } else {
    throw "Nie znaleziono paczki ZIP w $Dist"
  }

  Write-Host "DONE ✓" -ForegroundColor Green
} catch {
  Write-Host "INSTALL ERR: $($_.Exception.Message)" -ForegroundColor Red
}
