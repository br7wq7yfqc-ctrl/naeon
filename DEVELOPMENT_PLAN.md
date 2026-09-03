# NAEON — Подробный план разработки по фазам (для build-сессий)

**Версия:** 2.4  
**Дата:** 2026-08-22  
**Основа:** CONCEPT.md v1.3  
**Движок:** Godot 4.7.2
**Принцип:** Local-first → Vertical Slices → Iterative Multiplayer → Platform + AI + Educational Systems  
**SC → NAEON (роли, не клон):** `docs/design/SC_FEATURE_MAP.md` · бар подхода OS-A…OS-H: `docs/design/OPEN_SPACE_SC_BENCHMARK.md` (OS-A…OS-H built; harness ритуала. 60 FPS / 5 мин = 3090 human gate).  
**Clash нативен; бар арены — Predecessor/Paragon, не Arena Commander:** `docs/design/ARENA_PREDECESSOR_BENCHMARK.md` (AR-A…AR-W; код арены не вытесняет OS-A).  
**Стратегия — третий бар, не Clash и не полёт OPEN SPACE:** `docs/design/BASE_STATION_STRATEGY.md` (ST-A…ST-J built: overlay, extractor, print, hangar, orbital cluster, CX↔GR owner swap, own factory print, one pad turret, one pad storage, one pad hangar stub).  
**Каталог — дыры (очередь, не новый catalog):** `docs/design/WORLD_FILL.md` §6. Ready-made fill → locked plates без GLB → пластины только на титульную дыру. Не mint SITE_*. Не capital-ship wave. OS-H harness built; не G2.  
**NPC agency + MMO HOLD:** `docs/design/NPC_AGENCY.md` (NP-A…NP-F + NP-C + NP-G ST-C print + NP-H ST-D hangar + **NP-I** ST-G factory built) · `docs/design/MMO_SERVERS.md` (Phase 3 HOLD; 10k CCU / ≥100 на шард без instance-split; нет netcode сейчас; не G5 / G2–G6).

**2026-09-01 — текущий бар PV-B (не Voice, не G2, не G5):**  
OS-A…OS-H built. G2–G6 закрыты. G1 CRUISE не открыт.  
ST-A…ST-J / IN-A…E / WF-A / Q-A / Q-B / Q-C / Q-D / Q-E / HF-A / HF-B / HF-C / PV-A built.  
PV-B: first Space PvP from the seated player hull — same host-authority pad rival `CombatDummy`, Pulse 11 both ways, win HP → 0, Infection cap 5, Knowledge labels only. TPS PV-A stays.  
Петля P0.6 на RTX 3090 жива — не ломать. llvmpipe ≠ FPS PASS.

---

## Общие принципы

- **Local-first**: всё работает offline / в локальной сети максимально долго. Yandex Cloud — только после устойчивого vertical slice.
- **Vertical Slice**: каждый значимый билд playable end-to-end.
- **Build-сессии**: 1–2 недельные спринты или 3–5 дневные интенсивные сессии.
- **Definition of Done**: код + playable в editor/export + low-end check + docs + PR.
- **Инструменты**: GitHub Issues/Projects, Docker Compose (Postgres/Redis), Godot Profiler, CI export checks.
- **Приоритет**: low-end optimization с Phase 0, data-driven systems (abilities, blueprints, quests), modular voice & AI providers.
- **Reuse**: Ability system → open-world TPS + MOBA + Hacking/Firewall. AI-bots → all layers. Prompt Studio / aiNEX → content + educational generation.

---

## Phase 0: Setup & Foundation
**Длительность:** 1–2 недели  
**Effort:** 4–8 чел/дн  
**Цель:** Рабочий скелет проекта + локальная инфраструктура.

### Deliverables
- Структура репозитория (`/godot`, `/docs`, `/docker`, `/scripts`)
- Godot 4.x проект, placeholder scenes (player, space, planet surface)
- Input + third-person camera skeleton
- Docker Compose: Postgres + Redis (+ MinIO)
- Godot headless + dedicated server scene + MultiplayerAPI/ENet skeleton
- Basic GitHub Actions export check
- README с local launch instructions

### DoD
- Headless server запускается
- Client подключается локально
- Docker up работает
- Проект открывается без ошибок

---

## Phase 1: Core Prototypes (TPS + Ship + Colony + Ability Foundation)
**Длительность:** 2–4 недели  
**Effort:** 16–25 чел/дн  
**Цель:** Три playable прототипа + data-driven Ability System (основа для combat, MOBA, Hacking/Firewall).

