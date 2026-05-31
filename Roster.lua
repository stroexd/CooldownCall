local ADDON_NAME, ns = ...
local Roster = {}
ns.Roster = Roster

local function stripRealm(name)
  if not name then
    return nil
  end
  return (name:match("^([^%-]+)") or name)
end

-- Returns an array of { name, class, classFile, role } for everyone in the
-- current group (raid or party), including the player. Empty list when solo.
function Roster:Members()
  local out = {}
  local seen = {}

  local function add(unit)
    if not UnitExists(unit) then
      return
    end
    local name = UnitName(unit)
    if not name or seen[name] then
      return
    end
    seen[name] = true
    local _, classFile = UnitClass(unit)
    local role
    if UnitGroupRolesAssigned then
      local r = UnitGroupRolesAssigned(unit)
      if r and r ~= "NONE" then
        role = r
      end
    end
    table.insert(out, {
      name = name,
      classFile = classFile,
      role = role,
    })
  end

  if IsInRaid() then
    for i = 1, GetNumGroupMembers() do
      add("raid" .. i)
    end
  else
    add("player")
    for i = 1, 4 do
      add("party" .. i)
    end
  end

  table.sort(out, function(a, b)
    return (a.name or "") < (b.name or "")
  end)
  return out
end

-- Is this (possibly realm-suffixed) name currently in your group/raid? When
-- solo, only the player counts. Used to keep saved calls inert unless their
-- assigned caster is actually present, so they can't be used to whisper
-- arbitrary players later.
function Roster:InGroup(name)
  if not name then
    return false
  end
  local short = stripRealm(name)
  for _, m in ipairs(self:Members()) do
    if m.name == name or stripRealm(m.name) == short then
      return true
    end
  end
  return false
end

-- Best-effort class lookup for a (possibly realm-suffixed) name currently in
-- the group. Returns the class file token or nil.
function Roster:ClassOf(name)
  if not name then
    return nil
  end
  local short = stripRealm(name)
  for _, m in ipairs(self:Members()) do
    if m.name == name or stripRealm(m.name) == short then
      return m.classFile
    end
  end
  return nil
end
