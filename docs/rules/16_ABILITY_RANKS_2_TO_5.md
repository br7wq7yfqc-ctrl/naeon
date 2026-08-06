# NAEON — Ability Rank Scaling (2–5)

**Version:** 0.1  
**Depends on:** `04_ABILITY_PARAMETERS.md` (rank 1 baseline)  
**Scope:** Infect Link (gROT Hack) and Nex Barrier (Cybernex Firewall) + notes for generic abilities

---

## 1. Rank rules

- Rank 1 = values in `04_ABILITY_PARAMETERS.md`
- Ranks unlock via play progression (quests, combat milestones, Knowledge soft gates optional for **flavour text only** — never exclusive power).
- Soft scaling cap from ranks remains ~+12% total effect strength or cost efficiency unless noted.
- Both factions reach rank 5 on the same time-to-rank budget.

---

## 2. Infect Link (Hacking) by rank

| Rank | Energy | CD | Cast | Range | Infection duration | Notes |
|------|--------|-----|------|-------|--------------------|-------|
| 1 | 35 | 16 s | 0.4 s | 18 m | 6 s | Baseline |
| 2 | 34 | 15 s | 0.4 s | 18 m | 6.5 s | +5% cost pressure on target |
| 3 | 33 | 14 s | 0.35 s | 19 m | 7 s | Object claim progress +6% on channel hit |
| 4 | 32 | 13 s | 0.35 s | 20 m | 7.5 s | Optional biomass cost 5 for Deep Link (+1 stack feel) |
| 5 | 30 | 12 s | 0.3 s | 20 m | 8 s | Max stacks interaction stays interruptible |

**Stack model (align with design intent):** prefer readable stack count up to **5** if TestArena uses stack pips; if live code uses max 3 from v0.1 sheet, treat ranks 4–5 as duration/pressure tuning until stack model is unified in one pass.

Backlash on full Firewall block stays meaningful at all ranks (≈10–14 damage + short self-slow).

---

## 3. Nex Barrier (Firewall) by rank

| Rank | Energy | CD / charges | Cleanse | Immunity | Reveal hacker | Notes |
|------|--------|--------------|---------|----------|---------------|-------|
| 1 | 25 | 12 s or 2×18 s | All stacks | 2.5 s | 3 s | Baseline |
| 2 | 24 | 11 s | All | 2.7 s | 3.2 s | Absorption +15 vs energy |
| 3 | 23 | 10 s | All + ally pulse 8 m | 3.0 s | 3.5 s | Mid-channel break chance → reliable |
| 4 | 22 | 2 charges / 16 s | All + ally | 3.2 s | 4 s | Purified buff 3.5 s |
| 5 | 20 | 2 charges / 14 s | All + ally | 3.5 s | 4 s | Still not permanent immunity |

Firewall must remain a strong answer, not an AFK shield. No rank grants permanent hack immunity.

---

## 4. Generic ability rank feel

| Rank | Pulse / Dash class |
|------|---------------------|
| 2–3 | Minor CD or cost polish |
| 4–5 | Small effect clarity or 1 QoL targeting ring — **no** hidden +30% damage tier |

---

## 5. Implementation note

Store ranks in data resources. Session A should unify Infection max stacks (3 vs 5) in one balance pass and then lock this sheet.

---

*Rank 2–5 starting curve for playtests.*
