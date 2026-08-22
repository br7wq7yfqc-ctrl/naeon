# SC → NAEON: карта ролей (не клон)

**Версия:** 1.0  
**Дата:** 2026-08-17  
**Бенчмарк подхода:** [`OPEN_SPACE_SC_BENCHMARK.md`](OPEN_SPACE_SC_BENCHMARK.md)  
**Сшивка тела:** [`WORLD_FILL.md`](WORLD_FILL.md) §5  
**Clash нативен; бар арены — Predecessor/Paragon, не Arena Commander:** [`ARENA_PREDECESSOR_BENCHMARK.md`](ARENA_PREDECESSOR_BENCHMARK.md).  
**Стратегия — третий бар, не Clash и не полёт OPEN SPACE:** [`BASE_STATION_STRATEGY.md`](BASE_STATION_STRATEGY.md).  
**Каталог — дыры / очередь fill:** [`WORLD_FILL.md`](WORLD_FILL.md) §6 (не mint SITE_*).  
**NPC agency + MMO HOLD:** [`NPC_AGENCY.md`](NPC_AGENCY.md) (NP-A…NP-F; боты ≠ agency) · [`MMO_SERVERS.md`](MMO_SERVERS.md) (Phase 3 HOLD; 10k CCU; не netcode / не G5).  

Likeness — **вся** фантазия SC (лететь, стыковаться, ходить, работать, драться, жить) в системах NAEON. Это не CIG и не Planet Tech V5. Новых именованных систем, городов и SITE_* пинов нет. Резидентная система одна: **ARK**.

Статус — по коду репо на 2026-08-17. Next = именованный OS-* / Phase / G / `wait`.

---

## Столпы

