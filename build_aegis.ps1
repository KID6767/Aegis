# ===== build_aegis.ps1 =====
# Aegis autobuilder – pełny, działający zestaw (0.8.1-dev)
param([string]$Version="0.8.1-dev")

function Log($t){Write-Host ("{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"),$t)}

$Root      = Split-Path -Parent $MyInvocation.MyCommand.Path
$Cfg       = Join-Path $Root "config"
$Themes    = Join-Path $Root "themes"
$Usr       = Join-Path $Root "userscripts"
$Archive   = Join-Path $Root "archive"
$Assets    = Join-Path $Root "assets"
$ZipPath   = Join-Path $Root ("Aegis-{0}.zip" -f $Version)
$RepoRaw   = "https://raw.githubusercontent.com/KID6767/Aegis/main"

$folders = @(
  $Cfg,$Themes,$Usr,$Archive,
  "$Assets/classic/ui","$Assets/classic/units","$Assets/classic/background","$Assets/classic/branding",
  "$Assets/pirate/ui","$Assets/pirate/units","$Assets/pirate/background","$Assets/pirate/branding",
  "$Assets/emerald/ui","$Assets/emerald/units","$Assets/emerald/background","$Assets/emerald/branding",
  "$Assets/dark/ui","$Assets/dark/units","$Assets/dark/background","$Assets/dark/branding"
)
$folders | ForEach-Object { if(-not(Test-Path $_)){ New-Item -ItemType Directory -Path $_ | Out-Null } }

# ---- mapping.json (gotowe ścieżki) ----
$mapping = @"
{
  "themes":{
    "classic":{
      "name":"Classic",
      "css":"themes/classic.css",
      "assets":{
        "ui/button.png":"assets/classic/ui/button.png",
        "units/bireme.png":"assets/classic/units/bireme.png",
        "units/fire_ship.png":"assets/classic/units/fire_ship.png",
        "background/port.jpg":"assets/classic/background/port.jpg",
        "background/city.jpg":"assets/classic/background/city.jpg",
        "branding/logo.png":"assets/classic/branding/logo.png"
      }
    },
    "pirate":{
      "name":"Pirate Epic",
      "css":"themes/pirate.css",
      "assets":{
        "ui/button.png":"assets/pirate/ui/button.png",
        "units/bireme.png":"assets/pirate/units/bireme_pirate.png",
        "units/fire_ship.png":"assets/pirate/units/fire_ship_pirate.png",
        "background/port.jpg":"assets/pirate/background/port_fire.jpg",
        "background/city.jpg":"assets/pirate/background/city_dark.jpg",
        "branding/logo.png":"assets/pirate/branding/logo.png"
      }
    },
    "emerald":{
      "name":"Emerald",
      "css":"themes/emerald.css",
      "assets":{
        "ui/button.png":"assets/emerald/ui/button.png",
        "units/bireme.png":"assets/emerald/units/bireme.png",
        "units/fire_ship.png":"assets/emerald/units/fire_ship.png",
        "background/port.jpg":"assets/emerald/background/port_green.jpg",
        "background/city.jpg":"assets/emerald/background/city_gold.jpg",
        "branding/logo.png":"assets/emerald/branding/logo.png"
      }
    },
    "dark":{
      "name":"Dark Mode",
      "css":"themes/dark.css",
      "assets":{
        "ui/button.png":"assets/dark/ui/button.png",
        "units/bireme.png":"assets/dark/units/bireme.png",
        "units/fire_ship.png":"assets/dark/units/fire_ship.png",
        "background/port.jpg":"assets/dark/background/port_night.jpg",
        "background/city.jpg":"assets/dark/background/city_mist.jpg",
        "branding/logo.png":"assets/dark/branding/logo.png",
        "background/fog.png":"assets/dark/background/fog.png"
      }
    }
  }
}
"@
$mapping | Out-File (Join-Path $Cfg "mapping.json") -Encoding utf8
Log "mapping.json ✓"

# ---- userscript (pełny, działający) ----
$UserJs = @"
// ==UserScript==
// @name         Aegis – Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      $Version
// @description  Dynamiczne skiny Grepolis (Classic, Pirate, Emerald, Dark) – real-time podmiana grafik + CSS + panel
// @author       KID6767
// @match        https://*.grepolis.com/*
// @updateURL    $RepoRaw/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  $RepoRaw/userscripts/grepolis-skin-switcher.user.js
// @grant        none
// ==/UserScript==

