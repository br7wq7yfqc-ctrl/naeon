# NAEON — Full code audit, 2026-08-15

Whole-repo audit of mechanics and function logic, driven by the owner's brief:
move the build from "raw prototype" toward something genuinely playable.
Every item below was confirmed against the real scripts (read + headless
reproduction), not inferred from names.

**Scope:** 101 GDScript files, 10 scenes, 12 autoloads.
**Machine check:** every `.gd` parses. The 43 `--check-only --script` failures
are all "Identifier not found: <autoload>" — that mode does not register
autoload singletons, so they are false positives, not defects.
**Gate:** `scripts/playtest_headless_smoke.sh` →
`OS_ERR=0 · TA_ERR=0 · MM_ERR=0 · MECH_CODE=0 · MECH_ERR=0 · [Playtest] PASS`.

---

## 1. What was actually broken

The prototype felt raw for concrete, findable reasons. The worst offenders were
not missing features — they were systems that looked implemented and were inert
or inverted.

### Blockers (the build was not honestly playable)

| Area | Defect | Consequence |
|------|--------|-------------|
| `scenes/test/TestArena.tscn` | `Barrier/CollisionShape3D` reused `FloorShape` (60×1×60) while its mesh was a 0.4×2.5×12 wall | An invisible slab covered ~77% of the arena; the player spawned a body-height above the lanes and fell off a hidden ledge at z=16 |
| `SurfaceWalker` / `GroundVehicle` | `get_floor_angle()` called with no argument measures against world **+Y**, not radial up | On a sphere every flat patch read as a 40–180° slope: the walker was pinned to 52% speed and could climb near-vertical cliffs; the rover was pinned to grip 0.38 (5.3 m/s of 14) |
| `SurfaceFacing.basis_from_up` | Seed forward switched from `(0,0,-1)` to `(1,0,0)` at `\|dot\|>0.95` | Walking (or driving) across the band within 18° of world ±Z snapped body, camera and drive direction 90° in one frame |
| `Turret._process` | `_cd -= delta` ran once per AI tick (0.12–0.22 s), not per frame | `fire_rate` drained 7–13× too slowly **and scaled with FPS**: every turret, pad guard and lane tower was effectively harmless |
| `PadBaseController._open_contest` | Wrote `transition_progress = 0.35` while flagged `CONTESTED`, so `_process` flipped `_status` to `"owned"` 3.25 s later and disabled the only decay path | Two rival C pulses could freeze a pad forever: no harvest, no decay, hostile guard alive |
| `PadBaseController.crystal_reserves` | Decremented, never regenerated | Each pad yielded 42 economy and died. Total game cap ≈252 against 1600 needed for the rank ladder — the core loop ended after ~3 minutes |
| `ShipFlightModel.approach_assist` | Closing speed computed with the sign flipped | The brake fired on **departure**: leaving a pad cost ~79% of speed per second (21.4 m travelled in 3 s vs 69.3 m away from a pad) |
| `PlanetBody.nearest_pad` | Force-built the whole pad complex synchronously, and `ShipController` calls it every physics frame | A hard freeze every time a ship crossed 500 m AGL, defeating the staggered builder written to prevent exactly that |
| `PlayerController._unhandled_input` | `ui_cancel` never marked the event handled, and `TestArena` also listens for Esc | Pressing Esc to release the mouse abandoned the match with no confirmation |

### Rules violations (no-P2W / soft-Knowledge / no friendly fire)

- `Ability._apply_aoe_burst` and `_spawn_projectile` multiplied damage by
  `1.0 + GameManager.knowledge_insight_bonus()`. Knowledge rank bought up to
  +15% weapon damage, and `knowledge_rank` is fed by `add_mastery()` on every
  harvest tick — harvest time literally bought power. Removed (rules/08).
- Hack auto-acquire ignored faction, and `Turret.on_hacked` / `CombatDummy.on_hacked`
  applied damage unconditionally: a Cybernex probe destroyed friendly towers,
  and in Clash that paid **+28 lane pressure and +15 objective score for
  killing your own tower**. Guarded at both the acquire and the receive end.
- `CombatDummy._find_player` / `_fire_at` never compared factions, so friendly
  bots shot the player.
- `ClashLanes` forced every tower into `"enemy"` regardless of side.
- `WarScore.daily_earned` was plain instance state on a tracker rebuilt on every
  arena load, and nothing was persisted: the documented 60/day cap was really a
  per-scene-load cap. Now persisted to `user://war_score.cfg`.
- `WarScore.emit_soft_influence` wrote `ownership.claim_strength` permanently.
  Replaced with `PadBaseController.apply_arena_influence`, a capped assist that
  decays to zero over ~10 minutes and never flips ownership alone.
- `MATCH_WIN_WS` was 8 against the documented 15 (rules/13); loss participation
  (+3) did not exist.

### Implemented-looking but inert

- `ChannelController` never joined `channel_controllers`, the only group
  Firewall's counterplay scans — breaking an enemy channel never fired once.
- `SurfaceWalker.firewall_timer` was written, never decremented, never read:
  Nex-Firewall gave the surface hero zero mitigation.
