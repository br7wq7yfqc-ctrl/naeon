# Aexion Clash — бенчмарк арены (не клон Omeda / Epic)

**Версия:** 1.0  
**Дата:** 2026-08-17  
**Движок:** Godot 4.3  
**Дверь:** `MainMenu` → AEXION CLASH → `TestArena` (`ClashLanes` / `AexionClash` / `ClashMatchDirector`)  
**Likeness:** 3rd-person over-the-shoulder MOBA (Paragon / Predecessor) — **ролями** в Clash NAEON, не Arena Commander и не top-down Dota/LoL.

Clash — **нативный** слой NAEON. Бар подхода космоса: [`OPEN_SPACE_SC_BENCHMARK.md`](OPEN_SPACE_SC_BENCHMARK.md). Карта SC: [`SC_FEATURE_MAP.md`](SC_FEATURE_MAP.md).  
Пластины арены в ledger: `moba_arena`, `hexarena_moba_map_schematic`, `tower_iouter_mid_inhibi` — очередь в [`WORLD_FILL.md`](WORLD_FILL.md) §6, не mint SITE_*.

Это **не** клон карт Omeda/Epic, карточной колоды Paragon и не IP героев. Новых SITE_* и городов нет. G5 (Clash-из-мира) **закрыт**. G2–G6 не реализовывать. P2W запрещён. Knowledge — soft (подпись, не unique DPS). Infection — кап 5. story ≠ power.

**CODE арены не вытесняет OS-A.** Этот PR: карта SC + сшивка OS-A + этот план. Первый арена-код — только после OS-A green, срез AR-A.

---

## Столпы

| # | Роль Predecessor / Paragon | Эквивалент NAEON | Сейчас (репо) | Next | Отказ |
|---|----------------------------|------------------|---------------|------|-------|
| 1 | Камера / feel: OTS 3rd person, не top-down | `PlayerController` + `CameraPivot` в `TestArena`; спринт Shift | **AR-A:** OTS правое плечо, FOV 70, pitch −8° (clamp не RTS); спринт = Shift; **travel-mode нет** | feel lock; не named travel / герой | Dota-камера; клон travel-mode IP |
| 2 | Топология: 3 линии, jungle, river, вертикаль / jump pads | `ClashLanes` TOP/MID/BOT на полу ~60×60 | **3 линии** (не 2): +X cyan / 0 gold / −X magenta; jungle/river/pads **нет**; плоско | AR-D на том же футпринте TestArena | новая city-map; SITE_* mint |
| 3 | Структуры: towers / inhibitors / core | башни = live `Turret` 160 HP; nexus = prop | **AR-B:** OUTER×6 + MID×6 + INHIB×2 + CORE×2, все с HP (`Turret`); inhib = gate у ядра (не 3-й полный ряд); нет P2W-ремонта | AR-C волны; не city-map | P2W-ремонт башен |
| 4 | Objectives: camps / fangtooth / prime | claim beacons + lane pressure + tower-down | 3 Neutral beacon (occupy C/Hack); pressure 0..100; tower death +28 soft; WS cap 60/день | AR-C/D: лагеря wait; **не** story-power drop | unique DPS с босса; Knowledge→урон |
| 5 | Waves / minions | `CombatDummy` с `lane_spawn_table()` | разовый спавн 3–7 dummy (tier cap); **периодических волн нет** | AR-C: волны по линии | магазин-миньоны |
| 6 | Heroes / kits | `AbilityKitCatalog` + `AbilitySystem`; формы = идентичность | 2 фракционных кита × 4 слота (Pulse / Firewall\|Hack / Probe\|Surge / Form Cycle) | Phase 3: 4–8 китов; формы не rank-стат | P2W kits; форма = скрытый MMR |
| 7 | Items / cards | модули / blueprints NAEON, не колода Paragon | item shop **нет**; `CanonPlates` = identity sketches, не карты силы | AR-E: blueprint/module, не deck | cash-shop power; клон карт Epic |
| 8 | Vision / wards | `ClashRadar`; soft scan | радар всегда рисует форму; вард-предметов нет | wait или soft label; Knowledge не покупает вард | pay-to-ward |
| 9 | Draft / match | `ClashMatchDirector` + kill-to-5 / 3 lane objectives | матч в редакторе; драфта нет; вход из мира = **G5 закрыт** | драфт later; дверь = TestArena | Arena Commander; G5 сейчас |
| 10 | Net | SoftNet сейчас visual; Phase 2 server authority | puppets без combat authority; local-first | AR-F: 3v3 local, потом 5v5 | pay-rank matchmaking |

---

## Доказательная база (2026-08-17)

| Узел | Факт |
|------|------|
| `ClashLanes.gd` | 3 полосы; OUTER/MID/INHIB/CORE live `Turret`; `structure_table()` + `lane_spawn_table()` |
| `AexionClash.gd` | kills→5, pressure TOP/MID/BOT, soft WS, `SITE_TEST_ARENA_PILLAR` уже в LayerContext (не чеканить новый) |
| `ClashMatchDirector.gd` | K/D, banner, lane HUD; no P2W |
| `TestArena.gd` | дверь слоя; beacons Neutral; dummy по линиям |
| `AbilityKitCatalog.gd` | data-driven, costs из `EnergyEconomy` |
| `HeroFormCatalog.gd` | Canine/Feline/Avian/Human + лёгкие loco-числа — **не** rank; не усиливать |
| `docs/systems/AEXION_CLASH_SLICE.md` | бар уже назван Predecessor; non-goal: full lanes/items P2W |
| `docs/rules/13_MOBA_ARENA_INFLUENCE.md` | арена не флипает планету; daily WS 60 |
| Phase 3 план | 5v5/3v3, 6–8 heroes, jungle, items — **ещё не код** |

---

## Срезы AR-A…AR-F

Каждый срез playable сам. **Не начинать, пока OS-A зелёный** (космос читает одно тело). Арена не перехватывает очередь Open Space.

| ID | Роль | Сейчас | Когда код | Отказ |
|----|------|--------|-----------|-------|
| **AR-A** | OTS feel + 3 полосы читаются без top-down | **сделано:** OTS + те же 3 strips | этот срез | новая карта; named hero |
| **AR-B** | Структуры честные: tower → (inhibitor) → core | **сделано:** OUTER→MID→INHIB→CORE с HP | этот срез | pay-to-repair |
| **AR-C** | Волны миньонов по линиям | dummy once | после AR-B | P2W waves |
| **AR-D** | Jungle / river / вертикаль на **том же** футпринте | плоско 60×60 | после AR-C | SITE_* city-map |
| **AR-E** | 4–8 китов; предметы = modules/blueprints | 2 кита | Phase 3; после AR-A минимум | Paragon deck; форма=стат |
| **AR-F** | 3v3 local authority, затем 5v5 | SoftNet visual | Phase 2/3; G5 всё ещё закрыт | вход из мира сейчас |

---

## Жёсткие отказы

Клон Omeda/Epic карт · колода карт · IP героев · Arena Commander · top-down Dota · SITE_* mint · G5 сейчас · G2–G6 код · P2W · Infection>5 · story=power · Knowledge→DPS · новая арена в этом PR.

---

## Этот PR

AR-A only: OTS feel на существующем TestArena / ClashLanes. OS-A не трогать. Дверь: редактор / меню → AEXION CLASH → TestArena. AR-B…F не начинать.
