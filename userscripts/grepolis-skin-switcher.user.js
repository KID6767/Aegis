// ==UserScript==
// @name         Aegis — Grepolis Skin Switcher
// @namespace    https://github.com/KID6767/Aegis-Grepolis-Remake
// @version      0.3
// @description  Classic, Pirate-Epic, Emerald — system motywów + Dark Mode dla całego Grepolis
// @author       KID6767
// @match        *://*.grepolis.com/*
// @run-at       document-end
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// ==/UserScript==

(function(){"use strict";
  const BASE_RAW = "https://raw.githubusercontent.com/KID6767/Aegis-Grepolis-Remake/main";
  const MAP_PATH = "/config/mapping.json";
  const THEMES = ["classic","pirate_epic","emerald"];
  let currentTheme = GM_getValue("aegis_theme","classic");
  let mapping = null;

  function rawUrl(path){ return BASE_RAW ? BASE_RAW + path : path; }

  function fetchJson(url) {
    return new Promise((resolve) => {
      try {
        GM_xmlhttpRequest({
          method: "GET",
          url: url + "?t=" + Date.now(),
          onload: (res) => { try { resolve(JSON.parse(res.responseText)); } catch(e){ console.error("[Aegis] JSON parse fail", e); resolve(null); } },
          onerror: () => resolve(null)
        });
      } catch(e) {
        fetch(url).then(r=>r.json()).then(resolve).catch(()=>resolve(null));
      }
    });
  }

  function matchAndSwapImg(img) {
    if (!mapping) return;
    const src = img.src;
    const fname = src.split("/").pop().split("?")[0].toLowerCase();
    let newUrl = mapping[currentTheme][fname];
    if (!newUrl) {
      for (const key of Object.keys(mapping[currentTheme])) {
        if (fname.includes(key.replace(".png",""))) { newUrl = mapping[currentTheme][key]; break; }
      }
    }
    if (newUrl && img.dataset.aegisSkinned !== "1") {
      img.src = rawUrl(newUrl);
      img.dataset.aegisSkinned = "1";
    }
  }

  function matchAndSwapStyle(el) {
    if (!mapping) return;
    const bg = getComputedStyle(el).getPropertyValue("background-image");
    const m = bg && bg.match(/url\(["']?([^"')]+)["']?\)/);
    if (m && m[1]) {
      const url = m[1];
      const fname = url.split("/").pop().split("?")[0].toLowerCase();
      let newUrl = mapping[currentTheme][fname];
      if (!newUrl) {
        for (const key of Object.keys(mapping[currentTheme])) {
          if (fname.includes(key.replace(".png",""))) { newUrl = mapping[currentTheme][key]; break; }
        }
      }
      if (newUrl && el.dataset.aegisSkinned !== "1") {
        el.style.backgroundImage = `url("${rawUrl(newUrl)}")`;
        el.dataset.aegisSkinned = "1";
      }
    }
  }

  function reskin(root=document) {
    root.querySelectorAll("img").forEach(matchAndSwapImg);
    root.querySelectorAll("[style*='background'], .unit_icon, .ship_icon, .building_icon, .gp_background")
        .forEach(matchAndSwapStyle);
  }

  function setTheme(t) {
    if (!THEMES.includes(t)) return;
    currentTheme = t;
    GM_setValue("aegis_theme", t);
    // reset flags so we can reskin already-processed elements
    document.querySelectorAll("[data-aegis-skinned]").forEach(el=>el.removeAttribute("data-aegis-skinned"));
    reskin();
    updatePanel();
    loadThemeCSS(t);

  }

  // Dark mode
  let darkStyleEl = null;
  function setDark(on) {
    if (on) {
      if (darkStyleEl) return;
      darkStyleEl = document.createElement("style");
      darkStyleEl.textContent = `
        body, .game_inner_box, .ui_box, .gpwindow_content, .forum_content, .login_page { background-color:#111 !important; color:#ddd !important; }
        a, .gpwindow_content a, .forum_content a { color:#4da6ff !important; }
        .button, .btn, input[type="submit"] { background-color:#333 !important; color:#eee !important; border:1px solid #555 !important; }
      `;
      document.head.appendChild(darkStyleEl);
      GM_setValue("aegis_dark", true);
    } else {
      if (darkStyleEl) darkStyleEl.remove();
      darkStyleEl = null;
      GM_setValue("aegis_dark", false);
    }
    updatePanel();
  }

  function updatePanel() {
    const themeSel = document.getElementById("aegis-theme");
    if (themeSel) themeSel.value = currentTheme;
    const darkBtn = document.getElementById("aegis-dark");
    if (darkBtn) darkBtn.textContent = "Dark: " + (darkStyleEl ? "ON" : "OFF");
  }

  function addPanel() {
    const box = document.createElement("div");
    box.innerHTML = `
      <div style="position:fixed; right:12px; bottom:12px; z-index:2147483647; background:rgba(10,10,10,0.75);
                  padding:10px; border-radius:10px; color:#fff; font:12px/1.3 system-ui,Segoe UI,Arial;">
        <div style="display:flex; gap:6px; align-items:center;">
          <strong>Aegis</strong>
          <select id="aegis-theme">
            <option value="classic">Classic</option>
            <option value="pirate_epic">Pirate-Epic</option>
            <option value="emerald">Emerald</option>
          </select>
          <button id="aegis-dark">Dark: OFF</button>
        </div>
      </div>`;
    document.body.appendChild(box.firstElementChild);
    document.getElementById("aegis-theme").addEventListener("change",(e)=>setTheme(e.target.value));
    document.getElementById("aegis-dark").addEventListener("click",()=>setDark(!darkStyleEl));
    updatePanel();
  }
// fragment – wczytanie CSS motywu i obsługa @2x
function loadThemeCSS(theme) {
  const id = 'aegis-theme-css';
  document.getElementById(id)?.remove();
  const link = document.createElement('link');
  link.id = id;
  link.rel = 'stylesheet';
  link.href = `${BASE_RAW}/assets/themes/${theme}/theme.css?t=${Date.now()}`;
  document.head.appendChild(link);
}

function pickDensity(urlBase) {
  const ratio = window.devicePixelRatio || 1;
  if (ratio >= 1.75) return urlBase.replace('.png', '@2x.png');
  return urlBase; // @1x domyślne
}

// w reskin():
if (newUrl) {
  const final = newUrl.endsWith('.png') ? pickDensity(rawUrl(newUrl)) : rawUrl(newUrl);
  img.src = final;
  img.classList.add('aegis-icon');
}

  async function init() {
    addPanel();
    mapping = await fetchJson(rawUrl(MAP_PATH));
    if (!mapping) { console.warn("[Aegis] mapping.json nie załadowany"); mapping = {"classic":{}, "pirate_epic":{}, "emerald":{}}; }
    if (GM_getValue("aegis_dark", false)) setDark(true);
    reskin();
    loadThemeCSS(currentTheme);

    const obs = new MutationObserver(ms=>ms.forEach(m=>m.addedNodes.forEach(n=>n.nodeType===1 && reskin(n))));
    obs.observe(document.documentElement, {childList:true, subtree:true});
  }

  init();
})();
