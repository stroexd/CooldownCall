local ADDON_NAME, ns = ...
local CD = {}
ns.CD = CD

-- We cannot query another player's spell cooldowns directly, so we watch the
-- combat log: when the assigned caster successfully casts a tracked spell, we
-- start a countdown using the spell's known cooldown duration. Bars read the
-- remaining time from here.

local addon
local ends = {} -- [call.key] = GetTime() + duration

local function short(name)
  if not name or name == "" then
    return nil
  end
  return (name:match("^([^%-]+)") or name):lower()
end

function CD:Initialize(parent)
  addon = parent
  addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function()
    CD:OnCombatLog()
  end)
end

function CD:OnCombatLog()
  local _, sub, _, _, sourceName, _, _, _, _, _, _, spellId, spellName = CombatLogGetCurrentEventInfo()
  if sub ~= "SPELL_CAST_SUCCESS" then
    return
  end

  local src = short(sourceName)
  if not src then
    return
  end

  for _, call in ipairs(addon.db.profile.calls) do
    if call.cd and call.cd > 0 and short(call.caster) == src then
      local match = (call.spellID and spellId == call.spellID) or (call.name and spellName == call.name)
      if match then
        ends[call.key] = GetTime() + call.cd
      end
    end
  end
end

-- Remaining cooldown in seconds for a call, or 0 if ready / untracked.
function CD:Remaining(call)
  local e = ends[call.key]
  if not e then
    return 0
  end
  local r = e - GetTime()
  if r <= 0 then
    ends[call.key] = nil
    return 0
  end
  return r
end

-- Format seconds as "m:ss" (>= 60s) or "Ns".
function CD:FormatTime(sec)
  if sec >= 60 then
    return ("%d:%02d"):format(math.floor(sec / 60), math.floor(sec % 60))
  end
  return ("%ds"):format(math.ceil(sec))
end
