# Column Widths by Sheet Class

Five sheet classes, each with its own width pattern. Column A is universally **3.7** (sheet-margin convention). Unlisted columns use Excel default (~8.43).

Build the workbook by classifying each sheet (cover / navigator / static / periodic / style_guide), then apply the class's widths.

| Class | Reference sheet | Set widths |
|---|---|---|
| cover | Cover | C=3.7 |
| navigator | Navigator | A=3.7, F=17.7 |
| style_guide | Style Guide | A=3.7, F=9.1, H=1.7, I=17.3, J=1.7, K=23.4, L=9.1, N=1.7, O=0.0, P=9.1 |
| static | Model Parameters | A=3.7, F=16.3, G=14.4, H=3.0, I=9.1, S=1.7, T=9.1 |
| periodic | Timing | A=3.7, G=22.1, H=10.7, J=10.7 |

## Why

Width clusters by **purpose**, not by absolute column letter. A periodic sheet's column J holds period values (~10.7 wide); the same letter on Model Parameters is unused. The previous "A=2, B=5, C=3 ..." table treated J as uniform — that's wrong for sheets that don't have period columns.
