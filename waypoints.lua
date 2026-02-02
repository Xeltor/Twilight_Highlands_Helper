local _, THH = ...

local function RecordWaypoint(_, _)
  return
end

function THH.SetTomTomWaypoint(mapID, x, y, title)
  if not TomTom or not TomTom.AddWaypoint then return nil end
  if THH.lastTomTomWaypoint and TomTom.RemoveWaypoint then
    TomTom:RemoveWaypoint(THH.lastTomTomWaypoint)
    THH.lastTomTomWaypoint = nil
  end
  local waypoint = TomTom:AddWaypoint(mapID, x, y, {
    title = title or "Twilight Highlands",
    source = "Twilight Highlands Helper",
    persistent = false,
    minimap = true,
    world = true,
  })
  THH.lastTomTomWaypoint = waypoint
  return waypoint
end

function THH.SetInGameWaypoint(mapID, x, y)
  if not mapID then return false end
  if not C_Map or not C_Map.SetUserWaypoint then return false end
  if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(mapID) then
    return false
  end
  local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
  C_Map.SetUserWaypoint(point)
  if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
  end
  return true
end

function THH.ClearWaypoints()
  if TomTom and TomTom.RemoveWaypoint and TomTom.waypoints then
    for _, waypoint in pairs(TomTom.waypoints) do
      if waypoint and waypoint.title and waypoint.title:find("^THH:") then
        TomTom:RemoveWaypoint(waypoint)
      end
    end
  end
  if THH.lastTomTomWaypoint and TomTom and TomTom.RemoveWaypoint then
    TomTom:RemoveWaypoint(THH.lastTomTomWaypoint)
    THH.lastTomTomWaypoint = nil
  end

  if C_Map and C_Map.ClearUserWaypoint then
    C_Map.ClearUserWaypoint()
  end
end

function THH.SetWaypoint(mapID, x, y, title)
  local markerTitle = title and ("THH: " .. title) or "THH: Twilight Highlands"
  local usedTomTom = THH.SetTomTomWaypoint(mapID, x, y, markerTitle)
  if usedTomTom then
    RecordWaypoint("tomtom", markerTitle)
    return true
  end

  if THH.SetInGameWaypoint(mapID, x, y) then
    RecordWaypoint("ingame", markerTitle)
    return true
  end

  RecordWaypoint("failed", "no TomTom / cannot set user waypoint")
  return false
end
