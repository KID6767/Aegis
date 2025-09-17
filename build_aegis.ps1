# build_aegis.ps1
# Uruchom w folderze, w którym chcesz utworzyć ZIP.
# PowerShell tworzy katalog Aegis-Grepolis-Remake-0.1b, zapisuje pliki i spakuje ZIP.

$root = Join-Path (Get-Location) "Aegis-Grepolis-Remake-0.1b"
if (Test-Path $root) {
    Write-Host "Usuwam stary folder..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $root
}
New-Item -ItemType Directory -Path $root | Out-Null

function Write-File($path, $content) {
    $dir = Split-Path $path -Parent
    if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $content | Out-File -FilePath $path -Encoding UTF8
}

Write-Host "Tworzę pliki..." -ForegroundColor Green

# README
$readme = @"
# Aegis — Grepolis Remake (0.1b - beta)

Quick start:
1. Unpack or place the contents of this folder into the root of your GitHub repo (userscripts/, config/, assets/, docs/, tools/).
2. Install Tampermonkey in your browser.
3. Install the userscript from userscripts/grepolis-skin-switcher.user.js (raw link from your repo).
4. Open Grepolis, log in, and you should see the Aegis switcher in the bottom-right corner.

Author: KID6767
License: MIT
"@
Write-File -path (Join-Path $root "README.md") -content $readme

# CHANGELOG
$changelog = @"
# CHANGELOG

## [0.1b] - Initial beta
- userscript (Tampermonkey)
- welcome screen + theme switcher (Remaster / Pirate-Epic)
- placeholder assets
- mapping files
"@
Write-File -path (Join-Path $root "CHANGELOG.md") -content $changelog

# LICENSE (MIT short)
$license = @"
MIT License

Copyright (c) 2025 KID6767

Permission is hereby granted, free of charge, to any person obtaining a copy...
"@
Write-File -path (Join-Path $root "LICENSE") -content $license

# userscript
$userscript = @"
// ==UserScript==
// @name         Aegis — Grepolis Skin Switcher
// @namespace    https://github.com/KID6767/Aegis-Grepolis-Remake
// @version      0.1b
// @description  Podmiana grafik Grepolis (Remaster 2025 / Pirate-Epic) — beta.
// @author       KID6767
// @match        https://*.grepolis.com/*
// @match        http://*.grepolis.com/*
// @run-at       document-end
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// @connect      raw.githubusercontent.com
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis-Grepolis-Remake/main/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis-Grepolis-Remake/main/userscripts/grepolis-skin-switcher.user.js
// ==/UserScript==

