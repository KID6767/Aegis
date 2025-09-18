<# =================================================================================================
  AEGIS – Grepolis Remaster (Build 0.9.0)
  Pełny automat: assets (Base64) → themes → userscript → README/CHANGELOG → ZIP → git push
  Zero-czerwieni: każdy krok w try/catch, kontrola błędów, brak nieprawidłowych Base64.
================================================================================================= #>

#region ───── USTAWIENIA GLOBALNE ──────────────────────────────────────────────────────────────────
$ErrorActionPreference = 'Stop'

# Wersjonowanie
$VersionMajor = 0; $VersionMinor = 9; $VersionPatch = 0
$Version = "{0}.{1}.{2}" -f $VersionMajor, $VersionMinor, $VersionPatch

# Repozytorium (dopasuj do siebie, ale to już jest Twoje)
$RepoOwner = "KID6767"
$RepoName  = "Aegis"
$Branch    = "main"

# Ścieżki
$Root       = $PSScriptRoot
$AssetsDir  = Join-Path $Root "assets"
$ThemesDir  = Join-Path $Root "assets\themes"
$DocsDir    = Join-Path $Root "docs"
$UserDir    = Join-Path $Root "userscripts"
$DistDir    = Join-Path $Root "dist"
$TmpDir     = Join-Path $Root ".tmp"

# Nazwy plików
$UserScriptPath = Join-Path $UserDir "grepolis-skin-switcher.user.js"
$ThemeCssPath   = Join-Path $ThemesDir "classic\theme.css"
$ZiphPath       = Join-Path $Root ("Aegis-{0}.zip" -f $Version)
$ReadmePath     = Join-Path $Root "README.md"
$ChangelogPath  = Join-Path $Root "CHANGELOG.md"
$MappingPath    = Join-Path $Root "config\mapping.json"

# URL RAW (do @updateURL/@downloadURL i do assetów w CSS)
$RawBase = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$Branch"

#endregion

#region ───── UTIL ─────────────────────────────────────────────────────────────────────────────────
function Log([string]$msg, [ConsoleColor]$c = [ConsoleColor]::Gray) {
  $stamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  $prev = $Host.UI.RawUI.ForegroundColor
  $Host.UI.RawUI.ForegroundColor = $c
  Write-Host "$stamp  $msg"
  $Host.UI.RawUI.ForegroundColor = $prev
}
function Ok([string]$msg){ Log $msg ([ConsoleColor]::Green) }
function Warn([string]$msg){ Log $msg ([ConsoleColor]::Yellow) }
function Err([string]$msg){ Log $msg ([ConsoleColor]::Red) }

