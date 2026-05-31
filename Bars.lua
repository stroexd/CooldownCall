local ADDON_NAME, ns = ...
local Bars = {}
ns.Bars = Bars

local WHITE = "Interface\\Buttons\\WHITE8x8"
local GAP = 3

local addon
local anchor, handle
local bars = {} -- pool of bar buttons, reused across refreshes

------------------------------------------------------------
-- Position
------------------------------------------------------------

local function applyPosition()
  local p = addon.db.profile.bar.point
  anchor:ClearAllPoints()
  if p and p.point then
    anchor:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x or 0, p.y or 0)
  else
    anchor:SetPoint("CENTER", UIParent, "CENTER", 250, 0)
  end
end

local function savePosition()
  local point, _, relPoint, x, y = anchor:GetPoint()
  addon.db.profile.bar.point = { point = point, relPoint = relPoint, x = x, y = y }
end

------------------------------------------------------------
-- Build anchor + drag handle
------------------------------------------------------------

function Bars:Initialize(parent)
  addon = parent

  anchor = CreateFrame("Frame", "CooldownCallBars", UIParent)
  anchor:SetSize(addon.db.profile.bar.width, 1)
  anchor:SetClampedToScreen(true)
  anchor:SetMovable(true)
  applyPosition()

  handle = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
  handle:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
  handle:SetPoint("BOTTOMRIGHT", anchor, "TOPRIGHT", 0, 2)
  handle:SetHeight(18)
  handle:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
  handle:SetBackdropColor(0, 0, 0, 0.8)
  handle:SetBackdropBorderColor(1, 0.82, 0.2, 1)
  handle:EnableMouse(true)
  handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart", function()
    anchor:StartMoving()
  end)
  handle:SetScript("OnDragStop", function()
    anchor:StopMovingOrSizing()
    savePosition()
  end)
  local hl = handle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hl:SetPoint("CENTER")
  hl:SetText("CooldownCall — drag me (/cc lock)")
  handle:Hide()

  self:Refresh()
end

------------------------------------------------------------
-- Bar widget
------------------------------------------------------------

local function acquireBar(index)
  local bar = bars[index]
  if bar then
    return bar
  end

  bar = CreateFrame("Button", nil, anchor, "BackdropTemplate")
  bar:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
  bar:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  bar.icon = bar:CreateTexture(nil, "ARTWORK")
  bar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- trim the default icon border

  -- Cooldown countdown overlay, drawn on top of the icon.
  bar.cdText = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  bar.cdText:SetTextColor(1, 0.82, 0.2)

  bar.spellName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  bar.spellName:SetJustifyH("LEFT")

  bar.casterName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  bar.casterName:SetJustifyH("RIGHT")

  bar:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(self.call.name or "?")
    GameTooltip:AddLine("Whisper " .. (self.call.caster or "?"), 1, 1, 1)
    GameTooltip:AddLine("|cffffff00Click|r to send the call", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)
  bar:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  bar:SetScript("OnClick", function(self)
    local ok, who, text = ns.Caller:Send(self.call)
    if ok then
      addon:Print(('called %s: "%s"'):format(who, text))
    else
      addon:Print(who) -- reason string
    end
  end)

  -- Show the assigned caster's cooldown counting down (combat-log driven).
  bar.elapsed = 0
  bar:SetScript("OnUpdate", function(self, e)
    self.elapsed = self.elapsed + e
    if self.elapsed < 0.1 then
      return
    end
    self.elapsed = 0
    local remaining = self.call and ns.CD:Remaining(self.call) or 0
    if remaining > 0 then
      self.cdText:SetText(ns.CD:FormatTime(remaining))
      self.icon:SetDesaturated(true)
      self:SetAlpha(0.55)
    elseif self.onCooldown ~= false then
      self.cdText:SetText("")
      self.icon:SetDesaturated(false)
      self:SetAlpha(1)
    end
    self.onCooldown = remaining > 0
  end)

  bars[index] = bar
  return bar
end

------------------------------------------------------------
-- Refresh: collect enabled calls, sort, lay out, theme
------------------------------------------------------------

function Bars:Refresh()
  if not anchor then
    return
  end

  -- Only show bars for calls whose assigned caster is currently in the group;
  -- they reappear automatically when that player rejoins (GROUP_ROSTER_UPDATE).
  local list = {}
  for _, call in ipairs(addon.db.profile.calls) do
    if call.enabled and ns.Roster:InGroup(call.caster) then
      table.insert(list, call)
    end
  end
  table.sort(list, function(a, b)
    local ra, rb = ns.Spells:RoleRank(a.role), ns.Spells:RoleRank(b.role)
    if ra ~= rb then
      return ra < rb
    end
    return (a.name or "") < (b.name or "")
  end)

  local w = addon.db.profile.bar.width
  local h = addon.db.profile.bar.height
  anchor:SetWidth(w)

  for i, call in ipairs(list) do
    local bar = acquireBar(i)
    bar.call = call
    bar:SetSize(w, h)
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -(i - 1) * (h + GAP))

    -- icon
    local inset = 2
    bar.icon:ClearAllPoints()
    bar.icon:SetPoint("LEFT", inset, 0)
    bar.icon:SetSize(h - inset * 2, h - inset * 2)
    bar.icon:SetTexture(ns.Spells:Icon(call.spellID) or "Interface\\Icons\\INV_Misc_QuestionMark")

    bar.cdText:ClearAllPoints()
    bar.cdText:SetPoint("CENTER", bar.icon, "CENTER", 0, 0)
    bar.onCooldown = nil -- let OnUpdate re-evaluate the cooldown visual

    -- caster colour drives this bar's accent
    local accent = ns.Theme:ClassColor(call.class)
    local t = ns.Theme:Get(addon.db.profile.theme, accent)
    bar:SetBackdropColor(unpack(t.bg))
    bar:SetBackdropBorderColor(unpack(t.border))

    bar.spellName:ClearAllPoints()
    bar.spellName:SetPoint("LEFT", bar.icon, "RIGHT", 5, 0)
    bar.spellName:SetText(call.name or "?")
    bar.spellName:SetTextColor(unpack(t.text))

    bar.casterName:ClearAllPoints()
    bar.casterName:SetPoint("RIGHT", -6, 0)
    bar.casterName:SetPoint("LEFT", bar.spellName, "RIGHT", 4, 0)
    bar.casterName:SetText((call.caster and call.caster:match("^[^%-]+")) or "?")
    bar.casterName:SetTextColor(unpack(t.name))

    bar:Show()
  end

  for i = #list + 1, #bars do
    bars[i]:Hide()
  end

  anchor:SetHeight(math.max(1, #list * (addon.db.profile.bar.height + GAP)))

  ns.Theme:ApplyFontToFrame(anchor)
end

------------------------------------------------------------
-- Lock / unlock movement
------------------------------------------------------------

function Bars:SetLocked(locked)
  addon.db.profile.bar.locked = locked and true or false
  if locked then
    handle:Hide()
  else
    handle:Show()
  end
end

function Bars:ToggleLock()
  self:SetLocked(not addon.db.profile.bar.locked)
  return addon.db.profile.bar.locked
end
