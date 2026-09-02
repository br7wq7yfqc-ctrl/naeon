# NAEON — Session Contract (owner-locked 2026-08-07, amended)

## Working mode (amended)
- **Not** thin playability hacks first.
- **Iterative mechanics + physics depth**, optimization, no pronounced bugs.
- Scrupulous detail work each pass; systems must feel intentional.
- Agent self-drives against concept + plan + this contract.
- `naeon-holistic-economical skill` = continue autonomously under this mode.

## Release policy
- **NO** Desktop DMG per micro-fix.
- Batch installers only at real milestones.
- Dev: `godot --path godot` + headless; Desktop on owner request / gate.

## Phase 0 honesty
- Still early prototype (~5–10%).
- Exit remains a 10-minute intentional loop — reached by **deepening** systems, not checklist theater.

## Physics / mechanics depth track (active)
1. Ship continuum: atmo density + drag, HOVER altitude hold + pad ground-effect, honest land speed gate (this pass)
2. Surface walker: coyote jump, slope grip, landing absorb (this pass)
3. Rover: slope grip + Space brake + planet gravity (this pass)
4. Chunk streaming (done)
5. Terrain stability (done)
6. Pad claim is occupy-to-hold after land — C/Hack pulses, not auto (this pass)
7. Combat hurtboxes + ability costs from rules/04
8. 10-min loop steps no longer self-complete on toast (this pass)
9. Stations interiors: life-support, doors, ops console, seat gating (this pass)
10. Stall in dense atmo (NAV drops to SCM); interior pocket outside planet mesh (this pass)
11. Pad-guard combat while occupying (this pass)
12. Land-to-harvest loop: in-ring / landed-ship extractor, EXTRACTING HUD, rover CargoHold (this pass)
13. Interior HUD clutter collapsed in pocket; Clash feel (movement, knock, honest lanes, occupy beacons) (this pass)
14. Clash HUD ScoreLine/LaneHUD/banner collapse; ship combat: bolt sweep, hull crit recover, shield hold, turrets track hulls (this pass)
15. Clash lane towers fight; ship afterburn W+Shift; walker variable jump (this pass)
16. **Full code audit**: sphere physics, turret cadence, pad contest deadlock, economy
    regen, pad brake sign, no-P2W / no-friendly-fire enforcement, real Infection,
    downed state, match conclusion, pad streaming teardown (memory climb closed,
    measured flat across two laps). Single record:
    **`docs/PROTOTYPE_TO_PLAYABLE.md`** (this pass)
17. Next: 10-min soak on Mac GPU for the FPS half of rules/25 (this VM is
    llvmpipe, so only the memory half could be signed off here)
18. ST-A: strategy overlay (B) + one habitat on unnamed pad; ship/TPS remain
    (built). G2–G6 still locked.
19. ST-B: extractor visible on unnamed pad + Contribution on HUD after occupy
    harvest. Knowledge is a label only (built).
20. ST-C: spend Contribution/Biomass at pad / NPC bench → one catalog module.
    No cash-shop skip. Knowledge does not cheapen rules/15 (built).
21. ST-D: hangar queue of one module on a catalog carrier hull. Refuse if
    mass/power exceeded. Not a mobile SITE_*. Interiors later (built).
22. ST-E: player-owned orbital cluster of two catalog modules (dock +
    habitat) on Nex-Prime orbit. Not a city. Not SITE_*. Not a second
    system. P0Slice.ORBITAL_STATIONS stays off (built).
23. ST-F: CX↔GR owner swap on one occupied unnamed pad. Visual theme +
    services list change; harvest / print / hangar numbers stay. Not a
    second SITE_*. Not arena-flip (built).
24. ST-G: factory in the existing player orbital cluster. Bench (c)
    spends Contribution/Biomass → one catalog module. Without factory,
    (c) refuses. No cash-shop skip. Knowledge does not cheapen rules/15.
    ST-E stays dock+habitat. ORBITAL_STATIONS stays off (built).