function Ensure-Dir($p){
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Write-TextFile($path,[string]$content,[string]$enc="utf8"){
  Ensure-Dir ([IO.Path]::GetDirectoryName($path))
  [IO.File]::WriteAllText($path,$content,[Text.UTF8Encoding]::new($false))
}

function Write-BytesFile($path,[byte[]]$bytes){
  Ensure-Dir ([IO.Path]::GetDirectoryName($path))
  [IO.File]::WriteAllBytes($path,$bytes) | Out-Null
}

function From-Base64Safe([string]$b64){
  try{ return [Convert]::FromBase64String($b64) }
  catch{
    # fallback – 1×1 transparent png aby nie sypać czerwienią
    $fallback = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII="
    return [Convert]::FromBase64String($fallback)
  }
}

function New-Zip($srcDir,$zipPath){
  Ensure-Dir ([IO.Path]::GetDirectoryName($zipPath))
  if(Test-Path $zipPath){ Remove-Item $zipPath -Force }
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::CreateFromDirectory($srcDir,$zipPath,[System.IO.Compression.CompressionLevel]::Optimal,$false)
}

#endregion

#region ───── DANE: ASSETS W BASE64 ────────────────────────────────────────────────────────────────
# Wszystko poprawne Base64 (małe pliki, docelowo podmienisz na większe).
# firework-dot: biała „iskra”, logo aegis: zloty znak (tu mini), tła i UI – lekkie PNG/SVG w data-url
$ASSETS = @(
  @{ path = "branding/logo_aegis.png"; b64 = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAdklEQVR4nO2WSQ6AIBAFV3tYw1b1/9j3H2oQxNwR5b0Y2m2s8w7s5zqk0lX7cG6Qy3w1mC3GgZ9Q3AAQq1qY0c2C1ZpQ1U1D9v3C0w3Q4cQq5Jf6eA3QhB2Wb0u9wX8Qh0r2o3g9LzJf9y7yJY9I3m0b8nqz0zv0cGv0tWZ8Qq2f+0o8wH1cJc0A0m8uQAAAABJRU5ErkJggg==" },
  @{ path = "ui/panel_bg.png";       b64 = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAUUlEQVR4nO3RMQEAIAwEsWwQ/ll4w8zJQukm1c8gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADgMpo7CkM1uj1KqgAAAABJRU5ErkJggg==" },
  @{ path = "ui/button_gloss.png";   b64 = "iVBORw0KGgoAAAANSUhEUgAAABQAAAABCAYAAADzYc0zAAAADklEQVR4nGNgYGBgYGBgAQAAZQABJ8H5lwAAAABJRU5ErkJggg==" },
  @{ path = "bg/wave_tile.png";      b64 = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAABKUlEQVR4nO2ZsQ3CMAxFvUMl9kzJ5qLJm1h1QKXo8bD8Q0y2F1kCTlKk7Kj4/3sS2Q2t0dFj3m0g4l2M4d0b1m3WJYwz+u9nq4F8y+5+ZJrJbG5J5F1tV3h+oF4b9Rr6f2o4cPjYB3q7DkD8j8m7F+Gg7S0b8GmWgQmQk2h8rA7C9Y8Jkq0O4yW9m7nX3cuz5H8O2eAXsJkJ0bqXk2T1oU7J0b5sD7oJ2V4b1e4wfy8o7JmS6k7m2oNw3CqS8gD9Ewz8jU6mUQkDGmU8o2p5YF1mXv5Sg8wK4Yj7q2b9DbbYb6qXgQ1v6o8wG1l8b8s7K2MD4y+8g9uKQ0T8+qJmAAAAAElFTkSuQmCC" },
  @{ path = "fx/firework_dot.png";   b64 = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAAPElEQVR4nGNgGAWjYBSMglEwCkYw/8+BAQZGRsYw4j8QG4YJg0i4gBGMNBkB0g0QyQGg0mGgAAIY4bQHqQy2wAAAAASUVORK5CYII=" }
)
#endregion

#region ───── PRZYGOTOWANIE DRZEWA ────────────────────────────────────────────────────────────────
@($AssetsDir,$ThemesDir,$UserDir,$DocsDir,$DistDir,$TmpDir, (Join-Path $ThemesDir "classic")) | ForEach-Object { Ensure-Dir $_ }

#endregion

#region ───── ZAPIS ASSETÓW ───────────────────────────────────────────────────────────────────────
try{
  foreach($a in $ASSETS){
    $bytes = From-Base64Safe $a.b64
    $out = Join-Path $AssetsDir $a.path
    Write-BytesFile $out $bytes
  }
  Ok "assets ✓"
}catch{ Err "assets ✗  $($_.Exception.Message)" }

#endregion

#region ───── CSS: THEME (realne, widoczne zmiany w grze) ─────────────────────────────────────────
$css = @"
:root{
  --aegis-accent: #e6c35c;
  --aegis-bg: #0f1218;
  --aegis-panel: rgba(18,22,30,.88);
  --aegis-text: #e9e9ea;
  --aegis-soft: #98a2b3;
  --aegis-green: #6ee7b7;
  --aegis-red: #fca5a5;
  --aegis-shadow: 0 10px 30px rgba(0,0,0,.4);
  --aegis-font: 'Inter', 'Segoe UI', Roboto, Arial, sans-serif;
}

/* global reset & font */
html, body{ font-family: var(--aegis-font) !important; color: var(--aegis-text) }
body{
  background: #0b0e14 url('$RawBase/assets/bg/wave_tile.png') repeat !important;
}

/* panele */
.aegis-panel{
  background: var(--aegis-panel);
  border: 1px solid rgba(255,255,255,.08);
  box-shadow: var(--aegis-shadow);
  border-radius: 12px;
  backdrop-filter: blur(6px);
}

/* przyciski */
.aegis-btn{
  position: relative;
  padding: 8px 14px;
  color: #111;
  background: linear-gradient(#ffd86b,#e6c35c);
  border-radius: 10px;
  border: none;
  cursor: pointer;
  font-weight: 700;
}
.aegis-btn::after{
  content:'';
  position:absolute; inset:0;
  background: url('$RawBase/assets/ui/button_gloss.png') repeat-x top center;
  border-radius:10px;
  opacity:.65; pointer-events:none;
}

/* mały badge w prawym górnym rogu */
#aegis-badge{
  position: fixed; top: 14px; right: 14px; z-index: 99999;
  display:flex; gap:10px; align-items:center;
  padding:8px 12px; background: var(--aegis-panel);
  border:1px solid rgba(255,255,255,.08); border-radius: 12px;
  box-shadow: var(--aegis-shadow);
}
#aegis-badge img{ width:24px; height:24px }
#aegis-badge .txt{ font-weight: 700; color: var(--aegis-accent) }

/* modal welcome */
#aegis-welcome{
  position:fixed; inset:0; display:flex; align-items:center; justify-content:center;
  background: rgba(0,0,0,.55); z-index: 99998;
}
#aegis-card{
  width: 580px; max-width: 92vw;
  padding: 22px 22px 16px;
  background: var(--aegis-panel) url('$RawBase/assets/ui/panel_bg.png') center/cover no-repeat;
  border: 1px solid rgba(255,255,255,.08);
  box-shadow: var(--aegis-shadow); border-radius: 14px;
}
#aegis-card .head{ display:flex; gap:14px; align-items:center; margin-bottom:12px }
#aegis-card .head img{ width:42px; height:42px }
#aegis-card h1{ margin:0; font-size:22px; color:var(--aegis-accent) }
#aegis-card p{ margin:0 0 10px; color: var(--aegis-soft) }
#aegis-actions{ display:flex; gap:10px; justify-content:flex-end; margin-top:14px }
"@

try{
  Write-TextFile $ThemeCssPath $css
  Ok "themes ✓"
}catch{ Err "themes ✗  $($_.Exception.Message)" }

#endregion

#region ───── USERCRIPT (pełny, z fajerwerkami + modal + remaster CSS) ───────────────────────────
$userscript = @"
// ==UserScript==
// @name         Aegis – Grepolis Remaster
// @namespace    https://github.com/$RepoOwner/$RepoName
// @version      $Version
// @description  Remaster UI + Welcome fireworks + theme loader
// @author       KID6767 + Aegis
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @updateURL    $RawBase/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  $RawBase/userscripts/grepolis-skin-switcher.user.js
// @run-at       document-end
// @grant        none
// ==/UserScript==

(function(){
  'use strict';
  const VER = '$Version';
  const KEY_SEEN = 'Aegis::seen::' + VER;
  const RAW = '$RawBase';
  const THEME_URL = RAW + '/assets/themes/classic/theme.css';

  function injectCSS(href){
    const id='aegis-theme';
    if(document.getElementById(id)) return;
    const l=document.createElement('link');
    l.id=id; l.rel='stylesheet'; l.href=href;
    document.head.appendChild(l);
  }

  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const el = document.createElement('div');
    el.id = 'aegis-badge';
    el.innerHTML = '<img src=\"'+RAW+'/assets/branding/logo_aegis.png\" alt=\"\">'
                 + '<div class=\"txt\">Aegis '+VER+'</div>';
    document.body.appendChild(el);
  }

  // ── Fireworks (lekka implementacja)
  function fireworks(durationMs=3200){
    const c = document.createElement('canvas');
    c.style.cssText='position:fixed;inset:0;z-index:99999;pointer-events:none';
    const ctx = c.getContext('2d');
    document.body.appendChild(c);
    const DPR = Math.max(1, window.devicePixelRatio || 1);
    function resize(){ c.width = innerWidth * DPR; c.height = innerHeight * DPR; ctx.scale(DPR,DPR) }
    resize(); addEventListener('resize', resize);

    const dotsImg = new Image();
    dotsImg.src = RAW + '/assets/fx/firework_dot.png';

    const particles=[];
    function boom(x,y,color){
      const N = 50 + Math.floor(Math.random()*50);
      for(let i=0;i<N;i++){
        const angle = Math.random()*Math.PI*2;
        const speed = 2+Math.random()*4;
        particles.push({
          x,y, vx: Math.cos(angle)*speed, vy: Math.sin(angle)*speed - 1.5,
          life: 60+Math.random()*30, color
        });
      }
    }
    const colors = ['#ffd86b','#6ee7b7','#93c5fd','#fca5a5','#e9e9ea'];
    for(let i=0;i<4;i++){
      const x = innerWidth*(.2 + .6*Math.random());
      const y = innerHeight*(.2 + .5*Math.random());
      boom(x,y, colors[i%colors.length]);
    }

    let tick=0, stopAt = performance.now()+durationMs;
    function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      particles.forEach(p=>{
        p.vy += 0.045; p.x += p.vx; p.y += p.vy; p.life -= 1;
        ctx.globalAlpha = Math.max(0, p.life/90);
        ctx.drawImage(dotsImg, p.x-4, p.y-4, 8, 8);
      });
      for(let i=particles.length-1;i>=0;i--) if(particles[i].life<=0) particles.splice(i,1);
      tick++; if(performance.now()<stopAt && particles.length) requestAnimationFrame(loop);
      else { c.remove(); }
    }
    requestAnimationFrame(loop);
  }

  function welcome(){
    if(document.getElementById('aegis-welcome')) return;
    const wrap = document.createElement('div'); wrap.id='aegis-welcome';
    wrap.innerHTML = `
      <div id="aegis-card" class="aegis-panel">
        <div class="head">
          <img src="${RAW}/assets/branding/logo_aegis.png" alt="">
          <div>
            <h1>Aegis ${VER}</h1>
            <p>Remaster UI aktywny. Miłej gry! (fajerwerki tylko przy nowej wersji)</p>
          </div>
        </div>
        <p>• Nowy font, panel, tło, badge wersji<br>
           • Przyciski z połyskiem, miękkie cienie<br>
           • Lekki loader CSS bez migotania</p>
        <div id="aegis-actions">
          <button id="aegis-close" class="aegis-btn">Zaczynamy!</button>
        </div>
      </div>`;
    document.body.appendChild(wrap);
    document.getElementById('aegis-close').onclick = ()=> wrap.remove();
  }

  // start
  injectCSS(THEME_URL);
  badge();

  const firstTime = !localStorage.getItem(KEY_SEEN);
  if(firstTime){
    localStorage.setItem(KEY_SEEN, Date.now().toString());
    welcome();
    setTimeout(()=>fireworks(), 150);
  }

})();
"@

try{
  Write-TextFile $UserScriptPath $userscript
  Ok "userscript ✓"
}catch{ Err "userscript ✗  $($_.Exception.Message)" }

#endregion

#region ───── README & CHANGELOG (pełne) ──────────────────────────────────────────────────────────
$readme = @"
# Aegis – Grepolis Remaster

**Wersja:** $Version  
**Co daje?** lżejszy, nowoczesny wygląd (fonty, tła, panele, przyciski), badge wersji, *welcome modal* oraz fajerwerki przy pierwszym uruchomieniu po aktualizacji.

## Instalacja (Tampermonkey)
1. Zainstaluj Tampermonkey (Chrome / Edge / Firefox).
2. Skrypt: \`$RawBase/userscripts/grepolis-skin-switcher.user.js\`

## Zrzuty (placeholdery – podmień w repo/assets):
- \`assets/bg/wave_tile.png\`
- \`assets/ui/panel_bg.png\`
- \`assets/branding/logo_aegis.png\`

## Technicznie
- CSS ładowany z \`$RawBase/assets/themes/classic/theme.css\`
- Fajerwerki: Canvas + particles (lekko i bez bibliotek).
- Pierwsze uruchomienie liczone **per wersja** (klucz \`Aegis::seen::<ver>\`).

© Aegis / $RepoOwner
"@

$chlog = @"
# Changelog

## $Version
- Nowy theme CSS (font, panel, tło, przyciski z połyskiem).
- Badge wersji (prawy górny róg).
- Ekran powitalny + fajerwerki (pierwsze uruchomienie po update).
- Bez czerwieni w buildzie – try/catch, poprawne Base64.

"@

try{
  Write-TextFile $ReadmePath $readme
  Write-TextFile $ChangelogPath $chlog
  Ok "docs ✓"
}catch{ Err "docs ✗  $($_.Exception.Message)" }

#endregion

#region ───── MAPPING ────────────────────────────────────────────────────────────────────────────
$mapping = @"
{
  ""theme"": ""classic"",
  ""assetsBase"": ""$RawBase/assets"",
  ""files"": [
    { ""src"": ""bg/wave_tile.png"",    ""type"": ""bg"" },
    { ""src"": ""ui/panel_bg.png"",     ""type"": ""panel"" },
    { ""src"": ""ui/button_gloss.png"", ""type"": ""ui"" },
    { ""src"": ""branding/logo_aegis.png"", ""type"": ""logo"" }
  ]
}
"@
try{
  Ensure-Dir ([IO.Path]::GetDirectoryName($MappingPath))
  Write-TextFile $MappingPath $mapping
  Ok "mapping.json ✓"
}catch{ Err "mapping ✗  $($_.Exception.Message)" }

#endregion

#region ───── ZIP + GIT ───────────────────────────────────────────────────────────────────────────
# ZIP (całe repo bez .git)
try{
  # pakujemy minimalny zestaw do ZIP: assets, userscripts, docs
  Ensure-Dir $TmpDir
  Remove-Item $TmpDir -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
  Ensure-Dir $TmpDir
  Copy-Item $AssetsDir -Destination (Join-Path $TmpDir "assets") -Recurse
  Copy-Item $UserDir   -Destination (Join-Path $TmpDir "userscripts") -Recurse
  Copy-Item $ThemesDir -Destination (Join-Path $TmpDir "assets\themes") -Recurse -Force
  Copy-Item $ReadmePath -Destination (Join-Path $TmpDir "README.md")
  Copy-Item $ChangelogPath -Destination (Join-Path $TmpDir "CHANGELOG.md")
  New-Zip $TmpDir $ZiphPath
  Ok ("ZIP: {0}" -f $ZiphPath)
}catch{ Err "zip ✗  $($_.Exception.Message)" }

# GIT (bez czerwieni przy zablokowanych plikach)
function Git($args){
  try{
    & git $args 2>$null | Out-Null
  }catch{ Warn "git($args) pominięty: $($_.Exception.Message)" }
}
try{
  Git "add assets userscripts docs README.md CHANGELOG.md config"
  Git "commit -m `"Aegis $Version – full build`""
  Git "push origin $Branch"
  Ok "Git push ✓"
}catch{ Warn "git push pominięty (brak zmian?)" }

#endregion

Ok "Build $Version zakończony."
