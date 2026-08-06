# NAEON — Master Plan: Rules, Mechanics & Content Artifacts

**Role:** Design Authority for game mechanics, rules, balance, lore and content.  
**Goal:** Produce a complete, consistent set of design artifacts that development agents can implement without ambiguity, while respecting the economical pipeline.

---

## 1. Foundational Legal & Meta Documents

| Artifact | Priority | Description |
|----------|----------|-------------|
| Terms of Service / User Agreement | High | Rights, obligations, account rules, acceptable use |
| Privacy Policy | High | Data collection, Yandex services, AI features |
| Community Guidelines | High | Chat, voice, UGC, griefing, exploits |
| Monetization Policy (Freemium + Subscription) | High | What is paid, what is free, no-P2W declaration |
| Age Rating & Content Warnings | Medium | ESRB/PEGI equivalent notes |
| EULA for generated content (aiNEX / Prompt Studio) | Medium | Ownership of AI-generated blueprints, missions, etc. |

---

## 2. Core Design Pillars & Vision

| Artifact | Status |
|----------|--------|
| Design Pillars (one-pager) | To create |
| Target Audience & Fantasy | To create |
| Core Loop Diagram (Strategy → Space → TPS → Meta) | To refine |
| Asymmetry Manifesto (Cybernex vs gROT) | Partially in CONCEPT |
| Soft Progression Philosophy (Contribution / Biomass / Knowledge) | Partially done |

---

## 3. Faction & Lore Artifacts

| Artifact | Priority |
|----------|----------|
| Full Schism Timeline | High |
| Cybernex Ideology, Society, Limitations of Genetic Editing | High |
| gROT Ideology, Swarm Hierarchy, ROT as entity | High |
| Noopeople (human-cyborgs) detailed rules | High |
| Transgalactic Network & Infection Vector lore | High |
| Major Story Arcs (Act structure for each faction) | High |
| Key Historical Events & War Score implications | Medium |
| Glossary of Terms | Medium |

---

## 4. Character & NPC Artifacts

| Artifact | Priority |
|----------|----------|
| Biography template | High |
| Major Cybernex characters (leaders, advisors, animal-robot archetypes) | High |
| Major gROT characters (lieutenants of ROT, unique mutants) | High |
| Quest-giver grid (both factions) | High |
| AI-NPC personality matrices (for Yandex GPT / SpeechKit) | Medium |
| Voice profiles & language style guides | Medium |

---

## 5. Systems & Mechanics Rulebooks

| System | Artifacts needed |
|--------|------------------|
| **Combat (TPS + Space)** | Ability parameters, Hacking vs Firewall full rules, damage types, status effects |
| **Strategy / Alliance** | Hierarchy, permissions, shared resources, claim rules, War Score |
| **Dynamic Ownership** | Transition rules, visual + gameplay changes, Contested state |
| **Economy (RBE / Biomass)** | Formulas, Contribution calculation, sinks & sources |
| **Knowledge & Educational** | Subject list, Mastery thresholds, soft combat benefits, puzzle design rules |
| **Quests** | Types, reward formulas, Premium vs regular, Alliance Constructor rules |
| **MOBA (Aexion Clash)** | Hero kits, itemization, map objectives, Arena Influence soft rules |
| **Crafting & Blueprints** | Tiers, decoration rules, Prompt Studio limits |
| **Voice & Chat** | Channel permissions, subscription gates, moderation |
| **Fleets & Carriers** | Multi-crew roles, drone rules, fleet command |

---

## 6. Balance & Parameter Sheets

| Sheet | Content |
|-------|--------|
| Ability Parameter Sheet | Cooldowns, costs, magnitudes, scaling |
| Ship Module Stats | Thrust, shields, weapons, cargo |
| Character Form Stats | Speed, health, special movement |
| Resource Values | Extraction rates, conversion ratios |
| Progression Curves | Contribution, Biomass Rank, Knowledge Rank |
| Soft Cap Tables | To prevent runaway power |
| Economy Simulation Notes | Early-game / mid-game / late-game targets |

---

## 7. Content Catalogs

| Catalog | Notes |
|---------|-------|
| Star Systems & Planets | Names, resources, ownership states, visual themes |
| Quest Catalog (templates + examples) | Generated + hand-authored |
| Premium Narrative Quests | Story-only, no balance impact |
| Global Events calendar | |
| Blueprint / Decoration catalog | |
| Educational Module library | Languages, STEM, lore |

---

## 8. AI & Generation Rules

| Artifact | Purpose |
|----------|--------|
| Prompt Studio Guidelines | What players can generate, safety filters |
| aiNEX Content Policy | |
| Educational Content Safety Rules | Age-appropriate, verified answers |
| NPC Dialogue Style Guides (per faction) | |
| Asset Generation Priority Rules (A/B/C) | Linked to economical pipeline |

---

## 9. Implementation Order (Design)

**Phase D1 (Immediate)**  
- Design Pillars  
- Full Schism + Faction ideologies  
- Ability Parameter Sheet (Hacking/Firewall first)  
- Quest type definitions + reward formulas  
- Agent Memory initialization  

**Phase D2**  
- Character biographies (core cast)  
- Star system bible  
- Dynamic Ownership detailed rules  
- Knowledge / Educational full rules  

**Phase D3**  
- Balance sheets for ships, forms, economy  
- Story arcs (both factions)  
- Premium quest outlines  
- MOBA integration rules  

**Phase D4+**  
- Full catalogs, events, advanced voice rules, live-ops content frameworks

---

## 10. Living Documents

All rules live in `/docs/rules/` and `/docs/content/`.  
Every significant design decision is also recorded in **Agent Shared Memory** (`docs/AGENT_MEMORY.md`).

---

*This plan is the single source of truth for what design artifacts must exist before systems are considered "complete".*
