# lifecycle_log.md — Template

The orchestrator resumes mid-lifecycle by reading this file — ad-hoc log
formats break resumption, so every run writes `lifecycle_log.md` in exactly
this shape. Copy the blocks below into the working directory's
`lifecycle_log.md` at the start of Phase 1 (or when picking up an existing
build), then keep it current: update the phase table after every phase
hand-off, the pass counter after every Test cycle, and the decisions log
whenever the user makes a call that later phases must respect.

---

## Header block

```markdown
# Lifecycle Log: <Model Name>

- **Model name**: TechCorp DCF Valuation
- **Model type**: Valuation (DCF)            ← from `_fm-shared/references/model_types.md`; carried into every phase
- **Working directory**: C:/Models/TechCorp/
- **Started**: 2026-06-12
```

The model type line is load-bearing: Phase 5 selects its sanity checks from it
(e.g. no Balance Sheet check on a DCF), so record it the moment Phase 1
establishes it.

## Phase table

One row per phase. `Status`: Pending / In progress / Complete / Reopened.
`User confirmed` is Y only after the explicit "happy to proceed?" exchange —
an artefact existing on disk is not confirmation.

```markdown
| Phase | Skill | Artefact | Status | User confirmed | Date | Notes |
|-------|-------|----------|--------|----------------|------|-------|
| 1. Scope | fm-1-scope | scope.md | Complete | Y | 2026-06-12 | DCF, 10-year horizon, quarterly |
| 2. Plan | fm-2-plan | plan.md | Complete | Y | 2026-06-12 | 14 sheets; WACC build-up on Gen Assumptions |
| 3. Design | fm-3-design | design.md | Complete | Y | 2026-06-13 | 30 SumProduct Cell Styles; 25 named ranges |
| 4. Build | fm-4-build | TechCorp_DCF.xlsx | Complete | Y | 2026-06-14 | Built via pywin32; 2 fix passes applied |
| 5. Test | fm-5-test | test_report.md | In progress | N | 2026-06-15 | Pass 2 running; see pass counter below |
| 6. Implement | fm-6-implement | delivery package | Pending | — | — | — |
```

## Fix-loop pass counter

Maintained during Phase 5. One row per fix-and-retest cycle, so the
orchestrator knows on resume whether the loop-4 / loop-5 escalation rules in
`fm-5-test/references/fix_loop_protocol.md` have been reached.

```markdown
| Cycle # | Findings reopened | Routed to | Outcome |
|---------|-------------------|-----------|---------|
| 1 | 12 (3 Critical, 5 Warning, 4 Info) | Phase 4 (Build) | 8 verified fixed, 4 reopened |
| 2 | 4 (0 Critical, 3 Warning, 1 Info) | Phase 4 (Build) | Awaiting retest |
```

## Decisions log

Anything the user decided that constrains later phases — accepted findings,
scope cuts, convention overrides. Without this, a resumed run re-litigates
settled questions.

```markdown
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-06-13 | Terminal value via Gordon growth, not exit multiple | User's board prefers perpetuity basis |
| 2026-06-15 | Accepted Warning: Mega-Formula on Calculations J211 | Legacy formula reproduced from client's source model |
```
