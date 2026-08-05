# NAEON — Подробная концепция игры

**Версия:** 0.4 (обновлено 2026-08-05)  
**Репозиторий:** https://github.com/br7wq7yfqc-ctrl/naeon  
**Основа:** NAEXOS + вселенная Aexion

---

## 1. Высокоуровневое видение

**NAEON** — массивная многопользовательская онлайн-игра (MMO) в футуристической вселенной **Aexion**. Многожанровый проект, объединяющий:

- Глобальную стратегию (колонии, базы, ресурсы, fleets)
- Космический симулятор (модульные корабли, multi-crew, флоты до 30)
- Action/RPG от третьего лица (TPS)
- **MOBA-режим** (Aexion Clash) — third-person Action-RPG MOBA в формате PvPvE

Игра полностью standalone, 3D, в тёмно-неоновых тонах, оптимизирована для слабых машин. Обе основные фракции полностью играбельны. Поддерживаются режимы **PvP** и **PvPvE** на всех слоях геймплея.

Цель: создать живой мир, где игроки строят утопию (Cybernex) или стремятся к абсолютному контролю (gROT), одновременно вовлекаясь в экосистему платформы **NAEXOS.ONLINE**.

---

## 2. Лор и фракции

### Вселенная Aexion
Сектор галактики с множеством звёздных систем, планет, астероидных полей и древних руин. Большая часть человечества находится в длительной гибернации внутри защищённого мега-города **NEX** на планете **ARK**.

### Cybernex (играбельна)
Кибернетическое общество: малочисленные люди-киборги + доминирующие **антропоморфные роботы-животные** (псовые, кошачьи, птицы, морские млекопитающие и др.).

- Идеология: **Resource-Based Economy** (Проект Венера) — нет денег, ресурсы распределяются оптимально через NAEXOS Core.
- Роботы обладают сознанием и культурой. Они — caretakers и защитники.
- Цель: торжество **NAEXOS** — устойчивого изобильного порядка.

### gROT (полностью играбельна)
Раса генетических киборгов-мутантов под властью бессмертного лидера **ROT**.

- Цель: трансформация всего сущего в кибер-биомассу, управляемая единой нейросетью ROT.
- Игроки начинают как низкоранговые мутанты и продвигаются по иерархии.
- Уникальные механики: biomass harvesting/assimilation, mutation skill trees, hive-mind бонусы, биомеханический хоррор-стиль.
- Асимметричный геймплей: агрессивный PvP-фокус vs коллективная RBE Cybernex.

### Будущие расы
Модульная система фракций. Возможны нейтральные (древние AI, независимые колонии, remnant-расы), splinter-группы Cybernex/gROT. Разблокируются через лор и контент.

### NPC AI-боты
У каждой расы свои активные AI-боты, участвующие в геймплее:

- **Cybernex**: роботы-животные (workers, patrols, squad mates, advisors, civilian caretakers). Behavior trees + aiNEX-усиленные диалоги и адаптивное поведение.
- **gROT**: рои биомассы, elite mutants, infection spreaders, hierarchical guardians. Агрессивный pack AI, механики заражения.
- Боты заполняют мир, патрулируют, строят, сражаются, реагируют на действия игроков и участвуют в PvP/PvPvE (включая MOBA-minions и jungle).

---

## 3. Геймплейные слои + PvP / PvPvE

### A. Глобальная стратегия
- Persistent shared universe. Колонии, орбитальные станции, верфи, экстракторы.
- Модульное строительство + автоматизация через AI-ботов.
- **PvP/PvPvE**: contested systems, colony raids, resource denial, alliance wars, claim wars. AI-силы обеих фракций + игроки.

### B. Космический симулятор
- Модульные корабли (Scout → Capital). Multi-crew (пилот, стрелок, инженер, командир и др.).
- Флоты до 30 кораблей с управлением с флагмана (стратегический режим).
- Semi-Newtonian физика + атмосферный полёт.
- **PvP/PvPvE**: open-space PvP zones, fleet battles, boarding, contested jump points. AI-флоты + игроки. Safe zones у хабов.

