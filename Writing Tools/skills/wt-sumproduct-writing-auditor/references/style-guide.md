# SumProduct Style Guide — Derived from 80+ Liam Bastick Articles + 6 Live Audit Sessions

This guide is derived from analysis of 40+ Liam-edited DAX articles, 20+ Liam-written Excel articles, 10+ FFF/MMM pairs, AI blog comparison pairs (Valentina-vs-Liam), and 6+ live audit sessions producing tracked-changes Word documents.

## Table of Contents
1. [Universal Rules (All Series)](#universal)
2. [DAX Series Template](#dax)
3. [Excel Series Template](#excel)
4. [FFF Series Template](#fff)
5. [MMM Series Template](#mmm)
6. [Voice & Personality](#voice)
7. [Series Comparison Table](#comparison)

---

<a name="universal"></a>
## 1. UNIVERSAL RULES (Apply to Every Article)

### 1.1 Bold Formatting
| Element | Format | Example |
|---------|--------|---------|
| **DAX** (the language) | **Bold + CAPS** | **DAX** |
| **M** (the language) | **Bold** | **M** |
| Function names | **BOLD CAPS** | **VLOOKUP**, **CALCULATE**, **TRIM** |
| Argument names in text | **bold lowercase** | **value**, **table_name**, **num_chars** |
| Table/column names | **Bold** | **Data**, **Sales[Amount]** |
| Keyboard shortcuts | **Bold** | **F9**, **CTRL+SHIFT+ENTER** |
| Inline formula expressions | **Bold** | **LCM(a, b)** × **GCD(a, b)** |
| Example section subheadings | ***Bold-italic*** | ***Simple examples***, ***Decimal handling*** |

**IMPORTANT:** Feature names containing language names are NOT bold:
- ✓ "DAX query view" — feature noun, no bold
- ✗ ~~"**DAX** query view"~~ — don't bold the language when part of a feature name

**IMPORTANT:** Function names and argument names must be bold **everywhere** — including remark bullets, example paragraphs, and casual references. Common miss: "consider using TRIM" should be "consider using **TRIM**".

### 1.2 Italic Formatting
| Element | Format | Example |
|---------|--------|---------|
| Latin abbreviations | *italic with periods* | *i.e.*, *e.g.*, *viz.*, *etc.* |
| Error values | *italic* | *#VALUE!*, *#N/A*, *#NUM!* |
| Image references | *italic in parentheses* | *(below)*, *(above)*, *(pictured)* |

### 1.3 NOT Bold (Common Mistakes)
| Element | Correct | Incorrect |
|---------|---------|-----------|
| TRUE / FALSE | TRUE, FALSE (caps only) | ~~**TRUE**~~, ~~**FALSE**~~ |
| "DAX query view" | DAX query view | ~~**DAX query view**~~ |
| Feature names with "DAX" or "M" | plain text | ~~bold~~ |

### 1.4 Number Convention
- Integers 0–9: word [digit] → "three [3]", "zero [0]"
- All others (non-integers, negatives, ≥10): plain numbers → "3.14", "-7.15", "10"
- **No redundant repetition**: once zero [0] has appeared in a sentence, subsequent "zero" in the same sentence should NOT repeat [0]
- See `liam-rules.md` Rule A6 and A13 for full specification

### 1.5 Date Format
- D Month YYYY (or D Month YY)
- Single-digit day: NO leading zero → "6 Jan 26" not "06 Jan 26"
- No ordinals → "7 October" not "7th October"
- No US format → not "October 7, 2025"

### 1.6 British English
- -ise not -ize: categorise, organise, realise, optimise
- -our not -or: colour, behaviour, honour, favour
- -lling not -ling: modelling, travelling, cancelled
- -tre not -ter: centre, theatre
- -mme not -m: programme
- -ence not -ense: licence (noun), defence

### 1.7 Oxford Comma
UK English — NO Oxford comma by default.
- ✓ "cheese, tomato and lettuce"
- ✗ "cheese, tomato, and lettuce"

**Exception 1** (unrelated final clause): "I hate cheese, tomato and lettuce, and I love pickles"
**Exception 2** (item contains "and"): "I love kebabs, fish and chips, and vodka"

### 1.8 Products Listed with Slashes
```
Excel / Power Pivot / Power Query / Power BI
```
Space-slash-space between products, never commas.

### 1.9 Semicolons
- Before "no" in restrictions: "this was a formula challenge; no Power Query"
- To fix comma splices between independent clauses

### 1.10 Image Rules
- All images centred
- Table columns wide enough to show full headers (no truncation)
- Confirm no copyright issues

### 1.10b "the following Table" — Capitalised
When introducing results with "the following Table:", capitalise Table:
- ✓ "This will return the following Table:"
- ✗ "This will return the following table:"

### 1.10c Text Return Values — Single Quotes
Text values returned by functions use single quotes in prose (UK convention):
- ✓ returns 'Sum'
- ✗ returns "Sum"
Note: double quotes inside formula syntax remain unchanged.

### 1.10d "Would" → "Will" for Certain Outcomes
Use "will" for definitive behaviour, "would" only for hypothetical:
- ✓ "you will need to wrap it in **VALUE**"
- ✗ "you would need to wrap it in **VALUE**"

### 1.11 Bullet Point Consistency
- same punctuation (all periods or none)
- same capitalisation
- parallel grammatical structure.

### 1.12 Bullet Point Capitalisation
If bullets are a continuation of a clause, start lowercase (unless a proper noun). If standalone sentences, use normal capitalisation.

### 1.13 Bullet Point Full Stops
Only the very FINAL bullet in a list ends with a full stop. All preceding bullets: no full stop. This does not apply to sub-bullets.

### 1.14 Currency Format
Currency symbols precede the number: "$500", "£200", "€50" — never "500$".

### 1.15 Function Syntax — No Angle Brackets
Arguments in syntax blocks should NOT use < and >:
- ✓ `FUNCTIONNAME(value, table_name)`
- ✗ `FUNCTIONNAME(<value>, <table_name>)`

### 1.16 Function Syntax — Spacing
No space between function name and opening parenthesis; space after each comma:
- ✓ `COLLAPSEALL([expression], axis)`
- ✗ `COLLAPSEALL ([expression],axis)`

### 1.17 Double Space Between Sentences
Liam uses two spaces after a full stop before the next sentence:
- ✓ "First sentence.  Second sentence."
- ✗ "First sentence. Second sentence."
Applies to all running text, remark bullets, and descriptions. Does NOT apply inside code blocks or formula syntax.

---

<a name="dax"></a>
## 2. DAX SERIES TEMPLATE

**Written by:** Staff writers, **edited by** Liam Bastick
**Voice:** Third person / institutional ("we")
**Title format:** `***Power Pivot Principles: The A to Z of DAX Functions -- FUNCTIONNAME***` (bold-italic)

### Structure:
1. Title (bold-italic) + Date
2. Opening: *"In our long-established Power Pivot Principles articles, we continue our series on the A to Z of Data Analysis eXpression (**DAX**) functions. This week, we look at **FUNCTIONNAME**."*
3. Function heading: `***The FUNCTIONNAME function***` (bold-italic, single unbroken block)
4. Function description with category identification
5. Syntax block (bold)
6. Argument count: "There are N [N] main arguments in this function:"
7. Argument list (bulleted, bold names, lowercase descriptions)
8. Remarks: "Here are a few remarks about the **FN** function:"
9. Preamble explanation if function concept is unclear
10. Example section
11. Closing (exact wording with 3 links: Blog, Training, Past Articles)

### Key DAX Conventions:
- "Data Analysis eXpression" — capital X always
- Argument count uses word [digit]: "There are two [2] main arguments"
- "the information function**s**" (plural with article "the")
- DirectQuery remark (standard last bullet in remarks)
- INFO articles have standardised DMV boilerplate
- "TM **stands** for" (not "stand for" — systematic error in originals)
- **Power Pivot focus**: the series explains Power Pivot, not Power BI. Prefer Power Pivot examples. "DAX query view" is a Power BI feature — use cautiously, and always verify the function works in Power Pivot
- **Visual calculation functions** (COLLAPSEALL, EXPANDALL, etc.) are Power BI-only — these CANNOT be demonstrated in Power Pivot at all. Flag prominently.
- Function arguments: no angle brackets in syntax blocks
- **Example subheadings: bold-italic** — when walking through example results with labelled sections (***Simple examples***, ***Decimal handling***, etc.), subheadings must be bold+italic, not just bold
- **"the following Table:"** — capitalise Table when introducing DAX query results
- **Text return values in prose: single quotes** — 'Sum' not "Sum"
- **"will" not "would"** for definitive statements about function behaviour
- **Bold function names and argument names everywhere** — including in remark bullets and example prose
- **Product name spacing**: always "Power BI" (two words), "Power Pivot" (two words), "Power Query" (two words) — never "PowerBI" etc.
- **Cross-referencing**: when the DAX function has an Excel counterpart, check if Liam has a corresponding "A to Z of Excel Functions" article and cross-reference where appropriate (Rule D5)
- **Web verification (Rule D11)**: ALWAYS search Microsoft docs and dax.guide to verify syntax, argument names, and Power Pivot compatibility are current. DAX evolves — training data may be stale.

### Closing (Exact):
*"Come back next week for our next post on Power Pivot in the Blog section. In the meantime, please remember we have training in Power Pivot which you can find out more about here. If you wish to catch up on past articles in the meantime, you can find all of our Past Power Pivot blogs here."*

---

<a name="excel"></a>
## 3. EXCEL SERIES TEMPLATE

**Written by:** Liam Bastick directly
**Voice:** First person / conversational ("I", "my")
**Title format:** `**A to Z of Excel Functions: the FUNCTIONNAME Function**` (bold only)

### Structure:
1. Title (bold) + Date
2. Opening: *"Welcome back to our regular A to Z of Excel Functions blog. Today we look at the **FUNCTIONNAME** function."*
3. Function heading: `**The FUNCTIONNAME function**` (bold only)
4. Function description: "The **FN** function employs the following syntax to operate:"
5. Syntax block (bold)
6. Arguments: "The **FN** function has the following argument(s):"
7. Remarks: "It should be further noted that:"
8. Example: "Please see my example(s) below:"
9. Closing: *"We'll continue our A to Z of Excel Functions soon. Keep checking back -- there's a new blog post every [other] business day."*

### Key Excel Conventions:
- First person is CORRECT here — "my example", "I can't afford"
- NO argument count line (unlike DAX)
- Liam's humour is intentional — NEVER flag puns, asides, self-deprecation
- Legacy function notes: "This function supersedes **OLDNAME**"
- No closing links (unlike DAX)

---

<a name="fff"></a>
## 4. FFF (FINAL FRIDAY FIX) TEMPLATE

**Written by:** Staff writers
**Voice:** Team ("we")
**Tense:** PRESENT (challenge is active)

### Structure:
1. Title: `***Final Friday Fix: [Month] [Year] Challenge***`
2. Date
3. Intro paragraph (italic) — varies by era
4. `***The Challenge***`
5. Challenge description (present tense)
6. Requirements list (present: "needs", "is", "are")
7. "Feel free to use the attached Excel file to assist you."
8. *"Sounds easy? Then why not have a go? We'll publish one solution in Monday's blog."*

---

<a name="mmm"></a>
## 5. MMM (MONDAY MORNING MULLING) TEMPLATE

**Written by:** Staff writers, **heavily edited by** Liam
**Voice:** Team ("we") for narrative; **imperative** for solution steps
**Tense:** PAST (challenge has concluded)

### Structure:
1. Title: `***Monday Morning Mulling: [Month] [Year] Challenge***`
2. Date
3. Intro paragraph (italic)
4. Challenge recap — PAST TENSE (Liam's #1 edit from FFF)
5. Requirements list (past: "needed", "was", "were")
6. `***Suggested Solution***` — if sub-types, use en-dash: "Suggested Solution – Modern Excel"
7. Detailed solution walkthrough — **imperative voice** ("type a comma", not "we type a comma")
8. `***Word to the Wise***` — "We appreciate there are many, many ways this could have been achieved. If you have come up with an alternative, radically different approach, congratulations -- that's half the fun of Excel!"
9. Closing: *"The Final Friday Fix will return on Friday [DATE] with a new Excel Challenge. In the meantime, please look out for the Daily Excel Tip on our home page and watch out for a new blog every business working day."*

### Key MMM Conventions:
- Imperative voice in solutions: "provide", "type", "enter" (not "we provide", "we type")
- "It should be noted that:" for explanatory list introductions (not "Here,")
- Explanatory bullets as standalone sentences (capitalised, with full stops)
- Sub-type labels: sentence case ("Legacy version" not "Legacy Version")
- Suggested Solution sub-types separated by en-dash (–), not colon
- Include honest caveats about solution limitations when relevant
- "based upon" preferred in technical descriptions

---

<a name="voice"></a>
## 6. VOICE & PERSONALITY

### Liam's Signature Style:
- **Dry British humour**: puns, self-deprecation, parenthetical asides
- **"We" for team content**, "I/my" for personal Excel articles
- **Irreverent intros**: "We'll feel free to ignore you", "If you don't like it, lump it"
- **Self-referencing expertise**: "consult an expert (hi, we are over here...)"

### Filler Words Liam Removes:
- "Well," at start of sentences
- "filter out" → "filter"
- "shall" → "should"
- "just" → "simply" or removed
- Unnecessary emphasis/italic
- Redundant words that add no meaning

### Word Preferences:
- "based upon" (not "based on") — default preference
- "whilst" (not "while") — for contrast/alternatives
- "However," (not "But") — at sentence start
- "judgment" (not "judgement") — Liam's preferred spelling
- "simply" (not "just") — when used as filler
- "impressive" (not "amazing") — tone down superlatives
- "may" (not "can") — when hedging AI capability claims

### Sentence Clarity:
- Liam restructures unclear sentences
- Provides preamble explanations for complex concepts
- Removes double-causal constructions ("Since...hence")
- Fixes word order errors
- Adds commas after introductory adverbs ("Now, we can...")
- Adds precision: "visual standards" → "required visual standards"

---

<a name="ai-blog"></a>
## 6b. AI BLOG SERIES TEMPLATE

**Written by:** Staff writers (e.g., Valentina), **edited by** Liam
**Voice:** Team ("we")
**Tense:** Present

### Key AI Blog Conventions:
- **Hedge AI capability claims** — use "may" not "can" for what AI tools do (see Rule C8/H1)
- **Feature/mode names in single quotes** — 'Audio Overview', 'Interactive Mode' (see Rule A15)
- **Number convention applies** — "two [2] practical ways" (commonly missed by writers)
- **"Whilst" for contrasts** — "one prioritises speed, whilst the other..."
- **"Based upon"** preferred over "based on"
- **"However,"** not "But" at sentence start
- **Tone down superlatives** — "impressive" not "amazing"
- **Add precision** — qualify vague terms ("required visual standards" not "visual standards")
- **Transitional phrases** — "Let me explain.", "Keep reading!" for flow
- **"Judgment"** not "judgement"
- Sentence case for mid-article sub-headings
- **Web verification (Rule D11)**: ALWAYS search for latest news about AI tools mentioned. AI tools change rapidly — tools get rebranded (Bard → Gemini), features are added/removed, tools get discontinued. Flag any outdated claims as Critical.

---

<a name="comparison"></a>
## 7. SERIES COMPARISON TABLE

| Feature | DAX | Excel | FFF | MMM | AI Blog |
|---------|-----|-------|-----|-----|---------|
| Writer | Staff | Liam | Staff | Staff+Liam | Staff+Liam |
| Voice | we | I/my | we | we + imperative | we |
| Title format | Bold-italic | Bold | Bold-italic | Bold-italic | Bold |
| Arg count | word [digit] | No count | N/A | N/A | N/A |
| Example intro | "Let's consider..." | "Please see my..." | N/A | N/A | N/A |
| Tense | Present | Present | Present | **Past** | Present |
| Closing links | 3 links | No links | None | Dated return | Teaser |
| Humour | Light | Frequent | None | None | None |
| Word to Wise | No | No | No | **Yes** | No |
| Hedge claims | No | No | No | No | **Yes** |
| Solution voice | N/A | N/A | N/A | **Imperative** | N/A |
