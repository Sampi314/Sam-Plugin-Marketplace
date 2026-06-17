# DAX Article Template — Exact Structure

Derived from 20+ Liam-approved DAX function articles. This file covers STRUCTURE and EXACT WORDING only. For all formatting, grammar and style rules, read the auditor skill's references:
- `/mnt/skills/user/wt-writing-auditor/references/liam-rules.md`
- `/mnt/skills/user/wt-writing-auditor/references/style-guide.md`

---

## 1. Title Block

**Format:** Bold-italic, en-dash separator, then date on next line.

```
***Power Pivot Principles: The A to Z of DAX Functions -- FUNCTIONNAME***

DD Month YYYY
```

Date rules: no leading zero, no ordinals, no US format (see Liam A7).

---

## 2. Opening Paragraph

**Exact wording (entire paragraph italic, DAX and function name bold within italic):**

```
*In our long-established Power Pivot Principles articles, we continue our series on the A to Z of Data Analysis eXpression (**DAX**) functions.  This week, we look at **FUNCTIONNAME**.*
```

"Data Analysis eXpression" — capital X always.

---

## 3. Function Heading

**Format:** Bold-italic, single unbroken block.

```
***The FUNCTIONNAME function***
```

---

## 4. Function Image

Insert an image placeholder after the heading:

```
[IMAGE PLACEHOLDER: Decorative/AI-generated image related to [concept]. Approximately 4" × 4".]
```

---

## 5. Function Description

A prose paragraph that:
1. States the function category (see patterns below)
2. Describes what it does in plain English
3. Optionally mentions the Excel equivalent
4. Transitions to syntax

### Category Identification Patterns (exact phrases from approved articles)

| Category | Phrasing |
|----------|---------|
| Text | "is one of the text functions which..." |
| Math/Trig | "is one of the mathematical and trigonometric functions" |
| Information | "is one of the information function**s** that..." |
| Financial | "is one function that calculates..." / "This function calculates..." |
| Time Intelligence | "is one of the time intelligence functions which..." |
| Statistical | "is categorised as a statistical function" / performs "linear regression" |
| Filter | "is used to modify how filters are applied whilst evaluating a **CALCULATE**..." |

### Excel Cross-Reference Pattern

```
If you have worked with **FUNCTIONNAME** in Excel before, it behaves in very much the same way in **DAX**.
```

### Preamble Explanation (When Needed)

If the concept is not immediately clear, explain it before the syntax. Examples from approved articles:
- LINEST: "Before we get into the syntax let's have a quick overview of what **LINEST** is, which is short for Linear Estimation..."
- LCM: "You can use **LCM** to add fractions with different denominators, align scheduling cycles or synchronise periodic events"
- ISPMT: "In reality, this is quite an easy financial instrument to calculate using basic formulae..."

### Transition to Syntax

Choose one:
- "It employs the following syntax:"
- "It uses the following syntax:"
- "It has the following syntax:"

---

## 6. Syntax Block

**Bold, own line, no angle brackets, proper spacing (Liam D1, D8):**

```
**FUNCTIONNAME(arg1, arg2 [, arg3])**
```

---

## 7. Argument Count Line

**Word [digit] convention (Liam A6):**

| Count | Phrasing |
|-------|---------|
| 1 | "There is only one [1] argument in this function:" OR "There is one [1] main argument in this function:" |
| 2 | "There are two [2] main arguments in this function:" |
| 3 | "There are three [3] main arguments in this function:" |
| 4 | "There are four [4] main arguments in this function:" |

Use "main" when there are also optional arguments. Use "only" for single-argument functions.

---

## 8. Argument List

**Bulleted, bold names, lowercase descriptions (Liam B1, B2):**

```
-   **arg1**: this argument is required. It is the [description]

-   **arg2**: this argument is optional. It specifies [description].
```

Rules:
- Only FINAL bullet ends with full stop
- Argument names bold: **text**, **number**, **rate**
- Start lowercase (clause continuation)
- Reference other arguments in bold: "between zero [0] and **nper**-1"
- State if required or optional

