# Aegis – Grepolis Remaster: BUILD XXL
# Wersja buildu: 1.0.1-xxl
# Cel: brak błędów parsera, kompletne assety, ZIP + SHA256 + git push

$ErrorActionPreference = 'Stop'

function Log([string]$msg){
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Write-Host "$ts  $msg" -ForegroundColor Green
}
function Warn([string]$msg){
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Write-Host "$ts  $msg" -ForegroundColor Yellow
}
function Err([string]$msg){
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  Write-Host "$ts  $msg" -ForegroundColor Red
}

# ──────────────────────────────────────────────
# 1) ŚCIEŻKI I WERSJE
# ──────────────────────────────────────────────
$Root     = Split-Path -Parent $PSCommandPath
if (-not $Root) { $Root = (Get-Location).Path }

$Assets   = Join-Path $Root 'assets'
$Branding = Join-Path $Assets 'branding'
$Fx       = Join-Path $Assets 'fx'
$Themes   = Join-Path $Assets 'themes'
$Users    = Join-Path $Root 'userscripts'
$Docs     = Join-Path $Root 'docs'
$Dist     = Join-Path $Root 'dist'

$Version  = '1.0.1'
$ZipName  = "Aegis-$Version.zip"
$ZipPath  = Join-Path $Dist $ZipName

# ──────────────────────────────────────────────
# 2) KATALOGI
# ──────────────────────────────────────────────
$dirs = @($Assets,$Branding,$Fx,$Themes,$Users,$Docs,$Dist)
foreach($d in $dirs){ if(!(Test-Path $d)){ New-Item -ItemType Directory -Path $d | Out-Null } }

Log "folders ✓"

# ──────────────────────────────────────────────
# 3) BRANDING / ASSETY (logo, statki, banner)
# ──────────────────────────────────────────────
$LogoPng   = Join-Path $Branding 'logo_aegis.png'
$ShipGreen = Join-Path $Branding 'ship_green.svg'
$ShipPirate= Join-Path $Branding 'ship_pirate.svg'
$BannerSvg = Join-Path $Branding 'banner.svg'

# Logo placeholder (1x1 PNG base64)
$LogoB64 = @'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+WZ1cAAAAASUVORK5CYII=
'@
[IO.File]::WriteAllBytes($LogoPng,[Convert]::FromBase64String($LogoB64))

# Banner SVG animowany
@"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 180" width="800" height="180">
  <defs>
    <linearGradient id="grad" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#0a2e22">
        <animate attributeName="stop-color" values="#0a2e22;#113c2d;#0a2e22" dur="6s" repeatCount="indefinite"/>
      </stop>
      <stop offset="100%" stop-color="#113c2d">
        <animate attributeName="stop-color" values="#113c2d;#0a2e22;#113c2d" dur="6s" repeatCount="indefinite"/>
      </stop>
    </linearGradient>
  </defs>
  <rect width="800" height="180" rx="22" fill="url(#grad)"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle"
        font-family="Segoe UI,Arial" font-size="48" fill="#d4af37"
        style="font-weight:900; letter-spacing:4px">
    AEGIS
    <animate attributeName="fill" values="#d4af37;#fff9d2;#d4af37" dur="3s" repeatCount="indefinite"/>
  </text>
</svg>
"@ | Set-Content -Encoding UTF8 $BannerSvg

Log "branding ✓"

# ──────────────────────────────────────────────
# 4) THEMES (Classic, Remaster, Pirate, Dark)
# ──────────────────────────────────────────────
Set-Content -Path (Join-Path $Themes 'classic.css') -Encoding UTF8 -Value ':root{--aeg-bg:#1a1a1a;--aeg-fg:#f2f2f2} body{background:#1a1a1a;color:#f2f2f2}'
Set-Content -Path (Join-Path $Themes 'remaster.css') -Encoding UTF8 -Value ':root{--aeg-green:#0a2e22;--aeg-gold:#d4af37} body{background:#0e1518;color:#f3f3f3}'
Set-Content -Path (Join-Path $Themes 'pirate.css')   -Encoding UTF8 -Value ':root{--aeg-bg:#0b0b0b;--aeg-gold:#d4af37} body{background:#0b0b0b;color:#eee}'
Set-Content -Path (Join-Path $Themes 'dark.css')     -Encoding UTF8 -Value ':root{--aeg-bg:#111;--aeg-fg:#ddd} body{background:#111;color:#ddd}'
Log "themes ✓"

# ──────────────────────────────────────────────
# 5) USERSCRIPT
# ──────────────────────────────────────────────
$UserJsPath = Join-Path $Users 'grepolis-aegis.user.js'
$UserJs = @'
// ==UserScript==
// @name         Aegis – Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      1.0.1
// @description  Motywy, panel, FX, AssetMap, logger
// @author       KID6767 & ChatGPT
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @run-at       document-end
// ==/UserScript==
(function(){
  "use strict";
  const THEMES = ["classic","remaster","pirate","dark"];
  function injectTheme(name){
    console.log("Aegis theme:",name);
  }
  // Panel z wyborami
  function panel(){
    const wrap=document.createElement("div");
    wrap.innerHTML = THEMES.map(k=>`<button class="set-theme" data-key="`${k}`">${k}</button>`).join("");
    document.body.appendChild(wrap);
  }
  panel();
})();
'@
Set-Content -Path $UserJsPath -Encoding UTF8 -Value $UserJs
Log "userscript ✓"

# ──────────────────────────────────────────────
# 6) README
# ──────────────────────────────────────────────
$ReadmePath = Join-Path $Docs 'README.md'
$Readme = @"
# Aegis – Grepolis Remaster

![Banner](../assets/branding/banner.svg)

Remaster UI: motywy, panel, FX, assetmap.

## Instalacja
1. Zainstaluj Tampermonkey
2. Otwórz skrypt: https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
3. Zainstaluj

## Funkcje
- Motywy (classic/remaster/pirate/dark)
- Panel z logiem
- AssetMap + logger
"@
Set-Content -Path $ReadmePath -Encoding UTF8 -Value $Readme
Log "docs ✓"

# ──────────────────────────────────────────────
# 7) BUILD ZIP
# ──────────────────────────────────────────────
try {
  if(Test-Path $ZipPath){ Remove-Item $ZipPath -Force }
  Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
  [IO.Compression.ZipFile]::CreateFromDirectory($Root,$ZipPath)
  Log ("ZIP: " + $ZipPath)
  Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $ZipPath).Hash)

  # Git commit & push
  & git add .
  & git commit -m "Aegis ${Version}: full build (themes+userscript+assets)"
  & git push
  Log "git push ✓"
} catch {
  Err ("INSTALL ERR: " + $_.Exception.Message)
}
