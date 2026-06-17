# Brand Spec — Daily AI Blog Visual & Editorial Language

Distilled from the upstream brand guidelines for use by the visual generation
scripts and the writing skill. This file is the in-plugin **source of truth**
for colour palette, typography, imagery rules, and voice. The scripts read
these constants here, not from their own baked-in defaults.

If the upstream brand guidelines are updated, re-derive this file from them.

---

## Colour palette

**Primary**

| Name       | Hex       | Notes                                  |
|------------|-----------|----------------------------------------|
| Dark Green | `#1e3c3b` | Backgrounds, dominant brand colour     |
| Lime       | `#d2f7b1` | Accent, highlights, light contrast     |

**Secondary**

| Name  | Hex       | Notes                                |
|-------|-----------|--------------------------------------|
| Green | `#007033` | Mid-tone, body accents, CTA buttons  |

**Neutrals**

| Name       | Hex       |
|------------|-----------|
| Black 100% | `#000000` |
| Black 70%  | `#6d6e71` |
| Black 50%  | `#939598` |
| Black 30%  | `#bcbec0` |
| Black 10%  | `#e6e7e8` |
| White      | `#ffffff` |

**Gradients** — linear at 45° angle. Approved combinations only:

- Dark Green → Black
- Lime → Green
- Lime → Black
- Dark Green → Lime
- Green → Dark Green
- White → Lime
- White → Black

**Accessible chart palette (Okabe-Ito)** — for data charts only, not brand identity:
`#e69f00` Orange, `#56b4e9` Sky Blue, `#009e73` Teal, `#f0e442` Yellow,
`#0072b2` Blue, `#d55e00` Vermillion, `#cc79a7` Pink, `#999999` Gray.

---

## Typography

**Primary typeface: DM Sans** (sans-serif). All headings and body in printed
and digital communications. Bold for headings, regular for body.

**Editorial / pull quotes: Noto Serif**, italic for pull quotes.

**Newsletters and internal docs: Calibri** or **Arial**.

**Hierarchy**

| Style      | Typeface  | Size       | Weight     | Use                       |
|------------|-----------|------------|------------|---------------------------|
| Display H1 | DM Sans   | 40–60 pt   | Bold       | Hero / cover headings     |
| Heading H1 | DM Sans   | 28–36 pt   | Bold       | Section titles            |
| Heading H2 | DM Sans   | 18–24 pt   | Bold       | Sub-section headings      |
| Heading H3 | DM Sans   | 14–16 pt   | SemiBold   | Content headings          |
| Body       | DM Sans   | 9–10 pt    | Regular    | All running text          |
| Caption    | DM Sans   | 7–8 pt     | Regular    | Image captions, labels    |
| Quote      | Noto Serif| 13–16 pt   | Italic     | Pull quotes, testimonials |

**Rules**

- Always sentence case for headings.
- Never ALL CAPS in body text.
- Maximum two typefaces per layout.
- Never decorative or script fonts.
- Never change font colours outside the palette above.

---

## Imagery rules

**Visual DNA: mathematical and logical symbols.** Symbols such as Σ, ∫, ∇,
≈, ∂, =, ≠, ⌐, ÷ appear as background patterns, image frames, and decorative
elements. Reference: analytics/Excel heritage — a distinctive, ownable
graphic vocabulary.

- Symbols: maximum **20% transparency**.
- Adjust to avoid busy or cluttered layouts.

**Photography subjects (three families)**

- *People at work* — collaborative, active scenes; genuine expressions, never
  posed smiles; diverse representation; modern, light office environments.
- *Data & technology* — close-up shots of screens, keyboards, notebooks;
  mathematical formulae and equations; abstract data visualisations;
  clean, high-contrast technical imagery.
- *Atmosphere & texture* — architectural geometric forms; light and shadow
  with strong contrast; textured surfaces (paper, glass, metal); macro shots
  with shallow depth of field.

**Image treatment**

- Subtle **Green**, **Dark Green**, or **Lime** colour overlay at
  **10–30% opacity** is the approved consistency device.
- Mathematical symbol overlays at 10–30% opacity allowed.
- Never stretch, pixelate, or distort.
- Never heavy filters, extreme saturation, or artificial vignettes.
- Black-and-white only for historical or editorial contexts.

**Daily AI blog variant** (the variant the `wt-ai-write` skill uses): bright
off-white backgrounds, SumProduct Green (`#007033`) dominant on the subject,
clean technical-savvy editorial / engineering-documentation feel. Dark Green
only as fine line work — never as a flooded background. See
`style-anchor.md` for the verbatim prompt fragment.

---

## Brand personality and voice

**Personality** — five attributes:

| Attribute     | Meaning                                                            |
|---------------|--------------------------------------------------------------------|
| Expert        | Deep craft knowledge; speak with authority and clarity.            |
| Approachable  | Complex ideas made simple. Never intimidate, never talk down.      |
| Precise       | Every number, word, and pixel is intentional.                      |
| Innovative    | Push the boundaries of what spreadsheets and data can achieve.     |
| Trusted       | Consistency in brand builds consistency in reputation.             |

**Voice characteristics** — four:

- **Knowledgeable** — specific numbers and data; back claims with evidence;
  avoid vague superlatives. Never "we are the best".
- **Clear** — short sentences; lead with the key point; active voice. Never
  bury the message; never pad with filler.
- **Human** — "you" and "we"; acknowledge challenges; celebrate wins. Never
  robotic, never overly formal.
- **Confident** — stand by expertise; don't hedge unnecessarily. Avoid
  excessive "might", "maybe", "perhaps".

**Writing style rules**

- Aim for short sentences. Mix short with longer explanatory ones.
- Write numbers numerically in body copy (3, not three).
- Use `%` not the word "percent" in data contexts.
- Sentence case for all headings; never ALL CAPS except logo or approved design.
- Spell out acronyms on first mention, e.g. "Power Query (PQ)"; abbreviate after.
- Inclusive language; gender-neutral; "they/them" as singular pronoun where
  appropriate.

**Tone by channel**

| Channel    | Tone shift                |
|------------|---------------------------|
| LinkedIn   | Professional and insightful |
| Email      | Direct and helpful          |
| Website    | Clear and converting        |
| Newsletter | Friendly and educational    |
