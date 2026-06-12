# design.md Template — Phase 3 Output Contract

Phase 3 ends with one artefact: `design.md`, structured exactly as below.
Phase 4 (fm-4-build) consumes it section by section — the section numbers map
directly onto build steps, so keep the numbering and the column orders intact.
Fill every section; where the standard register applies unchanged, say
"Standard — no deltas" rather than omitting the section, so the builder never
has to guess whether something was considered or merely forgotten.

---

## 0. Header

Why: ties the spec to its upstream artefacts so Build (and later the Phase 5
auditors) know exactly which scope and plan this design implements.

```markdown
# Design Specification — TechCorp DCF
- **Model name:** TechCorp DCF
- **Model type:** Standalone DCF valuation
- **Date:** 2026-06-12
- **Inputs:** scope.md (Phase 1) at `./scope.md`; plan.md (Phase 2) at `./plan.md`
```

## 1. Cell Styles

Why: Build creates every style before any sheet content (styles with
`IncludeNumber=True` overwrite number formats set earlier), so it needs the
complete adopted register in one table. Adopt from the 30-style register in
`sam_styles.md`; the "Based On" column records the register entry so
any deviation is visible at a glance.

| Style Name | Based On | Font | Fill BGR | Number Format | Usage |
|---|---|---|---|---|---|
| Assumption | Register #10 | Calibri 10 | 0x99FFFF | — (IncludeNumber=False; set per context) | All user-input cells |

### 1a. Deltas / additions

List every departure from the standard register — changed colour, new style,
omitted style — with the reason. "Standard — no deltas" if none.

| Style Name | Change | Reason |
|---|---|---|
| Scenario_Heading | New: Calibri 10 bold white, fill 0xC47244 | Scenario switch block needs its own header band |

## 2. Named Range register

Why: Build creates all names in one pass (build step 19) but formulas
reference them throughout — a complete register up front prevents `#NAME?`
chases at Test time.

| Name | Sheet | RefersTo | Purpose |
|---|---|---|---|
| Model_Start_Date | Timing | =Timing!$J$12 | First day of the first forecast period |

## 3. Number Format registry

Why: styles with `IncludeNumber=False` (e.g. Assumption) need their format set
separately, so Build must know which format each context gets. Full catalogue
and segment syntax: `validation_and_formats.md`.

| Context | Format Code | Example |
|---|---|---|
| Growth-rate assumptions | `0.0%` | 5.5% |

## 4. Data Validation spec

Why: validation is the model's only guard on user inputs; an explicit per-range
spec means Build wires it mechanically and Test can verify it cell by cell.

| Sheet | Range | Type | Operator | Source/Formula | Input Message |
|---|---|---|---|---|---|
| Timing | J14 | List | — | `"1,2,3,4,6,12"` | Months per period: 1=Monthly, 3=Quarterly, 6=Half-yearly, 12=Annual |

## 5. Conditional Formatting rules

Why: CF is applied late (build step 21) over finished ranges; listing rules
here stops them being improvised — or skipped — sheet by sheet.

| Sheet | Range | Rule | Formula | Format |
|---|---|---|---|---|
| Error Checks | J20:AC40 | Cell value = 0 | =0 | Green fill 0xCEEFC6, font 0x006100 |

## 6. Column layout per sheet class

Why: a uniform grid is what makes every periodic sheet readable in the same
way; deviations must be deliberate and recorded. Standard layout:
`cf_and_column_layout.md`.

**Periodic working sheets** (Assumptions, Calculations, statements, schedules):

| Column | Width | Purpose |
|---|---|---|
| E | 30 | Row labels |

**Deviating sheet classes** (Cover, Navigator, Lookup, dashboards) — one table
each, same columns.

## 7. Navigation spec

Why: hyperlinks are wired after all sheets exist (build step 20); the TOC and
return links only work if targets are pinned down before Build starts.

| TOC Entry (Navigator) | Target | Return Link |
|---|---|---|
| Model Parameters | 'Model Parameters'!A1 | Row 3 → Navigator!A1 |

Cover the Navigator TOC entries (one per content sheet, in tab order), the
per-sheet row-3 return links (`HL_Navigator`), and any error-check jump links
(`HL_BS_Errors` etc.).

## 8. Build notes & exceptions

Why: the catch-all that stops verbal agreements evaporating between phases —
anything Build must know that fits no table above.

Example: *"Lookup sheet is non-periodic; skip period-visibility CF there.
Client logo on Cover is deferred to Phase 6."*
