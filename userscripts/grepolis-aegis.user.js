/* ==UserScript==
@name         Aegis – Grepolis Remaster (1.0.0 Final)
@namespace    https://github.com/KID6767/Aegis
@version      1.0.0
@description  Remaster UI: motywy (Classic/Remaster/Pirate/Dark), panel, animacje (smoke), badge, AssetMap, BBCode linki
@match        https://*.grepolis.com/*
@match        https://*.grepolis.pl/*
@run-at       document-end
@grant        GM_getValue
@grant        GM_setValue
==/UserScript== */
(function(){
  'use strict';
  const get = (k,d)=> typeof GM_getValue==='function' ? GM_getValue(k,d) : (JSON.parse(localStorage.getItem(k)||'null') ?? d);
  const set = (k,v)=> typeof GM_getValue==='function' ? GM_setValue(k,v) : localStorage.setItem(k, JSON.stringify(v));
  const THEMES = {
    classic: `:root{--a:#d4af37;--b:#232a36;--bg:#1a1a1a;--fg:#f2f2f2}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:#1a1a1a!important;color:#f2f2f2!important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:#232a36!important;color:#d4af37!important;border-color:#a8832b!important}
      .button,.btn,.ui-button{background:#2a2a2a!important;color:#f2f2f2!important;border:1px solid #555!important}`,
    remaster: `:root{--g1:#0a2e22;--g2:#113c2d;--gold:#d4af37;--bg:#0e1518;--fg:#f3f3f3}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--bg)!important;color:var(--fg)!important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:linear-gradient(180deg,var(--g1),var(--g2))!important;color:var(--gold)!important;border-color:rgba(212,175,55,.35)!important}
      .button,.btn,.ui-button{background:#122018!important;color:var(--gold)!important;border:1px solid rgba(212,175,55,.35)!important}`,
    pirate: `:root{--gold:#d4af37;--bg:#0b0b0b;--ink:#101010;--fg:#eee}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:#0b0b0b!important;color:#eee!important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:#101010!important;color:#d4af37!important;border-color:#d4af37!important}`,
    dark: `:root{--bg:#111;--fg:#ddd;--ac:#4da6ff}
      body,.gpwindow_content,.game_inner_box,.ui_box,.forum_content{background:#111!important;color:#ddd!important}
      a,.gpwindow_content a,.forum_content a{color:#4da6ff!important}`
  };
  function applyTheme(name){
    const css = THEMES[name] || THEMES.remaster;
    let el = document.getElementById('aegis-theme');
    if(!el){ el=document.createElement('style'); el.id='aegis-theme'; document.head.appendChild(el) }
    el.textContent = css;
  }
  function smoke(){
    if(document.getElementById('aegis-smoke')) return;
    const s=document.createElement('div'); s.id='aegis-smoke';
    const st=document.createElement('style'); st.textContent = `
      #aegis-smoke{position:fixed;left:0;right:0;bottom:-30px;height:140px;z-index:2;pointer-events:none;opacity:.75;
       background: radial-gradient(120px 60px at 10% 80%, rgba(255,255,255,.05), transparent 60%),
                   radial-gradient(180px 70px at 40% 90%, rgba(255,255,255,.07), transparent 60%),
                   radial-gradient(140px 60px at 70% 85%, rgba(255,255,255,.06), transparent 60%),
                   radial-gradient(200px 80px at 90% 95%, rgba(255,255,255,.05), transparent 60%);
       animation:aeg-smoke 9s ease-in-out infinite;}
      @keyframes aeg-smoke{0%{transform:translate3d(0,0,0) scale(1);opacity:.25}50%{transform:translate3d(30px,-10px,0) scale(1.05);opacity:.35}100%{transform:translate3d(0,-20px,0) scale(1.1);opacity:.20}}`;
    document.head.appendChild(st); document.body.appendChild(s);
  }
  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const b=document.createElement('div'); b.id='aegis-badge';
    b.textContent='Aegis 1.0.0'; b.style.cssText='position:fixed;right:10px;top:10px;z-index:99998;background:linear-gradient(135deg,#0a2e22,#113c2d);border:1px solid rgba(212,175,55,.35);color:#d4af37;padding:6px 10px;border-radius:10px;font:600 12px/1.2 system-ui;user-select:none';
    document.body.appendChild(b);
  }
  function panel(){
    if(document.getElementById('aegis-panel')) return;
    const cur = localStorage.getItem('AEGIS_THEME')||'remaster';
    const w=document.createElement('div'); w.id='aegis-panel';
    w.style.cssText='position:fixed;bottom:76px;right:16px;width:320px;background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:12px;padding:12px;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px/1.35 system-ui,Arial';
    w.innerHTML=`
      <div style="display:flex;justify-content:space-between;align-items:center;gap:8px;">
        <b>Aegis 1.0.0</b>
        <button id="aegis-x" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:6px;padding:2px 8px;cursor:pointer;">×</button>
      </div>
      <div style="margin-top:8px">
        <div style="margin:4px 0 6px;">Motyw:</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;">
          ${['classic','remaster','pirate','dark'].map(k=>'<button class="set-theme" data-key="'+k+'" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer;'+(k===cur?'outline:2px solid #d4af37':'')+'">'+k+'</button>').join('')}
        </div>
      </div>
      <div style="margin-top:10px"><a href="https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js" target="_blank" style="color:#f2d574">RAW userscript</a></div>`;
    document.body.appendChild(w);
    w.querySelector('#aegis-x').onclick=()=>w.remove();
    w.querySelectorAll('.set-theme').forEach(btn=>{
      btn.addEventListener('click',()=>{
        const name=btn.getAttribute('data-key');
        localStorage.setItem('AEGIS_THEME',name);
        applyTheme(name); 
      });
    });
  }
  function fab(){
    if(document.getElementById('aegis-fab')) return;
    const f=document.createElement('div'); f.id='aegis-fab';
    f.style.cssText='position:fixed;right:16px;bottom:16px;width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#d4af37,#f2d574);box-shadow:0 10px 30px rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647;';
    f.innerHTML='<div style="width:28px;height:28px;border-radius:6px;background:#0b1d13"></div>';
    f.onclick=panel; document.body.appendChild(f);
  }
  function assetMap(){
    const base='/assets/';
    const map={
      'branding/logo.png': base+'branding/logo_aegis.png',
      'ships/bireme.png' : base+'ships/ship_green.svg'
    };
    const wrap=(src)=>{ 
      try{ for(const k in map){ if(src.includes(k)) return map[k] } }catch(e){}
      return src;
    };
    const _c=document.createElement; 
    document.createElement=function(tag){
      const el=_c.call(document,tag);
      if((''+tag).toLowerCase()==='img'){
        const _set=el.setAttribute;
        el.setAttribute=function(n,v){ if(n==='src' && typeof v==='string'){ v=wrap(v) } return _set.call(this,n,v) }
      } 
      return el;
    };
    const patch=(root)=> root.querySelectorAll?.('img[src]')?.forEach(i=>i.src=wrap(i.src));
    new MutationObserver(m=>m.forEach(x=>x.addedNodes?.forEach(n=>n.nodeType===1&&patch(n)))).observe(document.documentElement,{childList:true,subtree:true});
    patch(document);
  }

  const theme = localStorage.getItem('AEGIS_THEME')||'remaster';
  applyTheme(theme);
  smoke();
  badge();
  fab();
  assetMap();
})();