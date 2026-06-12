# SumProduct Cell Style Register

Extracted from the canonical template by `scripts/extract_from_template.py`.
Total styles: **41**.

## Tick state legend

Six characters: **F**ont · Fi**l**l · **B**order · **A**lignment · **P**rotection · **N**umberFormat.
`Y` = style overrides this property group when applied. `.` = the property is inherited from the cell's prior state.

## Classification

- **Format** — applyNumberFormat only; for Pass 1 of two-pass application.
- **Visual** — fill/border only; for Pass 2 (preserves number format from Pass 1).
- **Combined** — applies both format and visual; cannot be layered.
- **Heading** / **Hyperlink** — structural styles for fixed positions.

See `style_application_matrix.md` for which style goes on which cell.

## Register

| Style Name | Class | FlBAPN | Font | Fill | Border | Number Format |
|---|---|---|---|---|---|---|
| Accounts Ref | Other | Y..... | Calibri 11 I theme0 | none | — | General |
| Assumption | Visual | YYY.Y. | Arial 9 theme8 | solid #FFFF99 | T=thin,B=thin,L=thin,R=thin | General |
| Comma | Format | Y....Y | Calibri 11 theme1 | none | — | _(#,##0.00_);\(#,##0.00\);_(\-_._0_0_) |
| Comma [0] | Format | Y....Y | Calibri 11 theme1 | none | — | _(#,##0_);\(#,##0\);_(\-_) |
| Constraint | Visual | Y.YY.. | Arial 9 theme0 | none | T=thin,B=thin,L=thin,R=thin | General |
| Currency | Format | Y....Y | Calibri 11 theme1 | none | — | _-"$"* #,##0.00_-;\-"$"* #,##0.00_-;_-"$"* "-"??_-;_-@_- |
| Currency [0] | Format | Y....Y | Calibri 11 theme1 | none | — | _-"$"* #,##0_-;\-"$"* #,##0_-;_-"$"* "-"_-;_-@_- |
| Date | Format | Y..Y.Y | Arial 9 theme1 | none | — | [$-C09]d\ mmm\ yy;@ |
| Date Heading | Heading | Y..Y.Y | Arial 9 B theme1 | none | — | mmm\ yy |
| Empty | Combined | YYY..Y | Calibri 11 theme1 | gray125 theme8 | T=thin,B=thin,L=thin,R=thin | ;;; |
| Error_Checks | Combined | YYYYYY | Wingdings 11 theme0 | solid theme6 | T=thin,B=thin,L=thin,R=thin | "ý";"ý";"þ" |
| Heading 1 | Heading | Y.Y... | Arial 15 B theme3 | none | B=thick | General |
| Heading 1 Number | Heading | YYY..Y | Arial 12 B theme0 | solid theme1 | B=thick | #,##0. |
| Heading 1 Text | Heading | YYY... | Arial 12 B theme0 | solid theme1 | B=thick | General |
| Heading 2 | Heading | Y.Y... | Arial 13 B theme3 | none | B=thick | General |
| Heading 2 Text | Heading | Y..... | Arial 13 B theme8 | none | — | General |
| Heading 3 | Heading | Y.Y... | Arial 11 B theme3 | none | B=medium | General |
| Heading 3 Text | Heading | Y..... | Arial 11 B theme1 | none | — | General |
| Heading 4 | Heading | Y..... | Arial 11 B theme3 | none | — | General |
| Hyperlink | Hyperlink | Y..YY. | Arial 9 B U theme1 | none | — | General |
| Hyperlink Text | Hyperlink | Y..YY. | Arial 8 B U | none | — | General |
| Internal Ref | Combined | YYY..Y | Arial 9 | solid theme0 | T=thin,B=thin,L=thin,R=thin | _-* #,##0_-;\-* #,##0_-;_-* "-"_-;_-@_- |
| Line Calc | Combined | Y.Y..Y | Calibri 11 theme1 | none | T=dotted | _-* #,##0_-;\-* #,##0_-;_-* "-"_-;_-@_- |
| Line Total | Combined | Y.Y..Y | Calibri 11 theme1 | none | T=thin | _(#,##0_);[Red]\(#,##0\);_(\-_); |
| Model Name | Other | Y..... | Arial 14 theme8 | none | — | General |
| Normal | Other | ...... | Arial 9 theme1 | none | — | General |
| Notes | Visual | Y.Y... | Arial 8 I #FF0000 | none | T=thin,B=thin,L=thin,R=thin | General |
| Numbers 0 | Format | Y....Y | Calibri 11 theme1 | none | — | _(#,##0_);[Red]\(#,##0\);_(\-_) |
| Parameter | Visual | YYY... | Arial 9 theme0 | solid theme8 | T=thin,B=thin,L=thin,R=thin | General |
| Per cent | Format | Y....Y | Calibri 11 theme1 | none | — | 0% |
| Range Name Description | Other | Y..... | Calibri 11 I theme0 | none | — | General |
| Right Currency | Format | Y..Y.Y | Arial 8 | none | — | _("$"#,##0.0_);\("$"#,##0.0\);_("-"_) |
| Right Number | Format | Y..Y.Y | Arial 8 | none | — | _(#,##0.0_);\(#,##0.0\);_("-"_) |
| Row Ref | Combined | YYYY.Y | Arial 9 I theme8 | solid theme8 | T=thin,B=thin,L=thin,R=thin | "Row "###0 |
| Row_Summary | Combined | YYY..Y | Calibri 11 | solid theme0 | T=thin,B=thin,L=thin,R=thin | _-* #,##0_-;\-* #,##0_-;_-* "-"_-;_-@_- |
| Sheet Title | Heading | Y..... | Arial 16 B theme8 | none | — | General |
| Table_Heading | Heading | YY.Y.. | Arial 9 B theme0 | solid theme1 | — | General |
| Title | Heading | Y..... | Arial 18 theme3 | none | — | General |
| Total | Visual | Y.Y... | Arial 11 B theme1 | none | T=thin,B=double | General |
| Units | Other | Y..... | Arial 9 theme8 | none | — | General |
| WIP | Visual | YYY.Y. | Arial 9 #FF0000 | solid #FFFF00 | T=thin,B=thin,L=thin,R=thin | General |
