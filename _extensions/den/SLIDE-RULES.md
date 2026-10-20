# Rules for writing DEN slides

Read this before writing or editing a `.qmd` that renders with `den-beamer`
or `den-revealjs`. `gallery.qmd` in the den-econ/deck repo shows every
pattern below; copy from it.

## What this format is for

The template reproduces the DEN PowerPoint master (the "Bahan Workshop ULN"
look) in PDF and HTML: photo title slide, brown bar beside an Arial title,
emblem at top right, page number in a brown square, charts with a heading,
cards with coloured headers, and a "Sumber:" line at the bottom right.

Both formats use the master's own page: 13.333 x 7.5 in. Beamer prints on
that page; revealjs draws a 960 x 540 px canvas (72 px per inch). Sizes are
therefore identical: a 14pt line in the PDF is 14px in the HTML, and text
wraps at the same words in both.

A slide is a title plus one of: bullets, an equation with its definitions,
one table, one figure, or one slot grid (`.cols`). Build card layouts only
with the `.cols` grid. Never hand-roll boxes with raw LaTeX, HTML, `###`
headings or beamer blocks.

## Type sizes

| Element | Size |
|:--|:--|
| Slide title | Arial Bold 18pt, at most two lines (16pt is applied automatically for a third line; shorten instead) |
| Body text, bullets | Calibri 14pt; `{.small}` 12pt, `{.smaller}` 11pt |
| Card text | 12pt at 2 or 3 columns, 11pt at 4, 10pt at 6 |
| Card and chart headings | 14pt at 2 or 3 columns, 12pt at 4, 11pt at 6 |
| Tables, source and note lines | 12pt |

## Titles

The title is the message of the slide, as a sentence: "Rasio ULN terkendali,
namun utang jangka pendek naik", not "Rasio ULN". It may take two lines
(about 150 characters); write it shorter if you can. Italics for foreign
terms are fine (`*debt service*`).

## Content budgets

Each slide carries one message, stated in its title. If the content exceeds
a budget, split the slide. Never shrink text to make it fit.

| Slide type | Budget |
|:--|:--|
| Normal text | 6 bullets, 2 lines each |
| `{.small}` | 8 bullets |
| `{.smaller}` | Dense tables and equations only, not for more bullets |
| Table, one-line cells | 10 body rows, 6 columns |
| Table, multi-line cells | 6 body rows, 5 columns |
| Figure | One per slide (or one per slot), plus a note and a source line |
| Columns (`.columns`) | Two at most, widths summing to 100% or less |
| Slot grid (`.cols`) | See "Slot grid and cards" below |
| Takeaway | One per slide, 2 lines |

## Source and note lines

Every slide with data ends with its source; add a note when the reader needs
one (definitions, cut-off date, what the colours mean).

```markdown
::: {.note}
Posisi per 30 Juni 2026; rasio memakai PDB empat kuartal terakhir.
:::

::: {.source}
Bank Indonesia & CEIC, diolah
:::
```

`.source` prints "**Sumber:** ..." at the bottom right, next to the page
number; `.note` prints "**Catatan:** ..." on the line above it, at the left.
Their position is fixed wherever they are written in the slide. Keep the
source to one line and the note to two. `label="Source"` changes the label.
Do not put sources in a takeaway or in plain text at the bottom.

## Slot grid and cards

`:::: {.cols n=N}` lays its child divs out in N equal columns, row by row.
Each child is a slot:

| Slot | Markup | Looks like |
|:--|:--|:--|
| Header card | `::: {.card title="..."}` | white box under a dark-brown header bar; `kicker="FISKAL"` adds a small capitals line above the title, `icon="img/x.png"` an icon at its left |
| Soft card | `::: {.card .soft title="..." icon="img/x.png"}` | cream box, orange border, brown heading inside, icon in an orange disc |
| Filled card | `::: {.card .fill title="..."}` | whole card in one colour with white text; `icon` puts a logo left of the heading |
| Plain card | `::: {.card}` | cream box, orange border, no heading |
| Banner | `::: {.banner}` | a bar of bold text such as "REKOMENDASI"; `.dark` for the brown gradient bar |
| Chart | `::: {.plain title="..." unit="Persen"}` | a figure with a bold centred heading and "(Persen)" under it |
| Plain | `::: {.plain}` | no box: text or a figure on the slide background |

