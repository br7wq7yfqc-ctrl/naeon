# NAEON — Generated Side-Quest Templates

**Version:** 0.1  
**Depends on:** rules/06, 07, 15, 08, 19, 25  
**IDs:** `SQ-{FACTION|ANY}-{TEMPLATE}-{nn}`  
**Constraint:** Controlled rewards; AI flavour only inside bands

---

## 1. Templates

| Template | Goal pattern | Reward | Layer |
|----------|--------------|--------|-------|
| `SQ_KILL_DUMMIES` | Defeat N training hostiles | Band XP + Contrib/Biomass | TPS |
| `SQ_GATHER` | Gather N items | Band | TPS |
| `SQ_DELIVER` | Deliver cargo to pad | Band; 0 if lost | TPS/Space |
| `SQ_VISIT_PIN` | Reach site_pin | Small band + codex chance | Any |
| `SQ_CLEANSE` | Cleanse Infection props | CX-leaning band | TPS |
| `SQ_STACK_TRAIN` | Apply stacks on pylon | gROT-leaning band | TPS |
| `SQ_SCAN` | Scan objects (utility) | Soft Knowledge tick optional | Space/TPS |
| `SQ_EDU_MODULE` | Complete one edu puzzle | Soft Knowledge only | Hub |

---

## 2. Generation rules

1. Pick template + site_pin from catalog + giver role from rules/07.
2. aiNEX/Prompt Studio fills **title and bark** only; numbers from template.
3. Daily soft cap on generated quest completions (anti-grind) — tune with telemetry.
4. Ownership may enable/disable location-tagged templates.
5. Premium generated variants = cosmetic title chance only, not higher DPS mats.

---

## 3. Perf

Max active side quests per player soft-capped; dummy pools reused (rules/25).

---

## 4. VS

One `SQ_GATHER` + one `SQ_KILL_DUMMIES` wired to TestArena.

---

*Side-quest template authority.*
