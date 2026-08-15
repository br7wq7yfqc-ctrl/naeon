# Session Status

**2026-08-15**
Full code audit + hardening: 101 scripts / 10 scenes / 12 autoloads, ~110
confirmed defects, blockers fixed. Single record:
**`docs/PROTOTYPE_TO_PLAYABLE.md`**. No DMG.

**Skill:** sequential-dev + holistic v2.0

## What changed for playability

| Was | Now |
|-----|-----|
| Invisible floor slab over ~77% of the arena, plus a walkable wall down the MID lane | Wall-sized shape, moved off the lane; every probe rests at `y=0.750`, worst step `0.000` |
| Flat ground read as a cliff on every planet | `get_floor_angle(_up)` — walker at full speed, rover at real grip |
| Body / camera / rover drive direction snapped 90° near world ±Z | Parallel-transported tangent frame |
| Turrets fired 7–13× too slowly, and slower on faster machines | Cooldown drains the gated interval |
| Pads could freeze in CONTESTED forever | Contest holds transition 1.0; decay always reachable |
| Economy died after ~3 min (42 per pad, ever) | Reserves regenerate while idle |
| Leaving a pad cost ~79% of speed per second | `approach_assist` sign fixed, delta-scaled |
| Knowledge bought +15% weapon damage | Removed (rules/08) |
| Friendly fire via Hack, dummies and your own towers | Guarded at the receiver |
| Infection was cosmetic | `take_damage(amount, source_faction)` amplifies gROT |
| Walker refilled in place; attackers never disengaged | Real downed window + `is_downed()` |
| Match ended silently | Result panel, Enter rematches |
| War Score daily cap reset on every arena load | Persisted to `user://` |
| Pads leaked per visited planet | Real unload; flat at 502 nodes across two laps |
| Knock used world Y on a sphere | Built in the target's own ground plane |
| Walker ignored rebinds and gamepad | Movement/sprint read the InputMap first |
| Every launch began at a 76% stall; HOVER could refuse to descend | Launch stays in HOVER; hold altitude only captured in a gravity well |

## Gate

`scripts/playtest_headless_smoke.sh` →
`OS_ERR=0 · TA_ERR=0 · MM_ERR=0 · MECH_CODE=0 · MECH_ERR=0 · [Playtest] PASS`

Plus two measurements: arena floor geometry probe and a two-lap pad streaming
leak test. Both in `docs/PROTOTYPE_TO_PLAYABLE.md` §2.

## Tracks

| Track | Status |
|-------|--------|
| Design VS + campaign + constructor/side/edu templates | **Gaps closed** |
| B | Continuum: land gate, HOVER hold, stall, EVA tether + fuel, hull crit, afterburn |
| C | Walker coyote/jump-cut/slope/downed; rover grip + parked-while-boarded; interiors; pocket HUD |
| A | Clash towers live; lanes/K/D/beacons; pad-guard; bolt sweep; Rot Surge reaches everything |
| D | Design ready (constructor + 26) |
| E | Act I implement first |

## Debt left open

- Mac 10-minute soak for the FPS half of rules/25 — this VM is llvmpipe, so only
  the memory half could be signed off.
- A few correct signals still have no listeners; the arena hero's procedural
  silhouette has no locomotion animation (art work). Both in
  `docs/PROTOTYPE_TO_PLAYABLE.md` §6.

## Marathon 2026-08-08T00:37:18.886364+00:00
- dig continuum + cave protect + crystal V scan + FOV

## 2026-08-14 bind
- OCR-bound 213 sheets → 129 catalog positions
- Tripo image-to-model batch in flight
