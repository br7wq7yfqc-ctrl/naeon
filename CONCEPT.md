# NAEON — Подробная концепция игры

**Версия:** 0.8 (обновлено 2026-08-05)  
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
- Живое двустороннее голосовое общение с ИИ-NPC на естественном языке
- Голосовое управление через Yandex Alice / SpeechKit + open-source альтернативы
- Сюжетные кампании фракций, генерируемые квесты, конструктор квестов альянсов, живая история вселенной
- Всё на базе **Yandex GPT + Yandex SpeechKit** (с поддержкой open-source) при платной подписке + оплате токенов

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
У каждой расы свои активные AI-боты, участвующие в геймплее. Ключевые NPC поддерживают полноценный двусторонний голосовой диалог на естественном языке и выдают все типы квестов.

---

## 3. Геймплейные слои + PvP / PvPvE

### A. Глобальная стратегия
Persistent shared universe. Колонии, орбитальные станции, верфи, экстракторы. Модульное строительство + автоматизация через AI-ботов. PvP/PvPvE: contested systems, colony raids, resource denial, alliance wars, claim wars.

### B. Космический симулятор
Модульные корабли (Scout → Capital). Multi-crew. Флоты до 30 кораблей. Semi-Newtonian физика. PvP/PvPvE в open space.

### C. TPS Action/RPG
Третье лицо. Playable animal-robots (Cybernex) и мутант-формы (gROT). Skill trees, модульное снаряжение. Seamless переход. PvP/PvPvE на поверхности.

### D. MOBA Mode — Aexion Clash (NAEON Arena)
Third-person Action-RPG MOBA в формате PvPvE (5v5 / 3v3). Soft influence на persistent world (Momentum, Proxy Contests только для minor-объектов). Major-объекты защищены.

---

## 4. Базовые механики и петли (детально)

### 4.1 Режим стратегии для лидеров альянсов
Strategic Command Interface: galactic overview, приказы флотам, allocation shared resources, permissions, goals, Proxy Contests, aiNEX/Yandex GPT Strategic Advisor, голосовые команды.

### 4.2 Управление структурами
Космические базы (модульные), NPC-флоты, Carriers с дронами и истребителями. Ownership + granular permissions.

### 4.3 Наземные операции
Player-driven objectives, Contract Board, user-generated missions.

### 4.4 Добыча, торговля и логистика
Extraction → Haul (contracts / freighters) → Allocate via RBE → Craft → Build → Defend / Expand → Contribution feedback.

### 4.5 Социальная структура альянсов
Иерархия (кастомизируемые ранги), permissions matrix, shared resource pool, shared tasks, shared blueprints library.

### 4.6 Крафтинг и чертежи
Полная система blueprints: компоненты → modules → ships → bases → декорации. Research, reverse-engineering, prompt-generation.

---

## 5. Сюжет, квесты, события и коммуникация

### 5.1 Сюжетные кампании фракций

Две параллельные, асимметричные сюжетные кампании.

**Cybernex Campaign — «Awakening of NAEXOS»**
- Главы: пробуждение ключевых людей из гибернации, защита ARK/NEX, расширение сети колоний по принципам Venus Project, поиск древних технологий, противостояние экспансии gROT, внутренние идеологические конфликты (насколько строго следовать RBE).
- Unlock глав через Contribution Rank + выполнение story progress.
- Смесь scripted миссий, ground ops, space operations и alliance-scale objectives.
- Финал глав влияет на living lore (видимые изменения в мире, новые NPC, cosmetics, narrative flags), но **не даёт прямого power advantage**.

**gROT Campaign — «Ascension of the Swarm»**
- Главы: подъём по иерархии ROT, assimilation ключевых систем, превращение миров в biomass, получение милости ROT, борьба с Cybernex «ересью», внутренние power struggles.
- Unlock через Biomass Rank + story progress.
- Более агрессивный, horror-toned, hierarchical тон.
- Аналогично: living history + cosmetics / narrative, без hard power.

Кампании можно проходить solo / group / alliance. Прогресс сохраняется на персонаже / фракции.

### 5.2 Регулярные генерируемые NPC-квесты

- Ежедневные / еженедельные / динамические квесты от NPC-сетки.
- Генерация через **Yandex GPT + templates** (Prompt Studio backend):
  - Combat / clear zones
  - Logistics / transport / escort
  - Exploration / data recovery
  - Crafting / resource gathering
  - Social / diplomacy / training
  - Defense / fortification