### 1.1 TPS Core + Ability System
- Character controller + 3–4 формы (Canine, Feline, Avian, Human-cyborg + gROT placeholders)
- AnimationTree + IK
- Data-driven Ability System (Resources): cooldown, cost, targeting, effects
- Базовый combat + 2–3 abilities
- Health / Stamina / inventory skeleton
- **DoD**: переключение форм, бой, abilities, 60+ FPS low-end

### 1.2 Space Ship Core
- Модульный корабль (Hull + engine/weapon/shield/cargo)
- Custom force physics, camera, basic combat
- **DoD**: экипировать, летать, стрелять, save/load

### 1.3 Colony / Strategy Core
**Бар:** `docs/design/BASE_STATION_STRATEGY.md` (ST-A…ST-I built). Overlay на загруженном теле ARK — не карта галактики.

- **ST-A (built):** `StrategyOverlay` (клавиша B) + один habitat на `Pad_North` / `Pad_Approach` / `Pad_Flank`. `LayerContext` = Strategy. Корабль и TPS живы после Esc/B. Не `SITE_*`.
- **ST-B (built):** видимый extractor на unnamed паде; occupy → harvest → Contribution на HUD. Knowledge только подпись.
- **ST-C (built):** печать одного catalog-модуля на паде / NPC-верстаке (`PadPrintBench`). Spend Contribution/Biomass (`rules/15`). Нет cash-shop skip. Knowledge ≠ cheaper tables.
- **ST-D (built):** очередь одного модуля в hangar catalog-носителя (`CatalogCarrier` / `CarrierHangarQueue`). Refuse если mass/power корпуса превышен. Не мобильный `SITE_*`. Интерьеры later.
- **ST-E (built):** своя орбитальная станция — два catalog-модуля (dock + habitat) в одном `PlayerOrbitalStation` на орбите Nex-Prime. Не город. Не `SITE_*`. `ORBITAL_STATIONS` выкл.
- Свои базы из модулей на unnamed pads / claimed dirt (occupy-to-hold): habitat (ST-A), extractor (ST-B), turret (ST-H), pad, storage (ST-I), hangar stub
- **ST-H (built):** one `PadDefenseTurret` on an occupied unnamed pad via `BaseBuilder.place_pad_turret` after occupy. HP; Pulse 11 at PV-A rival / BT-A range hostiles. Not Clash `Turret.gd` / OUTER 160. Overlay B still opens. ST-A habitat 0 combat + ST-B extractor stay. Knowledge labels only. No P2W repair. No `SITE_*`.
- **ST-I (built):** one `PadStorage` on an occupied unnamed pad via `BaseBuilder.place_pad_storage` after occupy. Holds **one** crate; occupy dock transfers pad-storage ↔ ship `CargoHold`. Knowledge labels only. Mass/value stay. Overlay B still opens. ST-A/B/H stay. Not a second ship hold. No `SITE_*`.
- Свои орбитальные станции из той же грамматики (dock, habitat, factory, defense, hangar) — орбита authored-тела, не `SITE_*` — ST-E built (два модуля)
- Печать модулей на трёх верстаках: (a) NPC/authored пад или станция — ST-C built; (b) hangar carrier/mothership — ST-D built; (c) своя factory — ST-G built
- Ресурсные ноды + extraction + локальный Contribution / RBE / Biomass — ST-B built
- **DoD ST-A:** overlay на Nex-Prime; модуль на unnamed паде; корабль и TPS живы
- **DoD ST-B:** occupy → добыча → число Contribution на HUD; Knowledge ≠ yield
- **DoD ST-C:** списать Contribution/Biomass; получить один модуль; cash-shop skip невозможен
- **DoD ST-D:** очередь в hangar (один модуль); упёрлась в mass/power; не мобильный `SITE_*`
- **DoD ST-E:** два модуля в одном player orbital cluster; не город; не mint `SITE_*`; не 2-я система
- **DoD ST-G:** factory в том же player cluster; списать Contribution/Biomass; один catalog-модуль; без factory — отказ; cash-shop skip невозможен
- **DoD ST-H:** occupy unnamed pad → one visible turret with HP; Pulse hits a pad hostile; destroyed turret ≠ permadeath; not Clash OUTER; overlay B opens; no `SITE_*`
- **DoD ST-I:** occupy unnamed pad → one visible storage; one-unit occupy dock pad-storage ↔ ship CargoHold; mass/value stay; overlay B opens; no `SITE_*`

