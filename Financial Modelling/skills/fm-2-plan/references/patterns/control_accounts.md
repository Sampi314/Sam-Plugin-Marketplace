# Control Account Patterns

Every balance sheet item follows the same structure. The "balancing figure" approach guarantees the BS always balances by construction.

## Pattern A: Working Capital (Days-Based)

Used for: Trade Receivables, Trade Payables, Inventory

```
Opening balance     = Prior period Closing (or Opening BS for first period)
+ Additions         = Revenue (for receivables) / COGS (for payables) / Purchases (for inventory)
- Deductions        = Cash movement (BALANCING FIGURE)
= Closing balance   = Additions in period x Days assumption / Days in period
```

The **cash movement** is derived: `Cash = Opening + Additions - Closing`

This means you calculate the Closing balance first (from the days assumption), then derive what cash must have moved.

**Example: Trade Receivables**
```
Row 1: Opening receivables    = Prior period's Row 4
Row 2: Revenue                = link to Revenue calculation
Row 3: Cash receipts          = Row 4 - Row 1 - Row 2  (balancing figure)
Row 4: Closing receivables    = Revenue x Days_receivable / Days_in_period
```

**Example: Trade Payables**
```
Row 1: Opening payables       = Prior period's Row 4
Row 2: COGS                   = link to COGS calculation (or Purchases)
Row 3: Cash payments           = Row 4 - Row 1 - Row 2  (balancing figure, usually negative)
Row 4: Closing payables       = COGS x Days_payable / Days_in_period
```

## Pattern B: Fixed Asset Register

Used for: PPE, Intangibles, Right-of-Use Assets

```
GROSS ASSET:
  Opening gross      = Prior period Closing gross
  + CapEx            = link to CapEx assumption
  - Disposals        = link to disposal assumption (if any)
  = Closing gross    = Opening + CapEx - Disposals

ACCUMULATED DEPRECIATION:
  Opening accum dep  = Prior period Closing accum dep
  + Depreciation     = Closing gross x (1 / Useful life)  [straight-line]
                       OR Opening net x Dep rate          [diminishing value]
  - Disposal dep     = accumulated dep on disposed assets
  = Closing accum    = Opening + Depreciation - Disposal dep

NET BOOK VALUE:
  = Closing gross - Closing accum dep
```

## Pattern C: Debt Facility

Used for: Term loans, Revolvers, Bonds

```
Opening balance     = Prior period Closing
+ Drawdowns         = per drawdown schedule / availability
- Repayments        = per repayment profile (see variants below)
= Closing balance   = Opening + Drawdowns - Repayments

INTEREST:
  Interest expense  = Average balance x Interest rate x Days_in_period / Days_in_year
  (Average balance  = (Opening + Closing) / 2)
```

**Repayment Variants:**
- **Equal instalments**: Fixed repayment per period
- **Bullet**: Zero repayments until maturity, then full balance
- **Amortising (equal principal)**: Balance / Remaining periods
- **Sculpted (to target DSCR)**: Repayment = CFADS / Target DSCR - Interest
- **Cash sweep**: Excess cash after distributions applied to early repayment

## Pattern D: Tax Computation

```
NPBT (from Income Statement)
+ / - Temporary differences (depreciation vs tax depreciation)
+ / - Permanent differences (non-deductible expenses)
= Taxable income

Tax @ rate           = MAX(Taxable income, 0) x Tax rate
Less: Utilised losses = MIN(Tax losses b/f, Taxable income x Tax rate)  [if applicable]
= Tax payable

Tax losses:
  Opening losses     = Prior period Closing
  + New losses       = MAX(-Taxable income, 0)
  - Utilised         = as above
  = Closing losses
```

## Pattern E: Retained Earnings

```
Opening retained earnings = Prior period Closing
+ NPAT                    = from Income Statement
- Dividends               = per dividend policy (% of NPAT or fixed amount)
= Closing retained earnings
```
