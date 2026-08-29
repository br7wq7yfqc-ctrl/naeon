# NAEON — Shared Agent Memory

**Last updated:** 2026-08-28 (ST-G own factory print §6(c) in the existing player cluster)

## Core constraints
No P2W · soft Knowledge · Infection max 5 · story ≠ power · Godot 4.7.2 · adult hard-sci-fi · site_pin catalog only · WorldFill = authored skeleton + unnamed filler · ready-made assets first, Tripo unique only · one resident system (ARK) · no planetary voxel shell · perf/25 (FPS on owner GPU, not llvmpipe)

## Design corpus
rules/00–26 · **OPEN_SPACE_SC_BENCHMARK** · **BASE_STATION_STRATEGY** · **ASSET_SOURCE_CANON** · **WORLD_FILL** · DEVELOPMENT_PLAN 2.4 · SITE_PIN · GALAXY_LAYER_PLAN (G2–G6 locked) · TRIPO_ASSET_MANIFEST

## Where things are authored
- **Order of work** → `docs/design/BASE_STATION_STRATEGY.md` (ST-A…ST-G built). OS-A…OS-H remain in `OPEN_SPACE_SC_BENCHMARK.md`. Pointer in `DEVELOPMENT_PLAN.md`
- **Mesh source** → `docs/design/ASSET_SOURCE_CANON.md`
- **Fill vs authored** → `docs/design/WORLD_FILL.md`
- **Human GPU fact** → `docs/PLAYTEST_SANDBOX.md` (3090 / P0.6; not FPS PASS on llvmpipe)
- **Placement** of star / bodies / belt / gate anchors → `godot/scripts/world/StarSystemCatalog.gd`
- **Physical envelopes** (radius, gravity, atmosphere) → `PlanetProfileCatalog.gd`
- Travel, maps, gates, arena entry → `docs/design/GALAXY_LAYER_PLAN.md` (do not implement G2–G6 until OPEN SPACE loop is honest)
- Unique mesh list → `docs/design/TRIPO_ASSET_MANIFEST.md` (not T1 until OS bar is honest)

## Gaps closed
- Constructor template seed (8 templates, VS = 2)
- Generated side-quest templates
- Edu module library soft
- LEGENDARY_SITES v0.2 with IDs
- HANDOFFS refreshed to skill v2.0 + rules 20–26

## Implementation P0
A: Infection 5 + perf · B: TransitionContext S1 · E: Act I resources · Ops: Tripo/neon

## Protocol
HANDOFF → rules/lore/design → skill §25 → code.

## 2. Current Mechanical Truths

### Factions & Lore
- The Schism originated from conflict among NAEXOS creators.
- gROT split and used the transgalactic network as infection vector.
- Most of humanity is in hibernation in NEX on ARK.
- Noo-people and Cybernex animal-robots are protected by genetic editing (with limitations compensated by RBE/NAEXOS model).

### Key Systems Status
- Ability System: data-driven foundation exists (supports Hacking / Firewall flags).
- OwnershipData + OwnershipComponent: data model and skeleton exist.
- Knowledge / Contribution / Subject Mastery: data structures exist.
- Dynamic Ownership: visual + gameplay transformation required (dual themes).
- Asset Pipeline: Tripo-first, free-tier prioritized, documented.

### Monetization
- Freemium + paid subscription.
- Tokens for AI generation (Yandex GPT / aiNEX).
- Voice channels gated by subscription or achievement.
- Premium quests are narrative-only and must not affect MMO balance.

## 3. Decision Log (append only)

| Date | Decision | Reason |
|------|----------|--------|
| 2026-08-05 | Design Lead role activated | User directive |
| 2026-08-05 | Tripo selected as primary 3D generator | Best balance of topology, price, free tier for game assets |
| 2026-08-05 | Parallel multi-agent build sessions stopped; handoffs created | User directive |
| 2026-08-05 | Shared Agent Memory + Holistic Skill created | User directive |

