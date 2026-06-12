# Error Patterns — Found Across 80+ SumProduct Articles + Live Audit Sessions

All errors below are REAL examples from analysed articles and live audit sessions (LEN, LEFT, COLLAPSEALL, LINEST, LINESTX). Use these to calibrate what to look for.

## Table of Contents
1. [Grammar Errors](#grammar)
2. [Formatting Errors](#formatting)
3. [Technical Errors](#technical)
4. [Punctuation Errors](#punctuation)
5. [Spelling Errors](#spelling)
6. [Structural Errors](#structural)
7. [Quick Audit Checklist](#checklist)

---

<a name="grammar"></a>
## 1. GRAMMAR ERRORS

### 1.1 Missing Words (Most Common — 20+ instances across all series)

| Error | Correct | Source |
|-------|---------|--------|
| "is one of information function" | "is one of **the** information function**s**" | DAX 222, 223 |
| "checks whether a value Boolean" | "whether a value **is** Boolean" | DAX 223 |
| "with few simple examples" | "with **a** few simple examples" | DAX 223 |
| "this function able to check" | "this function **is** able to check" | DAX 233 |
| "benefits **the** accrue based upon" | "benefits **that** accrue" | Excel 321, 322 |
| "if probability ≤ 0 or if ≥ 1" | "or if **probability** ≥ 1" | Excel 327, 331 |
| "been involved calculating" | "involved **in** calculating" | Excel 334 |
| "for many get together" | "for many **to** get together" | MMM Dec 2022 |

**What to look for:** Every sentence needs complete articles (a, an, the), verbs (is, returns, has), prepositions (in, of, to), and relative pronouns (that, which).

### 1.2 Subject-Verb Disagreement (Very Common — 15+ instances)

| Error | Correct | Source |
|-------|---------|--------|
| "TM **stand** for" | "TM **stands** for" | ALL 12 INFO articles |
| "KEEPFILTERS is **use** within" | "is **used** within" | DAX 246 |
| "that **perform** navigation only" | "that **performs**" | DAX 46a |
| "it still **allow** you" | "it still **allows** you" | DAX 223 |
| "PivotTable that **grab**" | "that **grabs**" | DAX 247 |
| "Is In Scope 1 field **return** TRUE" | "**returns** TRUE" | DAX 232 |

**Rule:** Singular subjects (it, that, which, function, this) take singular verbs (returns, performs, allows, stands).

### 1.3 Wrong Verb Form

| Error | Correct | Rule |
|-------|---------|------|
| "let's **added** a slicer" | "let's **add**" | "Let's" + base form |
| "**Let** create our visual" | "**Let's** create" | Missing apostrophe-s |
| "let **have** a look" | "let**'s** have a look" | Missing apostrophe-s |
| "are being **push** down" | "being **pushed** down" | Passive = past participle |
| "culture is **setting** accordingly" | "is **set** accordingly" | Passive = past participle |
| "which **use** to calculate" | "which **is used** to" | Missing passive auxiliary |
| "this **functions** returns" | "this **function** returns" | Singular/plural mismatch |

### 1.3b Typos That Change Meaning

| Error | Correct | Source |
|-------|---------|--------|
| "this **if** the F statistic" | "this **is** the F statistic" | DAX LINEST audit |
| "return us **wil** the" | "return us **with** the" | DAX 232 |
| "**PowerBI**" | "**Power BI**" | Multiple audits — product name spacing |

### 1.4 Word Order Errors

| Error | Correct | Source |
|-------|---------|--------|
| "let's **the use** following code" | "let's **use the** following code" | DAX 243, 245 |
| "return us **wil** the following" | "return us **with** the following" | DAX 232 |
| "we now **will** have" | "we **will now** have" | DAX 135 |
| "achieve the **same the** result" | "achieve the **same** result" | DAX 222 |

### 1.5 Incomplete Sentences

| Error | Issue | Source |
|-------|-------|--------|
| "...grab the first Date of every." | Missing object after "every" | DAX 247 |
| "...with ISBLANK function to determine" | Determine what? | DAX 222 |

**Rule:** Every sentence must have complete subject-verb-object. Watch for trailing determiners.

### 1.6 Parallel Structure

| Error | Correct | Source |
|-------|---------|--------|
| "maintain direction or **bringing** it nearer" | "or **bring** it nearer" | Excel 316 |

**Rule:** Items in a list or joined by "or"/"and" must use the same grammatical form.

---

<a name="formatting"></a>
## 2. FORMATTING ERRORS

### 2.1 Bold/Italic Violations

| Error | Correct | Rule |
|-------|---------|------|
| **TRUE** / **FALSE** (bold) | TRUE / FALSE (caps only) | Liam Rule A3 |
| FUNCTIONNAME (no bold) | **FUNCTIONNAME** | Liam Rule A2 |
| #VALUE! (no italic) | *#VALUE!* | Liam Rule A5 |
| i.e. (no italic) | *i.e.* | Liam Rule A4 |
| **DAX query view** (bold) | DAX query view | Liam Rule A1 |
| DAX (no bold) | **DAX** | Liam Rule A1 |
| **INFO***.***ANNOTATIONS** (broken) | **INFO.ANNOTATIONS** | Single bold block |
| **FIND f**unction (split bold) | **FIND** function | Bold ends at function name |
| **Simple examples** (bold only) | ***Simple examples*** (bold-italic) | Liam Rule A9 |
| "the following table" (lowercase) | "the following Table" (capital T) | Liam Rule A10 |
| returns "Sum" (double quotes) | returns 'Sum' (single quotes) | Liam Rule A11 |
| "you would need to" | "you will need to" | Liam Rule A12 |
| num_chars (no bold in text) | **num_chars** (bold) | Liam Rule A2b |
| TRIM (no bold in remarks) | **TRIM** (bold) | Liam Rule A2 |
| LCM(a, b) (no bold inline) | **LCM(a, b)** (bold) | Liam Rule A14 |
| **axis**: this is an axis ref | **axis**: this is an **axis** ref | Liam Rule A2b |
| `FN ([arg],arg)` (space before paren) | `FN([arg], arg)` (no space, comma+space) | Liam Rule D8 |

### 2.2 Bullet Point Violations

| Error | Correct | Rule |
|-------|---------|------|
| Full stop on non-final bullet | Only final bullet gets full stop | Liam B2 |
| "**Number**: This is..." (capitals) | "**number**: this is..." (lowercase) | Liam B1 |
| Mixed capitalisation in bullet list | All bullets same pattern | Liam B3 |

### 2.3 Angle Brackets in Syntax

| Error | Correct | Rule |
|-------|---------|------|
| `FUNCTION(<value>, <table>)` | `FUNCTION(value, table)` | Liam D1 |

### 2.3b Product Name Spacing

| Error | Correct | Rule |
|-------|---------|------|
| PowerBI | Power BI | Liam D9 |
| PowerPivot | Power Pivot | Liam D9 |
| PowerQuery | Power Query | Liam D9 |

Note: PivotTable and PivotChart are correctly one word (camel case).

### 2.4 Number Convention Violations

| Error | Correct | Rule |
|-------|---------|------|
| "two names" (in args context) | "two [2] names" | Integer 0–9 needs [digit] |
| "one column" (in requirements) | "one [1] column" | Integer 0–9 needs [digit] |
| "three [3].14" | "3.14" | Non-integers are plain numbers |
| "zero [0]...returns zero [0]" | "zero [0]...returns zero" | No redundant [digit] in same sentence (Liam A13) |

### 2.5 Date Format Violations

| Error | Correct | Rule |
|-------|---------|------|
| "06 Jan 26" | "6 Jan 26" | No leading zeros |
| "January 6th, 2026" | "6 January 2026" | No ordinals, no US format |

### 2.5b Single Space Between Sentences

| Error | Correct | Rule |
|-------|---------|------|
| "returns TRUE. This function" (single space) | "returns TRUE.  This function" (double space) | Liam A20 |
| "in the report. It should" (single space) | "in the report.  It should" (double space) | Liam A20 |

**What to look for:** Every full stop followed by a new sentence should have **two** spaces, not one. Search for `. [A-Z]` patterns. Does NOT apply inside code blocks or formula syntax.

### 2.6 Closing Italic Missing

| Error | Source |
|-------|--------|
| Missing opening `*` for italic in closing paragraph | Excel 320, 321, 322 |

---

<a name="technical"></a>
## 3. TECHNICAL ERRORS

### 3.1 Wrong Function Syntax

| Error | Correct | Source |
|-------|---------|--------|
| `NOW(number1, [number2], ...)` | `NOW()` — takes NO arguments | Excel 333 |

**Always verify:** Does the syntax line match the function's actual signature?

### 3.2 Self-Referencing Supersedes

| Error | Correct | Source |
|-------|---------|--------|
| "This function supersedes **NORM.S.INV**" | "supersedes **NORMSINV**" | Excel 327 |

**A function cannot supersede itself.** Always check the legacy function name.

### 3.3 Missing Aggregation in DAX Measures

| Error | Correct | Source |
|-------|---------|--------|
| `Sales = (Sales[Amount])` | `Sales = SUM(Sales[Amount])` | DAX 246 |

**Every DAX measure must include an aggregation function.**

### 3.4 Misspelled Function Names

| Error | Correct | Source |
|-------|---------|--------|
| FRISTDATE | FIRSTDATE | DAX 247 |
| KEEPFILTER | KEEPFILTERS | DAX 246 |
| $SYSTEM. TMSCHEMA_MODEL (extra space) | $SYSTEM.TMSCHEMA_MODEL | DAX 182 |

### 3.5 Visual Calculation Functions — Power BI-Only

Functions like **COLLAPSEALL**, **EXPANDALL**, **COLLAPSE**, **EXPAND** are visual calculation functions that ONLY work in Power BI. They do NOT work in Power Pivot at all. If a DAX article covers one of these:

- Flag as **Critical** that the function is Power BI-only
- Article MUST explicitly state this limitation
- No Power Pivot example possible
- See Liam Rule D10

### 3.6 Title Missing Function Name

| Error | Correct | Source |
|-------|---------|--------|
| "Power Pivot Principles: The A to Z of DAX Functions" (no function) | "...DAX Functions -- **LEN**" | DAX LEN audit |

### 3.7 Missing DirectQuery Remark

DAX articles should include a standard remark about DirectQuery compatibility as the last bullet in remarks. If absent, flag as **Minor**.

### 3.8 Opening Paragraph Missing Bold on (DAX)

The opening paragraph should bold "DAX" within parentheses: `(**DAX**)`. Some articles use plain `(DAX)` — flag as formatting inconsistency.

---

<a name="punctuation"></a>
## 4. PUNCTUATION ERRORS

### 4.1 Oxford Comma Violations

**Default: NO Oxford comma (UK English)**

| Error | Correct |
|-------|---------|
| "cheese, tomato, and lettuce" | "cheese, tomato and lettuce" |

**Exception 1** (unrelated clause): "I hate X, Y and Z, and I love W" — comma IS correct
**Exception 2** (item contains "and"): "kebabs, fish and chips, and vodka" — comma IS correct

### 4.2 Comma Splices

| Error | Correct |
|-------|---------|
| "...do that, you could download..." | "...do that; you could download..." |

Two independent clauses joined by comma → upgrade to semicolon.

---

<a name="spelling"></a>
## 5. SPELLING ERRORS

### 5.1 US vs British English

| US (Wrong) | British (Correct) |
|-----------|-------------------|
| categorizing | categorising |
| organizing | organising |
| color | colour |
| behavior | behaviour |
| modeling | modelling |
| center | centre |
| analyze | analyse |
| optimize | optimise |

### 5.2 Homophones

| Error | Correct | Source |
|-------|---------|--------|
| "may also **except** a custom list" | "**accept**" | Excel 321 |

---

<a name="structural"></a>
## 6. STRUCTURAL ERRORS

### 6.1 FFF → MMM Tense Not Converted

Every present-tense verb in the FFF challenge text must be converted to past tense in the MMM. See Liam Rule C3 for complete conversion table.

### 6.2 Missing Structural Sections

| Section | Expected In |
|---------|-------------|
| "Suggested Solution" | Every MMM |
| "Word to the Wise" | Most MMMs |
| Closing paragraph | Every MMM |
| 3 closing links | Every DAX article |

---

<a name="web-verified"></a>
## 6b. WEB-VERIFIED ERRORS (Found via Search)

These are errors that can ONLY be caught by checking current online sources. Static rules and training data cannot detect these.

### 6b.1 Outdated DAX Syntax

| Error Type | Example | How to Detect |
|-----------|---------|--------------|
| Wrong argument count | Article says 2 args, Microsoft docs say 3 | Search `DAX [FN] site:learn.microsoft.com` |
| Wrong argument name | Article says "value", docs say "expression" | Search `DAX [FN] site:learn.microsoft.com` |
| Deprecated function | Article uses function that's been superseded | Search `DAX [FN] deprecated` |
| New parameters added | Article missing optional param added in recent update | Search `DAX [FN] site:dax.guide` version history |
| Wrong compatibility claim | Article says "works in Power Pivot" but function is Power BI-only | Search `[FN] Power Pivot compatibility` |

### 6b.2 Outdated AI Tool Information

| Error Type | Example | How to Detect |
|-----------|---------|--------------|
| Tool rebranded | Article says "Bard", now it's "Gemini" | Search `[tool name] latest news [year]` |
| Feature removed | Article describes feature that no longer exists | Search `[tool name] features [year]` |
| Pricing changed | Article quotes old pricing | Search `[tool name] pricing [year]` |
| Tool discontinued | Article recommends tool that's been shut down | Search `[tool name] shutdown discontinued` |
| Capability overstated | Article claims tool can do X, but it can't anymore | Search `[tool name] capabilities limitations` |

### 6b.3 Outdated Excel Information

| Error Type | Example | How to Detect |
|-----------|---------|--------------|
| New function availability | GROUPBY now available in more versions | Search `Excel [FN] availability` |
| Changed behaviour | Function behaviour changed in recent update | Search `Excel [FN] site:learn.microsoft.com` |
| Supersedes relationship wrong | Article says FN supersedes OLDFN but that's incorrect | Search `Excel [FN] supersedes replaces` |

---

<a name="checklist"></a>
## 7. QUICK AUDIT CHECKLIST

### Pass 0: Web Verification — Freshness Check (Before All Other Passes)
- [ ] **DAX articles**: Searched `DAX [FUNCTIONNAME] site:learn.microsoft.com` — syntax matches article [Liam D11]
- [ ] **DAX articles**: Searched `[FUNCTIONNAME] Power Pivot compatibility` — compatibility claim verified [Liam D4/D11]
- [ ] **DAX articles**: Searched `DAX [FUNCTIONNAME] site:dax.guide` — cross-referenced availability and examples [Liam D11]
- [ ] **DAX articles**: If supersedes claim, verified the legacy function name is correct [Liam D6/D11]
- [ ] **AI Blog articles**: Searched `[AI tool name] latest news` — tool still exists, not rebranded [Liam D11]
- [ ] **AI Blog articles**: Searched `[AI tool name] features` — features described are still available [Liam D11]
- [ ] **Excel articles**: If syntax looks questionable, verified against Microsoft docs [Liam D11]
- [ ] **All articles**: Product/feature names confirmed current [Liam D9/D11]
- [ ] Freshness Check section added to top of audit report with ✅/⚠️/❌ for each item

### Pass 1: Technical Accuracy (Priority 1)
- [ ] All function names spelled correctly (including cross-references) [Liam D6]
- [ ] All formulas syntactically valid (balanced parentheses, correct arguments) [Liam D6]
- [ ] No angle brackets in function syntax [Liam D1]
- [ ] All **DAX** measures include aggregation functions [Liam D6]
- [ ] Supersedes relationships correct (function cannot supersede itself) [Liam D6]
- [ ] Syntax blocks match actual function signatures [Liam D6]
- [ ] Plurals correct (*e.g.*, **KEEPFILTERS** not **KEEPFILTER**) [Liam D7]
- [ ] DAX series: function verified to work in Power Pivot [Liam D4]
- [ ] Visual calculation functions: flagged as Power BI-only if applicable [Liam D10]
- [ ] Complex function explanations NOT rewritten — flagged for Liam if unclear [Liam D2]
- [ ] Product names correctly spaced: "Power BI", "Power Pivot", "Power Query" [Liam D9]
- [ ] Title includes function name (DAX series: `-- FUNCTIONNAME` suffix) [Template]
- [ ] Opening paragraph bolds (**DAX**) within parentheses [Template]
- [ ] DirectQuery remark present in DAX articles [Template]

### Pass 2: Liam's SumProduct Rules — Tier 2 (Priority 2)
- [ ] **DAX** and **M** bold as languages, but NOT bold in feature names ("DAX query view") [Liam A1]
- [ ] *i.e.* and *e.g.* italic [Liam A4]
- [ ] Error values italic (*#VALUE!*, *#N/A*, etc.) [Liam A5]
- [ ] Function names bold EVERYWHERE — including remark bullets and example prose [Liam A2]
- [ ] Argument names bold in running text AND in their own descriptions [Liam A2b]
- [ ] Key technical terms bold when emphasised in remarks [Liam A2c]
- [ ] TRUE/FALSE capitalised but NOT bold [Liam A3]
- [ ] "DAX query view" — not bold, not capitalised [Liam F2]
- [ ] Number convention correct (integers 0–9 as word [digit], others as numbers) [Liam A6]
- [ ] Number convention: no redundant [digit] repetition in same sentence [Liam A13]
- [ ] Date format: D Month YY (no leading zeros) [Liam A7]
- [ ] Currency symbol before number ("$500" not "500$") [Liam A8]
- [ ] Example subheadings: bold-italic (***Simple examples***) not just bold [Liam A9]
- [ ] "the following Table:" — capital T [Liam A10]
- [ ] Text return values: single quotes ('Sum') not double quotes ("Sum") [Liam A11]
- [ ] "will" not "would" for definitive outcomes [Liam A12]
- [ ] Inline formula expressions bold (**LCM(a, b)** not LCM(a, b)) [Liam A14]
- [ ] Bullet points: lowercase if continuation of clause [Liam B1]
- [ ] Bullet points: only final bullet ends with full stop [Liam B2]
- [ ] Bullet points formatted consistently [Liam B3]
- [ ] No angle brackets < > in function argument syntax [Liam D1]
- [ ] Syntax spacing: no space before `(`, space after commas [Liam D8]
- [ ] Double space between sentences in all running text [Liam A20]
- [ ] Images centred, column headers not truncated [Liam E1, E2]
- [ ] Preamble explanations where concepts need introduction [Liam D3]
- [ ] No rewriting of complex function explanations (flag for Liam instead) [Liam D2]
- [ ] DAX series: Power Pivot examples shown, not just DAX query view [Liam D4]

### Pass 3: UK English — Tier 1 (Priority 3)
- [ ] British spelling throughout (-ise, -our, -lling, -tre) [UK1]
- [ ] No Oxford commas (except two exceptions) [UK2]
- [ ] Currency symbol before number [UK3]
- [ ] UK date format [UK4]
- [ ] "judgment" not "judgement" [Liam C10]

### Pass 4: Grammar & Sentence Quality (Priority 4)
- [ ] No missing articles (a, an, the)
- [ ] No missing verbs (is, returns, has)
- [ ] Subject-verb agreement
- [ ] "Let's" + base form only
- [ ] Passive voice uses past participle
- [ ] No word order errors
- [ ] No incomplete sentences
- [ ] Parallel structure in lists
- [ ] No homophones (accept/except, affect/effect)
- [ ] "Based upon" not "based on" [Liam C4]
- [ ] "Whilst" for contrast, "while" for temporal [Liam C5]
- [ ] "However," not "But" at sentence start [Liam C6]
- [ ] Comma after introductory adverbs [Liam C11]

### Pass 5: Tone & Structure (Priority 5)
- [ ] Semicolons before "no" in restrictions
- [ ] No comma splices
- [ ] Filler words removed ("Well,", "filter out" → "filter", "just" → "simply") [Liam C1, C7]
- [ ] "should" not "shall"
- [ ] Series-specific template followed
- [ ] Closing paragraph matches template
- [ ] Feature/mode names in single quotes ('Audio Overview') [Liam A15]
- [ ] Remove unnecessary double quotes around ordinary words [Liam A16]
- [ ] Negative numbers: digit first (-2 [negative two]) [Liam A17]
- [ ] Ordinals ≤ 9 as words (third not 3rd) [Liam A18]
- [ ] Mid-article sub-headings in sentence case [Liam A19]
- [ ] AI blog: hedge capability claims ("may" not "can") [Liam C8/H1]
- [ ] AI blog: tone down superlatives ("impressive" not "amazing") [Liam C9]
- [ ] MMM: imperative voice in solution steps [Liam G2]
- [ ] MMM: "It should be noted that:" for explanatory lists [Liam G3]
- [ ] MMM: Suggested Solution sub-types with en-dash [Liam G1]
- [ ] MMM: standalone sentence bullets for explanations [Liam G4]
- [ ] "And / or" with spaces [Liam C12]
- [ ] Compound term slashes without spaces (Top/Bottom) [Liam F1b]

### Pass 6: What NOT to Flag
- [ ] Liam's humour (puns, asides, self-deprecation)
- [ ] First-person voice in Excel series
- [ ] Shared content across related articles
- [ ] Intentional variations ("every business day" vs "every other business day")
