# Aegis Installer (PowerShell)
# Tworzy pełną strukturę projektu + pliki

$ErrorActionPreference = "Stop"

Write-Host "== Aegis Installer ==" -ForegroundColor Cyan

# Katalogi
$dirs = @("assets/branding","userscripts","docs","forum")
foreach ($d in $dirs) {
    if (!(Test-Path $d)) { New-Item -ItemType Directory -Path $d | Out-Null }
}

# Assets (SVG + GIF przykładowe)
$banner = @'
<svg xmlns="http://www.w3.org/2000/svg" width="600" height="120">
  <rect width="100%" height="100%" fill="black"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle"
        font-size="32" fill="white">Aegis Banner</text>
</svg>
'@
$banner | Set-Content assets/branding/banner.svg -Encoding utf8

$shipGreen = @'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64">
  <circle cx="32" cy="32" r="30" fill="green"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle"
        font-size="20" fill="white">G</text>
</svg>
'@
$shipGreen | Set-Content assets/branding/ship_green.svg -Encoding utf8

$shipPirate = @'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64">
  <circle cx="32" cy="32" r="30" fill="red"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle"
        font-size="20" fill="white">P</text>
</svg>
'@
$shipPirate | Set-Content assets/branding/ship_pirate.svg -Encoding utf8

# Userscript
$userscript = @'
// ==UserScript==
// @name        Aegis Grepolis Remaster
// @namespace   aegis
// @version     1.0.1
// @description Skórki, panel, assetmap
// @match       *://*.grepolis.com/*
// @grant       none
// ==/UserScript==

(function() {
  console.log("Aegis loaded ✅");
  document.body.style.border = "5px solid limegreen";
})();
'@
$userscript | Set-Content userscripts/aegis.user.js -Encoding utf8

# README
$readme = @'
# Aegis – Grepolis Remaster 2025

Pełen pakiet modyfikacji:
- motywy: Classic, Remaster, Pirate, Dark
- panel konfiguracji
- ekran powitalny
- AssetMap
'@
$readme | Set-Content README.md -Encoding utf8

# CHANGELOG
$changelog = @'
## 1.0.1
- dodano branding SVG
- poprawki userscriptu
- nowy instalator
'@
$changelog | Set-Content CHANGELOG.md -Encoding utf8

# Forum post
$forum = @'
[img]assets/branding/banner.svg[/img]

[b]Aegis – Grepolis Remaster 2025[/b]
Nowa era Grepolis!

[list]
[*] Motywy (Classic / Remaster / Pirate / Dark)
[*] Panel konfiguracji
[*] AssetMap
[*] Ekran powitalny
[/list]

Instalacja:
1. Zainstaluj Tampermonkey
2. Kliknij: userscripts/aegis.user.js
3. Odśwież Grepolis
'@
$forum | Set-Content forum/post.txt -Encoding utf8

Write-Host "== DONE ==" -ForegroundColor Green
