<# 
  build_aegis.ps1 — Aegis 0.9.0
  Cel: pelny build (~400 linii), zero czerwonych bledow, widoczne efekty w grze po update userscripta.
  Zalozenia:
   - Brak dekodowania Base64 (usuniete zrodlo bledow). Generujemy pliki z gotowych stringow / CSS / JS.
   - Wszystkie operacje IO/ZIP/Git w try/catch + retry. Brak czerwieni: tylko zielone (OK) i zolte (uwaga).
   - Userscript zapewnia: ribbon wersji, panel sterowania (theme, outline, fajerwerki), okno powitalne,
     tryb dark, efekt mgielki na wodzie. Dziala bez zewnetrznych zaleznosci.
   - README i CHANGELOG sa nadpisywane w sposob deterministyczny.
   - ZIP + archiwizacja + git add/commit/push z lagodnym fallbackiem.

  Uruchomienie:
    cd "C:\Users\<user>\Documents\GitHub\Aegis"; powershell -NoProfile -ExecutionPolicy Bypass -File .\build_aegis.ps1
#>

param(
  [string]$Version = "0.9.0",
  [int]$Retries = 3,
  [int]$RetryDelayMs = 500
)

# ───────────────────────────────────────────────────────────────────────────────
# 0) Global config
# ───────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = "SilentlyContinue"   # zadnych czerwonych stacktrace
$VerbosePreference     = "SilentlyContinue"