| # | Роль SC | Эквивалент NAEON | Сейчас | Next | Отказ |
|---|---------|------------------|--------|------|-------|
| 1 | Flight / IFCS (SCM, NAV/quantum, decoupled, gear, VTOL/hover, boost, fuel) | `ShipController` SCM / NAV / HOVER / STALL / LAND; `ShipFlightModel`; afterburn W+Shift; `ShipLandingGear` (G, pad LAND gate) | SCM/NAV/HOVER/STALL/LAND живы; gear down нужен для чистого LAND на unnamed pad (G; SCM default up); HOVER у пада автосброс (OS-H); decoupled нет; топливо SCM/HOVER расход; empty = limited thrust / no afterburn | G1 CRUISE **закрыт** (OS-C без сверхсвета); quantum / interdiction ждать G1/G3 | клон IFCS; G3 сейчас; P2W-топливо |
| 2 | Atmosphere / planet approach | бар OS-A…OS-H; шейдеры лимба/дымки | OS-A шов; OS-B оболочка; OS-C старт 8 км; OS-D unnamed fill; OS-E near read; OS-F lift/glide; OS-G силуэт; OS-H harness ритуала | 60 FPS / 5 мин soak на 3090 (human gate) | Planet Tech V5; воксельная оболочка |
| 3 | Ship as place (interior, seats, multi-crew) | `InteriorDirector` / `InteriorGenerator`; Seat; F seat→pilot | seat↔pocket↔hatch EVA; двери ведут в карман/EVA; multi-crew нет | Phase 2 multi-crew | фейковые двери |
| 4 | Ship engineering (power/cool/life, component HP) | модульный hull + `ShipModule` (engine/weapon/shield/cargo/extractor); hull-crit recover | модули HP (integrity→thrust/weapon/shield); hull HP; шины power/cool/life нет | шины power/cool later; life-support уже в pocket | pay-to-repair |
| 5 | Cargo / tractor / dock | `CargoHold` + `CargoRamp`; unnamed pads | occupy dock: 1 unit pad↔hold; Knowledge подписывает crate; 3 пада/тело + один unnamed силуэт | hangar later; пады unnamed до pin каталога | трактор-клон; SITE_* mint |
| 6 | On-foot FPS | `SurfaceWalker` EVA + Pulse | TPS на сфере, snap, Pulse по dummy после EVA | полировка / больше FPS later | SC armor-meta |
| 7 | Zero-G EVA | `eva_mode` + fuel + tether; всё в ARK | zero-G у корпуса (не грунт); fuel+tether; грунт SurfaceWalker | полировка; всё ещё ARK | вторая система |
| 8 | Scanning / radar / ping | `soft_scan`; `SoftKnowledge`; `SoftScanCache`; HUD radar | метки / intel; V на паде | Knowledge может подписать (soft) | rarer fill; +DPS от скана |
| 9 | Contracts / loops | SessionObjectives; Phase 3 Contract Board | boot-loop тексты; квестов нет | Phase 3; **миссии в этом PR не делать** | story=power |
| 10 | Industry | RBE / biomass / Contribution / `Extractor` / `ResourceNode` / pad harvest | ST-A: overlay + one habitat on unnamed pad (0 combat); harvest still occupy-to-hold | ST-B extractor readout; ST-C print later | P2W richer nodes |
| 11 | Refuel / repair / restock | пады; occupy-to-hold refill SCM/HOVER; GLB pump/tank как проп | заправка + медленный repair + locker restock (energy / Pulse) с occupy; Knowledge подписывает насос/локер, не скипает wait; empty ≠ hard lock | G1/G3 hyperdrive fuel later | paid skip |
| 12 | World composition | ARK authored (`StarSystemCatalog`); Nex-Prime / ROT-Hive / Shard-Moon; пояс authored | G0 layout жив; outposts = unnamed pads; `CityNightLights` ≠ город | пады unnamed; SITE_* позже из каталога; города ждут; погода после OS-B | сгенерированная галактика; SITE_* mint |
| 13 | Traffic / AI | dummy / pad guard / Clash bots | NPC can fly the existing loop (NP-A); occupy/harvest on unnamed pad (NP-B); player invites one NPC into the squad (NP-D); short offline pad/follow cycle (NP-F); two NPCs soft-alliance / raid or logistics intent (NP-E) | Clash density later | generated galaxy traffic |
| 14 | Combat | dummy + Clash/MOBA (нативно); бар Predecessor | TestArena / Aexion Clash / Turret | AR-A…AR-E **built**; **G5 закрыт** | арена-магазин; Arena Commander |
| 15 | Medical / death | Infection/Firewall кап 5 + health; downed; hull-crit recover | кап 5 enforced; нет перманентной смерти | кап держать | cash-shop spawn |
| 16 | Inventory / persistence | `SoftSession` local-first; `CargoHold` | form/faction/layer + last action в `user://`; NP-F short offline cycle | hangar later | insurance P2W |
| 17 | Social | `AllianceRanks` | ранги + soft permissions; NP-E two-NPC intent visible | Voice later | pay-to-rank |
| 18 | Map / nav | in-system pad pip (`GameHUD` radar) | пип пада жив | **G2 закрыт** | галактическая карта сейчас |
| 19 | Ground vehicles | `GroundVehicle.gd` rover | деплой с occupied unnamed пада, петля на Relief, обратно в CargoHold | hangar later | отдельный планетарный гараж-клон |
| 20 | Character / forms | формы NAEON = идентичность | Canine/Feline/Avian/Human; dual-theme | косметика only | форма = статы |
| 21 | Hacking / Infection | NAEON-native; `InfectionStatus` / Firewall / `ChannelController` | кап 5; Knowledge не множит урон | кап держать | Infection > 5; P2W hack |
| 22 | Tech budget | `FloatingOrigin`; chunk budget; одна система; 60 FPS MED | origin rebase 2.5 км; LOD/park far planets; MED target | OS-A дешёвый macro FBM; без второй noise-планеты | вторая система; voxel shell; 2-й шум-мир |

---

## Жёсткие отказы (все строки)

CIG copy · воксели · SITE_* mint · G2–G6 сейчас · P2W · Tripo dirt/rock/flora · вторая система · Planet Tech V5 · story=power · Knowledge→DPS · Infection>5.

---

## Что уже есть / что приближаем / что не делаем

| Класс | Факт репо |
|-------|-----------|
| Уже есть | SCM/HOVER/STALL/LAND, OpenSpace ARK, пады, EVA snap, Clash, Infection 5, Contribution, Alliance, pad pip, rover петля на Relief, local save, лимб + OS-B оболочка, OS-C подход 8 км, OS-D unnamed fill, OS-E near read, OS-F lift/glide, OS-G силуэт, OS-H harness ритуала, ST-A strategy overlay + habitat |
| Приближаем | ST-B extractor; 3090 FPS / 5 мин soak (human gate) |
| Отказ | quantum сейчас, карта галактики, гейты-прыжки, арена-из-мира (G5), города, каталожные SITE_*, воксели, P2W |

Очередь кода: **ST-A built**. ST-B next. NP-C unblocked. Headless PASS ≠ FPS PASS. Не G2.
