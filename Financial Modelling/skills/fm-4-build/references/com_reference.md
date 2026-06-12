# pywin32 COM Reference for Financial Model Building

> **SINGLE SOURCE OF TRUTH** for COM constants used across fm-3-design and fm-4-build — edit here, not in copies.

## Initialisation Pattern

```python
import win32com.client as win32
import pythoncom, os, time

def init_excel():
    pythoncom.CoInitialize()
    xl = win32.gencache.EnsureDispatch('Excel.Application')
    xl.Visible = True
    xl.ScreenUpdating = False
    xl.DisplayAlerts = False
    xl.Calculation = -4135     # xlCalculationManual
    return xl

def finalise_excel(xl, wb, save_path):
    xl.Calculation = -4105     # xlCalculationAutomatic
    xl.ScreenUpdating = True
    wb.SaveAs(os.path.abspath(save_path))
```

## BGR Colour Table

pywin32 uses **BGR** (0xBBGGRR), NOT RGB.

| Purpose | RGB Hex | BGR Value | Notes |
|---------|---------|-----------|-------|
| Dark Blue (Heading 1) | #003366 | 0x663300 | Section headers |
| White | #FFFFFF | 0xFFFFFF | Heading text on dark bg |
| Light Yellow (Assumption) | #FFFF99 | 0x99FFFF | User input cells |
| Medium Blue (Table_Heading) | #4472C4 | 0xC47244 | Table column headers |
| Light Green (Internal Ref) | #E2EFDA | 0xDAEFE2 | Cross-sheet links |
| Light Grey (Parameter) | #D9D9D9 | 0xD9D9D9 | Constants |
| Lighter Grey (Row Ref/Summary) | #F2F2F2 | 0xF2F2F2 | Reference cells |
| Red (Notes) | #FF0000 | 0x0000FF | Developer notes |
| Blue (Hyperlink/Range Name) | #0563C1 | 0xC10563 | Clickable links |
| Orange (WIP text) | #ED7D31 | 0x1D7DED | Work in progress |
| Light Orange (WIP fill) | #FFF2CC | 0xCCF2FF | WIP background |
| Grey (Units/Accounts Ref) | #808080 | 0x808080 | Muted text |
| Black | #000000 | 0x000000 | Default text |
| CF Green Pass (fill) | #C6EFCE | 0xCEEFC6 | Error check pass |
| CF Green Pass (font) | #006100 | 0x006100 | Error check pass |
| CF Red Fail (fill) | #FFC7CE | 0xCEC7FF | Error check fail |
| CF Red Fail (font) | #9C0006 | 0x06009C | Error check fail |

## COM Constants

### Validation
| Constant | Value | Use |
|----------|-------|-----|
| xlValidateWholeNumber | 1 | Integer input |
| xlValidateDecimal | 2 | Decimal input |
| xlValidateList | 3 | Drop-down list |
| xlValidateDate | 4 | Date input |
| xlValidateCustom | 7 | Custom formula |
| xlValidAlertStop | 1 | Prevent invalid entry |
| xlValidAlertWarning | 2 | Warn but allow |
| xlValidAlertInformation | 3 | Inform but allow |
| xlBetween | 1 | Range operator |
| xlEqual | 3 | Equals operator |
| xlNotEqual | 4 | Not equals operator |
| xlGreater | 5 | Greater than operator |
| xlLess | 6 | Less than operator |
| xlGreaterEqual | 7 | Greater than or equal operator |
| xlLessEqual | 8 | Less than or equal operator |

### Conditional Formatting
| Constant | Value | Use |
|----------|-------|-----|
| xlCellValue | 1 | Compare cell value |
| xlExpression | 2 | Formula-based rule |

### Borders
| Constant | Value | Use |
|----------|-------|-----|
| xlEdgeTop | 8 | Top border |
| xlEdgeBottom | 9 | Bottom border |
| xlEdgeLeft | 7 | Left border |
| xlEdgeRight | 10 | Right border |
| xlContinuous | 1 | Solid line style |
| xlThin | 2 | Thin weight |
| xlMedium | -4138 | Medium weight |

### Alignment
| Constant | Value |
|----------|-------|
| xlLeft | -4131 |
| xlCenter | -4108 |
| xlRight | -4152 |
| xlGeneral | 1 |

### Calculation
| Constant | Value |
|----------|-------|
| xlCalculationManual | -4135 |
| xlCalculationAutomatic | -4105 |

