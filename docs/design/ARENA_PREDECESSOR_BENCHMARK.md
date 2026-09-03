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
| 2 | Топология: 3 линии, jungle, river, вертикаль / jump pads | `ClashLanes` TOP/MID/BOT на полу ~60×60 | **3 линии** + **AR-D** camp + **AR-J** prime camp + **AR-X** small camp + **река** (`ClashRiver`) + **jump pads** (`ClashJumpPads`, короткий hop) на том же 60×60 | feel lock; не city-map | новая city-map; SITE_* mint |
| 3 | Структуры: towers / inhibitors / core | башни = live `Turret` 160 HP; nexus = prop | **AR-B:** OUTER×6 + MID×6 + INHIB×2 + CORE×2, все с HP (`Turret`); inhib = gate у ядра (не 3-й полный ряд); нет P2W-ремонта | AR-C волны; не city-map | P2W-ремонт башен |
| 4 | Objectives: camps / fangtooth / prime | claim beacons + lane pressure + tower-down | **AR-D** fangtooth + **AR-J** prime + **AR-X** small (все off-lane, не IP); damageable; soft contest; drop = soft WS, не unique weapon; Knowledge `CAMP` / `JUNGLE` / prime labels only | feel lock; **не** story-power drop | unique DPS с босса; Knowledge→урон |
| 5 | Waves / minions | `CombatDummy` с `lane_spawn_table()` | **AR-C + AR-T + AR-V + AR-W:** `ClashWaves` — периодические волны `CombatDummy` по линии; **AR-T seed** host-authority Pulse 11; **AR-V** opposite-lane mirror; **AR-W** remaining lane (MID); SoftKnowledge `WAVE` / `MINION`; march к OUTER; без магазина | feel lock | магазин-миньоны |
| 6 | Heroes / kits | `AbilityKitCatalog` + `AbilitySystem`; формы = идентичность | **AR-E + AR-L + AR-M + AR-N + AR-O + AR-P + AR-Q + AR-R + AR-S:** 12 китов × 4 слота (CX Nex/Grid/Lattice/Prism/Helix/Spire, GR Rot/Spore/Vein/Facet/Coil/Thorn; Pulse / utility / probe\|surge / Form Cycle) | feel lock; формы не rank-стат; toward 6–8 | P2W kits; форма = скрытый MMR |
| 7 | Items / cards | модули / blueprints NAEON, не колода Paragon | **AR-E + AR-K:** один `ClashModuleBench` (session `ShipModule.SENSOR` + catalog `CARGO` / Nex Hold); Knowledge только подпись; не колода | не shop of power | cash-shop power; клон карт Epic |
| 8 | Vision / wards | `ClashRadar`; soft scan | радар всегда рисует форму; вард-предметов нет | wait или soft label; Knowledge не покупает вард | pay-to-ward |
| 9 | Draft / match | `ClashMatchDirector` + kill-to-5 / 3 lane objectives | **AR-I:** CORE HP → 0 ends match (WIN/LOSS SoftKnowledge); soft WS +15/+3, daily cap 60; драфта нет; вход из мира = **G5 закрыт** | драфт later; дверь = TestArena | Arena Commander; G5 сейчас |
| 10 | Net | SoftNet сейчас visual; Phase 2 server authority | **AR-G:** 5v5 local host authority на том же 60×60; SoftNet visual puppets; 3v3 startable | feel lock; не cluster | pay-rank matchmaking |

---

## Доказательная база (2026-08-17)

