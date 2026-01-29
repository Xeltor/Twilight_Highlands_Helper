local ADDON_NAME, THH = ...
THH = THH or {}

THH.ADDON_NAME = ADDON_NAME

local function SendSystemMessage(message)
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(message)
    return
  end
  print(message)
end

THH.SendSystemMessage = SendSystemMessage

function THH.PrintStatus()
  local enabled = THH.IsEnabled and THH.IsEnabled()
  local stateLabel = enabled and "enabled" or "disabled"
  SendSystemMessage(("|cffffd200Twilight Highlands Helper|r is %s."):format(stateLabel))
end

local function BoolText(value)
  if value == nil then return "n/a" end
  return value and "true" or "false"
end

local function NumText(value, fmt)
  if value == nil then return "n/a" end
  if fmt then
    return fmt:format(value)
  end
  return tostring(value)
end

local function TimeText(value)
  if not value then return "n/a" end
  return date("%Y-%m-%d %H:%M:%S", value)
end

function THH.PrintDebug()
  local info = THH.lastDebug
  if not info then
    SendSystemMessage("|cffffd200Twilight Highlands Helper|r: no debug data yet.")
    return
  end

  SendSystemMessage("|cffffd200Twilight Highlands Helper Debug|r")
  SendSystemMessage(("Enabled: %s | State: %s | Reason: %s%s"):format(
    BoolText(THH.IsEnabled and THH.IsEnabled()),
    info.state or "n/a",
    info.reason or "n/a",
    info.detail and (" (" .. tostring(info.detail) .. ")") or ""
  ))
  SendSystemMessage(("MapID: %s | Time: %s | NowServer: %s"):format(
    NumText(info.mapID),
    info.time or "n/a",
    TimeText(info.nowServer or info.serverTime)
  ))
  SendSystemMessage(("Event: active=%s effective=%s | Visible: idx=%s dead=%s"):format(
    BoolText(info.eventActive),
    BoolText(info.eventActiveEffective),
    NumText(info.visibleIndex),
    BoolText(info.visibleDead)
  ))
  SendSystemMessage(("Rotation: source=%s | current=%s @ %s | next=%s | target=%s | grace=%s"):format(
    info.source or "n/a",
    NumText(info.currentIndex),
    TimeText(info.currentStart),
    NumText(info.nextIndex),
    NumText(info.targetIndex),
    BoolText(info.withinGrace)
  ))
  SendSystemMessage(("Guards: recentEndedIndex=%s"):format(
    NumText(info.recentEndedIndex)
  ))
  if info.targetName or info.targetX or info.targetY then
    SendSystemMessage(("Target: %s @ %s, %s"):format(
      info.targetName or "n/a",
      NumText(info.targetX, "%.3f"),
      NumText(info.targetY, "%.3f")
    ))
  end
  if info.db then
    local lastDet = info.db.lastDetection
    if lastDet then
      SendSystemMessage(("LastDetection: idx=%s source=%s dead=%s time=%s"):format(
        NumText(lastDet.index),
        lastDet.source or "n/a",
        BoolText(lastDet.dead),
        lastDet.time or TimeText(lastDet.serverTime)
      ))
    end
    SendSystemMessage(("Anchors: lastSeen=%s @ %s | cycle=%s @ %s"):format(
      NumText(info.db.lastSeenIndex),
      TimeText(info.db.lastSeenTime),
      NumText(info.db.cycleAnchorIndex),
      TimeText(info.db.cycleAnchorStart)
    ))
    SendSystemMessage(("DB: nextIndex=%s | hasProgress=%s | activeVisible=%s"):format(
      NumText(info.db.nextIndex),
      BoolText(info.db.hasProgress),
      NumText(info.db.activeVisibleIndex)
    ))
  end
  SendSystemMessage(("LastMarkerKey: %s | DebugTime: %s"):format(
    info.lastMarkerKey or "n/a",
    info.time or "n/a"
  ))
end

SLASH_THH1 = "/thh"
SlashCmdList["THH"] = function(msg)
  if THH.InitDB then
    THH.InitDB()
  end
  local command = msg and msg:lower():match("^%s*(.-)%s*$") or ""
  if command == "" or command == "toggle" then
    THH.DB.enabled = not (THH.IsEnabled and THH.IsEnabled())
    if THH.DB.enabled == false and THH.ClearWaypoints then
      THH.ClearWaypoints()
    end
    THH.PrintStatus()
    return
  end
  if command == "on" or command == "enable" then
    THH.DB.enabled = true
    THH.PrintStatus()
    return
  end
  if command == "off" or command == "disable" then
    THH.DB.enabled = false
    if THH.ClearWaypoints then
      THH.ClearWaypoints()
    end
    THH.PrintStatus()
    return
  end
  if command == "status" or command == "state" then
    THH.PrintStatus()
    return
  end
  if command == "debug" then
    THH.PrintDebug()
    return
  end
  SendSystemMessage("|cffffd200Twilight Highlands Helper|r: /thh [on|off|toggle|status|debug]")
end
