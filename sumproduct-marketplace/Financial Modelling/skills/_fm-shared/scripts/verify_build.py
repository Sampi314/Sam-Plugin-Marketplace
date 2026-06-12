"""Post-build verifier: assert a freshly built model matches the design spec.

Usage:
    python verify_build.py <path-to.xlsx|.xlsm>
        [--styles "Assumption,Line Calc,..."]   expected custom Cell Styles
        [--names "Days_in_Year,Currency,..."]   expected named ranges
        [--sheets "Cover,Navigator,..."]        expected sheet names IN ORDER

Run this immediately after fm-4-build saves the file, BEFORE handing to
fm-5-test. Exit code 0 = all checks pass, 1 = failures (listed in output).

Checks (always):
  A. File opens without repair prompts
  B. Expected sheets present, in order (if --sheets given)
  C. Expected Cell Styles registered (if --styles given)
  D. All named ranges resolve (no #REF!) + expected names exist (if --names)
  E. No error values anywhere (#REF!, #VALUE!, #DIV/0!, ...)
  F. Overall_Error_Check named range exists and evaluates to 0 (skipped with
     a warning if the name is absent)
  G. Every hyperlink's target sheet exists

Type-specific conservation checks (BS balance, dept-sum, payout-sum, weekly
chain) are formula rows INSIDE the model wired into Overall_Error_Check —
check F covers them. See _fm-shared/references/model_types.md.

Requires: Windows, Excel, pywin32. Opens the file READ-ONLY.
"""

import argparse
import sys

import pythoncom
import win32com.client as win32

XL_CELLTYPE_FORMULAS = -4123
XL_ERRORS = 16

PASS = "PASS"
FAIL = "FAIL"
WARN = "WARN"


def open_workbook(path):
    pythoncom.CoInitialize()
    app = win32.gencache.EnsureDispatch("Excel.Application")
    app.Visible = False
    app.DisplayAlerts = False
    wb = app.Workbooks.Open(path, ReadOnly=True, UpdateLinks=0)
    return app, wb


def check_sheets(wb, expected, results):
    actual = [ws.Name for ws in wb.Worksheets]
    if not expected:
        results.append((WARN, "B. Sheets", f"no --sheets given; found: {actual}"))
        return
    missing = [s for s in expected if s not in actual]
    if missing:
        results.append((FAIL, "B. Sheets", f"missing: {missing}"))
        return
    order = [s for s in actual if s in expected]
    if order != expected:
        results.append((FAIL, "B. Sheet order",
                        f"expected {expected}, got {order}"))
    else:
        results.append((PASS, "B. Sheets", f"all {len(expected)} present, in order"))


def check_styles(wb, expected, results):
    if not expected:
        results.append((WARN, "C. Styles", "no --styles given; skipped"))
        return
    actual = {st.Name for st in wb.Styles}
    missing = [s for s in expected if s not in actual]
    if missing:
        results.append((FAIL, "C. Styles", f"not registered: {missing}"))
    else:
        results.append((PASS, "C. Styles", f"all {len(expected)} registered"))


def check_names(wb, expected, results):
    broken = [nm.Name for nm in wb.Names if "#REF!" in nm.RefersTo]
    if broken:
        results.append((FAIL, "D. Named ranges (resolve)", f"broken: {broken}"))
    else:
        results.append((PASS, "D. Named ranges (resolve)",
                        f"all {wb.Names.Count} resolve"))
    if expected:
        actual = {nm.Name for nm in wb.Names}
        missing = [n for n in expected if n not in actual]
        if missing:
            results.append((FAIL, "D. Named ranges (expected)",
                            f"missing: {missing}"))
        else:
            results.append((PASS, "D. Named ranges (expected)",
                            f"all {len(expected)} exist"))


def check_error_values(wb, results):
    found = []
    for ws in wb.Worksheets:
        for cell_type in (XL_CELLTYPE_FORMULAS, 2):
            try:
                rng = ws.UsedRange.SpecialCells(cell_type, XL_ERRORS)
            except Exception:
                continue
            for area in rng.Areas:
                for cell in area:
                    found.append(f"{ws.Name}!{cell.Address}={cell.Text}")
    if found:
        results.append((FAIL, "E. Error values", f"{len(found)} cells: "
                        + "; ".join(found[:20])
                        + ("…" if len(found) > 20 else "")))
    else:
        results.append((PASS, "E. Error values", "none"))


def check_overall_error(wb, results):
    try:
        nm = wb.Names("Overall_Error_Check")
    except Exception:
        results.append((WARN, "F. Overall_Error_Check",
                        "named range absent — wire one up per the standard "
                        "error-check system"))
        return
    try:
        val = nm.RefersToRange.Value
    except Exception as e:
        results.append((FAIL, "F. Overall_Error_Check", f"unreadable: {e}"))
        return
    if val == 0:
        results.append((PASS, "F. Overall_Error_Check", "= 0 (all checks tick)"))
    else:
        results.append((FAIL, "F. Overall_Error_Check",
                        f"= {val} (a model check is firing — open the Error "
                        f"Checks sheet to locate it)"))


def check_hyperlinks(wb, results):
    sheet_names = {ws.Name for ws in wb.Worksheets}
    broken = []
    total = 0
    for ws in wb.Worksheets:
        for hl in ws.Hyperlinks:
            total += 1
            if hl.SubAddress:
                tgt = hl.SubAddress.split("!")[0].strip("'")
                if tgt not in sheet_names:
                    broken.append(f"{ws.Name}!{hl.Range.Address} -> {tgt}")
    if broken:
        results.append((FAIL, "G. Hyperlinks", f"broken: {broken}"))
    else:
        results.append((PASS, "G. Hyperlinks", f"all {total} target existing sheets"))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("path")
    ap.add_argument("--styles", default="", help="comma-separated expected styles")
    ap.add_argument("--names", default="", help="comma-separated expected named ranges")
    ap.add_argument("--sheets", default="", help="comma-separated expected sheets in order")
    args = ap.parse_args()

    split = lambda s: [x.strip() for x in s.split(",") if x.strip()]
    results = []

    try:
        app, wb = open_workbook(args.path)
        results.append((PASS, "A. File opens", "no repair prompt"))
    except Exception as e:
        print(f"FAIL  A. File opens: {e}")
        return 1

    try:
        check_sheets(wb, split(args.sheets), results)
        check_styles(wb, split(args.styles), results)
        check_names(wb, split(args.names), results)
        check_error_values(wb, results)
        check_overall_error(wb, results)
        check_hyperlinks(wb, results)
    finally:
        wb.Close(SaveChanges=False)
        app.Quit()

    fails = sum(1 for s, _, _ in results if s == FAIL)
    print(f"# Build Verification: {args.path}\n")
    for status, check, detail in results:
        print(f"{status:5} {check}: {detail}")
    print(f"\n{'VERDICT: FAIL — fix before fm-5-test' if fails else 'VERDICT: PASS — ready for fm-5-test'}"
          f"  ({fails} failures, {len(results)} checks)")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
