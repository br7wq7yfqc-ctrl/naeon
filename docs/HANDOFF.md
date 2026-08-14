# NAEON — Unified Handoff

**Date:** 2026-08-14
**Skill:** `naeon-holistic-economical` **v2.0**
**Repo:** https://github.com/br7wq7yfqc-ctrl/naeon

## Terrain dance fix (local)

SurfaceDetail / TerrainEdit / Flora **followed the player** on a ring and rebuilt basis from observer each snap → continuous "swimming". LOD sphere mesh swaps also morphing.

### Fix
- Planet **lat/lon cell grid** anchors (stable across visits)
- Stable tangent basis (UP/RIGHT ref, no pole flips)
- LOD hysteresis ~0.5s before mesh swap
- No surface emission shimmer

Updated: 2026-08-07T23:03:47.555592+00:00

## Surface continuum controls (marathon 2026-08-08T00:43:50.054573+00:00)
- G/B terrain raise/lower · U undo · budget soft-cap
- C claim pad · V pad intel scan / cave crystal scan
- F cave enter/exit · FOV blends inside
- Cave floor cannot be dug; sea floor clamp

## Design status — gaps closed this pass

| Artifact | Status |
|----------|--------|
| Campaign Act I–VI + premium | Done |
| SITE_PIN_CATALOG + LEGENDARY_SITES IDs | Done |
| CONSTRUCTOR_TEMPLATES | **Done** |
| SIDE_QUEST_TEMPLATES | **Done** |
| EDU_MODULE_LIBRARY | **Done** |
| HANDOFFS briefs v2.0 | **Done** |
| Rules 00–26 | Done |

---

## Implementation queue (code / ops)

| Priority | Owner | Task |
|----------|--------|------|
| **P0** | A | Infection 5; Ability 04/16; perf smoke |
| **P0** | B | TransitionContext S1 + site_pin |
| **P0** | All | ~60 FPS; no memory climb — even primitive |
| P1 | E | Act I Quest Resources |
| P2 | D | Constructor CT_* + ranks UI 26 |
| Ops | Owner | Tripo; neon |

---

## Non-negotiables

No P2W · soft Knowledge · Infection max 5 · story≠power · Tripo-first · no secrets · Godot 4 Mac+Windows · rules/25 · site_pin catalog · constructor templates only

---

*Design residual gaps for VS closed. Code implements.*
