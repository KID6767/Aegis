// ==UserScript==
// @name         Aegis – Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      0.8.0-dev
// @description  Dynamiczne skiny Grepolis: Classic, Pirate, Emerald, Dark (+ niespodzianki)
// @author       KID6767
// @match        https://*.grepolis.com/*
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @grant        none
// ==/UserScript==

(async function() {
    'use strict';
    const repo = "https://raw.githubusercontent.com/KID6767/Aegis/main";
    const mappingUrl = ${repo}/config/mapping.json;

    let mapping = {};
    try {
        mapping = await fetch(mappingUrl).then(r => r.json());
    } catch (e) {
        console.error("[Aegis] Cannot load mapping.json", e);
        return;
    }

    const saved = localStorage.getItem("aegis-theme") || "classic";
    applyTheme(saved);

    function applyTheme(theme) {
        if(!mapping.themes[theme]) return;
        const def = mapping.themes[theme];

        if(def.css){
            const link = document.createElement("link");
            link.rel = "stylesheet";
            link.href = ${repo}/;
            document.head.appendChild(link);
        }

        for(const [key, val] of Object.entries(def.assets)) {
            const els = document.querySelectorAll(img[src*='']);
            els.forEach(el => el.src = ${repo}/);
        }

        console.log("[Aegis] Theme applied:", def.name);
    }

    // UI panel
    const panel = document.createElement("div");
    panel.style.position="fixed";
    panel.style.top="60px";
    panel.style.right="10px";
    panel.style.background="rgba(0,0,0,0.75)";
    panel.style.color="#fff";
    panel.style.padding="8px";
    panel.style.borderRadius="10px";
    panel.style.zIndex=9999;
    panel.style.font="14px 'Cinzel Decorative', serif";
    panel.style.boxShadow="0 0 10px rgba(0,0,0,0.5)";

    const label = document.createElement("label");
    label.textContent="Motyw: ";
    panel.appendChild(label);

    const select = document.createElement("select");
    for(const [k,v] of Object.entries(mapping.themes)){
        const opt = document.createElement("option");
        opt.value = k;
        opt.textContent = v.name;
        if(k===saved) opt.selected = true;
        select.appendChild(opt);
    }
    select.addEventListener("change", e=>{
        localStorage.setItem("aegis-theme", e.target.value);
        location.reload();
    });
    panel.appendChild(select);

    const ver = document.createElement("div");
    ver.textContent = "Aegis " + "0.8.0-dev";
    ver.style.fontSize="11px";
    ver.style.marginTop="6px";
    ver.style.opacity="0.8";
    panel.appendChild(ver);

    document.body.appendChild(panel);
})();
