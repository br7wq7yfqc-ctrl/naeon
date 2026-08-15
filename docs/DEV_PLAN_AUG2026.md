# NAEON Dev Plan — Aug 2026

## Current focus: galaxy layer (Phase G)

Authority: `docs/design/GALAXY_LAYER_PLAN.md` · Assets: `docs/design/TRIPO_ASSET_MANIFEST.md`
Full phase breakdown in `DEVELOPMENT_PLAN.md` (Phase G, inserted before Phase 4).

| Sub-phase | State | Gist |
|-----------|-------|------|
| **G0** system layout | **DONE 2026-08-15** | Star at the origin, bodies on distinct orbits (3800 / 7400 / 11800), belt from data, per-body light direction, gate anchors authored |
| **G1** CRUISE | next | In-system superluminal, mass lock near bodies, orbits scale up ~2.8× in the same pass |
| **G2** galaxy data + maps | after G1 | `GalaxyCatalog`, `NavState`, `M` galaxy map, `N` system map, route plotting that names why a leg fails |
| **G3** hyperdrive | after G2 | New module type, six-state jump, fuel, refuel at pads, tow instead of stranding |
| **G4** gates | after G3 | NAEXOS relay rings: open / dormant / infected / contested, traversal streams the target system |
| **G5** arena from the map | after G4 | Clash Beacons in-world, hold-F entry, return to the same beacon, influence on the host system |
| **G6** content | later | Remaining systems, gate networks, interdiction, fuel scooping, map filters |

## Preceding work, complete

**2026-08-15 audit + hardening** — 101 scripts / 10 scenes / 12 autoloads, ~110
confirmed defects, blockers fixed. Single record: `docs/PROTOTYPE_TO_PLAYABLE.md`.
Gate: `OS_ERR=0 · TA_ERR=0 · MM_ERR=0 · MECH_CODE=0 · MECH_ERR=0 · [Playtest] PASS`,
plus an arena floor geometry probe and a two-lap pad streaming leak test.

**Hotfix batch 2026-08-11** — character mesh faces −Z, land gate plus pad assist,
hatch door hidden, interior enter from pilot at 42 m.

## Asset pipeline

Next Tripo batch is **T1** from the manifest: `hypergate_ring`, `hypergate_core`,
`hypergate_pylon`, `hyperdrive_relay` — the hero objects G3 and G4 cannot be
evaluated without. Then **T2**: `scout_hull`, `cockpit_interior_shell`,
`landing_gear_strut`, because the player looks at their own ship more than
anything else and it is still procedural.

Caps stand at 5k credits/week, 20k/month. Every ingest updates
`s3://neon/generations/catalog.json`.

## Standing gates

- No DMG per micro-fix; batch installers at real milestones only.
- ~60 FPS min preset, no monotonic memory climb (rules/25). The memory half is
  measured; the FPS half needs the owner's Mac — this VM is llvmpipe.
- No P2W, soft Knowledge, Infection cap 5, no permadeath.
