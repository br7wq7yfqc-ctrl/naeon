# NAEON — Подробный план разработки по фазам (для build-сессий)

**Версия:** 1.1  
**Дата:** 2026-08-05  
**Основа:** CONCEPT.md v0.3  
**Движок:** Godot 4.3+ / 4.4+  
**Принцип:** Local-first → Vertical Slices → Iterative Multiplayer → Platform Integration + MOBA

---

## Общие принципы

- **Local-first**: всё работает offline / в локальной сети до Phase 3+. Cloud (Yandex Cloud) только после устойчивого vertical slice.
- **Vertical Slice**: каждый значимый билд должен быть playable end-to-end (хотя бы частично).
- **Build-сессии**: 1–2 недельные спринты или интенсивные 3–5 дневные сессии (4–8 часов focused coding + ежедневный playtest).
- **Definition of Done (DoD)**: код + базовые тесты + playable в editor/export + проверка на low-end + обновление docs + PR review.
- **Инструменты**:
  - Git: main protected, feature branches, PR.
  - Tracking: GitHub Issues + Projects (Kanban).
  - CI: GitHub Actions (export check, headless tests).
  - Backend local: Docker Compose (Postgres, Redis, MinIO).
  - Profiling: Godot Profiler + low-end machine export каждый Phase.
- **Команда**: ориентир 3–4 человека (или solo с приоритизацией). Effort указан в человеко-днях (чел/дн).
- **Приоритет оптимизации**: low-end с самого начала (LOD, instancing, simplified physics, animation compression).
- **MOBA**: переиспользует TPS combat, ability system, AI-bots и character controllers — минимальный новый scope при максимальной ценности.

---

## Phase 0: Setup & Foundation
**Длительность:** 1–2 недели (1–2 build-сессии)  
**Effort:** 4–7 чел/дн  
**Цель:** Готовый рабочий скелет проекта + локальная инфраструктура.

### Ключевые deliverables
- Структура репозитория: `/godot`, `/docs`, `/docker`, `/scripts`, `CONCEPT.md`, `DEVELOPMENT_PLAN.md`
- Godot 4.x проект с базовыми сценами (placeholder player, empty space, empty planet surface)
- Input system + third-person camera skeleton
- Docker Compose: Postgres + Redis + MinIO
- Godot headless export + простой dedicated server scene
- MultiplayerAPI + ENet skeleton (server + client connect)
- GitHub Actions: basic export check (Windows/Linux)
- README с инструкциями запуска local

### DoD
- `godot --headless` запускает server
- Client подключается локально
- Docker up работает
- Проект открывается без ошибок

### Риски
- Несовместимость версий Godot / GDExtension
- Слишком сложный setup → упростить до минимума

**Зависимости:** нет

---

## Phase 1: Core Prototypes (TPS + Ship + Colony + Ability Foundation)
**Длительность:** 2–4 недели  
**Effort:** 14–22 чел/дн  
**Цель:** Три независимых playable прототипа + data-driven ability system (основа для open-world и MOBA).

### 1.1 TPS Core + Ability System (Lucas focus)
- Character controller: walk/run/sprint/jump + form-specific (climb feline, limited flight avian, tank canine)
- 3–4 базовые формы: Canine, Feline, Avian, Human-cyborg (+ базовые gROT placeholders)
- AnimationTree + IK
- Базовый combat: melee, simple ranged
- **Data-driven Ability System** (Resource-based): cooldown, cost, targeting, effects — переиспользуется в open-world и MOBA
- Health / Stamina / простой inventory + equipment slots
- **DoD**: переключение форм, базовый бой + 2–3 abilities в арене, 60+ FPS на low-end

### 1.2 Space Ship Core (Harper focus)
- Базовый корабль с custom force physics (thrust, rotation)
- Модульная система: Hull + модули (engine, weapon, shield, cargo) как сцены/ноды
- Простая UI экипировки модулей
- Оружие, щиты, health
- Camera (third-person ship + free look)
- **DoD**: экипировать модули, летать, стрелять, получать урон, save/load конфига корабля

### 1.3 Colony / Strategy Core (Benjamin focus)
- Планетарная поверхность + размещение модульных зданий (habitat, extractor, turret)
- Ресурсные ноды + extraction
- Локальный Contribution Score
- Простейший rule-based RBE allocator
- **DoD**: построить outpost, добыть ресурс, увидеть Contribution