### C. TPS Action/RPG
- Вид от третьего лица. Playable animal-robots (Cybernex) и мутант-формы (gROT).
- Skill trees, модульное снаряжение, cyber-upgrades.
- Seamless (или почти seamless) переход с корабля на поверхность.
- **PvP/PvPvE**: open-world hotspots, instanced arenas, base defense/assault, squad vs squad. AI-боты как allies, enemies или третья сила.

### D. MOBA Mode — Aexion Clash (NAEON Arena)
**Third-person Action-RPG MOBA** в формате **PvPvE** (по аналогии с Paragon / Predecessor).

#### Позиционирование
- Основной формат: **instanced ranked / casual matches** (5v5, с вариантом 3v3).
- Доступен из хабов NEX / ROT-цитаделей или через terminals.
- Lore: «Simulation Conflicts» / «Proxy Wars» / тренировочные симуляции и реальные proxy-сражения за ключевые точки.
- Не ломает open-world loop, но использует тех же героев и soft-прогрессию.

#### Формат матча
- 5v5 (стандарт) или 3v3.
- Команды: Cybernex vs gROT (асимметрия) или draft mixed (casual).
- Длительность: 25–40 минут или до уничтожения Core.
- Карты: dedicated dark-neon арены (NEX Perimeter, Biomass Fields, Ruined Orbital, ARK Wilds).

#### Герои
Герои = существующие формы с полноценными ability kits (3–4 способности + passive + ultimate):

**Cybernex примеры:**
- **Canine (Guardian)** — Tank/Initiator: taunt, pack howl, charge, ultimate Fortress Mode.
- **Feline (Shadow)** — Assassin/Carry: stealth, dash, bleed, ultimate Multi-Strike.
- **Avian (Skyward)** — Mage/Support: aerial glide, dive bomb, vision pulse, ultimate Storm Call.
- **Cetacean (Resonance)** — Support/Healer: sonic heal, barrier, area silence, ultimate Tidal Wave.
- **Human-cyborg (Architect)** — Utility/Flex: deploy turrets, hack, shield, ultimate NAEXOS Overload.

**gROT примеры:**
- **Brute** — Heavy/Juggernaut: smash, regenerate, grab, ultimate Biomass Explosion.
- **Swarm Lord** — Summoner/Controller: spawn minions, infect, swarm dash, ultimate Hive Takeover.
- **Stalker** — Assassin: cloak, pounce, toxin, ultimate Mass Infection.
- **Assimilator** — Bruiser: drain, absorb, mutate, ultimate Conversion Field.
- **ROT Proxy** — Mage/Control: control abilities, ultimate focused on ROT’s will.

Roster на запуске: 8–12 героев, расширяемый. Unlock базовых героев через основной прогресс (Contribution / Biomass Rank / TPS playtime).

#### Механики
- **Leveling**: 1–18 в матче (XP от last-hits, assists, objectives, jungle).
- **Ability points** при повышении уровня.
- **Items**: in-match gold shop (6 слотов). Gold от minions, kills, objectives. Items = modular cyber-upgrades / biomass mutations (stats + actives). Некоторые предметы связаны с основным прогрессом (soft unlocks).
- **Lanes + Jungle**: 3 lanes, continuous AI-minion waves (faction bots), jungle camps (neutral AI + elite objectives).
- **Objectives**: Towers / Inhibitors (faction-themed AI defenses), Core (NEX Relay vs ROT Nexus), secondary control points / Resource Spires.
- **PvPvE depth**: periodic Invasion Events / Infection Waves / Cybernex Drone Swarms, neutral bosses, environmental hazards. AI minions и jungle actively participate.
- Vision system (sensors / spores).

#### Связь с основным геймплеем и платформой
- Победа и performance → Contribution Score / Biomass Rank (с daily cap, чтобы не сломать RBE).
- Hero mastery и skins unlock через main game + NAEXOS Premium / Battle Pass.
- Post-match: опциональный «submit match report» как knowledge gate в NAEXOS.ONLINE.
- Ranked MMR частично синхронизируется с Trust Score / Qualification Levels.
- **aiNEX**: recommended builds, draft assistant, post-match analysis (limited free, full with sub).
- Cosmetics и ability VFX — через подписку / Battle Pass / platform activity.
- **Нет pay-to-win и нет прямого power-transfer** в open-world.