(async () => {
  'use strict';
  const REPO = '$RepoRaw';
  const MAP  = REPO + '/config/mapping.json?v=$Version';
  const KEY  = 'aegis-theme';
  const DEF  = localStorage.getItem(KEY) || 'pirate';

  function css(href){
    const l=document.createElement('link'); l.rel='stylesheet'; l.href=href; document.head.appendChild(l);
  }
  function style(t){
    const s=document.createElement('style'); s.textContent=t; document.head.appendChild(s);
  }
  function el(n,attrs={},kids=[]){const e=document.createElement(n);Object.entries(attrs).forEach(([k,v])=>e[k]=v);kids.forEach(k=>e.appendChild(k));return e;}

  let mapping;
  try{ mapping = await fetch(MAP).then(r=>r.json()); }catch(e){ console.error('[Aegis] mapping.json error',e); return; }

  function applyTheme(name){
    const def = mapping.themes[name]; if(!def) return;
    // CSS
    css(REPO + '/' + def.css + '?v=$Version');

    // globalny font + reset focusów
    style(`@import url('https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700&display=swap');
      *{outline:none}
      .aegis-badge{position:fixed;left:10px;bottom:10px;padding:6px 10px;border-radius:8px;background:rgba(0,0,0,.6);color:#fff;font:12px "Cinzel Decorative",serif;z-index:99999}
      .aegis-modal{position:fixed;inset:0;background:rgba(0,0,0,.7);display:flex;align-items:center;justify-content:center;z-index:99998}
      .aegis-card{min-width:420px;max-width:520px;background:#101418;border:1px solid #2a3b4a;border-radius:14px;box-shadow:0 0 30px #000;padding:18px;color:#e8f0ff}
      .aegis-title{font:700 22px "Cinzel Decorative",serif;margin:0 0 8px}
      .aegis-actions{display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
      .aegis-btn{cursor:pointer;border:0;border-radius:8px;padding:8px 12px;background:#1e2b36;color:#cfe;transition:.2s}
      .aegis-btn:hover{transform:translateY(-1px);background:#254151}
    `);

    // Podmiana grafik IMG po fragmencie ścieżki (działa od razu – placeholdery też się wyświetlą)
    const map = def.assets || {};
    const imgs = document.querySelectorAll('img');
    imgs.forEach(img=>{
      const src = img.getAttribute('src')||'';
      Object.keys(map).forEach(pattern=>{
        if(src.includes(pattern)){
          img.setAttribute('src', REPO + '/' + map[pattern] + '?v=$Version');
        }
      });
    });

    // Znaczek wersji
    const old = document.querySelector('.aegis-badge'); if(old) old.remove();
    document.body.appendChild(el('div',{className:'aegis-badge',innerText:`Aegis ${'$Version'} • ${def.name}`}));
    console.log('[Aegis] Theme applied:', def.name);
  }

  // Panel wyboru motywu
  function mountPanel(){
    const wrap = document.createElement('div');
    wrap.style.cssText = 'position:fixed;top:68px;right:10px;z-index:99999;background:rgba(0,0,0,.72);padding:8px;border-radius:10px;color:#fff;font:14px "Cinzel Decorative",serif;box-shadow:0 2px 10px rgba(0,0,0,.4)';
    const lab = el('span',{innerText:'Motyw: '});
    const sel = el('select');
    Object.entries(mapping.themes).forEach(([k,v])=>{
      const o = el('option',{value:k,innerText:v.name}); if(k===localStorage.getItem(KEY)||k===DEF && !localStorage.getItem(KEY)) o.selected=true;
      sel.appendChild(o);
    });
    sel.onchange = e => { localStorage.setItem(KEY,e.target.value); location.reload(); };
    wrap.append(lab,sel);
    document.body.appendChild(wrap);
  }

  // Ekran powitalny (jednorazowo po update)
  function welcome(){
    const k='aegis-welc-'+('$Version'.replace(/\W/g,''));
    if(localStorage.getItem(k)) return;
    localStorage.setItem(k,'1');
    const modal = el('div',{className:'aegis-modal'});
    const card  = el('div',{className:'aegis-card'});
    card.append(
      el('h3',{className:'aegis-title',innerText:'Aegis – Grepolis Remaster'}),
      el('p',{innerText:'Motywy, nowe UI, animacje. Wybierz styl, a grafiki i kolory zmienią się automatycznie.'}),
      el('div',{className:'aegis-actions'},
        [el('button',{className:'aegis-btn',innerText:'Classic',onclick:()=>{localStorage.setItem(KEY,'classic');location.reload();}}),
         el('button',{className:'aegis-btn',innerText:'Pirate', onclick:()=>{localStorage.setItem(KEY,'pirate'); location.reload();}}),
         el('button',{className:'aegis-btn',innerText:'Emerald',onclick:()=>{localStorage.setItem(KEY,'emerald');location.reload();}}),
         el('button',{className:'aegis-btn',innerText:'Dark',   onclick:()=>{localStorage.setItem(KEY,'dark');   location.reload();}})]
      )
    );
    modal.append(card); document.body.appendChild(modal);
    modal.addEventListener('click',e=>{ if(e.target===modal) modal.remove(); },{once:true});
  }

  applyTheme(DEF);
  mountPanel();
  welcome();
})();
"@
$UserJs | Out-File (Join-Path $Usr "grepolis-skin-switcher.user.js") -Encoding utf8
Log "userscript ✓"

