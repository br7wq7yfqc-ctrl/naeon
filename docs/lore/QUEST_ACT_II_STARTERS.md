# NAEON — Act II Starter Quest Definitions

**Version:** 0.1  
**IDs from:** CAMPAIGN_QUEST_IDS.md  
**NPCs:** CHARACTER_BIOS_CORE + rules/07  
**Sites:** LEGENDARY_SITES  
**Rewards:** rules/15 bands; no premium power  
**Perf:** objectives must not spawn unbounded actors (rules/25)

---

## Cybernex — Contribution

### CQ-CX-II-01 — Belt Pickup

| Field | Value |
|-------|--------|
| Giver | `CX_QUARTERMASTER` (VO may share Aegis-adjacent duty tone) |
| Layer | TPS → optional short logistics route |
| Site pins | Extract node near **Ring of Quiet Lights** approach (`SITE_ARK_RING`) |
| Goal | Gather 15 `ore_basic` or equivalent from marked nodes |
| Teach | Extract loop, inventory, node Ownership read |
| Reward | Contribution 70–100 |
| Fail | Soft — resources stay in world |

### CQ-CX-II-02 — Ring Delivery

| Field | Value |
|-------|--------|
| Giver | `CX_QUARTERMASTER` |
| Goal | Deliver cargo to allied pad; complete conversion to Contribution |
| Site pins | `SITE_ARK_RING` delivery bay |
| Teach | Delivery risk if Contested; score only on complete delivery (rules/15) |
| Reward | Contribution 80–120 |
| Notes | If player dies in Contested, cargo rules apply — no score |

### CQ-CX-II-03 — Repair Relay

| Field | Value |
|-------|--------|
| Giver | `CX_CIVIC_ENGINEER` / Helix Ord brief optional |
| Goal | Spend score/mats on T1 repair sink or relay prop |
| Site pins | `SITE_ARK_VAULT_CROWN` outer maintenance ring |
| Teach | Upkeep/sink fantasy; Contribution spend |
| Reward | Contribution 60–90 + cosmetic “relay tick” |

---

## gROT — Harvest

### CQ-GR-II-01 — slurry Run

| Field | Value |
|-------|--------|
| Giver | `GR_HARVESTER` (Kiln-Nine VO optional) |
| Layer | TPS |
| Site pins | Approach **Vein Kilns** outer markers (`SITE_ROT_KILNS`) |
| Goal | Collect 15 organics / slurry-equivalent from harvest nodes |
| Teach | Extract for Biomass path |
| Reward | Biomass 70–100 |

### CQ-GR-II-02 — Feed the Vat

| Field | Value |
|-------|--------|
| Giver | `GR_HARVESTER` |
| Goal | Convert cargo at corrupted/ allied vat → Biomass progress |
| Site pins | `SITE_ROT_KILNS` |
| Teach | Conversion completes only at vat; lost cargo = no score |
| Reward | Biomass 80–120 |

### CQ-GR-II-03 — Corrupt the Drip

| Field | Value |
|-------|--------|
| Giver | `GR_SPAWN_WRIGHT` |
| Goal | Apply claim pressure or corruption interaction on a training node (not free permanent flip) |
| Site pins | Contested training pillar in ROT-Prime outer belt |
| Teach | Ownership pressure fantasy; timers visible |
| Reward | Biomass 60–90 |

---

## Design rules

- Act II teaches **economy loop**, not new exclusive weapons.
- Named bios VO optional; giver role_id remains authoritative.
- Cap simultaneous extract props for performance (rules/25).
- TransitionContext carries `active_quest_ids` + optional `site_pin_id`.

---

*Act II hooks for Session E after Act I resources exist.*
