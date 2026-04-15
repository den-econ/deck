-- Lua filter to handle section divider slides for beamer and revealjs
-- Syntax: `## Part 2: Results {.section-divider background-image="divider.png"}`
-- Renders a full-page background image with the heading text overlaid
-- middle-left in white. For revealjs, the header passes through and CSS
-- handles the layout via the .section-divider class.

function Header(el)
  if el.level == 2 and el.classes:includes("section-divider") then
    if FORMAT:match("beamer") or FORMAT:match("latex") then
      local title = pandoc.utils.stringify(el.content)
      local bg_image = el.attributes["background-image"] or "title.png"
      return pandoc.RawBlock("latex", string.format([[
\end{frame}
\begin{frame}[plain]
\denDividerFrame{%s}{%s}
]], title, bg_image))
    else
      return el
    end
  end
  return el
end
