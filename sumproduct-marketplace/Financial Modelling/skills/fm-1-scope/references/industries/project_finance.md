# Project Finance (cross-sector)

> Common patterns for any project-financed deal, regardless of underlying sector.

## Debt Structure to Suggest
- **Senior debt** — term loan with sculpted repayments to DSCR targets
- **Cash sweep** — excess cash applied to accelerated repayment
- **Reserve accounts** — Debt Service Reserve (6 months), Maintenance Reserve, Distribution Lock-up
- **Cash waterfall** — strict priority of payments (opex -> debt service -> reserves -> equity)
- **Lock-up test** — distributions to equity only if DSCR > threshold (typically 1.10-1.20x)
- **Default test** — if DSCR < 1.00x, technical default

## Key Ratios
- **DSCR** — CFADS / Debt Service (target 1.20-1.50x depending on sector)
- **LLCR** — NPV of remaining CFADS / Outstanding Debt
- **PLCR** — NPV of project life CFADS / Outstanding Debt
- **Gearing** — Debt / (Debt + Equity) at financial close

## Common Pitfalls
- Circularity from interest on cash balance
- Not sculpting repayments (flat repayments waste debt capacity)
- Cash waterfall order wrong (equity before reserves)
- Forgetting that DSCR is a period-by-period test, not an average
- Tax timing differences (cash tax vs accounting tax)
