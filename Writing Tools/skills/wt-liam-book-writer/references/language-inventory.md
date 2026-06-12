# Language Inventory — Liam Bastick's Book Writing

Specific phrases, transitions, idioms, and technical explanation patterns extracted from both books.  Use these as building blocks — not as a script to copy verbatim, but as a palette of language choices that sound authentically like Liam.

---

## 1. Transitional Phrases

### Between Sections
- "OK, so with no further ado, let's take a look at..."
- "Jokes aside, maybe we should move on."
- "If there are no more questions, let's get going…"
- "So where do I start?"
- "Having said that..."
- "With this borne in mind..."
- "Let me be clear what I mean by..."
- "Before we go anywhere..."
- "Apart from [X], you should also familiarise yourself with..."
- "If nothing else, this should provide useful reference material as we..."

### Within Sections
- "Well, let me try."
- "Now yes, I appreciate it isn't *that* difficult..."
- "The point I make here is that..."
- "This is precisely where [X] comes in."
- "It is with this borne in mind that..."
- "You might wonder why I have..."
- "To ensure it is enabled..."
- "So will it balance?  Do you think I'd have written this if it didn't?"

### Introducing New Concepts
- "Consider the following situation:"
- "This is best illustrated using another example:"
- "To show how it works, consider the following example."
- "Now, for more sophisticated readers, yes, I appreciate [caveat]..."
- "For those of you with no more than a passing acquaintance with [topic]..."
- "I make no apologies that [X] was not discussed."

### Qualifying Statements
- "I want to be clear: no one is holding a gun to your head and saying you *must* do it this way."
- "This book is not an [X] book.  It is simply intended to provide..."
- "It is not possible to have an example that covers everything.  If I could, I'd be much richer, trust me."
- "I am not saying that [X] will ensure [Y], but in theory it should *reduce*..."
- "I have been modelling for a long time (you'd think I would get the thing finished by now)..."

---

## 2. Emphasis Patterns

### Italic Emphasis
Used for:
- Latin abbreviations: *i.e.*, *e.g.*, *viz.*, *etc.*, *ad nauseum*
- Words being defined or first-used: "This is known as *relative referencing*"
- Stressing a key word in an otherwise normal sentence: "it should *reduce* both the number and the magnitude"
- Book/publication titles: *The Simpsons*, *An Introduction to Financial Modelling*

### Bold Emphasis
Used for:
- Function names: **SUM**, **IF**, **VLOOKUP**
- Feature names on first mention: **Quick Analysis**, **Data Table**
- Key phrases that are mantras: **KEEP IT SIMPLE STUPID**
- Keyboard shortcuts: **ALT + =**, **CTRL + 1**, **F4**
- Important terms being defined: **lazy modeller** vs **lazy modelling**

### ALL CAPS Emphasis
Used sparingly for maximum impact:
- **KEEP IT SIMPLE STUPID** — the primary mantra
- Sub-chapter headings: "CHAPTER 1.1: SUM"
- Very rarely in running text for shock value

### Centred Standalone Lines
Key principles sometimes get their own centred line, separated from surrounding text:

> KEEP IT SIMPLE STUPID

> A lazy modeller is to be encouraged; lazy modelling isn't.

> Concepts are key.

---

## 3. Recurring Phrases and Idioms

### Liam's Stock Phrases
These appear multiple times across both books:

| Phrase | Context |
|---|---|
| "more on that later" | Teasing upcoming content |
| "how many times have I said that so far?" | After repeating a principle |
| "this reinforces one of my on-going themes" | Connecting current point to broader philosophy |
| "you get the picture" | After giving enough examples to establish a pattern |
| "suffice to say" | Summarising without labouring the point |
| "I couldn't resist that" | After a particularly bad pun |
| "let me be clear" | Before defining something precisely |
| "it makes sense to..." | Recommending a practice |
| "the aim is to..." | Stating an objective |
| "don't fall into that trap" | Warning about common mistakes |
| "to that end" | Connecting cause to action |
| "it is my preference" | Stating personal opinion (not mandate) |
| "in the context of financial modelling" | Narrowing scope from general Excel to modelling |
| "the chances are" | Probabilistic warning |
| "let's face it" | Inviting honest assessment |
| "if you did read that book" | Self-deprecating reference to first book |
| "that blessed Balance Sheet" | Affectionate frustration |
| "warts and all" | Comprehensive / unvarnished |
| "the whole hog" | Going all the way |
| "true" (as sentence opener) | Conceding a point before making a counter-argument |

### British Idioms Liam Uses
- "ploughing through" — working through methodically
- "hot under the collar" — agitated/passionate
- "got off my backside" — took initiative
- "ticks some, if not all, of the boxes" — meets requirements
- "the usual fare" — typical/standard approach
- "fit square pegs in round holes" — forcing inappropriate solutions
- "cradle to grave" — comprehensive/complete lifecycle
- "nigh on" — almost/nearly
- "on commission for" — frequent promotion of

