Zawsze pokazuj szczegóły
# Create full Aegis 1.0.0 package with scripts, assets, userscript, docs, and a ZIP.
import os, json, zipfile, hashlib, textwrap, datetime, io, base64, pathlib

root = "/mnt/data/Aegis"
assets = os.path.join(root, "assets")
branding = os.path.join(assets, "branding")
fx = os.path.join(assets, "fx")
themes = os.path.join(assets, "themes")
users = os.path.join(root, "userscripts")
docs = os.path.join(root, "docs")
dist = os.path.join(root, "dist")

for d in [root, assets, branding, fx, themes, users, docs, dist]:
    os.makedirs(d, exist_ok=True)

VERSION = "1.0.0"

# ---------- assets: logo (animated SVG banner), ships (left/right), icon PNG ----------
banner_svg = textwrap.dedent(f"""\
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 260" width="1200" height="260">
  <defs>
    <linearGradient id="g-bg" x1="0" x2="1" y1="0" y2="1">
      <stop offset="0" stop-color="#0a2e22"/>
      <stop offset="1" stop-color="#113c2d"/>
    </linearGradient>
    <linearGradient id="g-gold" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0" stop-color="#f2d574"/>
      <stop offset="1" stop-color="#d4af37"/>
    </linearGradient>
    <filter id="soft" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur in="SourceGraphic" stdDeviation="2" result="b"/>
      <feBlend in="SourceGraphic" in2="b" mode="screen"/>
    </filter>
    <style><![CDATA[
      .title { font: 900 56px/1.1 'Segoe UI',system-ui,Arial; fill: url(#g-gold); filter:url(#soft); letter-spacing: .5px; }
      .ver   { font: 700 16px/1 'Segoe UI',system-ui,Arial; fill: #f3f3f3; opacity:.9 }
      .chip  { fill:#0f1513; stroke:#d4af37; stroke-width:1.2; opacity:.9 }
      .smoke {{ opacity:.4; animation: s 9s ease-in-out infinite; }}
      @keyframes s {{
        0% {{ transform: translate(0,0) scale(1);   opacity:.25 }}
        50%{{ transform: translate(30px,-10px) scale(1.06); opacity:.35 }}
        100%{{ transform: translate(0,-20px) scale(1.1);  opacity:.22 }}
      }}
    ]]></style>
  </defs>
  <rect width="1200" height="260" rx="18" fill="url(#g-bg)"/>
  <g transform="translate(32,50)">
    <g transform="translate(0,120)" class="smoke">
      <ellipse cx="120" cy="52" rx="160" ry="52" fill="#ffffff" opacity=".06"/>
      <ellipse cx="420" cy="62" rx="210" ry="66" fill="#ffffff" opacity=".07"/>
      <ellipse cx="720" cy="54" rx="170" ry="50" fill="#ffffff" opacity=".06"/>
      <ellipse cx="980" cy="70" rx="260" ry="72" fill="#ffffff" opacity=".06"/>
    </g>
    <g transform="translate(140,0)">
      <text class="title">AEGIS</text>
      <rect x="2" y="78" rx="10" width="235" height="28" class="chip"/>
      <text class="ver" x="16" y="98">Grepolis Remaster • v{VERSION} • Bottle Green × Gold</text>
    </g>
    <g transform="translate(0,4)">
      <rect x="0" y="0" width="100" height="100" rx="18" fill="url(#g-gold)"/>
      <rect x="14" y="14" width="72" height="72" rx="12" fill="#0b1d13"/>
      <circle cx="50" cy="50" r="20" fill="url(#g-gold)">
        <animate attributeName="r" values="20;22;20" dur="2.2s" repeatCount="indefinite"/>
      </circle>
    </g>
  </g>
  <!-- Ships left/right -->
  <g transform="translate(20,150)">
    <path d="M0 24 Q40 0 90 10 L86 24 Z" fill="#c8a357"/>
    <path d="M12 8 L12 2 L52 6 L52 12 Z" fill="#e5c66a"/>
    <circle cx="18" cy="16" r="2" fill="#2b1b0a"/>
  </g>
  <g transform="translate(1080,150) scale(-1,1)">
    <path d="M0 24 Q40 0 90 10 L86 24 Z" fill="#c8a357"/>
    <path d="M12 8 L12 2 L52 6 L52 12 Z" fill="#e5c66a"/>
    <circle cx="18" cy="16" r="2" fill="#2b1b0a"/>
  </g>
</svg>
""")

