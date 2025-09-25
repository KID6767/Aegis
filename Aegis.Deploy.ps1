# Aegis.Deploy.ps1
#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Log([string]$msg, [ConsoleColor]$c = [ConsoleColor]::Green){
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $old = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $c
  Write-Host "$ts  $msg"
  $Host.UI.RawUI.ForegroundColor = $old
}
function Warn([string]$msg){ Log $msg ([ConsoleColor]::Yellow) }
function Err([string]$msg){ Log $msg ([ConsoleColor]::Red) }

function Ensure-Dir([string]$p){
  if(-not (Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null }
}
function Write-Text([string]$path, [string]$content){
  Ensure-Dir (Split-Path -LiteralPath $path -Parent)
  $content | Set-Content -Encoding UTF8 -NoNewline -Path $path
}
function Write-Base64([string]$path, [string]$b64){
  Ensure-Dir (Split-Path -LiteralPath $path -Parent)
  [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String(($b64 -replace '\s','')))
}

# ───────── USTAWIENIA
$Version   = '1.0.2'
$Root      = (Get-Location).Path
$Assets    = Join-Path $Root 'assets'
$Branding  = Join-Path $Assets 'branding'
$Users     = Join-Path $Root 'userscripts'
$Docs      = Join-Path $Root 'docs'
$Forum     = Join-Path $Root 'forum'
$Dist      = Join-Path $Root 'dist'

@($Assets,$Branding,$Users,$Docs,$Forum,$Dist) | ForEach-Object { Ensure-Dir $_ }
Log "Structure OK"

# ───────── ASSETY (placeholdery bezpieczne znakowo)
$BannerSvg = @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 880 220">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#0a2e22"/>
      <stop offset="100%" stop-color="#123528"/>
    </linearGradient>
  </defs>
  <rect width="880" height="220" rx="16" fill="url(#g)"/>
  <text x="440" y="118" text-anchor="middle" font-family="Georgia,serif" font-size="34" fill="#d4af37">AEGIS — Grepolis Remaster</text>
</svg>
'@

# 1x1 złota kropka
$GoldPngB64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAocB9yP2LZsAAAAASUVORK5CYII='
# 16x16 prosty spinner
$SpinnerGifB64 = 'R0lGODlhEAAQAMQAAP///wAAAMLCwkJCQmZmZjY2Nk5OTqCgoKioqKOjo6urq7CwsM7Oztra2u/v7+fn5+vr6wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAAAAAAALAAAAAAQABAAAAVVICCOZGmeaKqubOu+cCzPdF1GmUGpIqBQAOw=='
# 16x16 okrągła ikonka (bursztyn) – użyta do przykładowej podmiany UI
$AmberPngB64 = 'iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAAZUlEQVQ4T2NkoBAwUqifYWBg+P//f0YwMDA0hSgYbGZgGJgYQzEwMDCg0yAJg0Zg0GQYw4BKMkC0g0gQk0gqgQm4QJ8gkN4gQ3YgB8yQJk2gCqQ4z8QWgZCkQw4A4VUBWmZy8JmAAAAAElFTkSuQmCC'

Write-Text  (Join-Path $Branding 'banner.svg')     $BannerSvg
Write-Base64 (Join-Path $Branding 'gold_dot.png')  $GoldPngB64
Write-Base64 (Join-Path $Branding 'spinner.gif')   $SpinnerGifB64
Write-Base64 (Join-Path $Branding 'amber_16.png')  $AmberPngB64
Log "Assets OK"

# ───────── USER SCRIPT 1.0.2 (pełny, bez backticków i ${})
$UserJs = @'
// ==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      1.0.2
// @description  Motywy, panel (⚙), zaokrąglenia, poprawki UI (lewy & prawy panel), AssetMap (branding+ikony), dym, fajerwerki, skróty.
// @author       KID6767 & ChatGPT
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @run-at       document-end
// @grant        none
// ==/UserScript==
(function(){
"use strict";
var VER = "1.0.2";

function onReady(fn){ if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded", fn);} else {fn();}}
function toast(m,ms){ms=ms||2000;var t=document.createElement("div");t.textContent=m;t.style.cssText="position:fixed;left:50%;bottom:64px;transform:translateX(-50%);background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:10px;padding:8px 12px;z-index:2147483647;box-shadow:0 8px 24px rgba(0,0,0,.55);font:13px system-ui";document.body.appendChild(t);setTimeout(function(){t.remove();},ms);}

var CFG_KEY = "AEGIS_CFG_V1";
var DEFAULTS = { theme:"pirate", round:true, compactLeft:true, godsRound:true, smoke:true, fireworks:true, assetBranding:true };
function cfg(){ try{ return Object.assign({}, DEFAULTS, JSON.parse(localStorage.getItem(CFG_KEY)||"{}")); }catch(e){ return Object.assign({}, DEFAULTS);}}
function save(part){ var c=cfg(); Object.assign(c, part||{}); localStorage.setItem(CFG_KEY, JSON.stringify(c)); }

var THEMES = {
  classic: "body,.gpwindow_content,.game_inner_box,.ui_box{background:#f4e2b2!important;color:#222!important}a,.gpwindow_content a{color:#996515!important}",
  remaster: "body,.gpwindow_content,.game_inner_box,.ui_box{background:#0f1518!important;color:#eee!important}.ui-dialog .ui-dialog-titlebar,.game_header{background:#13221a!important;color:#d4af37!important;border-color:#a8832b!important}.button,.btn,.ui-button{background:#1b241f!important;color:#d4af37!important;border:1px solid #a8832b!important}",
  pirate: "body,.gpwindow_content,.game_inner_box,.ui_box{background:#0b0b0b!important;color:#d4af37!important}.ui-dialog .ui-dialog-titlebar,.game_header{background:#101010!important;color:#d4af37!important;border-color:#d4af37!important}.button,.btn,.ui-button{background:#151515!important;color:#d4af37!important;border:1px solid #d4af37!important}a,.gpwindow_content a{color:#e5c66a!important}",
  dark: "body,.gpwindow_content,.game_inner_box,.ui_box,.forum_content{background:#111!important;color:#ddd!important}a,.gpwindow_content a,.forum_content a{color:#4da6ff!important}.button,.btn,.ui-button{background:#333!important;color:#eee!important;border:1px solid #555!important}"
};

var CSS_BASE =
  "#aegis-fab{position:fixed;right:16px;bottom:16px;width:46px;height:46px;border-radius:12px;border:2px solid #d4af37;background:#0f0f0f;color:#d4af37;display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647;box-shadow:0 10px 30px rgba(0,0,0,.55)}" +
  "#aegis-panel{position:fixed;right:16px;bottom:76px;width:320px;padding:12px;border-radius:12px;border:1px solid #d4af37;background:#0f0f0f;color:#d4af37;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px system-ui}" +
  ".aegis-btn{background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer}" +
  ".aegis-grid{display:grid;grid-template-columns:1fr 1fr;gap:6px}" +
  ".aegis-row{display:flex;align-items:center;gap:8px;margin-top:8px}";

var CSS_ROUND =
  ".ui-dialog,.ui_box,.game_inner_box,.gpwindow_content,.gpwindow{border-radius:12px!important;overflow:hidden}" +
  ".ui-dialog .ui-dialog-titlebar{border-top-left-radius:12px;border-top-right-radius:12px}" +
  ".ui-tabs .ui-tabs-nav li a{border-radius:10px!important}" +
  ".town_info .unit_icon, .unit_box .unit_icon, .ui_button, .btn, .button {border-radius:10px!important}" +
  "#ui_box .game_inner_box img, .gpwindow_content img{border-radius:8px}";

var CSS_LEFT_COMPACT =
  "#ui_box .game_menu, .game_menu{backdrop-filter:none} " +
  "#ui_box .game_menu .submenu li a, .game_menu .submenu li a{border-radius:10px!important}" +
  ".game_menu .submenu li a:hover{filter:brightness(1.1)}";

var CSS_GODS_ROUND =
  "#ui_box .ui_sidebar_right img, .ui_sidebar_right img{border-radius:10px!important;box-shadow:0 0 0 2px rgba(212,175,55,.35)}";

function applyCSS(){
  var c = cfg();
  var s = document.getElementById("aegis-theme"); if(!s){ s=document.createElement("style"); s.id="aegis-theme"; document.head.appendChild(s);}
  var css = (THEMES[c.theme]||"") + CSS_BASE;
  if(c.round) css += CSS_ROUND;
  if(c.compactLeft) css += CSS_LEFT_COMPACT;
  if(c.godsRound) css += CSS_GODS_ROUND;
  s.textContent = css;
}

function mountFab(){
  if(document.getElementById("aegis-fab")) return;
  var fab = document.createElement("div"); fab.id="aegis-fab"; fab.title="Aegis — ustawienia"; fab.textContent="⚙"; fab.onclick = mountPanel;
  document.body.appendChild(fab);
  window.addEventListener("keydown", function(e){
    if(e.altKey && !e.ctrlKey && !e.shiftKey){
      if(e.code==="KeyT"){ e.preventDefault(); cycleTheme(); }
      if(e.code==="KeyG"){ e.preventDefault(); mountPanel(); }
    }
  });
}

function cycleTheme(){
  var order=["classic","remaster","pirate","dark"];
  var c=cfg(); var i=order.indexOf(c.theme); c.theme=order[(i+1)%order.length]; save({theme:c.theme}); applyCSS(); toast("Motyw: "+c.theme);
}

function mountPanel(){
  if(document.getElementById("aegis-panel")) return;
  var c = cfg();
  var w = document.createElement("div"); w.id="aegis-panel";
  w.innerHTML =
    "<div style='display:flex;justify-content:space-between;align-items:center;margin-bottom:8px'>" +
      "<b>Aegis "+VER+"</b>" +
      "<button id='aegis-x' class='aegis-btn' style='padding:2px 8px'>×</button>" +
    "</div>" +
    "<div>Motywy:</div>" +
    "<div class='aegis-grid'>" +
      "<button class='aegis-btn set-theme' data-k='classic'>Classic</button>" +
      "<button class='aegis-btn set-theme' data-k='remaster'>Remaster</button>" +
      "<button class='aegis-btn set-theme' data-k='pirate'>Pirate</button>" +
      "<button class='aegis-btn set-theme' data-k='dark'>Dark</button>" +
    "</div>" +
    "<div class='aegis-row'><label><input id='aegis-round' type='checkbox'"+(c.round?" checked":"")+"> Zaokrąglaj okna/ikony</label></div>" +
    "<div class='aegis-row'><label><input id='aegis-left' type='checkbox'"+(c.compactLeft?" checked":"")+"> Upiększ lewy panel</label></div>" +
    "<div class='aegis-row'><label><input id='aegis-gods' type='checkbox'"+(c.godsRound?" checked":"")+"> Zaokrąglij panel bogów</label></div>" +
    "<div class='aegis-row'><label><input id='aegis-smoke' type='checkbox'"+(c.smoke?" checked":"")+"> Dym przy dole</label></div>" +
    "<div class='aegis-row'><label><input id='aegis-fw' type='checkbox'"+(c.fireworks?" checked":"")+"> Fajerwerki na start</label></div>" +
    "<div class='aegis-row'><label><input id='aegis-brand' type='checkbox'"+(c.assetBranding?" checked":"")+"> AssetMap (branding)</label></div>";
  document.body.appendChild(w);

  var buttons = w.querySelectorAll(".set-theme");
  for(var i=0;i<buttons.length;i++){ buttons[i].addEventListener("click", function(){ save({theme:this.getAttribute("data-k")}); applyCSS(); toast("Motyw: "+cfg().theme);});}
  w.querySelector("#aegis-round").onchange = function(){ save({round:this.checked}); applyCSS(); };
  w.querySelector("#aegis-left").onchange  = function(){ save({compactLeft:this.checked}); applyCSS(); };
  w.querySelector("#aegis-gods").onchange  = function(){ save({godsRound:this.checked}); applyCSS(); };
  w.querySelector("#aegis-smoke").onchange = function(){ save({smoke:this.checked}); ensureSmoke(); if(!this.checked){ var n=document.getElementById("aegis-smoke"); if(n) n.remove(); } };
  w.querySelector("#aegis-fw").onchange    = function(){ save({fireworks:this.checked}); if(this.checked){ fireworks(1500);} };
  w.querySelector("#aegis-brand").onchange = function(){ save({assetBranding:this.checked}); toast("Branding: "+(this.checked?"ON":"OFF")); };
  w.querySelector("#aegis-x").onclick = function(){ w.remove(); };
}

function ensureSmoke(){
  var c = cfg(); if(!c.smoke) return;
  if(document.getElementById("aegis-smoke-style")==null){
    var s=document.createElement("style"); s.id="aegis-smoke-style";
    s.textContent="#aegis-smoke{position:fixed;left:0;right:0;bottom:-28px;height:140px;z-index:1;pointer-events:none;opacity:.75;background: radial-gradient(120px 60px at 10% 80%, rgba(255,255,255,.05), transparent 60%), radial-gradient(180px 70px at 40% 90%, rgba(255,255,255,.07), transparent 60%), radial-gradient(140px 60px at 70% 85%, rgba(255,255,255,.06), transparent 60%), radial-gradient(200px 80px at 90% 95%, rgba(255,255,255,.05), transparent 60%); animation:aegis-sm 9s ease-in-out infinite;}@keyframes aegis-sm{0%{transform:translate3d(0,0,0) scale(1);opacity:.25}50%{transform:translate3d(30px,-10px,0) scale(1.05);opacity:.35}100%{transform:translate3d(0,-20px,0) scale(1.1);opacity:.20}}";
    document.head.appendChild(s);
  }
  if(!document.getElementById("aegis-smoke")){ var g=document.createElement("div"); g.id="aegis-smoke"; document.body.appendChild(g); }
}

function fireworks(ms){
  ms = ms || 2200;
  var c=document.createElement("canvas"), ctx=c.getContext("2d");
  c.style.position="fixed"; c.style.inset="0"; c.style.zIndex="2147483646"; c.style.pointerEvents="none";
  document.body.appendChild(c);
  function rs(){ c.width=innerWidth; c.height=innerHeight; } rs(); addEventListener("resize", rs);
  var parts=[];
  function boom(x,y){ for(var i=0;i<70;i++){ var a=Math.random()*Math.PI*2, s=2+Math.random()*4; parts.push({x:x,y:y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.2,life:60+Math.random()*30});}}
  for(var j=0;j<3;j++){ boom(innerWidth*(.25+.5*Math.random()), innerHeight*(.35+.4*Math.random()));}
  var stop=performance.now()+ms;
  (function loop(){
    ctx.clearRect(0,0,c.width,c.height);
    for(var k=0;k<parts.length;k++){ var p=parts[k]; p.vy+=0.045; p.x+=p.vx; p.y+=p.vy; p.life-=1; ctx.globalAlpha=Math.max(0,p.life/90); ctx.beginPath(); ctx.arc(p.x,p.y,2,0,Math.PI*2); ctx.fillStyle="#ffd86b"; ctx.fill(); }
    parts = parts.filter(function(p){return p.life>0;});
    if(performance.now()<stop && parts.length){ requestAnimationFrame(loop);} else { c.remove(); }
  })();
}

/* AssetMap – branding + przykład podmiany kilku ikon.
   - banner.svg, spinner.gif z repo
   - prosta podmiana ikon: ścieżki zawierające "gods" lub "settings" → bursztyn (data URL) */
var BRAND = {
  banner: "https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg",
  spinner: "https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/spinner.gif",
  amber16: "data:image/png;base64,REPLACED_BY_DEPLOY" /* wstrzyknięte poniżej z PowerShell */
};
function mapSrc(src){
  try{
    var c=cfg(); if(!c.assetBranding) return src;
    if(!src) return src;
    var s = String(src);
    if(s.indexOf("banner.svg")>-1) return BRAND.banner;
    if(s.indexOf("spinner")>-1) return BRAND.spinner;
    if(s.indexOf("/gods/")>-1 || s.indexOf("god_")>-1 || s.indexOf("settings")>-1){ return BRAND.amber16; }
  }catch(e){}
  return src;
}
(function interceptIMG(){
  var create = document.createElement;
  document.createElement = function(tag){
    var el = create.call(document, tag);
    if(String(tag).toLowerCase()==="img"){
      var set = el.setAttribute;
      el.setAttribute = function(n,v){ if(n==="src" && typeof v==="string"){ v = mapSrc(v); } return set.call(this,n,v); };
    }
    return el;
  };
  var mo=new MutationObserver(function(m){ m.forEach(function(x){ x.addedNodes && x.addedNodes.forEach(function(n){ if(n.nodeType===1){ n.querySelectorAll && n.querySelectorAll("img[src]").forEach(function(img){ img.src = mapSrc(img.src);}); } }); }); });
  mo.observe(document.documentElement,{childList:true,subtree:true});
})();

function welcomeOnce(){
  var key="AEGIS_SEEN_"+VER;
  if(localStorage.getItem(key)) return;
  localStorage.setItem(key, Date.now()+"");
  var c = cfg(); if(!c.fireworks) return;
  setTimeout(function(){ fireworks(2000); }, 150);
}

function start(){
  // wstrzyknięcie base64 bursztynu z PS (zastąpione przy deploy)
  BRAND.amber16 = BRAND.amber16.replace("REPLACED_BY_DEPLOY", window.AEGIS_AMBER_16 || "");
  applyCSS();
  mountFab();
  ensureSmoke();
  welcomeOnce();
  console.log("%c[Aegis] "+VER+" ready","color:#d4af37;font-weight:700");
}

window.AEGIS_AMBER_16 = ""; // zostanie podmienione na data URL przez deploy
onReady(start);
})();
'@

# wstrzykujemy realny data URL bursztynu (z assetu amber_16.png)
$AmberDataUrl = 'data:image/png;base64,' + $AmberPngB64
$UserJs = $UserJs -replace 'window\.AEGIS_AMBER_16 = ""', ('window.AEGIS_AMBER_16 = "' + $AmberPngB64 + '"')

Write-Text (Join-Path $Users 'grepolis-aegis.user.js') $UserJs
Log "Userscript OK"

# ───────── README / CHANGELOG / forum
$README = @'
<p align="center"><img src="./assets/branding/banner.svg" width="880" height="220" alt="Aegis banner"></p>

# Aegis — Grepolis Remaster (1.0.2)

Butelkowa zieleń + złoto, panel ⚙, zaokrąglenia okien i ikon, **dym** przy dolnej krawędzi, **fajerwerki** na start,
oraz **AssetMap** (branding + przykładowe ikony). Wszystkie grafiki do podmiany trzymaj w `assets/branding/`
(podmień 1:1, commit → gra załaduje z RAW).

## Instalacja (Tampermonkey)
1. Zainstaluj TM
2. RAW userscriptu: `https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js`
3. Install / Update, w grze pojawi się ⚙ (Alt+G, Alt+T)

## Funkcje
- Motywy: Classic / Remaster / Pirate / Dark
- Panel ustawień (⚙): zaokrąglenia, lewy panel, panel bogów, dym, fajerwerki, branding
- Skróty: Alt+G (panel), Alt+T (następny motyw)
- AssetMap: `banner.svg`, `spinner.gif`, prosta podmiana ikon (gods/settings → bursztyn 16×16)

MIT • KID6767 & ChatGPT
'@

$CHANGELOG = @'
# Changelog

## 1.0.2
- Panel ⚙ (pełny)
- Zaokrąglenia UI + poprawki lewego i prawego panelu
- Dym przy dole, fajerwerki (welcome-once)
- AssetMap: branding + przykładowe ikony
'@

$ForumBB = @'
[center]
[img]https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg[/img]

[b]Aegis — Grepolis Remaster 1.0.2[/b]
[list]
[*] Motywy: Classic / Remaster / Pirate / Dark
[*] Panel ⚙ (Alt+G), motyw (Alt+T)
[*] Zaokrąglenia, dym, fajerwerki
[*] AssetMap — branding + ikony
[/list]

[i]MIT — KID6767 & ChatGPT[/i]
[/center]
'@

Write-Text (Join-Path $Docs  'README.md')     $README
Write-Text (Join-Path $Docs  'CHANGELOG.md')  $CHANGELOG
Write-Text (Join-Path $Forum 'forum_post.txt') $ForumBB
Log "Docs OK"

# ───────── ZIP
$ZipName = "Aegis-$Version.zip"
$ZipPath = Join-Path $Dist $ZipName
try{
  Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
  if(Test-Path -LiteralPath $ZipPath){ Remove-Item -LiteralPath $ZipPath -Force }
  [IO.Compression.ZipFile]::CreateFromDirectory($Root, $ZipPath)
  Log ("ZIP: " + $ZipPath)
  Log ("SHA-256: " + (Get-FileHash -Algorithm SHA256 $ZipPath).Hash)
}catch{ Warn ("ZIP WARN: " + $_.Exception.Message) }

Log "Aegis 1.0.2 — complete"
Write-Host ""
Write-Host "Userscript: userscripts\\grepolis-aegis.user.js"
Write-Host "Assets:     assets\\branding\\ (banner.svg, spinner.gif, gold_dot.png, amber_16.png)"
Write-Host ("ZIP:       dist\\" + $ZipName)
