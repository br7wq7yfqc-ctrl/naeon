# NAEON — Unified Handoff

**Date:** 2026-08-06  
**Design queue (VS phase):** **COMPLETE**  
**Skill:** `naeon-holistic-economical` v1.6  
**Repo:** https://github.com/br7wq7yfqc-ctrl/naeon

---

## Design corpus ready for implementation

| Area | Paths |
|------|--------|
| Pillars / legal | rules/00, 01, legal/* |
| Combat | rules/02, **04 (Infection max 5)**, 16 |
| Ownership / space | rules/03, 14, **18 TransitionContext** |
| Economy / craft | rules/05, 12, 15 |
| Quests / NPC / lore | rules/06–09, CAMPAIGN_QUEST_IDS, QUEST_ACT_I_STARTERS, STAR_SYSTEMS |
| UI / freemium / voice | rules/10, **19**, 17 |
| MOBA influence | rules/13 |
| Schemas (examples) | docs/design/DATA_SCHEMAS_VS.md |
| Skill / memory | HOLISTIC_DEV_SKILL, SHARED_AGENT_MEMORY |

---

## Implementation queue (code / ops — not design blockers)

| Priority | Owner | Task |
|----------|--------|------|
| P0 | Session A | Infection **5** pips; align Ability resources to 04/16; interruptible Hack |
| P0 | Session B | `TransitionContext` round-trip TestArena↔SpaceTest; declare S0/S1 |
| P1 | Session E | Quest Resources CQ-CX-I-01 + CQ-GR-I-01 |
| P1 | Session A/E | Act I tutorial wiring |
| P2 | Session D | Contribution/Biomass ledgers soft caps |
| Ops | Owner | Tripo credits; neon rclone keys |

---

## Non-negotiables

No P2W · soft Knowledge · Infection max 5 · Arena soft caps · freemium labels rules/19 · Tripo-first · no secrets in git · Godot 4 Mac+Windows

---

*Design VS backlog closed. Code implements against rules above.*