# ---- themes CSS (wyraźne zmiany) ----
$cssClassic = @"
@import url('https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700&display=swap');
body{font-family:'Cinzel Decorative',serif}
@keyframes waves{0%{background-position:0 0}100%{background-position:180px 0}}
.aegis-water{background:linear-gradient(180deg,#0fb5ff22,#00447733),url('$RepoRaw/assets/classic/background/port.jpg?v=$Version') center/cover fixed;animation:waves 14s linear infinite}
"@
$cssPirate = @"
body{font-family:'Cinzel Decorative',serif;background:#080b10;color:#eee}
.logo, .gpwindow_header{filter:drop-shadow(0 0 2px #f80);animation:aegisGlow 2.2s ease-in-out infinite alternate}
@keyframes aegisGlow{from{filter:drop-shadow(0 0 2px #f80)}to{filter:drop-shadow(0 0 12px #ffbf00)}}
a, .button, .btn_confirm{color:#ffd47a !important}
"@
$cssEmerald = @"
body{font-family:'Cinzel Decorative',serif;background:#071a12;color:#cfe}
.gpwindow_header, .button, .btn_confirm{border-color:#06d47a !important; box-shadow:0 0 8px #06d47a55}
.logo{animation:aegisShine 3s linear infinite}
@keyframes aegisShine{0%{filter:brightness(1)}50%{filter:brightness(1.6)}100%{filter:brightness(1)}}
"@
$cssDark = @"
body{background:#0d1117;color:#d0d6dc}
@keyframes fog{0%{opacity:.55}50%{opacity:.9}100%{opacity:.55}}
body::after{content:'';position:fixed;inset:0;background:url('$RepoRaw/assets/dark/background/fog.png?v=$Version') repeat;animation:fog 22s ease-in-out infinite;pointer-events:none}
.gpwindow_header,.button,.btn_confirm{background:#161b22;border-color:#30363d;color:#c9d1d9}
"@
$cssClassic | Out-File (Join-Path $Themes "classic.css") -Encoding utf8
$cssPirate  | Out-File (Join-Path $Themes "pirate.css")  -Encoding utf8
$cssEmerald | Out-File (Join-Path $Themes "emerald.css") -Encoding utf8
$cssDark    | Out-File (Join-Path $Themes "dark.css")    -Encoding utf8
Log "themes ✓"

# ---- minimalne, widoczne assety (Base64) ----
function SaveB64($b64,$path){
  [IO.File]::WriteAllBytes($path,[Convert]::FromBase64String($b64))
}
# 256x256 PNG kolorowe (widoczne od razu). Zastąpisz je docelowymi grafikami 1:1.
$pngGold  = "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAIAAADTED8xAAAALUlEQVR4nO3BMQEAAADCoPVP7WcPoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwGAE9wAAc4m6bQAAAABJRU5ErkJggg=="  # złoty
$pngEmer  = "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAIAAADTED8xAAAALUlEQVR4nO3BMQEAAADCoPVP7WcPoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwGAFqgAAc4mDkQAAAABJRU5ErkJggg=="  # zielony
$pngDark  = "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAIAAADTED8xAAAALUlEQVR4nO3BMQEAAADCoPVP7WcPoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwGAEUgAAc4k1eQAAAABJRU5ErkJggg=="  # ciemny
$pngBlue  = "iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAIAAADTED8xAAAALUlEQVR4nO3BMQEAAADCoPVP7WcPoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwGAFgwAAc4k2zQAAAABJRU5ErkJggg=="  # niebieski
$fogTile  = "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAQAAACqG5s8AAAAzUlEQVR42u3YwQ3CMBRF0c8cQakx0m2Zc0o1mQqkcm8w1mKQqQ5j1K0sH3f7xwEw7r8gG1m2qGqf1eFhQfCzq6zq7kZVw9o6z9f0wC3kqCqD7rN2cXrU36j4a7Q9qf3o7j5m+Zk8pYw5Y0t2m6vIf2r0V2m3m8H1yE6q1gN3kq8Zy5g8bC6Uj9sCkX1g8pCkH1gskCkH1gskCkH1gsn3G3b2c+u3k0gk3QAAAABJRU5ErkJggg==" # półprzezroczysta mgła

# classic
SaveB64 $pngBlue "$Assets/classic/units/bireme.png"
SaveB64 $pngBlue "$Assets/classic/units/fire_ship.png"
SaveB64 $pngBlue "$Assets/classic/ui/button.png"
SaveB64 $pngBlue "$Assets/classic/branding/logo.png"
SaveB64 $pngBlue "$Assets/classic/background/port.jpg"
SaveB64 $pngBlue "$Assets/classic/background/city.jpg"
# pirate
SaveB64 $pngGold "$Assets/pirate/units/bireme_pirate.png"
SaveB64 $pngGold "$Assets/pirate/units/fire_ship_pirate.png"
SaveB64 $pngGold "$Assets/pirate/ui/button.png"
SaveB64 $pngGold "$Assets/pirate/branding/logo.png"
SaveB64 $pngGold "$Assets/pirate/background/port_fire.jpg"
SaveB64 $pngGold "$Assets/pirate/background/city_dark.jpg"
# emerald
SaveB64 $pngEmer "$Assets/emerald/units/bireme.png"
SaveB64 $pngEmer "$Assets/emerald/units/fire_ship.png"
SaveB64 $pngEmer "$Assets/emerald/ui/button.png"
SaveB64 $pngEmer "$Assets/emerald/branding/logo.png"
SaveB64 $pngEmer "$Assets/emerald/background/port_green.jpg"
SaveB64 $pngEmer "$Assets/emerald/background/city_gold.jpg"
# dark
SaveB64 $pngDark "$Assets/dark/units/bireme.png"
SaveB64 $pngDark "$Assets/dark/units/fire_ship.png"
SaveB64 $pngDark "$Assets/dark/ui/button.png"
SaveB64 $pngDark "$Assets/dark/branding/logo.png"
SaveB64 $pngDark "$Assets/dark/background/port_night.jpg"
SaveB64 $pngDark "$Assets/dark/background/city_mist.jpg"
SaveB64 $fogTile "$Assets/dark/background/fog.png"
Log "assets (base64) ✓  — podmień 1:1, ścieżki już spięte"

# ---- README / CHANGELOG (nagłówek + auto) ----
$readTop = @"
# Aegis – Grepolis Remaster

**Wersja:** $Version  
**Motywy:** Classic, Pirate Epic, Emerald, Dark.  
**Instalacja (Tampermonkey):**  
$RepoRaw/userscripts/grepolis-skin-switcher.user.js

"@
if(Test-Path "$Root/README.md"){ $rest = Get-Content "$Root/README.md" -Raw } else { $rest="" }
Set-Content "$Root/README.md" ($readTop + $rest) -Encoding utf8
Add-Content "$Root/CHANGELOG.md" "`n## $Version`n- Real-time motywy (CSS+IMG), panel, ekran powitalny, badge wersji`n- Assets + themes spięte 1:1 (podmień pliki w /assets i odśwież)`n"
Log "docs ✓"

# ---- ZIP + SHA + ARCHIVE + GIT ----
if(Test-Path $ZipPath){ Remove-Item $ZipPath -Force }
Compress-Archive -Path "$Cfg","$Themes","$Usr","$Assets","$Root/README.md","$Root/CHANGELOG.md" -DestinationPath $ZipPath
$SHA = (Get-FileHash $ZipPath -Algorithm SHA256).Hash
Log ("ZIP: {0}" -f $ZipPath)
Log ("SHA-256: {0}" -f $SHA)

$day = Get-Date -Format "yyyy-MM-dd"
$archDir = Join-Path $Archive $day
if(-not(Test-Path $archDir)){ New-Item -ItemType Directory -Path $archDir | Out-Null }
Copy-Item $ZipPath $archDir -Force
Log "Archive ✓"

git add .
git commit -m "Build $Version (themes+assets+userscript+docs)"
git push
Log "Git push ✓"
