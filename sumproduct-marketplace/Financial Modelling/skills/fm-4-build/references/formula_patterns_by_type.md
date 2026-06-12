# Formula Patterns by Model Type (non-3-statement)

Concrete Excel formula patterns for the model types not covered by
`formula_patterns.md` (which serves 3-statement / project finance / M&A).
Design rationale for each pattern: `fm-2-plan/references/patterns/calculation_patterns_by_type.md`.
Type registry: `_fm-shared/references/model_types.md`.

All patterns follow fm-4-build's critical rules: uniform R1C1 across period
columns, labels linked not retyped, units via named ranges.

---

## Budget / Rolling Budget

**3-D consolidation across identical department sheets** (sheets must be
contiguous in the tab order, bracketed by marker sheets if needed):

```
='Dept Alpha:Dept Omega'!J14            ← wrong: this is a reference, not a sum
=SUM('Dept Alpha:Dept Omega'!J14)       ← correct 3-D sum
```

pywin32 note: enter 3-D formulas via `.Formula`, not `.FormulaR1C1` — the R1C1
form of 3-D references is error-prone through COM.

**Rolling actual/budget switch** (Last_Actual_Period is a named cell;
row 8 holds the period counter):

```
=IF(J$8<=Last_Actual_Period, J24, J25)      ← J24 actuals layer, J25 budget layer
R1C1: =IF(R8C<=Last_Actual_Period, R[ -2]C, R[-1]C)
```

**Variance % with guard**:

```
=IF(J25=0, 0, (J24-J25)/J25)
```

**Allocation-key completeness check** (one per driver row):

```
=ROUND(SUM(J30:S30)-1, Rounding_Accuracy)    ← 0 when key sums to 100%
```

## Commission / Incentive

**Marginal tier engine** — tier table at `$E$40:$F$44` (col E lower bounds
ascending starting at 0, col F rates). The SUMPRODUCT band-differential
pattern computes marginal commission on attainment in J17 in ONE row:

```
=SUMPRODUCT( (J17>$E$40:$E$44) * (J17-$E$40:$E$44) *
             ($F$40:$F$44 - IFERROR(OFFSET($F$40:$F$44,-1,0)*($E$40:$E$44>0),0)) )
```

Prefer the transparent multi-row version unless rows are at a premium — one
row per band:

```
Band 1 commission: =MIN(J17,$E$41)*$F$40
Band 2 commission: =MAX(0, MIN(J17,$E$42)-$E$41)*$F$41
...
Total:             =SUM(band rows)
```

The multi-row form is CRaFT-preferred (Transparency); use it by default.

**Cliff tier** (single rate on whole amount):

```
=J17 * VLOOKUP(J17/J16, $E$40:$F$44, 2, TRUE)    ← J16 quota, lookup on attainment %
```

Tier table MUST be ascending for the TRUE (range) lookup — add a check row:
`=SUMPRODUCT(--($E$41:$E$44<=$E$40:$E$43))` (0 when strictly ascending).

**Clawback ledger** (control account, per rep):

```
Opening   =K52 (prior closing)
New       =IF(cancellation event, commission previously paid, 0)
Recovered =MIN(Opening+New, recovery this period)
Closing   =Opening + New − Recovered
```

**Payout conservation check**:

```
=ROUND(SUM(per-rep payout column) − engine total payable, Rounding_Accuracy)
```

## Cost Allocation

**Allocation grid** — pools in rows 20-29, recipients in columns J-S, driver
percentages in the grid, pool totals in column H:

```
Allocated cell:        =$H20*J$18          ← pool total × driver %
Driver check (col T):  =ROUND(SUM(J18:S18)-1, Rounding_Accuracy)
Conservation (row 31): =ROUND(SUM(J20:J29 across all cols) − SUM($H20:$H29), Rounding_Accuracy)
```

**Step-down**: order pools so service departments allocate first; once a pool
has allocated, it receives nothing (its receiving cells are zero by
construction — enforce with layout, not IF logic).

## Cashflow Forecast (13-week)

**Lagged receipts** (debtor days ≈ N weeks, invoicing in row 14, lag weeks in
a named cell `Receipt_Lag_Weeks`):

