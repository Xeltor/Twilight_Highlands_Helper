local _, THH = ...

THH.RARE_BY_NPC = {}
THH.RARE_BY_VIGNETTE = {}
THH.SPECIAL_BY_NPC = {}
THH.SPECIAL_BY_VIGNETTE = {}

function THH.InitDB()
  THH.DB = THH.DB or {}
  if THH.DB.enabled == nil then
    THH.DB.enabled = true
  end
  THH.currentState = THH.DB.currentState
  -- Force a fresh marker set after reload; keep saved values in DB only.
  THH.lastMarkerKey = nil
  THH.activeVisibleIndex = nil

  if not next(THH.RARE_BY_NPC) then
    for i, rare in ipairs(THH.RARE_SEQUENCE) do
      if rare.npc then
        THH.RARE_BY_NPC[rare.npc] = i
      end
      if rare.vignette then
        THH.RARE_BY_VIGNETTE[rare.vignette] = i
      end
    end
  end
  if not next(THH.SPECIAL_BY_NPC) and THH.SPECIAL_RARES then
    for i, rare in ipairs(THH.SPECIAL_RARES) do
      if rare.npc then
        THH.SPECIAL_BY_NPC[rare.npc] = i
      end
      if rare.vignette then
        THH.SPECIAL_BY_VIGNETTE[rare.vignette] = i
      end
    end
  end
end

function THH.IsEnabled()
  return THH.DB and THH.DB.enabled ~= false
end
