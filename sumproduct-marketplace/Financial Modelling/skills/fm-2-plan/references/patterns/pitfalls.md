# Common Pitfalls by Model Type

## ANY Model
| Pitfall | Why It Matters | Prevention |
|---------|---------------|-----------|
| Hardcoded values in Calculations | Invisible assumptions, audit nightmare | ALL inputs on Assumptions sheet |
| Formulas not uniform across row | Pattern breaks cause silent errors | Check R1C1 consistency |
| Balance sheet doesn't balance | Fundamental integrity failure | Use control account pattern; ROUND check |
| CFS doesn't reconcile to BS cash | Missing a movement | Ensure every BS change flows through CFS |
| No error checks | Problems go undetected | Always build checks sheet |
| First period formula different from others | Initialisation logic needed | Document first-period exceptions |

## Project Finance
| Pitfall | Prevention |
|---------|-----------|
| Circular reference (interest on cash) | Use average balance: (Opening + Closing) / 2 |
| Cash waterfall order wrong | Operating costs -> Senior debt -> Reserves -> Equity |
| DSCR calculated on wrong period | DSCR is per-period, not cumulative |
| Sculpted repayments don't converge | Use iterative Goal Seek or manual convergence |
| Distribution lock-up logic missing | Test: if DSCR < lock-up threshold, dividends = 0 |

## 3-Statement Corporate
| Pitfall | Prevention |
|---------|-----------|
| Retained earnings doesn't link to NPAT | RE = Opening RE + NPAT - Dividends |
| Deferred tax ignored | Model temporary differences between accounting and tax depreciation |
| Working capital signs wrong | Increase in receivables = cash OUTFLOW (negative on CFS) |
| Dividends on CFS but not in RE | Must appear in both places |

## Mining
| Pitfall | Prevention |
|---------|-----------|
| Forgetting rehabilitation provisioning | Accrue over mine life, release at closure |
| Using mine life in years instead of linking to ore reserves | Deplete reserves to drive mine life dynamically |
| Not handling stripping ratios | Overburden increases as mine deepens |

## Energy / Renewables
| Pitfall | Prevention |
|---------|-----------|
| Assuming constant capacity factor | Varies by season and degrades over time |
| Forgetting degradation in solar/wind | Solar ~0.5%/year |
| Not modelling curtailment risk | Grid constraints may force output reduction |

## Real Estate
| Pitfall | Prevention |
|---------|-----------|
| Not staggering lease expiries | Cliff-edge risk |
| Forgetting tenant incentive amortisation | Amortise over lease term |
| Vacancy rates being static instead of dynamic | Model lease-by-lease |

## Budget / Rolling Forecast
| Pitfall | Prevention |
|---------|-----------|
| No version control between forecast cycles | Track which forecast version is current |
| Allocation keys not documented | Make allocation bases transparent and auditable |
| Actuals overwriting forecast without trace | Keep actuals and forecast in separate rows |

## Commission / Incentive
| Pitfall | Prevention |
|---------|-----------|
| Not recalculating full YTD on clawback | Removing revenue can cross tier boundaries |
| Ignoring timing of commission trigger | Booking vs invoicing vs cash receipt changes amounts |
| No cap/floor handling | Can blow out costs if uncapped |
