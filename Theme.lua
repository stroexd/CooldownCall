local ADDON_NAME, ns = ...
local Theme = {}
ns.Theme = Theme

-- Dark-mode base colour (from the user's swatch): warm-neutral charcoal.
local CHARCOAL = { 0.17, 0.17, 0.18 }

local FALLBACK = { r = 1.0, g = 0.82, b = 0.0 } -- "ungrouped"/unknown class -> gold

-- Font: bundled copy of Expressway (the "Merfin Font 1" used by MerfinUI/ElvUI),
-- so CooldownCall matches the user's UI without depending on another addon.
Theme.FONT = [[Interface\AddOns\CooldownCall\Media\Expressway.ttf]]
Theme.FONT_FLAGS = "OUTLINE"

-- Re-font every FontString / EditBox under `frame`, keeping each one's existing
-- size but swapping the family to Expressway with an outline (the MerfinUI look).
-- Lets us skin widgets created with the default GameFont* objects without
-- touching each CreateFontString call site.
function Theme:ApplyFontToFrame(frame)
  if not frame then
    return
  end
  if frame.GetRegions then
    for _, r in ipairs({ frame:GetRegions() }) do
      if r.GetObjectType and r:GetObjectType() == "FontString" then
        local _, size = r:GetFont()
        r:SetFont(self.FONT, size or 12, self.FONT_FLAGS)
      end
    end
  end
  if frame.GetChildren then
    for _, c in ipairs({ frame:GetChildren() }) do
      if c.GetObjectType and c:GetObjectType() == "EditBox" and c.SetFont then
        local _, size = c:GetFont()
        c:SetFont(self.FONT, size or 12, self.FONT_FLAGS)
      end
      self:ApplyFontToFrame(c)
    end
  end
end

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

  -- dark (default): flat ElvUI / MerfinUI look — near-black background, thin
  -- pure-black border, class colour reserved for names (not the border).
  return {
    mode = "dark",
    accent = accent,
    bg = { 0.09, 0.09, 0.09, 0.9 },
    border = { 0, 0, 0, 1 },
    rowBg = { 0.11, 0.11, 0.11, 0.9 },
    rowAlt = { 0.14, 0.14, 0.14, 0.9 },
    text = { 0.9, 0.9, 0.9, 1 },
    dim = { 0.55, 0.55, 0.58, 1 },
    name = rgba(accent, 1), -- char / caster name in class colour
    btnBg = { 0.16, 0.16, 0.16, 1 },
    btnHover = { 0.24, 0.24, 0.26, 1 },
    btnBorder = { 0, 0, 0, 1 },
    editBg = { 0, 0, 0, 0.6 },
    editBorder = { 0, 0, 0, 1 },
  }
end