### Cross
- Asset pipeline: Blender → Godot (GLTF + LOD groups)
- Dark-neon placeholder materials (emissive)
- Basic save system (local JSON)

**DoD Phase 1:** Три отдельных playable демо + работающая ability system.

**Риски:** Слишком много форм/модулей сразу → ограничить до 3 форм и 4–5 модулей. Ability system должна быть достаточно гибкой для MOBA kits.

---

## Phase 2: Integration of Core Loop + Basic Multiplayer + AI-bots + MOBA Seed
**Длительность:** 3–5 недель  
**Effort:** 20–32 чел/дн  
**Цель:** Соединить три прототипа в единый local multiplayer loop + AI-боты + базовый PvP + начало MOBA.

### Основные задачи
- **Seamless / loading transition**: посадка с корабля → TPS на поверхности
- **Multi-crew**: 2–4 игрока на одном корабле (роли), MultiplayerSynchronizer
- **AI-bots**: Cybernex animal-robots + gROT swarms (BehaviorTree / FSM + NavigationAgent3D)
- **Strategy / Space / TPS PvP** basics
- **RBE / Biomass**: глобальный pool, redistribution, Contribution / Biomass Rank
- **MOBA Seed**:
  - Basic arena scene (simple 3-lane or objective map)
  - 4 heroes (2 Cybernex + 2 gROT) с полноценными kits на базе ability system
  - Simple minion waves (reuse AI-bots)
  - Basic XP / leveling in arena
  - Simple gold + 2–3 items
  - Match start / end + win condition (destroy core placeholder)
- Networking: server authority для critical, prediction для movement

### DoD
- Local multiplayer: 2–4 игрока могут летать multi-crew, высадиться, построить/атаковать колонию, сражаться с AI-ботами
- Обе фракции playable
- RBE redistribution работает
- **MOBA prototype**: 3v3 или 4v4 arena match с 4 heroes, minions, leveling, items, win condition
- Нет критических desync

**Зависимости:** Phase 1 prototypes + ability system

**Риски:** Netcode complexity, balance между формами, performance с AI + MOBA entities

---

## Phase 3: Vertical Slice + Full MOBA Prototype
**Длительность:** 3–5 недель  
**Effort:** 22–35 чел/дн  
**Цель:** Полностью playable vertical slice одной звёздной системы + полноценный 5v5 (или 3v3) MOBA.

### Deliverables
- Одна система: 2–3 планеты + space + jump points
- Persistent local / server authority для колоний и ships
- Fleet system: до 10–15 кораблей, flagship strategic overlay
- Full boarding mechanics
- Advanced AI-bots
- NAEXOS gates prototype + aiNEX basic (colony planner + **MOBA builds**)
- Basic Progression: skill trees, modular equipment, mutation trees
- **MOBA Full Prototype**:
  - 5v5 (или polished 3v3) maps с 3 lanes + jungle
  - 6–8 heroes с polished kits
  - Full item shop (6 slots), last-hitting, objectives (towers, core, secondary)
  - Jungle camps + elite neutrals + basic Invasion Events
  - Match flow: draft/select → game → rewards (Contribution / Biomass)
  - Basic matchmaking (local / simple queue)
  - Post-match rewards pipeline

### DoD
- Полный цикл Strategy → Space → TPS → back
- PvP/PvPvE работает во всех слоях с AI
- Local persistent save
- **MOBA**: playable 5v5/3v3 match с полным циклом, rewards, AI minions/jungle
- Low-end playable
- Гейты и aiNEX placeholders работают

**Риски:** Scope creep (одна система + MOBA), balance, performance

---

## Phase 4: Platform Integration + Economy Deep + Ranked MOBA + Monetization
**Длительность:** 2–4 недели  
**Effort:** 14–22 чел/дн  
**Цель:** Реальная интеграция с NAEXOS.ONLINE + полноценная экономика + ranked MOBA + monetization hooks.

### Задачи
- Account linking (SSO / token) с NAEXOS.ONLINE
- Activity Mining + full RBE (projects, voting, events)
- Biomass hierarchy progression
- aiNEX advanced (включая MOBA draft/builds/post-match)
- Subscription system: feature flags (multipliers, aiNEX quota, cosmetics, hero skins, ability VFX)
- Cosmetics pipeline + shop skeleton
- Cross-events / Battle Pass (shared main + MOBA)
- **Ranked MOBA**: MMR, seasons, leaderboards, NAEXOS Trust Score sync
- More heroes / maps / balance pass
- Open-world MOBA Hotspots (optional smaller scale)

