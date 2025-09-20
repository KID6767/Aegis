/* ==UserScript==
@name         Aegis – Grepolis Remaster
@namespace    https://github.com/KID6767/Aegis
@version      1.0.2
@description  Remaster UI (motywy, panel, badge, dym, fajerwerki). UI-only, bez automatyzacji.
@match        https://*.grepolis.com/*
@match        https://*.grepolis.pl/*
@updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
@downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js
@run-at       document-end
@grant        GM_getValue
@grant        GM_setValue
==/UserScript== */
(function(){
  'use strict';
  const VER = '1.0.2';
  const get=(k,d)=>typeof GM_getValue==='function'?GM_getValue(k,d):(JSON.parse(localStorage.getItem(k)||'null')??d);
  const set=(k,v)=>typeof GM_setValue==='function'?GM_setValue(k,v):localStorage.setItem(k,JSON.stringify(v));

  const THEMES={
    classic:`:root{--gold:#d4af37;--bg:#1a1a1a;--fg:#f2f2f2}
body,.gpwindow_content,.game_inner_box,.ui_box{background:#1a1a1a!important;color:#f2f2f2!important}
.game_header,.ui-dialog .ui-dialog-titlebar{background:#232a36!important;color:#d4af37!important;border-color:#a8832b!important}
.button,.btn,.ui-button{background:#2a2a2a!important;color:#f2f2f2!important;border:1px solid #555!important;box-shadow:0 4px 14px rgba(0,0,0,.35)}
a{color:#e3c26b!important}
`,
    remaster:`:root{--green:#0a2e22;--green2:#113c2d;--gold:#d4af37;--fg:#f3f3f3;--bg:#0e1518}
@keyframes aegis-glow{0%,100%{box-shadow:0 0 0 rgba(212,175,55,0)}50%{box-shadow:0 0 12px rgba(212,175,55,.45)}}
body,.gpwindow_content,.game_inner_box,.ui_box{background:var(--bg)!important;color:var(--fg)!important}
.game_header,.ui-dialog .ui-dialog-titlebar{background:linear-gradient(180deg,var(--green),var(--green2))!important;color:var(--gold)!important;border-color:rgba(212,175,55,.35)!important}
.button,.btn,.ui-button{background:#122018!important;color:var(--gold)!important;border:1px solid rgba(212,175,55,.35)!important;box-shadow:0 10px 30px rgba(0,0,0,.55);text-shadow:0 1px 0 rgba(0,0,0,.65)}
.gp_table th,.gp_table td{border-color:rgba(212,175,55,.35)!important}
`,
    pirate:`:root{--gold:#d4af37;--bg:#0b0b0b;--ink:#101010;--fg:#eee}
body,.gpwindow_content,.game_inner_box,.ui_box{background:#0b0b0b!important;color:#eee!important}
.game_header,.ui-dialog .ui-dialog-titlebar{background:#101010!important;color:#d4af37!important;border-color:#d4af37!important}
.button,.btn,.ui-button{background:#151515!important;color:#d4af37!important;border:1px solid #d4af37!important;box-shadow:0 8px 26px rgba(0,0,0,.6)}
a{color:#e5c66a!important}
`,
    dark:`:root{--bg:#111;--fg:#ddd;--ac:#4da6ff}
body,.gpwindow_content,.game_inner_box,.ui_box,.forum_content{background:#111!important;color:#ddd!important}
a,.gpwindow_content a,.forum_content a{color:#4da6ff!important}
.button,.btn,.ui-button{background:#333!important;color:#eee!important;border:1px solid #555!important}
`
  };
  function injectTheme(name){
    const css = THEMES[name]||THEMES.remaster;
    let el=document.getElementById('aegis-theme-style');
    if(!el){ el=document.createElement('style'); el.id='aegis-theme-style'; document.head.appendChild(el); }
    el.textContent=css;
  }

  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const el = document.createElement('div'); el.id='aegis-badge';
    el.textContent='Aegis '+VER;
    el.style.cssText='position:fixed;right:10px;top:10px;z-index:99998;background:linear-gradient(135deg,#0a2e22,#113c2d);border:1px solid rgba(212,175,55,.35);color:#d4af37;padding:6px 10px;border-radius:10px;font:600 12px/1.2 system-ui,Segoe UI,Arial;animation:aegis-glow 3.2s ease-in-out infinite;user-select:none;pointer-events:none;';
    const glow=document.createElement('style'); glow.textContent='@keyframes aegis-glow{0%,100%{box-shadow:0 0 0 rgba(212,175,55,0)}50%{box-shadow:0 0 12px rgba(212,175,55,.45)}}';
    document.head.appendChild(glow); document.body.appendChild(el);
  }

  function smoke(){
    if(document.getElementById('aegis-smoke')) return;
    const s=document.createElement('div'); s.id='aegis-smoke';
    s.style.cssText='position:fixed;left:0;right:0;bottom:-30px;height:140px;z-index:1;pointer-events:none;opacity:.75;background:radial-gradient(120px 60px at 10% 80%, rgba(255,255,255,.05), transparent 60%),radial-gradient(180px 70px at 40% 90%, rgba(255,255,255,.07), transparent 60%),radial-gradient(140px 60px at 70% 85%, rgba(255,255,255,.06), transparent 60%),radial-gradient(200px 80px at 90% 95%, rgba(255,255,255,.05), transparent 60%);animation:aegis-smoke 9s ease-in-out infinite;';
    const k=document.createElement('style'); k.textContent='@keyframes aegis-smoke{0%{transform:translate3d(0,0,0) scale(1);opacity:.25}50%{transform:translate3d(30px,-10px,0) scale(1.05);opacity:.35}100%{transform:translate3d(0,-20px,0) scale(1.1);opacity:.20}}';
    document.head.appendChild(k); document.body.appendChild(s);
  }

  function fireworks(ms=2600){
    const c=document.createElement('canvas'); Object.assign(c.style,{position:'fixed',inset:'0',zIndex:99999,pointerEvents:'none'});
    const ctx=c.getContext('2d'); document.body.appendChild(c);
    const DPR=Math.max(1,window.devicePixelRatio||1);
    function resize(){c.width=innerWidth*DPR; c.height=innerHeight*DPR; ctx.setTransform(DPR,0,0,DPR,0,0);} resize(); addEventListener('resize',resize);
    const parts=[]; function boom(x,y){const N=60+Math.floor(Math.random()*60); const cols=['#ffd86b','#e6c55e','#f2e5a3','#fff9d2','#fbe6a4']; for(let i=0;i<N;i++){const a=Math.random()*Math.PI*2,s=2+Math.random()*4; parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.5,life:60+Math.random()*40,color:cols[i%cols.length]});}}
    for(let i=0;i<4;i++) boom(innerWidth*(.2+.6*Math.random()),innerHeight*(.25+.5*Math.random()));
    const stopAt=performance.now()+ms; (function loop(){ctx.clearRect(0,0,innerWidth,innerHeight); for(const p of parts){p.vy+=0.045;p.x+=p.vx;p.y+=p.vy;p.life-=1;ctx.globalAlpha=Math.max(0,p.life/90);ctx.beginPath();ctx.arc(p.x,p.y,2.1,0,Math.PI*2);ctx.fillStyle=p.color;ctx.fill();} for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1); if(performance.now()<stopAt && parts.length) requestAnimationFrame(loop); else c.remove();})();
  }

  function panel(){
    if(document.getElementById('aegis-fab')) return;
    const fab=document.createElement('div'); fab.id='aegis-fab';
    fab.style.cssText='position:fixed;right:16px;bottom:16px;width:48px;height:48px;border-radius:12px;background:linear-gradient(135deg,#d4af37,#f2d574);box-shadow:0 10px 30px rgba(0,0,0,.55);display:flex;align-items:center;justify-content:center;cursor:pointer;z-index:2147483647;';
    fab.innerHTML='<div style="width:28px;height:28px;border-radius:6px;background:#0b1d13;animation:aegis-pulse 3s infinite"></div><style>@keyframes aegis-pulse{0%,100%{filter:none}50%{filter:brightness(1.15)}}</style>';
    fab.onclick = openPanel; document.body.appendChild(fab);
    window.addEventListener('keydown',e=>{ if(e.altKey && !e.ctrlKey && !e.shiftKey && e.code==='KeyT'){ e.preventDefault(); cycleTheme(); }});
  }

  function openPanel(){
    if(document.getElementById('aegis-panel')) return;
    const cur=get('aegis_theme','remaster');
    const wrap=document.createElement('div'); wrap.id='aegis-panel';
    wrap.style.cssText='position:fixed;bottom:76px;right:16px;width:330px;background:#0f0f0f;color:#d4af37;border:1px solid #d4af37;border-radius:12px;padding:12px;z-index:2147483647;box-shadow:0 16px 40px rgba(0,0,0,.55);font:13px/1.35 system-ui,Arial';
    const btn=(k)=>'<button class="aeg-theme" data-k="'+k+'" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:8px;padding:6px;cursor:pointer;'+(k===cur?'outline:2px solid #d4af37':'')+'">'+k+'</button>';
    wrap.innerHTML='<div style="display:flex;justify-content:space-between;align-items:center;gap:8px;"><b>Aegis '+VER+'</b><button id="aegis-close" style="background:#111;color:#d4af37;border:1px solid #d4af37;border-radius:6px;padding:2px 8px;cursor:pointer;">×</button></div>'
      + '<div style="margin-top:8px"><div style="margin:4px 0 6px;">Motyw:</div><div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;">'
      + ['classic','remaster','pirate','dark'].map(btn).join('') + '</div></div>';
    document.body.appendChild(wrap);
    wrap.querySelectorAll('.aeg-theme').forEach(btn=>btn.addEventListener('click',()=>{ set('aegis_theme', btn.dataset.k); injectTheme(btn.dataset.k); }));
    wrap.querySelector('#aegis-close').onclick=()=>wrap.remove();
  }

  function cycleTheme(){
    const keys=['classic','remaster','pirate','dark'];
    const cur=get('aegis_theme','remaster'); const i=keys.indexOf(cur);
    const nx=keys[(i+1)%keys.length]; set('aegis_theme',nx); injectTheme(nx);
  }

  function welcomeOnce(){
    const k='Aegis::seen::'+VER; if(get(k,null)) return; set(k,Date.now()); setTimeout(()=>fireworks(),150);
  }

  injectTheme(get('aegis_theme','remaster'));
  badge(); smoke(); panel(); welcomeOnce();
})();