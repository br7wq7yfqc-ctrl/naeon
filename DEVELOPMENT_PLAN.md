# NAEON — Подробный план разработки по фазам (для build-сессий)

**Версия:** 1.0  
**Дата:** 2026-08-05  
**Основа:** CONCEPT.md  
**Движок:** Godot 4.3+ / 4.4+  
**Принцип:** Local-first → Vertical Slices → Iterative Multiplayer → Platform Integration

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

## Phase 1: Core Prototypes (TPS + Ship + Colony)
**Длительность:** 2–4 недели  
**Effort:** 12–20 чел/дн  
**Цель:** Три независимых playable прототипа, которые потом соединятся.

### 1.1 TPS Core (Lucas focus)
- Character controller: walk/run/sprint/jump + form-specific (climb feline, limited flight avian, tank canine)
- 3–4 базовые формы: Canine, Feline, Avian, Human-cyborg (+ базовые gROT placeholders)
- AnimationTree + IK
- Базовый combat: melee (claws/weapons), simple ranged, abilities placeholders
- Health / Stamina / простой inventory + equipment slots
- **DoD**: переключение форм, базовый бой в арене, 60+ FPS на low-end

### 1.2 Space Ship Core (Harper focus)
- Базовый корабль с custom force physics (thrust, rotation)
- Модульная система: Hull + модули (engine, weapon, shield, cargo) как сцены/ноды
- Простая UI экипировки модулей
- Оружие (projectile/laser), щиты, health
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

**DoD Phase 1:** Три отдельных playable демо работают стабильно.

**Риски:** Слишком много форм/модулей сразу → ограничить до 3 форм и 4–5 модулей.

---

## Phase 2: Integration of Core Loop + Basic Multiplayer + AI-bots
**Длительность:** 3–5 недель  
**Effort:** 18–28 чел/дн  
**Цель:** Соединить три прототипа в единый local multiplayer loop + AI-боты + базовый PvP.

### Основные задачи
- **Seamless / loading transition**: посадка с корабля → TPS на поверхности (position matching)
- **Multi-crew**: 2–4 игрока на одном корабле (Pilot / Gunner / Engineer / Commander), role-based input, MultiplayerSynchronizer
- **AI-bots**:
  - Cybernex: animal-robot workers, patrols, squad mates (BehaviorTree / FSM + NavigationAgent3D)
  - gROT: swarms, basic infection units
- **Strategy PvP**: claim system, простой raid (игроки + AI-боты)
- **Space PvP**: базовые open zones, damage sync
- **TPS PvP**: instanced arena + open hotspot skeleton
- **RBE / Biomass**: глобальный pool (local service), redistribution, Contribution / Biomass Rank
- **Networking**: server authority для critical (damage, claims), prediction для movement

### DoD
- Local multiplayer: 2–4 игрока могут летать multi-crew, высадиться, построить/атаковать колонию, сражаться с AI-ботами
- Обе фракции playable на базовом уровне
- RBE redistribution работает
- Нет критических desync

**Зависимости:** Phase 1 prototypes

**Риски:** Netcode complexity, balance между формами, performance с AI

---

## Phase 3: Vertical Slice (одна система)
**Длительность:** 3–5 недель  
**Effort:** 20–30 чел/дн  
**Цель:** Полностью playable vertical slice одной звёздной системы.

### Deliverables
- Одна система: 2–3 планеты + space + jump points
- Persistent local / server authority для колоний и ships
- Fleet system: до 10–15 кораблей (player + AI), flagship strategic overlay (базовые orders)
- Full boarding mechanics (transition to TPS interior/exterior)
- Advanced AI-bots (адаптивное поведение, роль в PvPvE)
- NAEXOS gates prototype: in-game terminal → mock deep-link / browser + quest “submit knowledge”
- aiNEX basic: rule-based colony planner + ship design suggestions (UI)
- Basic Progression: skill trees data-driven, modular equipment, mutation trees (gROT)
- Contribution / Biomass sync mock с Trust Score

### DoD
- Полный цикл: Strategy → Space (multi-crew + fleet) → TPS → back
- PvP/PvPvE работает во всех слоях с AI
- Local persistent save
- Low-end playable (профилирование пройдено)
- Гейты и aiNEX placeholders работают

**Риски:** Scope creep (одна система должна оставаться маленькой), seamless quality

