==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      0.9.1-dev
// @description  Widoczne od razu: powitanie + fajerwerki, tryb ciemny, odświeżone UI, przełącznik motywów.
// @match        https://*.grepolis.com/*
// @match        https://*.grepolis.pl/*
// @run-at       document-end
// @grant        none
==/UserScript==

(function(){
  'use strict';
  const AEGIS_NS = 'aegis';
  const VER = '0.9.1-dev';
  const qs  = (s, r=document)=>r.querySelector(s);
  const qsa = (s, r=document)=>Array.from(r.querySelectorAll(s));
  const onReady = (fn)=> (document.readyState === 'loading') ? document.addEventListener('DOMContentLoaded', fn) : fn();
  const save = (k,v)=>localStorage.setItem(\\:\\, v);
  const load = (k,d=null)=>localStorage.getItem(\\:\\) ?? d;

  const baseCSS = 
  :root{
    --aegis-accent:#00d084; --aegis-gold:#d4af37; --aegis-ink:#0e0f13; --aegis-bg:#111318;
  }
  .aegis-ribbon{
    position:fixed; left:-40px; top:16px; transform:rotate(-45deg);
    background:linear-gradient(90deg,var(--aegis-gold),#ffdd76); color:#1b1400; font-weight:700;
    font-family:Segoe UI,Arial; letter-spacing:.5px; padding:6px 48px; z-index:999999;
    box-shadow:0 8px 18px rgba(0,0,0,.35);
  }
  .aegis-panel{
    position:fixed; right:18px; bottom:18px; z-index:999999;
    background:#1d1f26; color:#eee; border:1px solid #2b2f3a; border-radius:12px;
    box-shadow:0 10px 20px rgba(0,0,0,.35); padding:10px 12px; font-family:Segoe UI,Arial;
  }
  .aegis-panel h3{margin:0 0 8px 0; font-size:13px; color:#cfd3dc; font-weight:600;}
  .aegis-panel select, .aegis-panel button{
    all:unset; background:#2a2f3a; color:#e8ecf4; padding:6px 10px; border-radius:8px; cursor:pointer;
    margin-right:6px; font-size:12px;
  }
  .aegis-panel button:hover, .aegis-panel select:hover{filter:brightness(1.1)}
  .aegis-chip{display:inline-block; padding:2px 8px; border-radius:999px; background:#223; color:#aef; font-size:11px; margin-left:6px;}
  body.aegis-dark{ background:#0c0e12 !important; }
  .aegis-water::after{
    content:""; position:fixed; left:0; top:0; right:0; bottom:0; pointer-events:none;
    background: radial-gradient(60% 50% at 70% 85%, rgba(255,255,255,.06), transparent 60%),
                radial-gradient(45% 35% at 20% 80%, rgba(0,224,224,.08), transparent 55%);
    mix-blend-mode: screen; animation:aegis-breathe 5s ease-in-out infinite;
  }
  @keyframes aegis-breathe{ 0%,100%{opacity:.35} 50%{opacity:.65} }
  .aegis-outline *{ outline-color: rgba(0,208,132,.25); }
  ;
  const styleTag = document.createElement('style'); styleTag.id='aegis-styles'; styleTag.textContent=baseCSS;
  document.documentElement.appendChild(styleTag);

  function fireworksOnce(){
    const canvas = document.createElement('canvas');
    canvas.id='aegis-confetti'; canvas.style.cssText='position:fixed;inset:0;z-index:999998;pointer-events:none;';
    document.body.appendChild(canvas);
    const ctx = canvas.getContext('2d');
    const resize=()=>{canvas.width=innerWidth; canvas.height=innerHeight}; resize(); addEventListener('resize',resize);
    const parts = Array.from({length:180},()=>({
      x: Math.random()*canvas.width, y: -20 - Math.random()*100, r: 4+Math.random()*6,
      vx: -1 + Math.random()*2, vy: 1 + Math.random()*2, c: \hsl(\ 90% 60%)\, a:1
    }));
    let t=0, raf;
    (function tick(){
      ctx.clearRect(0,0,canvas.width,canvas.height);
      parts.forEach(p=>{ p.x+=p.vx; p.y+=p.vy; p.vy+=0.03; p.a-=0.008;
        ctx.globalAlpha=Math.max(p.a,0); ctx.fillStyle=p.c;
        ctx.beginPath(); ctx.arc(p.x,p.y,p.r,0,Math.PI*2); ctx.fill();
      });
      if((t++)<400){ raf=requestAnimationFrame(tick) } else { cancelAnimationFrame(raf); canvas.remove(); }
    })();
  }

  function welcome(){
    if(load('welcomed')==='yes') return;
    save('welcomed','yes');
    const wrap = document.createElement('div');
    wrap.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,.55);display:grid;place-items:center;z-index:999999';
    wrap.innerHTML = \
      <div style="background:#151822;border:1px solid #2b2f3a;border-radius:16px;padding:22px 24px;max-width:520px;color:#dde3ee;font-family:Segoe UI,Arial;box-shadow:0 20px 40px rgba(0,0,0,.45)">
        <div style="font-size:18px;font-weight:700;margin-bottom:6px">Aegis — Remaster aktywny</div>
        <div style="opacity:.85;line-height:1.55;margin-bottom:14px">
          Witaj! Włączyliśmy <b>tryb Aegis</b> dla Grepolis. Masz panel sterowania (prawy-dół), tryb ciemny,
          lekką mgiełkę na wodzie, nową wstążkę wersji i przełącznik motywów.
        </div>
        <div style="display:flex;gap:8px;justify-content:flex-end">
          <button id="aegis-ok" style="all:unset;background:#2a2f3a;color:#e8ecf4;padding:8px 12px;border-radius:10px;cursor:pointer">OK, jedziemy!</button>
        </div>
      </div>\;
    document.body.appendChild(wrap);
    wrap.querySelector('#aegis-ok').addEventListener('click', ()=> wrap.remove());
    fireworksOnce();
  }

  function setTheme(theme){
    save('theme', theme);
    document.body.classList.toggle('aegis-dark', theme==='dark' || theme==='pirate');
    document.body.classList.toggle('aegis-water', theme==='classic' || theme==='emerald' || theme==='pirate');
  }

  function mountPanel(){
    const panel = document.createElement('div');
    panel.className='aegis-panel';
    panel.innerHTML=\
      <h3>Aegis <span class="aegis-chip">v\</span></h3>
      <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap">
        <select id="aegis-theme">
          <option value="classic">Classic</option>
          <option value="emerald">Emerald</option>
          <option value="pirate">Pirate</option>
          <option value="dark">Dark</option>
        </select>
        <button id="aegis-outline">Outline</button>
        <button id="aegis-fire">Fajerwerki</button>
      </div>\;
    document.body.appendChild(panel);
    const sel = panel.querySelector('#aegis-theme');
    sel.value = load('theme','classic');
    sel.addEventListener('change', ()=> setTheme(sel.value));
    panel.querySelector('#aegis-outline').addEventListener('click', ()=> document.body.classList.toggle('aegis-outline'));
    panel.querySelector('#aegis-fire').addEventListener('click', fireworksOnce);
  }

  function mountRibbon(){
    const el = document.createElement('div');
    el.className='aegis-ribbon'; el.textContent='AEGIS '+VER; document.body.appendChild(el);
  }

  onReady(()=>{ mountRibbon(); mountPanel(); setTheme(load('theme','classic')); welcome(); });
})();