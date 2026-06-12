# Structural Patterns in Liam Bastick's Books

Derived from chapter-by-chapter analysis of *An Introduction to Financial Modelling* and *Continuing Financial Modelling*.

---

## 1. Book-Level Structure

### Book Opening Sequence
Both books follow this exact sequence:
1. **Title page** — includes subtitle with a pun/parenthetical
2. **Copyright page** — standard legal
3. **About the Author** — credentials + humorous final line ("Unfortunately, he follows Derby County and the England cricket team" / "He still follows Derby County and the England cricket team")
4. **Preface** — personal, warm, includes the "farmer/expert" joke, thanks to contributors, Layla's foreword
5. **Editor's Notes** — Tim Heng's perspective, usually gently mocking Liam's jokes
6. **Contents** — detailed with sub-section numbering
7. **Chapter 0** — never "Chapter 1".  Liam deliberately starts at zero as a nod to programming and to signal that the introduction is "before we begin"

### Chapter Numbering Convention
- Main chapters: **Chapter 0, 1, 2, 3...**
- Sub-chapters: **Chapter X.Y** (e.g., Chapter 1.1, Chapter 2.3)
- Headings use ALL CAPS for the sub-chapter label: "CHAPTER 1.1: SUM"

### Book Closing
The Introduction book ends with Self Review and Ratio Analysis (practical application).  The Continuing book ends with "Look to the Future" (forward-looking).  Both end with an Index.

---

## 2. Chapter-Level Structure

### Chapter Opening Patterns

Liam uses several repeating patterns to open chapters.  Each opening is 2–4 paragraphs of personality before any technical content begins.

**Pattern A: The Callback Opening**
References the previous chapter or the reader's journey so far:
- "Congratulations, you made it!  Whether you are a novice or last year's Financial Modelling World Champion *(someone needs to explain that title to me)*, hopefully you learned something..."
- "So far so good – so what?"
- "They say I always have to undertake things an even number of times: the first time to do it and the second time to apologise."

**Pattern B: The "At Last" Opening**
Creates intimacy by acknowledging the reader's arrival:
- "At last we meet."
- "just like that embarrassing condition you can only tell your doctor about, I'm back."

**Pattern C: The Pun/Joke Opening**
Leads with wordplay directly related to the chapter topic:
- Chapter on dates: "There comes a time in most people's lives that they realise it's time to confront the world head-on, go out there and ask for a date."
- Chapter on absolute referencing: "As my editor said to me recently, 'are you absolutely sure you need this section?'"
- Chapter on control accounts: "I am going to let you in to one of the finance world's best kept secrets.  I will explain what they are but I may have to kill you afterwards."

**Pattern D: The "Real Talk" Opening**
Drops the humour briefly to explain why this topic matters:
- "In our day to day work, my colleagues and I see time and time again poor decisions made by management based on mistakes held in financial models."
- "Are you all sleeping comfortably?  Then I shall begin.  At the risk of sending us all off to see the Sandman, I need to talk through the financial statements."

### Chapter Roadmap
After the opening personality paragraphs, Liam almost always provides a bulleted roadmap of what the chapter will cover:
- "The plan is therefore as follows:" followed by bulleted items with bold topic names and explanatory text
- "In this section, I plan to explain the merits (or otherwise) of each of the following:" followed by a simple bullet list

### Chapter Body Flow
The body of a chapter follows this rhythm:

```
[Section heading]
→ Personality paragraph (joke, context, why this matters)
→ Concept explanation in plain English
→ Screenshot/figure reference
→ Step-by-step walkthrough
→ Practical tip or "trap" warning
→ Transition paragraph (joke + preview of next section)
[Next section heading]
```

### Chapter Closing Patterns

**Pattern A: The Forward Bridge**
- "Jokes aside, maybe we should move on." (transitions to next chapter)
- "If there are no more questions, let's get going…"

**Pattern B: The Reinforcement Close**
Circles back to the key takeaway:
- "In summary, it's all about design and scoping."
- "Modelling financial statements really is that simple."

**Pattern C: The Challenge/Encouragement**
- "Don't worry about any specific formulae; ensure you get the concepts."
- "Try it – it's fun, not!"

---

## 3. Sub-Section Structure

### Sub-Section Headings
- Use bold or ALL CAPS: "CHAPTER 1.1: SUM"
- Sometimes use sentence-case descriptive headings within sections: "Mixing Up Your IFS", "1-D Data Tables"

### The Standard Explanation Block
When Liam introduces a new function, feature, or concept, he follows this template:

1. **Hook question or observation** (1–2 sentences)
   - "Is there really anyone out there that hasn't encountered the SUM function?"
   - "I must confess I remain unconvinced about this one."

2. **Plain English definition** (1–3 sentences)
   - "SUM adds things up.  It may include cells, numbers or ranges."
   - State what it does before showing syntax.

3. **Practical context** (1–2 sentences)
   - "In the context of financial modelling, summations are usually of numbers either directly above or to the left of the cell in question."

4. **Visual reference** (screenshot/figure)
   - Liam references screenshots frequently.  In written output where images aren't available, describe what the reader would see or use a text-based representation.

5. **Keyboard shortcut or tip** (if applicable)
   - "There is a great keyboard shortcut available on most PC's (PC = *proper computer*)."
   - Always include the shortcut keys in bold: **ALT + =**

6. **Syntax block** (for functions/formulas)
   - Function name in bold
   - Arguments on separate lines with bullet explanations
   - Include data types and edge cases

