#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ── UTIL ──────────────────────────────────────────────────────────────────────
$Root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
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
  Set-Content -Encoding UTF8 -NoNewline -LiteralPath $path -Value $content
}
function Write-Base64([string]$path, [string]$b64) {
  Ensure-Dir (Split-Path $path -Parent)
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String(($b64 -replace '\s','')))
}

Log "== Aegis Installer ==" Cyan

# ── STRUKTURA ─────────────────────────────────────────────────────────────────
$Dirs = @(
  "assets/branding",
  "userscripts",
  "forum",
  "docs",
  "dist"
) | ForEach-Object { Join-Path $Root $_ }
$Dirs | ForEach-Object { Ensure-Dir $_ }
Log "struktura ✓"

# ── ASSETY (SVG/PNG/GIF) ─────────────────────────────────────────────────────
$bannerSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 260" width="960" height="260">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%"  stop-color="#0a2e22">
        <animate attributeName="stop-color" values="#0a2e22;#113c2d;#0a2e22" dur="6s" repeatCount="indefinite"/>
      </stop>
      <stop offset="100%" stop-color="#113c2d">
        <animate attributeName="stop-color" values="#113c2d;#0a2e22;#113c2d" dur="6s" repeatCount="indefinite"/>
      </stop>
    </linearGradient>
    <filter id="glow"><feGaussianBlur stdDeviation="2.5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <rect width="960" height="260" rx="18" fill="url(#g)"/>
  <g filter="url(#glow)">
    <text x="480" y="140" text-anchor="middle" font-family="Georgia,serif" font-size="52" fill="#e7d98b" style="letter-spacing:1.5px">
      AEGIS — Grepolis Remaster
      <animate attributeName="fill" values="#e7d98b;#fff7bf;#e7d98b" dur="3s" repeatCount="indefinite"/>
    </text>
  </g>
  <image href="ship_pirate.svg" x="22"  y="72" width="180" height="120" opacity="0.9">
    <animateTransform attributeName="transform" type="translate" values="0 0; 0 -3; 0 0" dur="4s" repeatCount="indefinite"/>
  </image>
  <image href="ship_green.svg"  x="758" y="62" width="180" height="130" opacity="0.95">
    <animateTransform attributeName="transform" type="translate" values="0 0; 0 3; 0 0" dur="4s" repeatCount="indefinite"/>
  </image>
</svg>
'@
$shipGreenSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 120" width="200" height="120">
  <rect width="200" height="120" fill="none"/>
  <path d="M10,90 C50,120 150,120 190,90 L170,90 C150,95 50,95 30,90 Z" fill="#2e8b57" stroke="#d4af37" stroke-width="3"/>
  <polygon points="80,30 120,30 95,70" fill="#66bb6a" stroke="#d4af37" stroke-width="2"/>
  <line x1="95" y1="70" x2="95" y2="25" stroke="#d4af37" stroke-width="3"/>
  <circle cx="30" cy="88" r="5" fill="#d4af37">
    <animate attributeName="r" values="5;7;5" dur="2.5s" repeatCount="indefinite"/>
  </circle>
</svg>
'@
$shipPirateSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 120" width="200" height="120">
  <rect width="200" height="120" fill="none"/>
  <path d="M10,90 C50,120 150,120 190,90 L170,90 C150,95 50,95 30,90 Z" fill="#1b1b1b" stroke="#8c6f39" stroke-width="3"/>
  <polygon points="75,25 115,25 92,70" fill="#2b2b2b" stroke="#8c6f39" stroke-width="2"/>
  <line x1="92" y1="70" x2="92" y2="20" stroke="#8c6f39" stroke-width="3"/>
  <circle cx="30" cy="88" r="5" fill="#8c6f39">
    <animate attributeName="r" values="5;7;5" dur="2.5s" repeatCount="indefinite"/>
  </circle>
</svg>
'@
# 1x1 PNG (gold) + mały spinner GIF
$pngGoldDotB64 = @'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQI12P4z/D/PwAHggJ/P6aJ/QAAAABJRU5ErkJggg==
'@
$spinnerGifB64 = @'
R0lGODlhEAAQAPQAAP///wAAAGZmZlpaWn9/f5mZmdDQ0JmZmX5+fp6enmZmZgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAACH5BAAAAAAALAAAAAAQABAAAAWqICCOZGmeaKqubOu+cCzPdF1iQJgWg0iqoXQqv1wA0JQvEJQKp1cQhCFQ
BAQhQGgDMMFQJgB0CBAw6H2dY0hE9wQGm8CExqQhC5bY0QDCRxgkS8JQ8iCwYkB1XUAAOw==
'@

$Brand = Join-Path $Root "assets\branding"
Write-Text  (Join-Path $Brand "banner.svg")       $bannerSvg
Write-Text  (Join-Path $Brand "ship_green.svg")   $shipGreenSvg
Write-Text  (Join-Path $Brand "ship_pirate.svg")  $shipPirateSvg
Write-Base64 (Join-Path $Brand "gold_dot.png")    $pngGoldDotB64
Write-Base64 (Join-Path $Brand "spinner.gif")     $spinnerGifB64
Log "assets ✓ (banner.svg, ship_*.svg, spinner.gif, gold_dot.png)"

# ── USERSCRIPT (pełny: pasek + modal + motywy) ───────────────────────────────
$userscript = @'
// ==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    aegis
// @version      1.0.1
// @description  Motywy (Classic/Remaster/Pirate/Dark), pasek konfiguracji (PP-dół), modal z podglądem brandingu.
// @match        *://*.grepolis.com/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function(){
  "use strict";

  const ASSETS = {
    banner: "https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg"
  };

  const THEMES = {
    classic:  { bg:"#f3e6c1", fg:"#2c2c2c", accent:"#8c6f39" },
    remaster: { bg:"#13221a", fg:"#efead4", accent:"#d4af37" },
    pirate:   { bg:"#101010", fg:"#e0d0a0", accent:"#8c6f39" },
    dark:     { bg:"#0b0f12", fg:"#d7dfeb", accent:"#7fb07f" }
  };

  function css(v){
    return `
      :root{--aeg-bg:${v.bg};--aeg-fg:${v.fg};--aeg-ac:${v.accent}}
      .aeg-bar{position:fixed; right:12px; bottom:12px; z-index:99999; display:flex; gap:8px; align-items:center;
        background:var(--aeg-bg); color:var(--aeg-fg); border:2px solid var(--aeg-ac); border-radius:12px; padding:8px 10px;
        box-shadow:0 8px 24px rgba(0,0,0,.35); font-family:system-ui,Segoe UI,Arial; font-size:12px;}
      .aeg-btn{cursor:pointer; padding:4px 8px; border:1px solid var(--aeg-ac); border-radius:8px; background:transparent; color:var(--aeg-fg)}
      .aeg-btn:hover{background:var(--aeg-ac); color:#111}
      .aeg-back{position:fixed; inset:0; background:rgba(0,0,0,.55); display:flex; align-items:center; justify-content:center; z-index:100000}
      .aeg-modal{width:min(900px,92vw); max-height:86vh; overflow:auto; background:var(--aeg-bg); color:var(--aeg-fg);
        border:2px solid var(--aeg-ac); border-radius:16px; padding:18px; box-shadow:0 10px 30px rgba(0,0,0,.45)}
      .aeg-modal h2{margin:0 0 10px 0; font-size:22px}
      .aeg-grid{display:grid; grid-template-columns:1fr 1fr; gap:14px}
      .aeg-card{border:1px dashed var(--aeg-ac); border-radius:12px; padding:10px; background:rgba(0,0,0,.03)}
      .aeg-banner{width:100%; border-radius:12px; border:1px solid var(--aeg-ac)}
      .aeg-close{float:right}
    `;
  }
  function loadTheme(name){
    const conf = THEMES[name] || THEMES.remaster;
    let tag = document.getElementById("aeg-style");
    if(!tag){ tag = document.createElement("style"); tag.id = "aeg-style"; document.head.appendChild(tag); }
    tag.textContent = css(conf);
    localStorage.setItem("AEGIS:theme", name);
  }
  function openModal(){
    const wrap = document.createElement("div"); wrap.className = "aeg-back";
    const modal = document.createElement("div"); modal.className = "aeg-modal";
    modal.innerHTML = `
      <button class="aeg-btn aeg-close">Zamknij</button>
      <h2>AEGIS — Grepolis Remaster</h2>
      <div class="aeg-grid">
        <div class="aeg-card"><strong>Motywy</strong><br/><br/>
          ${["classic","remaster","pirate","dark"].map(k=>'<button class="aeg-btn switch" data-k="'+k+'">'+k+'</button>').join(" ")}
        </div>
        <div class="aeg-card">
          <strong>Branding</strong><br/><br/>
          <ul style="margin-top:6px">
            <li>banner.svg — <code>assets/branding/banner.svg</code></li>
            <li>ship_green.svg / ship_pirate.svg</li>
            <li>spinner.gif, gold_dot.png</li>
          </ul>
        </div>
        <div class="aeg-card" style="grid-column:1 / span 2">
          <img src="${ASSETS.banner}" alt="Aegis banner" class="aeg-banner"/>
        </div>
      </div>`;
    wrap.appendChild(modal);
    document.body.appendChild(wrap);
    modal.querySelector(".aeg-close").onclick = ()=>wrap.remove();
    modal.querySelectorAll(".switch").forEach(b=>b.onclick = ()=>loadTheme(b.dataset.k));
  }
  function initBar(){
    const bar = document.createElement("div"); bar.className = "aeg-bar";
    bar.innerHTML = `
      <button class="aeg-btn" id="aeg-open">Aegis</button>
      <select class="aeg-btn" id="aeg-theme">
        ${Object.keys(THEMES).map(k=>'<option value="'+k+'">'+k+'</option>').join("")}
      </select>`;
    document.body.appendChild(bar);
    document.getElementById("aeg-open").onclick = openModal;
    const sel = document.getElementById("aeg-theme");
    sel.value = (localStorage.getItem("AEGIS:theme")||"remaster");
    sel.onchange = ()=>loadTheme(sel.value);
  }
  function ready(fn){ if (document.readyState!=="loading") fn(); else document.addEventListener("DOMContentLoaded", fn); }
  ready(()=>{
    const theme = localStorage.getItem("AEGIS:theme") || "remaster";
    loadTheme(theme);
    initBar();
    console.log("%cAegis loaded ✓","color:#0f0;background:#222;padding:2px 6px;border-radius:6px");
  });
})();
'@
$UserOut = Join-Path $Root "userscripts\grepolis-aegis.user.js"
Write-Text $UserOut $userscript
Log "userscript ✓ ($([IO.Path]::GetFileName($UserOut)))"

