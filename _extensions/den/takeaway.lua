-- Lua filter for the takeaway box: one full-width brown bar carrying the
-- single message of the slide.
-- Syntax:
--   ::: {.takeaway}
--   The message, at most two lines.
--   :::
-- The bar follows the content above it. With `.pin` its bottom edge is fixed
-- 0.6in above the foot of the page, whatever the content above it, so the
-- takeaway sits at the same height on every slide.
-- For beamer the div becomes the `dentakeaway` environment defined in
-- beamer-header.tex (inside a textblock* when pinned). For revealjs the div
-- passes through and CSS styles it via the .takeaway and .pin classes.

function Div(el)
  if not el.classes:includes("takeaway") then
    return nil
  end
  if FORMAT:match("beamer") or FORMAT:match("latex") then
    local pinned = el.classes:includes("pin")
    local open = pinned
      and "\\begin{textblock*}{\\denTextWidth}[0,1](0.5in,6.9in)\\begin{dentakeaway}[nobeforeafter]"
      or "\\begin{dentakeaway}"
    local close = pinned and "\\end{dentakeaway}\\end{textblock*}" or "\\end{dentakeaway}"
    local blocks = pandoc.List({ pandoc.RawBlock("latex", open) })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock("latex", close))
    return blocks
  end
  return el
end
