/* ==UserScript==
@name         Aegis – Grepolis Remaster
@namespace    https://github.com/KID6767/Aegis
@version      0.9.0
@description  Remaster UI + motyw (butelkowa zieleń + złoto) + animowany dym + ekran powitalny + fajerwerki przy nowej wersji
@author       KID6767
@match        https://*.grepolis.com/*
@match        https://*.grepolis.pl/*
@updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
@downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
@run-at       document-end
@grant        none
==/UserScript== */

(function(){
  "use strict";
  const VER = "0.9.0";
  const KEY = "Aegis::seen::" + VER;
  const RAW = "https://raw.githubusercontent.com/KID6767/Aegis/main";

  function css(href){
    const id="aegis-theme";
    if(document.getElementById(id)) return;
    const l=document.createElement("link");
    l.id=id; l.rel="stylesheet"; l.href=RAW + "/assets/themes/aegis.css";
    document.head.appendChild(l);
    const smoke=document.createElement("div");
    smoke.id="aegis-smoke";
    document.body.appendChild(smoke);
  }

  function badge(){
    if(document.getElementById("aegis-badge")) return;
    const el=document.createElement("div");
    el.id="aegis-badge";
    el.innerHTML = '<img src="'+RAW+'/assets/branding/logo.svg" alt="logo"/>' +
                   '<div class="txt">Aegis '+VER+'</div>';
    document.body.appendChild(el);
  }

  // very light fireworks using single 8x8 particle
  function fireworks(ms=2800){
    const c=document.createElement("canvas"); c.className="aegis-fireworks";
    const ctx=c.getContext("2d"); document.body.appendChild(c);
    const DPR=Math.max(1,window.devicePixelRatio||1);
    function fit(){ c.width=innerWidth*DPR; c.height=innerHeight*DPR; ctx.setTransform(DPR,0,0,DPR,0,0) }
    fit(); addEventListener("resize",fit);
    const dot=new Image(); dot.src=RAW+"/assets/fx/dot.png";

    const parts=[];
    function boom(x,y){
      const N=80+Math.floor(Math.random()*60);
      for(let i=0;i<N;i++){
        const a=Math.random()*Math.PI*2, s=1.8+Math.random()*3.2;
        parts.push({x,y,vx:Math.cos(a)*s,vy:Math.sin(a)*s-1.2,life:70+Math.random()*30});
      }
    }
    for(let i=0;i<4;i++) boom(innerWidth*(.2+.6*Math.random()), innerHeight*(.25+.5*Math.random()));
    const stop=performance.now()+ms;
    (function loop(){
      ctx.clearRect(0,0,innerWidth,innerHeight);
      parts.forEach(p=>{ p.vy+=.045; p.x+=p.vx; p.y+=p.vy; p.life--; ctx.globalAlpha=Math.max(0,p.life/90); ctx.drawImage(dot,p.x-4,p.y-4,8,8); });
      for(let i=parts.length-1;i>=0;i--) if(parts[i].life<=0) parts.splice(i,1);
      if(performance.now()<stop && parts.length) requestAnimationFrame(loop); else c.remove();
    })();
  }

  function welcome(){
    if(document.getElementById("aegis-welcome")) return;
    const wrap=document.createElement("div"); wrap.id="aegis-welcome";
    wrap.innerHTML = [
      '<div class="aegis-panel">',
      ' <div class="head">',
      '   <img src="'+RAW+'/assets/branding/logo.svg" alt="">',
      '   <div><h1>Aegis '+VER+'</h1>',
      '   <p>Remaster UI aktywny – butelkowa zieleń + złoto, animowany dym na dole, lekki start bez migotania.</p>',
      '   </div></div>',
      ' <p>• Ekran powitalny + fajerwerki tylko przy nowej wersji<br>',
      '    • Panel, badge wersji, porządki w zasobach<br>',
      '    • Gotowe pod #GrepoFusion</p>',
      ' <div><button id="aegis-close" class="aegis-btn">Zaczynamy!</button></div>',
      '</div>'
    ].join("");
    document.body.appendChild(wrap);
    document.getElementById("aegis-close").onclick = ()=> wrap.remove();
  }

  css(); badge();
  const first = !localStorage.getItem(KEY);
  if(first){ localStorage.setItem(KEY, Date.now()+""); welcome(); setTimeout(()=>fireworks(),140); }
})();
