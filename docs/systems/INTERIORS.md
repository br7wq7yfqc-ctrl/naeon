# Station & Ship Interiors

**Status:** IN-A + IN-B + IN-C V0/V1 built · Procedural seed · **Cost:** 0 Tripo

## Why procedural first
Hero station meshes are A-tier Tripo later. For playable vertical slice we generate **modular neon rooms** (foyer / corridor / ops / quarters) so boarding and “inside base” fantasy works without asset spend.

## Flow
1. On foot near an **occupied unnamed pad** or the **player orbital cluster** (ST-E dock+habitat + ST-G factory) → **I** enter a station foyer/ops pocket. Not the ship cockpit.
2. On a **catalog carrier** hull (ST-D `cybernex_capital_carrier` …) → **I** enter a `hangar_bay` pocket. Not a `SITE_*`. Not the ship cockpit.
3. Pilot **I** → leave seat into ship pocket (cockpit → airlock). No exterior hop.
4. **F** at the ship seat → pilot. **F** at `OpsSeat` (station) or `HangarSeat` (hangar) boards that legal seat. **I** from the legal seat returns to the same pocket (no exterior hop). Landed **F** from the ship is still the pad-deck walker.
5. **E** at the station ops console is a real board action (pad occupy when pad-linked, factory print gate on the ST-G factory). Not a locked prop. Not toast-only. Recycler toggle stays.
6. Pocket life-support is a live readout. Vented / off LS uses the EVA suit soft warn. No HP. No P2W.
7. **I** at airlock/hatch → EVA (zero-G if not landed) or pad. Doors open into the next room or the hatch. Station/hangar hatch returns to pad or dock in the same `OpenSpace.tscn` (not MainMenu). When the catalog-carrier ramp is DEPLOYED, hangar hatch exits onto the plates (walk to pad).

## Implementation
- `InteriorGenerator` builds rooms + collision + exit marker (`build_station`, `build_hangar_bay`, ship profiles)
- `InteriorDirector` teleports player into offset pocket (Y=9200) with flat gravity
- Pad / cluster `I` → `station`. Carrier `I` → `hangar_bay`. Pilot `I` → `ship`. Three pockets stay distinct.
- Station/hangar seats are `OpsSeat` / `HangarSeat` — not ship `Seat` / `SeatVolume`
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

Updated: 2026-08-28 — IN-C hangar ramp V0/V1 (headless PASS). IN-A/IN-B pockets unchanged.
