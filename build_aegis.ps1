# Aegis – build 1.0.1
$ErrorActionPreference='Stop'
function Log($m){ $t=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); Write-Host "$t  $m" -ForegroundColor Green }
$Root = Split-Path -Parent $PSCommandPath
if(-not $Root){ $Root=(Get-Location).Path }

$Dist   = Join-Path $Root 'dist'
$Assets = Join-Path $Root 'assets'
$Users  = Join-Path $Root 'userscripts'
$Docs   = Join-Path $Root 'docs'
$ZipOut = Join-Path $Dist 'Aegis-1.0.1.zip'

New-Item -ItemType Directory -Force -Path $Dist | Out-Null
$UserSrc = Join-Path $Users 'grepolis-aegis.user.js'
$UserDst = Join-Path $Dist  'grepolis-aegis.user.js'
if (Test-Path $UserSrc) { Copy-Item $UserSrc $UserDst -Force }

try {
  Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
  if(Test-Path $ZipOut){ Remove-Item $ZipOut -Force -ErrorAction SilentlyContinue }
  $tmp = Join-Path $Root ('_pkg_'+([Guid]::NewGuid().ToString('N')))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  foreach($d in @('assets','userscripts','docs','dist')){ $p = Join-Path $Root $d; if(Test-Path $p){ Copy-Item $p -Destination $tmp -Recurse } }
  [IO.Compression.ZipFile]::CreateFromDirectory($tmp, $ZipOut)
  Remove-Item $tmp -Recurse -Force
  Log ("ZIP: " + $ZipOut)
  Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $ZipOut).Hash)
} catch { Write-Host ("ZIP ERR: "+$_.Exception.Message) -ForegroundColor Red }
