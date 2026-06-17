# Editorial Rules

This document has TWO tiers:

1. **TIER 1 — UK English Rules**: Standard British English writing conventions. These are not Liam-specific — they are the baseline for any UK English publication.
2. **TIER 2 — Liam's Rules**: editorial rules defined by Liam Bastick. These sit ON TOP of UK English rules and override where there is a conflict.

When auditing, apply BOTH tiers. Tier 2 always wins over Tier 1 if there is a conflict.

---
---
---

# TIER 1: UK ENGLISH RULES (Foundation)

These are standard British English conventions that all content must follow.

---

## UK1. British Spelling

Use British English spelling throughout. Never use American English variants.

| US (Wrong) | British (Correct) |
|-----------|-------------------|
| categorizing | categorising |
| organizing | organising |
| realized | realised |
| specialized | specialised |
| color | colour |
| behavior | behaviour |
| favor | favour |
| honor | honour |
| modeling | modelling |
| traveling | travelling |
| canceled | cancelled |
| center | centre |
| theater | theatre |
| analyze | analyse |
| optimize | optimise |
| fulfill | fulfil |
| program | programme |
| defense | defence |
| license (noun) | licence (noun) |

## UK2. No Oxford / Boston Comma

UK English does NOT use the Oxford (serial) comma:

- ✓ "cheese, tomato and lettuce"
- ✗ "cheese, tomato, and lettuce"

### Two Standard Exceptions:

**Exception 1: Final subclause is unrelated to preceding items**
- ✓ "I hate cheese, tomato and lettuce, and I love pickles"
(The "and I love pickles" is a separate thought, not part of the list)

**Exception 2: A list item contains "and"**
- ✓ "I love kebabs, fish and chips, and vodka"
("fish and chips" is one item — the comma prevents ambiguity)

### How to Audit:
1. Find every ", and" in the text
2. Check if either exception applies
3. No exception → flag and remove the comma before "and"
4. Exception applies → comma is correct, do not flag

## UK3. Currency Symbols Precede the Number

- ✓ "$500", "£200", "€50", "¥1,000"
- ✗ "500$", "200£", "50€"

## UK4. Date Format

- Day before month: "6 January 2026"
- No American format: not "January 6, 2026"
- No ordinals: not "6th January"

## UK5. Quotation Marks

UK English uses single quotation marks for primary quotes:
- ✓ 'Tabular model'
- Double quotes for quotes within quotes

## UK6. -ise vs -ize

UK English accepts both, but the house style uses the **-ise** form consistently:
- ✓ categorise, organise, recognise, specialise
- ✗ categorize, organize, recognize, specialize

---
---
---

# TIER 2: LIAM'S RULES (Editorial — On Top of UK English)

These rules are defined by Liam Bastick. They sit on top of standard UK English and take priority.

Rules are grouped into six categories:
- **A. Formatting** — bold, italic, numbers, dates
- **B. Bullet Points** — capitalisation, punctuation, consistency
- **C. Grammar & Style** — filler removal, semicolons, tense
- **D. Technical** — function syntax, accuracy, Power Pivot
- **E. Images** — centering, column widths, copyright
- **F. Terminology** — product names, feature names

---

## A. FORMATTING RULES

### A0. Default Is NOT Bold

Most prose is plain text. **Bold is reserved for the specific cases listed in the rules below** (function names, argument names, key technical terms, field / column / cell references, inline formula expressions, programming languages, syntax lines, example sub-headings).

If a word does not fall into one of those categories, do not bold it — no matter how important it feels in the moment. When auditing, default to *removing* bold rather than *adding* it.

This is the master principle of the bold convention. Liam: "Take care with what you embolden. Most other things are not [bold]."

### A1. Bold: Languages vs Feature Names

The programming languages **DAX** and **M** are bold when referenced as languages:
- ✓ "we write a **DAX** formula" — **DAX** is the language
- ✓ "this can be achieved in **M**" — **M** is the language

However, nouns and feature names that contain these words are NOT bold:
- ✓ "DAX query view" — feature/noun, no bold anywhere
- ✗ ~~"**DAX query view**"~~
- ✗ ~~"**DAX** query view"~~ (don't bold "DAX" when it's part of a feature name)

