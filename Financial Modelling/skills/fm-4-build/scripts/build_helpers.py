"""Reusable pywin32 COM helpers for Sam fm-4-build skill.

Import as:
    from build_helpers import (
        init_excel, finalise_excel,
        apply_style, apply_style_and_format,
        add_named_range, add_validation_list, add_validation_decimal,
        add_cf_equals, add_cf_greater_than,
        write_header_block, write_section_heading,
        set_column_widths, apply_print_setup,
    )

All functions take a pywin32 worksheet or workbook object and operate via the
Excel COM API. They assume `wb.Styles.Add(...)` has already been called via
the `create_all_styles` function from
`fm-3-design/references/style_creation_code.md`.
"""

import win32com.client as win32
import pythoncom


def init_excel(visible: bool = False):
    """Start Excel, disable screen updating, set manual calc.

    Returns the Excel Application COM object.
    """
    pythoncom.CoInitialize()
    app = win32.gencache.EnsureDispatch("Excel.Application")
    app.Visible = visible
    app.ScreenUpdating = False
    app.Calculation = -4135   # xlCalculationManual
    app.DisplayAlerts = False
    return app


def finalise_excel(app, wb, save_path: str):
    """Re-enable auto calc, save and close. Always call at end of build."""
    app.Calculation = -4105   # xlCalculationAutomatic
    app.ScreenUpdating = True
    wb.SaveAs(save_path)
    wb.Close(SaveChanges=False)
    app.Quit()


def apply_style(cell, style_name: str):
    """Apply a Cell Style to a Range without touching its number format."""
    cell.Style = style_name


def apply_style_and_format(cell, style_name: str, number_format: str):
    """Apply Cell Style, THEN set the number format. Order matters for styles
    with IncludeNumber=False (e.g. Assumption — see the trap in
    fm-3-design/references/style_creation_code.md)."""
    cell.Style = style_name
    cell.NumberFormat = number_format


def add_named_range(wb, name: str, refers_to: str):
    """Add a workbook-scope named range. refers_to like '=Timing!$J$5'."""
    wb.Names.Add(Name=name, RefersTo=refers_to)


def add_validation_list(rng, values, input_msg: str = ""):
    """Add a List validation to a range. xlValidateList=3, xlBetween=1."""
    rng.Validation.Delete()
    rng.Validation.Add(Type=3, AlertStyle=1, Operator=1,
                       Formula1=",".join(str(v) for v in values))
    if input_msg:
        rng.Validation.InputTitle = ""
        rng.Validation.InputMessage = input_msg


def add_validation_decimal(rng, minimum: float, maximum: float,
                           input_msg: str = ""):
    """Decimal between min and max. xlValidateDecimal=2, xlBetween=1."""
    rng.Validation.Delete()
    rng.Validation.Add(Type=2, AlertStyle=1, Operator=1,
                       Formula1=str(minimum), Formula2=str(maximum))
    if input_msg:
        rng.Validation.InputMessage = input_msg


def add_cf_equals(rng, value, font_color_bgr: int, fill_color_bgr: int):
    """Conditional Format: equals `value` → coloured.
    Type=1 xlCellValue, Operator=3 xlEqual."""
    cf = rng.FormatConditions.Add(Type=1, Operator=3, Formula1=str(value))
    cf.Font.Color = font_color_bgr
    cf.Interior.Color = fill_color_bgr


def add_cf_greater_than(rng, threshold_formula: str, font_color_bgr: int,
                        fill_color_bgr: int):
    """CF: cell value > threshold (threshold can be a formula).
    Type=1 xlCellValue, Operator=5 xlGreater."""
    cf = rng.FormatConditions.Add(Type=1, Operator=5,
                                  Formula1=threshold_formula)
    cf.Font.Color = font_color_bgr
    cf.Interior.Color = fill_color_bgr


def write_header_block(ws, sheet_title: str, model_name_formula: str = "=Model_Name"):
    """Rows 1-2 standard Sam sheet header.

    Row 3 (navigation links) is written by a separate navigation helper.
    Row 4 is intentionally left blank as the standard Sam spacer.
    """
    ws.Cells(1, 1).Value = sheet_title
    ws.Cells(1, 1).Style = "Sheet Title"
    ws.Cells(2, 1).Formula = model_name_formula
    ws.Cells(2, 1).Style = "Model Name"


def write_section_heading(ws, row: int, section_num: int, title: str):
    """Section heading: number in col B (Heading 1 Number style), title in
    col C (Heading 1 Text style)."""
    ws.Cells(row, 2).Value = section_num
    ws.Cells(row, 2).Style = "Heading 1 Number"
    ws.Cells(row, 3).Value = title
    ws.Cells(row, 3).Style = "Heading 1 Text"


def set_column_widths(ws, widths: dict):
    """Set column widths from a dict like {"A": 2, "E": 30, "J:AC": 12}."""
    for col_spec, width in widths.items():
        ws.Columns(col_spec).ColumnWidth = width


def apply_print_setup(ws, landscape: bool = True, fit_to_width: int = 1,
                      header_rows: str = "$1:$9"):
    """Standard Sam print setup: landscape A4, fit to 1 page wide,
    header rows 1-9 repeat on every page."""
    ws.PageSetup.Orientation = 2 if landscape else 1  # xlLandscape=2
    ws.PageSetup.PaperSize = 9                        # xlPaperA4
    ws.PageSetup.Zoom = False
    ws.PageSetup.FitToPagesWide = fit_to_width
    ws.PageSetup.FitToPagesTall = False
    ws.PageSetup.PrintTitleRows = header_rows
