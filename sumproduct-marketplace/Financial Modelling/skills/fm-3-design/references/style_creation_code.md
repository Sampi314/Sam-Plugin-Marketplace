# Cell Style Creation Code

This file contains the canonical pywin32 code for creating all 30 SumProduct
Cell Styles in a workbook. Used by fm-3-design (Phase 3) and fm-4-build
(Phase 4).

## Usage

Call `create_all_styles(wb)` **before** any sheet content is built. Once the
styles are registered on the workbook, they appear in Home → Cell Styles →
Custom and can be applied to any cell with `cell.Style = "Style Name"`.

The function uses `wb.Styles.Add(...)` which creates **true Excel Cell Styles**
(visible in the Cell Styles gallery), not direct formatting.

## Function

```python
def create_all_styles(wb):
    """Create all SumProduct Cell Styles in the workbook.
    Must be called BEFORE any sheet content is built.
    Uses wb.Styles.Add() which creates TRUE Excel Cell Styles
    visible in Home → Cell Styles → Custom.
    """

    # --- SECTION A: Headers & Dividers ---

    s = wb.Styles.Add("Sheet Title")
    s.Font.Name = "Calibri"; s.Font.Size = 14
    s.Font.Bold = True; s.Font.Color = 0x663300  # dark blue BGR
    s.Interior.Pattern = -4142  # xlNone
    s.IncludeNumber = False

    s = wb.Styles.Add("Model Name")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Bold = False; s.Font.Color = 0x663300
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Heading 1 Text")
    s.Font.Name = "Calibri"; s.Font.Size = 11
    s.Font.Bold = True; s.Font.Color = 0xFFFFFF  # white
    s.Interior.Color = 0x663300; s.Interior.Pattern = 1  # dark blue, xlSolid
    s.IncludeNumber = False

    s = wb.Styles.Add("Heading 1 Number")
    s.Font.Name = "Calibri"; s.Font.Size = 11
    s.Font.Bold = True; s.Font.Color = 0xFFFFFF
    s.Interior.Color = 0x663300; s.Interior.Pattern = 1
    s.IncludeNumber = True; s.NumberFormat = '#,##0"."'

    s = wb.Styles.Add("Heading 2 Text")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Bold = True; s.Font.Color = 0x663300
    s.Interior.Pattern = -4142
    s.Borders(9).LineStyle = 1; s.Borders(9).Weight = 2  # bottom thin
    s.IncludeNumber = False

    s = wb.Styles.Add("Heading 3 Text")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Bold = True; s.Font.Color = 0x000000
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Table_Heading")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Bold = True; s.Font.Color = 0xFFFFFF
    s.Interior.Color = 0xC47244; s.Interior.Pattern = 1  # medium blue BGR
    s.IncludeNumber = False

    s = wb.Styles.Add("Date Heading")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Bold = True; s.Font.Color = 0x000000
    s.Interior.Pattern = -4142
    s.IncludeNumber = True; s.NumberFormat = 'mmm yy'

    # --- SECTION B: Individual Cell Styles ---

    s = wb.Styles.Add("Accounts Ref")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x808080  # grey
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Assumption")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Color = 0x99FFFF; s.Interior.Pattern = 1  # light yellow BGR
    s.IncludeNumber = False  # CRITICAL: don't override number format

    s = wb.Styles.Add("Constraint")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x808080
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Date")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Pattern = -4142
    s.IncludeNumber = True; s.NumberFormat = '[$-C09]d mmm yy;@'

    s = wb.Styles.Add("Empty")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Error_Checks")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Interior.Pattern = -4142
    s.IncludeNumber = True; s.NumberFormat = '"ý";"ý";"þ"'

    s = wb.Styles.Add("Hyperlink Text")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Bold = True; s.Font.Color = 0xC10563  # blue BGR
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Internal Ref")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Color = 0xDAEFE2; s.Interior.Pattern = 1  # light green BGR
    s.IncludeNumber = False

    s = wb.Styles.Add("Line Calc")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Line Total")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Pattern = -4142
    s.Borders(8).LineStyle = 1; s.Borders(8).Weight = 2  # top thin border
    s.IncludeNumber = False

    s = wb.Styles.Add("Notes")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x0000FF  # red BGR
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Numbers 0")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Pattern = -4142
    s.IncludeNumber = True
    s.NumberFormat = '_(#,##0_);[Red]\\(#,##0\\);_("—"_);'

    s = wb.Styles.Add("Parameter")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Color = 0xD9D9D9; s.Interior.Pattern = 1  # light grey
    s.IncludeNumber = False

    s = wb.Styles.Add("Range Name Description")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0xC10563  # blue
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("Right Currency")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Pattern = -4142
    s.IncludeNumber = True
    s.NumberFormat = '"$"* _(#,##0.00_);"$"* \\(#,##0.00\\);"$"* _("—"_.00)'
    s.HorizontalAlignment = -4152  # xlRight

    s = wb.Styles.Add("Right Number")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Pattern = -4142
    s.IncludeNumber = True
    s.NumberFormat = '_(#,##0.00_);[Red]\\(#,##0.00\\);_("—"_.00);'
    s.HorizontalAlignment = -4152

    s = wb.Styles.Add("Row Ref")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x808080  # grey
    s.Interior.Color = 0xF2F2F2; s.Interior.Pattern = 1
    s.IncludeNumber = True; s.NumberFormat = '"Row "###0'

    s = wb.Styles.Add("Row_Summary")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x000000
    s.Interior.Color = 0xF2F2F2; s.Interior.Pattern = 1
    s.IncludeNumber = True
    s.NumberFormat = '_-* #,##0_-;\\-* #,##0_-;_-* "-"_-;_-@_-'

    s = wb.Styles.Add("Units")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x808080
    s.Interior.Pattern = -4142
    s.IncludeNumber = False

    s = wb.Styles.Add("WIP")
    s.Font.Name = "Calibri"; s.Font.Size = 10
    s.Font.Color = 0x1D7DED  # orange BGR
    s.Interior.Color = 0xCCF2FF; s.Interior.Pattern = 1  # light orange BGR
    s.IncludeNumber = False
```

