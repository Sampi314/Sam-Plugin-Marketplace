# _fm-shared

Shared resources used by multiple `fm-*` skills. The leading underscore signals
that this is NOT a skill itself (no SKILL.md, will not be auto-discovered as a
skill). Skills reference these files by relative path:
`../_fm-shared/scripts/md_to_docx.py` etc.

## Contents

- `scripts/md_to_docx.py` — convert a Markdown file to .docx. Used by fm-1-scope,
  fm-2-plan, fm-6-implement.
- `scripts/inspect_workbook.py` — workbook X-ray: one read-only pass dumps a
  markdown digest (sheets, named ranges, R1C1 pattern groups with break
  detection, error cells, styles, validations, CF, hyperlinks). Run FIRST in
  any analysis — fm-5-test Step 2, fm-1-scope existing-model engagements,
  Optimisation-type diagnosis.
- `scripts/verify_build.py` — post-build verifier: asserts styles registered,
  names resolve, Overall_Error_Check = 0, no error values, hyperlinks valid.
  Exit 0/1. Run by fm-4-build before handing to fm-5-test.
- `references/craft_principles.md` — single canonical statement of the Sam
  CRaFT methodology (Consistency, Robustness, Flexibility, Transparency).
  Referenced from fm-orchestrator and fm-5-test.
- `references/model_types.md` — canonical registry of all 13 model types:
  trigger phrases, skeletons, calculation patterns, type-specific checks,
  complexity scaling, and the phase applicability matrix. Referenced from
  every fm- phase skill. **Edit type definitions HERE, not in phase skills.**

## Why a shared folder rather than a skill?

A skill folder must contain a SKILL.md with frontmatter; the discovery layer will
try to load `_fm-shared/SKILL.md` and fail noisily. Prefixing with `_` is the
agreed convention in this workshop for "resources, not skills".
