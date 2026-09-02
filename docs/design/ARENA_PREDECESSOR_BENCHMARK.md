# Aexion Clash — бенчмарк арены (не клон Omeda / Epic)

**Версия:** 1.0  
**Дата:** 2026-08-17  
**Движок:** Godot 4.7.2  
**Дверь:** `MainMenu` → AEXION CLASH → `TestArena` (`ClashLanes` / `AexionClash` / `ClashMatchDirector`)  
**Likeness:** 3rd-person over-the-shoulder MOBA (Paragon / Predecessor) — **ролями** в Clash NAEON, не Arena Commander и не top-down Dota/LoL.

Clash — **нативный** слой NAEON. Бар подхода космоса: [`OPEN_SPACE_SC_BENCHMARK.md`](OPEN_SPACE_SC_BENCHMARK.md). Карта SC: [`SC_FEATURE_MAP.md`](SC_FEATURE_MAP.md).  
Стратегия — третий бар, не Clash и не полёт OPEN SPACE: [`BASE_STATION_STRATEGY.md`](BASE_STATION_STRATEGY.md).  
NPC/Clash bots ≠ player agency; MMO/10k CCU HOLD: [`NPC_AGENCY.md`](NPC_AGENCY.md) · [`MMO_SERVERS.md`](MMO_SERVERS.md).  
Пластины арены в ledger: `moba_arena`, `hexarena_moba_map_schematic`, `tower_iouter_mid_inhibi` — очередь в [`WORLD_FILL.md`](WORLD_FILL.md) §6, не mint SITE_*.

Это **не** клон карт Omeda/Epic, карточной колоды Paragon и не IP героев. Новых SITE_* и городов нет. G5 (Clash-из-мира) **закрыт**. G2–G6 не реализовывать. P2W запрещён. Knowledge — soft (подпись, не unique DPS). Infection — кап 5. story ≠ power.

**CODE арены не вытесняет OS-A.** Этот PR: карта SC + сшивка OS-A + этот план. Первый арена-код — только после OS-A green, срез AR-A. **AR-I** — first Clash match-end + soft WS (rules/13) on the existing TestArena / ClashDirector.

---

## Столпы

| # | Роль Predecessor / Paragon | Эквивалент NAEON | Сейчас (репо) | Next | Отказ |
|---|----------------------------|------------------|---------------|------|-------|
| 1 | Камера / feel: OTS 3rd person, не top-down | `PlayerController` + `CameraPivot` в `TestArena`; спринт Shift | **AR-A:** OTS правое плечо, FOV 70, pitch −8° (clamp не RTS); спринт = Shift; **travel-mode нет** | feel lock; не named travel / герой | Dota-камера; клон travel-mode IP |
| 2 | Топология: 3 линии, jungle, river, вертикаль / jump pads | `ClashLanes` TOP/MID/BOT на полу ~60×60 | **3 линии** + **AR-D** camp + **река** (`ClashRiver`) + **jump pads** (`ClashJumpPads`, короткий hop) на том же 60×60 | feel lock; не city-map | новая city-map; SITE_* mint |
| 3 | Структуры: towers / inhibitors / core | башни = live `Turret` 160 HP; nexus = prop | **AR-B:** OUTER×6 + MID×6 + INHIB×2 + CORE×2, все с HP (`Turret`); inhib = gate у ядра (не 3-й полный ряд); нет P2W-ремонта | AR-C волны; не city-map | P2W-ремонт башен |
| 4 | Objectives: camps / fangtooth / prime | claim beacons + lane pressure + tower-down | **AR-D:** один jungle camp (fangtooth-роль, не IP); damageable; soft contest; drop = soft WS, не unique weapon; Knowledge только подпись | prime later; **не** story-power drop | unique DPS с босса; Knowledge→урон |
| 5 | Waves / minions | `CombatDummy` с `lane_spawn_table()` | **AR-C:** `ClashWaves` — периодические волны `CombatDummy` по линии; march к OUTER; без магазина | feel lock | магазин-миньоны |
| 6 | Heroes / kits | `AbilityKitCatalog` + `AbilitySystem`; формы = идентичность | **AR-E:** 4 кита × 4 слота (CX Nex/Grid, GR Rot/Spore; Pulse / utility / probe\|surge / Form Cycle) | feel lock; формы не rank-стат | P2W kits; форма = скрытый MMR |
| 7 | Items / cards | модули / blueprints NAEON, не колода Paragon | **AR-E:** один `ClashModuleBench` (session `ShipModule.SENSOR`); Knowledge только подпись; не колода | не shop of power | cash-shop power; клон карт Epic |
| 8 | Vision / wards | `ClashRadar`; soft scan | радар всегда рисует форму; вард-предметов нет | wait или soft label; Knowledge не покупает вард | pay-to-ward |
| 9 | Draft / match | `ClashMatchDirector` + kill-to-5 / 3 lane objectives | **AR-I:** CORE HP → 0 ends match (WIN/LOSS SoftKnowledge); soft WS +15/+3, daily cap 60; драфта нет; вход из мира = **G5 закрыт** | драфт later; дверь = TestArena | Arena Commander; G5 сейчас |
| 10 | Net | SoftNet сейчас visual; Phase 2 server authority | **AR-G:** 5v5 local host authority на том же 60×60; SoftNet visual puppets; 3v3 startable | feel lock; не cluster | pay-rank matchmaking |

