# Phase 0 playtest stitch (2026-08-14)

Working testing gate for the current prototype (not a closed Phase 0).
Smoke: `scripts/playtest_headless_smoke.sh` → OS_ERR=0 · TA_ERR=0 · MECH_CODE=0. No DMG.
OS-H ritual (headless steps, not FPS): `--playtest-ritual` or the mechanics gate. F5 loop: `docs/design/OPEN_SPACE_SC_BENCHMARK.md` § OS-H.

## Play
- Menu → Open Space or Aexion Clash
- GUI: `scripts/run_godot_playtest.sh` (gl_compatibility on software GL)
- OS-H F5: open `OpenSpace.tscn` → F5 → hold S (no pitch) → E land → F EVA → F board → Space takeoff → above atmo
- 10-min loop: fly/fight → land/lane → occupy/claim → harvest Contribution/Biomass

## Canon plates
Locked IDs: `godot/resources/canon_plates.json` (mirror of `docs/design/approved_sketches.json`).
Renders stay in `s3://neon/generations/canon/{class}/{id}/master.jpg` (not git).
If the local `generations/` tree or `user://canon_cache/{id}.jpg` exists, boards show the JPG; otherwise identity cards (faction / class / UUID).
Public GET on the bucket still needs `storage.admin` on SA `neon-access`.

## This pass
1. Arena runner + turret bolts: SoftScanCache enemies (no per-frame `get_nodes_in_group`)
2. CombatJuice floating numbers from a Label pool
3. AbilitySystem actually activates (was returning before `activate`)
4. Ability costs/CDs from rules/04; Firewall cleanses all 5 stacks
5. Hurtbox center/radius on dummy / player / turret
6. LayerContext.site_pin_id on Space + Arena + pad claim
7. PadAmbientLife / rover chassis quotes restored (parse blockers)
8. Infection HUD always 5 pips
9. Procedural Cybernex/gROT hero + dummy silhouettes when GLB missing (code-first, dual-theme)
10. Compact play HUD: HP/EN bars, ability chips, Infection 5 pips; F3 debug dump
11. Pulse bolts as oriented streaks; dummy death collapse (not instant hide)
12. Pad claim pylon (base/shaft/crown); ship cruise nacelles; OpenSpace HUD one-liner (F3 dump)
13. Clash arena perimeter + nexus halo (less greybox)
14. Honest land gate (no fake-land / auto-claim / secret brake); C claims after touchdown
15. HOVER altitude hold; NAV locked in dense atmosphere
16. 10-min loop: harvest-only economy_tick; objectives do not self-complete
17. Surface walker coyote/slope/landing; rover grip + Space brake
18. Station/ship interiors: honest atmo/life-support, sliding doors, E console, F seat only at ship seat
19. Pad contest: occupy-to-hold meter, decay on leave, turret guard, no harvest while contested, Hack/C pulses
20. HOVER ground-effect + pad-aware hold altitude
21. Interior pocket at y=9200 (was inside Nex-Prime r=1400); WorldRoot hidden; walker reparented so TPS camera stays visible
22. Atmospheric stall (vacuum=0, HOVER=0); NAV drops to SCM; HUD STALL line
23. Headless `--playtest-mechanics` gate in `scripts/playtest_headless_smoke.sh` (`timeout`, not `--quit-after` frames)
24. Interior HUD uses POCKET, not leftover ship AGL; occupy presence moves the contest meter
25. Pad contest guard actually fights: headless hitscan, pad_up aim, stays dead until 8s respawn; walker Pulse uses CamPivot
26. Harvest only while owner (or landed owning ship) is in the ring; EXTRACTING HUD line with rate + reserves
27. Seat→pilot no longer crashes HUD on a freed walker; headless playtest exits after PASS (dummy renderer hang)
28. Interior doors drop collision when the slab is open; cockpit E works when standing on the console
29. EVA tether warns at 80m and reels toward the ship past 120m (no death); HUD shows tether meters
30. Surface walker Nex-Firewall cleanses Infection (cap 5); pad V `soft_scan` is callable intel
31. Station recycler E vents POWER IDLE then restores POWER BUS; leftover console cooldown no longer blocks the next pocket
32. Scout hulls keep a CargoHold (no belly ramp); rover deploys on a landed pad and stores as a vehicle entry
33. Interior pocket HUD: GameHUD keeps HP/EN, infection, abilities, compact kind + I/F/E + life-support; radar/pads/CONTRIB/LAYER/briefing hidden; OpenSpace occupy one-liner off unless F3
34. Clash walker: planar accel/decel (not xz snap), coyote + jump buffer, 0.7s downed return to nexus spawn, ClashMatchDirector deaths
35. Pulse/dummy knock: CombatHits planar knock; dummy stagger skips AI so knock holds; lane holds fire after 0.22s windup
36. Clash lanes: K/D and pressure sync from AexionClash (0..100); random LaneBar drift removed
37. Rot Surge is a 4.5m AOE burst + knock (EE.ROT_SURGE / CD_SURGE); Cybernex kit unchanged
38. Interior doors: open hysteresis 0.55s, faster slide, emission + play_door; panels/lights follow recycler/atmo
39. Clash beacons start Neutral; C/Hack occupy-to-hold (1.75, decays on leave); full claim = objective + lane pressure
40. Extractor harvest only while owned by the player faction; ship bolts use ProjectilePool
41. Clash HUD drops SessionObjectives briefing / LAYER chip (F3 still dumps)
42. Mac 10-min soak still needs owner GPU (this VM is llvmpipe)
43. Cave crystal is a named `Crystal` node; V scan only inside the pocket; prompt at the deposit
44. Rover mouse look (yaw + cam pitch) while boarded
45. Clash HUD: MatchBanner legend ~4s then hide; ScoreLine `K D · OBJ · ECO`; LaneHUD lane+pressure only; GameHUD econ hidden (F3 dump)
46. GUI bolts sweep `CombatHits.apply_shot` along the step (no tunnel at ship speeds); shooter excluded
47. CombatHits considers `ship` hurtboxes; pad turrets track hulls; no planar knock on a landed ship
48. Hull critical: recover 35% HP, thrust cut 1.8s, shield hold 2.4s after hit, HP chrome shows hull+shields