---

## 4. Technical Explanation Language

### Formula Walkthroughs
When explaining a formula, Liam uses this pattern:

```
The calculation [formula fragment] takes the [description] and [action],
so that it [result].  It's a common mistake made in analytical models
and is an error that is easily avoided.
```

Example from the book:
"The calculation H25 / (1 - H23) takes the target NPAT (H25) and scales it up by the tax rate (1 - H23), so that it reverts to the target amount once tax has been deducted."

### Introducing Functions
Pattern: Question → Definition → Context → Example

"Is there really anyone out there that hasn't encountered the **SUM** function?  Given this book is intended to be about financial modelling rather than an introduction to Excel functions, is there anything new for me to tell you about **SUM**…?  Well, let me try.  **SUM** adds things up."

### Error Explanations
Pattern: What goes wrong → Why it matters → How to fix it

"However, if the Denominator is either blank or zero, this will result in a #DIV/0! error.  Excel has several errors that it cannot evaluate... prima facie errors should be avoided in Excel as they detract from the key results and cause the user to doubt the overall model integrity."

### Keyboard Shortcuts
Always presented with context and the shortcut in bold:
"There is a great keyboard shortcut available on most PC's (PC = *proper computer*).  If you select the cell directly to the right or below the values to be aggregated and then use the shortcut **ALT + =** you will see that the range is summed automatically."

---

## 5. Parenthetical Patterns

Liam uses parentheses extensively and distinctively:

### The Explanatory Aside
- "(often called a 'stub' period)"
- "(known as the 'Net Present Value' (NPV))"
- "(a bit of an incendiary reference, I know)"

### The Editorial Aside
- "(I said no such thing — Editor.)"
- "(someone needs to explain that title to me)"
- "(believe it or not, this is what Microsoft call these things!)"

### The Self-Deprecating Aside
- "(you'd think I would get the thing finished by now)"
- "(my daughter doesn't agree)"
- "(for a fee, of course)"
- "(cheapskate)"

### The Joke Extension
- "(PC = *proper computer*)"
- "(sounds kinky I know)"
- "(maybe I could have phrased that better, but I did warn you about my sense of humour)"
- "(well, I've certainly moved up a pay bracket…)"

### The Qualifier
- "(more on that later)"
- "(although not always)"
- "(and plenty more)"
- "(assuming you haven't cheated and turned straight to this chapter!)"

---

## 6. Sentence Openers

### For Opening Paragraphs
- "At last..."
- "So, I finally managed it..."
- "They say I always have to..."
- "In light of the discussion on..."
- "Now before we all get carried away here..."
- "Are you all sleeping comfortably?  Then I shall begin."
- "I am going to let you in to..."

### For Explanatory Paragraphs
- "With this borne in mind..."
- "It is worth noting that..."
- "The aim is to..."
- "It is my preference..."
- "Most variants of Excel..."
- "Since functions are limited to..."
- "One thing to note is that..."

### For Warning/Trap Paragraphs
- "It's a common mistake..."
- "Don't make the same mistake..."
- "This is where [function/concept] comes in."
- "My old boss used to promote the idea of..."
- "The problem is..."
- "Unfortunately..."

### For Transition/Bridge Paragraphs
- "Jokes aside, maybe we should move on."
- "OK, so with no further ado..."
- "So where do I start?"
- "If there are no more questions..."
- "And there's more."

---

## 7. Acknowledging the Audience

### For Beginners
- "For those of you with no more than a passing acquaintance with [topic]"
- "Even if you have never seen this dialog box before, you just know where you need to input data."
- "Don't worry about any specific formulae; ensure you get the concepts."

### For Advanced Readers
- "For the more advanced amongst you, may I suggest you read this section as well, as there's stuff in here that many just don't appreciate."
- "Now, for more sophisticated readers, yes, I appreciate [caveat]"
- "Whether you are a novice or an expert, hopefully, there may be some useful tips for all."

### Bridging Both
Liam's signature move is addressing both simultaneously:
- "Whether you are a novice or last year's Financial Modelling World Champion *(someone needs to explain that title to me)*, hopefully you learned something"
- "I am going to assume that you, dear reader, have a basic understanding of Excel: I assume you are alive..."

---

## 8. The "Apology" Pattern

Liam has a distinctive pattern of apologising for — then immediately doubling down on — his jokes:

```
[Bad pun]
[Brief acknowledgement: "I did warn you" / "I couldn't resist" / "get it?"]
[Immediately moves on to serious content]
```

He never dwells on whether the joke landed.  The acknowledgement IS the punchline.

---

## 9. Closing Phrases for Sections

- "Simple!"
- "That's it."
- "The end."
- "You get the picture."
- "Try it – it's fun, not!"
- "And there you have it."
- "If you were the recipient of such a model... would you feel more comfortable?"
- "So will it balance?  Do you think I'd have written this if it didn't?"
