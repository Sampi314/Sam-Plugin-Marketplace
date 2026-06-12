# Fix Loop Protocol

> How findings become fixes, how fixes route to the right phase, and how retesting works.

## Table of Contents
1. [Finding Classification](#1-finding-classification)
2. [Fix Routing Matrix](#2-fix-routing-matrix)
3. [Fix List Template](#3-fix-list-template)
4. [Retest Protocol](#4-retest-protocol)
5. [Loop Tracking](#5-loop-tracking)
6. [Escalation Rules](#6-escalation-rules)

---

## 1. Finding Classification

Every finding is classified on **two dimensions**: severity and fix destination.

### Severity

The three-level scale — 🔴 Critical / ⚠️ Warning / 🟡 Info, with meanings,
delivery impact, and JSON values — is defined once in
`../../_excel-shared/references/audit_standards.md` §3. Severity arrives from
every auditor as a **dedicated column** in the unified findings table, so no
mapping step is needed. Only when consuming a historic report that still uses
description prefixes, map `🔴 HIGH:` → Critical, `⚠️ MEDIUM:` → Warning,
`🟡 LOW:` → Info (the legacy mapping in audit_standards.md §3).

### Acceptance

Warnings and Info items can be **accepted** (user decides not to fix). Accepted items:
- Are removed from the active Fix List
- Are logged in the "Accepted Items" section of the Test Report
- Do NOT count against the pass/fail verdict
- Must include a reason for acceptance

**Critical items can NEVER be accepted** — they must be fixed.

---

## 2. Fix Routing Matrix

Every finding routes to a specific phase for fixing. The routing determines which phase the loop returns to.

### By Error Type

| Error Type | Examples | Route To | Why |
|-----------|---------|----------|-----|
| **Formula error** | Wrong reference, pattern break, missing SUM, incorrect operator, hardcoded value in Calculations | Phase 4 (Build) | Formula fix in existing structure |
| **Number format error** | Percentage shown as General, date shown as number, wrong decimal places | Phase 4 (Build) | Format fix on existing cells |
| **Cell Style error** | Wrong named style applied, missing style, style not created | Phase 4 (Build) | Style application fix |
| **Navigation error** | Broken hyperlink, missing TOC entry, missing return link | Phase 4 (Build) | Hyperlink fix |
| **Validation error** | Missing data validation, broken list source, wrong validation type | Phase 4 (Build) | Validation fix |
| **Naming/text error** | Typo in label, inconsistent terminology, missing unit label | Phase 4 (Build) | Text/label fix |
| **Named range error** | Missing named range, dead name, wrong reference | Phase 4 (Build) | Name Manager fix |
| **Conditional formatting error** | Missing CF rule, wrong colours, wrong range | Phase 4 (Build) | CF fix |
| **Mega-Formula** | Formula > 500 chars, needs decomposition into helper rows | Phase 4 (Build) | Structural formula change |
| **Structural issue** | Wrong sheet order, missing section, wrong column layout, missing sheet | Phase 3 (Design) | Design revision needed |
| **Style convention missing** | Cell Style not defined in workbook, Style Guide sheet incomplete | Phase 3 (Design) | Design spec incomplete |
| **Missing functionality** | Scope item not modelled, wrong model type, missing revenue stream | Phase 1 (Scope) | Scope gap |
| **Wrong calculation approach** | Depreciation method wrong, tax logic incorrect for jurisdiction | Phase 2 (Plan) | Plan revision needed |

### By Agent

| Agent | Typical Route | Exception |
|-------|--------------|-----------|
| Sentry 🛡️ | Phase 4 (Build) | Dead names from missing sheets → Phase 3 |
| Logic 🧠 | Phase 4 (Build) | Wrong calculation approach → Phase 2 |
| Stylist 🎨 | Phase 4 (Build) | Missing Cell Styles → Phase 3 |
| Efficiency ⚡ | Phase 4 (Build) | Mega-Formula requiring new helper rows → may need Phase 2 if section redesign |
| Lingo ✍️ | Phase 4 (Build) | Always Build |
| Architect 🏗️ | Phase 3 (Design) | Structural issues are design problems by definition |
| Hyperlinks 🔗 | Phase 4 (Build) | Missing sheets → Phase 3 |
| VBA 📦 | Phase 4 (Build) | Always Build |
| PQ ⚡ | Phase 4 (Build) | Architecture issues → Phase 3 |

### Routing Decision Flowchart

```
Finding detected
    │
    ▼
Is it a formula, format, style, link, validation, or text fix
on an EXISTING cell/sheet?
    │
    ├── YES → Phase 4 (Build)
    │
    ▼
Does it require a NEW sheet, NEW section, or CHANGED structure?
    │
    ├── YES → Phase 3 (Design) → then Phase 4 (Build)
    │
    ▼
Does it indicate a missing requirement or wrong model type?
    │
    ├── YES → Phase 1 (Scope) → then Phase 2 → 3 → 4
    │
    ▼
Does it indicate a wrong calculation approach (not just wrong formula)?
    │
    ├── YES → Phase 2 (Plan) → then Phase 3 → 4
    │
    ▼
Phase 4 (Build) — default
```

---

## 3. Fix List Template

The Fix List is the handoff document from Test to Build (or Design/Scope).

```markdown
# Fix List: [Model Name] — Test Pass [n]

**Date**: [date]
**Model file**: [path]
**Test verdict**: ❌ FAIL
**Total findings**: [n] (🔴 [n] Critical, ⚠️ [n] Warning, 🟡 [n] Info)
**Route**: Phase [4/3/2/1]

---

## Critical Fixes (MUST DO — blocks delivery)

| # | Agent | Sheet | Cell(s) | Category | Description | Fix Action | Status |
|---|-------|-------|---------|----------|-------------|-----------|--------|
| 1 | Logic 🧠 | Calculations | J47:AC47 | Pattern Break | R1C1 `=R[-2]C*R[-1]C` expected, J47 has `=J45*J46+100` | Remove +100, reference assumption cell | ☐ Open |
| 2 | Sentry 🛡️ | Balance Sheet | K57 | Dead Name | HL_BS_Balance refers to #REF! | Fix named range to point to correct cell | ☐ Open |
| 3 | Stylist 🎨 | Gen Assumptions | J30:AC30 | Number Format | Percentage input formatted as General | Apply NumberFormat = '0%' after Assumption style | ☐ Open |

## Warning Fixes (SHOULD DO — or accept with reason)

| # | Agent | Sheet | Cell(s) | Category | Description | Fix Action | Status |
|---|-------|-------|---------|----------|-------------|-----------|--------|
| 4 | Efficiency ⚡ | Calculations | J211 | Mega-Formula | 823 chars, correct but unauditable | Break into 3 helper rows | ☐ Open |
| 5 | Lingo ✍️ | Multiple | B3,D15,E42 | Inconsistent Naming | "Cashflow" ×3 vs "Cash Flow" ×8 | Standardise to "Cash Flow" | ☐ Open |

## Info Fixes (NICE TO DO — not blocking)

| # | Agent | Sheet | Cell(s) | Category | Description | Fix Action | Status |
|---|-------|-------|---------|----------|-------------|-----------|--------|
| 6 | Hyperlinks 🔗 | Lookup | A3:E3 | Missing Return Link | No Navigator links in row 3 | Add 5 HL_Navigator hyperlinks | ☐ Open |

## Accepted Items (user chose not to fix)

| # | Agent | Category | Description | Acceptance Reason | Accepted By |
|---|-------|----------|-------------|------------------|------------|
```

### Status Values

| Status | Meaning |
|--------|---------|
| ☐ Open | Not yet addressed |
| 🔧 In Progress | Build is working on it |
| ✅ Fixed | Fix applied, awaiting retest |
| ✅ Verified | Fix confirmed in retest |
| ↩️ Reopened | Fix didn't work, needs another attempt |
| 🚫 Accepted | User accepted, not fixing |

---

## 4. Retest Protocol

### Why Full Retest?

After Build applies fixes, Test runs the **entire audit suite again** — not just the checks that failed. Reasons:

1. **Fixing one formula can break another** (e.g., fixing a reference that was used downstream)
2. **Style changes can cascade** (changing a named style definition affects all cells using it)
3. **Named range fixes can affect multiple sheets** (a single name is used everywhere)
4. **New issues may be introduced** during the fix process

### Retest Procedure

1. Build marks all Fix List items as "✅ Fixed"
2. Test receives the updated model file
3. Test runs the **pre-test sanity check** (Step 1 in main SKILL.md)
4. If sanity check passes → run full audit suite
5. If sanity check fails → return to Build immediately
6. Compare new findings against previous Fix List:
   - Items that no longer appear → mark "✅ Verified"
   - Items that still appear → mark "↩️ Reopened" with notes
   - **New items** → add to Fix List with next sequence number
7. Produce updated Fix List for next loop (if needed)

### Delta Report

After each retest, produce a **delta** showing what changed:

```markdown
## Retest Delta: Pass [n-1] → Pass [n]

| Metric | Pass [n-1] | Pass [n] | Change |
|--------|-----------|---------|--------|
| Total findings | 12 | 4 | -8 |
| 🔴 Critical | 3 | 0 | -3 ✅ |
| ⚠️ Warning | 5 | 3 | -2 |
| 🟡 Info | 4 | 1 | -3 |

### Fixed (no longer appearing)
- #1: Logic pattern break in J47:AC47 ✅
- #2: Sentry dead name HL_BS_Balance ✅
- ...

### Still Open (reopened)
- #4: Efficiency Mega-Formula in J211 — still 823 chars (fix not applied?)

### New Issues
- #7: Stylist — Heading 2 style missing bottom border on row 35 (introduced during fix)
```

---

## 5. Loop Tracking

Maintain the **Test Pass Log** across all iterations:

```markdown
## Test Pass Log

| Pass | Date | Findings | 🔴 | ⚠️ | 🟡 | Verdict | Route | Notes |
|------|------|----------|-----|-----|-----|---------|-------|-------|
| 1 | [date] | 12 | 3 | 5 | 4 | ❌ FAIL | → Build | 3 critical formula errors |
| 2 | [date] | 4 | 0 | 3 | 1 | ⚠️ COND | — | User reviewing 3 warnings |
| 3 | [date] | 1 | 0 | 0 | 1 | ✅ PASS | → Implement | 1 info item accepted |
```

### Expected Trajectory

A healthy fix loop looks like this:
- **Pass 1**: 10–20 findings (initial build always has issues)
- **Pass 2**: 2–5 findings (most issues fixed, a few new ones from fixes)
- **Pass 3**: 0–2 findings (clean or nearly clean)

If findings are **not decreasing** between passes, something is wrong — escalate.

---

## 6. Escalation Rules

### Warning at Loop 4

If still failing after 3 complete passes:

> *"We've been through 3 fix cycles and still have [n] findings. This may indicate a deeper issue. I recommend we pause and review:"*
> - *"Are the remaining issues symptomatic of a **structural problem**? (→ Phase 3 Design)"*
> - *"Is there a **misunderstanding of requirements**? (→ Phase 1 Scope)"*
> - *"Or are these genuinely independent issues that just need more time? (→ Continue Phase 4)"*

### Routing Decision Tree (loop ≥ 4)

When the loop counter reaches 4, stop patching and read the **reopened
findings as a cluster** — then route:

```
Loop counter ≥ 4 — examine the reopened findings as a cluster
    │
    ▼
Majority are formatting / Cell Style / named-range structural issues?
    │
    ├── YES → Phase 3 (Design) review
    │
    ▼
Findings describe missing functionality or the wrong model type?
    │
    ├── YES → Phase 1 (Scope) review
    │
    ▼
Same findings reopening because the calculation approach is wrong?
    │
    ├── YES → Phase 2 (Plan) review
    │
    ▼
Heterogeneous, independent items with the count trending down?
    │
    ├── YES → Continue Phase 4 (Build) fix loop
    │
    ▼
Loop counter ≥ 5 → HARD STOP — mandatory Phase 2/3 review with the user
```

The cluster signature tells you which upstream artefact is wrong. A loop that
keeps reopening the same *kind* of finding is not a build problem — style and
structure clusters implicate the Design spec, functionality gaps implicate the
Scope, and recurring calculation rewrites implicate the Plan. Continuing to
patch in Phase 4 treats the symptoms while the defective upstream artefact
keeps regenerating them.

### Hard Stop at Loop 5

If still failing after 5 passes, the hard stop in the decision tree applies —
do not run another Phase 4 cycle. Review the Plan (Phase 2) or Design
(Phase 3) **with the user** before continuing:

> *"After 5 fix cycles, the model still has [n] critical findings. I strongly recommend stepping back to Phase [2/3] to review the [plan/design] before continuing. Continuing to patch individual fixes is not productive."*

### Regression Escalation

If a retest produces **more** total findings than the previous pass:

> *"⚠️ Regression detected: Pass [n] has [X] findings vs [Y] in pass [n-1]. The fixes may have introduced new problems. I recommend reviewing the changes made in the last Build pass before continuing."*
