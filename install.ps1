#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ───────────────────────── Helpers ─────────────────────────
function Log([string]$msg, [ConsoleColor]$c = [ConsoleColor]::Green){
  $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $prev = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $c
  Write-Host "$ts  $msg"
  $Host.UI.RawUI.ForegroundColor = $prev
}
function Ensure-Dir([string]$path){ if(-not (Test-Path $path)){ New-Item -ItemType Directory -Force -Path $path | Out-Null } }
function Write-Text([string]$path, [string]$content){
  Ensure-Dir (Split-Path -Parent $path)
  $content | Set-Content -Path $path -Encoding UTF8
}
function Write-Base64([string]$path, [string]$b64){
  Ensure-Dir (Split-Path -Parent $path)
  $b64 = ($b64 -replace '\s','').Trim()
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($b64))
}

# ───────────────────────── Root & dirs ─────────────────────
$Root = if($PSScriptRoot){ $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path){ Split-Path -Parent $MyInvocation.MyCommand.Path } else { (Get-Location).Path }
Set-Location $Root
Log "== Aegis Installer ==" Cyan

$dirs = @('assets/branding','userscripts','docs','dist','.tmp','forum')
$dirs | ForEach-Object { Ensure-Dir $_ }
Log "strukturę katalogów ✓"

# ───────────────────────── Assets (SVG/PNG/GIF) ────────────
$bannerSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 260" width="960" height="260">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#0a2e22">
        <animate attributeName="stop-color" values="#0a2e22;#113c2d;#0a2e22" dur="8s" repeatCount="indefinite"/>
      </stop>
      <stop offset="100%" stop-color="#113c2d">
        <animate attributeName="stop-color" values="#113c2d;#0a2e22;#113c2d" dur="8s" repeatCount="indefinite"/>
      </stop>
    </linearGradient>
    <filter id="glow"><feGaussianBlur stdDeviation="3" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
  </defs>
  <rect width="960" height="260" rx="18" fill="url(#g)"/>
  <g filter="url(#glow)">
    <text x="480" y="138" text-anchor="middle" font-family="Georgia,serif" font-size="54" fill="#e7d98b" style="letter-spacing:1.5px">
      AEGIS — Grepolis Remaster
      <animate attributeName="fill" values="#e7d98b;#fff9c4;#e7d98b" dur="3s" repeatCount="indefinite"/>
    </text>
  </g>
  <image href="ship_pirate.svg" x="18"  y="72" width="180" height="116" opacity="0.9">
    <animateTransform attributeName="transform" type="translate" values="0 0; 0 -3; 0 0" dur="4.2s" repeatCount="indefinite"/>
  </image>
  <image href="ship_green.svg"  x="762" y="62" width="180" height="126" opacity="0.9">
    <animateTransform attributeName="transform" type="translate" values="0 0; 0 3; 0 0" dur="4.2s" repeatCount="indefinite"/>
  </image>
</svg>
'@

$shipGreenSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 120" width="200" height="120">
  <rect width="200" height="120" fill="none"/>
  <path d="M10,90 C50,120 150,120 190,90 L165,90 C145,95 55,95 35,90 Z" fill="#2e8b57" stroke="#d4af37" stroke-width="3"/>
  <polygon points="78,28 122,28 98,72" fill="#66bb6a" stroke="#d4af37" stroke-width="2"/>
  <line x1="98" y1="72" x2="98" y2="22" stroke="#d4af37" stroke-width="3"/>
  <circle cx="34" cy="88" r="5" fill="#d4af37">
    <animate attributeName="r" values="5;7;5" dur="2.6s" repeatCount="indefinite"/>
  </circle>
</svg>
'@

$shipPirateSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 120" width="200" height="120">
  <rect width="200" height="120" fill="none"/>
  <path d="M10,90 C50,120 150,120 190,90 L165,90 C145,95 55,95 35,90 Z" fill="#141414" stroke="#8c6f39" stroke-width="3"/>
  <polygon points="75,24 115,24 92,70" fill="#2b2b2b" stroke="#8c6f39" stroke-width="2"/>
  <line x1="92" y1="70" x2="92" y2="20" stroke="#8c6f39" stroke-width="3"/>
  <circle cx="34" cy="88" r="5" fill="#8c6f39">
    <animate attributeName="r" values="5;7;5" dur="2.6s" repeatCount="indefinite"/>
  </circle>
