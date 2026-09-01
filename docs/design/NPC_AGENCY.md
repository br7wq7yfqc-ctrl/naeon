# NAEON — агентность NPC (local-first до MMO)

**Версия:** 1.0  
**Дата:** 2026-08-18  
**Движок:** Godot 4.7.2  
**Статус:** NP-A…NP-F + NP-C + NP-G + NP-H + NP-I built. **Q-D this pass** (pad visitor offers the same Q-A ContractBoard id).  
**Код срезов:** NP-A flight · NP-B occupy/harvest · NP-C habitat · NP-D invite · NP-E soft alliance · NP-F offline · NP-G print · NP-H hangar · NP-I factory · **Q-D same board giver**. Не G2–G6. Не 10k CCU.

Запрос владельца (в план): NPC должны **полностью закрывать петлю живого игрока**, пока MMO-кластер не запущен — летать, делать все playable-действия, прогрессировать, ставить базы, собирать альянсы и рейды. Живые: отвечают игроку, меняются под его влияние, работают offline и в coop с друзьями. Игрок берёт NPC в отряд и сообщество. **ИИ NPC — подписка AI Agency:** платят за инициативу и диалог, **никогда** за HP / DPS / yield / уникальное оружие (это P2W, отказ). Кластер: [`MMO_SERVERS.md`](MMO_SERVERS.md) — HOLD до Phase 3.

Подход космоса: [`OPEN_SPACE_SC_BENCHMARK.md`](OPEN_SPACE_SC_BENCHMARK.md).  
Clash: [`ARENA_PREDECESSOR_BENCHMARK.md`](ARENA_PREDECESSOR_BENCHMARK.md).  
Стратегия (GPU-gate): [`BASE_STATION_STRATEGY.md`](BASE_STATION_STRATEGY.md).  
Роли SC: [`SC_FEATURE_MAP.md`](SC_FEATURE_MAP.md) столп 13.  
План: [`DEVELOPMENT_PLAN.md`](../../DEVELOPMENT_PLAN.md) Phase 2 «AI-bots».

---

## 1. Канон (не размывать)

- Нет P2W. Knowledge soft. Infection max 5. story ≠ power.
- Одна резидентная система: **ARK**, пока G2 закрыт.
- Не чеканить `SITE_*`. Не изобретать UUID каталога.
- Бесплатный dummy остаётся. Подписка не сильнее в бою и не скипает печать ST.
- SoftNet сейчас visual (`docs/systems/SOFT_NET.md`): без combat authority.
- Godot 4.7.2. Local-first: offline + LAN/coop, без Yandex Cloud.

---

## 2. Честный статус (2026-08-18)

**Боты есть. Полной замены игрока нет.** Phase 2 план («BehaviorTree / Navigation, fight with/against AI») — набросок, не слой.

| Узел | Факт репо | Это не |
|------|-----------|--------|
| `PadTraffic.gd` | 1 pad-guard `CombatDummy` + visitor `ShipController`/`NpcPilot` (NP-A flight, NP-B occupy/harvest, NP-C habitat, NP-G ST-C print, NP-H ST-D hangar, NP-I ST-G factory, NP-D squad invite, NP-F short offline pad/follow, NP-E soft alliance / raid-or-logistics intent, **Q-D same Q-A ContractBoard id**) + surface dummy под Pulse + **PV-A / PV-B** host-authority rival dummy (Pulse 11 both ways; TPS + seated hull) | mobile SITE_*; second quest board; G5 Clash |
| `PadAmbientLife.gd` | GLB-пропы, bob/wander, **0 боя** | агент, квест, альянс |
| `ClashWaves.gd` | timed `CombatDummy` march по `ClashLanes` | герой Clash, драфт, agency |
| `CombatDummy.gd` | HP, optional aggro/lane; цель и миньон | корабль, база, Contribution |
| `SoftRemotePuppet.gd` | visual peer: поза / форма / фракция / полёт | AI, authority |
| `SoftNetSession.gd` | loopback/ENet visual; default OFF | MMO, 10k CCU |
| `AllianceRanks.gd` | ранги 0–4, soft perms; **не** сила / claim; NP-E два NPC + видимый intent | siege (`rules/23`); pay-to-rank |
| `rules/24` | отряд 2–5; invite одного NPC (NP-D follow/seat) | NP-E два NPC; pay-slot; аура урона |
| `rules/07` | role_id квестодателей (`CX_PILOT_LIAISON`…) — **Q-D** visitor stamps this on the same Q-A board | второй quest system; кампания |
| `rules/11`, `rules/23` | иерархия; NP-E intent ≠ siege | pay-to-war; structure siege |
| `SoftSession.gd` | `user://` form / faction / layer + last action; NP-F short offline cycle | кластер; вторая галактика |
| `BaseBuilder.gd` | P0 controller-only; ST-A `place_player_habitat`; NP-C `place_npc_habitat`; ST-C/NP-G `print_catalog_module`; ST-G/NP-I `print_factory_catalog_module` | mint SITE_* |
| `PadBaseController.gd` | occupy-to-hold, harvest → Contribution / Biomass; NP-B visitor uses the same path | свой yield |
| `PadPrintBench.gd` | ST-C §6(a) spend → one catalog module; **NP-G** same `print_one_module`; **NP-I** same `print_one_factory_module` | cash skip; hangar (b) |
| `CarrierHangarQueue.gd` | ST-D §6(b) one hangar slot; **NP-H** same `enqueue_module` | cash skip; factory (c); mint SITE_* |
| `PlayerOrbitalStation.gd` | ST-E dock+habitat; ST-G factory; **NP-I** same bench (c) | mint SITE_*; city |
| `ShipController` / `ShipFlightModel` / `ShipLandingGear` | SCM/NAV/HOVER/STALL/LAND; G = LAND на unnamed pad | NPC-пилот |
| `Contribution.gd` | `add` / `spend`; NP-B harvest + NP-G print + NP-I factory use the same GameManager wallet | отдельный кошелёк NPC |
| Каталог носителей | slug `cybernex_capital_carrier`, `grot_capital_carrier`, `grot_drone_carrier`, `cybernex_mothership`, `grot_mothership` | hangar + очередь (ST-D **built**; NP-H uses same path) |
| `DEVELOPMENT_PLAN` Phase 2 | «AI-bots + multi-crew» | код agency |

