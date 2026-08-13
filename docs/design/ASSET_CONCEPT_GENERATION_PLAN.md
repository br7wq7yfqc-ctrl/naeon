# NAEON — Asset Concept Generation Plan

**Version:** 0.1  
**Date:** 2026-08-13  
**Pipeline:** Tripo-first · dual-theme · neon + local assets/ · no secrets in git  
**Skill:** naeon-holistic-economical + naeon-sequential-dev  
**Constraint:** Concept art feeds 3D (Tripo/Blender), not final production meshes in git

---

## 1. Delivery format per object

| Deliverable | Spec |
|-------------|------|
| **Cinematic** | 1 key art, landscape or portrait, dark-neon, readable silhouette |
| **Ortho sheet** | Single image: front / side / back / top (or 3⁄4) on neutral grid — modeler reference |
| **Anim / scene clip** | 2–6 s loop or beat (idle, walk, undock, claim flip) — optional per batch |

**Dual theme:** Cybernex = cyan/white/soft green + living architecture · gROT = crimson/purple/spore + industrial biomass.

---

## 2. Priority batches (sequential)

### Batch 1 — VS critical (generate first)

| ID | Object | Type |
|----|--------|------|
| `CHAR_AEGIS` | Aegis Walker (canine CX) | Character |
| `CHAR_GRAFT` | Graft Hound (lurcher gROT) | Character |
| `CHAR_SERA` | Sera Venn (noo-person) | Character |
| `LOC_ARK_VAULT` | NEX Vault Crown exterior | Location |
| `LOC_ROT_SPIRE` | Spire of One Voice exterior | Location |
| `PROP_PILLAR` | Contested claim pillar (both themes) | Prop |
| `SHIP_STARTER` | Starter hull (CX lattice / gROT spore variants) | Ship |
| `WPN_PULSE_T0` | T0 Pulse rifle | Weapon |
| `INT_TESTARENA` | TestArena interior shell | Interior |

### Batch 2 — Forms + hubs

| ID | Object |
|----|--------|
| `CHAR_HELIX` | Helix Ord (avian Warden) |
| `CHAR_THROAT` | Third Throat |
| `CHAR_KILN` | Kiln-Nine |
| `FORM_FELINE` | CX feline scout chassis |
| `FORM_AVIAN` | CX avian |
| `LOC_ARK_RING` | Ring of Quiet Lights |
| `LOC_ROT_KILNS` | Vein Kilns |
| `INT_NEX_HAB` | Cybernex habitat interior |
| `INT_SPIRE_HALL` | gROT ritual hall |

### Batch 3 — Space + modules

| ID | Object |
|----|--------|
| `SHIP_T1_FIGHTER` | T1 fighter both themes |
| `SHIP_HAULER` | Logistics hauler |
| `MOD_THRUSTER_T0` | Propulsion module |
| `MOD_SHIELD_CX` | Shield lattice |
| `MOD_SHIELD_GR` | Spore ward |
| `PAD_DOCK` | Dock / Transition pad |
| `LOC_HELIOS` | Dawn Scaffold |
| `LOC_TWIN_MOON` | Twin Moon A Contested |

### Batch 4 — Economy + social + remaining sites

Gear T1 body, extractor, storage, constructor beacon, Mirror Spindle, Echo Memory Well, Forge Anvil, fleet LOD icons, décor props.

### Batch 5+ — Full catalog expansion

All SITE_PIN locations cinematic; remaining form families; T2–T3 hero ships; MOBA arena skin; seasonal VFX boards.

---

## 3. Per-object checklist

```text
[ ] Cinematic prompt locked (faction theme, no gore fetish, readable)
[ ] Ortho 4-view prompt locked (T-pose or neutral, scale markers)
[ ] Generated + reviewed silhouette
[ ] Optional 2–6s anim (idle / interaction)
[ ] Logged in ASSET_GEN_LOG.md (date, batch, paths)
[ ] Hand to Tripo/Blender only after ortho approved
```

---

## 4. Prompt style anchors

**Cybernex:** dark chrome, cyan edge light, biotech gardens, Venus-Project calm tech, anthropomorphic cyborg animals, clean panels.

**gROT:** ash industrial, spore veins, asymmetric morphs, red-purple bioluminescence, dense machinery, hierarchical ornament.

**Ortho:** pure white or dark grid background, orthographic camera, no dramatic lighting, equal scale, labels Front Side Back Top.

**Avoid:** real-world trademarks, excessive gore, P2W glow language, illegible clutter.

---

## 5. Volume reality

Full universe ≠ one session. **Batch 1** is mandatory before parallel Tripo. Subsequent batches on command «дальше / batch N».

Videos: short loops only for hero objects in each batch (not every prop).

---

## 6. Status

| Batch | Status |
|-------|--------|
| 1 VS critical | **In generation** |
| 2–5 | Queued |

---

*Concept generation authority; production meshes stay out of git.*
