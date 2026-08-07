# NAEON — VO Barks (Core Cast Seed)

**Version:** 0.1  
**Depends on:** CHARACTER_BIOS_CORE, FACTION_SLANG_AND_VOICE  
**Constraint:** Flavour only — no combat power, no paywalled lines required for quest completion

Short lines for implementation placeholders (EN). Localize later.

---

## Aegis Walker (CX)

| Context | Line |
|---------|------|
| Idle | "Ring still holds." |
| Combat start | "On me — keep it clean." |
| Firewall up | "Lattice steady." |
| Ally down | "Up. We do not leave the waking unguarded." |
| Quest handoff | "Contribution board updated. Move." |

## Sera Venn (CX)

| Context | Line |
|---------|------|
| Idle | "Timestamps do not lie. People do." |
| Quest start | "Read before you run." |
| Archive found | "Another fragment of the Bleed — sealed, not weaponized." |
| Player rush | "Precision is also speed." |

## Helix Ord (CX)

| Context | Line |
|---------|------|
| Idle | "Shift report." |
| Defend order | "Hold the ring." |
| Success | "Protocol satisfied." |
| Failure pressure | "Again. The sleepers do not get a second lattice." |

## Graft Hound (GR)

| Context | Line |
|---------|------|
| Idle | "Still unfinished out there." |
| Infect apply | "Open." |
| Kill | "Feeds the Vein." |
| Quest | "Limits are a cage. Come." |

## The Third Throat (GR)

| Context | Line |
|---------|------|
| Idle | "ROT endures." |
| Broadcast | "Pack truth is spoken." |
| War push | "Expand. Convert." |
| Displeasure | "Unfinished work… including yours." |

## Kiln-Nine (GR)

| Context | Line |
|---------|------|
| Idle | "Tonnage, not poetry." |
| Harvest | "Convert." |
| Logistics | "Ash March quota holds." |
| Graft rivalry | "Sport infection wastes mass." |

---

## Implementation

- Key as `vo.cx.aegis.idle` etc. in localization.
- Optional; text quest continues if VO missing.
- Voice channel playback still gated by rules/17 when player voice is involved — NPC barks may play as SFX/VO budget allows (performance §25: VO pool, no leak on spam).

---

*VO bark seed.*
