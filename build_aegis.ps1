# Aegis – Build (Final)
$ErrorActionPreference = "Stop"
function Log([string]$m){ $ts=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "$ts  $m" -ForegroundColor Cyan }
function EnsureDir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Path $p | Out-Null } }

$Root   = Split-Path -Parent $PSCommandPath
$Dist   = Join-Path $Root "dist"
$Zip    = Join-Path $Dist "Aegis-1.0.0.zip"
EnsureDir $Dist

# ZIP (assets + userscripts + docs + forum)
try{
  $tmp = Join-Path $Root ("_pkg_"+[Guid]::NewGuid().ToString("N"))
  EnsureDir $tmp
  @("assets","userscripts","docs","forum") | ForEach-Object {
    $src = Join-Path $Root $_
    if(Test-Path $src){ Copy-Item $src -Destination $tmp -Recurse }
  }
  Add-Type -AssemblyName "System.IO.Compression.FileSystem"
  if(Test-Path $Zip){ Remove-Item $Zip -Force -ErrorAction SilentlyContinue }
  [IO.Compression.ZipFile]::CreateFromDirectory($tmp, $Zip)
  Remove-Item $tmp -Recurse -Force
  Log "ZIP: $Zip"
  Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $Zip).Hash)
}catch{
  Write-Host ("ZIP ERR: " + $_.Exception.Message) -ForegroundColor Red
}

# Opcjonalnie git
try{
  & git add -A | Out-Null
  & git commit -m "Aegis 1.0.0: full build (userscript+assets+docs+forum+zip)" | Out-Null
  & git push | Out-Null
  Log "git push ✓"
}catch{
  Write-Host ("GIT WARN: "+$_.Exception.Message) -ForegroundColor Yellow
}
Log "DONE ✓"