with open(os.path.join(branding, "banner.svg"), "w", encoding="utf-8") as f:
    f.write(banner_svg)

# simple icon png (1x1 gold) as placeholder
icon_png = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8HwQACfsD/QGl7pQAAAAASUVORK5CYII=")
with open(os.path.join(branding, "logo_aegis.png"), "wb") as f:
    f.write(icon_png)

# two decorative ship svgs for docs
ship_left = """<svg xmlns="http://www.w3.org/2000/svg" width="140" height="60" viewBox="0 0 140 60"><path d="M2 46 Q56 6 124 18 L120 46 Z" fill="#c8a357"/><path d="M14 22 L14 8 L70 16 L70 28 Z" fill="#e5c66a"/><circle cx="26" cy="34" r="4" fill="#2b1b0a"/></svg>"""
ship_right = """<svg xmlns="http://www.w3.org/2000/svg" width="140" height="60" viewBox="0 0 140 60"><g transform="translate(140,0) scale(-1,1)"><path d="M2 46 Q56 6 124 18 L120 46 Z" fill="#c8a357"/><path d="M14 22 L14 8 L70 16 L70 28 Z" fill="#e5c66a"/><circle cx="26" cy="34" r="4" fill="#2b1b0a"/></g></svg>"""
with open(os.path.join(branding, "ship_left.svg"), "w") as f: f.write(ship_left)
with open(os.path.join(branding, "ship_right.svg"), "w") as f: f.write(ship_right)

# fx smoke svg (subtle)
smoke_svg = """<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="160"><defs><radialGradient id="g" cx="50%" cy="80%" r="60%"><stop offset="0%" stop-color="#fff" stop-opacity=".08"/><stop offset="100%" stop-color="#fff" stop-opacity="0"/></radialGradient></defs><rect width="1600" height="160" fill="url(#g)"/></svg>"""
with open(os.path.join(fx, "smoke.svg"), "w") as f: f.write(smoke_svg)

# ---------- themes ----------
themes_css = {
"classic.css": """:root{--aeg-gold:#d4af37;--aeg-fg:#f2f2f2;--aeg-bg:#1a1a1a}
body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--aeg-bg)!important;color:var(--aeg-fg)!important}
a{color:#e3c26b!important}.button,.btn,.ui-button{background:#2a2a2a!important;color:#fff!important;border:1px solid #555!important;border-radius:10px}
""",
"remaster.css": """:root{--aeg-green:#0a2e22;--aeg-green-2:#113c2d;--aeg-gold:#d4af37;--aeg-bg:#0e1518;--aeg-fg:#f3f3f3}
@keyframes aegis-glow{0%,100%{box-shadow:0 0 0 rgba(212,175,55,0)}50%{box-shadow:0 0 12px rgba(212,175,55,.45)}}
body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--aeg-bg)!important;color:var(--aeg-fg)!important}
.game_header,.ui-dialog .ui-dialog-titlebar{background:linear-gradient(180deg,var(--aeg-green),var(--aeg-green-2))!important;color:var(--aeg-gold)!important;border-color:rgba(212,175,55,.35)!important}
.button,.btn,.ui-button{background:#122018!important;color:var(--aeg-gold)!important;border:1px solid rgba(212,175,55,.35)!important;box-shadow:0 10px 30px rgba(0,0,0,.55)}
.gp_table th,.gp_table td{border-color:rgba(212,175,55,.35)!important}
""",
"pirate.css": """:root{--aeg-gold:#d4af37;--aeg-bg:#0b0b0b;--aeg-fg:#eee}
body,.gpwindow_content,.game_inner_box,.ui_box{background:#0b0b0b!important;color:#eee!important}
.game_header,.ui-dialog .ui-dialog-titlebar{background:#101010!important;color:#d4af37!important;border-color:#d4af37!important}
.button,.btn,.ui-button{background:#151515!important;color:#d4af37!important;border:1px solid #d4af37!important;box-shadow:0 8px 26px rgba(0,0,0,.6)}
a{color:#e5c66a!important}
""",
"dark.css": """:root{--aeg-bg:#111;--aeg-fg:#ddd;--aeg-ac:#4da6ff}
body,.gpwindow_content,.game_inner_box,.ui_box,.forum_content{background:#111!important;color:#ddd!important}
a,.gpwindow_content a,.forum_content a{color:#4da6ff!important}
.button,.btn,.ui-button{background:#333!important;color:#eee!important;border:1px solid #555!important}
"""
}
for name,css in themes_css.items():
    with open(os.path.join(themes, name), "w") as f: f.write(css)

