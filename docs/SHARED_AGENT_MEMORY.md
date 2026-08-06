# NAEON — Shared Agent Memory

**Purpose:** Single source of truth for all design decisions, mechanical rules, content progress, and constraints that every development agent must respect.

**Maintainer:** Design Lead  
**Last updated:** 2026-08-05

---

## 1. Core Project Constraints (Never Violate)

- **No Pay-to-Win.** Subscription and tokens give convenience, cosmetics, voice, premium narrative, generation quota — never combat power or claim advantage.
- **Economical Asset Pipeline.** Prefer free credits → Tripo primary → Meshy secondary → Rodin only for hero assets. One mesh → many variants (Cybernex + gROT) in Blender.
- **Local-first development.** Heavy assets never in main Git repo. Use `assets/` (gitignored) + Yandex Object Storage bucket `neon`.
- **Godot 4.x**, dark-neon futuristic aesthetic, low-end optimization target.
- **Asymmetric factions:** Cybernex (protection, harmony, Nex-Firewall) vs gROT (assimilation, infection, hacking).
- **Soft Knowledge system** only — informational / QoL advantages, never raw stats.

## 2. Current Mechanical Truths

### Factions & Lore
- The Schism originated from conflict among NAEXOS creators.
- gROT split and used the transgalactic network as infection vector.
- Most of humanity is in hibernation in NEX on ARK.
- Noo-people and Cybernex animal-robots are protected by genetic editing (with limitations compensated by RBE/NAEXOS model).

### Key Systems Status
- Ability System: data-driven foundation exists (supports Hacking / Firewall flags).
- OwnershipData + OwnershipComponent: data model and skeleton exist.
- Knowledge / Contribution / Subject Mastery: data structures exist.
- Dynamic Ownership: visual + gameplay transformation required (dual themes).
- Asset Pipeline: Tripo-first, free-tier prioritized, documented.

### Monetization
- Freemium + paid subscription.
- Tokens for AI generation (Yandex GPT / aiNEX).
- Voice channels gated by subscription or achievement.
- Premium quests are narrative-only and must not affect MMO balance.

## 3. Decision Log (append only)

| Date | Decision | Reason |
|------|----------|--------|
| 2026-08-05 | Design Lead role activated | User directive |
| 2026-08-05 | Tripo selected as primary 3D generator | Best balance of topology, price, free tier for game assets |
| 2026-08-05 | Parallel multi-agent build sessions stopped; handoffs created | User directive |
| 2026-08-05 | Shared Agent Memory + Holistic Skill created | User directive |

## 4. Open Questions / To Resolve

- Exact numerical parameters for Hacking duration, Firewall strength, infection progress rates.
- Full list of starting star systems and their ownership rules.
- Concrete soft multipliers for each Subject Mastery in combat.
- Voice channel achievement thresholds.

## 5. How Agents Must Use This Memory

1. Before making any design or mechanical change — read this file.
2. After any significant decision or new rule — append to Decision Log and update the relevant section.
3. Never contradict the Core Project Constraints.
4. Prefer updating existing artifacts over creating conflicting new ones.

---

*This memory is the contract between all agents working on NAEON.*

| 2026-08-06 | Vertical slice asset batch1 complete (10 meshes → dual-theme LODs) via Tripo+Blender; economical A/B/C | Holistic skill |
| 2026-08-06 | Ship/colony/dummy runtime GLB load; Mac DMG installer + AutoUpdater | Session |

## Decision Log — 2026-08-06
- Budget: week 5k / month 20k Tripo; vision not capped after top-up.
- Sysreqs floor: RTX 1060 3GB / i3 / 16GB; tiers LOW–ULTRA in GraphicsQuality.
- Shipped OpenSpace seamless continuum (FloatingOrigin, PlanetBody, ship SCM/NAV/HOVER, surface walk).
- Main scene switched to OpenSpace.tscn.
- Wave S complete; A in progress under week cap.