- Параметры: фракция, локация, Contribution/Biomass rank игрока, текущие world events, alliance needs.
- Разнообразие + повторяемость без полной повторяемости текста/целей.
- Можно принимать несколько, есть daily/weekly caps на rewards.

### 5.3 Конструктор квестов для членов альянса

- Любой член (с соответствующими permissions) может создать квест через **Alliance Quest Constructor** (UI + Prompt Studio).
- Задаёт: тип objectives, локацию, сложность, награду (из shared alliance pool или personal), описание (можно сгенерировать GPT).
- Officers / Leaders утверждают (или auto-approve для низких наград).
- Квест появляется в Contract Board / Alliance Hub.
- Выполнение даёт Contribution создателю + исполнителю + shared pool feedback.
- Модерация + anti-abuse (caps, reports).

### 5.4 Механики наград и опыта за квесты

**Основные награды:**
- **Contribution Score** (Cybernex) / **Biomass Rank progress** (gROT)
- **Character XP** (skill trees, levels)
- **Hero Mastery XP** (для MOBA / forms)
- Ресурсы / компоненты (capped)
- Blueprints / recipe unlocks (редко)
- Cosmetics / titles / decorations (часто)
- Temporary multipliers / soft buffs (короткие)

**Принципы:**
- Soft и capped (daily/weekly limits).
- Performance-based (не только «сдал»).
- Alliance-shared rewards где уместно.
- Нет hard power-creep от квестов.
- Премиум-квесты и глобальные события дают **только narrative / cosmetic / lore rewards**.

### 5.5 Премиум-квесты и глобальные события

**Премиум-квесты (только для подписчиков NAEXOS Premium):**
- Чисто сюжетные, высококачественные, hand-crafted или GPT-enhanced.
- Входят в **живую историю вселенной** (новые lore entries, NPC reactions, world flavour text, temporary visual changes).
- **Не влияют на баланс MMO**: не дают ресурсов, Contribution, power, claims, blueprints combat-значимых.
- Награды: exclusive cosmetics, titles, lore codex entries, unique decorations, narrative flags, temporary visual auras.
- Доступны в специальных story hubs / через ключевых NPC.

**Глобальные события:**
- Server-wide или faction-wide (вторжения, пробуждения, ROT offensives, Cybernex expeditions, ancient discoveries).
- Могут быть открытыми для всех или иметь Premium-only narrative branches / cutscenes / exclusive follow-up quests.
- Влияние на баланс — только soft / temporary (как Arena Momentum) или чисто narrative.
- После события мир «запоминает» его (living history).

### 5.6 Сетка NPC, выдающих квесты (обе фракции)

**Cybernex:**
- **Core Advisors** (NEX/ARK) — campaign starters, high-level story, RBE guidance
- **Colony Governors** — local defense, expansion, logistics
- **Fleet Captains / Carrier Commanders** — space combat, escort, fleet ops
- **Research Directors** — exploration, data, blueprints
- **Logistics Coordinators** — transport, supply, contracts
- **Animal-Robot Mentors** (Canine, Feline, Avian и др.) — form training, hero mastery, personal growth
- **Quest Brokers / Contract Officers** — generated daily/weekly quests
- **Special Agents** — premium / global event quests

**gROT:**
- **ROT Proxies / Hierarchs** — campaign, hierarchy advancement, assimilation
- **Swarm Overseers** — combat, infection, biomass collection
- **Assimilation Specialists** — conversion of systems/colonies
- **Fleet Warlords** — aggressive space ops, raids
- **Biomass Harvesters** — extraction, logistics of biomass
- **Mutation Guides** — form/mutation progression
- **Quest Brokers** — generated quests (more aggressive tone)
- **Special Envoys of ROT** — premium narrative / global events

Все ключевые NPC поддерживают голосовой диалог и могут выдавать/комментировать квесты.

### 5.7 Встроенный игровой чат и коммуникационные хабы альянсов

**Глобальный / локальный чат:**
- Text chat: system, local, faction, alliance, private, group.
- Free для всех.
- Moderation tools + report system.
- Интеграция с NAEXOS (опциональный bridge).

**Alliance Communication Hubs:**
- Специальные пространства (в хабах / на базах / виртуальные).
- Text channels (general, officers, logistics, combat, random).
- Shared boards (quests, contracts, blueprints, announcements).
- Permissions-based access.

