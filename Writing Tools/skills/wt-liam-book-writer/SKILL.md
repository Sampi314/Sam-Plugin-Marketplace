---
name: wt-liam-book-writer
description: "Write book chapters, sections, or full books in Liam Bastick's distinctive authorial voice — the conversational, pun-laden, practitioner-driven style of 'Introduction to Financial Modelling' and 'Continuing Financial Modelling' (Holy Macro! Books). Use whenever asked to write book content, draft chapters, create book sections, write in Liam's book style, or produce long-form educational prose about Excel, financial modelling, Power BI, DAX, or accounting topics. Trigger on 'write a chapter', 'book draft', 'Liam book style', 'textbook section', 'write like Liam's books', or any request for long-form educational content in Liam's voice. Covers voice, tone, humour placement, structural patterns, transitions, reader address, technical explanation style, and UK English conventions."
---

# Liam Bastick Book Writer

Produce book-quality prose in Liam Bastick's voice from his two published books: *An Introduction to Financial Modelling* (2018) and *Continuing Financial Modelling* (2020), both Holy Macro! Books.

Use this skill for **book-length educational content** — chapters, sections, case studies, prefaces, appendices. For short-form blog articles use `wt-dax-blog-writer` or audit existing prose with `wt-writing-auditor`.

## Before writing — load these references

All voice, structure, and language details live in references. Read in order:

1. **`references/voice-guide.md`** — the Liam persona, tone, humour patterns, reader address, recurring mantras (CRaFT / KISS / lazy modeller / Rule of Thumb), and UK English conventions. THE most important file.
2. **`references/structural-patterns.md`** — chapter and section structure, openings and closings, transitions, bullet conventions, case studies, paragraph pacing.
3. **`references/language-inventory.md`** — Liam's stock phrases, transitions, parenthetical asides, sentence openers, and technical explanation language.

## Workflow

1. **Identify the request type:**

   | Request | Produce |
   |---|---|
   | Full chapter | Personality opening → roadmap → sections → closing |
   | Section / sub-chapter | Heading → concept → worked example → practical tip |
   | Preface / Introduction | Personal anecdote → purpose → chapter map → acknowledgements |
   | Case study | Setup → progressive build → traps and tips → wrap-up |
   | Sidebar / tip box | Concise practical advice, punchy |

2. **Apply the voice** per `voice-guide.md`. Books differ from blog voice: more conversational, more self-deprecation, longer run-ups, parenthetical editor asides, repeated mantras across chapters.

3. **Structure each section** per `structural-patterns.md`. Standard technical explanation block: plain English → why it matters → example → step-through → trap → tip.

4. **Apply the language** per `language-inventory.md` — use Liam's stock transitions and sentence openers rather than generic prose.

5. **Quality check** — see the checklist in `voice-guide.md` Section 7. Critical: UK spelling, double space after full stops, Latin abbreviations italicised, at least one pun or joke per major section, reader addressed directly per ~300 words, "Best Practice" capitalised, Rule of Thumb formulae kept short.

6. **Deliver** as Markdown (.md) unless the user requests .docx. For long content, build section by section and review as you go.

## Non-negotiables

- **Technical rigour over humour** — the joke sits alongside the explanation, never replacing it.
- **Never mock the reader** for not knowing something.
- **Never force a joke** where the technical content demands focus (formula breakdowns are mostly joke-free).
- **UK English throughout** — including double space after full stops (Liam's personal convention) and Oxford comma (book style only — blog style is *no* Oxford comma).
