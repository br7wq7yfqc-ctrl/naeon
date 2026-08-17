# Aexion Clash vertical slice

**Stage:** S1 · **Bar:** Predecessor/Paragon readability + soft world influence  
**Skill:** naeon-holistic-economical v1.4 §4.4

## Rules (implemented)
| Rule | Value |
|------|-------|
| Daily War Score cap | **60** |
| Kill WS | 1.5 |
| Match win WS | 8 |
| Soft influence | ≤20% of match WS, max 4 — **temporary**, never permanent planet flip |
| Layer | Arena via LayerContext |
| Exit | O → OpenSpace · Tab → SpaceTest |

## Non-goals
Full MOBA lanes, items shop P2W, arena flipping capitals.

## Play
OpenSpace → **M** or **Tab** → TestArena Clash · kill dummies to 5 · soft influence toast

## Camera (AR-A)
- TestArena / Clash hero: over-the-shoulder 3rd person (`PlayerController.apply_clash_ots`)
- Right-shoulder boom, FOV 70, default pitch −8°, clamp blocks top-down RTS
- Same 3 strips; no new map, no travel-mode name, no G5

## Lane readability (0.3.3+)
- TOP +X cyan · MID gold · BOT -X magenta strips + Label3D
- NEXUS Cybernex south (+Z) / gROT north (-Z)
- Lane structures (AR-B): OUTER / MID / INHIB / CORE as live `Turret` HP on the same 60×60; one INHIB per side (core gate); no P2W repair
- OUTER still fires (160 HP, +28 soft pressure); MID/INHIB/CORE take damage; enemy CORE down = soft match win
- ClashRadar Control HUD
- Lane waves (AR-C): `ClashWaves` timed `CombatDummy` proxies march TOP/MID/BOT toward enemy OUTER; hit/be-hit via existing Turret hooks; no shop / P2W / new GLB

## Soft lane objectives
| Action | Pressure | Soft WS |
|--------|----------|---------|
| Kill on lane | +12 | via kill WS |
| Near gROT nexus | +1.2–3.5 /0.25s | — |
| Forward of z=-10 | +0.8 /0.25s | — |
| Lane hits 100 | claim once | **+2** |
| All 3 lanes | match win | win WS |

Never permanent map control. Daily WS still capped at 60.
