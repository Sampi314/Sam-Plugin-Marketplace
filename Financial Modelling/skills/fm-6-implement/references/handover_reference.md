# Documentation & Handover Reference

> Templates and checklists for Phase 6 — preparing the model for delivery.

## Table of Contents
1. [User Guide Template](#1-user-guide-template)
2. [Handover Checklist](#2-handover-checklist)
3. [Delivery Package Structure](#3-delivery-package-structure)
4. [Change Log Format](#4-change-log-format)

---

## 1. User Guide Template

Adapt this template for each model. Delete sections that don't apply.

```markdown
# User Guide: [Model Name]

**Version**: [X.X]
**Date**: [date]
**Prepared by**: [developer]
**Client**: [client name]

---

## 1. Introduction

### 1.1 Purpose
[One paragraph: what this model does and what decisions it supports.]

### 1.2 Scope
[What the model covers and what it does NOT cover.]

### 1.3 Prerequisites
- Microsoft Excel 2016 or later (Windows recommended)
- Macros enabled (if .xlsm)
- No other Excel workbooks open during use (if using VBA)

---

## 2. Getting Started

### 2.1 Opening the Model
1. Open the file in Excel
2. If prompted, click "Enable Macros" (for .xlsm files)
3. Navigate to the **Navigator** sheet — this is your table of contents

### 2.2 Navigation
- The **Navigator** sheet has hyperlinks to every sheet in the model
- Every sheet has "Navigator" links in row 3 — click to return to the Navigator
- Error check status displays at the top of every sheet (row 4)

### 2.3 Understanding the Colour Coding
| Colour | Meaning | Action |
|--------|---------|--------|
| Yellow background | User input | You can change these |
| No background (white) | Calculated value | Do NOT change |
| Light green background | Cross-sheet link | Do NOT change |
| Grey background | Parameter/constant | Change only if instructed |
| Green tick (ý) | Error check passes | No action needed |
| Red cross (þ) | Error check fails | Investigate |

See the **Style Guide** sheet for the complete formatting legend.

---

## 3. How to Use the Model

### 3.1 Changing Assumptions
1. Go to the **General Assumptions** sheet
2. Only change cells with a **yellow background**
3. All other sheets update automatically

### 3.2 Key Inputs
| Input | Location | Current Value | Notes |
|-------|----------|---------------|-------|
| [Revenue volume] | Gen Assumptions!J17 | [value] | [notes] |
| [Price] | Gen Assumptions!J18 | [value] | [notes] |
| [Inflation] | Gen Assumptions!J19 | [value] | Per period |

### 3.3 Changing the Timeline
Go to the **Timing** sheet to modify:
- **Number of periods**: Select from dropdown (5–20)
- **Start date**: Enter the first day of the first period
- **Periodicity**: Select months per period (1/3/6/12)
All other sheets update automatically.

### 3.4 Scenarios (if applicable)
[Describe how to switch between scenarios — dropdown location, what changes]

---

## 4. Understanding the Outputs

### 4.1 Income Statement
[Brief explanation of key lines and what drives them]

### 4.2 Balance Sheet
[Brief explanation, note the error checks at the bottom]

### 4.3 Cash Flow Statement
[Brief explanation, note the reconciliation check]

### 4.4 Key Metrics (if Dashboard exists)
[Describe the dashboard and what each metric means]

---

## 5. Error Checks

The **Error Checks** sheet consolidates all model integrity checks:

| Check | What It Means | What to Do If It Fails |
|-------|--------------|----------------------|
| BS has no errors | No formula errors on Balance Sheet | Click the hyperlink to investigate |
| BS balances | Assets = Liabilities + Equity | Check recent assumption changes |
| Insolvency check | Net assets > 0 | Review if equity has gone negative |
| CFS has no errors | No formula errors on Cash Flow Statement | Click to investigate |
| CFS reconciles | CFS closing cash = BS cash | Check all movements are captured |

**If any check shows a red cross**, click the hyperlink to go directly to the failing check.

---

## 6. Technical Reference

### 6.1 Named Ranges
Key named ranges (view all via Formulas → Name Manager):
| Name | Location | Value | Purpose |
|------|----------|-------|---------|
| Model_Start_Date | Timing!H17 | [date] | First period start |
| Periodicity | Timing!H19 | [n] | Months per period |
| Currency | Model Parameters!G45 | [unit] | Currency display label |

### 6.2 Sheet Index
| # | Sheet | Purpose |
|---|-------|---------|
| 1 | Cover | Project identity |
| 2 | Navigator | Table of contents |
| ... | ... | ... |

---

## 7. Limitations & Assumptions

[List key assumptions and limitations the user should be aware of:]
1. [Assumption 1]
2. [Limitation 1]
3. [What the model does NOT capture]

---

## 8. Contact

For questions or modifications, contact:
- **Developer**: [name] — [email]
- **Organisation**: [company name]
```

---

## 2. Handover Checklist

Run through this before delivering the model.

### Model Integrity
- [ ] All error checks pass (Overall_Error_Check = 0)
- [ ] Balance Sheet balances across all periods
- [ ] Cash Flow Statement reconciles across all periods
- [ ] Opening Balance Sheet balances
- [ ] No circular reference warnings
- [ ] File opens cleanly (no recovery prompt)
- [ ] Calculation mode is Automatic (not stuck on Manual)

### Structure & Navigation
- [ ] All sheets present in correct order
- [ ] Navigator has hyperlinks to every sheet
- [ ] Every sheet has Navigator return links (row 3)
- [ ] Every sheet shows error check in row 4
- [ ] Sheet tabs are clearly named

### Formatting & Styles
- [ ] All 30 Cell Styles present in Custom gallery
- [ ] Assumption cells have yellow background (Assumption style)
- [ ] Headings use correct Heading 1/2/3 styles
- [ ] Number formats are correct (percentages show %, dates show dates)
- [ ] Error checks show ticks (green) or crosses (red)
- [ ] Style Guide sheet is populated with all styles

### Content
- [ ] Cover sheet has: client name, model name, developer, contact, notes
- [ ] Model Parameters has all constants with named ranges
- [ ] Timing produces correct dates
- [ ] All scope requirements are addressed
- [ ] No WIP-styled cells remain (or converted to final)
- [ ] No developer notes that should be removed
- [ ] Change Log has initial entry

### Documentation
- [ ] User Guide written and reviewed
- [ ] Model Summary produced (Navigator skill output)
- [ ] Calculation Reference produced (Navigator skill output)
- [ ] Test Report included in package

### Print
- [ ] Print preview renders correctly (landscape, A4, header rows repeat)
- [ ] No cut-off columns in print

### File
- [ ] Saved in correct format (.xlsx or .xlsm)
- [ ] File size reasonable (not bloated)
- [ ] No external links (unless intentional)
- [ ] No personal file paths in formulas

---

## 3. Delivery Package Structure

```
[Project Name] Model Delivery/
│
├── [Model Name].xlsx (or .xlsm)         ← The model
│
├── USER_GUIDE.md (or .docx)             ← How to use it
│
├── Documentation/
│   ├── NAV_01_Model_Summary.md          ← What it does
│   ├── NAV_02_Model_Flowchart.mermaid   ← How it flows
│   └── NAV_03_Calculation_Reference.md  ← Every formula explained
│
├── Audit/
│   └── test_report.md                   ← Test results & CRaFT compliance
│
└── Reference/
    └── scope.md                         ← Original requirements (for traceability)
```

---

## 4. Change Log Format

The Change Log sheet in the model tracks all modifications:

| Column | Content | Style |
|--------|---------|-------|
| C | Date | Date style |
| E | Author | Line Calc |
| G | Description of change | Line Calc |
| I | Version number | Line Calc |

Initial entry:
```
Date: [build completion date]
Author: [developer name]
Description: Initial model build
Version: 1.0
```
