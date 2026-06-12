# Question Bank — Round 2 Deep Dive

> First identify the model type, then load only the relevant question file(s). Ask one group at a time — let the user respond before moving on.

## Step 1: Identify the Model Type

Not every engagement is a 3-statement model. Sam builds across a wide range — identify which type early so you ask the right questions:

| Model Type | Trigger Phrases | Question File |
|-----------|----------------|---------------|
| **3-Statement / Corporate** | "P&L, balance sheet, cash flow", "full financial model" | `questions/financial_statements.md` |
| **Budget / Rolling Budget** | "annual budget", "rolling forecast", "departmental budget" | `questions/budget.md` |
| **Project Finance / PPP** | "debt covenants", "DSCR", "cash waterfall", "concession" | `questions/project_finance.md` + `questions/financial_statements.md` |
| **Valuation (DCF / Comparables)** | "what's it worth", "DCF", "enterprise value" | `questions/valuation.md` |
| **M&A / LBO** | "acquisition model", "leveraged buyout", "synergies" | `questions/mna_lbo.md` + `questions/financial_statements.md` |
| **Commission / Incentive** | "sales commission", "bonus calculation", "tiered rates" | `questions/commission.md` |
| **Detailed Operational** | "mine plan", "production schedule", "every component" | `questions/operational.md` |
| **Cost Allocation** | "cost centre", "overhead allocation", "charge-back" | `questions/cost_allocation.md` |
| **Cashflow Forecast** | "13-week cashflow", "liquidity", "cash runway" | `questions/cashflow.md` |
| **Model Optimisation** | "fix the model", "improve", "rebuild", "too slow" | `questions/optimisation.md` |
| **Dashboard / Reporting** | "executive summary", "KPI dashboard" | `questions/dashboard.md` |
| **Feasibility / Investment** | "should we invest", "go/no-go", "feasibility" | `questions/financial_statements.md` |
| **Strategic / Scenario** | "strategic options", "what if", "long-range plan" | `questions/financial_statements.md` |

Many engagements combine types (e.g., project finance + detailed operational). Load multiple question files as needed.

---

## Step 2: Universal Questions (always ask these)

### Group A — Timeline & Structure
- Model start date and financial year-end month?
- Periodicity — annual, quarterly, or monthly? (Suggest: "Annual is simpler and usually sufficient unless you need monthly cash flow visibility for debt covenants or seasonal patterns.")
- How many forecast periods?
- Is there a construction/development phase before operations?
- Any historical periods to include? How many?

### Group B — Outputs & Deliverables
- What key metrics matter? (NPV, IRR, DSCR, payback, margins, ROI?)
- Who will use this model day-to-day? What decisions does it support?
- Dashboard or summary page needed?
- Base/Upside/Downside cases?
- Which variables should be sensitisable?
- Any specific format requirements? (e.g., lender template, board pack format)

---

## Step 3: Load the relevant question file(s) from the table above
