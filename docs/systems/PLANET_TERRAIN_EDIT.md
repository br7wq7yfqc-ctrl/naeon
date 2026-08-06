# Planet Terrain Edit (NMS-like, limited)

**Status:** Vertical slice · **Cost:** 0 Tripo (procedural)

## Goal
Near-surface **editable heightfield** inspired by No Man's Sky terrain manipulator, with **hard limits** so low-end clients stay stable and no P2W terraforming power.

## Model
| Layer | Role |
|-------|------|
| Sphere LOD | Far/mid planet shell (unchanged) |
| SurfaceDetail | Cheap decorative noise patches |
| **PlanetTerrainEdit** | Active plate under player: base FBM + edit deltas |

## Limits (enforced)
| Cap | Value |
|-----|-------|
| Max delta per cell | ±8 m |
| Brush radius | ~4.5 m |
| Total edit volume / planet | 4000 m³ abs |
| Persistence | `user://terrain_<id>.dat` local only |

Exceeding volume → edit blocked (`budget_exhausted`). Not purchasable.

## Controls (on foot, near surface)
| Key | Action |
|-----|--------|
| **G** | Raise terrain |
| **B** | Lower / dig |

## Faction / economy
- Edits are **cosmetic + navigation** (cover, paths). No claim power, no combat stat from terraforming.
- Future: optional Contribution sink for **alliance-shared** landscape projects (still soft).

## Perf
- Single plate ~33² verts, trimesh collision only while near surface
- Hidden above ~120 m alt
- Tier LOW: can reduce RES later

## Out of scope (later)
- Full planetary voxel shell
- Multiplayer authoritative terrain sync
- Underwater caves network


## Controls (updated)
| Key | Action |
|-----|--------|
| G | Raise |
| B | Dig |
| U | Undo last stroke (stack depth 12) |

## FX
Brush torus: green raise / orange dig under player.
