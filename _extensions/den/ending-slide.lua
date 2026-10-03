-- Lua filter to handle ending slide for beamer and revealjs
-- Syntax: `## Terima kasih {.ending-slide}`
-- The heading text is rendered centred over end.jpg. If the heading is
-- empty, it defaults to "Thank you" (user can write "Terima kasih", etc.).
-- `background-image="..."` selects another picture.
-- For backward compatibility, an empty `::: {.ending-slide} :::` div after
-- the header is still accepted and silently dropped.

function Header(el)
  if el.level == 2 and el.classes:includes("ending-slide") then
    local text = pandoc.utils.stringify(el.content)
    if text == "" then text = "Thank you" end
    local bg_image = el.attributes["background-image"] or "end.jpg"

    if FORMAT:match("beamer") or FORMAT:match("latex") then
      return pandoc.RawBlock("latex", string.format([[
\end{frame}
\begin{frame}[plain]
\begin{tikzpicture}[remember picture, overlay]
\node[anchor=center] at (current page.center) {
\includegraphics[width=\paperwidth, height=\paperheight, keepaspectratio=false]{%s}
};
\node[anchor=center, text=denendtext, align=center] at (current page.center) {\Huge\bfseries %s};
\end{tikzpicture}
]], bg_image, text))
    else
      el.attributes["background-image"] = bg_image
      if not el.attributes["background-size"] then
        el.attributes["background-size"] = "cover"
      end
      -- Reveal.js: ensure the heading has visible text even if user left it blank
      if pandoc.utils.stringify(el.content) == "" then
        el.content = {pandoc.Str("Thank"), pandoc.Space(), pandoc.Str("you")}
      end
      return el
    end
  end
  return el
end

function Div(el)
  -- Backward compatibility: a standalone `::: {.ending-slide} :::` div is
  -- no longer required, but if present we drop it silently in both formats.
  if el.classes:includes("ending-slide") then
    return {}
  end
  return el
end
