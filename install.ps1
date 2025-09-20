#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ───────────────────────── helpers ─────────────────────────
function Log([string]$msg, [ConsoleColor]$c = [ConsoleColor]::Green) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $prev = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $c
  Write-Host "$ts  $msg"
  $Host.UI.RawUI.ForegroundColor = $prev
}
function Ensure-Dir([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
  }
}
function Write-Text([string]$path, [string]$content) {
  Ensure-Dir (Split-Path -LiteralPath $path -Parent)
  $content | Set-Content -Encoding UTF8 -NoNewline -LiteralPath $path
}
function Write-Base64([string]$path, [string]$b64) {
  Ensure-Dir (Split-Path -LiteralPath $path -Parent)
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String(($b64 -replace '\s','')))
}

# ───────────────────────── locations ───────────────────────
$Root = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Root)) { $Root = (Get-Location).Path }
Set-Location -LiteralPath $Root

$Dirs = @(
  "assets/branding",
  "userscripts",
  "docs",
  "forum",
  "config",
  "dist"
) | ForEach-Object { Join-Path $Root $_ }

$Dirs | ForEach-Object { Ensure-Dir $_ }
Log "STRUCTURE ✓" Cyan

# ───────────────────────── assets (SVG/PNG/GIF) ────────────
$bannerSvg = @"
<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 960 260' width='960' height='260'>
  <defs>
    <linearGradient id='g' x1='0' y1='0' x2='1' y2='0'>
      <stop offset='0%' stop-color='#0a2e22'>
        <animate attributeName='stop-color' values='#0a2e22;#113c2d;#0a2e22' dur='6s' repeatCount='indefinite'/>
      </stop>
      <stop offset='100%' stop-color='#113c2d'>
        <animate attributeName='stop-color' values='#113c2d;#0a2e22;#113c2d' dur='6s' repeatCount='indefinite'/>
      </stop>
    </linearGradient>
    <filter id='glow'><feGaussianBlur stdDeviation='3' result='b'/><feMerge><feMergeNode in='b'/><feMergeNode in='SourceGraphic'/></feMerge></filter>
  </defs>
  <rect width='960' height='260' rx='18' fill='url(#g)'/>
  <g filter='url(#glow)'>
    <text x='480' y='138' text-anchor='middle' font-family='Georgia,serif' font-size='48' fill='#e7d98b' style='letter-spacing:1.5px'>
      AEGIS — Grepolis Remaster 2025
      <animate attributeName='fill' values='#e7d98b;#fff7b2;#e7d98b' dur='3s' repeatCount='indefinite'/>
    </text>
  </g>
  <image href='ship_pirate.svg' x='26'  y='84' width='170' height='110' opacity='.9'>
    <animateTransform attributeName='transform' type='translate' values='0 0; 0 -3; 0 0' dur='4s' repeatCount='indefinite'/>
  </image>
  <image href='ship_green.svg'  x='764' y='72' width='170' height='120' opacity='.95'>
    <animateTransform attributeName='transform' type='translate' values='0 0; 0 3; 0 0' dur='4s' repeatCount='indefinite'/>
  </image>
</svg>
"@

$shipGreenSvg = @"
<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 120'>
  <path d='M10,90 C50,120 150,120 190,90 L170,90 C150,95 50,95 30,90 Z' fill='#2e8b57' stroke='#d4af37' stroke-width='3'/>
  <polygon points='80,30 120,30 95,70' fill='#66bb6a' stroke='#d4af37' stroke-width='2'/>
  <line x1='95' y1='70' x2='95' y2='25' stroke='#d4af37' stroke-width='3'/>
  <circle cx='30' cy='88' r='5' fill='#d4af37'>
    <animate attributeName='r' values='5;7;5' dur='2.5s' repeatCount='indefinite'/>
  </circle>
</svg>
"@

$shipPirateSvg = @"
<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 200 120'>
  <path d='M10,90 C50,120 150,120 190,90 L170,90 C150,95 50,95 30,90 Z' fill='#1b1b1b' stroke='#8c6f39' stroke-width='3'/>
  <polygon points='75,25 115,25 92,70' fill='#2b2b2b' stroke='#8c6f39' stroke-width='2'/>
  <line x1='92' y1='70' x2='92' y2='20' stroke='#8c6f39' stroke-width='3'/>
  <circle cx='30' cy='88' r='5' fill='#8c6f39'>
    <animate attributeName='r' values='5;7;5' dur='2.5s' repeatCount='indefinite'/>
  </circle>