---

## Доказательная база (2026-08-17)

| Узел | Факт |
|------|------|
| `ClashLanes.gd` | 3 полосы; OUTER/MID/INHIB/CORE live `Turret`; `structure_table()` + `lane_march_path()` |
| `ClashWaves.gd` | timed волны `CombatDummy` по линии; cap по GraphicsQuality; no P2W |
| `AexionClash.gd` | kills→5, pressure TOP/MID/BOT, soft WS, `SITE_TEST_ARENA_PILLAR` уже в LayerContext (не чеканить новый) |
| `ClashMatchDirector.gd` | K/D, banner, lane HUD; no P2W |
| `ClashCamp.gd` | один off-lane pit; HP; soft contest announce; drop = soft WS (не оружие) |
| `ClashRiver.gd` | река на том же 60×60: mid-crossing + каналы между полосами; terrain/read, не objective |
| `ClashJumpPads.gd` | 4 pad на том же 60×60; короткий hop walker/hero, не полёт и не корабль |
| `TestArena.gd` | дверь слоя; beacons Neutral; `ClashWaves` на полосах; один `ClashCamp`; один `ClashModuleBench`; `ClashRiver`; `ClashJumpPads`; `ClashLocalMatch` 5v5 (3v3 startable) |
| `ClashLocalMatch.gd` | 5v5 local host authority; 10 actors на TOP/MID/BOT + jungle; 3v3 startable; SoftNet visual puppets; G5 закрыт |
| `AbilityKitCatalog.gd` | 4 кита; costs из `EnergyEconomy`; `kit_for_faction` = прежний default |
| `HeroFormCatalog.gd` | Canine/Feline/Avian/Human + лёгкие loco-числа — **не** rank; не усиливать |
| `docs/systems/AEXION_CLASH_SLICE.md` | бар уже назван Predecessor; non-goal: full lanes/items P2W |
| `docs/rules/13_MOBA_ARENA_INFLUENCE.md` | арена не флипает планету; daily WS 60 |
| Phase 3 план | 6–8 heroes / full jungle / items — **ещё не код** (5v5 local = AR-G) |

---

## Срезы AR-A…AR-G

Каждый срез playable сам. **Не начинать, пока OS-A зелёный** (космос читает одно тело). Арена не перехватывает очередь Open Space.

| ID | Роль | Сейчас | Когда код | Отказ |
|----|------|--------|-----------|-------|
| **AR-A** | OTS feel + 3 полосы читаются без top-down | **сделано:** OTS + те же 3 strips | этот срез | новая карта; named hero |
| **AR-B** | Структуры честные: tower → (inhibitor) → core | **сделано:** OUTER→MID→INHIB→CORE с HP | этот срез | pay-to-repair |
| **AR-C** | Волны миньонов по линиям | **сделано:** timed `ClashWaves` + lane march | этот срез | P2W waves |
| **AR-D** | Jungle / river / вертикаль на **том же** футпринте | **сделано:** один off-lane camp + река + jump pads на том же 60×60 | этот срез | SITE_* city-map |
| **AR-E** | 4–8 китов; предметы = modules/blueprints | **сделано:** 4 кита + один session-bench | этот срез | Paragon deck; форма=стат |
| **AR-F** | 3v3 local authority, затем 5v5 | **сделано:** 3v3 local host + SoftNet visual puppets на том же 60×60 | 3v3 startable | вход из мира сейчас |
| **AR-G** | 5v5 local authority на тех же полосах + jungle | **сделано:** 10 actors (host Cybernex MID + 9 SoftNet visual puppets) на том же 60×60 | этот срез | вход из мира сейчас |
| **AR-H** | дверь из OpenSpace / occupied unnamed pad в Clash TestArena | **сделано:** `ClashDoor` на паде; F → TestArena; не city-map; G5 cluster закрыт | этот срез | G2 карта; leftover 5v5 soak |
| **AR-I** | match-end + soft world influence seed | **сделано:** CORE Turret HP → 0 ends 3v3/5v5; SoftKnowledge WIN/LOSS; SoftSession WS +15/+3, daily cap 60 → further wins cosmetics/title; не planet flip | этот срез | unique combat item; SITE_*; G5; leftover 5v5 soak |

---

## Жёсткие отказы

Клон Omeda/Epic карт · колода карт · IP героев · Arena Commander · top-down Dota · SITE_* mint · G5 сейчас · G2–G6 код · P2W · Infection>5 · story=power · Knowledge→DPS · новая арена в этом PR.

---

## Этот PR

5v5 local authority на том же 60×60 TestArena (host process; SoftNet visual puppets на bot-слотах ClashWaves/`CombatDummy`; jungle из AR-D). 3v3 остаётся startable. AR-A…AR-F, река и jump pads не откатывать. G5 закрыт. Не mint SITE_*. Knowledge не меняет DPS. Дверь: меню → AEXION CLASH → TestArena.
