# NAEON — Alliance Permissions & Constructor UI Copy

**Version:** 0.1  
**Depends on:** rules/11 (ranks/powers), rules/10 (UI layer), rules/19 (freemium labels)  
**Languages:** EN baseline + RU keys  
**Constraint:** No harassment tools; no rank-bought combat power; voice still gated by 17/19

---

## 1. Rank labels

| Rank | EN (Cybernex) | EN (gROT) | Key |
|------|---------------|-----------|-----|
| 0 | Applicant | Drone | `ui.alliance.rank.0` |
| 1 | Member | Pack | `ui.alliance.rank.1` |
| 2 | Officer | Fang | `ui.alliance.rank.2` |
| 3 | Steward | Spine | `ui.alliance.rank.3` |
| 4 | Leader | Voice | `ui.alliance.rank.4` |

Cosmetic faction names only — powers mirrored (rules/11).

---

## 2. Permission matrix (object access)

UI columns: Dock/Enter · Deposit · Withdraw · Defenses · Claim/Abandon · Constructor target

| Permission | Default rank min | EN label | Key |
|------------|------------------|----------|-----|
| Dock / Enter | 1 | Dock & enter | `ui.alliance.perm.dock` |
| Storage deposit | 1 | Deposit to storage | `ui.alliance.perm.deposit` |
| Storage withdraw | 2 | Withdraw from storage | `ui.alliance.perm.withdraw` |
| Operate defenses | 2 | Operate defenses | `ui.alliance.perm.defenses` |
| Claim / Abandon | 3 | Claim or abandon | `ui.alliance.perm.claim` |
| Constructor target | 2 | Set constructor target | `ui.alliance.perm.constructor` |
| Pool policy | 3 | Edit pool policy | `ui.alliance.perm.pool` |
| Diplomacy | 4 | Diplomacy actions | `ui.alliance.perm.diplomacy` |
| Rank edit | 4 | Edit ranks | `ui.alliance.perm.ranks` |

Steward+ may tighten defaults; cannot grant rank 0 combat exclusives.

---

## 3. Constructor panel copy

| Element | EN | Key |
|---------|----|-----|
| Title | Constructor | `ui.alliance.constructor.title` |
| Template list | Allowed templates | `ui.alliance.constructor.templates` |
| Daily budget | Daily alliance budget | `ui.alliance.constructor.budget` |
| Reject harassment | Template not allowed — personal harassment blocked | `ui.alliance.constructor.reject_harass` |
| War template | Enemy Ownership objective (war state required) | `ui.alliance.constructor.war` |
| Rank gated | Requires Officer (Fang) or higher | `ui.alliance.constructor.rank_gate` |

---

## 4. Pool widgets

| Element | EN | Key |
|---------|----|-----|
| Contribution pool | Contribution pool | `ui.alliance.pool.contribution` |
| Biomass pool | Biomass pool | `ui.alliance.pool.biomass` |
| Cap notice | Daily transfer cap applies | `ui.alliance.pool.cap` |
| No power | Pools do not buy combat power | `ui.alliance.pool.no_power` |

---

## 5. RU short forms (mirror keys)

| Key | RU |
|-----|----|
| `ui.alliance.rank.0` | Кандидат / Дрон |
| `ui.alliance.rank.1` | Участник / Стая |
| `ui.alliance.rank.2` | Офицер / Клык |
| `ui.alliance.rank.3` | Смотритель / Хребет |
| `ui.alliance.rank.4` | Лидер / Голос |
| `ui.alliance.pool.no_power` | Пулы не покупают боевую силу |
| `ui.alliance.constructor.reject_harass` | Шаблон запрещён — личные преследования блокируются |

(Full RU table can expand in localization pack; keys stable.)

---

## 6. VS must-have UI

- Rank list with cosmetic names  
- Permission toggles for Steward+ on one claimable  
- Constructor template picker (2–3 templates) with budget number  
- Pool read-only for Member; deposit for Member+

---

## 7. Perf

Alliance roster virtualized if >50; no per-frame full rebuild (rules/25).

---

*UI copy authority for alliance hub / permissions.*
