"""excel_automation.py — pywin32 COM bridge for what openpyxl cannot read.

Used by excel-pq-auditor (Power Query M code) and excel-vba-auditor (VBA).
Everything else should use extract_workbook.py instead — COM is slow,
serialises access, and needs Excel installed; openpyxl needs none of that.

Usage:
    from excel_automation import excel_app, open_workbook, PowerQueryManager, VBAManager

    with excel_app(visible=False) as xl:
        with open_workbook(xl, r"C:\\path\\model.xlsm") as wb:
            queries = PowerQueryManager.list_queries(wb)
            modules = VBAManager.list_macros(wb)
            code = VBAManager.get_module_code(wb, modules[0]["name"])

Requires: Windows, Excel, pywin32 (pip install pywin32).
VBA access additionally requires: File > Options > Trust Center >
Macro Settings > "Trust access to the VBA project object model".
"""

from __future__ import annotations

from contextlib import contextmanager

try:
    import pythoncom
    import win32com.client as win32
    from pywintypes import com_error
except ImportError:  # pragma: no cover
    raise ImportError("pywin32 is required for COM automation: pip install pywin32")

TRUST_CENTER_HINT = (
    "Cannot access the VBA project. Enable: File > Options > Trust Center > "
    "Trust Center Settings > Macro Settings > 'Trust access to the VBA project "
    "object model', then close Excel and retry."
)

# Frequently-needed COM constants (single source for rule scripts)
XL_CELLTYPE_FORMULAS = -4123
XL_CELLTYPE_CONSTANTS = 2
XL_ERRORS = 16
XL_CELLTYPE_ALLVALIDATION = -4174
XL_CALCULATION_MANUAL = -4135
XL_CALCULATION_AUTOMATIC = -4105

VBA_COMPONENT_TYPES = {
    1: "Standard Module",
    2: "Class Module",
    3: "UserForm",
    100: "Document Module",   # ThisWorkbook / Sheet modules
}


@contextmanager
def excel_app(visible: bool = False, screen_updating: bool = False):
    """Start (or attach to) an Excel COM instance; always quits on exit."""
    pythoncom.CoInitialize()
    app = win32.gencache.EnsureDispatch("Excel.Application")
    app.Visible = visible
    app.DisplayAlerts = False
    try:
        app.ScreenUpdating = screen_updating
    except com_error:
        pass  # only settable when a window exists
    try:
        yield app
    finally:
        try:
            app.Quit()
        finally:
            pythoncom.CoUninitialize()


@contextmanager
def open_workbook(app, path: str, read_only: bool = True):
    """Open a workbook read-only with external links left un-updated."""
    wb = app.Workbooks.Open(path, ReadOnly=read_only, UpdateLinks=0)
    try:
        yield wb
    finally:
        wb.Close(SaveChanges=False)


class PowerQueryManager:
    """Read Power Query (Get & Transform) M code via the Workbook.Queries API."""

    @staticmethod
    def list_queries(wb) -> list[dict]:
        """[{name, formula, description}] — empty list if the workbook has none."""
        out = []
        try:
            queries = wb.Queries
            count = queries.Count
        except (com_error, AttributeError):
            return out  # very old Excel, or no queries collection
        for i in range(1, count + 1):
            q = queries.Item(i)
            out.append({
                "name": q.Name,
                "formula": q.Formula,
                "description": getattr(q, "Description", "") or "",
            })
        return out


class VBAManager:
    """Read VBA module inventory and source code via the VBE object model."""

    @staticmethod
    def _components(wb):
        try:
            return wb.VBProject.VBComponents
        except com_error as exc:
            raise RuntimeError(TRUST_CENTER_HINT) from exc

    @classmethod
    def list_macros(cls, wb) -> list[dict]:
        """[{name, type, line_count}] for every VBA component in the workbook."""
        out = []
        for comp in cls._components(wb):
            out.append({
                "name": comp.Name,
                "type": VBA_COMPONENT_TYPES.get(comp.Type, f"Type {comp.Type}"),
                "line_count": comp.CodeModule.CountOfLines,
            })
        return out

    @classmethod
    def get_module_code(cls, wb, name: str) -> str:
        for comp in cls._components(wb):
            if comp.Name == name:
                n = comp.CodeModule.CountOfLines
                return comp.CodeModule.Lines(1, n) if n else ""
        raise KeyError(f"No VBA component named {name!r}")


if __name__ == "__main__":
    # Smoke test: open a workbook read-only, print inventory, leave no EXCEL.EXE.
    import sys

    if len(sys.argv) != 2:
        sys.exit("Usage: python excel_automation.py <workbook>  (smoke test)")
    with excel_app() as xl:
        with open_workbook(xl, sys.argv[1]) as wb:
            print(f"Sheets: {wb.Worksheets.Count}")
            print(f"Power Query queries: {len(PowerQueryManager.list_queries(wb))}")
            try:
                print(f"VBA components: {len(VBAManager.list_macros(wb))}")
            except RuntimeError as e:
                print(f"VBA: {e}")
    print("COM bridge OK — Excel closed cleanly.")
