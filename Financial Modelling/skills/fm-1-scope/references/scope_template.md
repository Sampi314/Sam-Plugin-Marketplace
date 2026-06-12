# Scope Document Template

> Use this template when producing deliverables in Round 4. All deliverables
> are `.md` files. If the user also wants `.docx`, convert using the shared
> converter (see "Generating .docx" below).

## Instructions

1. **Write `scope.md` first** using the universal core below, then add the
   section block matching the model type identified in Round 2.
2. For **Mode A** (client brief): mark unknowns as `[TBC]` and assumed
   defaults with `[Assumed — confirm with client]`
3. **Questions for Client** is critical for Mode A — give the modeller a
   ready-to-send list grouped by topic and prioritised (Must Have / Nice to
   Have). Frame questions so a non-technical client can answer them.
4. Tell the user the files are ready — do NOT paste full content into chat
5. Do not proceed to Phase 2 until the user explicitly confirms the scope

Model type definitions: `../../_fm-shared/references/model_types.md`.

## Universal core (every model type)

```markdown
# Model Scope: [Project Name]

**Date**: [date]
**Prepared by**: Claude (AI) in collaboration with [User]
**Version**: 1.0
**Model Type**: [from the registry — e.g. Budget / Commission / 3-Statement]
**Status**: Draft — awaiting confirmation

---

## 1. Model Identity
| Field | Value |
|-------|-------|
| Model Name | |
| Client | |
| Purpose / decision supported | |
| Audience | |
| Industry | |
| Existing Model? | |
| Delivery Deadline | |

## 2. Timeline & Periodicity
[table: start date, FY-end, periodicity, forecast periods, historical periods]

## 3. Key Outputs Required
[metrics, format requirements, dashboard?]

## 4. Scenarios & Sensitivities
[scenarios needed, sensitisable variables — write "None" explicitly if none]

## 5. Currency & Units
[currency, symbol, scale]

## 6. Complexity Level
[Simple / Standard / Complex — per the registry's scaling guidance, with the
 one-line justification tied to the decision at stake]

## 7. Out of Scope
[excluded items WITH reasons — as important as what's in]

## 8. Reference Documents
[files provided]

## 9. Open Questions
| # | Question | Blocking? | Status |
|---|----------|-----------|--------|

## 10. Questions for Client
*For Mode A: ready-to-send list of questions to close gaps in the client brief.*

| # | Topic | Question | Priority |
|---|-------|----------|----------|
```

## Type-specific section blocks (insert after section 6)

Pick the block matching the model type. Combined engagements take the union.

### 3-Statement / Project Finance / M&A-LBO / Feasibility

```markdown
## T1. Revenue Streams
[table per stream: driver, price basis, escalation, ramp-up]

## T2. Cost Structure
[table: category, fixed/variable, driver]

## T3. Capital Expenditure
[table: asset, cost, timing, useful life, depreciation method]

## T4. Funding & Debt
[table per facility: amount, rate, term, repayment shape, covenants]

## T5. Working Capital
[receivable/payable/inventory days]

## T6. Tax
[rate, losses, jurisdiction-specific rules]
```

Project Finance adds: `## T7. Waterfall & Covenants` (cascade order, DSCR/LLCR
targets, reserve accounts, lock-up tests).
M&A/LBO adds: `## T7. Transaction Structure` (sources & uses, purchase price,
synergies, returns hurdles).

### Budget / Rolling Budget

```markdown
## T1. Departments / Cost Centres
[list with owner and approver per department]

## T2. Budget Basis
[top-down / bottom-up; driver-based or line-item]

## T3. Allocation Keys
[shared cost pools and the driver allocating each]

## T4. Actuals & Re-forecast Cadence
[actuals source, refresh frequency, rolling horizon]

## T5. Approval Workflow
[sign-off stages the model must accommodate]
```

### Commission / Incentive

```markdown
## T1. Sales Roles & Territories
[role list, headcount, territory structure]

## T2. Plan Elements
[base commission, accelerators, SPIFFs, overrides — per role]

## T3. Tier Structure
[marginal or cliff; tier table per element]

## T4. Clawback Rules
[trigger events, recovery method, time limits]

## T5. Pay-out Schedule
[frequency, payment lag, true-up treatment]
```

### Cost Allocation

```markdown
## T1. Cost Pools
[pool list with annual values]

## T2. Allocation Drivers
[driver per pool, data source for driver values]

## T3. Recipients
[departments/products receiving allocations]

## T4. Method
[direct / step-down (with order) / reciprocal — and why]
```

### Cashflow Forecast (13-week / liquidity)

```markdown
## T1. Cash Inflows
[sources, timing basis (debtor days or calendar), data source]

## T2. Cash Outflows
[categories, timing basis, committed vs discretionary]

## T3. Opening Position & Facilities
[opening cash, facility limits, drawn balances]

## T4. Refresh Cadence
[weekly refresh process, actuals source, forecast horizon roll]
```

### Dashboard / Reporting

```markdown
## T1. KPI Register
[KPI, numerator, denominator, target, owner]

## T2. Data Sources
[source per KPI, refresh method, refresh frequency]

## T3. Views & Filters
[pages, slicers, period selection, drill paths]
```

### Valuation (DCF / Comparables)

```markdown
## T1. Forecast Assumptions
[forecast horizon, key drivers]

## T2. Discounting
[WACC components, mid-year convention?]

## T3. Terminal Value
[Gordon growth / exit multiple, parameters]

## T4. Comparables (if used)
[comp set, multiples, adjustments]
```

### Detailed Operational

```markdown
## T1. Physical Drivers
[production/capacity/resource schedule basis]

## T2. Constraints
[capacity limits, resource calendars, maintenance windows]

## T3. Cost Build
[unit cost rates, fixed/variable split at the physical level]
```

### Model Optimisation

```markdown
## T1. Current Model Diagnosis
[known problems; attach fm-5-test audit findings if run]

## T2. Improvement Targets
[performance, size, auditability, specific defects]

## T3. Tie-Out Outputs
[the 10-30 key outputs that must match the original]

## T4. Migration Constraints
[parallel-run period, user retraining, cutover date]
```

### Strategic / Scenario

```markdown
## T1. Scenario Set
[scenario list with the story each tells]

## T2. Scenario Variables
[which assumptions vary per scenario]

## T3. Comparison Outputs
[the outputs to show side-by-side; crossover analysis?]
```

## Generating .docx (optional)

If the user wants Word format, run:
```bash
python ../_fm-shared/scripts/md_to_docx.py scope.md
```
This produces `scope.docx` in the same directory with proper headings, tables,
and formatting.