49. Rover drive stays in `_physics_process`; mouse look stays in `_unhandled_input` (delta parse)
50. Clash lane towers are live Turrets (faction, 160 HP, collision); death = +28 soft pressure, not a planet flip
51. Ship afterburn: W+Shift spends 16 EN/s, thrust×1.55, speed×1.18; hull-crit and landed deny; Shift without W still descends
52. Walker + Clash jump: release Space while rising cuts upward speed (variable height)

## Audit pass 2026-08-15 (full code audit)
53. Arena Barrier uses a wall-sized collision shape (was the 60x1x60 floor shape — invisible slab, player spawned above the lanes)
54. `get_floor_angle(_up)` on walker + rover; sphere frames parallel-transport a tangent reference (no 90-degree snap near world +/-Z)
55. Turret cooldown drains the gated AI interval, so fire_rate is honest and FPS-independent; dead turrets/dummies leave the target groups
56. Pad contest holds transition 1.0 (a partial write flipped status to owned and killed decay); reserves regenerate while idle
57. One press = one claim pulse via `claim_pulse_from`; the ship must be landed; harvest credits the owning faction
58. `approach_assist` brakes on approach, not departure, and scales with delta
59. No-P2W: Knowledge no longer multiplies ability damage; War Score cap persists to user://; arena influence is capped + decaying
60. No friendly fire: hack, dummy fire and tower kills all check faction at the receiver
61. Infection amplifies gROT damage via `take_damage(amount, source_faction)`; Firewall decays and mitigates on the walker
62. Walker has a real downed window and `is_downed()`, so attackers disengage; EVA has a fuel budget and keeps planet gravity
63. Ship: HOVER hold only inside a gravity well, commanded-lift-only strip, launch stays in HOVER, one hardpoint per module type, recovery runs with no pilot
64. Clash: match_ended shows a result panel (Enter rematches), kills come from AexionClash, minimap orientation fixed, lane refill counts the living
65. Perf: shared arena meshes/materials, 10 Hz ownership visuals, one-time HUD styling, preloaded per-shot scripts, bolt pool counter reset on scene change
66. Arena Barrier moved out of the MID lane (it was a 2.5m wall lying along the lane that the player could stand on and fall off — the real "invisible ledge")
67. Friendly Clash towers moved behind the spawn camera (the MID tower at z=12 sat inside the chase camera and hid the player)
68. F3 overlay: GameHUD owns every stat readout; legacy TestArena labels off; the debug left column has a fixed stacked layout; pad radar clear of the vitals block
69. Match result panel is compact and top-centre so the fight stays visible

