# Audit Skills — Live Pointer Guide

> **Plugin note:** the audit skills above ship in the separate **audit-general** plugin — install it alongside this one (`/plugin install audit-general@sumproduct`) so fm-5-test can run the audit suite. The shared standards file is bundled with both plugins at `skills/_excel-shared/references/audit_standards.md`.

The audit agents live as real skills under `.claude/skills/` — **the live
SKILL.md is always authoritative**. This guide replaces the snapshot copies
that used to sit in `audit_skills/`: snapshots drift silently as the real
skills improve (they already had — the Architect auditor existed only as a
snapshot here until it was promoted to a real skill).

When a finding is raised, read the matching live skill for its full process,
rule catalogue (`references/<agent>_rules.md`), and special rules. Shared
findings format, severity scale and Grouping Rule for ALL agents:
`../../_excel-shared/references/audit_standards.md`.

| Agent | Live skill | Role in one line |
|---|---|---|
| Sentry 🛡️ | `ag-sentry-auditor` | Technical errors: #REF!/#VALUE!/etc., dead names, invalid validations |
| Logic 🧠 | `ag-logic-auditor` | Formula-vs-label correctness, R1C1 pattern breaks, hard-codes, sanity checks |
| AI 🤖 | `ag-ai-auditor` | LLM-build errors: formula-as-text, static snapshots, SUM boundaries |
| Stylist 🎨 | `ag-stylist-auditor` | Formatting convention detection + colour/number-format deviations |
| Efficiency ⚡ | `ag-efficiency-auditor` | Mega-Formulas, redundant calculation, volatile functions |
| Lingo ✍️ | `ag-lingo-auditor` | Spelling, terminology consistency, unit labels, tab hygiene |
| Architect 🏗️ | `ag-architect-auditor` | Structural integrity, scalability, inputs/calcs/outputs separation |
| Hyperlinks 🔗 | `ag-hyperlinks-auditor` | Link targets, TOC integrity, orphaned sheets, portability |
| VBA 📦 | `ag-vba-auditor` | VBA security/performance/error-handling/standards (.xlsm; COM) |
| PQ ⚡ | `ag-pq-auditor` | Power Query M code quality and architecture (COM) |
| Navigator 🧭 | `ag-navigator` | Model summary, flowchart, plain-English calculation reference |
| Cartographer 🗺️ | `ag-cartographer` | Dependency maps (formula + shadow layers), critical paths |
| Audit Manager 👔 | `ag-audit-manager` | Orchestrates the specialists, consolidates findings |
| Detailed Report 📊 | `ag-detailed-audit-report` | Client-facing 11-section audit document |
| Generalizer 🧰 | `ag-generalizer` | Refactors project-specific audit scripts into reusable tools |