| Узел | Факт |
|------|------|
| `ClashLanes.gd` | 3 полосы; OUTER/MID/INHIB/CORE live `Turret`; `structure_table()` + `lane_march_path()` |
| `ClashWaves.gd` | timed волны `CombatDummy` по линии; **AR-T** host-authority Pulse 11; **AR-V** opposite-lane seed; **AR-W** remaining-lane (MID) seed; SoftKnowledge `WAVE` / `MINION`; cap по GraphicsQuality; no P2W |
| `AexionClash.gd` | kills→5, pressure TOP/MID/BOT, soft WS, `SITE_TEST_ARENA_PILLAR` уже в LayerContext (не чеканить новый) |
| `ClashMatchDirector.gd` | K/D, banner, lane HUD; **AR-T** SoftKnowledge `WAVE` / `MINION`; **AR-U** SoftKnowledge `XP` / `LEVEL`; **AR-X** SoftKnowledge `CAMP` / `JUNGLE`; **AR-Y** SoftKnowledge `REWARD` / `TITLE`; **AR-Z** SoftKnowledge `MATCH` / `QUEUE` / `READY`; no P2W |
| `ClashCamp.gd` | три off-lane pit (AR-D fangtooth + AR-J prime + AR-X small); HP; soft contest announce; drop = soft WS (не оружие); small weaker than prime |
| `ClashRiver.gd` | река на том же 60×60: mid-crossing + каналы между полосами; terrain/read, не objective |
| `ClashJumpPads.gd` | 4 pad на том же 60×60; короткий hop walker/hero, не полёт и не корабль |
| `TestArena.gd` | дверь слоя; beacons Neutral; `ClashWaves` на полосах (**AR-T** WAVE/MINION + **AR-V** opposite + **AR-W** MID); `ClashCamp` + `ClashPrimeCamp` + `ClashSmallCamp`; один `ClashModuleBench` (AR-E SENSOR + AR-K CARGO); `ClashRiver`; `ClashJumpPads`; `ClashLocalMatch` 5v5 (3v3 startable); **AR-U** XP/LEVEL HUD; **AR-Y** REWARD/TITLE HUD; **AR-Z** MATCH/QUEUE/READY HUD |
| `ClashLocalMatch.gd` | 5v5 local host authority; 10 actors на TOP/MID/BOT + jungle; 3v3 startable; SoftNet visual puppets; G5 закрыт; **AR-U** match XP / level labels only |
| `AbilityKitCatalog.gd` | 12 китов (AR-E 4 + AR-L Lattice + AR-M Vein + AR-N Prism + AR-O Facet + AR-P Helix + AR-Q Coil + AR-R Spire + AR-S Thorn); costs из `EnergyEconomy`; `kit_for_faction` = прежний default |
| `HeroFormCatalog.gd` | Canine/Feline/Avian/Human + лёгкие loco-числа — **не** rank; не усиливать |
| `docs/systems/AEXION_CLASH_SLICE.md` | бар уже назван Predecessor; non-goal: full lanes/items P2W |
| `docs/rules/13_MOBA_ARENA_INFLUENCE.md` | арена не флипает планету; daily WS 60 |
| Phase 3 план | 6–8 heroes / items / matchmaking — **ещё не код**; jungle bite = AR-D + AR-J + AR-X; items-shop seed = AR-K; fifth kit = AR-L; sixth kit = AR-M; seventh kit = AR-N; eighth kit = AR-O; ninth kit = AR-P; tenth kit = AR-Q; eleventh kit = AR-R; twelfth kit = AR-S (12 kits toward 6–8); minion-wave seed = AR-T; XP/leveling seed = AR-U; second-lane wave = AR-V; third-lane wave = AR-W (3 lanes; 5v5 local = AR-G); small jungle camp = AR-X; rewards pipeline seed = AR-Y; matchmaking seed = AR-Z |

---

