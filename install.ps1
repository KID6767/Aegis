# ============================
# Aegis – Installer (Final)
# ============================
$ErrorActionPreference = 'Stop'
function Log([string]$m){ $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); Write-Host "$ts  $m" -ForegroundColor Green }
function Warn([string]$m){ $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); Write-Host "$ts  $m" -ForegroundColor Yellow }
function Err([string]$m){ $ts=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); Write-Host "$ts  $m" -ForegroundColor Red }
function EnsureDir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Path $p | Out-Null } }
function WriteUtf8($p,$t){ EnsureDir (Split-Path -Parent $p); [IO.File]::WriteAllText($p,$t,[Text.UTF8Encoding]::new($false)) }
function WriteBytes($p,$b){ EnsureDir (Split-Path -Parent $p); [IO.File]::WriteAllBytes($p,$b) }
function B64Bytes($s){ try{ [Convert]::FromBase64String($s.Trim()) }catch{ @() } }

$Root = Split-Path -Parent $PSCommandPath
if(-not $Root){ $Root=(Get-Location).Path }
Set-Location $Root
Log "== Aegis Installer =="

# Ścieżki
$Assets   = Join-Path $Root 'assets'
$Branding = Join-Path $Assets 'branding'
$Ships    = Join-Path $Assets 'ships'
$Docs     = Join-Path $Root 'docs'
$Users    = Join-Path $Root 'userscripts'
$Dist     = Join-Path $Root 'dist'
$Tools    = Join-Path $Root 'tools'
$Forum    = Join-Path $Root 'forum'

@($Assets,$Branding,$Ships,$Docs,$Users,$Dist,$Tools,$Forum) | ForEach-Object { EnsureDir $_ }

# ------------------------------
# Grafiki (SVG/PNG/GIF minimalist)
# ------------------------------
$bannerSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="360" viewBox="0 0 1600 360">
  <defs>
    <linearGradient id="bg" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0%" stop-color="#0a2e22"/>
      <stop offset="100%" stop-color="#113c2d"/>
    </linearGradient>
    <linearGradient id="gold" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0%" stop-color="#d4af37"/>
      <stop offset="100%" stop-color="#f2d574"/>
    </linearGradient>
    <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="6" result="b"/>
      <feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
  </defs>
  <rect width="1600" height="360" fill="url(#bg)"/>
  <g filter="url(#glow)">
    <text x="800" y="190" text-anchor="middle" font-family="Segoe UI,system-ui,Arial" font-size="84" font-weight="900" fill="url(#gold)">AEGIS — GREPOLIS REMASTER</text>
    <text x="800" y="235" text-anchor="middle" font-family="Segoe UI,system-ui,Arial" font-size="22" fill="#e9e1c5" opacity=".9">Butelkowa zieleń • Złoto • Konfigurator • Animacje • AssetMap</text>
  </g>
  <!-- statki (L/R) -->
  <g opacity=".9">
    <path d="M120 300c50-40 90-60 140-60 46 0 86 16 128 46-12 2-24 3-38 3-64 0-122-18-230 11Z" fill="#0f1d16"/>
    <path d="M1340 300c-50-40-90-60-140-60-46 0-86 16-128 46 12 2 24 3 38 3 64 0 122-18 230 11Z" fill="#0f1d16"/>
    <circle cx="180" cy="260" r="7" fill="#d4af37"/>
    <circle cx="1420" cy="260" r="7" fill="#d4af37"/>
  </g>
</svg>
'@

$shipGreenSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="320" height="120" viewBox="0 0 320 120">
  <defs>
    <linearGradient id="g" x1="0" x2="1"><stop offset="0" stop-color="#0f3a2c"/><stop offset="1" stop-color="#145a43"/></linearGradient>
    <linearGradient id="gold" x1="0" x2="1"><stop offset="0" stop-color="#d4af37"/><stop offset="1" stop-color="#f2d574"/></linearGradient>
  </defs>
  <path d="M10 85c40-28 90-42 150-42 60 0 110 14 150 42-20 4-42 6-66 6-88 0-155-26-234-6z" fill="url(#g)"/>
  <rect x="160" y="20" width="6" height="40" rx="2" fill="url(#gold)"/>
  <path d="M166 20l50 18-50 18z" fill="#e9e1c5"/>
</svg>
'@

$shipPirateSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" width="320" height="120" viewBox="0 0 320 120">
  <defs>
    <linearGradient id="p" x1="0" x2="1"><stop offset="0" stop-color="#0a0a0a"/><stop offset="1" stop-color="#111"/></linearGradient>
    <linearGradient id="gold" x1="0" x2="1"><stop offset="0" stop-color="#d4af37"/><stop offset="1" stop-color="#f2d574"/></linearGradient>
  </defs>
  <path d="M10 85c40-28 90-42 150-42 60 0 110 14 150 42-20 4-42 6-66 6-88 0-155-26-234-6z" fill="url(#p)"/>
  <rect x="160" y="20" width="6" height="40" rx="2" fill="url(#gold)"/>
  <path d="M166 20l44 16-44 16z" fill="#af1a1a"/>
</svg>
'@

$logoPngB64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAAAQCAYAAABAfUpiAAAAFElEQVR4nO3MMQEAAAgDINc/9K0hQYkQyqQpZz0Gxg=="
$spinnerGifB64 = "R0lGODlhEAAQAPQAAP///wAAAIaGhmZmZl5eXqioqJ6enrS0tOvr6/Pz8/Ly8vDw8OXl5eTk5Ojo6O7u7v///wAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAB8ALAAAAAAQABAAAAVb4CeOZGmeaKqubIsxCjDgCw7BEFQpA4mQJQYg1bB8gQHnq8lUQh0mJinm9kFJ0mE9yJ2lq4g0KQWQhCEYJxGZF0gCkWQbB8QYpRkQAAOw=="

WriteUtf8 (Join-Path $Branding 'banner.svg')      $bannerSvg
WriteUtf8 (Join-Path $Ships    'ship_green.svg')   $shipGreenSvg
WriteUtf8 (Join-Path $Ships    'ship_pirate.svg')  $shipPirateSvg
$logoBytes    = B64Bytes $logoPngB64
$spinnerBytes = B64Bytes $spinnerGifB64
if($logoBytes.Length   -gt 0){ WriteBytes (Join-Path $Branding 'logo_aegis.png') $logoBytes }
if($spinnerBytes.Length -gt 0){ WriteBytes (Join-Path $Branding 'spinner.gif')   $spinnerBytes }

Log "assets ✓ (banner.svg, ships, logo, spinner.gif)"

