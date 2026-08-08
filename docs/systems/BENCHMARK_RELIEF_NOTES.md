# Benchmark notes (SC / NMS / continuum)

No local reference videos in repo this session. Product-benchmark notes:

## Star Citizen
- Seamless atmo: density fog ramp
- Mountains readable at distance; canyons for landing drama
- Water: reflective patches + foam line (not full ocean sim on weak GPU)
- Caves: dark mouths first, interiors streamed later
- Ship↔FPS: same collision height

## No Man's Sky
- Editable terrain budget
- Biome colors + fauna by biome
- Water planes + shore blend
- Cave entrances as negative space

## EVE / Stellaris (space)
- Far LOD: planet disks with ocean/land albedo (R4)

## Mapping
| Feel | Track |
|------|-------|
| Non-flat terrain | PlanetRelief R0–R1 done |
| Water | SurfaceWater R2 done |
| Cave mouths | CaveMouthField R3 prototype done |
| Height continuum | Walker relief snap done |
| Macro paint | R4 next |

Updated: 2026-08-08T00:14:55.061395+00:00
