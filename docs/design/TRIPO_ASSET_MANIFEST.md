# NAEON — Tripo asset manifest

**Complete list of meshes to generate.** Version 1.0, 2026-08-15.
Companion to `docs/design/GALAXY_LAYER_PLAN.md`; supersedes ad-hoc asset lists.

## How to read this

**Path convention** (enforced by `godot/scripts/assets/AssetPaths.gd`):

```
<category>/<asset_id>/<asset_id>_<faction>_lod<N>.glb
faction ∈ { cybernex, grot }        N ∈ { 0, 1, 2 }
```

LOD policy — one Tripo generation per asset, decimated in Blender on the asset VM
(near-free, per the economical skill §3):

| LOD | Budget | Used for |
|-----|--------|----------|
| 0 | ≤ 12k tris | hero / first-person / close character |
| 1 | ≤ 5k tris | normal gameplay distance |
| 2 | ≤ 1.5k tris | streamed props, belts, distant structures |

**Class** (economical skill §3.2): **A** = hero, higher quality allowed ·
**B** = normal, one generation + variants · **C** = maximum reuse, procedural
acceptable if the budget is tight.

**Variant** — how the gROT version is produced:
`gen` = a separate Tripo generation, `kit` = Blender re-skin of the Cybernex mesh
with the gROT material kit, `shared` = one neutral mesh for both.

**Priority** — `P0` blocks the current phase, `P1` next phase, `P2` polish.

**Status** — `IN CODE` = a path already referenced by a script (so a fallback is
in use today), `NEW` = required by the galaxy layer plan, `MISSING` = referenced
but never generated.

Every entry lands under `s3://neon/generations/` with `catalog.json` updated on
ingest, per the `naeon-sequential-dev` skill.

---

## 1. Galaxy layer — new, this plan

### 1.1 Hyperspace gates (plan §6) — **P0 for G4**

| Path | Class | Variant | LODs | Notes |
|------|-------|---------|------|-------|
| `environments/hypergate_ring/` | **A** | gen | 0,1,2 | The hero object of the whole layer. Large NAEXOS relay ring, ~400 m, pre-Schism architecture: it must read as *older* than both factions. Open aperture, no gimmick geometry in the middle |
| `environments/hypergate_pylon/` | B | kit | 1,2 | Four support pylons around the ring; carries the ownership tint |
| `environments/hypergate_core/` | B | kit | 1,2 | Central power core, the thing that glows by state (open / dormant / infected) |
| `props/gate_anchor_buoy/` | C | shared | 2 | Approach marker buoys, instanced in a line to the aperture |
| `props/gate_infection_growth/` | B | gen (GR only) | 1,2 | Biomass overgrowth for the infected state; must look additive, draped over the ring |
| `props/gate_firewall_lattice/` | B | gen (CX only) | 1,2 | Cybernex cleanse lattice, the visual answer to the above |

`environments/gate_arch/` already exists in code as a small decorative arch. It is
**not** the hypergate — keep both, rename nothing.

### 1.2 Star and system dressing — **P1**

| Path | Class | Variant | LODs | Notes |
|------|-------|---------|------|-------|
| `environments/star_corona_shell/` | C | shared | 2 | Optional mesh shell for the star; a procedural sphere + corona ships today, so this is polish only |
| `environments/nav_beacon/` | B | kit | 1,2 | Orbital navigation beacon; marks orbits and gate approaches on the system map |
| `environments/orbital_ring_segment/` | B | kit | 1,2 | Tileable segment for larger stations than the current habitat ring |
| `environments/asteroid_large/` | C | shared | 1,2 | Belt hero rocks; `asteroid_ore` covers the small ones |
| `environments/comet_body/` | C | shared | 2 | Belt / outer system variety |
| `environments/debris_field_chunk/` | C | shared | 2 | Wreck debris near contested gates |

### 1.3 Hyperdrive and ship modules (plan §5) — **P0 for G3**

