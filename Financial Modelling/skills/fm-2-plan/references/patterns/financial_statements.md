# Financial Statement Mappings

Financial statement sheets contain **links only** — no new calculations.

## Income Statement Standard Lines

| Line | Source in Calculations | Notes |
|------|----------------------|-------|
| Revenue | Revenue section — total revenue row | |
| COGS | COGS section — total row | Negative value |
| **Gross Profit** | = Revenue + COGS | Only sum/subtraction allowed on FS |
| Wastage / Stock Loss | Inventory section — wastage row | If applicable |
| Operating Expenditure | OpEx section — total row | Negative |
| **EBITDA** | = Gross Profit + Wastage + OpEx | |
| Depreciation | Depreciation section — total row | Negative |
| Amortisation | Amortisation section — total row | If applicable |
| **EBIT** | = EBITDA + D&A | |
| Interest Income | Interest section — income row | If applicable |
| Interest Expense | Interest section — expense row | Negative |
| **NPBT** | = EBIT + Interest | |
| Tax Expense | Tax section — tax payable row | Negative |
| **NPAT** | = NPBT + Tax | |

## Balance Sheet Standard Lines

| Section | Line | Source | Notes |
|---------|------|--------|-------|
| Current Assets | Cash | Cash calculation — closing balance | |
| | Trade Receivables | WC section — closing receivables | |
| | Inventory | Inventory section — closing inventory | |
| | Other Current Assets | As applicable | |
| | **Total Current Assets** | = SUM | |
| Non-Current Assets | PPE (net) | Fixed asset register — net book value | |
| | Intangibles | If applicable | |
| | **Total Non-Current Assets** | = SUM | |
| **TOTAL ASSETS** | | = Total CA + Total NCA | |
| Current Liabilities | Trade Payables | WC section — closing payables | |
| | Tax Payable | Tax section — closing payable | If applicable |
| | Current Debt | Debt — current portion | |
| | **Total Current Liabilities** | = SUM | |
| Non-Current Liabilities | Long-term Debt | Debt — non-current portion | |
| | Other | As applicable | |
| | **Total Non-Current Liabilities** | = SUM | |
| **TOTAL LIABILITIES** | | = Total CL + Total NCL | |
| **NET ASSETS** | | = Total Assets - Total Liabilities | |
| Equity | Share Capital | Fixed or per equity raises | |
| | Retained Earnings | RE control account — closing | |
| | **Total Equity** | = SUM | |

## Balance Sheet Checks (rows 56-58)
```
Row 56: Error check   = (any formula errors in this sheet) x 1
Row 57: Balance check  = IF(Row56<>0, 0, (ROUND(Total Assets - Total Equity, Rounding_Accuracy) <> 0) x 1)
Row 58: Insolvency     = (Net Assets < 0) x 1
```

## Cash Flow Statement Standard Structure

| Section | Line | Source |
|---------|------|--------|
| **Operating** | NPAT | IS link |
| | Depreciation (add back) | Positive |
| | Working capital changes | Change in Receivables, Payables, Inventory |
| | Tax paid | Cash tax from tax section |
| | **Net Operating Cash Flow** | |
| **Investing** | CapEx | CapEx cash outflows |
| | Disposals | Proceeds |
| | **Net Investing Cash Flow** | |
| **Financing** | Debt drawdowns | |
| | Debt repayments | |
| | Interest paid | |
| | Equity injections | |
| | Dividends paid | |
| | **Net Financing Cash Flow** | |
| **Net Cash Movement** | | = Operating + Investing + Financing |
| Opening Cash | | = Prior period closing (or Opening BS) |
| **Closing Cash** | | = Opening + Net Movement |

## CFS Reconciliation Check
```
CFS Closing Cash - BS Cash = 0  (must reconcile)
```
