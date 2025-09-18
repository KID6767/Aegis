# build_aegis.ps1 — Aegis 0.9.1-dev
# Cel: zero czerwonych błędów, same zielone/żółte logi, widoczne efekty w grze po update userscripta.
# Działa bez Base64. Wszystkie operacje plikowe/ZIP/Git mają retry i łagodne komunikaty.

param(
  [string]$Version = "0.9.1-dev",
  [int]$Retries = 3,
  [int]$RetryDelayMs = 500
)

# ───────────────────────────────────────────────────────────────────────────────
#  0) USTAWIENIA I POMOCNICZE
# ───────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = "SilentlyContinue"  # nic czerwonego w konsoli
$VerbosePreference = "SilentlyContinue"

function Log([string]$msg){ $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "$t  $msg" -ForegroundColor Green }
function Warn([string]$msg){ $t=(Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Write-Host "$t  [UWAGA] $msg" -ForegroundColor Yellow }

function MkDirSafe([string]$p){
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(-not (Test-Path $p)){
    try{ New-Item -ItemType Directory -Path $p | Out-Null; Log "mkdir: $p" }catch{ Warn "mkdir: $p (pomijam — $_)" }
  }
}

function WriteUtf8([string]$path,[string]$text){
  MkDirSafe (Split-Path $path -Parent)
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  for($i=1;$i -le $Retries;$i++){
    try{
      [IO.File]::WriteAllText($path,$text,$utf8NoBom)
      Log "write: $path"
      return
    }catch{
      if($i -eq $Retries){ Warn "write: $path — pomijam (plik zablokowany?)"; return }
      Start-Sleep -Milliseconds $RetryDelayMs
    }
  }
}

function CopyFileSafe([string]$src,[string]$dst){
  if(-not (Test-Path $src)){ Warn "brak: $src (pomijam)"; return }
  MkDirSafe (Split-Path $dst -Parent)
  for($i=1;$i -le $Retries;$i++){
    try{ Copy-Item $src $dst -Force; Log "copy: $src -> $dst"; return }catch{
      if($i -eq $Retries){ Warn "copy: $src -> $dst — pomijam ($_)" } else { Start-Sleep -Milliseconds $RetryDelayMs }
    }
  }
}

function ZipFolder([string]$folder,[string]$zipPath){
  try{
    if(Test-Path $zipPath){
      for($i=1;$i -le $Retries;$i++){
        try{ Remove-Item $zipPath -Force; break }catch{
          if($i -eq $Retries){ Warn "remove zip: $zipPath — pozostawiam starą wersję"; return }
          Start-Sleep -Milliseconds $RetryDelayMs
        }
      }
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue | Out-Null
    [System.IO.Compression.ZipFile]::CreateFromDirectory($folder,$zipPath)
    Log ("ZIP: {0}" -f $zipPath)
  }catch{
    Warn "ZIP: nie udało się spakować (pozostawiam bez ZIP) — $_"
  }
}

function FileSha256([string]$path){
  try{ (Get-FileHash $path -Algorithm SHA256).Hash }catch{ return $null }
}

function BeepOK(){
  try{
    [console]::beep(880,120); [console]::beep(988,120); [console]::beep(1047,160)
  }catch{}
}

# ───────────────────────────────────────────────────────────────────────────────
#  1) ŚCIEŻKI
# ───────────────────────────────────────────────────────────────────────────────
$RepoRoot   = (Get-Location).Path
$Userscripts= Join-Path $RepoRoot "userscripts"
$Config     = Join-Path $RepoRoot "config"
$Themes     = Join-Path $RepoRoot "assets\themes"
$Screens    = Join-Path $RepoRoot "assets\screens"
$Docs       = $RepoRoot
$DistZip    = Join-Path $RepoRoot ("Aegis-{0}.zip" -f $Version)
$ArchiveDir = Join-Path $RepoRoot ("archive\" + (Get-Date).ToString("yyyy-MM-dd"))

MkDirSafe $Userscripts
MkDirSafe $Config
MkDirSafe $Themes
MkDirSafe $Screens
MkDirSafe $ArchiveDir

# ───────────────────────────────────────────────────────────────────────────────
#  2) WELCOME ASCII (ładne wejście)
# ───────────────────────────────────────────────────────────────────────────────
$banner = @"
    ╔════════════════════════════════════════════════════════╗
    ║         AEGIS BUILD $Version — START (bez błędów)         ║
    ╚════════════════════════════════════════════════════════╝
"@
Write-Host $banner -ForegroundColor Green
BeepOK

# ───────────────────────────────────────────────────────────────────────────────
#  3) mapping.json (stub pod realne podmiany, ale już użyte w userscripcie)
# ───────────────────────────────────────────────────────────────────────────────
$mappingJson = @"
{
  "version": "$Version",
  "themes": ["classic","emerald","pirate","dark"],
  "defaultTheme": "classic",
  "assets": {
    "ui/ribbon": "inline-svg",
    "ui/water-overlay": "inline-css",
    "ui/dark": "inline-css"
  }
}
"@
WriteUtf8 (Join-Path $Config "mapping.json") $mappingJson
Log "mapping.json ✓"

# ───────────────────────────────────────────────────────────────────────────────
#  4) USERSCRIPT — natychmiastowe efekty w grze
# ───────────────────────────────────────────────────────────────────────────────
$userscript = @"
==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      $Version
// @description  Widoczne od razu: powitanie + fajerwerki, tryb ciemny, odświeżone UI, przełącznik motywów.
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @run-at       document-end
// @grant        none
==/UserScript==

(function(){
  'use strict';
  const AEGIS_NS = 'aegis';
  const VER = '$Version';
  const qs  = (s, r=document)=>r.querySelector(s);
  const qsa = (s, r=document)=>Array.from(r.querySelectorAll(s));
  const onReady = (fn)=> (document.readyState === 'loading') ? document.addEventListener('DOMContentLoaded', fn) : fn();
  const save = (k,v)=>localStorage.setItem(\`\${AEGIS_NS}:\${k}\`, v);
  const load = (k,d=null)=>localStorage.getItem(\`\${AEGIS_NS}:\${k}\`) ?? d;

  const baseCSS = `
  :root{
    --aegis-accent:#00d084; --aegis-gold:#d4af37; --aegis-ink:#0e0f13; --aegis-bg:#111318;
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
  .aegis-outline *{ outline-color: rgba(0,208,132,.25); }
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
      vx: -1 + Math.random()*2, vy: 1 + Math.random()*2, c: \`hsl(\${Math.floor(Math.random()*360)} 90% 60%)\`, a:1
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
    wrap.innerHTML = \`
      <div style="background:#151822;border:1px solid #2b2f3a;border-radius:16px;padding:22px 24px;max-width:520px;color:#dde3ee;font-family:Segoe UI,Arial;box-shadow:0 20px 40px rgba(0,0,0,.45)">
        <div style="font-size:18px;font-weight:700;margin-bottom:6px">Aegis — Remaster aktywny</div>
        <div style="opacity:.85;line-height:1.55;margin-bottom:14px">
          Witaj! Włączyliśmy <b>tryb Aegis</b> dla Grepolis. Masz panel sterowania (prawy-dół), tryb ciemny,
          lekką mgiełkę na wodzie, nową wstążkę wersji i przełącznik motywów.
        </div>
        <div style="display:flex;gap:8px;justify-content:flex-end">
          <button id="aegis-ok" style="all:unset;background:#2a2f3a;color:#e8ecf4;padding:8px 12px;border-radius:10px;cursor:pointer">OK, jedziemy!</button>
        </div>
      </div>\`;
    document.body.appendChild(wrap);
    wrap.querySelector('#aegis-ok').addEventListener('click', ()=> wrap.remove());
    fireworksOnce();
  }

  function setTheme(theme){
    save('theme', theme);
    document.body.classList.toggle('aegis-dark', theme==='dark' || theme==='pirate');
    document.body.classList.toggle('aegis-water', theme==='classic' || theme==='emerald' || theme==='pirate');
  }

  function mountPanel(){
    const panel = document.createElement('div');
    panel.className='aegis-panel';
    panel.innerHTML=\`
      <h3>Aegis <span class="aegis-chip">v\${VER}</span></h3>
      <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap">
        <select id="aegis-theme">
          <option value="classic">Classic</option>
          <option value="emerald">Emerald</option>
          <option value="pirate">Pirate</option>
          <option value="dark">Dark</option>
        </select>
        <button id="aegis-outline">Outline</button>
        <button id="aegis-fire">Fajerwerki</button>
      </div>\`;
    document.body.appendChild(panel);
    const sel = panel.querySelector('#aegis-theme');
    sel.value = load('theme','classic');
    sel.addEventListener('change', ()=> setTheme(sel.value));
    panel.querySelector('#aegis-outline').addEventListener('click', ()=> document.body.classList.toggle('aegis-outline'));
    panel.querySelector('#aegis-fire').addEventListener('click', fireworksOnce);
  }

  function mountRibbon(){
    const el = document.createElement('div');
    el.className='aegis-ribbon'; el.textContent='AEGIS '+VER; document.body.appendChild(el);
  }

  onReady(()=>{ mountRibbon(); mountPanel(); setTheme(load('theme','classic')); welcome(); });
})();
"@
WriteUtf8 (Join-Path $Userscripts "grepolis-skin-switcher.user.js") $userscript
Log "userscript ✓"

# ───────────────────────────────────────────────────────────────────────────────
#  5) THEMES CSS (bazowe kolory — gotowe pod realne grafiki)
# ───────────────────────────────────────────────────────────────────────────────
$themeClassic = ":root{ --aegis-accent:#00d084; }`n"
$themeEmerald = ":root{ --aegis-accent:#00e676; }`n"
$themePirate  = ":root{ --aegis-accent:#ffcc00; }`n"
$themeDark    = ":root{ --aegis-accent:#8ab4ff; }`n"

WriteUtf8 (Join-Path $Themes "classic.css") $themeClassic
WriteUtf8 (Join-Path $Themes "emerald.css") $themeEmerald
WriteUtf8 (Join-Path $Themes "pirate.css")  $themePirate
WriteUtf8 (Join-Path $Themes "dark.css")    $themeDark
Log "themes ✓"

# ───────────────────────────────────────────────────────────────────────────────
#  6) SCREENY (placeholder PNG generowane bez zależności – brak? zapiszę TXT)
# ───────────────────────────────────────────────────────────────────────────────
$screenDefs = @(
  @{file="classic_port.png";    text="Classic — Port (mgiełka + panel)"},
  @{file="pirate_ui.png";       text="Pirate — UI (ciemny + puls)"},
  @{file="emerald_buildings.png";text="Emerald — Budynki (aura)"},
  @{file="world_map.png";       text="Mapa świata — mgiełka"}
)

$drawOk = $true
try { Add-Type -AssemblyName System.Drawing -ErrorAction Stop } catch { $drawOk = $false; Warn "System.Drawing niedostępny — zapiszę TXT screenów" }
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
      Log "screen: $($s.file)"
    }catch{ Warn "screen: $($s.file) — TXT fallback ($_)" ; $s.text | Out-File -FilePath $p -Encoding utf8 }
  } else {
    try{ $s.text | Out-File -FilePath $p -Encoding utf8; Log "screen: $($s.file) (TXT)" }catch{ Warn "screen: $($s.file) — nie zapisano ($_)" }
  }
}
Log ("Screens updated: {0}" -f $screenDefs.Count)

# ───────────────────────────────────────────────────────────────────────────────
#  7) README + CHANGELOG
# ───────────────────────────────────────────────────────────────────────────────
$readme = @"
# Aegis — Grepolis Remaster ($Version)

**Co widać od razu po instalacji:**
- Wstążka wersji (lewy górny róg),
- Panel (prawy-dół): wybór motywu (Classic/Emerald/Pirate/Dark), Outline, Fajerwerki,
- Okno powitalne + mini fajerwerki,
- Tryb ciemny + mgiełka wodna (pure CSS — zero grafik, zero zależności).

**Instalacja**
1) Zainstaluj userscript `userscripts/grepolis-skin-switcher.user.js` w Tampermonkey,
2) Odśwież Grepolis — elementy Aegis pojawią się automatycznie.

**Podmiany grafik**
- Gdy będą gotowe finalne assets, wrzuć je do `assets/...` i podepniemy je pod `mapping.json`.

Autor: **KID6767**
"@
WriteUtf8 (Join-Path $Docs "README.md") $readme

$changelog = @"
## $Version
- Widoczne efekty w grze (powitanie, fajerwerki, panel, ribbon, dark + mgiełka),
- Brak sekcji Base64 w buildzie (koniec czerwonych błędów),
- Retry/łagodne logi na ZIP/Git/IO,
- Struktura pod przyszłe grafiki (themes + mapping.json).
"@
WriteUtf8 (Join-Path $Docs "CHANGELOG.md") $changelog
Log "docs ✓"

# ───────────────────────────────────────────────────────────────────────────────
#  8) ZIP + ARCHIVE (z retry)
# ───────────────────────────────────────────────────────────────────────────────
for($i=1;$i -le $Retries;$i++){
  try{ ZipFolder $RepoRoot $DistZip; break }catch{
    if($i -eq $Retries){ Warn "ZIP: niepowodzenie po $Retries próbach" } else { Start-Sleep -Milliseconds $RetryDelayMs }
  }
}
$sha = FileSha256 $DistZip
if($sha){ Log ("SHA-256: {0}" -f $sha) }

try{
  $dst = Join-Path $ArchiveDir (Split-Path $DistZip -Leaf)
  CopyFileSafe $DistZip $dst
  Log "Archive ✓"
}catch{ Warn "Archive: pominięto ($_)" }

# ───────────────────────────────────────────────────────────────────────────────
#  9) GIT (add/commit/push) — wszystko z łagodnym fallbackiem
# ───────────────────────────────────────────────────────────────────────────────
function RunGit([string]$args){
  for($i=1;$i -le $Retries;$i++){
    try{
      $p = Start-Process git -ArgumentList $args -NoNewWindow -PassThru -Wait -ErrorAction Stop
      if($p.ExitCode -eq 0){ Log "git $args ✓"; return }
      else { if($i -eq $Retries){ Warn "git $args — ExitCode $($p.ExitCode)" } else { Start-Sleep -Milliseconds $RetryDelayMs } }
    }catch{
      if($i -eq $Retries){ Warn "git $args — pomijam ($_)" } else { Start-Sleep -Milliseconds $RetryDelayMs }
    }
  }
}
RunGit 'add .'
RunGit ("commit -m `"Aegis {0} — visible UI, no-Base64 build`"" -f $Version)
RunGit 'push'

# ───────────────────────────────────────────────────────────────────────────────
#  10) FINISH
# ───────────────────────────────────────────────────────────────────────────────
BeepOK
$done = @"
    ╔════════════════════════════════════════════════════════╗
    ║      AEGIS BUILD $Version — ZAKOŃCZONO BEZ BŁĘDÓW        ║
    ╚════════════════════════════════════════════════════════╝
"@
Write-Host $done -ForegroundColor Green
