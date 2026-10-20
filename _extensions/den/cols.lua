-- Lua filter for the slot grid: `:::: {.cols n=3}` lays its child divs out in
-- n equal columns, row by row. Every child is a slot:
--   ::: {.card}                    cream box with an orange border
--   ::: {.card title="Judul"}      white box under a coloured header bar;
--                                  kicker="FISKAL" adds a small line above the
--                                  title, icon="img/x.png" an icon at its left
--   ::: {.card .soft title="..."}  cream box with a brown heading inside;
--                                  icon="..." adds an icon in an orange disc
--   ::: {.card .fill title="..."}  whole card in one colour, white text;
--                                  icon="..." adds a logo left of the heading
--   ::: {.banner}                  a bar of bold text, e.g. "REKOMENDASI"
--   ::: {.plain}                   no box: text or a figure on the slide;
--                                  title="..." unit="Persen" add a chart heading
-- Colour classes for header, fill and banner: .gold .amber .rust .orange .tan
-- .brown .dark (header default dark brown, fill default amber, banner default
-- gold; a .dark banner is a brown gradient).
-- A slot with .wide takes a full row. `rows="2,1"` sets relative row heights
-- (default 1 per row, 0.5 for a .wide row, 0.25 for a row of banners) and
-- `height="80%"` the share of the slide body the grid occupies.
--
-- Rows have fixed heights, so cards in a row are equally tall and a figure in
-- a slot is scaled to fit it. Text size is fixed per n, never per slide.
--
-- A `###` heading must not be used as a card title: inside a div, revealjs
-- turns it into a separate slide.

-- Slide body below the title band (1.2in) down to the note line (6.9in), and
-- the text width between 0.5in margins, on the 13.333 x 7.5in page. revealjs
-- uses a 960 x 540px canvas, so 1in = 72px there.
local BODY_IN = 5.7
local TEXTWIDTH_IN = 12.333
local GAP_IN = 0.15
local PX_PER_IN = 72
local SLOT_BOXES = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L" }
-- Text and heading sizes in pt per number of columns
local BODY_PT = { [1] = 14, [2] = 12, [3] = 12, [4] = 11, [6] = 10 }
local HEAD_PT = { [1] = 16, [2] = 14, [3] = 14, [4] = 12, [6] = 11 }
local COLOURS = { gold = "dengold", amber = "denamber", rust = "denrust", orange = "denorange",
                  tan = "dentan", brown = "denbar", dark = "dendarkbrown" }

local function is_latex()
  return FORMAT:match("beamer") or FORMAT:match("latex")
end

local function kind(slot)
  if slot.classes:includes("banner") then return "banner" end
  if not slot.classes:includes("card") then return "plain" end
  if slot.classes:includes("fill") then return "fill" end
  if slot.classes:includes("soft") or (slot.attributes.icon and not slot.attributes.title) then return "soft" end
  if slot.attributes.title and slot.attributes.title ~= "" then return "head" end
  return "card"
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

local function all_banners(row)
  for _, slot in ipairs(row.slots) do
    if kind(slot) ~= "banner" then return false end
  end
  return true
end

