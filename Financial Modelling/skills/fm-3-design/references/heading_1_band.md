# Heading 1 Cover Area (Band Length Rule)

**Rule:** `Heading 1 Text` style is applied from column **B** to the **sheet's last-used column + 1**.

The band extends one cell past the rightmost data column to give the heading a visual buffer at the right edge.

## Build order constraint

Because the rule depends on `worksheet.dimensions`, the band must be styled **after** the sheet's data is populated — not during the initial style-application pass. This is the one exception to the IncludeNumber "styles first" rule from `style_creation_code.md`.

## Observed in the template

| Sheet | Last col | H1 band end |
|---|---|---|
| Navigator | L | L |
| Style Guide | N | M |
| Model Parameters | R | R |
| Timing | O | O |
| Error Checks | K | K |
| Change Log | L | L |
| Sam Notes for Model Build | L | L |
| Timing Template | O | O |
| No Timing Template | O | O |