### A2. Function Names — Always Bold (Everywhere)

All function names in running text must be bold and in CAPS — this applies **everywhere** in the article, including inside remark bullet points, example walkthrough paragraphs, and inline references:

**VLOOKUP**, **SUMPRODUCT**, **INDEX**, **MATCH**, **CALCULATE**, **FILTER**, **KEEPFILTERS**, **TRIM**, **VALUE**

Common miss: function names in remark bullets or casual mentions (*e.g.*, "consider using TRIM") often lack bold. They must ALWAYS be bold: "consider using **TRIM**".

### A2b. Argument Names — Bold in Running Text

Function argument names (*e.g.*, **num_chars**, **number1**, **value**, **table_name**, **expression**, **axis**) must also be bold when referenced in running text, including:

- Inside remark bullets: "if the **num_chars** argument is larger than..."
- In their own argument descriptions: "**expression:** this represents the **expression** to be evaluated"
- In other remarks referencing them: "referenced by the **axis** reference"

Common miss: argument names in their own description line are bold at the label but NOT bold when the same word appears again in the description text. Both must be bold:
- ✓ "**axis**: this is an **axis** reference."
- ✗ "**axis**: this is an axis reference."

### A2c. Key Technical Terms — Bold When Emphasised

When a remark or explanation highlights a key **DAX** technical term that is central to the point being made, bold it for emphasis:

- ✓ "the function modifies the evaluation **context** by navigating to the highest level"
- ✗ "the function modifies the evaluation context by navigating to the highest level"

Apply sparingly — only bold terms that are the core concept of the remark (*e.g.*, "context" in a remark about context modification), not every technical word.

### A2d. Field Names, Column References and Cell References — Bold

Bold these three categories whenever they appear in running prose:

- **Field names** — column headings in a data table or PivotTable: **Sales Amount**, **Customer ID**, **Order Date**
- **Column references** — bracketed-name column references in DAX or Power Query: **[Sales Amount]**, **[Customer ID]**, **[Quantity]**
- **Cell references** — Excel cell addresses, ranges, and named ranges: **A1**, **$B$3:$C$10**, **Total_Sales**

This extends A2 / A2b / A2c — together they cover function names, argument names, key technical terms, and now field / column / cell references. The common thread: anything the reader needs to find in the underlying workbook should be bold.

Common miss: cell references in casual mentions ("then enter the formula in cell A1") are routinely left un-bold. Bold them: "then enter the formula in cell **A1**".

Inside code blocks and formula syntax, references stay as written — this rule applies to *running prose* only.

### A3. TRUE and FALSE — Capitalised but NOT Bold

TRUE and FALSE are Boolean values:
- ✓ Capitalised: TRUE, FALSE
- ✗ NOT bold: ~~**TRUE**~~, ~~**FALSE**~~

### A4. Latin Abbreviations — Always Italic

*i.e.* and *e.g.* must always be in italics with periods.
Also: *viz.*, *etc.*

### A4b. Latin Abbreviations — No Comma After

Do not follow *i.e.*, *e.g.*, *viz.* or *etc.* with a comma.

- ✓ "the function rejects empty strings, *i.e.* zero-length values"
- ✗ "the function rejects empty strings, *i.e.*, zero-length values"
- ✓ "use a list-validation function, *e.g.* DataValidation"
- ✗ "use a list-validation function, *e.g.*, DataValidation"
- ✓ "wrap arguments, *etc.* before saving"
- ✗ "wrap arguments, *etc.*, before saving"

Typical American / Chicago style does insert a comma after — this house rule overrides it. A comma *before* the Latin abbreviation may still appear where the sentence's syntax requires it; the rule only forbids the comma after.

### A5. Error Values — Always Italic

Error results are always in italics:
*#VALUE!*, *#N/A*, *#NUM!*, *#REF!*, *#DIV/0!*, *#NAME?*, *#NULL!*, *NaN*

### A6. Number Convention

**Integers from zero [0] to nine [9]:** Write as WORD + [DIGIT]
- zero [0], one [1], two [2], three [3], four [4], five [5], six [6], seven [7], eight [8], nine [9]

