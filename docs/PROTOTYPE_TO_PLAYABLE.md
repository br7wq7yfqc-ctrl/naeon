# NAEON — From prototype to playable

> **2026-08-15 historical audit.** Current GPU fact (17 Aug 2026, RTX 3090 / P0.6): land / EVA / takeoff, hold-S 770→0, 6 min / 60 FPS, 0 debugger errors. Not FPS PASS on llvmpipe. Next bar: `docs/design/OPEN_SPACE_SC_BENCHMARK.md`.

**Single record of the 2026-08-15 hardening work.** Owner brief: audit the whole
codebase, fix what is broken, and move the build away from "raw prototype".
A follow-up brief then added the galaxy layer — see §7, with the design in
`docs/design/GALAXY_LAYER_PLAN.md` and the asset list in
`docs/design/TRIPO_ASSET_MANIFEST.md`.

This is the one document to read before touching combat, pads, ship flight, the
walker or the arena. It supersedes the scattered notes; `docs/SHARED_AGENT_MEMORY.md`
points here, and `docs/systems/PHASE0_PLAYTEST.md` items 53–74 are the short
changelog form of what follows.

- **Scope:** 101 GDScript files, 10 scenes, 12 autoloads.
- **Confirmed defects:** ~110, each verified against running code, not inferred
  from names.
