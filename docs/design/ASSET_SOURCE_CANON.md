# NAEON — Asset source canon (anchor)

**Authority for “where a mesh may come from.”** Version 1.0, 2026-08-16.  
Pipeline how-to: `docs/ASSET_PIPELINE.md`.  
Authored world vs unnamed fill: `docs/design/WORLD_FILL.md` (parallel PR; if absent on `main`, this file still holds).

Pillars: no P2W · Knowledge soft · Infection max 5 · story ≠ power · Godot 4.3 · взрослый hard-sci-fi.

| Kind | Source | Storage | Git |
|------|--------|---------|-----|
| **Unique** — фракционные герои, dual-theme CX/GR, `site_pin`, locked catalog | **Tripo only** (one gen → Blender LOD + faction kit) | `s3://neon/generations/` + manifest | never the mesh |
| **Generic** — грунт, скалы, флора, HDRI, unnamed scatter | **CC0** (Poly Haven, AmbientCG) | `s3://neon` + manifest row | never |
| **Paid scan** — surfaces / plants / rock libraries | **ScansLibrary** (royalty-free, not OSS) | `s3://neon` + **notice** in ship | never |
| **Unclear licence** | **Отказ** | — | — |

Hard rules:

- Максимум готового из сети. Tripo — только уникальное.
- Готовый меш **не** становится `SITE_*` и **не** даёт power.
- Неясная лицензия = отказ. Не «пока положим, разберёмся».
- `assets/` и `generations/` не в git. Секреты не коммитить. S3 Index не патчить из этого якоря.
- SPDX репо оставить `null`, пока в пайплайне есть ScansLibrary.