# ------------------------------
# Userscript (pełny – panel, motywy, smoke, badge, AssetMap)
# ------------------------------
$userJs = @'
/* ==UserScript==
@name         Aegis – Grepolis Remaster (1.0.0 Final)
@namespace    https://github.com/KID6767/Aegis
@version      1.0.0
@description  Remaster UI: motywy (Classic/Remaster/Pirate/Dark), panel, animacje (smoke), badge, AssetMap, BBCode linki
@match        https://*.grepolis.com/*
@match        https://*.grepolis.pl/*
@run-at       document-end
@grant        GM_getValue
@grant        GM_setValue
==/UserScript== */
(function(){
  'use strict';
  const get = (k,d)=> typeof GM_getValue==='function' ? GM_getValue(k,d) : (JSON.parse(localStorage.getItem(k)||'null') ?? d);
  const set = (k,v)=> typeof GM_getValue==='function' ? GM_setValue(k,v) : localStorage.setItem(k, JSON.stringify(v));
  const THEMES = {
    classic: `:root{--a:#d4af37;--b:#232a36;--bg:#1a1a1a;--fg:#f2f2f2}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:#1a1a1a!important;color:#f2f2f2!important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:#232a36!important;color:#d4af37!important;border-color:#a8832b!important}
      .button,.btn,.ui-button{background:#2a2a2a!important;color:#f2f2f2!important;border:1px solid #555!important}`,
    remaster: `:root{--g1:#0a2e22;--g2:#113c2d;--gold:#d4af37;--bg:#0e1518;--fg:#f3f3f3}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--bg)!important;color:var(--fg)!important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:linear-gradient(180deg,var(--g1),var(--g2))!important;color:var(--gold)!important;border-color:rgba(212,175,55,.35)!important}
      .button,.btn,.ui-button{background:#122018!important;color:var(--gold)!important;border:1px solid rgba(212,175,55,.35)!important}`,
    pirate: `:root{--gold:#d4af37;--bg:#0b0b0b;--ink:#101010;--fg:#eee}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:#0b0b0b!important;color:#eee!important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:#101010!important;color:#d4af37!important;border-color:#d4af37!important}`,
    dark: `:root{--bg:#111;--fg:#ddd;--ac:#4da6ff}
      body,.gpwindow_content,.game_inner_box,.ui_box,.forum_content{background:#111!important;color:#ddd!important}
      a,.gpwindow_content a,.forum_content a{color:#4da6ff!important}`
  };
  function applyTheme(name){
    const css = THEMES[name] || THEMES.remaster;
    let el = document.getElementById('aegis-theme');
    if(!el){ el=document.createElement('style'); el.id='aegis-theme'; document.head.appendChild(el) }
    el.textContent = css;
  }
  function smoke(){
    if(document.getElementById('aegis-smoke')) return;
    const s=document.createElement('div'); s.id='aegis-smoke';
    const st=document.createElement('style'); st.textContent = `
      #aegis-smoke{position:fixed;left:0;right:0;bottom:-30px;height:140px;z-index:2;pointer-events:none;opacity:.75;
       background: radial-gradient(120px 60px at 10% 80%, rgba(255,255,255,.05), transparent 60%),
                   radial-gradient(180px 70px at 40% 90%, rgba(255,255,255,.07), transparent 60%),
                   radial-gradient(140px 60px at 70% 85%, rgba(255,255,255,.06), transparent 60%),
                   radial-gradient(200px 80px at 90% 95%, rgba(255,255,255,.05), transparent 60%);
       animation:aeg-smoke 9s ease-in-out infinite;}
      @keyframes aeg-smoke{0%{transform:translate3d(0,0,0) scale(1);opacity:.25}50%{transform:translate3d(30px,-10px,0) scale(1.05);opacity:.35}100%{transform:translate3d(0,-20px,0) scale(1.1);opacity:.20}}`;
    document.head.appendChild(st); document.body.appendChild(s);
  }
  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const b=document.createElement('div'); b.id='aegis-badge';
    b.textContent='Aegis 1.0.0'; b.style.cssText='position:fixed;right:10px;top:10px;z-index:99998;background:linear-gradient(135deg,#0a2e22,#113c2d);border:1px solid rgba(212,175,55,.35);color:#d4af37;padding:6px 10px;border-radius:10px;font:600 12px/1.2 system-ui;user-select:none';
    document.body.appendChild(b);
  }
  function panel(){
    if(document.getElementById('aegis-panel')) return;
    const cur = localStorage.getItem('AEGIS_THEME')||'remaster';
    const w=document.createElement('div'); w.id='aegis-panel';
    w.style.cssText='position:fixed;bottom:76px;right:16px;width:320px;background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:12px;padding:12px;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px/1.35 system-ui,Arial';
    w.innerHTML=`
      <div style="display:flex;justify-content:space-between;align-items:center;gap:8px;">
        <b>Aegis 1.0.0</b>
        <button id="aegis-x" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:6px;padding:2px 8px;cursor:pointer;">×</button>
      </div>
      <div style="margin-top:8px">
        <div style="margin:4px 0 6px;">Motyw:</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;">
          ${['classic','remaster','pirate','dark'].map(k=>'<button class="set-theme" data-key="'+k+'" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer;'+(k===cur?'outline:2px solid #d4af37':'')+'">'+k+'</button>').join('')}
        </div>
      </div>
      <div style="margin-top:10px"><a href="https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js" target="_blank" style="color:#f2d574">RAW userscript</a></div>`;
    document.body.appendChild(w);
    w.querySelector('#aegis-x').onclick=()=>w.remove();
    w.querySelectorAll('.set-theme').forEach(btn=>{
      btn.addEventListener('click',()=>{
        const name=btn.getAttribute('data-key');
        localStorage.setItem('AEGIS_THEME',name);
        applyTheme(name); 
      });
    });
  }
  function fab(){
    if(document.getElementById('aegis-fab')) return;
    const f=document.createElement('div'); f.id='aegis-fab';
    f.style.cssText='position:fixed;right:16px;bottom:16px;width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#d4af37,#f2d574);box-shadow:0 10px 30px rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647;';
    f.innerHTML='<div style="width:28px;height:28px;border-radius:6px;background:#0b1d13"></div>';
    f.onclick=panel; document.body.appendChild(f);
  }
  function assetMap(){
    const base='/assets/';
    const map={
      'branding/logo.png': base+'branding/logo_aegis.png',
      'ships/bireme.png' : base+'ships/ship_green.svg'
    };
    const wrap=(src)=>{ 
      try{ for(const k in map){ if(src.includes(k)) return map[k] } }catch(e){}
      return src;
    };
    const _c=document.createElement; 
    document.createElement=function(tag){
      const el=_c.call(document,tag);
      if((''+tag).toLowerCase()==='img'){
        const _set=el.setAttribute;
        el.setAttribute=function(n,v){ if(n==='src' && typeof v==='string'){ v=wrap(v) } return _set.call(this,n,v) }
      } 
      return el;
    };
    const patch=(root)=> root.querySelectorAll?.('img[src]')?.forEach(i=>i.src=wrap(i.src));
    new MutationObserver(m=>m.forEach(x=>x.addedNodes?.forEach(n=>n.nodeType===1&&patch(n)))).observe(document.documentElement,{childList:true,subtree:true});
    patch(document);
  }

  const theme = localStorage.getItem('AEGIS_THEME')||'remaster';
  applyTheme(theme);
  smoke();
  badge();
  fab();
  assetMap();
})();
'@
WriteUtf8 (Join-Path $Users 'grepolis-aegis.user.js') $userJs
Log "userscript ✓"

