-- Lua filter for the slide footer lines of the DEN master:
--   ::: {.source}
--   Bank Indonesia & CEIC, diolah
--   :::
-- prints "Sumber: Bank Indonesia & CEIC, diolah" on the bottom line of the
-- slide, right-aligned against the page number, and
--   ::: {.note}
--   Posisi per 30 Juni 2026
--   :::
-- prints "Catatan: ..." on the line above it, at the left margin.
-- `label="Source"` replaces the bold label. The div may sit anywhere in the
-- slide; its position on the page is fixed.
-- For beamer the div becomes \densource or \dennote (beamer-header.tex). For
-- revealjs the label is added and CSS places the div via its class.

local LABELS = { source = "Sumber", note = "Catatan" }

local function role(el)
  for class in pairs(LABELS) do
    if el.classes:includes(class) then return class end
  end
  return nil
end

local function as_latex(blocks)
  local paragraphs = pandoc.List()
  for _, block in ipairs(blocks) do
    local text = pandoc.write(pandoc.Pandoc({ block }), "latex"):gsub("%s+$", "")
    paragraphs:insert(text)
  end
  return table.concat(paragraphs, "\\\\ ")
end

function Div(el)
  local r = role(el)
  if not r then return nil end
  local label = el.attributes.label or LABELS[r]

  if FORMAT:match("beamer") or FORMAT:match("latex") then
    local command = r == "source" and "\\densource" or "\\dennote"
    return pandoc.RawBlock("latex", string.format("%s{%s}{%s}", command, label, as_latex(el.content)))
  end

  el.attributes.label = nil
  local first = el.content[1]
  if first and (first.t == "Para" or first.t == "Plain") then
    first.content:insert(1, pandoc.Space())
    first.content:insert(1, pandoc.Strong({ pandoc.Str(label .. ":") }))
  end
  return el
end
