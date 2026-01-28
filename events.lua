local _, THH = ...

THH.InitDB()
if C_Timer and C_Timer.After then
  C_Timer.After(1.0, function()
    THH.UpdateWaypointForZone()
  end)
  C_Timer.After(3.0, function()
    THH.UpdateWaypointForZone()
  end)
end

local retryTicker
local function StartRetryWindow()
  if retryTicker then return end
  if not C_Timer or not C_Timer.NewTicker then return end
  local startAt = GetTime()
  retryTicker = C_Timer.NewTicker(1.0, function()
    THH.UpdateWaypointForZone()
    if THH.lastMarkerKey then
      retryTicker:Cancel()
      retryTicker = nil
      return
    end
    if GetTime() - startAt > 15 then
      retryTicker:Cancel()
      retryTicker = nil
    end
  end)
end

StartRetryWindow()

local ticker = C_Timer.NewTicker(1.0, function()
  THH.UpdateWaypointForZone()
end)

local events = CreateFrame("Frame")

local function OnEvent(_, event)
  if event == "PLAYER_LOGIN" then
    THH.InitDB()
    THH.UpdateWaypointForZone()
    StartRetryWindow()
    return
  end

  if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
    THH.UpdateWaypointForZone()
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
  local eventsToRegister = {
    "PLAYER_LOGIN",
    "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA",
    "VIGNETTES_UPDATED",
    "VIGNETTE_MINIMAP_UPDATED",
    "COMBAT_LOG_EVENT_UNFILTERED",
  }

  local registeredCount = 0
  for _, eventName in ipairs(eventsToRegister) do
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

  if ticker then
    ticker:Cancel()
    ticker = nil
  end
end

RegisterEvents()
