# Finalisation Code Reference

Reusable pywin32 patterns for finalising a workbook before delivery. Used by
fm-6-implement.

## Cover Sheet Updates

```python
ws = wb.Sheets("Cover")
ws.Range("C5").Value = scope["client_name"]
ws.Range("C6").Formula = "=Model_Name"
ws.Range("C14").Value = f"Primary Developer: {scope['developer']}"
ws.Range("C17").Value = scope["cover_notes"]
ws.Range("G21").Value = scope["developer"]
ws.Hyperlinks.Add(Anchor=ws.Range("G21"),
                  Address=f"mailto:{scope['email']}")
```

## Change Log Entry

```python
import datetime

ws = wb.Sheets("Change Log")
row = next_empty_row(ws)   # walk col C downward from row 11 until empty
ws.Cells(row, 3).Value = datetime.date.today()
ws.Cells(row, 3).Style = "Date"
ws.Cells(row, 5).Value = scope["developer"]
ws.Cells(row, 7).Value = "Initial model build"
ws.Cells(row, 9).Value = scope["version"]
```

## Sheet Protection

Protect calculation/output sheets entirely. On input sheets, unlock the input
cells before applying protection.

```python
def protect_input_sheet(ws, assumption_cell_addresses):
    """Lock everything except yellow (Assumption) cells."""
    ws.Cells.Locked = True
    for addr in assumption_cell_addresses:
        ws.Range(addr).Locked = False
    ws.Protect(Password="", Contents=True, AllowFormattingCells=True)


def protect_output_sheet(ws):
    """Fully protect a non-input sheet."""
    ws.Protect(Password="", DrawingObjects=True, Contents=True,
               Scenarios=True, AllowFormattingCells=True)


for name in ["Calculations", "Income Statement", "Balance Sheet",
             "Cash Flow Statement", "Error Checks"]:
    protect_output_sheet(wb.Sheets(name))
```

## Why no password

SumProduct's convention is **empty-string passwords**. The protection is to
prevent accidental edits, not to defend against deliberate tampering — clients
need to be able to unprotect for their own audit. A password creates a support
burden when the client inevitably needs it.