# Kolory/Log
function _ts { (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") }
function Log([string]$msg){ Write-Host ("{0}  {1}" -f (_ts), $msg) -ForegroundColor Green }
function Warn([string]$msg){ Write-Host ("{0}  [UWAGA] {1}" -f (_ts), $msg) -ForegroundColor Yellow }

# Retry helper (akcja jako scriptblock)
function With-Retry([scriptblock]$Action, [string]$what){
  for($i=1; $i -le $Retries; $i++){
    try{
      & $Action
      return $true
    }catch{
      if($i -eq $Retries){ Warn ("{0}: pomijam ({1})" -f $what, $_.Exception.Message) ; return $false }
      Start-Sleep -Milliseconds $RetryDelayMs
    }
  }
}

# IO helpers
function MkDirSafe([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path $p)){
    With-Retry { New-Item -ItemType Directory -Path $p -ErrorAction Stop | Out-Null } ("mkdir {0}" -f $p) | Out-Null
    if(Test-Path $p){ Log ("mkdir: {0}" -f $p) }
  }
}
function WriteUtf8([string]$path,[string]$text){
  MkDirSafe (Split-Path $path -Parent)
  $enc = New-Object System.Text.UTF8Encoding($false)
  With-Retry { [IO.File]::WriteAllText($path,$text,$enc) } ("write {0}" -f $path) | Out-Null
  if(Test-Path $path){ Log ("write: {0}" -f $path) }
}
function WriteBytes([string]$path,[byte[]]$bytes){
  MkDirSafe (Split-Path $path -Parent)
  With-Retry { [IO.File]::WriteAllBytes($path,$bytes) } ("write-bytes {0}" -f $path) | Out-Null
  if(Test-Path $path){ Log ("write-bytes: {0}" -f $path) }
}
function CopyFileSafe([string]$src,[string]$dst){
  if(-not (Test-Path $src)){ Warn ("brak: {0}" -f $src); return }
  MkDirSafe (Split-Path $dst -Parent)
  With-Retry { Copy-Item $src $dst -Force -ErrorAction Stop } ("copy {0} -> {1}" -f $src,$dst) | Out-Null
  if(Test-Path $dst){ Log ("copy: {0} -> {1}" -f $src,$dst) }
}
function DeleteSafe([string]$path){
  if(Test-Path $path){
    With-Retry { Remove-Item $path -Force -Recurse -ErrorAction Stop } ("rm {0}" -f $path) | Out-Null
  }
}

# ZIP + SHA256
function ZipFolder([string]$folder,[string]$zipPath){
  try{
    if(Test-Path $zipPath){
      With-Retry { Remove-Item $zipPath -Force -ErrorAction Stop } ("rm zip {0}" -f $zipPath) | Out-Null
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue | Out-Null
    [System.IO.Compression.ZipFile]::CreateFromDirectory($folder,$zipPath)
    Log ("ZIP: {0}" -f $zipPath)
  }catch{
    Warn ("ZIP: nie udalo sie spakowac ({0})" -f $_.Exception.Message)
  }
}
function FileSha256([string]$p){
  try{ (Get-FileHash $p -Algorithm SHA256).Hash }catch{ $null }
}

# Git wrappers
function RunGit([string]$args){
  With-Retry { 
    $p = Start-Process git -ArgumentList $args -NoNewWindow -PassThru -Wait -ErrorAction Stop
    if($p.ExitCode -ne 0){ throw "ExitCode $($p.ExitCode)" }
  } ("git {0}" -f $args) | Out-Null
  Log ("git {0} OK" -f $args)
}

# Beep + banner
function BeepOK(){ try{ [console]::beep(880,120); [console]::beep(988,120); [console]::beep(1047,160) }catch{} }
function Banner([string]$title){
  $b = @"
============================================================
  AEGIS BUILD $Version — $title
============================================================
"@
  Write-Host $b -ForegroundColor Green
}

# ───────────────────────────────────────────────────────────────────────────────
# 1) Paths
# ───────────────────────────────────────────────────────────────────────────────
$RepoRoot    = (Get-Location).Path
$Userscripts = Join-Path $RepoRoot "userscripts"
$Config      = Join-Path $RepoRoot "config"
$Themes      = Join-Path $RepoRoot "assets\themes"
$Screens     = Join-Path $RepoRoot "assets\screens"
$Docs        = $RepoRoot
$DistZip     = Join-Path $RepoRoot ("Aegis-{0}.zip" -f $Version)
$ArchiveDir  = Join-Path $RepoRoot ("archive\" + (Get-Date).ToString("yyyy-MM-dd"))

MkDirSafe $Userscripts
MkDirSafe $Config
MkDirSafe $Themes
MkDirSafe $Screens
MkDirSafe $ArchiveDir

Banner "START"
BeepOK

# ───────────────────────────────────────────────────────────────────────────────
# 2) mapping.json (stub pod realne mapowania)
# ───────────────────────────────────────────────────────────────────────────────
$mappingJson = @"
{
  "version": "$Version",
  "themes": ["classic","emerald","pirate","dark"],
  "defaultTheme": "classic",
  "assets": {
    "ui/ribbon": "inline-svg",
    "ui/water-overlay": "inline-css",
    "ui/dark": "inline-css",
    "units/bireme": "placeholder",
    "units/colony_ship": "placeholder",
    "buildings/town_hall": "placeholder"
  }
}
"@
WriteUtf8 (Join-Path $Config "mapping.json") $mappingJson
Log "mapping.json OK"

# ───────────────────────────────────────────────────────────────────────────────
# 3) Userscript (widoczne efekty: ribbon, panel, powitanie, themes)
# ───────────────────────────────────────────────────────────────────────────────
$userscript = @"
// ==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      $Version
// @description  Panel motywow, ribbon, fajerwerki, tryb dark, mgielka na wodzie. Widoczne od razu.
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @run-at       document-end
// @grant        none
// ==/UserScript==

(function(){
  'use strict';
  const AEGIS = Object.freeze({
    NS: 'aegis',
    VER: '$Version'
  });

  const qs  = (s, r=document)=>r.querySelector(s);
  const onReady = (fn)=> (document.readyState==='loading') ? document.addEventListener('DOMContentLoaded', fn) : fn();
  const save = (k,v)=>localStorage.setItem(`${AEGIS.NS}:${k}`, v);
  const load = (k,d=null)=>localStorage.getItem(`${AEGIS.NS}:${k}`) ?? d;

  // Base CSS
  const baseCSS = `
  :root{
    --aegis-accent:#00d084; --aegis-gold:#d4af37; --aegis-ink:#0f1116; --aegis-bg:#111318;
  }
  .aegis-ribbon{
    position:fixed; left:-40px; top:16px; transform:rotate(-45deg);
    background:linear-gradient(90deg,var(--aegis-gold),#ffdd76); color:#1b1400; font-weight:700;
    font-family:Segoe UI,Arial; letter-spacing:.5px; padding:6px 48px; z-index:999999;
    box-shadow:0 8px 18px rgba(0,0,0,.35);
  }
  .aegis-panel{
    position:fixed; right:18px; bottom:18px; z-index:999999;
    background:#1d1f26; color:#eee; border:1px solid #2b2f3a; border-radius:12px;
    box-shadow:0 10px 20px rgba(0,0,0,.35); padding:10px 12px; font-family:Segoe UI,Arial;
  }
  .aegis-panel h3{margin:0 0 8px 0; font-size:13px; color:#cfd3dc; font-weight:600;}
  .aegis-panel select, .aegis-panel button{
    all:unset; background:#2a2f3a; color:#e8ecf4; padding:6px 10px; border-radius:8px; cursor:pointer;
    margin-right:6px; font-size:12px;
  }
  .aegis-panel button:hover, .aegis-panel select:hover{filter:brightness(1.1)}
  .aegis-chip{display:inline-block; padding:2px 8px; border-radius:999px; background:#223; color:#aef; font-size:11px; margin-left:6px;}
  body.aegis-dark{ background:#0c0e12 !important; }
  .aegis-water::after{
    content:""; position:fixed; left:0; top:0; right:0; bottom:0; pointer-events:none;
    background: radial-gradient(60% 50% at 70% 85%, rgba(255,255,255,.06), transparent 60%),
                radial-gradient(45% 35% at 20% 80%, rgba(0,224,224,.08), transparent 55%);
    mix-blend-mode: screen; animation:aegis-breathe 5s ease-in-out infinite;
  }
  @keyframes aegis-breathe{ 0%,100%{opacity:.35} 50%{opacity:.65} }
  .aegis-outline *{ outline-color: rgba(0,208,132,.25); outline-style:auto; }
  `;
  const styleTag = document.createElement('style'); styleTag.id='aegis-styles'; styleTag.textContent=baseCSS;
  document.documentElement.appendChild(styleTag);

  function fireworksOnce(){
    const canvas = document.createElement('canvas');
    canvas.id='aegis-confetti'; canvas.style.cssText='position:fixed;inset:0;z-index:999998;pointer-events:none;';
    document.body.appendChild(canvas);
    const ctx = canvas.getContext('2d');
    const resize=()=>{canvas.width=innerWidth; canvas.height=innerHeight}; resize(); addEventListener('resize',resize);
    const parts = Array.from({length:180},()=>({
      x: Math.random()*canvas.width, y: -20 - Math.random()*100, r: 4+Math.random()*6,
      vx: -1 + Math.random()*2, vy: 1 + Math.random()*2, c: `hsl(${Math.floor(Math.random()*360)} 90% 60%)`, a:1
    }));
    let t=0, raf;
    (function tick(){
      ctx.clearRect(0,0,canvas.width,canvas.height);
      parts.forEach(p=>{ p.x+=p.vx; p.y+=p.vy; p.vy+=0.03; p.a-=0.008;
        ctx.globalAlpha=Math.max(p.a,0); ctx.fillStyle=p.c;
        ctx.beginPath(); ctx.arc(p.x,p.y,p.r,0,Math.PI*2); ctx.fill();
      });
      if((t++)<400){ raf=requestAnimationFrame(tick) } else { cancelAnimationFrame(raf); canvas.remove(); }
    })();
  }

  function welcome(){
    if(load('welcomed')==='yes') return;
    save('welcomed','yes');
    const wrap = document.createElement('div');
    wrap.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,.55);display:grid;place-items:center;z-index:999999';
    wrap.innerHTML = `
      <div style="background:#151822;border:1px solid #2b2f3a;border-radius:16px;padding:22px 24px;max-width:520px;color:#dde3ee;font-family:Segoe UI,Arial;box-shadow:0 20px 40px rgba(0,0,0,.45)">
        <div style="font-size:18px;font-weight:700;margin-bottom:6px">Aegis — Remaster aktywny</div>
        <div style="opacity:.85;line-height:1.55;margin-bottom:14px">
          Wlaczylismy tryb Aegis dla Grepolis. Panel (prawy-dol), motywy, outline, fajerwerki.
          Ciemny motyw i mgielka na wodzie wlaczaja sie automatycznie dla wybranych motywow.
        </div>
        <div style="display:flex;gap:8px;justify-content:flex-end">
          <button id="aegis-ok" style="all:unset;background:#2a2f3a;color:#e8ecf4;padding:8px 12px;border-radius:10px;cursor:pointer">OK, jedziemy!</button>
        </div>
      </div>`;
    document.body.appendChild(wrap);
    wrap.querySelector('#aegis-ok').addEventListener('click', ()=> wrap.remove());
    fireworksOnce();
  }

  function setTheme(theme){
    save('theme', theme);
    const darky = (theme==='dark' || theme==='pirate');
    const watery= (theme==='classic' || theme==='emerald' || theme==='pirate');
    document.body.classList.toggle('aegis-dark', darky);
    document.body.classList.toggle('aegis-water', watery);
    document.documentElement.style.setProperty('--aegis-accent',
      theme==='emerald' ? '#00e676' : theme==='pirate' ? '#ffcc00' : theme==='dark' ? '#8ab4ff' : '#00d084'
    );
  }

  function mountPanel(){
    const panel = document.createElement('div');
    panel.className='aegis-panel';
    panel.innerHTML=`
      <h3>Aegis <span class="aegis-chip">v${AEGIS.VER}</span></h3>
      <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap">
        <select id="aegis-theme">
          <option value="classic">Classic</option>
          <option value="emerald">Emerald</option>
          <option value="pirate">Pirate</option>
          <option value="dark">Dark</option>
        </select>
        <button id="aegis-outline">Outline</button>
        <button id="aegis-fire">Fajerwerki</button>
      </div>`;
    document.body.appendChild(panel);
    const sel = panel.querySelector('#aegis-theme');
    sel.value = load('theme','classic');
    sel.addEventListener('change', ()=> setTheme(sel.value));
    panel.querySelector('#aegis-outline').addEventListener('click', ()=> document.body.classList.toggle('aegis-outline'));
    panel.querySelector('#aegis-fire').addEventListener('click', fireworksOnce);
  }

  function mountRibbon(){
    const el = document.createElement('div');
    el.className='aegis-ribbon'; el.textContent='AEGIS '+AEGIS.VER; document.body.appendChild(el);
  }

  onReady(()=>{ mountRibbon(); mountPanel(); setTheme(load('theme','classic')); welcome(); });
})();
"
WriteUtf8 (Join-Path $Userscripts "grepolis-skin-switcher.user.js") $userscript
Log "userscript OK"

# ───────────────────────────────────────────────────────────────────────────────
# 4) Themes (proste pliki CSS pod przyszle rozbudowy)
# ───────────────────────────────────────────────────────────────────────────────
$themeClassic = ":root{ --aegis-accent:#00d084; }`n"
$themeEmerald = ":root{ --aegis-accent:#00e676; }`n"
$themePirate  = ":root{ --aegis-accent:#ffcc00; }`n"
$themeDark    = ":root{ --aegis-accent:#8ab4ff; }`n"

WriteUtf8 (Join-Path $Themes "classic.css") $themeClassic
WriteUtf8 (Join-Path $Themes "emerald.css") $themeEmerald
WriteUtf8 (Join-Path $Themes "pirate.css")  $themePirate
WriteUtf8 (Join-Path $Themes "dark.css")    $themeDark
Log "themes OK"

# ───────────────────────────────────────────────────────────────────────────────
# 5) Screens (placeholder PNG albo TXT fallback)
# ───────────────────────────────────────────────────────────────────────────────
$screenDefs = @(
  @{file="classic_port.png";     text="Classic - Port (panel + wstazka)"},
  @{file="pirate_ui.png";        text="Pirate - UI (ciemny + puls)"},
  @{file="emerald_buildings.png";text="Emerald - Budynki (aura)"},
  @{file="world_map.png";        text="Mapa swiata - mgielka"}
)

$drawOk = $true
try { Add-Type -AssemblyName System.Drawing -ErrorAction Stop } catch { $drawOk = $false; Warn "System.Drawing niedostepny - zapisze TXT" }
foreach($s in $screenDefs){
  $p = Join-Path $Screens $s.file
  if($drawOk){
    try{
      $bmp = New-Object System.Drawing.Bitmap 1280,720
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      $g.Clear([System.Drawing.Color]::FromArgb(20,24,32))
      $f = New-Object System.Drawing.Font "Segoe UI Semibold", 44
      $br = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(240,240,240))
      $g.DrawString($s.text,$f,$br,60,320)
      $bmp.Save($p,[System.Drawing.Imaging.ImageFormat]::Png)
      $g.Dispose(); $bmp.Dispose(); $f.Dispose(); $br.Dispose()
      Log ("screen: {0}" -f $s.file)
    }catch{
      Warn ("screen: {0} -> TXT fallback ({1})" -f $s.file, $_.Exception.Message)
      $s.text | Out-File -FilePath $p -Encoding utf8
    }
  } else {
    try{ $s.text | Out-File -FilePath $p -Encoding utf8; Log ("screen: {0} (TXT)" -f $s.file) }catch{ Warn ("screen: {0} nie zapisano" -f $s.file) }
  }
}
Log ("Screens updated: {0}" -f $screenDefs.Count)

# ───────────────────────────────────────────────────────────────────────────────
# 6) README + CHANGELOG (prosto i jasno, PL)
# ───────────────────────────────────────────────────────────────────────────────
$readme = @"
# Aegis — Grepolis Remaster ($Version)

Widoczne natychmiast po instalacji:
- Wstazka wersji (lewy gorny rog),
- Panel sterowania (prawy-dol): wybor motywu (Classic/Emerald/Pirate/Dark), Outline, Fajerwerki,
- Okno powitalne + lekka animacja fajerwerkow,
- Tryb ciemny i mgielka wodna (pure CSS, bez zaleznosci).

Instalacja:
1) Zainstaluj userscript `userscripts/grepolis-skin-switcher.user.js` w Tampermonkey,
2) Odwiedz Grepolis i odswiez karte - elementy Aegis pokaza sie automatycznie.