## 4. Open Questions / To Resolve

- Exact numerical parameters for Hacking duration, Firewall strength, infection progress rates.
- Full list of starting star systems and their ownership rules.
- Concrete soft multipliers for each Subject Mastery in combat.
- Voice channel achievement thresholds.

## 5. How Agents Must Use This Memory

1. Before making any design or mechanical change — read this file.
2. After any significant decision or new rule — append to Decision Log and update the relevant section.
3. Never contradict the Core Project Constraints.
4. Prefer updating existing artifacts over creating conflicting new ones.

---

*This memory is the contract between all agents working on NAEON.*

| 2026-08-06 | Vertical slice asset batch1 complete (10 meshes → dual-theme LODs) via Tripo+Blender; economical A/B/C | Holistic skill |
| 2026-08-06 | Ship/colony/dummy runtime GLB load; Mac DMG installer + AutoUpdater | Session |

## Decision Log — 2026-08-06
- Budget: week 5k / month 20k Tripo; vision not capped after top-up.
- Sysreqs floor: RTX 1060 3GB / i3 / 16GB; tiers LOW–ULTRA in GraphicsQuality.
- Shipped OpenSpace seamless continuum (FloatingOrigin, PlanetBody, ship SCM/NAV/HOVER, surface walk).
- Main scene switched to OpenSpace.tscn.
- Wave S complete; A in progress under week cap.

| 2026-08-06 | BaseBuilder pad streaming + altitude fog; A 2w wave nearly complete | Holistic queue |
| 2026-08-06 | Atmosphere fresnel dual-shell adopted as default (no Bruneton on min spec) | Atmo analysis |\n\n| 2026-08-06 | Pad claim + harvest → Contribution only (soft mastery colony_ops); no combat power from ownership | Holistic |\n\n| 2026-08-06 | OpenSpace: full flight attitude; SurfaceWalker snap; procedural char anim — priority playability | Holistic |\n

| 2026-08-06 | SurfaceDetail procedural patches (code-first, 0 Tripo) | Holistic economical |
| 2026-08-06 | Contested pad ownership with readable dual-threat tint | Dynamic Ownership |
| 2026-08-06 | Infection stacks 1–5 + GameHUD; Firewall cleanse 1; ability CD to param sheet | Ability track A |\n\n| 2026-08-06 | Channeled Hack 1.5s interruptible + Firewall break; pad dual-theme swap on claim resolve | Holistic A/B |\n\n\n| 2026-08-06 | Planet terrain edit NMS-like with volume caps; procedural station/ship interiors (I key); 0 Tripo | Holistic |\n

| 2026-08-06 | Terrain undo+FX; channel VFX; ContestedRing; interior GLB decorate; 0 Tripo autonomous | Holistic |

| 2026-08-06 | Contested HUD banner+radar; terra dust; limb walk; soft Knowledge toasts; Desktop DMG size verify | Holistic economical |\n\n| 2026-08-06 | SoftKnowledge §7.3 + asymmetric Contribution/Biomass + EduQuest pad seed + F9 faction cycle; 0 Tripo | Holistic conceptual |\n\n| 2026-08-06 | Seamless S1 LayerContext + layer HUD; physics lead marker QoL; AllianceRanks 0–4 soft promote; 0 Tripo | Holistic v1.4 |\n\n| 2026-08-06 | Aexion Clash slice + WarScore daily 60 soft influence; Arena layer S1; VERSION 0.3.3; 0 Tripo | Holistic v1.4 |\n\n| 2026-08-06 | Clash 3-lane readability + radar + dual nexus; firewall channel break helper; 0 Tripo | Holistic v1.4 |\n\n| 2026-08-06 | Soft lane objectives pressure 0-100 + alt win 3 lanes; +2 WS/lane; 0 Tripo | Holistic v1.4 |\n\n| 2026-08-06 | Wave C HeroFormCatalog dual-theme + gROT Infector; LayerContextAuthority local stub; 0 Tripo | Holistic v1.4 |\n
| 2026-08-06 | ProceduralLocomotion arena bob + SoftNetSession lag ghost (120ms); 0 Tripo multiplayer prep | Holistic v1.4 |