---

## Phase 4: Platform Integration + Economy Deep + Monetization
**Длительность:** 2–4 недели  
**Effort:** 12–20 чел/дн  
**Цель:** Реальная интеграция с NAEXOS.ONLINE + полноценная экономика + monetization hooks.

### Задачи
- Account linking (SSO / token) с NAEXOS.ONLINE (или полноценный mock + real browser)
- Activity Mining: export discoveries → local wiki / API
- Full RBE: project proposals, voting, global events
- Biomass hierarchy progression
- aiNEX advanced: hooks к local/remote models (YandexGPT или self-hosted later), rate limits
- Subscription system: feature flags (multipliers, aiNEX quota, cosmetics unlock, private fleet slots)
- Cosmetics pipeline + shop skeleton
- Cross-events / Battle Pass placeholders

### DoD
- Гейты end-to-end (даже с mock API)
- Подписка влияет на UI и soft-multipliers (no P2W)
- Economy обеих фракций сбалансирована на vertical slice
- Документация интеграции

**Зависимости:** Phase 3 vertical slice

---

## Phase 5: Optimization, Scale Prep & Polish
**Длительность:** 3–5 недель  
**Effort:** 15–25 чел/дн  
**Цель:** Готовность к closed alpha + подготовка к Yandex Cloud.

### Задачи
- Interest management / spatial partitioning
- Aggressive LOD, MultiMesh, impostors, physics layers separation
- Animation compression, simplified distant AI
- Load testing (много AI-ботов + clients локально)
- Docker → Terraform / IaC шаблоны для Yandex Cloud
- Monitoring skeleton (Godot + external)
- Balance pass (PvP, forms, RBE vs Biomass)
- Full low-end preset + graphics options
- Bug fixing + UX polish

### DoD
- Стабильная симуляция 50–100+ entities локально
- Infra-as-code ready
- Closed alpha build exportable
- Performance targets достигнуты

---

## Phase 6: Closed Alpha → Open Beta → Launch Prep
**Длительность:** ongoing  
**Цель:** Живой сервис + контент + live-ops.

- Deploy на Yandex Cloud (Phase 1 calc: 25–50k ₽/мес)
- Real NAEXOS API integration (если доступна)
- Content expansion (больше систем, квестов, рас)
- Analytics, anti-cheat basics, support tools
- Marketing / community gates
- Full monetization live

---

## Рекомендуемый порядок build-сессий (первые 8–10 недель)

| Сессия | Фокус                          | Главный результат                     |
|--------|--------------------------------|---------------------------------------|
| 1      | Phase 0 + TPS controller       | Playable animal form                  |
| 2      | Ship physics + modules         | Fly & shoot                           |
| 3      | Colony placement + resources   | Build outpost                         |
| 4      | Multi-crew + basic net         | 2 players on one ship                 |
| 5      | AI-bots + TPS combat           | Fight with/against AI                 |
| 6      | Landing transition + PvP arena | Full local loop                       |
| 7–8    | Fleet + Strategy PvP + RBE     | Vertical slice skeleton               |
| 9+     | Polish + NAEXOS gates          | Playable vertical slice               |

---

## Матрица рисков (топ)

| Риск                              | Вероятность | Влияние | Митигация                              |
|-----------------------------------|-------------|---------|----------------------------------------|
| Netcode desync / lag              | Высокая     | Высокое | Server authority + prediction early    |
| Scope creep (слишком много форм)  | Высокая     | Высокое | Жёсткий лимит на Phase 1–3             |
| Performance с 30 ships + AI       | Средняя     | Высокое | Interest management + LOD с Phase 2    |
| RBE ощущается «не хватает agency» | Средняя     | Среднее | Visible impact + personal contribution |
| Интеграция NAEXOS API задержится  | Средняя     | Среднее | Полноценный mock + browser gates       |
| Animation quality animal forms    | Высокая     | Среднее | Placeholder → polish later             |

---

## Следующие шаги прямо сейчас

1. Создать GitHub Project / Issues по Phase 0–1 задачам.
2. Назначить owners на подсистемы.
3. Провести Phase 0 build-сессию (setup + first playable form).
4. Ежедневно: short playtest + update Issues.

---

*План живой. Обновляется по итогам каждой build-сессии. Следующий документ: TECHNICAL_ARCHITECTURE.md и GDD sections.*
