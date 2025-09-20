# Aegis build 1.0.0
$ErrorActionPreference = 'Stop'
function Log([string]$m){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Write-Host "$ts  $m" -ForegroundColor Green }

$Root = Split-Path -Parent $PSCommandPath
if(-not $Root){ $Root = (Get-Location).Path }
$Assets = Join-Path $Root 'assets'
$Brand  = Join-Path $Assets 'branding'
$Docs   = Join-Path $Root 'docs'
$Users  = Join-Path $Root 'userscripts'
$Dist   = Join-Path $Root 'dist'

$dirs = @($Assets,$Brand,$Docs,$Users,$Dist)
foreach($d in $dirs){ if(!(Test-Path $d)){ New-Item -ItemType Directory -Path $d | Out-Null } }

# sanity files exist
$UserJs = Join-Path $Users 'grepolis-aegis.user.js'
if(!(Test-Path $UserJs)){ throw "Brak userscripts/grepolis-aegis.user.js" }

# Copy to dist
$OutUser = Join-Path $Dist 'grepolis-aegis.user.js'
Copy-Item $UserJs $OutUser -Force
Copy-Item $Assets (Join-Path $Dist 'assets') -Recurse -Force
Copy-Item $Docs   (Join-Path $Dist 'docs')   -Recurse -Force

# Zip
$Zip = Join-Path $Root 'Aegis-1.0.0.zip'
if(Test-Path $Zip){ Remove-Item $Zip -Force -ErrorAction SilentlyContinue }
Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
[IO.Compression.ZipFile]::CreateFromDirectory($Root, $Zip)

Log ("ZIP: " + $Zip)
Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $Zip).Hash)

# Optional git
try{
  & git add -A | Out-Null
  & git commit -m ("Build 1.0.0 (userscript+docs+assets)") | Out-Null
  & git push | Out-Null
  Log "git push ✓"
}catch{
  Write-Host ("GIT WARN: " + $_.Exception.Message) -ForegroundColor Yellow
}
Log "DONE ✓"
