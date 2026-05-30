local ADDON_NAME, ns = ...
local Options = {}
ns.Options = Options

local WHITE = "Interface\\Buttons\\WHITE8x8"

local FRAME_W = 600
local PAD = 16
local ROW_H = 24
local ROW_GAP = 3

-- Row column x / width (relative to the inner area; inner width = 568)
local COL = {
  check = { x = 0, w = 18 },
  icon = { x = 24, w = 18 },
  spell = { x = 48, w = 110 },
  caster = { x = 164, w = 84 },
  message = { x = 254, w = 180 },
  call = { x = 440, w = 50 },
  del = { x = 496, w = 18 },
}

local function theme()
  return ns.Theme:Get(ns.Addon.db.profile.theme)
end

------------------------------------------------------------
-- Themed widget builders
------------------------------------------------------------

local function backdrop(frame, edge)
  frame:SetBackdrop({ bgFile = WHITE, edgeFile = edge and WHITE or nil, edgeSize = edge or nil })
end

local skinList = {} -- { obj = frame, kind = "button"|"check"|"edit"|"panel" }

local function register(obj, kind)
  table.insert(skinList, { obj = obj, kind = kind })
  return obj
end

local function makeButton(parent, text, w, h)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(w, h or 20)
  backdrop(b, 1)
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fs:SetPoint("CENTER")
  fs:SetText(text)
  b.label = fs
  b:SetScript("OnEnter", function(self)
    if self:IsEnabled() then
      self:SetBackdropColor(unpack(self._hover or { 0.3, 0.3, 0.4, 1 }))
    end
  end)
  b:SetScript("OnLeave", function(self)
    self:SetBackdropColor(unpack(self._bg or { 0.2, 0.2, 0.24, 1 }))
  end)
  return register(b, "button")
end

local function makeCheck(parent)
  local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
  b:SetSize(18, 18)
  backdrop(b, 1)
  local check = b:CreateTexture(nil, "OVERLAY")
  check:SetPoint("CENTER")
  check:SetSize(14, 14)
  check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  b.checkTex = check
  b.checked = false
  function b:SetChecked(v)
    self.checked = v and true or false
    self.checkTex:SetShown(self.checked)
  end
  function b:GetChecked()
    return self.checked
  end
  b:SetScript("OnClick", function(self)
    self:SetChecked(not self.checked)
    if self.onToggle then
      self.onToggle(self.checked)
    end
  end)
  return register(b, "check")
end

local function makeEdit(parent, w)
  local e = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
  e:SetSize(w, 20)
  backdrop(e, 1)
  e:SetAutoFocus(false)
  e:SetFontObject("GameFontHighlightSmall")
  e:SetTextInsets(5, 5, 0, 0)
  e:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
  end)
  e:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)
  return register(e, "edit")
end