### Cross
- Asset pipeline (GLTF + LOD), dark-neon materials, local save

**DoD Phase 1:** Три отдельных playable демо + гибкая ability system.

---

## Phase 2: Core Loop Integration + Multiplayer + AI-bots + MOBA Seed + Basic Hacking/Firewall
**Длительность:** 3–5 недель  
**Effort:** 22–35 чел/дн  
**Цель:** Единый local multiplayer loop + AI-боты + PvP + MOBA seed + асимметричные способности.

### Задачи
- Seamless / loading transition (ship → TPS)
- Multi-crew (2–4 игрока, роли) — **MC-A + MC-B + MC-C + MC-D built:** one extra `CrewSeat` on the player hull pocket; station role `gunner` is a SoftKnowledge / HUD label only; third seat `engineer` (HUD CREW n/3); fourth seat `scanner` (HUD CREW n/4; local-first, host authority; Pulse / Hack / thrust / yield stay)
- AI-bots (Cybernex animal-robots + gROT swarms) — BehaviorTree / Navigation — **BT-A built:** one pad-guard on an occupied unnamed pad (tiny 3-state GDScript BT: patrol / engage Pulse / return-to-pad; host authority; Pulse 11; Knowledge labels only; PV-A rival stays distinct; G5 closed; not Clash waves). **BT-B built:** one visitor `NpcPilot` (approach / hold / leave; hold keeps NP-B occupy/harvest; host authority; Pulse 11; BT-A stays; G5 closed; not Clash waves; not 10k CCU). **BT-C built:** one gROT swarm of 3 `CombatDummy` on an occupied unnamed pad (gather / pulse-engage / scatter-return-to-pad; host authority; Pulse 11 both ways; Infection cap 5; no permadeath; Knowledge labels only; BT-A / BT-B stay; PV-A rival stays distinct; G5 closed; not Clash waves; not TestArena; not AR leftover 5v5). **BT-D built:** one Cybernex animal-robot pack of 3 `CombatDummy` on an occupied unnamed pad (gather / pulse-engage / scatter-return-to-pad; host authority; Pulse 11 both ways; Infection cap 5; no permadeath; Knowledge labels only; BT-A / BT-B / BT-C stay; PV-A rival stays distinct; G5 closed; not Clash waves; not TestArena; not AR leftover 5v5)
- Basic Strategy / Space / TPS PvP — **PV-A built** (TPS on occupied unnamed pad) + **PV-B built** (seated hull on OpenSpace): same host-authority rival `CombatDummy` / SoftNet visual; Pulse 11 both ways; win = rival HP → 0; no permadeath; Infection cap 5; Knowledge labels only; G5 closed; no `SITE_*`
- RBE / Biomass pools + Contribution / Biomass Rank — **BR-A built:** Biomass Rank 0–4 from lifetime Biomass wallet (same `AllianceRanks` 0–4 family). SoftKnowledge / HUD label only (`BIOMASS` / `BIOMASS RANK` + rank number). **CR-A built:** Contribution Rank 0–4 from lifetime Contribution wallet (same ladder). SoftKnowledge / HUD `CONTRIB` / `CONTRIBUTION` + rank number. gROT stays `BIOMASS`. Rank ≠ yield / DPS / Pulse / Hack / print / exclusive modules. ST-B Contribution stays. No P2W. No `SITE_*`.
- **Hacking / Infection (gROT) + Nex-Firewall (Cybernex)** — первые версии abilities (TPS + simple Strategy) — **HF-A built** (unnamed-pad TPS) + **HF-B built** (seated hull / OpenSpace) + **HF-C built** (ST-A Strategy overlay, key B): +1 stack / cap 5 refuse / Firewall −1 (same AbilitySystem; pad-guard or pad InfectionStatus; Knowledge labels only)
- **MOBA Seed**: arena, 4 heroes (kits на ability system), minion waves, XP/leveling, basic items, win condition — **AR-I built (first bite):** CORE Turret HP → 0 ends the match on existing TestArena / ClashDirector (3v3 + 5v5). SoftKnowledge HUD `WIN` / `LOSS` only. SoftSession War Score +15 win / +3 loss; daily soft cap 60 → further wins cosmetics/title only. Not a unique permanent combat item. Not planet flip. AR-A…AR-H stay. Infection cap 5. Host authority. SN-D stays. `P0Slice.ORBITAL_STATIONS` stays false. **AR-K built (items-shop seed):** second session catalog option on the existing `ClashModuleBench` (AR-E SENSOR stays; catalog CARGO / Nex Hold). SoftKnowledge / HUD labels only. Not a Paragon deck. Not cash-shop / P2W / unique weapon. AbilityKitCatalog prior 4 kits stay. **AR-L built (fifth kit):** CX Lattice on the same catalog (Pulse / Lattice Seal / Lattice Probe / Form Cycle). SoftKnowledge / HUD `LATTICE` only. **AR-M built (sixth kit):** GR Vein (Pulse / Vein Claim / Vein Surge / Form Cycle). SoftKnowledge / HUD `VEIN` only. **AR-N built (seventh kit):** CX Prism (Pulse / Prism Seal / Prism Probe / Form Cycle). SoftKnowledge / HUD `PRISM` only. **AR-O built (eighth kit):** GR Facet (Pulse / Facet Seal / Facet Probe / Form Cycle). SoftKnowledge / HUD `FACET` only. **AR-P built (ninth kit):** CX Helix (Pulse / Helix Seal / Helix Probe / Form Cycle). SoftKnowledge / HUD `HELIX` only. **AR-Q built (tenth kit):** GR Coil (Pulse / Coil Seal / Coil Probe / Form Cycle). SoftKnowledge / HUD `COIL` only. **AR-R built (eleventh kit):** CX Spire (Pulse / Spire Seal / Spire Probe / Form Cycle). SoftKnowledge / HUD `SPIRE` only. **AR-S built (twelfth kit):** GR Thorn (Pulse / Thorn Seal / Thorn Probe / Form Cycle). SoftKnowledge / HUD `THORN` only. **AR-T built (minion-wave seed):** one host-authority lane wave of `CombatDummy` on existing TestArena / ClashDirector / `ClashWaves`. SoftKnowledge / HUD `WAVE` / `MINION` only. Pulse 11 both ways. Infection cap 5. Not a unique weapon, XP power, cash-shop, or 13th kit. AbilityKitCatalog stays at 12 (`cx_nex`…`gr_thorn`). FL-N FLEET 15/15 stays. **AR-U built (XP/leveling seed):** SoftKnowledge / HUD `XP` / `LEVEL` on the same Clash match. Level is informational only — never DPS / Pulse / yield / kit unlock / exclusive module. Rank / XP ≠ power. Infection cap 5. AbilityKitCatalog stays at 12. FL-N FLEET 15/15 stays. AR-T wave stays. **AR-V built (second-lane wave):** mirrors AR-T (host-authority `WAVE` / `MINION`, Pulse 11) on the opposite Clash lane. SoftKnowledge / HUD only. Infection cap 5. Not a 13th kit. Not XP power. Not another fleet pip. AbilityKitCatalog stays at 12. FL-N FLEET 15/15 stays. AR-T stays on its lane. AR-U XP/LEVEL stay informational. **AR-W built (third-lane wave):** remaining Clash lane (MID) gets the same host-authority `WAVE` / `MINION` Pulse 11 seed. Completes the 3-lane MOBA seed. AR-T and AR-V stay. AR-U XP/LEVEL stay informational. Not a 13th kit. AbilityKitCatalog stays at 12. FL-N FLEET 15/15 stays.
- Networking: server authority + prediction — **SN-A built:** second local viewer on occupied unnamed pad sees SoftNet visual `SurfaceWalker` puppet (optional PV-A rival pose). Host keeps Pulse / occupy. **SN-B built:** second local viewer seated on the player hull / OpenSpace sees SoftNet visual puppet of the host hull / pilot (or crew-seat pose). Host keeps Pulse / occupy / thrust. No second physical hull. **SN-C built:** second local viewer on ST-A Strategy overlay (key B) sees SoftNet visual puppet of the host pad / strategy actor (habitat / extractor / modules pose). Host keeps Pulse / occupy / Hack. No second physical pad modules. **SN-D built:** second local viewer in Clash (TestArena / ClashDirector) sees SoftNet visual puppet of the host (arena / Clash pose). Host keeps Pulse / Hack / form. No second physical Clash dummy. AR-H pad door stays as the legal Clash entry. Not ENet cluster. Not 10k CCU. G5 closed.