| Path | Class | Variant | LODs | Notes |
|------|-------|---------|------|-------|
| `ships/hyperdrive_relay/` | **A** | gen | 1,2 | Starter Relay-1 drive; visible hardpoint module |
| `ships/hyperdrive_nex_lattice/` | B | gen (CX) | 1,2 | Cybernex class — lattice, cool light |
| `ships/hyperdrive_spore_fold/` | B | gen (GR) | 1,2 | gROT class — organic fold, warm light |
| `ships/fuel_scoop/` | B | kit | 1,2 | Star-scooping intake (plan §5.3, later phase) |
| `ships/hyperspace_vent/` | C | kit | 2 | Heat vents that glow after arrival |

### 1.4 Clash beacons (plan §8) — **P0 for G5**

| Path | Class | Variant | LODs | Notes |
|------|-------|---------|------|-------|
| `environments/clash_beacon_station/` | **A** | gen | 1,2 | Orbital arena station; the thing you dock to in order to enter Clash |
| `environments/clash_beacon_surface/` | B | kit | 1,2 | Surface arena entrance near a pad |
| `props/clash_beacon_holo/` | C | kit | 2 | Holographic match-invite sign at the dock |

### 1.5 Navigation UI props — **P1**

| Path | Class | Variant | LODs | Notes |
|------|-------|---------|------|-------|
| `props/galaxy_map_table/` | B | kit | 1 | Physical map table for the ship interior pocket; the diegetic home of the `M` map |
| `props/nav_console/` | B | kit | 1 | Route-plotting console for the cockpit |

---

## 2. Already referenced by code

These paths are live in scripts. Where a mesh is absent the code falls back to a
procedural placeholder, so the game runs — but every one of them is a placeholder
the player currently sees.

### 2.1 Characters — **P0**

| Path | Class | Variant | LODs | Status |
|------|-------|---------|------|--------|
| `characters/player_canine/` | **A** | kit | 0,1,2 | IN CODE |
| `characters/player_avian/` | **A** | kit | 0,1,2 | IN CODE |
| `characters/player_feline/` | **A** | kit | 0,1,2 | NEW — form exists in code, no path yet |
| `characters/player_human_cyborg/` | **A** | kit | 0,1,2 | NEW — same |
| `characters/cybernex_sentry/` | B | gen (CX) | 0,2 | IN CODE |
| `characters/grot_thrall/` | B | gen (GR) | 0,2 | IN CODE |
| `characters/grot_infector/` | B | gen (GR) | 0,2 | IN CODE |
| `characters/combat_drone/` | B | kit | 2 | IN CODE |

**Rigging note:** the audit found the arena hero stuck in bind pose because Tripo
exports arrive unskinned. Characters need a Blender rigging step (Rigify or a
shared humanoid/quadruped skeleton) before the procedural locomotion layer can
drive them. Until then `ProceduralHeroSilhouette` is the honest stand-in.

### 2.2 Ships and modules — **P0**

| Path | Class | Variant | LODs | Status |
|------|-------|---------|------|--------|
| `ships/scout_hull/` | **A** | gen | 0,1,2 | NEW — the player hull is procedural today |
| `ships/hauler_hull/` | **A** | gen | 1,2 | NEW |
| `ships/ship_module_engine/` | B | kit | 1,2 | IN CODE (fallback path) |
| `ships/ship_module_weapon/` | B | kit | 1,2 | IN CODE (fallback path) |
| `ships/shield_module/` | B | kit | 2 | IN CODE |
| `ships/thruster_cluster_neon/` | B | kit | 1,2 | IN CODE |
| `ships/cargo_pod/` | C | kit | 2 | IN CODE |
| `ships/landing_gear_strut/` | C | kit | 2 | NEW — gear is procedural |
| `ships/cockpit_interior_shell/` | **A** | kit | 1 | NEW — the interior pocket is greybox |

### 2.3 Weapons — **P1**