Colours for headers, filled cards and banners: `.gold`, `.amber`, `.rust`,
`.orange`, `.tan`, `.brown`, `.dark`. Defaults: header dark brown, filled
card amber, banner gold. Use colour to group (one colour per stage or per
institution), not for decoration.

A slot with `.wide` takes a full row. `rows="2,0.3,1"` sets relative row
heights (default 1 per row, 0.5 for a `.wide` row, 0.25 for a row of
banners). `height="80%"` is the share of the slide body the grid fills
(default 80%, which leaves room for one takeaway; use 100% when the grid is
alone on the slide, with or without source and note lines).

Row heights are fixed, so cards in a row are equally tall and a figure in a
slot is scaled to fit it. Text size is set by N and cannot be changed.

Typical layouts, as in DEN decks:

| Layout | Markup |
|:--|:--|
| Two charts side by side | `{.cols height="100%"}` with two chart slots |
| Two charts over two soft cards | `{.cols rows="2.6,1" height="100%"}` |
| Three header cards, banner, three numbered gold cards | `{.cols n=3 rows="1.5,0.3,1.2" height="100%"}`, banner `.wide` |
| Two banners over a 2 x 2 of soft and filled cards | `{.cols rows="0.3,1,1" height="100%"}` |
| 3 x 2 header cards | `{.cols n=3}` |
| 4 x 2 header cards | `{.cols n=4}` |
| 6 columns + 1 row | `{.cols n=6 rows="2,1"}`, 7th slot `.wide` |

Budget per card (text in the body, the heading excluded):

| Columns | Full-height row | Half-height row |
|:--|:--|:--|
| 2 | 6 bullets or 80 words | 3 bullets or 40 words |
| 3 | 5 bullets or 60 words | 2 bullets or 30 words |
| 4 | 4 bullets or 40 words | 2 bullets or 20 words |
| 6 | 25 words | 10 words |

Slot sizes, for drawing figures at their final size:

| Columns | Slot width | Row height |
|:--|:--|:--|
| 1 | 12.3 in | 4.6 in at the default height, 5.7 in at `height="100%"` |
| 2 | 6.1 in | as above, split by `rows` minus 0.15 in per gap |
| 3 | 4.0 in | as above |
| 4 | 3.0 in | as above |
| 6 | 1.9 in | as above |

A chart heading takes about 0.5 in of the slot; a header card's bar about
0.5 in (0.7 in with a kicker).

Rules for cards:

- One `.cols` grid per slide, with at most one takeaway below it.
- A slot holds one figure or text, not both.
- No `###` headings inside a slot: in revealjs they become separate slides.
- Icons are white glyphs on a transparent background (PNG or SVG). For a
  filled card's logo any image works.
- If the text does not fit its card, cut the text. Do not raise `height`
  beyond 100% or drop to a denser layout to gain room.

## Figures

- **Code-chunk figures**: draw at the size of the slot they fill, with 12pt
  text, no title inside the figure (the slide title or the chart heading
  is the title), using fig-den with `den.AMBER_GOLD` and `den.CLAY` as the
  main pair, as in DEN decks. The format default is 12 x 4.8 in, the full
  text width. For a chart slot in a two-column grid use about 6 x 4.6 in, or
  6 x 3.3 in when soft cards sit below.
- **Figure files**: `![](fig.png){.fig-full}` when the figure is the slide;
  `{.fig-half}` when it shares the slide with text or a takeaway. Inside a
  column the slot follows the column width.
- Label the last value of a series in a box of the series colour (see
  `end_label` in `gallery.qmd`).

## Components

- **Takeaway**: `::: {.takeaway}` … `:::`. The single message of the slide,
  placed last. Not for sources or footnotes.
- **Tables**: plain pipe or grid tables. The header row is tan, every
  second row cream, rules thin; add no table markup.
- **Sizes**: only `{.small}` and `{.smaller}` on the slide header.
- **Section divider**: `## Bagian 2: Hasil {.section-divider}`.
- **Ending slide**: `## Terima kasih {.ending-slide}`.

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

If the deck is also rendered to revealjs, check the HTML too:

6. Render: `quarto render deck.qmd --to den-revealjs`
7. Check: `python _extensions/den/check-deck-html.py deck.html`
8. Fix every `ERROR` as in step 3 and look at the images in `deck_check_html/`.

The deck is not finished until both checkers report 0 errors and every slide
image has been looked at.
