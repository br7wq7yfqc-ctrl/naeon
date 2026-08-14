# 06 — Quest System Foundation

**Version:** 0.1  
**Last updated:** 2026-08-05

## 1. Quest Categories

| Category | Description | Balance Impact |
|----------|-------------|----------------|
| Story Campaign | Main faction narrative arcs | Low direct, high lore |
| Generated NPC Quests | Procedural / AI-assisted daily & repeatable | Controlled |
| Alliance Quests | Player-created via constructor | Medium |
| Educational Quests | Knowledge / learning focused | Soft only |
| Premium Narrative | Subscriber-only story content | None on MMO balance |
| Global Events | Limited-time world events | Soft / temporary |

## 2. Core Rules

1. Premium narrative quests **must not** grant unique permanent combat power.
2. Educational quests grant Knowledge mastery and soft benefits only.
3. Alliance Quest Constructor has validation rules to prevent abuse (resource sinks, time gates, objective limits).
4. Generated quests use templates + aiNEX for flavor text and minor variations.
5. All quests award either Contribution, Biomass, XP, Knowledge, or cosmetic / convenience rewards according to faction and type.

## 3. Reward Philosophy

- Story & Premium → narrative satisfaction + cosmetics / titles / lore items.
- Generated & Alliance → steady economic and progression fuel.
- Educational → Knowledge Rank + soft combat QoL.
- Global Events → temporary bonuses + exclusive cosmetics.

## 4. Quest Lifecycle

Available → Accepted → In Progress → Completed / Failed → Cooldown / Archive

Server tracks state. Some quests are instance-bound, others open-world.

## 5. NPC Quest Givers (high-level)

Each major hub and many outposts have a small set of named NPCs that cover:
- Military / defense
- Logistics / economy
- Exploration / science
- Educational / Knowledge
- Faction loyalty / special ops

Detailed grid will be a separate artifact.

## 6. Integration Points

- Dynamic Ownership can enable / disable certain quests on a location.
- Hacking / Firewall objectives can appear as quest goals.
- Knowledge gates can soft-lock advanced educational chains.
