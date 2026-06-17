# Style Anchor — Daily AI Blog Image Prompt

The locked visual descriptor that goes in every image call. Per-post calls
prepend a one-sentence concept; the script appends this anchor verbatim.
Editing this file shifts the whole daily series — touch it deliberately.

The visual language is modelled on the Claude Skills 3-part field-guide
images (Parts 1–3): polished 3D illustrations and clean labelled diagrams
that directly illustrate the article's content, not abstract still life.

Colours and imagery rules come from `brand-spec.md`; keep the two in sync.

---

## Anchor (sent verbatim to Gemini after the per-post concept)

> Composition: a polished 3D-rendered illustration OR clean infographic
> diagram, in the style of a modern technical editorial publication. Soft
> isometric or three-quarter angle perspective when depicting objects;
> clean labelled flat-vector style when depicting diagrams, flowcharts or
> before/after comparisons. Bright, friendly mood — never dark, never moody.
>
> Background: a bright off-white or very light cream field (around
> #f5f5ef) with a subtle pale-lime tint in one corner. Soft shadows under
> 3D objects. Modest depth of field that keeps labels and details legible.
>
> SumProduct Green (#007033) is the dominant accent — the strong brand
> colour on folders, files, key surfaces, headers, callout labels, and
> the main highlights. Lime (#d2f7b1) as secondary lighter accent / soft
> glow / tag colour. Dark Green (#1e3c3b) only as fine line work, label
> text, or small accent shadows — never as a flooded background.
>
> Subjects are CONCRETE and tied to the article content: folders, files,
> code editor windows, spreadsheets, terminal windows, file trees,
> labelled flowcharts, layered stacks, before/after comparisons, annotated
> UI elements, or 3D-rendered illustrations of the specific objects the
> article discusses. The reader should see what the prose describes —
> not abstract metaphor.
>
> Text labels are encouraged where they help — folder names, file names,
> section headers, callout labels, numbered annotations, short captions
> (1–4 words). Keep typography clean sans-serif, modest weight, legible.
> Mathematical or logical symbols (Σ, ∫, ∇, ≈, ∂, =) may appear at very
> low opacity as background watermark but should never dominate.
>
> Strictly no people, no faces, no hands, no third-party brand logos
> (other than abstract icons that obviously stand in for a concept), no
> neon, no glowing orbs, no neural-network mesh, no dark moody
> atmospheres, no black backgrounds. The mood is bright, modern,
> technical, friendly — like an illustration in a contemporary technical
> publication.

---

## Why this descriptor

- **Polished 3D illustration / labelled diagram** matches the Claude
  Skills 3-part series tone and produces images the reader can decode at
  a glance — folders, files, flowcharts, comparisons.
- **Content-grounded subjects** mean the reader sees what the prose
  describes (a plugin folder, a marketplace manifest, a before/after of
  scattered Skills vs bundled plugin), not abstract glass cubes.
- **Text labels allowed** because the reference series uses them
  extensively — "SKILL.md", "plugin.json", "Match?", "Yes/No", section
  headers. Pure imagery without any label often reads as decorative.
- **SumProduct Green dominant + Lime secondary** keeps the brand front
  and centre and matches the wordmark green.
- **Bright background** keeps the series readable at small sizes and
  suits a daily news brief, not a hero spread.
