# Phase 0 playtest stitch (2026-08-14)

Working testing gate for the current prototype (not a closed Phase 0).
Smoke: `scripts/playtest_headless_smoke.sh` → OS_ERR=0 · TA_ERR=0 · MECH_CODE=0. No DMG.

## Play
- Menu → Open Space or Aexion Clash
- GUI: `scripts/run_godot_playtest.sh` (gl_compatibility on software GL)
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
