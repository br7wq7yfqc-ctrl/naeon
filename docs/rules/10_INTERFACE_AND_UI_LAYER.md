# 10 — Interface & UI Layer

**Version:** 0.1  
**Last updated:** 2026-08-05

## 1. Design Goals

- Dark-neon futuristic aesthetic consistent with the Aexion universe.
- Clear faction identity (Cybernex vs gROT) without harming readability.
- Low-end friendly: scalable UI, minimal overdraw, readable at 1080p and below.
- Support all major modes: Strategy, Space, TPS, MOBA, Educational terminals.
- Voice and AI-NPC integration must feel native, not bolted on.

## 2. Visual Language

### Cybernex UI
- Clean geometry, soft glow (cyan / white / soft green)
- High contrast but calm
- Organic-tech motifs, subtle living lines
- Rounded panels, clear hierarchy

### gROT UI
- Sharper, more aggressive shapes
- Red-purple / deep crimson emission
- Biomass overlays, irregular edges, slight "corruption" accents
- Still must remain legible in combat

### Neutral / System UI
- Dark base with neon accents
- Used for shared menus, settings, login, platform gates

## 3. Core HUD Layers

| Layer | Content |
|-------|--------|
| Persistent | Health / Integrity, Energy / Heat, faction resource, minimap / radar |
| Contextual | Ability bar, target info, Infection / Firewall status, objective tracker |
| Mode-specific | Strategy command bar, ship modules, MOBA items / levels, educational terminal |
| Social | Chat, alliance alerts, voice indicators (subscription-gated) |
| System | Notifications, warnings, Ownership change banners |

## 4. Key Screens

- Login / Character / Form select
- Main Hub (faction-themed)
- Galaxy / System map (Ownership colours)
- Inventory & Crafting
- Ability / Loadout loadout
- Alliance management
- Quest log (with Knowledge & Premium filters)
- Settings (graphics, accessibility, voice, AI tokens)
- NAEXOS.ONLINE gate overlays

## 5. Accessibility & Low-end

- Scalable text and UI scale slider
- Colour-blind friendly palette options
- Reduced motion / reduced particles toggle
- High-contrast mode
- Keyboard + gamepad full support

## 6. Dynamic Ownership Reflection

When the player is in a location whose Ownership changes:
- Subtle ambient UI tint shift
- Banner / toast notification
- Local service icons update
- No hard screen takeover that blocks combat

## 7. AI & Voice Integration

- AI-NPC dialogue panel with optional voice playback
- Prompt Studio access clearly separated and marked as token-consuming when applicable
- Educational terminals have distinct visual treatment

## 8. Implementation Notes

- Prefer Control nodes + themes over hard-coded positions
- Faction themes as Theme / StyleBox resources that can be swapped
- HUD elements should be modular scenes
- Avoid permanent full-screen overlays during action