# ---------- userscript ----------
userscript = textwrap.dedent(f"""\
/* ==UserScript==
@name         Aegis – Grepolis Remaster
@namespace    https://github.com/KID6767/Aegis
@version      {VERSION}
@description  Remaster UI: themes, animated banner, quick panel, smoke, fireworks (optional). Pure UI, no automation.
@author       KID6767 & ChatGPT
@match        https://*.grepolis.com/*
@match        https://*.grepolis.pl/*
@grant        none
@run-at       document-end
==/UserScript== */
(function () {{
  'use strict';
  const VER = '{VERSION}';
  const RAW = 'https://raw.githubusercontent.com/KID6767/Aegis/main/assets';
  const THEMES = {{
    classic: `${{RAW}}/themes/classic.css`,
    remaster: `${{RAW}}/themes/remaster.css`,
    pirate: `${{RAW}}/themes/pirate.css`,
    dark: `${{RAW}}/themes/dark.css`
  }};
  function injectCSS(href,id){{
    if(document.getElementById(id)) return;
    const l=document.createElement('link');
    l.id=id; l.rel='stylesheet'; l.href=href; l.crossOrigin='anonymous';
    document.head.appendChild(l);
  }}
  function inlineStyle(css,id){{
    let el=document.getElementById(id); if(!el){{ el=document.createElement('style'); el.id=id; document.head.appendChild(el);}}
    el.textContent=css;
  }}
  function badge(){{
    if(document.getElementById('aegis-badge')) return;
    const el=document.createElement('div'); el.id='aegis-badge';
    el.textContent='Aegis '+VER;
    el.style.cssText='position:fixed;right:10px;top:10px;z-index:99998;background:linear-gradient(135deg,#0a2e22,#113c2d);border:1px solid rgba(212,175,55,.35);color:#d4af37;padding:6px 10px;border-radius:10px;font:600 12px/1.2 system-ui,Segoe UI,Arial;user-select:none;pointer-events:none;box-shadow:0 8px 24px rgba(0,0,0,.45)';
    document.body.appendChild(el);
  }}
  function smoke(){{
    if(document.getElementById('aegis-smoke')) return;
    const d=document.createElement('div'); d.id='aegis-smoke';
    d.style.cssText='position:fixed;left:0;right:0;bottom:-28px;height:130px;z-index:1;pointer-events:none;background:url('+RAW+'/fx/smoke.svg) center/cover no-repeat;opacity:.8';
    document.body.appendChild(d);
  }}
  function fireworks(ms=2600){{
    const c=document.createElement('canvas'); Object.assign(c.style,{{position:'fixed',inset:'0',zIndex:99999,pointerEvents:'none'}});
    const ctx=c.getContext('2d'); document.body.appendChild(c);
    const DPR=Math.max(1,window.devicePixelRatio||1);
    function resize(){{ c.width=innerWidth*DPR; c.height=innerHeight*DPR; ctx.setTransform(DPR,0,0,DPR,0,0) }}; resize(); addEventListener('resize',resize);
    const parts=[]; function boom(x,y){{ const N=60+Math.floor(Math.random()*50), cols=['#ffd86b','#e6c55e','#f2e5a3','#fff9d2','#fbe6a4']; for(let i=0;i<N;i++){{ const a=Math.random()*Math.PI*2,s=2+Math.random()*4; parts.push({{x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.4,life:60+Math.random()*40,color:cols[i%cols.length]}});}}}}
    for(let i=0;i<4;i++) boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.5*Math.random()));
    const stopAt=performance.now()+ms;
    (function loop(){{
      ctx.clearRect(0,0,innerWidth,innerHeight);
      for(const p of parts){{ p.vy+=0.045; p.x+=p.vx; p.y+=p.vy; p.life-=1; ctx.globalAlpha=Math.max(0,p.life/90); ctx.beginPath(); ctx.arc(p.x,p.y,2,0,Math.PI*2); ctx.fillStyle=p.color; ctx.fill(); }}
      for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1);
      if(performance.now()<stopAt && parts.length) requestAnimationFrame(loop); else c.remove();
    }})();
  }}
  function welcome(){{
    const k='Aegis::seen::'+VER; if(localStorage.getItem(k)) return; localStorage.setItem(k, Date.now());
    const w=document.createElement('div'); w.id='aegis-welcome';
    w.style.cssText='position:fixed;inset:0;z-index:99997;display:flex;align-items:center;justify-content:center;background:radial-gradient(ellipse at center, rgba(0,0,0,.55), rgba(0,0,0,.85))';
    w.innerHTML = '<div style="width:min(860px,94vw);color:#f3f3f3;background:linear-gradient(180deg,rgba(10,46,34,.96),rgba(10,46,34,.92));border:1px solid rgba(212,175,55,.35);border-radius:16px;padding:18px 20px;box-shadow:0 10px 30px rgba(0,0,0,.5)">'+
                  '<div style="display:flex;align-items:center;gap:16px"><img src="'+RAW+'/branding/ship_left.svg" width="120" height="50"/>'+
                  '<div style="flex:1"><img src="'+RAW+'/branding/banner.svg" style="width:100%;height:auto;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,.45)"/></div>'+
                  '<img src="'+RAW+'/branding/ship_right.svg" width="120" height="50"/></div>'+
                  '<div style="margin-top:12px;display:flex;gap:10px;justify-content:flex-end"><button id="aegis-ok" style="background:linear-gradient(180deg,#d4af37,#f2d574);color:#2a2000;border:none;border-radius:12px;padding:10px 16px;font-weight:800;cursor:pointer;box-shadow:0 4px 10px rgba(0,0,0,.35)">Zaczynamy!</button></div>'+
                  '</div>';
    document.body.appendChild(w);
    document.getElementById('aegis-ok').onclick=()=>w.remove();
    setTimeout(()=>fireworks(), 180);
  }}
  function panel(){{
    if(document.getElementById('aegis-fab')) return;
    const fab=document.createElement('div');
    fab.id='aegis-fab';
    fab.title='Aegis — panel';
    fab.style.cssText='position:fixed;right:16px;bottom:16px;width:50px;height:50px;border-radius:14px;background:linear-gradient(135deg,#d4af37,#f2d574);display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647;box-shadow:0 10px 30px rgba(0,0,0,.55)';
    fab.innerHTML='<div style="width:30px;height:30px;border-radius:8px;background:#0b1d13;animation:p 3s infinite"></div><style>@keyframes p{{50%{{filter:brightness(1.18)}}}}</style>';
    document.body.appendChild(fab);
    fab.onclick = ()=>{{
      if(document.getElementById('aegis-panel')) return;
      const wrap=document.createElement('div'); wrap.id='aegis-panel';
      wrap.style.cssText='position:fixed;bottom:76px;right:16px;width:340px;background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:12px;padding:12px;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px/1.35 system-ui,Arial';
      wrap.innerHTML=''+
        '<div style="display:flex;justify-content:space-between;align-items:center;gap:8px"><b>Aegis {VERSION}</b>'+
        '<button id="aegis-close" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:6px;padding:2px 8px;cursor:pointer">×</button></div>'+
        '<div style="margin-top:8px"><div style="margin:4px 0 6px">Motyw:</div>'+
        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px">'+
          ['classic','remaster','pirate','dark'].map(k=>'<button class="set-theme" data-key="'+k+'" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer">'+k+'</button>').join('')+
        '</div></div>'+
        '<div style="margin-top:10px;opacity:.85">Skróty: Alt+T (zmiana motywu), Alt+G (panel)</div>';
      document.body.appendChild(wrap);
      wrap.querySelector('#aegis-close').onclick=()=>wrap.remove();
      wrap.querySelectorAll('.set-theme').forEach(btn=>btn.addEventListener('click',()=>{{ setTheme(btn.dataset.key); wrap.remove(); }}));
    }};
    window.addEventListener('keydown',(e)=>{{ if(e.altKey && !e.shiftKey && !e.ctrlKey){{ if(e.code==='KeyG'){{ e.preventDefault(); fab.click(); }} if(e.code==='KeyT'){{ e.preventDefault(); cycleTheme(); }} }} }});
  }}
  function setTheme(name){{
    localStorage.setItem('AEGIS_THEME', name);
    // remove previous tag if any and load new css
    const old = document.getElementById('aegis-theme-css'); if(old) old.remove();
    const href = THEMES[name] || THEMES.remaster;
    const l = document.createElement('link'); l.id='aegis-theme-css'; l.rel='stylesheet'; l.href=href; l.crossOrigin='anonymous';
    document.head.appendChild(l);
  }}
  function cycleTheme(){{
    const list=['classic','remaster','pirate','dark']; const cur=localStorage.getItem('AEGIS_THEME')||'remaster'; const i=list.indexOf(cur); const next=list[(i+1)%list.length]; setTheme(next);
  }}
  function start(){{
    const theme = localStorage.getItem('AEGIS_THEME') || 'remaster';
    setTheme(theme);
    badge();
    smoke();
    panel();
    welcome();
    console.log('%c[Aegis] {VERSION} ready','color:#d4af37;font-weight:700');
  }}
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded', start); else start();
}})();
""")
with open(os.path.join(users, "grepolis-aegis.user.js"), "w", encoding="utf-8") as f:
    f.write(userscript)

