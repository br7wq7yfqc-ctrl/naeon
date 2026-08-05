# NAEON — Подробная концепция игры

**Версия:** 0.6 (обновлено 2026-08-05)  
**Репозиторий:** https://github.com/br7wq7yfqc-ctrl/naeon  
**Основа:** NAEXOS + вселенная Aexion

---

## 1. Высокоуровневое видение

**NAEON** — массивная многопользовательская онлайн-игра (MMO) в футуристической вселенной **Aexion**. Многожанровый проект, объединяющий:

- Глобальную стратегию (колонии, базы, ресурсы, fleets)
- Космический симулятор (модульные корабли, multi-crew, флоты до 30)
- Action/RPG от третьего лица (TPS)
- **MOBA-режим** (Aexion Clash) — third-person Action-RPG MOBA в формате PvPvE

**Уникальность:**
- Генерация контента по промптам прямо в клиенте
- Живое общение с ИИ-NPC
- **Голосовое управление через Yandex Alice**
- Всё на базе **Yandex GPT + Yandex SpeechKit / Alice** (при платной подписке + оплате токенов)

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

- **Cybernex**: роботы-животные (workers, patrols, squad mates, advisors, civilian caretakers). Behavior trees + aiNEX / Yandex GPT-усиленные диалоги и адаптивное поведение.
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
Герои = существующие формы с полноценными ability kits (3–4 способности + passive + ultimate). Roster на запуске: 8–12 героев, расширяемый. Unlock через основной прогресс.

#### Механики
- Leveling 1–18 в матче, ability points, items (gold shop), lanes + jungle, objectives, PvPvE events, vision system.

#### Связь с основным геймплеем и платформой
- Победа и performance → Contribution Score / Biomass Rank (с daily cap).
- Ranked MMR частично синхронизируется с Trust Score.
- **aiNEX** + Yandex GPT: builds, draft, post-match analysis.
- Cosmetics через подписку / Battle Pass.
- **Нет pay-to-win и нет прямого power-transfer** в open-world.

#### Влияние побед в Aexion Clash на persistent universe (без вреда MMO-loop)

Все эффекты **soft, temporary, capped и преимущественно faction-wide**. MMO-loop остаётся главным источником долгосрочного прогресса и контроля карты.

1. **Faction War Score / Momentum** — wins → temporary faction buffs (extraction, repairs, AI strength, claim power).
2. **Proxy Contests** — только minor-объекты (outposts, extractors, orbital relays, derelicts) → temporary control (12–48ч) + resource trickle.
3. **Major-объекты защищены** — full colonies, cities, capital ships, hubs можно захватывать только через main layers. Arena даёт только Siege Prep.
4. **Resource Injection** — capped daily/weekly injection into faction pools.
5. **Personal Soft Rewards** — temporary multipliers, Hero Momentum, mastery unlocks, cosmetics.
6. **Seasonal & Narrative** — seasons/tournaments дают temporary map advantages и small permanent soft unlocks.

Safeguards: caps, diminishing returns, open-world always can contest, UI transparency, performance rating.

---

## 4. Базовые механики и петли (детально)

### 4.1 Режим стратегии для лидеров альянсов
Специальный **Strategic Command Interface** (доступен рангам Leader / Officer):
- Galactic map с real-time overview: claims, structures, NPC fleets, logistics, threats, Arena Momentum, shared resources.
- Tools: назначение приказов флотам (NPC + player), постановка alliance goals, allocation shared resources, объявление Proxy Contests / wars, управление permissions, создание shared tasks.
- **aiNEX / Yandex GPT Strategic Advisor**: prompt-based analysis («предложи следующий шаг экспансии», «как защитить систему X», «оптимизируй логистику»).
- Поддержка голосовых команд через Yandex Alice.

### 4.2 Управление структурами

**Космические базы и орбитальные станции**
- Модульные: Habitat, Shipyard, Refinery, Defense Platform, Research Lab, Logistics Hub, Carrier Dock, Hangar.
- Строительство через Strategy layer (лидеры размещают, RBE/Contribution выделяет ресурсы).
- Ownership (player / alliance) + granular permissions matrix (view / dock / extract / manage / full control).
- AI-боты автоматически обслуживают базу.

**Флоты NPC**
- Альянсы могут создавать и управлять NPC-флотами (лимит зависит от Contribution / Alliance rank / War Score).
- Типы: Patrol, Defense, Mining Escort, Transport Escort, Assault.
- Приказы из Strategy mode: move, patrol route, defend object, attack, escort.
- Behavior trees + aiNEX / Yandex GPT для higher-level решений (при подписке).