local function row_shares(el, rows)
  local given = {}
  for part in (el.attributes.rows or ""):gmatch("[%d%.]+") do
    given[#given + 1] = tonumber(part)
  end
  local shares, total = {}, 0
  for i, row in ipairs(rows) do
    shares[i] = given[i] or (all_banners(row) and 0.25) or (row.wide and 0.5) or 1
    total = total + shares[i]
  end
  for i = 1, #shares do shares[i] = shares[i] / total end
  return shares
end

local function grid_share(el)
  local value = el.attributes.height and tonumber((el.attributes.height:gsub("%%", "")))
  return (value or 80) / 100
end

local function inlines(text)
  if not text or text == "" then return nil end
  local parsed = pandoc.read(text, "markdown").blocks[1]
  return parsed and parsed.content or pandoc.Inlines({ pandoc.Str(text) })
end

local function colour(slot, default)
  for class, name in pairs(COLOURS) do
    if slot.classes:includes(class) then return name end
  end
  return default
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

local function latex(inl)
  return pandoc.write(pandoc.Pandoc({ pandoc.Plain(inl) }), "latex")
end

local function size(pt)
  return string.format("\\densize{%d}", pt)
end

-- Vertical space (in) taken by everything in a slot except its content,
-- so a figure in the slot can be given the remaining height.
local function chrome_in(k, slot, head_pt)
  local line = head_pt * 1.2 / 72
  if k == "head" then return 0.32 + line + (slot.attributes.kicker and 0.2 or 0) end
  if k == "soft" or k == "fill" then return 0.3 + (slot.attributes.title and line + 0.06 or 0) end
  if k == "card" then return 0.25 end
  if k == "plain" and slot.attributes.title then return line + (slot.attributes.unit and 0.22 or 0) + 0.08 end
  return 0
end

local function latex_heading(slot, head_pt, body_pt, colour_name)
  local title = inlines(slot.attributes.title)
  if not title then return "" end
  return "{\\color{" .. colour_name .. "}\\bfseries" .. size(head_pt) .. " " .. latex(title) .. "\\par}\\vspace{0.06in}"
end

local function latex_slot(slot, box, width_share, height_in, n)
  local k = kind(slot)
  local body_pt, head_pt = BODY_PT[n] or 10, HEAD_PT[n] or 11
  local font = size(body_pt)
  local options = { string.format("width=%.4f\\textwidth", width_share),
                    string.format("height=%.3fin", height_in) }
  local before = ""
  local icon = slot.attributes.icon

  if k == "head" then
    local c = colour(slot, "denheader")
    table.insert(options, 1, "denheadcard=" .. c)
    local kicker = slot.attributes.kicker
      and ("{" .. size(body_pt - 1) .. " \\MakeUppercase{" .. latex(inlines(slot.attributes.kicker)) .. "}\\par}") or ""
    local text = kicker .. "{" .. size(head_pt) .. " " .. latex(inlines(slot.attributes.title)) .. "\\par}"
    local title
    if icon then
      title = string.format("\\begin{minipage}[c]{0.45in}\\includegraphics[width=0.45in, height=0.45in]{%s}\\end{minipage}"
        .. "\\hspace{0.12in}\\begin{minipage}[c]{\\dimexpr\\linewidth-0.6in}%s\\end{minipage}", icon, text)
    else
      title = text
    end
    options[#options + 1] = "fonttitle=\\bfseries"
    options[#options + 1] = "title={" .. title .. "}"
  elseif k == "soft" then
    table.insert(options, 1, "densoftcard")
    if icon then
      options[#options + 1] = "denicondisc={" .. icon .. "}"
      options[#options + 1] = "left=0.95in"
    end
    before = latex_heading(slot, head_pt, body_pt, "denbar")
  elseif k == "fill" then
    table.insert(options, 1, "denfillcard=" .. colour(slot, "denamber"))
    local heading = latex_heading(slot, head_pt, body_pt, "white")
    if icon and heading ~= "" then
      heading = string.format("\\includegraphics[height=0.4in]{%s}\\hspace{0.1in}", icon)
        .. "\\raisebox{0.13in}{\\color{white}\\bfseries" .. size(head_pt) .. " "
        .. latex(inlines(slot.attributes.title)) .. "}\\par\\vspace{0.04in}"
    end
    before = "\\setbeamercolor{itemize item}{fg=white}\\setbeamertemplate{itemize item}{\\textbullet}" .. heading
  elseif k == "banner" then
    if slot.classes:includes("dark") then
      table.insert(options, 1, "denbannershade")
    else
      table.insert(options, 1, "denbanner=" .. colour(slot, "dengold"))
    end
    font = "\\bfseries" .. size(head_pt + 2)
  elseif k == "card" then
    table.insert(options, 1, "dencard")
  else
    table.insert(options, 1, "denplain")
    local title = inlines(slot.attributes.title)
    if title then
      local unit = slot.attributes.unit
        and ("{\\centering" .. size(body_pt) .. " (" .. latex(inlines(slot.attributes.unit)) .. ")\\par}") or ""
      before = "{\\centering\\bfseries" .. size(head_pt) .. " " .. latex(title) .. "\\par}" .. unit .. "\\vspace{0.08in}"
    end
  end

  local image_in = height_in - chrome_in(k, slot, head_pt)
  local content = unfloat(slot.content):walk({
    Image = function(img)
      img.attributes.width = "100%"
      img.attributes.height = string.format("%.2fin", image_in)
      return img
    end,
  })

  options[#options + 1] = "fontupper=" .. font
  local blocks = pandoc.List({ pandoc.RawBlock("latex",
    "\\begin{lrbox}{\\denslot" .. box .. "}\\begin{tcolorbox}[" .. table.concat(options, ", ") .. "]"
    .. before .. (only_image(content) and "\\centering" or "")) })
  blocks:extend(content)
  blocks:insert(pandoc.RawBlock("latex", "\\end{tcolorbox}\\end{lrbox}"))
  return blocks
end

local function latex_grid(el, n, rows, shares)
  local gap_share = GAP_IN / TEXTWIDTH_IN
  -- Rounded down, so a row never comes out wider than the text and wraps.
  local column_share = math.floor((1 - (n - 1) * gap_share) / n * 1000) / 1000
  local rows_in = grid_share(el) * BODY_IN - (#rows - 1) * GAP_IN

  local blocks, lines, used = pandoc.List(), {}, 0
  for i, row in ipairs(rows) do
    local boxes = {}
    for _, slot in ipairs(row.slots) do
      used = used + 1
      if used > #SLOT_BOXES then
        error("cols.lua: a .cols grid holds at most " .. #SLOT_BOXES .. " slots")
      end
      local box = SLOT_BOXES[used]
      blocks:extend(latex_slot(slot, box, row.wide and 1 or column_share, shares[i] * rows_in, n))
      boxes[#boxes + 1] = "\\usebox{\\denslot" .. box .. "}"
    end
    lines[#lines + 1] = "\\noindent" .. table.concat(boxes, string.format("\\hspace{%.4f\\textwidth}", gap_share))
  end
  blocks:insert(pandoc.RawBlock("latex",
    "\\par" .. table.concat(lines, string.format("\\par\\nointerlineskip\\vspace{%.2fin}", GAP_IN)) .. "\\par"))
  return blocks
end

-- === revealjs ===

local function div(content, class)
  return pandoc.Div(content, pandoc.Attr("", { class }))
end

local function icon_image(path, class)
  return pandoc.Image({}, path, "", pandoc.Attr("", { class }))
end

local function html_slot(slot)
  local k = kind(slot)
  local content = unfloat(slot.content)
  if only_image(content) then
    content = pandoc.List({ pandoc.Plain(content[1].content) })
    slot.classes:insert("fig")
  end
  local title = inlines(slot.attributes.title)
  local icon = slot.attributes.icon
  local body = div(content, "card-body")

  if k == "head" then
    local text = pandoc.List()
    if slot.attributes.kicker then text:insert(div({ pandoc.Plain(inlines(slot.attributes.kicker)) }, "card-kicker")) end
    text:insert(div({ pandoc.Plain(title) }, "card-title-text"))
    local head = pandoc.List()
    if icon then head:insert(pandoc.Plain({ icon_image(icon, "card-icon") })) end
    head:insert(div(text, "card-title-stack"))
    slot.classes:insert("titled")
    content = pandoc.List({ div(head, "card-title"), body })
  elseif k == "soft" or k == "fill" then
    slot.classes:insert(k)
    local inner = pandoc.List()
    if title then
      local heading = pandoc.List()
      if icon and k == "fill" then heading:insert(icon_image(icon, "card-logo")) end
      heading:extend(title)
      inner:insert(div({ pandoc.Plain(heading) }, "card-heading"))
    end
    inner:insert(body)
    content = pandoc.List()
    if icon and k == "soft" then content:insert(div({ pandoc.Plain({ icon_image(icon, "card-icon") }) }, "card-disc")) end
    content:insert(div(inner, "card-main"))
  elseif k == "plain" and title then
    slot.classes:insert("charted")
    local head = pandoc.List({ div({ pandoc.Plain(title) }, "chart-title") })
    if slot.attributes.unit then
      local unit = pandoc.Inlines({ pandoc.Str("(") })
      unit:extend(inlines(slot.attributes.unit))
      unit:insert(pandoc.Str(")"))
      head:insert(div({ pandoc.Plain(unit) }, "chart-unit"))
    end
    content = pandoc.List({ div(head, "chart-head"), body })
  else
    content = pandoc.List({ body })
  end
  for _, name in ipairs({ "title", "kicker", "icon", "unit" }) do slot.attributes[name] = nil end
  slot.content = content
  return slot
end

local function html_grid(el, n, rows, shares)
  local tracks = {}
  for i = 1, #shares do tracks[i] = string.format("%.4ffr", shares[i]) end
  el.classes:insert("n" .. n)
  el.attributes.style = string.format("--n: %d; height: %dpx; grid-template-rows: %s;",
    n, math.floor(grid_share(el) * BODY_IN * PX_PER_IN), table.concat(tracks, " "))
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
