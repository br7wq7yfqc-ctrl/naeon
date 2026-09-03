# NAEON — базы, станции, стратегия (третий бар)

**Версия:** 1.0  
**Дата:** 2026-08-17  
**Движок:** Godot 4.7.2  
**Статус:** ST-I built (2026-09-02).  
**Очередь кода:** ST-I one pad storage after occupy. G2–G6 still locked.

Это **третий бар**: не полёт OPEN SPACE и не Clash.  
Подход космоса: [`OPEN_SPACE_SC_BENCHMARK.md`](OPEN_SPACE_SC_BENCHMARK.md) (OS-A…OS-H).  
Арена: [`ARENA_PREDECESSOR_BENCHMARK.md`](ARENA_PREDECESSOR_BENCHMARK.md) (AR-A…AR-G).  
Роли SC: [`SC_FEATURE_MAP.md`](SC_FEATURE_MAP.md).  
Длинный план: [`DEVELOPMENT_PLAN.md`](../../DEVELOPMENT_PLAN.md) §1.3 / Phase 3.  
NPC agency (NP-C после ST-A) + MMO HOLD: [`NPC_AGENCY.md`](NPC_AGENCY.md) · [`MMO_SERVERS.md`](MMO_SERVERS.md).

Один мир. Другая камера и ввод. Не вторая галактика.

---

## 1. Канон (не размывать)

- Нет P2W. Knowledge soft. Infection max 5. story ≠ power.
- Одна резидентная система: **ARK**, пока G2 закрыт.
- Не чеканить `SITE_*`. Не изобретать UUID каталога.
- Tripo только unique / фракция. Безымянный scatter (пад, мачта, ящик) — не легендарный сайт.
- Dual-theme CX lattice / GR biomass — через Dynamic Ownership, не второй `SITE_*`.
- Нет воксельной планеты. Нет Clash-из-мира (G5).
- Godot 4.7.2.

---

## 2. Честный статус (2026-08-17)

Слой стратегии **набросан** в старом плане (Phase 1.3, Phase 3) и **почти отсутствует** в играбельном OPEN SPACE / Clash.

| Узел | Факт репо | Это не |
|------|-----------|--------|
| `DEVELOPMENT_PLAN.md` §1.3 | habitat / extractor / turret, ноды, Contribution, RBE allocator; DoD «outpost + добыча + Contribution» | playable strategy overlay |
| Phase 3 | carriers seed (hangar + drones); Dynamic Ownership на 1–2 объектах; цикл Strategy → Space → TPS | код очереди hangar / print |
| `LayerContext.gd` | комментарий `Strategy \| Space \| TPS \| Arena` | `set_layer("Strategy")` нигде не зовётся; OpenSpace = Space/TPS, Clash = Arena |
| `BaseBuilder.gd` | стримит HQ-кластер (habitat, extractor, turret, beacon…) **или** P0: только `PadBaseController` | игрок не ставит один модуль |
| `P0Slice.ONE_PAD` | `true` → BaseBuilder идёт в controller-only | размещение зданий |
| `PadBaseController.gd` | occupy-to-hold, harvest → `GameManager.deposit_economy`, Contribution / Biomass, `swap_cluster_theme` | очередь постройки |
| `Extractor.gd` + `ResourceNode.gd` | сцена колонии; harvest + Contribution; живёт в `TestArena` | стратегия на теле OPEN SPACE |
| `Contribution.gd` | Resource: `add` / `spend` | аллокатор RBE как слой |
| `rules/22` | Extractor T1, Storage, turret, dock/pad, Factory/vat, Habitat, hangar seed | runtime-модули базы |
| `WORLD_FILL.md` §6 | ledger `colony` = **1** slug: `t1_resource_extractor` | lock-UUID (не выдумывать) |
| OS-D | `Pad_North` + `Pad_Approach` + `Pad_Flank`; unnamed; не `SITE_*` | легендарный пин |
| OS-G | `OutpostSilhouette` на `Pad_Approach`: мачта + habitat-прокси | своя база из модулей |
| `OpenSpace._spawn_orbital_stations` | 3× `colony/station_habitat_ring/…` у первого тела | **выкл.**: `P0Slice.ORBITAL_STATIONS = false` |
| Каталог кораблей | slug есть: `cybernex_capital_carrier`, `grot_capital_carrier`, `grot_drone_carrier`, `cybernex_mothership`, `grot_mothership` | hangar interior, очередь печати |
| `ShipModule` | HULL / ENGINE / WEAPON / SHIELD / CARGO / EXTRACTOR / SENSOR | модуль базы/станции |
| `StarSystemCatalog` | ARK: Aex, Nex-Prime, ROT-Hive, Shard-Moon; станций в данных нет | вторая система |
| Clash / OS бары | полёт и арена закрыты своими срезами | place / queue / logistics |

