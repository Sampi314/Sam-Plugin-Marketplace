# Shadow Dependency Extraction Guide

Shadow dependencies are structural relationships that don't appear in formula tracing but create real data flow connections. These must be fully resolved and recorded.

## Step 1 — Table Inventory

For every sheet, enumerate all ListObjects (Tables):

| Table Name | Sheet | Header Row | Data Range | Column Names |
|---|---|---|---|---|

For each table, record: table name, host sheet, header row number, current data range, all column names, whether it has a total row.

## Step 2 — Named Range Resolution

Build a **Name Resolution Table** from the Name Manager:

| Name | Refers To (raw) | Scope | Resolution Type | Resolved Sheet | Resolved Range | Source Table | Status |
|---|---|---|---|---|---|---|---|

**Resolution logic:**

a. **Structured table reference** (e.g., `=tbl_Lookups[Status]`): Look up the table, resolve to physical column range. Type: `Table Column`.

b. **Static cell/range reference** (e.g., `=Sheet1!$A$1:$A$50`): Resolve directly. Type: `Static Range` or `Single Cell`.

c. **Formula** (e.g., `=OFFSET(...)`): Flag as ⚠️ MEDIUM — dynamic, cannot be statically resolved. Type: `Dynamic Formula`.

d. **#REF!**: Flag as 🔴 HIGH — broken reference. Type: `Error`.

e. If scoped to a single sheet, note the scope.

## Step 3 — Data Validation Extraction

For every data validation rule on every sheet, classify and trace the full chain.

### Classification of Validation Source Types

| Source Type | Example formula1 | Resolution Hops | Description |
|---|---|---|---|
| **Hardcoded List** | `"Yes,No,Maybe"` | 0 | Values embedded directly. No external dependency. |
| **Direct Range** | `=Lookups!$A$2:$A$50` | 1 | Points directly to a cell range. |
| **Named Range → Static** | `=Status_List` (→ `Lookups!$A$2:$A$50`) | 2 | Validation → Named Range → Static range. |
| **Named Range → Table** | `=Status_List` (→ `tbl_Lookups[Status]`) | 3 | Validation → Named Range → Table → Physical cells. |
| **Direct Table Reference** | `=tbl_Lookups[Status]` | 2 | Points directly to a table column. |
| **Dynamic Formula** | `=OFFSET(...)` or `=INDIRECT(...)` | Unknown | Cannot be statically resolved. Flag as ⚠️ MEDIUM. |

### Extraction Procedure

For each validation rule:

1. **Record target cells** (the `sqref`).
2. **Extract `formula1`** (and `formula2` if present).
3. **Classify the source type**.
4. **Resolve the full chain**:
   - **Hardcoded**: No arrow. Record in inventory only.
   - **Direct Range**: One edge: `Source!Range → Target cells` (type: `VALIDATION`).
   - **Named Range → Static**: Flatten: `Source!Range → Target` (via: name).
   - **Named Range → Table**: Full resolution: table → column → physical range → target (via: name, source table).
   - **Direct Table**: Resolve column to physical range → target.
   - **Dynamic**: Flag as ⚠️, record raw formula.
5. **Deduplicate**: Same rule across a range → record once.

## Step 4 — Conditional Formatting Extraction

For every CF rule on every sheet:

1. Record target range.
2. Extract the rule formula.
3. Parse all cell references.
4. Resolve named ranges or table references within.
5. Record each as directed edge with type `COND_FORMAT`.
6. Note: CF dependencies are display-only but reveal hidden logic.

## Step 5 — Shadow Dependency Classification

| Type Code | Meaning | Arrow Style |
|---|---|---|
| `VALIDATION` | Validation sourced from cells on another sheet | Dotted: `-. "label" .->` |
| `VALIDATION_HARDCODED` | Hardcoded list (no external dependency) | No arrow (inventory only) |
| `VALIDATION_DYNAMIC` | Unresolvable dynamic formula | Dotted with ⚠️ label |
| `COND_FORMAT` | CF rule references cells on another sheet | Dotted (grey) |
| `NAME_DEF` | Named range definition (internal record) | — |

## Shadow Health Summary Template

| Metric | Count | Notes |
|---|---|---|
| Total Tables | X | |
| Active Tables (referenced) | X | |
| Orphaned Tables | X | 🟡 Consider removing |
| Total Named Ranges | X | |
| Active Named Ranges | X | |
| Broken Named Ranges (#REF!) | X | 🔴 Fix immediately |
| Orphaned Named Ranges | X | 🟡 Consider removing |
| Total Validation Rules | X | |
| Table-backed validations | X | Most robust pattern |
| Hardcoded validations | X | |
| Dynamic/unresolvable | X | ⚠️ Review manually |
| Broken validations | X | 🔴 Fix immediately |
| Total CF Rules | X | |
| Cross-sheet CF rules | X | Shadow dependencies |

## Key Insight

Shadow dependencies are often **more fragile** than formula dependencies. A broken named range silently kills a dropdown with no `#REF!` error to alert anyone. A deleted table column silently breaks a validation. Flag all broken shadow chains as 🔴 HIGH.
