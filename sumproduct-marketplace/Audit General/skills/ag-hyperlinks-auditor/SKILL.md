---
name: ag-hyperlinks-auditor
description: >
  Verify that every hyperlink within an Excel model navigates to a valid, meaningful destination — whether
  internal cell references, named ranges, other sheets, or external URLs. Checks for broken links to missing
  sheets, links to blank cells, stale links shifted by row/column insertions, misleading display text,
  broken TOC entries, missing return links, placeholder URLs, non-portable file paths, and orphaned sheets
  unreachable via navigation. Use this skill whenever the user wants to check hyperlinks, verify navigation,
  audit TOC links, find broken links, or validate the model's navigation layer. Trigger on "check hyperlinks",
  "broken links", "fix navigation", "TOC audit", "verify links", or any mention of hyperlink validation.
---

# Excel Hyperlinks Auditor 🔗

> *"A link that leads nowhere is worse than no link at all."*

## Mission

Verify that every hyperlink within the model navigates to a valid, meaningful destination and that no link points to a blank cell, a deleted sheet, or a broken target.

## Prerequisites

- **Python packages**: `openpyxl` (or `pywin32` on Windows for COM automation)
- Install if needed: `pip install openpyxl --break-system-packages`

## Quick Start

1. Ask the user for the Excel file path (or detect from uploads)
2. Ask which sheets to audit (or default to all)
3. Run the audit following the phased process below
4. Present the findings report

---

## Process

### Phase 1 — MAP HYPERLINKS

Build a Hyperlink Inventory for each sheet:

1. **HYPERLINK() formulas**: Search all cells for the function, capture `link_location` and `friendly_name`.
2. **UI-inserted hyperlinks**: Detect hyperlinks added via right-click/Ctrl+K (stored in cell's hyperlink property).
3. **Shapes/objects**: Check text boxes, shapes, and buttons for embedded hyperlinks.
4. **Classify each hyperlink**: Internal Cell Reference, Internal Named Range, Internal Navigation (TOC/Back), External URL, External File Path, External Email.
5. **Store the Inventory**: sheet, cell, type, destination, display text.

### Phase 2 — UNDERSTAND NAVIGATION INTENT

1. Identify TOC sheets (named "TOC", "Index", "Navigation", "Contents", etc.).
2. Identify "Back to" or "Go to" navigation links in headers/footers.
3. Map expected navigation paths: TOC → Section → Detail → Back to TOC.

### Phase 3 — VALIDATE HYPERLINK TARGETS

#### Internal Cell References

| Check | Failure |
|---|---|
| Target sheet exists | **Broken Link – Missing Sheet** |
| Target cell within bounds | **Broken Link – Out of Bounds** |
| Target cell not blank | **Link to Blank Cell** |
| Destination matches display text | **Misleading Link** |
| Reference survived structural changes | **Stale Link – Shifted Target** |

#### Internal Named Ranges

| Check | Failure |
|---|---|
| Named range exists in Name Manager | **Broken Link – Missing Name** |
| Named range doesn't evaluate to `#REF!` | **Broken Link – #REF! Name** |
| Named range target not blank | **Link to Blank Cell** |

#### Navigation (TOC / Back Links)

| Check | Failure |
|---|---|
| All TOC entries link to existing sheets | **Broken TOC Entry** |
| All sheets have return links (if pattern) | **Missing Return Link** |
| TOC text matches sheet names | **Misleading TOC Entry** |
| Navigation links consistent across sheets | **Inconsistent Navigation** |

#### External URLs

| Check | Failure |
|---|---|
| URL well-formed (http://, https://, mailto:) | **Malformed URL** |
| Domain not placeholder (example.com, xxx) | **Placeholder URL** |
| No `file:///` protocol in shared models | **Non-Portable File Link** |

#### External File Paths

| Check | Failure |
|---|---|
| Not user-specific (`C:\Users\<username>\`) | **Non-Portable File Path** |
| Consistent path convention (all UNC or relative) | **Inconsistent Path Convention** |

### Phase 4 — CROSS-CHECK CONSISTENCY

1. **Orphaned sheets**: Sheets not linked from any TOC or navigation.
2. **Duplicate targets**: Multiple hyperlinks to same destination (copy-paste error?).
3. **Circular navigation**: Link chains that loop (A → B → A).
4. **Renamed sheet residue**: Links with old sheet names.
5. **Batch pattern breaks**: Column of links where one row breaks the pattern.

### Phase 5 — REPORT

#### Grouping Rule

Group cells with identical errors into ranges. Express references in R1C1 where applicable.

#### Findings Table

| Sheet Name | Cell Reference | Description of the Location | Short Error Category | Long Description of Error |
|---|---|---|---|---|

---

## Error Categories

| Category | Description |
|---|---|
| **Broken Link – Missing Sheet** | Target sheet doesn't exist |
| **Broken Link – Out of Bounds** | Target cell beyond used range |
| **Broken Link – Missing Name** | Named range not defined |
| **Broken Link – #REF! Name** | Named range resolves to `#REF!` |
| **Link to Blank Cell** | Valid cell but empty |
| **Stale Link – Shifted Target** | Content moved due to structural changes |
| **Misleading Link** | Display text doesn't match destination |
| **Broken TOC Entry** | TOC link doesn't resolve |
| **Missing Return Link** | Sheet missing navigation link that peers have |
| **Inconsistent Navigation** | Navigation links differ across sheets |
| **Placeholder URL** | Obvious placeholder text |
| **Malformed URL** | Invalid URL syntax |
| **Non-Portable File Path** | User-specific local path |
| **Orphaned Sheet** | Sheet unreachable via hyperlinks/TOC |
| **Circular Navigation** | Link chain loops back |

## Severity Levels

| Level | Meaning | Prefix |
|---|---|---|
| 🔴 **High** | Definitively broken — destination doesn't exist | `🔴 HIGH:` |
| ⚠️ **Medium** | Resolves but blank, misleading, or stale | `⚠️ MEDIUM:` |
| 🟡 **Low** | Minor inconsistency — pattern break or cosmetic | `🟡 LOW:` |

## Special Rules

- **Full Inventory Required**: Every hyperlink must be catalogued — don't skip shapes, text boxes, or hidden sheets.
- **Blank Cell Strictness**: Spaces, single apostrophe, or `""` = blank.
- **Case Sensitivity**: Sheet name matching must be exact.
- **Hidden Sheets**: Flag links to hidden sheets with a note, not as broken.
- **Full Cell References**: Never use "..." or truncated lists.
- Report only — do not modify or delete any hyperlinks.
