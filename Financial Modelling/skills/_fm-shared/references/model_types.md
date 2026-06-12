# Model Type Registry — Canonical Reference

**This is the single source of truth for model types across all fm- skills.**
Phase skills (fm-1 through fm-6) and the orchestrator reference this file
instead of maintaining their own type tables. When a phase needs
phase-specific detail (e.g. which question file to load, which formula
patterns to use), that detail lives in the phase's own references — but the
type definitions, skeletons, and applicability rules live HERE.

## How to use this file

1. **Identify the type** in Phase 1 using the trigger phrases below.
2. **Record it** in `scope.md` (Model Type field) and `lifecycle_log.md`.
3. **Every later phase reads the type** and applies only the elements marked
   applicable for it.
4. Many engagements **combine types** (project finance + operational; budget +
   dashboard). Apply the union of both types' elements.

## Universal elements (every model, every type)

These apply regardless of type — they are the CRaFT backbone:

| Element | Notes |
|---------|-------|
| Cover sheet | Project identity, version, developer |
| Navigator sheet | Hyperlinked TOC |
| Style Guide sheet | Documents the Cell Styles used |
| Model Parameters sheet | Technical constants, unit labels |
| Timing engine | Wherever the model is periodic (almost always) |
| Error Checks sheet | Consolidated checks — contents vary by type |
| Change Log sheet | Version history |
| Cell Styles (not direct formatting) | Per fm-3-design |
| Named ranges for units/constants | Per fm-3-design |
| Uniform R1C1 formulas per row | Per fm-4-build Rule 2 |

## Complexity scaling (applies to every type)

Each type below lists a **Simple → Standard → Complex** scale. Match the build
to the decision at stake, not to what is technically possible:

- **Simple**: single sheet of inputs + outputs may suffice; skip sub-schedules;
  annual periodicity; no scenario engine. Right when the decision is low-stakes
  or the deadline is days away.
- **Standard**: the full skeleton for the type; quarterly/monthly as needed;
  base + 1-2 scenarios.
- **Complex**: adds consolidation, multi-entity, multi-currency, full scenario
  engine, per-unit sub-schedules. Only when the audience (lender, board,
  regulator) or the decision requires it.

Rule of thumb: **start Standard, justify any move to Complex against the
scope's stated decision.** Complexity that doesn't serve the decision is a
maintenance liability.

---

## Type 1: 3-Statement / Corporate

- **Trigger phrases**: "P&L, balance sheet, cash flow", "full financial model", "integrated model", "three-way"
- **Skeleton (14)**: Cover, Navigator, Style Guide, Model Parameters, Timing, General Assumptions, Calculations, Opening BS, Income Statement, Balance Sheet, Cash Flow Statement, Lookup, Error Checks, Change Log
- **Core calculation patterns**: control accounts (working capital, fixed assets, debt, tax, retained earnings); statements link-only to Calculations
- **Key outputs**: IS / BS / CFS, margins, NPAT, net cash
- **Type-specific checks**: BS balances each period; CFS reconciles to BS cash movement; Opening BS ties
- **Scaling**: Simple = P&L + cash summary only (no BS). Complex = multi-entity consolidation, intercompany eliminations.

## Type 2: Budget / Rolling Budget

- **Trigger phrases**: "annual budget", "rolling forecast", "departmental budget", "budget vs actuals"
- **Skeleton (~9)**: Cover, Navigator, Style Guide, Model Parameters, Timing, Budget Inputs (per department or via a repeating template), Consolidation, Variance Analysis, Change Log
- **Core calculation patterns**: department template (identical layout per dept — critical for consolidation via 3-D SUM or structured references); allocation keys for shared costs; rolling-period shift logic (actuals replace budget as months close)
- **Key outputs**: consolidated budget, variance to actuals, per-department views
- **Type-specific checks**: department subtotals = consolidated total; variance = actual − budget per period; allocation keys sum to 100%
- **Scaling**: Simple = single-sheet budget. Complex = 20+ departments with approval-stage tracking and driver-based re-forecast.