## Style Application Rules

| Cell Purpose | Style to Apply | Number Format (set separately) |
|-------------|---------------|-------------------------------|
| Row A1 (sheet name) | `Sheet Title` | General |
| Row A2 (model name) | `Model Name` | General |
| Navigator links (A3:E3) | `Hyperlink Text` | General |
| Section number (col B) | `Heading 1 Number` | `#,##0"."` (built into style) |
| Section title (col C+) | `Heading 1 Text` | General |
| Sub-section heading | `Heading 2 Text` | General |
| Sub-sub heading | `Heading 3 Text` | General |
| User input cells | `Assumption` | Set per context (%, $, #, dates) |
| Internal parameter | `Parameter` | Per context |
| Cross-sheet link | `Internal Ref` | Per context |
| Formula calculation | `Line Calc` | Per context (usually Numbers 0) |
| Subtotal / total | `Line Total` | Per context |
| Units column (G) | `Units` | General |
| Row ref column (H) | `Row Ref` | `"Row "###0` (built into style) |
| Error check cells | `Error_Checks` | `"ý";"ý";"þ"` (built into style) |
| Date headers (row 5) | `Date Heading` | `mmm yy` (built into style) |
| Date values (rows 6-7) | `Date` | `[$-C09]d mmm yy;@` (built into style) |
| Developer notes | `Notes` | General |
| WIP placeholders | `WIP` | General |
| Table column headers | `Table_Heading` | General |
| Named range labels (col I) | `Range Name Description` | General |
| Summary values (col I) | `Row_Summary` | Built into style |

## The Assumption-Style Trap

`Assumption` style has `IncludeNumber = False`. Applying the style does NOT
change the number format. You must set the number format separately **after**
applying the style:

```python
cell = ws.Range("J17")
cell.Style = "Assumption"           # yellow fill, keeps existing number format
cell.NumberFormat = '0%'             # THEN set the number format
```