# ---------- docs ----------
readme = textwrap.dedent(f"""\
<p align="center">
  <img src="./assets/branding/banner.svg" width="820" alt="Aegis banner"/>
</p>

<p align="center">
  <img src="./assets/branding/ship_left.svg" width="120" />
  <span style="display:inline-block;width:24px"></span>
  <img src="./assets/branding/ship_right.svg" width="120" />
</p>

# Aegis – Grepolis Remaster (v{VERSION})

Stabilny **remaster UI** do Grepolis: **motywy** (Classic / Remaster / Pirate / Dark), **panel** w prawym dolnym rogu,
**baner z animacją**, **delikatny dym** u dołu, **fajerwerki** na powitanie wersji. **Zero automatyzacji**.

## Instalacja (Tampermonkey)
1. Zainstaluj Tampermonkey.
2. Otwórz raw użytkowy skrypt z repo i zaakceptuj instalację: `userscripts/grepolis-aegis.user.js` (lub RAW GitHub).
3. Odśwież grę – zobaczysz badge wersji, dym i panel (kliknij złote logo).

## Skróty
- `Alt + G` – pokaż/ukryj panel konfiguracyjny.
- `Alt + T` – przełącz motyw.

## Motywy
- Classic • Remaster • Pirate • Dark – lekkie, czytelne, bezpieczne dla oczu.
- Zaokrąglone przyciski i boxy, subtelne cienie, złote akcenty.

## Assety
- Baner: `assets/branding/banner.svg`
- Stateczki: `assets/branding/ship_left.svg`, `assets/branding/ship_right.svg`
- Dym: `assets/fx/smoke.svg`

## Zrzut (mockup)
> baner i statki umieszczamy w panelu powitalnym i README, po bokach animowanego logo.
""")
with open(os.path.join(docs, "README.md"), "w", encoding="utf-8") as f:
    f.write(readme)

