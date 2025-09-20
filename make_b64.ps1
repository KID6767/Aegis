#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = $PSScriptRoot
if(-not $Root){ $Root = (Get-Location).Path }
$Zip  = Join-Path $Root "dist/Aegis-1.0.2.zip"
$B64  = Join-Path $Root "aegis.b64"

if(-not (Test-Path $Zip)){ throw "Brak ZIP: $Zip. Najpierw uruchom install.ps1." }

[byte[]]$data = [IO.File]::ReadAllBytes($Zip)
$sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $Zip).Hash
[IO.File]::WriteAllText($B64, [Convert]::ToBase64String($data))
Write-Host "ZIP:" $Zip
Write-Host "SHA-256:" $sha
Write-Host "B64:" $B64
