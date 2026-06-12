# Audit Suite Execution Guide

> How to invoke each audit skill, in what order, with what inputs, and what to expect back.

## Table of Contents
1. [Execution Order & Dependencies](#1-execution-order--dependencies)
2. [Per-Skill Invocation Guide](#2-per-skill-invocation-guide)
3. [Standard Findings Format](#3-standard-findings-format)
4. [Consolidation Rules](#4-consolidation-rules)
5. [Skipping Skills](#5-skipping-skills)
6. [Applicability by Model Type](#6-applicability-by-model-type)

---

## 1. Execution Order & Dependencies

Skills must run in this order because later skills depend on earlier results.

```
 ┌─────────────────────────────────────────────────────────┐
 │  TIER 1 — Run first (no dependencies)                   │
 │  ┌─────────┐  ┌─────────┐                               │
 │  │ Sentry  │  │ Lingo   │                               │
 │  │   🛡️    │  │   ✍️    │                               │
 │  └────┬────┘  └────┬────┘                               │
 │       │             │                                    │
 │  TIER 2 — Needs Tier 1 context                          │
 │  ┌────▼────┐  ┌────▼────┐  ┌─────────┐                 │
 │  │ Logic   │  │ Stylist │  │Efficiency│                 │
 │  │   🧠    │  │   🎨    │  │    ⚡    │                 │
 │  └────┬────┘  └────┬────┘  └────┬────┘                 │
 │       │             │            │                       │
 │  TIER 3 — Structural & navigation                       │
 │  ┌────▼────┐  ┌────▼────┐  ┌────▼────┐                 │
 │  │Architect│  │Hyperlinks│  │  VBA    │  ┌─────────┐   │
 │  │   🏗️    │  │   🔗     │  │   📦    │  │   PQ    │   │
 │  └────┬────┘  └─────────┘  └─────────┘  │   ⚡    │   │
 │       │                                   └─────────┘   │
 │  TIER 4 — Documentation (optional, last)                │
 │  ┌────▼────┐  ┌──────────┐                              │
 │  │Navigator│  │Cartograph│                              │
 │  │   🧭    │  │   🗺️     │                              │
 │  └─────────┘  └──────────┘                              │
 └─────────────────────────────────────────────────────────┘
```

### Why This Order Matters

| Dependency | Reason |
|-----------|--------|
| Sentry before Logic | Logic should not waste time analysing cells that have #REF! errors — Sentry finds those first |
| Sentry before Stylist | Broken named styles may cause false positives in Stylist if not catalogued first |
| Logic before Architect | Architect's scalability checks benefit from knowing which formulas have pattern breaks |
| Lingo can run in parallel with Sentry | No dependency — text analysis is independent of formula checks |
| VBA and PQ are independent | Only run if .xlsm has VBA / Power Query is present |
| Navigator and Cartographer last | They document the model — better to document a clean model after fixes |

---

## 2. Per-Skill Invocation Guide

### Shared extraction — run once, before any specialist

Every specialist's rule script consumes the same `extract.json`, built once
per test pass (extract once, audit many times):

```bash
python ../../_excel-shared/scripts/extract_workbook.py "<model>.xlsx" --out extract.json --digest digest.md
```

Paths here are relative to this file (the skills root is `../../`); adjust
from your working directory. The schema and per-auditor consumption map are in
`../../_excel-shared/references/extraction_guide.md`. All rule scripts share
one CLI shape:

```bash
python <skill>/scripts/<name>_rules.py extract.json [--json OUT|-] [--md OUT|-]
```

Rule scripts perform **deterministic checks only**; the specialist skill then
makes the judgment calls (intentional-error filters, semantic label matching,
spelling, business rules) on top of the script output. Power Query M code and
VBA source live outside the parts of the file openpyxl can read, so those two
auditors use COM scripts (Windows + Excel) instead of `extract.json`.

---

### Sentry 🛡️ — Technical Errors

**Input**: File path, sheet list (or "all")
**What to read**: `ag-sentry-auditor/SKILL.md`
**Rule script**: `python ../../ag-sentry-auditor/scripts/sentry_rules.py extract.json --md -` — deterministic sweep of `errors`, `named_ranges`, `validations`; the skill then applies the intentional-#N/A judgment filter
**Process**:
1. Full error sweep — every cell on every sheet (including hidden)
2. Name Manager audit — dead names, #REF! names
3. Data Validation audit — broken list sources, invalid custom formulas
4. Circular reference check

**Expected output**: Findings table with categories: Broken Reference, Calculation Error, Circular Reference, Dead Name, Invalid Validation

**Typical finding count**: 0–20 for a well-built model, 50+ for a troubled one

**Common false positives**: #N/A used intentionally for chart gap suppression — Sentry should filter these

---

### Logic 🧠 — Formula Context

**Input**: File path, sheet list, optional `calculation_logic.md` or `model_design_spec.md`
**What to read**: `ag-logic-auditor/SKILL.md`
**Rule script**: `python ../../ag-logic-auditor/scripts/logic_rules.py extract.json --md -` — deterministic pattern-break and hard-code detection from `r1c1_rows`/`cells`; semantic label matching and business-rule judgment stay with the skill
**Process**:
1. Map context — row descriptors, column headers, section headers
2. Reason — understand business logic from docs or scope
3. Audit formula sensibility — operator check, reference direction, R1C1 pattern consistency, hardcoded literal detection
4. Validate — sanity checks (negative tax on positive profit, BS imbalance, impossible margins)
5. Cross-sheet consistency

**Expected output**: Findings table with R1C1 notation. Categories: Logical Flaw, Formula Context Error, Formula Pattern Break, Hard-Code in Formula, Sanity Check Failure, Cross-Sheet Mismatch

**Key rule**: R1C1 notation is MANDATORY in all formula-related findings

**SumProduct-specific checks**:
- Units column (G) should reference named ranges (`=Currency`), not contain text
- Section numbering should use `MAX($B$x:$By)+1` pattern
- Financial statement rows should contain simple links to Calculations, not new logic
- Row 4 should contain `=Overall_Error_Check` on every sheet

---

### Stylist 🎨 — Formatting Consistency

**Input**: File path, sheet list
**What to read**: `ag-stylist-auditor/SKILL.md`
**Rule script**: `python ../../ag-stylist-auditor/scripts/stylist_rules.py extract.json --md -` — deterministic style/format consistency checks over `cells` + `styles`; convention detection and intent judgment stay with the skill
**Process**:
1. Phase 0 — Detect style convention (Style Guide sheet → Named Styles → Statistical inference)
2. Map context
3. Scan formatting — compare each cell against detected convention
4. Check number formats — cross-reference against row/column context

**Expected output**: Style Convention Summary (detection method, confidence per cell type) PLUS findings table

**SumProduct-specific checks**:
- All 30 custom Cell Styles must exist in `wb.Styles` (list in `fm-3-design/references/sumproduct_styles.md`)
- Assumption cells must use `Assumption` style (yellow fill #FFFF99)
- Heading rows must use `Heading 1 Text` / `Heading 1 Number` styles
- Date headers must use `Date Heading` style with `mmm yy` format
- Error check cells must use `Error_Checks` style with `"ý";"ý";"þ"` format
- Parameter cells must use `Parameter` style (grey fill #D9D9D9)
- Line totals must use `Line Total` style (top thin border)

**Critical**: Stylist must check `cell.Style` property (the named style), not just the raw formatting attributes. A cell can have the right colours by accident — what matters is whether the correct Named Style was applied.

---

### Efficiency ⚡ — Formula Complexity

**Input**: File path, sheet list, Mega-Formula threshold (default: 500 chars)
**What to read**: `ag-efficiency-auditor/SKILL.md`
**Rule script**: `python ../../ag-efficiency-auditor/scripts/efficiency_rules.py extract.json --md -` — deterministic Mega-Formula, volatile-function, and redundancy scans; the deep correctness audit of each Mega-Formula stays with the skill
**Process**:
1. Mega-Formula scan — every formula > 500 chars
2. Deep logic audit — deconstruct each Mega-Formula
3. Redundancy & volatile scan — repeated sub-expressions, OFFSET/INDIRECT/NOW/TODAY counts

**Expected output**: Summary statistics (total formulas, Mega-Formulas by tier, volatile count) PLUS findings table

**SumProduct-specific check**:
- Calculations sheet should have a FORMULATEXT audit column (column P) — flag if missing

---

### Lingo ✍️ — Text Quality

**Input**: File path, sheet list
**What to read**: `ag-lingo-auditor/SKILL.md`
**Rule script**: `python ../../ag-lingo-auditor/scripts/lingo_rules.py extract.json --md -` — deterministic variant tallies and label checks from `text_inventory`; spelling/grammar judgment stays with the skill
**Process**:
1. Read all strings (sheet tabs, headers, labels, comments)
2. Tally variant spellings — identify dominant term
3. Spell-check (respect industry jargon)
4. Label check — every numerical block should have unit labels

**Expected output**: Findings table. Categories: Typo, Grammar, Inconsistent Naming, Dominant Term Mismatch, Missing Label

**SumProduct-specific checks**:
- Sheet tab names should match Navigator TOC entries
- Row labels on Calculations should be linked (formulas), not retyped
- Named range descriptions (column I on Model Parameters) should match the range names

---

### Architect 🏗️ — Structural Integrity

A real skill in its own right (`ag-architect-auditor/`) — the structural
integrity specialist. It primarily reads the `dependencies` and `r1c1_rows`
sections of `extract.json` to judge scalability, modularity, and date-spine
alignment.

**Input**: File path, sheet list
**What to read**: `ag-architect-auditor/SKILL.md`
**Rule script**: none — Architect has no rule script. Its deterministic signals are already pre-computed in `extract.json` (`dependencies` for cross-sheet flow, `r1c1_rows` for pattern structure); the skill reads those sections directly and all architectural judgment (is this fragile? is this a black box?) stays with Claude
**Process**:
1. Structural review — sheet inventory, cross-sheet dependencies, section identification
2. Time axis consistency — all sheets share same time horizon
3. Scalability — can periods be extended without formula rewrites?
4. Modularity — are calculations broken into auditable steps?
5. Category consistency — same order across sheets

**Expected output**: Findings table. Categories: Structural Weakness, Scalability Issue, Modularity Failure, Date Spine Misalignment, Category Inconsistency, Fragile Reference

---

### Hyperlinks 🔗 — Navigation

**Input**: File path, sheet list
**What to read**: `ag-hyperlinks-auditor/SKILL.md`
**Rule script**: `python ../../ag-hyperlinks-auditor/scripts/hyperlinks_rules.py extract.json --md -` — deterministic target validation from `hyperlinks` + `meta.sheets`; navigation-intent judgment (TOC completeness, misleading display text) stays with the skill
**Process**:
1. Map all hyperlinks (HYPERLINK formulas, UI-inserted, shapes)
2. Understand navigation intent (TOC, back links)
3. Validate targets — does destination exist, is it non-blank, does display text match?
4. Cross-check — orphaned sheets, duplicate targets, circular navigation

**SumProduct-specific checks**:
- Navigator sheet must link to every content sheet
- Every sheet row 3 must have 5 Navigator return links
- Error Checks sheet must hyperlink to each individual check cell on BS/CFS

---

### VBA 📦 — Macro Review (if .xlsm)

**Input**: File path (must be .xlsm or .xlsb)
**What to read**: `ag-vba-auditor/SKILL.md`
**Rule script**: `python ../../ag-vba-auditor/scripts/vba_audit.py "<model>.xlsm" --md -` — COM-based (VBA source is not in `extract.json`); Windows + Excel required
**Prerequisite**: Excel Trust Center → Trust access to VBA project object model
**Skip if**: File is .xlsx (no VBA)

---

### PQ ⚡ — Power Query (if present)

**Input**: File path
**What to read**: `ag-pq-auditor/SKILL.md`
**Rule script**: `python ../../ag-pq-auditor/scripts/pq_audit.py "<model>.xlsx" --md -` — COM-based (M code is not in `extract.json`); Windows + Excel required
**Skip if**: No Power Query connections in workbook

---

### Navigator 🧭 — Documentation (optional)

**Input**: File path
**What to read**: `ag-navigator/SKILL.md`
**Rule script**: `python ../../ag-navigator/scripts/build_calc_inventory.py extract.json [--out OUT]` — deterministic calculation inventory from `cells` + `text_inventory` (`--out -` or omitted = stdout); the plain-English formula translation and model summary stay with the skill
**When to run**: Final pass only (after all fixes), or skip if not needed
**Output**: NAV_01_Model_Summary.md, NAV_02_Model_Flowchart.mermaid, NAV_03_Calculation_Reference.md

---

### Cartographer 🗺️ — Dependencies (optional)

**Input**: File path
**What to read**: `ag-cartographer/SKILL.md`
**Rule script**: `python ../../ag-cartographer/scripts/build_dependency_graph.py extract.json [--mermaid OUT] [--register OUT]` — deterministic formula-layer and shadow-layer graph from `dependencies`, `named_ranges`, `validations`, `conditional_formatting`, `charts` (`-` = stdout); critical-path narrative stays with the skill
**When to run**: Final pass only, or skip if not needed
**Output**: Mermaid flowcharts + dependency register

---

## 3. Standard Findings Format

Defined once — and only — in
`../../_excel-shared/references/audit_standards.md`, the single source of
truth for the whole audit family. This guide deliberately does not restate it,
so the format can never drift between Test and the specialists. Read there:

- **§1** — the unified specialist findings table (Severity is a dedicated
  column: 🔴 Critical / ⚠️ Warning / 🟡 Info; R1C1 expected/actual mandatory
  for formula findings)
- **§3** — the severity scale, with the legacy `HIGH/MEDIUM/LOW` prefix
  mapping for historic reports
- **§4** — the cell-range Grouping Rule (implemented by
  `audit_lib.cells_to_ranges()`, so rule-script output is pre-grouped)
- **§5** — the findings JSON interchange schema that rule scripts emit via
  `--json`

---

## 4. Consolidation Rules

Also defined once in `../../_excel-shared/references/audit_standards.md`
(§2 consolidated table, §6 dedup key, severity-on-merge, sort order, and
`F001`-style ID assignment), implemented mechanically by
`ag-audit-manager/scripts/consolidate_findings.py`. Consolidate via the
script rather than by hand — mechanical consolidation is exactly what the
unified format and JSON schema buy.

---

## 5. Skipping Skills

| Condition | Skip | Note in Report |
|-----------|------|---------------|
| File is .xlsx (not .xlsm) | VBA Auditor | "VBA audit skipped — file is .xlsx (no macros)" |
| No Power Query connections | PQ Auditor | "Power Query audit skipped — no queries detected" |
| User requests quick check only | Architect, Navigator, Cartographer | "Structural/documentation audits skipped at user request" |
| First test pass (pre-fix) | Navigator, Cartographer | "Documentation audits deferred to final pass" |
| Model has < 3 sheets | Architect | "Structural audit skipped — model too simple to warrant" |

## 6. Applicability by Model Type

The five required auditors (Sentry, Logic, Stylist, Efficiency, Lingo) apply
to **every** model type — technical errors, pattern breaks, style compliance,
formula complexity, and text quality are universal. What varies by type is
(a) which **sanity expectations** the Logic auditor should assert, and (b)
which **type-specific conservation check** must pass. Model type definitions:
`_fm-shared/references/model_types.md`.

| Model type | Logic auditor: assert | Conservation check (must = 0) | NOT applicable (do not raise) |
|------------|----------------------|-------------------------------|-------------------------------|
| 3-Statement / Project Finance / M&A | BS balance, CFS recon, control accounts close | BS check rows, CFS check rows | — |
| Budget | dept layouts identical, rolling switch consistent | Σ departments − consolidated | BS balance, CFS recon |
| Commission | tier table ascending, payout ≥ 0 | Σ per-rep − total payable; clawback ledger closes | BS balance, CFS recon, control accounts (except clawback ledger) |
| Cost Allocation | driver rows sum to 100% | Σ allocated − Σ pools | BS balance, CFS recon |
| Cashflow Forecast | weekly chain unbroken, headroom flags wired | closing − (opening + net flow) per week | BS balance (unless BS included) |
| Valuation (DCF) | g < WACC, TV method matches scope | EV bridge sums; WACC component recon | BS balance, CFS recon |
| Detailed Operational | production ≤ capacity, utilisation ≤ 100% | inventory conservation | CFS recon (unless statements included) |
| Dashboard | every KPI traces to source | n/a (trace audit instead) | BS balance, CFS recon, control accounts |
| Model Optimisation | inherits original type's asserts | **tie-out vs original = 0** | — (inherits) |
| Feasibility | discount basis consistent, sunk costs excluded | NPV recalc ties | BS balance (if no BS) |
| Strategic / Scenario | switch changes all outputs, no direct scenario refs | per-scenario assumption completeness | — (inherits base type) |

**Reporting rule**: when a check is Not Applicable for the model type, the
audit report must say "N/A — [type]" rather than showing a pass. A commission
model showing "Balance Sheet balances ✅" is a red flag that the wrong
checklist ran, not a clean result.