| 2026-08-07 | Session Contract: batch DMG only; benchmarks SC/NMS+EVE/Stellaris+Predecessor; Phase0 ~5%; Tripo check each iter | Owner |
| 2026-08-07 | Phase 0 feel pass: MainMenu, CombatJuice, AudioDirector, SessionObjectives, pad density | Holistic |


| 2026-08-07 | Planned EVA open-space exit, per-hull interiors (incl. single-seat), OpMode SIEGE morph geometry | Owner + holistic |
| 2026-08-07 | Authority doc docs/systems/SHIP_EVA_INTERIOR_MORPH.md; sprint order EVA→MORPH→INT→NET | Holistic |

| 2026-08-07 | Ground vehicles hangars/ramps planned + CargoHold/Ramp/Rover scaffold | Holistic |
| 2026-08-07 | 0.3.18 combat readability + SurfaceFlora | Holistic |

| 2026-08-07 | S-EVA / S-MORPH / S-INT / V1-V2 code landed; Desktop still 0.3.18 until acceptance → 0.3.19 | Holistic |


## Decision Log — 2026-08-07T23:22:10.485908+00:00
- Parallel content: Tripo A ownership_claim_pylon (high) + B ground_rover_chassis (standard); balance was ~4870.
- Code: ship bolts → Area3D + ProjectileRunner hits; pad claim particles + claim_beacon mesh; siege energy cost up.
- No DMG micro-release.


## 2026-08-07T23:35:35.579344+00:00
- Ability feedback toasts + HUD CD bar; walker full kit keys.
- Tripo B: cybernex_shield_emitter + cargo_landing_container (−40 cr). Balance ~4720.

### 2026-08-08 — ShipHullAmbient
- Code-first hull rim/engine/cabin lights + op_mode pulse (SIEGE/SCAN/land).
- 0 Tripo. Sequential after scan/landscape.


