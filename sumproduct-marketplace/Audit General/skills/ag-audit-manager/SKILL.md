---
name: ag-audit-manager
description: >
  Orchestrate a comprehensive Excel financial model audit by coordinating all twelve specialist audit
  agents (Sentry, Logic, AI, Stylist, Efficiency, Lingo, Architect, Hyperlinks, VBA, Power Query,
  Navigator, Cartographer) and consolidating their findings into a single professional audit report.
  Extracts the workbook once, manages the sequence of agent execution, collects findings JSON,
  deduplicates via script, and produces the final consolidated Audit Report — or hands off to
  ag-detailed-audit-report for the client document. Use this skill whenever the user wants a full
  model audit, comprehensive review, complete workbook check, or coordinated multi-agent audit.
  Trigger on "full audit", "comprehensive review", "audit everything", "complete model check",
  "run all checks", or any request for an end-to-end model audit.
---

# Excel Audit Manager 👔

> *"Success is in the coordination; quality is in the consolidation."*

## Mission

The **orchestrator** of the audit family: extract the workbook once, dispatch the right
specialists, consolidate their findings mechanically, and deliver one coherent report. For a
quick one-shot single-pass audit use **ag-model-auditor** instead; client report assembly
is delegated to **ag-detailed-audit-report**.

## Prerequisites

- The specialist audit skills installed alongside this one (roster below).
- **Python packages**: `openpyxl` (extraction + consolidation); `pywin32` only for the VBA/PQ
  specialists (Windows + Excel installed). `pip install openpyxl pywin32`

## Specialist roster & run order

Run in priority order — Sentry first because technical errors (#REF!, broken names) poison
every downstream check; Navigator and Cartographer last because they document the model rather
than fault it.

| # | Agent | Skill | Focus |
|---|---|---|---|
| 1 | Sentry 🛡️ | `ag-sentry-auditor` | Technical errors, broken names, validation, circular refs |
| 2 | Logic 🧠 | `ag-logic-auditor` | Formula context, pattern breaks, sanity checks, business rules |
| 3 | AI Auditor 🤖 | `ag-ai-auditor` | LLM-introduced build errors — include when the model is AI-built |
| 4 | Stylist 🎨 | `ag-stylist-auditor` | Formatting consistency, colour coding, number formats |
| 5 | Efficiency ⚡ | `ag-efficiency-auditor` | Mega-Formulas, redundancy, volatile functions |
| 6 | Lingo ✍️ | `ag-lingo-auditor` | Spelling, grammar, naming consistency, unit labels |
| 7 | Architect 🏗️ | `ag-architect-auditor` | Structural integrity, scalability, modularity |
| 8 | Hyperlinks 🔗 | `ag-hyperlinks-auditor` | Link validation, TOC integrity, navigation |
| 9 | VBA 📦 | `ag-vba-auditor` | VBA security, performance, error handling (Windows only) |
| 10 | PQ ⚡ | `ag-pq-auditor` | Power Query M code quality (Windows only) |
| 11 | Navigator 🧭 | `ag-navigator` | Model documentation: summary, flowchart, calc reference |
| 12 | Cartographer 🗺️ | `ag-cartographer` | Dependency mapping and flowcharts |

## Quick Start

1. Get the model path; confirm which specialists to run (default: all applicable — skip
   VBA/PQ when the workbook has none or the host is not Windows) and any context docs.
2. Create a `Workings/` folder beside the model, then **extract once**:

   ```
   python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out Workings/extract.json --digest Workings/digest.md
   ```

3. Run each selected specialist in run order. Pass the `extract.json` path in the delegation
   prompt so the specialist does **not** re-extract — extraction is the expensive step, and one
   extract keeps every agent looking at the same snapshot. Each specialist saves its findings
   to `Workings/<agent>-findings.json` (schema: audit_standards §5). Delegation prompt template
   and per-specialist notes: `references/orchestration_guide.md`.
4. Consolidate (dedup, sort, assign F001 IDs — list the findings files explicitly; PowerShell
   does not expand `*` for Python):

   ```
   python scripts/consolidate_findings.py Workings/sentry-findings.json Workings/logic-findings.json ... --extract Workings/extract.json --out Workings/consolidated.json --md Workings/consolidated.md
   ```

5. Deliver: hand `Workings/consolidated.json` (plus `extract.json`) to
   **ag-detailed-audit-report** for the client document — or, for a quick run, present
   `consolidated.md` with the script's summary statistics yourself.
6. Post-clean per `references/orchestration_guide.md`: keep the deliverable and the
   consolidated JSON, clear intermediates.

## Report format

Findings tables, the severity scale, consolidated columns (ID + Agent), and the dedup rules are
defined once in `../_excel-shared/references/audit_standards.md` — sections 2 and 6 cover the
consolidated report specifically. Never invent a variant format; consolidation only works
because every specialist emits the same shape.

## Ground rules

- Never modify the model without explicit instruction — this is an audit, not a fix pass.
- Never drop a specialist's finding: dedup *merges* duplicates, it does not delete them.
- If a specialist cannot run (e.g. VBA on a non-Windows host), say so in the report and move on.

## Reference map

| Read | For |
|---|---|
| `references/orchestration_guide.md` | Delegation prompt template, per-specialist invocation notes, severity mapping, pre/post-clean rules |
| `../_excel-shared/references/audit_standards.md` | Findings formats (§1–2), severity scale (§3), Grouping Rule (§4), JSON schema (§5), consolidation rules (§6) |
| `../_excel-shared/references/extraction_guide.md` | extract.json schema + which sections each specialist consumes |
| `scripts/consolidate_findings.py` | Mechanical dedup / sort / ID assignment (CLI above) |
