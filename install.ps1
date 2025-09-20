# Aegis installer wrapper
$ErrorActionPreference='Stop'
function Log([string]$m){ $ts=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Write-Host "$ts  $m" -ForegroundColor Cyan }
$Root = Split-Path -Parent $PSCommandPath
if(-not $Root){ $Root = (Get-Location).Path }
Set-Location $Root
Log "== Aegis Installer =="
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'build_aegis.ps1')
