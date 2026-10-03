-- Lua filter for the takeaway box: one full-width brown bar carrying the
-- single message of the slide.
-- Syntax:
--   ::: {.takeaway}
--   The message, at most two lines.
--   :::
-- For beamer the div becomes the `dentakeaway` environment defined in
-- beamer-header.tex. For revealjs the div passes through and CSS styles it
-- via the .takeaway class.

function Div(el)
  if not el.classes:includes("takeaway") then
    return nil
  end
  if FORMAT:match("beamer") or FORMAT:match("latex") then
    local blocks = pandoc.List({ pandoc.RawBlock("latex", "\\begin{dentakeaway}") })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock("latex", "\\end{dentakeaway}"))
    return blocks
  end
  return el
end
