# NAEON — Подробный план разработки по фазам (для build-сессий)

**Версия:** 2.0  
**Дата:** 2026-08-05  
**Основа:** CONCEPT.md v1.2  
**Движок:** Godot 4.3+ / 4.4+  
**Принцип:** Local-first → Vertical Slices → Iterative Multiplayer → Platform + AI + Educational Systems

---

## Общие принципы

- **Local-first**: всё работает offline / в локальной сети максимально долго. Yandex Cloud — только после устойчивого vertical slice.
- **Vertical Slice**: каждый значимый билд playable end-to-end.
- **Build-сессии**: 1–2 недельные спринты или 3–5 дневные интенсивные сессии.
- **Definition of Done**: код + playable в editor/export + low-end check + docs + PR.
- **Инструменты**: GitHub Issues/Projects, Docker Compose (Postgres/Redis), Godot Profiler, CI export checks.
- **Приоритет**: low-end optimization с Phase 0, data-driven systems (abilities, blueprints, quests), modular voice & AI providers.
- **Reuse**: Ability system → open-world TPS + MOBA + Hacking/Firewall. AI-bots → all layers. Prompt Studio / aiNEX → content + educational generation.

---

## Phase 0: Setup & Foundation
**Длительность:** 1–2 недели  
**Effort:** 4–8 чел/дн  
**Цель:** Рабочий скелет проекта + локальная инфраструктура.

### Deliverables
- Структура репозитория (`/godot`, `/docs`, `/docker`, `/scripts`)
- Godot 4.x проект, placeholder scenes (player, space, planet surface)
- Input + third-person camera skeleton
- Docker Compose: Postgres + Redis (+ MinIO)
- Godot headless + dedicated server scene + MultiplayerAPI/ENet skeleton
- Basic GitHub Actions export check
- README с local launch instructions

### DoD
- Headless server запускается
- Client подключается локально
- Docker up работает
- Проект открывается без ошибок

---

## Phase 1: Core Prototypes (TPS + Ship + Colony + Ability Foundation)
**Длительность:** 2–4 недели  
**Effort:** 16–25 чел/дн  
**Цель:** Три playable прототипа + data-driven Ability System (основа для combat, MOBA, Hacking/Firewall).

### 1.1 TPS Core + Ability System
- Character controller + 3–4 формы (Canine, Feline, Avian, Human-cyborg + gROT placeholders)
- AnimationTree + IK
- Data-driven Ability System (Resources): cooldown, cost, targeting, effects
- Базовый combat + 2–3 abilities
- Health / Stamina / inventory skeleton
- **DoD**: переключение форм, бой, abilities, 60+ FPS low-end

### 1.2 Space Ship Core
- Модульный корабль (Hull + engine/weapon/shield/cargo)
- Custom force physics, camera, basic combat
- **DoD**: экипировать, летать, стрелять, save/load

### 1.3 Colony / Strategy Core
- Поверхность + размещение зданий (habitat, extractor, turret)
- Ресурсные ноды + extraction + локальный Contribution
- Простейший RBE allocator
- **DoD**: построить outpost, добыть ресурс, увидеть Contribution

### Cross
- Asset pipeline (GLTF + LOD), dark-neon materials, local save

**DoD Phase 1:** Три отдельных playable демо + гибкая ability system.

---

## Phase 2: Core Loop Integration + Multiplayer + AI-bots + MOBA Seed + Basic Hacking/Firewall
**Длительность:** 3–5 недель  
**Effort:** 22–35 чел/дн  
**Цель:** Единый local multiplayer loop + AI-боты + PvP + MOBA seed + асимметричные способности.

### Задачи
- Seamless / loading transition (ship → TPS)
- Multi-crew (2–4 игрока, роли)
- AI-bots (Cybernex animal-robots + gROT swarms) — BehaviorTree / Navigation
- Basic Strategy / Space / TPS PvP
- RBE / Biomass pools + Contribution / Biomass Rank
- **Hacking / Infection (gROT) + Nex-Firewall (Cybernex)** — первые версии abilities (TPS + simple Strategy)
- **MOBA Seed**: arena, 4 heroes (kits на ability system), minion waves, XP/leveling, basic items, win condition
- Networking: server authority + prediction

