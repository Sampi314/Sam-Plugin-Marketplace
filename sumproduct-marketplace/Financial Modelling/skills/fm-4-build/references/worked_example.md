# Worked Example: Model Parameters sheet via `build_helpers`

The helper library (`scripts/build_helpers.py`) reduces a standard sheet
build to declarative calls. This is the canonical pattern — copy it for new
sheets.

```python
from build_helpers import (
    init_excel, finalise_excel,
    write_header_block, write_section_heading,
    set_column_widths, add_named_range, apply_print_setup,
)
# create_all_styles(wb) must already have been called per
# fm-3-design/references/style_creation_code.md

app = init_excel()
wb = app.Workbooks.Add()
# ... create_all_styles(wb) here ...

ws = wb.Sheets.Add()
ws.Name = "Model Parameters"
set_column_widths(ws, {"A": 2, "B": 5, "C": 3, "D": 3, "E": 30,
                        "F": 2, "G": 10, "H": 10, "I": 12})

write_header_block(ws, "Model Parameters")
write_section_heading(ws, row=11, section_num=1, title="Technical Constants")

ws.Cells(13, 5).Value = "Days in Year"
ws.Cells(13, 5).Style = "Line Calc"
ws.Cells(13, 9).Value = 365
ws.Cells(13, 9).Style = "Parameter"
add_named_range(wb, "Days_in_Year", "='Model Parameters'!$I$13")

apply_print_setup(ws)
finalise_excel(app, wb, r"C:\models\my_model.xlsx")
```

Key points the example demonstrates:

1. `init_excel()` / `finalise_excel()` bracket every build — manual calc and
   no screen updates during, auto calc and save at the end.
2. Column widths are set before content.
3. Style is applied per cell (`Line Calc` for labels, `Parameter` for the
   grey constant cells) — never direct formatting.
4. The named range is added immediately after the cell it refers to, so the
   register never drifts out of sync with the layout.
