# NAEON — Act IV Starter Quest Definitions

**Version:** 0.1  
**IDs from:** CAMPAIGN_QUEST_IDS.md  
**Systems:** TransitionContext S1 (rules/18), ship seed (14), modules (22), perf (25)  
**Sites:** SITE_PIN_CATALOG  
**Constraint:** Teach space layer + preserve context; no exclusive permanent ship DPS

---

## Cybernex — Beyond ARK

### CQ-CX-IV-01 — Undock Clearance

| Field | Value |
|-------|--------|
| Giver | `CX_PILOT_LIAISON` |
| Layer | TPS → Space |
| Site pins | `SITE_ARK_RING` pad / `SITE_SPACE_TEST_PAD` in VS |
| Goal | Board starter hull; undock; receive layer label; confirm TransitionContext keeps active_quest_ids |
| Teach | S1 transition, layer HUD, no quest drop |
| Reward | Contribution 80–110 |
| Perf | No hitch beyond S1 budget on undock (rules/25) |

### CQ-CX-IV-02 — Escort to Helios

| Field | Value |
|-------|--------|
| Giver | `CX_PILOT_LIAISON` |
| Goal | Fly marked corridor to Helios approach; survive or evade 1–2 dummy hostiles (capped) |
| Site pins | Route toward `SITE_HELIOS_DAWN_SCAFFOLD` |
| Teach | Flight basics, target brackets |
| Reward | Contribution 100–140 |

### CQ-CX-IV-03 — Helios Handshake

| Field | Value |
|-------|--------|
| Giver | `CX_QUARTERMASTER` |
| Goal | Dock at Helios pad; open hub services; optional small delivery |
| Site pins | `SITE_HELIOS_DAWN_SCAFFOLD` |
| Teach | Dock flow; hub services; Ownership-tinted UI |
| Reward | Contribution 70–100 |

---

## gROT — Spore Yards

### CQ-GR-IV-01 — Yard Infiltration

| Field | Value |
|-------|--------|
| Giver | `GR_SPAWN_WRIGHT` |
| Layer | Space or TPS at yard |
| Site pins | Approach `SITE_ROT_KILNS` |
| Goal | Reach infiltration marker; plant claim pressure (training) |
| Teach | Approach; Ownership push fantasy |
| Reward | Biomass 90–130 |

### CQ-GR-IV-02 — Flip the Bay

| Field | Value |
|-------|--------|
| Giver | `GR_SPAWN_WRIGHT` |
| Goal | Contested progress on training bay to threshold (not free permanent world flip) |
| Site pins | `SITE_TRAINING_CONTESTED_GR` |
| Teach | Contested industrial |
| Reward | Biomass 100–140 |

### CQ-GR-IV-03 — Spawn Rite

| Field | Value |
|-------|--------|
| Giver | `GR_MUTATION_SCRIBE` |
| Goal | Structure-growth interaction / cosmetic rite at controlled node |
| Site pins | `SITE_ROT_KILNS` |
| Teach | Structure fantasy; no unique endgame weapon |
| Reward | Biomass 70–100 + cosmetic |

**Parity:** Shared S1 undock tech available before GR IV if player never flew.

---

## Design rules

- TransitionContext carries quest ids + site_pin + cargo across undock/dock.
- Dummy ships: LOD if many (rules/22 + 25).
- Act IV does not unlock exclusive T3 modules.

---

*Act IV space / yard hooks for Sessions B+E.*
