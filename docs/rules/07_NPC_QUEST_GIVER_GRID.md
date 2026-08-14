# NAEON — NPC Quest Giver Grid

**Version:** 0.2  
**Depends on:** rules/06 Quest System, lore/CAMPAIGN_QUEST_IDS, rules/09 Schism

NPC roles are **stable IDs** for dialogue, quest assignment, and AI-NPC hooks. Names may localize; IDs do not.

---

## 1. Cybernex roles

| Role ID | Display (EN) | Primary quest types | Typical hubs |
|---------|--------------|---------------------|--------------|
| `CX_WARDEN` | Defense Coordinator / Sentinel-Archer | Defend, Contested, Firewall drills | ARK perimeter, Twin Moon |
| `CX_QUARTERMASTER` | Logistics Director / Supply-Warden | Extract, deliver, Contribution | Docks, extractors |
| `CX_ARCHIVIST` | Knowledge Curator / Scholar-Unit | Educational, lore, soft Knowledge | NEX archive, Learning nodes |
| `CX_PATHFINDER` | Exploration Lead | Survey, scout, space transition intro | Outposts, Helios route |
| `CX_ALLIANCE_BOARD` | Alliance Liaison / Concord Speaker | Alliance intro, constructor briefs | Alliance hub |
| `CX_MEDICAE` | Medicae / Cleanse Specialist | Cleanse, Infection recovery, Firewall | Field clinics |
| `CX_PILOT_LIAISON` | Pilot Liaison | Undock, escort, multi-crew seed | Pads, hangars |
| `CX_NEX_OPERATIVE` | Nex-Operative | Anti-hack, special ops (standard power only) | Restricted decks |

---

## 2. gROT roles

| Role ID | Display (EN) | Primary quest types | Typical hubs |
|---------|--------------|---------------------|--------------|
| `GR_PACK_LEADER` | Swarm Overseer / Flesh-Commander | Assault, raid, hierarchy tests | Forward packs |
| `GR_INFECTION_ADEPT` | Assimilation Broker / Converter | Hack, Infection stacks, vs Firewall | Contested edges |
| `GR_HARVESTER` | Biomass Harvester / Grower-Unit | Slurry, convert, Biomass progress | Vats, fields |
| `GR_VOICE_OF_ROT` | Whisper of ROT / Echo-Priest | Loyalty, story, premium lore | Spire rituals |
| `GR_SPAWN_WRIGHT` | Corruption Engineer / Code-Eater | Ownership push, structure growth | Spore yards |
| `GR_SHIP_BUTCHER` | Lane / void raider | Space-TPS mix, logistics pressure | Ash March routes |
| `GR_MUTATION_SCRIBE` | Mutation Scribe | Cosmetic mutation unlocks, blueprints | Labs |
| `GR_ALLIANCE_SPIRE` | Alliance Spire officer | Alliance ops, Contested climax | Spire |

---

## 3. Assignment rules

- Campaign IDs in `CAMPAIGN_QUEST_IDS.md` reference these role IDs as **givers**.
- Generated side quests pick a role + template from rules/06 — no free-form power rewards.
- AI-NPC dialogue may flavour lines; **rewards and objectives** stay data-driven.
- Both factions need givers for: combat tutorial, extract/convert, Ownership, educational, alliance.

---

## 4. Implementation notes

- Store as Resource/JSON: `role_id`, `faction`, `quest_tags[]`, `hub_tags[]`.
- Voice TTS personality presets may key off role_id (cosmetic).

---

*NPC grid source of truth for Session E and dialogue hooks.*
