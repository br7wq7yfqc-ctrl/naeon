# Station & Ship Interiors

**Status:** Procedural seed · **Cost:** 0 Tripo

## Why procedural first
Hero station meshes are A-tier Tripo later. For playable vertical slice we generate **modular neon rooms** (foyer / corridor / ops / quarters) so boarding and “inside base” fantasy works without asset spend.

## Flow
1. On foot near **landing pad** → **I** enter station interior pocket
2. Near **ship** → **I** enter ship cockpit/mid/cargo
3. **I** again at hatch/exit → return to pad/ship exterior

## Implementation
- `InteriorGenerator` builds rooms + collision + exit marker
- `InteriorDirector` teleports player into offset pocket (Y=50 km) with flat gravity
- FloatingOrigin still tracks player

## Future
- Swap rooms for HQ dual-theme GLB modules when budget allows
- Multi-crew ship stations
- Persistence of interior props


---

## Planned expansion (see SHIP_EVA_INTERIOR_MORPH.md)

- **ShipInteriorProfile** per hull class — single-seat still has Cockpit + Airlock
- Seat volume → direct PILOT
- Morph-linked interior parts (siege blister)
- EVA exterior ≠ interior pocket (I only when in hull volume or on pad)

Updated: 2026-08-07T10:55:29.115564+00:00
