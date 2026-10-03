-- Lua filter for the slot grid: `:::: {.cols n=3}` lays its child divs out in
-- n equal columns, row by row. Every child is a slot:
--   ::: {.card title="Judul"}   boxed, with an optional title bar
--   ::: {.card .gold}           title bar in gold; .dark for dark brown
--   ::: {.plain}                no box: text or a figure on the slide background
-- A slot with .wide takes a full row. `rows="2,1"` sets relative row heights
-- (default 1 per row, 0.5 for a .wide row) and `height="80%"` the share of
-- the slide body the grid occupies.
--
-- Rows have fixed heights, so cards in a row are equally tall and a figure in
-- a slot is scaled to fit it. Text size is fixed per n, never per slide.
--
-- A `###` heading must not be used as a card title: inside a div, revealjs
-- turns it into a separate slide.

local BODY_CM = 6.5          -- beamer: height of the slide body below the title
local TEXTWIDTH_CM = 14.0    -- beamer: 16:9 text width
local GAP_CM = 0.22
local BODY_PX = 520          -- revealjs: height of the slide body below the title
local SLOT_BOXES = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L" }
local FONT = { [2] = "\\small", [3] = "\\footnotesize", [4] = "\\scriptsize", [6] = "\\scriptsize" }
local TITLE_COLOURS = { gold = "dengold", dark = "dendarkbrown" }

local function is_latex()
  return FORMAT:match("beamer") or FORMAT:match("latex")
end