### Interior Pattern
| Constant | Value |
|----------|-------|
| xlSolid | 1 |
| xlNone | -4142 |

### Page Setup
| Constant | Value |
|----------|-------|
| xlPortrait | 1 |
| xlLandscape | 2 |
| xlPaperA4 | 9 |
| xlPaperLetter | 1 |

## Helper Functions

### Sheet Management
```python
def add_sheet(wb, name, after_name=None):
    if after_name:
        ws = wb.Sheets.Add(After=wb.Sheets(after_name))
    else:
        ws = wb.Sheets.Add(After=wb.Sheets(wb.Sheets.Count))
    ws.Name = name
    return ws

def delete_default_sheets(wb):
    for name in ['Sheet1', 'Sheet2', 'Sheet3']:
        try: wb.Sheets(name).Delete()
        except: pass
```

### Named Ranges
```python
def add_name(wb, name, refers_to):
    try: wb.Names.Add(Name=name, RefersTo=refers_to)
    except: wb.Names(name).RefersTo = refers_to
```

### Data Validation
```python
def add_list_validation(ws, cell, formula1, title="", msg=""):
    rng = ws.Range(cell)
    rng.Validation.Delete()
    rng.Validation.Add(Type=3, AlertStyle=1, Formula1=formula1)
    if title: rng.Validation.InputTitle = title
    if msg: rng.Validation.InputMessage = msg; rng.Validation.ShowInput = True

def add_decimal_validation(ws, cell, min_val, max_val, title="", msg=""):
    rng = ws.Range(cell)
    rng.Validation.Delete()
    rng.Validation.Add(Type=2, AlertStyle=1, Operator=1,
                       Formula1=str(min_val), Formula2=str(max_val))
    if title: rng.Validation.InputTitle = title
    if msg: rng.Validation.InputMessage = msg; rng.Validation.ShowInput = True
```

### Conditional Formatting
```python
def add_error_check_cf(ws, range_addr):
    rng = ws.Range(range_addr)
    rng.FormatConditions.Delete()
    fc1 = rng.FormatConditions.Add(Type=1, Operator=3, Formula1="=0")
    fc1.Interior.Color = 0xCEEFC6; fc1.Font.Color = 0x006100
    fc2 = rng.FormatConditions.Add(Type=1, Operator=4, Formula1="=0")
    fc2.Interior.Color = 0xCEC7FF; fc2.Font.Color = 0x06009C

def add_period_visibility_cf(ws, range_addr):
    rng = ws.Range(range_addr)
    fc = rng.FormatConditions.Add(Type=2, Formula1="=J$9>Number_of_Periods")
    fc.Interior.Color = 0xF2F2F2; fc.Font.Color = 0xD9D9D9
```

### Navigation
```python
def add_nav_row(ws):
    for col in ["A","B","C","D","E"]:
        cell = ws.Range(f"{col}3")
        txt = "Navigator" if col == "A" else "HL_Navigator"
        ws.Hyperlinks.Add(Anchor=cell, Address="", SubAddress="Navigator!A1",
                          TextToDisplay=txt, ScreenTip="Return to Navigator")
        cell.Style = "Hyperlink Text"

def add_error_banner(ws, label_cell="B4", value_cell="F4"):
    ws.Range(label_cell).Value = "Error Checks:"
    ws.Range(value_cell).Formula = "=Overall_Error_Check"
    ws.Range(value_cell).Style = "Error_Checks"
```

### Column Widths
```python
def set_standard_widths(ws, num_periods=20):
    widths = {"A":2,"B":5,"C":3,"D":3,"E":30,"F":2,"G":10,"H":10,"I":12}
    for col, w in widths.items():
        ws.Columns(col).ColumnWidth = w
    for c in range(10, 10 + num_periods):
        ws.Columns(c).ColumnWidth = 12
```

### Print Setup
```python
def set_print_setup(ws, is_periodic=True):
    ps = ws.PageSetup
    ps.Orientation = 2; ps.PaperSize = 9
    ps.FitToPagesWide = 1; ps.FitToPagesTall = False
    ps.PrintGridlines = False; ps.PrintHeadings = False
    ps.LeftHeader = "&A"; ps.RightHeader = "&F"
    ps.LeftFooter = "&D"; ps.CenterFooter = "Confidential"
    ps.RightFooter = "Page &P of &N"
    if is_periodic: ps.PrintTitleRows = "$1:$9"
```
