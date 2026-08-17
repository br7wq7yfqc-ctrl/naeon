# Planet Relief — mountains / water / canyons / caves

## Problem
Planets must **not** read as flat featureless spheres. Macro LOD is spherical shell; near-surface chunks must show **real geography**.

## Feature set (required)
| Feature | Feel | Height rule |
|---------|------|-------------|
| **Mountains / ridges** | scarp & peaks | ridged multi-octave noise |
| **Hills / plains** | rolling base | low FBM |
| **Seas / oceans** | water basins | continent mask + sea_level flatten |
| **Rivers** | flow lines | meander carve SDF |
| **Canyons** | deep cuts | sharp negative trenches |
| **Caves** | subterranean | cave_openness SDF (mesh F3) |

## Phases
| Phase | Deliverable | Status |
|-------|-------------|--------|
| **R0** | PlanetRelief sampler API | done |
| **R1** | SurfaceDetail uses relief + shore/ocean/alpine colors | done |
| **R2** | Water material / sea plane juice | next |
| **R3** | Cave mouths + tunnel SDF near player | queued |
| **R4** | Macro ocean/land bands on far sphere | OS-A (`WORLD_FILL.md` §5) — same FBM / seed / sphere_xz |
| **R5** | Per-planet profiles | done (with R0) |
| **R6** | Terrain edit respects sea floor & caves | later |

## Continuum
Ship landing and SurfaceWalker must stand on the **same** PlanetRelief height.

## Performance
Analytic noise only at R1; chunk budget unchanged; caves only NEAR LOD later.