### DoD
- 2–4 игрока: multi-crew → высадка → колония / бой с AI
- Обе фракции playable
- Hacking vs Firewall работают в TPS
- MOBA 3v3/4v4 prototype playable
- Нет критических desync

---

## Phase 3: Vertical Slice + Full MOBA + Dynamic Ownership Seed + Basic Quests & Knowledge
**Длительность:** 4–6 недель  
**Effort:** 28–42 чел/дн  
**Цель:** Playable vertical slice одной системы + полноценный MOBA + первые динамические трансформации + квесты + Knowledge foundation.

### Deliverables
- Одна система (2–3 планеты + space + jump points) — предпочтительно ARK или Helios Reach
- Persistent colonies / ships
- Fleet system (до 10–15 кораблей, flagship overlay)
- Carriers seed (hangar + drones/fighters)
- **Dynamic Ownership Transformation** (prototype): visual + mechanical swap Cybernex (Venus Project) ↔ gROT (biomass industrial) на 1–2 объектах
- Advanced AI-bots + NPC quest givers skeleton
- **Quest system foundation**: Contract Board, generated quests (templates), basic Alliance Quest Constructor
- **Knowledge & Skills foundation**: Knowledge Rank / Subject Mastery, optional Learning Nodes в квестах, soft combat integration (informational)
- **MOBA Full Prototype**: 5v5/3v3, 6–8 heroes, lanes + jungle, items, objectives, rewards pipeline, basic matchmaking
- aiNEX basic (colony planner + MOBA builds + simple educational puzzle generation)
- Voice foundation (open-source STT/TTS path first)

### DoD
- Полный цикл Strategy → Space → TPS → back
- Ownership transformation работает на prototype objects
- Educational puzzle nodes + soft combat knowledge effects
- Playable 5v5/3v3 MOBA + rewards
- Low-end playable

---

## Phase 4: Full Systems — Quests, Campaigns, Voice, Education, Social, Platform Hooks
**Длительность:** 4–6 недель  
**Effort:** 25–40 чел/дн  
**Цель:** Глубокие системы контента, социального взаимодействия, AI и образования.

### Задачи
- **Сюжетные кампании** (Cybernex «Awakening of NAEXOS» + gROT «Ascension of the Swarm») — первые 1–2 главы
- Полный Quest system: generated NPC quests, Alliance Quest Constructor, Premium narrative quests (story-only)
- **Educational Quests** с AI-генерируемыми головоломками как тестами (aiNEX)
- Полная soft-интеграция Subject Mastery в combat (все слои)
- **Voice stack**: Yandex SpeechKit / Alice + open-source providers (Whisper/Vosk/Piper/Silero), natural NPC dialogue, voice commands, alliance voice channels (Premium/achievements)
- Alliance social: hierarchy, permissions, shared resources/tasks, Communication Hubs
- Logistics + Transport Contracts + Carriers polish
- Crafting + full blueprints (включая decorations)
- Dynamic Ownership на большем числе объектов + contested transition states
- Account linking + Knowledge gates + Trust Score / Qualifications sync prototype
- Subscription flags + cosmetics pipeline
- Ranked MOBA + seasons + Trust Score sync

### DoD
- Кампании playable (первые главы)
- Educational quests + combat knowledge effects работают end-to-end
- Voice dialogue + commands (hybrid open/Yandex)
- Alliance hubs + voice channels
- Platform gates prototype
- No-P2W соблюдён

---

## Phase 5: Optimization, Scale Prep, Content Expansion & Polish
**Длительность:** 3–5 недель  
**Effort:** 18–30 чел/дн  
**Цель:** Готовность к closed alpha + подготовка Yandex Cloud + контент.

