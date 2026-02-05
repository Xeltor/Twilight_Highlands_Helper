local _, THH = ...

THH.InitDB()

local function IsInTargetZone()
  local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  return mapID == THH.DEFAULT_MAP_ID
end

local events = CreateFrame("Frame")
local useEvents = false
local tickerActive = false
local zoneEventsRegistered = false

local ZONE_EVENTS = {
  "VIGNETTES_UPDATED",
  "VIGNETTE_MINIMAP_UPDATED",
  "COMBAT_LOG_EVENT_UNFILTERED",
}

local function RegisterZoneEvents()
  if not useEvents or zoneEventsRegistered then return end
  for _, eventName in ipairs(ZONE_EVENTS) do
    pcall(events.RegisterEvent, events, eventName)
  end
  zoneEventsRegistered = true
end

local function UnregisterZoneEvents()
  if not zoneEventsRegistered then return end
  for _, eventName in ipairs(ZONE_EVENTS) do
    pcall(events.UnregisterEvent, events, eventName)
  end
  zoneEventsRegistered = false
end

local function TickLoop()
  if not tickerActive then return end
  THH.UpdateWaypointForZone()
  C_Timer.After(1.0, TickLoop)
end

local function StartTicker()
  if tickerActive then return end
  tickerActive = true
  TickLoop()
end

local function StopTicker()
  tickerActive = false
end

local function OnZoneCheck()
  if IsInTargetZone() then
    if useEvents then
      RegisterZoneEvents()
    else
      StartTicker()
    end
    THH.UpdateWaypointForZone()
  else
    if useEvents then
      UnregisterZoneEvents()
    else
      StopTicker()
    end
    THH.UpdateWaypointForZone()
  end
end

local function OnEvent(_, event)
  if event == "PLAYER_LOGIN" then
    THH.InitDB()
    OnZoneCheck()
    return
  end

  if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
    OnZoneCheck()
    return
  end

  if event == "VIGNETTES_UPDATED" or event == "VIGNETTE_MINIMAP_UPDATED" then
    THH.UpdateWaypointForZone()
    return
  end

  if event == "COMBAT_LOG_EVENT_UNFILTERED" then
    local _, subEvent, _, _, _, _, _, _, destName, _, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
    if subEvent == "UNIT_DIED" or subEvent == "PARTY_KILL" then
      local index = THH.FindRareIndexByNpc(THH.GetNpcIdFromGUID(destGUID)) or THH.FindRareIndexByName(destName)
      if index then
        if THH.RecordDetection then
          THH.RecordDetection(index, "combat", true)
        end
        THH.DB.nextIndex = (index % #THH.RARE_SEQUENCE) + 1
        THH.DB.hasProgress = true
        THH.UpdateWaypointForZone()
      end
    end
  end
end

local GLOBAL_EVENTS = {
  "PLAYER_LOGIN",
  "PLAYER_ENTERING_WORLD",
  "ZONE_CHANGED_NEW_AREA",
}

local function RegisterEvents()
  if events.isRegistered then return end
  if not (THH.DB and THH.DB.allowEvents) then
    return
  end
  if events.IsForbidden and events:IsForbidden() then
    return
  end
  if InCombatLockdown and InCombatLockdown() then
    C_Timer.After(1, RegisterEvents)
    return
  end

  local registeredCount = 0
  for _, eventName in ipairs(GLOBAL_EVENTS) do
    local ok, registered = pcall(events.RegisterEvent, events, eventName)
    if ok and registered ~= false then
      registeredCount = registeredCount + 1
    end
  end
  events:SetScript("OnEvent", OnEvent)

  if registeredCount == 0 then
    return
  end

  events.isRegistered = true
  useEvents = true

  if IsInTargetZone() then
    RegisterZoneEvents()
  end
end

RegisterEvents()

-- If event registration failed, use ticker as fallback (only when in zone)
if not useEvents and IsInTargetZone() then
  StartTicker()
end

-- Initial update for players already in the zone on load
if C_Timer and C_Timer.After then
  C_Timer.After(1.0, OnZoneCheck)
end