## Continuation pass 2026-08-15 (hardening to playable)
70. Pad streaming really unloads past 1.35x the build radius (was hide-only); measured flat at 502 nodes across two laps of all three planets, no planet left built
71. `Pads` joins the parked-node list, so far controllers stop polling input and scanning groups
72. Knock is built in the target ground plane (`up_direction`), not world XZ+Y — hits no longer shove a walker sideways on a sphere
73. Surface walker movement/sprint read the InputMap first (rebinding + gamepad now work on the main character)
74. `snap_to_surface` probes from just above the head and only reaches higher on a miss (was +40, which could strand you on a roof)
75. Perf: pooled jump FX, cached ship scan in EVA, ship Label3D written on change, `_recompute_stats` on attach/detach, attitude applied once per tick
76. Harvest VFX called; pad loss announced while you are away; siege denies unsupported hulls; F3 detail counter reads `queue_depth`
77. ENERGY_ECONOMY doc re-synced to the constants (it listed Pulse 6/0.55s against the real 18/5.0s)
78. Land gate is legible: `land_readiness_line()` on the ship HUD says which term still fails (`alt 600→120`, `pad 148m→90m`, `slow 12.3→12`, `LAND READY — E`); the refusal toast names the same term, and gate + readout share one `_land_envelope()`

## Galaxy layer G0 2026-08-15
79. `StarSystemCatalog` owns placement: star at the system origin, bodies on distinct orbits with distinct angles and inclinations (3800 / 7400 / 11800) instead of one hand-typed clump
80. Visible emissive star with corona; each planet takes its light direction from the star it orbits; the shadow light aims along the star-to-observer line
81. Asteroid belt is called for the first time and takes its band from the system layout
82. Gate anchors to ROT-Prime / Helios Reach / Echo Ruins authored but not spawned — a gate prop with no jump is the inert-system trap this branch was removing
83. Per-tier camera far clip sized to contain a system (LOW 22000 -> ULTRA 48000) with near 0.05 -> 0.25: at 8000 the two far bodies (10383 / 15960 from spawn) and every gate anchor were clipped away entirely
84. Star corona shell removed — a constant-alpha additive sphere rendered as a flat grey ring, not a glow; real corona needs rim falloff (manifest polish)
85. Ship module HP: engine/weapon/shield/cargo/extractor integrity scales function; hull stays; pad occupy repair (no cash). `--playtest-mechanics` asserts damaged engine reduces thrust. No power/cool/life buses.
86. Zero-G EVA near ship (not on dirt): no planet gravity, fuel+tether stay, F reboard. Surface walker / OS-H ritual unchanged.
87. Pad fuel is a real SCM/HOVER tank: occupy-to-hold refill (no cash skip); Knowledge labels the pump only. Empty = no afterburn / limited thrust, not an OS-H hard lock. `--playtest-mechanics` asserts occupy→fuel-up.
88. Ship as place: I from seat → pocket → walk a real door/airlock → F seat (or I hatch → EVA). No fake locked doors. `--playtest-mechanics` asserts seat→pocket→seat.
89. Cargo dock on an occupied unnamed pad: land/occupy, transfer one crate pad↔`CargoHold` (ramp if present, no tractor). Knowledge labels the crate only — mass/value stay. `--playtest-mechanics` asserts occupy→one-unit.
90. Pad traffic: one CombatDummy guard + one visiting hull hold on an occupied unnamed pad. Knowledge labels only. `--playtest-mechanics` asserts pad traffic present.
91. OpenSpace play HUD: one left stack (fuel, cargo count, worst module, landed/occupy, EVA/0G). GFX/FPS/OBJECTIVE stay right/center; Clash HUD unchanged. Helper asserted in `--playtest-mechanics` / `--playtest-ritual`.
92. Occupied unnamed pad: live Contribution/Biomass on the OpenSpace HUD stack (ticks with harvest). Knowledge labels yield only. `--playtest-mechanics` asserts occupy→Contribution increased. Not ST-A.