changelog = """# Changelog

## 1.0.0
- Pierwsze stabilne wydanie Aegis Remaster.
- Motywy: Classic / Remaster / Pirate / Dark.
- Panel w prawym dolnym rogu (złota kostka).
- Badge wersji w prawym górnym rogu.
- Baner SVG (animacja + statki po bokach).
- Dym u dołu ekranu (subtelny).
- Fajerwerki na powitanie nowej wersji (jednorazowe).
- Userscript zgodny z Tampermonkey (`@run-at document-end`).
- Zero automatyzacji; kosmetyka i UX.
"""
with open(os.path.join(docs, "CHANGELOG.md"), "w", encoding="utf-8") as f:
    f.write(changelog)

# ---------- PowerShell scripts ----------
build_ps1 = textwrap.dedent(f"""\
# Aegis – Grepolis Remaster: BUILD
# Version: {VERSION}

$ErrorActionPreference = 'Stop'

function Log([string]$msg) {{ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Write-Host "$ts  $msg" -ForegroundColor Green }}

$Root = Split-Path -Parent $PSCommandPath
if(-not $Root) {{ $Root = (Get-Location).Path }}

$Assets   = Join-Path $Root 'assets'
$Branding = Join-Path $Assets 'branding'
$Fx       = Join-Path $Assets 'fx'
$Themes   = Join-Path $Assets 'themes'
$Users    = Join-Path $Root 'userscripts'
$Docs     = Join-Path $Root 'docs'
$Dist     = Join-Path $Root 'dist'

$dirs = @($Assets,$Branding,$Fx,$Themes,$Users,$Docs,$Dist)
foreach($d in $dirs){{ if(!(Test-Path $d)){{ New-Item -ItemType Directory -Path $d | Out-Null }} }}

# Repack ZIP
$ZipName = "Aegis-{VERSION}.zip"
$ZipPath = Join-Path $Dist $ZipName
try {{
  if(Test-Path $ZipPath) {{ Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue }}
  Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
  $tmp = Join-Path $Root ("_pkg_" + [Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  Copy-Item $Assets -Destination $tmp -Recurse
  Copy-Item $Users  -Destination $tmp -Recurse
  Copy-Item $Docs   -Destination $tmp -Recurse
  Copy-Item $Themes -Destination $tmp -Recurse
  [IO.Compression.ZipFile]::CreateFromDirectory($tmp, $ZipPath)
  Remove-Item $tmp -Recurse -Force
  Log ("ZIP: " + $ZipPath)
  Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $ZipPath).Hash)
}} catch {{
  Write-Host ("ZIP ERR: " + $_.Exception.Message) -ForegroundColor Red
}}
Log "BUILD OK ✓"
""")
with open(os.path.join(root, "build_aegis.ps1"), "w", encoding="utf-8") as f:
    f.write(build_ps1)

