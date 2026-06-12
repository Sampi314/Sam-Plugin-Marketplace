---
name: fm-4-build
description: >
  Phase 4 of the financial model build lifecycle — the pywin32 .xlsx
  construction phase (requires an existing Design spec from Phase 3).
  Construct the Excel workbook via pywin32 COM, executing the Design spec
  mechanically - creating sheets, applying Cell Styles, entering formulas,
  setting Named Ranges, Data Validation, Conditional Formatting, Navigation
  hyperlinks, and Print Setup. Use this skill when building the actual Excel
  file, constructing formulas, wiring sheets together, or executing a model
  design. Trigger on 'build the model', 'construct the workbook', 'create the
  Excel file', 'wire the formulas', or after completing the Design phase.
---

# Phase 4: Build 🔨

> *"Execute the design; deviate from nothing."*

## Mission

Construct the Excel workbook by executing the Design specification from Phase 3 using pywin32 COM automation. Every Cell Style, Named Range, formula, validation rule, and conditional format is applied exactly as specified.

## Prerequisites

- **Windows OS** with Microsoft Excel installed
- **Python package**: `pywin32` (`pip install pywin32`)
- `design.md` from Phase 3, structured per `../fm-3-design/references/design_template.md` — that template is the input contract: its numbered sections map onto the build steps below

## Quick Start

Start from `scripts/build_scaffold.py` — a runnable skeleton of the 23-step build order with COM init, sheet creation, and save already working, and every model-specific stage a marked TODO. Copy it, fill the TODOs from `design.md` and `plan.md`, run it, then verify:

```bash
python scripts/build_scaffold.py design.md plan.md --out model.xlsx
python ../_fm-shared/scripts/verify_build.py model.xlsx
```

## Important References

Before building, read:
1. `references/formula_patterns.md` — timing engine, sheet header block, section numbering, control accounts, financial statement wiring, error check system, formula audit column (3-statement / project finance / M&A)
1b. `references/formula_patterns_by_type.md` — patterns for all other model types: budget 3-D consolidation, commission tiers, allocation grids, weekly cash chains, DCF/terminal value, scenario switches, tie-out checks
2. `references/com_reference.md` — COM initialisation, BGR colour table, all COM constants (the single source of truth for both fm-3-design and fm-4-build), raw helper snippets
3. `references/sheet_build_templates.md` — boilerplate pywin32 code per standard sheet type (Cover, Navigator, Style Guide, Model Parameters, Timing, periodic sheets, Opening BS, statements, Error Checks)
4. `scripts/build_helpers.py` — reusable helpers (`init_excel`, `finalise_excel`, `apply_style_and_format`, `add_named_range`, validation/CF/header/width/print helpers). Use these instead of repeating raw COM calls.

Also read the Design skill's references:
- `../fm-3-design/references/style_creation_code.md` — `create_all_styles(wb)` and the style application rules
- `../fm-3-design/references/sumproduct_styles.md` — human-readable Cell Style register
- `../fm-3-design/references/validation_and_formats.md` — Data Validation rules and number formats

## Process

### BUILD ORDER (strict sequence)

```
1. Initialise Excel COM         ← ScreenUpdating=False, Calculation=Manual
2. Create workbook
3. Create Cell Styles           ← from fm-3-design (MUST be first)
4. Add sheets in order          ← delete default Sheet1/2/3 after
5. Set column widths            ← per sheet (design.md §6)
6. Build Timing sheet           ← drives all period calculations
7. Build Model Parameters       ← all constants and named ranges
8. Build Cover                  ← project identity
9. Build Style Guide            ← documents all styles
10. Build General Assumptions   ← all inputs with Assumption style + validation
11. Build Calculations          ← all formulas, mirrored labels
12. Build Opening Balance Sheet ← single-column balances
13. Build Income Statement      ← links to Calculations
14. Build Balance Sheet         ← links to Calculations + checks
15. Build Cash Flow Statement   ← links to Calculations + reconciliation
16. Build Lookup                ← reference tables
17. Build Error Checks          ← consolidated checks
18. Build Navigator             ← TOC with hyperlinks (last content sheet)
19. Create Named Ranges         ← all wb.Names.Add() (design.md §2)
20. Wire Navigation hyperlinks  ← per-sheet row 3 + Navigator TOC (design.md §7)
21. Apply Conditional Formatting ← error checks, period visibility (design.md §5)
22. Apply Print Setup           ← all sheets
23. Final: Calculation=Auto, ScreenUpdating=True, Save
```