| 2026-08-13 | `s3://neon/generations/` = approved design renders + orthogonal Tripo schemes; index `generations/catalog.json` updated on every ingest | Owner + sequential-dev |
| 2026-08-14 | Phase 0 playtest: AbilitySystem activate, rules/04 costs, enemy scan cache, CombatJuice label pool, site_pin, canon identity cards. No DMG. | sequential-dev |
| 2026-08-15 | Clash HUD collapse (banner/ScoreLine/LaneHUD); ship bolt sweep + hull crit recover + shield hold; pad turrets track hulls. No permadeath, no P2W. | sequential-dev |
| 2026-08-15 | Clash towers are live Turrets; ship afterburn W+Shift (energy); walker variable jump cut. Soft pressure only. | sequential-dev |
| 2026-08-15 | **Full code audit + hardening** — 101 scripts / 10 scenes / 12 autoloads. ~110 confirmed defects, blockers fixed, pad streaming memory climb closed. Single record: `docs/PROTOTYPE_TO_PLAYABLE.md` | owner brief: prototype → playable |
| 2026-08-15 | **Galaxy layer planned + G0 built** — star at the system origin, bodies on distinct orbits, belt from data. Hyperspace, hyperdrives, NAEXOS gates, galaxy/system maps and arena-from-map specified. Authority: `docs/design/GALAXY_LAYER_PLAN.md`; assets: `docs/design/TRIPO_ASSET_MANIFEST.md` (78 assets); plan: `DEVELOPMENT_PLAN.md` Phase G | owner brief: star system + hyperspace + gates + map |
| 2026-08-16 | WorldFill canon + asset source split (PR #6). Authored skeleton vs unnamed fill. No SITE_* mint. | world-fill |
| 2026-08-17 | P0.6 squash on main: HUD, hold-S 770→0, EVA on Relief, HOVER S. RTX 3090: land/EVA/takeoff, 6 min / 60 FPS, 0 debugger errors. Not FPS PASS on llvmpipe. | P0 runtime |
| 2026-08-17 | OPEN SPACE SC benchmark plan (OS-A…OS-H). Port unique #7 canon docs; drop #7 code. HUMAN_UNFIT superseded by 3090 fact. G2–G6 stay closed. | open-space-sc |
| 2026-08-17 | OS-H ritual harness: space→atmo→land→EVA→takeoff→space, same scene. Headless steps; F5 documented. Not 3090 FPS / 5 min soak. | os-h-ritual |
| 2026-08-17 | SC pillar 4 module HP: integrity scales thrust/weapon/shield; hull stays; occupy-to-hold pad repair (no cash). No power/cool/life buses. | ship-module-hp |
| 2026-08-17 | SC pillar 7 zero-G EVA near ship (not dirt): no planet gravity, fuel+tether stay, F reboard. OS-H ritual intact. Still ARK. | zero-g-eva |
| 2026-08-17 | SC pillar 11 pad fuel: SCM/HOVER tank spends; occupy-to-hold refill; Knowledge labels pump only; empty = limited thrust / no afterburn. No G1 CRUISE. | pad-fuel |
| 2026-08-17 | SC pillar 11 leftover: occupy locker restocks energy / Pulse CDs (no cash skip). Knowledge labels locker only. Fuel + module repair stay. | pad-restock |
| 2026-08-17 | SC pillar 3 ship as place: seat→pocket→hatch EVA; doors lead to pocket or EVA. No multi-crew. No SITE_*. | ship-as-place |
| 2026-08-17 | OpenSpace HUD stack: fuel / cargo / worst module / landed·occupy / EVA 0G. No overlap with GFX/FPS/OBJECTIVE or no-P2W. Clash unchanged. | openspace-hud-stack |
| 2026-08-17 | SC pillar 10: live Contribution/Biomass on occupied unnamed pad via OpenSpace HUD stack. Harvest yield unchanged. Not ST-A. | pad-contrib-visible |
| 2026-08-22 | ST-A: StrategyOverlay (B) on unnamed Nex-Prime pad + one PlayerHabitat (0 combat). Honest range refusal. No SITE_*. Ship/TPS survive exit. G2–G6 stay closed. | st-a-overlay |
| 2026-08-27 | ST-B: visible PadHarvestExtractor on unnamed pad; occupy → harvest → Contribution on HUD. Knowledge labels only. No SITE_*. | st-b-extractor |
| 2026-08-27 | ST-C: PadPrintBench on unnamed pad / NPC bench. Spend Contribution/Biomass (rules/15 T1) → one catalog module. No cash-shop skip. Knowledge labels only. | st-c-print |
| 2026-08-27 | ST-D: hangar queue of one module on catalog carrier (`cybernex_capital_carrier` …). Refuse mass/power. Not a mobile SITE_*. Interiors later. | st-d-hangar |
| 2026-08-27 | ST-E: player-owned orbital cluster of two catalog modules (dock + habitat) on Nex-Prime orbit. Not a city. Not SITE_*. Not ORBITAL_STATIONS. | st-e-orbital |
| 2026-08-27 | ST-F: CX↔GR owner swap on one occupied unnamed pad. Theme + services change. Harvest / print / hangar numbers stay. Not SITE_*. Not arena-flip. | st-f-owner |
| 2026-08-29 | AR-E leftover: cycle_form advances from live current_form, not stale _form_index after SoftSession restore (Feline+0 → Feline). Identity only; no HP/DPS. |
| 2026-08-29 | OS-H leftover: F-board frees the pad walker; occupy / HUD / dummy no longer read `global_transform` on a node that is valid but off-tree. ST-F playtest `get_meta("site_pin")` uses a default. | os-h-freed-actor |
| 2026-08-29 | OS-H leftover: SoftScanCache get_player/pads/ships/enemies require `is_inside_tree`; Pulse hurtbox skips off-tree; F-interact same. | os-h-scan-cache |
| 2026-08-29 | OS-H leftover: EVA snap facing uses pad-tangent hull nose (`set_spawn_facing`), not world-XZ yaw around pad_up (sideways W). | os-h-eva-facing |
| 2026-08-29 | IN leftover: F at pocket hatch exits (airlock). F at seat still boards. F while seated leaves seat. No silent miss / try_enter_ship from y=9200. | in-f-hatch |
| 2026-08-29 | Walker landing absorb: impact from last airborne v_up, planar settle, crouch/cam dip, pad drop playtest. Arena PlayerController same. | walker-land-absorb |
| 2026-08-29 | Rover OS-I leftover: off the 28 m plate dirt trimesh owns the floor (analytic only core-fall). Space brake via set_drive_command. Slope snap like walker. | rover-os-i-brake |
| 2026-08-29 | Ship pad land: settle from approach height onto `_land_hold_h`, not teleport +4 m. Playtest start h≥5.2 → hold. | ship-land-settle |
| 2026-08-29 | HOVER hold: pad no longer rewrites `_hover_hold_alt` to deck+8 (autopilot). Ground-effect still cushions. | hover-hold-pd |
| 2026-08-29 | Walker dirt slope: PlanetRelief.slope_rad finite-diff. Grip uses max(floor, relief) off-pad. | walker-dirt-slope |
| 2026-08-29 | Rover dirt slope: same PlanetRelief.slope_rad off plate/ramp. Pad/ramp stay floor-only. | rover-dirt-slope |
| 2026-08-29 | Walker coyote on dirt: near relief refreshes coyote; request_jump playtest. | walker-dirt-coyote |
| 2026-08-29 | Interior hatch onto pad: spawn facing is pad-tangent hull nose (same as EVA). Seat leave is local −Z. | in-hatch-facing |
| 2026-08-29 | Pocket HUD: F at hatch is airlock (`F/I hatch`). Labels match. | in-hatch-hud |
| 2026-08-29 | Pocket floor: catch at stand-height (not 5 m void). Playtest h in 0.6…3.5. | in-pocket-floor |
| 2026-08-29 | Occupy HUD after F-board: origin is hull when walker is freed. | hud-occupy-board |
| 2026-08-29 | Rover dirt stick: near relief, catch at 0.85 m (not 3 m). | rover-dirt-stick |
| 2026-08-29 | Surface land: hold is radius+relief+gear, not sphere+3.5. | ship-dirt-land |
| 2026-08-29 | EVA after surface land: beside hull on Relief, not nearest pad. | eva-dirt-hull |
| 2026-08-29 | EVA dirt facing: local radial up + hull nose (not nearest-pad up). | eva-dirt-facing |
| 2026-08-29 | HOVER dirt: pad ground-effect only on the plate (lat ≤16 m). | hover-dirt-hold |
| 2026-08-29 | Approach assist: plate envelope only (lat ≤28, deck 0.5…22 m). | approach-plate |
| 2026-08-29 | LAND READY / pad snap: plate envelope. Overflight is deck→22. | land-ready-plate |
| 2026-08-29 | Ramp AGL: deck height on plate (lat ≤28). Dirt AGL off-plate. | ramp-agl-plate |
| 2026-08-29 | Ship altitude_agl: deck on plate, Relief off-plate (CargoRamp). | ship-agl-plate |
| 2026-08-29 | Player-ship ramp pose host: 7 m HOVER deploy, 40 m too high. | ship-ramp-hover |
| 2026-08-29 | Ramp dirt: Relief AGL off-plate. layout_to_deck plate-only. | ramp-dirt-agl |
| 2026-08-29 | Occupy HUD: claim_radius 40 m. Dirt 50 m is not PAD occupy. | occupy-hud-dirt |
| 2026-08-29 | Pad radar: on-foot 400 m. 12 km only when piloting. | pad-radar-dirt |
| 2026-08-29 | snap_to_pad: lat>16 dirt refuse. Keep 12–16 occupy offset. | snap-dirt |
| 2026-08-29 | I-hatch after dirt land: beside hull, not nearest pad. | hatch-dirt |
| 2026-08-29 | I-hatch dirt facing after exterior place; live radial up. | hatch-dirt-facing |
| 2026-08-29 | Occupy HUD after dirt I-hatch: live walker, not hull. No PAD. | occupy-hatch-dirt |
| 2026-08-29 | Pad radar after dirt I-hatch: restore chrome, 400 m on-foot. | radar-hatch-dirt |
| 2026-08-29 | OS-stack after dirt I-hatch: TPS layer, no occupy/0G. | os-stack-hatch-dirt |
| 2026-08-29 | I-hatch dirt: zero pocket velocity, AGL on Relief. | hatch-dirt-agl |
| 2026-08-29 | I-hatch dirt: surface profile after snap; coyote/jump. | hatch-dirt-coyote |
| 2026-08-29 | I-hatch dirt: _update_up radial; slope = Relief. | hatch-dirt-slope |
| 2026-08-29 | F-board after dirt I-hatch: 28 m hull-side, not 16 m pad. | hatch-dirt-board |
| 2026-08-29 | Dirt launch hold = altitude_agl (Relief), not sphere vs pad. | hatch-dirt-launch |
| 2026-08-29 | HOVER PD after dirt launch uses altitude_agl; hold stays. | hover-pd-dirt-launch |
| 2026-08-29 | HOVER GE after dirt launch: altitude_agl, pad term lat≤28. | hover-ge-dirt-launch |
| 2026-08-30 | HOVER+S dirt launch: altitude_agl, hold floor 4 m not 8. | hover-sink-dirt-launch |
| 2026-08-30 | Dirt LAND after HOVER+S: altitude_agl, no pad steal. | dirt-land-after-sink |
| 2026-08-30 | F-EVA after dirt land (post sink): hull-side Relief, not 0G. | eva-after-dirt-sink-land |
| 2026-08-30 | F-EVA dirt facing after settle: hull-nose tangent. | eva-dirt-facing-after-sink |
| 2026-08-30 | F-EVA dirt coyote after sink land: grace 0, jump. | eva-dirt-coyote-after-sink |
| 2026-08-30 | F-EVA dirt slope after sink land: Relief, not Y-cliff. | eva-dirt-slope-after-sink |
| 2026-08-30 | Occupy HUD after F-EVA dirt (post sink): walker, not hull. | occupy-hud-eva-dirt-sink |
| 2026-08-30 | Pad radar after F-EVA dirt (post sink): 400 m, origin _up. | pad-radar-eva-dirt-sink |
| 2026-08-30 | OS-stack after F-EVA dirt: TPS, occupy origin, not 0G. | os-stack-eva-dirt-sink |
| 2026-08-30 | F-board after F-EVA dirt: occupy hull, layer Space. | board-after-eva-dirt-sink |
| 2026-08-28 | ST-G: factory in existing PlayerOrbitalStation cluster. Bench (c) spend Contribution/Biomass → one catalog module. Without factory, (c) refuses. No SITE_*. ST-E stays dock+habitat. | st-g-factory |

| 2026-08-21 | OS-I closeout: warm dirt trimesh before EVA snap; disable pooled chunk collision; stop analytic floor-assist fighting hills (fall-through after F/I). Character yaw 0/PI only — no 90deg sideways walk. |
| 2026-08-21 | OS-J: orbit-read FarPlate/FarMast/outpost hide below ~400 m. Near hull metal. Cyan 96 m slab was the blue monolith next to the ship. |
| 2026-08-23 | ST-A: B overlay on unnamed pad (Pad_North class); one catalog habitat, 0 combat, no SITE_*. Esc leaves ship/TPS. |
| 2026-08-28 | NP-C: visitor places one catalog habitat on an empty unnamed pad (not Pad_North if ST-A already used it). 0 combat. No SITE_*. One per hull. |
| 2026-08-27 | OS-E PBR leftover on current main: drop unshaded, bind CC0/fallback, chart UV. ST-A overlay/habitat kept. OS-I physics not this slice. | os-e-pbr |

## Full code audit + hardening — 2026-08-15

Authority: **`docs/PROTOTYPE_TO_PLAYABLE.md`** — the single record of this pass.
Read it before touching combat, pads, ship flight, the walker or the arena.
Summary of what every agent must now assume:

### Traps found here — do not reintroduce

- `get_floor_angle()` **must** be passed radial up on a planet. The default is
  world +Y, which reads flat ground as a cliff.
- Never derive a tangent frame from a fixed world seed axis. `SurfaceFacing`
  exposes `basis_from_up_ref` + `transport_ref`; carry the reference between
  frames or the frame snaps 90° near world ±Z.
- A gated AI tick must drain cooldowns by the **gated interval**, not one
  `delta`, or rates silently scale with FPS.
- Set `faction` **before** `add_child`: `_ready` picks groups, mesh and label
  from it.
- Never iterate `SoftScanCache.get_enemies()` while damaging — a kill clears the
  shared array. Snapshot first.
- "Planar" on a sphere means the target's own ground plane, not world XZ.
- Streaming that only toggles `visible` is not streaming — free the subtree and
  reset every flag the builder reads.
- Only one owner per HUD line, and only one initiator per input action. Two
  systems polling the same key double its effect.
- A one-time styling pass must run after the nodes it styles exist.
- `--check-only --script` does not register autoloads, and `--script` cannot load
  a scene script that references them; "Identifier not found: GameManager" from
  those modes is a false positive. Probe inside a scene instead.
- Headless frames run far faster than wall clock — await timers, not
  `process_frame`, when testing anything time-throttled.

### Invariants (re-established, must hold)

1. Knowledge / Contribution / Biomass are soft only — never damage, HP, CDR or
   claim strength (rules/08, rules/04).
2. No friendly fire, and no self-damage. Guard at the receiver, not just the
   caster.
3. Infection hard cap 5, with a real bounded effect via the attacker faction
   passed into `take_damage(amount, source_faction)`.
4. No permadeath anywhere: walker, arena hero and ship all recover.
5. Arena influence on the persistent map is capped, temporary and decaying
   (`PadBaseController.apply_arena_influence`), never a raw `claim_strength`
   write.
6. Claims need presence, and one press is one pulse
   (`PadBaseController.claim_pulse_from`).
7. Harvest credits the **owning** faction, not the local player's selection.

8. Every HUD line has exactly one writer, in play mode and under F3.

### Measured, not asserted

- Arena floor: every capsule probe rests at `y=0.750`, MID lane worst step
  `0.000` (it was `3.250` — the player stood on a wall lying down the lane).
- Pad streaming: node count peaks at 688 with pads up and returns to 502 after
  retreat, and a second lap returns to exactly 502 again. The +90 residual is
  one-time pool allocation, not a leak; no planet stays built.

### Known debt left open (with reasons)

- `harvested` / `contribution_gained` / `influence_emitted` have no listeners
  yet. `claimed` now also drives a "pad lost while you were away" toast from
  inside the controller.
- `_spawn_asteroid_belt`, `_schedule_surface_settle` are content hooks, still
  uncalled.
- The arena hero's procedural silhouette has no locomotion animation — art work,
  not a logic defect.
- Mac 10-minute soak still needs the owner's GPU for the FPS half of rules/25;
  this VM is llvmpipe, so only the memory half is signed off.