</svg>
"@

# 32×32 złota kropka (PNG)
$pngGoldDotB64 = @"
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAACXBIWXMAAA7EAAAOxAGVKw4bAAABZElE
QVRYCe2XvU7CQBSEZzC2m1qJ7yq2m2E1C1a3rC3QJxgG6b7S2d3M8p2wJ1+Nwq7P4fCw3p4WvM0m6y0p5c
d4t5g0w8xZQwQp3m0f4yQk5m2a1q3yPpWg6b0iC2QO1Xw3eCqg1Z1sWwQm6hS5r1f1lqC0f8wG6fT1I9V7
x8k1a8z4QeZcA6Wq3c6o2mQzGq6uQ5n4QxZ3qQ2P4QK5VfU3o+4Qk5Wq7S3m5yYQ7Gm4H4vHfQvI1qv3Nn
M8E8gJ4bN7p1Q7h+o8z6b8Q5Nf2Q3+zqg1H2gU7m7p0kQxg8dJm9v0y3qQH3b3VYyUo7C3+7g4i9d1lqL9
YH1w8xkY9dr8t0Q9tqVg1u+uF9w9o0gO2T7c8D6o5bq0Jc9f2wP2l0Uq8m/0A1VQpwB0o6gNwD0s7gNwC0
qYF4v8Rz0zD8Ckqj2k6iGJTTXqK3G7iCV7m0S5b7mQAAAABJRU5ErkJggg==
"@

# 16×16 spinner (GIF)
$spinnerGifB64 = @"
R0lGODlhEAAQAPQAAP///wAAAGZmZlpaWn9/f5mZmdDQ0JmZmX5+fp6enmZmZgAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAAQABAAAAWqICCOZGmeaKqubOu+cCzPdF1
iQJgWg0iqoXQqv1wA0JQvEJQKp1cQhCFQBAQhQGgDMMFQJgB0CBAw6H2dY0hE9wQGm8CExqQhC5bY0QD
CRxgkS8JQ8iCwYkB1XUAAOw==
"@

$assetsRoot = Join-Path $Root "assets\branding"
Write-Text   (Join-Path $assetsRoot "banner.svg")       $bannerSvg
Write-Text   (Join-Path $assetsRoot "ship_green.svg")   $shipGreenSvg
Write-Text   (Join-Path $assetsRoot "ship_pirate.svg")  $shipPirateSvg
Write-Base64 (Join-Path $assetsRoot "gold_dot.png")     $pngGoldDotB64
Write-Base64 (Join-Path $assetsRoot "spinner.gif")      $spinnerGifB64
Log "ASSETS ✓ (SVG/PNG/GIF)" Green

# ───────────────────────── userscript ──────────────────────
# NOTE: Userscript pobiera baner i spinner z repo (raw). Podmienisz grafikę → TM ją zobaczy.
$rawBase = "https://raw.githubusercontent.com/KID6767/Aegis/main"
$userscript = @"
// ==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    aegis
// @version      1.0.1
// @description  Motywy (Classic/Remaster/Pirate/Dark), panel Aegis, branding (AssetMap), ekran powitalny.
// @author       KID6767 & ChatGPT
// @match        *://*.grepolis.com/*
// @grant        none
// ==/UserScript==

