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

function THH.PrintStatus()
  local enabled = THH.IsEnabled and THH.IsEnabled()
  local stateLabel = enabled and "enabled" or "disabled"
  SendSystemMessage(("|cffffd200Twilight Highlands Helper|r is %s."):format(stateLabel))
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
  SendSystemMessage("|cffffd200Twilight Highlands Helper|r: /thh [on|off|toggle|status]")
end
