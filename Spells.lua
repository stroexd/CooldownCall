local ADDON_NAME, ns = ...
local Spells = {}
ns.Spells = Spells

-- Per-class catalog of raid cooldowns worth requesting from a teammate.
-- `id` is any rank of the spell; the localized name and icon are resolved
-- from it at runtime, so one entry covers every rank and client locale.
-- `en` is a fallback name used only if the id cannot be resolved.
-- `role` groups/sorts the on-screen bars and gives a sensible ordering.
Spells.CATALOG = {
  PRIEST = {
    { id = 10060, en = "Power Infusion", role = "Throughput" },
    { id = 33076, en = "Prayer of Mending", role = "Heal" },
  },
  DRUID = {
    { id = 29166, en = "Innervate", role = "Mana" },
    { id = 26994, en = "Rebirth", role = "Combat Rez" },
  },
  PALADIN = {
    { id = 10278, en = "Blessing of Protection", role = "Defensive" },
    { id = 27148, en = "Blessing of Sacrifice", role = "Defensive" },
    { id = 1044, en = "Blessing of Freedom", role = "Utility" },
    { id = 27154, en = "Lay on Hands", role = "Defensive" },
    { id = 19752, en = "Divine Intervention", role = "Defensive" },
  },
  HUNTER = {
    { id = 34477, en = "Misdirection", role = "Threat" },
  },
  SHAMAN = {
    { id = 974, en = "Earth Shield", role = "Defensive" },
    { id = 2825, en = "Bloodlust", role = "Throughput" },
    { id = 32182, en = "Heroism", role = "Throughput" },
    { id = 16190, en = "Mana Tide Totem", role = "Mana" },
  },
  MAGE = {
    { id = 10170, en = "Dampen Magic", role = "Utility" },
    { id = 6117, en = "Amplify Magic", role = "Utility" },
  },
  WARLOCK = {
    { id = 27239, en = "Soulstone Resurrection", role = "Combat Rez" },
  },
  WARRIOR = {
    { id = 3411, en = "Intervene", role = "Defensive" },
  },
}

-- Lower number = higher up in the bar list.
Spells.ROLE_ORDER = {
  ["Combat Rez"] = 1,
  ["Defensive"] = 2,
  ["Mana"] = 3,
  ["Throughput"] = 4,
  ["Threat"] = 5,
  ["Heal"] = 6,
  ["Utility"] = 7,
}

function Spells:RoleRank(role)
  return self.ROLE_ORDER[role] or 99
end

-- Resolve a display name for a spell id, falling back to a provided string.
function Spells:Name(id, fallback)
  if id then
    local name = GetSpellInfo(id)
    if name and name ~= "" then
      return name
    end
  end
  return fallback
end

-- Resolve an icon texture for a spell id (nil if unknown).
function Spells:Icon(id)
  if not id then
    return nil
  end
  return (GetSpellTexture(id))
end

-- The catalog list for a class file token, or an empty table.
function Spells:ForClass(classFile)
  return self.CATALOG[classFile] or {}
end
