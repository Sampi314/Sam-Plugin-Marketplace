# Orchestration Guide 👔

Operational detail for `ag-audit-manager`. The workflow skeleton lives in `../SKILL.md`;
formats live in `../../_excel-shared/references/audit_standards.md`. This file covers how to
*run* the orchestration: setup, delegation, per-specialist notes, verification, and cleanup.

---

## 1. Initiate

Confirm with the user before dispatching anything:

- **Model path** — and that the file opens (a corrupt file fails fastest at extraction).
- **Specialist selection** — default to all applicable. Skip VBA/PQ when the workbook is
  `.xlsx` with no queries, or the host lacks Windows + Excel. Include AI Auditor 🤖 when the
  model was built by an LLM (openpyxl/pywin32 builds have a distinctive error profile).
- **Context docs** — `calculation_logic.md`, `model_design_spec.md`, or a design spec from
  fm-3-design if this model came through the fm lifecycle. Pass them to Logic and Architect;
  they turn guesses into verdicts.
- **Target sheets** — default full workbook, hidden sheets included.
- **Output** — consolidated markdown (quick run) or full client document via
  `ag-detailed-audit-report`.

## 2. Pre-clean

Delete stale audit artifacts (`Workings/*.json`, `Workings/*.md`) before extracting, so this
run's consolidation cannot pick up findings from a previous model version.

## 3. Extract once

```
python ../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out Workings/extract.json --digest Workings/digest.md
```

Read `Workings/digest.md` yourself before delegating — sheet count, error count, named ranges,
hyperlinks. It tells you which specialists will have material to work with (e.g. 0 hyperlinks
means the Hyperlinks agent only needs to check for *missing* navigation).

## 4. Delegate

### Prompt template

For each specialist, spawn a subagent (or run sequentially yourself) with:

```
Use the <skill-name> skill to audit the model <model.xlsx>.

A workbook extract already exists at <abs path>/Workings/extract.json — use it; do NOT
re-extract. Context docs: <paths or "none">. Target sheets: <list or "all">.

Run your full check catalogue. Apply the Grouping Rule before reporting. Save your findings
as JSON (audit_standards.md §5 schema, agent="<agent-id>") to
<abs path>/Workings/<agent-id>-findings.json and reply with your markdown findings table
plus anything that needs my judgment (suspected-intentional items, checks you could not run).
```

Use absolute paths — subagents do not inherit your working directory.

### Per-specialist notes

| Agent | findings file | extract sections used | Notes |
|---|---|---|---|
| Sentry 🛡️ | `sentry-findings.json` | `errors`, `named_ranges`, `validations` | Run first. Ask it to report intentional-#N/A exclusions so you can sanity-check the filter. |
| Logic 🧠 | `logic-findings.json` | `r1c1_rows`, `r1c1_cols`, `cells`, `text_inventory` | Give it context docs; business-rule checks need them. |
| AI Auditor 🤖 | `ai-findings.json` | `cells` (+ own scanner) | Only when AI-built. Overlaps Logic on pattern breaks — consolidation dedups that. |
| Stylist 🎨 | `stylist-findings.json` | `cells` (style/fmt), `styles`, `conditional_formatting` | Tell it whether a Style Guide sheet exists (digest shows sheet names). |
| Efficiency ⚡ | `efficiency-findings.json` | `cells` (formula length), `r1c1_rows` | Architect cross-references its Mega-Formula list — run before Architect. |
| Lingo ✍️ | `lingo-findings.json` | `text_inventory`, `meta.sheets` | Spelling/terminology judgment stays with the agent, not a wordlist script. |
| Architect 🏗️ | `architect-findings.json` | `dependencies`, `r1c1_rows`, `meta` | Pass Efficiency's findings file path if available. |
| Hyperlinks 🔗 | `hyperlinks-findings.json` | `hyperlinks`, `meta.sheets` | Zero hyperlinks in digest → still run orphan-sheet/missing-navigation checks. |
| VBA 📦 | `vba-findings.json` | none — COM via `excel_automation.py` | Windows only. Cell refs are module names (kept verbatim by the lib). |
| PQ ⚡ | `pq-findings.json` | none — COM via `excel_automation.py` | Windows only. Cell refs are query names. |
| Navigator 🧭 | n/a (documentation) | `cells`, `text_inventory`, `dependencies` | Produces summary + flowchart + calc reference for the report's front sections. |
| Cartographer 🗺️ | n/a (documentation) | `dependencies`, `named_ranges`, `validations`, `conditional_formatting`, `charts` | Produces the Mermaid dependency maps. |

Section-by-section schema: `../../_excel-shared/references/extraction_guide.md`.

## 5. Collect & verify

- Confirm every dispatched specialist wrote its findings file (an agent that found nothing
  still writes `{"findings": []}` — a *missing* file means the agent failed, not that the
  model is clean).
- Spot-check one finding per agent against the extract: right sheet, plausible cells, severity
  values from the canonical scale.
- **Severity mapping**: specialists emit `critical` / `warning` / `info`
  (audit_standards §3). If an older agent emits HIGH/MEDIUM/LOW prefixes, the lib maps them
  (HIGH→Critical, MEDIUM→Warning, LOW→Info) — but flag that agent for overhaul.

## 6. Consolidate

```
python scripts/consolidate_findings.py <each findings.json> --extract Workings/extract.json --out Workings/consolidated.json --md Workings/consolidated.md
```

The script implements audit_standards §6 (dedup on sheet + overlapping cells + category,
max severity, longer description wins with "(also flagged by <agent>)", sort, F001 IDs) and
prints summary statistics — per-file input counts, dedup merges, per-agent and per-severity
totals. Quote those statistics in your hand-off; they are the executive summary numbers.

Judgment pass after the script: scan merged findings for *false* merges (same cells, same
category, genuinely different concerns) and split them manually if needed — the script is
deterministic and cannot tell.

## 7. Report / hand off

- **Client document**: invoke `ag-detailed-audit-report` with `consolidated.json` +
  `extract.json` (+ Navigator/Cartographer outputs). It formats; it does not re-audit.
- **Quick run**: present `consolidated.md` (already in the §2 consolidated table format)
  under a short header: model, date, sheets audited, agents run, summary statistics, then
  the table. Agents that ran clean: `✅ No issues detected.` Agents skipped: say why.

## 8. Post-clean

Keep: the final report, `consolidated.json` (the fix loop in fm-5-test consumes it), and
`extract.json` (re-used on re-test). Delete: per-agent findings files and any scratch
output — once consolidated they are duplicate data that will confuse a later run.
