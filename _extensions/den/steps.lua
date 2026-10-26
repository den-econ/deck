-- Lua filter for a sequence of numbered steps: bars of equal height, one under
-- the other, each indented a little further than the one above, all ending
-- at the right margin.
-- Syntax:
--   :::: {.steps height="80%"}
--   ::: {.step title="MRV dulu"}
--   One or two lines of explanation.
--   :::
--   ::: {.step title="Harga karbon domestik"}
--   ...
--   :::
--   ::::
-- Steps are numbered 1, 2, ... in a white disc. Colours run gold, amber,
-- brown, dark, then repeat; a colour class on a step (.gold .amber .rust
-- .orange .tan .brown .dark) overrides it. `height` is the share of the slide
-- body the steps fill (default 80%, which leaves room for one takeaway).
-- For beamer each step is a `denstep` tcolorbox (beamer-header.tex); for
-- revealjs the divs get classes and CSS lays them out.

local BODY_IN = 5.7
local GAP_IN = 0.1
local INDENT_IN = 0.35
-- A box at the very top of a frame starts 0.15in above where text and grids
-- start, so the first step is moved down by that much.
local FIRST_SKIP_IN = 0.15
local PX_PER_IN = 72
local CYCLE = { "gold", "amber", "brown", "dark" }
local COLOURS = { gold = "dengold", amber = "denamber", rust = "denrust", orange = "denorange",
                  tan = "dentan", brown = "denbar", dark = "dendarkbrown" }

local function is_latex()
  return FORMAT:match("beamer") or FORMAT:match("latex")
end

local function colour_class(step, i)
  for class in pairs(COLOURS) do
    if step.classes:includes(class) then return class end
  end
  return CYCLE[(i - 1) % #CYCLE + 1]
end

local function inlines(text)
  if not text or text == "" then return nil end
  local parsed = pandoc.read(text, "markdown").blocks[1]
  return parsed and parsed.content or pandoc.Inlines({ pandoc.Str(text) })
end

local function height_share(el)
  local value = el.attributes.height and tonumber((el.attributes.height:gsub("%%", "")))
  return (value or 80) / 100
end

local function latex_steps(steps, total_in)
  local step_in = (total_in - (#steps - 1) * GAP_IN) / #steps
  local blocks = pandoc.List()
  for i, step in ipairs(steps) do
    local title = inlines(step.attributes.title)
    local heading = title
      and ("{\\bfseries\\densize{14} " .. pandoc.write(pandoc.Pandoc({ pandoc.Plain(title) }), "latex")
           .. "\\par}\\vspace{0.03in}") or ""
    blocks:insert(pandoc.RawBlock("latex", string.format(
      "\\begin{tcolorbox}[denstep={%s}{%d}, left skip=%.2fin, height=%.3fin, before skip=%.2fin, after skip=%.2fin]%s",
      COLOURS[colour_class(step, i)], i, (i - 1) * INDENT_IN, step_in,
      i == 1 and FIRST_SKIP_IN or 0, i < #steps and GAP_IN or 0, heading)))
    blocks:extend(step.content)
    blocks:insert(pandoc.RawBlock("latex", "\\end{tcolorbox}"))
  end
  return blocks
end

local function html_steps(el, steps, total_in)
  local content = pandoc.List()
  for i, step in ipairs(steps) do
    local inner = pandoc.List({ pandoc.Div({ pandoc.Plain({ pandoc.Str(tostring(i)) }) }, pandoc.Attr("", { "step-num" })) })
    local title = inlines(step.attributes.title)
    if title then inner:insert(pandoc.Div({ pandoc.Plain(title) }, pandoc.Attr("", { "step-title" }))) end
    inner:insert(pandoc.Div(step.content, pandoc.Attr("", { "step-body" })))
    content:insert(pandoc.Div(inner, pandoc.Attr("", { "step", colour_class(step, i) },
      { style = string.format("--i: %d;", i - 1) })))
  end
  el.attributes.height = nil
  el.attributes.style = string.format("height: %dpx;", math.floor(total_in * PX_PER_IN))
  el.content = content
  return el
end

function Div(el)
  if not el.classes:includes("steps") then
    return nil
  end
  local steps = pandoc.List()
  for _, child in ipairs(el.content) do
    if child.t == "Div" then steps:insert(child) end
  end
  if #steps == 0 then return nil end
  local total_in = height_share(el) * BODY_IN
  if is_latex() then
    return latex_steps(steps, total_in)
  end
  return html_steps(el, steps, total_in)
end
