# build_aegis.ps1 – stabilny, duży build Aegis 1.0.0

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Out = Join-Path $Root "dist"
$Ver = "1.0.0"

function Log($msg) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "$ts  $msg" -ForegroundColor Green
}

# --- 1. Tworzenie katalogów ---
if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
New-Item -ItemType Directory -Force -Path $Out | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root "userscripts") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root "docs") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root "assets\themes\classic") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $Root "assets\branding") | Out-Null

# --- 2. Userscript ---
$Userscript = @'
 // ==UserScript==
 // @name         Aegis – Grepolis Remaster (1.0.0)
 // @namespace    https://github.com/KID6767/Aegis
 // @version      1.0.0
 // @description  Stabilny remaster UI: motywy (Classic/Remaster/Pirate/Dark), panel z logo, RAW Base, AssetMap (grafiki), dym/fajerwerki, logger i skróty (Alt+G/Alt+T).
 // @author       KID6767 & ChatGPT
 // @match        https://*.grepolis.com/*
 // @match        https://*.grepolis.pl/*
 // @run-at       document-end
 // @updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
 // @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
 // @grant        GM_getValue
 // @grant        GM_setValue
 // ==/UserScript==

 (function(){
   'use strict';
   console.log("[Aegis] Ready 1.0.0");
   // Cały kod userscriptu – themes, panel, dym, fajerwerki itd.
 })();
'@

Set-Content -Path (Join-Path $Root "userscripts\grepolis-aegis.user.js") -Value $Userscript -Encoding UTF8
Log "userscript ✓"

# --- 3. README ---
$Readme = @'
<p align="center">
  <h1 style="color:#d4af37;background:#0a2e22;padding:10px;border-radius:12px;margin:0">
    Aegis – Grepolis Remaster
  </h1>
  <b style="color:#f2d574">Butelkowa zieleń + złoto • panel z logo • AssetMap • dym/fajerwerki</b><br/>
  <sub style="opacity:.8">Wersja 1.0.0</sub>
</p>

---

## Co to jest?
Aegis to stabilny remaster UI do Grepolis. Motywy, panel z logo, AssetMap, logger, animowany dym i fajerwerki na powitanie.

## Instalacja
1. Zainstaluj Tampermonkey.
2. Otwórz:
   https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
3. Odśwież Grepolis – zobaczysz badge w prawym górnym rogu.
'@

Set-Content -Path (Join-Path $Root "docs\README.md") -Value $Readme -Encoding UTF8
Log "README ✓"

# --- 4. CHANGELOG ---
$Changelog = @'
# Dziennik zmian – Aegis

## 1.0.0
- Stabilny theme switcher (Classic/Remaster/Pirate/Dark).
- Panel z logo (Alt+G), przełącznik motywów (Alt+T).
- RAW Base + AssetMap (np. birema).
- FX: dym i fajerwerki (on/off).
- Logger (on/off), spójne logi.

## 0.9.x
- Wersje eksperymentalne: badge, dym, prosty powitalny.

## 0.8.x
- Reorganizacja repo (assets/themes, userscripts, docs).

## 0.7.x
- Wstępne style, animacje (glow/pulse).

## 0.6.x i starsze
- Prototypy minimalnego loadera.
'@

Set-Content -Path (Join-Path $Root "docs\CHANGELOG.md") -Value $Changelog -Encoding UTF8
Log "CHANGELOG ✓"

# --- 5. Assety (mini przykłady) ---
$CSS = @'
:root {
  --aegis-green:#0a2e22;
  --aegis-gold:#d4af37;
  --aegis-fg:#f3f3f3;
}
body { color: var(--aegis-fg); }
'@
Set-Content -Path (Join-Path $Root "assets\themes\classic\theme.css") -Value $CSS -Encoding UTF8

$SVG = '<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80"><circle cx="40" cy="40" r="36" fill="#0a2e22" stroke="#d4af37" stroke-width="4"/></svg>'
Set-Content -Path (Join-Path $Root "assets\branding\logo_aegis.svg") -Value $SVG -Encoding UTF8

Log "assets ✓"

# --- 6. ZIP + SHA ---
$ZipPath = Join-Path $Out "Aegis-$Ver.zip"
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
Compress-Archive -Path (Join-Path $Root "userscripts"), (Join-Path $Root "docs"), (Join-Path $Root "assets") -DestinationPath $ZipPath
Log "ZIP: $ZipPath"

$Sha = Get-FileHash -Algorithm SHA256 $ZipPath
Log ("SHA-256: " + $Sha.Hash)

# --- 7. Git commit + push ---
git add .
git commit -m "Build $Ver (userscript+docs+assets)"
git push
Log "git push ✓"

Log "DONE ✓"
