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

-- The {spell} token becomes a clickable in-game spell link when we know the
-- spell id; otherwise it falls back to the plain (localized) spell name.
local function spellToken(call)
  if call.spellID then
    local link = GetSpellLink(call.spellID)
    if link and link ~= "" then
      return link
    end
  end
  return call.name or "?"
end

-- Replace {spell}, {caster}, {target} tokens in the message template.
-- Function replacements are used so link text containing magic characters
-- (|, [, ]) is inserted verbatim.
function Caller:Format(call)
  local target = ""
  if UnitExists("target") and UnitIsPlayer("target") then
    target = UnitName("target") or ""
  end
  local spell = spellToken(call)
  local caster = shortName(call.caster) or ""

  local msg = call.message or "{spell}!"
  msg = msg:gsub("{spell}", function()
    return spell
  end)
  msg = msg:gsub("{caster}", function()
    return caster
  end)
  msg = msg:gsub("{target}", function()
    return target
  end)
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

  -- Only ever whisper someone who is currently in your group/raid. Saved calls
  -- stay on disk but are inert otherwise, so a stored call can't be used to
  -- whisper an arbitrary player later.
  if not ns.Roster:InGroup(caster) then
    return false, ("%s is not in your group"):format(shortName(caster) or caster)
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
