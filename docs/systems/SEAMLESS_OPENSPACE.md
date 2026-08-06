# Seamless Open Space (SC-like continuum)

**Scene:** `res://scenes/world/OpenSpace.tscn` (main scene)  
**Status:** v1 playable — free flight, 3 bodies, pads, origin rebase, exit/enter ship

## System requirements (targets)
| | CPU | GPU | RAM |
|--|-----|-----|-----|
| Min | i3 4-core | RTX 1060 3GB | 16 GB |
| Rec | i7 8-core | RTX 3060 12GB | 32 GB |
| Max | i9 | RTX 4060 12GB | 64 GB |

Quality tiers: `GraphicsQuality` autoload F1 cycle LOW→MEDIUM→HIGH→ULTRA.

## Architecture
- **FloatingOrigin** — rebase WorldRoot when pilot > 2.5 km from origin
- **PlanetBody** — sphere mesh + atmosphere shell + radial gravity + surface pads
- **ShipController** — SCM / NAV / HOVER; land on pad or surface; **no change_scene**
- **SurfaceWalker** — TPS on foot with planetary gravity after F exit
- **OpenSpace** — multi-planet free volume, asteroid belt, HUD

## Controls
| Key | Action |
|-----|--------|
| WASD / Space / Shift | Thrust / lift |
| Mouse | Look |
| 1 / 2 / 3 | SCM / NAV / HOVER |
| E | Land (pad/surface) / Launch |
| F | Exit ship (if landed) / Enter ship |
| Q | Fire |
| R | Attach extractor module |
| F1 | Cycle graphics quality |
| Tab | → TestArena (combat sandbox) |

## Bodies (v1)
1. **Nex-Prime** (Cybernex) R=1400 — 3 pads  
2. **ROT-Hive** (gROT) R=1100 — 3 pads  
3. **Shard-Moon** R=420 — no base  

## Roadmap (same month, 20k assets + code)
- [x] v1 seamless continuum + modes + origin
- [x] Surface chunk height detail + **editable** heightfield (PlanetTerrainEdit, NMS caps)\n- [x] Station/ship interior pockets (procedural)
- [ ] Colony buildings stream on pads (HQ GLBs)
- [ ] Atmosphere shader (height fog band)
- [ ] Multi-seat / cargo gameplay on surface
- [ ] Quantum-lite travel between distant markers (optional)
