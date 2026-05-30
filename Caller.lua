local ADDON_NAME, ns = ...
local Caller = {}
ns.Caller = Caller

local addon
local lastSent = {} -- [caster .. "/" .. spell] = GetTime() of last whisper

local function shortName(name)
  if not name or name == "" then
    return nil
  end
  return (name:match("^([^%-]+)") or name)
end

function Caller:Initialize(parent)
  addon = parent
end

-- Replace {spell}, {caster}, {target} tokens in the message template.
function Caller:Format(call)
  local target = ""
  if UnitExists("target") and UnitIsPlayer("target") then
    target = UnitName("target") or ""
  end
  local msg = call.message or "{spell}!"
  msg = msg:gsub("{spell}", call.name or "?")
  msg = msg:gsub("{caster}", shortName(call.caster) or "")
  msg = msg:gsub("{target}", target)
  return (msg:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Send the request for a single call. Returns true plus the recipient and the
-- sent text on success, or false plus a reason string.
function Caller:Send(call)
  if not call then
    return false, "no call"
  end
  if not addon.db.profile.enabled then
    return false, "CooldownCall is disabled (/cc on)"
  end

  local caster = call.caster
  if not caster or caster:trim() == "" then
    return false, ("no player assigned to %s"):format(call.name or "?")
  end

  local throttle = addon.db.profile.throttle or 0
  if throttle > 0 then
    local k = caster .. "/" .. (call.name or "?")
    local now = GetTime()
    if lastSent[k] and (now - lastSent[k]) < throttle then
      return false, "throttled (just sent that)"
    end
    lastSent[k] = now
  end

  local text = self:Format(call)
  if text == "" then
    return false, "message is empty"
  end

  SendChatMessage(text, "WHISPER", nil, caster)
  return true, caster, text
end