</svg>
'@

# 1x1 PNG (transparent)
$pngGoldDotB64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+WZ1cAAAAASUVORK5CYII='
# 16x16 prosty spinner GIF
$spinnerGifB64 = 'R0lGODlhEAAQAPQAAP///wAAAGZmZlpaWn9/f5mZmdDQ0JmZmX5+fp6enmZmZgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAAQABAAAAWqICCOZGmeaKqubOu+cCzPdF1iQJgWg0iqoXQqv1wA0JQvEJQKp1cQhCFQBAQhQGgDMMFQJgB0CBAw6H2dY0hE9wQGm8CExqQhC5bY0QDCRxgkS8JQ8iCwYkB1XUAAOw=='

Write-Text  'assets/branding/banner.svg'       $bannerSvg
Write-Text  'assets/branding/ship_green.svg'   $shipGreenSvg
Write-Text  'assets/branding/ship_pirate.svg'  $shipPirateSvg
Write-Base64 'assets/branding/gold_dot.png'    $pngGoldDotB64
Write-Base64 'assets/branding/spinner.gif'     $spinnerGifB64
Log "assetów (banner.svg, ship_*.svg, gold_dot.png, spinner.gif) ✓"

# ───────────────────────── Userscript (pełny) ─────────────
$userscript = @'
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
  var VER = "1.0.2";

  function onReady(fn){ if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", fn); else fn(); }
  function toast(msg, ms){ ms = ms||2200; var t=document.createElement("div"); t.textContent=msg; t.style.cssText="position:fixed;left:50%;bottom:60px;transform:translateX(-50%);background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:10px;padding:8px 12px;z-index:2147483647;box-shadow:0 8px 24px rgba(0,0,0,.55);font:13px system-ui"; document.body.appendChild(t); setTimeout(function(){t.remove()}, ms); }

  var THEMES = {
    "classic":
      "body,.gpwindow_content,.game_inner_box,.ui_box{background:#f4e2b2!important;color:#222!important}"+
      "a,.gpwindow_content a{color:#996515!important}",
    "remaster":
      ":root{--aeg-gold:#d4af37}"+
      "body,.gpwindow_content,.game_inner_box,.ui_box{background:#0f1518!important;color:#eee!important}"+
      ".ui-dialog .ui-dialog-titlebar,.game_header{background:#13221a!important;color:#d4af37!important;border-color:#a8832b!important}"+
      ".button,.btn,.ui-button{background:#1b241f!important;color:#d4af37!important;border:1px solid #a8832b!important}",
    "pirate":
      "body,.gpwindow_content,.game_inner_box,.ui_box{background:#0b0b0b!important;color:#d4af37!important}"+
      ".ui-dialog .ui-dialog-titlebar,.game_header{background:#101010!important;color:#d4af37!important;border-color:#d4af37!important}"+
      ".button,.btn,.ui-button{background:#151515!important;color:#d4af37!important;border:1px solid #d4af37!important}"+
      "a,.gpwindow_content a{color:#e5c66a!important}",
    "dark":
      "body,.gpwindow_content,.game_inner_box,.ui_box,.forum_content{background:#111!important;color:#ddd!important}"+
      "a,.gpwindow_content a,.forum_content a{color:#4da6ff!important}"+
      ".button,.btn,.ui-button{background:#333!important;color:#eee!important;border:1px solid #555!important}"
  };

  function applyTheme(name){
    var css = THEMES[name] || THEMES.pirate;
    var s = document.getElementById("aegis-theme"); if(!s){ s=document.createElement("style"); s.id="aegis-theme"; document.head.appendChild(s); }
    s.textContent = css + "#aegis-fab{position:fixed;right:16px;bottom:16px;width:46px;height:46px;border-radius:12px;border:2px solid #d4af37;background:#0f0f0f;color:#d4af37;display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647;box-shadow:0 10px 30px rgba(0,0,0,.55)}"+
      "#aegis-panel{position:fixed;right:16px;bottom:76px;width:320px;padding:12px;border-radius:12px;border:1px solid #d4af37;background:#0f0f0f;color:#d4af37;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px system-ui}"+
      ".aegis-btn{background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer}";
    localStorage.setItem("AEGIS_THEME", name);
    toast("Motyw: "+name);
  }

  function mountFab(){
    if(document.getElementById("aegis-fab")) return;
    var fab = document.createElement("div"); fab.id="aegis-fab"; fab.title="Aegis — ustawienia"; fab.textContent="⚙";
    fab.onclick = mountPanel;
    document.body.appendChild(fab);
    window.addEventListener("keydown", function(e){
      if(e.altKey && !e.ctrlKey && !e.shiftKey){
        if(e.code==="KeyT"){ e.preventDefault(); cycleTheme(); }
        if(e.code==="KeyG"){ e.preventDefault(); mountPanel(); }
      }
    });
  }

  function cycleTheme(){
    var keys=["classic","remaster","pirate","dark"];
    var cur=localStorage.getItem("AEGIS_THEME")||"pirate";
    var i = keys.indexOf(cur); applyTheme(keys[(i+1)%keys.length]);
  }

  function mountPanel(){
    if(document.getElementById("aegis-panel")) return;
    var wrap = document.createElement("div"); wrap.id="aegis-panel";
    wrap.innerHTML =
      "<div style='display:flex;justify-content:space-between;align-items:center;margin-bottom:8px'>"+
        "<b>Aegis "+VER+"</b>"+
        "<button id='aegis-x' class='aegis-btn' style='padding:2px 8px'>×</button>"+
      "</div>"+
      "<div>Motywy:</div>"+
      "<div style='display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-top:6px'>"+
        "<button class='aegis-btn set-theme' data-k='classic'>Classic</button>"+
        "<button class='aegis-btn set-theme' data-k='remaster'>Remaster</button>"+
        "<button class='aegis-btn set-theme' data-k='pirate'>Pirate</button>"+
        "<button class='aegis-btn set-theme' data-k='dark'>Dark</button>"+
      "</div>"+
      "<div style='margin-top:10px'><label style='display:flex;gap:8px;align-items:center;cursor:pointer'><input id='aegis-smoke' type='checkbox' checked/> <span>Animowany dym</span></label></div>"+
      "<div style='margin-top:10px'><label style='display:flex;gap:8px;align-items:center;cursor:pointer'><input id='aegis-fireworks' type='checkbox' checked/> <span>Fajerwerki na start</span></label></div>";
    document.body.appendChild(wrap);
    wrap.querySelectorAll(".set-theme").forEach(function(b){ b.addEventListener("click", function(){ applyTheme(b.getAttribute("data-k")); }); });
    wrap.querySelector("#aegis-x").onclick = function(){ wrap.remove(); };
  }

  // Smoke (subtelne tło)
  function ensureSmoke(){
    if(document.getElementById("aegis-smoke-style")) return;
    var s=document.createElement("style"); s.id="aegis-smoke-style";
    s.textContent = "#aegis-smoke{position:fixed;left:0;right:0;bottom:-28px;height:140px;z-index:1;pointer-events:none;opacity:.75;background: radial-gradient(120px 60px at 10% 80%, rgba(255,255,255,.05), transparent 60%), radial-gradient(180px 70px at 40% 90%, rgba(255,255,255,.07), transparent 60%), radial-gradient(140px 60px at 70% 85%, rgba(255,255,255,.06), transparent 60%), radial-gradient(200px 80px at 90% 95%, rgba(255,255,255,.05), transparent 60%); animation:aegis-smoke 9s ease-in-out infinite;} @keyframes aegis-smoke{0%{transform:translate3d(0,0,0) scale(1);opacity:.25}50%{transform:translate3d(30px,-10px,0) scale(1.05);opacity:.35}100%{transform:translate3d(0,-20px,0) scale(1.1);opacity:.20}}";
    document.head.appendChild(s);
    if(!document.getElementById("aegis-smoke")){ var g=document.createElement("div"); g.id="aegis-smoke"; document.body.appendChild(g); }
  }

  // Prosty „fireworks” na canvas
  function fireworks(ms){
    ms = ms || 2800;
    var c=document.createElement("canvas"), ctx=c.getContext("2d"); Object.assign(c.style,{position:"fixed",inset:"0",zIndex:99999,pointerEvents:"none"});
    document.body.appendChild(c);
    function resize(){ c.width=innerWidth; c.height=innerHeight; }
    resize(); addEventListener("resize", resize);
    var parts=[];
    function boom(x,y){ var n=70; for(var i=0;i<n;i++){ var a=Math.random()*Math.PI*2, s=2+Math.random()*4; parts.push({x:x,y:y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.2,life:60+Math.random()*30}) } }
    for(var j=0;j<4;j++) boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.5*Math.random()));
    var stop=performance.now()+ms;
    (function loop(){
      ctx.clearRect(0,0,c.width,c.height);
      for(var k=0;k<parts.length;k++){ var p=parts[k]; p.vy+=0.045; p.x+=p.vx; p.y+=p.vy; p.life-=1; ctx.globalAlpha=Math.max(0,p.life/90); ctx.beginPath(); ctx.arc(p.x,p.y,2,0,Math.PI*2); ctx.fillStyle="#ffd86b"; ctx.fill(); }
      parts = parts.filter(function(p){return p.life>0});
      if(performance.now()<stop && parts.length) requestAnimationFrame(loop); else c.remove();
    })();
  }

  // AssetMap – podmiana kilku ikon na nasze (inline/base64 lub RAW)
  var RAW_MAP = {
    "branding/banner.svg": "https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg",
    "branding/spinner.gif": "https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/spinner.gif"
  };
  function mapSrc(src){
    try{
      if(!src) return src;
      if(src.indexOf("banner.svg")>-1) return RAW_MAP["branding/banner.svg"];
      if(src.indexOf("spinner")>-1) return RAW_MAP["branding/spinner.gif"];
    }catch(e){}
    return src;
  }
  (function interceptIMG(){
    var orig = document.createElement;
    document.createElement = function(tag){
      var el = orig.call(document, tag);
      if(String(tag).toLowerCase()==="img"){
        var set = el.setAttribute;
        el.setAttribute = function(n,v){ if(n==="src" && typeof v==="string"){ v = mapSrc(v); } return set.call(this,n,v); };
      }
      return el;
    };
    var mo=new MutationObserver(function(m){ m.forEach(function(x){ x.addedNodes && x.addedNodes.forEach(function(n){ if(n.nodeType===1){ n.querySelectorAll && n.querySelectorAll("img[src]").forEach(function(img){ img.src = mapSrc(img.src); }); } }); }); });
    mo.observe(document.documentElement,{childList:true,subtree:true});
  })();

  function welcomeOnce(){
    var k="AEGIS::seen::"+VER; if(localStorage.getItem(k)) return;
    localStorage.setItem(k, Date.now()+"");
    var w=document.createElement("div"); w.id="aegis-welcome"; w.style.cssText="position:fixed;inset:0;z-index:99997;display:flex;align-items:center;justify-content:center;background:radial-gradient(ellipse at center, rgba(0,0,0,.55), rgba(0,0,0,.85));";
    w.innerHTML =
      "<div style='width:min(720px,92vw);color:#f3f3f3;background:linear-gradient(180deg,rgba(10,46,34,.96),rgba(10,46,34,.92));border:1px solid rgba(212,175,55,.35);border-radius:16px;padding:18px 20px;box-shadow:0 10px 30px rgba(0,0,0,.5)'>"+
        "<div style='display:flex;gap:14px;align-items:center;margin-bottom:8px'>"+
          "<div style='width:46px;height:46px;border-radius:10px;background:linear-gradient(135deg,#d4af37,#f2d574);box-shadow:inset 0 2px 6px rgba(0,0,0,.25)'></div>"+
          "<div><h1 style='margin:0;font:800 20px system-ui,Segoe UI,Arial;color:#d4af37'>Aegis "+VER+"</h1>"+
          "<p style='margin:4px 0 0;opacity:.9'>Remaster UI aktywny. Miłej gry!</p></div>"+
        "</div>"+
        "<img src='https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg' style='width:100%;border-radius:12px;border:1px solid rgba(212,175,55,.35)'/>"+
        "<div style='display:flex;gap:10px;margin-top:14px'><button id='aegis-ok' class='aegis-btn' style='padding:8px 14px;background:#111'>Zaczynamy!</button></div>"+
      "</div>";
    document.body.appendChild(w);
    document.getElementById("aegis-ok").onclick=function(){ w.remove(); };
    setTimeout(function(){ fireworks(); }, 120);
  }

  function start(){
    applyTheme(localStorage.getItem("AEGIS_THEME")||"pirate");
    ensureSmoke();
    mountFab();
    welcomeOnce();
    console.log("%c[Aegis] "+VER+" ready","color:#d4af37;font-weight:700");
  }

  onReady(start);
})();
'@

