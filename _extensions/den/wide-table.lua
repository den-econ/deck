-- Lua filter for full-width tables:
--   ::: {.wide-table widths="2,6,4" row-height="0.5"}
--   | ... pipe or grid table ... |
--   :::
-- The table spans the whole text width. `widths` sets relative column widths;
-- without it, widths written in the table itself (dash counts of a long pipe
-- table, a grid table's column widths) are scaled to the full width, and a
-- table without any gets widths in proportion to its longest cell per column.
-- `row-height` (inches) is the minimum height of a body row; text stays at
-- the top of the cell, as in DEN decks.
-- For beamer the widths become pandoc's p{} columns and the row height a
-- strut in the first cell of each row; for revealjs CSS reads the widths
-- from the colgroup pandoc writes and the row height from --row-h.

local MIN_SHARE = 0.08
local PX_PER_IN = 72

local function numbers(text)
  local values = {}
  for part in (text or ""):gmatch("[%d%.]+") do
    values[#values + 1] = tonumber(part)
  end
  return values
end

local function normalise(shares)
  local total = 0
  for _, s in ipairs(shares) do total = total + s end
  for i = 1, #shares do shares[i] = shares[i] / total end
  return shares
end

local function longest_cells(tbl)
  local longest = {}
  local function measure(rows)
    for _, row in ipairs(rows) do
      for i, cell in ipairs(row.cells) do
        local length = utf8.len(pandoc.utils.stringify(cell.contents)) or 0
        longest[i] = math.max(longest[i] or 0, length)
      end
    end
  end
  measure(tbl.head.rows)
  for _, body in ipairs(tbl.bodies) do measure(body.body) end
  return longest
end

local function column_shares(tbl, given)
  local n = #tbl.colspecs
  local shares = {}
  if #given > 0 then
    for i = 1, n do shares[i] = given[i] or 1 end
    return normalise(shares)
  end
  local written = true
  for i, spec in ipairs(tbl.colspecs) do
    shares[i] = spec[2]
    if not shares[i] or shares[i] == 0 then written = false end
  end
  if written then return normalise(shares) end
  shares = longest_cells(tbl)
  for i = 1, n do shares[i] = math.max(shares[i] or 1, 1) end
  normalise(shares)
  for i = 1, n do shares[i] = math.max(shares[i], MIN_SHARE) end
  return normalise(shares)
end

local function strut(cell, height_in)
  local raw = pandoc.RawInline("latex",
    string.format("\\rule[-%.2fin]{0pt}{%.2fin}", height_in - 0.13, height_in))
  local first = cell.contents[1]
  if first and (first.t == "Plain" or first.t == "Para") then
    first.content:insert(1, raw)
  else
    cell.contents:insert(1, pandoc.Plain({ raw }))
  end
end

local function widen(tbl, el)
  local shares = column_shares(tbl, numbers(el.attributes.widths))
  for i, spec in ipairs(tbl.colspecs) do
    tbl.colspecs[i] = { spec[1], shares[i] }
  end
  local row_in = tonumber(el.attributes["row-height"])
  if row_in and (FORMAT:match("beamer") or FORMAT:match("latex")) then
    for _, body in ipairs(tbl.bodies) do
      for _, row in ipairs(body.body) do
        if row.cells[1] then strut(row.cells[1], row_in) end
      end
    end
  end
  return tbl
end

function Div(el)
  if not el.classes:includes("wide-table") then
    return nil
  end
  el.content = el.content:walk({ Table = function(tbl) return widen(tbl, el) end })
  if FORMAT:match("beamer") or FORMAT:match("latex") then
    return el.content
  end
  local row_in = tonumber(el.attributes["row-height"])
  el.attributes.widths, el.attributes["row-height"] = nil, nil
  if row_in then
    el.attributes.style = string.format("--row-h: %dpx;", math.floor(row_in * PX_PER_IN))
  end
  return el
end