**Корабли-носители (Carriers)**
- Специальный класс Capital / Carrier ships (Light / Fleet / Super-Carrier).
- Hangar slots: drones (mining, combat, repair, scout) + fighters (player-piloted или AI).
- Multi-crew: Commander управляет carrier, другие игроки пилотируют fighters или управляют drone swarms.
- Launch / recall, formations, auto-attack modes.
- В PvP/PvPvE — mobile force multiplier и support platform.
- Высокоуровневые blueprints + высокие требования к Contribution / shared resources.

### 4.3 Наземные операции
- После посадки (или orbital drop) игрок в TPS участвует в ground ops.
- **Player-driven objectives**: лидеры / игроки ставят динамические цели (capture zone, defend extractor, escort, sabotage, rescue, biomass purge и т.д.).
- Objective markers + progress UI. AI-боты автоматически помогают или сопротивляются в зависимости от фракции и прав.
- Успех даёт Contribution / Biomass, ускоряет claims, разблокирует structures.

### 4.4 Пользовательские миссии и контракты
- **Contract Board** (в хабах, на базах, через terminals).
- Игроки / альянсы публикуют контракты: доставка, зачистка, сбор данных, защита, эскорт и т.д.
- Награда: ресурсы, Contribution, blueprints, cosmetics, temporary rights.
- Escrow-система (in-game + NAEXOS bridge).
- **User-generated missions**: через Prompt Studio (Yandex GPT) игрок/лидер генерирует кастомную миссию. AI валидирует и балансирует.
- Петля: Create → Accept → Execute (TPS/Space) → Reward + feedback в RBE/Alliance.

### 4.5 Добыча ресурсов, торговля и логистика
**Добыча**
- Player-driven, automated (AI-bots / drones), или смешанная.
- Extractors на планетах и в космосе.

**Торговля**
- Cybernex: RBE allocation / request system (нет классической валюты).
- gROT: hierarchical / black-market style с Biomass credits.
- Internal alliance markets + limited cross-faction (с риском).

**Логистика**
- Ценные грузы (rare materials, data cores, biomass samples, crafted components) перевозятся cargo-ships или player ships.
- Маршруты: player-driven или AI-convoy (NPC escort).
- Риски: pirates, contested systems, player ambushes → PvPvE.
- Logistics Hub structures автоматизируют часть перевозок.
- Игроки создают Transport Contracts (награда в Contribution / resources).

**Core Economic Loop (пример Cybernex):**
Extract (player / AI / drones) → Haul (contracts / freighters) → Allocate via RBE (alliance leaders + Contribution) → Craft (blueprints) → Build structures / equip fleets → Defend / Expand → Contribution feedback.

### 4.6 Управление социальной структурой сообществ (Альянсы)
- **Иерархия**: Leader → Officers → Members → Recruits (полностью кастомизируемые ранги).
- **Permissions matrix**: granular права (кто может строить, claim’ить, тратить shared resources, объявлять войну, access hangars, edit blueprints, publish contracts).
- **Shared resource pool** (RBE-style для Cybernex-альянсов).
- **Alliance tasks / contracts**: лидеры создают общие задачи для членов.
- **Shared blueprints and decorations library**.
- Strategy Command Interface даёт лидерам полный overview и инструменты управления.

### 4.7 Крафтинг и чертежи (Blueprints)
- Полная система blueprints: от компонентов → modules → ships → bases → **декорации** (furniture, neon signs, custom holograms, interior/exterior).
- Crafting stations на базах, станциях, carriers.
- Research / reverse-engineering / prompt-generation для получения blueprints.
- Player-created blueprints можно сохранять, делиться в альянсе, публиковать (с модерацией).
- Декорации полностью placeable — поддержка высокой степени персонализации баз и кораблей.
- Крафт требует ресурсов + (иногда) Contribution rank.

**Crafting Loop:**
Unlock / research / prompt-generate blueprint → Gather components → Craft at station → Place / use (включая decorations) → Share in alliance / NAEXOS.

---

## 5. Уникальность: Генерация контента, живые ИИ-NPC и голосовое управление

### 5.1 Prompt Studio / Creation Terminal (в клиенте)
Игрок может прямо в клиенте генерировать контент по промптам (текст или **голос через Alice**):
- Миссии и контракты
- Описания и data для структур / колоний / кораблей
- Blueprints декораций и модулей
- Lore entries, названия, события
- Диалоги и personality для NPC

Yandex GPT генерирует текст + structured data (JSON). Результат можно сохранить как personal / alliance asset, опубликовать в Contract Board или (после модерации) в общий пул.

**Ограничения:**
- Free tier: limited prompts/day + простые outputs + rule-based fallback.
- NAEXOS Premium + оплата токенов: высокие лимиты, лучшие модели, complex multi-object generation, persistent memory.

