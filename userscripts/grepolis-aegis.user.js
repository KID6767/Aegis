// ==UserScript==
// @name         Aegis – Grepolis Remaster (1.0.0)
// @namespace    https://github.com/KID6767/Aegis
// @version      1.0.0
// @description  Motywy (Classic/Remaster/Pirate/Dark), panel, powitanie z fajerwerkami, AssetMap pod branding.
// @author       KID6767 & ChatGPT
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @run-at       document-end
// ==/UserScript==
(function(){
  'use strict';
  const get=(k,d)=>{try{return JSON.parse(localStorage.getItem(k))??d}catch{return d}};
  const set=(k,v)=>localStorage.setItem(k,JSON.stringify(v));
  const RAW='https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding';

  const THEMES={
    classic:`:root{--a:#1a1a1a;--fg:#f2f2f2;--g:#d4af37}body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--a)!important;color:var(--fg)!important}.game_header,.ui-dialog .ui-dialog-titlebar{background:#232a36!important;color:var(--g)!important}`,
    remaster:`:root{--bg:#0e1518;--fg:#f3f3f3;--g:#d4af37}body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--bg)!important;color:var(--fg)!important}.game_header,.ui-dialog .ui-dialog-titlebar{background:linear-gradient(180deg,#0a2e22,#113c2d)!important;color:var(--g)!important}`,
    pirate:`:root{--bg:#0b0b0b;--g:#d4af37;--fg:#eee}body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--bg)!important;color:var(--fg)!important}.game_header,.ui-dialog .ui-dialog-titlebar{background:#101010!important;color:var(--g)!important}`,
    dark:`:root{--bg:#111;--fg:#ddd}body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--bg)!important;color:var(--fg)!important}`
  };
  function applyTheme(name){
    const css=THEMES[name]||THEMES.remaster;
    let el=document.getElementById('aegis-theme-style'); if(!el){el=document.createElement('style');el.id='aegis-theme-style';document.head.appendChild(el)}
    el.textContent=css;
  }

  function fireworks(ms=2500){
    if(document.hidden) return;
    const c=document.createElement('canvas'); Object.assign(c.style,{position:'fixed',inset:'0',zIndex:99999,pointerEvents:'none'});
    const ctx=c.getContext('2d'); document.body.appendChild(c);
    const DPR=Math.max(1,devicePixelRatio||1); function resize(){c.width=innerWidth*DPR;c.height=innerHeight*DPR;ctx.setTransform(DPR,0,0,DPR,0,0)}; resize(); addEventListener('resize',resize);
    const P=[]; function boom(x,y){for(let i=0;i<90;i++){const a=Math.random()*6.283,s=2+Math.random()*4;P.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.2,l:70+Math.random()*30,c:['#ffd86b','#f2d574','#fff4c1'][i%3]})}};
    for(let i=0;i<4;i++) boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.5*Math.random()));
    const stop=performance.now()+ms;
    (function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      for(const p of P){p.vy+=0.045;p.x+=p.vx;p.y+=p.vy;p.l--;ctx.globalAlpha=Math.max(0,p.l/90);ctx.beginPath();ctx.arc(p.x,p.y,2,0,6.283);ctx.fillStyle=p.c;ctx.fill()}
      for(let i=P.length-1;i>=0;i--) if(P[i].l<=0) P.splice(i,1);
      if(performance.now()<stop && P.length) requestAnimationFrame(loop); else c.remove();
    })();
  }

  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const b=document.createElement('div'); b.id='aegis-badge';
    b.textContent='Aegis 1.0.0'; b.style.cssText='position:fixed;right:10px;top:10px;z-index:99998;background:linear-gradient(135deg,#0a2e22,#113c2d);border:1px solid rgba(212,175,55,.35);color:#d4af37;padding:6px 10px;border-radius:10px;font:600 12px system-ui;user-select:none;pointer-events:none';
    document.body.appendChild(b);
  }

  function fab(){
    if(document.getElementById('aegis-fab')) return;
    const f=document.createElement('div'); f.id='aegis-fab'; f.title='Aegis – ustawienia';
    f.style.cssText='position:fixed;right:16px;bottom:16px;width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#d4af37,#f2d574);box-shadow:0 10px 30px rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647';
    f.innerHTML='<div style="width:28px;height:28px;border-radius:6px;background:#0b1d13"></div>';
    f.onclick=panel; document.body.appendChild(f);
    window.addEventListener('keydown',e=>{ if(e.altKey && e.code==='KeyT'){e.preventDefault(); const list=['classic','remaster','pirate','dark']; const cur=get('aegis_theme','remaster'); const i=list.indexOf(cur); const n=list[(i+1)%list.length]; set('aegis_theme',n); applyTheme(n);} });
  }

  function panel(){
    if(document.getElementById('aegis-panel')) return;
    const cur=get('aegis_theme','remaster');
    const w=document.createElement('div'); w.id='aegis-panel';
    w.style.cssText='position:fixed;bottom:76px;right:16px;width:320px;background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:12px;padding:12px;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px system-ui';
    const btn = (k)=>`<button class="set-theme" data-key="${k}" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer;${k===cur?'outline:2px solid #d4af37':''}">${k}</button>`;
    w.innerHTML=`<div style="display:flex;justify-content:space-between;align-items:center"><b>Aegis 1.0.0</b><button id="aegis-close" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:6px;padding:2px 8px;cursor:pointer">×</button></div>
    <div style="margin-top:8px">Motyw:</div>
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;margin-top:4px">${['classic','remaster','pirate','dark'].map(k=>btn(k)).join('')}</div>
    <div style="margin-top:10px">Grafiki (AssetMap) pobierane z: <code>${RAW}</code></div>`;
    document.body.appendChild(w);
    w.querySelector('#aegis-close').onclick=()=>w.remove();
    w.querySelectorAll('.set-theme').forEach(b=>b.onclick=()=>{ set('aegis_theme',b.dataset.key); applyTheme(b.dataset.key) });
  }

  function assetOverride(){
    const map = {
      "ships/bireme.png": RAW + "/ship_green.svg",
      "ui/settings.png":  RAW + "/logo_aegis.png",
      "branding/banner":  RAW + "/banner.svg"
    };
    const fix=(src)=>{ for(const k in map){ if(src.includes(k)) return map[k]; } return src; };
    const orig=document.createElement;
    document.createElement=function(t){ const el=orig.call(document,t); if(String(t).toLowerCase()==='img'){ const _s=el.setAttribute; el.setAttribute=function(n,v){ if(n==='src' && typeof v==='string'){ v=fix(v) } return _s.call(this,n,v) } } return el; };
    const patch=(root)=>root.querySelectorAll?.('img[src]').forEach(i=>{i.src=fix(i.src)});
    new MutationObserver(m=>m.forEach(x=>x.addedNodes?.forEach(n=>n.nodeType===1&&patch(n)))).observe(document.documentElement,{childList:true,subtree:true});
    patch(document);
  }

  function welcome(){
    const k='Aegis::seen::1.0.0'; if(get(k,false)) return; set(k,true);
    const wrap=document.createElement('div'); wrap.style.cssText='position:fixed;inset:0;z-index:99997;display:flex;align-items:center;justify-content:center;background:radial-gradient(ellipse at center,rgba(0,0,0,.55),rgba(0,0,0,.85))';
    wrap.innerHTML=`<div style="width:min(720px,92vw);color:#f3f3f3;background:linear-gradient(180deg,rgba(10,46,34,.96),rgba(10,46,34,.92));border:1px solid rgba(212,175,55,.35);border-radius:16px;padding:18px 20px;box-shadow:0 10px 30px rgba(0,0,0,.5)">
      <div style="display:flex;gap:14px;align-items:center;margin-bottom:8px">
        <img src="${RAW}/logo_aegis.png" width="46" height="46" style="border-radius:8px;background:#0b1d13;box-shadow:inset 0 2px 6px rgba(0,0,0,.25)"/>
        <div><h1 style="margin:0;font:800 20px system-ui;color:#d4af37">Aegis 1.0.0</h1><p style="margin:4px 0 0;opacity:.9">Remaster UI aktywny. Miłej gry!</p></div>
      </div>
      <p>• Butelkowa zieleń + złoto • Delikatne cienie i połysk • Panel w prawym dolnym rogu</p>
      <div style="display:flex;gap:10px;margin-top:14px"><button id="aeg-ok" style="background:linear-gradient(180deg,#d4af37,#f2d574);color:#2a2000;border:none;border-radius:12px;padding:10px 16px;font-weight:700;cursor:pointer">Zaczynamy!</button></div>
    </div>`;
    document.body.appendChild(wrap); document.getElementById('aeg-ok').onclick=()=>wrap.remove(); setTimeout(()=>fireworks(),150);
  }

  function start(){ applyTheme(get('aegis_theme','remaster')); badge(); fab(); assetOverride(); welcome(); }
  if(document.readyState==='loading') document.addEventListener('DOMContentLoaded', start); else start();
})();
