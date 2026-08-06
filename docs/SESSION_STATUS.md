# NAEON — Session Status

**Last update:** 2026-08-06  
**Mode:** Unified multi-track session (A + B + C)

## Tracks
| Track | Focus | Status |
|-------|--------|--------|
| A | TPS + Ability + Ownership + TestArena | Playable + combat dummies + crate props |
| B | ShipController + modules + colony seed | SpaceTest playable |
| C | Tripo→Blender→dual-theme→neon | E2E verified (sci_fi_crate) |

## Infra
- Mac: Godot 4.3, Blender 4.5.12, rclone, Docker, Grok CLI
- Tripo: paid key working (budget ~1k–1.5k credits after smoke)
- Bucket neon: read/write OK via path-style `neon:neon/dev`
- Target VM 158.160.185.220: SSH still blocked pending perimeter

## Recent code
- `godot/scripts/combat/CombatDummy.gd`
- `godot/scenes/combat/CombatDummy.tscn`
- `godot/scripts/assets/GlbProp.gd`
- TestArena spawns dummies + GLB crates
