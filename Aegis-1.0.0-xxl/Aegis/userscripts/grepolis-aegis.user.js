// ==UserScript==
// @name         Aegis – Grepolis Remaster (1.0.0 XXL)
// @namespace    https://github.com/KID6767/Aegis
// @version      1.0.0
// @description  Stabilny remaster UI: motywy, panel z logo, RAW Base, AssetMap (grafiki), dym/fajerwerki (on/off), logger i skróty (Alt+G/Alt+T).
// @author       KID6767 & ChatGPT
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
// @run-at       document-end
// @grant        GM_getValue
// @grant        GM_setValue
// ==/UserScript==
(function () {
  'use strict';

  const VER = '1.0.0';
  const get = (k, d) => (typeof GM_getValue === 'function' ? GM_getValue(k, d) : (JSON.parse(localStorage.getItem(k) || 'null') ?? d));
  const set = (k, v) => (typeof GM_setValue === 'function' ? GM_setValue(k, v) : localStorage.setItem(k, JSON.stringify(v)));
  const AEGIS = (window.AEGIS ||= {});
  AEGIS.version = VER;
  AEGIS.getLogLevel = () => get('aegis_log', 'info');   // 'info' | 'off'
  AEGIS.setLogLevel = (lvl) => set('aegis_log', (lvl || 'off'));
  AEGIS.log = (...a) => { if (AEGIS.getLogLevel() !== 'off') console.log('%c[Aegis]', 'color:#d4af37;font-weight:700', ...a); };
  AEGIS.toast = (msg, ms = 2200) => {
    const t = document.createElement('div');
    t.textContent = msg;
    t.style.cssText = 'position:fixed;left:50%;bottom:60px;transform:translateX(-50%);background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:10px;padding:8px 12px;z-index:2147483647;box-shadow:0 8px 24px rgba(0,0,0,.55);font:13px/1.3 system-ui,Arial';
    document.body.appendChild(t); setTimeout(() => t.remove(), ms);
  };
  const onReady = (fn) => (document.readyState === 'loading' ? document.addEventListener('DOMContentLoaded', fn) : fn());

  // Themes (inline fallback)
  const THEMES = {
    classic: `:root{--aeg-gold:#d4af37;--aeg-gold-2:#f2d574;--aeg-bg:#1a1a1a;--aeg-fg:#f2f2f2;}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:#1a1a1a !important;color:#f2f2f2 !important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:#232a36 !important;color:#d4af37 !important;border-color:#a8832b !important}
      .button,.btn,.ui-button{background:#2a2a2a !important;color:#f2f2f2 !important;border:1px solid #555 !important;box-shadow:0 4px 14px rgba(0,0,0,.35)}
      a{color:#e3c26b !important}.gp_table th,.gp_table td{border-color:#555 !important}`,
    remaster: `:root{--aeg-green:#0a2e22;--aeg-green-2:#113c2d;--aeg-gold:#d4af37;--aeg-gold-2:#f2d574;--aeg-fg:#f3f3f3;--aeg-bg:#0e1518}
      @keyframes aegis-glow{0%,100%{box-shadow:0 0 0 rgba(212,175,55,0)}50%{box-shadow:0 0 12px rgba(212,175,55,.45)}}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--aeg-bg) !important;color:var(--aeg-fg) !important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:linear-gradient(180deg,var(--aeg-green),var(--aeg-green-2)) !important;color:var(--aeg-gold) !important;border-color:rgba(212,175,55,.35) !important}
      .button,.btn,.ui-button{background:#122018 !important;color:var(--aeg-gold) !important;border:1px solid rgba(212,175,55,.35) !important;box-shadow:0 10px 30px rgba(0,0,0,.55);text-shadow:0 1px 0 rgba(0,0,0,.65)}
      .gp_table th,.gp_table td{border-color:rgba(212,175,55,.35) !important}`,
    pirate: `:root{--aeg-gold:#d4af37;--aeg-bg:#0b0b0b;--aeg-ink:#101010;--aeg-fg:#eee}
      body,.gpwindow_content,.game_inner_box,.ui_box{background:#0b0b0b !important;color:#eee !important}
      .game_header,.ui-dialog .ui-dialog-titlebar{background:#101010 !important;color:#d4af37 !important;border-color:#d4af37 !important}
      .button,.btn,.ui-button{background:#151515 !important;color:#d4af37 !important;border:1px solid #d4af37 !important;box-shadow:0 8px 26px rgba(0,0,0,.6)}
      a{color:#e5c66a !important}`,
    dark: `:root{--aeg-bg:#111;--aeg-fg:#ddd;--aeg-ac:#4da6ff}
      body,.gpwindow_content,.game_inner_box,.ui_box,.forum_content{background:#111 !important;color:#ddd !important}
      a,.gpwindow_content a,.forum_content a{color:#4da6ff !important}
      .button,.btn,.ui-button{background:#333 !important;color:#eee !important;border:1px solid #555 !important}`
  };
  function injectTheme(name){
    const css = THEMES[name] || THEMES.remaster;
    const id = 'aegis-theme-style';
    let el = document.getElementById(id);
    if(!el){ el = document.createElement('style'); el.id=id; document.head.appendChild(el); }
    el.textContent = css;
    document.documentElement.classList.add('aegis-theme');
  }
  AEGIS.getTheme = () => get('aegis_theme','remaster');
  AEGIS.applyTheme = (name)=>{ set('aegis_theme',name); injectTheme(name); AEGIS.toast('Motyw: '+name); };
  AEGIS.cycleTheme = ()=>{ const list = Object.keys(THEMES); const cur = AEGIS.getTheme(); const i=list.indexOf(cur); AEGIS.applyTheme(list[(i+1)%list.length]); };

  // RAW base + AssetMap
  AEGIS.getRawBase = () => get('aegis_raw', 'https://raw.githubusercontent.com/KID6767/Aegis/main/assets');
  AEGIS.setRawBase = (url) => set('aegis_raw', (url||'').trim() || AEGIS.getRawBase());
  AEGIS._assetMapExt = get('aegis_asset_map_ext', {});
  AEGIS.addAssetMap = (obj)=>{ Object.assign(AEGIS._assetMapExt, obj||{}); set('aegis_asset_map_ext', AEGIS._assetMapExt); AEGIS.toast('Dodano reguły AssetMap'); };

  function baseMap(){
    const RAW = AEGIS.getRawBase();
    return {
      "ships/bireme.png"      : RAW + "/ships/bireme.png",
      "ui/settings.png"       : RAW + "/ui/settings.png",
      "branding/logo.png"     : RAW + "/branding/logo_aegis.png"
    };
  }
  AEGIS.resolveAsset = (src)=>{
    try{
      const map = {...baseMap(), ...AEGIS._assetMapExt};
      for(const [needle,url] of Object.entries(map)){
        if(src.includes(needle)) return url;
      }
      return src;
    }catch(e){return src;}
  };

  (function interceptCreate(){
    const orig = document.createElement;
    document.createElement = function(tag){
      const el = orig.call(document,tag);
      if(String(tag).toLowerCase()==='img'){
        const setAttr = el.setAttribute;
        el.setAttribute = function(name,value){
          if(name==='src' && typeof value==='string'){ value=AEGIS.resolveAsset(value); }
          return setAttr.call(this,name,value);
        };
      }
      return el;
    };
  })();
  (function observeImgs(){
    const patch = (node)=>{
      if(node.tagName==='IMG' && node.src) node.src = AEGIS.resolveAsset(node.src);
      node.querySelectorAll?.('img[src]')?.forEach(img => img.src = AEGIS.resolveAsset(img.src));
    };
    new MutationObserver(m=>m.forEach(x=>x.addedNodes?.forEach(n=>n.nodeType===1 && patch(n)))).observe(document.documentElement,{childList:true,subtree:true});
    patch(document);
  })();

  // FX
  AEGIS.getFx = ()=> get('aegis_fx', {smoke:true, fireworks:true});
  AEGIS.toggleFx = (k,v)=>{ const fx=AEGIS.getFx(); fx[k]=!!v; set('aegis_fx',fx); AEGIS.toast(`FX ${k}: ${v?'ON':'OFF'}`); };

  function ensureSmoke(){
    if(!AEGIS.getFx().smoke) return;
    if(!document.getElementById('aegis-smoke-style')){
      const s = document.createElement('style'); s.id='aegis-smoke-style';
      s.textContent = `
      #aegis-smoke{position:fixed;left:0;right:0;bottom:-30px;height:140px;z-index:1;pointer-events:none;opacity:.75;
        background: radial-gradient(120px 60px at 10% 80%, rgba(255,255,255,.05), transparent 60%),
                    radial-gradient(180px 70px at 40% 90%, rgba(255,255,255,.07), transparent 60%),
                    radial-gradient(140px 60px at 70% 85%, rgba(255,255,255,.06), transparent 60%),
                    radial-gradient(200px 80px at 90% 95%, rgba(255,255,255,.05), transparent 60%);
        animation:aegis-smoke 9s ease-in-out infinite;}
      @keyframes aegis-smoke{0%{transform:translate3d(0,0,0) scale(1);opacity:.25}50%{transform:translate3d(30px,-10px,0) scale(1.05);opacity:.35}100%{transform:translate3d(0,-20px,0) scale(1.1);opacity:.20}}
      `;
      document.head.appendChild(s);
    }
    if(!document.getElementById('aegis-smoke')){
      const g = document.createElement('div'); g.id='aegis-smoke'; document.body.appendChild(g);
    }
  }

  function fireworks(ms=3200){
    if(!AEGIS.getFx().fireworks) return;
    if(document.hidden) return;
    const c = document.createElement('canvas');
    Object.assign(c.style,{position:'fixed',inset:'0',zIndex:99999,pointerEvents:'none'});
    const ctx = c.getContext('2d'); document.body.appendChild(c);
    const DPR = Math.max(1, window.devicePixelRatio||1);
    function resize(){ c.width=innerWidth*DPR; c.height=innerHeight*DPR; ctx.setTransform(DPR,0,0,DPR,0,0); }
    resize(); addEventListener('resize', resize);
    const parts=[];
    function boom(x,y){
      const N = 60+Math.floor(Math.random()*60);
      const cols = ['#ffd86b','#e6c55e','#f2e5a3','#fff9d2','#fbe6a4'];
      for(let i=0;i<N;i++){
        const a=Math.random()*Math.PI*2, s=2+Math.random()*4;
        parts.push({x,y,vx:Math.cos(a)*s, vy:Math.sin(a)*s-1.5, life:60+Math.random()*40, color:cols[i%cols.length]});
      }
    }
    for(let i=0;i<4;i++) boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.5*Math.random()));
    const stopAt = performance.now()+ms;
    (function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      for(const p of parts){
        p.vy+=0.045; p.x+=p.vx; p.y+=p.vy; p.life-=1;
        ctx.globalAlpha = Math.max(0, p.life/90);
        ctx.beginPath(); ctx.arc(p.x,p.y,2.1,0,Math.PI*2); ctx.fillStyle=p.color; ctx.fill();
      }
      for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1);
      if(performance.now()<stopAt && parts.length) requestAnimationFrame(loop); else c.remove();
    })();
  }

  // Panel + shortcuts
  function mountLogoFAB(){
    if(document.getElementById('aegis-fab')) return;
    const fab = document.createElement('div'); fab.id='aegis-fab'; fab.title='Aegis — ustawienia';
    fab.style.cssText='position:fixed;right:16px;bottom:16px;width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#d4af37,#f2d574);box-shadow:0 10px 30px rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647;';
    fab.innerHTML='<div style="width:28px;height:28px;border-radius:6px;background:#0b1d13;animation:aegis-pulse 3s infinite"></div><style>@keyframes aegis-pulse{0%,100%{filter:none}50%{filter:brightness(1.15)}}</style>';
    fab.onclick = mountPanel;
    document.body.appendChild(fab);
    window.addEventListener('keydown',(e)=>{
      if(e.altKey && !e.shiftKey && !e.ctrlKey){
        if(e.code==='KeyG'){ e.preventDefault(); mountPanel(); }
        if(e.code==='KeyT'){ e.preventDefault(); AEGIS.cycleTheme(); }
      }
    });
  }

  function mountPanel(){
    if(document.getElementById('aegis-panel')) return;
    const raw = AEGIS.getRawBase(); const cur = AEGIS.getTheme(); const fx = AEGIS.getFx();
    const wrap = document.createElement('div'); wrap.id='aegis-panel';
    wrap.style.cssText='position:fixed;bottom:76px;right:16px;width:320px;background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:12px;padding:12px;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px/1.35 system-ui,Arial';
    wrap.innerHTML = `
      <div style="display:flex;justify-content:space-between;align-items:center;gap:8px;">
        <b>Aegis ${VER}</b>
        <button id="aegis-close" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:6px;padding:2px 8px;cursor:pointer;">×</button>
      </div>
      <div style="margin-top:8px">
        <div style="margin:4px 0 6px;">Motyw:</div>
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;">
          ${['classic','remaster','pirate','dark'].map(k=>`<button class="aegis-theme" data-t="${k}" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer;${k===cur?'outline:2px solid #d4af37':''}">${k}</button>`).join('')}
        </div>
      </div>
      <div style="margin-top:10px">
        <div>RAW base (assets):</div>
        <input id="aegis-raw" value="${raw}" style="width:100%;padding:6px;border-radius:8px;border:1px solid #d4af37;background:#111;color:#d4af37;">
        <button id="aegis-raw-save" style="margin-top:6px;width:100%;background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer;">Zapisz RAW base</button>
      </div>
      <div style="margin-top:10px">
        <label style="display:flex;align-items:center;gap:8px;cursor:pointer;">
          <input id="aegis-smoke" type="checkbox" ${fx.smoke ? 'checked':''}/><span>Animowany dym</span>
        </label>
      </div>
      <div style="margin-top:10px">
        <label style="display:flex;align-items:center;gap:8px;cursor:pointer;">
          <input id="aegis-fireworks" type="checkbox" ${fx.fireworks ? 'checked':''}/><span>Fajerwerki (ekran powitalny)</span>
        </label>
      </div>
      <div style="margin-top:10px">
        <label style="display:flex;align-items:center;gap:8px;cursor:pointer;">
          <input id="aegis-logger" type="checkbox" ${AEGIS.getLogLevel()!=='off' ? 'checked':''}/><span>Logger (konsola)</span>
        </label>
      </div>
    `;
    document.body.appendChild(wrap);
    wrap.querySelectorAll('.aegis-theme').forEach(btn => btn.addEventListener('click', () => AEGIS.applyTheme(btn.dataset.t)));
    wrap.querySelector('#aegis-raw-save').onclick = () => { AEGIS.setRawBase(wrap.querySelector('#aegis-raw').value.trim()); AEGIS.toast('Zapisano RAW base'); };
    wrap.querySelector('#aegis-smoke').onchange = (e) => AEGIS.toggleFx('smoke', !!e.target.checked);
    wrap.querySelector('#aegis-fireworks').onchange = (e) => AEGIS.toggleFx('fireworks', !!e.target.checked);
    wrap.querySelector('#aegis-logger').onchange = (e) => AEGIS.setLogLevel(e.target.checked ? 'info' : 'off');
    wrap.querySelector('#aegis-close').onclick = () => wrap.remove();
  }

  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const el = document.createElement('div'); el.id='aegis-badge';
    el.textContent='Aegis '+VER;
    el.style.cssText='position:fixed;right:10px;top:10px;z-index:99998;background:linear-gradient(135deg,#0a2e22,#113c2d);border:1px solid rgba(212,175,55,.35);color:#d4af37;padding:6px 10px;border-radius:10px;font:600 12px/1.2 system-ui,Segoe UI,Arial;animation:aegis-glow 3.2s ease-in-out infinite;user-select:none;pointer-events:none;';
    const glow = document.createElement('style'); glow.textContent='@keyframes aegis-glow{0%,100%{box-shadow:0 0 0 rgba(212,175,55,0)}50%{box-shadow:0 0 12px rgba(212,175,55,.45)}}';
    document.head.appendChild(glow);
    document.body.appendChild(el);
  }
  function fireworks(ms=3200){
    if(!AEGIS.getFx().fireworks) return;
    if(document.hidden) return;
    const c = document.createElement('canvas');
    Object.assign(c.style,{position:'fixed',inset:'0',zIndex:99999,pointerEvents:'none'});
    const ctx = c.getContext('2d'); document.body.appendChild(c);
    const DPR = Math.max(1, window.devicePixelRatio||1);
    function resize(){ c.width=innerWidth*DPR; c.height=innerHeight*DPR; ctx.setTransform(DPR,0,0,DPR,0,0); }
    resize(); addEventListener('resize', resize);
    const parts=[];
    function boom(x,y){
      const N = 60+Math.floor(Math.random()*60);
      const cols = ['#ffd86b','#e6c55e','#f2e5a3','#fff9d2','#fbe6a4'];
      for(let i=0;i<N;i++){
        const a=Math.random()*Math.PI*2, s=2+Math.random()*4;
        parts.push({x,y,vx:Math.cos(a)*s, vy:Math.sin(a)*s-1.5, life:60+Math.random()*40, color:cols[i%cols.length]});
      }
    }
    for(let i=0;i<4;i++) boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.5*Math.random()));
    const stopAt = performance.now()+ms;
    (function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      for(const p of parts){
        p.vy+=0.045; p.x+=p.vx; p.y+=p.vy; p.life-=1;
        ctx.globalAlpha = Math.max(0, p.life/90);
        ctx.beginPath(); ctx.arc(p.x,p.y,2.1,0,Math.PI*2); ctx.fillStyle=p.color; ctx.fill();
      }
      for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1);
      if(performance.now()<stopAt && parts.length) requestAnimationFrame(loop); else c.remove();
    })();
  }
  function welcome(){
    const k='Aegis::seen::'+VER;
    if(get(k,null)) return;
    set(k, Date.now());
    const w = document.createElement('div'); w.id='aegis-welcome';
    w.style.cssText='position:fixed;inset:0;z-index:99997;display:flex;align-items:center;justify-content:center;background:radial-gradient(ellipse at center, rgba(0,0,0,.55), rgba(0,0,0,.85));';
    w.innerHTML = `
      <div style="width:min(720px,92vw);color:#f3f3f3;background:linear-gradient(180deg,rgba(10,46,34,.96),rgba(10,46,34,.92));border:1px solid rgba(212,175,55,.35);border-radius:16px;padding:18px 20px;box-shadow:0 10px 30px rgba(0,0,0,.5);">
        <div style="display:flex;gap:14px;align-items:center;margin-bottom:8px">
          <div style="width:46px;height:46px;border-radius:10px;background:linear-gradient(135deg,#d4af37,#f2d574);box-shadow:inset 0 2px 6px rgba(0,0,0,.25);"></div>
          <div><h1 style="margin:0;font:800 20px/1.2 system-ui,Segoe UI,Arial;color:#d4af37">Aegis ${VER}</h1>
          <p style="margin:4px 0 0;opacity:.9">Remaster UI aktywny. Miłej gry!</p></div>
        </div>
        <p>• Butelkowa zieleń + złoto • Delikatne cienie i połysk • Animowany dym u dołu (możesz wyłączyć w panelu)</p>
        <div style="display:flex;gap:10px;margin-top:14px">
          <button id="aegis-ok" style="background:linear-gradient(180deg,#d4af37,#f2d574);color:#2a2000;border:none;border-radius:12px;padding:10px 16px;font-weight:700;cursor:pointer;box-shadow:0 4px 10px rgba(0,0,0,.35);">Zaczynamy!</button>
        </div>
      </div>`;
    document.body.appendChild(w);
    document.getElementById('aegis-ok').onclick = ()=> w.remove();
    setTimeout(()=>fireworks(),150);
  }

  function start(){
    injectTheme(AEGIS.getTheme());
    ensureSmoke();
    badge();
    mountLogoFAB();
    welcome();
    AEGIS.log('ready');
  }
  onReady(start);
})();