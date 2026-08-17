# Planet Profiles

`PlanetProfileCatalog.gd`

| Body | R | Atmo H | Envelope | g | Role |
|------|---|--------|----------|---|------|
| Nex-Prime | 1400 | 320 | 1100 | 9.0 | Cybernex home |
| ROT-Hive | 1100 | 260 | 880 | 8.4 | gROT home |
| Shard-Moon | 420 | 40 | 140 | 2.2 | low-g moon |

`atmosphere_height` — визуальный лимб. `atmosphere_envelope` — OS-B плотность / туман / потолок. Gravity well остаётся `height*1.8` (P0.6).

OPEN SPACE старт (OS-C): 8 км AGL над первым телом. Far-сфера + лимб держатся до 15 км AGL. Колодец не растягивать.

ShipFlightModel: `atmosphere_density(alt, height, envelope)`. OS-F lift/glide читает ту же плотность.

Updated: 2026-08-17
