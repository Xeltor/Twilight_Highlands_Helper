local _, THH = ...

THH.lastDebugTick = nil
THH.lastMarkerKey = nil
THH.activeVisibleIndex = nil
THH.visibleLostAt = nil
THH.ignoreEventActiveUntil = nil
THH.recentEndedIndex = nil
THH.lastStateKey = nil
THH.currentState = nil
THH.lastDebug = nil

local function GetPlayerDistanceYards(mapID, x, y)
  if not x or not y then return false end
  local px, py = THH.GetPlayerMapPosition(mapID)
  if not px or not py then return false end

  if C_Map and C_Map.GetMapWorldSize then
    local width, height = C_Map.GetMapWorldSize(mapID)
    if width and height and width > 0 and height > 0 then
      local dx = (x - px) * width
      local dy = (y - py) * height
      return math.sqrt(dx * dx + dy * dy)
    end
  end

  local dx = x - px
  local dy = y - py
  return math.sqrt(dx * dx + dy * dy)
end

local function IsPlayerNear(mapID, x, y, yards)
  local dist = GetPlayerDistanceYards(mapID, x, y)
  if not dist then return false end
  if dist == true then return false end
  return dist <= yards
end

local function ShouldSuppressMarker(mapID, x, y)
  local hideAt = THH.NEAR_HIDE_YARDS or 25
  local showAt = THH.NEAR_SHOW_YARDS or 100
  local dist = GetPlayerDistanceYards(mapID, x, y)
  if not dist or dist == true then
    return false
  end
  if THH.nearSuppressed then
    if dist >= showAt then
      THH.nearSuppressed = false
      return false
    end
    return true
  end
  if dist <= hideAt then
    THH.nearSuppressed = true
    return true
  end
  return false
end

local function SetState(state, detail)
  if THH.currentState == state then
    return
  end
  THH.currentState = state
  if THH.DB then
    THH.DB.currentState = state
  end
end

local function ClearActiveMarker()
  THH.ClearWaypoints()
  THH.lastMarkerKey = nil
  if THH.DB then
    THH.DB.lastMarkerKey = nil
  end
end

function THH.RecordDecision(code, detail)
  THH.lastDecisionCode = code
  THH.lastDecisionDetail = detail
end

local function AlignToIntervalAnchor(nowServer)
  return nowServer
end

function THH.RecordDetection(index, source, isDead)
  if not THH.DB then return end
  local nowServer = GetServerTime()
  local alignedStart = AlignToIntervalAnchor(nowServer)
  THH.DB.lastDetection = {
    index = index,
    source = source,
    dead = isDead and true or false,
    serverTime = nowServer,
    time = date("%Y-%m-%d %H:%M:%S"),
  }
  THH.DB.lastSeenIndex = index
  THH.DB.lastSeenTime = nowServer
  THH.DB.cycleAnchorIndex = index
  THH.DB.cycleAnchorStart = alignedStart
end

local function UpdateCycleAnchor(index, detectedAt)
  if not THH.DB then return end
  local nowServer = detectedAt or GetServerTime()
  THH.DB.cycleAnchorIndex = index
  THH.DB.cycleAnchorStart = AlignToIntervalAnchor(nowServer)
end

local function GetCycleCurrentIndex()
  if not THH.DB then return nil end
  local anchorIndex = THH.DB.cycleAnchorIndex
  local anchorStart = THH.DB.cycleAnchorStart
  if not anchorIndex or not anchorStart then return nil end
  local interval = THH.SPAWN_INTERVAL_SECONDS or 600
  local cycle = #THH.RARE_SEQUENCE
  if interval <= 0 or cycle == 0 then return nil end
  local nowServer = GetServerTime()
  if nowServer < anchorStart then return nil end
  local steps = math.floor((nowServer - anchorStart) / interval)
  local currentIndex = ((anchorIndex - 1 + steps) % cycle) + 1
  local currentStart = anchorStart + (steps * interval)
  return currentIndex, currentStart
