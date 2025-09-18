// ==UserScript==
// @name         Aegis â€” Grepolis Skin Switcher
// @namespace    https://github.com/KID6767/Aegis-Grepolis-Remake
// @version      0.1b
// @description  Podmiana grafik Grepolis (Remaster 2025 / Pirate-Epic) â€” beta.
// @author       KID6767
// @match        https://*.grepolis.com/*
// @match        http://*.grepolis.com/*
// @run-at       document-end
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_addStyle
// @grant        GM_xmlhttpRequest
// @connect      raw.githubusercontent.com
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis-Grepolis-Remake/main/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis-Grepolis-Remake/main/userscripts/grepolis-skin-switcher.user.js
// ==/UserScript==

(function () {
  'use strict';
  const THEMES = {
    remaster2025: "local:config/mapping.remaster2025.json",
    pirate_epic: "local:config/mapping.pirate_epic.json"
  };
  const DEFAULT_THEME = GM_getValue("theme", "remaster2025");
  let mapping = {};
  function loadLocalMapping(theme, cb) {
    const path = (THEMES[theme] || THEMES.remaster2025);
    if (path.startsWith("local:")) {
      const localPath = path.replace("local:", "");
      fetch(location.origin + "/" + localPath)
        .then(r => r.json())
        .then(j => { mapping = j; if (cb) cb(); })
        .catch(e => { mapping = {}; if (cb) cb(); });
      return;
    }
    cb && cb();
  }
  function swapUrl(original) {
    if (!original) return original;
    const clean = original.replace(/(\\?.*)$/, "");
    if (mapping[clean]) return mapping[clean];
    const file = clean.split("/").pop();
    for (const k of Object.keys(mapping)) {
      if (k.endsWith(file)) return mapping[k];
    }
    return original;
  }
  function processImg(img) {
    if (!img || img.dataset.aegisSkinned === "1") return;
    const newSrc = swapUrl(img.src);
    if (newSrc && newSrc !== img.src) {
      img.src = newSrc;
      img.dataset.aegisSkinned = "1";
    }
  }
  function processStyle(el) {
    if (!el || el.dataset.aegisSkinned === "1") return;
    const bg = getComputedStyle(el).getPropertyValue("background-image");
    if (bg && bg.includes("url(")) {
      const urlMatch = bg.match(/url\\([\"']?([^\"')]+)[\"']?\\)/);
      if (urlMatch && urlMatch[1]) {
        const newUrl = swapUrl(urlMatch[1]);
        if (newUrl && newUrl !== urlMatch[1]) {
          el.style.backgroundImage = url(\"\");
          el.dataset.aegisSkinned = "1";
        }
      }
    }
  }
  function scanOnce(root = document) {
    root.querySelectorAll("img").forEach(processImg);
    root.querySelectorAll("[style*='background'], .unit_icon, .ship_icon, .building_icon, .gp_background")
        .forEach(processStyle);
  }
  function addSwitcher() {
    const bar = document.createElement('div');
    bar.id = 'aegis-switcher';
    bar.innerHTML = 
      <div style="position:fixed; right:12px; bottom:12px; z-index:2147483647;
                  background:rgba(10,10,10,0.6); padding:8px; border-radius:8px; color:#fff; font:12px sans-serif;">
        <label style="margin-right:6px;">Aegis:</label>
        <select id="aegis-theme">
          <option value="remaster2025">Remaster 2025</option>
          <option value="pirate_epic">Pirate Epic</option>
        </select>
        <button id="aegis-refresh" style="margin-left:8px;">Refresh</button>
      </div>;
    document.body.appendChild(bar);
    const sel = document.getElementById('aegis-theme');
    sel.value = DEFAULT_THEME;
    sel.addEventListener('change', () => {
      GM_setValue('theme', sel.value);
      loadLocalMapping(sel.value, () => { scanOnce(); });
    });
    document.getElementById('aegis-refresh').addEventListener('click', () => { scanOnce(); });
  }

  function showWelcomeIfNeeded() {
    if (GM_getValue("aegis_welcome_shown", false)) return;
    try {
      const box = document.createElement('div');
      box.id = 'aegis-welcome-box';
      box.style = 'position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background:#0f0f10; color:#fff; padding:20px 30px; border-radius:12px; z-index:2147483647; text-align:center; max-width:520px; box-shadow:0 0 30px rgba(0,0,0,0.8);';
      box.innerHTML = 
        <img src="/assets/branding/logo.png" style="max-width:260px; margin-bottom:14px;" />
        <h2 style="margin:0; font-family:sans-serif;">Witaj w Aegis!</h2>
        <p style="font-family:sans-serif; font-size:14px; line-height:1.5; margin-top:10px;">
          TwĂłj Ĺ›wiat wĹ‚aĹ›nie dostaĹ‚ nowe ĹĽycie:<br>
          âś¨ Remaster 2025 â€“ odĹ›wieĹĽone klasyki<br>
          â ď¸Ź Pirate-Epic â€“ totalna zmiana klimatu
        </p>
        <p style="margin-top:12px; font-size:12px; opacity:0.8;">Autor: KID6767</p>
        <button id="aegis-welcome-close" style="margin-top:15px; padding:6px 12px; border:none; border-radius:6px; background:#e38b06; color:#fff; font-weight:bold; cursor:pointer;">Zaczynamy!</button>
      ;
      document.body.appendChild(box);
      document.getElementById('aegis-welcome-close').onclick = () => { box.remove(); GM_setValue('aegis_welcome_shown', true); };
    } catch (e) { console.warn('Aegis welcome failed', e); }
  }

  addSwitcher();
  loadLocalMapping(DEFAULT_THEME, () => { scanOnce(); showWelcomeIfNeeded(); });
  const obs = new MutationObserver((muts) => {
    muts.forEach(m => {
      if (m.addedNodes && m.addedNodes.length) {
        m.addedNodes.forEach(n => { if (n.nodeType === 1) scanOnce(n); });
      }
    });
  });
  obs.observe(document.documentElement, { childList: true, subtree: true });
})();
