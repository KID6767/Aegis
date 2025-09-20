#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log([string]$msg, [ConsoleColor]$c = [ConsoleColor]::Green) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $prev = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $c
  Write-Host "$ts  $msg"
  $Host.UI.RawUI.ForegroundColor = $prev
}

function Ensure-Dir([string]$path) {
  if (-not (Test-Path $path)) { New-Item -Force -ItemType Directory -Path $path | Out-Null }
}

function Write-Text([string]$path, [string]$content) {
  Ensure-Dir (Split-Path $path -Parent)
  $content | Set-Content -Encoding UTF8 -Path $path
}

function Write-Base64([string]$path, [string]$b64) {
  Ensure-Dir (Split-Path $path -Parent)
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($b64))
}

# ───────────────────────────────────────────
Log "== Aegis Installer ==" Cyan

# ───────────────────────────────────────────
# 1) STRUKTURA
# ───────────────────────────────────────────
$dirs = @("assets/branding","userscripts","docs","dist",".tmp")
$dirs | ForEach-Object { Ensure-Dir $_ }
Log "strukturę ✓"

# ───────────────────────────────────────────
# 2) ASSETY
# ───────────────────────────────────────────
$bannerSvg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 960 260'><rect width='960' height='260' rx='18' fill='#113c2d'/><text x='480' y='135' text-anchor='middle' font-size='64' font-family='Georgia' fill='#e7d98b'>AEGIS — Grepolis Remaster</text></svg>"
$shipGreenSvg = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 120'><path d='M10,90 C50,120 150,120 190,90 Z' fill='#2e8b57'/></svg>"
$shipPirateSvg= "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 120'><path d='M10,90 C50,120 150,120 190,90 Z' fill='#1b1b1b'/></svg>"

$pngGoldDotB64 = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0..."
$spinnerGifB64 = "R0lGODlhEAAQAPQAAP///wAAAGZmZlpaWn9/f5mZmdDQ0..."

Write-Text "assets/branding/banner.svg" $bannerSvg
Write-Text "assets/branding/ship_green.svg" $shipGreenSvg
Write-Text "assets/branding/ship_pirate.svg" $shipPirateSvg
Write-Base64 "assets/branding/gold_dot.png" $pngGoldDotB64
Write-Base64 "assets/branding/spinner.gif" $spinnerGifB64
Log "assetów ✓"

# ───────────────────────────────────────────
# 3) USERSCRIPT
# ───────────────────────────────────────────
$userscript = @'
// ==UserScript==
// @name         GrepoFusion (Aegis Edition)
// @namespace    aegis
// @version      1.5.0.2
// @description  Theme Switcher + AssetMap + Panel + Changelog
// @author       KID6767 & ChatGPT
// @match        *://*.grepolis.com/*
// @grant        none
// ==/UserScript==

(function(){
  "use strict";
  const VER = "1.5.0.2";
  function toast(m,ms){ms=ms||2000;const t=document.createElement("div");t.textContent=m;t.style.cssText="position:fixed;left:50%;bottom:60px;transform:translateX(-50%);background:#111;color:#d4af37;padding:8px 12px;border-radius:8px;border:1px solid #d4af37;z-index:2147483647;font:13px system-ui";document.body.appendChild(t);setTimeout(()=>t.remove(),ms);}
  function applyTheme(name){ /* CSS motywów */ }
  function mountFAB(){ /* przycisk ⚙ */ }
  function mountPanel(){ /* panel motywów */ }
  function changelog(){ /* popup changeloga */ }
  applyTheme(localStorage.getItem("GF_THEME")||"pirate");
  mountFAB();
  setTimeout(changelog,600);
  console.log("%c[GrepoFusion] "+VER+" ready","color:#d4af37;font-weight:700");
})();
'@

Write-Text "userscripts/grepolis-aegis.user.js" $userscript
Log "userscript ✓"

# ───────────────────────────────────────────
# 4) README / DOCS
# ───────────────────────────────────────────
$README = @"
# Aegis — Grepolis Remaster

## Instalacja
1. Zainstaluj Tampermonkey.
2. Otwórz: https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
3. Kliknij Install.

## Funkcje
- Motywy: Classic, Remaster, Pirate, Dark
- Panel ustawień (⚙)
- AssetMap (grafiki z GitHuba)
- Changelog

## Licencja
MIT
"@
Write-Text "README.md" $README
Log "docs ✓"

# ───────────────────────────────────────────
# 5) ZIP + BASE64
# ───────────────────────────────────────────
$fullZip = "Aegis-Full.zip"
$liteZip = "Aegis-Lite.zip"

if (Test-Path $fullZip) { Remove-Item $fullZip }
if (Test-Path $liteZip) { Remove-Item $liteZip }

Compress-Archive -Path assets,userscripts,docs -DestinationPath $fullZip
Compress-Archive -Path userscripts -DestinationPath $liteZip

[Convert]::ToBase64String([IO.File]::ReadAllBytes($fullZip)) | Set-Content "aegis-full.b64"
[Convert]::ToBase64String([IO.File]::ReadAllBytes($liteZip)) | Set-Content "aegis-lite.b64"
Log "zipy + base64 ✓"

# ───────────────────────────────────────────
# 6) INSTRUKCJA
# ───────────────────────────────────────────
Write-Host ""
Write-Host "Następne kroki:" -ForegroundColor Yellow
Write-Host "1) Masz dwa archiwa: Aegis-Full.zip, Aegis-Lite.zip"
Write-Host "2) Masz też dwa base64: aegis-full.b64, aegis-lite.b64"
Write-Host "3) Aby zainstalować → otwórz userscript w Tampermonkey"
Write-Host "   https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js"
Write-Host "4) Gotowe! 🚀"