| Path | Class | Variant | LODs | Status |
|------|-------|---------|------|--------|
| `props/weapon_pulse_cannon/` | B | gen (CX) | 1,2 | IN CODE |
| `props/weapon_biomass_spitter/` | B | gen (GR) | 1,2 | IN CODE |
| `props/cybernex_rail_slug/` | B | gen (CX) | 1,2 | IN CODE |
| `props/grot_organic_cannon/` | B | gen (GR) | 1,2 | IN CODE |
| `props/turret_emplacement/` | B | kit | 1,2 | IN CODE (CX variant MISSING) |
| `props/turret_rotating_barrel/` | B | kit | 1,2 | IN CODE — the animator expects `Head`/`Barrel` nodes; name them in the export |
| `props/assault_carbine/` | B | kit | 0,1 | Sketch locked in ASSET_CATALOG, no mesh |
| `props/dmr_rifle/` | B | kit | 0,1 | Sketch locked, no mesh |
| `props/firewall_gadget/` | B | gen (CX) | 0,1 | Sketch locked, no mesh |
| `props/infection_tool/` | B | gen (GR) | 0,1 | Sketch locked, no mesh |

### 2.4 Colony and pads — **P0**

| Path | Class | Variant | LODs | Status |
|------|-------|---------|------|--------|
| `environments/landing_pad/` | **A** | kit | 1,2 | IN CODE |
| `colony/colony_habitat/` | **A** | kit | 1,2 | IN CODE |
| `colony/extractor_unit/` | B | kit | 1,2 | IN CODE (GR variant MISSING) |
| `colony/station_habitat_ring/` | B | kit | 1,2 | IN CODE |
| `colony/grot_biomass_spire/` | B | gen (GR) | 1,2 | IN CODE — currently pathed as `_cybernex_`, fix on ingest |
| `colony/solar_panel/` | C | kit | 2 | IN CODE |
| `colony/fuel_tank/` | C | kit | 2 | IN CODE |
| `colony/resource_crystal/` | C | shared | 1,2 | IN CODE |
| `colony/surface_crystal_spire/` | C | shared | 2 | IN CODE |
| `props/ownership_claim_pylon/` | **A** | kit | 1,2 | IN CODE — the ownership readability object |
| `props/claim_beacon/` | B | kit | 1,2 | IN CODE |
| `props/pad_control_obelisk/` | B | kit | 1,2 | IN CODE |
| `props/pad_refuel_pump/` | B | kit | 2 | IN CODE — SCM/HOVER occupy refill; hyperdrive fuel later (§5.3) |
| `props/pad_floodlight/` | C | kit | 2 | IN CODE |
| `props/control_console/` | B | kit | 1,2 | IN CODE |
| `props/med_station/` | B | kit | 1,2 | IN CODE |
| `props/nex_relay/` | C | kit | 2 | IN CODE |
| `props/antenna_array/` | C | kit | 2 | IN CODE |
| `props/holo_projector/` | C | kit | 2 | IN CODE |
| `props/energy_barrier/` | C | kit | 2 | IN CODE |
| `props/shield_bubble_emitter/` | C | kit | 1,2 | IN CODE |
| `props/cybernex_shield_emitter/` | C | gen (CX) | 1 | IN CODE |

### 2.5 Vehicles — **P1**

| Path | Class | Variant | LODs | Status |
|------|-------|---------|------|--------|
| `vehicles/ground_rover_chassis/` | **A** | kit | 1,2 | IN CODE |
| `vehicles/apc_hull/` | B | kit | 1,2 | Sketch locked, no mesh |
| `vehicles/tank_hull/` | B | kit | 1,2 | Sketch locked, no mesh |
| `vehicles/hover_platform/` | B | kit | 1,2 | Sketch locked, no mesh |
| `vehicles/mech_frame/` | **A** | kit | 1,2 | Sketch locked, no mesh |

### 2.6 Interiors — **P1**

| Path | Class | Variant | LODs | Notes |
|------|-------|---------|------|-------|
| `environments/interior_corridor/` | B | kit | 1,2 | NEW — pockets are greybox |
| `environments/interior_door_frame/` | B | kit | 1,2 | NEW — the sliding slab is a box |
| `environments/interior_seat/` | C | kit | 1 | NEW — the pilot seat marker is invisible |
| `environments/walkway_segment/` | C | kit | 2 | IN CODE |
| `props/interior_locker/` | C | kit | 2 | NEW |
| `props/life_support_unit/` | B | kit | 1,2 | NEW — the recycler the E console vents |
| `props/storage_barrel/` | C | kit | 2 | IN CODE |
| `props/sci_fi_crate/` | C | kit | 2 | IN CODE |
| `props/ammo_crate/` | C | kit | 2 | IN CODE |
| `props/cargo_landing_container/` | C | kit | 2 | IN CODE |

