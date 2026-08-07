# NAEON — Act V Starter Quest Definitions

**Version:** 0.1  
**IDs from:** CAMPAIGN_QUEST_IDS.md  
**Systems:** Soft Knowledge (rules/08), educational modules, Echo Ruins  
**Sites:** SITE_PIN_CATALOG  
**Constraint:** Knowledge = UI/QoL/lore only — **never** damage, HP, CDR, claim strength, yield

---

## Cybernex — Mirror and Memory

### CQ-CX-V-01 — Archive Access

| Field | Value |
|-------|--------|
| Giver | `CX_ARCHIVIST` (Sera Venn VO preferred) |
| Layer | TPS / hub |
| Site pins | `SITE_ECHO_MEMORY_WELL` or ARK archive annex |
| Goal | Enter archive; complete access protocol; unlock first codex cluster |
| Teach | Educational node UI; optional overlay toggle |
| Reward | Contribution 60–90 + History subject soft rank tick |

### CQ-CX-V-02 — Schism Primer

| Field | Value |
|-------|--------|
| Giver | `CX_ARCHIVIST` |
| Goal | Read three Schism timeline entries; answer soft quiz (no combat fail) |
| Site pins | `SITE_ECHO_MEMORY_WELL` |
| Teach | SCHISM_TIMELINE beats; ideology without power |
| Reward | Contribution 70–100 + History soft rank |

### CQ-CX-V-03 — Soft Insight Drill

| Field | Value |
|-------|--------|
| Giver | `CX_ARCHIVIST` |
| Goal | Complete one educational puzzle module (math/logistics/cybernetics soft) |
| Site pins | Learning hall / Prompt Studio entry (gated labels rules/19) |
| Teach | Knowledge flags → optional UI only; disable path exists |
| Reward | Contribution 50–80 + subject soft rank (rules/08 table) |

---

## gROT — Ash March (Act V IDs: space/TPS mix + logistics)

Campaign map Act V gROT is Ash March (raid/logistics). Knowledge parity via Mutation Scribe optional.

### CQ-GR-V-01 — Lane Raid

| Field | Value |
|-------|--------|
| Giver | `GR_SHIP_BUTCHER` |
| Layer | Space / TPS mix |
| Site pins | Border toward `SITE_SHATTERED_HAULERS_TEETH` |
| Goal | Complete short raid marker; capped dummy opposition |
| Teach | Mixed layer pressure |
| Reward | Biomass 90–130 |

### CQ-GR-V-02 — Logistics Bleed

| Field | Value |
|-------|--------|
| Giver | `GR_HARVESTER` (Kiln-Nine optional) |
| Goal | Intercept or protect slurry cargo once (risk rules apply) |
| Site pins | Hauler corridor |
| Teach | Cargo risk; no score if lost |
| Reward | Biomass 100–140 |

### CQ-GR-V-03 — Border Howl

| Field | Value |
|-------|--------|
| Giver | `GR_PACK_LEADER` |
| Goal | Clear patrol objective; optional biology hazard recognition soft tip |
| Site pins | Border marker |
| Teach | Pack assault; optional Biology soft UI |
| Reward | Biomass 80–120 |

**gROT Knowledge optional beat:** `GR_MUTATION_SCRIBE` can offer a parallel soft module (biology/history of Vein) — same rules/08 limits, ID `CQ-GR-V-K01` if implemented as side quest.

---

## Design rules

- Educational fail = retry, not combat death mandatory.
- Soft ranks never appear in damage formulas.
- Premium story modules may add codex only (rules/19).

---

*Act V Knowledge / Ash March hooks.*
