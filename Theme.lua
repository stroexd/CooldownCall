local ADDON_NAME, ns = ...
local Theme = {}
ns.Theme = Theme

-- Dark-mode base colour (from the user's swatch): warm-neutral charcoal.
local CHARCOAL = { 0.17, 0.17, 0.18 }

local FALLBACK = { r = 1.0, g = 0.82, b = 0.0 } -- "ungrouped"/unknown class -> gold

-- Resolve a class file token ("MAGE", "PALADIN", ...) to an {r,g,b} table.
function Theme:ClassColor(classFile)
  local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] or FALLBACK
  return { c.r, c.g, c.b }
end

function Theme:PlayerClassColor()
  local _, classFile = UnitClass("player")
  return self:ClassColor(classFile)
end

function Theme:Charcoal()
  return { CHARCOAL[1], CHARCOAL[2], CHARCOAL[3] }
end

local function lighten(c, amount)
  return {
    math.min(c[1] + amount, 1),
    math.min(c[2] + amount, 1),
    math.min(c[3] + amount, 1),
  }
end

local function rgba(c, a)
  return { c[1], c[2], c[3], a or 1 }
end

-- Build the full colour set for the active theme. `accent` defaults to the
-- player's class colour; bars pass their caster's class colour instead.
function Theme:Get(mode, accent)
  accent = accent or self:PlayerClassColor()
  local ch = CHARCOAL

  if mode == "light" then
    return {
      mode = "light",
      accent = accent,
      bg = rgba(accent, 0.95),
      border = rgba(ch, 1),
      rowBg = rgba(lighten(accent, 0.28), 0.95),
      rowAlt = rgba(lighten(accent, 0.40), 0.95),
      text = rgba(ch, 1),
      dim = { 0.30, 0.30, 0.34, 1 },
      name = rgba(ch, 1), -- char name uses the dark-mode colour in light mode
      btnBg = { 1, 1, 1, 0.85 },
      btnHover = { 1, 1, 1, 1 },
      btnBorder = rgba(ch, 1),
      editBg = { 1, 1, 1, 0.92 },
      editBorder = rgba(ch, 1),
    }
  end

  -- dark (default)
  return {
    mode = "dark",
    accent = accent,
    bg = rgba(ch, 0.96),
    border = rgba(accent, 1),
    rowBg = { 0.13, 0.13, 0.15, 0.92 },
    rowAlt = { 0.17, 0.17, 0.20, 0.92 },
    text = { 0.92, 0.92, 0.95, 1 },
    dim = { 0.60, 0.60, 0.66, 1 },
    name = rgba(accent, 1), -- char name in class colour
    btnBg = { 0.20, 0.20, 0.24, 1 },
    btnHover = { 0.30, 0.30, 0.38, 1 },
    btnBorder = rgba(accent, 0.85),
    editBg = { 0, 0, 0, 0.5 },
    editBorder = { 0.30, 0.30, 0.36, 1 },
  }
end
