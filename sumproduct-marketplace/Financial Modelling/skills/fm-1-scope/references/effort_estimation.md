# Effort Estimation & Quoting Sub-Skill

> Only use when the user opts in to effort estimation. Read `estimation_benchmarks.md` alongside this file for the hour/multiplier data tables.

## When to Use
The user said "yes" to effort estimation at the start of scoping, OR they ask mid-conversation: "how long will this take?", "can you quote this?", "estimate hours", "what would this cost?"

## Process

### Step 1: Map Scope to Sections

Break the completed scope into model sections. Use the hour ranges from `estimation_benchmarks.md` to estimate junior analyst hours for each section.

| Phase | Section | Build (hrs) | QA (hrs) | Notes |
|-------|---------|-------------|----------|-------|
| Setup | Structure, timing, styles | X | X | |
| Revenue | [n] streams | X | X | |
| Costs | [n] categories | X | X | |
| CapEx | [n] asset classes | X | X | |
| Debt | [n] facilities | X | X | |
| WC/Tax | Working capital + tax | X | X | |
| Outputs | IS, BS, CFS, dashboard | X | X | |
| Checks | Error checks | X | X | |
| Scenarios | [n] scenarios | X | X | |
| Docs | Documentation | X | X | |
| Iteration | Review rounds (x[n]) | X | -- | |

### Step 2: Apply Complexity Multipliers

Check `estimation_benchmarks.md` for the full multiplier table. Apply all that are relevant — they compound multiplicatively.

### Step 3: Produce Estimate

```markdown
## Effort Estimate: [Project Name]

| Phase | Section | Build (hrs) | QA (hrs) |
|-------|---------|-------------|----------|
| ... | ... | ... | ... |
| **Subtotal** | | **X** | **X** |
| Complexity multiplier | [factor] x [reason] | | |
| **Total** | | **X hrs** | **X hrs** |
| **Grand Total** | Build + QA | **X hrs** | |

**Assumptions:**
- Junior analyst rate: $[rate]/hr
- Estimated fee range: $[low] -- $[high]

**Caveats:**
- Assumes stable requirements. Scope changes require re-estimation.
- QA assumes single review pass. Complex models may need additional review.
- Does not include client meeting time or data gathering.
- Estimate is for model construction only, not strategic advice or interpretation.
```
