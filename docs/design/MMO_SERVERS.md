# NAEON — MMO-серверы (Phase 3 HOLD)

**Версия:** 1.0  
**Дата:** 2026-08-18  
**Движок:** Godot 4.7.2  
**Статус:** **HOLD до Phase 3.** Этим PR runtime и netcode не менять. Не открывать G5 / G2–G6.

Запрос владельца (в план): кластер обязан держать **до 10 000 CCU**; **минимум 100 игроков на шард без нарезки на отдельные инстансы**; играемое пространство **общее**. Бенчмарк — гибрид EVE Online (один шард экономики / альянсов) и Star Citizen server meshing (одно пространство, стрим). До Phase 3 — этот файл. Не писать netcode. Не открывать G5 (Clash-из-мира) и G2–G6.

Local-first до снятия HOLD: [`NPC_AGENCY.md`](NPC_AGENCY.md) (NP-A…NP-F).  
SoftNet сейчас: [`SOFT_NET.md`](../systems/SOFT_NET.md).  
Clash net: [`ARENA_PREDECESSOR_BENCHMARK.md`](ARENA_PREDECESSOR_BENCHMARK.md) AR-F.  
Карта ролей: [`SC_FEATURE_MAP.md`](SC_FEATURE_MAP.md) столпы 13 / 17.  
План: [`DEVELOPMENT_PLAN.md`](../../DEVELOPMENT_PLAN.md) Phase 3 (окно HOLD), Phase 5 (scale prep — не 10k сейчас).

---

## 1. Канон (не размывать)

- Нет P2W. Knowledge soft. Infection max 5. story ≠ power.
- Одна резидентная система: **ARK**, пока G2 закрыт. Кластер не оправдывает вторую галактику.
- Не чеканить `SITE_*`. Не изобретать UUID каталога.
- Pay-rank matchmaking запрещён. Clash остаётся нативным (`TestArena`), не входом из мира.
- Godot 4.7.2. Yandex Cloud — после устойчивого vertical slice, не в этом PR.

---

## 2. Цели (не код)

| Цель | Смысл | Не означает |
|------|--------|-------------|
| **10 000 CCU** | пик одновременных клиентов на кластере | реализовать в Phase 0–2; обещать 10k на одном процессе Godot |
| **≥100 на шард без instance-split** | сто человек в одном месте остаются вместе; их не разводят по копиям карты | 100 инстансов по 1; Clash-матч как замена мира |
| **Общее пространство** | один играемый объём ARK; стрим интереса, не отдельные вселенные | вторая система «под нагрузку»; G2 сейчас |
| **EVE-роль** | один ledger экономики / альянсов / стояний (`Contribution`, `AllianceRanks`, `rules/23`) | клон Tranquility; spreadsheet-only |
| **SC-meshing роль** | одно пространство, серверы стримят сектора | клон CIG; Planet Tech V5; voxel |

Шард здесь — **пространственный кусок одного мира**, не инстанс-копия «ваша ARK №47». Экономика и дипломатия не размножаются на шард.

---

## 3. Честный статус (2026-08-18)

| Узел | Факт репо | Это не |
|------|-----------|--------|
| `SOFT_NET.md` / `SoftNetSession` | visual; UDP JSON / ENet fallback / loopback; **no combat authority** | dedicated shard |
| `SoftRemotePuppet.gd` | поза / форма / фракция / полёт | симуляция мира |
| `SoftENet.gd` | LAN host/join seed | 10k CCU |
| Phase 2 план | 2–4 игрока, multi-crew, server authority + prediction | сделано |
| AR-F | 3v3 local host authority **built**; SoftNet visual; still startable; G5 закрыт | вход в Clash из OPEN SPACE |
| AR-G | 5v5 local host authority **built**; SoftNet visual; same 60×60; G5 закрыт | вход в Clash из OPEN SPACE |
| Phase 3 план | vertical slice **одной** системы ARK; quests; MOBA full proto | кластер 10k |
| Phase 5 план | interest management; load test «50–100+ entities» | целевые 10k CCU |
| `NPC_AGENCY.md` | боты есть; agency — docs | замена кластера кодом NPC |