### DoD
- 2–4 игрока: multi-crew → высадка → колония / бой с AI
- Обе фракции playable
- Hacking vs Firewall работают в TPS
- MOBA 3v3/4v4 prototype playable
- Нет критических desync

---

## Phase 3: Vertical Slice + Full MOBA + Dynamic Ownership Seed + Basic Quests & Knowledge
**Длительность:** 4–6 недель  
**Effort:** 28–42 чел/дн  
**Цель:** Playable vertical slice одной системы + полноценный MOBA + первые динамические трансформации + квесты + Knowledge foundation.

### Deliverables
- Одна система (звезда + 3 тела на разных орбитах + пояс + якоря гейтов) — ARK. Планировка сделана в **Phase G0**; jump points включаются в G3–G4
- Persistent colonies / ships
- Fleet system (до 10–15 кораблей, flagship overlay) — **FL-A + FL-B + FL-C + FL-D + FL-E + FL-F + FL-G + FL-H + FL-I + FL-J + FL-K + FL-L + FL-M + FL-N built:** fourteen extra allied pips on ST-A Strategy overlay (FL-A existing pad-visitor `NpcPilot` / NP-A hull; FL-B / FL-C / FL-D / FL-E / FL-F / FL-G / FL-H / FL-I / FL-J / FL-K / FL-L / FL-M / FL-N SoftNet visual, same grammar; cap 15 = player + 14 closes the 10–15 bar as SoftNet pips; SoftKnowledge / HUD `FLEET n/15`; click/select ≠ combat; host Pulse / occupy; not 15 physical ships; not a second OpenSpace; not ENet)
- Carriers seed (hangar + drones/fighters) — очередь печати модуля: `docs/design/BASE_STATION_STRATEGY.md` ST-D **built**
- **Dynamic Ownership Transformation** (prototype): visual + mechanical swap Cybernex (Venus Project) ↔ gROT (biomass industrial) на 1–2 объектах — **DO-A built:** contested transition on one occupied unnamed pad (`Pad_North` / `Pad_Approach` / `Pad_Flank`); `OwnershipData.start_transition` / `advance_transition` + `OwnershipComponent` + `ContestedRing`; SoftKnowledge / HUD `CONTESTED` / `CYBERNEX` / `GROT` only; host authority; ST-F instant flip stays; not HyperGate G4; not galaxy-wide transforms. **DO-B built:** same grammar on the existing `PlayerOrbitalStation` cluster (ST-E dock+habitat stay; ST-G factory stays); not a second pad; not galaxy-wide
- Advanced AI-bots + NPC quest givers skeleton — **Q-D built** (same Q-A ContractBoard id on the pad visitor; not a second quest system)
- **Quest system foundation**: Contract Board, generated quests (templates), basic Alliance Quest Constructor — **Q-A + Q-B + Q-C + Q-D + Q-E built** (one board, occupy/harvest/deliver_crate/scan_extractor, one shared alliance occupy/logistics contract, one optional Learning Node, one NPC giver on the same board; not campaigns)
- **Knowledge & Skills foundation**: Knowledge Rank / Subject Mastery, optional Learning Nodes в квестах, soft combat integration (informational) — **Q-A + Q-B + Q-C + Q-D + Q-E built** (`SoftKnowledge` `quest_intel` / `alliance_intel` / `field_intel` labels only; never DPS / yield / exclusive modules). **KR-A built:** Knowledge Rank 0–4 from lifetime mastery (same `AllianceRanks` 0–4 family). SoftKnowledge / HUD label only (`KNOWLEDGE` / `KNOWLEDGE RANK` + rank number). BR-A stays. Rank ≠ yield / DPS / Pulse / Hack / print / exclusive modules.
- **MOBA Full Prototype**: 5v5/3v3, 6–8 heroes, lanes + jungle, items, objectives, rewards pipeline, basic matchmaking — **AR-I first bite built:** CORE destroy is the honest match-end on the existing 60×60; soft WS (rules/13) only. **AR-J prime camp bite built:** one extra off-lane prime-class `ClashCamp` on the same 60×60 (AR-D fangtooth stays); drop = soft WS only; SoftKnowledge labels. **AR-K items-shop seed built:** second session catalog option on the same `ClashModuleBench`. **AR-L fifth kit built:** CX Lattice on `AbilityKitCatalog`. **AR-M sixth kit built:** GR Vein. **AR-N seventh kit built:** CX Prism. **AR-O eighth kit built:** GR Facet. **AR-P ninth kit built:** CX Helix. **AR-Q tenth kit built:** GR Coil. **AR-R eleventh kit built:** CX Spire. **AR-S twelfth kit built:** GR Thorn (12 kits toward 6–8). **AR-T minion-wave seed built:** one host-authority lane `CombatDummy` wave on the same 60×60 (`ClashWaves`); SoftKnowledge `WAVE` / `MINION`; Pulse 11; Infection cap 5; not a 13th kit. **AR-U XP/leveling seed built:** SoftKnowledge / HUD `XP` / `LEVEL` on the same match; level informational only (never DPS / Pulse / yield / kit unlock); 12 kits stay; FLEET 15/15 stays. **AR-V second-lane wave built:** mirrors AR-T on the opposite Clash lane (host-authority Pulse 11; SoftKnowledge `WAVE` / `MINION`); AR-T stays on its lane; not a 13th kit. **AR-W third-lane wave built:** remaining Clash lane (MID) host-authority Pulse 11; SoftKnowledge `WAVE` / `MINION`; AR-T and AR-V stay; 3 lanes complete; not a 13th kit. Full 6–8 heroes / cash-shop / matchmaking still later. Not Voice. Not G2–G6.
- aiNEX basic (colony planner + MOBA builds + simple educational puzzle generation)
- Voice foundation (open-source STT/TTS path first)

