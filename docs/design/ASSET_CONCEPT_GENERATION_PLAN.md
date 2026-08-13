# NAEON — Asset Concept Generation Plan

**Version:** 0.4  
**Date:** 2026-08-13  
**Pipeline:** Tripo-first · dual-theme · neon + local assets/ · no secrets in git  
**Skill:** naeon-holistic-economical + naeon-sequential-dev  
**Constraint:** Concept art feeds 3D (Tripo/Blender), not final production meshes in git

---

## 0. Style Lock (mandatory for all batches)

- **Adult hard sci-fi only.** Mature realistic proportions, function-over-form, readable wear and material detail.
- **Forbidden:** cartoon, cute, chibi, anime stylization, soft “mascot” proportions, excessive gore fetish, medieval, pure fantasy organic, wood/bone ritual aesthetics.
- **Cybernex:** dark chrome / white-grey, cyan lattice edge light, living architecture in harmony with nature (Venus Project), clean geometric panels.
- **gROT:** always black + red. Industrial futurism + **structured genetic cyber-biomass** (engineered tissue, spore veins, biotech fusion on hard-surface frames and factory chassis). Mass-production / hive-lab feel. Never pure organic monster or gothic castle.
- **Neutral / Relic:** third aesthetic — weathered grey-gold, non-human geometry, neither cyan nor red dominance.
- **Ortho sheets:** neutral dark or light grid, orthographic, equal scale, Front / Side / Back / Top, minimal labels.

---

## 1. Delivery format per object

| Deliverable | Spec |
|-------------|------|
| **Cinematic** | 1 key art, landscape or portrait, dark-neon, readable silhouette |
| **Ortho sheet** | Single image: front / side / back / top on neutral grid — modeler reference |
| **Anim / scene clip** | 2–6 s loop or beat (idle, walk, undock, fly-through, claim flip) — optional per hero object |

Dual-theme required wherever ownership or faction presence applies.

---

## 2. Priority batches (sequential)

### Batch 1 — VS critical
CHAR_AEGIS, CHAR_GRAFT, CHAR_SERA, LOC_ARK_VAULT, LOC_ROT_SPIRE, PROP_PILLAR (dual), SHIP_STARTER (dual), WPN_PULSE_T0, INT_TESTARENA  
**Status:** largely complete (prior session)

### Batch 2 — Forms + hubs
CHAR_HELIX, CHAR_THROAT, CHAR_KILN, FORM_FELINE, FORM_AVIAN, LOC_ARK_RING, LOC_ROT_KILNS, INT_NEX_HAB, INT_SPIRE_HALL  
**Status:** largely complete

### Batch 3 — Space + modules
SHIP_T1_FIGHTER (dual), SHIP_HAULER, MOD_THRUSTER_T0, MOD_SHIELD_CX / GR, PAD_DOCK, LOC_HELIOS, LOC_TWIN_MOON  
**Status:** largely complete

### Batch 4 — Economy + social + sites
T1 gear, extractor, storage, constructor, Mirror Spindle, Echo Well, Forge Anvil, décor seeds, SITE_PIN set  
**Status:** largely complete

### Batch 5 — MOBA Arena (paused for later refinement)
Hex layout, diagonal river, multi-height labyrinth jungle (CX healthy / GR infected), 3 towers + inhibitors per lane, creep types (melee / ranged / artillery), super-creeps  
**Status:** geometry + style locked v0.3.2; visual polish deferred

### Batch 6–11 — Environments expansion (CLOSED this session)
- **Biomes:** BIO_CX_HARMONY, BIO_GR_INFECTED, BIO_ASH_MARCH, BIO_ARK_NEX, BIO_ICE_OUTER, BIO_OCEAN_REEF
- **Flora:** FLORA_CX_CRYSTAL / GARDEN, FLORA_GR_SPORE / VEIN, FLORA_NEUTRAL
- **Fauna:** FAUNA_CX_SCOUT (mature hard-sci-fi), FAUNA_GR_SWARM / HUNTER, FAUNA_NEUT_DRIFTER, FAUNA_RELIC_ECHO
- **Nebulae:** NEB_CX_LUMEN, NEB_GR_ASH, NEB_HELIOS, NEB_NULL
- **Space:** SPACE_ASTEROID_BELT, SPACE_ASTEROID_HOLLOW, SPACE_RELIC_RING, SPACE_RELIC_OBELISK, SPACE_WRECK_FIELD, SPACE_STATION_NEUTRAL
- **Interiors:** INT_RELIC_CHAMBER, INT_COLONY_CX / GR, INT_SHIP_BRIDGE, INT_SHIP_BAY

### Batch 12 — Active (current)
1. SPACE_RELIC_RING cinematic + short fly-through clip
2. NEB_VEIL (contested border)
3. INT_FACTORY_CX / INT_FACTORY_GR dual
4. INT_VAULT_CROWN + INT_SPIRE (HQ interiors)
5. Surface transport: CX rover + GR crawler
6. Capital ship exteriors dual (CX clean / GR bio-industrial)
7. PROP_DECOR dual (hab furniture + industrial crates)
8. Start T0–T1 weapons/gear dual (pulse, lattice rifle, cyber-blade, shield modules)

### Batch 13+ — Remaining
T2–T3 ships, more form families, seasonal VFX, remaining SITE_PIN polish, full ortho backlog for Tripo hand-off, MOBA arena return.

---

## 3. Per-object checklist

```text
[ ] Cinematic prompt locked (adult hard sci-fi + faction canon)
[ ] Ortho 4-view prompt locked (neutral, scale, no drama)
[ ] Generated + silhouette reviewed
[ ] Optional 2–6s anim for hero objects
[ ] Logged (date, batch, paths)
[ ] Hand to Tripo/Blender only after ortho approved
```

---

## 4. Prompt style anchors (quick reference)

**Cybernex:** dark chrome, cyan edge light, biotech gardens, Venus-Project calm tech, anthropomorphic cyborg animals (mature), clean panels.

**gROT:** black industrial hard-surface + controlled red genetic cyber-biomass (engineered tissue / spore veins on frames), mass-production, hierarchical, red optic/glow accents.

**Relic / Neutral:** weathered grey-gold, non-human geometry, third aesthetic.

**Ortho:** pure grid background, orthographic, equal scale, Front Side Back Top.

**Avoid:** trademarks, excessive gore, P2W language, illegible clutter, cartoon/cute, medieval, pure organic fantasy.

---

## 5. Volume reality

Full universe ≠ one session. Generate on command «дальше / batch N».  
Videos: short loops only for hero objects.  
Heavy assets stay in neon bucket + local assets/; never commit large binaries to git.

---

## 6. Status summary

| Batch | Status |
|-------|--------|
| 1–4 VS + core | Largely complete |
| 5 Arena | Geometry locked, visual polish deferred |
| 6–11 Environments | **Closed** (biomes → interiors) |
| 12 Current | **Active** (relic, factories, transport, capital, weapons start) |
| 13+ | Queued |

---

*Concept generation authority; production meshes stay out of git. Style lock is non-negotiable.*
