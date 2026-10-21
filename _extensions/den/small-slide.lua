-- Lua filter to set the text size of a slide
-- Text-only slides (bullets, equations) get the large size, 16pt. Slides
-- with a figure, a table or a slot grid keep the normal size, 14pt.
-- `{.normal}` keeps a text-only slide at 14pt; `{.small}` (12pt) and
-- `{.smaller}` (11pt) are set by hand and always win.
-- For beamer: injects font size commands at the start of slide content
-- For revealjs: adds the size class to the header; CSS handles the styling
--
-- Also drops the beamer `shrink` frame option. Shrink rescales each frame by
-- a different factor, so text size differs from slide to slide and the frame
-- no longer fills the text width. Overfull slides must be split instead.

local densize = { large = 16, small = 12, smaller = 11 }

-- Slides drawn by other filters, whose text size is fixed
local special = { ["section-divider"] = true, ["ending-slide"] = true }

-- Code cells that Quarto turns into a figure after this filter has run
local diagram = { mermaid = true, dot = true, ["{mermaid}"] = true, ["{dot}"] = true }

local function is_beamer()
  return FORMAT:match("beamer") or FORMAT:match("latex")
end

local function without(classes, dropped)
  return classes:filter(function(c) return not dropped[c] end)
end

local function ends_slide(block)
  if block.t == "Header" then return block.level <= 2 end
  if block.t == "HorizontalRule" then return true end
  -- section-divider.lua and ending-slide.lua have already replaced their
  -- headers with a new frame in beamer
  return block.t == "RawBlock" and block.text:match("^%s*\\end{frame}") ~= nil
end

local function has_visual(blocks)
  local found = false
  local function mark() found = true end
  pandoc.Div(blocks):walk({
    Image = mark,
    Figure = mark,
    Table = mark,
    Div = function(el)
      if el.classes:includes("cols") or el.classes:includes("cell-output-display") then mark() end
    end,
    CodeBlock = function(el)
      if el.classes:find_if(function(c) return diagram[c] end) then mark() end
    end,
    RawBlock = function(el)
      if el.text:match("includegraphics") or el.text:match("tikzpicture")
          or el.text:match("<img") or el.text:match("<svg") or el.text:match("<iframe") then
        mark()
      end
    end,
  })
  return found
end

local function slide_size(header, content)
  if header.classes:includes("smaller") then return "smaller" end
  if header.classes:includes("small") then return "small" end
  if header.classes:includes("normal") then return nil end
  if header.classes:find_if(function(c) return special[c] end) then return nil end
  if has_visual(content) then return nil end
  return "large"
end

local function warn_shrink(header)
  io.stderr:write(string.format(
    "[den] '.shrink' ignored on slide \"%s\": use .small/.smaller or split the slide.\n",
    pandoc.utils.stringify(header.content)))
end

function Pandoc(doc)
  local new_blocks = {}
  local i = 1

  while i <= #doc.blocks do
    local block = doc.blocks[i]
    table.insert(new_blocks, block)

    if block.t == "Header" and block.level == 2 then
      local j = i + 1
      while j <= #doc.blocks and not ends_slide(doc.blocks[j]) do j = j + 1 end
      local content = pandoc.List({ table.unpack(doc.blocks, i + 1, j - 1) })
      local fontsize = slide_size(block, content)

      if is_beamer() then
        if block.classes:includes("shrink") then warn_shrink(block) end
        -- Remove our custom classes as beamer doesn't understand them
        block.classes = without(block.classes, { small = true, smaller = true, normal = true, shrink = true })
        if fontsize then
          table.insert(new_blocks, pandoc.RawBlock("latex", string.format("\\densize{%d}", densize[fontsize])))
        end
      elseif fontsize == "large" then
        block.classes:insert("large")
      end
    end

    i = i + 1
  end

  doc.blocks = new_blocks
  return doc
end
