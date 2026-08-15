# Energy Economy

**Single source of truth in code:** `godot/scripts/systems/EnergyEconomy.gd`.
This document mirrors it. If the two disagree, the constants win — an earlier
version of this table listed values the code never used (Pulse 6 / 0.55 s
against the real 18 / 5.0 s), so treat the file as authoritative and update this
mirror in the same commit.

## Regen (units/sec)

| Actor | Rate |
|-------|------|
| Arena hero (`REGEN_PLAYER`) | 8.0 |
| Surface walker (`REGEN_WALKER`) | 8.0 |
| Ship (`REGEN_SHIP`) | 8.0 |
| Max pool (`MAX_DEFAULT`) | 100.0 |

Walker regen is scaled by `InfectionStatus.energy_regen_mult()` (1.0 → 0.50 at
3+ stacks) and cut to 25% while EVA thrusters are burning, so EVA is a real fuel
budget rather than a net gain.

## Ability kit (rules/04)

| Ability | Cost | Cooldown |
|---------|------|----------|
| Pulse Bolt | 18 | 5.0 s |
| Nex-Firewall | 25 | 12.0 s |
| System Probe | 22 | 11.0 s |
| Hack | 35 | 16.0 s |
| Rot Surge | 30 | 14.0 s |
| Form Cycle | 0 | 2.0 s |

## Ship

| Action | Cost |
|--------|------|
| Bolt (SCM / HOVER) | 5.0 |
| Bolt (NAV) | 5.5 |
| Bolt in SIEGE | ×1.35 |
| Afterburn, W+Shift | 16.0/s while held |

Afterburn multiplies thrust ×1.55 and top speed ×1.18. It needs 18 energy to
engage (hysteresis — without a floor it strobed every frame near empty), and is
denied while landed or hull-critical.

## Rules

- `Ability.activate` aborts when `EnergyEconomy.spend` fails, so an ability can
  never fire for free.
- Channel start failure **refunds**. An interrupt mid-channel keeps the spend
  (that is the risk).
- Economy rank and Knowledge never modify any number here (rules/08). Knowledge
  used to multiply ability damage; that was removed in the 2026-08-15 audit.

Updated: 2026-08-15 (audit pass — mirror re-synced to the constants).
