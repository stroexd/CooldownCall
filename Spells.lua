local ADDON_NAME, ns = ...
local Spells = {}
ns.Spells = Spells

-- Per-class catalog of raid cooldowns worth requesting from a teammate.
-- `id` is any rank of the spell; the localized name and icon are resolved
-- from it at runtime, so one entry covers every rank and client locale.
-- `en` is a fallback name used only if the id cannot be resolved.
-- `role` groups/sorts the on-screen bars and gives a sensible ordering.
-- `cd` is the spell's TBC cooldown in seconds, used to show a countdown after
-- the caster uses it (combat-log driven; nil/0 = no timer shown). These are
-- base values — talents/glyphs that shorten them are not accounted for.
Spells.CATALOG = {
  PRIEST = {
    { id = 10060, en = "Power Infusion", role = "Throughput", cd = 180 },
    { id = 33076, en = "Prayer of Mending", role = "Heal", cd = 10 },
  },
  DRUID = {
    { id = 29166, en = "Innervate", role = "Mana", cd = 360 },
    { id = 26994, en = "Rebirth", role = "Combat Rez", cd = 1800 },
  },
  PALADIN = {
    { id = 10278, en = "Blessing of Protection", role = "Defensive", cd = 300 },
    { id = 27148, en = "Blessing of Sacrifice", role = "Defensive", cd = 120 },
    { id = 1044, en = "Blessing of Freedom", role = "Utility", cd = 25 },
    { id = 27154, en = "Lay on Hands", role = "Defensive", cd = 3600 },
    { id = 19752, en = "Divine Intervention", role = "Defensive", cd = 3600 },
  },
  HUNTER = {
    { id = 34477, en = "Misdirection", role = "Threat", cd = 30 },
  },
  SHAMAN = {
    { id = 974, en = "Earth Shield", role = "Defensive", cd = 0 },
    { id = 2825, en = "Bloodlust", role = "Throughput", cd = 600 },
    { id = 32182, en = "Heroism", role = "Throughput", cd = 600 },
    { id = 16190, en = "Mana Tide Totem", role = "Mana", cd = 300 },
  },
  MAGE = {
    { id = 10170, en = "Dampen Magic", role = "Utility", cd = 0 },
    { id = 6117, en = "Amplify Magic", role = "Utility", cd = 0 },
  },
  WARLOCK = {
    { id = 27239, en = "Soulstone Resurrection", role = "Combat Rez", cd = 1800 },
  },
  WARRIOR = {
    { id = 3411, en = "Intervene", role = "Defensive", cd = 30 },
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