### DoD
- Гейты end-to-end
- Подписка влияет на UI и soft-multipliers (no P2W)
- Ranked MOBA работает + rewards pipeline
- Economy обеих фракций сбалансирована
- Документация интеграции

**Зависимости:** Phase 3 vertical slice + MOBA prototype

---

## Phase 5: Optimization, Scale Prep & Polish
**Длительность:** 3–5 недель  
**Effort:** 15–25 чел/дн  
**Цель:** Готовность к closed alpha + подготовка к Yandex Cloud.

### Задачи
- Interest management / spatial partitioning
- Aggressive LOD, MultiMesh, impostors, physics layers
- Animation compression, simplified distant AI
- Load testing (много AI-ботов + clients + MOBA instances локально)
- Docker → Terraform / IaC шаблоны для Yandex Cloud
- Monitoring skeleton
- Balance pass (PvP, forms, RBE vs Biomass, MOBA heroes/items)
- Full low-end preset + graphics options
- Bug fixing + UX polish
- Spectator mode / replay basics for MOBA

### DoD
- Стабильная симуляция 50–100+ entities + несколько MOBA matches локально
- Infra-as-code ready
- Closed alpha build exportable
- Performance targets достигнуты

---

## Phase 6: Closed Alpha → Open Beta → Launch Prep
**Длительность:** ongoing  
**Цель:** Живой сервис + контент + live-ops.

- Deploy на Yandex Cloud
- Real NAEXOS API integration
- Content expansion (больше систем, квестов, рас, MOBA maps/heroes)
- Analytics, anti-cheat basics, support tools
- Marketing / community gates + MOBA tournaments
- Full monetization live

---

## Рекомендуемый порядок build-сессий (первые 10–12 недель)

| Сессия | Фокус                                      | Главный результат                          |
|--------|--------------------------------------------|--------------------------------------------|
| 1      | Phase 0 + TPS controller + Ability System  | Playable animal form + 1–2 abilities       |
| 2      | Ship physics + modules                     | Fly & shoot                                |
| 3      | Colony placement + resources                | Build outpost                              |
| 4      | Multi-crew + basic net                     | 2 players on one ship                      |
| 5      | AI-bots + TPS combat                       | Fight with/against AI                      |
| 6      | Landing transition + PvP arena             | Full local loop                            |
| 7      | MOBA Seed: arena + 4 heroes + minions      | Playable 3v3/4v4 MOBA prototype            |
| 8–9    | Fleet + Strategy PvP + RBE + MOBA polish   | Vertical slice skeleton + better MOBA      |
| 10+    | Full MOBA maps/items/rewards + gates       | Playable vertical slice + solid MOBA       |

---

## Матрица рисков (топ)

| Риск                              | Вероятность | Влияние | Митигация                                      |
|-----------------------------------|-------------|---------|------------------------------------------------|
| Netcode desync / lag              | Высокая     | Высокое | Server authority + prediction early            |
| Scope creep (слишком много форм + MOBA) | Высокая | Высокое | Жёсткий лимит на Phase 1–3, reuse ability system |
| Performance с 30 ships + AI + MOBA | Средняя   | Высокое | Interest management + LOD + separate MOBA instances |
| RBE ощущается «не хватает agency» | Средняя     | Среднее | Visible impact + personal contribution         |
| Интеграция NAEXOS API задержится  | Средняя     | Среднее | Полноценный mock + browser gates               |
| Animation quality animal forms    | Высокая     | Среднее | Placeholder → polish later                     |
| MOBA balance / hero kit depth     | Средняя     | Высокое | Start with 4–6 heroes, iterate with playtests  |

---

## Следующие шаги прямо сейчас

1. Создать GitHub Project / Issues по Phase 0–1 задачам (включая Ability System).
2. Назначить owners на подсистемы (включая MOBA track).
3. Провести Phase 0 build-сессию (setup + first playable form + ability foundation).
4. Ежедневно: short playtest + update Issues.

---

*План живой. Обновляется по итогам каждой build-сессии. Следующий документ: TECHNICAL_ARCHITECTURE.md и GDD sections (включая MOBA GDD).*