**All other numbers:** Write as PLAIN NUMBERS
- Non-integers (decimals): 3.14, -7.15, 29.77
- Negative numbers: -7.15
- Integers ≥ 10: 10, 15, 100, 1000

**Lenient application:** Only flag in clearly house-convention contexts (argument counts, requirements, step counts, prose quantities). Do NOT flag in formula values, cell references, data values, or large technical numbers.

### A7. Date Format — No Leading Zeros

Extends UK4 with an additional house rule: single-digit days must NOT have a leading zero.
- ✓ "6 Jan 26"
- ✗ "06 Jan 26"

General format: `D Month YY` or `D Month YYYY`

### A8. Currency Format

Extends UK3 — same rule, listed here for completeness. Symbol always precedes number: "$500", "£200", "€50"

### A9. Section Subheadings in Example Walkthroughs — Bold + Italic

When an article walks through examples with labelled sub-sections (*e.g.*, "Simple examples", "Decimal handling", "Numeric input"), these section subheadings must be **bold AND italic** (bold-italic), NOT bold-only.

- ✓ ***Simple examples*** (bold-italic)
- ✗ **Simple examples** (bold only — wrong)

This applies to all mid-article example walkthrough headings in DAX articles. It matches the convention already used for the function heading (*e.g.*, ***The LCM function***).

### A10. "Table" — Capitalised When Referring to Output

When referring to the result of a DAX query or code block with "the following Table", capitalise "Table":

- ✓ "This will return the following Table:"
- ✗ "This will return the following table:"

### A11. Text Return Values — Single Quotes (UK Convention)

When quoting text values returned by functions in running prose, use single quotes (UK English convention), NOT double quotes:

- ✓ **LEFT**("Holiday", 3) returns 'Hol'
- ✗ **LEFT**("Holiday", 3) returns "Hol"

Note: double quotes inside formula syntax (*e.g.*, `LEFT("Holiday", 3)`) remain as double quotes — this rule only applies to the prose description of what a function returns.

### A12. "Would" → "Will" for Definitive Outcomes

Use "will" (not "would") when describing definitive, certain outcomes or requirements:

- ✓ "you will need to wrap it in a **VALUE** function"
- ✗ "you would need to wrap it in a **VALUE** function"

Reserve "would" for truly conditional or hypothetical scenarios.

### A13. Number Convention — No Redundant [Digit] Repetition

When the word+[digit] notation (*e.g.*, zero [0]) has already appeared for a given number in the same sentence or remark, do NOT repeat the [digit] for subsequent occurrences of the same number word:

- ✓ "if either argument is zero [0], **LCM** returns zero, since the least common multiple of any number and zero is zero"
- ✗ "if either argument is zero [0], **LCM** returns zero [0], since the least common multiple of any number and zero [0] is zero [0]"

The first occurrence establishes the mapping; repeating it is redundant.

### A14. Inline Formula Expressions — Bold

When formula expressions appear inline in running prose (not in code blocks), bold the entire expression:

- ✓ "the relationship **LCM(a, b)** × **GCD(a, b)** = **a × b** always holds"
- ✗ "the relationship LCM(a, b) × GCD(a, b) = a × b always holds"

This extends Rule A2 (function names bold) to complete formula expressions including their arguments when used inline.

### A15. Feature/Mode Names — Single Quotes

When referring to a specific named feature, mode, or UI element in running text, wrap it in single quotes:

- ✓ select 'Audio Overview' and choose the style
- ✗ select Audio Overview and choose the style
- ✓ what differentiates NotebookLM is its 'Interactive Mode'
- ✗ what differentiates NotebookLM is its Interactive Mode

This applies to product features and UI elements, NOT to product/language names like **DAX**, Excel, or Power Pivot (which follow Rules A1/F1).

### A16. Remove Unnecessary Double Quotes

Do not wrap ordinary words in double quotes for emphasis when the word stands on its own without needing it:

- ✓ "a formula is required to return dynamic results"
- ✗ "a formula is required to return \"dynamic\" results"

Reserve quotes for actual quotations, text values (Rule A11 — use single quotes), or terms that genuinely need scare quotes.

