# _excel-shared

Shared resources used by the `excel-*` audit skill family. The leading underscore
signals that this is NOT a skill itself (no SKILL.md, will not be auto-discovered
as a skill — the discovery layer would otherwise try to load
`_excel-shared/SKILL.md` and fail noisily). Skills reference these files by
relative path: `../_excel-shared/scripts/extract_workbook.py` etc. This mirrors
the `_fm-shared/` convention used by the fm-* series.

## Contents

### references/

- `audit_standards.md` — **the single source of truth** for the audit family:
  unified findings table format, severity scale (Critical/Warning/Info) with
  legacy mapping, the canonical cell-range grouping rule, the findings JSON
  interchange schema, and consolidation/dedup rules. Every auditor's SKILL.md
  points here instead of restating these. **Edit standards HERE, not in skills.**
- `extraction_guide.md` — schema of `extract.json` (the output of
  `extract_workbook.py`), a per-auditor map of which sections each skill
  consumes, and the openpyxl-vs-COM split.

### scripts/

- `extract_workbook.py` — **run FIRST in any audit.** One openpyxl pass dumps a
  complete JSON model of the workbook (cells with formulas/R1C1/formats/styles,
  pattern-group pre-computes, error cells, named ranges, validations, CF,
  hyperlinks, text inventory, cross-sheet dependencies, styles, charts).
  All auditor rule scripts consume this JSON — extract once, audit many times.
  Works with Excel closed; no COM required.
- `audit_lib.py` — shared toolkit imported by every rule script: `Finding`
  dataclass, the grouping-rule engine (`cells_to_ranges`), A1→R1C1 conversion,
  markdown/JSON emitters matching audit_standards.md. See its docstring for the
  3-line `sys.path` bootstrap used from a skill's `scripts/` folder.
- `excel_automation.py` — pywin32 COM bridge for the two things openpyxl cannot
  read: **Power Query M code and VBA**. Context managers (`excel_app`,
  `open_workbook`) plus `PowerQueryManager` / `VBAManager`. Windows + Excel only;
  used by excel-pq-auditor and excel-vba-auditor.
- `check_skill.py` — light verification for any skill directory (fm-* included):
  frontmatter validity, description length, thin-body rule, referenced paths
  exist, bundled scripts compile. Run after editing any skill.

## Why one shared extractor instead of per-skill extraction?

The audit-manager runs up to 12 specialists on one workbook. If each specialist
opened the file itself (worse: via COM), an audit would mean 12 slow serial
opens and a fragile Excel instance. One `extract.json` produced up front is
parallel-safe, COM-free, and gives every specialist an identical view of the
model — which also makes findings consolidation deterministic.
