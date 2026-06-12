---
name: ag-detailed-audit-report
description: >
  Produce a comprehensive, reader-friendly Excel model audit report in Markdown, organized by content type
  rather than by agent. The report walks the reader through the model (summary, flowcharts, formula inventory,
  formatting inventory, text quality, named ranges, structure, hyperlinks, VBA, Power Query) before presenting
  all audit findings in a consolidated error section. Section 3 lists every unique R1C1 formula pattern with
  the A1 cell ranges it covers, highlighting pattern breaks. Use this skill whenever the user wants a detailed
  audit report, client-ready audit deliverable, comprehensive model review document, or full walkthrough-style
  audit output. Trigger on "detailed audit report", "client audit report", "full model report", "walkthrough
  audit", or any request for a structured audit document that separates reference sections from error findings.
---

# Excel Detailed Audit Report 📊

> *"Understand the model first, then show what's wrong."*

## Role

**Pure report formatter** — the client-facing deliverable of the audit family.
It consumes the consolidated findings JSON produced by **ag-audit-manager**
(its `consolidate_findings.py` script) plus the shared `extract.json` for the
inventory sections. In **standalone mode** (no audit-manager run available),
run the extractor and the relevant specialists yourself first, then consolidate,
then format. For a quick single-pass audit instead, use **ag-model-auditor**.

## Philosophy

Organized by **content type**, not by agent. Sections 1–10 are informational —
they exist even if the model has zero errors; a reader should understand the
model from them alone. Section 11 is the only place findings appear.

## Inputs

| Input | Produced by |
|---|---|
| `extract.json` | `../_excel-shared/scripts/extract_workbook.py <model.xlsx> --out extract.json` |
| Consolidated findings JSON | `../ag-audit-manager/scripts/consolidate_findings.py <agent JSONs...> --out consolidated.json` |
| Flowcharts / inventories | Navigator 🧭, Cartographer 🗺️, Stylist 🎨 convention block, Lingo ✍️ `--terms` sidecar, VBA 📦 / PQ ⚡ inventories |

## Output

A single Markdown file: `AUDIT_REPORT_<ModelName>.md` — structure:

Sections 1–10 (reference): Model Summary · Flowcharts · **Formula Inventory
(the signature section: every unique R1C1 pattern with its A1 ranges, breaks
flagged ⚠️)** · Style & Format Inventory · Lingo Report · Named Ranges ·
Structural Assessment · Hyperlinks · VBA Summary · PQ Summary.
Section 11 (findings): consolidated tables split 11a–11i by agent, summary
count table on top. Appendix: Glossary.

## Quick Start

1. Confirm inputs exist (extract.json + consolidated findings JSON); in
   standalone mode produce them first.
2. Copy the structure from `references/report_template.md` — exactly.
3. Populate section by section per `references/report_build_guide.md`
   (Section 3 comes straight from extract.json `r1c1_rows`; Section 11 comes
   straight from the consolidated JSON — never renumber or regroup its IDs).
4. Save as `AUDIT_REPORT_<ModelName>.md`. One file, no splitting.

## Read when needed

| Read | For |
|---|---|
| `references/report_template.md` | The full 11-section template (copy verbatim) |
| `references/report_build_guide.md` | Per-section population rules, data sources, special rules |
| `../_excel-shared/references/audit_standards.md` | Consolidated findings columns (§2), severity scale, Grouping Rule |
| `../_excel-shared/references/extraction_guide.md` | extract.json schema |