### DoD
- Полный цикл Strategy → Space → TPS → back
- Ownership transformation работает на prototype objects
- Educational puzzle nodes + soft combat knowledge effects
- Playable 5v5/3v3 MOBA + rewards
- Low-end playable

---

## Phase G: Галактический слой — системы, гиперпространство, гейты, карта, вход в арену

**Детальный дизайн:** `docs/design/GALAXY_LAYER_PLAN.md` · **Ассеты:** `docs/design/TRIPO_ASSET_MANIFEST.md`
**Идёт параллельно Phase 3–4** — это то, что превращает «одну систему» в галактику.
**Цель:** планеты естественно разнесены вокруг звезды; система пересекается целиком; между системами летают гиперпрыжком или через гейты; есть карта и навигация; арена открывается из мира.

Каждая подфаза playable отдельно (принцип vertical slice).

### G0 — Планировка системы — **СДЕЛАНО (2026-08-15)**
- `StarSystemCatalog`: звезда в центре, тела на разных орбитах с углами и наклонениями
- Видимое тело звезды с короной; направление света на каждую планету — от её звезды
- Пояс астероидов берёт полосу из данных системы (до этого не вызывался вовсе)
- Якоря гейтов авторские, но намеренно **не** спавнятся: гейт-пропс без прыжка — это ровно та «реализованная на вид, но мёртвая» система, которую вычищал аудит
- **DoD выполнен:** тела на орбитах 3800 / 7400 / 11800, smoke зелёный