```
=IF(J$8>Receipt_Lag_Weeks, INDEX($14:$14, 1, COLUMN()-Receipt_Lag_Weeks), 0)
```

INDEX-on-counter, not OFFSET — OFFSET is volatile (fm-efficiency rule).

**Weekly cash chain**:

```
Opening (row 40): =I46              ← prior week closing; first week links Opening_Cash
Closing (row 46): =J40+J42-J44      ← opening + inflows − outflows
Conservation:     =ROUND(J46-(J40+J42-J44), Rounding_Accuracy)   ← always 0
```

**Headroom + breach flag**:

```
Headroom: =Facility_Limit - J48
Flag:     =IF(J50<Min_Headroom, 1, 0)        ← CF turns the cell red when 1
Min week: =INDEX(J$6:U$6, MATCH(MIN(J50:U50), J50:U50, 0))
```

## Valuation (DCF)

**Discount factor with mid-year switch** (`Mid_Year` named cell = 0 or 0.5;
row 8 period counter):

```
=1/(1+WACC)^(J$8-Mid_Year)
```

**Terminal value, both methods with a switch** (`TV_Method` = 1 Gordon, 2 exit
multiple):

```
Gordon row:   =Final_FCF*(1+LT_Growth)/(WACC-LT_Growth)
Multiple row: =Final_EBITDA*Exit_Multiple
TV live:      =CHOOSE(TV_Method, Gordon_row, Multiple_row)
TV PV:        =TV_live * final period discount factor
```

Add validation on `LT_Growth < WACC` (else Gordon explodes):
check row `=IF(LT_Growth>=WACC, 1, 0)`.

**EV → equity bridge** (one visible row per step):

```
Enterprise Value  =SUM(PV of FCF rows) + TV_PV
Less: Net Debt    =-Net_Debt
Equity Value      =SUM(above)
Per Share         =Equity_Value/Shares_Outstanding
```

## Detailed Operational

**Capacity-constrained production**:

```
=MIN(J20, J22)        ← demand vs capacity, both visible rows above
```

**Inventory conservation (physical control account)**:

```
Closing units = Opening + Production − Sales
Check:        =ROUND(J30-(J27+J28-J29), Rounding_Accuracy)
```

**Unit cost tie-back check**:

```
=ROUND(Total_Operating_Cost/Total_Units − Reported_Unit_Cost, Rounding_Accuracy)
```

## Dashboard / Reporting

**Single period selector driving all visuals** (`Selected_Period` is a
data-validated named cell; staging rows hold full time series):

```
KPI card value: =INDEX(Staging!J24:U24, , MATCH(Selected_Period, Staging!J$6:U$6, 0))
```

**KPI staging row** (explicit numerator/denominator — never compute inside
the chart source):

```
=IF(Staging!J18=0, 0, Staging!J14/Staging!J18)
```

## Model Optimisation

**Tie-out row** (new model output vs snapshot of original):

```
=ROUND(NewOutput_cell − Original_Snapshot_cell, Rounding_Accuracy)
```

Snapshot the original values as PASTED VALUES (not links to the old file) —
the old workbook will not ship with the deliverable. Conditional format the
tie-out column with the standard green/red error-check rules.

## Strategic / Scenario

**Live-case INDEX switch** (scenario assumptions in columns K-M, live column J;
`Live_Case` is a data-validated named cell holding 1, 2 or 3):

```
J (live) = INDEX(K17:M17, , Live_Case)
```

**Comparison sheet reads all scenarios without switching** — re-derive a key
output per scenario column. Where outputs are too entangled to re-derive,
use a macro-free alternative: a data table with `Live_Case` as the column
input cell, capturing key outputs per case.

**No-direct-reference audit** (counts formulas that bypass the live column —
run during build, target 0):

```python
# pywin32 sweep: any formula on calc sheets referencing scenario columns directly?
bad = []
for ws in calc_sheets:
    rng = ws.UsedRange
    for cell in rng.SpecialCells(-4123):   # xlCellTypeFormulas
        if "'General Assumptions'!K" in cell.Formula or \
           "'General Assumptions'!L" in cell.Formula or \
           "'General Assumptions'!M" in cell.Formula:
            bad.append((ws.Name, cell.Address))
```