### A17. Negative Number Convention

For negative numbers in the 0–9 range, reverse the normal word [digit] order — put the **digit first** with the word in brackets:

- ✓ "achieved by inputting -2 [negative two] in the sort_order argument"
- ✗ "achieved by inputting negative two [-2] in the sort_order argument"

This is the opposite of the standard convention (Rule A6) because showing the digit first is clearer for negative values.

### A18. Ordinals for Numbers 0–9 — Use Words

Ordinal numbers in the 0–9 range should use words, not digit+suffix:

- ✓ "the third highest quantity"
- ✗ "the 3rd highest quantity"

Ordinals ≥ 10 remain as digits: "the 12th row".

### A19. Sentence Case for Mid-Article Sub-headings

Mid-article sub-headings and descriptive phrases should use sentence case (only first word capitalised), NOT title case:

- ✓ "Fix the problem at the source: the prompt."
- ✗ "Fix the Problem at the Source — the Prompt."
- ✓ "Convert the PDF into an editable deck."
- ✗ "Convert the PDF into an Editable Deck."

Exception: formal section titles like "Suggested Solution", "Word to the Wise", "The Challenge" retain title case.

### A20. Double Space Between Sentences

Liam uses **two spaces** after a full stop (period) before the start of the next sentence. This is a deliberate stylistic choice:

- ✓ "This is the first sentence.  This is the second sentence."
- ✗ "This is the first sentence. This is the second sentence."

This applies throughout all article text — running prose, remark bullets, example descriptions, and closing paragraphs. It does NOT apply inside code blocks or formula syntax.

**How to audit:** Search for single-space sentence boundaries (`. [A-Z]`) and flag them. The fix is to add an extra space after the full stop.

---

## B. BULLET POINT RULES

### B1. Capitalisation in Bullet Points

If a bullet point is a **continuation of a clause** (*i.e.*, the introductory line flows into the bullets grammatically), the first letter should be **lowercase** — unless it is a proper noun.

Example (correct):
```
The function has the following arguments:
-   **number**: this is the value to test
-   **text**: this is the string to search.
```

Example (incorrect):
```
The function has the following arguments:
-   **Number**: This is the value to test    ← wrong: capital letters
-   **Text**: This is the string to search.
```

If the bullet point is a **standalone sentence** (not a run-on from the introduction), normal sentence capitalisation applies.

### B2. Full Stops in Bullet Lists

Only the **very final bullet point** in a list should end with a full stop. All preceding bullets: NO full stop.

This rule does **NOT** apply to sub-bullets — only the main list level.

Example (correct):
```
Here are a few remarks:
-   this function returns TRUE if the value is blank
-   it will return FALSE for empty strings
-   this function is not supported in DirectQuery mode.
```

Example (incorrect):
```
Here are a few remarks:
-   this function returns TRUE if the value is blank.   ← wrong
-   it will return FALSE for empty strings.              ← wrong
-   this function is not supported in DirectQuery mode.
```

### B3. Bullet Point Consistency

Ensure bullet points throughout an article are formatted consistently:
- same punctuation pattern (per B2 rules above)
- same capitalisation pattern (per B1 rules above)
- same indentation level
- parallel grammatical structure.

---

## C. GRAMMAR & STYLE RULES

### C1. Filler Word Removal

Liam consistently removes unnecessary words:
- "Well," at start of sentence → delete
- "filter out" → "filter" (redundant "out")
- "shall" → "should" (less formal)
- unnecessary emphasis/italic where they add no value.

### C2. Semicolons for Independent Clauses

Fix comma splices by upgrading to semicolons:
- ✗ "...do that, you could download..."
- ✓ "...do that; you could download..."

Also the house pattern for restrictions:
- "this was a formula challenge; no Power Query / Get & Transform or VBA"

### C3. FFF → MMM Tense Conversion

When the same challenge text appears in both FFF (Friday) and MMM (Monday):
- FFF uses PRESENT tense (challenge is active)
- MMM uses PAST tense (challenge has concluded)