-- Lightweight themed dropdown: a button that opens a popup list.
local function makeDropdown(parent, w, placeholder)
  local dd = makeButton(parent, placeholder or "", w, 20)
  dd.label:ClearAllPoints()
  dd.label:SetPoint("LEFT", 6, 0)
  dd.label:SetJustifyH("LEFT")
  dd.label:SetWidth(w - 18)
  local arrow = dd:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  arrow:SetPoint("RIGHT", -5, 0)
  arrow:SetText("v")
  dd.arrow = arrow
  dd.placeholder = placeholder or ""

  local menu = CreateFrame("Frame", nil, dd, "BackdropTemplate")
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetToplevel(true)
  menu:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", 0, -2)
  menu:SetWidth(w)
  backdrop(menu, 1)
  menu:Hide()
  register(menu, "panel")
  dd.menu = menu
  dd.itemButtons = {}

  function dd:SetValue(text)
    self.value = text
    self.label:SetText(text and text ~= "" and text or self.placeholder)
  end

  function dd:SetItems(items)
    self.items = items
    -- Items are (re)created on open, after the last ApplyTheme pass, so colour
    -- each button here or it shows an unthemed white backdrop until hovered.
    local t = theme()
    for _, b in ipairs(self.itemButtons) do
      b:Hide()
    end
    local y = -2
    for i, item in ipairs(items) do
      local ib = self.itemButtons[i]
      if not ib then
        ib = makeButton(menu, "", w - 4, 18)
        ib.label:ClearAllPoints()
        ib.label:SetPoint("LEFT", 6, 0)
        ib.label:SetJustifyH("LEFT")
        self.itemButtons[i] = ib
      end
      ib._bg = t.btnBg
      ib._hover = t.btnHover
      ib:SetBackdropColor(unpack(t.btnBg))
      ib:SetBackdropBorderColor(unpack(t.btnBorder))
      ib:ClearAllPoints()
      ib:SetPoint("TOPLEFT", 2, y)
      ib.label:SetText(item.text)
      if item.color then
        ib.label:SetTextColor(item.color[1], item.color[2], item.color[3])
      else
        ib.label:SetTextColor(unpack(t.text))
      end
      ib:SetScript("OnClick", function()
        dd:SetValue(item.text)
        menu:Hide()
        if dd.onSelect then
          dd.onSelect(item)
        end
      end)
      ib:Show()
      y = y - 19
    end
    menu:SetHeight(math.max(4, #items * 19 + 4))
  end

  dd:SetScript("OnClick", function()
    if menu:IsShown() then
      menu:Hide()
    else
      if dd.onOpen then
        dd.onOpen()
      end
      menu:Show()
    end
  end)

  return dd
end

------------------------------------------------------------
-- Build static chrome
------------------------------------------------------------

function Options:Build()
  if self.frame then
    return
  end
  local addon = ns.Addon

  local f = CreateFrame("Frame", "CooldownCallFrame", UIParent, "BackdropTemplate")
  f:SetSize(FRAME_W, 240)
  f:SetPoint("CENTER")
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)
  backdrop(f, 2)
  f:Hide()
  register(f, "frameMain")
  self.frame = f

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", PAD, -12)
  title:SetText("CooldownCall")
  self.titleFS = title

  local charName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  charName:SetPoint("LEFT", title, "RIGHT", 8, 0)
  charName:SetText(UnitName("player") or "")
  self.charNameFS = charName

  local close = makeButton(f, "X", 20, 20)
  close:SetPoint("TOPRIGHT", -PAD, -12)
  close:SetScript("OnClick", function()
    Options:Hide()
  end)

  local themeBtn = makeButton(f, "", 90, 20)
  themeBtn:SetPoint("TOPRIGHT", close, "TOPLEFT", -6, 0)
  themeBtn:SetScript("OnClick", function()
    addon.db.profile.theme = (addon.db.profile.theme == "dark") and "light" or "dark"
    Options:ApplyTheme()
    ns.Bars:Refresh()
  end)
  self.themeBtn = themeBtn

  -- Master enable
  local en = makeCheck(f)
  en:SetPoint("TOPLEFT", PAD, -40)
  en.onToggle = function(v)
    addon.db.profile.enabled = v
  end
  self.enabledCheck = en
  local enLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  enLabel:SetPoint("LEFT", en, "RIGHT", 6, 0)
  enLabel:SetText("Send calls")
  self.enabledLabel = enLabel

  -- Lock bars
  local lockBtn = makeButton(f, "", 120, 20)
  lockBtn:SetPoint("LEFT", enLabel, "RIGHT", 16, 0)
  lockBtn:SetScript("OnClick", function()
    ns.Bars:ToggleLock()
    Options:UpdateLockLabel()
  end)
  self.lockBtn = lockBtn

  -- Bar size steppers
  local sizeY = -70
  local function stepper(labelText, x, getf, setf, lo, hi, step)
    local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("TOPLEFT", x, sizeY)
    lbl:SetText(labelText)
    self.skinDim = self.skinDim or {}
    table.insert(self.skinDim, lbl)

    local minus = makeButton(f, "-", 20, 18)
    minus:SetPoint("TOPLEFT", x + 56, sizeY + 2)
    local val = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    val:SetPoint("LEFT", minus, "RIGHT", 6, 0)
    val:SetWidth(34)
    val:SetJustifyH("CENTER")
    local plus = makeButton(f, "+", 20, 18)
    plus:SetPoint("LEFT", val, "RIGHT", 6, 0)
    self.skinText = self.skinText or {}
    table.insert(self.skinText, val)

    local function render()
      val:SetText(tostring(getf()))
    end
    minus:SetScript("OnClick", function()
      setf(math.max(lo, getf() - step))
      render()
      ns.Bars:Refresh()
    end)
    plus:SetScript("OnClick", function()
      setf(math.min(hi, getf() + step))
      render()
      ns.Bars:Refresh()
    end)
    render()
  end

  stepper("Width", PAD, function()
    return addon.db.profile.bar.width
  end, function(v)
    addon.db.profile.bar.width = v
  end, 120, 400, 10)
  stepper("Height", PAD + 170, function()
    return addon.db.profile.bar.height
  end, function(v)
    addon.db.profile.bar.height = v
  end, 14, 44, 2)

  -- Column headers
  local headerY = -98
  self.headerFS = {}
  local function header(key, label, justify)
    local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", PAD + COL[key].x, headerY)
    fs:SetWidth(COL[key].w + 40)
    fs:SetJustifyH(justify or "LEFT")
    fs:SetText(label)
    table.insert(self.headerFS, fs)
  end
  header("check", "On")
  header("spell", "Cooldown")
  header("caster", "Cast by")
  header("message", "Message")
  self.rowsTop = headerY - 16

  -- Add-call row widgets (positioned in Refresh)
  local casterDD = makeDropdown(f, 130, "Caster…")
  casterDD.onOpen = function()
    Options:PopulateCasters(casterDD)
  end
  casterDD.onSelect = function(item)
    Options.addCaster = item
    Options.spellDD:SetValue(nil)
    Options.addSpell = nil
  end
  self.casterDD = casterDD

  local spellDD = makeDropdown(f, 150, "Cooldown…")
  spellDD.onOpen = function()
    Options:PopulateSpells(spellDD)
  end
  spellDD.onSelect = function(item)
    Options.addSpell = item
  end
  self.spellDD = spellDD

  local customLbl = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  customLbl:SetText("or custom:")
  self.customLbl = customLbl
  self.skinDim = self.skinDim or {}
  table.insert(self.skinDim, customLbl)

  local customEdit = makeEdit(f, 110)
  self.customEdit = customEdit

  local addBtn = makeButton(f, "Add call", 80, 20)
  addBtn:SetScript("OnClick", function()
    Options:DoAdd()
  end)
  self.addBtn = addBtn

  local footer = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  footer:SetJustifyH("LEFT")
  footer:SetText(
    "Click a bar (or |cffffd200Call|r) to whisper. Tokens: {spell}, {caster}, {target}. Custom = spell name or ID."
  )
  self.footerFS = footer

  self.rows = {}
end

function Options:UpdateLockLabel()
  local locked = ns.Addon.db.profile.bar.locked
  self.lockBtn.label:SetText(locked and "Bars: locked" or "Bars: unlocked")
end

------------------------------------------------------------
-- Dropdown population
------------------------------------------------------------

function Options:PopulateCasters(dd)
  local items = {}
  for _, m in ipairs(ns.Roster:Members()) do
    table.insert(items, {
      text = m.name,
      name = m.name,
      class = m.classFile,
      color = ns.Theme:ClassColor(m.classFile),
    })
  end
  if #items == 0 then
    table.insert(items, { text = "(not in a group)", name = nil })
  end
  dd:SetItems(items)
end

function Options:PopulateSpells(dd)
  local items = {}
  local class = self.addCaster and self.addCaster.class
  if class then
    for _, s in ipairs(ns.Spells:ForClass(class)) do
      table.insert(items, {
        text = ns.Spells:Name(s.id, s.en),
        spellID = s.id,
        name = ns.Spells:Name(s.id, s.en),
        role = s.role,
        cd = s.cd,
        class = class,
      })
    end
  end
  if #items == 0 then
    table.insert(items, { text = class and "(no catalog entries)" or "(pick a caster first)" })
  end
  dd:SetItems(items)
end

------------------------------------------------------------
-- Add a call
------------------------------------------------------------

function Options:DoAdd()
  local addon = ns.Addon
  local caster = self.addCaster
  if not caster or not caster.name then
    addon:Print("pick a caster from your group first")
    return
  end

  local custom = self.customEdit:GetText():trim()
  local spellID, name, role, cd
  if custom ~= "" then
    local id = tonumber(custom)
    if id then
      name = ns.Spells:Name(id, nil)
      if not name then
        addon:Print("unknown spell id: " .. custom)
        return
      end
      spellID = id
    else
      name = custom
    end
    role = "Utility"
  elseif self.addSpell and self.addSpell.name then
    spellID = self.addSpell.spellID
    name = self.addSpell.name
    role = self.addSpell.role
    cd = self.addSpell.cd
  else
    addon:Print("pick a cooldown or type a custom one")
    return
  end

  addon:AddCall({
    caster = caster.name,
    class = caster.class,
    spellID = spellID,
    name = name,
    role = role,
    cd = cd,
  })
  self.customEdit:SetText("")
  self.spellDD:SetValue(nil)
  self.addSpell = nil
  self:Refresh()
  ns.Bars:Refresh()
end

------------------------------------------------------------
-- Row build / refresh
------------------------------------------------------------

local function makeRow(parent)
  local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  row:SetSize(FRAME_W - PAD * 2, ROW_H)
  backdrop(row, nil)
  register(row, "rowAuto")

  row.check = makeCheck(row)
  row.check:SetPoint("LEFT", COL.check.x, 0)

  row.icon = row:CreateTexture(nil, "ARTWORK")
  row.icon:SetPoint("LEFT", COL.icon.x, 0)
  row.icon:SetSize(COL.icon.w, COL.icon.w)
  row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

  row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.label:SetPoint("LEFT", COL.spell.x, 0)
  row.label:SetWidth(COL.spell.w)
  row.label:SetJustifyH("LEFT")

  row.casterFS = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  row.casterFS:SetPoint("LEFT", COL.caster.x, 0)
  row.casterFS:SetWidth(COL.caster.w)
  row.casterFS:SetJustifyH("LEFT")

  row.msgEdit = makeEdit(row, COL.message.w)
  row.msgEdit:SetPoint("LEFT", COL.message.x, 0)

  row.callBtn = makeButton(row, "Call", COL.call.w, 18)
  row.callBtn:SetPoint("LEFT", COL.call.x, 0)

  row.delBtn = makeButton(row, "X", COL.del.w, 18)
  row.delBtn:SetPoint("LEFT", COL.del.x, 0)

  return row
end

function Options:Refresh()
  if not self.frame then
    return
  end
  local addon = ns.Addon
  local calls = addon.db.profile.calls

  for i, call in ipairs(calls) do
    local row = self.rows[i]
    if not row then
      row = makeRow(self.frame)
      self.rows[i] = row
    end
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", PAD, self.rowsTop - (i - 1) * (ROW_H + ROW_GAP))
    row:Show()
    row.call = call

    row.check:SetChecked(call.enabled)
    row.check.onToggle = function(v)
      call.enabled = v
      Options:Refresh()
      ns.Bars:Refresh()
    end

    row.icon:SetTexture(ns.Spells:Icon(call.spellID) or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.label:SetText(call.name or "?")

    row.casterFS:SetText((call.caster and call.caster:match("^[^%-]+")) or "?")
    row.casterFS:SetTextColor(unpack(ns.Theme:ClassColor(call.class)))

    row.msgEdit:SetText(call.message or "")
    row.msgEdit:SetScript("OnTextChanged", function(self, userInput)
      if userInput then
        call.message = self:GetText()
      end
    end)

    if call.enabled then
      row.callBtn:Enable()
    else
      row.callBtn:Disable()
    end
    row.callBtn:SetScript("OnClick", function()
      local ok, who, text = ns.Caller:Send(call)
      if ok then
        addon:Print(('called %s: "%s"'):format(who, text))
      else
        addon:Print(who)
      end
    end)

    row.delBtn:SetScript("OnClick", function()
      addon:RemoveCall(call.key)
      Options:Refresh()
      ns.Bars:Refresh()
    end)
  end

  for i = #calls + 1, #self.rows do
    self.rows[i]:Hide()
  end

  local listBottom = self.rowsTop - #calls * (ROW_H + ROW_GAP) - 8

  self.casterDD:ClearAllPoints()
  self.casterDD:SetPoint("TOPLEFT", PAD, listBottom)
  self.spellDD:ClearAllPoints()
  self.spellDD:SetPoint("LEFT", self.casterDD, "RIGHT", 6, 0)
  self.customLbl:ClearAllPoints()
  self.customLbl:SetPoint("LEFT", self.spellDD, "RIGHT", 8, 0)
  self.customEdit:ClearAllPoints()
  self.customEdit:SetPoint("LEFT", self.customLbl, "RIGHT", 6, 0)
  self.addBtn:ClearAllPoints()
  self.addBtn:SetPoint("LEFT", self.customEdit, "RIGHT", 8, 0)

  self.footerFS:ClearAllPoints()
  self.footerFS:SetPoint("TOPLEFT", PAD, listBottom - 30)

  local h = math.abs(listBottom - 30) + 26
  self.frame:SetHeight(h)

  self:ApplyTheme()
end

------------------------------------------------------------
-- Theme application
------------------------------------------------------------

function Options:ApplyTheme()
  if not self.frame then
    return
  end
  local addon = ns.Addon
  local t = theme()

  self.titleFS:SetTextColor(unpack(t.name))
  self.charNameFS:SetTextColor(unpack(t.name))
  self.enabledLabel:SetTextColor(unpack(t.text))
  self.footerFS:SetTextColor(unpack(t.dim))
  self.themeBtn.label:SetText(addon.db.profile.theme == "dark" and "Theme: Dark" or "Theme: Light")
  self:UpdateLockLabel()

  for _, fs in ipairs(self.headerFS) do
    fs:SetTextColor(unpack(t.dim))
  end
  for _, fs in ipairs(self.skinDim or {}) do
    fs:SetTextColor(unpack(t.dim))
  end
  for _, fs in ipairs(self.skinText or {}) do
    fs:SetTextColor(unpack(t.text))
  end

  for _, item in ipairs(skinList) do
    local o, kind = item.obj, item.kind
    if kind == "frameMain" then
      o:SetBackdropColor(unpack(t.bg))
      o:SetBackdropBorderColor(unpack(t.border))
    elseif kind == "panel" then
      o:SetBackdropColor(unpack(t.bg))
      o:SetBackdropBorderColor(unpack(t.border))
    elseif kind == "button" then
      o._bg = t.btnBg
      o._hover = t.btnHover
      o:SetBackdropColor(unpack(t.btnBg))
      o:SetBackdropBorderColor(unpack(t.btnBorder))
      o.label:SetTextColor(unpack(t.text))
    elseif kind == "check" then
      o:SetBackdropColor(unpack(t.editBg))
      o:SetBackdropBorderColor(unpack(t.editBorder))
    elseif kind == "edit" then
      o:SetBackdropColor(unpack(t.editBg))
      o:SetBackdropBorderColor(unpack(t.editBorder))
      o:SetTextColor(unpack(t.text))
    end
  end

  -- Row striping + caster colours sit on top of the generic skin.
  for i, row in ipairs(self.rows) do
    if row:IsShown() then
      local bg = (i % 2 == 1) and t.rowBg or t.rowAlt
      row:SetBackdropColor(unpack(bg))
      local dim = row.call and not row.call.enabled
      row.label:SetTextColor(unpack(dim and t.dim or t.text))
      if row.call then
        row.casterFS:SetTextColor(unpack(ns.Theme:ClassColor(row.call.class)))
      end
    end
  end
end

------------------------------------------------------------
-- Show / hide
------------------------------------------------------------

function Options:Initialize(parent)
  ns.Addon = parent
end

function Options:Show()
  self:Build()
  local addon = ns.Addon
  self.enabledCheck:SetChecked(addon.db.profile.enabled)
  self.charNameFS:SetText(UnitName("player") or "")
  addon:RefreshNames()
  self:Refresh()
  self.frame:Show()
end

function Options:Hide()
  if self.frame then
    self.frame:Hide()
  end
end

function Options:Toggle()
  self:Build()
  if self.frame:IsShown() then
    self:Hide()
  else
    self:Show()
  end
end
