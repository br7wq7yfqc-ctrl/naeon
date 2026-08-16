# NAEON — WorldFill

**Status:** design authority for unnamed fill inside an already-loaded body or
system. **Version 1.3, 2026-08-16.**

This document is the contract. It does **not** replace
`docs/design/GALAXY_LAYER_PLAN.md` (authored galaxy, travel, maps, gates) or
`docs/lore/SITE_PIN_CATALOG.md` (named site IDs). It does **not** ship a
runtime universe generator. Schedule, playtest, and terrain-code work live
in `DEVELOPMENT_PLAN.md` — not here.

WorldFill answers one question: once a system and a body are already loaded
from authored data, what may the engine grow around the player — and what
must it never invent.

---

## 1. Why this contract exists

The local surface stack is already a fill layer. There is no world-gen class.

| Layer | What it does today |
|-------|--------------------|
| `PlanetRelief.gd` | Analytic height / biome. Seed from `planet_name.hash()` |
| `SurfaceDetail.gd` | 40 m lat/lon chunks, per-tick budget, same Relief sampler |
| `SurfaceChunkMath.gd` | Stable cells (no swim) |
| `PlanetTerrainEdit.gd` | Local carve on Relief base |
| `SurfaceFlora` / `SurfaceFauna` / `SurfaceWater` | Biome scatter on Relief |
| `CaveMouthField` / `CaveInterior` | Near-field cave SDF |
| `planet_surface.gdshader` | **A second FBM** on the far / impostor sphere |
| `StarSystemCatalog.gd` | **ARK only.** Gate anchors authored, not spawned |
| `GalaxyCatalog` / `NavState` / `Hyperdrive` / `HyperGate` / `ClashBeacon` | Not in repo (G2–G5) |

Without a written split, the next agent will either (a) mint named sites and
systems from noise, or (b) build `GalaxyCatalog` to “fill the galaxy.” Both
break canon. Fill is geology and logistics inside a loaded body. The galaxy
is authored data. Named places are a catalog.

Pillars this file must not dilute: no P2W, Knowledge stays soft, Infection
hard-caps at 5, story ≠ power, Tripo-first for authored meshes, Godot 4.3,
adult hard sci-fi. Named sites only from `SITE_PIN_CATALOG.md` (plus the
narrative rows in `LEGENDARY_SITES.md`). The galaxy is data, not geometry —
one system resident (`GALAXY_LAYER_PLAN.md` §1, §3, rules/25).

---

## 2. Authored forever

WorldFill must not create, move, rename, or infer any of the following.
Adding a new row is a lore/design commit, not a seed roll.

| Kind | Authority | Runtime today |
|------|-----------|---------------|
| Star systems (the eight names) | `docs/lore/STAR_SYSTEMS_SEED.md` | Only **ARK** is loaded |
| Galactic coordinates, faction heartlands, contested belt | `GalaxyCatalog` (G2), seeded from that list | Absent — do not invent |
| Body placement: star, orbits, angles, inclinations | `StarSystemCatalog.gd` | ARK: Aex, Nex-Prime, ROT-Hive, Shard-Moon |
| Physical envelopes (radius, gravity, atmosphere) | `PlanetProfileCatalog.gd` | Three ARK bodies |
| Relief *profiles* (sea, mountain, dune, mesa, crater) | `PlanetRelief.profile_for_planet` | Authored per body id |
| Belt **band** (inner / outer / thickness) | `StarSystemCatalog.belt` | Authored; rock count is fill |
| Gate **anchors** and pair `to` / `state` | `StarSystemCatalog.gates` | Authored, **not spawned** (G4) |
| Hyperdrive classes, jump range, fuel, charge | `GALAXY_LAYER_PLAN.md` §5 | Absent (G3) |
| Clash Beacons | `GALAXY_LAYER_PLAN.md` §8 | Absent (G5) |
| Named site pins `SITE_*` | `docs/lore/SITE_PIN_CATALOG.md` | Catalog only |
| Legendary geography / hooks | `docs/lore/LEGENDARY_SITES.md` | Catalog only |
| Quest locations, campaign theatres | Act starters + `QuestResource.site_pin_ids` | Must use catalog strings exactly |
| Training / VS pins | Catalog “Training / VS-only” table | `SITE_TEST_ARENA_PILLAR`, `SITE_SPACE_TEST_PAD`, … |