### 5.2 Живое общение с ИИ-NPC
- Любые ключевые NPC (advisors, governors, captains, merchants, workers, ROT proxies) поддерживают **live dialogue**.
- Игрок пишет **или говорит** (Yandex Alice / SpeechKit speech-to-text) → NPC отвечает in-character (text + optional TTS через Alice).
- Context-aware (локация, фракция, recent events, история игрока).
- Возможности: советы, торговля, динамические квесты, ролеплей, soft «обучение» NPC.
- Powered by **Yandex GPT API** + **Yandex Alice / SpeechKit**.

**Доступ:**
- Базовый (rule-based + короткие GPT-ответы) — бесплатно.
- Полный live GPT + long memory + advanced personality + continuous voice — Premium подписка + токены.

### 5.3 Голосовое управление через Yandex Alice

**Yandex Alice** интегрирована в клиент NAEON как основной голосовой интерфейс (на базе Yandex SpeechKit + Alice capabilities).

#### Основные сценарии использования

**1. Голосовой диалог с ИИ-NPC**
- «Алиса, спроси у советника о состоянии экстракторов»
- Естественный разговор с любым ключевым NPC без клавиатуры.
- Alice выступает как «голос» ship AI / personal companion / base AI.

**2. Prompt Studio голосом**
- «Алиса, сгенерируй миссию: защитить конвой от gROT на планете X»
- «Алиса, создай blueprint декоративного неонового фонтана в стиле Cybernex»
- Полностью hands-free генерация контента.

**3. Strategy Mode (для лидеров альянсов)**
- «Алиса, отправь патрульный флот в систему 7»
- «Алиса, выдели ресурсы на защиту орбитальной станции»
- «Алиса, покажи статус логистики»
- «Алиса, создай контракт на перевозку 200 единиц редких сплавов»

**4. Космический симулятор и Carriers**
- «Алиса, полный вперёд» / «курс на ARK»
- «Алиса, запустить истребители» / «отозвать дроны»
- «Алиса, перевести мощность на щиты»
- «Алиса, приказ флоту: атаковать цель»
- Multi-crew: голосовые приказы членам экипажа или AI-crew.

**5. TPS / Ground Ops / Combat**
- «Алиса, использовать способность X»
- «Алиса, переключить форму на Feline»
- «Алиса, отметить цель» / «запросить поддержку»
- Callouts и быстрые команды в бою (с подтверждением для критических действий).

**6. UI и Accessibility**
- Навигация по меню, картам, инвентарю голосом.
- Сильный accessibility feature (особенно важно для multi-crew и длительных сессий).

#### Техническая реализация
- **Yandex SpeechKit** (STT + TTS) + Alice API / custom skill или прямой SDK в Godot-клиенте.
- Push-to-talk (свободный) или continuous listening (Premium).
- Offline fallback: ограниченный набор локальных команд + rule-based responses.
- Latency optimization: локальный wake-word + cloud processing для сложных запросов.
- Privacy: явный consent, возможность отключить, данные обрабатываются согласно политике Yandex + игровым ToS.

#### Монетизация и доступ
- **Free**: push-to-talk + базовые команды + limited STT/TTS.
- **NAEXOS Premium**: continuous listening, advanced commands, lower latency, full voice NPC dialogue, voice Prompt Studio.
- Сложные generative-запросы (длинные промпты, multi-step) расходуют **токены Yandex GPT** (как и текстовая генерация).
- Голосовое управление **не даёт combat advantage** — только convenience, immersion и accessibility. Полностью соответствует no-P2W.

#### Safeguards
- Критические боевые/стратегические действия требуют подтверждения (голос + UI или double-confirm).
- Rate limits и anti-spam.
- System prompts и фильтры для NPC-диалогов.
- Возможность полностью отключить Alice.

### 5.4 Монетизация и безопасность Yandex-стека
- Токены покупаются за реальные деньги или частично зарабатываются активностью.
- Cost проходит напрямую пользователю (прозрачный баланс токенов).
- Rate limits, system prompts (жёсткие lore/safety filters), moderation pipeline, offline fallback.
- Генерация и голос **не дают combat power** — только content, creativity, convenience, immersion и accessibility.

### 5.5 Интеграция с aiNEX
Yandex GPT + Yandex Alice / SpeechKit являются backend-движком продвинутых функций aiNEX (Strategic Advisor, colony planner, ship designer, MOBA builds, NPC dialogue, prompt generation, voice control).

---

## 6. Экономика

### Cybernex — Resource-Based Economy (RBE)
Нет классической валюты. **Contribution Score** определяет влияние на allocation. NAEXOS Core + сенсоры распределяют ресурсы. Игроки и альянсы предлагают проекты; система выделяет ресурсы пропорционально вкладу + глобальным нуждам. Shared alliance pools.

### gROT — Biomass Economy
Личная/иерархическая сила через biomass. Harvesting, conversion, ranking under ROT.

### Мост с платформой NAEXOS.ONLINE
- Contribution Score / Biomass Rank синхронизируются с **Trust Score** и **Qualification Levels**.
- Activity Mining: открытия в игре → вклад в OKA/wiki платформы.
- MOBA ranked + generated content также влияют на Trust Score / Battle Pass.

