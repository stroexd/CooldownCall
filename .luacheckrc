std = "lua51"
max_line_length = 120
codes = true

ignore = {
  "212/self", -- unused argument self (Ace3 methods)
  "212/_",    -- unused vararg names
  "431",      -- shadowing upvalue (common in Ace3)
}

globals = {
  "LibStub",
  "CooldownCallDB",
}

read_globals = {
  -- Blizzard API used by the addon
  "UnitName", "UnitClass", "UnitExists", "UnitIsPlayer", "UnitGroupRolesAssigned",
  "IsInRaid", "IsInGroup", "GetNumGroupMembers",
  "GetSpellInfo", "GetSpellTexture",
  "GetTime", "SendChatMessage",
  "RAID_CLASS_COLORS",

  -- UI
  "CreateFrame", "UIParent", "GameTooltip",
  "GameFontNormal", "GameFontNormalLarge", "GameFontNormalSmall", "GameFontHighlightSmall",
}