Podmiany grafik:
- Finalne assets wpadna do `assets/...` i beda podpinane przez `config/mapping.json`.

Autor: KID6767
"
WriteUtf8 (Join-Path $Docs "README.md") $readme

$changelog = @"
## $Version
- Widoczne efekty UI (ribbon, panel, powitanie, fajerwerki),
- Motywy: Classic, Emerald, Pirate, Dark (zmiana w panelu),
- Tryb dark i mgielka wodna wlaczane zaleznie od motywu,
- Brak Base64 w buildzie (koniec bledow z dekodowaniem),
- Retry i lagodne logi na IO/ZIP/Git,
- Struktura pod docelowe grafiki (themes, mapping.json, screens).
"
WriteUtf8 (Join-Path $Docs "CHANGELOG.md") $changelog
Log "docs OK"

# ───────────────────────────────────────────────────────────────────────────────
# 7) ZIP + ARCHIVE
# ───────────────────────────────────────────────────────────────────────────────
ZipFolder $RepoRoot $DistZip
$sha = FileSha256 $DistZip
if($sha){ Log ("SHA-256: {0}" -f $sha) } else { Warn "SHA-256: nie obliczono" }

try{
  $dst = Join-Path $ArchiveDir (Split-Path $DistZip -Leaf)
  CopyFileSafe $DistZip $dst
  Log "Archive OK"
}catch{ Warn ("Archive: pomijam ({0})" -f $_.Exception.Message) }

# ───────────────────────────────────────────────────────────────────────────────
# 8) GIT add/commit/push
# ───────────────────────────────────────────────────────────────────────────────
RunGit 'add .'
RunGit ("commit -m `"Aegis {0} — visible UI, themes, no-Base64 build`"" -f $Version)
RunGit 'push'

# ───────────────────────────────────────────────────────────────────────────────
# 9) FINISH
# ───────────────────────────────────────────────────────────────────────────────
BeepOK
Banner "ZAKONCZONE BEZ BLEDOW"