Write-Text 'userscripts/grepolis-aegis.user.js' $userscript
Log "userscript ✓"

# ───────────────────────── Docs / Forum ────────────────────
$README = @'
# Aegis — Grepolis Remaster (1.0.2)

Butelkowa zieleń + złoto, **panel (⚙)**, animowany baner, **AssetMap** (branding), ekran powitalny i fajerwerki.

![banner](assets/branding/banner.svg)

## Instalacja (Tampermonkey)
1) Zainstaluj TM.  
2) Otwórz RAW userscript:  
   `https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js`  
3) Kliknij **Install** i odśwież Grepolis.

## Funkcje
- Motywy: Classic / Remaster / Pirate / Dark (skrót **Alt+T**).
- Panel (prawy-dolny róg, **⚙** / **Alt+G**): motyw, FX (dym/fajerwerki).
- AssetMap: możliwość podmiany brandingu (baner, spinner).
- Ekran powitalny: jednorazowe powitanie nowej wersji.

## Branding (assets/branding/)
- `banner.svg` – animowany nagłówek,
- `ship_green.svg` / `ship_pirate.svg` – ozdobniki,
- `spinner.gif`, `gold_dot.png` – placeholdery / akcenty.

MIT.
'@

$CHANGELOG = @'
# Changelog