`LayerContext.set_site_pin` is catalog-shaped in comment only. It does **not**
validate IDs. WorldFill must never call it. Validation is a later hardening
pass, not a fill feature.

Gate anchors stay dark until G4. Spawning a ring with no jump is the
“looks implemented, is inert” defect `GALAXY_LAYER_PLAN.md` already forbids.

---

## 3. What WorldFill generates

Fill runs **only** inside the already-loaded system and the already-loaded
body. It never chooses *which* system exists.

**One seed per body.** Derive a single stable integer from the authored body
id (`planet_name` / catalog id: `Nex-Prime`, `ROT-Hive`, `Shard-Moon`). Same
id → same height, biome, and scatter across sessions. Not `hash(node.name)`,
not a second modulo for the shader, not a default `seed_i = 11` per subsystem.

| Channel | Allowed fill | Seed rule |
|---------|--------------|-----------|
| Relief height / biome | Mountains, hills, seas, rivers, canyons, dunes, mesas, craters | **Body seed** + authored profile |
| Far / impostor sphere | Macro land / ocean / ridge **from that same sampler** | **Same body seed** |
| Surface chunks | 40 m heightfield, existing budget | Same sampler, same seed |
| Flora / fauna / landscape accents | Unnamed scatter by `biome_hint` | Body seed + **channel offset** for placement RNG only |
| Water / cave mouths / cave interior | Near-field only, Relief SDF | Same body seed for height; channel offset for prop RNG |
| Belt rocks | Unnamed rocks **inside the authored band** | System-or-body seed; count by quality tier |
| Unnamed pads | Land / claim / harvest plates (`Pad_North` class) | Stable from body seed + local dir. **No `SITE_*`** |

Unnamed pads may be occupy-to-hold and may carry Dynamic Ownership visuals.
That is logistics, not story. They are not quest targets, not legendary, not
galaxy-map names, not Training/VS pins.

Scatter is adult hard sci-fi geology and industry: rock, flora proxies, fauna
proxies, pad clutter. No fantasy dungeons, no generated relics, no story
power, no exclusive DPS. Fauna stays visual / soft-scan
(`docs/systems/FAUNA_BIOMES.md`). Knowledge may later *label* a biome; it
must not spawn more, rarer, or stronger fill.

Meshes for **named** places stay Tripo-first
(`docs/design/TRIPO_ASSET_MANIFEST.md`). Filler meshes are ready-made scans or
CC0 libraries, or stay code-first — see §3.1. Do not commit `assets/` or
`generations/`.

### 3.1 Filler asset sources — ready-made first

WorldFill **places** unnamed scatter. It does not mint systems or pins.
Seed, domain, and “authored vs unnamed” stay §2–§4.

**Pipeline rule:** maximum ready-made from the net. Generate (Tripo) only
unique objects. Do not spend the Tripo budget on dirt or unnamed rocks.
Pipeline how-to stays in `docs/ASSET_PIPELINE.md`; locked plates stay in
`docs/design/ASSET_CATALOG.md`. This section is the split.

#### Unique → Tripo-first (catalog, lock, dual-theme CX/GR)

- Faction-readable heroes: ships, weapons, modules, armor, drones, a unique
  prop that carries a canon label
- `SITE_*` / legendary / quest places
- Anything already locked by UUID in `approved_sketches.json` /
  `docs/asset_positions.json`
- Anything that needs a paired Cybernex and gROT look a scan does not have

A scan does **not** replace dual-theme. Code-first proxies remain valid
until a unique mesh is generated or a generic mesh is ingested to the bucket.

#### Non-unique → take ready-made, do not generate

- Ground, rock, bark, dust, tileable surfaces
- Vegetation and unnamed biome scatter
- Generic rock / crate / pipe / cable with no faction
- HDRI, sky, far-plane impostors
- Water / foam / WorldFill chunk decor

If a ready mesh does not read as Aexion (too Earth, too fantasy): **re-skin
in Blender** toward CX/GR, or refuse. Do not regenerate in Tripo while a
re-skin would close the gap.

A ready-made asset never becomes a `SITE_*` and never grants power or
Knowledge.

#### Preference order

