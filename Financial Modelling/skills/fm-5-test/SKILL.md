---
name: fm-5-test
description: >
  Phase 5 of the financial model build lifecycle — the audit-and-fix-retest-loop phase. Test the built model
  by running the full audit-skill suite, classify findings, manage the fix/retest loop — automatically
  categorising issues, routing fixes back to Phase 4 (Build), tracking fix status, and re-testing until the
  model passes. Includes pre-test sanity checks, full audit suite execution, finding classification,
  fix-and-retest loop management, and final sign-off. Trigger on 'test the model', 'run audit checks',
  'quality check', 'validate the model', 'check for errors', or after completing the Build phase.
---

# Phase 5: Test 🧪

> *"Trust, but verify — then fix — then verify again."*

## Mission

Run the full audit suite against the built model, classify every finding, route fixes back to Build, and repeat until the model passes. This phase is not just "run audits" — it's the quality gate that manages the **fix-and-retest loop**.

## Prerequisites

### Important References

Before running any test, read these reference files:

1. `references/audit_suite_guide.md` — How to invoke each audit skill (execution order, dependencies, per-skill inputs/outputs, standard findings format, consolidation rules, when to skip)
2. `references/fix_loop_protocol.md` — Finding classification, fix routing matrix, Fix List template, retest protocol, loop tracking, escalation rules
3. `../_fm-shared/references/craft_principles.md` — CRaFT philosophy (Consistency, Robustness, Flexibility, Transparency) as guiding principles — not a rigid checklist but a quality compass for framing findings and guiding Build decisions
4. `references/audit_skills_pointer.md` — pointer table to the LIVE skills for
   all 15 audit agents (sentry, logic, ai, stylist, efficiency, lingo,
   architect, hyperlinks, vba, pq, navigator, cartographer, audit-manager,
   detailed-audit-report, generalizer). The live SKILL.md files are the
   authoritative fix guides — when a finding is raised, follow the pointer to
   the matching skill for its full process, rule catalogue, and special rules.

### Audit Suite Overview

The full set of audit skills (priority order, when to skip each, dependencies)
is documented in `references/audit_suite_guide.md`. At a glance:

| Tier | Skills | Always run? |
|------|--------|-------------|
| **Required** | sentry 🛡️, logic 🧠, stylist 🎨, efficiency ⚡, lingo ✍️ | Yes |
| **Recommended** | architect 🏗️, hyperlinks 🔗, vba 📦 (.xlsm only), pq ⚡ (Power Query only), navigator 🧭, cartographer 🗺️ | Yes unless skipped per `audit_suite_guide.md` rules |
| **Reporting** | ag-detailed-audit-report 📊 | Final pass only |

When raising a finding, follow `references/audit_skills_pointer.md` to the
live skill for the authoritative fix process.

---

## Process

### STEP 1: PRE-TEST SANITY CHECK

Run the checklist in `references/pretest_checklist.md` — an [ALWAYS] block
(mechanically covered by `python ../_fm-shared/scripts/verify_build.py
"<model>.xlsx"`) plus conditional blocks per model type. Confirm the model
type from `scope.md` first; per-type applicability and the "N/A is not a
pass" reporting rule are in `references/audit_suite_guide.md` Section 6.

If any applicable check fails → **STOP. Create a pre-test fix list and return
to Phase 4 — don't waste a full audit on a broken file.**

### STEP 2: RUN AUDIT SUITE (First Pass)

**Generate the workbook digest first** — it gives every audit skill its raw
material in one pass instead of repeated COM exploration:

```bash
python ../_fm-shared/scripts/inspect_workbook.py "<model>.xlsx" --out xray.md
```

Read `xray.md` before invoking any auditor: Section 3 (R1C1 pattern groups)
pre-computes the Logic auditor's pattern-break detection; Section 2 flags
broken names for Sentry; Section 8 flags broken hyperlinks. Auditors then
verify and judge rather than re-discover.

Execute each audit skill in priority order following the **execution order and dependency rules** in `references/audit_suite_guide.md`.

For each skill:
1. Read the skill's SKILL.md (and the invocation guide for that skill)
2. Point it at the model file path
3. Collect findings in the **standard findings format** (see `references/audit_suite_guide.md` Section 3)

After running standard audit skills, also assess the model against the **CRaFT principles** from `../_fm-shared/references/craft_principles.md`. Frame findings in terms of which principle they violate (Consistency, Robustness, Flexibility, or Transparency). Not every model needs to achieve every technique — use pragmatic judgment based on the model's complexity and audience.

After ALL skills and CRaFT checks have run, consolidate into the **Master Finding List** using the **consolidation rules** from `references/audit_suite_guide.md` Section 4.

### STEP 3: CLASSIFY FINDINGS

Classify every finding on two dimensions — **severity** (🔴 Critical / ⚠️
Warning / 🟡 Info) and **fix routing** (which phase fixes it: most go to
Phase 4 Build; structural issues to Phase 3 Design; missing requirements to
Phase 1 Scope). The full severity definitions and routing matrix are in
`references/fix_loop_protocol.md` Sections 1–2.

### STEP 4: PRODUCE FIX LIST

Generate the **Fix List** using the template in
`references/fix_loop_protocol.md` Section 3 — the actionable document Phase 4
executes, grouped Critical → Warning → Info → Accepted, each row carrying
agent, sheet, cell(s), issue, and concrete fix action.

### STEP 5: FEEDBACK LOOP — FIX AND RETEST

```
RUN TEST ──▶ FIX LIST ──▶ BUILD (Phase 4) ──▶ RETEST (full suite) ──▶ ...
```

Core rules (full retest protocol, Test Pass Log template, and escalation
rules: `references/fix_loop_protocol.md` Sections 4–6):

1. Build addresses the Fix List in order and marks each fix done.
2. Retest runs the **FULL audit suite** — fixing one thing can break another.
3. New findings join the Fix List; loop until PASS or CONDITIONAL PASS.
4. **At loop 4**: flag a possible structural problem and suggest reviewing
   Design (Phase 3) or Scope (Phase 1). At loop 5: pause and review the Plan.

### STEP 6: DETERMINE VERDICT

| Verdict | Criteria | Next Step |
|---------|----------|-----------|
| ✅ **PASS** | 0 critical, 0 warnings | Proceed to Phase 6 (Implement) |
| ⚠️ **CONDITIONAL PASS** | 0 critical, warnings present but user-accepted | Proceed to Phase 6 with accepted items logged |
| ❌ **FAIL — Build** | Critical or unacceptable warnings | Generate Fix List → Phase 4 → Retest |
| ❌ **FAIL — Design** | Systematic issues (wrong structure, missing styles) | → Phase 3 → Phase 4 → Retest |
| ❌ **FAIL — Scope** | Missing functionality, wrong model type | → Phase 1 → Phase 2 → Phase 3 → Phase 4 → Retest |

### STEP 7: FINAL TEST REPORT

Once verdict is PASS or CONDITIONAL PASS, produce `test_report.md` using the
template in `references/test_report_template.md` (per-agent pass summary,
CRaFT compliance table with N/A handling per model type, fix history,
accepted items, recommendation).

---

## Sam Best-Practice Assessment

CRaFT principles: `../_fm-shared/references/craft_principles.md`. Use them as
a quality compass, not a rigid pass/fail checklist — rigour should match the
model's complexity and audience (see "Applying CRaFT Pragmatically" there).

When raising findings, **frame them against CRaFT** so the user understands
*why* something matters — e.g. *"Row 47 has a different R1C1 pattern from the
rest of the row — this breaks Consistency and makes the formula harder to
audit."* The principles guide has framing examples for all four qualities.