| FFF (Present) | MMM (Past) |
|---|---|
| "is" | "was" |
| "are" | "were" |
| "needs" | "needed" |
| "can" | "could" |
| "we challenge" | "we challenged" |
| "is allowed" | "was allowed" |
| "we want" | "we asked" |

### C4. "Based upon" Preferred Over "Based on"

Liam consistently prefers "upon" over "on" after "based":
- ✓ "based upon the uploaded sources"
- ✗ "based on the uploaded sources"

This is not an absolute rule — "on" may be acceptable where sentence flow requires it — but "upon" is the default preference.

### C5. "Whilst" Preferred for Contrast; "While" for Temporal

Use "whilst" when expressing contrast or alternatives:
- ✓ "One prioritises speed, whilst the other focuses on polish"
- ✗ "One prioritises speed, while the other focuses on polish"

"While" remains acceptable for temporal/simultaneous meaning (*e.g.*, "listen while NotebookLM generates").

### C6. "However" Only at the Start of a Clause; "But" Mid-Sentence

"However" is a conjunctive adverb, not a coordinating conjunction. Use it **only at the start of a clause** — either the start of a sentence, or immediately after a semicolon. In the middle of a sentence between two independent clauses, use "but" instead.

**At sentence start — use "However,":**
- ✓ "However, it can remove hours of manual effort"
- ✗ "But it can remove hours of manual effort"

**After a semicolon — use "; however,":**
- ✓ "Lucy's grammar is terrible; however, with practice, her use of conjunctive adverbs should improve."
- ✗ "Lucy's grammar is terrible, however, with practice, her use of conjunctive adverbs should improve."

**Mid-sentence between two independent clauses — use "but" instead of "however":**
- ✓ "Liam tells extremely funny jokes but no one ever laughs."
- ✗ "Liam tells extremely funny jokes however no one ever laughs."
- ✗ "Liam tells extremely funny jokes, however, no one ever laughs."

**Quick test:** if "however" sits between two independent clauses without a semicolon immediately before it, replace it with "but". If a sentence opens with "But", replace it with "However,".

### C7. "Simply" Not "Just" (as Filler)

When "just" is used as a filler/minimiser, replace with "simply" or remove entirely:
- ✓ "It does not simply summarise content"
- ✗ "It does not just summarise content"

Note: "just" is acceptable when it means "only" or "exactly" (*e.g.*, "just one cell").

### C8. Hedge AI Capability Claims

When describing what AI tools "can" do, Liam hedges strong claims to avoid overpromising:
- ✓ "a tool that may assist transforming static research"
- ✗ "a tool that transforms static research"
- ✓ "this approach may significantly speed up understanding"
- ✗ "this approach can significantly speed up understanding"

Pattern: "can" → "may"; definitive claims → hedged claims. This applies specifically to AI blog content.

### C9. Tone Down Superlatives

Replace hyperbolic adjectives with measured alternatives:
- ✓ "One impressive outcome"
- ✗ "One amazing outcome"
- Other examples: "incredible" → "noteworthy", "game-changing" → "significant"

### C10. "Judgment" Not "Judgement"

Liam uses the spelling **judgment** (no middle 'e'), which is the standard legal/formal British spelling:
- ✓ "AI will not replace judgment"
- ✗ "AI will not replace judgement"

### C11. Comma After Introductory Adverbs/Phrases

Insert a comma after introductory words and short phrases at the start of a sentence:
- ✓ "Now, we can try its Video feature"
- ✗ "Now we can try its Video feature"

### C12. "And / or" With Spaces Around Slash

When using "and/or", apply spaces around the slash (same as the product slash convention):
- ✓ "and / or"
- ✗ "and/or"

---

## D. TECHNICAL RULES

### D1. Function Arguments — No Angle Brackets

Function arguments in syntax blocks should NOT use < and > angle brackets:
- ✓ `FUNCTIONNAME(value, table_name)`
- ✗ `FUNCTIONNAME(<value>, <table_name>)`

### D2. Do NOT Explain Complex Functions in Your Own Words

When auditing, do NOT attempt to rewrite or rephrase technical explanations of complex functions. Some function behaviours are nuanced and incorrect paraphrasing can introduce factual errors.

