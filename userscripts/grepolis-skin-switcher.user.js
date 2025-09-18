// ==UserScript==
// @name         Aegis – Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      0.9.0
// @description  Remaster UI + Welcome fireworks + theme loader
// @author       KID6767 + Aegis
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @run-at       document-end
// @grant        none
// ==/UserScript==

(function(){
  'use strict';
  const VER = '0.9.0';
  const RAW = 'https://raw.githubusercontent.com/KID6767/Aegis/main';
  const THEME_DEFAULT = 'https://raw.githubusercontent.com/KID6767/Aegis/main/assets/themes/classic/theme.css';
  const KEY_SEEN = 'Aegis::seen::' + VER;
  const KEY_THEME = 'Aegis::theme';

  function injectCSS(href){
    const id='aegis-theme';
    const old=document.getElementById(id);
    if(old && old.href===href) return;
    if(old) old.remove();
    const l=document.createElement('link');
    l.id=id; l.rel='stylesheet'; l.href=href; l.type='text/css';
    document.head.appendChild(l);
  }

  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const el = document.createElement('div');
    el.id = 'aegis-badge';
    el.innerHTML = '<img src="'+RAW+'/assets/branding/logo_aegis.png" alt="Aegis">'
                 + '<div class="txt">Aegis '+VER+'</div>';
    document.body.appendChild(el);
  }

  // bardzo lekki pokaz — bez obrazków zewnętrznych (rysunek kółek)
  function fireworks(durationMs=2800){
    const c = document.createElement('canvas');
    c.style.cssText='position:fixed;inset:0;z-index:99999;pointer-events:none';
    document.body.appendChild(c);
    const ctx = c.getContext('2d');
    const DPR = Math.max(1, window.devicePixelRatio || 1);
    function resize(){
      c.width = innerWidth * DPR; c.height = innerHeight * DPR;
      ctx.setTransform(DPR,0,0,DPR,0,0);
    }
    resize(); addEventListener('resize', resize);

    const parts=[];
    function boom(x,y,color){
      const N = 60 + (Math.random()*60|0);
      for(let i=0;i<N;i++){
        const a = Math.random()*Math.PI*2, s=2+Math.random()*3.8;
        parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.2,life:70+Math.random()*30,color});
      }
    }
    const palette=['#fcd34d','#34d399','#93c5fd','#fca5a5','#e5e7eb'];
    for(let i=0;i<4;i++){
      boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.45*Math.random()), palette[i%palette.length]);
    }

    const end = performance.now()+durationMs;
    (function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      parts.forEach(p=>{
        p.vy += 0.045; p.x += p.vx; p.y += p.vy; p.life -= 1;
        ctx.globalAlpha = Math.max(0,p.life/100);
        ctx.beginPath(); ctx.arc(p.x,p.y,1.6,0,Math.PI*2); ctx.fillStyle=p.color; ctx.fill();
      });
      for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1);
      if(performance.now()<end && parts.length) requestAnimationFrame(loop);
      else c.remove();
    })();
  }

  function welcome(){
    if(document.getElementById('aegis-welcome')) return;
    const wrap = document.createElement('div'); wrap.id='aegis-welcome';
    wrap.innerHTML =
      '<div id="aegis-card" class="aegis-panel">'+
        '<div class="head">'+
          '<img src="'+RAW+'/assets/branding/logo_aegis.png" alt="">'+
          '<div><h1>Aegis '+VER+'</h1>'+
          '<p>Remaster UI aktywny. Fajerwerki uruchamiane przy pierwszym starcie tej wersji.</p></div>'+
        '</div>'+
        '<p>• Nowy font, panel, tło, badge wersji<br>• Przyciski z połyskiem, miękkie cienie<br>• Lekki loader CSS</p>'+
        '<div id="aegis-actions">'+
          '<button id="aegis-close" class="aegis-btn">Zaczynamy!</button>'+
        '</div>'+
      '</div>';
    document.body.appendChild(wrap);
    document.getElementById('aegis-close').onclick = ()=> wrap.remove();
  }

  // prosta selekcja motywu via localStorage (classic/pirate-epic/emerald)
  function currentThemeUrl(){
    const t = localStorage.getItem(KEY_THEME) || 'classic';
    return RAW + '/assets/themes/'+t+'/theme.css';
  }

  // inicjalizacja
  injectCSS(currentThemeUrl());
  badge();

  const firstTime = !localStorage.getItem(KEY_SEEN);
  if(firstTime){
    localStorage.setItem(KEY_SEEN, Date.now().toString());
    welcome();
    setTimeout(()=>fireworks(), 120);
  }

  // mini panel przełączania motywu (Ctrl+Alt+T)
  addEventListener('keydown', (e)=>{
    if(e.ctrlKey && e.altKey && e.key.toLowerCase() === 't'){
      const order=['classic','pirate-epic','emerald'];
      const now = localStorage.getItem(KEY_THEME) || 'classic';
      const idx = (order.indexOf(now)+1) % order.length;
      const next = order[idx];
      localStorage.setItem(KEY_THEME, next); injectCSS(RAW+'/assets/themes/'+next+'/theme.css'); // fix quote typo? (we will correct below)
    }
  });
})();