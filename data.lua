local _, THH = ...

THH.DEFAULT_MAP_ID = 241 -- Twilight Highlands
THH.SPAWN_INTERVAL_SECONDS = 300
-- Grace window after interval start to avoid pointing at next before event appears.
THH.EVENT_START_GRACE_SECONDS = 60
-- Hysteresis for waypoint visibility.
THH.NEAR_HIDE_YARDS = 50
THH.NEAR_SHOW_YARDS = 100
-- Fallback schedule anchor disabled (using detections only).

THH.RARE_SEQUENCE = {
  { name = "Redeye the Skullchewer", npc = 246572, vignette = 7007, map = 241, x = 0.650, y = 0.526 },
  { name = "T'aavihan the Unbound", npc = 246844, vignette = 7043, map = 241, x = 0.576, y = 0.756 },
  { name = "Ray of Putrescence", npc = 246460, vignette = 6995, map = 241, x = 0.710, y = 0.299 },
  { name = "Ix the Bloodfallen", npc = 246471, vignette = 6997, map = 241, x = 0.467, y = 0.252 },
  { name = "Commander Ix'vaarha", npc = 246478, vignette = 6998, map = 241, x = 0.452, y = 0.488 },
  { name = "Sharfadi, Bulwark of the Night", npc = 246559, vignette = 7004, map = 241, x = 0.418, y = 0.165 },
  { name = "Ez'Haadosh the Liminality", npc = 246549, vignette = 7001, map = 241, x = 0.652, y = 0.522 },
  { name = "Berg the Spellfist", npc = 237853, vignette = 6755, map = 241, x = 0.576, y = 0.756 },
  { name = "Corla, Herald of Twilight", npc = 237997, vignette = 6761, map = 241, x = 0.712, y = 0.299 },
  { name = "Void Zealot Devinda", npc = 246272, vignette = 6988, map = 241, x = 0.468, y = 0.248 },
  { name = "Asira Dawnslayer", npc = 246343, vignette = 6994, map = 241, x = 0.452, y = 0.492 },
  { name = "Archbishop Benedictus", npc = 246462, vignette = 6996, map = 241, x = 0.426, y = 0.176 },
  { name = "Nedrand the Eyegorger", npc = 246577, vignette = 7008, map = 241, x = 0.654, y = 0.530 },
  { name = "Executioner Lynthelma", npc = 246840, vignette = 7042, map = 241, x = 0.576, y = 0.756 },
  { name = "Gustavan, Herald of the End", npc = 246565, vignette = 7005, map = 241, x = 0.712, y = 0.316 },
  { name = "Voidclaw Hexathor", npc = 246578, vignette = 7009, map = 241, x = 0.466, y = 0.254 },
  { name = "Mirrorvise", npc = 246566, vignette = 7006, map = 241, x = 0.452, y = 0.490 },
  { name = "Saligrum the Observer", npc = 246558, vignette = 7003, map = 241, x = 0.426, y = 0.176 },
}

THH.SPECIAL_RARES = {
  { name = "Voice of the Eclipse", npc = 253378, vignette = 7340, map = 241 },
}
