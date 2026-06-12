# Final Test Report Template

Produce `test_report.md` once the verdict is PASS or CONDITIONAL PASS (Step 7).

```markdown
# Test Report: [Model Name]

**Date**: [date]
**Model**: [filename]
**Model Type**: [from scope.md]
**Test Passes**: [n]
**Final Verdict**: ✅ PASS / ⚠️ CONDITIONAL PASS

## Summary

| Agent | Pass 1 | Pass 2 | ... | Final |
|-------|--------|--------|-----|-------|
| Sentry 🛡️ | 3 | 1 | | 0 |
| Logic 🧠 | 4 | 2 | | 0 |
| Stylist 🎨 | 2 | 0 | | 0 |
| Efficiency ⚡ | 1 | 1 | | 0 |
| Lingo ✍️ | 2 | 0 | | 0 |
| Architect 🏗️ | 0 | 0 | | 0 |
| Hyperlinks 🔗 | 1 | 0 | | 0 |
| **Total** | **13** | **4** | | **0** |

## CRaFT Compliance

Mark checks N/A where the model type makes them inapplicable (see
audit_suite_guide.md Section 6) — "N/A — [type]", never a hollow ✅.

| Quality | Check | Result |
|---------|-------|--------|
| **Consistency** | Uniform header block (rows 1–9) across all periodic sheets | ✅ |
| **Consistency** | Same R1C1 formula pattern across all period columns per row | ✅ |
| **Consistency** | Cell Styles applied correctly (Assumption = yellow, etc.) | ✅ |
| **Robustness** | No circular references | ✅ |
| **Robustness** | All error checks pass (Overall_Error_Check = 0) | ✅ |
| **Robustness** | Data validation on all input cells | ✅ |
| **Robustness** | Type-specific conservation check passes | ✅ / N/A |
| **Flexibility** | Timing is parameterised (periodicity changeable) | ✅ |
| **Flexibility** | No hardcoded values in Calculations | ✅ |
| **Transparency** | Units column uses named ranges | ✅ |
| **Transparency** | Formula audit column (FORMULATEXT) in Calculations | ✅ / N/A |
| **Transparency** | Style Guide sheet documents all styles | ✅ |

## Fix History

[Include the full Fix List with all passes and resolutions]

## Accepted Items

| # | Agent | Issue | Reason for Acceptance |
|---|-------|-------|----------------------|

## Recommendation

[PASS → proceed to Phase 6 / CONDITIONAL → proceed with noted caveats]
```
