# Freeze Pane Rule

**Mechanical rule:** the freeze pane is set to *one row below the Heading 1 row* and (for periodic sheets) *one column right of the last frozen column*.

| Sheet class | Heading 1 row | Last frozen col | Freeze pane address |
|---|---|---|---|
| cover | n/a | n/a | None (static landing page) |
| static | 6 | A (no col freeze) | `A6` |
| periodic | 11 | I (cols A–I frozen) | `J11` |

Build code does not need a per-sheet freeze-pane spec — it derives the address from `(heading_row, last_frozen_col + 1)`.

## Observed in the template

| Sheet | Class | H1 row | Freeze pane |
|---|---|---|---|
| Cover | cover | — | None |
| Navigator | navigator | row 6 | A6 |
| Style Guide | style_guide | row 6 | A6 |
| Model Parameters | static | row 6 | A6 |
| Timing | periodic | row 11 | J11 |
| Error Checks | static | row 6 | A6 |
| Change Log | static | row 6 | A6 |
| Sam Notes for Model Build | static | row 6 | A6 |
| Timing Template | periodic | row 11 | J11 |
| No Timing Template | static | row 6 | A6 |