OS-G силуэт и ambient life — WorldFill / плотность, не жители.

---

## 3. Цель слоя

Пока нет кластера (`MMO_SERVERS.md` HOLD), **один мир ARK** остаётся играбельным: solo offline или coop с друзьями. NPC занимают те же действия, что игрок, по тем же правилам. После запуска MMO слой не умирает: добивает пустые слоты, offline, отряды.

| Слой | NPC делает тем же кодом, что игрок | Не отдельной экономикой |
|------|-------------------------------------|-------------------------|
| Space | взлёт / посадка / SCM на загруженном теле ARK | свой IFCS, G1 CRUISE |
| Pad | occupy, harvest, Contribution / Biomass | P2W-ноды |
| Strategy | один модуль / очередь **после ST-A** | mint `SITE_*`; skip печати |
| Social | отряд (`rules/24`); soft альянс (`AllianceRanks`) | pay-to-rank |
| Clash | те же dummy/kit-правила, если слой открыт | G5 из мира; P2W-кит |

Прогресс NPC = те же Contribution / Knowledge (подпись) / Infection кап 5. Не параллельный combat-track. Сюжетные реплики ≠ сила.

---

## 4. Срезы NP-A … NP-I

Каждый срез playable сам, **local-first** (offline и coop SoftNet visual). NP-A…F + NP-C + NP-G + NP-H + **NP-I** built.

| ID | Роль | Семя | DoD | Отказ |
|----|------|------|-----|-------|
| **NP-A** | Один NPC летает **существующей** петлёй корабля | `ShipController` / `ShipFlightModel` / `ShipLandingGear`; тело уже в ARK | взлёт и LAND на unnamed pad (`Pad_North` / `Pad_Approach` / `Pad_Flank`); игрок видит тот же SCM/HOVER/LAND | новый IFCS; G1; вторая система |
| **NP-B** | NPC occupy / harvest / Contribution | `PadBaseController`; `Contribution.gd`; `Extractor.gd` | те же числа и таймеры, что у игрока; Knowledge только подпись | свой yield; P2W-ноды |
| **NP-C** | Один habitat на пустом unnamed паде | ST-A overlay **built**; `BaseBuilder.place_npc_habitat` | **built:** один habitat, не SITE_* | mint `SITE_*`; cash-shop skip ST |
| **NP-G** | Печать одного catalog-модуля (путь ST-C) | `PadPrintBench.print_one_module`; `rules/12`; `rules/15` §6(a) | после NP-B: списать Contribution/Biomass; **один** catalog-модуль на unnamed pad | habitat hack (NP-C); factory (c); hangar (b); cash skip |
| **NP-H** | Очередь одного catalog-модуля (путь ST-D) | `CarrierHangarQueue.enqueue_module`; catalog carrier slugs | после NP-B: **один** модуль в hangar; mass/power refuse | mobile `SITE_*`; factory (c); второй NP-C habitat; cash skip |
| **NP-I** | Печать одного catalog-модуля (путь ST-G) | `PadPrintBench.print_one_factory_module`; `PlayerOrbitalStation` factory; `rules/15` §6(c) | после NP-B: списать Contribution/Biomass; **один** catalog-модуль на factory; без factory — отказ | hangar (b); pad bench (a); второй NP-C habitat; mobile `SITE_*`; cash skip |
| **NP-D** | Отряд: игрок зовёт **одного** NPC | `rules/24` (2–5); seat/F в `InteriorDirector` | invite; NPC следует / садится; coop: visual SoftNet, без combat authority | аура урона от группы; pay-slot |
| **NP-E** | Два NPC: soft-альянс / raid intent | `AllianceRanks` 0–4; `rules/11`; intent ≠ `rules/23` siege | оба с рангом и perm; intent виден (рейд/логистика); без бонуса HP/DPS/claim | P2W-ранг; pay-to-war |
| **NP-F** | Offline: короткая петля без игрока | `SoftSession` (`user://`); влияние **последних** действий игрока | игрок ушёл — NPC доигрывает короткий цикл (пад / follow); не кластер | серверный 10k sim; вторая галактика «под NPC» |
| **Q-D** | Квестодатель на том же Q-A board | `ContractBoard.offer_one`; pad visitor `NpcPilot` | тот же `QA-*` id; accept у NPC; complete → `quest_intel` | второй quest system; кампания; pay-to-complete |

