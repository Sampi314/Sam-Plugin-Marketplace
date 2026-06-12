# Detailed Audit Report — Template

Copy this structure verbatim. Sections 1–10 are informational/reference (they
exist even for a perfect model); Section 11 is the only place findings appear.
Findings tables use the consolidated columns from
`../../_excel-shared/references/audit_standards.md` §2.

```markdown
# Detailed Audit Report: [Model Name]

**Date:** [date]
**Auditor:** Sam AI Audit Suite
**File:** [filename]
**Sheets Audited:** [count] ([list or "All"])

---

## Section 1: Model Summary

### 1.1 Purpose
[What does this model calculate? What decision does it support?]

### 1.2 Model Structure
| Sheet Name | Role | Visible | Description |
|---|---|---|---|

### 1.3 Timeline
- **Start:** [date]
- **End:** [date]
- **Frequency:** [annual/quarterly/monthly]
- **Total periods:** [n]

### 1.4 Key Inputs
| Input | Location | Current Value | Unit |
|---|---|---|---|

### 1.5 Key Outputs
| Output | Location | Current Value | Unit |
|---|---|---|---|

### 1.6 Scenarios & Switches
| Switch | Location | Current Setting | Options |
|---|---|---|---|

### 1.7 Key Assumptions
[Narrative of material assumptions]

### 1.8 Circular References
[Description if any, or "None detected"]

---

## Section 2: Flowcharts

### 2a. Workbook-Level Data Flow

[Embed the Navigator/Cartographer workbook-level Mermaid flowchart]

```mermaid
[workbook-level flowchart here]
```

### 2b. Sheet-Level Flowcharts

#### [Sheet Name]
```mermaid
[sheet flowchart]
```

[Repeat for each sheet]

---

## Section 3: Formula Inventory

> Every unique R1C1 formula pattern in the model, grouped by sheet and row.
> Pattern breaks are highlighted with ⚠️.

### [Sheet Name]

| Row/Col | R1C1 Pattern | A1 Example | Cell Range | Count | Status |
|---|---|---|---|---|---|

[Repeat for each sheet]

**Summary:** [X] unique patterns across [Y] sheets. [Z] pattern breaks detected.

---

## Section 4: Style & Format Inventory

### 4a. Named Cell Styles
| Style Name | Font | Fill Colour | Number Format | Count |
|---|---|---|---|---|

### 4b. Colour Coding Convention (Detected)
| Role | Font Colour | Fill Colour | Sample Locations |
|---|---|---|---|

### 4c. Number Format Inventory
| Format String | Sample Location | Count | Potential Issue |
|---|---|---|---|

---

## Section 5: Lingo Report

### 5a. Term Frequency (Dominant vs Outlier)
| Term | Count | Dominant? | Locations (first 5) |
|---|---|---|---|

### 5b. Sheet Tab Name Review
| Sheet Name | Visible | Issue |
|---|---|---|

### 5c. Missing Unit Labels
| Sheet | Row | Row Label | Data Range | Issue |
|---|---|---|---|---|

### 5d. Spelling Issues
| Sheet | Cell | Original Text | Flagged Word | Suggestion |
|---|---|---|---|---|

---

## Section 6: Named Range List

| # | Name | Refers To | Scope | Resolved Sheet | Resolved Range | Used In Formulas | Used In Validations | Status |
|---|---|---|---|---|---|---|---|---|

---

## Section 7: Structural Assessment

### 7a. Scalability
[Can the model be extended without breaking?]

### 7b. Modularity
[Are calculations broken into auditable steps?]

### 7c. Date Spine Alignment
[Do all sheets reference a central timing assumption?]

### 7d. Category Consistency
[Are items listed in the same order across sheets?]

---

## Section 8: Hyperlink Inventory

| # | Sheet | Cell | Type | Destination | Display Text | Status |
|---|---|---|---|---|---|---|

---

## Section 9: VBA Code Summary

### 9a. Module Inventory
| Module | Type | Lines | Procedures | Entry Point? |
|---|---|---|---|---|

### 9b. Code Overview
[Brief description of what the VBA does — not a full code listing]

---

## Section 10: Power Query Summary

### 10a. Query Inventory
| Query Name | Type | Load Destination | Steps | Data Source |
|---|---|---|---|---|

### 10b. Architecture
[Query dependency map, shared sources, parameterisation status]

---

## Section 11: Audit Findings

> All errors and issues detected by the audit agents. Sections 1–10 are
> reference; this is the only section containing findings.

**Findings Summary:**

| Category | Agent | 🔴 Critical | ⚠️ Warning | 🟡 Info | Total |
|---|---|---|---|---|---|
| Technical Errors | Sentry 🛡️ | X | X | X | X |
| Formula Logic | Logic 🧠 | X | X | X | X |
| AI-Build Errors | AI 🤖 | X | X | X | X |
| Formatting | Stylist 🎨 | X | X | X | X |
| Efficiency | Efficiency ⚡ | X | X | X | X |
| Text & Naming | Lingo ✍️ | X | X | X | X |
| Structure | Architect 🏗️ | X | X | X | X |
| Hyperlinks | Hyperlinks 🔗 | X | X | X | X |
| VBA Code | VBA 📦 | X | X | X | X |
| Power Query | PQ ⚡ | X | X | X | X |
| **Total** | | **X** | **X** | **X** | **X** |

### 11a. Technical Errors (Sentry 🛡️)

| ID | Agent | Sheet | Cell Reference | Description of Location | Severity | Category | Description of Issue |
|---|---|---|---|---|---|---|---|

*[If none: "✅ No technical errors detected."]*

### 11b. Formula Logic Errors (Logic 🧠)
[same consolidated table format]

### 11c. Formatting Errors (Stylist 🎨)
[same]

### 11d. Efficiency Issues (Efficiency ⚡)
[same]

### 11e. Text & Naming Errors (Lingo ✍️)
[same]

### 11f. Structural Issues (Architect 🏗️)
[same]

### 11g. Hyperlink Errors (Hyperlinks 🔗)
[same]

### 11h. VBA Issues (VBA 📦)
[same — Sheet shows `(VBA)`, Cell Reference shows the module name]

*[If not applicable: "ℹ️ No VBA code present in this workbook."]*

### 11i. Power Query Issues (PQ ⚡)
[same — Sheet shows `(Power Query)`, Cell Reference shows the query name]

*[If not applicable: "ℹ️ No Power Queries present in this workbook."]*

---

## Appendix: Glossary

| Term | Definition |
|---|---|
| **CFADS** | Cash Flow Available for Debt Service |
| **DSCR** | Debt Service Coverage Ratio |
| **R1C1** | Row-Column notation where references are relative to the current cell |
| [Add model-specific terms as needed] |
```
