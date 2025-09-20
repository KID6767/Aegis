/* ==UserScript==
@name         Aegis – Grepolis Remaster
@namespace    https://github.com/KID6767/Aegis
@version      1.0.0
@description  Remaster UI: themes, animated banner, quick panel, smoke, fireworks (optional). Pure UI, no automation.
@author       KID6767 & ChatGPT
@match        https://*.grepolis.com/*
@match        https://*.grepolis.pl/*
@grant        none
@run-at       document-end
==/UserScript== */
(function () {
  'use strict';
  const VER = '1.0.0';
  const RAW = 'https://raw.githubusercontent.com/KID6767/Aegis/main/assets';
  const THEMES = {
    classic: `${RAW}/themes/classic.css`,
    remaster: `${RAW}/themes/remaster.css`,
    pirate: `${RAW}/themes/pirate.css`,
    dark: `${RAW}/themes/dark.css`
  };
  function setTheme(name){
    localStorage.setItem('AEGIS_THEME', name);
    const old = document.getElementById('aegis-theme-css'); if(old) old.remove();
    const href = THEMES[name] || THEMES.remaster;
    const l = document.createElement('link'); l.id='aegis-theme-css'; l.rel='stylesheet'; l.href=href; l.crossOrigin='anonymous';
    document.head.appendChild(l);
  }
  function cycleTheme(){
    const list=['classic','remaster','pirate','dark']; const cur=localStorage.getItem('AEGIS_THEME')||'remaster'; const i=list.indexOf(cur); const next=list[(i+1)%list.length]; setTheme(next);
  }
  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const el=document.createElement('div'); el.id='aegis-badge';
    el.textContent='Aegis '+VER;
    el.style.cssText='position:fixed;right:10px;top:10px;z-index:99998;background:linear-gradient(135deg,#0a2e22,#113c2d);border:1px solid rgba(212,175,55,.35);color:#d4af37;padding:6px 10px;border-radius:10px;font:600 12px/1.2 system-ui,Segoe UI,Arial;user-select:none;pointer-events:none;box-shadow:0 8px 24px rgba(0,0,0,.45)';
    document.body.appendChild(el);
  }
  function smoke(){
    if(document.getElementById('aegis-smoke')) return;
    const d=document.createElement('div'); d.id='aegis-smoke';
    d.style.cssText='position:fixed;left:0;right:0;bottom:-28px;height:130px;z-index:1;pointer-events:none;background:url('+RAW+'/fx/smoke.svg) center/cover no-repeat;opacity:.8';
    document.body.appendChild(d);
  }
  function fireworks(ms=2600){
    const c=document.createElement('canvas'); Object.assign(c.style,{position:'fixed',inset:'0',zIndex:99999,pointerEvents:'none'});
    const ctx=c.getContext('2d'); document.body.appendChild(c);
    const DPR=Math.max(1,window.devicePixelRatio||1);
    function resize(){ c.width=innerWidth*DPR; c.height=innerHeight*DPR; ctx.setTransform(DPR,0,0,DPR,0,0) }; resize(); addEventListener('resize',resize);
    const parts=[]; function boom(x,y){ const N=60+Math.floor(Math.random()*50), cols=['#ffd86b','#e6c55e','#f2e5a3','#fff9d2','#fbe6a4']; for(let i=0;i<N;i++){ const a=Math.random()*Math.PI*2,s=2+Math.random()*4; parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.4,life:60+Math.random()*40,color:cols[i%cols.length]});}}
    for(let i=0;i<4;i++) boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.5*Math.random()));
    const stopAt=performance.now()+ms;
    (function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      for(const p of parts){ p.vy+=0.045; p.x+=p.vx; p.y+=p.vy; p.life-=1; ctx.globalAlpha=Math.max(0,p.life/90); ctx.beginPath(); ctx.arc(p.x,p.y,2,0,Math.PI*2); ctx.fillStyle=p.color; ctx.fill(); }
      for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1);
      if(performance.now()<stopAt && parts.length) requestAnimationFrame(loop); else c.remove();
    })();
  }
  function welcome(){
    const k='Aegis::seen::'+VER; if(localStorage.getItem(k)) return; localStorage.setItem(k, Date.now());
    const w=document.createElement('div'); w.id='aegis-welcome';
    w.style.cssText='position:fixed;inset:0;z-index:99997;display:flex;align-items:center;justify-content:center;background:radial-gradient(ellipse at center, rgba(0,0,0,.55), rgba(0,0,0,.85))';
    w.innerHTML = '<div style="width:min(860px,94vw);color:#f3f3f3;background:linear-gradient(180deg,rgba(10,46,34,.96),rgba(10,46,34,.92));border:1px solid rgba(212,175,55,.35);border-radius:16px;padding:18px 20px;box-shadow:0 10px 30px rgba(0,0,0,.5)">'+
                  '<div style="display:flex;align-items:center;gap:16px"><img src="'+RAW+'/branding/ship_left.svg" width="120" height="50"/>'+
                  '<div style="flex:1"><img src="'+RAW+'/branding/banner.svg" style="width:100%;height:auto;border-radius:12px;box-shadow:0 6px 18px rgba(0,0,0,.45)"/></div>'+
                  '<img src="'+RAW+'/branding/ship_right.svg" width="120" height="50"/></div>'+
                  '<div style="margin-top:12px;display:flex;gap:10px;justify-content:flex-end"><button id="aegis-ok" style="background:linear-gradient(180deg,#d4af37,#f2d574);color:#2a2000;border:none;border-radius:12px;padding:10px 16px;font-weight:800;cursor:pointer;box-shadow:0 4px 10px rgba(0,0,0,.35)">Zaczynamy!</button></div>'+
                  '</div>';
    document.body.appendChild(w);
    document.getElementById('aegis-ok').onclick=()=>w.remove();
    setTimeout(()=>fireworks(), 180);
  }
  function panel(){
    if(document.getElementById('aegis-fab')) return;
    const fab=document.createElement('div');
    fab.id='aegis-fab';
    fab.title='Aegis — panel';
    fab.style.cssText='position:fixed;right:16px;bottom:16px;width:50px;height:50px;border-radius:14px;background:linear-gradient(135deg,#d4af37,#f2d574);display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647;box-shadow:0 10px 30px rgba(0,0,0,.55)';
    fab.innerHTML='<div style="width:30px;height:30px;border-radius:8px;background:#0b1d13;animation:p 3s infinite"></div><style>@keyframes p{50%{filter:brightness(1.18)}}</style>';
    document.body.appendChild(fab);
    fab.onclick = ()=>{
      if(document.getElementById('aegis-panel')) return;
      const wrap=document.createElement('div'); wrap.id='aegis-panel';
      wrap.style.cssText='position:fixed;bottom:76px;right:16px;width:340px;background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:12px;padding:12px;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px/1.35 system-ui,Arial';
      wrap.innerHTML=''+
        '<div style="display:flex;justify-content:space-between;align-items:center;gap:8px"><b>Aegis 1.0.0</b>'+
        '<button id="aegis-close" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:6px;padding:2px 8px;cursor:pointer">×</button></div>'+
        '<div style="margin-top:8px"><div style="margin:4px 0 6px">Motyw:</div>'+
        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:6px">'+
          ['classic','remaster','pirate','dark'].map(k=>'<button class="set-theme" data-key="'+k+'" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer">'+k+'</button>').join('')+
        '</div></div>'+
        '<div style="margin-top:10px;opacity:.85">Skróty: Alt+T (zmiana motywu), Alt+G (panel)</div>';
      document.body.appendChild(wrap);
      wrap.querySelector('#aegis-close').onclick=()=>wrap.remove();
      wrap.querySelectorAll('.set-theme').forEach(btn=>btn.addEventListener('click',()=>{ setTheme(btn.dataset.key); wrap.remove(); }));
    };
    window.addEventListener('keydown',(e)=>{ if(e.altKey && !e.shiftKey && !e.ctrlKey){ if(e.code==='KeyG'){ e.preventDefault(); fab.click(); } if(e.code==='KeyT'){ e.preventDefault(); cycleTheme(); } } });
  }
  function start(){
    const theme = localStorage.getItem('AEGIS_THEME') || 'remaster';
    setTheme(theme);
    badge();
    smoke();
    panel();
    welcome();
    console.log('%c[Aegis] 1.0.0 ready','color:#d4af37;font-weight:700');
  }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded', start); else start();
})();
