---
name: naeon-asset-design
description: Universal NAEON visual design + canon lock. Trigger — any concept, ortho, cinematic, ship, vehicle, weapon, module, armor, drone, character, environment. After every user approval, update neon bucket + repo index. Only locked sketches enter catalog/bucket/repo.
version: 1.1
---

# NAEON Asset Design

Applies to **every** NAEON object. Companion: `naeon-ship-design` (hull/engine/turret seating only).

## 1. Design Lock

Cinematic and 4-view ortho are **the same object**. Zero redesign between views.

- Same silhouette, panel count, engine count, turret count, hangar placement.
- Ortho = Front / Side / Back / Top, equal scale, neutral grid, no drama.
- If they diverge: remake the **non-canon** view. Never rewrite an approved view.

## 2. Factions

**Cybernex:** brushed steel-grey dominant. Thin cyan accents only (edges, optics, lattice). Flat, elongated, modular, bird-like on multicrew. Not a barrel. Not a brick. Not a city. Atmospheric-capable capitals.

**gROT:** black industrial dominant. Structured red cyber-biomass **20–35%** coverage — engineered tissue / canals on a hard chassis. Asymmetric. Not slime, not a monster, not a solid biomass brick. Flat, not a brick.

**Capture:** owner faction restyles the same hull language (CX planar / GR bio-integrated). No unique permanent DPS from paint.

## 3. Generation pair

Every object ships as:

1. Cinematic key art
2. Ortho 4-view for Tripo

Both must match. Show both. Do not advance until the user locks.

## 4. Index + bucket — after EVERY approval (mandatory)

On user words: `утверждено` / `согласовано` / `фиксируем` / `канон` / equivalent:

1. **Status = locked.** Drafts, seating tests, superseded takes do **not** enter.
2. **Bucket (neon)** — copy only the locked file(s):

   `s3://neon/generations/canon/{class}/{id}/master.jpg`

   Endpoint: `https://storage.yandexcloud.net`. Auth via env / local profile. **Never write keys into the skill, repo, or catalog.**

3. **Index (same turn, both places):**
   - Repo: `docs/design/ASSET_CATALOG.md` + `docs/design/approved_sketches.json`
   - Bucket: `generations/ASSET_CATALOG.md` + `generations/catalog.json`

   Index rows = **locked only**. No in-review, no shorts dump, no `rendered/` archive.

4. **Repo for further work:** the catalog row (id, faction, view, class, label, bucket key, grok URL). **Do not commit image binaries** (see `docs/ASSETS_STORAGE.md`). Images live in neon.

5. **Plan:** update `docs/design/ASSET_CONCEPT_GENERATION_PLAN.md` status in the same turn.

If the user rejects: mark superseded, do **not** copy to `canon/`, do **not** add to the approved index.

Raw dumps (`generations/imagine_images/`, `generations/rendered/`) are archive only. Never treat them as the catalog.

## 5. Propulsion seating (ships)

Proud on a **flat transom**. Plasma / exhaust into **open space**. **No niche, no tunnel, no shroud.** Main + RCS both shown. CX = hexagonal quantum lattice + RCS pucks. gROT = contractile nozzle + tendril RCS.

## 6. Banned

Cartoon / cute / anime. Brick capitals. Space-cities. Barrel Cybernex. Solid-biomass gROT. Modern-Earth guns. Cells on a muzzle. Floating unattached weapons. Ortho that does not match cinematic.

## 7. Grok URL

```
https://assets.grok.com/users/77c65418-d257-47c3-8504-4540b6e0a754/generated/{UUID}/image.jpg
```