If the original explanation appears unclear or potentially incorrect:
- flag it as needing Liam's review
- suggest a "preamble explanation" may be needed (see D3)
- do NOT substitute your own interpretation of what the function does.

### D3. Preamble Explanations

When explaining what a function does, if the explanation is not immediately clear, a "preamble explanation" should precede the syntax. This means explaining the concept or terminology the function deals with (*e.g.*, what "Start At" signifies) before diving into the technical syntax.

Flag articles that jump straight into syntax without adequate conceptual setup.

### D4. DAX Series — Power Pivot vs Power BI Compatibility

For the DAX article series specifically:
- the series explains **Power Pivot**, not Power BI
- "DAX query view" is a **Power BI feature** — it should not be the default demonstration method
- if a function is compatible with Power Pivot, always show a **Power Pivot example**
- if also showing DAX query view, explain that the function is compatible with both
- **take care**: some **DAX** functions may NOT work in Power Pivot — verify compatibility before including.

### D5. DAX Cross-Referencing with Excel

When there are similar Excel functions, check if there is anything usable for the **DAX** version. Cross-reference where appropriate.

### D6. Technical Accuracy — General

- every function name must be spelled correctly (including cross-references)
- every formula must be syntactically valid (balanced parentheses, correct arguments)
- every **DAX** measure must include an aggregation function
- function descriptions must match what the function actually does
- supersedes relationships must be correct (a function CANNOT supersede itself).

### D7. Plurals

Watch out for incorrect plurals, especially:
- function names (*e.g.*, **KEEPFILTERS** not **KEEPFILTER**)
- technical terms where singular/plural changes meaning.

### D8. Function Syntax Spacing

In syntax blocks, there must be **no space** between the function name and the opening parenthesis, and a **space after each comma**:

- ✓ `COLLAPSEALL([expression], axis)`
- ✗ `COLLAPSEALL ([expression],axis)` — space before `(` is wrong; no space after `,` is wrong

- ✓ `COLLAPSEALL(axis)`
- ✗ `COLLAPSEALL (axis)` — space before `(` is wrong

### D9. Product Name Spacing

Microsoft product names must use correct spacing. This is a common error in draft articles:

- ✓ "Power BI" (two words with space)
- ✗ "PowerBI" — ALWAYS flag
- ✓ "Power Pivot" (two words with space)
- ✗ "PowerPivot" — ALWAYS flag
- ✓ "Power Query" (two words with space)
- ✗ "PowerQuery" — ALWAYS flag
- ✓ "PivotTable" (one word, camel case — this IS correct)
- ✓ "PivotChart" (one word, camel case — this IS correct)

### D10. Visual Calculation Functions — Power BI-Only

Some **DAX** functions are **visual calculations** that work ONLY in Power BI and do NOT work in Power Pivot at all. These include:

- **COLLAPSEALL**, **COLLAPSE**, **EXPANDALL**, **EXPAND**
- **FIRST**, **LAST**, **PREVIOUS**, **NEXT** (visual calculation versions)
- **ISATLEVEL**, **ISONORBELOW**
- **MOVINGAVERAGE**, **RUNNINGSUM**, **RANK** (visual calculation versions)