#### Влияние побед в Aexion Clash на persistent universe (без вреда MMO-loop)

Все эффекты спроектированы как **soft, temporary, capped и преимущественно faction-wide**. Основной MMO-loop (строительство, полёты, ground ops, RBE/Biomass) остаётся главным источником долгосрочного прогресса и контроля карты. Arena даёт ощутимое влияние на войну фракций, но никогда не заменяет присутствие в open world.

**1. Faction War Score / Momentum**
- Ranked (и high-performance casual) победы добавляют очки в Faction War Score / Momentum.
- При достижении thresholds фракция получает **временные** buffs (обычно 12–72 часа):
  - +% к extraction / production rate в contested systems
  - Ускоренное строительство / ремонт кораблей и структур
  - Усиленные AI-боты (больше подкреплений в open-world PvPvE и raids)
  - Небольшое усиление claim strength на спорных территориях
- Score имеет natural decay. Обе фракции имеют равный доступ.
- Визуально отображается на galactic map.

**2. Proxy Contests для minor-объектов**
- Только **minor / secondary** объекты могут быть помечены как «Arena Contestable»:
  - Малые outposts и forward bases
  - Resource extractors и orbital relays
  - Derelict frigates / abandoned platforms
  - Secondary space stations и resource-rich asteroid bases
- Фракция может инициировать Proxy Challenge → серия или один high-stakes Arena match.
- Победа даёт **temporary control** (12–48 часов, реже до 72 часов) + trickle ресурсов в фракционный RBE / Biomass pool + усиленный AI-гарнизон.
- По истечении времени объект снова contestable. Open-world игроки противоположной фракции всегда могут отбить контроль обычными средствами (флот + TPS).

**3. Major-объекты защищены**
- Полные колонии, города, capital ships, основные космобазы, NEX/ARK-связанные объекты и ключевые hubs **нельзя** захватить через Arena.
- Arena может давать только **Siege Prep / Softening**:
  - Временный debuff на защитников AI
  - Assault Token, который снижает сложность последующего open-world штурма
  - Дополнительные AI-подкрепления атакующим на короткое время
- Сам захват и удержание всегда требуют main-game усилий (Strategy + Space + TPS).

**4. Resource Injection (строго capped)**
- Победа → небольшая порция Energy / Materials / Biomass в общий фракционный пул.
- Daily cap на игрока + weekly cap на фракцию.
- Performance rating (не только win/loss) влияет на размер награды.
- Не заменяет основной майнинг, строительство и extraction.

**5. Personal Soft Rewards**
- Temporary personal Contribution / Biomass multiplier (обычно 5–15% на 12–24 часа).
- Hero Momentum: небольшой boost XP / ability feel в open-world (без нарушения PvP fairness).
- Hero Mastery points → soft-unlocks альтернативных ability variants или cosmetics, usable в main game.
- Titles, auras, visual flair.

**6. Seasonal & Narrative Layer**
- Ranked seasons и high-stakes tournaments:
  - Победившая фракция получает temporary map advantages (новые temporary claim zones, уникальные resource nodes на 1–2 недели).
  - Небольшие permanent soft unlocks для всей фракции (cosmetic, minor blueprint, flavour ownership text).
  - Narrative impact (lore events, temporary renaming of contested zones).
- Даже сезонные преимущества требуют, чтобы open-world игроки их удерживали.

**Защита MMO-loop (ключевые принципы)**
- Все Arena-derived benefits имеют **daily/weekly caps** и diminishing returns.
- Open-world players, которые никогда не заходят в Arena, теряют только soft temporary buffs — core прогресс и возможность контролировать карту полностью сохраняются.
- Arena-only игроки получают ограниченные долгосрочные выгоды (в основном temporary и cosmetics).
- Major strategic assets всегда требуют присутствия в Strategy / Space / TPS слоях.
- UI ясно показывает временный характер Influence Zones и таймеры.
- Matchmaking + performance rating предотвращают чистый farming wins.

