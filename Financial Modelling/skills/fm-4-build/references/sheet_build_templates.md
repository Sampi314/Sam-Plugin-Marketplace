# Sheet Build Templates

> Boilerplate pywin32 code for building each standard sheet type. Copy and adapt per model.

## Table of Contents
1. [Universal Header Block](#1-universal-header-block)
2. [Cover Sheet](#2-cover-sheet)
3. [Navigator Sheet](#3-navigator-sheet)
4. [Style Guide Sheet](#4-style-guide-sheet)
5. [Model Parameters Sheet](#5-model-parameters-sheet)
6. [Timing Sheet](#6-timing-sheet)
7. [Periodic Sheet Template](#7-periodic-sheet-template)
8. [Opening Balance Sheet](#8-opening-balance-sheet)
9. [Financial Statement Template](#9-financial-statement-template)
10. [Error Checks Sheet](#10-error-checks-sheet)

---

## 1. Universal Header Block

Apply to EVERY sheet (except Cover). Rows 1–4 are identical everywhere.

```python
def build_header(ws, error_label_cell="B4", error_value_cell="F4"):
    """Rows 1-4: Sheet name, model name, navigator links, error banner."""
    # Row 1 — Sheet tab name
    ws.Range("A1").Formula = (
        '=IF(ISERROR(RIGHT(CELL("filename",A1),'
        'LEN(CELL("filename",A1))-FIND("]",CELL("filename",A1)))),'
        '"",RIGHT(CELL("filename",A1),'
        'LEN(CELL("filename",A1))-FIND("]",CELL("filename",A1))))')
    ws.Range("A1").Style = "Sheet Title"

    # Row 2 — Model name
    ws.Range("A2").Formula = "=Model_Name"
    ws.Range("A2").Style = "Model Name"

    # Row 3 — Navigator links (5 cells)
    for col in ["A", "B", "C", "D", "E"]:
        cell = ws.Range(f"{col}3")
        txt = "Navigator" if col == "A" else "HL_Navigator"
        ws.Hyperlinks.Add(Anchor=cell, Address="",
                          SubAddress="Navigator!A1",
                          TextToDisplay=txt)
        cell.Style = "Hyperlink Text"

    # Row 4 — Error check banner
    ws.Range(error_label_cell).Value = "Error Checks:"
    ws.Range(error_value_cell).Formula = "=Overall_Error_Check"
    ws.Range(error_value_cell).Style = "Error_Checks"
```

## 2. Cover Sheet

```python
def build_cover(wb, params):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = "Cover"

    ws.Range("A3").Value = "Navigator"
    ws.Hyperlinks.Add(Anchor=ws.Range("A3"), Address="",
                      SubAddress="Navigator!A1", TextToDisplay="Navigator")
    ws.Range("A3").Style = "Hyperlink Text"

    ws.Range("C5").Value = params.get("client_name", "")
    ws.Range("C5").Style = "Sheet Title"
    ws.Range("C6").Formula = "=Model_Name"
    ws.Range("C6").Style = "Model Name"

    ws.Range("C14").Value = f"Primary Developer: {params.get('developer', '')}"
    ws.Range("C16").Value = "General Cover Notes:"
    ws.Range("C16").Style = "Heading 2 Text"
    ws.Range("C17").Value = params.get("cover_notes", "")

    ws.Range("C21").Value = "Any queries, please e-mail:"
    ws.Range("G21").Value = params.get("developer", "")
    if params.get("email"):
        ws.Hyperlinks.Add(Anchor=ws.Range("G21"),
                          Address=f"mailto:{params['email']}")
```

## 3. Navigator Sheet

```python
def build_navigator(wb, sheet_names):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = "Navigator"
    build_header(ws, "E4", "G4")

    # Section header
    ws.Range("B7").Value = 1
    ws.Range("B7").Style = "Heading 1 Number"
    ws.Range("C7").Value = "Table of Contents"
    ws.Range("C7").Style = "Heading 1 Text"

    # TOC entries — one per sheet
    for i, name in enumerate(sheet_names):
        row = 9 + i
        cell = ws.Range(f"F{row}")
        cell.Value = name
        # Hyperlink to HL_n named range (created later)
        ws.Hyperlinks.Add(Anchor=cell, Address="",
                          SubAddress=f"'{name}'!A3",
                          TextToDisplay=name)
        cell.Style = "Hyperlink Text"
```

## 4. Style Guide Sheet

```python
def build_style_guide(wb):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = "Style Guide"
    build_header(ws)

    # Section 1: Headers / Dividers
    r = 6
    ws.Range(f"B{r}").Value = 1; ws.Range(f"B{r}").Style = "Heading 1 Number"
    ws.Range(f"C{r}").Value = "Formatting of Headers / Dividers"
    ws.Range(f"C{r}").Style = "Heading 1 Text"

    # Table headers
    r = 8
    for col, label in [("C","Description"), ("I","Display"), ("K","Style Name")]:
        ws.Range(f"{col}{r}").Value = label
        ws.Range(f"{col}{r}").Style = "Table_Heading"

    # Style entries — each style gets 2 rows (description + display)
    styles_list = [
        ("Sheet Title", "Sheet Title", "Sheet Title"),
        ("Model Name", "Model Name", "Model Name"),
        ("Header 1", "Header 1", "Heading 1 Text"),
        # ... continue for all styles
    ]
    # (In practice, enumerate all 30 styles with display examples)
```

## 5. Model Parameters Sheet

```python
def build_model_parameters(wb, params):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = "Model Parameters"
    build_header(ws)

    # Section 1: General
    r = 6; ws.Range(f"B{r}").Value = 1; ws.Range(f"B{r}").Style = "Heading 1 Number"
    ws.Range(f"C{r}").Value = "General"; ws.Range(f"C{r}").Style = "Heading 1 Text"

    ws.Range("C8").Value = "Key inputs"; ws.Range("C8").Style = "Heading 2 Text"
    ws.Range("E12").Value = "Model name"; ws.Range("E12").Style = "Line Calc"
    ws.Range("G12").Formula = (
        '=IF(ISERROR(OR(FIND("[",CELL("filename",A1)),'
        'FIND("]",CELL("filename",A1)))),"",MID(CELL("filename",A1),'
        'FIND("[",CELL("filename",A1))+1,'
        'FIND("]",CELL("filename",A1))-FIND("[",CELL("filename",A1))-1))')
    ws.Range("E13").Value = "Client name"
    ws.Range("G13").Value = params.get("client_name", "")
    ws.Range("G13").Style = "Assumption"

    # Section 2: Technical constants
    r = 16; ws.Range(f"B{r}").Value = 2; ws.Range(f"B{r}").Style = "Heading 1 Number"
    ws.Range(f"C{r}").Value = "General Range Names"; ws.Range(f"C{r}").Style = "Heading 1 Text"

    tech_constants = [
        ("Days in year", 365, "Days_in_Year"),
        ("Months in month", 1, "Months_in_Month"),
        ("Months in quarter", 3, "Months_in_Qtr"),
        ("Months in half yr", 6, "Months_in_Half_Yr"),
        ("Months in year", 12, "Months_in_Year"),
        ("Quarters in year", 4, "Quarters_in_Year"),
        ("Rounding accuracy", 5, "Rounding_Accuracy"),
        ("Very large number", 1e99, "Very_Large_Number"),
        ("Very small number", 1e-8, "Very_Small_Number"),
        ("Thousand", 1000, "Thousand"),
    ]
    r = 20
    for label, value, range_name in tech_constants:
        ws.Range(f"E{r}").Value = label; ws.Range(f"E{r}").Style = "Line Calc"
        ws.Range(f"G{r}").Value = value; ws.Range(f"G{r}").Style = "Parameter"
        ws.Range(f"I{r}").Value = range_name; ws.Range(f"I{r}").Style = "Range Name Description"
        r += 1

    # Section 3: Units
    # ... similar pattern for unit labels
```

## 6. Timing Sheet

See `references/formula_patterns.md` for the complete timing engine. Key structure:

```python
def build_timing(wb, params):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = "Timing"
    build_header(ws)
    set_standard_widths(ws, params["num_periods"])

    # Section 1
    r = 11
    ws.Range(f"B{r}").Value = 1; ws.Range(f"B{r}").Style = "Heading 1 Number"
    ws.Range(f"C{r}").Value = "Timing Assumptions"; ws.Range(f"C{r}").Style = "Heading 1 Text"

    # Inputs with validation
    inputs = [
        (15, "Number of periods", params["num_periods"], "Number_of_Periods", "H15"),
        (17, "Model start date", params["start_date"], "Model_Start_Date", "H17"),
        (19, "Months per period", params["periodicity"], "Periodicity", "H19"),
        (21, "Reporting month", params["reporting_month"], "Example_Reporting_Month", "H21"),
    ]
    for row, label, value, rn, cell_addr in inputs:
        ws.Range(f"D{row}").Value = label; ws.Range(f"D{row}").Style = "Line Calc"
        ws.Range(cell_addr).Value = value; ws.Range(cell_addr).Style = "Assumption"
        ws.Range(f"K{row}").Value = rn; ws.Range(f"K{row}").Style = "Range Name Description"

    # Build timeline rows 5–9 (see formula_patterns.md for formulas)
    build_timeline(ws, params["num_periods"])
```

## 7. Periodic Sheet Template

General Assumptions, Calculations use this common structure:

```python
def build_periodic_sheet(wb, name, params):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = name
    build_header(ws)
    set_standard_widths(ws, params["num_periods"])

    # Mirror timing rows 5–9 from Timing sheet
    first_period_col = 10  # column J
    for r in range(5, 10):
        for c in range(first_period_col, first_period_col + params["num_periods"]):
            ws.Cells(r, c).Formula = f"=Timing!{ws.Cells(r, c).Address(False, False)}"
    # Apply styles to timeline rows
    # Row 5: Date Heading, Rows 6-7: Date, Row 8-9: Line Calc
```

## 8. Opening Balance Sheet

Single-column (column I) with Assumption-styled input cells.

```python
def build_opening_bs(wb, params, bs_items):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = "Opening Balance Sheet"
    build_header(ws)

    r = 13
    ws.Range(f"C{r}").Value = "Current Assets"
    ws.Range(f"C{r}").Style = "Heading 2 Text"

    for item in bs_items["current_assets"]:
        r += 1
        ws.Range(f"D{r}").Value = item["name"]
        ws.Range(f"G{r}").Formula = "=Currency"
        ws.Range(f"G{r}").Style = "Units"
        ws.Range(f"I{r}").Value = item.get("value", 0)
        ws.Range(f"I{r}").Style = "Assumption"
        ws.Range(f"I{r}").NumberFormat = '_(#,##0_);[Red]\\(#,##0\\);_("—"_);'

    # Total row
    r += 1
    ws.Range(f"D{r}").Value = "Total Current Assets"
    ws.Range(f"D{r}").Style = "Line Total"
    # SUM formula for items above
```

## 9. Financial Statement Template

IS, BS, CFS all follow this pattern — links to Calculations only.

```python
def build_financial_statement(wb, name, line_items, params):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = name
    build_header(ws)
    set_standard_widths(ws, params["num_periods"])

    # Mirror timeline rows 5–9
    # ...

    r = 13
    for item in line_items:
        if item["type"] == "heading":
            ws.Range(f"C{r}").Value = item["label"]
            ws.Range(f"C{r}").Style = "Heading 2 Text"
        elif item["type"] == "line":
            ws.Range(f"D{r}").Value = item["label"]
            ws.Range(f"G{r}").Formula = item["unit_formula"]  # e.g., "=Currency"
            ws.Range(f"G{r}").Style = "Units"
            # Link to Calculations
            calc_row = item["calc_row"]
            for c in range(10, 10 + params["num_periods"]):
                col_letter = chr(64 + c) if c <= 26 else chr(64 + c // 26) + chr(64 + c % 26)
                ws.Cells(r, c).Formula = f"=Calculations!{ws.Cells(r,c).Address(False,False).replace(str(r), str(calc_row))}"
                ws.Cells(r, c).Style = "Line Calc"
                ws.Cells(r, c).NumberFormat = '_(#,##0_);[Red]\\(#,##0\\);_("—"_);'
        elif item["type"] == "total":
            ws.Range(f"D{r}").Value = item["label"]
            ws.Range(f"D{r}").Style = "Line Total"
            # SUM or addition of rows above
        r += 1
```

## 10. Error Checks Sheet

```python
def build_error_checks(wb, checks):
    ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = "Error Checks"
    build_header(ws)

    r = 6; ws.Range(f"B{r}").Value = 1; ws.Range(f"B{r}").Style = "Heading 1 Number"
    ws.Range(f"C{r}").Value = "Error Checks"; ws.Range(f"C{r}").Style = "Heading 1 Text"
    ws.Range("C8").Value = "Summary of Errors"; ws.Range("C8").Style = "Heading 2 Text"

    r = 12
    for check in checks:
        ws.Range(f"E{r}").Value = check["description"]
        ws.Range(f"I{r}").Formula = check["formula"]  # e.g., "=HL_BS_Errors"
        ws.Range(f"I{r}").Style = "Error_Checks"
        # Hyperlink to source
        ws.Hyperlinks.Add(Anchor=ws.Range(f"E{r}"), Address="",
                          SubAddress=check["link_target"],
                          TextToDisplay=check["description"])
        r += 1

    # Summary row
    r += 2
    ws.Range(f"E{r}").Value = "Summary of Errors"
    ws.Range(f"E{r}").Style = "Line Total"
    ws.Range(f"I{r}").Formula = f"=SUM(I12:I{r-2})"
    ws.Range(f"I{r}").Style = "Error_Checks"
    # This cell becomes Overall_Error_Check named range

    # Apply CF to all error check cells
    add_error_check_cf(ws, f"I12:I{r}")
```