---

## 7. aiNEX + Yandex GPT + Yandex Alice

aiNEX — семейство AI-инструментов:
- Colony planner / resource allocator
- Ship & module designer
- Combat / fleet tactics advisor
- Procedural / prompt-based mission & event generator
- Lore / dialogue enhancer
- Personal robot customization
- Strategic Advisor для лидеров
- MOBA builds / draft / post-match analysis
- Prompt Studio backend
- **Голосовое управление и TTS/STT через Yandex Alice**

**Доступ**: базовый free, полный через Premium + токены Yandex GPT.

---

## 8. Гейты вовлечения в NAEXOS.ONLINE

1. Account linking (SSO)
2. Knowledge gates (submit discoveries / generated content)
3. Time-bank / Skill exchange
4. Escrow & community deals
5. Cross-events & Battle Pass (включая MOBA seasons)
6. In-game terminals → platform tools
7. Community votes
8. MOBA gates + generated content contribution

---

## 9. Монетизация — Freemium + Subscription + Tokens

**Freemium**: полный core gameplay (все слои, обе фракции, PvP/PvPvE, базовые AI-боты, limited GPT + limited voice).

**NAEXOS Premium / Cybernex Pass**:
- Multipliers Contribution / Trust Score
- Полный доступ к advanced aiNEX + Yandex GPT + **Yandex Alice** (continuous listening, advanced commands, full voice NPC dialogue)
- Cosmetics, hero skins, ability VFX, decorations
- Дополнительные multi-crew / private fleet / carrier slots
- Battle Pass, priority matchmaking
- Cross-platform rewards

**Токены Yandex GPT**: покупаются отдельно (или частично зарабатываются) для генерации контента, long AI-NPC dialogue и сложных голосовых generative-запросов. Не дают combat power.

Строгое правило: **нет pay-to-win**.

---

## 10. Технологический стек

**Движок: Godot 4.3+ (4.4+)**
- Built-in multiplayer + dedicated servers
- GDScript + C# / GDExtension
- AnimationTree + IK
- Data-driven Ability + Blueprint systems

**Backend**:
- Godot dedicated servers (containerized)
- PostgreSQL + Redis
- Interest management
- RBE simulation service
- Matchmaking
- **Yandex GPT API** + **Yandex SpeechKit / Alice** integration (with local fallbacks)

**Art**: stylized low-to-mid poly + PBR + heavy emissives (dark-neon).

---

## 11. Серверная инфраструктура

**Фаза 0 — Local-first**: Godot headless + Docker (Postgres/Redis). Cost 0 ₽.

**Фаза 1 — Closed Alpha (50–200 CCU)**: Yandex Cloud, ~25–50k ₽/мес.

**Фаза 2 — Open Beta (500–2000 CCU)**: horizontal scaling, ~80–200k ₽/мес.

**Фаза 3 — Full Scale**: auto-scaling, multi-region, dedicated для RBE + Yandex GPT/SpeechKit proxy/rate-limiting.

---

## 12. Roadmap (высокоуровневый)

1. **Foundation** — TPS controllers, ship flight, simple colony, ability system, local multiplayer.
2. **Core Loop + PvP** — multi-crew, AI-bots, Contribution/Biomass, basic PvP, ability system for MOBA, basic structures.
3. **Vertical Slice + MOBA Prototype** — one system, fleets, carriers seed, ground ops, contracts, Momentum system, basic Prompt Studio mock.
4. **Platform + Full Systems** — full alliance hierarchy/permissions, logistics, crafting/blueprints, ranked MOBA, Yandex GPT integration (dialogue + generation), **Yandex Alice voice control**, Proxy Contests.
5. **Scale & Polish** — optimization, more content, balance, moderation tools for generated content, voice UX polish.
6. **Launch** — public release + live-ops.

---

## Уникальные преимущества NAEON

- Playable антропоморфные киборги-животные + асимметричный playable gROT.
- Настоящая Resource-Based Economy + мост с NAEXOS.
- Глубокая интеграция Strategy + Space + TPS + MOBA.
- Полноценные альянсы с иерархией, permissions, shared resources и Strategy mode для лидеров.
- Carriers с дронами/истребителями, NPC fleets, глубокая логистика.
- Player-driven objectives, user contracts и prompt-generated content.
- **Живые ИИ-NPC, генерация контента по промптам и голосовое управление через Yandex Alice** прямо в клиенте.
- Soft Arena influence на persistent world без ломки MMO-loop.
- Freemium + подписка + токены (без P2W).
- Local-first + реалистичный путь на Yandex Cloud.

---

*Документ поддерживается командой разработки. Следующий шаг — детальный GDD по подсистемам и vertical slice в Godot.*