## Срезы AR-A…AR-Z

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
| **AR-J** | второй jungle objective (prime-класс) | **сделано:** один extra off-lane `ClashCamp` prime-роль на том же 60×60; soft contest; drop = soft WS; AR-D fangtooth stays; Knowledge только подпись | этот срез | unique weapon; SITE_*; city-map; leftover 5v5 soak |
| **AR-K** | session items-shop seed | **сделано:** вторая session option на том же `ClashModuleBench` (catalog `CARGO` / Nex Hold); SoftKnowledge HOLD; не колода Paragon; не cash-shop / P2W / unique weapon | этот срез | shop of power; клон карт Epic; leftover 5v5 soak |
| **AR-L** | fifth AbilityKit toward 6–8 | **сделано:** один extra кит CX Lattice на том же `AbilityKitCatalog` (Pulse / Lattice Seal / Lattice Probe / Form Cycle); SoftKnowledge LATTICE; prior 4 kits stay; AR-K bench stays | этот срез | P2W kits; форма=стат; leftover 5v5 soak |
| **AR-M** | sixth AbilityKit toward 6–8 | **сделано:** один extra кит GR Vein на том же `AbilityKitCatalog` (Pulse / Vein Claim / Vein Surge / Form Cycle); SoftKnowledge VEIN; prior 5 kits stay; AR-K bench stays | этот срез | P2W kits; форма=стат; leftover 5v5 soak |
| **AR-N** | seventh AbilityKit toward 6–8 | **сделано:** один extra кит CX Prism на том же `AbilityKitCatalog` (Pulse / Prism Seal / Prism Probe / Form Cycle); SoftKnowledge PRISM; prior 6 kits stay; AR-K bench stays | этот срез | P2W kits; форма=стат; leftover 5v5 soak |
| **AR-O** | eighth AbilityKit toward 6–8 | **сделано:** один extra кит GR Facet на том же `AbilityKitCatalog` (Pulse / Facet Seal / Facet Probe / Form Cycle); SoftKnowledge FACET; prior 7 kits stay; AR-K bench stays | этот срез | P2W kits; форма=стат; leftover 5v5 soak |
| **AR-P** | ninth AbilityKit toward 6–8 | **сделано:** один extra кит CX Helix на том же `AbilityKitCatalog` (Pulse / Helix Seal / Helix Probe / Form Cycle); SoftKnowledge HELIX; prior 8 kits stay; AR-K bench stays | этот срез | P2W kits; форма=стат; leftover 5v5 soak |
| **AR-Q** | tenth AbilityKit | **сделано:** один extra кит GR Coil на том же `AbilityKitCatalog` (Pulse / Coil Seal / Coil Probe / Form Cycle); SoftKnowledge COIL; prior 9 kits stay; AR-K bench stays | этот срез | P2W kits; форма=стат; leftover 5v5 soak |
| **AR-R** | eleventh AbilityKit toward 6–8 | **сделано:** один extra кит CX Spire на том же `AbilityKitCatalog` (Pulse / Spire Seal / Spire Probe / Form Cycle); SoftKnowledge SPIRE; prior 10 kits stay; AR-K bench stays | этот срез | P2W kits; форма=стат; leftover 5v5 soak |
| **AR-S** | twelfth AbilityKit toward 6–8 | **сделано:** один extra кит GR Thorn на том же `AbilityKitCatalog` (Pulse / Thorn Seal / Thorn Probe / Form Cycle); SoftKnowledge THORN; prior 11 kits stay; AR-K bench stays | этот срез | P2W kits; форма=стат; leftover 5v5 soak |
| **AR-T** | first Clash minion-wave seed | **сделано:** одна host-authority lane-волна `CombatDummy` на том же 60×60 (`ClashWaves`); Pulse 11; SoftKnowledge `WAVE` / `MINION`; Infection cap 5; не 13-й кит; 12 kits stay; FL-N FLEET 15/15 stays | этот срез | unique weapon; XP power; cash-shop; AbilityKit 13; leftover 5v5 soak |
| **AR-U** | first Clash XP/leveling seed | **сделано:** SoftKnowledge / HUD `XP` / `LEVEL` на том же 60×60 (`ClashLocalMatch` / `ClashMatchDirector`); level informational only — never DPS / Pulse / yield / kit unlock; Infection cap 5; не 13-й кит; 12 kits stay; FL-N FLEET 15/15 stays; AR-T wave stays | этот срез | Rank / XP = power; AbilityKit 13; FL-O; leftover 5v5 soak |
| **AR-V** | second Clash lane minion-wave | **сделано:** вторая host-authority lane-волна `CombatDummy` на opposite Clash lane (тот же `ClashWaves`); Pulse 11; SoftKnowledge `WAVE` / `MINION`; AR-T остаётся на своей полосе; Infection cap 5; не 13-й кит; 12 kits stay; FL-N FLEET 15/15 stays; AR-U XP/LEVEL informational | этот срез | unique weapon; XP power; AbilityKit 13; FL-O; leftover 5v5 soak |
| **AR-W** | third Clash lane minion-wave | **сделано:** третья host-authority lane-волна `CombatDummy` на remaining Clash lane MID (тот же `ClashWaves`); Pulse 11; SoftKnowledge `WAVE` / `MINION`; 3-lane seed complete; AR-T и AR-V остаются; Infection cap 5; не 13-й кит; 12 kits stay; FL-N FLEET 15/15 stays; AR-U XP/LEVEL informational | этот срез | unique weapon; XP power; AbilityKit 13; FL-O; leftover 5v5 soak |
| **AR-X** | small jungle camp | **сделано:** один extra off-lane `ClashCamp` (weaker than AR-J prime; AR-D fangtooth stays) на том же 60×60; soft contest; drop = soft WS; SoftKnowledge `CAMP` / `JUNGLE`; Pulse 11; Infection cap 5; не 4-я полоса; не 13-й кит; 12 kits stay; FL-N FLEET 15/15 stays; AR-T/V/W stay; AR-U XP/LEVEL informational | этот срез | unique weapon; 4th lane; AbilityKit 13; FL-O; leftover 5v5 soak |
| **AR-Y** | first Clash rewards pipeline seed | **сделано:** SoftKnowledge / HUD `REWARD` / `TITLE` на match-end (rules/13 cosmetic / title / lore); grant informational — never unique combat item / Pulse / yield / kit unlock; Infection cap 5; не 13-й кит; 12 kits stay; FL-N FLEET 15/15 stays; AR-X camp stays; AR-W wave stays; AR-V wave stays; AR-U XP stays | этот срез | unique combat item; Pulse power; AbilityKit 13; FL-O; leftover 5v5 soak |
| **AR-Z** | first Clash matchmaking seed | **сделано:** SoftKnowledge / HUD `MATCH` / `QUEUE` / `READY`; local host-authority queue/ready before 3v3/5v5; informational — never pay-rank / P2W skip / unique item / Pulse / kit unlock; Infection cap 5; не 13-й кит; 12 kits stay; FL-N FLEET 15/15 stays; AR-Y REWARD stays | этот срез | pay-rank queue; P2W skip; AbilityKit 13; FL-O; leftover 5v5 soak |

---

## Жёсткие отказы

Клон Omeda/Epic карт · колода карт · IP героев · Arena Commander · top-down Dota · SITE_* mint · G5 сейчас · G2–G6 код · P2W · Infection>5 · story=power · Knowledge→DPS · новая арена в этом PR.

---

## Этот PR

AR-Z: first Clash matchmaking seed on the existing TestArena / ClashDirector 60×60. SoftKnowledge / HUD `MATCH` / `QUEUE` / `READY` only. Local host-authority queue/ready before 3v3/5v5. Informational — never pay-rank matchmaking, P2W queue skip, unique combat item / Pulse / yield / kit unlock. Infection cap 5. Not a 13th kit. Not another fleet pip. AbilityKitCatalog stays at 12 (`cx_nex`…`gr_thorn`). FL-N FLEET 15/15 stays. AR-Y REWARD/TITLE stays. AR-X small jungle camp stays. AR-W third-lane wave stays. AR-A…AR-Y, река и jump pads не откатывать. G5 закрыт. Не mint SITE_*. Knowledge не меняет DPS. Дверь: меню → AEXION CLASH → TestArena.