10k CCU — **цель кластера**, не DoD ближайшей сессии. Снятие HOLD ≠ шип 10k.

---

## 4. Гибрид (роли, не клон)

| Роль предшественника | Эквивалент NAEON | Отказ |
|----------------------|------------------|-------|
| EVE: один экономический шард, альянсы, война дорогая | один Contribution / Biomass ledger; `AllianceRanks`; war/truce без продажи исхода | pay-to-win market; pay-rank |
| EVE: игроки не живут в копиях одной системы | ≥100 вместе без instance-split; ARK общая | «инстанс на пати» как мир |
| SC: одно пространство, meshing/стрим | spatial partition + interest; клиент видит один континуум | CIG net; вторая галактика |
| SC: вход в зону без смены вселенной | тот же `LayerContext` Space/TPS/Strategy; Clash = отдельный нативный слой | G5 Clash-из-мира сейчас |

Clash / TestArena может иметь **собственные** матч-комнаты (AR-F later). Это не модель OPEN SPACE и не способ набрать 10k. Арена не флипает планету (`rules/13`).

---

## 5. Что NAEON отказывает **сейчас**

| Отказ сейчас | Почему |
|--------------|--------|
| Писать netcode / dedicated cluster | HOLD до Phase 3; SoftNet visual |
| Реализовать 10k CCU | нет слоя; Phase 5 ещё про 50–100 entities |
| Pay-rank matchmaking | Fair Play; `SC_FEATURE_MAP` столп 17; AR-F отказ |
| G5 (Clash-из-мира) | арена нативна; `GALAXY_LAYER_PLAN` закрыт |
| G2–G6 (карта, прыжки, гейты, вторая система) | петля OS / ARK; не «шарды галактики» |
| Вторая галактика под CCU / «миры NPC» | одна ARK; [`NPC_AGENCY.md`](NPC_AGENCY.md) §7 |
| Instance-split пати <100 как постоянный мир | ломает цель ≥100 вместе |
| P2W-слоты шарда / платная плотность | нет P2W |
| Чекан `SITE_*` под «серверный хаб» | каталог — enum |

---

## 6. Когда снимать HOLD

Earliest: **Phase 3** (`DEVELOPMENT_PLAN.md`) — окно **архитектуры**, не запуска 10k.

| Можно после снятия HOLD | Всё ещё нельзя |
|-------------------------|----------------|
| Документ шарда + interest; dedicated scene; authority поверх SoftNet | G2–G6 код «чтобы размазать CCU» |
| Цель ≥100 вместе на одном теле ARK как тест плотности | G5 вход в Clash из мира |
| Стык с `NPC_AGENCY` (NPC добивают пустые слоты на шарде) | P2W-умнее NPC; pay-rank queue |
| IaC / Yandex — по плану Phase 5, не раньше устойчивого slice | секреты в git; `assets/` в git |

До снятия HOLD играбельность мира — локальные NPC + coop visual. Игрок не ждёт кластер, чтобы сесть на пад.

---

## 7. Жёсткие отказы (всегда)

P2W · Knowledge→DPS · Infection>5 · story=power · `SITE_*` mint · G5 сейчас · G2–G6 сейчас · CIG/EVE clone · voxel · вторая резидентная система · pay-rank matchmaking · 10k CCU в этом PR.

---

## 8. Очередь

| Сейчас | Дальше |
|--------|--------|
| Этот файл = HOLD | Phase 3: архитектура шарда; не 10k в первый спринт |
| SoftNet visual | combat authority later (Phase 2/3 план) |
| [`NPC_AGENCY.md`](NPC_AGENCY.md) docs | NP-A…F local-first |
| OS-H / ST / AR бары | свои очереди; кластер их не обгоняет |

Не открывать G2, чтобы «было что мешить». Меш — на загруженной ARK.
