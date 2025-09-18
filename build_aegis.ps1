# Aegis build script 0.9.0 — full, safe, verbose
$ErrorActionPreference = "Stop"

function Log([string]$msg){
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "$ts  $msg"
}

function Ensure-Dir([string]$path){
  if(-not (Test-Path $path)){ New-Item -ItemType Directory -Force -Path $path | Out-Null }
}

function Write-TextFileUtf8([string]$path, [string]$content){
  # UTF8 without BOM
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($path, $content, $enc)
}

function Sha256([string]$path){
  if(-not (Test-Path $path)){ return "" }
  $h = Get-FileHash -Algorithm SHA256 -Path $path
  return $h.Hash.ToUpperInvariant()
}

# ————————————————————————————————————————————————————————————————————————
# USTAWIENIA
# ————————————————————————————————————————————————————————————————————————
$Version        = "0.9.0"
$RepoRoot       = (Get-Location).Path
$AssetsDir      = Join-Path $RepoRoot "assets"
$ThemesDir      = Join-Path $AssetsDir "themes"
$BrandingDir    = Join-Path $AssetsDir "branding"
$FxDir          = Join-Path $AssetsDir "fx"
$ShotsDir       = Join-Path $AssetsDir "screenshots"
$UserScriptsDir = Join-Path $RepoRoot "userscripts"
$DistDir        = Join-Path $RepoRoot "dist"
$DocsDir        = $RepoRoot

Ensure-Dir $AssetsDir
Ensure-Dir $ThemesDir
Ensure-Dir $BrandingDir
Ensure-Dir $FxDir
Ensure-Dir $ShotsDir
Ensure-Dir $UserScriptsDir
Ensure-Dir $DistDir

# ————————————————————————————————————————————————————————————————————————
# PLACEHOLDERY PNG (Base64) — walidacja i auto-padding
# ————————————————————————————————————————————————————————————————————————
# 1×1 PNG (transparent) — poprawny Base64
$PNG1x1 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+WZ1cAAAAASUVORK5CYII="

# delikatny „punkt” 8×8 (widoczny dla fajerwerków) — poprawny Base64
$PNGDot8 = @"
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAYAAADED76LAAAAJklEQVQoU2NkQAKMDIwM/8+ABQYGBiBQ
rEAGQwMjAxGgQmIBwAA1j0B6zXkM0sAAAAASUVORK5CYII=
"@.Trim()

# Utility: bezpieczny zapis Base64 (+ auto-padding)
function SafeWrite-Base64([string]$b64, [string]$outPath){
  try{
    $s = ($b64 -replace "\s","") # usuń whitespace
    $mod = ($s.Length % 4)
    if($mod -ne 0){ $s = $s + ("=" * (4 - $mod)) }
    $bytes = [Convert]::FromBase64String($s)
    [System.IO.File]::WriteAllBytes($outPath, $bytes)
  } catch {
    # jeśli coś jednak się wywali — wstaw 1×1
    $fallback = [Convert]::FromBase64String($PNG1x1)
    [System.IO.File]::WriteAllBytes($outPath, $fallback)
  }
}

# Zasoby wymagane przez userscript (logo + kropka do fajerwerków)
$LogoGifPath = Join-Path $BrandingDir "logo_aegis.gif"
$LogoPngPath = Join-Path $BrandingDir "logo_aegis.png"
$DotPngPath  = Join-Path $FxDir       "firework_dot.png"

# prosty „logo” (użyjemy PNG 1×1 – w README wstawimy mini animacje CSS)
SafeWrite-Base64 $PNG1x1 $LogoGifPath
SafeWrite-Base64 $PNG1x1 $LogoPngPath
SafeWrite-Base64 $PNGDot8 $DotPngPath

