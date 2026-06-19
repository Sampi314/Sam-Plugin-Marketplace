# Statusline palettes — visual reference

Six palettes ship with `cs-statusline-setup`. Pick one with the `-Palette` flag at install time:

```powershell
install.ps1 -Palette Sam          # default
install.ps1 -Palette Monochrome
install.ps1 -Palette HighContrast
install.ps1 -Palette Solarized
install.ps1 -Palette Nord
install.ps1 -Palette Dracula
```

Colour swatches below are rendered via `placehold.co` — view this page on GitHub for the previews, raw `.md` only shows the hex codes.

---

## Sam (default)

Purple / gold / teal — designed for dark terminals. The original palette baked into v3.1 of the statusline script.

| Role | Colour | Hex |
|---|---|---|
| `C_MODEL` — model name | ![](https://placehold.co/16x16/b48cff/b48cff.png) | `#b48cff` |
| `C_SKILL` — skill name | ![](https://placehold.co/16x16/82dcc8/82dcc8.png) | `#82dcc8` |
| `C_COST` — session $ | ![](https://placehold.co/16x16/ffdc50/ffdc50.png) | `#ffdc50` |
| `C_PROJCST` — project $ | ![](https://placehold.co/16x16/ffa064/ffa064.png) | `#ffa064` |
| `C_ADD` — lines added | ![](https://placehold.co/16x16/82dc82/82dc82.png) | `#82dc82` |
| `C_DEL` — lines removed | ![](https://placehold.co/16x16/ff6464/ff6464.png) | `#ff6464` |
| `C_TIME` — duration | ![](https://placehold.co/16x16/82b4ff/82b4ff.png) | `#82b4ff` |
| `C_COUNT` — session count | ![](https://placehold.co/16x16/c8aaff/c8aaff.png) | `#c8aaff` |
| `C_CYAN` — effort level | ![](https://placehold.co/16x16/50dcdc/50dcdc.png) | `#50dcdc` |
| `C_GOLD` — burn rate | ![](https://placehold.co/16x16/ffc83c/ffc83c.png) | `#ffc83c` |

---

## Monochrome

Greyscale only. Brighter shades reserved for the things you scan for (cost, lines added/removed); dimmer shades for time and duration. Best when you want the statusline to recede.

| Role | Colour | Hex |
|---|---|---|
| `C_MODEL` | ![](https://placehold.co/16x16/dcdcdc/dcdcdc.png) | `#dcdcdc` |
| `C_SKILL` | ![](https://placehold.co/16x16/b4b4b4/b4b4b4.png) | `#b4b4b4` |
| `C_COST` | ![](https://placehold.co/16x16/f0f0f0/f0f0f0.png) | `#f0f0f0` |
| `C_PROJCST` | ![](https://placehold.co/16x16/c8c8c8/c8c8c8.png) | `#c8c8c8` |
| `C_ADD` | ![](https://placehold.co/16x16/c8c8c8/c8c8c8.png) | `#c8c8c8` |
| `C_DEL` | ![](https://placehold.co/16x16/a0a0a0/a0a0a0.png) | `#a0a0a0` |
| `C_TIME` | ![](https://placehold.co/16x16/aaaaaa/aaaaaa.png) | `#aaaaaa` |
| `C_COUNT` | ![](https://placehold.co/16x16/b4b4b4/b4b4b4.png) | `#b4b4b4` |
| `C_CYAN` | ![](https://placehold.co/16x16/c8c8c8/c8c8c8.png) | `#c8c8c8` |
| `C_GOLD` | ![](https://placehold.co/16x16/dcdcdc/dcdcdc.png) | `#dcdcdc` |

---

## HighContrast

Saturated primaries only — no pastels. For bright terminals, colour-vision accessibility, or anyone who finds Sam's defaults too soft.

| Role | Colour | Hex |
|---|---|---|
| `C_MODEL` | ![](https://placehold.co/16x16/ff00ff/ff00ff.png) | `#ff00ff` (magenta) |
| `C_SKILL` | ![](https://placehold.co/16x16/00ffff/00ffff.png) | `#00ffff` (cyan) |
| `C_COST` | ![](https://placehold.co/16x16/ffff00/ffff00.png) | `#ffff00` (yellow) |
| `C_PROJCST` | ![](https://placehold.co/16x16/ff8000/ff8000.png) | `#ff8000` (orange) |
| `C_ADD` | ![](https://placehold.co/16x16/00ff00/00ff00.png) | `#00ff00` (green) |
| `C_DEL` | ![](https://placehold.co/16x16/ff0000/ff0000.png) | `#ff0000` (red) |
| `C_TIME` | ![](https://placehold.co/16x16/0080ff/0080ff.png) | `#0080ff` (blue) |
| `C_COUNT` | ![](https://placehold.co/16x16/ff00ff/ff00ff.png) | `#ff00ff` (magenta) |
| `C_CYAN` | ![](https://placehold.co/16x16/00ffff/00ffff.png) | `#00ffff` (cyan) |
| `C_GOLD` | ![](https://placehold.co/16x16/ffff00/ffff00.png) | `#ffff00` (yellow) |

---

## Solarized

Ethan Schoonover's [Solarized Dark](https://ethanschoonover.com/solarized/) — muted, warm, the dev-classic balanced palette. Good if you already run Solarized in your editor and want the statusline to harmonise.

| Role | Colour | Hex |
|---|---|---|
| `C_MODEL` — violet | ![](https://placehold.co/16x16/6c71c4/6c71c4.png) | `#6c71c4` |
| `C_SKILL` — cyan | ![](https://placehold.co/16x16/2aa198/2aa198.png) | `#2aa198` |
| `C_COST` — yellow | ![](https://placehold.co/16x16/b58900/b58900.png) | `#b58900` |
| `C_PROJCST` — orange | ![](https://placehold.co/16x16/cb4b16/cb4b16.png) | `#cb4b16` |
| `C_ADD` — green | ![](https://placehold.co/16x16/859900/859900.png) | `#859900` |
| `C_DEL` — red | ![](https://placehold.co/16x16/dc322f/dc322f.png) | `#dc322f` |
| `C_TIME` — blue | ![](https://placehold.co/16x16/268bd2/268bd2.png) | `#268bd2` |
| `C_COUNT` — magenta | ![](https://placehold.co/16x16/d33682/d33682.png) | `#d33682` |
| `C_CYAN` — cyan | ![](https://placehold.co/16x16/2aa198/2aa198.png) | `#2aa198` |
| `C_GOLD` — yellow | ![](https://placehold.co/16x16/b58900/b58900.png) | `#b58900` |

---

## Nord

Arctic-inspired cool pastels from [nordtheme.com](https://www.nordtheme.com/). Lower saturation than Sam's defaults; easier on the eyes for long sessions.

| Role | Colour | Hex |
|---|---|---|
| `C_MODEL` — nord15 purple | ![](https://placehold.co/16x16/b48ead/b48ead.png) | `#b48ead` |
| `C_SKILL` — nord7 teal | ![](https://placehold.co/16x16/8fbcbb/8fbcbb.png) | `#8fbcbb` |
| `C_COST` — nord13 yellow | ![](https://placehold.co/16x16/ebcb8b/ebcb8b.png) | `#ebcb8b` |
| `C_PROJCST` — nord12 orange | ![](https://placehold.co/16x16/d08770/d08770.png) | `#d08770` |
| `C_ADD` — nord14 green | ![](https://placehold.co/16x16/a3be8c/a3be8c.png) | `#a3be8c` |
| `C_DEL` — nord11 red | ![](https://placehold.co/16x16/bf616a/bf616a.png) | `#bf616a` |
| `C_TIME` — nord9 blue | ![](https://placehold.co/16x16/81a1c1/81a1c1.png) | `#81a1c1` |
| `C_COUNT` — nord15 purple | ![](https://placehold.co/16x16/b48ead/b48ead.png) | `#b48ead` |
| `C_CYAN` — nord8 cyan | ![](https://placehold.co/16x16/88c0d0/88c0d0.png) | `#88c0d0` |
| `C_GOLD` — nord13 yellow | ![](https://placehold.co/16x16/ebcb8b/ebcb8b.png) | `#ebcb8b` |

---

## Dracula

The [Dracula theme](https://draculatheme.com/) — vivid saturated dark theme with strong purples and pinks. Punchy; reads well against very dark backgrounds.

| Role | Colour | Hex |
|---|---|---|
| `C_MODEL` — purple | ![](https://placehold.co/16x16/bd93f9/bd93f9.png) | `#bd93f9` |
| `C_SKILL` — cyan | ![](https://placehold.co/16x16/8be9fd/8be9fd.png) | `#8be9fd` |
| `C_COST` — yellow | ![](https://placehold.co/16x16/f1fa8c/f1fa8c.png) | `#f1fa8c` |
| `C_PROJCST` — orange | ![](https://placehold.co/16x16/ffb86c/ffb86c.png) | `#ffb86c` |
| `C_ADD` — green | ![](https://placehold.co/16x16/50fa7b/50fa7b.png) | `#50fa7b` |
| `C_DEL` — red | ![](https://placehold.co/16x16/ff5555/ff5555.png) | `#ff5555` |
| `C_TIME` — cyan | ![](https://placehold.co/16x16/8be9fd/8be9fd.png) | `#8be9fd` |
| `C_COUNT` — pink | ![](https://placehold.co/16x16/ff79c6/ff79c6.png) | `#ff79c6` |
| `C_CYAN` — cyan | ![](https://placehold.co/16x16/8be9fd/8be9fd.png) | `#8be9fd` |
| `C_GOLD` — yellow | ![](https://placehold.co/16x16/f1fa8c/f1fa8c.png) | `#f1fa8c` |

---

## Adding your own palette

Open `scripts/install.ps1`, find the `$palettes` hashtable, add a new sub-table with the 10 colour-role keys, and add the name to the `[ValidateSet(...)]` on the `-Palette` parameter near the top of the file.

Each value is a single-quoted `'R G B'` triplet (space-separated integers, 0–255). The 10 role keys (`C_MODEL`, `C_SKILL`, `C_COST`, `C_PROJCST`, `C_ADD`, `C_DEL`, `C_TIME`, `C_COUNT`, `C_CYAN`, `C_GOLD`) are documented inline next to the Sam palette.
