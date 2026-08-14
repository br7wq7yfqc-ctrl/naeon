# NAEON — Alliance Constructor Templates (Seed)

**Version:** 0.1  
**Depends on:** rules/11, 26, 06, 03, 19, 25  
**Constraint:** Templated only — no free-form harassment; daily budget + server caps

---

## 1. Template catalog (VS + early)

| Template ID | Name | Min rank | Objective type | Reward source | Notes |
|-------------|------|----------|----------------|---------------|--------|
| `CT_DELIVER_HUB` | Hub delivery | 2 | Deliver item to allied pad | Alliance pool share + personal Contribution/Biomass band | Logistics |
| `CT_EXTRACT_NODE` | Node extract | 2 | Gather N from marked nodes | Same | Capped node spawns |
| `CT_DEFEND_CLAIM` | Defend claim | 2 | Hold Contested progress | Same | Dummy pressure capped |
| `CT_REPAIR_STRUCTURE` | Repair structure | 2 | Spend mats/score on sink | Same | Sink fantasy |
| `CT_SCOUT_PIN` | Scout site pin | 2 | Visit SITE_PIN | Small band | Exploration |
| `CT_WAR_CONTEST` | War Contested push | 2 | Contested vs enemy Ownership | Pool + band | **Requires war state** (rules/23) |
| `CT_CLEANSE_SWEEP` | Cleanse sweep (CX) | 2 | Cleanse props | CX-leaning | |
| `CT_INFECTION_DRILL` | Infection drill (gROT) | 2 | Stack on training pylon | gROT-leaning | Training only |

---

## 2. Validation rules

1. Reject objectives that target a single player by name (harassment).
2. Reject unbounded spawn counts — max concurrent from template data.
3. War templates only while diplomacy state = war (rules/23 warm-up respected).
4. Daily alliance budget from pool + server hard cap (rules/15 soft economy).
5. AI/Prompt Studio may **rename flavour text** inside template — cannot invent new reward power.

---

## 3. Data shape (example)

```json
{
  "id": "CT_DEFEND_CLAIM",
  "min_rank": 2,
  "requires_war": false,
  "max_concurrent_dummies": 6,
  "reward_band": [40, 80],
  "site_pin_optional": true
}
```

---

## 4. VS must-have

Implement **2 templates**: `CT_DELIVER_HUB`, `CT_DEFEND_CLAIM`. Rank gate Officer+.

---

*Constructor template authority.*
