# NAEON — Economy Numeric Rates & Crafting Tiers

**Version:** 0.1  
**Status:** Starting numbers for vertical slice / Phase 1–2  
**Depends on:** `05_ECONOMY_RBE_BIOMASS.md`  
**Constraint:** No P2W; Knowledge does not multiply raw extraction beyond tiny QoL

---

## 1. Physical resources (shared)

| Resource ID | Role | Typical node yield / min |
|-------------|------|---------------------------|
| `ore_basic` | Structure components | 6–10 |
| `energy_cell` | Modules, craft power | 4–8 |
| `organics` | Biomass recipes / medical | 5–9 |
| `nex_crystal` | Rare Cybernex-leaning | 0.5–1.5 |
| `biomass_slurry` | Rare gROT-leaning | 0.5–1.5 |

Ownership of node may bias rare type and service list; does not hard-lock the other faction out of all basic ore/energy.

---

## 2. Resource → score conversion

### Contribution (Cybernex) — on successful **delivery** to allied node

| Input | Contribution |
|-------|----------------|
| 1 ore_basic | 2 |
| 1 energy_cell | 2 |
| 1 organics | 2 |
| 1 nex_crystal | 12 |
| 1 biomass_slurry (reclaimed/purified) | 8 |

### Biomass progress (gROT) — on **conversion** at corrupted node / harvester

| Input | Biomass progress |
|-------|------------------|
| 1 ore_basic | 2 |
| 1 energy_cell | 2 |
| 1 organics | 3 |
| 1 biomass_slurry | 12 |
| 1 nex_crystal (corrupted) | 8 |

Delivery/conversion must complete; cargo lost on destroy grants **no** score.

---

## 3. Soft daily caps (per character)

| Source | Soft cap / day | Notes |
|--------|----------------|-------|
| Repetitive extract→deliver same node type | 400 Contribution **or** 400 Biomass | Diminishing after 70% of cap |
| Standard quests | 600 combined score-equivalent | |
| Claim/contest participation | 500 | Shared across events |
| Educational first-time modules | 120 | Repeat = cosmetic/Knowledge only |

Caps are soft (severe diminishing, not hard stop) so late play is not bricked.

---

## 4. Structure / upgrade sinks (Contribution or Biomass pool)

| Upgrade | Cost band | Upkeep / day |
|---------|-----------|--------------|
| Personal extractor T1 | 80–120 | 5 |
| Extractor T2 | 250–350 | 15 |
| Outpost defense kit T1 | 150–200 | 10 |
| Hub module (alliance) | 800–1200 from pool | 40 |

Upkeep unpaid → efficiency drop, then Contested vulnerability — not instant delete.

---

## 5. Crafting tier costs (components → gear)

| Tier | Example output | Typical mats | Blueprint gate |
|------|----------------|--------------|----------------|
| T0 | Plates, cables | 5–15 basic | None |
| T1 | Basic TPS gear piece / ship module | 20–40 basic + 2 rare | Quest or vendor |
| T2 | Mid module | 60–100 basic + 6 rare | Faction tree |
| T3 | High module | 150–250 + 15 rare | Alliance project or long chain |
| Cosmetic décor | Props | Mostly basic | Cosmetic track / premium skin OK |

**Rules**
- Equivalent power budgets on both faction trees at each tier.
- Shop may sell craft-time convenience and cosmetic skins only.
- Prompt Studio blueprints for power items must snap to these tier bands.

---

## 6. Alliance pool transfer

- Max transfer to pool per day: 200 personal score
- Officer+ withdraw for projects only (logged)
- No conversion pool → personal weapon DPS

---

## 7. Tuning levers

Change one of: node yield, conversion rate, daily soft cap, tier mat cost. Log extract hours, claim frequency, T2+ craft rate.

---

*Starting rates for implementation; revisit after first economy playtest.*