## Type 3: Project Finance / PPP

- **Trigger phrases**: "debt covenants", "DSCR", "cash waterfall", "concession", "availability payments", "sculpted repayment"
- **Skeleton**: 3-Statement skeleton **plus** Debt Schedule, Cash Waterfall, Covenant Summary; usually Construction Schedule
- **Core calculation patterns**: all 3-statement patterns plus debt sculpting (target DSCR back-solve), cash cascade ordering, reserve accounts (DSRA/MMRA), lock-up tests
- **Key outputs**: DSCR / LLCR / PLCR per period, equity IRR, waterfall by tier
- **Type-specific checks**: 3-statement checks plus waterfall conservation (cash in = cash distributed + retained); covenant flags fire at correct thresholds
- **Scaling**: Simple = single facility, annuity repayment. Complex = multi-tranche, sculpted, with refinancing cases.

## Type 4: Valuation (DCF / Comparables)

- **Trigger phrases**: "what's it worth", "DCF", "enterprise value", "WACC", "terminal value"
- **Skeleton (~7)**: Cover, Navigator, Style Guide, Model Parameters, Forecast Assumptions, DCF Build, Sensitivity Output, Change Log (+ Comparables sheet if comps used)
- **Core calculation patterns**: FCFF/FCFE build, mid-year convention discounting, terminal value (Gordon growth or exit multiple — state which), WACC build from components, EV→equity bridge
- **Key outputs**: enterprise value, equity value, value per share, sensitivity matrix (WACC × growth)
- **Type-specific checks**: TV formula matches stated approach; WACC reconciles to weighted components; sensitivity matrix centre = base case
- **Scaling**: Simple = 5-year FCF + Gordon TV on one sheet. Complex = full 3-statement feed + scenario-weighted valuation + comps triangulation.

## Type 5: M&A / LBO

- **Trigger phrases**: "acquisition model", "leveraged buyout", "synergies", "accretion/dilution", "sources and uses"
- **Skeleton**: 3-Statement skeleton **plus** Sources & Uses, Transaction Assumptions, Synergies, Returns Analysis (and Debt Schedule for LBO)
- **Core calculation patterns**: purchase price allocation, goodwill calc, pro-forma combination, debt paydown cascade, IRR/MOIC returns
- **Key outputs**: accretion/dilution, pro-forma EPS, sponsor IRR/MOIC, credit metrics
- **Type-specific checks**: sources = uses; pro-forma BS balances post-combination; goodwill non-negative (or flagged)
- **Scaling**: Simple = single-target accretion screen. Complex = multi-tranche LBO with management rollover and earn-outs.

## Type 6: Commission / Incentive

- **Trigger phrases**: "sales commission", "bonus calculation", "tiered rates", "clawback", "quota"
- **Skeleton (~8)**: Cover, Navigator, Style Guide, Model Parameters, Rep Data, Commission Rules, Commission Engine, Pay-out Reports, Change Log
- **Core calculation patterns**: tier banding (marginal vs cliff — state which; marginal uses the SUMPRODUCT band-differential pattern), attainment vs quota, clawback ledger (a control account: opening clawback + new − recovered = closing), override/manager rollup
- **Key outputs**: per-rep payout, total commission expense, attainment distribution
- **Type-specific checks**: tier boundaries match rules sheet; sum of per-rep = total payable; no payout where attainment below threshold; clawback ledger closes
- **Scaling**: Simple = flat-rate per rep. Complex = multi-element plans (base + accelerators + SPIFFs + overrides) with territory splits.

## Type 7: Detailed Operational

- **Trigger phrases**: "mine plan", "production schedule", "every component", "fleet model", "capacity plan"
- **Skeleton**: varies — Cover/Navigator/Style Guide/Parameters/Timing plus per-resource schedules (production, fleet, labour, consumables), Operating Cost Build, and usually a financial summary
- **Core calculation patterns**: physical units first, dollars second (volume × yield × price); capacity constraint logic (MIN of demand and capacity); resource calendars; unit-cost roll-ups
- **Key outputs**: production profile, unit costs, resource utilisation, cost per unit
- **Type-specific checks**: physical balances (production ≤ capacity; inventory conservation); unit-cost recalculation ties to total cost / total units
- **Scaling**: Simple = annual volumes × average cost. Complex = equipment-level scheduling with maintenance windows.