install_ps1 = textwrap.dedent(f"""\
# Aegis – Installer
$ErrorActionPreference = 'Stop'
function Log([string]$msg) {{ $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; Write-Host "$ts  $msg" -ForegroundColor Cyan }}
$Root = Split-Path -Parent $PSCommandPath
if(-not $Root) {{ $Root = (Get-Location).Path }}
try {{
  & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'build_aegis.ps1') | Out-Null
}} catch {{ Write-Host ("BUILD ERR: " + $_.Exception.Message) -ForegroundColor Red }}
$Zip = Join-Path $Root 'dist' 'Aegis-{VERSION}.zip'
if(Test-Path $Zip){{ Log ("ZIP: " + $Zip); Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $Zip).Hash) }} else {{ Write-Host "ZIP not found" -ForegroundColor Red }}
Log "DONE ✓"
""")
with open(os.path.join(root, "install.ps1"), "w", encoding="utf-8") as f:
    f.write(install_ps1)

install_bat = r"""@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
pause
"""
with open(os.path.join(root, "install.bat"), "w", encoding="utf-8") as f:
    f.write(install_bat)

# ---------- also produce a dist zip here ----------
zip_path = os.path.join(dist, f"Aegis-{VERSION}.zip")
def zipdir(path, ziph):
    for base, dirs, files in os.walk(path):
        for file in files:
            full = os.path.join(base, file)
            rel = os.path.relpath(full, root)
            ziph.write(full, rel)

with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zf:
    zipdir(assets, zf)
    zipdir(themes, zf)
    zipdir(users, zf)
    zipdir(docs, zf)

sha256 = hashlib.sha256(open(zip_path,'rb').read()).hexdigest()
(root, zip_path, sha256)