OS-G силуэт — WorldFill, не стратегия. Игрок его не ставит и не печатает.

---

## 3. Режим стратегии

Top-down или overlay на **уже загруженном** теле или станции в ARK. Не карта галактики (`M` = G2, закрыт). Не второй инстанс мира.

| Есть | Делает | Не делает |
|------|--------|-----------|
| Камера | выше, орто/крутой угол на пад / станцию / орбитальный кластер | не заменяет TPS и корабль |
| Ввод | курсор: поставить, очередь, логистика, владение | не IFCS, не OTS Clash |
| Слой | `LayerContext.set_layer("Strategy")` на том же теле | не `GalaxyCatalog` |
| Knowledge | soft-подпись yield / владельца (как V-scan пада) | не плотнее ноды, не уникальные модули |

Тот же мир. Выход — обратно в корабль или TPS. Контекст (quest / claim / cargo) по `rules/18`. Арена War Score не флипает базу сама (`rules/13`).

---

## 4. Поверхностные базы

Игрок собирает базу **из модулей** на unnamed паде или claimed dirt (occupy-to-hold). Не на легендарном пине.

| Модуль | Роль | Семя в репо |
|--------|------|-------------|
| Habitat | жильё, 0 боевых статов (`rules/22`) | путь `colony/colony_habitat/` в BaseBuilder / OS-G прокси |
| Extractor | съём с ноды → Contribution / Biomass | `Extractor.gd`; T1 в `rules/22` + `rules/15` (80–120); slug `t1_resource_extractor` |
| Turret | оборона структуры | **ST-H:** `PadDefenseTurret` via BaseBuilder after occupy. Clash `Turret.gd` stays TestArena OUTER / contest guard. |
| Pad | посадка, якорь перехода | OS-D пластины; `environments/landing_pad/` |
| Storage | объём, права альянса | **ST-I:** `PadStorage` via BaseBuilder after occupy. Cap 1 crate. Occupy dock ↔ ship `CargoHold`. |
| Hangar stub | техника / малый корабль | **ST-J:** `PadHangarStub` via BaseBuilder after occupy. Hatch/LAND stay on pad. Not ST-D `CarrierHangarQueue`. |

Тема CX / GR — `OwnershipData` + `swap_cluster_theme` / dual-mesh. Не второй `SITE_*`.

Безымянный пад — логистика, не квест и не легенда (`WORLD_FILL.md` §3). `PadBaseController` при пустом пине ставит уже каталожный `SITE_SPACE_TEST_PAD` — **не** плодить соседей.

---

## 5. Космические станции (свои)

Модульная станция игрока на **орбите authored-тела ARK** (Nex-Prime / ROT-Hive / Shard-Moon). Та же грамматика, где она держится.

| Модуль | Роль |
|--------|------|
| Dock | стыковка, pad-эквивалент |
| Habitat | жильё |
| Factory | верстак (c) в §6 |
| Defense | turret / harden, тот же tier-бюджет |
| Hangar | очередь / слот, не мобильный `SITE_*` |

Это не сгенерированный город (`CityNightLights` ≠ город). Не чеканить `SITE_*`. Не `OpenSpace._spawn_orbital_stations` как «своя станция» — тот код = безымянный проп, и он выключен.

`SITE_ARK_RING` уже в `SITE_PIN_CATALOG.md`. Своя станция **не** становится этим пином и не получает сестру.

---

## 6. Печать модулей

Factory печатает модули базы/станции. Три законных верстака:

