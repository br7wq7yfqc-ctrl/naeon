# NAEON — Ability System & Hacking / Nex-Firewall

**Version:** 0.2  
**Depends on:** rules/04 parameters, rules/16 ranks, rules/08 Knowledge, rules/10 UI

---

## 1. Goals

Unified **data-driven** Ability System for TPS, MOBA, and Strategy tags. Faction asymmetry with mandatory counterplay. No absolute permanent effects.

---

## 2. Ability data model

Resource fields (minimum):

`id`, `display_name`, `description`, `faction_tag` (Cybernex|gROT|Both), `ability_type`, `cost`, `cooldown`, `cast_time`, `range`, `duration`, `tags[]` (e.g. Hack, Firewall, Cleanse, Mobility), `rank_table_ref`, `effects[]`.

`AbilitySystem` owns equipped set, cooldowns, resource pools, effect lifecycle.

Required Knowledge rank = **soft gate for flavour/UI hints only**, never hard lock on core combat abilities.

---

## 3. Resource pools by layer

| Layer | Pools |
|-------|--------|
| TPS | Energy (+ Heat optional) |
| MOBA | Energy + Ultimate charge |
| Strategy | Command / Bandwidth + faction score |

---

## 4. gROT — Cyber-Hacking / Infection

- Apply **Infection stacks** (max **5**), cost pressure, slow charge, structure inefficiency (strategy tag).
- High Energy cost; interruptible channel; backlash if fully Firewalled.
- Cannot permanently steal player characters; cleansable.

## 5. Cybernex — Nex-Firewall / Purge

- Cleanse all stacks, short immunity, reveal hacker, optional ally pulse at higher ranks.
- Never permanent absolute immunity; overuse may add fatigue later.

## 6. Interaction rules

1. Hacks check live Firewall status.
2. Successful Firewall blocks/reduces and may punish caster.
3. Stacks decay if not refreshed; max 5 pips always readable (shape + number).
4. Knowledge = soft informational only.
5. Same teaching loop in PvE dummies.

## 7. Balance guidelines

Infection = pressure & attrition. Firewall = stability & timely cleanse. Every strong effect needs a visible counterplay window. Numbers live in rules/04 and /16 — not in scene scripts.

---

*Ability system design authority.*