## 1.0.2
- Naprawa instalatora (here-stringi, brak interpolacji `${…}`),
- Panel (motywy, FX), dym i fajerwerki,
- AssetMap (branding), intercept IMG + MO,
- Welcome overlay + badge (light).

## 1.0.1
- Wersja wstępna.
'@

$Forum = @'
[center][img]https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg[/img]

[b]Aegis — Grepolis Remaster 2025[/b]

[list]
[*] Motywy: Classic / Remaster / Pirate / Dark
[*] Panel (⚙) — szybka konfiguracja
[*] AssetMap — branding z GitHuba
[*] Ekran powitalny + fajerwerki
[/list]

[b]Instalacja[/b]:
1) Zainstaluj Tampermonkey  
2) Wejdź: [url]https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js[/url] → Install  
3) Odśwież Grepolis

[i]MIT[/i]
[/center]
'@

Write-Text 'docs/README.md'      $README
Write-Text 'docs/CHANGELOG.md'   $CHANGELOG
Write-Text 'forum/forum_post.txt' $Forum
Log "docs + forum ✓"

# ───────────────────────── ZIP + base64 ────────────────────
$FullZip = Join-Path $Root 'dist\Aegis-Full.zip'
$LiteZip = Join-Path $Root 'dist\Aegis-Lite.zip'
if(Test-Path $FullZip){ Remove-Item $FullZip -Force }
if(Test-Path $LiteZip){ Remove-Item $LiteZip -Force }

