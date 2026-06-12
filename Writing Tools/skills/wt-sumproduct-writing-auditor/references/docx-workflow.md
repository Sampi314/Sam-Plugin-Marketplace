# Output B — Tracked-Changes Word Document Workflow

This is the procedure for producing **Output B** (see auditor SKILL.md Step 3). The goal: Liam opens the **same .docx he uploaded**, with red-lined insertions, deletions, and comments he can accept or reject one by one.

---

## Golden rule

**Edit the user's ORIGINAL .docx.** Do NOT create a new .docx from scratch and paste corrected content into it. A new .docx loses all of:

- Original paragraph styles, character styles, theme fonts
- Embedded images, headers, footers, page numbers
- Section breaks, columns, page layout
- Comment threads already in the document
- Liam's downstream Word styles and template bindings

---

## Procedure

### 1. Copy the original

Copy the user's uploaded .docx into a working directory. **Do not touch the original**.

### 2. Unpack the .docx

A .docx is a ZIP archive. Unzip to access:

- `word/document.xml` — the main document body
- `word/comments.xml` — comments (create if absent)
- `word/_rels/document.xml.rels` — relationships (touch if adding comment refs)
- `[Content_Types].xml` — content type registrations (touch if adding `comments.xml` for the first time)

### 3. Edit `word/document.xml`

Insert tracked-change markup directly into the XML. Every change needs three attributes:

- `w:author="Claude"` — so Liam knows the edit source
- `w:date` — ISO timestamp, *e.g.* `2025-03-12T10:23:00Z`
- `w:id` — unique integer per change (start at 1000, increment)

#### 3a. Text deletion

Wrap the original text in `<w:del>`:

```xml
<w:del w:id="1001" w:author="Claude" w:date="2025-03-12T10:23:00Z">
  <w:r>
    <w:delText>old text here</w:delText>
  </w:r>
</w:del>
```

Note: inside `<w:del>`, the element is `<w:delText>`, not `<w:t>`.

#### 3b. Text insertion

Wrap the new text in `<w:ins>`:

```xml
<w:ins w:id="1002" w:author="Claude" w:date="2025-03-12T10:23:00Z">
  <w:r>
    <w:t>new text here</w:t>
  </w:r>
</w:ins>
```

#### 3c. Formatting change (*e.g.* adding bold to a function name)

Two options, in order of reliability:

**Option A — comment (reliable).** Add a comment that points at the run needing reformatting. See section 4.

**Option B — `<w:rPrChange>` (fragile).** Inside the run properties, add the old formatting wrapped in `<w:rPrChange>`:

```xml
<w:r>
  <w:rPr>
    <w:b/>
    <w:rPrChange w:id="1003" w:author="Claude" w:date="2025-03-12T10:23:00Z">
      <w:rPr/>
    </w:rPrChange>
  </w:rPr>
  <w:t>FUNCTIONNAME</w:t>
</w:r>
```

This requires splitting an existing run if the formatting target spans only part of it. Splitting runs reliably is hard. Prefer Option A.

### 4. Comments (`word/comments.xml`)

Use comments rather than tracked changes for:

- Issues requiring Liam's judgment (Rule D2 — complex function explanations)
- Image-related issues (centring, truncated headers, copyright)
- Structural suggestions (missing sections, template non-compliance)
- Web-verification findings that need Liam's confirmation
- Formatting changes where splitting Word XML runs would be unreliable

Comment markup goes in two places.

In `word/document.xml`, wrap the target text with range markers and a reference:

```xml
<w:commentRangeStart w:id="2001"/>
<w:r>
  <w:t>target text being commented on</w:t>
</w:r>
<w:commentRangeEnd w:id="2001"/>
<w:r>
  <w:rPr><w:rStyle w:val="CommentReference"/></w:rPr>
  <w:commentReference w:id="2001"/>
</w:r>
```

In `word/comments.xml`, define the comment body:

```xml
<w:comment w:id="2001" w:author="Claude" w:date="2025-03-12T10:23:00Z" w:initials="C">
  <w:p>
    <w:r>
      <w:t>Rule D2 — flag for review. The explanation here is paraphrased rather than from Microsoft documentation; please verify behaviour.</w:t>
    </w:r>
  </w:p>
</w:comment>
```

If `word/comments.xml` did not exist in the original .docx, you must also:

1. Create the file with a `<w:comments>` root element and the appropriate namespaces.
2. Register the relationship in `word/_rels/document.xml.rels` (`Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments"`, `Target="comments.xml"`).
3. Register the content type in `[Content_Types].xml` (`<Override PartName="/word/comments.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"/>`).

### 5. Repack the .docx

ZIP the modified contents back into a .docx. Preserve the file structure exactly — folder names and casing matter.

### 6. Verify

Open the produced file (or check programmatically) and confirm:

- All tracked changes show in Word's review pane
- Comments appear with author "Claude"
- Original images, headers, footers, and styles are intact

---

## Known traps with `python-docx`

- `run.italic` returns `None` (not `False`) when italic is applied via a paragraph or character **style** (*e.g.* Word's built-in "Emphasis" style) rather than direct run formatting. To detect italic accurately, inspect the underlying XML or resolve style inheritance manually.
- Direct run modification via `python-docx` does not produce tracked changes — the library has no native `<w:ins>`/`<w:del>` support. You must drop to XML.
- Splitting a run programmatically to apply formatting to a subset of its text often produces malformed XML if not done carefully. Prefer a comment.
- When checking product-name spacing (`"PowerBI"` vs `"Power BI"`), search both visible text **and** heading styles — product names may appear differently in styled elements and the body.

---

## Never do this

- Do NOT create a brand-new .docx using `python-docx` or `docx-js` and paste content into it. This destroys original formatting.
- Do NOT convert the .docx to Markdown and back. This loses all Word-specific formatting.
- Do NOT skip Output B if the user uploaded a .docx — the tracked-changes file is Liam's primary review tool.

---

## Fallback: no .docx uploaded

If the user provided the article as plain text or Markdown instead of a .docx:

1. Apply all corrections directly (no tracked changes possible — there is no original to compare).
2. Use the standard `docx` skill to produce a clean new .docx with the corrections.
3. Tell the user that tracked changes require an original .docx upload, and offer to redo the audit with one.