- `InfectionStatus.damage_taken_mult_from_grot()` had no callers anywhere. The
  whole gROT pressure mechanic was cosmetic. `take_damage` now carries the
  attacker's faction.
- `SurfaceWalker` had **no downed state and no `is_downed()`**: hitting 0 HP
  refilled in place, and because `CombatDummy`/`Turret` gate on `is_downed`,
  attackers never disengaged — an endless hit-refill loop.
- `Rot Surge` iterated the **live** `SoftScanCache` array; the first kill called
  `invalidate_enemies()` → `clear()`, ending the loop. Four 5 HP targets in
  radius: one died, three untouched. It also only scanned `enemy`, so it could
  not touch players or hulls at all.
- `ShipController._refresh_weapon_visual` filtered children by name, but nothing
  names them — 0 of 3 matched, so every SIEGE/SCAN toggle added another mesh.
- `_role.siege_dps_mult` does not exist (the property is `siege_main_dps_mult`),
  so the per-role DPS knob was dead data and SIEGE always used the 1.35 literal.
- `apply_faction_modules(faction)` shadowed the member, so the hull kept the old
  team tag on every projectile and pad claim after a faction swap.
- `PadDensityCluster` / `PadAmbientLife` / `CityNightLights` were parented to the
  pads root at the **planet centre**, so every prop, creature and city tower was
  built ~1400 m underground; `_update_city_density` then looked for the node one
  level too low and returned early every time.
- `SurfaceWalker._relief_floor_assist` and `_wade_splash` were fully written and
  never called.
- `PlayerController._form_skel` was read but never assigned.
- `CombatJuice`'s flood budget used `int(delta * 18.0)`, which truncates to 0
  above ~18 FPS, and the `flooded` flag was computed and never used.
- `ClashMatchDirector.register_kill` had no callers; `AexionClash.match_ended`
  had no listeners, so the match ended silently and the mode had no conclusion.
- `TurretProjectile.gd` was referenced by nothing and encoded a friendly-fire
  rule. Deleted, with two stale `facing_selftest.gd` copies.

### Feel and correctness

- Variable jump height fired on **any** airborne rise, including knockback.
  Gated behind a `_jumped` flag set only by a real jump.
- The jump buffer was only decremented in the key-released branch, so holding
  jump through a long fall auto-hopped on landing.
- Landing absorb read `v_up` after `move_and_slide` had already flattened it
  (a 19.8 m/s landing arrived as 0.000), so it never fired.
- EVA regenerated 8/s while thrusters burned 3.8/s: net **+4.2/s**, so the fuel
  budget did not exist. EVA also never integrated gravity, so stepping off a
  hovering ship inside an atmosphere granted free flight.
- Mag-boot pull went negative past 3.5 m and actively pushed the player away.
- Launch forced SCM, whose stall speed is 16 m/s, at a launch speed of 3.81 —
  every launch began at a guaranteed 76% stall.
- HOVER captured a hold altitude even in vacuum, then spent the session driving
  the ship back toward it; and it stripped the whole lift projection, which ate
  part of the gravity cancellation and slid a pitched hull off the pad.
- The HOVER landing envelope (24 m/s) was above the mode's own top speed (22),
  so that half of the gate could never fire.
- `_tick_combat` sat behind the `pilot_active` early return: taking hull-critical
  damage and stepping out pinned the ship at 45% thrust and 0 regen forever.
- Afterburn had no energy floor, so it strobed on/off every frame near empty
  (39 transitions in 40 physics frames).
- `attach_module` had no cap: 40 presses of C took the ship to 43 modules and
  620 cargo, leaking 43 visual nodes.
- Boarding the rover only hid the walker: WASD drove the rover **and** walked the
  hidden body away, Space jumped it, and its abilities still fired. Unboarding
  cleared the rover camera without restoring the pilot's, so Godot promoted an
  arbitrary camera.
- Interior mode was applied and then overwritten by `set_eva_profile`, and never
  restored `MOTION_MODE_GROUNDED`, so an EVA→interior transition left the player
  sinking with no jump.
- The pad polled `KEY_C` itself while the ship claimed on the same press: one tap
  applied 0.88 against a 0.45 threshold, from the air, making occupy-to-hold
  decorative.
- Harvest paid whichever currency the **local player** had selected, so a
  Cybernex-owned pad could pay Biomass; extractors bypassed the shared deposit
  entirely and always paid Contribution.
- Pad guards respawned the next frame (the 8 s window never applied) and each
  kill orphaned a dead turret that still answered every target scan.
- Contest FOV re-captured its baseline from an already-widened value and
  ratcheted 70 → 75 over three cycles without returning.
- Dead dummies and turrets stayed in the `enemy` group, so lane refill counted
  corpses (reinforcement stopped after the first wave) and live turrets locked
  onto bodies they could never damage.
- `CombatHits` never scanned the `ally` group, so a correctly-spawned Cybernex
  turret was invulnerable; the two production spawners only worked around it.
- `CombatHits` raised hit feedback **and** four of five `take_damage` owners did
  too: one bolt produced two damage numbers and three hit sounds.