# Screeny placeholder (4 sztuki, 1280×720 rysowane jeśli .NET dostępny)
$screenDefs = @(
  @{file="classic_port.png";    text="Classic – Port (fale + UI)"},
  @{file="pirate_ui.png";       text="Pirate–Epic – UI (ogień, puls)"},
  @{file="emerald_buildings.png";text="Emerald – Budynki (aura, świeczki)"},
  @{file="world_map.png";       text="Mapa świata – mgiełka"}
)

$drawOk = $true
try { Add-Type -AssemblyName System.Drawing -ErrorAction Stop } catch { $drawOk = $false }
foreach($s in $screenDefs){
  $p = Join-Path $ShotsDir $s.file
  if($drawOk){
    $bmp = New-Object System.Drawing.Bitmap 1280,720
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::FromArgb(20,24,32))
    $f = New-Object System.Drawing.Font "Segoe UI Semibold", 44
    $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(240,240,240))
    $g.DrawString($s.text,$f,$br,60,320)
    $bmp.Save($p,[System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose(); $f.Dispose(); $br.Dispose()
  } else {
    $s.text | Out-File -FilePath $p -Encoding utf8
  }
}
Log "screenshots ✓"

# ————————————————————————————————————————————————————————————————————————
# THEMES — minimalne, ale widoczne różnice + badge + welcome overlay
# ————————————————————————————————————————————————————————————————————————
Ensure-Dir (Join-Path $ThemesDir "classic")
Ensure-Dir (Join-Path $ThemesDir "pirate-epic")
Ensure-Dir (Join-Path $ThemesDir "emerald")

