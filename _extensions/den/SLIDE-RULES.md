# Rules for writing den-beamer slides

Read this before writing or editing a `.qmd` that renders with `den-beamer`.
`gallery.qmd` in the den-econ/deck repo shows every pattern below; copy from it.

## What this format is for

Use den-beamer for technical decks: equations, regression tables, figures
made in code. A slide is a title plus one of: bullets, an equation with its
definitions, one table, or one figure.

Do not build card layouts (rows of coloured boxes, icon tiles, 2x2 grids of
panels). If a slide needs cards, the deck belongs in pptx, not here.

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
| Columns | Two at most, widths summing to 100% or less |
| Takeaway | One per slide, 2 lines |

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
- `###` headings inside columns to fake boxes.

## Mandatory check before finishing

1. Render: `quarto render deck.qmd --to den-beamer`
2. Check: `python _extensions/den/check-deck.py deck.pdf`
3. Fix every `ERROR` by cutting or splitting content, then repeat 1 and 2.
4. Open the slide images the checker writes (`deck_check/`) and look at each
   one. The checker cannot judge crowding, figure legibility or alignment.
5. Review each `warning`; fix it or be able to say why it is acceptable.

The deck is not finished until the checker reports 0 errors and every slide
image has been looked at.
