"""Workbook X-ray: dump a structured digest of an Excel model for AI analysis.

Usage:
    python inspect_workbook.py <path-to.xlsx|.xlsm> [--out digest.md]

Prints a markdown digest to stdout (or writes to --out). The digest is the
INPUT to model analysis — run this FIRST, read the digest, then analyse.
It replaces ad-hoc cell-by-cell COM exploration with one exhaustive pass.

Digest contents:
  1. Sheet inventory (name, used range, visibility)
  2. Named ranges (with broken/#REF! flagged)
  3. Per-sheet R1C1 formula pattern groups — each row's formulas grouped by
     R1C1 signature, so pattern breaks read as "19 cells pattern A, 1 cell
     pattern B" (the break)
  4. Error cells (#REF!, #VALUE!, #DIV/0!, ...)
  5. Workbook Cell Styles (custom ones flagged)
  6. Data validation ranges
  7. Conditional formatting rules
  8. Hyperlinks (with missing-target flags)

Requires: Windows, Excel, pywin32. Opens the file READ-ONLY.
"""

import argparse
import sys
from collections import defaultdict

import pythoncom
import win32com.client as win32

XL_CELLTYPE_FORMULAS = -4123
XL_ERRORS = 16
XL_CELLTYPE_ALLVALIDATION = -4174

BUILTIN_STYLES = {
    "Normal", "Comma", "Comma [0]", "Currency", "Currency [0]", "Percent",
    "Hyperlink", "Followed Hyperlink", "Note", "Warning Text", "Title",
    "Heading 1", "Heading 2", "Heading 3", "Heading 4", "Input", "Output",
    "Calculation", "Check Cell", "Explanatory Text", "Linked Cell",
    "Total", "Good", "Bad", "Neutral",
}


def open_workbook(path):
    pythoncom.CoInitialize()
    app = win32.gencache.EnsureDispatch("Excel.Application")
    app.Visible = False
    app.DisplayAlerts = False
    app.ScreenUpdating = False
    wb = app.Workbooks.Open(path, ReadOnly=True, UpdateLinks=0)
    return app, wb


def sheet_inventory(wb, out):
    out.append("## 1. Sheet Inventory\n")
    out.append("| # | Sheet | Used Range | Visible |")
    out.append("|---|-------|-----------|---------|")
    for i, ws in enumerate(wb.Worksheets, 1):
        used = ws.UsedRange.Address if ws.UsedRange else "(empty)"
        vis = {-1: "Yes", 0: "Hidden", 2: "VeryHidden"}.get(ws.Visible, "?")
        out.append(f"| {i} | {ws.Name} | {used} | {vis} |")
    out.append("")


def named_ranges(wb, out):
    out.append("## 2. Named Ranges\n")
    names = list(wb.Names)
    if not names:
        out.append("_None defined._\n")
        return
    out.append("| Name | RefersTo | Status |")
    out.append("|------|----------|--------|")
    broken = 0
    for nm in names:
        ref = nm.RefersTo
        status = "OK"
        if "#REF!" in ref:
            status = "**BROKEN (#REF!)**"
            broken += 1
        out.append(f"| {nm.Name} | `{ref}` | {status} |")
    out.append(f"\nTotal: {len(names)} names, {broken} broken.\n")


def formula_patterns(wb, out, max_rows_per_sheet=500):
    out.append("## 3. Formula Patterns (R1C1, grouped per row)\n")
    out.append("Rows where ALL formulas share one R1C1 signature are uniform "
               "(CRaFT-consistent). Multiple signatures on one row = pattern "
               "break — judge whether intentional (e.g. first-period column).\n")
    for ws in wb.Worksheets:
        ur = ws.UsedRange
        if ur is None:
            continue
        try:
            f_r1c1 = ur.FormulaR1C1  # bulk 2D fetch — fast
        except Exception:
            continue
        if not isinstance(f_r1c1, tuple):  # single cell
            f_r1c1 = ((f_r1c1,),)
        first_row = ur.Row
        first_col = ur.Column
        sheet_lines = []
        n_rows = len(f_r1c1)
        truncated = n_rows > max_rows_per_sheet
        for r_idx, row in enumerate(f_r1c1[:max_rows_per_sheet]):
            groups = defaultdict(list)  # signature -> [col letters]
            for c_idx, val in enumerate(row):
                if isinstance(val, str) and val.startswith("="):
                    col_num = first_col + c_idx
                    groups[val].append(col_letter(col_num))
            if not groups:
                continue
            row_num = first_row + r_idx
            if len(groups) == 1:
                sig, cols = next(iter(groups.items()))
                sheet_lines.append(
                    f"- Row {row_num}: {len(cols)} cells uniform `{trunc(sig)}`")
            else:
                sheet_lines.append(f"- Row {row_num}: **{len(groups)} patterns**")
                for sig, cols in sorted(groups.items(),
                                        key=lambda kv: -len(kv[1])):
                    span = f"{cols[0]}..{cols[-1]}" if len(cols) > 2 else ",".join(cols)
                    sheet_lines.append(f"    - {len(cols)} cells [{span}]: `{trunc(sig)}`")
        if sheet_lines:
            out.append(f"### {ws.Name}\n")
            out.extend(sheet_lines)
            if truncated:
                out.append(f"\n_TRUNCATED: only first {max_rows_per_sheet} of "
                           f"{n_rows} rows scanned — rerun with --max-rows to "
                           f"cover the rest._")
            out.append("")


