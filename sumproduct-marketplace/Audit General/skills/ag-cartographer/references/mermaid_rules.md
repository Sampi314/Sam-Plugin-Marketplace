# Mermaid Syntax Rules (Mandatory)

These rules apply to **every** `.mermaid` file the Cartographer produces.

## Core Rules

| Rule | Detail |
|---|---|
| **File format** | Standalone `.mermaid` file. Never embed in Markdown fences. |
| **Comment header** | First line must be `%% Agent: Cartographer 🗺️ — [Deliverable Name]` to identify source agent. |
| **Subgraph IDs** | Always `sg_<n>` with display label `["Human-Readable Name"]`. |
| **Node IDs** | No `sg_` prefix. No spaces/slashes/special chars. Use underscores. |
| **Display labels** | `NodeID["Display Name"]` or `NodeID[Display Name]` for simple names. |
| **Formula arrows** | Solid lines: `-- "label" -->`. Always labelled. |
| **Shadow arrows** | Dotted lines: `-. "label" .->`. Always labelled. |
| **Arrow labels** | Wrap in `"..."` if label contains special chars or spaces. |
| **Direction** | `flowchart LR` for workbook maps, critical paths, shadow maps. `flowchart TD` for sheet maps. |
| **Circular refs** | `A <-- "🔄 Description" --> B` (bidirectional arrow). |
| **Hidden sheets** | `NodeID["Sheet Name (hidden)"]` |
| **Orphaned sheets** | `NodeID["Sheet Name"]:::orphan` with `classDef orphan stroke-dasharray: 5 5` |
| **Max nodes** | ~30 per diagram. Split if exceeded. |
| **No unlabelled arrows** | Every `-->` must have a `-- "label" -->`. Exception: L3 critical paths where flow is self-evident. |

## ClassDefs (Node Styles)

```
classDef input fill:#E8F5E9,stroke:#2E7D32
classDef output fill:#E3F2FD,stroke:#1565C0
classDef shared fill:#FFD700,stroke:#333
classDef table fill:#FFF3E0,stroke:#E65100
classDef named_range fill:#E1BEE7,stroke:#6A1B9A
classDef hardcoded fill:#F5F5F5,stroke:#9E9E9E,stroke-dasharray: 3 3
classDef validation_target fill:#E8EAF6,stroke:#283593
classDef shadow_ext stroke-dasharray: 3 3,stroke:#9C27B0
classDef external fill:#FFCDD2,stroke:#C62828
classDef cond_format fill:#ECEFF1,stroke:#607D8B
classDef orphan stroke-dasharray: 5 5
```

## Node Shapes

| Type | Shape | Example |
|---|---|---|
| Standard node | Rectangle | `NodeID["Name"]` |
| External input/output (L2) | Stadium | `NodeID(["Name"])` |
| Table | Cylinder | `NodeID[("tbl_Name")]:::table` |
| Named Range | Hexagon | `NodeID{{"Name"}}:::named_range` |
| Hardcoded validation | Rectangle (grey dashed) | `NodeID["Values"]:::hardcoded` |

## Mermaid ID Collision Checklist (Run Before Finalising)

1. Collect all subgraph IDs (immediately after `subgraph` keyword).
2. Collect all node IDs (before `[...]` display labels).
3. Confirm **zero overlap** between the two lists.
4. Confirm all subgraph IDs use the `sg_` prefix.
5. Confirm no IDs use reserved words: `end`, `graph`, `subgraph`, `direction`, `click`, `style`, `classDef`, `class`, `linkStyle`.
6. Confirm no IDs contain spaces, slashes, hyphens, or dots.
7. Confirm all arrow labels with special characters are wrapped in double quotes.

## L1 — Workbook Map Example

```
%% Agent: Cartographer 🗺️ — Workbook Map
flowchart LR
    subgraph sg_Inputs["Inputs"]
        Assumptions["Assumptions"]
        Control["Control"]
    end

    subgraph sg_Calcs["Calculations"]
        Calc_Revenue["Calc_Revenue"]
        Calc_COGS["Calc_COGS"]
    end

    subgraph sg_Outputs["Outputs"]
        Summary["Summary"]
    end

    %% Formula Layer (solid arrows)
    Assumptions -- "Volume, Pricing" --> Calc_Revenue
    Assumptions -- "Cost rates" --> Calc_COGS

    %% Shadow Layer (dotted arrows)
    Lookups -. "Status codes (via named ranges)" .-> Inputs
```

## L2 — Sheet Map Example

```
flowchart TD
    subgraph sg_External_In["External Inputs"]
        ext_Assum(["Assumptions"])
    end

    subgraph sg_Revenue["Revenue Sheet"]
        Vol["Volume Calculation\n(Rows 10–14)"]
        Price["Pricing\n(Rows 16–16)"]
        Rev["Revenue Calculation\n(Rows 17–19)"]
    end

    ext_Assum -- "Base Volume, Growth Rate" --> Vol
    Vol -- "Net Volume" --> Rev
    Price -- "Unit Price" --> Rev
```

## L3 — Critical Path Example

```
flowchart LR
    classDef input fill:#E8F5E9,stroke:#2E7D32
    classDef shared fill:#FFD700,stroke:#333
    classDef output fill:#E3F2FD,stroke:#1565C0

    BaseVol["Base Volume"]:::input
    NetRev["Net Revenue"]:::shared
    DSCR["DSCR"]:::output

    BaseVol --> NetVol --> NetRev --> CFADS --> DSCR
```

## L4 — Shadow Map Example

```
flowchart LR
    classDef table fill:#FFF3E0,stroke:#E65100
    classDef named_range fill:#E1BEE7,stroke:#6A1B9A
    classDef validation_target fill:#E8EAF6,stroke:#283593

    tbl_Lookups[("tbl_Lookups")]:::table
    Status_List{{"Status_List"}}:::named_range
    Inp_Status["Status\n(C5:C100)"]:::validation_target

    tbl_Lookups -- "[Status] column" --> Status_List
    Status_List -. "validation list" .-> Inp_Status
```

## Learned Patterns

### Subgraph ID Collision
When a subgraph and child node share the same ID (e.g., `subgraph Checks` containing `Checks[Checks]`), Mermaid treats it as a cycle. **Fix**: Always prefix subgraph IDs with `sg_`.

### Arrow Labels with Special Characters
Mermaid fails to parse labels with apostrophes or parentheses if not wrapped in double quotes. **Fix**: Always wrap arrow labels in `"..."`.