**Голосовые каналы:**
- Alliance voice channels (general, officers, fleet ops, ground ops и т.д.).
- **Доступ:**
  - По **подписке NAEXOS Premium**, или
  - За **выдающиеся достижения** (высокий Contribution / Biomass Rank, campaign completion, Arena rank, alliance leadership milestones).
- Технически: интеграция с Yandex SpeechKit / Alice + open-source alternatives (как и NPC voice).
- Spatial / proximity voice на станциях и в multi-crew (опционально).
- Push-to-talk default, continuous opt-in.
- Privacy controls, mute, deafen, channel permissions.

Голосовые коммуникации усиливают coordination лидеров и multi-crew, но не являются обязательными для прогресса.

---

## 6. Уникальность: Генерация контента, живые голосовые ИИ-NPC и голосовое управление

### 6.1 Prompt Studio / Creation Terminal
Генерация миссий, контрактов, blueprints, lore, декораций, диалогов (текст или голос).

### 6.2 Полноценный голосовой диалог с ИИ-NPC
Модульный pipeline: STT → NLU/LLM → TTS.  
Primary: Yandex SpeechKit + Yandex GPT.  
Open-source: Whisper / Vosk / Silero / Piper / Coqui / local LLMs.  
Player выбирает провайдера. Personality voices, interruptible, context-aware.

### 6.3 Голосовое управление
Alice / SpeechKit + open alternatives для Strategy, Space, TPS, Prompt Studio, UI.

### 6.4 Настройка SpeechKit
Streaming, multiple voices per NPC type, SSML, custom vocabulary, cost control via tokens, privacy opt-in, offline fallback.

---

## 7. Экономика

Cybernex — RBE (Contribution Score).  
gROT — Biomass hierarchy.  
Мост с NAEXOS.ONLINE (Trust Score, Activity Mining, Battle Pass).

---

## 8. aiNEX + Yandex GPT + SpeechKit + Open Voice Stack

Полный набор AI-инструментов + голосовой диалог + генерация + Strategic Advisor + Prompt Studio.

---

## 9. Гейты вовлечения в NAEXOS.ONLINE

Account linking, knowledge gates, time-bank, escrow, cross-events, terminals, community votes, MOBA + generated content contribution.

---

## 10. Монетизация — Freemium + Subscription + Tokens

**Freemium**: core gameplay + generated quests + text chat + open-source voice.

**NAEXOS Premium**:
- Advanced aiNEX + high-quality SpeechKit / Alice
- Premium narrative quests & exclusive global event branches
- Alliance voice channels
- Cosmetics, multipliers, priority, Battle Pass
- Continuous listening, full NPC dialogue, voice Prompt Studio

**Токены**: генерация и long voice dialogue.  
**Нет pay-to-win.** Premium quests и global events — только living history / cosmetics / lore.

---

## 11. Технологический стек

Godot 4.x + PostgreSQL + Redis + Yandex GPT + SpeechKit + open-source STT/TTS/LLM providers + modular voice stack.

---

## 12. Серверная инфраструктура

Local-first → Yandex Cloud (расчёт как ранее). Voice processing rate-limited и proxy’ится.

---

## 13. Roadmap (высокоуровневый)

1. Foundation  
2. Core Loop + PvP  
3. Vertical Slice + MOBA Prototype + basic quests + chat  
4. Full Systems (alliance constructor, campaigns seed, generated quests, voice dialogue, premium narrative)  
5. Scale & Polish  
6. Launch

---

## Уникальные преимущества NAEON

- Playable антропоморфные киборги-животные + асимметричный playable gROT
- Resource-Based Economy + мост с NAEXOS
- Strategy + Space + TPS + MOBA с soft Arena influence
- Полноценные альянсы + Strategy mode для лидеров
- Carriers, NPC fleets, глубокая логистика
- Сюжетные кампании фракций + генерируемые квесты + alliance quest constructor
- Премиум-квесты и глобальные события как living history (без влияния на баланс)
- Полноценный голосовой диалог с NPC + голосовое управление (Yandex + open-source)
- Встроенный чат и alliance voice hubs (voice по подписке / достижениям)
- Freemium + подписка + токены без P2W
- Local-first + Yandex Cloud

---

*Документ поддерживается командой разработки. Следующий шаг — детальный GDD по подсистемам и vertical slice в Godot.*