| ID | Верстак | Сейчас | Условие |
|----|---------|--------|---------|
| (a) | NPC / authored станция или пад | пад occupy-to-hold; орбитальные пропы выкл. | не легенда, если строки нет в `SITE_PIN_CATALOG` |
| (b) | Hangar carrier / mothership | корпуса в каталоге; интерьеры later | масса / мощность, не мобильный `SITE_*` |
| (c) | Своя база/станция **уже с** factory | Factory/vat в `rules/22` | без factory — нет печати |

Логистика: RBE / Contribution (CX) или Biomass (GR) + физические ресурсы `rules/15`. Доставка на союзный узел. Потеря груза = 0 очков.

Нет cash-shop skip. Knowledge не дешевле таблиц `rules/15` и не открывает exclusive-модули.

---

## 7. Носители

Hangar + очередь на **один** модуль в ST-D. Лимит — mass / power корпуса (`ShipModule.mass`, `power_draw`), не «станция в полёте».

Каталог (slug, без новых UUID): `cybernex_capital_carrier`, `grot_capital_carrier`, `grot_drone_carrier`, `cybernex_mothership`, `grot_mothership`. Phase 3 seed: hangar + drones/fighters. Интерьеры hangar — later (`InteriorGenerator` = pocket, не верстак).

Не чеканить `SITE_*` на корпус.

---

## 8. NPC-станции

Авторский пин **или** безымянный логистический хаб.

| Вид | Законно | Незаконно |
|-----|---------|-----------|
| Unnamed пад / выключенный habitat-ring | купить / напечатать модуль | назвать легендой |
| Строка уже в `SITE_PIN_CATALOG` | сервис на существующем ID | новый `SITE_*` «под хаб» |
| OS-G силуэт | читаемость с орбиты | верстак, своя база, пин |

Игрок печатает здесь по §6(a). Владение меняет тему и список услуг (`rules/12`, `rules/03`), не бюджет тира.

---

## 9. Срезы ST-A … ST-I

Каждый срез playable сам. ST-A built 2026-08-22. ST-B built 2026-08-27. ST-C built 2026-08-27. ST-D built 2026-08-27. ST-E built 2026-08-27 (`PlayerOrbitalStation`: dock + habitat on Nex-Prime orbit). ST-F built 2026-08-27 (`flip_cluster_owner` on the occupied unnamed pad). ST-G built 2026-08-28 (factory in that same player cluster; bench (c) print of one catalog module). ST-H built 2026-09-01 (one pad turret via `BaseBuilder.place_pad_turret` after occupy; not Clash `Turret.gd`). ST-I built 2026-09-02 (one pad storage via `BaseBuilder.place_pad_storage` after occupy; one crate; occupy dock ↔ ship `CargoHold`). ST-J built 2026-09-02 (one pad hangar stub via `BaseBuilder.place_pad_hangar_stub` after occupy; hatch/LAND stay on pad; not ST-D carrier hangar).

