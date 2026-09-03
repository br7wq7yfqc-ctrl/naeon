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
| 3 | Ship as place (interior, seats, multi-crew) | `InteriorDirector` / `InteriorGenerator`; Seat; F seat→pilot; MC-A `CrewSeat`; MC-B gunner label; MC-C engineer seat; MC-D scanner seat; SN-B hull SoftNet | seat↔pocket↔hatch EVA; двери ведут в карман/EVA; **MC-A** first crew seat (F/I same pocket); **MC-B** `GUNNER` label; **MC-C** `ENGINEER` third seat, HUD CREW n/3; **MC-D** `SCANNER` fourth seat, HUD CREW n/4; **SN-B** second local viewer on seated hull sees SoftNet visual hull/pilot puppet (host Pulse/occupy/thrust; no second hull) | — | фейковые двери |
| 4 | Ship engineering (power/cool/life, component HP) | модульный hull + `ShipModule` (engine/weapon/shield/cargo/extractor); hull-crit recover; `SoftShipSystems` buses | модули HP (integrity→thrust/weapon/shield); hull HP; шины power/cool/life живы (overdraw/overheat = soft sag); hull LS = IN-B soft | — | pay-to-repair |
| 5 | Cargo / tractor / dock | `CargoHold` + `CargoRamp`; unnamed pads | occupy dock: 1 unit pad↔hold; Knowledge подписывает crate; 3 пада/тело + один unnamed силуэт; **ST-J** pad hangar stub; **ST-K** orbital hangar stub on `PlayerOrbitalStation`; **ST-I** pad storage; **ST-M** orbital storage on that same cluster | пады unnamed до pin каталога | трактор-клон; SITE_* mint |
| 6 | On-foot FPS | `SurfaceWalker` EVA + Pulse | TPS на сфере, snap, Pulse по dummy после EVA; **PV-A** host-authority rival dummy на occupied unnamed pad (Pulse 11 both ways) | полировка / больше FPS later | SC armor-meta |
| 7 | Zero-G EVA | `eva_mode` + fuel + tether; всё в ARK | zero-G у корпуса (не грунт); fuel+tether; грунт SurfaceWalker | полировка; всё ещё ARK | вторая система |
| 8 | Scanning / radar / ping | `soft_scan`; `SoftKnowledge`; `SoftScanCache`; HUD radar | метки / intel; V на паде; **KR-A** Knowledge Rank 0–4 HUD label from lifetime mastery | Knowledge может подписать (soft) | rarer fill; +DPS от скана |
| 9 | Contracts / loops | SessionObjectives; `ContractBoard` | Q-A one pad template; Q-B one alliance-shared occupy/logistics; Q-C optional Learning Node; Q-D NPC offers same Q-A board id; Q-E `scan_extractor` on the same board | campaigns later | story=power |
| 10 | Industry | RBE / biomass / Contribution / `Extractor` / `ResourceNode` / pad harvest | ST-A habitat; ST-B extractor + HUD Contribution; ST-C print one catalog module at pad bench; ST-D hangar queue on catalog carrier; ST-E player orbital cluster (dock + habitat); ST-F CX↔GR owner swap (theme + services, same-tier numbers); **DO-A** contested CX↔GR transition on one occupied unnamed pad (SoftKnowledge CONTESTED / CYBERNEX / GROT); **DO-B** same contested grammar on the existing `PlayerOrbitalStation` cluster (ST-E/ST-G stay); **ST-J** pad hangar stub; **ST-K** orbital hangar stub on that same cluster (ST-E/ST-G/ST-J stay); **ST-L** orbital defense turret on that same cluster (ST-E/ST-G/ST-H/ST-K stay; Pulse 11); **ST-M** orbital storage on that same cluster (ST-E/ST-G/ST-I/ST-K/ST-L stay); **BR-A** Biomass Rank 0–4 HUD label from lifetime wallet; **CR-A** Contribution Rank 0–4 HUD label from lifetime wallet | — | P2W richer nodes |
| 11 | Refuel / repair / restock | пады; occupy-to-hold refill SCM/HOVER; GLB pump/tank как проп | заправка + медленный repair + locker restock (energy / Pulse) с occupy; Knowledge подписывает насос/локер, не скипает wait; empty ≠ hard lock | G1/G3 hyperdrive fuel later | paid skip |
| 12 | World composition | ARK authored (`StarSystemCatalog`); Nex-Prime / ROT-Hive / Shard-Moon; пояс authored | G0 layout жив; outposts = unnamed pads; `CityNightLights` ≠ город | пады unnamed; SITE_* позже из каталога; города ждут; погода после OS-B | сгенерированная галактика; SITE_* mint |
| 13 | Traffic / AI | dummy / pad guard / Clash bots | NPC can fly the existing loop (NP-A); occupy/harvest on unnamed pad (NP-B); player invites one NPC into the squad (NP-D); short offline pad/follow cycle (NP-F); two NPCs soft-alliance / raid or logistics intent (NP-E); **BT-A** pad-guard 3-state BT (patrol / engage Pulse / return); **BT-B** visitor 3-state BT (approach / hold / leave); **BT-C** gROT swarm 3-state BT (gather / pulse-engage / scatter-return-to-pad; 3 `CombatDummy`); **BT-D** Cybernex pack 3-state BT (gather / pulse-engage / scatter-return-to-pad; 3 `CombatDummy`); **FL-A** that visitor is one extra ST-A overlay fleet pip; **FL-B** a second SoftNet visual ally; **FL-C** a third SoftNet visual ally; **FL-D** a fourth SoftNet visual ally; **FL-E** a fifth SoftNet visual ally; **FL-F** a sixth SoftNet visual ally; **FL-G** a seventh SoftNet visual ally; **FL-H** an eighth SoftNet visual ally; **FL-I** a ninth SoftNet visual ally; **FL-J** a tenth SoftNet visual ally; **FL-K** an eleventh SoftNet visual ally; **FL-L** a twelfth SoftNet visual ally; **FL-M** a thirteenth SoftNet visual ally; **FL-N** a fourteenth SoftNet visual ally (cap 15 closes the 10–15 bar as SoftNet pips; `FLEET n/15`; host Pulse/occupy) | Clash density later | generated galaxy traffic |
| 14 | Combat | dummy + Clash/MOBA (нативно); бар Predecessor | TestArena / Aexion Clash / Turret; **PV-A** pad TPS PvP + **PV-B** seated-hull Space PvP + **PV-C** ST-A overlay Strategy PvP (same rival, not Clash); **AR-H** pad door → TestArena (not city-map); **SN-D** Clash SoftNet visual host puppet; **AR-K** session bench second catalog option; **AR-L** fifth AbilityKit (CX Lattice); **AR-M** sixth AbilityKit (GR Vein); **AR-N** seventh AbilityKit (CX Prism); **AR-O** eighth AbilityKit (GR Facet); **AR-P** ninth AbilityKit (CX Helix); **AR-Q** tenth AbilityKit (GR Coil); **AR-R** eleventh AbilityKit (CX Spire); **AR-S** twelfth AbilityKit (GR Thorn); **AR-T** minion-wave seed; **AR-U** XP/leveling seed; **AR-V** second-lane wave; **AR-W** third-lane wave; **AR-X** small jungle camp; **AR-Y** rewards pipeline seed; **AR-Z** matchmaking seed | AR-A…AR-Z **built**; **PV-A / PV-B / PV-C built**; **SN-D built**; **G5 закрыт** | cash-shop of power; Arena Commander |
| 15 | Medical / death | Infection/Firewall кап 5 + health; downed; hull-crit recover | кап 5 enforced; нет перманентной смерти | кап держать | cash-shop spawn |
| 16 | Inventory / persistence | `SoftSession` local-first; `CargoHold` | form/faction/layer + last action в `user://`; NP-F short offline cycle; **PC-A** pad/orbital player modules + ship across relaunch (SoftKnowledge COLONY / SHIP / PERSIST); **PC-B** ONE crate amount/slug for PadStorage / CargoHold (SoftKnowledge CRATE / CARGO / PERSIST) | hangar insurance later | insurance P2W |
| 17 | Social | `AllianceRanks` | ранги + soft permissions; NP-E two-NPC intent visible | Voice later | pay-to-rank |
| 18 | Map / nav | in-system pad pip (`GameHUD` radar) | пип пада жив | **G2 закрыт** | галактическая карта сейчас |
| 19 | Ground vehicles | `GroundVehicle.gd` rover | деплой с occupied unnamed пада, петля на Relief, обратно в CargoHold | hangar later | отдельный планетарный гараж-клон |
| 20 | Character / forms | формы NAEON = идентичность | Canine/Feline/Avian/Human; dual-theme | косметика only | форма = статы |
| 21 | Hacking / Infection | NAEON-native; `InfectionStatus` / Firewall / `ChannelController` | кап 5; Knowledge не множит урон; **HF-A** TPS + **HF-B** hull +1 / −1 | кап держать | Infection > 5; P2W hack |
| 22 | Tech budget | `FloatingOrigin`; chunk budget; одна система; 60 FPS MED | origin rebase 2.5 км; LOD/park far planets; MED target | OS-A дешёвый macro FBM; без второй noise-планеты | вторая система; voxel shell; 2-й шум-мир |

