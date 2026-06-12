# Semantic Formula Rules

Rules for detecting mismatches between cell formulas and their row/column labels. Each rule defines a label pattern and the expected formula characteristics.

## Rule Format

Each rule has:
- **Label patterns**: Keywords or regex patterns to match in row labels or column headers
- **Expected formula traits**: What the formula should contain or do
- **Mismatch condition**: When to flag the formula
- **Severity**: Default severity for violations

---

## Rules

### R001: Total / Subtotal
- **Label patterns**: `total`, `subtotal`, `sum`, `grand total`, `net total`
- **Expected**: Formula uses `SUM()`, `SUBTOTAL()`, `AGGREGATE()`, or adds multiple cells with `+`
- **Flag when**: Formula is a multiplication, division, single cell reference, or hardcoded value
- **Severity**: Critical
- **Comment template**: "Label indicates a total/sum but formula does not aggregate. Expected SUM or addition."

### R002: Per Unit / Per Item / Average / Mean
- **Label patterns**: `per unit`, `per item`, `average`, `avg`, `mean`, `unit price`, `unit cost`, `per capita`, `rate per`
- **Expected**: Formula contains a division operation (`/`) or uses `AVERAGE()`, `AVERAGEIF()`, `AVERAGEIFS()`
- **Flag when**: Formula is a simple multiplication (`*`) without any division
- **Severity**: Critical
- **Comment template**: "Label suggests a per-unit or average calculation but formula does not divide. Got [operation] instead."

### R003: Percentage / Rate / Ratio
- **Label patterns**: `%`, `percent`, `percentage`, `ratio`, `proportion`, `margin`, `yield`, `rate` (but not `rate per`)
- **Expected**: Formula divides one value by another, or result is formatted as percentage
- **Flag when**: Formula is a sum, multiplication without a denominator, or hardcoded non-decimal value
- **Severity**: Warning
- **Comment template**: "Label indicates a percentage/ratio but formula does not compute a proportion."

### R004: Variance / Difference / Delta / Change
- **Label patterns**: `variance`, `difference`, `delta`, `change`, `movement`, `increase`, `decrease`, `deviation`
- **Expected**: Formula subtracts one value from another (`-`) or uses comparison
- **Flag when**: Formula is a multiplication, division, or SUM without subtraction
- **Severity**: Warning
- **Comment template**: "Label suggests a variance/difference but formula does not subtract."

### R005: Growth / Growth Rate / YoY / MoM / QoQ
- **Label patterns**: `growth`, `yoy`, `y-o-y`, `mom`, `m-o-m`, `qoq`, `q-o-q`, `cagr`, `growth rate`
- **Expected**: Formula computes `(new - old) / old` or similar period-over-period ratio
- **Flag when**: Formula is a simple sum, single reference, or multiplication without period comparison
- **Severity**: Warning
- **Comment template**: "Label suggests a growth calculation but formula does not compare periods."

### R006: Count / Number of
- **Label patterns**: `count`, `number of`, `# of`, `no. of`, `qty`, `quantity`, `headcount`, `units`
- **Expected**: Formula uses `COUNT()`, `COUNTA()`, `COUNTIF()`, `COUNTIFS()`, `ROWS()`, or `SUM()` of 1/0 flags
- **Flag when**: Formula is a multiplication, division, or percentage calculation
- **Severity**: Warning
- **Comment template**: "Label indicates a count but formula performs arithmetic rather than counting."

### R007: Cumulative / Running Total / YTD / To Date
- **Label patterns**: `cumulative`, `running total`, `ytd`, `year to date`, `mtd`, `qtd`, `to date`, `accumulated`
- **Expected**: Formula references a prior cumulative cell plus current period, or uses expanding SUM range
- **Flag when**: Formula only references current period without accumulation
- **Severity**: Warning
- **Comment template**: "Label suggests cumulative calculation but formula does not accumulate prior periods."

### R008: Max / Min / Highest / Lowest / Peak
- **Label patterns**: `max`, `maximum`, `min`, `minimum`, `highest`, `lowest`, `peak`, `floor`, `ceiling`, `cap`
- **Expected**: Formula uses `MAX()`, `MIN()`, `LARGE()`, `SMALL()`, or conditional logic
- **Flag when**: Formula is a sum, average, or simple reference
- **Severity**: Info
- **Comment template**: "Label suggests a max/min operation but formula does not use MAX/MIN or equivalent."

### R009: Weighted Average / WACC / Blended
- **Label patterns**: `weighted`, `wacc`, `blended`, `composite`
- **Expected**: Formula multiplies weights by values then divides by total weight, or uses SUMPRODUCT
- **Flag when**: Formula uses simple AVERAGE() or SUM() without weighting
- **Severity**: Warning
- **Comment template**: "Label suggests weighted calculation but formula does not apply weights."

### R010: Balance / Closing / Opening / Ending
- **Label patterns**: `opening balance`, `closing balance`, `ending balance`, `beginning balance`, `ob`, `cb`
- **Expected**: Opening balance formula references prior period closing; Closing = Opening + Additions - Deductions
- **Flag when**: Formula doesn't follow balance roll-forward logic
- **Severity**: Warning
- **Comment template**: "Label indicates a balance but formula does not follow expected roll-forward pattern."

### R011: Net / After / Post
- **Label patterns**: `net`, `after tax`, `post-tax`, `after deductions`, `net of`
- **Expected**: Formula subtracts deductions/tax from a gross figure
- **Flag when**: Formula only adds or multiplies without any subtraction
- **Severity**: Warning
- **Comment template**: "Label suggests a net figure but formula does not subtract deductions."

### R012: Gross / Before / Pre
- **Label patterns**: `gross`, `before tax`, `pre-tax`, `before deductions`
- **Expected**: Formula should NOT subtract tax/deductions (that would make it net)
- **Flag when**: Formula subtracts tax-related items when label says "gross/before"
- **Severity**: Info
- **Comment template**: "Label suggests a gross figure but formula appears to subtract deductions, which would produce a net figure."

---

## Ambiguous Cases (Pass to AI)

The following situations should be flagged for AI review rather than auto-classified:

1. **Multiple operations**: Formula contains both multiplication and division — could be unit price or could be a complex calculation
2. **Nested functions**: `IF(condition, SUM(...), AVERAGE(...))` — depends on which branch is relevant
3. **Label is vague**: "Calculation", "Result", "Output", "Value", "Amount" — not enough semantic information
4. **Cross-sheet references**: Formula pulls from another sheet — need to understand the source context
5. **Named ranges in formulas**: The named range name might clarify intent but needs interpretation
6. **INDIRECT/OFFSET formulas**: Dynamic references that can't be statically analyzed
7. **Custom function calls**: UDFs or LAMBDA names that aren't standard Excel functions

For these cases, the script should output the formula, all surrounding context (row label, column header, adjacent cells, sheet name), and let Claude make the determination.
