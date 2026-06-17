"""
Flow chart fallback renderer using matplotlib.

Used when `mermaid-cli` (mmdc) is unavailable or cannot launch Chrome.
This is a TEMPLATE — copy and adapt the node/arrow layout to suit each
article's flow chart. Brand palette comes from brand-spec.md.
"""
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib import rcParams

rcParams["font.family"] = "DejaVu Sans"  # close stand-in for DM Sans

# Brand palette — mirror brand-spec.md. Update both files together if the
# upstream brand guidelines change.
DARK_GREEN = "#1e3c3b"  # primary — process-node borders, arrows, body text
LIME       = "#d2f7b1"  # accent  — decision-node fill, highlight backgrounds
GREEN      = "#007033"  # secondary — final-node fill, decision-node border
INK        = "#000000"  # Black 100% for body text
WHITE      = "#ffffff"

fig, ax = plt.subplots(figsize=(14, 5), dpi=100)
ax.set_xlim(0, 140)
ax.set_ylim(0, 50)
ax.axis("off")
fig.patch.set_facecolor(WHITE)


def box(x, y, w, h, text, fill, edge, text_color, bold=False):
    p = FancyBboxPatch(
        (x, y), w, h,
        boxstyle="round,pad=0.3,rounding_size=1.2",
        facecolor=fill, edgecolor=edge, linewidth=2,
    )
    ax.add_patch(p)
    ax.text(
        x + w / 2, y + h / 2, text,
        ha="center", va="center",
        fontsize=11, color=text_color,
        fontweight="bold" if bold else "normal", wrap=True,
    )


def arrow(x1, y1, x2, y2, label=None, label_offset=(0, 1.5), curve=0):
    style = f"arc3,rad={curve}" if curve else "arc3"
    a = FancyArrowPatch(
        (x1, y1), (x2, y2),
        arrowstyle="-|>", mutation_scale=15,
        color=DARK_GREEN, linewidth=1.8,
        connectionstyle=style,
    )
    ax.add_patch(a)
    if label:
        mx = (x1 + x2) / 2 + label_offset[0]
        my = (y1 + y2) / 2 + label_offset[1]
        ax.text(
            mx, my, label,
            ha="center", va="center",
            fontsize=9, color=INK, style="italic",
            bbox=dict(facecolor=WHITE, edgecolor="none", pad=1),
        )


# === Example layout (replace per article) ============================
# Six-node linear flow with a loop-back from "Self-check" to "Reason".
# All nodes at y=22 for a clean left-to-right flow.

h = 8
y = 22
nodes = [
    (2,   y, 18, h, "User\nprompt",            DARK_GREEN, DARK_GREEN, WHITE, True),
    (24,  y, 20, h, "Reason about\nlayout",    WHITE,      DARK_GREEN, INK,   False),
    (48,  y, 18, h, "Search the\nweb",         WHITE,      DARK_GREEN, INK,   False),
    (70,  y, 16, h, "Draft\nimage",            WHITE,      DARK_GREEN, INK,   False),
    (90,  y, 20, h, "Self-check\noutput",      LIME,       GREEN,      INK,   False),
    (114, y, 24, h, "Return up to 8\nconsistent images", GREEN, GREEN, WHITE, True),
]
for n in nodes:
    box(*n)

# Forward arrows between adjacent boxes.
arrow(20, 26, 24, 26)
arrow(44, 26, 48, 26)
arrow(66, 26, 70, 26)
arrow(86, 26, 90, 26)
arrow(110, 26, 114, 26, "Acceptable", label_offset=(0, 2))

# Loop-back arrow: Self-check → Reason about layout (arcs over the flow).
loop = FancyArrowPatch(
    (100, 30), (34, 30),
    arrowstyle="-|>", mutation_scale=15,
    color=GREEN, linewidth=1.8,
    connectionstyle="arc3,rad=0.35",
)
ax.add_patch(loop)
ax.text(
    67, 44, "Needs refinement",
    ha="center", va="center",
    fontsize=10, color=GREEN, style="italic", fontweight="bold",
    bbox=dict(facecolor=WHITE, edgecolor="none", pad=2),
)

# Title — replace per article.
ax.text(
    70, 6, "How thinking mode works",
    ha="center", va="center",
    fontsize=13, color=DARK_GREEN, fontweight="bold", style="italic",
)

plt.tight_layout()
plt.savefig("flowchart.png", dpi=100, bbox_inches="tight", facecolor=WHITE)
print("Saved flowchart.png")