When auditing a DAX article that covers one of these functions:
- Flag as **Critical** that the function is Power BI-only
- The article MUST explicitly state this limitation prominently
- No Power Pivot example can be shown (because it won't work)
- This is a stronger constraint than Rule D4's general compatibility check

### D11. Web Verification — Current Facts

Before completing an audit, use **web search** to verify that technical claims in the article are current. This is essential because:

- **DAX functions change**: Microsoft adds new parameters, deprecates functions, or changes syntax. The auditor's training data may be stale.
- **AI tools evolve rapidly**: Tools get rebranded, features are added/removed, pricing changes. An AI blog article can become outdated within weeks.
- **Excel features expand**: New functions (GROUPBY, PIVOTBY, LAMBDA) have evolving availability across versions.

**What to verify:**
1. **DAX articles**: Function syntax, argument names, Power Pivot compatibility, supersedes relationships — cross-check against `learn.microsoft.com/en-us/dax/` and `dax.guide`.
2. **AI Blog articles**: Tool names, feature availability, capability claims — search for `[tool name] latest news [year]`.
3. **Excel articles**: Function syntax and version availability — cross-check against `learn.microsoft.com`.
4. **All articles**: Product/feature names still exist and are correctly named.

**Reporting:** Add a "Freshness Check" section to the audit report showing what was verified and any discrepancies found. Include source URLs.

---

## E. IMAGE RULES

### E1. Image Centering

All images in articles must be centred.

### E2. Table Column Widths

For table/spreadsheet images:
- widen each column so that headings can be read fully
- if it's not possible to show all columns, that's fine
- but NEVER show truncated headers — this is not acceptable.

### E3. Image Copyright

Confirm that images used in blogs have no copyright issues. Flag any images that may have copyright concerns.

---

## F. PRODUCTS & TERMINOLOGY

### F1. Products Listed with Slashes

```
Excel / Power Pivot / Power Query / Power BI
```
Space-slash-space between products, never commas.

### F1b. Compound Terms — No Spaces Around Slash

When a slash joins parts of a **single compound term** (not separate products), do NOT use spaces:

- ✓ "Top/Bottom N" (compound term)
- ✗ "Top / Bottom N"

Compare with "and / or" (Rule C12) which DOES use spaces because it's a compound conjunction, not a compound noun.

### F2. "DAX query view" — Feature Name Treatment

Write as: "DAX query view" — lowercase "query view", no bold on any part.
This is a feature/noun, not a language reference (see Rule A1).

Note: For the DAX article series, this feature should be used cautiously — see Rule D4.

---

## G. MMM-SPECIFIC RULES

### G1. Suggested Solution Heading — En-Dash Separator

When a "Suggested Solution" heading has a sub-type, use an en-dash (–) not a colon:

- ✓ "Suggested Solution – Modern Excel (Microsoft 365, Excel Online, etc.)"
- ✗ "Suggested Solution: Modern Excel (Microsoft 365, Excel Online, etc.)"

The sub-type label after the dash uses sentence case:
- ✓ "Suggested Solution – Legacy version"
- ✗ "Suggested Solution – Legacy Version"

### G2. Imperative Voice in Solution Walkthroughs

In MMM solution steps, use imperative voice (direct instructions) rather than "we" voice:

- ✓ "provide a variable name in the first argument"
- ✗ "we provide a variable name in the first argument"
- ✓ "After that, type a comma"
- ✗ "After that, we type a comma"

This makes the solution read as clear instructions to the reader.

### G3. "It should be noted that:" for Explanatory Lists

When introducing a list of explanatory points about a formula or function, use "It should be noted that:" instead of bare "Here,":

- ✓ "It should be noted that:"
- ✗ "Here,"

### G4. Standalone Sentence Bullets for Explanatory Content

When bullet points in an MMM solution explain distinct concepts (not clause continuations), format them as standalone sentences — capitalised first letter, full stop at the end of each:

- ✓ "GROUPBY collects the fruit name and corresponding quantities, and sums them to give a total quantity value for each fruit."
- ✗ "GROUPBY collects the fruit name and corresponding quantities and sums them to give a total quantity value for each fruit"

This overrides Rules B1/B2 when the context is explanatory paragraphs (not clause-continuation lists).

### G5. Caveat Statements

Liam adds honest caveats about limitations of solutions:

- ✓ "It's not perfect, and in some versions of Excel, the PivotTable(s) will need to be manually refreshed if the data changes, but it is a simple alternative."

When a solution has known limitations, acknowledge them rather than presenting the solution as flawless.

---

## H. AI BLOG-SPECIFIC RULES

### H1. Hedge AI Capabilities

See Rule C8. In AI blog articles specifically, hedge strong claims about what AI tools can do:
- "can" → "may"
- "transforms" → "may assist transforming"
- "will significantly" → "may significantly"

### H2. Transitional Phrases

Add transitional phrases to improve flow:
- Before explanations: "Let me explain."
- Before teasers: "Keep reading!"

### H3. Precision in Descriptions

Add qualifying words for precision:
- "visual standards" → "required visual standards"
- "more setup" → "more setup time"
- "spelling and wording errors" → "spelling, grammatical and wording errors"