end

local function GetRegionTag()
  if type(GetCurrentRegionName) == "function" then
    local name = GetCurrentRegionName()
    if name == "US" or name == "EU" then
      return name
    end
    return nil
  end
  if type(GetCurrentRegion) == "function" then
    local region = GetCurrentRegion()
    if region == 1 then return "US" end
    if region == 3 then return "EU" end
  end
  return nil
end

local function GetFallbackScheduleCurrentIndex()
  return nil
end

local function GetTimeSinceSeenNextIndex()
  if not THH.DB then return nil end
  local lastIndex = THH.DB.lastSeenIndex
  local lastTime = THH.DB.lastSeenTime
  if not lastIndex or not lastTime then return nil end
  local interval = THH.SPAWN_INTERVAL_SECONDS or 600
  local cycle = #THH.RARE_SEQUENCE
  if interval <= 0 or cycle == 0 then return nil end
  local nowServer = GetServerTime()
  if nowServer < lastTime then return nil end
  local steps = math.floor((nowServer - lastTime) / interval)
  local currentIndex = ((lastIndex - 1 + steps) % cycle) + 1
  local currentStart = lastTime + (steps * interval)
  return currentIndex, currentStart
end

function THH.SetMarkerIfChanged(mapID, x, y, title, key)
  if THH.lastMarkerKey == key then
    return
  end
  THH.ClearWaypoints()
  local ok = THH.SetWaypoint(mapID, x, y, title)
  if not ok then
    THH.RecordDecision("SET_FAILED", title or "unknown")
    return
  end
  THH.lastMarkerKey = key
  if THH.DB then
    THH.DB.lastMarkerKey = key
  end
  if THH.DB and key and key:match("^next:%d+$") then
    local idx = tonumber(key:match("^next:(%d+)$"))
    if idx then
      THH.DB.lastIndex = idx
      THH.DB.nextIndex = idx
      THH.DB.hasProgress = true
    end
  end
end

