local ADDON_NAME, ns = ...

local CooldownCall = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0", "AceEvent-3.0")
ns.Addon = CooldownCall

local DEFAULT_MESSAGE = "{spell} bitte!"

local defaults = {
  profile = {
    enabled = true,
    throttle = 2, -- seconds; ignore repeat clicks of the same call (0 = off)
    theme = "dark", -- "dark" or "light"
    minimap = { hide = false }, -- LibDBIcon state
    bar = {
      width = 200,
      height = 24,
      locked = true,
      point = nil, -- { point, relPoint, x, y }
    },
    calls = {}, -- array of { key, caster, class, spellID, name, role, message, enabled }
  },
}

------------------------------------------------------------
-- Call helpers
------------------------------------------------------------

local function newKey()
  return ("c%d"):format(math.floor(GetTime() * 1000) % 100000000)
end

function CooldownCall:AddCall(data)
  local call = {
    key = newKey(),
    caster = data.caster,
    class = data.class,
    spellID = data.spellID,
    name = data.name or "?",
    role = data.role or "Utility",
    message = DEFAULT_MESSAGE,
    enabled = true,
  }
  table.insert(self.db.profile.calls, call)
  return call
end

function CooldownCall:RemoveCall(key)
  for i, c in ipairs(self.db.profile.calls) do
    if c.key == key then
      table.remove(self.db.profile.calls, i)
      return true
    end
  end
  return false
end

-- Re-resolve display names from spell ids (locale/spellbook may give a nicer
-- name now than when the call was first created).
function CooldownCall:RefreshNames()
  for _, c in ipairs(self.db.profile.calls) do
    if c.spellID then
      c.name = ns.Spells:Name(c.spellID, c.name)
    end
  end
end

------------------------------------------------------------
-- Minimap button (LibDataBroker + LibDBIcon)
------------------------------------------------------------

function CooldownCall:SetupMinimap()
  local ldb = LibStub("LibDataBroker-1.1", true)
  local icon = LibStub("LibDBIcon-1.0", true)
  if not ldb or not icon then
    return
  end

  local dataobj = ldb:NewDataObject(ADDON_NAME, {
    type = "launcher",
    text = "CooldownCall",
    icon = "Interface\\Icons\\Spell_Holy_PowerInfusion",
    OnClick = function(_, button)
      if button == "RightButton" then
        CooldownCall.db.profile.enabled = not CooldownCall.db.profile.enabled
        CooldownCall:Print("calls " .. (CooldownCall.db.profile.enabled and "enabled" or "disabled"))
      else
        ns.Options:Toggle()
      end
    end,
    OnTooltipShow = function(tt)
      tt:AddLine("CooldownCall")
      tt:AddLine("|cffffff00Left-click|r open the options window", 1, 1, 1)
      tt:AddLine("|cffffff00Right-click|r toggle calls on/off", 1, 1, 1)
    end,
  })

  icon:Register(ADDON_NAME, dataobj, self.db.profile.minimap)
  self.ldbIcon = icon
end

------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------

function CooldownCall:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("CooldownCallDB", defaults, true)

  ns.Caller:Initialize(self)
  ns.Options:Initialize(self)
  ns.Bars:Initialize(self)
  self:SetupMinimap()

  self:RegisterChatCommand("cooldowncall", "HandleSlashCommand")
  self:RegisterChatCommand("cdcall", "HandleSlashCommand")
  self:RegisterChatCommand("cc", "HandleSlashCommand")
end

function CooldownCall:OnEnable()
  self:RefreshNames()
  ns.Bars:Refresh()
  -- Rebuild bars when the group changes (caster availability / colours).
  self:RegisterEvent("GROUP_ROSTER_UPDATE", function()
    ns.Bars:Refresh()
  end)
  self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    ns.Bars:Refresh()
  end)
  self:Print(("ready. %d calls set up. /cc opens the options."):format(#self.db.profile.calls))
end

------------------------------------------------------------
-- Slash commands
------------------------------------------------------------

local function help(self)
  self:Print("commands:")
  self:Print("  /cc                 open / close the options window")
  self:Print("  /cc on | off        enable / disable sending calls")
  self:Print("  /cc lock | unlock   lock / unlock the on-screen bars")
  self:Print("  /cc minimap         toggle the minimap button")
  self:Print("  /cc status          show current state")
end

function CooldownCall:HandleSlashCommand(input)
  local cmd = (input or ""):trim():lower()

  if cmd == "" then
    ns.Options:Toggle()
  elseif cmd == "on" then
    self.db.profile.enabled = true
    self:Print("calls enabled")
  elseif cmd == "off" then
    self.db.profile.enabled = false
    self:Print("calls disabled")
  elseif cmd == "toggle" then
    self.db.profile.enabled = not self.db.profile.enabled
    self:Print("calls " .. (self.db.profile.enabled and "enabled" or "disabled"))
  elseif cmd == "lock" then
    ns.Bars:SetLocked(true)
    if ns.Options.frame then
      ns.Options:UpdateLockLabel()
    end
    self:Print("bars locked")
  elseif cmd == "unlock" then
    ns.Bars:SetLocked(false)
    if ns.Options.frame then
      ns.Options:UpdateLockLabel()
    end
    self:Print("bars unlocked — drag the handle, then /cc lock")
  elseif cmd == "minimap" then
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    if self.ldbIcon then
      if self.db.profile.minimap.hide then
        self.ldbIcon:Hide(ADDON_NAME)
      else
        self.ldbIcon:Show(ADDON_NAME)
      end
    end
    self:Print("minimap button " .. (self.db.profile.minimap.hide and "hidden" or "shown"))
  elseif cmd == "status" then
    self:Print(
      ("enabled=%s | calls=%d | theme=%s | bar=%dx%d"):format(
        tostring(self.db.profile.enabled),
        #self.db.profile.calls,
        self.db.profile.theme,
        self.db.profile.bar.width,
        self.db.profile.bar.height
      )
    )
  else
    help(self)
  end
end
