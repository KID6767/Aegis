// ==UserScript==
// @name         Aegis - Grepolis Remaster
// @namespace    https://github.com/KID6767/Aegis
// @version      1.0.1
// @description  Motywy, ekran powitalny, branding dla Grepolis
// @author       Aegis Dev Team
// @match        *://*.grepolis.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    console.log("Aegis 1.0.1 loaded");

    // Ekran powitalny z animacją
    const splash = document.createElement("div");
    splash.style.position = "fixed";
    splash.style.top = 0;
    splash.style.left = 0;
    splash.style.width = "100%";
    splash.style.height = "100%";
    splash.style.background = "rgba(0,0,0,0.85) url('https://raw.githubusercontent.com/KID6767/Aegis/main/assets/branding/spinner.gif') center no-repeat";
    splash.style.zIndex = 9999;
    splash.style.color = "white";
    splash.style.textAlign = "center";
    splash.style.fontSize = "32px";
    splash.innerHTML = "<br><br><br><br>⚔️ Witaj w Aegis ⚔️<br>Nowa era Grepolis!";
    document.body.appendChild(splash);

    setTimeout(() => {
        splash.remove();
    }, 5000);
})();
