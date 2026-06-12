# Calculation Reference Syntax Guide

## Readable Formula Patterns

| Pattern | How to Write It | Example |
|---|---|---|
| **Hard-coded input** | *Assumption* | Cell contains a typed value |
| **Link to another sheet** | *= SheetName :: RowName* (italicised) | *= Revenue :: Net Revenue* |
| **Simple arithmetic** | = A + B, = A − B, = A × B, = A ÷ B | = Gross Revenue − Revenue Adjustment |
| **Prior period reference** | = prior [Name] | = prior Closing Balance |
| **Sum of items** | = sum(Item1 to ItemN) | = sum(Cost Line 1 to Cost Line 8) |
| **Conditional** | = if [condition] then [result] else [result] | = if Debt Service = 0 then "N/A" else CFADS ÷ Debt Service |
| **Nested conditional** | = if ... then ... else if ... then ... else ... | Expand as needed |
| **Min / Max / Round** | = min(A, B), = max(0, A − B), = round(A, 2) | = min(CFADS ÷ Debt Service, Cap) |
| **Exponentiation** | = (1 + Rate) ^ Periods | = Base Price × (1 + CPI) ^ Year Index |
| **Named range** | Use the range name directly | = {Tax_Rate} |

## Key Principles

- Use `×` and `÷` (not `*` and `/`) for readability.
- Always reference items by their **Name** column value.
- Same-sheet: just the Name (e.g., `Net Volume`).
- Cross-sheet: prefix with sheet and `::` (e.g., `Revenue :: Net Revenue`).
- For conditionals, write close to natural English.

## Time-Series Notation

Most rows repeat the same formula across columns. Document each row **once** using the first period:

- **Same formula all periods**: Note `↔ Same D14:Z14`.
- **First period differs**: Add two rows — one for first period, one for periods 2+.

Example:

| Sheet | Cell | Name | Readable Formula | Excel Formula | Notes |
|---|---|---|---|---|---|
| Revenue | D11 | Volume Growth | = Assumptions :: Base Volume | `=Assumptions!$D$8` | First period only |
| Revenue | E11 | Volume Growth | = prior Volume Growth × (1 + Growth Rate) | `=D11*(1+Assumptions!$C$12)` | ↔ Same E11:Z11 |

## Complex IF / Logic Trees

When a formula has 3+ nested conditions, add a decision tree block below:

    if Taxable Income ≤ 0:
        → 0 (no tax on losses)
    else if Tax Loss CF > 0:
        → max(0, (Taxable Income − Tax Loss CF) × Tax Rate)
    else:
        → Taxable Income × Tax Rate

## Section Sub-Headers

For large sheets, insert section dividers as merged rows:

| Sheet | Cell | Name | Readable Formula | Excel Formula |
|---|---|---|---|---|
| **Revenue** | | **— Volume Calculation —** | | |
| Revenue | D10 | Base Volume | *= Assumptions :: Base Volume* | `=Assumptions!$D$8` |

## Glossary of Common Terms

| Term | Definition |
|---|---|
| **CFADS** | Cash Flow Available for Debt Service |
| **DSCR** | Debt Service Coverage Ratio — CFADS ÷ Debt Service |
| **LLCR** | Loan Life Coverage Ratio — NPV of CFADS ÷ Outstanding Debt |
| **PLCR** | Project Life Coverage Ratio — NPV of CFADS (project life) ÷ Debt |
| **ICR** | Interest Coverage Ratio — CFADS ÷ Interest |
| **IRR** | Internal Rate of Return |
| **NPV** | Net Present Value |
| **EBITDA** | Earnings Before Interest, Tax, Depreciation & Amortisation |
| **CAPEX** | Capital Expenditure |
| **OPEX** | Operating Expenditure |
| **CPI** | Consumer Price Index |
| **WACC** | Weighted Average Cost of Capital |