(function () {
  'use strict';
  const THEMES = {
    remaster2025: "local:config/mapping.remaster2025.json",
    pirate_epic: "local:config/mapping.pirate_epic.json"
  };
  const DEFAULT_THEME = GM_getValue("theme", "remaster2025");
  let mapping = {};
  function loadLocalMapping(theme, cb) {
    const path = (THEMES[theme] || THEMES.remaster2025);
    if (path.startsWith("local:")) {
      const localPath = path.replace("local:", "");
      fetch(location.origin + "/" + localPath)
        .then(r => r.json())
        .then(j => { mapping = j; if (cb) cb(); })
        .catch(e => { mapping = {}; if (cb) cb(); });
      return;
    }
    cb && cb();
  }
  function swapUrl(original) {
    if (!original) return original;
    const clean = original.replace(/(\\?.*)$/, "");
    if (mapping[clean]) return mapping[clean];
    const file = clean.split("/").pop();
    for (const k of Object.keys(mapping)) {
      if (k.endsWith(file)) return mapping[k];
    }
    return original;
  }
  function processImg(img) {
    if (!img || img.dataset.aegisSkinned === "1") return;
    const newSrc = swapUrl(img.src);
    if (newSrc && newSrc !== img.src) {
      img.src = newSrc;
      img.dataset.aegisSkinned = "1";
    }
  }
  function processStyle(el) {
    if (!el || el.dataset.aegisSkinned === "1") return;
    const bg = getComputedStyle(el).getPropertyValue("background-image");
    if (bg && bg.includes("url(")) {
      const urlMatch = bg.match(/url\\([\"']?([^\"')]+)[\"']?\\)/);
      if (urlMatch && urlMatch[1]) {
        const newUrl = swapUrl(urlMatch[1]);
        if (newUrl && newUrl !== urlMatch[1]) {
          el.style.backgroundImage = `url(\"${newUrl}\")`;
          el.dataset.aegisSkinned = "1";
        }
      }
    }
  }
  function scanOnce(root = document) {
    root.querySelectorAll("img").forEach(processImg);
    root.querySelectorAll("[style*='background'], .unit_icon, .ship_icon, .building_icon, .gp_background")
        .forEach(processStyle);
  }
  function addSwitcher() {
    const bar = document.createElement('div');
    bar.id = 'aegis-switcher';
    bar.innerHTML = `
      <div style="position:fixed; right:12px; bottom:12px; z-index:2147483647;
                  background:rgba(10,10,10,0.6); padding:8px; border-radius:8px; color:#fff; font:12px sans-serif;">
        <label style="margin-right:6px;">Aegis:</label>
        <select id="aegis-theme">
          <option value="remaster2025">Remaster 2025</option>
          <option value="pirate_epic">Pirate Epic</option>
        </select>
        <button id="aegis-refresh" style="margin-left:8px;">Refresh</button>
      </div>`;
    document.body.appendChild(bar);
    const sel = document.getElementById('aegis-theme');
    sel.value = DEFAULT_THEME;
    sel.addEventListener('change', () => {
      GM_setValue('theme', sel.value);
      loadLocalMapping(sel.value, () => { scanOnce(); });
    });
    document.getElementById('aegis-refresh').addEventListener('click', () => { scanOnce(); });
  }

  function showWelcomeIfNeeded() {
    if (GM_getValue("aegis_welcome_shown", false)) return;
    try {
      const box = document.createElement('div');
      box.id = 'aegis-welcome-box';
      box.style = 'position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#0f0f10; color:#fff; padding:20px 30px; border-radius:12px; z-index:2147483647; text-align:center; max-width:520px; box-shadow:0 0 30px rgba(0,0,0,0.8);';
      box.innerHTML = `
        <img src="/assets/branding/logo.png" style="max-width:260px; margin-bottom:14px;" />
        <h2 style="margin:0; font-family:sans-serif;">Witaj w Aegis!</h2>
        <p style="font-family:sans-serif; font-size:14px; line-height:1.5; margin-top:10px;">
          Twój świat właśnie dostał nowe życie:<br>
          ✨ Remaster 2025 – odświeżone klasyki<br>
          ☠️ Pirate-Epic – totalna zmiana klimatu
        </p>
        <p style="margin-top:12px; font-size:12px; opacity:0.8;">Autor: KID6767</p>
        <button id="aegis-welcome-close" style="margin-top:15px; padding:6px 12px; border:none; border-radius:6px; background:#e38b06; color:#fff; font-weight:bold; cursor:pointer;">Zaczynamy!</button>
      `;
      document.body.appendChild(box);
      document.getElementById('aegis-welcome-close').onclick = () => { box.remove(); GM_setValue('aegis_welcome_shown', true); };
    } catch (e) { console.warn('Aegis welcome failed', e); }
  }

  addSwitcher();
  loadLocalMapping(DEFAULT_THEME, () => { scanOnce(); showWelcomeIfNeeded(); });
  const obs = new MutationObserver((muts) => {
    muts.forEach(m => {
      if (m.addedNodes && m.addedNodes.length) {
        m.addedNodes.forEach(n => { if (n.nodeType === 1) scanOnce(n); });
      }
    });
  });
  obs.observe(document.documentElement, { childList: true, subtree: true });
})();
"@

Write-File -path (Join-Path $root "userscripts/grepolis-skin-switcher.user.js") -content $userscript

# mapping files
$map1 = '{ "https://cdn.grepolis.com/images/units/colonize_ship.png": "/assets/remaster2025/ships/colonize_ship.svg" }'
$map2 = '{ "https://cdn.grepolis.com/images/units/colonize_ship.png": "/assets/pirate_epic/ships/colonize_ship.svg" }'
Write-File -path (Join-Path $root "config/mapping.remaster2025.json") -content $map1
Write-File -path (Join-Path $root "config/mapping.pirate_epic.json") -content $map2

# placeholder SVG ship (remaster)
$svg1 = @"
<svg xmlns='http://www.w3.org/2000/svg' width='512' height='320' viewBox='0 0 512 320'>
  <rect width='100%' height='100%' fill='#f7f3ea'/>
  <g transform='translate(40,40)'>
    <rect x='0' y='120' width='432' height='80' rx='10' fill='#a16f3a' />
    <polygon points='120,120 280,20 360,120' fill='#fff8e6' stroke='#d4bf90' stroke-width='6'/>
    <text x='60' y='210' font-family='sans-serif' font-size='28' fill='#2b2b2b'>Remaster 2025</text>
  </g>
</svg>
"@
Write-File -path (Join-Path $root "assets/remaster2025/ships/colonize_ship.svg") -content $svg1

# placeholder SVG ship (pirate)
$svg2 = @"
<svg xmlns='http://www.w3.org/2000/svg' width='512' height='320' viewBox='0 0 512 320'>
  <rect width='100%' height='100%' fill='#0b0b0d'/>
  <g transform='translate(40,30)'>
    <rect x='0' y='140' width='432' height='70' rx='8' fill='#2f2b2a' />
    <polygon points='140,140 300,30 380,140' fill='#2d2d2d' stroke='#b66a2e' stroke-width='6'/>
    <text x='60' y='210' font-family='sans-serif' font-size='28' fill='#d9b48a'>Pirate - Epic</text>
  </g>
</svg>
"@
Write-File -path (Join-Path $root "assets/pirate_epic/ships/colonize_ship.svg") -content $svg2

# branding PNG placeholders: create small PNGs via .NET System.Drawing if available, otherwise write text placeholders
$logoPath = Join-Path $root "assets/branding/logo.png"
$bannerPath = Join-Path $root "assets/branding/banner.png"

try {
    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 512,128
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(12,12,12))
    $font = New-Object System.Drawing.Font("Arial",36,[System.Drawing.FontStyle]::Bold)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210,170,115))
    $size = $g.MeasureString("AEGIS", $font)
    $g.DrawString("AEGIS", $font, $brush, ([int](($bmp.Width - $size.Width)/2)), ([int](($bmp.Height - $size.Height)/2)))
    $bmp.Save($logoPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    # banner
    $bmp2 = New-Object System.Drawing.Bitmap 1200,300
    $g2 = [System.Drawing.Graphics]::FromImage($bmp2)
    $g2.Clear([System.Drawing.Color]::FromArgb(8,8,8))
    $font2 = New-Object System.Drawing.Font("Arial",48,[System.Drawing.FontStyle]::Bold)
    $brush2 = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(210,170,115))
    $size2 = $g2.MeasureString("AEGIS - GREPOLIS REMAKE", $font2)
    $g2.DrawString("AEGIS - GREPOLIS REMAKE", $font2, $brush2, ([int](($bmp2.Width - $size2.Width)/2)), ([int](($bmp2.Height - $size2.Height)/2)))
    $bmp2.Save($bannerPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $g2.Dispose(); $bmp2.Dispose()
} catch {
    Write-Host "System.Drawing niedostępny, zapisuję tekstowe placeholdery PNG zamiast grafiki." -ForegroundColor Yellow
    Write-File -path $logoPath -content "PNG_PLACEHOLDER_LOGO"
    Write-File -path $bannerPath -content "PNG_PLACEHOLDER_BANNER"
}

# tools scripts
$sh = @"
#!/bin/sh
DIR=\$(dirname \"\$0\")/..
cd \"\$DIR\"
zip -r Aegis-Grepolis-Remake-0.1b.zip ./*
"@
Write-File -path (Join-Path $root "tools/build-zip.sh") -content $sh
$bat = @"
@echo off
powershell -Command "Compress-Archive -Path * -DestinationPath Aegis-Grepolis-Remake-0.1b.zip -Force"
echo [*] Spakowano do: Aegis-Grepolis-Remake-0.1b.zip
pause
"@
Write-File -path (Join-Path $root "tools/build-zip.bat") -content $bat

# make sure build-zip.sh is executable on systems that support it
try { icacls (Join-Path $root "tools/build-zip.sh") /grant Everyone:RX 2>$null } catch {}

# create zip
$zipPath = Join-Path (Get-Location) "Aegis-Grepolis-Remake-0.1b.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $root "*") -DestinationPath $zipPath -Force

Write-Host "Gotowe: $zipPath" -ForegroundColor Cyan
Write-Host "Rozpakuj ZIP i wrzuć zawartość do swojego repo na GitHubie." -ForegroundColor Green
