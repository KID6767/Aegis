<p align="center">
  <img src="../assets/branding/logo_aegis.png" width="64" height="64" />
  <h1 style="color:#d4af37;background:#0a2e22;padding:10px;border-radius:12px;margin:0">Aegis – Grepolis Remaster</h1>
  <b style="color:#f2d574">Butelkowa zieleń + złoto • panel z logo • AssetMap • RAW Base • dym/fajerwerki (on/off)</b><br/>
  <sub style="opacity:.8">Wersja 1.0.0-xxl</sub>
</p>

---

## Jak to wygląda?

> Mockup (styl inspirowany):  
> <img src="../assets/branding/mockup.png" alt="Screenshot preview" width="960"/>

> Uwaga: mockup to podgląd stylistyki; finalny wygląd zależy od oryginalnego HTML Grepolis + motywu Aegisa.

## Co to jest?

**Aegis** to stabilny remaster UI do Grepolis.  
Daje spójny wygląd (Classic / Remaster / Pirate / Dark), panel konfiguracji w prawym dolnym rogu (złote logo), możliwość podmiany grafik przez **AssetMap** (z RAW Base), logger, animowany dym i jednorazowe fajerwerki na powitanie wersji.

## Najważniejsze funkcje

- 🌈 **Motywy**: Classic, Remaster 2025, Pirate, Dark (przełącznik i skrót `Alt+T`).
- ⚙️ **Panel z logo** (`Alt+G`): motyw, RAW Base (adres z assetami), FX (dym/fajerwerki), logger.
- 🖼️ **AssetMap**: konfigurowalna mapa zamiany grafik (np. birema → Twoja nowa birema).
- 🧩 **Bezpieczny loader**: inline CSS fallback (userscript nie zależy od zewnętrznego CSS).
- 🧪 **Logger**: `AEGIS.log(...)` i `AEGIS.version` (przełącznik w panelu).
- 🎆 **Powitanie wersji**: jednorazowy ekran + fajerwerki (możesz wyłączyć w panelu).
- 🌫️ **Dym**: subtelna animacja u dołu ekranu (również on/off).

## Instalacja (Tampermonkey)

1) Zainstaluj [Tampermonkey](https://www.tampermonkey.net/).  
2) Otwórz:  
   **https://raw.githubusercontent.com/KID6767/Aegis/main/userscripts/grepolis-aegis.user.js**  
   (TM zaproponuje instalację/aktualizację).
3) Odśwież Grepolis. Zobaczysz badge wersji (PP góra). Kliknij złote **logo** (PP dół), aby otworzyć panel.

## Konfiguracja / RAW Base

- **Motyw**: panel (Classic / Remaster / Pirate / Dark) lub `Alt+T`.
- **RAW Base**: adres katalogu z Twoimi grafikami (np. GitHub RAW).
- **FX**: „Animowany dym” i „Fajerwerki” możesz włączać/wyłączać.
- **Logger**: przełącznik w panelu (domyślnie ON).

## AssetMap (podmiana grafik)

Domyślnie Aegis ma mapę m.in. dla **biremy** i logo.  
Dopisz własne reguły w konsoli:

```js
AEGIS.addAssetMap({
  "ships/trireme.png": "https://raw.githubusercontent.com/USER/REPO/branch/assets/ships/my_trireme.png"
});
```
