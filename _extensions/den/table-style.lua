-- Lua filter: DEN table style for beamer.
-- Sets every header cell in bold brown. Row padding and rule colours are
-- set once in beamer-header.tex, so tables need no per-table markup.
-- For revealjs the table passes through and CSS handles the styling.

local function style_header_cell(cell)
  local first = cell.contents[1]
  if first and (first.t == "Plain" or first.t == "Para") then
    first.content:insert(1, pandoc.RawInline("latex", "\\dentablehead{}"))
  end
  return cell
end

function Table(el)
  if not (FORMAT:match("beamer") or FORMAT:match("latex")) then
    return el
  end
  for _, row in ipairs(el.head.rows) do
    for i, cell in ipairs(row.cells) do
      row.cells[i] = style_header_cell(cell)
    end
  end
  return el
end