- Faction was set **after** `add_child` at both arena spawn sites, so `_ready`
  filed a "Cybernex" turret as an enemy with a gROT mesh and label.
- The minimap negated Z against its own comment, drawing the enemy nexus at the
  bottom and every enemy behind the player, and plotted each gROT node twice
  (the dedupe compared a `Node` against an `Array` of `Vector3`).
- `GameHUD` wrote the status line, ability chips, channel bar and contested
  banner **twice per refresh in different formats**; one owner each now.
- Canon look-dev boards were spawned at z=8, between the camera and the spawn,
  filling the screen on load.

### Performance (rules/25)

- `PadBaseController._refresh_label` rebuilt a formatted `Label3D` every frame
  while harvesting, forever once depleted; `_tint_recursive` allocated a fresh
  `StandardMaterial3D` per mesh per frame during a claim transition.
- `OwnershipComponent._process` ran unthrottled on all 6 arena instances and
  wrote three material params plus a fresh string every frame (~360 strings and
  ~1080 `RenderingServer` calls per second for values that change on a claim).
- `ClashLanes` allocated a unique `BoxMesh` + `StandardMaterial3D` per box: 45+
  unique materials, each its own draw call.
- `TestArena._apply_arena_hud_layout` re-applied six theme overrides five times
  a second, each firing `NOTIFICATION_THEME_CHANGED`.
- `GameHUD` sorted the pad radar with an O(n²) loop recomputing two distances per
  comparison, 8 times a second, and rebuilt hidden text.
- Per-shot `load()` in `ShipController._fire_weapon` (×4), `Turret._fire`,
  `Ability`, `ProjectileRunner`, `CombatJuice`; per-frame
  `get_node_or_null("/root/GraphicsQuality")` in `Turret` and `CombatDummy`.
- `ProjectilePool._active` never accounted for bolts freed with the scene, so the
  live counter drifted upward across every scene change.

---

## 1b. Found by GUI playthrough, after the static pass

Three defects only surfaced once the arena was actually played. Worth recording
because a read-only audit could not have caught them.

- **The "invisible ledge" had a second half.** Replacing `Barrier`'s collision
  shape was necessary but not sufficient: the wall itself lay **lengthwise down
  the middle of the MID lane** at `(0, 1.25, -14)`, 2.5 m tall and walkable. A
  headless capsule probe came to rest at `y=3.250` on the lane instead of
  `y=0.750`, so the player stood on top of the wall and dropped 2.5 m stepping
  off it. Moved into the gap between MID and TOP; every probe point now rests at
  `0.750` and the lane has a `0.000` vertical step from end to end.
- **The friendly MID tower stood inside the chase camera.** Spawn is `z=6`,
  `CameraPivot/Camera3D` trails 4.5 units to `z≈10.5`, and the Cybernex MID
  tower sat at `z=12` with a 3.2 m translucent column — it filled the view and
  hid the player on load. Friendly towers moved back to `z=16..18`.
- **F3 was still unreadable.** The play-mode consolidation was not enough:
  `GameHUD`, the legacy `TestArena` `HUD/Root/*` labels and the director's
  `ScoreLine` all wrote the same two corners. `GameHUD` now owns every stat
  readout, the debug left column has one fixed stacked layout, and the pad radar
  moved above the vitals block. `LaneHUD` is anchored where it is created — the
  one-time styling pass ran from `_ready`, before `_finish_clash_layout` had
  built the label, so its layout never applied.

Method note: when a visual report and a code reading disagree, measure. A
headless probe that ray-casts the floor and drops a capsule at known points
settled this in one run, where two observers had given opposite answers.

---

## 2. Deliberately not changed

- `PlanetBody._update_pads` still only hides the pads root when leaving the
  streaming radius; there is no teardown counterpart, so pads/GLB/clusters
  accumulate per visited planet. Needs a real unload pass with `_pads_built`,
  `_glb_loaded` and per-pad meta reset — larger than this audit's blast radius.
- `_toggle_siege` silently rewrites `_role` when `allows_siege` is false, and
  `InteriorDirector._begin` can orphan a pocket when `host` is null. Both are
  unreachable in the current build (`make_scout` / `make_hauler` are never
  called; `_open_space` is always set).
- `PadBaseController.harvested` / `claimed`, `Extractor.contribution_gained` and
  `WarScore.influence_emitted` still have no listeners. They are correct
  signals with no consumer yet, not defects.
- `_harvest_vfx`, `OpenSpace._spawn_asteroid_belt` and `_schedule_surface_settle`
  remain defined and uncalled — content hooks, not logic errors.

---

## 3. Standing invariants this audit re-established

1. Knowledge, Contribution and Biomass are **soft only**. No code path converts
   them into damage, HP, cooldown or claim strength.
2. Nothing damages its own faction, and nothing damages itself.
3. Infection is hard-capped at 5 and now has a real, bounded effect.
4. There is no permadeath: both player controllers and the ship recover.
5. Arena influence on the persistent map is capped, temporary and decaying.
6. Claims require presence. One key press is one pulse.
7. Every HUD element has exactly one writer.