### Common Argument Description Openers

- "this argument is required. It is the..."
- "this is required which represents..."
- "this argument is optional. It specifies..."
- "this is optional which is the..."

---

## 9. Remarks Section

### Opening Line

| Situation | Phrasing |
|-----------|---------|
| 3+ remarks | "Here are a few remarks about the **FUNCTIONNAME** function:" |
| 2 remarks | "Here are a couple of remarks about the **FUNCTIONNAME** function:" |
| Additional set | "It should be further noted:" |

### Remark Bullet Rules

Per Liam B1/B2: lowercase start, only final bullet gets full stop. All function/argument names bold, error values italic, TRUE/FALSE not bold.

### Standard DirectQuery Remark (typically the final bullet)

```
-   this function is not supported for use in DirectQuery mode when used in calculated columns or row-level security (RLS) rules.
```

### Common Remark Patterns from Approved Articles

**Error conditions:**
```
-   if any argument is non-numeric, **FUNCTIONNAME** returns the *#VALUE!* error value
```

**Excel cross-reference (text functions):**
```
-   whereas Microsoft Excel contains different functions for working with text in single-byte and double-byte character languages (*i.e.* **LEFT** and **LEFTB**), **DAX** works with Unicode and stores all characters as the same length; therefore, a single function is sufficient
```

**Return type:**
```
-   **LEFT** always returns a text string, even when the input value is numeric
```

**Safety behaviour:**
```
-   if the **num_chars** argument is a number that is larger than the number of characters available, the function returns the maximum characters available and does not raise an error
```

**Related function:**
```
-   the **LCM** function is related to the **GCD** (Greatest Common Divisor) function
```

**Table-returning functions:**
```
-   **LINEST** returns a single-row table describing the line, plus additional statistics. These are the available columns:
```
(then sub-bullets listing each column)

**Consistency warning:**
```
-   make sure that you are consistent about the units you use for specifying rate and **nper**
```

**KEEPFILTERS-style context explanation:**
```
-   by default, filter arguments in functions such as **CALCULATE** are used as the context for evaluating the expression, and as such, filter arguments for **CALCULATE** replace all existing filters over the same columns
```

---

## 10. Example Section

### Transition Phrases (choose based on context)

| Phrase | When to Use |
|--------|------------|
| "Rather than demonstrate each scenario separately, we can use a single DAX query with a table constructor to showcase all the key behaviours of the **FUNCTIONNAME** function at once:" | Table constructor with multiple test cases |
| "Let's consider the following example." | Simple single example |
| "As an example, we can write the following formula in **DAX**:" | Direct formula demonstration |
| "As an example, let's set up a simple [Name] table within Power BI:" | Data table setup |
| "To test, a base table, consisting of [description], was created:" | Table creation for testing |
| "Let's write a few tests with different types of values to see how this function evaluates each of them:" | Multiple test scenarios |

### Pattern A: Table Constructor (Most Common for Scalar Functions)

```
**EVALUATE**
**{**
    **("Description 1", input1, FUNCTION(input1)),**
    **("Description 2", input2, FUNCTION(input2)),**
    **("Description 3", input3, FUNCTION(input3))**
**}**
```

Then: "This will return the following Table:" (capital T per Liam A10)

Then: `[IMAGE PLACEHOLDER: Screenshot of results table showing N rows.]`

Then: walkthrough with bold-italic sub-headings (***Sub-heading***) per Liam A9.

### Pattern B: DATATABLE + Measure (For Filter Context Functions)

```
**TableName =
DATATABLE (
    "Column1", STRING,
    "Column2", STRING,
    "Amount", INTEGER,
    {
        { "A", "East", 100 },
        { "B", "West", 50 }
    }
)**
```

Then: "This code will give you a simple table with N [N] columns:"

Then: `[IMAGE PLACEHOLDER: Screenshot of the data table.]`

Then: create measures and show visuals with image placeholders.

### Pattern C: DAX Query View (For Table-Returning Functions)

