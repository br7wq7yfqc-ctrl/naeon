# NAEON — Site Pin ID Catalog (enum)

**Version:** 0.1  
**Authority for:** QuestResource.site_pin_ids, TransitionContext.site_pin_id, map markers  
**Narrative detail:** LEGENDARY_SITES.md  
**Constraint:** IDs stable; renaming requires memory entry

---

## Canonical IDs

| ID | System | Display name |
|----|--------|----------------|
| `SITE_ARK_VAULT_CROWN` | ARK | NEX Vault Crown |
| `SITE_ARK_RING` | ARK | Ring of Quiet Lights |
| `SITE_ROT_SPIRE` | ROT-Prime | The Spire of One Voice |
| `SITE_ROT_KILNS` | ROT-Prime | Vein Kilns |
| `SITE_SHATTERED_TWIN_MOON_A` | Shattered Corridor | Twin Moon A |
| `SITE_SHATTERED_HAULERS_TEETH` | Shattered Corridor | Hauler’s Teeth |
| `SITE_HELIOS_DAWN_SCAFFOLD` | Helios Reach | Dawn Scaffold |
| `SITE_HELIOS_SOLAR_BLIND` | Helios Reach | Solar Blind |
| `SITE_VEIL_FIRST_BLEED` | Veil Reach | First Bleed Scar |
| `SITE_VEIL_UNINDEXED_ARCHIVE` | Veil Reach | Unindexed Archive |
| `SITE_MIRROR_GREY_SPINDLE` | Mirror Expanse | Grey Mediator Spindle |
| `SITE_MIRROR_SILENT_CUSTOMS` | Mirror Expanse | Silent Customs |
| `SITE_FORGE_ANVIL` | Forge Depths | Anvil of Claims |
| `SITE_FORGE_SLAG_CHOIR` | Forge Depths | Slag Choir |
| `SITE_ECHO_MEMORY_WELL` | Echo Ruins | Lattice Memory Well |
| `SITE_ECHO_GHOST_SWITCHYARD` | Echo Ruins | Ghost Switchyard |

---

## Training / VS-only pins (not legendary)

| ID | Use |
|----|-----|
| `SITE_TEST_ARENA_PILLAR` | TestArena Contested pillar |
| `SITE_SPACE_TEST_PAD` | SpaceTest dock pad |
| `SITE_TRAINING_CONTESTED_CX` | CX Act III training Contested |
| `SITE_TRAINING_CONTESTED_GR` | gROT Act III training Contested |

---

## Schema example

```json
{
  "id": "SITE_ARK_RING",
  "system": "ARK",
  "display_name": "Ring of Quiet Lights",
  "ownership_sensitive": true,
  "codex_key": "codex.site.ark_ring"
}
```

---

## Rules

- Quest docs and code must use these strings exactly.
- New sites → add row here + LEGENDARY_SITES + memory.
- Ownership presentation changes theme; ID does not change.

---

*Stable site_pin enum.*
