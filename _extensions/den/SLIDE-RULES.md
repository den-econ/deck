# Rules for writing den-beamer slides

Read this before writing or editing a `.qmd` that renders with `den-beamer`.
`gallery.qmd` in the den-econ/deck repo shows every pattern below; copy from it.

## What this format is for

Use den-beamer for DEN decks rendered to PDF: equations, regression tables,
figures made in code, and framework slides built from cards. A slide is a
title plus one of: bullets, an equation with its definitions, one table, one
figure, or one slot grid (`.cols`).

Build card layouts only with the `.cols` grid below. Never hand-roll boxes
with raw LaTeX, `###` headings or beamer blocks.

## Content budgets

Each slide carries one message, stated in its title. If the content exceeds
a budget, split the slide. Never shrink text to make it fit.

| Slide type | Budget |
|:--|:--|
| Normal text | 6 bullets, 2 lines each |
| `{.small}` | 8 bullets |
| `{.smaller}` | Dense tables and equations only, not for more bullets |
| Table, one-line cells | 6 body rows, 5 columns |
| Table, multi-line cells | 4 body rows, 4 columns, on a `{.smaller}` slide |
| Figure | One per slide, plus one line of explanation and source |
| Columns (`.columns`) | Two at most, widths summing to 100% or less |
| Slot grid (`.cols`) | See "Slot grid and cards" below |
| Takeaway | One per slide, 2 lines |

## Slot grid and cards

`:::: {.cols n=N}` lays its child divs out in N equal columns, row by row.
Each child is a slot, and a slot is one of:

- `::: {.card title="Judul"}`: cream box with a brown title bar. Add `.gold`
  or `.dark` for a gold or dark-brown bar. Without `title`, a plain cream box.
- `::: {.plain}`: no box. Use it for a figure or for text that should sit on
  the slide background. Not every slot has to be a card.

A slot with `.wide` takes a full row. `rows="2,1"` sets relative row heights
(default: 1 per row, 0.5 for a `.wide` row). `height="80%"` is the share of
the slide body the grid fills (default 80%, which leaves room for one
takeaway; use up to 100% when the grid is alone on the slide).

Row heights are fixed, so cards in a row are equally tall, and a figure in a
slot is scaled to fit it. Text size is set by N and cannot be changed.

| Layout | Markup | Text size | Budget per card |
|:--|:--|:--|:--|
| 2 columns | `{.cols}` with 2 slots | 10pt | title + 3 bullets or 30 words |
| 2 columns + 1 row | `{.cols}`, last slot `.wide` | 10pt | 20 words; wide row 1 to 2 lines |
| 2 x 2, short bottom row | `{.cols rows="2,1"}` with 4 slots | 10pt | top 3 bullets; bottom 1 line |
| 3 x 2 | `{.cols n=3}` with 6 slots | 9pt | title + 10 words |
| 6 columns + 1 row | `{.cols n=6 rows="2,1"}`, 7th slot `.wide` | 8pt | title of 1 word + 6 words; wide row 1 line |
| 4 x 2 | `{.cols n=4}` with 8 slots | 8pt | title + 8 words |

Slot sizes at the default height, for drawing figures at their final size:

| Layout | Slot width | Row height |
|:--|:--|:--|
| N = 2 | 6.9 cm (2.7 in) | 5.2 cm for one row; 2.5 cm each for two equal rows |
| N = 3 | 4.5 cm (1.8 in) | as above |
| N = 4 | 3.3 cm (1.3 in) | as above |
| N = 6 | 2.1 cm (0.8 in) | as above |
| With a `.wide` row or `rows="2,1"` | | 3.3 cm top, 1.7 cm bottom |

A titled card loses about 1 cm of that height to its title bar and padding.

Rules for cards:

- One `.cols` grid per slide, with at most one takeaway below it.
- Use the three title colours to group cards (for example one colour per
  stage), not for decoration. A card without a title has no colour.
- A figure goes in a `.plain` slot unless it needs a title bar.
- A slot holds one figure or text, not both.
- No `###` headings inside a slot: in revealjs they become separate slides.
- If the text does not fit its card, cut the text. Do not raise `height`
  beyond 100% or drop to a denser layout to gain room.

## Components

- **Takeaway**: `::: {.takeaway}` … `:::`. The single message of the slide,
  placed last. Not for sources or footnotes.
- **Figure slots**: `![](fig.png){.fig-full}` when the figure is the slide;
  `{.fig-half}` when it shares the slide with text or a takeaway. Inside a
  column the slot follows the column width.
- **Code-chunk figures**: draw at `figsize=(5.5, 2.2)` inches (the format
  default) with 7 to 8pt fonts, no title inside the figure, using fig-den.
  The slide title is the figure title.
- **Tables**: plain pipe or grid tables. Header and rules are styled by the
  template; add no table markup.
- **Sizes**: only `{.small}` and `{.smaller}` on the slide header.

## Forbidden

- `{.shrink}`: ignored by the template, with a warning.
- `\scriptsize`, `\tiny`, `\fontsize`, or any manual font size.
- Negative `\vspace`, and `\vspace` used to make content fit.
- `\renewcommand{\arraystretch}` and custom box macros in `header-includes`.
- `###` headings inside columns to fake boxes; use `.cols` and `.card`.
- Raw `tcolorbox`, `\colorbox` or beamer `block` environments.

## Mandatory check before finishing

1. Render: `quarto render deck.qmd --to den-beamer`
2. Check: `python _extensions/den/check-deck.py deck.pdf`
3. Fix every `ERROR` by cutting or splitting content, then repeat 1 and 2.
4. Open the slide images the checker writes (`deck_check/`) and look at each
   one. The checker cannot judge crowding, figure legibility or alignment.
5. Review each `warning`; fix it or be able to say why it is acceptable.

The deck is not finished until the checker reports 0 errors and every slide
image has been looked at.