### G1 — CRUISE (внутрисистемный сверхсвет)
- Режим `4`: 200 м/с → 4 км/с, throttle-scaled, warp-визуал, сдвиг FOV
- **Mass lock** в радиусе `2.5 × (радиус тела + атмосфера)` — не даёт включить и сбрасывает
- Расход топлива 0.05/мин; выход по `4` или автоматически по mass lock
- В том же проходе орбиты умножаются на ~2.8 (внешний гейт ≈ 40 км): именно CRUISE делает такой масштаб играбельным
- **DoD:** от орбиты Nex-Prime до внешнего гейта меньше 30 с; mass lock отказывает у планеты; после выхода корабль управляем
- *Затрагивает:* `ShipController`, `ShipFlightModel`, `StarSystemCatalog`, `GameHUD`

### G2 — Данные галактики + карты
- `GalaxyCatalog` (системы, координаты в св. годах, связи), `NavState` (текущая система, маршрут, топливо, разведанное)
- Галактическая карта `M`: цвет по контролю фракций, связи гейтов, доступные прыжки, скрытое неразведанное, фильтры
- Карта системы `N`: звезда, орбиты, тела, станции, гейты
- Прокладка маршрута с **названной причиной** отказа для каждого участка
- **DoD:** маршрут из 3 участков строится и читается; ни один отказ не молчит
- *Затрагивает:* новое `scripts/galaxy/`, `scripts/ui/GalaxyMap.gd`, `LayerContext`

### G3 — Гипердвигатель и прыжки
- Новый тип модуля `HYPERDRIVE`, один хардпоинт; классы Relay-1/2, Nex-Lattice (CX), Spore-Fold (GR) — зеркальные, не сильнее
- Шесть состояний: TARGET → ALIGN (15°) → CHARGE → JUMP (3 с) → ARRIVAL у звезды → COOLDOWN
- Топливо, заправка на падах, буксир при нуле; отказы называют числа
- Дальность падает от массы груза
- **DoD:** ARK → ROT-Prime и обратно, все состояния видны, отказы по дальности и топливу названы
- *Затрагивает:* `ShipModule`, `ShipController`, новый `HyperdriveController`, `NavState`, `OpenSpace`

