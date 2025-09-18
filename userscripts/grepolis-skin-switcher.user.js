// ==UserScript==
// @name         Aegis – Grepolis Skin Switcher
// @namespace    https://github.com/KID6767/Aegis
// @version      0.6.5-stable
// @description  Remaster Grepolis UI – dynamic skin/theme switcher (Classic, Pirate-Epic, Emerald, Dark Mode, Animations)
// @author       KID6767 & ChatGPT
// @match        https://*.grepolis.com/*
// @icon         https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/logo.png
// @updateURL    https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @downloadURL  https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-skin-switcher.user.js
// @grant        GM_xmlhttpRequest
// @grant        GM_addStyle
// @connect      raw.githubusercontent.com
// ==/UserScript==

(function() {
    'use strict';

    const REPO = "https://raw.githubusercontent.com/KID6767/Aegis/main";
    const MAPPING = `${REPO}/config/mapping.json`;

    let assets = {};
    let currentTheme = "classic"; // domyślnie Classic

    // 🔄 Pobierz mapping.json
    function loadMapping() {
        GM_xmlhttpRequest({
            method: "GET",
            url: MAPPING,
            onload: function(response) {
                try {
                    assets = JSON.parse(response.responseText);
                    console.log("[Aegis] Mapping loaded:", assets);
                    applyTheme(currentTheme);
                } catch (e) {
                    console.error("[Aegis] Mapping parse error:", e);
                }
            },
            onerror: function(e) {
                console.error("[Aegis] Failed to load mapping.json", e);
            }
        });
    }

    // 🎨 Zastosuj motyw
    function applyTheme(theme) {
        if (!assets[theme]) {
            console.warn(`[Aegis] Theme '${theme}' not found in mapping.json`);
            return;
        }
        currentTheme = theme;

        const mapping = assets[theme];
        for (const [selector, url] of Object.entries(mapping)) {
            const elements = document.querySelectorAll(selector);
            elements.forEach(el => {
                if (el.tagName === "IMG") {
                    el.src = url;
                } else {
                    el.style.backgroundImage = `url("${url}")`;
                }
            });
        }

        console.log(`[Aegis] Theme applied: ${theme}`);
    }

    // 🛠 Panel wyboru motywu
    function injectThemeSwitcher() {
        const container = document.createElement("div");
        container.id = "aegis-theme-switcher";
        container.style.position = "fixed";
        container.style.top = "100px";
        container.style.right = "10px";
        container.style.background = "rgba(0,0,0,0.7)";
        container.style.padding = "10px";
        container.style.borderRadius = "8px";
        container.style.color = "white";
        container.style.zIndex = 9999;

        ["classic", "pirate", "emerald", "dark"].forEach(theme => {
            const btn = document.createElement("button");
            btn.innerText = theme;
            btn.style.margin = "3px";
            btn.onclick = () => applyTheme(theme);
            container.appendChild(btn);
        });

        document.body.appendChild(container);
    }

    // 🚀 Start
    loadMapping();
    setTimeout(injectThemeSwitcher, 2000);
})();
