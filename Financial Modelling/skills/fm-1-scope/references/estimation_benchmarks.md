# Estimation Benchmarks

> Hour estimates for a junior analyst building each model section. Use with the Effort Estimation sub-skill.

## Base Hours by Section

| Section | Simple | Typical | Complex | What Drives Complexity |
|---------|--------|---------|---------|----------------------|
| **Setup** (sheets, styles, timing, params, nav) | 2 | 3 | 5 | Template vs greenfield; number of sheets |
| **Revenue** (per stream) | 1.5 | 3 | 6 | Flat vs ramp-up vs seasonal; contractual vs market |
| **COGS / Direct Costs** (per category) | 1 | 2 | 4 | Margin-based vs activity-based vs multi-input |
| **Operating Expenditure** | 1 | 2 | 4 | Number of line items; headcount model adds 2-4 hrs |
| **Staff Costs** (if separate) | — | 3 | 6 | FTE tracking, salary bands, on-costs, leave provisions |
| **CapEx** (per asset class) | 1 | 2 | 4 | Single purchase vs staged construction vs phased delivery |
| **Depreciation** | 0.5 | 1.5 | 3 | Straight-line vs DV vs UOP; multiple asset registers |
| **Debt** (per facility) | 2 | 4 | 8 | Bullet vs amortising vs sculpted; covenants add 2-4 hrs |
| **Working Capital** | 1.5 | 2.5 | 4 | Number of control accounts; inventory models add time |
| **Tax** | 1.5 | 3 | 6 | Simple rate vs deferred tax vs multi-jurisdiction |
| **Financial Statements** (IS+BS+CFS) | 3 | 4 | 6 | Number of line items; balance check complexity |
| **Error Checks** | 1 | 1.5 | 2 | Number of checks; custom checks beyond standard |
| **Scenarios / Sensitivity** | 1.5 | 3 | 5 | Number of scenarios; data table sensitivity adds time |
| **Dashboard / Summary** | 1.5 | 3 | 5 | Charts; conditional formatting; dynamic layouts |
| **Documentation** | 2 | 3 | 5 | User guide; calculation reference; flowcharts |
| **Review & Iteration** (per round) | 2 | 3 | 5 | Complexity of client feedback; number of changes |

## QA Hours (separate from build)

| Section | QA Hours | Notes |
|---------|----------|-------|
| Setup & structure | 0.5 | Quick check — styles, navigation, timing |
| Per calculation section | 0.5–1.5 | Formula review, R1C1 consistency, label matching |
| Financial statements | 1–2 | Balance check, CFS reconciliation, cross-sheet links |
| Full model (high-level) | 1–2 | Overall sense check, output reasonableness |
| Full model (detailed) | 3–6 | Cell-by-cell audit — typically for lender models |

## Complexity Multipliers

| Factor | Multiplier | Trigger Conditions |
|--------|-----------|-------------------|
| Monthly periodicity | ×1.3 | 12 columns per year vs 1; more formulas, more validation |
| Quarterly periodicity | ×1.1 | 4 columns per year |
| Multiple currencies | ×1.2 | FX conversion logic; separate FX assumption sheet |
| Multiple entities | ×1.5–2.0 | Per-entity sheets; intercompany transactions; consolidation |
| Construction + operations | ×1.3 | Different logic per phase; phase transition handling |
| Lender/regulatory format | ×1.2 | Specific output layouts; covenant calculations; cash waterfall |
| Greenfield (no template) | ×1.3 | Starting from blank; style setup; all boilerplate from scratch |
| Template-based build | ×0.8 | Starting from Sam template with styles pre-configured |
| Complex debt (sculpted) | ×1.2 | Applied to debt section only — iterative solver for sculpting |
| Sensitivity / data tables | ×1.1 | 2-variable data tables; scenario management engine |

## Typical Model Sizes

| Model Type | Sheets | Assumptions | Calc Rows | Typical Total Hours | QA Hours |
|-----------|--------|------------|-----------|--------------------|---------| 
| Simple budget (annual) | 8–10 | 15–30 | 50–100 | 20–35 | 4–6 |
| Standard 3-statement | 12–14 | 30–60 | 100–250 | 40–70 | 8–12 |
| Project finance (single asset) | 14–18 | 50–100 | 200–400 | 70–120 | 15–25 |
| Project finance (complex/PPP) | 18–25 | 80–150 | 300–600 | 100–180 | 25–40 |
| Multi-entity consolidation | 20–30+ | 100–200+ | 400–800+ | 150–250+ | 30–50+ |

## Fee Range Calculation

```
Base hours = sum of section hours from table above
Adjusted hours = Base hours × product of applicable multipliers
QA hours = sum of QA hours from table above
Total hours = Adjusted hours + QA hours
Buffer = Total hours × 15% (contingency for unknowns)
Grand total = Total hours + Buffer

Fee range:
  Low  = Grand total × hourly rate × 0.9
  High = Grand total × hourly rate × 1.1
```

## Caveats to Always Include

1. Estimate assumes requirements are confirmed and stable
2. Significant scope changes require re-estimation
3. QA hours assume a single review pass
4. Does not include client meeting time or data gathering
5. Does not include strategic advice or interpretation of results
6. Timeline depends on information availability and feedback turnaround
7. Complex iterative calculations (e.g., sculpted debt) may require additional time
