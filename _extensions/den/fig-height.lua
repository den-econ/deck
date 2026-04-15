-- Lua filter: cap image height for beamer output.
-- Pandoc's LaTeX writer emits height=\textheight by default when a caption
-- is present, which lets figures consume the full frame and push bullets
-- off the slide. For beamer only, set a shorter default height on any user
-- image that has a width but no explicit height. Users can still override
-- by writing {width=70% height=80%} in the source.

function Image(el)
  if not (FORMAT:match("beamer") or FORMAT:match("latex")) then
    return el
  end
  if el.attributes.width and not el.attributes.height then
    el.attributes.height = "65%"
  end
  return el
end
