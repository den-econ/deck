-- Lua filter: cap image height for beamer output.
-- Pandoc's LaTeX writer emits height=\textheight by default when a caption
-- is present, which lets figures consume the full frame and push bullets
-- off the slide. For beamer only, set a shorter default height on any user
-- image that has a width but no explicit height. Users can still override
-- by writing {width=70% height=80%} in the source.
--
-- Figure slots give a figure a fixed box so it cannot push content off the
-- slide. Aspect ratio is kept, so the figure fills whichever bound binds.
--   {.fig-full}  the figure is the slide: title, figure, at most one line
--   {.fig-half}  the figure shares the slide vertically with text or a takeaway
-- Inside a column the width is the column width.

local slots = {
  ["fig-full"] = { width = "100%", height = "68%" },
  ["fig-half"] = { width = "100%", height = "42%" },
}

function Image(el)
  if not (FORMAT:match("beamer") or FORMAT:match("latex")) then
    return el
  end
  for class, box in pairs(slots) do
    if el.classes:includes(class) then
      el.attributes.width = box.width
      el.attributes.height = box.height
      return el
    end
  end
  if el.attributes.width and not el.attributes.height then
    el.attributes.height = "65%"
  end
  return el
end