# ── README / CHANGELOG / FORUM ────────────────────────────────────────────────
$README = @'
# Aegis — Grepolis Remaster (1.0.1)

Butelkowa zieleń + złoto, pasek konfiguracji (prawy-dolny róg), modal z podglądem brandingu.

![banner](assets/branding/banner.svg)

## Szybki start
1. Zainstaluj **Tampermonkey**.
2. Otwórz RAW userscript (po wrzuceniu do GitHuba):  
   `https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js`
3. Kliknij **Install** w Tampermonkey i odśwież Grepolis.

## Motywy
- classic / remaster / pirate / dark

## Branding / AssetMap
- `assets/branding/banner.svg` — baner (animowany)
- `assets/branding/ship_green.svg`, `ship_pirate.svg`
- `assets/branding/spinner.gif`, `gold_dot.png`

Podmieniasz pliki → push → userscript je pobierze z RAW.
'@
$CHANGELOG = @'
# Changelog

## 1.0.1
- Pasek Aegis + modal konfiguracji,
- 4 motywy,
- animowany baner + statki,
- kompletny instalator i paczka ZIP.

## 1.0.0
- Inicjał repo.
'@
$FORUM = @'
[center][img]https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg[/img]

[b]Aegis — Grepolis Remaster 2025[/b]
Nowy, spójny wygląd Grepolis i szybka konfiguracja.

