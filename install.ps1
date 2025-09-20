# == Aegis Installer ==
$ErrorActionPreference = 'Stop'

function Log([string]$msg){
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Write-Host "$ts  $msg" -ForegroundColor Green
}
function Err([string]$msg){
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Write-Host "$ts  $msg" -ForegroundColor Red
}

try {
  Log "== Aegis Installer =="

  # uruchom build
  & powershell -NoProfile -ExecutionPolicy Bypass -File ".\build_aegis.ps1"

  # znajdź ostatni ZIP w dist
  $dist = Join-Path $PSScriptRoot "dist"
  $latest = Get-ChildItem $dist -Filter "Aegis-*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

  if ($null -eq $latest) { throw "Brak ZIP w $dist" }

  $hash = (Get-FileHash -Algorithm SHA256 $latest.FullName).Hash
  Log "ZIP: $($latest.FullName)"
  Log "SHA-256: $hash"

  # git add/commit/push
  & git add .
  & git commit -m "Install build: $($latest.Name)"
  & git push
  Log "git push ✓"

  Log "DONE ✓"
}
catch {
  Err ("INSTALL ERR: " + $_.Exception.Message)
}