# ------------------------------
# README / CHANGELOG (rozbudowane)
# ------------------------------
$readme = @'
<p align="center">
  <img src="./assets/branding/banner.svg" width="920" alt="Aegis banner"/>
</p>

# Aegis — Grepolis Remaster (1.0.0)

Butelkowa zieleń + złoto, **panel** w prawym dolnym rogu, **animowany „smoke”**, **badge**, **AssetMap** (podmiany grafik), 4 motywy (Classic / Remaster / Pirate / Dark).

## Szybki start
1. Zainstaluj Tampermonkey.
2. Otwórz RAW userscript: `userscripts/grepolis-aegis.user.js` (lub link z panelu).
3. Odśwież Grepolis → zobaczysz badge i FAB (złoty kwadrat) → kliknij, aby otworzyć panel (zmiana motywu).

## Co w paczce
- `assets/branding/banner.svg` – baner (forum/GitHub).
- `assets/ships/ship_green.svg`, `assets/ships/ship_pirate.svg` – 2 warianty statków.
- `userscripts/grepolis-aegis.user.js` – userscript (panel, motywy, assetmap, smoke, badge).
- `docs/CHANGELOG.md` – dziennik zmian.
- `forum/post.bbcode.txt` – gotowy post BBCode na forum Grepolis.

## Motywy
- **Classic**: jasny akcent złota na ciemnym tłem.
- **Remaster**: butelkowa zieleń, gradienty, złoto.
- **Pirate**: ciemny kontrast + złote obramowania.
- **Dark**: nowoczesny high-contrast.

## Panel
- Przełączanie motywów.
- Link do RAW userscript (instalacja/aktualizacja w Tampermonkey).

## AssetMap
- Minimalna mapa zamiany (logo, birema → statek).
- Wystarczy podmienić pliki w `assets/`, a zmiany zobaczysz bez grzebania w kodzie.

'@
WriteUtf8 (Join-Path $Docs 'README.md') $readme

$chlog = @'
# CHANGELOG

## 1.0.0
- Pierwsza pełna paczka: userscript (panel, badge, smoke, 4 motywy).
- AssetMap: logo + birema → podmiany z `assets/`.
- Baner SVG + dwa statki (zielony/piracki).
- Installery: BAT/PS1, ZIP + SHA256 + (opcjonalnie) git push.

'@
WriteUtf8 (Join-Path $Docs 'CHANGELOG.md') $chlog

# ------------------------------
# BBCode (forum)
# ------------------------------
$bb = @'
[center][img]https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg[/img]

[size=18][b]Aegis — Grepolis Remaster[/b][/size]
Butelkowa zieleń + złoto • Panel konfiguracji • Animowany smoke • AssetMap • 4 motywy

[b]Instalacja (Tampermonkey):[/b]
1) Zainstaluj Tampermonkey.
2) Otwórz RAW userscript: [url=https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js]klik[/url]
3) Odśwież Grepolis. W prawym dolnym rogu zobaczysz złoty przełącznik (FAB).

[b]Motywy:[/b] Classic • Remaster • Pirate • Dark
[b]AssetMap:[/b] prosta podmiana grafik – wystarczy podmienić pliki w assets/ (logo, statki).

[img]https://raw.githubusercontent.com/KID6767/Aegis/main/assets/ships/ship_green.svg[/img]    [img]https://raw.githubusercontent.com/KID6767/Aegis/main/assets/ships/ship_pirate.svg[/img]
[/center]
'@
WriteUtf8 (Join-Path $Forum 'post.bbcode.txt') $bb
Log "forum bbcode ✓"

# ------------------------------
# build_aegis.ps1 (build ZIP + git)
# ------------------------------
$build = @'
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
'@
WriteUtf8 (Join-Path $Root 'build_aegis.ps1') $build
Log "build script ✓"

# ------------------------------
# Wykonaj build od razu
# ------------------------------
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'build_aegis.ps1')
