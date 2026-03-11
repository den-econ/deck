-- Lua filter to handle ending slide for beamer and revealjs
-- For beamer: creates a plain frame with tikz full-page background (via Div)
-- For revealjs: uses Header with ending-slide class (CSS handles styling)

function Header(el)
  -- For beamer, remove the ending-slide header (we use Div instead)
  if el.level == 2 and el.classes:includes("ending-slide") then
    if FORMAT:match("beamer") or FORMAT:match("latex") then
      return {}
    end
  end
  return el
end

function Div(el)
  if el.classes:includes("ending-slide") then
    if FORMAT:match("beamer") or FORMAT:match("latex") then
      -- For beamer, replace with raw LaTeX
      -- First close any open frame, then create the ending frame
      local bg_image = el.attributes["background-image"] or "end.png"
      return pandoc.RawBlock("latex", string.format([[
\end{frame}
\begin{frame}[plain]
\begin{tikzpicture}[remember picture, overlay]
\node[anchor=center] at (current page.center) {
\includegraphics[width=\paperwidth, height=\paperheight]{%s}
};
\end{tikzpicture}
]], bg_image))
    else
      -- For revealjs, remove the Div (we use Header instead)
      return {}
    end
  end
  return el
end