Порядок: A → B → D → F → C (habitat) → E → G (ST-C print) → H (ST-D hangar) → I (ST-G factory) · **Q-D same board**. Не открывать G2 «чтобы было больше миров NPC».

---

## 5. Подписка AI Agency

Продукт: **платить за агентность / интеллект**, не за силу. Слой `rules/19`: `convenience` + `quota`, не `power`. Не отдельный боевой SKU.

| Есть подписка | Нет подписки (бесплатно) |
|---------------|--------------------------|
| Глубина инициативы (сам выбирает следующий легальный шаг) | Dummy / guard / Clash-волна / ambient — как сейчас |
| Диалог, вариации реплик, soft-реакция на игрока | Молчаливый прокси; `rules/07` role_id без agency |
| Длиннее offline-цикл NP-F (тот же ruleset) | Короткий или нулевой цикл; пад не пустеет визуально |
| Больше NPC в отряде/сообществе **внутри** капа `rules/24` | Один молчаливый слот или ноль — tune later |

| Никогда | Почему |
|---------|--------|
| Больше HP / DPS / yield / уникальное оружие у «умного» NPC | P2W |
| Exclusive-киты NPC за Knowledge | Knowledge soft |
| Skip очереди печати ST | Fair Play; `BASE_STATION_STRATEGY` §6 |
| Pay-to-rank / сильнее claim | `AllianceRanks` comment; `rules/11` |
| Громче combat-callout, чем у free в PvP | `rules/19` Voice |

Копия UI (смысл, не дословный ключ): «AI Agency — инициатива и диалог, без боевой силы». Рядом `label.no_p2w`. Токены aiNEX — квота реплик, не статы.

Лапс подписки: глубина падает до free dummy; прогресс (Contribution, occupy) **не** сгорает и **не** конвертируется в урон.

---

## 6. Offline и coop

| Режим | Кто симулирует | Сейчас | Срез |
|-------|----------------|--------|------|
| Solo offline | локальный процесс; `SoftSession` | короткий цикл пад / follow (NP-F) | не 10k sim |
| Coop друзья | SoftNet visual + те же локальные NPC | puppet без authority | NP-A…E на хосте; гости видят позу |
| MMO-кластер | не этот документ | нет | [`MMO_SERVERS.md`](MMO_SERVERS.md) HOLD |

Влияние игрока (NP-F): последние действия — occupy, harvest, invite, смена фракции/формы — смещают **выбор** следующего легального шага, не таблицу урона. Infection кап 5 на NPC как на игроке.

Официальные NPC ≠ запрет Fair Play §2.1 (сторонние макросы/читы).

---

## 7. Жёсткие отказы

| Отказ | Почему |
|-------|--------|
| «Умный» NPC бьёт сильнее / танкует больше | P2W |
| Knowledge-gated exclusive NPC-киты | Knowledge soft |
| Чекан `SITE_*` / новый UUID под хаб NPC | каталог — enum |
| G2 «больше миров для NPC» | одна система ARK |
| Clash-из-мира (G5) | арена нативна в `TestArena` |
| Реализовать 10k CCU сейчас | HOLD; SoftNet visual |
| Cash-shop skip печати ST | столп: нет P2W |
| story = power (квест NPC даёт unique DPS) | story ≠ power |
| Infection > 5 на NPC | кап 5 |
| Вторая галактика / voxel / CIG clone | канон OS / SC map |

---

## 8. Очередь

| Сейчас | Дальше |
|--------|--------|
| NP-A…F + NP-C habitat + NP-G ST-C print + NP-H ST-D hangar + NP-I ST-G factory + **Q-D** same Q-A board giver | следующий NP-срез |
| Стратегия — ST-A…ST-G built; NPC print = (a)/(b)/(c) | не mint `SITE_*` |
| SoftNet — visual | authority later; не 10k |
| G2–G6 | закрыты |
| `MMO_SERVERS.md` | HOLD до Phase 3 |

Не открывать G5, чтобы «NPC вели на арену из мира». Не плодить traffic-галактику.
