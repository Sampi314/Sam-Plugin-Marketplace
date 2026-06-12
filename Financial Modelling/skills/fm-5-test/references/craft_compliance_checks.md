# CRaFT Compliance Checks

> Sam-specific best-practice verification procedures beyond standard audit rules.
> These checks are run IN ADDITION to the standard audit skills.

## Table of Contents
1. [Consistency Checks](#1-consistency-checks)
2. [Robustness Checks](#2-robustness-checks)
3. [Flexibility Checks](#3-flexibility-checks)
4. [Transparency Checks](#4-transparency-checks)
5. [Verification Procedures](#5-verification-procedures)

---

## 1. Consistency Checks

| # | Check | How to Verify | Pass Criteria | Severity if Fail |
|---|-------|--------------|--------------|-----------------|
| C1 | **Header block identical across periodic sheets** | Compare rows 1–9 structure (A1 formula, A2=Model_Name, A3:E3 Navigator links, row 4 error banner, rows 5–9 timing) across all periodic sheets | Every periodic sheet has the same header structure | ⚠️ Warning |
| C2 | **Row 5 dates use Date Heading style** | Check `cell.Style == "Date Heading"` for row 5 on all periodic sheets | All row 5 period cells use Date Heading | 🟡 Info |
| C3 | **Uniform R1C1 formulas across rows** | For each formula row, convert all cells to R1C1 and verify dominant pattern consistency | ≤1 cell deviates per row (first period exception) | 🔴 Critical |
| C4 | **Cell Styles applied consistently** | For each cell, verify the named style matches its purpose (Assumption for inputs, Line Calc for formulas, etc.) | 95%+ cells have correct named style | ⚠️ Warning |
| C5 | **Section numbering pattern** | Check that section numbers in column B use `=MAX($B$x:$By)+1` formula | All section numbers are formula-driven, not hardcoded | ⚠️ Warning |
| C6 | **Calculations mirrors Assumptions labels** | Row labels (column E) on Calculations sheet should be formulas linking to General Assumptions, not retyped text | 90%+ labels are links, not text | ⚠️ Warning |
| C7 | **Financial statements contain links only** | Formulas on IS/BS/CFS should be simple cell references to Calculations (or SUM of other IS/BS/CFS rows). No new computation logic. | No formulas contain arithmetic operators beyond SUM/subtraction of adjacent rows | 🔴 Critical |
| C8 | **Column layout consistent** | Columns A–I have consistent widths and purposes across all periodic sheets | Widths match within ±1 | 🟡 Info |

---

## 2. Robustness Checks

| # | Check | How to Verify | Pass Criteria | Severity if Fail |
|---|-------|--------------|--------------|-----------------|
| R1 | **No circular references** | Check `xl.Application.CalculateBeforeSave` and scan for circular ref indicator | Zero circular references | 🔴 Critical |
| R2 | **Overall_Error_Check = 0** | Read the named range value | Value is exactly 0 | 🔴 Critical |
| R3 | **Balance Sheet balances** | Check BS row 57 (balance check) — all periods = 0 | All periods show 0 | 🔴 Critical |
| R4 | **Cash Flow reconciles** | Check CFS reconciliation row — all periods = 0 | All periods show 0 | 🔴 Critical |
| R5 | **Opening BS balances** | Check Opening BS row 57 | Value is 0 | 🔴 Critical |
| R6 | **Data validation on all input cells** | For every cell with Assumption style, check that Validation exists | 90%+ assumption cells have validation | ⚠️ Warning |
| R7 | **All named ranges resolve** | Iterate Name Manager, check none contain #REF! | Zero dead names | 🔴 Critical |
| R8 | **Error check conditional formatting present** | Check that error check cells (Error_Checks style) have green/red CF rules | All error check cells have CF | ⚠️ Warning |
| R9 | **ROUND tolerance in balance checks** | BS balance check formula should use ROUND with Rounding_Accuracy, not exact comparison | Balance check uses ROUND | ⚠️ Warning |
| R10 | **Control accounts balance** | For each control account: Opening + Additions − Deductions should equal Closing within rounding | All control accounts balance | 🔴 Critical |

---

## 3. Flexibility Checks

| # | Check | How to Verify | Pass Criteria | Severity if Fail |
|---|-------|--------------|--------------|-----------------|
| F1 | **Timing is parameterised** | Verify Periodicity, Number_of_Periods, Model_Start_Date are named ranges with data validation | All three exist and have validation | ⚠️ Warning |
| F2 | **No hardcoded values in Calculations** | Scan Calculations sheet for constant values (non-formula, non-blank cells) excluding structural elements (row labels, section headers) | Zero hardcoded numbers in the period columns (J onwards) | 🔴 Critical |
| F3 | **Period columns use relative references** | Formulas in period columns should use relative column references (RC[-1]) not absolute ($J$17) — except for row-absolute references to assumption rows | 95%+ formulas use relative column references | ⚠️ Warning |
| F4 | **Named ranges used for constants** | Values on Model Parameters that are referenced elsewhere should be via named range, not direct cell reference | All Model Parameters values referenced by name | ⚠️ Warning |
| F5 | **Scalable time horizon** | Adding a period column should not require any formula changes — only extending existing ranges | Spot-check: copy last period column → formulas auto-adjust | ⚠️ Warning |
| F6 | **Inactive period handling** | Conditional formatting should grey out periods beyond Number_of_Periods | CF rule exists on periodic sheets referencing counter vs Number_of_Periods | 🟡 Info |

---

## 4. Transparency Checks

| # | Check | How to Verify | Pass Criteria | Severity if Fail |
|---|-------|--------------|--------------|-----------------|
| T1 | **Units column (G) uses named ranges** | Every cell in column G on periodic sheets should be a formula referencing a named range (=Currency, =Unit, =Percentage, etc.) | 95%+ unit cells are formulas | ⚠️ Warning |
| T2 | **Row references present** | Column H on Calculations sheet should contain `="Row "&ROW(...)` for cross-reference rows | Row refs present where needed | 🟡 Info |
| T3 | **Formula audit column in Calculations** | Column P (or similar) should contain `=IFERROR(FORMULATEXT(...), "")` for every formula row | Audit column exists and is populated | ⚠️ Warning |
| T4 | **Style Guide sheet exists and is complete** | Style Guide sheet must list all 30 custom Cell Styles with display examples | All 30 styles documented | ⚠️ Warning |
| T5 | **Navigator sheet links to every content sheet** | Navigator TOC must have a hyperlink entry for every sheet in the workbook | 100% coverage | ⚠️ Warning |
| T6 | **Cover sheet is populated** | Cover sheet has client name, model name, developer, contact, notes | All key fields non-blank | 🟡 Info |
| T7 | **All 30 Cell Styles exist** | Check workbook Styles collection for all 30 names from the Sam standard set | All 30 present | ⚠️ Warning |
| T8 | **Error Checks sheet hyperlinks to source checks** | Each error check row should have a hyperlink to the actual check cell on BS/CFS | All checks have hyperlinks | 🟡 Info |

---

## 5. Verification Procedures

### How to Check Cell Styles via pywin32

```python
def verify_cell_styles(wb):
    """Check all 30 Sam Cell Styles exist in the workbook."""
    required_styles = [
        "Sheet Title", "Model Name",
        "Heading 1 Text", "Heading 1 Number", "Heading 2 Text",
        "Heading 3 Text", "Table_Heading", "Date Heading",
        "Accounts Ref", "Assumption", "Constraint", "Date",
        "Empty", "Error_Checks", "Hyperlink Text", "Internal Ref",
        "Line Calc", "Line Total", "Notes", "Numbers 0",
        "Parameter", "Range Name Description", "Right Currency",
        "Right Number", "Row Ref", "Row_Summary", "Units", "WIP",
        "Heading 1 Number",  # sometimes listed twice in gallery
    ]

    existing = set()
    for i in range(1, wb.Styles.Count + 1):
        existing.add(wb.Styles(i).Name)

    missing = [s for s in required_styles if s not in existing]
    return missing  # empty list = pass
```

### How to Check Assumption Style Application

```python
def verify_assumption_cells(ws, period_start_col=10, period_end_col=30):
    """Check that all hardcoded input cells have Assumption style."""
    findings = []
    for r in range(1, ws.UsedRange.Rows.Count + 1):
        for c in range(period_start_col, period_end_col + 1):
            cell = ws.Cells(r, c)
            if cell.Value is not None and not cell.HasFormula:
                # This is a hardcoded value — should have Assumption style
                if cell.Style.Name != "Assumption":
                    findings.append({
                        "cell": cell.Address,
                        "current_style": cell.Style.Name,
                        "value": cell.Value,
                    })
    return findings
```

### How to Check R1C1 Consistency

```python
def verify_r1c1_consistency(ws, row, start_col=10, end_col=30):
    """Check that all formulas in a row share the same R1C1 pattern."""
    patterns = {}
    for c in range(start_col, end_col + 1):
        cell = ws.Cells(row, c)
        if cell.HasFormula:
            r1c1 = cell.FormulaR1C1
            patterns.setdefault(r1c1, []).append(cell.Address)

    if len(patterns) <= 1:
        return None  # all consistent (or no formulas)

    # Find dominant pattern
    dominant = max(patterns, key=lambda k: len(patterns[k]))
    breaks = {k: v for k, v in patterns.items() if k != dominant}
    return {
        "dominant": dominant,
        "dominant_cells": patterns[dominant],
        "breaks": breaks,
    }
```

### How to Check Financial Statement Links Only

```python
def verify_links_only(ws, calc_sheet_name="Calculations",
                      period_start_col=10, period_end_col=30):
    """Verify formulas on a financial statement are simple links,
    not new calculations."""
    findings = []
    for r in range(1, ws.UsedRange.Rows.Count + 1):
        for c in range(period_start_col, period_end_col + 1):
            cell = ws.Cells(r, c)
            if cell.HasFormula:
                formula = cell.Formula
                # Allowed: simple reference like ='Calculations'!J23
                # Allowed: SUM of same-sheet cells like =J13+J14
                # Allowed: subtraction like =J13-J14
                # Not allowed: multiplication, division, IF, VLOOKUP, etc.
                suspicious_ops = ['*', '/', 'IF(', 'VLOOKUP(', 'INDEX(',
                                  'MATCH(', 'SUMIF(', 'OFFSET(', 'INDIRECT(']
                for op in suspicious_ops:
                    if op in formula:
                        findings.append({
                            "cell": cell.Address,
                            "formula": formula,
                            "issue": f"Contains '{op}' — financial statement "
                                     f"should only link, not calculate",
                        })
                        break
    return findings
```

### How to Check Control Account Balance

```python
def verify_control_account(ws, opening_row, additions_rows, deductions_rows,
                           closing_row, period_start_col=10, period_end_col=30):
    """Verify: Opening + sum(Additions) - sum(Deductions) = Closing."""
    findings = []
    for c in range(period_start_col, period_end_col + 1):
        opening = ws.Cells(opening_row, c).Value or 0
        additions = sum(ws.Cells(r, c).Value or 0 for r in additions_rows)
        deductions = sum(ws.Cells(r, c).Value or 0 for r in deductions_rows)
        closing = ws.Cells(closing_row, c).Value or 0
        expected = opening + additions - deductions
        if abs(expected - closing) > 0.01:  # rounding tolerance
            findings.append({
                "column": c,
                "opening": opening,
                "additions": additions,
                "deductions": deductions,
                "expected_closing": expected,
                "actual_closing": closing,
                "difference": expected - closing,
            })
    return findings
```