Таким образом, победы в Aexion Clash ощущаются значимыми («мы помогли фракции закрепиться на этом участке»), создают живую войну фракций и дают competitive игрокам влияние на большой мир, но **MMO-loop остаётся королём**.

**Основная петля** остаётся: Exploration / Colonization → Ship building → Space ops & fleets → Ground ops → Contribution / Biomass Rank → feedback в RBE / hierarchy. MOBA — мощный competitive слой и источник rewards + engagement.

---

## 4. Экономика

### Cybernex — Resource-Based Economy (RBE)
Нет классической валюты. **Contribution Score** определяет влияние на allocation. NAEXOS Core + сенсоры распределяют ресурсы. Игроки предлагают проекты; система выделяет ресурсы пропорционально вкладу + глобальным нуждам.

### gROT — Biomass Economy
Личная/иерархическая сила через biomass. Harvesting, conversion, ranking under ROT.

### Мост с платформой NAEXOS.ONLINE
- Contribution Score / Biomass Rank синхронизируются с **Trust Score** и **Qualification Levels** платформы.
- Activity Mining: открытия в игре → вклад в OKA/wiki платформы.
- Опциональный bridge: навыки и знания, зафиксированные на платформе, дают soft-multipliers в игре.
- MOBA ranked performance также влияет на Trust Score / Battle Pass.

---

## 5. aiNEX — AI-инструменты в игре

aiNEX — семейство AI-инструментов экосистемы NAEXOS:

- Colony planner / resource allocator
- Ship & module designer
- Combat / fleet tactics advisor
- Procedural mission & event generator
- Lore / dialogue enhancer для NPC
- Personal robot customization AI
- **MOBA**: recommended builds, draft advice, post-match analysis, ability tooltips

**Доступ**:
- Базовые лимиты — бесплатно.
- Расширенные модели и высокий лимит — через подписку или высокий Contribution / активность на платформе.

---

## 6. Гейты вовлечения в NAEXOS.ONLINE

1. **Account linking** — единый аккаунт (SSO). Синхронизация прогресса и Trust Score.
2. **Onboarding / Knowledge gates** — квесты «Sync with NAEXOS Core»: отправить discovery / гайд в wiki платформы → in-game reward.
3. **Time-bank / Skill exchange** — обмен навыками (стратегия, design, coaching) на платформе → boost в RBE или cosmetics.
4. **Escrow & community deals** — услуги, связанные с игрой, через платформенный escrow.
5. **Cross-events & Battle Pass** — сезонные события с dual rewards (игра + платформа), включая MOBA seasons.
6. **In-game terminals** — deep links / embedded views к dashboard, AI Lab, forums, economy tools платформы.
7. **Community votes** — игроки влияют на приоритеты RBE через голосования на NAEXOS.ONLINE.
8. **MOBA gates**: ranked performance, match reports, community tournaments → Trust Score / Qualifications / cosmetics.

Цель гейтов: органично вовлекать игроков в реальную деятельность платформы (обмен навыками, фиксация знаний, команды, AI-tools).

---

## 7. Монетизация — Freemium + Subscription

**Freemium (бесплатно)**:
- Полный доступ к core gameplay всех слоёв (включая MOBA).
- Обе фракции (Cybernex + gROT).
- PvP / PvPvE.
- Базовые AI-боты и limited aiNEX.
- Все системы прогрессии.

**Подписка (NAEXOS Premium / Cybernex Pass)** — удобство и cosmetics, **без pay-to-win**:
- Повышенные multipliers Contribution / Trust Score sync.
- Полный / приоритетный доступ к advanced aiNEX (включая MOBA builds).
- Эксклюзивные cosmetics, варианты животных-форм / мутаций, hero skins, ability VFX.
- Дополнительные слоты multi-crew / private fleet options.
- Battle Pass tiers (shared between main game and MOBA), priority matchmaking, expanded storage.
- Cross-platform rewards.

Строгое правило: подписка не даёт прямого боевого преимущества или ускоренного получения ключевых ресурсов/силы.

---

## 8. Технологический стек

