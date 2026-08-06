# NAEON — Ability Parameter Sheet

**Version:** 0.2  
**Purpose:** Vertical-slice numbers. Tuned from telemetry later.  
**Canon:** Infection max stacks = **5** (skill v1.4+, UI pips shape+number)

---

## 1. Global Constants

| Parameter | Value | Notes |
|-----------|-------|-------|
| Base player Energy (TPS) | 100 | Regen out of combat |
| Energy regen (out of combat) | 8 / sec | |
| Energy regen (in combat) | 3 / sec | |
| **Max Infection stacks** | **5** | Visible pips; decisive window, not permanent lock |
| Soft scaling cap from ranks | +12% | Cost or minor effect strength — rules/16 |

---

## 2. Hacking (gROT) — TPS: `Infect Link`

| Parameter | Value |
|-----------|-------|
| Energy cost | 35 |
| Cooldown | 16 s |
| Cast time | 0.4 s |
| Range | 18 m |
| Infection duration (per apply) | 6 s |
| Effect while stacks > 0 | +20% ability cost on target, 15% slower charge, soft outline for hacker |
| Stacks 4–5 | Pressure escalates (stronger cost/slow bands); still fully cleansable |
| Backlash on full Firewall block | 12 damage + 1.5 s self-slow |
| Strategy version cooldown | 45 s |
| Strategy effect | −25% claim strength gain / production on node for 20 s |

Channel is **interruptible**. Rank curve: rules/16.

---

## 3. Nex-Firewall (Cybernex) — TPS: `Nex Barrier`

| Parameter | Value |
|-----------|-------|
| Energy cost | 25 |
| Cooldown | 12 s (or 2 charges, 18 s recharge) |
| Cast | Instant (reactive window 0.35 s after hack detection) |
| Cleanse | **Removes all Infection stacks** (up to 5) |
| Immunity window | 2.5 s |
| Reveal hacker | 3 s |
| Strategy version | 1 charge, 60 s, hardens node vs next 2 hacks |

Never permanent absolute immunity. Rank curve: rules/16.

---

## 4. Interaction Notes

- Full Firewall block: hack energy spent, charge consumed, backlash applied.
- Partial resist (no active Firewall, high Nex Integrity): reduced duration only.
- Diminishing returns: 2nd hack on same target within 10 s → 30% less duration; 3rd → 50%.
- Stacks decay if not refreshed; cleanse wipes all.

---

## 5. Placeholder Basic Abilities (TestArena)

| Ability | Faction | Cost | CD | Effect |
|---------|---------|------|----|--------|
| Pulse Bolt | Both | 18 | 5 s | Ranged damage |
| Dash | Both | 22 | 8 s | Short movement |
| Repair Nanites | Cybernex | 30 | 14 s | Small HoT |
| Biomass Spike | gROT | 30 | 14 s | Burst + minor slow |

---

## 6. Tuning Rules

- Change one lever at a time.
- Log: successful hacks, blocks, backlash, Infection uptime, time-at-5-stacks.
- Feel targets: skilled Firewall stops ~55–65% naive hacks; skilled hacker lands ~40%+ vs good opponents.
- TTK equal skill ~4.5–6.5 s (Session A dummy).

---

*VS starting values — not final balance.*
