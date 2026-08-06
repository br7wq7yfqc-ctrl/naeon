# NAEON — Ability Parameter Sheet (v0.1)

**Purpose:** First concrete numbers for Vertical Slice. All values are starting points and will be tuned from telemetry.

---

## 1. Global Constants

| Parameter | Value | Notes |
|-----------|-------|-------|
| Base player Energy (TPS) | 100 | Regenerates out of combat |
| Energy regen (out of combat) | 8 / sec | |
| Energy regen (in combat) | 3 / sec | |
| Max concurrent Infection stacks | 3 | |
| Soft scaling cap from ranks | +12% | Cost reduction or minor effect strength |

---

## 2. Hacking (gROT) — TPS: `Infect Link`

| Parameter | Value |
|-----------|-------|
| Energy cost | 35 |
| Cooldown | 16 s |
| Cast time | 0.4 s |
| Range | 18 m |
| Infection duration | 6 s |
| Effect while Infected | +20% ability cost on target, 15% slower ability charge, soft outline for hacker |
| Backlash on full block | 12 damage + 1.5 s self-slow |
| Strategy version cooldown | 45 s |
| Strategy effect | -25% claim strength gain / production on target node for 20 s |

## 3. Nex-Firewall (Cybernex) — TPS: `Nex Barrier`

| Parameter | Value |
|-----------|-------|
| Energy cost | 25 |
| Cooldown | 12 s (or 2 charges, 18 s recharge) |
| Cast time | Instant (reactive window 0.35 s after hack detection) |
| Cleanse | Removes all Infection stacks |
| Immunity window | 2.5 s |
| Reveal hacker duration | 3 s |
| Strategy version | 1 charge, 60 s, hardens node against next 2 hacks |

## 4. Interaction Notes

- Full block by Firewall: hack energy still spent, Firewall charge consumed, backlash applied.
- Partial resist (no active Firewall but high Nex Integrity): reduced duration only.
- Diminishing returns: 2nd hack on same target within 10 s has 30% reduced duration; 3rd has 50%.

## 5. Placeholder Basic Abilities (for TestArena)

| Ability | Faction | Cost | CD | Effect (placeholder) |
|---------|---------|------|----|----------------------|
| Pulse Bolt | Both | 18 | 5 s | Ranged damage |
| Dash | Both | 22 | 8 s | Short movement |
| Repair Nanites | Cybernex | 30 | 14 s | Small heal over time |
| Biomass Spike | gROT | 30 | 14 s | Short damage burst + minor slow |

## 6. Tuning Rules

- Change only one lever at a time.
- Log: successful hacks, blocked hacks, backlash events, average Infection uptime.
- Target feel: a skilled Firewall user should stop ~55–65% of naive hacks; skilled hacker should still land ~40%+ against good opponents.

---
*Numbers are Vertical Slice starting values, not final balance.*
