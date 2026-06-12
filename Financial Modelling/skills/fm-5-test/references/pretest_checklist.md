# Pre-Test Sanity Checklist

Run BEFORE any audit skill. If any applicable check fails, stop immediately
and return to Phase 4 (Build) — don't waste a full audit on a broken file.

**The model type drives which conditional blocks apply.** Confirm the type
from `scope.md`. Type definitions: `../../_fm-shared/references/model_types.md`.

Tip: `python ../../_fm-shared/scripts/verify_build.py "<model>.xlsx"` covers
the [ALWAYS] block mechanically (exit 0 = pass).

```
[ALWAYS]
[ ] File opens without Excel errors or recovery prompts
[ ] All expected sheets present and in correct order
[ ] Timing sheet dates look correct (spot-check first + last period)
[ ] Overall_Error_Check = 0 (all ticks on Error Checks sheet)
[ ] Named ranges exist in Name Manager (Ctrl+F3)
[ ] Cell Styles visible in Home → Cell Styles → Custom
[ ] At least one Navigator hyperlink works

[3-STATEMENT / PROJECT FINANCE / M&A-LBO / FEASIBILITY]
[ ] Balance Sheet balances (row 57 checks = 0)
[ ] Cash Flow Statement reconciles (row 59 checks = 0)

[BUDGET / ROLLING BUDGET]
[ ] Department subtotals sum to consolidated total
[ ] Variance = Actuals - Budget across every period

[COMMISSION / INCENTIVE]
[ ] Tier boundaries match the rules sheet
[ ] Total commission payable = sum of per-rep payouts

[COST ALLOCATION]
[ ] Allocated total = pool total (cross-check)
[ ] No allocation driver sums to zero

[CASHFLOW FORECAST]
[ ] Closing cash = Opening cash + Net inflow each period
[ ] Liquidity headroom never goes below threshold without flag

[DASHBOARD / REPORTING]
[ ] Every KPI traces to a data source
[ ] Refresh actually pulls new data

[VALUATION (DCF)]
[ ] Terminal value formula matches stated approach
[ ] WACC build reconciles to weighted average
```
