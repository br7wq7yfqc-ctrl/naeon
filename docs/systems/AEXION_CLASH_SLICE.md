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
- Towers mid each lane: live Turrets (faction fire, 160 HP, +28 soft pressure on death)
- ClashRadar Control HUD
- Dummies spawn from `lane_spawn_table()`

## Soft lane objectives
| Action | Pressure | Soft WS |
|--------|----------|---------|
| Kill on lane | +12 | via kill WS |
| Near gROT nexus | +1.2–3.5 /0.25s | — |
| Forward of z=-10 | +0.8 /0.25s | — |
| Lane hits 100 | claim once | **+2** |
| All 3 lanes | match win | win WS |

Never permanent map control. Daily WS still capped at 60.
