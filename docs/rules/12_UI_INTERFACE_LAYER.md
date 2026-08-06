# NAEON — Interface Layer Rules

**Version:** 0.1  
**Date:** 2026-08-06

---

## 1. Purpose

The interface is a first-class system: it must express faction asymmetry, support multi-layer gameplay (Strategy / Space / TPS / Arena / Meta), remain readable on low-end hardware, and never hide counterplay.

## 2. Global UI Principles

1. **Readability over spectacle** — critical state (Infected, Contested, Firewall up) must be obvious within ~0.5s.
2. **Faction skin, shared skeleton** — same layouts for both factions; colors, motifs and microcopy change.
3. **Soft Knowledge only in UI** — higher Knowledge may add optional info density, never exclusive power buttons.
4. **One universe navigation** — clear switches between Strategy map, Space, TPS, Arena, Alliance hub, Prompt Studio.
5. **Low-end safe** — scalable UI, reduced particles mode, no mandatory heavy blur.
6. **Subscription gates are labeled** — premium narrative / voice / extra tokens show clear unlock path, no fake power locks.

## 3. Layer Map

| Layer | Primary UI | Critical widgets |
|-------|------------|------------------|
| **Boot / Meta** | Login, faction select, form select | Fair Play notice, subscription status |
| **Strategy** | System map, Ownership colors, orders | Claim bars, Contested timers, Alliance roster |
| **Space** | Flight HUD, modules, cargo, multi-crew | Target lock, ship hack/firewall states |
| **TPS** | Crosshair, ability bar, form indicator | Infection stacks, Firewall charges, quest tracker |
| **Arena** | MOBA HUD + soft influence meter | Capped claim-bonus indicator |
| **Alliance Hub** | Hierarchy, shared pools, constructor | Permissions, voice list |
| **Learning / Prompt Studio** | Modules, puzzles, budget | Tokens, safety filters |
| **Social** | Chat, voice, codex | Channel gates |

## 4. Faction Visual Language (UI)

| Element | Cybernex | gROT |
|---------|----------|------|
| Palette | Cyan, white, soft green on navy | Red-violet, bone, amber on black |
| Frames | Smooth, architectural | Jagged, organic-tech |
| Positive status | Green-cyan pulse | Amber growth |
| Hostile status | Magenta warning | Deep red / sickly green |
| Type | Clean geometric | Heavier, slight unstable tracking |

Shared icon shapes stay recognizable; chrome follows faction / Ownership.

## 5. Counterplay UI Contracts

- **Infection**: icon + stacks + duration on self and target
- **Firewall**: charge pips + reactive timing window
- **Contested**: world marker + progress ring + color blend
- **Backlash**: explicit self-debuff feedback
- Never color-only — shape + text + optional audio

## 6. HUD Density Modes

- Minimal / Standard / Specialist (Knowledge optional) / Performance (low-end)

## 7. Accessibility

- Keyboard+mouse first; colorblind-safe shapes; scalable text; subtitles for AI voice; text playable without voice.

## 8. Monetization UI

- Cosmetics separate from loadout
- Premium quests labeled **Story Only — no power rewards**
- Token packs show budget, never imply P2W

## 9. Vertical Slice Must-Have

- TPS HUD (abilities, infection, firewall, quest tracker)
- Simple Space HUD
- Ownership progress on claimables
- Faction chrome switch
- Basic text chat

---
*Authoritative interface-layer design for early implementation.*