$CommonCss = @"
@font-face{
  font-family:'AegisUI';
  src:local('Segoe UI'), local('Arial');
  font-weight:400; font-style:normal;
}
:root{
  --aegis-accent:#6ee7b7;
  --aegis-bg:#10141b;
  --aegis-card:#161b24;
  --aegis-text:#e6e7eb;
  --aegis-gloss:linear-gradient(180deg,rgba(255,255,255,.18),rgba(255,255,255,0));
}
#aegis-badge{
  position:fixed; right:12px; top:12px; z-index:99999;
  display:flex; align-items:center; gap:8px;
  padding:6px 10px; border-radius:10px;
  background:rgba(0,0,0,.55); backdrop-filter: blur(6px);
  box-shadow:0 8px 18px rgba(0,0,0,.35);
  color:var(--aegis-text); font:12px/1 AegisUI, sans-serif;
  border:1px solid rgba(255,255,255,.12);
}
#aegis-badge img{ width:20px;height:20px; border-radius:4px }
#aegis-badge .txt{ opacity:.9 }
#aegis-welcome{
  position:fixed; inset:0; z-index:99998;
  background:radial-gradient(60% 60% at 50% 40%, rgba(30,40,58,.9), rgba(10,14,20,.95));
  display:grid; place-items:center; font-family:AegisUI, sans-serif;
}
.aegis-panel{
  width:min(680px, 92vw);
  background:var(--aegis-card);
  color:var(--aegis-text);
  border-radius:18px; padding:22px 22px;
  box-shadow:0 24px 60px rgba(0,0,0,.45), inset 0 1px rgba(255,255,255,.06);
  border:1px solid rgba(255,255,255,.1);
}
.aegis-panel .head{ display:flex; gap:16px; align-items:center; }
.aegis-panel .head img{ width:52px;height:52px; border-radius:8px }
.aegis-panel h1{ margin:0; font-size:22px }
.aegis-btn{
  appearance:none; border:0; cursor:pointer;
  padding:10px 16px; border-radius:12px; font-weight:600;
  background:
    var(--aegis-gloss),
    linear-gradient(180deg, #45d4a4, #22b36f 65%);
  color:#0d1b16;
  box-shadow:0 10px 22px rgba(34,179,111,.35), inset 0 1px rgba(255,255,255,.28);
}
.aegis-btn:hover{ transform:translateY(-1px) scale(1.01) }
.aegis-btn:active{ transform:translateY(0) scale(.99) }

body, .ui_game, #main_container{ font-family:AegisUI, sans-serif !important }
"@

$ClassicCss = $CommonCss + @"
body{ background:#0c1117 url('../../screenshots/classic_port.png') center/cover fixed no-repeat }
"@

$PirateCss = $CommonCss + @"
:root{ --aegis-accent:#eab308 }
body{ filter:saturate(1.08) contrast(1.04) hue-rotate(-12deg);
      background:#0b0b0d url('../../screenshots/pirate_ui.png') center/cover fixed no-repeat }
.aegis-btn{
  background:
    var(--aegis-gloss),
    linear-gradient(180deg, #f8d148, #b78109 65%);
  color:#1a1302;
}
"@

$EmeraldCss = $CommonCss + @"
:root{ --aegis-accent:#34d399 }
body{ background:#07140d url('../../screenshots/emerald_buildings.png') center/cover fixed no-repeat }
"@

Write-TextFileUtf8 (Join-Path $ThemesDir "classic\theme.css")       $ClassicCss
Write-TextFileUtf8 (Join-Path $ThemesDir "pirate-epic\theme.css")   $PirateCss
Write-TextFileUtf8 (Join-Path $ThemesDir "emerald\theme.css")       $EmeraldCss
Log "themes ✓"

# ————————————————————————————————————————————————————————————————————————
# USERSCRIPT — badge, welcome, fajerwerki, loader CSS (classic jako default)
# ————————————————————————————————————————————————————————————————————————
$RAW = "https://raw.githubusercontent.com/KID6767/Aegis/main"
$ThemeDefault = "$RAW/assets/themes/classic/theme.css"
$LogoRaw      = "$RAW/assets/branding/logo_aegis.png"

$UserScript = @"
// ==UserScript==
// @name         Aegis – Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      $Version
// @description  Remaster UI + Welcome fireworks + theme loader
// @author       KID6767 + Aegis
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @run-at       document-end
// @grant        none
// ==/UserScript==

(function(){
  'use strict';
  const VER = '$Version';
  const RAW = '$RAW';
  const THEME_DEFAULT = '$ThemeDefault';
  const KEY_SEEN = 'Aegis::seen::' + VER;
  const KEY_THEME = 'Aegis::theme';

  function injectCSS(href){
    const id='aegis-theme';
    const old=document.getElementById(id);
    if(old && old.href===href) return;
    if(old) old.remove();
    const l=document.createElement('link');
    l.id=id; l.rel='stylesheet'; l.href=href; l.type='text/css';
    document.head.appendChild(l);
  }

  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const el = document.createElement('div');
    el.id = 'aegis-badge';
    el.innerHTML = '<img src="'+RAW+'/assets/branding/logo_aegis.png" alt="Aegis">'
                 + '<div class="txt">Aegis '+VER+'</div>';
    document.body.appendChild(el);
  }

  // bardzo lekki pokaz — bez obrazków zewnętrznych (rysunek kółek)
  function fireworks(durationMs=2800){
    const c = document.createElement('canvas');
    c.style.cssText='position:fixed;inset:0;z-index:99999;pointer-events:none';
    document.body.appendChild(c);
    const ctx = c.getContext('2d');
    const DPR = Math.max(1, window.devicePixelRatio || 1);
    function resize(){
      c.width = innerWidth * DPR; c.height = innerHeight * DPR;
      ctx.setTransform(DPR,0,0,DPR,0,0);
    }
    resize(); addEventListener('resize', resize);

    const parts=[];
    function boom(x,y,color){
      const N = 60 + (Math.random()*60|0);
      for(let i=0;i<N;i++){
        const a = Math.random()*Math.PI*2, s=2+Math.random()*3.8;
        parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.2,life:70+Math.random()*30,color});
      }
    }
    const palette=['#fcd34d','#34d399','#93c5fd','#fca5a5','#e5e7eb'];
    for(let i=0;i<4;i++){
      boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.45*Math.random()), palette[i%palette.length]);
    }

    const end = performance.now()+durationMs;
    (function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      parts.forEach(p=>{
        p.vy += 0.045; p.x += p.vx; p.y += p.vy; p.life -= 1;
        ctx.globalAlpha = Math.max(0,p.life/100);
        ctx.beginPath(); ctx.arc(p.x,p.y,1.6,0,Math.PI*2); ctx.fillStyle=p.color; ctx.fill();
      });
      for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1);
      if(performance.now()<end && parts.length) requestAnimationFrame(loop);
      else c.remove();
    })();
  }

  function welcome(){
    if(document.getElementById('aegis-welcome')) return;
    const wrap = document.createElement('div'); wrap.id='aegis-welcome';
    wrap.innerHTML =
      '<div id="aegis-card" class="aegis-panel">'+
        '<div class="head">'+
          '<img src="'+RAW+'/assets/branding/logo_aegis.png" alt="">'+
          '<div><h1>Aegis '+VER+'</h1>'+
          '<p>Remaster UI aktywny. Fajerwerki uruchamiane przy pierwszym starcie tej wersji.</p></div>'+
        '</div>'+
        '<p>• Nowy font, panel, tło, badge wersji<br>• Przyciski z połyskiem, miękkie cienie<br>• Lekki loader CSS</p>'+
        '<div id="aegis-actions">'+
          '<button id="aegis-close" class="aegis-btn">Zaczynamy!</button>'+
        '</div>'+
      '</div>';
    document.body.appendChild(wrap);
    document.getElementById('aegis-close').onclick = ()=> wrap.remove();
  }

  // prosta selekcja motywu via localStorage (classic/pirate-epic/emerald)
  function currentThemeUrl(){
    const t = localStorage.getItem(KEY_THEME) || 'classic';
    return RAW + '/assets/themes/'+t+'/theme.css';
  }

  // inicjalizacja
  injectCSS(currentThemeUrl());
  badge();

  const firstTime = !localStorage.getItem(KEY_SEEN);
  if(firstTime){
    localStorage.setItem(KEY_SEEN, Date.now().toString());
    welcome();
    setTimeout(()=>fireworks(), 120);
  }

  // mini panel przełączania motywu (Ctrl+Alt+T)
  addEventListener('keydown', (e)=>{
    if(e.ctrlKey && e.altKey && e.key.toLowerCase() === 't'){
      const order=['classic','pirate-epic','emerald'];
      const now = localStorage.getItem(KEY_THEME) || 'classic';
      const idx = (order.indexOf(now)+1) % order.length;
      const next = order[idx];
      localStorage.setItem(KEY_THEME', next); // fix quote typo? (we will correct below)
    }
  });
})();
"@

# mała korekta — uniknijmy literówek po złożeniu
$UserScript = $UserScript -replace "localStorage\.setItem\(KEY_THEME', next\);","localStorage.setItem(KEY_THEME, next); injectCSS(RAW+'/assets/themes/'+next+'/theme.css');"

$UserJsPath = Join-Path $UserScriptsDir "grepolis-skin-switcher.user.js"
Write-TextFileUtf8 $UserJsPath $UserScript
Log "userscript ✓"

# ————————————————————————————————————————————————————————————————————————
# README — ładne, z obrazkami (animację logo robimy CSS-em w HTML markdown)
# ————————————————————————————————————————————————————————————————————————
$Readme = @"
<div align="center">
  <img src="assets/branding/logo_aegis.png" width="96" style="border-radius:12px;animation:aegisPulse 2.6s ease-in-out infinite;">
  <h1>Aegis – Grepolis Remaster</h1>
  <p>Motywy, UI 2025, ekran powitalny, fajerwerki ✨</p>
</div>

<style>
@keyframes aegisPulse{0%{filter:drop-shadow(0 0 0 rgba(110,231,183,.0))}50%{filter:drop-shadow(0 0 16px rgba(110,231,183,.45))}100%{filter:drop-shadow(0 0 0 rgba(110,231,183,.0))}}
</style>

---

## Funkcje
- Nowy motyw CSS (czcionki, panel, tło, przyciski z połyskiem).
- Wersja odznaki (prawy górny róg).
- Ekran powitalny + fajerwerki (pierwsze uruchomienie po aktualizacji).
- 3 motywy: **classic**, **pirate-epic**, **emerald**; skrót: <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd>.
- Loader CSS bez migotania.

## Instalacja
- Zainstaluj Tampermonkey.
- Otwórz userscript:  
  `https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js`
- Wejdź do Grepolis → zobaczysz ekran powitalny i badge wersji.  
- Przełączanie motywu: <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>T</kbd>.

## Zrzuty (placeholdery)
<p>
  <img src="assets/screenshots/classic_port.png" width="360">
  <img src="assets/screenshots/pirate_ui.png" width="360">
  <img src="assets/screenshots/emerald_buildings.png" width="360">
</p>

---
"@
Write-TextFileUtf8 (Join-Path $RepoRoot "README.md") $Readme
Log "README ✓"

# ————————————————————————————————————————————————————————————————————————
# CHANGELOG — pełny, narastający
# ————————————————————————————————————————————————————————————————————————
$Changelog = @"
# Dziennik zmian

## 0.9.0
- Nowy motyw CSS (czcionka, panel, tło, przyciski z połyskiem).
- Wersja odznaki (prawy górny róg).
- Ekran powitalny + fajerwerki (pierwsze uruchomienie po aktualizacji).
- 3 motywy: classic, pirate-epic, emerald (skrót Ctrl+Alt+T).
- Zaostrzone zabezpieczenia Base64 (walidacja + padding).

## 0.8.1
- Naprawione ścieżki assets.
- Obsługa błędów FromBase64String (try/catch + fallback).
- README/CHANGELOG generowane w buildzie.
- SHA-256 dla ZIP.

## 0.8.0
- Pierwszy stabilny build buildera.
- Userscript z loaderem CSS.
- Mapa zasobów (wstępna).
"@
Write-TextFileUtf8 (Join-Path $RepoRoot "CHANGELOG.md") $Changelog
Log "CHANGELOG ✓"

# ————————————————————————————————————————————————————————————————————————
# ZIP + SHA256
# ————————————————————————————————————————————————————————————————————————
$ZipName = "Aegis-$Version.zip"
$ZipPath = Join-Path $RepoRoot $ZipName
if(Test-Path $ZipPath){ try{ Remove-Item $ZipPath -Force -ErrorAction Stop }catch{} }

# Zbieramy do paczki: assets + userscripts + README + CHANGELOG
$toZip = @(
  (Join-Path $RepoRoot "assets"),
  (Join-Path $RepoRoot "userscripts"),
  (Join-Path $RepoRoot "README.md"),
  (Join-Path $RepoRoot "CHANGELOG.md")
)
Compress-Archive -Path $toZip -DestinationPath $ZipPath -Force
$sha = Sha256 $ZipPath
Log "ZIP: $ZipPath"
Log "SHA-256: $sha"

# archiwizacja do dist/
Copy-Item $ZipPath (Join-Path $DistDir (Split-Path $ZipPath -Leaf)) -Force
Log "dist ✓"

# ————————————————————————————————————————————————————————————————————————
# Git — opcjonalnie (jeśli repo)
# ————————————————————————————————————————————————————————————————————————
if(Test-Path (Join-Path $RepoRoot ".git")){
  try{
    git add -A | Out-Null
    git commit -m "Build $Version (themes+assets+userscript+docs)" | Out-Null
    git push | Out-Null
    Log "git push ✓"
  } catch {
    Log "git (pominięty/bez konfiguracji)"
  }
}

Log "DONE ✓"