| Order | Source | Licence (as published) | Storage |
|------:|--------|------------------------|---------|
| 1 | **[Poly Haven](https://polyhaven.com/license)**, **[ambientCG](https://docs.ambientcg.com/license/)**, NASA/USGS 3D where the **item** page is public-domain / agency-media (do not assume CC0 — record the page), Sketchfab **CC0 + downloadable** filter | CC0 / public domain. Safe to **document** in git. | Binary → `s3://neon`. Git → `source`, `license`, `url` on the position only |
| 2 | **[ScansLibrary](https://www.scanslibrary.com/)** ([licence](https://www.scanslibrary.com/content/licence)) and other royalty-free paid scans (surfaces / 3D / plants / atlases, PBR, LOD0–3, OBJ/FBX). **Not** open source. | Paid royalty-free. Incompatible with OSS/CC on the game while in the pipeline. | **`s3://neon` only. Never git.** Build notice if extractable (below) |
| 3 | Mixed libraries (OpenGameArt, Fab, Megascans, …) | Only if the licence **explicitly** allows a commercial game without redistributing source files. Doubt → refuse. | Same as the licence requires; default `s3://neon`, never git |

Write `source`, `license`, `url` on the position / `assets_manifest` row.
Never the GLB or textures. Do not patch S3 Index
(`generations/catalog.json` is wiped).

**ScansLibrary — hard rules** (re-read the live FAQ/licence before any
purchase; this file does not quote prices):

- Free-section assets **without** an active paid plan or on-demand credits
  are **not** for commercial use.
- No redistribution: not the public git repo, not FAB / marketplaces, not a
  Creative Commons package.
- GitHub `license` / SPDX on `br7wq7yfqc-ctrl/naeon` is **`null`**. Leave it
  null while ScansLibrary scans are in the pipeline.
- If a mesh can be extracted from a shipped build, include a text notice:
  `Contains assets from ScansLibrary.com - Assets may not be redistributed`.

#### Decision

| Case | Do |
|------|----|
| Unique (hero, lock, `SITE_*`, dual-theme a scan cannot pair) | **Tripo** → bucket + catalog lock. Not a library grab. |
| Generic + CC0 / public domain | **`s3://neon` + git manifest** (`source`, `license`, `url`). No Tripo. |
| Generic + paid scan | **`s3://neon` + build notice**. Never git. SPDX stays null. No Tripo. |
| Unclear licence | **Refuse.** Do not generate “to be safe.” |

---

## 4. Hard prohibitions

| Forbidden | Why |
|-----------|-----|
| Mint `SITE_*` (or any pin not already in the catalog) | Named places are enum + memory, not noise |
| Put a generated id into `LayerContext.site_pin_id` / `QuestResource.site_pin_ids` | Story and transitions bind to the catalog |
| Expand jump range, charge, fuel, or gate access via Knowledge or fill | Knowledge is soft (`rules/08`, `GALAXY_LAYER_PLAN.md` §7.4 / §9) |
| Pay-to-win fill (better terrain, denser nodes, exclusive pads for subscribers) | Pillar: no P2W |
| A second galaxy, arm, or system list from noise | Eight authored names. Galaxy is data |
| `GalaxyCatalog` entries that are not the lore seed | G2 authors; WorldFill does not populate the map |
| Full planetary voxel shell | Out of scope. Analytic Relief + chunks only |
| A second in-memory star system | rules/25; `GALAXY_LAYER_PLAN.md` §1 |
| Spawning gate props, hyperdrive, or Clash Beacons as fill | G3–G5 authored objects |
| Story power from filler (unique weapons, claim strength, Infection > 5) | story ≠ power; Infection max 5 |
| Secrets, bucket keys, or generated plates in git | `.gitignore` already excludes `assets/`, `generations/`, `.env` |
| ScansLibrary (or any paid scan) binaries in git / FAB / CC | Royalty-free ≠ redistributable; see §3.1 |
| Tripo (or Meshy/Rodin) on unnamed dirt, rocks, tileable ground, HDRI | Ready-made first; budget is for unique only |

---

## 5. One planet: stitch the two noises

`docs/systems/PLANET_RELIEF.md` already requires: ship landing and
`SurfaceWalker` stand on the **same** `PlanetRelief` height. That continuum
is incomplete while the far sphere is a different planet.

### 5.1 Defect (current main)

Two samplers, two seeds, two domains.

| Path | Sampler | Domain | Seed in `PlanetBody` |
|------|---------|--------|----------------------|
| Far sphere + impostor | `planet_surface.gdshader` — 2-octave value-noise FBM on world normal | Unit normal | `absi(planet_name.hash()) % 97` |
| Chunks / walker / edit | `PlanetRelief.height_at(x, z, …)` — sin/cos FBM | Local tangent `x,z` (cell metres) | `planet_name.hash() % 10000` |
| Flora | Relief height, but | same tangent chart | `hash(node.name) % 10000` |
| Caves / water / landscape | Relief | same | body hash **plus** ad-hoc offsets / defaults |

Orbit ≠ dirt. A brown ridge from NAV is not the chunk under the walker.
`PLANET_RELIEF.md` **R4** (“macro ocean/land bands on far sphere”) is this
stitch, not a third noise.

### 5.2 Contract

1. **One body seed.** Every height read uses it. Channel offsets are for
   *placement RNG only* (which rock, which tuft), never for elevation.
2. **One spherical domain.** Sample by unit direction from body centre
   (or lat/lon derived from that direction). A local `x,z` chart may wrap
   that sample for a chunk; it must not be a second world.
3. **One Relief.** `PlanetRelief` remains the CPU source of truth
   (`height_at` / a `height_at_dir` sibling / `biome_hint` / `is_sea`).
   The far and impostor shader evaluates the **same** continent, ridge, and
   sea terms (GLSL port or a cheap subset) with the same seed and the same
   authored profile (`sea_level`, `mountain_amp`, …).
4. **LOD is drop, not replace.** The far pass may omit rivers, caves, and
   micro-grain. It must not substitute a different FBM. Land under a
   mountain from orbit is alpine/hills on foot; ocean is sea.
5. **Continuum consumers** — `SurfaceDetail`, `PlanetTerrainEdit`,
   `SurfaceWalker`, flora / fauna / water / caves / landscape — all call
   that Relief. No subsystem brings its own height field.
6. **No voxels.** Heightfield chunks + analytic SDF. Not a planetary voxel
   shell.

### 5.3 Next code (not this document)

**Shared Relief sampler for the sphere shader and `SurfaceDetail` — not
`GalaxyCatalog`.** That stitch is a later code PR. See `DEVELOPMENT_PLAN.md`.

`GalaxyCatalog` is G2 authored data (eight systems, light-year coordinates,
gate links). It does not make Nex-Prime one planet. The stitch is local to
bodies already in memory (ARK) and does not wait on G2.

---

## 6. Layers and G0–G6

WorldFill is a **local** layer. Travel, maps, and the system list stay
`GALAXY_LAYER_PLAN.md`.

```
Authored galaxy data          GalaxyCatalog (G2)     — not WorldFill
  └─ one resident system      StarSystemCatalog      — authored layout
       ├─ authored bodies     PlanetProfileCatalog   — envelopes
       ├─ authored belt band  + gate anchors         — no spawn until G4
       └─ WorldFill           Relief + chunks + unnamed scatter / pads
```

| Phase | Galaxy plan | WorldFill |
|-------|-------------|-----------|
| **G0** (done: layout) | ARK star, orbits, belt band, dark gate anchors | This contract applies now. Do not spawn gates, add systems, or mint pins. Sampler stitch is later code — see `DEVELOPMENT_PLAN.md`. |
| **G1** CRUISE + 2.8× orbits | Far clip LOW 22000 … ULTRA 48000; deep-space impostor pass | Fill must not fight G1. Far sphere / impostor is the cheap Relief preview. Do **not** grow chunk rings to “paint the planet from CRUISE.” Impostor already uses `planet_surface.gdshader` — that is the stitch target. |
| **G2** galaxy data + maps | `GalaxyCatalog`, `NavState`, `M` / `N`, honest refusals | **Wait.** Do not fill non-ARK systems. Unnamed pads stay off the named map. Maps show authored systems and (later) authored gates / beacons only. |
| **G3** hyperdrive | Module, fuel, star-adjacent arrival | Fill does not add range, systems, or fuel. Arrival still loads **one** authored system; fill runs after that load. |
| **G4** gates | Authored `HyperGate` props, Infection cap 5 | No generated gates. Infected authored gates use existing `InfectionStatus` (max 5). |
| **G5** Clash Beacons | Authored objects, hold-F, return to same beacon | No generated beacons. No filler pin for the arena. |
| **G6** more systems | Remaining lore-seed systems, authored gate nets | After a system is authored **and** loaded, WorldFill may fill its bodies the same way. Still no noise galaxy. |

Schedule and playtest: see `DEVELOPMENT_PLAN.md`. This file only states the
boundary. Wait for G2 before any fill outside ARK, any galaxy-map marker for
filler, or anything that looks like a generated system list.

---

## 7. Performance

rules/25 still wins: ~60 FPS on the minimum preset, no monotonic memory
climb. One system in memory. Far clip stays LOW 22000 · MED 28000 ·
HIGH 36000 · ULTRA 48000 until G1 revisits the deep-space pass.

WorldFill **must not** change the existing chunk contract
(`docs/systems/CHUNK_STREAMING.md`, `SurfaceDetail.gd`):

| Lever | Keep |
|-------|------|
| Cell size | 40 m lat/lon |
| Load / unload rings | LOW 1/2 · HIGH 2/3 (quality-scaled) |
| Build budget | 1 mesh per stream tick (2 on ULTRA); warm-up 1 |
| Queue cap | 12 |
| Mesh cache / pool | 32 / 8 |
| Activate | Only near the body (`SurfaceDetail` parks above ~140 m AGL) |
| Pads | Staggered build; unload on departure (already measured flat) |
| Belt | Quality-capped instance count, no collision on rocks |
| Caves | Near LOD only |

The stitch is analytic uniforms + the same cheap FBM the CPU already runs —
not more chunks, not a voxel shell, not a second system. G1's impostor
layer is the far read of Relief, not a wider stream ring.

---

## 8. Definition of done

How to know the contract holds. These checks are for the **code** PRs that
implement WorldFill, not for this document PR.

| Check | Pass | Fail |
|-------|------|------|
| **One planet from orbit and from dirt** | Pick a lat/lon on Nex-Prime. Far-sphere land/ocean/ridge at that direction matches `PlanetRelief.biome_hint` / height sign (land vs sea, ridge vs basin) on the chunk and under the walker. Repeat on ROT-Hive and Shard-Moon. Same body seed both paths. | Current main: shader FBM `% 97` vs Relief `% 10000`. Brown from NAV, different chunk underfoot. |
| **Pin was not generated** | After a fill session: `SITE_PIN_CATALOG.md` unchanged; `LayerContext.site_pin_id` is empty or a catalog string; logs/saves contain no new `SITE_*`; unnamed pads have local names only (`Pad_North` class). | Any minted `SITE_*`, any fill write into `set_site_pin`, any quest bound to a generated id. |
| **Seed stable** | Same body id → same height at the same direction after reload. | Flora keyed off `node.name`; per-subsystem default seeds. |
| **One system resident** | WorldFill never loads a second `StarSystemCatalog` entry. | Noise galaxy, eager ROT-Prime geometry, generated `GalaxyCatalog`. |
| **Chunk budget intact** | Rings, `LOAD_BUDGET`, queue cap, park-on-depart unchanged; 5 min near-surface idle does not climb. | Stream rings grown to paint the sphere; unbounded scatter. |
| **Knowledge / P2W inert** | Rank and subscription do not change fill density, rarity, pad count, or jump math. | Soft-mastery extra nodes; paid richer terrain. |
| **No voxel shell** | Heightfield + analytic SDF only. | Planetary voxel volume. |
| **Filler mesh is not a hero / not a pin** | Scan or CC0 used only as unnamed ground/flora/rock; CX/GR heroes and `SITE_*` stay Tripo + catalog. ScansLibrary files absent from git. | Scan as a faction hero, a `SITE_*`, or a blob on `main`. |
| **Tripo not spent on dirt** | Generic ground/rock/flora/HDRI ingested ready-made (or still code-first). Manifest has `source`/`license`/`url`, no binary in git. | Tripo job whose brief is “unnamed rock” or tileable dirt. |

---

## 9. What this file is not

- Not a runtime generator and not a Godot class named `WorldFill`.
- Not a patch to S3 Index, `MANUAL_CATALOG.md`, or `generations/`.
- Not `GalaxyCatalog`. That remains G2, authored from
  `STAR_SYSTEMS_SEED.md`.
- Not a second copy of `GALAXY_LAYER_PLAN.md` or `SITE_PIN_CATALOG.md`.
  If travel or pin rules change, update those files; this file only cites
  them.
- Not permission to validate-or-invent pins in `LayerContext` in the same
  breath as fill. Validate later; invent never.
- Not a price list, not a download, and not a patch to S3 Index. §3.1 names
  licences, storage, and the ready-made vs Tripo split.
- Not `DEVELOPMENT_PLAN.md`, not a playtest, and not a terrain-code fix.

---

*Design authority for unnamed fill. Update this file in the same commit as
any change to what WorldFill may generate or what it must never author.*
