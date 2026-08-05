# NAEON — Подробная концепция игры

**Версия:** 0.2 (обновлено 2026-08-05)  
**Репозиторий:** https://github.com/br7wq7yfqc-ctrl/naeon  
**Основа:** NAEXOS + вселенная Aexion

---

## 1. Высокоуровневое видение

**NAEON** — массивная многопользовательская онлайн-игра (MMO) в футуристической вселенной **Aexion**. Многожанровый проект, объединяющий:

- Глобальную стратегию (колонии, базы, ресурсы, fleets)
- Космический симулятор (модульные корабли, multi-crew, флоты до 30)
- Action/RPG от третьего лица (TPS)

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

- Цель: трансформация всего сущего в кибер-биомассу, управляемую единой нейросетью ROT.
- Игроки начинают как низкоранговые мутанты и продвигаются по иерархии.
- Уникальные механики: biomass harvesting/assimilation, mutation skill trees, hive-mind бонусы, биомеханический хоррор-стиль.
- Асимметричный геймплей: агрессивный PvP-фокус vs коллективная RBE Cybernex.

### Будущие расы
Модульная система фракций. Возможны нейтральные (древние AI, независимые колонии, remnant-расы), splinter-группы Cybernex/gROT. Разблокируются через лор и контент.

### NPC AI-боты
У каждой расы свои активные AI-боты, участвующие в геймплее:

- **Cybernex**: роботы-животные (workers, patrols, squad mates, advisors, civilian caretakers). Behavior trees + aiNEX-усиленные диалоги и адаптивное поведение.
- **gROT**: рои биомассы, elite mutants, infection spreaders, hierarchical guardians. Агрессивный pack AI, механики заражения.
- Боты заполняют мир, патрулируют, строят, сражаются, реагируют на действия игроков и участвуют в PvP/PvPvE.

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

**Основная петля**: Exploration / Colonization → Ship building → Space ops & fleets → Ground ops → Contribution / Biomass Rank → feedback в RBE / hierarchy.

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

---

## 5. aiNEX — AI-инструменты в игре

aiNEX — семейство AI-инструментов экосистемы NAEXOS:

- Colony planner / resource allocator
- Ship & module designer
- Combat / fleet tactics advisor
- Procedural mission & event generator
- Lore / dialogue enhancer для NPC
- Personal robot customization AI

**Доступ**:
- Базовые лимиты — бесплатно.
- Расширенные модели и высокий лимит — через подписку или высокий Contribution / активность на платформе.

---

## 6. Гейты вовлечения в NAEXOS.ONLINE

1. **Account linking** — единый аккаунт (SSO). Синхронизация прогресса и Trust Score.
2. **Onboarding / Knowledge gates** — квесты «Sync with NAEXOS Core»: отправить discovery / гайд в wiki платформы → in-game reward.
3. **Time-bank / Skill exchange** — обмен навыками (стратегия, design, coaching) на платформе → boost в RBE или cosmetics.
4. **Escrow & community deals** — услуги, связанные с игрой, через платформенный escrow.
5. **Cross-events & Battle Pass** — сезонные события с dual rewards (игра + платформа).
6. **In-game terminals** — deep links / embedded views к dashboard, AI Lab, forums, economy tools платформы.
7. **Community votes** — игроки влияют на приоритеты RBE через голосования на NAEXOS.ONLINE.

Цель гейтов: органично вовлекать игроков в реальную деятельность платформы (обмен навыками, фиксация знаний, команды, AI-tools).

---

## 7. Монетизация — Freemium + Subscription

**Freemium (бесплатно)**:
- Полный доступ к core gameplay всех слоёв.
- Обе фракции (Cybernex + gROT).
- PvP / PvPvE.
- Базовые AI-боты и limited aiNEX.
- Все системы прогрессии.

**Подписка (NAEXOS Premium / Cybernex Pass)** — удобство и cosmetics, **без pay-to-win**:
- Повышенные multipliers Contribution / Trust Score sync.
- Полный / приоритетный доступ к advanced aiNEX.
- Эксклюзивные cosmetics, варианты животных-форм / мутаций, модули внешнего вида.
- Дополнительные слоты multi-crew / private fleet options.
- Battle Pass tiers, priority matchmaking, expanded storage.
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

**Backend**:
- Godot dedicated servers (containerized).
- PostgreSQL + Redis.
- Interest management / spatial partitioning.
- RBE simulation как отдельный сервис (Go/Rust или Godot).

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
- Dynamic instance managers для Space/TPS (auto-scale)
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
2. **Core Loop + PvP** — модульные корабли, multi-crew, Contribution/Biomass, базовые AI-боты, PvP во всех слоях.
3. **Vertical Slice** — одна система с планетами, seamless-переходы, fleets, RBE simulation, account linking prototype.
4. **Platform Integration** — aiNEX tools, гейты в NAEXOS.ONLINE, subscription system.
5. **Scale & Polish** — interest management, optimization low-end, content, balance both factions.
6. **Launch** — public release + live-ops.

---

## Уникальные преимущества NAEON

- Playable антропоморфные киборги-животные + асимметричный playable gROT.
- Настоящая Resource-Based Economy + мост с реальной платформой обмена навыками NAEXOS.
- Глубокая интеграция трёх жанров + полноценный PvP/PvPvE на каждом слое.
- aiNEX как живой AI-слой внутри игры и платформы.
- Freemium без pay-to-win + осмысленные гейты в экосистему NAEXOS.ONLINE.
- Local-first разработка + реалистичный путь на Yandex Cloud.

---

*Документ поддерживается командой разработки. Следующий шаг — детальный GDD и vertical slice в Godot.*
