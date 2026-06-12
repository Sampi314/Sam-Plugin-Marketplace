# SumProduct Marketplace

Claude Code plugin marketplace from [SumProduct](https://www.sumproduct.com) —
financial modelling and Excel model audit skills built around the CRaFT
methodology (Consistency, Robustness, Flexibility, Transparency).

## Plugins

| Plugin | What it does |
|---|---|
| **financial-modelling** | The six-phase CRaFT model build lifecycle: `fm-orchestrator` coordinates Scope → Plan → Design → Build → Test → Implement, taking an Excel financial model from requirements gathering to client-ready delivery. |
| **audit-general** | The Excel model audit suite: `ag-audit-manager` orchestrates specialist auditors (logic, technical errors, formatting, language, efficiency, structure, hyperlinks, VBA, Power Query) and consolidates their findings into a single professional audit report. Also includes dependency mapping (`ag-cartographer`) and plain-English model documentation (`ag-navigator`). |

The two plugins cooperate: the Test phase of the financial-modelling lifecycle
invokes the audit-general specialists. Install both for the full workflow.

## Installation

From a local clone:

```
/plugin marketplace add <path-to>/sumproduct-marketplace
```

Or directly from GitHub once published:

```
/plugin marketplace add <github-org>/<repo-name>
```

Then install the plugins:

```
/plugin install financial-modelling@sumproduct
/plugin install audit-general@sumproduct
```

## Requirements

- **Python 3.9+** with `openpyxl` (`pip install openpyxl`) — used by the shared
  workbook extractor that powers the audit skills.
- **Windows + Excel + pywin32** (`pip install pywin32`) — required only for the
  model **build** phase (COM construction) and the **VBA / Power Query**
  auditors. Everything else runs cross-platform with Excel closed.
- VBA auditing additionally needs: File → Options → Trust Center →
  Macro Settings → *Trust access to the VBA project object model*.

## Layout

Each plugin keeps its skills in `skills/`, alongside a shared resource folder
(`_fm-shared/` or `_excel-shared/`) that holds the common references and
scripts the skills point at by relative path. The underscore prefix marks
these as resources, not skills.

## Licence

MIT — see [LICENSE](LICENSE).
