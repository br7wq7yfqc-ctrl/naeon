# NAEON — Campaign Quest ID Lists (per act)

**Version:** 0.1  
**Depends on:** `CAMPAIGN_ARCS_SEED.md`, `06_QUEST_SYSTEM.md`, `07_NPC_QUEST_GIVER_GRID.md`  
**Reward rule:** Standard quests use normal Contribution/Biomass bands. Premium epilogues = cosmetics/lore only.

ID format: `CQ-{FACTION}-{ACT}-{NN}`  
NPC roles reference the quest-giver grid.

---

## Cybernex — Awakening of NAEXOS

### Act I — Wake Protocols
| ID | Title (working) | Giver | Systems |
|----|-----------------|-------|---------|
| CQ-CX-I-01 | Perimeter Sweep | CX_ANIMAL_SCOUT | TPS move, basic combat |
| CQ-CX-I-02 | First Cleanse | CX_MEDICAE | Firewall intro, cleanse |
| CQ-CX-I-03 | Infection Signature | CX_WARDEN | Read Infection pips |

### Act II — Contribution
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-CX-II-01 | Belt Pickup | CX_QUARTERMASTER | Extract |
| CQ-CX-II-02 | Ring Delivery | CX_QUARTERMASTER | Deliver → Contribution |
| CQ-CX-II-03 | Repair Relay | CX_CIVIC_ENGINEER | Repair sink |

### Act III — Cracks in the Ring
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-CX-III-01 | Contested Module | CX_WARDEN | Ownership Contested |
| CQ-CX-III-02 | Hold the Lattice | CX_WARDEN | Defend claim |
| CQ-CX-III-03 | After-Action Nex | CX_MEDICAE | Cleanse / Integrity |

### Act IV — Beyond ARK
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-CX-IV-01 | Undock Clearance | CX_PILOT_LIAISON | Space transition |
| CQ-CX-IV-02 | Escort to Helios | CX_PILOT_LIAISON | Escort / flight |
| CQ-CX-IV-03 | Helios Handshake | CX_QUARTERMASTER | Hub services |

### Act V — Mirror and Memory
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-CX-V-01 | Archive Access | CX_ARCHIVIST | Educational node |
| CQ-CX-V-02 | Schism Primer | CX_ARCHIVIST | History subject |
| CQ-CX-V-03 | Soft Insight Drill | CX_ARCHIVIST | Knowledge QoL only |

### Act VI — Line in the Reach
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-CX-VI-01 | Alliance Board | CX_ALLIANCE_BOARD | Alliance intro |
| CQ-CX-VI-02 | Twin Moon Brief | CX_WARDEN | Multi-player objective |
| CQ-CX-VI-03 | Contest the Moon | CX_ALLIANCE_BOARD | Claim contest |

**Premium epilogue:** `CQ-CX-PREM-01` Audience of the Elder — cosmetic/codex only.

---

## gROT — Ascension of the Swarm

### Act I — Pack Brand
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-GR-I-01 | Blood Mark | GR_PACK_LEADER | TPS aggression |
| CQ-GR-I-02 | First Channel | GR_INFECTION_ADEPT | Basic Hack |
| CQ-GR-I-03 | Stack the Prey | GR_INFECTION_ADEPT | Infection stacks |

### Act II — Harvest
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-GR-II-01 | Slurry Run | GR_HARVESTER | Biomass extract |
| CQ-GR-II-02 | Feed the Vat | GR_HARVESTER | Convert → Biomass |
| CQ-GR-II-03 | Corrupt the Drip | GR_SPAWN_WRIGHT | Node corruption |

### Act III — Voice and Vein
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-GR-III-01 | Hierarchy Test | GR_VOICE_OF_ROT | Loyalty beat |
| CQ-GR-III-02 | Break the Lattice | GR_INFECTION_ADEPT | Hack vs Firewall duel |
| CQ-GR-III-03 | Vein Open | GR_PACK_LEADER | Stack pressure |

### Act IV — Spore Yards
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-GR-IV-01 | Yard Infiltration | GR_SPAWN_WRIGHT | Ownership push |
| CQ-GR-IV-02 | Flip the Bay | GR_SPAWN_WRIGHT | Contested flip |
| CQ-GR-IV-03 | Spawn Rite | GR_MUTATION_SCRIBE | Structure growth |

### Act V — Ash March
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-GR-V-01 | Lane Raid | GR_SHIP_BUTCHER | Space/TPS mix |
| CQ-GR-V-02 | Logistics Bleed | GR_HARVESTER | Cargo pressure |
| CQ-GR-V-03 | Border Howl | GR_PACK_LEADER | Patrol assault |

### Act VI — Claim for ROT
| ID | Title | Giver | Systems |
|----|-------|-------|---------|
| CQ-GR-VI-01 | Spire Orders | GR_ALLIANCE_SPIRE | Alliance op |
| CQ-GR-VI-02 | Moon B Pressure | GR_VOICE_OF_ROT | Contested climax |
| CQ-GR-VI-03 | Claim Pulse | GR_ALLIANCE_SPIRE | Hold to flip |

**Premium epilogue:** `CQ-GR-PREM-01` Nearness to ROT — title/cosmetic only.

---

## Implementation notes

- Quest data resources should reference these IDs.
- Acts gate **narrative order**, not permanent combat power exclusivity.
- Generated side quests use templates from `06_QUEST_SYSTEM.md`, not these IDs.

---

*First quest ID map for Session E / campaign implementation.*