---

## Жёсткие отказы (все строки)

CIG copy · воксели · SITE_* mint · G2–G6 сейчас · P2W · Tripo dirt/rock/flora · вторая система · Planet Tech V5 · story=power · Knowledge→DPS · Infection>5.

---

## Что уже есть / что приближаем / что не делаем

| Класс | Факт репо |
|-------|-----------|
| Уже есть | SCM/HOVER/STALL/LAND, OpenSpace ARK, пады, EVA snap, Clash, Infection 5, Contribution, Alliance, pad pip, rover петля на Relief, local save, лимб + OS-B оболочка, OS-C подход 8 км, OS-D unnamed fill, OS-E PBR near read (CC0/fallback), OS-F lift/glide, OS-G силуэт, OS-H harness ритуала, ST-A strategy overlay + habitat, ST-B extractor + HUD Contribution, ST-C pad print bench, ST-D hangar queue, ST-E orbital cluster, ST-F CX↔GR owner swap, **DO-A** contested pad transition, **DO-B** contested orbital-station transition, ST-H pad turret, ST-K orbital hangar stub, **ST-L** orbital defense turret, **ST-M** orbital storage, SE-A hull power/cool/life buses, **PV-C** overlay Strategy PvP, **PC-A** SoftSession colony/ship persist, **PC-B** SoftSession crate/cargo persist |
| Приближаем | 3090 FPS / 5 мин soak (human gate) |
| Отказ | quantum сейчас, карта галактики, гейты-прыжки, арена-из-мира (G5), города, каталожные SITE_*, воксели, P2W |

Очередь кода: **SE-A built**. Headless PASS ≠ FPS PASS. Не G2.
