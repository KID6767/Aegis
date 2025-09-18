# ⚔️ Aegis — Grepolis Remaster (0.6-dev)

Pełny remaster wizualny 2025: 3 motywy (Classic / Pirate-Epic / Emerald), animacje (fale, ogień, aura, chorągwie, świece), @2x grafiki, Dark Mode.

## Instalacja (Tampermonkey)
1) Zainstaluj Tampermonkey.
2) Zainstaluj skrypt z RAW:
   https://raw.githubusercontent.com/KID6767/Aegis-Grepolis-Remake/main/userscripts/grepolis-skin-switcher.user.js
3) W grze w prawym-dolnym rogu: panel Aegis (motyw / Dark / Refresh).

## Struktura
- assets/themes/<theme>/theme.css + theme-anim.css — styl i animacje motywu
- assets/(units|buildings|ui)/<theme>/<nazwa>.png i <nazwa>@2x.png — grafiki w 1x/2x
- assets/sprites/*.png — sprite’y do animacji (ogień, iskry, chorągiew, świeca)
- config/mapping.json — mapowanie nazw z oryginału na nasze
- userscripts/grepolis-skin-switcher.user.js — logika podmian i animacji
