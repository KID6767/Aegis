/* ==UserScript==
@name         Aegis – Grepolis Remaster
@namespace    https://github.com/KID6767/Aegis
@version      1.0.0
@description  Motywy (Classic/Remaster/Pirate/Dark) + panel z logo (PP dół) + ekran powitalny + fajerwerki + AssetMap (podmiana grafik).
@author       KID6767 and "ChatGPT"
@match        https://*.grepolis.com/*
@match        https://*.grepolis.pl/*
@run-at       document-end
@grant        none
==/UserScript== */
(function(){
  'use strict';
  const A = (window.AEGIS ||= {});
  const VER = '1.0.0';
  const get = (k,d)=>{try{return JSON.parse(localStorage.getItem(k)) ?? d}catch(e){return d}};
  const set = (k,v)=>localStorage.setItem(k,JSON.stringify(v));

  // ---- Themes (inline fallback) ----
  const THEMES = {
    classic: `:root{--aeg-gold:#d4af37;--aeg-bg:#1a1a1a;--aeg-fg:#f2f2f2}
body,.gpwindow_content,.game_inner_box,.ui_box{background:#1a1a1a !important;color:#f2f2f2 !important}
.game_header,.ui-dialog .ui-dialog-titlebar{background:#232a36 !important;color:#d4af37 !important;border-color:#a8832b !important}
.button,.btn,.ui-button{background:#2a2a2a !important;color:#f2f2f2 !important;border:1px solid #555 !important;box-shadow:0 4px 14px rgba(0,0,0,.35)}
a{color:#e3c26b !important}`,
    remaster:`:root{--aeg-green:#0a2e22;--aeg-green-2:#113c2d;--aeg-gold:#d4af37;--aeg-fg:#f3f3f3;--aeg-bg:#0e1518}
@keyframes aegis-glow{0%,100%{box-shadow:0 0 0 rgba(212,175,55,0)}50%{box-shadow:0 0 12px rgba(212,175,55,.45)}}
body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--aeg-bg)!important;color:var(--aeg-fg)!important}
.game_header,.ui-dialog .ui-dialog-titlebar{background:linear-gradient(180deg,var(--aeg-green),var(--aeg-green-2))!important;color:var(--aeg-gold)!important;border-color:rgba(212,175,55,.35)!important}
.button,.btn,.ui-button{background:#122018!important;color:var(--aeg-gold)!important;border:1px solid rgba(212,175,55,.35)!important;box-shadow:0 10px 30px rgba(0,0,0,.55);text-shadow:0 1px 0 rgba(0,0,0,.65)}`,
    pirate:  `:root{--aeg-gold:#d4af37;--aeg-bg:#0b0b0b;--aeg-fg:#eee}
body,.gpwindow_content,.game_inner_box,.ui_box{background:#0b0b0b!important;color:#eee!important}
.game_header,.ui-dialog .ui-dialog-titlebar{background:#101010!important;color:#d4af37!important;border-color:#d4af37!important}
.button,.btn,.ui-button{background:#151515!important;color:#d4af37!important;border:1px solid #d4af37!important;box-shadow:0 8px 26px rgba(0,0,0,.6)}`,
    dark:    `:root{--aeg-bg:#111;--aeg-fg:#ddd;--aeg-ac:#4da6ff}
body,.gpwindow_content,.game_inner_box,.ui_box,.forum_content{background:#111!important;color:#ddd!important}
a,.gpwindow_content a,.forum_content a{color:#4da6ff!important}
.button,.btn,.ui-button{background:#333!important;color:#eee!important;border:1px solid #555!important}`
  };
  function injectTheme(name){
    const css = THEMES[name] || THEMES.remaster;
    let el = document.getElementById('aegis-theme-style');
    if(!el){ el=document.createElement('style'); el.id='aegis-theme-style'; document.head.appendChild(el); }
    el.textContent = css;
  }
  A.getTheme = ()=> get('aegis_theme','remaster');
  A.applyTheme = (name)=>{ set('aegis_theme',name); injectTheme(name); toast('Motyw: '+name); };

  // ---- Toast ----
  function toast(msg,ms=2000){
    const t=document.createElement('div');
    t.textContent=msg;
    t.style.cssText='position:fixed;left:50%;bottom:60px;transform:translateX(-50%);background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:10px;padding:8px 12px;z-index:2147483647;box-shadow:0 8px 24px rgba(0,0,0,.55);font:13px system-ui';
    document.body.appendChild(t); setTimeout(()=>t.remove(),ms);
  }

  // ---- Badge ----
  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const el = document.createElement('div'); el.id='aegis-badge';
    el.textContent='Aegis '+VER;
    el.style.cssText='position:fixed;right:10px;top:10px;z-index:99998;background:linear-gradient(135deg,#0a2e22,#113c2d);border:1px solid rgba(212,175,55,.35);color:#d4af37;padding:6px 10px;border-radius:10px;font:600 12px/1.2 system-ui;animation:aegis-glow 3.2s ease-in-out infinite;pointer-events:none;user-select:none';
    const g=document.createElement('style'); g.textContent='@keyframes aegis-glow{0%,100%{box-shadow:0 0 0 rgba(212,175,55,0)}50%{box-shadow:0 0 12px rgba(212,175,55,.45)}}';
    document.head.appendChild(g); document.body.appendChild(el);
  }

  // ---- Smoke + Fireworks ----
  function ensureSmoke(){
    if(document.getElementById('aegis-smoke-style')) return;
    const s=document.createElement('style'); s.id='aegis-smoke-style';
    s.textContent = '#aegis-smoke{position:fixed;left:0;right:0;bottom:-30px;height:140px;z-index:1;pointer-events:none;opacity:.75;background:radial-gradient(120px 60px at 10% 80%, rgba(255,255,255,.05), transparent 60%),radial-gradient(180px 70px at 40% 90%, rgba(255,255,255,.07), transparent 60%),radial-gradient(140px 60px at 70% 85%, rgba(255,255,255,.06), transparent 60%),radial-gradient(200px 80px at 90% 95%, rgba(255,255,255,.05), transparent 60%);animation:aegis-smoke 9s ease-in-out infinite}@keyframes aegis-smoke{0%{transform:translate3d(0,0,0) scale(1);opacity:.25}50%{transform:translate3d(30px,-10px,0) scale(1.05);opacity:.35}100%{transform:translate3d(0,-20px,0) scale(1.1);opacity:.20)}';
    document.head.appendChild(s);
    const g = document.createElement('div'); g.id='aegis-smoke'; document.body.appendChild(g);
  }
  function fireworks(ms=3200){
    const c=document.createElement('canvas'); c.style.cssText='position:fixed;inset:0;z-index:2147483647;pointer-events:none';
    const ctx=c.getContext('2d'); document.body.appendChild(c);
    const DPR=Math.max(1,window.devicePixelRatio||1);
    function resize(){ c.width=innerWidth*DPR; c.height=innerHeight*DPR; ctx.setTransform(DPR,0,0,DPR,0,0); }
    resize(); addEventListener('resize', resize);
    const parts=[]; function boom(x,y){ const N=60+Math.floor(Math.random()*60); const cols=['#ffd86b','#e6c55e','#f2e5a3','#fff9d2','#fbe6a4']; for(let i=0;i<N;i++){const a=Math.random()*Math.PI*2,s=2+Math.random()*4;parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.5,life:60+Math.random()*40,color:cols[i%cols.length]});} }
    for(let i=0;i<4;i++) boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.5*Math.random()));
    const stop=performance.now()+ms;
    (function loop(){ ctx.clearRect(0,0,innerWidth,innerHeight); for(const p of parts){p.vy+=0.045;p.x+=p.vx;p.y+=p.vy;p.life-=1;ctx.globalAlpha=Math.max(0,p.life/90);ctx.beginPath();ctx.arc(p.x,p.y,2.1,0,Math.PI*2);ctx.fillStyle=p.color;ctx.fill();} for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1); if(performance.now()<stop && parts.length) requestAnimationFrame(loop); else c.remove(); })();
  }

  // ---- Panel FAB ----
  function mountFAB(){
    if(document.getElementById('aegis-fab')) return;
    const fab=document.createElement('div'); fab.id='aegis-fab';
    fab.style.cssText='position:fixed;right:16px;bottom:16px;width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#d4af37,#f2d574);box-shadow:0 10px 30px rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647';
    fab.innerHTML='<div style="width:26px;height:26px;border-radius:6px;background:#0b1d13"></div>';
    fab.onclick = openPanel;
    document.body.appendChild(fab);
  }
  function openPanel(){
    if(document.getElementById('aegis-panel')) return;
    const cur=A.getTheme();
    const w=document.createElement('div'); w.id='aegis-panel';
    w.style.cssText='position:fixed;bottom:76px;right:16px;width:320px;background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:12px;padding:12px;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px/1.35 system-ui';
    const themeBtns = ['classic','remaster','pirate','dark'].map(k=>'<button class="set-theme" data-key="'+k+'" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer;'+(k===cur?'outline:2px solid #d4af37':'')+'">'+k+'</button>').join('');
    w.innerHTML = '<div style="display:flex;justify-content:space-between;align-items:center;gap:8px"><b>Aegis '+VER+'</b><button id="aegis-x" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:6px;padding:2px 8px;cursor:pointer">×</button></div>'+
      '<div style="margin-top:8px"><div style="margin:4px 0 6px">Motyw:</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:6px">'+themeBtns+'</div></div>';
    document.body.appendChild(w);
    w.querySelector('#aegis-x').onclick=()=>w.remove();
    w.querySelectorAll('.set-theme').forEach(b=>b.onclick=()=>A.applyTheme(b.dataset.key));
  }

  // ---- Welcome once per version ----
  function welcome(){
    const k='Aegis::seen::'+VER;
    if(localStorage.getItem(k)) return;
    localStorage.setItem(k, Date.now());
    const overlay=document.createElement('div'); overlay.style.cssText='position:fixed;inset:0;z-index:2147483647;display:flex;align-items:center;justify-content:center;background:radial-gradient(ellipse at center, rgba(0,0,0,.55), rgba(0,0,0,.85))';
    overlay.innerHTML='<div style="width:min(720px,92vw);color:#f3f3f3;background:linear-gradient(180deg,rgba(10,46,34,.96),rgba(10,46,34,.92));border:1px solid rgba(212,175,55,.35);border-radius:16px;padding:18px 20px;box-shadow:0 10px 30px rgba(0,0,0,.5)"><div style="display:flex;gap:14px;align-items:center;margin-bottom:8px"><div style="width:46px;height:46px;border-radius:10px;background:linear-gradient(135deg,#d4af37,#f2d574)"></div><div><h1 style="margin:0;font:800 20px/1.2 system-ui;color:#d4af37">Aegis '+VER+'</h1><p style="margin:4px 0 0;opacity:.9">Remaster UI aktywny. Miłej gry!</p></div></div><p>• Butelkowa zieleń + złoto • Delikatne cienie i połysk • Animowany dym u dołu</p><div style="display:flex;gap:10px;margin-top:14px"><button id="aegis-ok" style="background:linear-gradient(180deg,#d4af37,#f2d574);color:#2a2000;border:none;border-radius:12px;padding:10px 16px;font-weight:700;cursor:pointer;box-shadow:0 4px 10px rgba(0,0,0,.35)">Zaczynamy!</button></div></div>';
    document.body.appendChild(overlay);
    overlay.querySelector('#aegis-ok').onclick=()=>overlay.remove();
    setTimeout(()=>fireworks(),150);
  }

  // ---- Start ----
  function start(){
    injectTheme(A.getTheme());
    ensureSmoke();
    badge();
    mountFAB();
    welcome();
  }
  if(document.readyState==='loading'){ document.addEventListener('DOMContentLoaded', start); } else { start(); }
})();