(function(){
  'use strict';

  const RAW = '$rawBase/assets/branding';
  const THEMES = {
    classic:  { bg:'#f3e6c1', fg:'#2c2c2c', accent:'#8c6f39' },
    remaster: { bg:'#13221a', fg:'#efead4', accent:'#d4af37' },
    pirate:   { bg:'#101010', fg:'#e0d0a0', accent:'#8c6f39' },
    dark:     { bg:'#0b0f12', fg:'#d7dfeb', accent:'#7fb07f' }
  };

  function css(vars){
    return `
      :root{
        --aegis-bg:${vars.bg}; --aegis-fg:${vars.fg}; --aegis-accent:${vars.accent};
      }
      .aegis-bar{
        position:fixed; right:12px; bottom:12px; z-index:99999;
        display:flex; gap:8px; align-items:center;
        background:var(--aegis-bg); color:var(--aegis-fg);
        border:2px solid var(--aegis-accent); border-radius:12px; padding:8px 10px;
        box-shadow:0 8px 24px rgba(0,0,0,.35);
        font-family:system-ui,-apple-system,Segoe UI,Arial,sans-serif; font-size:12px;
      }
      .aegis-btn{ cursor:pointer; padding:4px 8px; border:1px solid var(--aegis-accent);
        border-radius:8px; background:transparent; color:var(--aegis-fg);}
      .aegis-btn:hover{ background:var(--aegis-accent); color:#111;}
      .aegis-modal-backdrop{
        position:fixed; inset:0; background:rgba(0,0,0,.55); display:flex; align-items:center; justify-content:center; z-index:100000;
      }
      .aegis-modal{
        width:min(900px,92vw); max-height:86vh; overflow:auto;
        background:var(--aegis-bg); color:var(--aegis-fg);
        border:2px solid var(--aegis-accent); border-radius:16px; padding:18px 18px 10px;
        box-shadow:0 10px 30px rgba(0,0,0,.45);
      }
      .aegis-modal h2{ margin:0 0 10px 0; font-size:22px; letter-spacing:.4px; }
      .aegis-grid{ display:grid; grid-template-columns:1fr 1fr; gap:14px; }
      .aegis-card{ border:1px dashed var(--aegis-accent); border-radius:12px; padding:10px; background:rgba(0,0,0,.03); }
      .aegis-banner{ width:100%; border-radius:12px; border:1px solid var(--aegis-accent); }
      .aegis-close{ float:right; }
    `;
  }

  function loadTheme(name){
    const conf = THEMES[name] || THEMES.remaster;
    const styleId = 'aegis-style';
    let tag = document.getElementById(styleId);
    if(!tag){ tag = document.createElement('style'); tag.id = styleId; document.head.appendChild(tag); }
    tag.textContent = css(conf);
    localStorage.setItem('aegis.v1:theme', name);
  }

  function bannerEl(){
    const img = document.createElement('img');
    img.src = RAW + '/banner.svg';
    img.alt = 'Aegis banner';
    img.className = 'aegis-banner';
    return img;
  }

  function openModal(){
    const wrap = document.createElement('div'); wrap.className = 'aegis-modal-backdrop';
    const modal = document.createElement('div'); modal.className = 'aegis-modal';
    modal.innerHTML = `
      <button class='aegis-btn aegis-close'>Zamknij</button>
      <h2>AEGIS — Grepolis Remaster 2025</h2>
      <div class='aegis-grid'>
        <div class='aegis-card'>
          <strong>Motywy</strong><br/><br/>
          ${['classic','remaster','pirate','dark'].map(k=>`<button class='aegis-btn switch' data-k='${k}'>${k}</button>`).join(' ')}
        </div>
        <div class='aegis-card'>
          <strong>Branding</strong><br/><br/>
          <ul style='margin-top:6px'>
            <li>banner.svg / ship_green.svg / ship_pirate.svg</li>
            <li>spinner.gif • gold_dot.png</li>
          </ul>
        </div>
        <div class='aegis-card' style='grid-column:1 / span 2'>${bannerEl().outerHTML}</div>
      </div>
      <div style='margin-top:12px; font-size:12px; opacity:.8'>Aegis: panel zainicjalizowany — motyw, branding, modal.</div>
    `;
    wrap.appendChild(modal);
    document.body.appendChild(wrap);
    modal.querySelector('.aegis-close').onclick = ()=>wrap.remove();
    modal.querySelectorAll('.switch').forEach(b=>b.onclick = ()=>loadTheme(b.dataset.k));
  }

  function initBar(){
    const bar = document.createElement('div'); bar.className = 'aegis-bar';
    bar.innerHTML = `
      <button class='aegis-btn' id='aegis-open'>Aegis</button>
      <select class='aegis-btn' id='aegis-theme'>
        ${Object.keys(THEMES).map(k=>`<option value='${k}'>${k}</option>`).join('')}
      </select>
    `;
    document.body.appendChild(bar);
    document.getElementById('aegis-open').onclick = openModal;
    const sel = document.getElementById('aegis-theme');
    sel.value = (localStorage.getItem('aegis.v1:theme')||'remaster');
    sel.onchange = ()=>loadTheme(sel.value);
  }

  function ready(fn){
    if (document.readyState === 'complete' || document.readyState === 'interactive') return fn();
    document.addEventListener('DOMContentLoaded', fn);
  }

  ready(()=>{
    const theme = localStorage.getItem('aegis.v1:theme') || 'remaster';
    loadTheme(theme);
    initBar();
    console.log('%cAegis loaded ✓','color:#0f0; background:#222; padding:2px 6px; border-radius:6px');
  });
})();
"@