function THH.UpdateWaypointForZone()
  if THH.IsEnabled and not THH.IsEnabled() then
    THH.lastDebug = {
      reason = "DISABLED",
      detail = nil,
      time = date("%Y-%m-%d %H:%M:%S"),
      serverTime = GetServerTime(),
      state = THH.currentState,
      lastMarkerKey = THH.lastMarkerKey,
      db = THH.DB,
    }
    return
  end
  local function SnapshotDB()
    if not THH.DB then return nil end
    return {
      lastSeenIndex = THH.DB.lastSeenIndex,
      lastSeenTime = THH.DB.lastSeenTime,
      cycleAnchorIndex = THH.DB.cycleAnchorIndex,
      cycleAnchorStart = THH.DB.cycleAnchorStart,
      nextIndex = THH.DB.nextIndex,
      hasProgress = THH.DB.hasProgress,
      lastDetection = THH.DB.lastDetection,
      currentState = THH.DB.currentState,
      activeVisibleIndex = THH.DB.activeVisibleIndex,
    }
  end

  local function CaptureDebug(reason, detail, snapshot)
    snapshot = snapshot or {}
    THH.lastDebug = {
      reason = reason,
      detail = detail,
      time = date("%Y-%m-%d %H:%M:%S"),
      serverTime = GetServerTime(),
      nowServer = snapshot.nowServer,
      mapID = snapshot.mapID,
      eventActive = snapshot.eventActive,
      eventActiveEffective = snapshot.eventActiveEffective,
      visibleIndex = snapshot.visibleIndex,
      visibleDead = snapshot.isDead,
      visibleLostThisTick = snapshot.visibleLostThisTick,
      scheduleCurrent = snapshot.scheduleCurrent,
      timeBasedCurrent = snapshot.timeBasedCurrent,
      fallbackCurrent = snapshot.fallbackCurrent,
      currentIndex = snapshot.currentIndex,
      currentStart = snapshot.currentStart,
      nextIndex = snapshot.nextIndex,
      targetIndex = snapshot.targetIndex,
      withinGrace = snapshot.withinGrace,
      source = snapshot.source,
      targetName = snapshot.targetName,
      targetX = snapshot.targetX,
      targetY = snapshot.targetY,
      recentEndedIndex = snapshot.recentEndedIndex,
      state = THH.currentState,
      lastMarkerKey = THH.lastMarkerKey,
      db = SnapshotDB(),
    }
  end

  local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
  if mapID ~= THH.DEFAULT_MAP_ID then
    THH.RecordDecision("OUT_OF_ZONE", tostring(mapID))
    SetState("OUT_OF_ZONE")
    CaptureDebug("OUT_OF_ZONE", tostring(mapID), { mapID = mapID })
    THH.startHintShown = false
    if THH.lastMarkerKey then
      THH.ClearWaypoints()
      THH.lastMarkerKey = nil
      if THH.DB then
        THH.DB.lastMarkerKey = nil
      end
      THH.activeVisibleIndex = nil
      if THH.DB then
        THH.DB.activeVisibleIndex = nil
      end
      THH.visibleLostAt = nil
    end
    return
  end

  if #THH.RARE_SEQUENCE == 0 then
    THH.RecordDecision("NO_DATA", "empty rare list")
    SetState("NO_DATA")
    CaptureDebug("NO_DATA", "empty rare list", { mapID = mapID })
    return
  end

  local eventActive = THH.IsEventActiveNearby(mapID)

  local visibleIndex, vx, vy, isDead = THH.GetVisibleRareIndex(mapID)
  local visibleLostThisTick = false
  if visibleIndex then
    THH.recentEndedIndex = nil
    THH.RecordDecision("VISIBLE", tostring(visibleIndex))
    SetState("VISIBLE", tostring(visibleIndex))
    THH.activeVisibleIndex = visibleIndex
    if THH.DB then
      THH.DB.activeVisibleIndex = visibleIndex
    end
    THH.RecordDetection(visibleIndex, "vignette", isDead)
    THH.visibleLostAt = nil
    if THH.DB then
      THH.DB.nextIndex = visibleIndex
      THH.DB.hasProgress = true
    end
    local rare = THH.RARE_SEQUENCE[visibleIndex]
    if isDead then
      SetState("VISIBLE_DEAD", tostring(visibleIndex))
      CaptureDebug("VISIBLE_DEAD", tostring(visibleIndex), {
        mapID = mapID,
        eventActive = eventActive,
        visibleIndex = visibleIndex,
        isDead = isDead,
        targetIndex = visibleIndex,
        targetName = rare and rare.name,
        targetX = rare and rare.x,
        targetY = rare and rare.y,
      })
    else
      local wx, wy = vx, vy
      if not wx or not wy then
        wx, wy = rare and rare.x, rare and rare.y
      end
      if wx and wy then
        if ShouldSuppressMarker(mapID, wx, wy) then
          THH.RecordDecision("NEAR_TARGET_VISIBLE", tostring(visibleIndex))
          SetState("NEAR_TARGET", tostring(visibleIndex))
          CaptureDebug("NEAR_TARGET_VISIBLE", tostring(visibleIndex), {
            mapID = mapID,
            eventActive = eventActive,
            visibleIndex = visibleIndex,
            isDead = isDead,
            targetIndex = visibleIndex,
            targetName = rare and rare.name,
            targetX = wx,
            targetY = wy,
          })
          ClearActiveMarker()
          return
        end
        THH.SetMarkerIfChanged(mapID, wx, wy, rare and rare.name or "Visible Rare", "visible:" .. visibleIndex)
        CaptureDebug("VISIBLE", tostring(visibleIndex), {
          mapID = mapID,
          eventActive = eventActive,
          visibleIndex = visibleIndex,
          isDead = isDead,
          targetIndex = visibleIndex,
          targetName = rare and rare.name,
          targetX = wx,
          targetY = wy,
        })
      end
      return
    end
  end

  if THH.activeVisibleIndex then
    if isDead then
      if THH.DB and THH.DB.nextIndex and THH.activeVisibleIndex == THH.DB.nextIndex then
        local nextIndex = THH.DB.nextIndex + 1
        if nextIndex > #THH.RARE_SEQUENCE then
          nextIndex = 1
        end
        THH.DB.lastSeenIndex = THH.activeVisibleIndex
        THH.DB.lastSeenTime = GetServerTime()
        THH.DB.nextIndex = nextIndex
        THH.DB.hasProgress = true
        SetState("ADVANCED_DEAD", tostring(nextIndex))
      end
      THH.activeVisibleIndex = nil
      if THH.DB then
        THH.DB.activeVisibleIndex = nil
      end
      THH.visibleLostAt = nil
    end

    local lostIndex = THH.activeVisibleIndex
    if THH.DB and THH.DB.nextIndex and THH.activeVisibleIndex == THH.DB.nextIndex then
      local nextIndex = THH.DB.nextIndex + 1
      if nextIndex > #THH.RARE_SEQUENCE then
        nextIndex = 1
      end
      THH.DB.nextIndex = nextIndex
      THH.DB.hasProgress = true
      SetState("ADVANCED_DISAPPEAR", tostring(nextIndex))
    end
    THH.activeVisibleIndex = nil
    if THH.DB then
      THH.DB.activeVisibleIndex = nil
    end
    THH.visibleLostAt = nil
    THH.recentEndedIndex = lostIndex
    visibleLostThisTick = true
    CaptureDebug("VISIBLE_LOST_CLEAR", tostring(lostIndex), {
      mapID = mapID,
      eventActive = eventActive,
      visibleIndex = lostIndex,
      isDead = isDead,
    })
  end

  local scheduleCurrent, scheduleStart = GetCycleCurrentIndex()
  local timeBasedCurrent, timeBasedStart = scheduleCurrent and nil or GetTimeSinceSeenNextIndex()
  local fallbackCurrent, fallbackStart = (scheduleCurrent or timeBasedCurrent) and nil or GetFallbackScheduleCurrentIndex()
  local currentIndex = scheduleCurrent or timeBasedCurrent or fallbackCurrent
  local currentStart = scheduleStart or timeBasedStart or fallbackStart
  local source = scheduleCurrent and "schedule" or (timeBasedCurrent and "lastSeen" or (fallbackCurrent and "fallback" or "none"))
  if not currentIndex then
    THH.RecordDecision("NO_NEXT", "no anchor, recent seen, or fallback")
    SetState("WAITING")
    CaptureDebug("NO_NEXT", "no anchor, recent seen, or fallback", {
      mapID = mapID,
      eventActive = eventActive,
      visibleIndex = visibleIndex,
      isDead = isDead,
      scheduleCurrent = scheduleCurrent,
      timeBasedCurrent = timeBasedCurrent,
      fallbackCurrent = fallbackCurrent,
      currentIndex = currentIndex,
      currentStart = currentStart,
      source = source,
      nowServer = GetServerTime(),
      visibleLostThisTick = visibleLostThisTick,
      recentEndedIndex = THH.recentEndedIndex,
    })
    if not THH.startHintShown and THH.SendSystemMessage then
      THH.startHintShown = true
      THH.SendSystemMessage("|cffffd200Twilight Highlands Helper|r: Waiting for event to appear.")
    end
    return
  end
  local nextIndex = currentIndex + 1
  if nextIndex > #THH.RARE_SEQUENCE then
    nextIndex = 1
  end

  local graceSeconds = THH.EVENT_START_GRACE_SECONDS or 0
  local nowServer = GetServerTime()
  local withinGrace = (not visibleIndex) and currentStart and (nowServer - currentStart) <= graceSeconds
  if visibleLostThisTick then
    withinGrace = false
  end

  local eventActiveEffective = eventActive
  if eventActive and not visibleIndex and not withinGrace then
    eventActiveEffective = false
  end
  if visibleLostThisTick then
    eventActiveEffective = false
  end
  if THH.recentEndedIndex and not visibleIndex and eventActiveEffective then
    if currentIndex == THH.recentEndedIndex then
      eventActiveEffective = false
    end
  end

  local targetIndex
  if eventActiveEffective then
    targetIndex = currentIndex
  else
    targetIndex = nextIndex
  end
  local targetRare = THH.RARE_SEQUENCE[targetIndex]
  if not targetRare then
    THH.RecordDecision("INVALID_NEXT", tostring(targetIndex))
    SetState("INVALID_NEXT", tostring(targetIndex))
    CaptureDebug("INVALID_NEXT", tostring(targetIndex), {
      mapID = mapID,
      eventActive = eventActive,
      visibleIndex = visibleIndex,
      isDead = isDead,
      scheduleCurrent = scheduleCurrent,
      timeBasedCurrent = timeBasedCurrent,
      fallbackCurrent = fallbackCurrent,
      currentIndex = currentIndex,
      currentStart = currentStart,
      nextIndex = nextIndex,
      targetIndex = targetIndex,
      withinGrace = withinGrace,
      source = source,
    })
    return
  end
  if targetIndex == currentIndex then
    SetState("CURRENT", tostring(targetIndex))
  else
    SetState("NEXT", tostring(targetIndex))
  end
  local stateKey = ((targetIndex == currentIndex) and "current:" or "next:") .. targetIndex
  if THH.DB and (scheduleCurrent or timeBasedCurrent or fallbackCurrent) then
    THH.DB.nextIndex = targetIndex
    THH.DB.hasProgress = true
  end
  if THH.lastStateKey ~= stateKey then
    THH.lastStateKey = stateKey
  end
  if ShouldSuppressMarker(mapID, targetRare.x, targetRare.y) then
    THH.RecordDecision("NEAR_TARGET_NEXT", tostring(targetIndex))
    SetState("NEAR_TARGET", tostring(targetIndex))
    CaptureDebug("NEAR_TARGET_NEXT", tostring(targetIndex), {
      mapID = mapID,
      eventActive = eventActive,
      visibleIndex = visibleIndex,
      isDead = isDead,
      scheduleCurrent = scheduleCurrent,
      timeBasedCurrent = timeBasedCurrent,
      fallbackCurrent = fallbackCurrent,
      currentIndex = currentIndex,
      currentStart = currentStart,
      nextIndex = nextIndex,
      targetIndex = targetIndex,
      withinGrace = withinGrace,
      source = source,
      targetName = targetRare.name,
      targetX = targetRare.x,
      targetY = targetRare.y,
    })
    ClearActiveMarker()
    return
  end
  THH.SetMarkerIfChanged(mapID, targetRare.x, targetRare.y, targetRare.name, stateKey)
  local decision = (targetIndex == currentIndex) and "SET_CURRENT" or "SET_NEXT"
  THH.RecordDecision(decision, tostring(targetIndex))
  CaptureDebug(decision, tostring(targetIndex), {
    mapID = mapID,
    eventActive = eventActive,
    visibleIndex = visibleIndex,
    isDead = isDead,
    scheduleCurrent = scheduleCurrent,
    timeBasedCurrent = timeBasedCurrent,
    fallbackCurrent = fallbackCurrent,
    currentIndex = currentIndex,
    currentStart = currentStart,
    nextIndex = nextIndex,
    targetIndex = targetIndex,
    withinGrace = withinGrace,
    source = source,
    nowServer = nowServer,
    eventActiveEffective = eventActiveEffective,
    visibleLostThisTick = visibleLostThisTick,
    recentEndedIndex = THH.recentEndedIndex,
    targetName = targetRare.name,
    targetX = targetRare.x,
    targetY = targetRare.y,
  })
end
