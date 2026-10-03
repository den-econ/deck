-- Lua filter to handle small and smaller slide classes
-- For beamer: injects font size commands at the start of slide content
-- For revealjs: CSS handles the styling via classes
--
-- Also drops the beamer `shrink` frame option. Shrink rescales each frame by
-- a different factor, so text size differs from slide to slide and the frame
-- no longer fills the text width. Overfull slides must be split instead.

-- Track which slides need font resizing
local slide_fontsize = {}

local function without(classes, dropped)
  return classes:filter(function(c) return not dropped[c] end)
end

function Header(el)
  -- Handle headers with .small or .smaller class for beamer
  if el.level == 2 then
    if FORMAT:match("beamer") or FORMAT:match("latex") then
      if el.classes:includes("shrink") then
        io.stderr:write(string.format(
          "[den] '.shrink' ignored on slide \"%s\": use .small/.smaller or split the slide.\n",
          pandoc.utils.stringify(el.content)))
        el.classes = without(el.classes, { shrink = true })
      end

      local fontsize = nil

      if el.classes:includes("smaller") then
        fontsize = "smaller"
      elseif el.classes:includes("small") then
        fontsize = "small"
      end

      if fontsize then
        -- Remove our custom class as beamer doesn't understand it
        el.classes = without(el.classes, { small = true, smaller = true })

        -- Store the fontsize for this header's identifier
        local id = el.identifier or pandoc.utils.stringify(el.content)
        slide_fontsize[id] = fontsize
      end
    end
    -- For revealjs, keep the classes as-is (CSS will handle them)
  end
  return el
end

function Pandoc(doc)
  if not (FORMAT:match("beamer") or FORMAT:match("latex")) then
    return doc
  end

  local new_blocks = {}
  local i = 1

  while i <= #doc.blocks do
    local block = doc.blocks[i]
    table.insert(new_blocks, block)

    -- Check if this is a level 2 header that needs font resizing
    if block.t == "Header" and block.level == 2 then
      local id = block.identifier or pandoc.utils.stringify(block.content)
      local fontsize = slide_fontsize[id]

      if fontsize then
        -- Insert font size command right after the header
        if fontsize == "smaller" then
          table.insert(new_blocks, pandoc.RawBlock("latex", "\\footnotesize"))
        elseif fontsize == "small" then
          table.insert(new_blocks, pandoc.RawBlock("latex", "\\small"))
        end
      end
    end

    i = i + 1
  end

  doc.blocks = new_blocks
  return doc
end
