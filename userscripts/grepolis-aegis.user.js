// ==UserScript==
// @name         Aegis — Grepolis Remaster
// @namespace    aegis
// @version      1.0.1
// @description  Motywy (Classic/Remaster/Pirate/Dark), pasek konfiguracji (PP-dół), modal z podglądem brandingu.
// @match        *://*.grepolis.com/*
// @grant        none
// @run-at       document-end
// ==/UserScript==

(function(){
  "use strict";

  const ASSETS = {
    banner: "https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/banner.svg"
  };

  const THEMES = {
    classic:  { bg:"#f3e6c1", fg:"#2c2c2c", accent:"#8c6f39" },
    remaster: { bg:"#13221a", fg:"#efead4", accent:"#d4af37" },
    pirate:   { bg:"#101010", fg:"#e0d0a0", accent:"#8c6f39" },
    dark:     { bg:"#0b0f12", fg:"#d7dfeb", accent:"#7fb07f" }
  };

  function css(v){
    return `
      :root{--aeg-bg:${v.bg};--aeg-fg:${v.fg};--aeg-ac:${v.accent}}
      .aeg-bar{position:fixed; right:12px; bottom:12px; z-index:99999; display:flex; gap:8px; align-items:center;
        background:var(--aeg-bg); color:var(--aeg-fg); border:2px solid var(--aeg-ac); border-radius:12px; padding:8px 10px;
        box-shadow:0 8px 24px rgba(0,0,0,.35); font-family:system-ui,Segoe UI,Arial; font-size:12px;}
      .aeg-btn{cursor:pointer; padding:4px 8px; border:1px solid var(--aeg-ac); border-radius:8px; background:transparent; color:var(--aeg-fg)}
      .aeg-btn:hover{background:var(--aeg-ac); color:#111}
      .aeg-back{position:fixed; inset:0; background:rgba(0,0,0,.55); display:flex; align-items:center; justify-content:center; z-index:100000}
      .aeg-modal{width:min(900px,92vw); max-height:86vh; overflow:auto; background:var(--aeg-bg); color:var(--aeg-fg);
        border:2px solid var(--aeg-ac); border-radius:16px; padding:18px; box-shadow:0 10px 30px rgba(0,0,0,.45)}
      .aeg-modal h2{margin:0 0 10px 0; font-size:22px}
      .aeg-grid{display:grid; grid-template-columns:1fr 1fr; gap:14px}
      .aeg-card{border:1px dashed var(--aeg-ac); border-radius:12px; padding:10px; background:rgba(0,0,0,.03)}
      .aeg-banner{width:100%; border-radius:12px; border:1px solid var(--aeg-ac)}
      .aeg-close{float:right}
    `;
  }
  function loadTheme(name){
    const conf = THEMES[name] || THEMES.remaster;
    let tag = document.getElementById("aeg-style");
    if(!tag){ tag = document.createElement("style"); tag.id = "aeg-style"; document.head.appendChild(tag); }
    tag.textContent = css(conf);
    localStorage.setItem("AEGIS:theme", name);
  }
  function openModal(){
    const wrap = document.createElement("div"); wrap.className = "aeg-back";
    const modal = document.createElement("div"); modal.className = "aeg-modal";
    modal.innerHTML = `
      <button class="aeg-btn aeg-close">Zamknij</button>
      <h2>AEGIS — Grepolis Remaster</h2>
      <div class="aeg-grid">
        <div class="aeg-card"><strong>Motywy</strong><br/><br/>
          ${["classic","remaster","pirate","dark"].map(k=>'<button class="aeg-btn switch" data-k="'+k+'">'+k+'</button>').join(" ")}
        </div>
        <div class="aeg-card">
          <strong>Branding</strong><br/><br/>
          <ul style="margin-top:6px">
            <li>banner.svg — <code>assets/branding/banner.svg</code></li>
            <li>ship_green.svg / ship_pirate.svg</li>
            <li>spinner.gif, gold_dot.png</li>
          </ul>
        </div>
        <div class="aeg-card" style="grid-column:1 / span 2">
          <img src="${ASSETS.banner}" alt="Aegis banner" class="aeg-banner"/>
        </div>
      </div>`;
    wrap.appendChild(modal);
    document.body.appendChild(wrap);
    modal.querySelector(".aeg-close").onclick = ()=>wrap.remove();
    modal.querySelectorAll(".switch").forEach(b=>b.onclick = ()=>loadTheme(b.dataset.k));
  }
  function initBar(){
    const bar = document.createElement("div"); bar.className = "aeg-bar";
    bar.innerHTML = `
      <button class="aeg-btn" id="aeg-open">Aegis</button>
      <select class="aeg-btn" id="aeg-theme">
        ${Object.keys(THEMES).map(k=>'<option value="'+k+'">'+k+'</option>').join("")}
      </select>`;
    document.body.appendChild(bar);
    document.getElementById("aeg-open").onclick = openModal;
    const sel = document.getElementById("aeg-theme");
    sel.value = (localStorage.getItem("AEGIS:theme")||"remaster");
    sel.onchange = ()=>loadTheme(sel.value);
  }
  function ready(fn){ if (document.readyState!=="loading") fn(); else document.addEventListener("DOMContentLoaded", fn); }
  ready(()=>{
    const theme = localStorage.getItem("AEGIS:theme") || "remaster";
    loadTheme(theme);
    initBar();
    console.log("%cAegis loaded ✓","color:#0f0;background:#222;padding:2px 6px;border-radius:6px");
  });
})();