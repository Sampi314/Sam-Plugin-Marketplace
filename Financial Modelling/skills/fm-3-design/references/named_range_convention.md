# Named Range Naming Convention

Two prefixes, mandatory. Build code rejects names that don't match these patterns.

## `HL_NNN` — Sheet navigation targets

One per sheet, anchored at `$A$3`. Three-digit zero-padded number assigned in sheet tab order.

| Name | Refers to |
|---|---|
| HL_000 | Cover!$A$3 |
| HL_001 | Cover!$A$3 |
| HL_002 | 'Style Guide'!$A$3 |
| HL_003 | 'Model Parameters'!$A$3 |
| HL_004 | Timing!$A$3 |
| HL_005 | 'Error Checks'!$A$3 |
| HL_006 | 'Change Log'!$A$3 |
| HL_007 | 'Sam Notes for Model Build'!$A$3 |
| HL_008 | 'Timing Template'!$A$3 |
| HL_009 | 'No Timing Template'!$A$3 |
| HL_010 | 'No Timing Template'!$A$3 |

## `HL_<name>` — Special navigation targets

PascalCase. Used for non-per-sheet links (e.g. the navigator itself, or error-check jump targets).

| Name | Refers to |
|---|---|
| HL_Navigator | Navigator!$A$1 |

## `N_<PascalCase>` — Named constants and key cells

PascalCase with underscores between words. Used for every constant the model references by name.

| Name | Refers to |
|---|---|
| N_Client_Name | 'Model Parameters'!$G$12 |
| N_Days_in_Year | 'Model Parameters'!$G$19 |
| N_Example_Reporting_Month | Timing!$H$19 |
| N_Model_Name | 'Model Parameters'!$G$11 |
| N_Model_Start_Date | Timing!$H$15 |
| N_Months_in_Half_Yr | 'Model Parameters'!$G$22 |
| N_Months_in_Month | 'Model Parameters'!$G$20 |
| N_Months_in_Qtr | 'Model Parameters'!$G$21 |
| N_Months_in_Year | 'Model Parameters'!$G$23 |
| N_Overall_Error_Check | 'Error Checks'!$I$17 |
| N_Periodicity | Timing!$H$17 |
| N_Quarters_in_Year | 'Model Parameters'!$G$24 |
| N_Reporting_Month_Factor | Timing!$H$21 |
| N_Rounding_Accuracy | 'Model Parameters'!$G$26 |
| N_Thousand | 'Model Parameters'!$G$31 |

## What NOT to use

- `_xleta.*` is reserved by Excel for LET equivalents — do not user-define.
- Names without a prefix (e.g. bare `Days_in_Year`) — always use `N_Days_in_Year`.
- `HL_` without the 3-digit number (e.g. `HL_BS_Errors`) — use a number for sheet links or `HL_<PascalCase>` for special targets.
