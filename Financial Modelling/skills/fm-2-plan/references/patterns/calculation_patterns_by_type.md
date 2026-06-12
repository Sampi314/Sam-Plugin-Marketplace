# Calculation Patterns by Model Type (non-3-statement)

Design-level calculation patterns for the model types NOT covered by
`control_accounts.md` and `financial_statements.md` (which serve 3-statement,
project finance, and M&A models). Use during Stage 3 (section layout) and in
place of Stage 5 where control accounts don't apply.

Type definitions and skeletons: `../../../_fm-shared/references/model_types.md`.

---

## Budget / Rolling Budget

**The department template is the unit of design.** Every department sheet must
have an IDENTICAL layout — same rows, same columns, same row meanings — so
consolidation is a simple 3-D sum across sheets. A single misaligned row in
one department silently corrupts the consolidation.

```
Department template (identical per dept):
  Row 12  Revenue (if revenue-generating)
  Row 14  Staff costs        = FTE × average salary × (1 + on-costs%)
  Row 15  Direct costs       (input rows per category)
  Row 20  Allocated overhead = allocation key % × central pool   <- from Allocation sheet
  Row 22  Total              = SUM
Consolidation:
  Each line = SUM('First Dept:Last Dept'!J14)    <- 3-D reference
```

**Rolling logic**: define a single `Last_Actual_Period` cell. Every period
column tests `IF(period ≤ Last_Actual_Period, actual, budget)` — never
overwrite budget columns with actuals; keep both layers and switch.

**Variance**: a separate block (or sheet), never interleaved: variance =
actual − budget, plus variance % with divide-by-zero guard.

## Commission / Incentive

**Decide marginal vs cliff tiers first** — they are different machines:

- **Marginal** (each band's rate applies only to attainment within the band):
  plan a tier table (lower bound, rate) and compute via band differentials.
  This is the SUMPRODUCT pattern — see fm-4-build
  `formula_patterns_by_type.md` for the formula.
- **Cliff** (one rate applies to the whole amount based on final band):
  a single LOOKUP of attainment against the tier table.

**Clawback is a control account** (the one place the 3-statement pattern
reappears): opening clawback balance + new clawbacks − recovered = closing.
Plan a clawback ledger per rep.

**Layout**: Rep Data (one row per rep: territory, quota, manager) → Commission
Engine (one calculation block per element: base, accelerator, SPIFF, override)
→ Pay-out Report (per-rep summary + grand total). The grand total on the
report must equal the engine's total — plan that as an error check.

## Cost Allocation

**The allocation matrix is the design**: pools as rows, recipients as columns,
driver percentages in the grid. Two structural rules:

1. **Every driver row sums to exactly 100%** — plan a check column.
2. **Conservation**: total allocated = total pool — plan a check row.

**Step-down ordering matters**: if service departments charge each other,
decide the step-down order in the plan (most-used service first) and document
that the residual cross-charges are ignored — or plan 2-3 iterative passes if
materiality requires. Avoid true reciprocal (matrix inversion) unless the
client specifically needs it; it kills transparency.

## Cashflow Forecast (13-week)

**Receipts and payments are timing transforms of P&L events.** Plan the lag
structure explicitly:

```
Invoicing (from sales ledger or estimate)
  → Receipts = invoicing shifted by debtor-days (in weeks: OFFSET-free,
    use index arithmetic on the week counter)
Purchases → Payments = purchases shifted by creditor-days
Payroll, rent, tax: calendar-driven (specific weeks), not lagged
```

**Weekly chain**: closing(w) = opening(w) + inflows(w) − outflows(w);
opening(w+1) = closing(w). Plan a conservation check on every week.

**Headroom line**: facility limit − drawn balance, with a conditional flag
row when headroom < threshold. The minimum-headroom week is usually the
single most important output — plan a MIN + MATCH callout for it.

**Actuals discipline**: as weeks close, actuals enter a separate row layer
(same as budget rolling logic) — forecast accuracy tracking comes free.

## Valuation (DCF)

**Plan the value bridge before the cashflows**: FCFF → discount at WACC →
enterprise value → less net debt → equity value → per share. Each step is a
visible row; no compound mega-formula.

- **Discounting**: plan period-end vs mid-year convention as an explicit
  switch, not an assumption buried in a formula.
- **Terminal value**: Gordon growth `FCF×(1+g)/(WACC−g)` or exit multiple —
  plan BOTH as rows with a method switch if the client is undecided; flag
  that TV is typically 60-80% of EV so the g and WACC inputs deserve
  validation rules.
- **WACC build**: component rows (risk-free, beta, ERP, size premium, cost of
  debt, tax shield, weights) — never a single input cell.
- **Sensitivity**: plan a two-way data table (WACC × g) with the base case at
  the centre cell.

## Detailed Operational

**Physical units flow first; dollars are derived.** Plan two distinct layers:

```
Layer 1 (physical): demand → capacity constraint (MIN) → production →
                    yield/recovery → saleable output → inventory movement
Layer 2 (financial): saleable output × price = revenue
                     production × unit cost rates = operating cost
```

Never let a dollar formula reach back past the physical layer. The physical
layer needs its own conservation checks (inventory: opening + production −
sales = closing; utilisation ≤ 100%).

## Dashboard / Reporting

**Three-layer rule**: Raw data → Staging/KPI calculations → Display. Charts
and cards point ONLY at the staging layer. This makes data refresh safe and
keeps display formulas trivial.

- Plan a **KPI register**: each KPI gets a row with explicit
  numerator/denominator/source/refresh frequency. This register becomes both
  the staging layer spec and the user documentation.
- Plan a **single period selector cell** (data-validated) that drives every
  visual via INDEX — one cell changes the whole dashboard.

## Model Optimisation

The "calculation pattern" is a **process**, not a layout:

1. **Diagnose**: run the fm-5-test audit suite against the ORIGINAL model
   first. The findings list IS the requirements document.
2. **Tie-out harness**: before changing anything, snapshot the original's key
   outputs (10-30 cells). Plan a tie-out sheet in the new model: new output,
   original value, difference, tolerance. Every difference must be zero or a
   documented defect fix.
3. **Migrate in slices**: restructure one calculation chain at a time,
   re-running the tie-out after each slice.

## Feasibility / Investment Appraisal

- **Incremental only**: plan an explicit "excluded as sunk" list in the
  assumptions section — auditors look for it.
- **Like-for-like options**: if comparing options, all options share ONE
  assumptions section with per-option columns; never one sheet per option
  with independently drifting assumptions.
- **Returns block**: NPV (rate as input row), IRR (with guard for
  non-converging cashflow patterns), discounted payback (MATCH on cumulative
  discounted cashflow sign change).

## Strategic / Scenario

**Switch architecture**: one live-case cell (data-validated list); every
scenario-dependent assumption row holds per-scenario values in adjacent
columns and a live column computed via `INDEX(scenario_columns, , Live_Case)`.

Two design rules:

1. **Calculations only ever read the live column.** If any formula reads a
   scenario column directly, switching cases silently fails — plan an audit
   row that counts direct references (should be zero).
2. **The comparison sheet reads all scenarios simultaneously** by re-deriving
   key outputs per scenario via INDEX — it must not require flipping the live
   case to populate.
