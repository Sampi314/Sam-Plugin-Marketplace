"""build_scaffold.py - runnable skeleton for a Phase 4 model build.

Lays out the strict 23-step build order from fm-4-build/SKILL.md as stage
functions. Stages marked TODO are model-specific: fill them from design.md
(the Phase 3 spec, structured per fm-3-design/references/design_template.md
- section numbers cited below) and plan.md (the Phase 2 blueprint).

The scaffold already executes end to end - COM init, sheet creation, save -
producing an empty-but-valid workbook, so builders start from a working
skeleton instead of blank COM boilerplate.

Usage:
    python build_scaffold.py <design.md> <plan.md> --out <model.xlsx>

After building, verify mechanically:
    python ../../_fm-shared/scripts/verify_build.py <model.xlsx>
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))  # find build_helpers

# TODO(step 4): replace with the sheet list / tab order from plan.md.
DEFAULT_SHEETS = [
    "Cover", "Navigator", "Style Guide", "Model Parameters", "Timing",
    "General Assumptions", "Calculations", "Opening Balance Sheet",
    "Income Statement", "Balance Sheet", "Cash Flow Statement",
    "Lookup", "Error Checks",
]


# ---- Step 3: Cell Styles (TODO - MUST run before any sheet content) --------

def create_styles(wb):
    """Styles with IncludeNumber=True overwrite number formats set earlier,
    which is why this runs first, straight after workbook creation."""
    # TODO(step 3): paste create_all_styles(wb) from
    # fm-3-design/references/style_creation_code.md, apply the design.md
    # section 1a deltas, then call it here.


# ---- Step 4: Sheets (EXECUTES) ----------------------------------------------

def create_sheets(wb, sheet_names):
    for name in sheet_names:
        ws = wb.Worksheets.Add(After=wb.Worksheets(wb.Worksheets.Count))
        ws.Name = name
    for ws in list(wb.Worksheets):  # drop Excel's default Sheet1/2/3
        if ws.Name not in sheet_names:
            ws.Delete()


# ---- Steps 5-18: Content (all TODO - model-specific) ------------------------

def set_widths(wb):
    """Step 5 - column widths per sheet class (design.md section 6)."""
    # TODO: build_helpers.set_column_widths(ws, {"A": 2, ..., "J:AC": 12}) per sheet


def build_timing(wb):
    """Step 6 - Timing first: every period calculation hangs off it."""
    # TODO: EOMONTH/MOD/N() engine - references/formula_patterns.md


def build_model_parameters(wb):
    """Step 7 - technical constants + unit labels the named ranges point at."""
    # TODO: copy references/worked_example.md (canonical helper-based pattern)


def build_cover_and_style_guide(wb):
    """Steps 8-9 - Cover (project identity), Style Guide (documents styles)."""
    # TODO: references/sheet_build_templates.md


def build_assumptions_and_calculations(wb):
    """Steps 10-11 - inputs (Assumption style + validation, design.md
    section 4), then Calculations (uniform R1C1 per row - Critical Rule 2)."""
    # TODO


def build_statements(wb):
    """Steps 12-15 - Opening BS, IS, BS, CFS. Labels LINK to their source
    (Critical Rule 3); statements link to Calculations rows."""
    # TODO: references/formula_patterns.md - financial statement wiring


def build_lookup_and_error_checks(wb):
    """Steps 16-17 - Lookup reference tables, then consolidated Error Checks."""
    # TODO


def build_navigator(wb):
    """Step 18 - Navigator TOC last, once every hyperlink target exists."""
    # TODO: design.md section 7 (navigation spec)


# ---- Steps 19-22: Wiring + presentation (all TODO) --------------------------

def create_named_ranges(wb):
    """Step 19 - every name in the design.md section 2 register."""
    # TODO: build_helpers.add_named_range(wb, name, refers_to)


def wire_navigation(wb):
    """Step 20 - row-3 return links on each sheet + Navigator TOC targets."""
    # TODO: design.md section 7


def apply_conditional_formatting(wb):
    """Step 21 - error-check green/red + inactive-period greying (design.md
    section 5)."""
    # TODO: build_helpers.add_cf_equals(...)


def apply_print_setup(wb):
    """Step 22 - landscape A4, fit to width, repeating header rows."""
    # TODO: build_helpers.apply_print_setup(ws) for each sheet


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Scaffold a Phase 4 build: 23-step order with TODO stages.")
    ap.add_argument("design", help="design.md from Phase 3 (design_template.md shape)")
    ap.add_argument("plan", help="plan.md from Phase 2")
    ap.add_argument("--out", required=True, help="output workbook path (.xlsx)")
    ap.add_argument("--visible", action="store_true", help="show Excel while building")
    args = ap.parse_args(argv)

    for p in (args.design, args.plan):
        if not Path(p).exists():
            ap.error(f"input not found: {p}")
    out = Path(args.out).resolve()  # relative SaveAs paths land in Documents

    # Lazy import: --help and py_compile work on machines without pywin32/Excel.
    from build_helpers import init_excel, finalise_excel

    app = init_excel(visible=args.visible)          # step 1: COM init
    wb = app.Workbooks.Add()                        # step 2: create workbook
    try:
        create_styles(wb)                           # step 3
        create_sheets(wb, DEFAULT_SHEETS)           # step 4
        set_widths(wb)                              # step 5
        build_timing(wb)                            # step 6
        build_model_parameters(wb)                  # step 7
        build_cover_and_style_guide(wb)             # steps 8-9
        build_assumptions_and_calculations(wb)      # steps 10-11
        build_statements(wb)                        # steps 12-15
        build_lookup_and_error_checks(wb)           # steps 16-17
        build_navigator(wb)                         # step 18
        create_named_ranges(wb)                     # step 19
        wire_navigation(wb)                         # step 20
        apply_conditional_formatting(wb)            # step 21
        apply_print_setup(wb)                       # step 22
    except Exception:
        wb.Close(SaveChanges=False)
        app.Quit()
        raise
    finalise_excel(app, wb, str(out))               # step 23: calc auto + save
    print(f"Workbook written -> {out}")
    print(f'Next: python ../../_fm-shared/scripts/verify_build.py "{out}"')
    return 0


if __name__ == "__main__":
    sys.exit(main())
