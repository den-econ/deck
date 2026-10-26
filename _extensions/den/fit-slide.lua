-- Lua filter (revealjs only) for slides with a `.cols .fit` grid: wraps the
-- content of the slide in a `.den-body` div of the height of the slide body,
-- and CSS centres it vertically. A takeaway that is not pinned stays in the
-- wrapper, so grid and takeaway are centred together, as in DEN decks.
-- Source and note lines, speaker notes and a pinned takeaway stay outside,
-- at their fixed positions; with a pinned takeaway the body ends above it.
-- Beamer has fixed row heights and no such wrapper, so this filter does
-- nothing there.

local function ends_slide(block)
  if block.t == "Header" then return block.level <= 2 end
  return block.t == "HorizontalRule"
end

local function has(block, class)
  return block.t == "Div" and block.classes:includes(class)
end

local function stays_outside(block)
  return has(block, "source") or has(block, "note") or has(block, "notes")
    or (has(block, "takeaway") and block.classes:includes("pin"))
end

local function has_fit_grid(blocks)
  for _, block in ipairs(blocks) do
    if has(block, "cols") and block.classes:includes("fit") then return true end
  end
  return false
end

local function wrap(blocks)
  local inside, outside, pinned = pandoc.List(), pandoc.List(), false
  for _, block in ipairs(blocks) do
    if stays_outside(block) then
      outside:insert(block)
      if has(block, "takeaway") then pinned = true end
    else
      inside:insert(block)
    end
  end
  local classes = { "den-body" }
  if pinned then classes[#classes + 1] = "pinned" end
  local result = pandoc.List({ pandoc.Div(inside, pandoc.Attr("", classes)) })
  result:extend(outside)
  return result
end

function Pandoc(doc)
  if FORMAT:match("beamer") or FORMAT:match("latex") then
    return nil
  end
  local blocks = pandoc.List()
  local i = 1
  while i <= #doc.blocks do
    local block = doc.blocks[i]
    blocks:insert(block)
    i = i + 1
    if block.t == "Header" and block.level == 2 then
      local j = i
      while j <= #doc.blocks and not ends_slide(doc.blocks[j]) do j = j + 1 end
      local content = pandoc.List({ table.unpack(doc.blocks, i, j - 1) })
      blocks:extend(has_fit_grid(content) and wrap(content) or content)
      i = j
    end
  end
  doc.blocks = blocks
  return doc
end
