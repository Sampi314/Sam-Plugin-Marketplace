# Heading Staircase Pattern

Headings step **one column right** and **two rows down** at each level. The heading 1 row is the first scrollable row after the freeze pane (`row 6` static, `row 11` periodic — see `freeze_pane_rule.md`).

```
Row N        B = Heading 1 Number   (formula =MAX($B$prev:$B[N-1])+1)
             C..end = Heading 1 Text  (band — see heading_1_band.md)

Row N+2      C = Heading 2 Text     (one column right, one blank spacer row above)
             continues to band end

Row N+4      D or E = Heading 3 Text  (one more column right)
```

- The `Heading N Number` style only appears on Heading 1 — it auto-numbers section numbers via `=MAX`.
- Heading 2 and Heading 3 omit the number column.

## Inter-section spacing

Between the last data row of one Heading 1 section and the start of the next, leave **two blank rows**. So if Section 1 ends at row M, Section 2's Heading 1 row is at row M+3.

```
Row M        Section 1 last content row
Row M+1      blank
Row M+2      blank
Row M+3      Section 2 Heading 1
```

This applies whether or not Section 1 used Heading 2 / Heading 3 sub-levels — the spacer is between Heading 1 sections only.
