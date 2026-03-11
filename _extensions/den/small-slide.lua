-- Lua filter to handle small and smaller slide classes
-- For beamer: injects font size commands at the start of slide content
-- For revealjs: CSS handles the styling via classes

-- Track which slides need font resizing
local slide_fontsize = {}

function Header(el)
  -- Handle headers with .small or .smaller class for beamer
  if el.level == 2 then
    if FORMAT:match("beamer") or FORMAT:match("latex") then
      local fontsize = nil
      
      if el.classes:includes("smaller") then
        fontsize = "smaller"
      elseif el.classes:includes("small") then
        fontsize = "small"
      end
      
      if fontsize then
        -- Remove our custom class as beamer doesn't understand it
        local new_classes = {}
        for _, c in ipairs(el.classes) do
          if c ~= "smaller" and c ~= "small" then
            table.insert(new_classes, c)
          end
        end
        el.classes = new_classes
        
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
