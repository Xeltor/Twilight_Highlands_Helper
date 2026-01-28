local _, THH = ...

function THH.GetPlayerMapPosition(mapID)
  if not C_Map or not C_Map.GetPlayerMapPosition then return nil end
  local pos = C_Map.GetPlayerMapPosition(mapID, "player")
  if not pos then return nil end
  return pos:GetXY()
end

function THH.NormalizeName(name)
  if not name then return nil end
  local trimmed = name:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  trimmed = trimmed:gsub("%s*%b()", "")
  return trimmed:lower()
end

function THH.GetNpcIdFromGUID(guid)
  if not guid then return nil end
  local unitType, _, _, _, _, npcId = strsplit("-", guid)
  if unitType ~= "Creature" and unitType ~= "Vehicle" then
    return nil
  end
  return tonumber(npcId)
end

function THH.FindRareIndexByNpc(npcId)
  if not npcId then return nil end
  return THH.RARE_BY_NPC[npcId]
end

function THH.FindRareIndexByName(name)
  if not name or name == "" then return nil end
  local needle = THH.NormalizeName(name)
  if not needle or needle == "" then return nil end
  if THH.DB and THH.DB.nextIndex and THH.RARE_SEQUENCE[THH.DB.nextIndex] then
    if THH.NormalizeName(THH.RARE_SEQUENCE[THH.DB.nextIndex].name) == needle then
      return THH.DB.nextIndex
    end
  end
  for i, rare in ipairs(THH.RARE_SEQUENCE) do
    if THH.NormalizeName(rare.name) == needle then
      return i
    end
  end
  return nil
end

function THH.FindRareIndexByVignette(vignetteId)
  if not vignetteId then return nil end
  return THH.RARE_BY_VIGNETTE[vignetteId]
end

function THH.FindVisibleRare(mapID)
  if not C_VignetteInfo or not C_VignetteInfo.GetVignettes then
    return nil
  end

  local playerX, playerY = THH.GetPlayerMapPosition(mapID)
  local bestIndex, bestX, bestY
  local bestDist
  local deadIndex

  local vignettes = C_VignetteInfo.GetVignettes()
  for _, vignetteGUID in ipairs(vignettes) do
    local info = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
    if info then
      local index = THH.FindRareIndexByVignette(info.vignetteID)
      local npcId = THH.GetNpcIdFromGUID(info.objectGUID)
      if not index then
        index = THH.FindRareIndexByNpc(npcId) or THH.FindRareIndexByName(info.name)
      end
      if index then
        if info.isDead then
          deadIndex = index
        end
        local x, y = C_VignetteInfo.GetVignettePosition(vignetteGUID, mapID)
        if x and y then
          if playerX and playerY then
            local dx = x - playerX
            local dy = y - playerY
            local dist = dx * dx + dy * dy
            if not bestDist or dist < bestDist then
              bestDist = dist
              bestIndex, bestX, bestY = index, x, y
            end
          else
            bestIndex, bestX, bestY = index, x, y
            break
          end
        else
          if not bestIndex then
            bestIndex = index
          end
        end
      end
    end
  end

  if deadIndex then
    return deadIndex, nil, nil, true
  end

  if bestIndex then
    return bestIndex, bestX, bestY
  end

  return nil
end

function THH.GetVisibleRareIndex(mapID)
  local visibleIndex, vx, vy, isDead = THH.FindVisibleRare(mapID)
  if visibleIndex then
    return visibleIndex, vx, vy, isDead
  end
  return nil
end

function THH.IsEventActiveNearby(mapID)
  if not C_AreaPoiInfo or not C_AreaPoiInfo.GetEventsForMap then
    return false
  end

  local eventIds = C_AreaPoiInfo.GetEventsForMap(mapID) or {}
  if #eventIds == 0 then
    return false
  end

  for _, poiId in ipairs(eventIds) do
    local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiId)
    if info and info.isCurrentEvent then
      return true
    end
  end

  return false
end
