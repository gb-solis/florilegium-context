-- t-florilegium.lua -- the Lua half of the ConTeXt (LMTX) module t-florilegium.mkxl: what
-- florilegium.lua's LaTeX glue does for LuaLaTeX (page geometry, colors, marks in the
-- page box, captions, PDF output), done the ConTeXt way. The drawing itself is the
-- same Lua as under LuaLaTeX (florilegium.lua and florilegium-*.lua, installed beside
-- this file), untouched. Everything is reached as thirddata.florilegium.
-- Copyright (c) 2026 Kevin Raymond. MIT License: see LICENSE or florilegium.sty.
-- From the ConTeXt port of florilegium 1.3 published by Luis Montgomery
-- (https://github.com/montylucho/florilegium); moved to florilegium 2.0.1 and maintained
-- by Gabriel Solis (https://github.com/gb-solis/florilegium-context).

local M = {}
M.version = "2.1.0"                -- the release; it must be florilegium.lua's, checked below
local this = M.version

-- the drawing code sends its warnings (an authored margin on a page it was not made
-- for, a \florilegiumbloom that names no motif) through LaTeX's luatexbase; here
-- they go to ConTeXt's log
luatexbase = luatexbase or {}
luatexbase.module_warning = luatexbase.module_warning or function(name, msg)
  logs.report(name, "warning: %s", msg)
end

local ink = require("florilegium-ink")
M = require("florilegium")                    -- the shared glue: seeds, primitives, compositions
if M.version ~= this then
  error(string.format("florilegium: t-florilegium.lua is from release %s, florilegium.lua from %s. "
    .. "Install the module from one release: t-florilegium.mkxl, t-florilegium.lua and every florilegium*.lua.", this, tostring(M.version)), 0)
end
local floor, fmt, concat = math.floor, string.format, table.concat

M.engine = "context"
local SP_CM = 2.54 / (72.27 * 65536)          -- cm per scaled point
local BP = 72 / 72.27 / 65536                 -- bp per scaled point

-- ---------------------------------------------------------------- PDF output
-- The drawing is one literal at the current point (ConTeXt's "origin" literal,
-- the same as a pdf_literal in mode 0); the graphics states for opacity and
-- multiply go into the page resources through lpdf.
ink.backend = {
  literal = function(data)
    node.write(nodes.pool.originliteral(data))
  end,
  extgstate = function(name, op, mult)
    local d = lpdf.dictionary { ca = op, CA = op }
    if mult then d.BM = lpdf.constant("Multiply") end
    lpdf.adddocumentextgstate(name, d)
  end,
}

-- ---------------------------------------------------------------- colors
-- M.inkcolor and M.accentcolor name ordinary ConTeXt colors (\setupflorilegium[inkcolor=darkred])
M.inkcolor, M.accentcolor = "florilegium:ink", "florilegium:accent"
local function rgb(name)
  local ok, c = pcall(attributes.colors.spec, name)
  if not ok or not c then return nil end
  if c.model == "gray" then return c.s, c.s, c.s end
  if c.model == "cmyk" then
    return (1 - c.c) * (1 - c.k), (1 - c.m) * (1 - c.k), (1 - c.y) * (1 - c.k)
  end
  return c.r, c.g, c.b
end
function M.ctx_colors()
  local ir, ig, ib = rgb(M.inkcolor)
  local ar, ag, ab = rgb(M.accentcolor)
  if not ir then ir, ig, ib = 0x24 / 255, 0x56 / 255, 0xC4 / 255 end
  if not ar then ar, ag, ab = 0.71, 0.40, 0.18 end
  M.colors(ir, ig, ib, ar, ag, ab)
end

-- ---------------------------------------------------------------- page geometry
-- The layout of the page being shipped out, passed by \florilegium_page as scaled
-- points: the text block's left edge (\texthoffset, which is \backspace or, on a
-- left-hand page of a double-sided document, \paperwidth - \backspace - \makeupwidth),
-- and the vertical stack \topspace, header, text, footer (the top area lies inside
-- \topspace, so it does not move the header). The same g as
-- florilegium.geometry() makes from LaTeX's lengths, so the growth code is unchanged.
M.layout = nil
function M.geometry()
  local L = M.layout
  local cm = function(k) return (L[k] or 0) * SP_CM end
  local g = { pw = cm("paperwidth"), ph = cm("paperheight"), textleft = cm("textleft") }
  g.textright = g.textleft + cm("makeupwidth")
  if g.pw - g.textright > g.textleft + 0.05 then
    g.mirror = true
    g.textleft, g.textright = g.pw - g.textright, g.pw - g.textleft
  end
  -- the top of the text area, below the header and its distance
  g.ytop = g.ph - cm("topspace") - cm("headerheight") - cm("headerdistance")
  g.ybot = g.ytop - cm("textheight")
  g.colright = g.textleft - 0.4
  -- LaTeX's head rule hangs 1 mm under the header's baseline, and its footer stem
  -- runs along the footer's baseline: here a strut is centered in each area
  local sht, sdp = cm("strutht"), cm("strutdp")
  local function baseline(top, h) return top - (h - sht - sdp) / 2 - sht end
  g.headrule = baseline(g.ytop + cm("headerdistance") + cm("headerheight"), cm("headerheight")) - 0.1
  g.footy = baseline(g.ybot - cm("footerdistance"), cm("footerheight"))
  return g
end

-- ---------------------------------------------------------------- marks in the text
-- \florilegiumbloom, \florilegiumtheme and the headings leave a user-defined whatsit
-- (ConTeXt's own kind, its data in the node's properties). When the page is shipped
-- out, the page box is searched for them, so the garden knows the height of those
-- lines on the same page in the same run.
local userids = nodes.pool.userids
local USERID = userids["florilegium"]
local marks = {}
function M.mark(kind, arg)
  marks[#marks + 1] = { kind = kind, arg = arg }
  node.write(nodes.pool.userdefined(USERID, #marks))
end

local HLIST, VLIST, GLUE, KERN, RULE, WHATSIT = node.id("hlist"), node.id("vlist"), node.id("glue"), node.id("kern"), node.id("rule"), node.id("whatsit")
local USER = nodes.whatsitcodes.userdefined
local getproperty, effective = node.getproperty, node.effectiveglue
-- y grows downward from the top of the outer box, x rightward. LuaMetaTeX boxes
-- can carry an offset (\boxxoffset, \boxyoffset), which moves what they show.
local function walk(head, parent, x, y, vertical, out)
  for n in node.traverse(head) do
    local id = n.id
    if id == HLIST or id == VLIST then
      local xo, yo = n.xoffset or 0, n.yoffset or 0
      if vertical then
        local base = y + n.height
        if n.list then walk(n.list, n, x + n.shift + xo, (id == VLIST and y or base) - yo, id == VLIST, out) end
        y = base + n.depth
      else
        local base = y + n.shift
        if n.list then walk(n.list, n, x + xo, (id == VLIST and base - n.height or base) - yo, id == VLIST, out) end
        x = x + n.width
      end
    elseif id == GLUE then
      local w = effective(n, parent)
      if vertical then y = y + w else x = x + w end
    elseif id == KERN then
      if vertical then y = y + n.kern else x = x + n.kern end
    elseif id == RULE then
      if vertical then y = y + n.height + n.depth else x = x + n.width end
    elseif id == WHATSIT then
      if n.subtype == USER then
        local p = getproperty(n)
        local m = p and p.id == USERID and marks[p.data]
        if m then out[#out + 1] = { kind = m.kind, arg = m.arg, x = x, y = y } end
      end
    elseif not vertical then
      x = x + node.dimensions(n, n.next)
    end
  end
end
-- the marks on the page being shipped out (\pagebox: the paper, its origin at
-- the top-left corner), in page cm from the lower-left corner
function M.page_marks(box)
  local b = box and tex.getbox(box)
  if not b then return {} end
  local out = {}
  -- the walk measures y from the top of a vlist, but from the baseline of an hlist
  -- (ConTeXt's page box is an hlist with the paper's height)
  walk(b.list, b, 0, b.id == VLIST and 0 or b.height, b.id == VLIST, out)
  local ph = M.layout.paperheight * SP_CM
  for _, m in ipairs(out) do
    m.x = m.x * SP_CM
    m.y = ph - m.y * SP_CM
  end
  return out
end

-- ---------------------------------------------------------------- captions
-- Text a theme sets in the margin (the math theme's symbols and equations), at
-- {x, y} in layout cm by a TikZ anchor (default north). Under LuaLaTeX these are
-- TikZ nodes; here each is a box set by TeX (\florilegium_caption_set) and placed
-- by florilegium.ctx_caption, rotated and scaled about its anchor.
local function texcolor(c, op)
  local s = fmt("r=%.3f,g=%.3f,b=%.3f", c[1], c[2], c[3])
  if op and op < 1 then s = s .. fmt(",a=1,t=%.2f", op) end   -- ConTeXt's t is the opacity
  return s
end
function M.captions(g, list, shown)
  if not list or #list == 0 then return end
  local plain = ink.tone(0.12)
  local out = {}
  for _, cap in ipairs(list) do
    if not shown or shown(cap) then
      local x = g.mirror and g.pw - cap.x or cap.x
      local anchor = cap.anchor or "north"
      if g.mirror then anchor = anchor:gsub("east", "\0"):gsub("west", "east"):gsub("\0", "west") end
      -- TikZ scales a 10 pt node (transform shape); here the font is set at that size
      -- instead (to a quarter point), since ConTeXt's backend loses its place when
      -- a fraction is drawn under a scaling matrix in the page background
      local size = cap.scale and fmt("%.2fpt", floor(40 * cap.scale + 0.5) / 4) or (cap.small and "5.5pt" or "6.5pt")
      local rot = (cap.rotate and cap.rotate ~= 0) and (g.mirror and -cap.rotate or cap.rotate) or 0
      out[#out + 1] = fmt("\\FlorilegiumCaptionSet{%s}{%s}{%s}\\FlorilegiumCaptionPut{%.0f}{%.0f}{%s}{%.2f}",
        size, texcolor(cap.color or plain, cap.opacity), cap.text, x / SP_CM, cap.y / SP_CM, anchor, rot)
    end
  end
  tex.sprint(catcodes.numbers.ctxcatcodes, concat(out))
end
-- the offset (sp) from a box's reference point to one of its TikZ anchors, inner sep 0
function M.ctx_anchor(box, anchor)
  local b = tex.getbox(box)
  local w, h, d = b.width, b.height, b.depth
  local ax, ay = w / 2, (h - d) / 2
  if anchor:find("west") then ax = 0 elseif anchor:find("east") then ax = w end
  if anchor:find("north") then ay = h elseif anchor:find("south") then ay = -d
  elseif anchor:find("base") then ay = 0 end
  tex.sprint(fmt("{%.0f}{%.0f}", -ax, -ay))
end

-- ---------------------------------------------------------------- the page
-- \florilegium_page calls this inside the page's background overlay, at the
-- lower-left corner of the paper. t: the layout (sp), the page numbers, the box
-- that holds the page, and where the text ended if it ended on this page.
M.composition = "authored"
M.fixedseed = nil
M.aging = false
local GLYPH = node.id("glyph")
local function has_glyph(head)
  for n in node.traverse(head) do
    if n.id == GLYPH then return true end
    if (n.id == HLIST or n.id == VLIST) and n.list and has_glyph(n.list) then return true end
  end
  return false
end
function M.ctx_page(t)
  -- a page with nothing typeset on it, not even a header or a page number, is the
  -- blank page ConTeXt adds to end a double-sided document on a left-hand page:
  -- it stays blank
  local b = tex.getbox(t.box)
  if not (b and b.list and has_glyph(b.list)) then return end
  M.layout = t
  M.twoside = false                           -- the geometry above already knows the side
  M.ctx_colors()
  local seed = M.seed(t.userpage, M.fixedseed)
  if M.composition == "grown" then
    if M.aging and t.lastpage and t.lastpage > 0 then M.auto_age(t.realpage, t.lastpage) end
    if t.endtotal then
      local g = M.geometry()
      M.grown(seed, 1, g.ytop - t.endtotal * SP_CM, t.box)
    else
      M.grown(seed, 0, 0, t.box)
    end
  else
    M.authored(seed, t.box)
  end
end

-- ---------------------------------------------------------------- in the text
-- \florilegiumdraw[x=, y=, rotate=, scale=]{name}{s, opts}: one primitive at the
-- current point (in a \startflorilegiumpicture, its lower-left corner), moved by
-- x, y (cm) and turned by rotate (degrees), as a TikZ scope would
local pending = nil
function M.sync_transform()
  ink.set_transform(pending or { ink.CM, 0, 0, ink.CM, 0, 0 })
end
function M.ctx_draw(x, y, rot, sc, name, s, o)
  M.ctx_colors()
  local c, sn = math.cos(math.rad(rot or 0)), math.sin(math.rad(rot or 0))
  local C, k = ink.CM, sc or 1
  pending = { c * C * k, sn * C * k, -sn * C * k, c * C * k, (x or 0) * C, (y or 0) * C }
  M.draw(name, s, o)
  pending = nil
end
-- a hairline in a picture, from (x1, y1) to (x2, y2) cm, in gray g (0 black, 1 white)
function M.ctx_line(x1, y1, x2, y2, gray, w)
  ink.set_transform({ ink.CM, 0, 0, ink.CM, 0, 0 })
  ink.moveto(x1, y1) ink.lineto(x2, y2)
  ink.stroke({ gray, gray, gray }, w or 0.4)
  ink.flush()
end
function M.ctx_rect(x1, y1, x2, y2, gray, w)
  ink.set_transform({ ink.CM, 0, 0, ink.CM, 0, 0 })
  ink.poly({ { x1, y1 }, { x2, y1 }, { x2, y2 }, { x1, y2 } }, true)
  ink.stroke({ gray, gray, gray }, w or 0.4)
  ink.flush()
end

-- \florilegiumornament: florilegium.ornament with the current colors
function M.ctx_ornament(name, size, inkhex, acchex, angle, seed)
  M.ctx_colors()
  M.ornament(name, size, inkhex, acchex, angle, seed)
end

-- \florilegiuminitial: florilegium.initial with the current colors
function M.ctx_initial(letter, side, hang, cap)
  M.ctx_colors()
  M.initial(letter, side, hang, cap)
end

thirddata = thirddata or {}
thirddata.florilegium = M                     -- \ctxlua{thirddata.florilegium...}
return M
