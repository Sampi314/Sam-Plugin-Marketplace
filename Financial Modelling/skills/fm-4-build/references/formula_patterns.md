# Formula Patterns Reference

## Table of Contents
1. [Timing Engine](#1-timing-engine)
2. [Sheet Header Block](#2-sheet-header-block)
3. [Section Numbering](#3-section-numbering)
4. [General Assumptions Patterns](#4-general-assumptions-patterns)
5. [Calculations Patterns](#5-calculations-patterns)
6. [Control Account Pattern](#6-control-account-pattern)
7. [Financial Statement Wiring](#7-financial-statement-wiring)
8. [Error Check System](#8-error-check-system)
9. [Conditional Formatting Rules](#9-conditional-formatting-rules)
10. [Formula Audit Column](#10-formula-audit-column)
11. [Common Formula Techniques](#11-common-formula-techniques)
12. [Opening Balance Sheet Patterns](#12-opening-balance-sheet-patterns)
13. [Lookup Sheet Patterns](#13-lookup-sheet-patterns)

---

## 1. Timing Engine

The Timing sheet drives ALL period calculations. It must be built first.

### Key Inputs (with data validation)

```
H15: Number_of_Periods (e.g. 20) — validated list 5-20
H17: Model_Start_Date (e.g. 1-Jul-2024) — date input
H19: Periodicity (e.g. 12 for annual) — validated list: 1,2,3,4,6,12
H21: Example_Reporting_Month (e.g. 6 for June) — validated list: 1-12
H23: Reporting_Month_Factor — derived: =MOD(Example_Reporting_Month, Periodicity)
```

### Timeline Row Formulas (Rows 5–9, starting at column J)

These formulas are placed on the Timing sheet, then referenced by all periodic sheets.

**pywin32 Pattern:**
```python
def build_timeline(ws, num_periods, start_col=10):
    """Build rows 5-9 on the Timing sheet.
    start_col=10 means column J (1-indexed).
    """
    j = start_col  # first period column number

    for p in range(num_periods):
        c = j + p   # current column number

        if p == 0:
            # Row 5 — First period end date
            ws.Cells(5, c).Formula = (
                '=EOMONTH(Model_Start_Date,'
                'MOD(Periodicity+Reporting_Month_Factor'
                '-MONTH(Model_Start_Date),Periodicity))'
            )
            # Row 6 — First start date
            ws.Cells(6, c).Formula = '=Model_Start_Date'
        else:
            # Row 5 — Subsequent end dates
            ws.Cells(5, c).Formula = f'=EOMONTH({ws.Cells(5, c-1).Address},Periodicity)'
            # Row 6 — Subsequent start dates
            ws.Cells(6, c).Formula = f'={ws.Cells(7, c-1).Address}+1'

        # Row 7 — End date (= row 5)
        ws.Cells(7, c).Formula = f'={ws.Cells(5, c).Address}'
        # Row 8 — Days in period
        ws.Cells(8, c).Formula = f'={ws.Cells(7, c).Address}-{ws.Cells(6, c).Address}+1'
        # Row 9 — Counter
        ws.Cells(9, c).Formula = f'=N({ws.Cells(9, c-1).Address})+1'

    # Apply styles
    for p in range(num_periods):
        c = j + p
        ws.Cells(5, c).Style = "Date Heading"
        ws.Cells(6, c).Style = "Date"
        ws.Cells(7, c).Style = "Date"
        ws.Cells(8, c).NumberFormat = '#,##0'
        ws.Cells(9, c).NumberFormat = '#,##0'
```

```excel
' Row 5 — Period End Dates (Date Heading style, mmm yy)
' First period:
J5 = EOMONTH(Model_Start_Date, MOD(Periodicity + Reporting_Month_Factor - MONTH(Model_Start_Date), Periodicity))
' Subsequent periods (K5 onwards):
K5 = EOMONTH(J5, Periodicity)

' Row 6 — Start Dates (Date style)
J6 = Model_Start_Date
K6 = J7 + 1    (i.e., day after previous end date)

' Row 7 — End Dates (Date style)
J7 = J5         (same as heading date in row 5)
K7 = K5

' Row 8 — Number of Days
J8 = J7 - J6 + 1
K8 = K7 - K6 + 1

' Row 9 — Counter (1, 2, 3, ...)
J9 = N(I9) + 1
K9 = N(J9) + 1
```

### Referencing Timing from Other Sheets

All periodic sheets mirror the Timing rows 5–9 by referencing directly:
```excel
' On General Assumptions, Calculations, Income Statement, etc:
J5 = Timing!J5    (or use a shared formula / dynamic array spill)
J6 = Timing!J6
J7 = Timing!J7
J8 = Timing!J8
J9 = Timing!J9
```

For dynamic arrays: the first cell (J5) can contain an array formula that spills across all periods. Subsequent cells show `=` (spill continuation).

---

## 2. Sheet Header Block

EVERY sheet (except Cover) uses this template for rows 1-4:

**pywin32 Pattern:**
```python
def build_sheet_header(ws, wb):
    """Apply the standard header block (rows 1-4) to any sheet."""
    # A1 — Sheet tab name formula
    ws.Range("A1").Formula = (
        '=IF(ISERROR(RIGHT(CELL("filename",A1),'
        'LEN(CELL("filename",A1))-FIND("]",CELL("filename",A1)))),'
        '"",RIGHT(CELL("filename",A1),'
        'LEN(CELL("filename",A1))-FIND("]",CELL("filename",A1))))'
    )
    ws.Range("A1").Style = "Sheet Title"

    # A2 — Model name
    ws.Range("A2").Formula = "=Model_Name"
    ws.Range("A2").Style = "Model Name"

    # A3:E3 — Navigator links
    add_nav_row(ws)

    # Row 4 — Error check banner
    add_error_banner(ws)
```

```excel
' A1 — Sheet tab name (auto-detected from filename)
A1 = IF(ISERROR(RIGHT(CELL("filename",A1), LEN(CELL("filename",A1)) - FIND("]",CELL("filename",A1)))), "", RIGHT(CELL("filename",A1), LEN(CELL("filename",A1)) - FIND("]",CELL("filename",A1))))

' A2 — Model name
A2 = Model_Name

' A3:E3 — Navigator links (all 5 cells)
A3 = "Navigator"  (with hyperlink to HL_Navigator)
B3 = "HL_Navigator" (with hyperlink to HL_Navigator)
C3 = "HL_Navigator" (with hyperlink to HL_Navigator)
D3 = "HL_Navigator" (with hyperlink to HL_Navigator)
E3 = "HL_Navigator" (with hyperlink to HL_Navigator)

' Row 4 — Error check banner
' Position varies slightly (B4 or E4 for label, F4 or G4 for value)
{Label cell} = "Error Checks:"
{Value cell} = Overall_Error_Check
' Apply Error_Checks style and conditional formatting to value cell
```

Apply styles:
- A1 → `Sheet Title`
- A2 → `Model Name`
- A3:E3 → `Hyperlink Text`
- Error check value → `Error_Checks` with conditional formatting

---

## 3. Section Numbering

Sections use auto-incrementing numbers in column B:

```excel
' First section (e.g. B11)
B11 = MAX($B$10:$B10) + 1    → returns 1

' Second section (e.g. B35)
B35 = MAX($B$10:$B34) + 1    → returns 2

' Section title in column C references sheet name
C11 = A1    (displays the sheet tab name as section title)
```

Apply `Heading 1 Number` to column B, `Heading 1 Text` to remaining cells in the heading row.

---

## 4. General Assumptions Patterns

### Structure
Assumptions are grouped by business area with consistent sub-structure:

```
Section Header (Heading 1): "1. [Sheet Name]"
  Sub-header (Heading 2): "Revenue and related"
    Group (Heading 3): "Sales"
      Row: "Projected sales"    | Units: =Unit     | J: [input values...]
      Row: "Unit price"         | Units: =Currency  | J: [input value]
      Row: "Inflation"          | Units: =Percentage | J: [input values...]
    Group: "Working capital"
      Row: "Days receivable"    | Units: =No._of_days | J: [input values...]
```

### Formula Conventions
- **Static inputs**: Hardcoded values in yellow cells with `Assumption` style
- **Uniform across periods**: Same value every period, entered once, then the formula references it
- **Period-varying inputs**: Different value per period, all yellow
- **Units column (G)**: Always references a named range (=Currency, =Unit, =Percentage, etc.)
- **Opening balance** (column I, one period before J): For items needing a starting value, place it one column to the left of the first period, with date label = `Model_Start_Date - 1`

---

## 5. Calculations Patterns

### Mirror Structure from Assumptions
The Calculations sheet mirrors General Assumptions structure exactly. Row labels are LINKED, not retyped:

```excel
' Link labels from General Assumptions
C13 = 'General Assumptions'!C13
D15 = 'General Assumptions'!D15
E17 = 'General Assumptions'!E17
G17 = =Unit    (units column still uses named ranges)
```

### Bringing Forward Assumptions
Input values from General Assumptions are linked (not re-entered):
```excel
' Direct reference for assumptions
J17 = 'General Assumptions'!J17    (or array formula that spills)
J18 = 'General Assumptions'!J18
```

### Calculations Add New Derived Rows
After bringing in assumptions, Calculations adds intermediate results:

```excel
' Example: Price per unit (inflated)
E21 = "Price per unit"
G21 = =Currency
J21 = J18 * (1 + J19)    ' base price × (1 + inflation)

' Example: Revenue
E23 = "Revenue"
G23 = =Currency  
J23 = J17 * J21           ' units × price per unit
```

### Row References (Column H)
When a calculation refers to a specific row, use a row reference:
```excel
H45 = "Row "&ROW(J23)    ' Shows "Row 23" — tells the user this line references row 23
```
Apply `Row Ref` style.

---

## 6. Control Account Pattern

SumProduct uses a standard control account for every balance sheet item:

```
Opening balance
+ Additions (revenue, purchases, etc.)
- Deductions (cash receipts, depreciation, etc.)
= Closing balance
```

### Formula Pattern

```excel
' Working Capital example: Trade Receivables
E35 = "Opening receivables"     | J35 = I38    (closing of prior = opening of current)
E36 = "Revenue"                 | J36 = J23    (links to Revenue calc row)
E37 = "Cash receipts"           | J37 = J38 - J35 - J36   (balancing figure = Closing - Opening - Revenue)
E38 = "Closing receivables"     | J38 = J23 * J27 / J29   (Revenue × Days receivable / Days in period)

' For the FIRST period (column J):
' Opening = Opening Balance Sheet value
I38 = 'Opening Balance Sheet'!$I$15
J35 = I38    ' first period opening = opening BS value
```

### The Balancing Figure Trick
The "cash" or "movement" line is always derived as:
```
Cash movement = Closing - Opening - Non-cash movements
```
This ensures the control account ALWAYS balances by construction.

---

## 7. Financial Statement Wiring

Financial statement sheets contain **LINKS ONLY** — no new calculations.

### Income Statement
```excel
D13 = "Revenue"          | J13 = Calculations!J23      ' Revenue
D14 = "COGS"             | J14 = Calculations!J49      ' COGS (negative)
D15 = "Gross profit"     | J15 = J13 + J14             ' Sum (only exception: subtotals)
D17 = "Wastage"          | J17 = Calculations!J138     ' Wastage
D18 = "Operating exp"    | J18 = Calculations!J173     ' OpEx (negative)
D19 = "EBITDA"           | J19 = J15 + J17 + J18       ' Subtotal
D21 = "Depreciation"     | J21 = Calculations!J211     ' Depreciation (negative)
D22 = "EBIT"             | J22 = J19 + J21             ' Subtotal
D24 = "Interest expense" | J24 = Calculations!J253     ' Interest (negative)
D25 = "NPBT"             | J25 = J22 + J24             ' Subtotal
D27 = "Tax expense"      | J27 = Calculations!J276     ' Tax (negative)
D28 = "NPAT"             | J28 = J25 + J27             ' Bottom line
```

### Balance Sheet
All items linked from Calculations closing balance rows:
```excel
' Current Assets
D14 = "Cash"              | J14 = Calculations!J373    ' Closing cash
D15 = "Trade receivables" | J15 = Calculations!J38     ' Closing receivables
D16 = "Inventory"         | J16 = Calculations!J128    ' Closing inventory

' Labels linked from Opening BS
D14 = 'Opening Balance Sheet'!D14
```

### Balance Sheet Checks (rows 56-58)
```excel
D56 = "PF error check"      | J56 = (check formula per period)
D57 = "Balance check"        | J57 = (Assets - Liabilities - Equity <> 0)*1
D58 = "Insolvency check"     | J58 = (negative equity flag)

' Summary column (I) uses MIN(SUM(...), 1) to collapse all period checks:
I56 = MIN(SUM(ANCHORARRAY(J56)), 1)    ' 0 if all periods pass
I57 = IF(I56<>0, 0, (ROUND(I42-I51, Rounding_Accuracy)<>0)*1)
I58 = MIN(SUM(ANCHORARRAY(J58)), 1)
```

### Cash Flow Statement
Built from control account movements, with reconciliation:
```excel
D59 = "CFS error check"     | similar to BS checks
D60 = "Reconciliation"      | J60 = J14(BS Cash) - I14(BS prior Cash) - J56(CFS net cash)
' Should be zero — flags if CFS doesn't reconcile to BS cash movement
```

---

## 8. Error Check System

### Error Checks Sheet Structure

```
Row 12: "Balance Sheet has no errors"              | I12 = HL_BS_Errors
Row 13: "Balance Sheet balances"                   | I13 = HL_BS_Balance
Row 14: "Insolvency check for Balance Sheet"       | I14 = HL_BS_Insolvency
Row 15: "Opening Balance Sheet has no errors"      | I15 = HL_Op_BS_Errors
Row 16: "Opening Balance Sheet balances"           | I16 = HL_Op_BS_Balance
Row 17: "Insolvency check for Opening BS"          | I17 = HL_Op_BS_Insolvency
Row 18: "Cash Flow Statement has no errors"        | I18 = HL_CFS_Error
Row 19: "Cash Flow Statement reconciles"           | I19 = HL_CFS_Rec_Check
...
Row 25: "Summary of Errors"                        | I25 = SUM(I12:I19)
```

- Each I cell links to the named range on the relevant financial statement
- I25 is named `Overall_Error_Check` — this is the master check
- Every sheet displays `=Overall_Error_Check` in its header (row 4)

### Error Check Formatting
Apply `Error_Checks` style with number format `"ý";"ý";"þ"`:
- Value 0 → displays tick (ý) — PASS
- Value non-zero → displays cross (þ) — FAIL

### Error Check Hyperlinks
Each error check row on the Error Checks sheet has a hyperlink to the specific check cell on the source sheet, so the user can click to investigate.

---

## 9. Conditional Formatting Rules

### Error Check Cells (tick/cross)

**pywin32 Pattern:**
```python
def apply_error_check_cf(ws, range_addr):
    """Apply green-pass / red-fail conditional formatting to error check cells."""
    rng = ws.Range(range_addr)
    rng.FormatConditions.Delete()

    # Rule 1: Green when = 0 (PASS)
    fc1 = rng.FormatConditions.Add(Type=1, Operator=3, Formula1="=0")
    # Type=1 (xlCellValue), Operator=3 (xlEqual)
    fc1.Interior.Color = 0xCEEFC6     # Light green (BGR)
    fc1.Font.Color = 0x006100         # Dark green (BGR)

    # Rule 2: Red when <> 0 (FAIL)
    fc2 = rng.FormatConditions.Add(Type=1, Operator=4, Formula1="=0")
    # Operator=4 (xlNotEqual)
    fc2.Interior.Color = 0xCEC7FF     # Light red (BGR)
    fc2.Font.Color = 0x06009C         # Dark red (BGR)
```

Apply to: All error check cells (I12:I19, I25 on Error Checks; I56:I58 on BS; I58:I59 on CFS; row 4 error banner on each sheet; and across period columns for BS/CFS checks).

### Period Visibility (Timing-driven)
On periodic sheets, use expression-based conditional formatting to grey out inactive periods:

**pywin32 Pattern:**
```python
def apply_period_visibility_cf(ws, data_range, counter_row=9):
    """Grey out columns beyond Number_of_Periods."""
    rng = ws.Range(data_range)
    # Use xlExpression (Type=2)
    fc = rng.FormatConditions.Add(
        Type=2,  # xlExpression
        Formula1=f'=J${counter_row}>Number_of_Periods'
    )
    fc.Interior.Color = 0xF2F2F2   # Light grey
    fc.Font.Color = 0xD9D9D9       # Grey text
```

### Balance Sheet: Per-Period Check Cells
The period-level check cells (J56:AC58) get conditional formatting identical to the error check pattern (green pass / red fail).

---

## 10. Formula Audit Column

The Calculations sheet includes a **formula audit column** (column P onwards) that displays the formula text for each calculation row:

```excel
P14 = IFERROR(FORMULATEXT(J14), "")
```

**pywin32 Pattern:**
```python
def add_formula_audit_column(ws, first_row, last_row, formula_col="J", audit_col="P"):
    """Add FORMULATEXT audit column to show formulas as text."""
    for r in range(first_row, last_row + 1):
        cell = ws.Range(f"{audit_col}{r}")
        cell.Formula = f'=IFERROR(_xlfn.FORMULATEXT({formula_col}{r}),"")'
        cell.Style = "Notes"
```

This is copied down for every calculation row. It allows auditors to see the formula without clicking into each cell. Apply Notes style (red font).

---

## 11. Common Formula Techniques

### Avoiding Circular References
SumProduct NEVER uses circular references. Interest calculations that might create circularity (interest on cash balance which depends on interest) are broken using:
- Sequential calculation (calculate interest on prior period balance)
- Average balance approximation
- Or iterative convergence with a counter

### MOD for Periodicity
```excel
' Determine if a period aligns with a reporting boundary
= MOD(Periodicity + Reporting_Month_Factor - MONTH(date), Periodicity)
```

### N() for Safe Counter Initialisation
```excel
' Counter that works even when the cell to the left is empty/text
J9 = N(I9) + 1
' N() returns 0 for non-numeric values, so this safely starts at 1
```

### EOMONTH for Date Arithmetic
```excel
' Next period end date
= EOMONTH(previous_end_date, Periodicity)
```

### MIN/MAX for Bounds
```excel
' Cap a value at zero (no negative)
= MAX(calculated_value, 0)

' Floor at zero for depreciation
= MIN(remaining_balance, depreciation_amount)
```

### OFFSET for Lookback
```excel
' Sum the last N periods for a rolling calculation
= SUM(OFFSET(current_cell, 0, 0, 1, -N))
```

### ROUND for Tolerance Checks
```excel
' Check if balance sheet balances (within rounding tolerance)
= (ROUND(Assets - Liabilities - Equity, Rounding_Accuracy) <> 0) * 1
' Returns 0 if balanced, 1 if not
```

### Dynamic Arrays (Modern Excel)
SumProduct's newer models use dynamic array formulas that spill across periods:
```excel
' Single formula in J5 that spills to fill all period columns
J5 = {array formula that generates all period dates}
' Subsequent cells show = (spill reference)
' Use ANCHORARRAY() or cell# to reference spill ranges
```

---

## 12. Opening Balance Sheet Patterns

The Opening Balance Sheet is a single-column (column I) snapshot of starting balances.

### Structure
```
Current Assets:
  I14: Cash           = assumption (yellow)
  I15: Receivables    = assumption (yellow)
  I16: Inventory      = assumption (yellow)
  I17: Other CA       = assumption (yellow)
  I18: Total CA       = SUM(I14:I17)

Non-Current Assets:
  I21: PPE (gross)    = assumption (yellow)
  I22: Accum deprec   = assumption (yellow, negative)
  I23: Total NCA      = SUM(I21:I22)

I25: TOTAL ASSETS     = I18 + I23

Current Liabilities:
  I28: Trade payables  = assumption (yellow)
  ...
  I33: Total CL       = SUM(I28:I32)

I35: NET ASSETS        = I25 - I33 - I40

Equity:
  I46: Share capital   = assumption (yellow)
  I47: Retained earn   = I42 - I46 (derived)
  ...
  I51: Total Equity    = SUM(I46:I50)

Checks:
  I56: Error check     = (any formulas referencing non-existent cells) * 1
  I57: Balance check   = IF(I56<>0, 0, (ROUND(I42-I51, Rounding_Accuracy)<>0)*1)
  I58: Insolvency      = (I42 < 0) * 1
```

---

## 13. Lookup Sheet Patterns

### Future Year-End Dates
```excel
' Generate future year-end dates from timing
D11 = OFFSET(Timing!$J$7, , ROWS($A$9:$A9))    ' 1st future year end
D12 = OFFSET(Timing!$J$7, , ROWS($A$9:$A10))   ' 2nd future year end
...etc
```

Named range `LU_Future_Years` covers D11:D15 (or as many as needed).

### Scenario Tables (if applicable)
```
Column B: Scenario name (e.g. "Base", "Upside", "Downside")
Column C onwards: Parameter values per scenario
```

Selected scenario drives assumptions via INDEX/MATCH or XLOOKUP.