- **Branch:** `cursor/full-code-audit-40fa` · PR [#4](https://github.com/br7wq7yfqc-ctrl/naeon/pull/4)
- **Gate:** `scripts/playtest_headless_smoke.sh` →
  `OS_ERR=0 · TA_ERR=0 · MM_ERR=0 · MECH_CODE=0 · MECH_ERR=0 · [Playtest] PASS`

---

## 1. Why the build felt raw

Not missing features. Systems that **looked** implemented and were inert,
inverted, or measured against the wrong axis. Grouped by what the player felt.

### 1.1 "The floor is wrong"

| Defect | What the player got |
|--------|---------------------|
| `Barrier/CollisionShape3D` reused the 60×1×60 floor shape while its mesh was a 0.4×2.5×12 wall | An invisible slab over ~77% of the arena; the player spawned a body-height above the lane strips |
| The same `Barrier` lay **lengthwise down the middle of the MID lane** at `(0, 1.25, -14)`, 2.5 m tall and walkable | You stood on top of a wall in the middle of the lane and dropped 2.5 m stepping off it. A capsule probe rested at `y=3.250` instead of `0.750` |
| The friendly MID tower sat at `z=12`; spawn is `z=6` and the chase camera trails to `z≈10.5` | A translucent 3.2 m column filled the view and hid the player on load |

Both `Barrier` problems had to be fixed: the shape **and** the placement. After
the fix every probe point rests at `0.750` and the MID lane has a `0.000`
vertical step from end to end.

### 1.2 "Movement fights me"

`get_floor_angle()` with no argument measures against world **+Y**. On a sphere
that makes every flat patch read as a 40–180° slope:

- the walker was clamped to the 0.52 speed floor **everywhere**, and permanently
  took the "canyon" branch that raises `floor_max_angle` to 70°, so it could walk
  up near-vertical cliffs;
- the rover's grip went negative before the clamp rescued it to 0.38, capping it
  at 5.3 m/s of a designed 14.

`SurfaceFacing.basis_from_up` switched its seed forward from `(0,0,-1)` to
`(1,0,0)` at `|dot| > 0.95`, and the two projections disagree in the tangent
plane. Crossing the band within 18° of world ±Z snapped body, camera and — for
the rover, which derives travel direction from its basis — the **drive
direction** 90° in a single frame. Both now parallel-transport a tangent
reference frame to frame (`basis_from_up_ref` + `transport_ref`).

Also: knock was built as `Vector3(dir.x, 0, dir.z)` plus world `+Y`. On a planet
"up" is radial, so hits shoved the walker sideways and dug the impulse into the
ground. It now uses the body's own `up_direction`.

The walker read `KEY_W/A/S/D` and `KEY_SHIFT` directly and never consulted the
`move_*` / `sprint` actions that exist in `project.godot`, so rebinding and
gamepad sticks did nothing on the main character.

### 1.3 "Nothing threatens me"

`Turret._process` drained `_cd` by a single frame's `delta`, but the statement
sat behind an AI-tick gate of 0.12–0.22 s. Cooldowns ran 7–13× too slowly **and
faster machines made turrets slower**. Every turret, pad guard and lane tower was
effectively harmless. Fixed by draining the gated interval.

Dead turrets and dummies stayed in the `enemy` group with `visible = false`, so
live turrets locked onto corpses they could never damage (`CombatHits` correctly
refuses dead targets), and the arena's lane refill counted bodies as living —
reinforcement stopped after the first wave.

`CombatHits.apply_shot` never scanned the `ally` group, so a correctly-spawned
Cybernex turret was **invulnerable**. The two production spawners only worked
around it by force-moving guards into `enemy`.

### 1.4 "The loop runs out"

`crystal_reserves` was decremented and never regenerated. Each pad yielded
`120 × 0.35 = 42` economy and was `depleted` forever. Two pads per planet across
three planets caps the whole game near 252 against the 1600 the rank ladder
needs — the core loop died after roughly three minutes. Reserves now regenerate
while nobody is extracting.

`_open_contest` wrote `transition_progress = 0.35` while flagging the pad
`CONTESTED`, so `_process` saw `>= 1.0` 3.25 s later and flipped `_status` to
`"owned"` — which permanently disabled `_decay_contest`, the only path back. Two
rival C pulses and a walk away killed a pad for the session: no harvest, no
decay, hostile guard alive, label reading `BASE CONTESTED / owned`.

Harvest paid whichever currency the **local player** had selected rather than the
pad's owner, so a Cybernex base could pay Biomass; extractors bypassed the shared
deposit entirely and always paid Contribution.

### 1.5 "Systems that were pure decoration"

- `ChannelController` never joined `channel_controllers`, the only group
  Nex-Firewall's counterplay scans — breaking an enemy channel never fired once.
- `SurfaceWalker.firewall_timer` was written, never decremented, never read:
  Firewall gave the surface hero zero mitigation, and the flag stayed set forever.
- `InfectionStatus.damage_taken_mult_from_grot()` had **no callers anywhere**. The
  entire gROT pressure mechanic was cosmetic outside a 1.2 s glitch slow.
  `take_damage(amount, source_faction)` now carries the attacker's faction.
- `SurfaceWalker` had no downed state and no `is_downed()`: at 0 HP it refilled in
  place. Since `CombatDummy` and `Turret` both gate on `is_downed`, attackers never
  disengaged — an endless hit-refill loop.
- Rot Surge iterated the **live** `SoftScanCache` array; the first kill called
  `invalidate_enemies()` → `clear()`, ending the loop. Four 5 HP targets in radius:
  one died, three untouched. It also only scanned `enemy`, so it could not reach
  players or hulls at all — a PvE-only tool in a faction-vs-faction mode.
- `_refresh_weapon_visual` freed children whose **name** contained "weapon"/"cannon"/…,
  but nothing names them: 0 of 3 matched, so every SIEGE/SCAN toggle added a mesh.
- `_role.siege_dps_mult` does not exist (it is `siege_main_dps_mult`), so the
  per-role DPS knob was dead data and SIEGE always used the 1.35 literal.
- `apply_faction_modules(faction)` shadowed the member, so after a faction swap
  the hull kept the old team tag on every projectile and pad claim.
- `PadDensityCluster` / `PadAmbientLife` / `CityNightLights` were parented to the
  pads root at the **planet centre** — every prop, creature and city tower was
  built ~1400 m underground, and `_update_city_density` then looked one level too
  low and returned early every time.
- `AexionClash.match_ended` had no listeners and `ClashMatchDirector.register_kill`
  had no callers: the match ended silently and kills paid no reward.
- `_harvest_vfx`, `_relief_floor_assist` and `_wade_splash` were fully written and
  never called.

### 1.6 Rules violations

The design rules are not decoration either. These were being broken in code:

- `Ability` multiplied damage by `1.0 + GameManager.knowledge_insight_bonus()`,
  and `knowledge_rank` is fed by `add_mastery()` on every harvest tick. **Harvest
  time bought up to +15% weapon damage** — the exact link rules/08 forbids.
- Hack auto-acquire ignored faction, and `Turret.on_hacked` / `CombatDummy.on_hacked`
  applied damage unconditionally. A Cybernex probe destroyed friendly towers, and
  in Clash that paid **+28 lane pressure and +15 objective score for killing your
  own tower** — the fastest way to win a lane.
- `CombatDummy` never compared factions, so friendly bots shot the player.
- `WarScore.daily_earned` was instance state on a tracker rebuilt on every arena
  load, and nothing was persisted: the documented 60/day cap was a per-scene-load
  cap. Now written to `user://war_score.cfg`.
- `emit_soft_influence` wrote `ownership.claim_strength` permanently. Replaced by
  `PadBaseController.apply_arena_influence` — capped, decaying to zero over ~10
  minutes, and never able to flip ownership on its own (rules/13).
- `MATCH_WIN_WS` was 8 against the documented 15; loss participation (+3) did not
  exist.

### 1.7 Feel

- Variable jump height fired on **any** airborne rise, so knockback was silently
  cut to 42%. Now gated behind a `_jumped` flag only a real jump sets.
- The jump buffer was decremented only in the key-released branch, so holding
  jump through a long fall auto-hopped on landing.
- Landing absorb read `v_up` after `move_and_slide` had flattened it — a 19.8 m/s
  landing arrived as `0.000`, so the absorb never fired. It now reads the last
  airborne rise.
- EVA regenerated 8/s while thrusters burned 3.8/s: **net +4.2/s**, so the fuel
  budget did not exist and the low-energy penalty was unreachable. EVA also never
  integrated gravity, so stepping off a hovering ship inside an atmosphere granted
  free flight.
- Mag-boot pull went negative past 3.5 m and actively pushed the player away
  from the hull.
- Launch forced SCM (stall speed 16 m/s) at a launch speed of 3.81, so **every
  launch began at a guaranteed 76% stall**. It now stays in HOVER, which has no
  stall speed.
- HOVER captured a hold altitude even in vacuum and then spent the session
  driving the ship back toward it — measured climbing at +2.1 m/s from 300 m AGL
  with a 20 km hold, which the 22 m/s trim would need 909 s to walk down.
- HOVER stripped the whole lift projection, which also ate part of the gravity
  cancellation: a pitched hull slid sideways off the pad (2.63 m over 2 s at 45°).
- The HOVER landing envelope was 24 m/s against the mode's own 22 m/s top speed,
  so that half of the gate could never fire.
- `_tick_combat` sat behind the `pilot_active` early return, so taking
  hull-critical damage and stepping out pinned the ship at 45% thrust and 0 regen
  indefinitely.
- Afterburn had no energy floor and strobed on/off every frame near empty — 39
  transitions in 40 physics frames.
- `attach_module` had no cap: 40 presses of C reached 43 modules and 620 cargo,
  leaking 43 visual nodes.
- `approach_assist` computed closing speed with the sign flipped, so the brake
  fired on **departure**: 21.4 m travelled in 3 s of full thrust near a pad
  against 69.3 m away from one.
- Boarding the rover only hid the walker: WASD drove the rover **and** walked the
  hidden body away, Space jumped it, its abilities still fired, and it stayed the
  `player` group target enemies track. Unboarding cleared the rover camera without
  restoring the pilot's, so Godot promoted an arbitrary camera.
- Interior mode was applied and then overwritten by `set_eva_profile`, and never
  restored `MOTION_MODE_GROUNDED`; an EVA→interior transition left the player
  sinking through the floor with no jump.
- The pad polled `KEY_C` itself while the ship claimed on the same press: one tap
  applied 0.88 against a 0.45 threshold, **from the air**, making occupy-to-hold
  decorative.
- `snap_to_surface` probed from `+40` and took the first hit downward, so anything
  overhead became the "surface" — and since it also runs on every death, recovery
  could strand you on a roof.
- Pressing Esc to release the mouse abandoned the match: the arena hero never
  consumed `ui_cancel`, so `TestArena` handled it too.
- **The land gate was honest but illegible.** `_do_land` refused with
  "Approach a pad (<90m) or low surface", which restates the rule instead of
  saying which condition failed. A tester given the full control scheme spent
  many attempts and never landed, reading the refusal as a bug. The ship HUD now
  carries a live `land_readiness_line()` — `LAND: alt 600→120`,
  `LAND: pad 148m→90m`, `LAND: slow 12.3→12`, or `LAND READY — E` — and the
  refusal toast names the same failing term. The gate itself is unchanged; both
  it and the readout now read one `_land_envelope()`.
- `nearest_pad` force-built the entire pad complex synchronously, and
  `ShipController` calls it every physics frame — a hard freeze each time a ship
  crossed 500 m AGL, defeating the staggered builder written to prevent it.
- The minimap negated Z against its own comment, drawing the enemy nexus at the
  bottom and every enemy behind the player, and plotted each gROT node twice (the
  dedupe compared a `Node` against an `Array` of `Vector3`).
- `GameHUD` wrote the status line, ability chips, channel bar and contested banner
  **twice per refresh in different formats**; under F3, `GameHUD`, the legacy
  `TestArena` labels and the director's `ScoreLine` all wrote the same two corners.
- Canon look-dev boards spawned at `z=8`, between the camera and the spawn.

### 1.8 Performance (rules/25)

| Hot path | Was |
|----------|-----|
| Pad streaming | Leaving a planet only hid the pads root — every visited planet kept pads, GLB, base clusters, rings and guards for the session |
| `PadBaseController._refresh_label` | Formatted string + `Label3D` glyph rebuild every frame while harvesting, forever once depleted |
| `_tint_recursive` | A fresh `StandardMaterial3D` per mesh per frame during a claim transition (~25 meshes) |
| `OwnershipComponent._process` | Unthrottled on 6 instances, writing 3 material params + a new string per frame (~360 strings/s) |
| `ClashLanes._box` | A unique `BoxMesh` + `StandardMaterial3D` per box — 45+ materials, each its own draw call |
| `TestArena._apply_arena_hud_layout` | Six theme overrides re-applied 5×/s, each firing `NOTIFICATION_THEME_CHANGED` |
| `GameHUD` radar sort | O(n²) with two distance calls per comparison, 8×/s, plus rebuilding hidden text |
| Per-shot `load()` | 4 in `ShipController._fire_weapon`, plus `Turret`, `Ability`, `ProjectileRunner`, `CombatJuice` |
| Per-frame node lookups | `get_node_or_null("/root/GraphicsQuality")` in `Turret` and `CombatDummy`; a `ship` group scan every physics frame in EVA |
| `_spawn_jump_fx` | A fresh `GPUParticles3D` + material + mesh + `SceneTree` timer per jump |
| Ship `Label3D` | Text reassigned every physics frame, regenerating the glyph mesh; `_recompute_stats` re-walked modules every frame; `_apply_attitude` wrote `global_transform` once per mouse event |
| `CombatJuice` flood budget | `int(delta * 18.0)` truncates to 0 above ~18 FPS, and the `flooded` flag was computed and never used |
| `ProjectilePool._active` | Never accounted for bolts freed with the scene, so the counter drifted up across every scene change |

---

## 2. Evidence

### Headless gate

```
OS_ERR=0
TA_ERR=0
MM_ERR=0
MECH_CODE=0 MECH_ERR=0
[Playtest] PASS
```

### Arena floor geometry probe

Downward rays along the MID lane plus a capsule dropped at five points:

```
MID lane worst step between samples: 0.000
from (0, 4, 6)    rest y=0.750 on_floor=true
from (0, 4, 0)    rest y=0.750 on_floor=true
from (0, 4, -10)  rest y=0.750 on_floor=true      # was 3.250 (standing on the wall)
from (14, 4, -6)  rest y=0.750 on_floor=true
from (-14, 4, 12) rest y=0.750 on_floor=true
```

### Pad streaming leak test (two laps of all three planets)

```
baseline nodes=412
lap0 near Nex-Prime  built=true  nodes=550
lap0 near ROT-Hive   built=true  nodes=688
lap0 retreat         nodes=502  still_built=0  (+90 over baseline)
lap1 near Nex-Prime  built=true  nodes=610
lap1 near ROT-Hive   built=true  nodes=718
lap1 retreat         nodes=502  still_built=0  (+90 over baseline)
```

Lap 1 returns to **exactly** the lap 0 figure, so the +90 residual is one-time
pool allocation in the surface systems, not a leak, and no planet stays built.

### Landing readout, driven down through the envelope

```
alt 600  LAND: alt 600→120
alt 300  LAND: alt 300→120
alt 150  LAND: pad 148m→90m      # pads have streamed in by here
alt  80  LAND READY — E
alt  20  LAND READY — E
fast     LAND: slow 12.3→12
```

Landing itself measured working: at 80 m altitude `nearest_pad` returns
`Pad_North` at 79.4 m and `_do_land()` sets `is_landed=true`. At 300 m the pads
are legitimately not streamed in yet (tier 0 builds at `radius + 220`) and
`altitude_of` exceeds the 120 m surface-land limit — which is exactly what the
new readout now says out loud.

### GUI playthrough

Walked the MID lane end to end at constant height, fought to 5 kills, saw the
result panel, rematched with Enter, and confirmed the F3 overlay is readable.

---

## 3. Method note worth keeping

A visual review and a code reading disagreed about whether the player was
floating. Rather than pick a side, I wrote a headless probe that ray-casts the
floor and drops a capsule at known points. One run settled it **and** found the
real cause, which neither observer had named: the wall lying down the lane.

When observation and code disagree, measure.

---

## 4. Invariants — these must keep holding

1. Knowledge, Contribution and Biomass are **soft only**. No code path turns them
   into damage, HP, cooldown or claim strength (rules/04, rules/08).
2. Nothing damages its own faction, and nothing damages itself. Guard at the
   **receiver**, not only the caster.
3. Infection hard-caps at 5 and has a real bounded effect, delivered through
   `take_damage(amount, source_faction)`.
4. No permadeath anywhere: walker, arena hero and ship all recover.
5. Arena influence on the persistent map is capped, temporary and decaying
   (`PadBaseController.apply_arena_influence`) — never a raw `claim_strength` write.
6. Claims need presence, and one key press is one pulse
   (`PadBaseController.claim_pulse_from`).
7. Harvest credits the **owning** faction, not the local player's selection.
8. Every HUD line has exactly one writer, in play mode and under F3.

---

## 5. Traps that caused these bugs — do not reintroduce

- `get_floor_angle()` **must** be passed radial up on a planet. The default is
  world +Y, which reads flat ground as a cliff.
- Never derive a tangent frame from a fixed world seed axis. Use
  `SurfaceFacing.basis_from_up_ref` + `transport_ref` and carry the reference
  between frames.
- A gated AI tick must drain cooldowns by the **gated interval**, not one
  `delta`, or rates silently scale with FPS.
- Set `faction` **before** `add_child`: `_ready` picks groups, mesh and label
  from it.
- Never iterate `SoftScanCache.get_enemies()` while damaging — a kill clears the
  shared array. Snapshot first.
- "Planar" on a sphere means the target's own ground plane, not world XZ.
- Streaming that only toggles `visible` is not streaming. Free the subtree and
  reset every flag the builder reads.
- One owner per HUD line and one initiator per input action; two systems polling
  the same key double its effect.
- A one-time styling pass must run after the nodes it styles exist —
  `_apply_arena_hud_layout` ran from `_ready`, before `LaneHUD` was built.
- `--check-only --script` does not register autoloads, and `--script` cannot load
  a scene script that references them. "Identifier not found: GameManager" from
  those modes is a false positive; probe inside a scene instead.
- Headless frames run far faster than wall clock. Await timers, not
  `process_frame`, when testing anything time-throttled.

---

## 6. Still open, deliberately

- `harvested`, `claimed`, `contribution_gained` and `influence_emitted` are
  correct signals with no consumers yet. `claimed` now also drives a
  "pad lost while you were away" toast from inside the controller; a proper
  listener belongs to whatever owns the persistent map.
- `_spawn_asteroid_belt` and `_schedule_surface_settle` are content hooks, still
  uncalled.
- `InteriorDirector._begin` can orphan a pocket when `host` is null, and that
  path is unreachable today (`_open_space` is always set by
  `OpenSpace._setup_interior`).
- The procedural hero silhouette has no locomotion animation on the arena hero;
  that is art/animation work, not a logic defect.
- Mac 10-minute soak: **signed off 2026-09-05** on owner GPU.
  GUI Godot 4.7.2 `/Applications/Godot.app` (`--playtest-soak`, not headless).
  Device: AMD Radeon Pro 5600M, Vulkan 1.2 Forward+, display=macOS,
  min preset `LOW (min 1060)`. 41 samples / 600s.
  TIME_FPS min=56.0 avg=59.7 max=60.0 (honest, vsync-capped, not clamped in
  code). MEMORY_STATIC 101.1 → 101.4 MB (delta +0.4, climb_steps=0).
  OBJECT_NODE_COUNT 815 → 815. Headless dummy FPS still must not sign this off.

---

## 7. Galaxy layer — the follow-up brief

Second owner brief on the same day: planets must be naturally spread around their
star; add hyperspace between systems the way Elite Dangerous does it, with
hyperdrives; every system carries gates to its neighbours; add a galaxy map and
navigation; let the player enter the arena from the OpenSpace map; and produce the
full Tripo asset list.

**Design:** `docs/design/GALAXY_LAYER_PLAN.md` — the authority, specified to the
point of implementation. **Assets:** `docs/design/TRIPO_ASSET_MANIFEST.md` — 78
assets with class, faction variant, LODs, priority and generation order.
**Plan:** `DEVELOPMENT_PLAN.md` Phase G (G0–G6). **Concept:** `CONCEPT.md` §6.

### 7.1 Built now — G0, star system layout

The three planets sat on hand-typed coordinates inside one ~4 km clump, and "the
sun" was a `DirectionalLight3D` with a fixed rotation and no body behind it.
Nothing orbited anything.

`StarSystemCatalog` now owns placement, and `PlanetProfileCatalog` keeps only the
physical envelopes:

| Body | Orbit | Angle | Inclination |
|------|-------|-------|-------------|
| Star **Aex** (G, r=900) | 0 | — | — |
| Nex-Prime | 3800 | 24° | 0° |
| ROT-Hive | 7400 | 158° | +6.5° |
| Shard-Moon | 11800 | 268° | −9° |
| Belt | 9000–10400 | ring | ±210 |
| Gates (×3) | 13600–15200 | authored | not spawned |

Distinct angles keep the bodies from lining up; distinct inclinations keep them
out of one plane. The star is a visible emissive body with a corona, each planet
takes its light direction from the star it orbits, and the shadow light aims along
the star→observer line so the terminator matches where the star actually is. The
asteroid belt is called for the first time and takes its band from the layout.

Measured: `Nex-Prime at orbit 3800 · ROT-Hive at orbit 7400 · Shard-Moon at orbit
11800 · system ARK bodies=3`, smoke green.

**Spreading the orbits exposed two defects the old clump hid:**

- **The system was bigger than the render distance.** At the minimum preset the
  camera far plane was 8000, but from the spawn ROT-Hive is 10383 away and
  Shard-Moon 15960 — both were being clipped away entirely, along with every gate
  anchor at 13600–15200. Far clips are now sized to fit a system (LOW 22000 →
  ULTRA 48000) and the near plane moved 0.05 → 0.25, which buys back the depth
  precision that widening the range costs.
- **The star's corona shell rendered as a dark ring.** A constant-alpha additive
  sphere is not a glow: 16% white over black space is flat grey. Removed — a grey
  ring is worse than no corona, and a real one needs the same rim falloff the
  planet atmospheres use (tracked as `star_corona_shell` polish in the manifest).
  Glow post-processing blooms the bright disc on its own at tier ≥ 2.

Both were found by rendering frames in-engine rather than by eye: a probe placed a
camera at known points, aimed it at known targets, and saved real frames. Two
observers using the mouse had failed to find the star at all, because from the
spawn it sits 45° off-axis and partly behind Nex-Prime's limb — which the geometry
readout said outright (`angle_off_camera=45 deg`, `fov=70`).

### 7.2 Deliberately not built yet

Gate anchors are authored in the catalog and **nothing spawns them**. A gate prop
with no jump behind it is precisely the "looks implemented, is inert" defect class
this whole branch spent its time removing — `ChannelController` outside its group,
`InfectionStatus` with no callers, `match_ended` with no listener. Authoring the
data without the prop keeps the layout honest and leaves G4 a clean start.

The same reasoning holds the orbits at their current scale. The plan's target is
~2.8× larger, but at NAV's 180 m/s the outer gate would already be a four-minute
hold of W. The scale-up ships in the same pass as CRUISE (G1), which is what makes
it playable.

### 7.3 Why gates, and why they matter

Gates are not generic sci-fi furniture. The existing lore already says NAEXOS
built a transgalactic network and gROT used it as an **infection vector** after
the Schism. So a gate is exactly where Infection should arrive from, which gives
gate ownership real stakes and lets the design reuse three systems this audit had
just repaired — `InfectionStatus` (hard cap 5), `ChannelController` (Probe to wake
a dormant gate, Firewall to cleanse an infected one), and the pads'
occupy-to-hold meter for the contested state — instead of inventing parallels.

Gate ownership grants **soft** benefits only: faster spool, a traffic readout. No
tolls, no blocking the other faction. A gate the enemy cannot use at all would be
hard power, which rules/04 forbids.

### 7.4 What the audit taught this design

Three lessons from §1 are written into the galaxy plan as requirements:

- **Every refusal names its failing term.** The land gate was honest but illegible
  and read as a bug. So the jump sequence gets `jump_readiness_line()`, and route
  plotting states *why* a leg is impossible rather than omitting it.
- **One owner per readout and per input.** `M` becomes the galaxy map, `N` the
  system map, `F` the beacon interact; `Tab` drops to an F3-gated developer
  shortcut instead of a second way into the arena.
- **Streaming means freeing.** Gate traversal reuses the staggered `PlanetBody`
  builder and the pad unload measured flat in §2, rather than adding a second
  system that only toggles `visible`.

---

Updated: 2026-08-15. Authority for the hardening pass; see
`docs/SHARED_AGENT_MEMORY.md` for the short form every agent loads, and
`docs/design/GALAXY_LAYER_PLAN.md` for the galaxy layer.