Simple:
```
**EVALUATE
FUNCTIONNAME(args)**
```

Or with DEFINE VAR:
```
**DEFINE
    VAR VariableName = expression
EVALUATE
    FUNCTIONNAME(VariableName, ...)**
```

Or with measure + visual:
```
**MeasureName =
VAR _result = FUNCTIONNAME(args)
VAR _value = MAXX(_result, [Column])
RETURN
    _value**
```

### Results Walkthrough Patterns

- "Let's walk through the key observations from this results table:"
- "Row N shows that..." / "Row N demonstrates..."
- "This makes sense, since..."
- "This means..."
- "This returns the following table:" (for non-DAX-query results)

### Sub-heading Conventions

Bold-italic, sentence case (Liam A9, A19):
- ***Simple examples***
- ***Decimal handling***
- ***Numeric input***
- ***When num_chars exceeds the string length***
- ***Default behaviour***
- ***Spaces and empty strings***
- ***Nesting FUNCTIONNAME for three or more numbers***
- ***Multiple independent variables***
- ***Extracting scalar values from FUNCTIONNAME***

### Image Placeholders

For each screenshot location:
```
[IMAGE PLACEHOLDER: Description of what the image shows. Approximate dimensions.]
```

Common image descriptions:
- "Screenshot of the [Table Name] data table with N columns and N rows."
- "Screenshot of results table. Columns: [col1], [col2], [col3]. N rows."
- "Screenshot of the DAX query view code."
- "Screenshot of the PivotTable / Card visual / Line chart showing [description]."
- "Screenshot of the Power BI slicer filtering to [value]."

---

## 11. Closing Paragraph

**Exact wording (italic, with three hyperlinks):**

```
*Come back next week for our next post on Power Pivot in the [Blog](https://www.sumproduct.com/blog) section.  In the meantime, please remember we have training in Power Pivot which you can find out more about [here](https://www.sumproduct.com/courses/power-pivot-power-query-and-power-bi).  If you wish to catch up on past articles in the meantime, you can find all of our Past Power Pivot blogs [here](https://www.sumproduct.com/thought/power-pivot-principles-blog-series).*
```

The three links:
1. "Blog" → `https://www.sumproduct.com/blog`
2. "here" (training) → `https://www.sumproduct.com/courses/power-pivot-power-query-and-power-bi`
3. "here" (past articles) → `https://www.sumproduct.com/thought/power-pivot-principles-blog-series`

---

## Complete Skeleton

```markdown
***Power Pivot Principles: The A to Z of DAX Functions -- FUNCTIONNAME***

DD Month YYYY

*In our long-established Power Pivot Principles articles, we continue our series on the A to Z of Data Analysis eXpression (**DAX**) functions.  This week, we look at **FUNCTIONNAME**.*

***The FUNCTIONNAME function***

[IMAGE PLACEHOLDER: Decorative image related to [concept].]

[Function description paragraph — category, purpose, optional Excel cross-ref, transition to syntax.]

[Optional preamble explanation for complex concepts.]

**FUNCTIONNAME(arg1, arg2)**

There are two [2] main arguments in this function:

-   **arg1**: this argument is required. It is the [description]

-   **arg2**: this argument is optional. It specifies [description].

Here are a few remarks about the **FUNCTIONNAME** function:

-   [remark 1]

-   [remark 2]

-   this function is not supported for use in DirectQuery mode when used in calculated columns or row-level security (RLS) rules.

[Example transition phrase]

[DAX code block]

This will return the following Table:

[IMAGE PLACEHOLDER: Results table.]

[Walkthrough with ***bold-italic sub-headings***]

*Come back next week for our next post on Power Pivot in the [Blog](https://www.sumproduct.com/blog) section.  In the meantime, please remember we have training in Power Pivot which you can find out more about [here](https://www.sumproduct.com/courses/power-pivot-power-query-and-power-bi).  If you wish to catch up on past articles in the meantime, you can find all of our Past Power Pivot blogs [here](https://www.sumproduct.com/thought/power-pivot-principles-blog-series).*
```
