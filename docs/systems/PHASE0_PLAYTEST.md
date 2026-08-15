# Phase 0 playtest stitch (2026-08-14)

Working testing gate for the current prototype (not a closed Phase 0).
Smoke: `scripts/playtest_headless_smoke.sh` → OS_ERR=0 · TA_ERR=0. No DMG.

## Play
- Menu → Open Space or Aexion Clash
- GUI: `scripts/run_godot_playtest.sh` (gl_compatibility on software GL)
- 10-min loop: fly/fight → land/lane → C claim → harvest Contribution/Biomass

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