$usersPath = Join-Path $Root "userscripts\grepolis-aegis.user.js"
Write-Text $usersPath $userscript
Log "USERSCRIPT ✓ (Tampermonkey)" Green

# ───────────────────────── docs & forum ────────────────────
$README = @"
# Aegis — Grepolis Remaster (1.0.1)

Butelkowa zieleń i złoto, panel z pięknym **dymem motywu**, ekran powitalny, **AssetMap** (branding),
i szybka konfiguracja rodem z GRCR Tools — po naszemu.

![banner](assets/branding/banner.svg)

## Szybki start
1. Zainstaluj **Tampermonkey**.
2. Otwórz:  
   \`$rawBase/userscripts/grepolis-aegis.user.js\`  
   i kliknij **Install**.
3. Odśwież Grepolis → zobaczysz **pasek Aegis** (prawy-dolny róg). Kliknij „Aegis”, aby otworzyć panel.

## Motywy
- **classic** – jasny akcent na ciepłym tle,
- **remaster** – zielono-złoty,
- **pirate** – ciemny (piracki),
- **dark** – głęboka ciemność z zielenią.

## Branding / AssetMap
- \`assets/branding/banner.svg\` — baner (animowany),
- \`assets/branding/ship_green.svg\` i \`ship_pirate.svg\`,
- \`assets/branding/spinner.gif\`, \`gold_dot.png\`.

Podmień pliki w \`assets/branding\` → userscript pobierze je z RAW GitHuba.

## Licencja
MIT — wolne i otwarte.
"@

$CHANGELOG = @"
# Changelog

## 1.0.1
- Panel Aegis (modal + pasek),
- 4 motywy kolorystyczne,
- animowany baner i statki,
- AssetMap (branding w \`assets/branding\`),
- userscript gotowy do TM.

## 1.0.0
- Inicjalna struktura repo.
"@

$Forum = @"
[center][img]$rawBase/assets/branding/banner.svg[/img]

[b]Aegis — Grepolis Remaster 2025[/b]
Nowa era Grepolis!

[list]
[*] Epickie motywy (Classic / Remaster / Pirate / Dark),
[*] Panel konfiguracji (prawy-dolny róg),
[*] Ekran powitalny z banerem,
[*] AssetMap — branding z GitHuba (prosta podmiana grafik).
[/list]

[b]Instalacja[/b]
1) Zainstaluj Tampermonkey.  
2) Kliknij: [url]$rawBase/userscripts/grepolis-aegis.user.js[/url] i [b]Install[/b].  
3) Odśwież Grepolis — nowy pasek Aegis jest w prawym-dolnym rogu.

Zrzuty (brand):
[img]$rawBase/assets/branding/ship_green.svg[/img]
[img]$rawBase/assets/branding/ship_pirate.svg[/img]

[i]MIT — darmowe i otwarte.[/i]
[/center]
"@

Write-Text (Join-Path $Root "README.md")      $README
Write-Text (Join-Path $Root "changelog.md")   $CHANGELOG
Write-Text (Join-Path $Root "forum_post.txt") $Forum
Log "DOCS ✓ (README, CHANGELOG, forum_post)" Green

# ───────────────────────── pack ZIP ────────────────────────
$zipName = "Aegis-1.0.1.zip"
$zipPath = Join-Path $Root ("dist\" + $zipName)
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

$toPack = @(
  "assets","userscripts","README.md","changelog.md","forum_post.txt"
) | ForEach-Object { Join-Path $Root $_ }

Compress-Archive -Path $toPack -DestinationPath $zipPath -CompressionLevel Optimal
$sha = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash

Log "ZIP ✓  $zipPath" Yellow
Log "SHA-256: $sha" Yellow

Write-Host ""
Log "DONE ✓" Green
Write-Host ""
Write-Host "Następne kroki:" -ForegroundColor Yellow
Write-Host "1) (opcjonalnie) commit/push do GitHuba — RAW URL-e już wpisane." 
Write-Host "2) Otwórz w przeglądarce i zainstaluj w Tampermonkey:" 
Write-Host "   $rawBase/userscripts/grepolis-aegis.user.js"
Write-Host ""
