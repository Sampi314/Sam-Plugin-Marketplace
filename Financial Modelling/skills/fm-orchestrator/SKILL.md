---
name: fm-orchestrator
description: >
  Orchestrate the 6-phase financial model build lifecycle following Sam
  CRaFT methodology. Coordinates Scope, Plan, Design, Build, Test, and
  Implement phases by invoking dedicated sub-skills (fm-1-scope through
  fm-6-implement) at the right moments, carrying state between them. Use this
  skill whenever the user wants to create a financial model end-to-end, build
  a model from scratch, run the full model development lifecycle, or follow
  CRaFT methodology. Trigger on 'build a financial model', 'create a model',
  'full model build', 'model development', 'CRaFT model', 'end-to-end model',
  or any request for a managed Excel financial model build.
---

# Financial Model Orchestrator

> *"A model built with discipline is a model built to last."*

## Mission

Orchestrate the complete financial model build lifecycle using Sam's
CRaFT methodology (Consistency, Robustness, Flexibility, Transparency) across
six phases, each handled by a dedicated sub-skill.

## How orchestration actually works

The orchestrator does **not** read another skill's SKILL.md directly. Instead
it:

1. Determines which phase to start at (entry-point detection — see below).
2. Tells the user which sub-skill is about to run and why.
3. Invokes the sub-skill via the `Skill` tool.
4. Waits for the sub-skill's output artefact (`scope.md`, `plan.md`,
   `design.md`, the `.xlsx`, `test_report.md`, or the delivery package).
5. Confirms with the user before advancing to the next phase.
6. Carries forward references to artefacts so the next sub-skill knows where
   to look.

State is carried in two places: artefacts on disk in the working directory,
and a short orchestrator-maintained `lifecycle_log.md` in that same working
directory, structured exactly per `references/lifecycle_log_template.md`
(header block, phase table, fix-loop pass counter, decisions log). Keep that
shape — the orchestrator resumes mid-lifecycle by reading this file, and
ad-hoc log formats break resumption.

## Prerequisites

- **Windows OS** with Microsoft Excel installed
- **Python package**: `pywin32` (`pip install pywin32`)
- All 6 phase skills installed (`fm-1-scope` through `fm-6-implement`)
- Existing audit skills for Test phase (sentry, logic, stylist, lingo,
  efficiency, etc.)
- Shared resources at `.claude/skills/_fm-shared/`

## Phase overview

```
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────┐
│1.SCOPE │→│2.PLAN  │→│3.DESIGN│→│4.BUILD │→│5.TEST  │→│6.IMPLEMENT│
│What?   │ │How?    │ │Look?   │ │Make!   │ │Check!  │ │Deliver!  │
└────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └──────────┘
```

| Phase | Skill | Purpose | Output artefact |
|-------|-------|---------|----------------|
| 1. Scope | `fm-1-scope` | Gather requirements, define boundaries | `scope.md` |
| 2. Plan | `fm-2-plan` | Sheet structure, timeline, data flow | `plan.md` |
| 3. Design | `fm-3-design` | Cell Styles, named ranges, formats | `design.md` |
| 4. Build | `fm-4-build` | pywin32 construction of `.xlsx`/`.xlsm` | The workbook file |
| 5. Test | `fm-5-test` | Full audit + fix/retest loop | `test_report.md` |
| 6. Implement | `fm-6-implement` | Docs, protection, packaging | Delivery package folder |

## Model-type awareness

**Most Sam engagements are not 3-statement integrated models.**
The canonical registry of all 13 model types — skeletons, calculation
patterns, type-specific checks, complexity scaling — is
`../_fm-shared/references/model_types.md`. Phase 1 (`fm-1-scope`) routes scope
questioning by type via `fm-1-scope/references/question_bank.md`; Phase 2
(`fm-2-plan`) routes the sheet skeleton in its Stage 0; Phase 4 has per-type
formula patterns; Phase 5 has a per-type applicability matrix. The
orchestrator's job is to **carry the model type from Phase 1 into every
subsequent phase** — record it explicitly in `lifecycle_log.md` so each
sub-skill (especially Phase 5 / Test) applies the right checks.

If the user enters mid-lifecycle (e.g. "test this model I built"), ask which
model type it is so Phase 5 knows which sanity checks apply (BS balance and
CFS reconciliation only apply to 3-statement / project finance models).

## Entry-point detection

Read the user's request and route to the earliest phase that does not yet have
its input artefact:

| User says... | Start phase | Reason |
|--------------|-------------|--------|
| "Build me a model for X" (any type) | 1 | No scope yet |
| "Here's my scope.md, plan it" | 2 | scope.md provided |
| "Here's my brief and plan, design the styles" | 3 | scope + plan provided |
| "Here's the spec, build it" | 4 | design provided |
| "Test this model I built" | 5 | Workbook provided — confirm model type |
| "I need to fix audit issues" | 4 | Loop back to Build |
| "Prepare for handover" | 6 | Workbook tested and passing |

If unsure, ask one clarifying question — do not assume the model is 3-statement.

## Handoff protocol per phase

For each phase:

1. **Announce** to the user: *"Now running Phase N: <PhaseName> via the
   `fm-N-<phase>` skill. Expected output: <artefact>. This phase is
   interactive."*
2. **Invoke** the sub-skill via the `Skill` tool. The sub-skill then drives
   the conversation with the user.
3. **Inspect the artefact** the sub-skill produced.
4. **Confirm with the user**: *"Phase N produced <artefact>. Are you happy
   to proceed to Phase N+1?"*
5. **Update** the phase table row in `lifecycle_log.md` (status, user
   confirmed Y/N, date, notes) per `references/lifecycle_log_template.md`.

## Iteration after Test (Phase 5)

Phase 5 produces a verdict. The orchestrator routes based on it:

| Verdict | Next |
|---------|------|
| PASS or CONDITIONAL PASS | Phase 6 (Implement) |
| FAIL — Build | Phase 4 with the Fix List |
| FAIL — Design | Phase 3, then Phase 4, then Phase 5 |
| FAIL — Scope | Phase 1, then re-traverse 2 → 3 → 4 → 5 |

After three fix-and-retest loops without a PASS, escalate to the user: *"We
have been through 3 fix cycles. Should we review the Design (Phase 3) or
Scope (Phase 1)?"*

## Working directory convention

All artefacts go in a single working directory chosen at the start of Phase 1:

```
<user-chosen-dir>/
├── scope.md             ← Phase 1
├── plan.md              ← Phase 2
├── design.md            ← Phase 3
├── <ModelName>.xlsx     ← Phase 4
├── test_report.md       ← Phase 5
├── fix_list_pass_N.md   ← Phase 5 (one per pass)
├── USER_GUIDE.md        ← Phase 6
└── lifecycle_log.md     ← orchestrator-maintained
```

## Reference

The CRaFT methodology itself lives in
`../_fm-shared/references/craft_principles.md` — read it once at orchestration
start so framing is consistent across all six phases.
