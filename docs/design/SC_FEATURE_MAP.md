# SC → NAEON: карта ролей (не клон)

**Версия:** 1.0  
**Дата:** 2026-08-17  
**Бенчмарк подхода:** [`OPEN_SPACE_SC_BENCHMARK.md`](OPEN_SPACE_SC_BENCHMARK.md)  
**Сшивка тела:** [`WORLD_FILL.md`](WORLD_FILL.md) §5  
**Clash нативен; бар арены — Predecessor/Paragon, не Arena Commander:** [`ARENA_PREDECESSOR_BENCHMARK.md`](ARENA_PREDECESSOR_BENCHMARK.md).  
**Каталог — дыры / очередь fill:** [`WORLD_FILL.md`](WORLD_FILL.md) §6 (не mint SITE_*).  

Likeness — **вся** фантазия SC (лететь, стыковаться, ходить, работать, драться, жить) в системах NAEON. Это не CIG и не Planet Tech V5. Новых именованных систем, городов и SITE_* пинов нет. Резидентная система одна: **ARK**.

Статус — по коду репо на 2026-08-17. Next = именованный OS-* / Phase / G / `wait`.

---

## Столпы

| # | Роль SC | Эквивалент NAEON | Сейчас | Next | Отказ |
|---|---------|------------------|--------|------|-------|
| 1 | Flight / IFCS (SCM, NAV/quantum, decoupled, gear, VTOL/hover, boost, fuel) | `ShipController` SCM / NAV / HOVER / STALL / LAND; `ShipFlightModel`; afterburn W+Shift; `ShipLandingGear` visual | SCM/NAV/HOVER/STALL/LAND живы; gear visual; decoupled нет; топливо — проп пада, не расход | G1 CRUISE **закрыт** (OS-C без сверхсвета); quantum / interdiction ждать G1/G3 | клон IFCS; G3 сейчас; P2W-топливо |
| 2 | Atmosphere / planet approach | бар OS-A…OS-H; шейдеры лимба/дымки | OS-A шов; OS-B оболочка; OS-C старт 8 км; OS-D unnamed fill; OS-E near read; OS-F lift/glide; OS-G силуэт; OS-H harness ритуала | 60 FPS / 5 мин soak на 3090 (human gate) | Planet Tech V5; воксельная оболочка |
| 3 | Ship as place (interior, seats, multi-crew) | `InteriorDirector` / `InteriorGenerator`; Seat; F seat→pilot | pocket + двери + Seat живы; multi-crew нет | после OS-A green; Phase 2 multi-crew | фейковые двери |
| 4 | Ship engineering (power/cool/life, component HP) | модульный hull + `ShipModule` (engine/weapon/shield/cargo/extractor); hull-crit recover | модули + hull HP; шины power/cool/life нет | модули HP после OS-A; life-support уже в pocket | pay-to-repair |
| 5 | Cargo / tractor / dock | `CargoHold` + `CargoRamp`; unnamed pads | hold + ramp scaffold; 3 пада/тело + один unnamed силуэт | пады unnamed до pin каталога | трактор-клон; SITE_* mint |
| 6 | On-foot FPS | `SurfaceWalker` EVA + Pulse | TPS на сфере, snap, combat | расширять **после OS-E** | SC armor-meta |
| 7 | Zero-G EVA | `eva_mode` + fuel + tether; всё в ARK | EVA у корабля/планеты; не zero-G | **после OS-H**, всё ещё ARK | вторая система |
| 8 | Scanning / radar / ping | `soft_scan`; `SoftKnowledge`; `SoftScanCache`; HUD radar | метки / intel; V на паде | Knowledge может подписать (soft) | rarer fill; +DPS от скана |
| 9 | Contracts / loops | SessionObjectives; Phase 3 Contract Board | boot-loop тексты; квестов нет | Phase 3; **миссии в этом PR не делать** | story=power |
| 10 | Industry | RBE / biomass / Contribution / `Extractor` / `ResourceNode` / pad harvest | добыча на occupied паде; Contribution | Phase 1.3 полировка | P2W richer nodes |
| 11 | Refuel / repair / restock | пады; GLB pump/tank как проп | визуал; функциональной заправки нет | пады; G1 топливо после OS-C | paid skip |
| 12 | World composition | ARK authored (`StarSystemCatalog`); Nex-Prime / ROT-Hive / Shard-Moon; пояс authored | G0 layout жив; outposts = unnamed pads; `CityNightLights` ≠ город | пады unnamed; SITE_* позже из каталога; города ждут; погода после OS-B | сгенерированная галактика; SITE_* mint |
| 13 | Traffic / AI | dummy / pad guard / Clash bots | бой и охрана пада | после читаемой планеты (OS-A/E) | generated galaxy traffic |
| 14 | Combat | dummy + Clash/MOBA (нативно); бар Predecessor | TestArena / Aexion Clash / Turret | AR-A…AR-C **built**; **G5 закрыт** | арена-магазин; Arena Commander |
| 15 | Medical / death | Infection/Firewall кап 5 + health; downed; hull-crit recover | кап 5 enforced; нет перманентной смерти | кап держать | cash-shop spawn |
| 16 | Inventory / persistence | `SoftSession` local-first; `CargoHold` | form/faction/layer в `user://` | hangar later | insurance P2W |
| 17 | Social | `AllianceRanks` | ранги + soft permissions | Voice later | pay-to-rank |
| 18 | Map / nav | in-system pad pip (`GameHUD` radar) | пип пада жив | **G2 закрыт** | галактическая карта сейчас |
| 19 | Ground vehicles | `GroundVehicle.gd` rover | деплой с пада, в CargoHold | **после OS-E** | отдельный планетарный гараж-клон |
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
| Уже есть | SCM/HOVER/STALL/LAND, OpenSpace ARK, пады, EVA snap, Clash, Infection 5, Contribution, Alliance, pad pip, rover, local save, лимб + OS-B оболочка, OS-C подход 8 км, OS-D unnamed fill, OS-E near read, OS-F lift/glide, OS-G силуэт, OS-H harness ритуала |
| Приближаем | 3090 FPS / 5 мин soak (human gate); zero-G (после честного OS-H на GPU) |
| Отказ | quantum сейчас, карта галактики, гейты-прыжки, арена-из-мира (G5), города, каталожные SITE_*, воксели, P2W |

Очередь кода: **OS-H built (harness)**. Headless PASS ≠ FPS PASS. Не G2.