**Движок: Godot 4.3+ (рекомендуется 4.4+)**
- Открытый исходный код, отличная производительность на weak hardware.
- Built-in multiplayer + dedicated/headless servers.
- GDScript + C# / GDExtension (C++) для hot paths.
- AnimationTree + IK для animal forms.
- Aggressive LOD, instancing, occlusion — критично для low-end.
- Ability system data-driven (Resources) — переиспользуется между TPS open-world и MOBA.

**Backend**:
- Godot dedicated servers (containerized).
- PostgreSQL + Redis.
- Interest management / spatial partitioning.
- RBE simulation как отдельный сервис (Go/Rust или Godot).
- Matchmaking service для MOBA (local first → cloud).

**Art**: stylized low-to-mid poly + PBR + heavy emissives (dark-neon).

---

## 9. Серверная инфраструктура

### Фаза 0 — Полностью локальная разработка (приоритет)
- Godot headless servers + clients на машинах разработчиков.
- Docker Compose: Postgres, Redis, MinIO (опционально), auth/world/fleet services.
- Полный vertical slice работает offline / в локальной сети.
- **Стоимость: 0 ₽** (используется существующее железо).

### Фаза 1 — Closed Alpha / Early Testing (50–200 CCU)
Провайдер по умолчанию: **Yandex Cloud**.

Примерная конфигурация:
- 1× Auth/Gateway: 2 vCPU / 4 GB
- 2× World/Strategy servers: 4 vCPU / 8–16 GB
- Dynamic instance managers для Space/TPS/MOBA (auto-scale)
- Managed PostgreSQL + Redis
- Object Storage

**Ориентировочная стоимость: 25 000 – 50 000 ₽ / месяц**

### Фаза 2 — Open Beta / Soft Launch (500–2000 CCU)
- Горизонтальное масштабирование game nodes
- Managed K8s (опционально)
- Более мощный DB-кластер, CDN, мониторинг
- **Ориентировочно: 80 000 – 200 000 ₽ / месяц** (зависит от реальной нагрузки и регионов)

### Фаза 3 — Full Scale
- Auto-scaling groups, multi-region, выделенные мощности под RBE simulation и aiNEX inference (YandexGPT / DataSphere или внешние endpoints с rate limits).

**Рекомендация**: максимально долго оставаться на local-first. Переход на Yandex Cloud только при необходимости persistent multi-user тестирования. Использовать Infrastructure-as-Code (Terraform).

---

## 10. Roadmap (высокоуровневый)

1. **Foundation** — Godot прототип: TPS animal controllers + basic ship flight + simple colony + local multiplayer.
2. **Core Loop + PvP** — модульные корабли, multi-crew, Contribution/Biomass, базовые AI-боты, PvP во всех слоях + начало ability system для MOBA.
3. **Vertical Slice + MOBA Prototype** — одна система с планетами, seamless-переходы, fleets, RBE simulation, account linking prototype + 3v3/5v5 MOBA arena prototype + базовый Momentum system.
4. **Platform Integration + Full MOBA** — aiNEX tools, гейты в NAEXOS.ONLINE, subscription system, ranked MOBA, rewards pipeline, Proxy Contests, full influence systems.
5. **Scale & Polish** — interest management, optimization low-end, content, balance both factions + MOBA roster/maps.
6. **Launch** — public release + live-ops.

---

## Уникальные преимущества NAEON

- Playable антропоморфные киборги-животные + асимметричный playable gROT.
- Настоящая Resource-Based Economy + мост с реальной платформой обмена навыками NAEXOS.
- Глубокая интеграция трёх жанров + полноценный PvP/PvPvE на каждом слое.
- **Competitive third-person MOBA (Aexion Clash)** с теми же героями, PvPvE-глубиной и meaningful (но soft) влиянием на persistent world.
- aiNEX как живой AI-слой внутри игры и платформы.
- Freemium без pay-to-win + осмысленные гейты в экосистему NAEXOS.ONLINE.
- Local-first разработка + реалистичный путь на Yandex Cloud.

---

*Документ поддерживается командой разработки. Следующий шаг — детальный GDD и vertical slice в Godot.*