def error_cells(wb, out):
    out.append("## 4. Error Cells\n")
    found = []
    for ws in wb.Worksheets:
        for cell_type in (XL_CELLTYPE_FORMULAS, 2):  # formulas, constants
            try:
                rng = ws.UsedRange.SpecialCells(cell_type, XL_ERRORS)
            except Exception:
                continue  # none of this kind
            for area in rng.Areas:
                for cell in area:
                    found.append((ws.Name, cell.Address, str(cell.Text)))
    if not found:
        out.append("_None — clean._\n")
        return
    out.append("| Sheet | Cell | Error |")
    out.append("|-------|------|-------|")
    for sheet, addr, txt in found:
        out.append(f"| {sheet} | {addr} | {txt} |")
    out.append(f"\nTotal: {len(found)} error cells.\n")


def styles(wb, out):
    out.append("## 5. Workbook Cell Styles\n")
    custom, builtin = [], []
    for st in wb.Styles:
        (builtin if st.Name in BUILTIN_STYLES else custom).append(st.Name)
    out.append(f"**Custom ({len(custom)})**: {', '.join(sorted(custom)) or '(none)'}\n")
    out.append(f"**Built-in present ({len(builtin)})**: {', '.join(sorted(builtin))}\n")


def validations(wb, out):
    out.append("## 6. Data Validation Ranges\n")
    any_found = False
    for ws in wb.Worksheets:
        try:
            rng = ws.Cells.SpecialCells(XL_CELLTYPE_ALLVALIDATION)
        except Exception:
            continue
        any_found = True
        out.append(f"- **{ws.Name}**: {rng.Address}")
    out.append("" if any_found else "_None found._\n")


def conditional_formats(wb, out):
    out.append("## 7. Conditional Formatting\n")
    any_found = False
    for ws in wb.Worksheets:
        try:
            count = ws.Cells.FormatConditions.Count
        except Exception:
            count = 0
        if count:
            any_found = True
            out.append(f"### {ws.Name} ({count} rules)")
            for i in range(1, count + 1):
                try:
                    fc = ws.Cells.FormatConditions(i)
                    applies = fc.AppliesTo.Address
                    formula = getattr(fc, "Formula1", "")
                    out.append(f"- Rule {i}: applies {applies}, formula `{formula}`")
                except Exception as e:
                    out.append(f"- Rule {i}: (unreadable: {e})")
            out.append("")
    if not any_found:
        out.append("_None found._\n")


def hyperlinks(wb, out):
    out.append("## 8. Hyperlinks\n")
    sheet_names = {ws.Name for ws in wb.Worksheets}
    rows = []
    for ws in wb.Worksheets:
        for hl in ws.Hyperlinks:
            target = hl.SubAddress or hl.Address or "(empty)"
            status = "OK"
            if hl.SubAddress:
                tgt_sheet = hl.SubAddress.split("!")[0].strip("'")
                if tgt_sheet not in sheet_names:
                    status = "**BROKEN — sheet missing**"
            rows.append((ws.Name, hl.Range.Address, target, status))
    if not rows:
        out.append("_None found._\n")
        return
    out.append("| Sheet | Cell | Target | Status |")
    out.append("|-------|------|--------|--------|")
    for r in rows:
        out.append("| " + " | ".join(r) + " |")
    out.append("")


def col_letter(n):
    s = ""
    while n:
        n, rem = divmod(n - 1, 26)
        s = chr(65 + rem) + s
    return s


def trunc(s, limit=120):
    return s if len(s) <= limit else s[:limit] + "…"


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("path", help="Path to .xlsx/.xlsm")
    ap.add_argument("--out", help="Write digest to this file instead of stdout")
    ap.add_argument("--max-rows", type=int, default=500,
                    help="Max rows scanned per sheet for formula patterns")
    args = ap.parse_args()

    app, wb = open_workbook(args.path)
    out = [f"# Workbook X-Ray: {wb.Name}\n"]
    try:
        sheet_inventory(wb, out)
        named_ranges(wb, out)
        formula_patterns(wb, out, args.max_rows)
        error_cells(wb, out)
        styles(wb, out)
        validations(wb, out)
        conditional_formats(wb, out)
        hyperlinks(wb, out)
    finally:
        wb.Close(SaveChanges=False)
        app.Quit()

    digest = "\n".join(out)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(digest)
        print(f"Digest written to {args.out}")
    else:
        print(digest)


if __name__ == "__main__":
    sys.exit(main())