[list]
[*] 4 motywy (Classic / Remaster / Pirate / Dark)
[*] Pasek w prawym-dolnym rogu + modal
[*] Branding z repo (baner, statki, spinner)
[/list]

[b]Instalacja[/b]
1) Zainstaluj Tampermonkey.
2) Kliknij RAW userscript (po wrzuceniu do GitHuba):  
[url]https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js[/url]
3) Odśwież grę.

[i]MIT — wolne i otwarte.[/i]
[/center]
'@

Write-Text (Join-Path $Root "README.md")       $README
Write-Text (Join-Path $Root "CHANGELOG.md")    $CHANGELOG
Write-Text (Join-Path $Root "forum_post.txt")  $FORUM
Log "docs ✓ (README, CHANGELOG, forum_post)"

# ── ZIP (bez rekursywnego pakowania samego dist) ─────────────────────────────
$ZipOut = Join-Path $Root "dist\Aegis-1.0.1.zip"
if (Test-Path $ZipOut) { Remove-Item $ZipOut -Force }

# Zbuduj listę elementów do spakowania (tylko te ścieżki)
$ToZip = @(
  "assets",
  "userscripts",
  "docs",
  "forum"
) | ForEach-Object { Join-Path $Root $_ }

# Użyj tymczasowego folderu aby uniknąć zbędnych śmieci
$Tmp = Join-Path $Root (".tmp_pkg_" + [Guid]::NewGuid().ToString("N"))
Ensure-Dir $Tmp
foreach($p in $ToZip){
  Copy-Item -Path $p -Destination $Tmp -Recurse -Force
}
Compress-Archive -Path (Join-Path $Tmp "*") -DestinationPath $ZipOut -Force
Remove-Item $Tmp -Recurse -Force
Log "ZIP ✓ → $ZipOut"
Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $ZipOut).Hash)

Log "DONE ✓" Green
