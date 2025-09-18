
// ==Skrypt użytkownika==
// @name Aegis — Grepolis Skin Switcher
// @namespace https://github.com/KID6767/Aegis-Grepolis-Remake
// @wersja 0.4-dev
// @description Classic / Pirate-Epic / Emerald – remaster 2025: skiny + Dark Mode + @2x; ładowanie motywu CSS w mapping.json z GitHuba.
// @autor KID6767
// @match *://*.grepolis.com/*
// @run-at document-end
// @grant GM_getValue
// @grant GM_setValue
// @grant GM_addStyle
// @grant GM_xmlhttpRequest
// ==/Skrypt użytkownika==

(funkcjonować(){{
  "użyj ściśle";
  const BASE_RAW = "https://raw.githubusercontent.com/KID6767/Aegis-Grepolis-Remake/main";
  const MAP_PATH = "/config/mapping.json";
  const TEMATY = ["klasyczny","piracki_epicki","szmaragdowy"];
  niech bieżącyTheme = GM_getValue("aegis_theme","classic");
  niech mapowanie = null;

  funkcja rawUrl(p){{ return BASE_RAW + p; }}
  funkcja pobierzJson(url) {{
    zwróć nową obietnicę((rozwiąż) => {{
      próbować {{
        GM_xmlhttpRequest({{
          metoda: „GET”, url: url + „?t=” + Date.now(),
          onload: (res) => {{ try {{ resolve(JSON.parse(res.responseText)); }} catch(e){{ resolve(null); }} }},
          onerror: () => resolve(null)
        }});
      }} złap(e) {{ pobierz(url).then(r=>r.json()).then(rozwiąż).catch(()=>rozwiąż(null)); }}
    }});
  }}

  funkcja loadThemeCSS(motyw) {{
    const id='aegis-theme-css'; document.getElementById(id)?.remove();
    const link=document.createElement('link'); link.id=id; link.rel='arkusz stylów';
    link.href = rawUrl(`/assets/themes/${{theme}}/theme.css`) + "?t=" + Date.now();
    document.head.appendChild(link);
  }}

  funkcja pickDensityKey(fname) {{
    const hi = fname.replace(/\.png$/i,'@2x.png');
    zwróć (mapowanie[aktualnyMotyw] i mapowanie[aktualnyMotyw][cześć]) ? cześć : fname;
  }}

  funkcja mapUrl(src) {{
    const fname = src.split('/').pop().split('?')[0].toLowerCase();
    const map = mapping[aktualnymotyw] || {{}};
    niech klucz = fname;
    jeśli (!map[klucz]) {{
      dla (const k obiektu Object.keys(map)) {{ if (fname.includes(k.replace('@2x.png','').replace('.png',''))) {{ key = k; break; }} }}
    }}
    jeśli (!map[klucz]) zwraca null;
    const best = pickDensityKey(klucz);
    zwróć rawUrl(map[najlepsza] || mapa[klucz]);
  }}

  funkcja reskin(root=document) {{
    root.querySelectorAll("img").forEach(img => {{
      jeśli (img.dataset.aegisSkinned==='1') zwróć;
      const nu = mapUrl(img.src); jeśli (nu) {{ img.src=nu; img.dataset.aegisSkinned='1'; img.classList.add('aegis-icon'); }}
    }});
    root.querySelectorAll("[style*='tło'], .ikona_jednostki, .ikona_statku, .ikona_budynku, .tło_gp").forEach(el=>{{
      jeśli (el.dataset.aegisSkinned==='1') zwróć;
      const bg = getComputedStyle(el).getPropertyValue("obraz tła");
      const m = bg && bg.match(/url\(["']?([^"')]+)["']?\)/);
      jeśli (m && m[1]) {{ const nu = mapUrl(m[1]); jeśli (nu) {{ el.style.backgroundImage=`url("${{nu}}")`; el.dataset.aegisSkinned='1'; }} }}
    }});
  }}

  funkcja setTheme(t) {{
    jeśli (!THEMES.includes(t)) zwróć;
    bieżącyTheme=t; GM_setValue('aegis_theme',t);
    document.querySelectorAll('[data-aegis-skinned]').forEach(n=>n.removeAttribute('data-aegis-skinned'));
    załadujThemeCSS(t); reskin(); zaktualizujPanel();
  }}

  funkcja setDark(on) {{
    GM_setValue('aegis_dark', !!on);
    document.documentElement.classList.toggle('aegis-dark', !!on);
    zaktualizujPanel();
  }}

  funkcja updatePanel() {{
    const sel=document.getElementById('aegis-theme'); if (sel) sel.value=currentTheme;
    const dark=document.getElementById('aegis-dark'); if (dark) dark.textContent = 'Ciemny: ' + (GM_getValue('aegis_dark',false)?'ON':'OFF');
  }}

  funkcja addPanel() {{
    const wrap=document.createElement('div');
    wrap.innerHTML=`
    <div style="pozycja:stała; prawa:12px; dół:12px; indeks z:2147483647; tło:rgba(10,10,10,.75);
                wypełnienie: 10px; promień obramowania: 10px; kolor: #fff; czcionka: 12px/1.3 system-ui,Segoe UI,Arial;">
      <div style="display:flex; gap:6px; align-items:center;">
        <strong>Egida</strong>
        <select id="aegis-theme">
          <option value="classic">Klasyczny</option>
          <option value="pirate_epic">Piracki-Epic</option>
          <option value="emerald">Szmaragd</option>
        </wybierz>
        <button id="aegis-dark">Ciemny: WYŁ</button>
        <button id="aegis-reskin">Odśwież</button>
      </div>
    </div>`;
    dokument.ciało.appendChild(wrap.firstElementChild);
    document.getElementById('aegis-theme').addEventListener('change',e=>setTheme(e.target.value));
    document.getElementById('aegis-dark').addEventListener('click',()=>setDark(!GM_getValue('aegis_dark',false)));
    document.getElementById('aegis-reskin').addEventListener('click',()=>reskin());
    zaktualizujPanel();
  }}

  funkcja asynchroniczna init() {{
    dodajPanel();
    załadujThemeCSS(bieżącyMotyw);
    mapowanie = oczekuj na pobranieJson(rawUrl(MAP_PATH)) || {{"klasyczny":{{}}, "piracki_epicki":{{}}, "szmaragdowy":{{}}}};
    setDark(GM_getValue('aegis_dark', false));
    zmiana wyglądu();
    const obs = nowy MutationObserver(ms=>ms.forEach(m=>m.addedNodes.forEach(n=>n.nodeType===1 && reskin(n))));
    obs.observe(document.documentElement, {{childList:true, subtree:true}});
  }}
  init();
}})();