### 2.7 Arena (Clash) — **P1**

| Path | Class | Variant | LODs | Status |
|------|-------|---------|------|--------|
| `environments/clash_nexus_core/` | **A** | kit | 1,2 | IN CODE |
| `environments/clash_lane_tower/` | B | kit | 1,2 | IN CODE — now a live turret, so a barrel node is wanted |
| `environments/clash_arena_floor/` | C | kit | 2 | NEW — the floor is a box |
| `props/clash_cover_block/` | C | kit | 2 | NEW — cover is boxes |

### 2.8 Surface and caves — **P2**

| Path | Class | Variant | LODs | Status |
|------|-------|---------|------|--------|
| `environments/surface_rock_cluster/` | C | shared | 2 | IN CODE |
| `props/cave_energy_crystal/` | B | shared | 1,2 | IN CODE — the V-scan deposit |
| `environments/cave_mouth/` | C | shared | 2 | NEW |
| `environments/asteroid_ore/` | C | kit | 2 | IN CODE |
| `props/flora_cluster_cx/` | C | gen (CX) | 2 | NEW |
| `props/flora_cluster_gr/` | C | gen (GR) | 2 | NEW |
| `props/fauna_grazer/` | B | kit | 1,2 | NEW — `SurfaceFauna` streams procedural stand-ins |

---

## 3. Generation order

Ordered so that each batch makes something visibly better in a build that already
runs. Costs are Tripo credits at the current rate; the weekly cap is 5k and the
monthly 20k (`SHARED_AGENT_MEMORY`, 2026-08-06 decision log).

| Batch | Contents | Why now |
|-------|----------|---------|
| **T1** | `hypergate_ring`, `hypergate_core`, `hypergate_pylon`, `hyperdrive_relay` | The galaxy layer's hero objects; G3/G4 cannot be evaluated without them |
| **T2** | `scout_hull`, `cockpit_interior_shell`, `landing_gear_strut` | The player looks at their own ship more than anything else, and it is procedural |
| **T3** | `player_feline`, `player_human_cyborg` + rigging pass on all four forms | Closes the form roster and unblocks real locomotion |
| **T4** | `clash_beacon_station`, `clash_beacon_holo` | G5 arena entry from the map |
| **T5** | `interior_corridor`, `interior_door_frame`, `life_support_unit`, `interior_seat` | Interiors are the most-visited greybox |
| **T6** | `nav_beacon`, `asteroid_large`, `orbital_ring_segment`, `debris_field_chunk` | Makes the newly large system worth crossing |
| **T7** | Missing faction variants: `turret_emplacement` CX, `extractor_unit` GR, `grot_biomass_spire` path fix | Dual-theme completeness |
| **T8** | Weapons from locked sketches: carbine, DMR, firewall gadget, infection tool | Infantry readability |
| **T9** | Vehicles: APC, tank, hover, mech | Ground-layer expansion |
| **T10** | Flora, fauna, cave mouth, arena floor and cover | Environmental polish |

### Totals

| | Count |
|---|---|
| Distinct assets in this manifest | **78** |
| Already referenced by code | 47 |
| New for the galaxy layer | 21 |
| Referenced but never generated (fallback visible today) | ~30 |
| Class A (hero) | 16 |
| Tripo generations needed (`gen` entries, before Blender variants) | ~34 |

---

## 4. Rules for every ingest

1. Approved files go under `s3://neon/generations/` in the right folder.
2. Run `scripts/assets/update_generations_catalog.py` so `catalog.json` includes
   the new keys, then upload the file **and** the catalog.
3. Never commit binaries: `/assets/` is gitignored, and raw `*.glb` must stay out
   of git.
4. Name the export's internal nodes when code expects them —
   `turret_rotating_barrel` needs `Head` and `Barrel`, or `TurretAnimator` cannot
   drive it.
5. Faces −Z. `MeshOrient.face_neg_z` corrects imports, but a correct export skips
   a runtime rotation.
6. Decimate to the LOD budgets in Blender on the asset VM rather than paying for
   extra generations.

---

*Asset authority. Update in the same commit as any new mesh path in code.*