Compress-Archive -Path 'assets','userscripts','docs','forum' -DestinationPath $FullZip -Force
Compress-Archive -Path 'userscripts' -DestinationPath $LiteZip -Force
Log "ZIPy ✓ ($([IO.Path]::GetFileName($FullZip)), $([IO.Path]::GetFileName($LiteZip)))"

$FullB64 = Join-Path $Root 'dist\aegis-full.b64'
$LiteB64 = Join-Path $Root 'dist\aegis-lite.b64'
[Convert]::ToBase64String([IO.File]::ReadAllBytes($FullZip)) | Set-Content -Encoding ASCII $FullB64
[Convert]::ToBase64String([IO.File]::ReadAllBytes($LiteZip)) | Set-Content -Encoding ASCII $LiteB64
Log "base64 ✓ (aegis-full.b64, aegis-lite.b64)"

# ────────────────────────────────────────────────
# FINISH
# ────────────────────────────────────────────────
Write-Host ""
Log "Aegis $Version — gotowe. Odśwież grę i sprawdź panel ⚙ (Alt+G) / motyw (Alt+T)." ([ConsoleColor]::Green)

Write-Host "Userscript: userscripts\grepolis-aegis.user.js"
Write-Host "Assets:     assets\branding\ (banner.svg, ship_green.svg, ship_pirate.svg, spinner.gif, gold_dot.png)"
Write-Host "Docs:       docs\README.md, docs\CHANGELOG.md"
Write-Host "Forum:      forum\forum_post.txt"
Write-Host ("ZIP:        dist\{0}" -f $ZipName)
