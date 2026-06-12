# Plan Document Template

> Use this template when producing deliverables in Stage 7. All deliverables
> are `.md` files. If the user also wants `.docx`, convert using
> `python ../_fm-shared/scripts/md_to_docx.py plan.md`.

Model type definitions: `../../_fm-shared/references/model_types.md`.
Per-type calculation patterns: `patterns/calculation_patterns_by_type.md`.

## Universal core (every model type)

```markdown
# Model Plan: [Project Name]

**Based on**: scope.md v[X] dated [date]
**Model Type**: [from scope.md]
**Prepared by**: Claude (AI) in collaboration with [User]

## 1. Sheet Structure
[numbered list with purpose for each sheet — use the skeleton for THIS model
 type from the registry, not the generic 14-sheet skeleton]

## 2. Data Flow
[Mermaid diagram — graph LR — adapted to this model's actual sheets]

## 3. Section Layout — Inputs
[section-by-section breakdown with row items, traced to scope items]

## 4. Section Layout — Calculations
[mirrored structure with derived rows highlighted as NEW]

## 5. [TYPE-SPECIFIC LOGIC SECTION — see blocks below]

## 6. [TYPE-SPECIFIC MAPPING SECTION — see blocks below]

## 7. Timing Parameters
[table: start date, FY-end, periodicity, periods, phase splits]

## 8. Named Range Plan
[what will be named, on which sheet, naming convention]

## 9. Pitfalls Mitigated
[2-3 most relevant pitfalls for this model type and how the design avoids them]

## 10. Open Design Decisions
| # | Decision | Options | Recommendation | User Choice |
|---|----------|---------|---------------|-------------|

## 11. Questions for Client
*Items that need client input before the plan can be finalised. Ready to send.*

| # | Topic | Question | Priority | Blocking? |
|---|-------|----------|----------|-----------|
```

## Type-specific sections 5-6

| Model type | Section 5 | Section 6 |
|------------|-----------|-----------|
| 3-Statement / Project Finance / M&A | Control Account Mappings (table: BS Item, Opening, Additions, Deductions, Closing) | Financial Statement Mappings (which Calculations rows feed which IS/BS/CFS lines) |
| Project Finance (additional) | + Cash Waterfall ordering & covenant definitions | + Debt schedule per facility |
| Budget | Department Template Layout (the one layout every dept sheet copies) | Consolidation Logic (3-D sum ranges, allocation keys) |
| Commission | Commission Calculation Logic (tier type, per-element engines) | Clawback Processing Flow + payout report mapping |
| Cost Allocation | Allocation Matrix Design (pools × recipients × drivers) | Step-down Order & conservation checks |
| Cashflow Forecast | Receipts/Payments Lag Structure | Weekly Chain & headroom logic |
| Valuation (DCF) | DCF Calculation Structure (FCF build, discounting, bridge) | Terminal Value Approach + WACC build |
| Detailed Operational | Physical Layer Design (units, constraints, conservation) | Financial Layer Mapping (units → dollars) |
| Dashboard / Reporting | KPI Definitions (register: numerator/denominator/source) | Data Source Mappings & refresh design |
| Model Optimisation | Current vs Proposed Structure Comparison | Migration Plan & tie-out output list |
| Feasibility | Incremental Cashflow Definition (inclusions/sunk exclusions) | Options Comparison structure |
| Strategic / Scenario | Scenario Switch Architecture | Comparison Output design |

Every block's design detail is in `patterns/calculation_patterns_by_type.md`
(non-FS types) or `patterns/control_accounts.md` + `patterns/financial_statements.md`
(FS types).
