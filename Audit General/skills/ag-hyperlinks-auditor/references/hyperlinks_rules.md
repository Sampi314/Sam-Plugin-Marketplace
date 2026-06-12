# Hyperlinks Rule Catalogue 🔗

The full check catalogue for `ag-hyperlinks-auditor`. Findings table format, severity
scale, and the cell-range Grouping Rule are defined once in
`../../_excel-shared/references/audit_standards.md` — this file defines only *what* the
Hyperlinks auditor checks and the categories it reports under.

`scripts/hyperlinks_rules.py` covers the deterministic subset (broken internal targets,
placeholder/malformed/non-portable external targets, orphaned sheets). Display-text-vs-target
review and navigation-intent checks are Claude's judgment pass.

---

## Phase 1 — MAP HYPERLINKS — *extractor + judgment*

Build a Hyperlink Inventory for each sheet (the extract's `hyperlinks[]` covers items 1–2;
shapes need a manual look):

1. **HYPERLINK() formulas**: Search all cells for the function, capture `link_location` and
   `friendly_name` (the extractor parses these — `source: "formula"`).
2. **UI-inserted hyperlinks**: Detect hyperlinks added via right-click/Ctrl+K (stored in the
   cell's hyperlink property — `source: "ui"`).
3. **Shapes/objects**: Check text boxes, shapes, and buttons for embedded hyperlinks
   (not in the extract — inspect via COM or openpyxl drawing parts if present).
4. **Classify each hyperlink**: Internal Cell Reference, Internal Named Range, Internal
   Navigation (TOC/Back), External URL, External File Path, External Email.
5. **Store the Inventory**: sheet, cell, type, destination, display text.

## Phase 2 — UNDERSTAND NAVIGATION INTENT — *judgment only*

1. Identify TOC sheets (named "TOC", "Index", "Navigation", "Contents", etc.).
2. Identify "Back to" or "Go to" navigation links in headers/footers.
3. Map expected navigation paths: TOC → Section → Detail → Back to TOC.

## Phase 3 — VALIDATE HYPERLINK TARGETS

### Internal Cell References

| Check | Failure | Source |
|---|---|---|
| Target sheet exists | **Broken Link – Missing Sheet** | rule script (`broken`) |
| Target cell within bounds | **Broken Link – Out of Bounds** | rule script (`broken`) |
| Target cell not blank | **Link to Blank Cell** | judgment |
| Destination matches display text | **Misleading Link** | judgment |
| Reference survived structural changes | **Stale Link – Shifted Target** | judgment |

### Internal Named Ranges

| Check | Failure | Source |
|---|---|---|
| Named range exists in Name Manager | **Broken Link – Missing Name** | rule script (`broken`) |
| Named range doesn't evaluate to `#REF!` | **Broken Link – #REF! Name** | rule script (`broken`) |
| Named range target not blank | **Link to Blank Cell** | judgment |

### Navigation (TOC / Back Links) — *judgment only*

| Check | Failure |
|---|---|
| All TOC entries link to existing sheets | **Broken TOC Entry** |
| All sheets have return links (if pattern) | **Missing Return Link** |
| TOC text matches sheet names | **Misleading TOC Entry** |
| Navigation links consistent across sheets | **Inconsistent Navigation** |

### External URLs

| Check | Failure | Source |
|---|---|---|
| URL well-formed (http://, https://, mailto:) | **Malformed URL** | rule script (mailto without @) + judgment |
| Domain not placeholder (example.com, localhost, TODO, xxx) | **Placeholder URL** | rule script |
| No `file:///` protocol in shared models | **Non-Portable File Link** | rule script |

The script does **string checks only** — it never fetches URLs. Liveness of external links
is out of scope unless the user asks and network access is available.

### External File Paths

| Check | Failure | Source |
|---|---|---|
| Not user-specific (`C:\Users\<username>\`) or absolute drive/UNC | **Non-Portable File Path** | rule script |
| Consistent path convention (all UNC or relative) | **Inconsistent Path Convention** | judgment |

## Phase 4 — CROSS-CHECK CONSISTENCY

1. **Orphaned sheets**: Sheets not linked from any TOC or navigation. (*rule script*: flags a
   visible sheet that is the target of zero internal links AND contains zero links out — only
   when the workbook has 3+ visible sheets and at least one internal link exists. A workbook
   with no internal links isn't link-navigated, so the check stands down rather than flag
   every sheet.)
2. **Duplicate targets**: Multiple hyperlinks to the same destination (copy-paste error?).
   (*judgment*)
3. **Circular navigation**: Link chains that loop (A → B → A). (*judgment*)
4. **Renamed sheet residue**: Links with old sheet names. (*judgment*)
5. **Batch pattern breaks**: Column of links where one row breaks the pattern. (*judgment*)

---

## Error categories

Use exactly these values in the findings table's Category column:

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
| **Placeholder URL** | Obvious placeholder text (example.com, localhost, TODO) |
| **Malformed URL** | Invalid URL syntax |
| **Non-Portable File Path** | User-specific local path, absolute drive, or UNC path |
| **Orphaned Sheet** | Sheet unreachable via hyperlinks/TOC |
| **Circular Navigation** | Link chain loops back |

The rule script emits the coarser labels **Broken Link** (the extract's `broken` flag does
not say *why* the target failed) and **Non-Portable Path**. During the judgment pass, refine
to the specific category above where the cause is identifiable (missing sheet vs. deleted
name vs. out-of-bounds cell).

## Severity calibration

The scale itself (🔴 Critical / ⚠️ Warning / 🟡 Info) is defined in
`../../_excel-shared/references/audit_standards.md` §3. Hyperlinks-specific calibration:

- **Critical** — definitively broken: the destination doesn't exist (missing sheet, dead
  name, out-of-bounds cell, `#REF!` name).
- **Warning** — resolves but is blank, misleading, stale, a placeholder, or non-portable.
- **Info** — minor inconsistency: pattern break, orphaned sheet, cosmetic navigation issue.

## Special rules

- **Full Inventory Required**: Every hyperlink must be catalogued — don't skip shapes, text
  boxes, or hidden sheets.
- **Blank Cell Strictness**: Spaces, a single apostrophe, or `""` = blank.
- **Case Sensitivity**: Sheet name matching must be exact.
- **Hidden Sheets**: Flag links to hidden sheets with a note, not as broken.
- Cell references follow the Grouping Rule in `audit_standards.md` §4 — never "...", "etc.",
  or truncated lists. Where a finding concerns a `HYPERLINK()` formula pattern, express the
  formula in R1C1.
- Report only — do not modify or delete any hyperlinks.
- A workbook with zero hyperlinks is a clean pass: state `✅ No issues detected.`