local function grid_rows(el, n)
  local rows, current = {}, {}
  for _, child in ipairs(el.content) do
    if child.t == "Div" then
      if child.classes:includes("wide") then
        if #current > 0 then rows[#rows + 1] = { slots = current }; current = {} end
        rows[#rows + 1] = { slots = { child }, wide = true }
      else
        current[#current + 1] = child
        if #current == n then rows[#rows + 1] = { slots = current }; current = {} end
      end
    end
  end
  if #current > 0 then rows[#rows + 1] = { slots = current } end
  return rows
end

local function row_shares(el, rows)
  local given = {}
  for part in (el.attributes.rows or ""):gmatch("[%d%.]+") do
    given[#given + 1] = tonumber(part)
  end
  local shares, total = {}, 0
  for i, row in ipairs(rows) do
    shares[i] = given[i] or (row.wide and 0.5 or 1)
    total = total + shares[i]
  end
  for i = 1, #shares do shares[i] = shares[i] / total end
  return shares
end

local function grid_share(el)
  local value = el.attributes.height and tonumber((el.attributes.height:gsub("%%", "")))
  return (value or 80) / 100
end

local function title_inlines(slot)
  local title = slot.attributes.title
  if not title or title == "" then return nil end
  local parsed = pandoc.read(title, "markdown").blocks[1]
  return parsed and parsed.content or pandoc.Inlines({ pandoc.Str(title) })
end

local function title_colour(slot)
  for class, colour in pairs(TITLE_COLOURS) do
    if slot.classes:includes(class) then return colour end
  end
  return "denbrown"
end

-- Figures cannot float inside a slot, so a captioned figure is reduced to its image.
local function unfloat(blocks)
  return blocks:walk({
    Figure = function(fig)
      local images = pandoc.List()
      fig:walk({ Image = function(img) images:insert(img) end })
      return pandoc.Plain(images)
    end,
  })
end

local function only_image(blocks)
  return #blocks == 1 and (blocks[1].t == "Para" or blocks[1].t == "Plain")
    and #blocks[1].content == 1 and blocks[1].content[1].t == "Image"
end

-- === beamer ===

local function latex_slot(slot, box, width_share, height_cm, font)
  local is_card = slot.classes:includes("card")
  local title = is_card and title_inlines(slot)
  local options = { is_card and "dencard" or "denplain",
                    string.format("width=%.4f\\textwidth", width_share),
                    string.format("height=%.3fcm", height_cm),
                    "fontupper=" .. font }
  local padding_cm = 0
  if is_card then padding_cm = 0.4 end
  if title then
    local text = pandoc.write(pandoc.Pandoc({ pandoc.Plain(title) }), "latex")
    options[#options + 1] = "dencardtitle=" .. title_colour(slot)
    options[#options + 1] = "fonttitle=" .. font .. "\\bfseries"
    options[#options + 1] = "title={\\strut " .. text .. "}"
    padding_cm = 0.95
  end

  local content = unfloat(slot.content):walk({
    Image = function(img)
      img.attributes.width = "100%"
      img.attributes.height = string.format("%.2fcm", height_cm - padding_cm)
      return img
    end,
  })

  local blocks = pandoc.List({ pandoc.RawBlock("latex",
    "\\begin{lrbox}{\\denslot" .. box .. "}\\begin{tcolorbox}[" .. table.concat(options, ", ") .. "]"
    .. (only_image(content) and "\\centering" or "")) })
  blocks:extend(content)
  blocks:insert(pandoc.RawBlock("latex", "\\end{tcolorbox}\\end{lrbox}"))
  return blocks
end

local function latex_grid(el, n, rows, shares)
  local gap_share = GAP_CM / TEXTWIDTH_CM
  -- Rounded down, so a row never comes out wider than the text and wraps.
  local column_share = math.floor((1 - (n - 1) * gap_share) / n * 1000) / 1000
  local rows_cm = grid_share(el) * BODY_CM - (#rows - 1) * GAP_CM
  local font = FONT[n] or "\\scriptsize"

  local blocks, lines, used = pandoc.List(), {}, 0
  for i, row in ipairs(rows) do
    local boxes = {}
    for _, slot in ipairs(row.slots) do
      used = used + 1
      if used > #SLOT_BOXES then
        error("cols.lua: a .cols grid holds at most " .. #SLOT_BOXES .. " slots")
      end
      local box = SLOT_BOXES[used]
      blocks:extend(latex_slot(slot, box, row.wide and 1 or column_share, shares[i] * rows_cm, font))
      boxes[#boxes + 1] = "\\usebox{\\denslot" .. box .. "}"
    end
    lines[#lines + 1] = "\\noindent" .. table.concat(boxes, string.format("\\hspace{%.4f\\textwidth}", gap_share))
  end
  blocks:insert(pandoc.RawBlock("latex",
    "\\par" .. table.concat(lines, string.format("\\par\\nointerlineskip\\vspace{%.2fcm}", GAP_CM)) .. "\\par"))
  return blocks
end

-- === revealjs ===

local function html_slot(slot)
  local content = unfloat(slot.content)
  if only_image(content) then
    content = pandoc.List({ pandoc.Plain(content[1].content) })
    slot.classes:insert("fig")
  end
  local title = slot.classes:includes("card") and title_inlines(slot)
  if title then
    slot.attributes.title = nil
    slot.classes:insert("titled")
    content = pandoc.List({
      pandoc.Div({ pandoc.Plain(title) }, pandoc.Attr("", { "card-title" })),
      pandoc.Div(content, pandoc.Attr("", { "card-body" })),
    })
  end
  slot.content = content
  return slot
end

local function html_grid(el, n, rows, shares)
  local tracks = {}
  for i = 1, #shares do tracks[i] = string.format("%.4ffr", shares[i]) end
  el.classes:insert("n" .. n)
  el.attributes.style = string.format("--n: %d; height: %dpx; grid-template-rows: %s;",
    n, math.floor(grid_share(el) * BODY_PX), table.concat(tracks, " "))
  el.attributes.n, el.attributes.rows, el.attributes.height = nil, nil, nil
  local slots = pandoc.List()
  for _, row in ipairs(rows) do
    for _, slot in ipairs(row.slots) do slots:insert(html_slot(slot)) end
  end
  el.content = slots
  return el
end

function Div(el)
  if not el.classes:includes("cols") then
    return nil
  end
  local n = tonumber(el.attributes.n) or 2
  local rows = grid_rows(el, n)
  local shares = row_shares(el, rows)
  if is_latex() then
    return latex_grid(el, n, rows, shares)
  end
  return html_grid(el, n, rows, shares)
end
