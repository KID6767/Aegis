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
  const KEY_SEEN = 'Aegis::seen::' + VER;
  const RAW = 'https://raw.githubusercontent.com/KID6767/Aegis/main';
  const THEME_URL = RAW + '/assets/themes/classic/theme.css';

  function injectCSS(href){
    const id='aegis-theme';
    if(document.getElementById(id)) return;
    const l=document.createElement('link');
    l.id=id; l.rel='stylesheet'; l.href=href;
    document.head.appendChild(l);
  }

  function badge(){
    if(document.getElementById('aegis-badge')) return;
    const el = document.createElement('div');
    el.id = 'aegis-badge';
    el.innerHTML = '<img src=\"'+RAW+'/assets/branding/logo_aegis.png\" alt=\"\">'
                 + '<div class=\"txt\">Aegis '+VER+'</div>';
    document.body.appendChild(el);
  }

  // ── Fireworks (lekka implementacja)
  function fireworks(durationMs=3200){
    const c = document.createElement('canvas');
    c.style.cssText='position:fixed;inset:0;z-index:99999;pointer-events:none';
    const ctx = c.getContext('2d');
    document.body.appendChild(c);
    const DPR = Math.max(1, window.devicePixelRatio || 1);
    function resize(){ c.width = innerWidth * DPR; c.height = innerHeight * DPR; ctx.scale(DPR,DPR) }
    resize(); addEventListener('resize', resize);

    const dotsImg = new Image();
    dotsImg.src = RAW + '/assets/fx/firework_dot.png';

    const particles=[];
    function boom(x,y,color){
      const N = 50 + Math.floor(Math.random()*50);
      for(let i=0;i<N;i++){
        const angle = Math.random()*Math.PI*2;
        const speed = 2+Math.random()*4;
        particles.push({
          x,y, vx: Math.cos(angle)*speed, vy: Math.sin(angle)*speed - 1.5,
          life: 60+Math.random()*30, color
        });
      }
    }
    const colors = ['#ffd86b','#6ee7b7','#93c5fd','#fca5a5','#e9e9ea'];
    for(let i=0;i<4;i++){
      const x = innerWidth*(.2 + .6*Math.random());
      const y = innerHeight*(.2 + .5*Math.random());
      boom(x,y, colors[i%colors.length]);
    }

    let tick=0, stopAt = performance.now()+durationMs;
    function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      particles.forEach(p=>{
        p.vy += 0.045; p.x += p.vx; p.y += p.vy; p.life -= 1;
        ctx.globalAlpha = Math.max(0, p.life/90);
        ctx.drawImage(dotsImg, p.x-4, p.y-4, 8, 8);
      });
      for(let i=particles.length-1;i>=0;i--) if(particles[i].life<=0) particles.splice(i,1);
      tick++; if(performance.now()<stopAt && particles.length) requestAnimationFrame(loop);
      else { c.remove(); }
    }
    requestAnimationFrame(loop);
  }

  function welcome(){
    if(document.getElementById('aegis-welcome')) return;
    const wrap = document.createElement('div'); wrap.id='aegis-welcome';
    wrap.innerHTML = 
      <div id="aegis-card" class="aegis-panel">
        <div class="head">
          <img src="/assets/branding/logo_aegis.png" alt="">
          <div>
            <h1>Aegis </h1>
            <p>Remaster UI aktywny. Miłej gry! (fajerwerki tylko przy nowej wersji)</p>
          </div>
        </div>
        <p>• Nowy font, panel, tło, badge wersji<br>
           • Przyciski z połyskiem, miękkie cienie<br>
           • Lekki loader CSS bez migotania</p>
        <div id="aegis-actions">
          <button id="aegis-close" class="aegis-btn">Zaczynamy!</button>
        </div>
      </div>;
    document.body.appendChild(wrap);
    document.getElementById('aegis-close').onclick = ()=> wrap.remove();
  }

  // start
  injectCSS(THEME_URL);
  badge();

  const firstTime = !localStorage.getItem(KEY_SEEN);
  if(firstTime){
    localStorage.setItem(KEY_SEEN, Date.now().toString());
    welcome();
    setTimeout(()=>fireworks(), 150);
  }

})();