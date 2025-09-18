// ==UserScript==
// @name         Aegis — Grepolis Remaster (visual)
// @namespace    https://github.com/KID6767/Aegis-Grepolis-Remake
// @version      0.6-dev
// @description  Full visual remaster 2025: 3 themes, Dark, @2x, animations (waves, fire, aura, flags), sprite overlays, RAW loader.
// @author       KID6767
// @match        *://*.grepolis.com/*
// @run-at       document-end
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// ==/UserScript==

(function(){"use strict";
  const BASE_RAW = "https://raw.githubusercontent.com/KID6767/Aegis-Grepolis-Remake/main";
  const MAP_PATH = "/config/mapping.json";
  const THEMES = ["classic","pirate_epic","emerald"];
  let currentTheme = GM_getValue("aegis_theme","classic");
  let mapping = null;
  const root = document.documentElement;
  const ROLE_MAP = [["harbor","aegis-role-port"],["temple","aegis-role-temple"],["senate","aegis-role-senate"],["attack","aegis-role-attack"]];

  function rawUrl(p){ return BASE_RAW + p; }
  function fetchJson(url){ return new Promise((resolve)=>{ try{ GM_xmlhttpRequest({method:"GET",url:url+"?t="+Date.now(),onload:(r)=>{ try{resolve(JSON.parse(r.responseText))}catch(e){resolve(null)} },onerror:()=>resolve(null)})}catch(e){ fetch(url).then(r=>r.json()).then(resolve).catch(()=>resolve(null)); } }); }

  function loadThemeCSS(theme){ ['aegis-theme-css','aegis-anim-css'].forEach(id=>document.getElementById(id)?.remove()); const l1=document.createElement('link');l1.id='aegis-theme-css';l1.rel='stylesheet';l1.href=rawUrl(`/assets/themes/${theme}/theme.css`)+"?t="+Date.now(); const l2=document.createElement('link');l2.id='aegis-anim-css';l2.rel='stylesheet';l2.href=rawUrl(`/assets/themes/${theme}/theme-anim.css`)+"?t="+Date.now(); document.head.append(l1,l2); root.classList.remove('aegis-anim-classic','aegis-anim-pirate_epic','aegis-anim-emerald'); root.classList.add('aegis-anim-'+theme); ensureFog(); }
  function ensureFog(){ let fog=document.querySelector('.aegis-fog-overlay'); if(!fog){ fog=document.createElement('div'); fog.className='aegis-fog-overlay'; document.body.appendChild(fog); } }

  function pickDensityKey(fname){ const hi=fname.replace(/\.png$/i,'@2x.png'); return (mapping[currentTheme] && mapping[currentTheme][hi]) ? hi : fname; }
  function chooseKey(fname){ const map=mapping[currentTheme]||{}; if(map[fname]) return fname; const base=fname.replace('@2x.png','').replace('.png',''); for(const k of Object.keys(map)){ if(k.includes(base)) return k; } return null; }
  function addRoles(el,fname){ const base=fname.toLowerCase(); ROLE_MAP.forEach(([frag,cls])=>{ if(base.includes(frag)) el.classList.add(cls); }); }
  function mapUrl(src,el){ const fname=src.split('/').pop().split('?')[0].toLowerCase(); const key=chooseKey(fname); if(!key) return null; addRoles(el,key); const best=pickDensityKey(key); return rawUrl((mapping[currentTheme][best]||mapping[currentTheme][key])); }

  function reskin(node=document){ node.querySelectorAll('img').forEach(img=>{ if(img.dataset.aegisSkinned==='1') return; const nu=mapUrl(img.src,img); if(nu){ img.src=nu; img.dataset.aegisSkinned='1'; img.classList.add('aegis-icon'); } }); node.querySelectorAll("[style*='background'], .unit_icon, .ship_icon, .building_icon, .gp_background").forEach(el=>{ if(el.dataset.aegisSkinned==='1') return; const bg=getComputedStyle(el).getPropertyValue('background-image'); const m=bg&&bg.match(/url\(["']?([^"')]+)["']?\)/); if(m&&m[1]){ const nu=mapUrl(m[1],el); if(nu){ el.style.backgroundImage=`url("${nu}")`; el.dataset.aegisSkinned='1'; } }); }
  function setTheme(t){ if(!THEMES.includes(t)) return; currentTheme=t; GM_setValue('aegis_theme',t); document.querySelectorAll('[data-aegis-skinned]').forEach(n=>n.removeAttribute('data-aegis-skinned')); loadThemeCSS(t); reskin(); updatePanel(); }
  function setDark(on){ GM_setValue('aegis_dark',!!on); document.documentElement.classList.toggle('aegis-dark',!!on); updatePanel(); }
  function updatePanel(){ const sel=document.getElementById('aegis-theme'); if(sel) sel.value=currentTheme; const d=document.getElementById('aegis-dark'); if(d) d.textContent='Dark: '+(GM_getValue('aegis_dark',false)?'ON':'OFF'); }
  function addPanel(){ const wrap=document.createElement('div'); wrap.innerHTML=`<div style="position:fixed;right:12px;bottom:12px;z-index:2147483647;background:rgba(10,10,10,.75);padding:10px;border-radius:10px;color:#fff;font:12px/1.3 system-ui,Segoe UI,Arial;"><div style="display:flex;gap:6px;align-items:center;"><strong>Aegis</strong><select id="aegis-theme"><option value="classic">Classic</option><option value="pirate_epic">Pirate-Epic</option><option value="emerald">Emerald</option></select><button id="aegis-dark">Dark: OFF</button><button id="aegis-reskin">Refresh</button></div></div>`; document.body.appendChild(wrap.firstElementChild); document.getElementById('aegis-theme').addEventListener('change',e=>setTheme(e.target.value)); document.getElementById('aegis-dark').addEventListener('click',()=>setDark(!GM_getValue('aegis_dark',false))); document.getElementById('aegis-reskin').addEventListener('click',()=>reskin()); updatePanel(); }

  async function init(){ addPanel(); loadThemeCSS(currentTheme); mapping = await fetchJson(rawUrl(MAP_PATH)) || {"classic":{}, "pirate_epic":{}, "emerald":{}}; setDark(GM_getValue('aegis_dark',false)); reskin(); const obs=new MutationObserver(ms=>ms.forEach(m=>m.addedNodes.forEach(n=>n.nodeType===1 && reskin(n)))); obs.observe(document.documentElement,{childList:true,subtree:true}); }
  init();
})();