### G4 — Гейты
- `HyperGate`: кольцо, пилоны, ядро; состояния open / dormant / infected / contested
- Проход: влёт под 100 м/с → 2 с раскрутки → выход у парного гейта, целевая система стримится во время раскрутки
- Владение через `OwnershipData`; dormant будится каналом Probe; infected накладывает Infection (кап 5), Firewall снимает
- Переиспользуются уже отремонтированные системы: `InfectionStatus`, `ChannelController`, occupy-to-hold падов
- **DoD:** ARK → Helios Reach и обратно; пробуждение dormant; infected даёт стаки, Firewall чистит
- *Затрагивает:* новый `scripts/world/HyperGate.gd`, `StarSystemCatalog`, `OwnershipData`, `InfectionStatus`

### G5 — Арена из мира
- `ClashBeacon`: орбитальная станция и наземная арена у пада
- Подлёт на 300 м → `ENTER CLASH — hold F` (1.2 с, чтобы не входить случайно)
- Возврат **в ту же систему к тому же маяку** с сохранённым кораблём и грузом
- Soft-влияние матча ложится на пады этой системы через `apply_arena_influence`
- `M` освобождается под карту; `Tab` остаётся девелоперским шорткатом под F3
- **DoD:** матч с маяка ARK и возврат туда же; влияние видно на паде ARK
- *Затрагивает:* новый `scripts/world/ClashBeacon.gd`, `LayerContext`, `TestArena`, `OpenSpace`

### G6 — Контент и полировка
Остальные системы из лорного сида, сети гейтов по фракциям, interdiction, топливный скуп у звезды, буксир, фильтры и поиск на карте.

---

## Phase 4: Full Systems — Quests, Campaigns, Voice, Education, Social, Platform Hooks
**Длительность:** 4–6 недель  
**Effort:** 25–40 чел/дн  
**Цель:** Глубокие системы контента, социального взаимодействия, AI и образования.

### Задачи
- **Сюжетные кампании** (Cybernex «Awakening of NAEXOS» + gROT «Ascension of the Swarm») — первые 1–2 главы
- Полный Quest system: generated NPC quests, Alliance Quest Constructor, Premium narrative quests (story-only)
- **Educational Quests** с AI-генерируемыми головоломками как тестами (aiNEX)
- Полная soft-интеграция Subject Mastery в combat (все слои)
- **Voice stack**: Yandex SpeechKit / Alice + open-source providers (Whisper/Vosk/Piper/Silero), natural NPC dialogue, voice commands, alliance voice channels (Premium/achievements)
- Alliance social: hierarchy, permissions, shared resources/tasks, Communication Hubs
- Logistics + Transport Contracts + Carriers polish
- Crafting + full blueprints (включая decorations)
- Dynamic Ownership на большем числе объектов + contested transition states
- Account linking + Knowledge gates + Trust Score / Qualifications sync prototype
- Subscription flags + cosmetics pipeline
- Ranked MOBA + seasons + Trust Score sync

### DoD
- Кампании playable (первые главы)
- Educational quests + combat knowledge effects работают end-to-end
- Voice dialogue + commands (hybrid open/Yandex)
- Alliance hubs + voice channels
- Platform gates prototype
- No-P2W соблюдён

---

## Phase 5: Optimization, Scale Prep, Content Expansion & Polish
**Длительность:** 3–5 недель  
**Effort:** 18–30 чел/дн  
**Цель:** Готовность к closed alpha + подготовка Yandex Cloud + контент.

### Задачи
- Interest management / spatial partitioning
- Aggressive LOD, MultiMesh, animation compression, distant AI simplification
- Load testing (entities + MOBA instances + voice)
- Full star systems set (ARK, ROT-Prime, Helios Reach, Veil Reach, Forge Depths, Echo Ruins…) — Phase G6 наполняет `GalaxyCatalog` и сети гейтов
- More campaign chapters, generated content variety, educational tracks
- Balance pass (PvP, Hacking/Firewall, RBE vs Biomass, MOBA, soft knowledge effects)
- Terraform / IaC для Yandex Cloud
- Monitoring, anti-cheat basics, moderation tools for generated content
- Full low-end presets + graphics options
- Spectator / replay для MOBA
- UX polish (including educational UI, voice settings, ownership transition feedback)

