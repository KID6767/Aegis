# Aegis – Grepolis Remaster: BUILD XXL
# Wersja buildu: 1.0.0-xxl
# Cel: zero czerwieni, pełny komplet plików, ZIP + SHA256 + git push (w try/catch).

$ErrorActionPreference = 'Stop'

function Log([string]$msg){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Write-Host "$ts  $msg" -ForegroundColor Green }
function Warn([string]$msg){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Write-Host "$ts  $msg" -ForegroundColor Yellow }
function Err([string]$msg){ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Write-Host "$ts  $msg" -ForegroundColor Red }

# ─────────────────────────────────────────────────────────────────────────────
# 1) ŚCIEŻKI I WERSJE
# ─────────────────────────────────────────────────────────────────────────────
$Root     = Split-Path -Parent $PSCommandPath
$Assets   = Join-Path $Root 'assets'
$Branding = Join-Path $Assets 'branding'
$Themes   = Join-Path $Assets 'themes'
$Fx       = Join-Path $Assets 'fx'
$Users    = Join-Path $Root 'userscripts'
$Docs     = Join-Path $Root 'docs'
$Dist     = Join-Path $Root 'dist'

$Version  = '1.0.0'
$ZipName  = "Aegis-$Version.zip"
$ZipPath  = Join-Path $Dist $ZipName
$Tmp      = Join-Path $env:TEMP ("AegisBuild_" + [guid]::NewGuid())
New-Item -ItemType Directory -Force -Path $Tmp | Out-Null

# ─────────────────────────────────────────────────────────────────────────────
# 2) KATALOGI (tworzenie/pewność)
# ─────────────────────────────────────────────────────────────────────────────
$dirs = @($Assets,$Branding,$Themes,$Fx,$Users,$Docs,$Dist)
foreach($d in $dirs){ if(!(Test-Path $d)){ New-Item -ItemType Directory -Path $d | Out-Null } }
Log "assets ✓"; Log "themes ✓"; Log "userscripts ✓"; Log "docs ✓"; Log "dist ✓"

# ─────────────────────────────────────────────────────────────────────────────
# 3) WALIDACJA PODSTAWOWYCH ASSETÓW
# ─────────────────────────────────────────────────────────────────────────────
$Logo    = Join-Path $Branding 'logo_aegis.png'
$Smoke   = Join-Path $Branding 'smoke.svg'
$ThemesF = @('classic.css','remaster.css','pirate.css','dark.css') | ForEach-Object { Join-Path $Themes $_ }
$UserJs  = Join-Path $Users 'grepolis-aegis.user.js'

$missing = @()
if(!(Test-Path $Logo)){   $missing += $Logo }
if(!(Test-Path $Smoke)){  $missing += $Smoke }
foreach($t in $ThemesF){ if(!(Test-Path $t)){ $missing += $t } }
if(!(Test-Path $UserJs)){ $missing += $UserJs }

if($missing.Count -gt 0){
  Err "Brakujące pliki:"
  $missing | ForEach-Object { Err " - $_" }
  throw "Brakujące pliki – przerwano build."
}

# ─────────────────────────────────────────────────────────────────────────────
# 4) KOPIOWANIE DO TMP (bez konfliktu z samym ZIPem)
# ─────────────────────────────────────────────────────────────────────────────
try{
  # Kopiujemy wszystko z repo, ale NIE kopiujemy starego ZIPa do TMP,
  # oraz nie kopiujemy folderu .git, dist
  Get-ChildItem -Path $Root -Recurse -File -Force | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and
    $_.FullName -notmatch '\\dist\\'  -and
    $_.Name -ne $ZipName
  } | ForEach-Object {
    $rel = $_.FullName.Substring($Root.Length).TrimStart('\')
    $dest = Join-Path $Tmp $rel
    $dir = Split-Path -Parent $dest
    if(!(Test-Path $dir)){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
  }
  Log "copy → tmp ✓"
}catch{
  Err "Copy error: $($_.Exception.Message)"
  throw
}

# ─────────────────────────────────────────────────────────────────────────────
# 5) ZIP + SHA256
# ─────────────────────────────────────────────────────────────────────────────
try{
  if(Test-Path $ZipPath){ Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::CreateFromDirectory($Tmp, $ZipPath)
  $sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $ZipPath).Hash
  Log "ZIP: $ZipPath"
  Log "SHA-256: $sha"
  Log "dist ✓"
}catch{
  Err "ZIP error: $($_.Exception.Message)"
  throw
}

# ─────────────────────────────────────────────────────────────────────────────
# 6) GIT ADD/COMMIT/PUSH (best-effort)
# ─────────────────────────────────────────────────────────────────────────────
try{
  Set-Location $Root
  git add -A | Out-Null
  $msg = "Build $Version (assets+themes+userscript+docs+zip)"
  git commit -m $msg | Out-Null
  git push | Out-Null
  Log "git push ✓"
}catch{
  Warn "git step skipped: $($_.Exception.Message)"
}

# ─────────────────────────────────────────────────────────────────────────────
# 7) CLEANUP
# ─────────────────────────────────────────────────────────────────────────────
try{
  Remove-Item -Recurse -Force -LiteralPath $Tmp -ErrorAction SilentlyContinue
}catch{}

Log "DONE ✓"