### CRITICAL RULES

#### Rule 1: Style Before Content
Apply Cell Styles BEFORE entering values or formulas. If you enter a value first and then apply a style with `IncludeNumber=True`, the style's number format will override what you set.

For `Assumption` style (`IncludeNumber=False`), the order is:
```python
cell.Style = "Assumption"    # apply yellow fill
cell.NumberFormat = '0%'     # set number format separately
cell.Value = 0.05            # then enter value
```

#### Rule 2: Uniform Formulas Across Rows
Every formula row in a time series must have the **same R1C1 pattern** from first period to last. The only exception is the first period column (J) which may differ for initial-period logic.

```python
# CORRECT: uniform R1C1
for c in range(start_col, start_col + num_periods):
    ws.Cells(row, c).FormulaR1C1 = "=RC[-1]*(1+R19C)"

# WRONG: mixed patterns
ws.Cells(row, 10).Formula = "=J18"           # different pattern
ws.Cells(row, 11).Formula = "=J21*(1+K19)"   # another pattern
```

#### Rule 3: Labels Link, Don't Retype
On Calculations and Financial Statement sheets, row labels must be **linked** to their source:
```python
# Calculations links to General Assumptions
ws.Cells(17, 5).Formula = "='General Assumptions'!E17"

# Income Statement links to Opening BS or Calculations
ws.Cells(14, 4).Formula = "='Opening Balance Sheet'!D14"
```

#### Rule 4: Units Column Always References Named Ranges
```python
ws.Cells(17, 7).Formula = "=Currency"     # not "US$'000"
ws.Cells(19, 7).Formula = "=Percentage"   # not "%"
ws.Cells(23, 7).Formula = "=No._of_days"  # not "# Days"
```

### WORKED EXAMPLE

`references/worked_example.md` shows a complete Model Parameters sheet built via `scripts/build_helpers.py` — the canonical pattern to copy for any new sheet (init → widths → header → sections → styled cells → named ranges → print setup → finalise).

## Output

The constructed `.xlsx` or `.xlsm` file, saved to the user-specified path.

## Post-Build Checklist

**Run the mechanical verifier first** — it covers most of the checklist in one pass:

```bash
python ../_fm-shared/scripts/verify_build.py "<built-file>.xlsx" \
    --styles "Assumption,Line Calc,Line Total,Heading 1 Text" \
    --names "Days_in_Year,Currency,Model_Start_Date,Overall_Error_Check" \
    --sheets "Cover,Navigator,Style Guide,Model Parameters,Timing"
```

Exit 0 = ready for Phase 5. Any FAIL lines = fix before proceeding. Then spot-check the remaining visual items:

- [ ] All sheets present in correct order
- [ ] All Cell Styles visible in Home → Cell Styles → Custom
- [ ] All Named Ranges defined in Name Manager (Ctrl+F3)
- [ ] Timing engine produces correct dates
- [ ] Assumptions have yellow fill (Assumption style)
- [ ] Error checks show ticks (all zeros)
- [ ] Navigator hyperlinks work (click each one)
- [ ] Balance Sheet balances (row 57 = 0)
- [ ] Cash Flow reconciles (row 59 = 0)
- [ ] Conditional formatting renders (green ticks, red for errors)
- [ ] Print preview shows landscape A4 with header rows repeating