## Type 8: Cost Allocation

- **Trigger phrases**: "cost centre", "overhead allocation", "charge-back", "shared services"
- **Skeleton (~7)**: Cover, Navigator, Style Guide, Model Parameters, Cost Pools, Drivers, Allocation Output, Change Log
- **Core calculation patterns**: pool → driver → recipient matrix; step-down vs reciprocal allocation (state which; reciprocal needs iteration or matrix algebra — usually approximate with 2-3 step-down passes); driver normalisation (each driver column sums to 1)
- **Key outputs**: allocated cost per recipient, before/after department P&L impact
- **Type-specific checks**: allocated total = pool total (conservation); no driver sums to zero; no recipient gets a negative allocation unintentionally
- **Scaling**: Simple = one pool, one driver. Complex = reciprocal multi-pass with service-department cross-charges.

## Type 9: Cashflow Forecast (13-week / liquidity)

- **Trigger phrases**: "13-week cashflow", "liquidity", "cash runway", "working capital crunch"
- **Skeleton (~7)**: Cover, Navigator, Style Guide, Model Parameters, Cash Inflows, Cash Outflows, Liquidity Summary, Change Log
- **Core calculation patterns**: receipts/payments timing offsets from P&L events (debtor days lag applied to invoicing); weekly buckets; opening + inflows − outflows = closing, chained week to week; facility headroom = limit − drawn
- **Key outputs**: weekly closing cash, headroom, minimum-cash week flagged
- **Type-specific checks**: closing = opening + net flow every week (no plugs); headroom breach flags fire; actuals vs forecast variance once weeks close
- **Scaling**: Simple = 13 columns of direct estimates. Complex = receipts engine driven by invoice-level ageing.

## Type 10: Model Optimisation

- **Trigger phrases**: "fix the model", "improve", "rebuild", "too slow", "inherited this model"
- **Skeleton**: inherits the original model's type — the deliverable is the *improved* model plus a before/after comparison
- **Core calculation patterns**: diagnose first (run the fm-5-test audit suite on the ORIGINAL); the "plan" is a migration path; preserve numerical outputs while restructuring (tie-out check: new outputs = old outputs given same inputs)
- **Key outputs**: tie-out report, performance/size comparison, list of defects fixed
- **Type-specific checks**: **tie-out is the critical check** — every key output matches the original to rounding tolerance, or the difference is a documented defect fix
- **Scaling**: Simple = formula cleanup in place. Complex = full rebuild on the standard skeleton with parallel-run period.

## Type 11: Dashboard / Reporting

- **Trigger phrases**: "executive summary", "KPI dashboard", "monthly reporting pack"
- **Skeleton (~6)**: Cover, Navigator, Style Guide, Data Source(s), KPI Calculations, Dashboard, Change Log
- **Core calculation patterns**: staging layer between raw data and display (never point charts at raw data); KPI definitions with explicit numerator/denominator; period selector driving all visuals from one cell
- **Key outputs**: the dashboard sheet itself; KPI definitions register
- **Type-specific checks**: every KPI traces to a data source; refresh pulls new data; period selector changes all visuals consistently
- **Scaling**: Simple = one page, static monthly. Complex = slicer-driven multi-page with drill-through and Power Query refresh.

## Type 12: Feasibility / Investment Appraisal