7. **Worked example**
   - Walk through with specific cell references
   - Show the formula, explain each part
   - Show the result

8. **The Trap / Common Mistake** (1–2 paragraphs)
   - "It's a common mistake made in analytical models and is an error that is easily avoided."
   - "This type of conditional formula is known as creating an error trap."

9. **Practical takeaway** (1–2 sentences, often bold or set apart)
   - "A lazy modeller is to be encouraged; lazy modelling isn't."
   - "Concepts are key."

---

## 4. Bullet Point Convention

Liam uses a consistent bullet style across both books:

### List Introduction
Lists are introduced with a colon and often a framing phrase:
- "The plan is therefore as follows:"
- "I would rather we consider the term as a proper noun to reflect the idea that a good model has four key attributes:"
- "There are various reasons an #SPILL! error could occur:"

### Bullet Formatting
- **Semicolons** separate bullet items (not full stops)
- **Only the final bullet** gets a full stop
- **"and"** appears before the final bullet item (Oxford comma style)
- Bullets that continue a sentence from the introduction start lowercase
- Standalone/heading bullets start with a capital and bold topic name

**Example (continuation-style):**
```
...that a good model has four key attributes:
•  Consistency;
•  Robustness;
•  Flexibility; and
•  Transparency.
```

**Example (explanatory bullets):**
```
•  Start date: This will allow for models where the first period is not a "full" period...;
•  End date: This will define the end of the period...;
•  Counter: Start and end dates are insufficient...
```

### Numbered Lists
Used rarely, primarily for:
- Sequential steps ("The first thing to do is...")
- Categories with distinct types (error checks, sensitivity checks, alert checks)
- Control account properties (three key things control accounts tell you)

---

## 5. Example and Figure References

### Screenshot References
Liam frequently references screenshots that would appear in the printed book.  In text-only output, handle this by:
- Describing what the reader would see
- Using formatted text tables where appropriate
- Noting "[See accompanying Excel file]" or similar

### "Consider the following" Pattern
Liam often introduces examples with:
- "Consider the following situation:"
- "Consider the following example:"
- "To show how it works, consider the following example."
- "This is best illustrated using another example:"

### Formula Display
Formulas are displayed on their own line, often indented or formatted distinctly:
```
=IF(Denominator=0, , Numerator / Denominator)
```
Liam uses named ranges in formulas wherever possible to improve readability (*e.g.*, `Model_Start_Date` rather than `$B$3`).

---

## 6. Case Study Structure

The case study in Chapter 10 of the Introduction book follows this pattern:

1. **Disclaimer** — "this is a simple model build.  It wouldn't matter how complicated I made this model, it would never be exactly what you, dear reader, would want."
2. **Scope** — What the case study covers and what it deliberately excludes, with reasons for exclusions
3. **Assumptions list** — Bullet points with specific values in brackets
4. **Progressive build** — Each section builds on the previous one, with explicit references to "the template from Chapter 7"
5. **Running commentary** — Liam narrates the build as if doing it live: "So will it balance?  Do you think I'd have written this if it didn't?"
6. **Trap warnings** — Flagged as they arise, not saved for an appendix
7. **Wrap-up** — Brief, practical, pointing to the appendix for full formula list

---

## 7. Cross-Referencing Convention

### Internal References
- "as discussed in Chapter 3" / "as we saw in the previous section"
- "(more on that later)" — very frequently used as a teaser
- "as I mentioned in the first book" — cross-book references in the Continuing book

### External References
- "There's so much literature out there on this hotly-debated topic"
- References to industry standards by name: "Best Practice Spreadsheet Modelling Standards, FAST, SMART and TransparencEY"
- Minimal footnotes — Liam integrates citations into the text naturally

### Companion Materials
- "Head to our website at https://www.sumproduct.com/book-resources"
- "If you have trouble reading the formulae in the worksheets, you'll find a full list in the appendix"

---

## 8. Paragraph Length and Pacing

### Paragraph Length
- **Opening/personality paragraphs**: 3–6 sentences, conversational pace
- **Technical explanation paragraphs**: 2–4 sentences, tighter
- **Worked example narration**: 1–3 sentences per step
- **Summary/transition paragraphs**: 2–4 sentences

### Sentence Length Variation
Liam alternates deliberately between:
- **Long, clause-heavy sentences** for context-setting: "I have been meaning to write this book for more years than I care to remember and you have decided that maybe there is a better way of building financial models that doesn't involve trying to find Balance Sheet errors at 2am on a Saturday morning."
- **Punchy short sentences** for emphasis: "That's it." / "Concepts are key." / "Simple!" / "Deal..?"

### The "One-Liner" Emphasis
Key principles are sometimes given their own paragraph or even their own centred line:

```
KEEP IT SIMPLE STUPID
```

or

```
A lazy modeller is to be encouraged; lazy modelling isn't.
```

---

## 9. The "Plan" Disclosure

Both books feature a structured "plan" early on — a roadmap of what follows.  This is a signature structural element:

**Introduction book:**
"The plan is therefore as follows:
•  Key Excel functions: Before we go anywhere...
•  Key Excel functionalities: There are other attributes...
•  "Best Practice" methodology: There's so much literature...
•  Layout tips: Everyone always ploughs straight into Excel..."

**Continuing book:**
"The plan is therefore as follows:
•  Recap: It may have been a while since you read the first book...
•  What-if? analysis: Since the first book came out, if there's one question I have been asked above all else...
•  Forecasting: At the other end of the spectrum..."

Each bullet in the plan includes the topic name in bold followed by a conversational explanation of why it's included.
