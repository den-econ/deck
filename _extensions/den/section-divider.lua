-- Lua filter to handle section divider slides for beamer and revealjs
-- Syntax: `## Part 2: Results {.section-divider}`
-- Renders divider.jpg (or `background-image="..."`) full page, with the
-- heading text overlaid middle-left in white. For revealjs the header keeps
-- its class and CSS places the text; the background is fitted to the canvas.

function Header(el)
  if el.level == 2 and el.classes:includes("section-divider") then
    local bg_image = el.attributes["background-image"] or "divider.jpg"
    if FORMAT:match("beamer") or FORMAT:match("latex") then
      local title = pandoc.utils.stringify(el.content)
      return pandoc.RawBlock("latex", string.format([[
\end{frame}
\begin{frame}[plain]
\denDividerFrame{%s}{%s}
]], title, bg_image))
    end
    el.attributes["background-image"] = bg_image
    el.attributes["background-size"] = el.attributes["background-size"] or "contain"
    el.attributes["background-color"] = el.attributes["background-color"] or "white"
    return el
  end
  return el
end