- **Trigger phrases**: "should we invest", "go/no-go", "feasibility", "business case"
- **Skeleton**: usually 3-Statement skeleton, often without full BS (P&L + cashflow + returns); plus an Options Comparison sheet when comparing alternatives
- **Core calculation patterns**: incremental cashflows only (exclude sunk costs — note them in scope as exclusions); NPV/IRR/payback on the increment; option comparison on identical assumptions
- **Key outputs**: NPV, IRR, payback, sensitivity tornado, option ranking
- **Type-specific checks**: discount rate consistency (nominal vs real matches cashflow basis); terminal assumptions stated; options compared on like-for-like timing
- **Scaling**: Simple = single-option NPV on one sheet. Complex = multi-option with risk-weighted scenarios.

## Type 13: Strategic / Scenario

- **Trigger phrases**: "strategic options", "what if", "long-range plan", "scenario planning"
- **Skeleton**: base type's skeleton (often 3-statement or feasibility) **plus** Scenario Manager sheet (switch architecture) and Comparison Output sheet
- **Core calculation patterns**: scenario switch via INDEX/CHOOSE on a single live-case cell; assumptions stored per-scenario in columns, never overwritten; comparison table reads all scenarios simultaneously via INDEX
- **Key outputs**: side-by-side scenario comparison, crossover analysis
- **Type-specific checks**: switching scenarios changes ALL dependent outputs (no orphaned hardcodes); each scenario's assumption set is complete (no fallthrough to base accidentally)
- **Scaling**: Simple = 3 hardwired cases. Complex = Monte Carlo or full factorial sensitivity grid.

---

## Phase applicability matrix

Which phase elements apply per type. ✅ = always, ◐ = adapt, ✗ = skip.

| Element | 3-Stmt | Budget | ProjFin | Valn | M&A | Comm | Ops | Alloc | CashF | Optim | Dash | Feas | Strat |
|---------|--------|--------|---------|------|-----|------|-----|-------|-------|-------|------|------|-------|
| Phase 1 question file (`fm-1-scope/references/questions/`) | financial_statements | budget | project_finance + financial_statements | valuation | mna_lbo + financial_statements | commission | operational | cost_allocation | cashflow | optimisation | dashboard | financial_statements | financial_statements |
| Control accounts (fm-2 Stage 5) | ✅ | ✗ | ✅ | ✗ | ✅ | ◐ (clawback ledger) | ◐ (assets/inventory) | ✗ | ✗ | inherits | ✗ | ◐ | ◐ |
| IS/BS/CFS wiring | ✅ | ◐ (P&L only) | ✅ | ◐ (P&L+CF) | ✅ | ✗ | ◐ | ✗ | ✗ | inherits | ✗ | ◐ | ◐ |
| BS-balance / CFS-recon checks (fm-5) | ✅ | ✗ | ✅ | ✗ | ✅ | ✗ | ◐ | ✗ | ✗ | inherits | ✗ | ◐ | ◐ |
| Conservation check (type-specific, fm-5) | n/a | dept Σ = consol | waterfall | n/a | S&U balance | Σ reps = total | physical balance | Σ alloc = pool | weekly chain | tie-out | KPI trace | n/a | switch integrity |
| Timing engine | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ◐ | ✅ weekly | inherits | ◐ | ✅ | ✅ |
| Scenario engine | ◐ | ◐ | ✅ | ✅ | ✅ | ✗ | ◐ | ✗ | ◐ | ✗ | ✗ | ✅ | ✅ |

## Where the per-phase detail lives

| Phase | Reference with per-type detail |
|-------|-------------------------------|
| 1 Scope | `fm-1-scope/references/question_bank.md` (router) + `questions/<type>.md` + `scope_template.md` (per-type sections) |
| 2 Plan | `fm-2-plan/references/patterns/calculation_patterns_by_type.md` + `plan_template.md` (per-type sections) |
| 3 Design | full style register applies to all types; smaller models simply use fewer styles |
| 4 Build | `fm-4-build/references/formula_patterns.md` (3-statement) + `formula_patterns_by_type.md` (all other types) |
| 5 Test | `fm-5-test/references/audit_suite_guide.md` (applicability matrix) + type-conditional pre-test checks in SKILL.md |
| 6 Implement | `handover_reference.md` is type-agnostic; User Guide content varies naturally with outputs |
