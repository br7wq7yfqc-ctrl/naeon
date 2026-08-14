# NAEON — Knowledge Soft Effects

**Version:** 0.2  
**Status:** Design authority  
**Constraint:** Knowledge never grants raw damage, HP, CDR, claim strength, or extraction rate beyond tiny QoL

---

## 1. Intent

Knowledge / Subject Mastery is **informational and QoL**. It supports the educational fantasy and NAEXOS.ONLINE-style learning without becoming a pay-or-study-to-win combat track.

---

## 2. Subject → soft benefit

| Subject ID | Soft benefit (examples) | Explicitly not |
|------------|-------------------------|----------------|
| `cybernetics` | Clearer Infection pip timing; optional early hack-channel telegraph density | Damage reduction, HP |
| `programming` | Enemy ability cooldown **estimate** tooltips (fuzzy bands) | True perfect CDR reveal in ranked if abused — keep fuzzy |
| `logistics` | Better cargo mass/value estimates; sort filters | Cargo stealth from enemies |
| `ecology` | Resource node type highlight (optional overlay) | Higher node yield |
| `history` | Extra lore entries, dialogue variants | Unique permanent weapons |
| `mathematics` | Crafting cost/preview clarity | Lower craft costs than tier tables |
| `physics` | Minor trajectory assist **UI** (toggleable) | Auto-aim, aimbot |
| `biology` | Faster biomass hazard icon recognition | Immunity to hazards |
| `languages` | Additional dialogue variants / subtitle clarity | Skip combat encounters |

Overlays default **off** or subtle; player can disable. Never required to see core threat (Hack/Firewall/Infection shapes).

---

## 3. Progression

- Rank up via educational modules, campaign Knowledge beats, optional puzzles (aiNEX templates).
- Soft daily/weekly diminishing on pure grind modules.
- Subscription may unlock extra **module slots or cosmetic archive skins**, not higher combat soft-caps than free max.

---

## 4. Combat integration rules

1. Soft benefits are **UI and prediction** — not hidden stat multipliers.
2. Equal-skill TTK targets in rules/04 remain valid with or without Knowledge.
3. Competitive modes may offer “Competitive HUD” preset that disables optional Knowledge clutter for fairness optics (optional).

---

## 5. Godot hooks

- `KnowledgeFlags` / subject ranks on profile
- UITheme optional overlay layers gated by flags
- No ability damage formulas read Knowledge ranks

---

*Soft Knowledge source of truth.*
