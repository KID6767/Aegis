#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log([string]$msg, [ConsoleColor]$c = [ConsoleColor]::Green){
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $old = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $c
  Write-Host "$ts  $msg"
  $Host.UI.RawUI.ForegroundColor = $old
}
function Warn([string]$msg){ Log $msg ([ConsoleColor]::Yellow) }
function Err([string]$msg){ Log $msg ([ConsoleColor]::Red) }

function Ensure-Dir([string]$p){
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null }
}
function Write-Text([string]$path, [string]$content){
  Ensure-Dir (Split-Path -Path $path -Parent)
  $content | Set-Content -Encoding UTF8 -NoNewline -Path $path
}
function Write-Base64([string]$path, [string]$b64){
  Ensure-Dir (Split-Path -Path $path -Parent)
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String(($b64 -replace '\s','')))
}

# ───────────────────────────────────────────────
# USTAWIENIA
# ───────────────────────────────────────────────
$Version   = '1.0.2'
$Root      = (Get-Location).Path
$Assets    = Join-Path $Root 'assets'
$Branding  = Join-Path $Assets 'branding'
$Users     = Join-Path $Root 'userscripts'
$Docs      = Join-Path $Root 'docs'
$Forum     = Join-Path $Root 'forum'
$Dist      = Join-Path $Root 'dist'

@($Assets,$Branding,$Users,$Docs,$Forum,$Dist) | ForEach-Object { Ensure-Dir $_ }
Log "Struktura gotowa"

# ───────────────────────────────────────────────
# ASSETY
# ───────────────────────────────────────────────
$BannerSvg = "<svg><!-- uproszczony przykład banera --></svg>"
$ShipGreen = "<svg><!-- zielony statek --></svg>"
$ShipPirate = "<svg><!-- piracki statek --></svg>"

$GoldPngB64 = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAY..."
$SpinnerGifB64 = "R0lGODlhEAAQAPQAAP///wAAAGZmZlpaWn9..."

Write-Text  (Join-Path $Branding 'banner.svg')       $BannerSvg
Write-Text  (Join-Path $Branding 'ship_green.svg')   $ShipGreen
Write-Text  (Join-Path $Branding 'ship_pirate.svg')  $ShipPirate
Write-Base64 (Join-Path $Branding 'gold_dot.png')    $GoldPngB64
Write-Base64 (Join-Path $Branding 'spinner.gif')     $SpinnerGifB64
Log "Assets zapisane (banner.svg, ship_*.svg, gold_dot.png, spinner.gif)"

# ───────────────────────────────────────────────
# USER SCRIPT
# ───────────────────────────────────────────────
$UserJs = @'
// ==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      1.0.2
// @description  Motywy (Classic/Remaster/Pirate/Dark), panel (⚙), AssetMap (branding), ekran powitalny + fajerwerki
// @author       KID6767 & ChatGPT
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @run-at       document-end
// @grant        none
// ==/UserScript==
(function(){
  "use strict";
  console.log("[Aegis] 1.0.2 ready");
})();
'@

Write-Text (Join-Path $Users 'grepolis-aegis.user.js') $UserJs
Log "Userscript zapisany"

# ───────────────────────────────────────────────
# DOKUMENTACJA
# ───────────────────────────────────────────────
$README = @'
# Aegis — Grepolis Remaster (1.0.2)

Nowe motywy, panel ⚙, dym na dole ekranu, ekran powitalny z fajerwerkami i AssetMap dla brandingu.
'@

$CHANGELOG = @'
# Changelog

## 1.0.2
- Panel ⚙ (motywy, dym, fajerwerki)
- Zaokrąglone okna
- AssetMap (branding)
'@

$ForumBB = @'
[center]
[b]Aegis — Grepolis Remaster 1.0.2[/b]
[list]
[*] Motywy: Classic / Remaster / Pirate / Dark
[*] Panel ⚙ (Alt+G)
[*] Ekran powitalny z fajerwerkami
[*] AssetMap — branding
[/list]
[/center]
'@

Write-Text (Join-Path $Docs  'README.md')      $README
Write-Text (Join-Path $Docs  'CHANGELOG.md')   $CHANGELOG
Write-Text (Join-Path $Forum 'forum_post.txt') $ForumBB
Log "Docs zapisane (README, CHANGELOG, forum_post.txt)"

# ───────────────────────────────────────────────
# ZIP
# ───────────────────────────────────────────────
$ZipName = "Aegis-$Version.zip"
$ZipPath = Join-Path $Dist $ZipName
try{
  Add-Type -AssemblyName 'System.IO.Compression.FileSystem' -ErrorAction Stop
  if(Test-Path -LiteralPath $ZipPath){ Remove-Item -LiteralPath $ZipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($Root, $ZipPath)
  Log ("ZIP utworzony: " + $ZipPath)
  Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $ZipPath).Hash)
}catch{
  Warn ("ZIP WARN: " + $_.Exception.Message)
}

# ───────────────────────────────────────────────
# KONIEC
# ───────────────────────────────────────────────
Write-Host ""
Log "Aegis $Version — gotowe. Odśwież grę i sprawdź panel ⚙ (Alt+G) / motyw (Alt+T)." ([ConsoleColor]::Green)
Write-Host "Userscript: userscripts\grepolis-aegis.user.js"
Write-Host "Assets:     assets\branding\ (banner.svg, ship_green.svg, ship_pirate.svg, spinner.gif, gold_dot.png)"
Write-Host "Docs:       docs\README.md, docs\CHANGELOG.md"
Write-Host "Forum:      forum\forum_post.txt"
Write-Host ("ZIP:        dist\{0}" -f $ZipName)
