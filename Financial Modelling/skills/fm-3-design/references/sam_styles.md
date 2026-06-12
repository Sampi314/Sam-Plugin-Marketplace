# Sam Cell Styles Reference

> Extracted from production Sam models (16_-sp-case-study-final-model.xlsm, Model_13_-_Financial_Modelling_Exercise_Final.xlsm) and verified against the Excel Cell Styles gallery screenshot.

## Excel Cell Styles Gallery (Custom Section)

The following 30 styles appear in Home → Cell Styles → Custom in every Sam model:

```
Row 1: Accounts Ref | Assumption | Constraint | Date | Date Heading | Empty
Row 2: Heading 1 Number | Heading 1 Text | Heading 2 Text | Heading 3 Text | Hyperlink Text
Row 3: Internal Ref | Line Calc | Line Total | Model Name | Notes | Numbers 0
Row 4: Parameter | Range Name Description | Right Currency | Right Number | Row Ref | Row_Summary
Row 5: Sheet Title | Table_Heading | Units | WIP
Row 6: Heading 1 Number (duplicate display — same as Row 2)
```

## Complete Style Definitions

### A. Headers & Dividers

| # | Style Name | Font | Size | Bold | Font Colour (RGB) | Font Colour (BGR) | Fill Colour (RGB) | Fill Colour (BGR) | Borders | Number Format | IncludeNumber |
|---|-----------|------|------|------|-------------------|-------------------|-------------------|-------------------|---------|--------------|---------------|
| 1 | Sheet Title | Calibri | 14 | Yes | #003366 | 0x663300 | None | -4142 | None | General | False |
| 2 | Model Name | Calibri | 10 | No | #003366 | 0x663300 | None | -4142 | None | General | False |
| 3 | Heading 1 Text | Calibri | 11 | Yes | #FFFFFF | 0xFFFFFF | #003366 | 0x663300 | None | General | False |
| 4 | Heading 1 Number | Calibri | 11 | Yes | #FFFFFF | 0xFFFFFF | #003366 | 0x663300 | None | `#,##0"."` | True |
| 5 | Heading 2 Text | Calibri | 10 | Yes | #003366 | 0x663300 | None | -4142 | Bottom thin | General | False |
| 6 | Heading 3 Text | Calibri | 10 | Yes | #000000 | 0x000000 | None | -4142 | None | General | False |
| 7 | Table_Heading | Calibri | 10 | Yes | #FFFFFF | 0xFFFFFF | #4472C4 | 0xC47244 | None | General | False |
| 8 | Date Heading | Calibri | 10 | Yes | #000000 | 0x000000 | None | -4142 | None | `mmm yy` | True |

### B. Individual Cell Styles

