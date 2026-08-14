# NAEON — Freemium UI, Gates & Copy Strings

**Version:** 0.1  
**Status:** Design authority for monetization surfaces  
**Depends on:** skill §5 freemium table, rules/01 Fair Play, rules/10 UI, rules/13 MOBA, rules/17 Voice  
**Constraint:** No Pay-to-Win — ever

---

## 1. Product model

- **Free core:** full combat viability, claim participation, both factions, standard quests, text chat.
- **Subscription (Premium):** convenience, cosmetics, voice path, premium **story-only** narrative, higher generation quota.
- **Tokens:** Prompt Studio / aiNEX generation budget, optional cosmetic packs — never power.

---

## 2. Allow / deny (UI must enforce labels)

| Surface | Allowed | Forbidden |
|---------|---------|-------------|
| Shop item tags | Cosmetic, Convenience, Story, Quota | Power, DPS, HP, Claim, War Score |
| Premium quest reward | Codex, title, skin, emote | Contribution/Biomass beyond cosmetic, gear with stats |
| Token spend | Generation, skin unlock | Extraction multiplier, rank skip that grants combat |
| Voice | Sub **or** achievement (rules/17) | Pay for louder/global combat callouts that free cannot match in PvP info |
| MOBA | Cosmetic paths, skins | Higher influence rate, stronger heroes |

---

## 3. Mandatory UI labels (copy — EN; RU variants below)

Use exact meaning; wording may be localized but **must not** imply power.

| Key | EN copy |
|-----|---------|
| `label.story_only` | Story Only — no power rewards |
| `label.cosmetic` | Cosmetic |
| `label.convenience` | Convenience — no combat advantage |
| `label.quota` | Generation quota |
| `label.sub_required` | Premium subscription |
| `label.achievement_path` | Or unlock via achievement |
| `label.tokens_budget` | Tokens remaining: {n} |
| `label.no_p2w` | Does not affect combat power or claims |
| `shop.section.cosmetics` | Cosmetics |
| `shop.section.convenience` | Convenience |
| `shop.section.story` | Story & codex |
| `shop.section.quota` | AI & generation |
| `gate.voice_locked` | Voice channels: Premium or achievement |
| `gate.prompt_cost` | This generation costs {n} tokens |
| `gate.premium_quest` | Premium story quest — rewards are cosmetic/lore only |
| `arena.influence_cap` | Daily world influence from Clash is capped for all players |

### RU (reference)

| Key | RU copy |
|-----|---------|
| `label.story_only` | Только история — без усиления силы |
| `label.cosmetic` | Косметика |
| `label.convenience` | Удобство — без боевого преимущества |
| `label.quota` | Квота генерации |
| `label.sub_required` | Подписка Premium |
| `label.achievement_path` | Или открыть достижением |
| `label.tokens_budget` | Токены: {n} |
| `label.no_p2w` | Не влияет на боевую силу и захваты |
| `gate.voice_locked` | Голосовые каналы: Premium или достижение |
| `gate.prompt_cost` | Генерация стоит {n} токенов |
| `gate.premium_quest` | Премиум-сюжет — награды только косметика/лор |
| `arena.influence_cap` | Дневное влияние Clash на мир ограничено для всех |

---

## 4. Screen-level gates

### Shop
- Sections split by allowed types only.
- Every power-like iconography forbidden on cosmetic rows.
- Tooltip includes `label.no_p2w` for convenience items.

### Quest log
- Premium entries show `label.story_only` badge before accept.
- Reward preview lists cosmetics/codex only — no fake gear stats.

### Prompt Studio / Learning
- Cost + budget before confirm (`gate.prompt_cost`, `label.tokens_budget`).
- Safety reject: plain text, non-punitive.
- Educational rewards never show damage numbers as unlock.

### Voice
- Locked state: `gate.voice_locked` + link to Premium **and** achievement list (rules/17).
- Unlocked via either path; lapse of sub does not remove achievement path.

### Arena end screen
- If world-linked: show capped influence with `arena.influence_cap`.
- Never show “buy more influence”.

---

## 5. Analytics / Fair Play hooks

- Log accept of premium story quests with reward_type=cosmetic_or_lore only.
- Flag UI experiments that hide `story_only` badge as Fair Play defects.
- Win-trading for War Score remains exploit (rules/13) — not solvable by shop.

---

## 6. Godot notes

- Centralize copy in `localization/freemium.csv` or TranslationServer keys above.
- Gate widgets read subscription + achievement flags from account service / local mock.
- Shop item resource: `product_kind: cosmetic | convenience | story | quota` — no `power` enum value.

---

## 7. Vertical-slice minimum

- One cosmetic purchase mock
- One premium story quest with badge
- Token budget label on Prompt Studio placeholder
- Voice lock string visible when locked

---

*Monetization UI source of truth; skill §5 is the short form.*
