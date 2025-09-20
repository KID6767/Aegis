// ==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      1.0.1
// @description  Motywy (Classic/Remaster/Pirate/Dark), panel, branding banner, prosta AssetMap
// @author       KID6767 & ChatGPT
// @match        *://*.grepolis.com/*
// @match        *://*.grepolis.pl/*
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
// @run-at       document-end
// @grant        none
// ==/UserScript==

(function(){
  'use strict';
  const RAW = 'https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/';
  const THEMES = {
    classic:  { bg:'#f3e6c1', fg:'#2c2c2c', ac:'#8c6f39' },
    remaster: { bg:'#13221a', fg:'#efead4', ac:'#d4af37' },
    pirate:   { bg:'#0b0b0b', fg:'#e0d0a0', ac:'#8c6f39' },
    dark:     { bg:'#0b0f12', fg:'#d7dfeb', ac:'#7fb07f' }
  };
  function injectCSS(t){
    const id='aegis-style'; let el=document.getElementById(id);
    if(!el){ el=document.createElement('style'); el.id=id; document.head.appendChild(el); }
    el.textContent=`:root{--aeg-bg:${t.bg};--aeg-fg:${t.fg};--aeg-ac:${t.ac}}
    .aeg-bar{position:fixed;right:12px;bottom:12px;z-index:99999;display:flex;gap:8px;align-items:center;
      background:var(--aeg-bg);color:var(--aeg-fg);border:2px solid var(--aeg-ac);border-radius:12px;padding:8px 10px;
      box-shadow:0 8px 24px rgba(0,0,0,.35);font:12px system-ui,Segoe UI,Arial}
    .aeg-btn{cursor:pointer;padding:4px 8px;border:1px solid var(--aeg-ac);border-radius:8px;background:transparent;color:var(--aeg-fg)}
    .aeg-btn:hover{background:var(--aeg-ac);color:#111}
    .aeg-modal-backdrop{position:fixed;inset:0;background:rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;z-index:100000}
    .aeg-modal{width:min(900px,92vw);max-height:86vh;overflow:auto;background:var(--aeg-bg);color:var(--aeg-fg);
      border:2px solid var(--aeg-ac);border-radius:16px;padding:18px;box-shadow:0 10px 30px rgba(0,0,0,.45)}
    .aeg-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
    .aeg-card{border:1px dashed var(--aeg-ac);border-radius:12px;padding:10px;background:rgba(0,0,0,.03)}`;
  }
  function loadTheme(name){
    const t = THEMES[name]||THEMES.remaster;
    injectCSS(t);
    localStorage.setItem('AEGIS::theme', name);
  }
  function banner(){
    const img=new Image(); img.src=RAW+'banner.svg'; img.alt='Aegis banner'; img.style.cssText='width:100%;border-radius:12px;border:1px solid var(--aeg-ac)'; return img;
  }
  function openModal(){
    const wrap=document.createElement('div'); wrap.className='aeg-modal-backdrop';
    const m=document.createElement('div'); m.className='aeg-modal';
    m.innerHTML=`<button class="aeg-btn aeg-close" style="float:right">×</button>
      <h2 style="margin:0 0 10px 0">AEGIS — Grepolis Remaster</h2>
      <div class="aeg-grid">
        <div class="aeg-card">
          <b>Motywy</b><br/><br/>
          ${['classic','remaster','pirate','dark'].map(k=>'<button class="aeg-btn sw" data-k="'+k+'">'+k+'</button>').join(' ')}
        </div>
        <div class="aeg-card">
          <b>Branding</b><br/><br/>
          <ul style="margin-top:6px">
            <li>banner.svg</li><li>ship_green.svg</li><li>ship_pirate.svg</li><li>spinner.gif</li>
          </ul>
          <small>Podmień pliki w <code>assets/branding</code> w swoim repo.</small>
        </div>
        <div class="aeg-card" style="grid-column:1 / span 2"></div>
      </div>`;
    wrap.appendChild(m); document.body.appendChild(wrap);
    m.querySelector('.aeg-card:last-child').appendChild(banner());
    m.querySelector('.aeg-close').onclick=()=>wrap.remove();
    m.querySelectorAll('.sw').forEach(b=>b.onclick=()=>loadTheme(b.dataset.k));
  }
  function initBar(){
    const bar=document.createElement('div'); bar.className='aeg-bar';
    bar.innerHTML=`<button class="aeg-btn" id="aeg-open">Aegis</button>
      <select class="aeg-btn" id="aeg-theme">${Object.keys(THEMES).map(k=>'<option value="'+k+'">'+k+'</option>').join('')}</select>`;
    document.body.appendChild(bar);
    document.getElementById('aeg-open').onclick=openModal;
    const sel=document.getElementById('aeg-theme');
    sel.value=localStorage.getItem('AEGIS::theme')||'remaster';
    sel.onchange=()=>loadTheme(sel.value);
  }
  function ready(fn){ if(document.readyState==='loading') document.addEventListener('DOMContentLoaded', fn); else fn(); }
  ready(()=>{ loadTheme(localStorage.getItem('AEGIS::theme')||'remaster'); initBar(); console.log('%cAegis ready','color:#0f0;background:#222;padding:2px 6px;border-radius:6px'); });
})();
