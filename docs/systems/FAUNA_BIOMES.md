# Fauna & Biomes — NAEON

## Goal
Living worlds: animals per biome layer (water / land / air / vacuum), **visual density first**, soft harvest only later. No P2W combat power from fauna.

## Domains
| Domain | Layer | Examples | Spawn rule |
|--------|-------|----------|------------|
| **Aquatic** | oceans / lakes / ice-slush | reef runners, abyssal jellies, ice krill | altitude ~ sea level, wet biomes |
| **Terrestrial** | plains / forest / hive / barren | crystal grazers, thrall beetles, shard hoppers | surface stream cells |
| **Aerial** | troposphere / thermals | nex gliders, spore moths, hive wasps | height band 8–80 m AGL |
| **Space** | orbital / vacuum near stations | void mites, metal barnacles, plasma eels | alt > atmosphere_height * 0.6 |

## Planet → biome seed
| Planet | Primary biomes | Domains |
|--------|----------------|---------|
| Nex-Prime | temperate_forest, crystal_coast, shallow_sea | land + water + air |
| ROT-Hive | fungal_wastes, biomass_sea, spore_sky | land + water + air |
| Shard-Moon | barren_regolith, ice_crater, thin_air | land + air + space |

## Implementation phases
1. **F0** catalog + procedural proxy fauna stream (code) ← now
2. **F1** wire observer/cell stream like SurfaceFlora
3. **F2** Tripo B-batch species (1 mesh × dual-theme) when pad dense enough
4. **F3** soft interact (scan / soft harvest biomass/contrib — no combat)
5. **F4** rare space fauna near stations / belts

## Tripo economy
- Prefer **1 species / domain / faction tint** reused across planets via material swap
- LOD2 only until vertical slice feels alive
- Cap ~6 unique fauna meshes before batch DMG

## Non-goals
- Fauna does **not** deal combat damage or grant gear power
- No soft-lock of claims via wildlife

Updated: 2026-08-07T23:59:45.690186+00:00
