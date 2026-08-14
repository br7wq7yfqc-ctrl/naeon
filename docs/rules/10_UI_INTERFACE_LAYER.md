# NAEON — Interface Layer (UI/UX Rules)

**Version:** 0.2  
**Status:** Design authority (canonical UI doc)  
**Supersedes:** 10_INTERFACE_AND_UI_LAYER.md, 12_UI_INTERFACE_LAYER.md

---

## 1. Goals

- Dark-neon futuristic language readable on low-end hardware.
- Faction identity without hiding critical combat information.
- Soft Knowledge improves clarity — never required for core threat info.
- Strategy / Space / TPS / MOBA feel like layers of one universe.

---

## 2. Global visual language

| Token | Value |
|-------|--------|
| Base chrome | Dark panels, thin neon edges, high contrast text |
| Cybernex accent | Cyan / white / soft green |
| gROT accent | Red-purple / sickly green / black |
| Neutral / system | Cool grey-blue |
| Danger | Amber → hard red (same for both factions) |
| Safe / ally | Readable green independent of faction skin |

Faction skin changes ornament; not the meaning of red/green threat.

---

## 3. Layer map

| Layer | Primary UI | Critical widgets |
|-------|------------|------------------|
| Boot / Meta | Login, faction/form select | Fair Play notice, subscription status |
| Strategy | System map, Ownership colours | Claim bars, Contested timers, Alliance roster |
| Space | Flight HUD, modules, cargo, multi-crew | Target lock, ship Hack/Firewall states |
| TPS | Crosshair, ability bar, form indicator | Infection stacks, Firewall charges, quest tracker |
| Arena | MOBA HUD + soft influence meter | Capped claim-bonus indicator |
| Alliance Hub | Hierarchy, pools, constructor | Permissions, voice list |
| Learning / Prompt Studio | Modules, puzzles, budget | Tokens, safety filters |
| Social | Chat, voice, codex | Channel gates |

---

## 4. HUD details

**TPS:** Health/Integrity, Energy, Biomass (gROT); ability bar; unique Hack channel vs Firewall shield silhouettes; Infection pips on nameplate; Knowledge overlays optional (no auto-aim).

**Space:** Speed/shield, module hotbar, ownership-tinted brackets, multi-crew role strip, cargo risk UI.

**Strategy:** Ownership icons (Cybernex/gROT/Contested/Neutral/Protected), Contested progress ring, pool widgets for officers+, constructor pins by rank.

**MOBA:** Lane clarity first; faction ornaments second; post-match influence summary when world-linked.

---

## 5. Counterplay UI contracts

- Infection: icon + stacks + duration on self and target
- Firewall: charge pips + reactive timing window
- Contested: world marker + progress ring + colour blend
- Never colour-only — shape + text + optional audio

---

## 6. Dynamic Ownership in UI

Hub entry: theme cross-fade. Contested: glitch/mix on map widget and service menus. Service lists swap by owner with clear labels. No hard screen takeover that blocks combat.

---

## 7. Social, meta, monetization UI

- Alliance ranks (cosmetic names). Voice indicator only if unlocked.
- Premium quests marked **Story Only — no power rewards**.
- Shop: cosmetics and convenience explicitly labelled; no combat power tags.
- Token packs show budget, never imply P2W.

---

## 8. Accessibility and performance

Colourblind-safe shapes for Hack/Firewall/Infection. Scalable text. Density modes: Minimal / Standard / Specialist (Knowledge optional) / Performance. Low-end prioritizes threat icons over panel particles. No mandatory heavy glass blur on minimum preset. Keyboard + gamepad full support.

---

## 9. AI surfaces

Quota/cost before confirm. Plain safety rejects. Educational puzzles visually separated from combat rewards.

---

## 10. Godot hooks

`UITheme` packs (Cybernex/gROT/Neutral). OwnershipComponent → theme controller. Ability tags → icons/channel widgets. Knowledge flags → optional overlays only. Prefer Control nodes + themes; modular HUD scenes.

---

## 11. Vertical slice must-have

TPS HUD (abilities, infection, firewall, quest tracker); simple Space HUD; Ownership progress on claimables; faction chrome switch; basic text chat.

---

*Canonical UI/UX source of truth.*