| ID | Роль | Семя | DoD | Отказ |
|----|------|------|-----|-------|
| **ST-A** | Strategy-камера + **один** модуль на unnamed паде | **built:** `StrategyOverlay` (B) / `BaseBuilder.place_player_habitat`; **FL-A/B/C/D/E/F/G/H** fleet pips (cap 9; `FLEET n/9`) | overlay на Nex-Prime; habitat на `Pad_North` / `Pad_Approach` / `Pad_Flank`; корабль и TPS живы; восемь allied SoftNet/visitor pips; click ≠ combat | вторая галактика; mint `SITE_*`; 10–15 ships |
| **ST-B** | Extractor + видимый Contribution | **built:** `PadBaseController` harvest; `Extractor.bind_pad`; HUD stack | occupy → добыча → число на HUD; Knowledge только подпись | P2W-ноды; Knowledge→yield |
| **ST-C** | Печать модуля на паде / NPC-верстаке | **built:** `PadPrintBench`; `rules/12`, `rules/15`, §6(a) | списать Contribution/Biomass; получить **один** модуль | cash-shop skip |
| **ST-D** | Очередь на носителе (один модуль) | **built:** `CatalogCarrier` + `CarrierHangarQueue`; catalog slugs; Phase 3 hangar seed | очередь в hangar; упёрлась в mass/power | мобильный `SITE_*` |
| **ST-E** | Своя орбитальная станция ≥2 модулей | **built:** `PlayerOrbitalStation` dock+habitat на орбите Nex-Prime; грамматика §5 | два модуля в одном кластере; не город | mint `SITE_*`; 2-я система |
| **ST-F** | Смена владельца CX↔GR на одной базе | **built:** `PadBaseController.flip_cluster_owner`; `swap_cluster_theme`; `OwnershipData` | визуал + услуги, те же числа тира | второй `SITE_*`; арена-флип |
| **DO-A** | Contested переход CX↔GR на одном occupied unnamed паде | **built:** `start_contested_transition` / `advance_contested_transition`; `OwnershipData` + `OwnershipComponent` + `ContestedRing`; SoftKnowledge `CONTESTED` / `CYBERNEX` / `GROT` | визуал + метр contest; host authority | HyperGate G4; galaxy transforms; P2W |
| **DO-B** | Contested переход CX↔GR на существующем player orbital cluster | **built:** `PlayerOrbitalStation.start_contested_transition` / `advance_contested_transition`; same `OwnershipData` / `OwnershipComponent` / `ContestedRing` as DO-A; SoftKnowledge `CONTESTED` / `CYBERNEX` / `GROT` | ST-E dock+habitat stay; ST-G factory stays; host authority | второй пад; galaxy transforms; P2W |
| **ST-G** | Своя factory + печать (c) | **built:** factory on `PlayerOrbitalStation`; `PadPrintBench.print_one_factory_module`; `rules/15` | factory в том же кластере; списать Contribution/Biomass; **один** модуль; без factory — отказ | cash-shop skip; mint `SITE_*`; ST-E = 3 модуля |
| **ST-H** | Один turret на occupied unnamed паде | **built:** `BaseBuilder.place_pad_turret` / `PadDefenseTurret` after occupy | turret с HP; Pulse 11 по PV-A rival / BT-A range; overlay B жив; ST-A/B stay; не Clash OUTER | Clash `Turret.gd`; mint `SITE_*`; P2W repair; permadeath |
| **ST-I** | Один storage на occupied unnamed паде | **built:** `BaseBuilder.place_pad_storage` / `PadStorage` after occupy | storage держит **один** crate; occupy dock ↔ ship `CargoHold`; overlay B жив; ST-A/B/H stay; Knowledge labels; mass/value stay | второй ship `CargoHold`; mint `SITE_*`; Clash; P2W |
| **ST-J** | Один hangar stub на occupied unnamed паде | **built:** `BaseBuilder.place_pad_hangar_stub` / `PadHangarStub` after occupy | hatch/LAND на пад (тот же OpenSpace); overlay B жив; ST-A/B/H/I stay; не ST-D carrier hangar | `CarrierHangarQueue`; mint `SITE_*`; rover spawn; MainMenu |

---

## 10. Жёсткие отказы

| Отказ | Почему |
|-------|--------|
| P2W-печать быстрее / skip очереди | столп: нет P2W |
| Knowledge-gated exclusive-модули | Knowledge soft |
| Чекан `SITE_*` / новый UUID | каталог — enum |
| Вторая резидентная система | G2 закрыт |
| Воксельная планета | Analytic Relief |
| Clash-из-мира (G5) | арена нативна в `TestArena` |
| Силуэт OS-G / unnamed scatter = легенда | WorldFill ≠ pin |
| Свой кластер = новый `SITE_*` | ownership, не каталог |
| Носитель = мобильный pin | hangar + mass/power |
| Замена TPS / корабля стратегией | тот же мир, другой ввод |

---

## 11. Очередь

| Сейчас | Дальше |
|--------|--------|
| ST-I один storage на occupied unnamed паде | — |
| ST-H один turret на occupied unnamed паде | **built** |
| ST-G своя factory + печать (c) в player cluster | **built** |
| ST-F смена владельца CX↔GR на одной базе | **built** |
| DO-A contested переход CX↔GR на occupied unnamed паде | **built** |
| DO-B contested переход CX↔GR на PlayerOrbitalStation | **built** |
| NP-C | **built** — NPC ставит один модуль |
| G2–G6 | закрыты |

Не открывать G2 «чтобы была карта стратегии». Overlay живёт на загруженном теле ARK.
