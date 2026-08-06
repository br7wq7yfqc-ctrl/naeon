# NAEON — Shared Agent Memory

**Last updated:** 2026-08-06 (rules 18–19 + skill map)

## Core constraints
No P2W · soft Knowledge only · asymmetric Cybernex/gROT · Dynamic Ownership + capped Arena · readable UI · Infection max 5 · Tripo-first dual-theme · no secrets/heavy assets in Git · Godot 4 Mac+Windows · reference bars ≠ parity · freemium never sells combat/claim power

## Design reference bars
Star Citizen → seamless S0–S3 · NMS → variants · EVE/Stellaris → economy/social · Predecessor/Paragon → MOBA TPS soft influence

## Design corpus
rules/00–19 · lore · legal · HANDOFF/HANDOFFS · Skill **v1.5** (map to include 18–19)

### New this pass
- **rules/18_SEAMLESS_CONTEXT_PAYLOAD.md** — TransitionContext schema, S0/S1 DoD, primary routes, Godot hooks
- **rules/19_FREEMIUM_UI_AND_GATES.md** — allow/deny, EN/RU copy keys, screen gates, VS minimum

## Implementation snapshot
TestArena + SpaceTest playable · pipeline scripts live · Tripo balance 0 · neon keys TBD · transitions **S0** until HANDOFF says otherwise

## Decision log (recent)
| Date | Decision |
|------|----------|
| 2026-08-06 | Skill v1.5 freemium/AI/Godot/QA |
| 2026-08-06 | **rules/18** context payload + **rules/19** freemium UI copy/gates |

## Open gaps
Session A: Infection → 5 pips · Session B: implement TransitionContext round-trip TestArena↔SpaceTest · ops: Tripo/neon

## Agent protocol
HANDOFF → brief → rules (18 for transitions, 19 for shop/sub UI) → skill → code.