### Задачи
- Interest management / spatial partitioning
- Aggressive LOD, MultiMesh, animation compression, distant AI simplification
- Load testing (entities + MOBA instances + voice)
- Full star systems set (ARK, ROT-Prime, Helios Reach, Verdant Veil, Forge Depths, Echo Ruins…)
- More campaign chapters, generated content variety, educational tracks
- Balance pass (PvP, Hacking/Firewall, RBE vs Biomass, MOBA, soft knowledge effects)
- Terraform / IaC для Yandex Cloud
- Monitoring, anti-cheat basics, moderation tools for generated content
- Full low-end presets + graphics options
- Spectator / replay для MOBA
- UX polish (including educational UI, voice settings, ownership transition feedback)

### DoD
- Стабильная симуляция 50–100+ entities + multiple MOBA + voice
- Infra-as-code ready
- Closed alpha build
- Performance targets достигнуты

---

## Phase 6: Closed Alpha → Open Beta → Launch Prep
**Длительность:** ongoing  
**Цель:** Живой сервис + live-ops + полный контент.

- Deploy на Yandex Cloud
- Real NAEXOS.ONLINE API integration (Trust Score, Knowledge gates, skill exchange)
- Content expansion (больше систем, квестов, рас, MOBA maps/heroes, educational modules)
- Full monetization (Premium + tokens)
- Analytics, support tools, community events, MOBA tournaments
- Living history / global events pipeline
- Continuous balance и educational content updates

---

## Рекомендуемый порядок первых build-сессий (ориентир 12–16 недель)

| Сессия | Фокус | Главный результат |
|--------|-------|------------------|
| 1 | Phase 0 + TPS controller + Ability System | Playable form + 1–2 abilities |
| 2 | Ship physics + modules | Fly & shoot |
| 3 | Colony + resources + Contribution | Build outpost |
| 4 | Multi-crew + basic net | 2 players on one ship |
| 5 | AI-bots + TPS combat + Hacking/Firewall seed | Fight with/against AI + asymmetric abilities |
| 6 | Landing + PvP arena + Knowledge Rank foundation | Full local loop + soft knowledge |
| 7 | MOBA Seed (arena + 4 heroes + minions) | Playable 3v3/4v4 MOBA |
| 8–9 | Fleet + Carriers seed + Dynamic Ownership prototype + RBE | Vertical slice skeleton + transformable object |
| 10 | Quest system + Educational Nodes + aiNEX puzzles | Generated quests + learning tests |
| 11+ | Voice foundation + Alliance social + Campaigns seed + MOBA polish | Voice dialogue + social hubs + story start |

---

## Матрица рисков (топ)

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Netcode desync / lag | Высокая | Высокое | Server authority + prediction early |
| Scope creep (много систем) | Высокая | Высокое | Жёсткий vertical slice, reuse ability/AI systems |
| Performance (entities + MOBA + voice + transformation) | Средняя | Высокое | Interest management, LOD, separate instances, open-source voice first |
| Educational content quality / generation cost | Средняя | Среднее | Templates + curated knowledge base + rate limits + offline fallback |
| Voice latency / provider complexity | Средняя | Среднее | Modular providers, open-source first, hybrid mode |
| Ownership transformation visual complexity | Средняя | Среднее | Shader/material swap + gradual transition, start with few objects |
| Hacking/Firewall balance | Средняя | Высокое | Early playtests, strong counterplay, caps |
| Integration with NAEXOS.ONLINE delays | Средняя | Среднее | Full local mocks + browser gates |

---

## Следующие шаги прямо сейчас

1. Создать / обновить GitHub Project и Issues по Phase 0–1 (включая Ability System + Hacking/Firewall foundation).
2. Назначить owners на подсистемы (TPS/Abilities, Space/Carriers, Strategy/RBE, AI/Voice, Quests/Education, MOBA).
3. Провести Phase 0 build-сессию.
4. Ежедневно: short playtest + update Issues.
5. Параллельно вести TECHNICAL_ARCHITECTURE.md и GDD-секции (особенно Abilities, Knowledge, Voice, Dynamic Ownership).

---

*План живой. Обновляется по итогам каждой build-сессии. Актуальная версия CONCEPT.md — v1.2.*