| # | Style Name | Font | Size | Bold | Font Colour (RGB) | Font Colour (BGR) | Fill Colour (RGB) | Fill Colour (BGR) | Borders | Number Format | IncludeNumber |
|---|-----------|------|------|------|-------------------|-------------------|-------------------|-------------------|---------|--------------|---------------|
| 9 | Accounts Ref | Calibri | 10 | No | #808080 | 0x808080 | None | -4142 | None | General | False |
| 10 | Assumption | Calibri | 10 | No | #000000 | 0x000000 | #FFFF99 | 0x99FFFF | None | — | **False** |
| 11 | Constraint | Calibri | 10 | No | #808080 | 0x808080 | None | -4142 | None | General | False |
| 12 | Date | Calibri | 10 | No | #000000 | 0x000000 | None | -4142 | None | `[$-C09]d mmm yy;@` | True |
| 13 | Empty | Calibri | 10 | No | #000000 | 0x000000 | None | -4142 | None | General | False |
| 14 | Error_Checks | Calibri | 10 | No | (CF-driven) | — | (CF-driven) | — | None | `"ý";"ý";"þ"` | True |
| 15 | Hyperlink Text | Calibri | 10 | Yes | #0563C1 | 0xC10563 | None | -4142 | None | General | False |
| 16 | Internal Ref | Calibri | 10 | No | #000000 | 0x000000 | #E2EFDA | 0xDAEFE2 | None | — | False |
| 17 | Line Calc | Calibri | 10 | No | #000000 | 0x000000 | None | -4142 | None | — | False |
| 18 | Line Total | Calibri | 10 | No | #000000 | 0x000000 | None | -4142 | Top thin | — | False |
| 19 | Notes | Calibri | 10 | No | #FF0000 | 0x0000FF | None | -4142 | None | General | False |
| 20 | Numbers 0 | Calibri | 10 | No | #000000 | 0x000000 | None | -4142 | None | `_(#,##0_);[Red]\(#,##0\);_("—"_);` | True |
| 21 | Parameter | Calibri | 10 | No | #000000 | 0x000000 | #D9D9D9 | 0xD9D9D9 | None | — | False |
| 22 | Range Name Description | Calibri | 10 | No | #0563C1 | 0xC10563 | None | -4142 | None | General | False |
| 23 | Right Currency | Calibri | 10 | No | #000000 | 0x000000 | None | -4142 | None | `"$"* _(#,##0.00_);"$"* \(#,##0.00\);"$"* _("—"_.00)` | True |
| 24 | Right Number | Calibri | 10 | No | #000000 | 0x000000 | None | -4142 | None | `_(#,##0.00_);[Red]\(#,##0.00\);_("—"_.00);` | True |
| 25 | Row Ref | Calibri | 10 | No | #808080 | 0x808080 | #F2F2F2 | 0xF2F2F2 | None | `"Row "###0` | True |
| 26 | Row_Summary | Calibri | 10 | No | #000000 | 0x000000 | #F2F2F2 | 0xF2F2F2 | None | `_-* #,##0_-;\-* #,##0_-;_-* "-"_-;_-@_-` | True |
| 27 | Units | Calibri | 10 | No | #808080 | 0x808080 | None | -4142 | None | General | False |
| 28 | WIP | Calibri | 10 | No | #ED7D31 | 0x1D7DED | #FFF2CC | 0xCCF2FF | None | General | False |

### C. Additional Standard Styles (Modified)

| # | Style Name | Notes |
|---|-----------|-------|
| 29 | Comma | Standard Excel, used for 2dp numbers |
| 30 | Comma [0] | Standard Excel, modified to show negatives in red brackets |
| 31 | Currency | Standard Excel currency format |
| 32 | Currency [0] | Standard Excel, whole-number currency |
| 33 | Percent | Standard Excel percentage |

## Critical Notes

### IncludeNumber = False
Styles with `IncludeNumber = False` do **not** override the cell's existing number format when applied. This is intentional — it allows `Assumption` style (yellow fill) to be applied to cells regardless of whether they hold percentages, dates, currencies, or integers. The number format is set **separately** after applying the style.

### BGR Colour Format
pywin32 uses **BGR** byte order (Blue-Green-Red), not RGB. To convert:
- RGB `#003366` → swap bytes → BGR `0x663300`
- RGB `#FFFF99` → BGR `0x99FFFF`
- RGB `#E2EFDA` → BGR `0xDAEFE2`

### Error_Checks Special Format
The number format `"ý";"ý";"þ"` uses Wingdings characters:
- Positive value → displays `ý` (tick ✓)
- Negative value → displays `ý` (tick ✓) 
- Zero → displays `þ` (cross ✗)

Wait — this is reversed in Sam's convention. The format shows:
- **0 → tick (pass)** via the third format segment
- **Non-zero → cross (fail)** via the first/second segments

The actual rendering depends on the font being Wingdings, which is set via Conditional Formatting (green fill for 0, red fill for non-zero).

### Line Calc vs Line Total
Both have no fill, but `Line Total` has a **top thin border** to visually separate subtotals from detail rows.

### Style Application Order
1. Apply the Cell Style first (sets font, fill, borders)
2. Then set the number format separately (if the style has `IncludeNumber = False`)
3. Then apply any conditional formatting on top

### Heading Row Application
For a section heading row (e.g., row 11):
```python
ws.Range(f"B{r}").Style = "Heading 1 Number"   # section number
ws.Range(f"C{r}:I{r}").Style = "Heading 1 Text" # title spans C to I
# Period columns in the heading row also get Heading 1 Text
ws.Range(f"J{r}:AC{r}").Style = "Heading 1 Text"
```
