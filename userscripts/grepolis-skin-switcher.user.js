// ==UserScript==
// @name         Aegis – Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      0.8.1-dev
// @description  Dynamiczne skiny Grepolis (Classic, Pirate, Emerald, Dark) – real-time podmiana grafik + CSS + panel
// @author       KID6767
// @match        https://*.grepolis.com/*
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @grant        none
// ==/UserScript==

(async () => {
  'use strict';
  const REPO = 'https://raw.githubusercontent.com/KID6767/Aegis/main';
  const MAP  = REPO + '/config/mapping.json?v=0.8.1-dev';
  const KEY  = 'aegis-theme';
  const DEF  = localStorage.getItem(KEY) || 'pirate';

  function css(href){
    const l=document.createElement('link'); l.rel='stylesheet'; l.href=href; document.head.appendChild(l);
  }
  function style(t){
    const s=document.createElement('style'); s.textContent=t; document.head.appendChild(s);
  }
  function el(n,attrs={},kids=[]){const e=document.createElement(n);Object.entries(attrs).forEach(([k,v])=>e[k]=v);kids.forEach(k=>e.appendChild(k));return e;}

  let mapping;
  try{ mapping = await fetch(MAP).then(r=>r.json()); }catch(e){ console.error('[Aegis] mapping.json error',e); return; }

  function applyTheme(name){
    const def = mapping.themes[name]; if(!def) return;
    // CSS
    css(REPO + '/' + def.css + '?v=0.8.1-dev');

    // globalny font + reset focusów
    style(@import url('https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700&display=swap');
      *{outline:none}
      .aegis-badge{position:fixed;left:10px;bottom:10px;padding:6px 10px;border-radius:8px;background:rgba(0,0,0,.6);color:#fff;font:12px "Cinzel Decorative",serif;z-index:99999}
      .aegis-modal{position:fixed;inset:0;background:rgba(0,0,0,.7);display:flex;align-items:center;justify-content:center;z-index:99998}
      .aegis-card{min-width:420px;max-width:520px;background:#101418;border:1px solid #2a3b4a;border-radius:14px;box-shadow:0 0 30px #000;padding:18px;color:#e8f0ff}
      .aegis-title{font:700 22px "Cinzel Decorative",serif;margin:0 0 8px}
      .aegis-actions{display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
      .aegis-btn{cursor:pointer;border:0;border-radius:8px;padding:8px 12px;background:#1e2b36;color:#cfe;transition:.2s}
      .aegis-btn:hover{transform:translateY(-1px);background:#254151}
    );

    // Podmiana grafik IMG po fragmencie ścieżki (działa od razu – placeholdery też się wyświetlą)
    const map = def.assets || {};
    const imgs = document.querySelectorAll('img');
    imgs.forEach(img=>{
      const src = img.getAttribute('src')||'';
      Object.keys(map).forEach(pattern=>{
        if(src.includes(pattern)){
          img.setAttribute('src', REPO + '/' + map[pattern] + '?v=0.8.1-dev');
        }
      });
    });

    // Znaczek wersji
    const old = document.querySelector('.aegis-badge'); if(old) old.remove();
    document.body.appendChild(el('div',{className:'aegis-badge',innerText:Aegis  • }));
    console.log('[Aegis] Theme applied:', def.name);
  }

  // Panel wyboru motywu
  function mountPanel(){
    const wrap = document.createElement('div');
    wrap.style.cssText = 'position:fixed;top:68px;right:10px;z-index:99999;background:rgba(0,0,0,.72);padding:8px;border-radius:10px;color:#fff;font:14px "Cinzel Decorative",serif;box-shadow:0 2px 10px rgba(0,0,0,.4)';
    const lab = el('span',{innerText:'Motyw: '});
    const sel = el('select');
    Object.entries(mapping.themes).forEach(([k,v])=>{
      const o = el('option',{value:k,innerText:v.name}); if(k===localStorage.getItem(KEY)||k===DEF && !localStorage.getItem(KEY)) o.selected=true;
      sel.appendChild(o);
    });
    sel.onchange = e => { localStorage.setItem(KEY,e.target.value); location.reload(); };
    wrap.append(lab,sel);
    document.body.appendChild(wrap);
  }

  // Ekran powitalny (jednorazowo po update)
  function welcome(){
    const k='aegis-welc-'+('0.8.1-dev'.replace(/\W/g,''));
    if(localStorage.getItem(k)) return;
    localStorage.setItem(k,'1');
    const modal = el('div',{className:'aegis-modal'});
    const card  = el('div',{className:'aegis-card'});
    card.append(
      el('h3',{className:'aegis-title',innerText:'Aegis – Grepolis Remaster'}),
      el('p',{innerText:'Motywy, nowe UI, animacje. Wybierz styl, a grafiki i kolory zmienią się automatycznie.'}),
      el('div',{className:'aegis-actions'},
        [el('button',{className:'aegis-btn',innerText:'Classic',onclick:()=>{localStorage.setItem(KEY,'classic');location.reload();}}),
         el('button',{className:'aegis-btn',innerText:'Pirate', onclick:()=>{localStorage.setItem(KEY,'pirate'); location.reload();}}),
         el('button',{className:'aegis-btn',innerText:'Emerald',onclick:()=>{localStorage.setItem(KEY,'emerald');location.reload();}}),
         el('button',{className:'aegis-btn',innerText:'Dark',   onclick:()=>{localStorage.setItem(KEY,'dark');   location.reload();}})]
      )
    );
    modal.append(card); document.body.appendChild(modal);
    modal.addEventListener('click',e=>{ if(e.target===modal) modal.remove(); },{once:true});
  }

  applyTheme(DEF);
  mountPanel();
  welcome();
})();