25. Q-A: Contract Board on the IN-B station ops console. One generated
    occupy / harvest / deliver-crate template on the same ARK body.
    Completing grants a SoftKnowledge rank/label only. Harvest / print /
    hangar numbers stay. No cash-shop skip, pay-to-complete, or
    Knowledge-gated exclusive weapons/modules (built).
26. Q-B: one alliance-shared occupy/logistics contract on the same
    unnamed pad / ARK body. Visible to the two NP-E NPCs (same id).
    Completing grants a SoftKnowledge alliance intel label only.
    Harvest / print / hangar / Q-A numbers stay. No pay-to-complete,
    pay-to-rank, or Knowledge-gated exclusive modules (this pass).
27. MC-A: one extra crew seat on the existing player ship pocket.
    F boards crew; I returns to the same ship_int. Pilot F/I unchanged.
    HUD CREW n/2 is a label only — Knowledge does not change thrust /
    DPS / yield. Host authority. Optional SoftNet visual puppet.
    No second hull. No passenger combat. No SITE_* (this pass).
28. MC-B: that crew seat is named gunner (SoftKnowledge / HUD GUNNER).
    HUD CREW n/2 plus role. Knowledge does not change Pulse / Hack /
    thrust / DPS / yield. F/I role stays crew. Host authority.
    No second hull. Not Clash. No SITE_* (this pass).
29. ST-J: one hangar stub on an occupied unnamed pad via BaseBuilder.
    Not ST-D carrier hangar. Hatch/LAND stay on the pad (same
    OpenSpace, not MainMenu). Overlay B stays. ST-A/B/H/I stay.
    Knowledge labels only. No rover. No SITE_* (this pass).
30. MC-C: one extra crew seat on the existing player ship pocket
    (third seat). station_role engineer is SoftKnowledge / HUD ENGINEER.
    HUD CREW n/3. F boards crew; I returns to the same ship_int.
    Pilot F/I unchanged. MC-A gunner seat stays. Host authority.
    Knowledge does not change thrust / DPS / yield / Pulse / Hack.
    No second hull. Not Clash. No SITE_* (this pass).
33. MC-D: one extra crew seat on the existing player ship pocket
    (fourth seat). station_role scanner is SoftKnowledge / HUD SCANNER.
    HUD CREW n/4. F boards crew; I returns to the same ship_int.
    Pilot F/I unchanged. MC-A gunner + MC-C engineer stay. Host authority.
    Knowledge does not change thrust / DPS / yield / Pulse / Hack.
    No second hull. Not Clash. No SITE_* (this pass).
31. KR-A: Knowledge Rank 0–4 from lifetime mastery (AllianceRanks family).
    SoftKnowledge / HUD KNOWLEDGE / KNOWLEDGE RANK + rank number.
    BR-A Biomass Rank stays. Cybernex stays CONTRIB. Rank does not
    change harvest / Pulse / Hack / print / exclusive modules.
    Infection cap 5. No P2W. No SITE_* (this pass).
32. CR-A: Contribution Rank 0–4 from lifetime Contribution wallet
    (AllianceRanks family). SoftKnowledge / HUD CONTRIB / CONTRIBUTION
    + rank number. BR-A Biomass Rank stays (gROT). Rank does not
    change harvest / Pulse / Hack / print / exclusive modules.
    Infection cap 5. No P2W. No SITE_* (this pass).
36. AR-H: one door on an occupied unnamed pad into Clash TestArena.
    F at ClashDoor. Not a city-map. Not G2. G5 cluster stays closed.
    Headless does not change_scene. AR-A…G stay. No leftover 5v5 soak.
    No SITE_* (this pass).

## Tripo
- Balance check when generating; code-first when zero.

Updated: 2026-08-07T23:18:08.396968+00:00


## Approved generations (bucket)

- Store approved design renders and orthogonal Tripo schemes in `s3://neon/generations/`.
- Keep `s3://neon/generations/catalog.json` current on every new approved file.
- Skill: `naeon-sequential-dev`.
