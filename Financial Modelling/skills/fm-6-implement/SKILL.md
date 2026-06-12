---
name: fm-6-implement
description: >
  Phase 6 of the financial model build lifecycle — the documentation-protection-and-delivery phase. Finalise
  a tested model for client delivery: produce the user guide, model summary, change log, protect sheets,
  clean up working files, and package the final deliverable. Use this skill when preparing a model for
  handover, creating model documentation, writing a user guide, finalising for client delivery, or packaging
  a model. Trigger on 'finalise the model', 'prepare for delivery', 'create documentation', 'user guide',
  'handover', 'model delivery', or after completing the Test phase.
---

# Phase 6: Implement 📦

> *"A model without documentation is a liability, not an asset."*

## Mission

Finalise the model for delivery — documentation, protection, cleanup, and packaging. The user should be able to pick up the model and use it without needing the developer.

## Prerequisites

- Model file from Phase 4 (Build), passing Phase 5 (Test)
- Test report from Phase 5

## Important References

Before finalising, read:
1. `references/handover_reference.md` — User Guide template (complete Markdown template with all sections), handover checklist (model integrity, structure, formatting, content, documentation, print, file), delivery package structure, and Change Log format

## Process

### 1. FINALISE WORKBOOK

The pywin32 code for updating the Cover sheet, appending a Change Log entry,
and protecting sheets is in `references/finalisation_code.md`. Pattern:

1. **Cover sheet** — write client name, developer, cover notes, version. Add
   a `mailto:` hyperlink on the developer name.
2. **Change Log** — append a row dated today with developer, action, and
   version.
3. **Navigator** — verify every sheet appears in the TOC with a working
   hyperlink.

### 2. PROTECT SHEETS (Optional)

Use `protect_output_sheet` for Calculations and the financial statements
(everything locked). Use `protect_input_sheet` for General Assumptions
(unlock the yellow Assumption cells first). Both helpers are in
`references/finalisation_code.md`.

SumProduct convention: protection uses an **empty-string password**. See the
reference for the rationale.

### 3. PRODUCE DOCUMENTATION

Generate these deliverables:

#### 3a. Model User Guide (`USER_GUIDE.md` or `.docx`)

Populate the **User Guide template from `references/handover_reference.md`
Section 1** (getting started, how to use, timeline changes, outputs, error
checks, style guide, named ranges — adapt the outputs section to the model
type). Then convert to `.docx`:

```bash
python scripts/generate_user_guide.py USER_GUIDE.md USER_GUIDE.docx
```

#### 3b. Model Summary (use `ag-navigator` skill if available)

Run the Navigator skill to produce:
- `NAV_01_Model_Summary.md` — what the model does
- `NAV_02_Model_Flowchart.mermaid` — data flow diagram
- `NAV_03_Calculation_Reference.md` — every formula explained

#### 3c. Dependency Map (use `ag-cartographer` skill if available)

Run the Cartographer skill to produce:
- Workbook-level flowchart
- Sheet-level flowcharts
- Dependency register

### 4. CLEANUP

- Delete any temporary working files
- Remove any developer notes (WIP style cells) or convert to final notes
- Verify no external links remain unless intentional
- Check file size is reasonable

### 5. FINAL VERIFICATION

Run a lightweight re-test:
- Open file fresh (close and reopen)
- Check all error checks pass
- Spot-check 3-5 key outputs against manual calculation
- Verify Navigator links work
- Verify print preview renders correctly

### 6. PACKAGE

Deliver to the user:

```
Delivery Package:
├── [Model Name].xlsx (or .xlsm)
├── USER_GUIDE.md (or .docx)
├── NAV_01_Model_Summary.md
├── NAV_02_Model_Flowchart.mermaid
├── NAV_03_Calculation_Reference.md
├── test_report.md (from Phase 5)
└── scope.md (from Phase 1, for reference)
```

## Handover Notes

When presenting to the user:
1. Walk through the Navigator sheet
2. Show how to change key assumptions
3. Demonstrate the error check system
4. Show the Style Guide
5. Point out the documentation package