### DoD
- Стабильная симуляция 50–100+ entities + multiple MOBA + voice
- Infra-as-code ready
- Closed alpha build
- Performance targets достигнуты

---

## Phase 6: Closed Alpha → Open Beta → Launch Prep
**Длительность:** ongoing  
**Цель:** Живой сервис + live-ops + полный контент.

- Deploy на Yandex Cloud
- Real NAEXOS.ONLINE API integration (Trust Score, Knowledge gates, skill exchange)
- Content expansion (больше систем, квестов, рас, MOBA maps/heroes, educational modules)
- Full monetization (Premium + tokens)
- Analytics, support tools, community events, MOBA tournaments
- Living history / global events pipeline
- Continuous balance и educational content updates

---

## Рекомендуемый порядок первых build-сессий (ориентир 12–16 недель)

| Сессия | Фокус | Главный результат |
|--------|-------|------------------|
| 1 | Phase 0 + TPS controller + Ability System | Playable form + 1–2 abilities |
| 2 | Ship physics + modules | Fly & shoot |
| 3 | Colony + resources + Contribution | Build outpost — бар `docs/design/BASE_STATION_STRATEGY.md` |
| 4 | Multi-crew + basic net | 2 players on one ship |
| 5 | AI-bots + TPS combat + Hacking/Firewall seed | Fight with/against AI + asymmetric abilities |
| 6 | Landing + PvP arena + Knowledge Rank foundation | Full local loop + soft knowledge |
| 7 | MOBA Seed (arena + 4 heroes + minions) — **AR-I first bite:** CORE→0 WIN/LOSS + soft WS | Playable 3v3/4v4 MOBA |
| 8–9 | Fleet + Carriers seed + Dynamic Ownership prototype + RBE | Vertical slice skeleton + transformable object |
| 10 | Quest system + Educational Nodes + aiNEX puzzles | Generated quests + learning tests |
| 11+ | Voice foundation + Alliance social + Campaigns seed + MOBA polish | Voice dialogue + social hubs + story start |

---

## Матрица рисков (топ)

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| CRUISE делает систему пустой | Средняя | Среднее | Mass lock заставляет реально подходить к телам; пояс, станции и гейты дают смысл внешней системе |
| Два способа перемещения путают | Средняя | Среднее | Разные роли: гейт фиксирован, бесплатен, оспариваем; прыжок свободен и стоит топлива. Карта подписывает каждый участок |
| Хитч при стриминге системы через гейт | Средняя | Высокое | Переиспользовать staggered-билдер `PlanetBody`; время раскрутки = бюджет стриминга; пады уже выгружаются при отлёте |
| Топливо превращается в рутину | Средняя | Среднее | Щедрый расход в CRUISE, бесплатная заправка на своих падах, буксир, который не даёт застрять |
| Netcode desync / lag | Высокая | Высокое | Server authority + prediction early |
| Scope creep (много систем) | Высокая | Высокое | Жёсткий vertical slice, reuse ability/AI systems |
| Performance (entities + MOBA + voice + transformation) | Средняя | Высокое | Interest management, LOD, separate instances, open-source voice first |
| Educational content quality / generation cost | Средняя | Среднее | Templates + curated knowledge base + rate limits + offline fallback |
| Voice latency / provider complexity | Средняя | Среднее | Modular providers, open-source first, hybrid mode |
| Ownership transformation visual complexity | Средняя | Среднее | Shader/material swap + gradual transition, start with few objects |
| Hacking/Firewall balance | Средняя | Высокое | Early playtests, strong counterplay, caps |
| Integration with NAEXOS.ONLINE delays | Средняя | Среднее | Full local mocks + browser gates |

---

## Следующие шаги прямо сейчас

1. Создать / обновить GitHub Project и Issues по Phase 0–1 (включая Ability System + Hacking/Firewall foundation).
2. Назначить owners на подсистемы (TPS/Abilities, Space/Carriers, Strategy/RBE, AI/Voice, Quests/Education, MOBA).
3. Провести Phase 0 build-сессию.
4. Ежедневно: short playtest + update Issues.
5. Параллельно вести TECHNICAL_ARCHITECTURE.md и GDD-секции (особенно Abilities, Knowledge, Voice, Dynamic Ownership).

---

*План живой. Обновляется по итогам каждой build-сессии. Актуальная версия CONCEPT.md — v1.2.*
