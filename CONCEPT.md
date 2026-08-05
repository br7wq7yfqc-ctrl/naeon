# NAEON — Подробная концепция игры

**Версия:** 0.9 (обновлено 2026-08-05)  
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
- **Динамические миры**: планеты, базы и объекты меняют визуал и геймплей в зависимости от фракции-владельца
- Всё на базе **Yandex GPT + Yandex SpeechKit** (с поддержкой open-source) при платной подписке + оплате токенов

Игра полностью standalone, 3D, в тёмно-неоновых тонах, оптимизирована для слабых машин. Обе основные фракции полностью играбельны. Поддерживаются режимы **PvP** и **PvPvE** на всех слоях геймплея.

Цель: создать живой мир, где игроки строят утопию (Cybernex) или стремятся к абсолютному контролю (gROT), одновременно вовлекаясь в экосистему платформы **NAEXOS.ONLINE**.

---

## 2. Лор и фракции

### Вселенная Aexion
Сектор галактики с множеством звёздных систем, планет, астероидных полей и древних руин. Большая часть человечества находится в длительной гибернации внутри защищённого мега-города **NEX** на планете **ARK**.

### Cybernex (играбельна)
Кибернетическое общество: малочисленные люди-киборги + доминирующие **антропоморфные роботы-животные**. Идеология — Resource-Based Economy (Проект Венера). Цель — торжество NAEXOS.

### gROT (полностью играбельна)
Раса генетических киборгов-мутантов под властью ROT. Цель — трансформация всего сущего в кибер-биомассу.

### NPC AI-боты
У каждой расы свои активные AI-боты. Ключевые NPC поддерживают голосовой диалог и выдают все типы квестов.

---

## 3. Геймплейные слои + PvP / PvPvE

Strategy • Space Simulator • TPS Action/RPG • MOBA (Aexion Clash) с soft influence на persistent world.

---

## 4. Базовые механики и петли

Стратегия для лидеров альянсов, структуры (базы, NPC-флоты, Carriers), наземные операции, логистика, социальная иерархия, крафтинг и blueprints (включая декорации).

---

## 5. Сюжет, квесты, события и коммуникация

Сюжетные кампании фракций, генерируемые NPC-квесты, Alliance Quest Constructor, награды/XP, Premium narrative quests и глобальные события (living history, без влияния на баланс), сетка NPC, встроенный чат + Alliance Hubs с голосовыми каналами (Premium / achievements).

---

## 6. Основные звёздные системы и планеты

Мир Aexion построен вокруг **динамической ownership-системы**. Любая планета, орбитальная база, колония, станция или claimable-объект **визуально и механически трансформируется** при смене фракции-владельца.

### 6.1 Ключевые звёздные системы

#### 1. Система ARK (столица Cybernex)
- **Центральная планета: ARK** — дом мега-города **NEX**. Большая часть человечества в гибернации.
- Безопасная зона / стартовая для Cybernex. Сильная защита, высокий Contribution threshold для влияния.
- Орбитальные станции: NEX Relay, research rings, civilian habitats.
- Роль: политический, научный и RBE-хаб. Ключевые главы кампании Cybernex.

#### 2. Система ROT-Prime (столица gROT)
- **Центральный объект: ROT Nexus / Hive Core** — индустриально-органический мир / искусственная конструкция.
- Стартовая / безопасная зона для gROT. Иерархия ROT, biomass conversion hubs.
- Роль: центр assimilation, hierarchy advancement, ключевые главы кампании gROT.

#### 3. Система Helios Reach (пограничная contested)
- Планеты: **Helios Prime** (умеренная, ресурсная), **Ashen Moon**, астероидные поля.
- Классическая спорная зона. Часто становится ареной Proxy Contests и крупных fleet battles.
- Ресурсы: mixed energy + rare alloys. Важна для логистики.

#### 4. Система Verdant Veil
- Планеты: **Gaia-7** (пышная, биоразнообразная), **Mistworld**.
- Идеально подходит под Venus Project aesthetic Cybernex. Высокий потенциал для eco-colonies и research.
- Ресурсы: organic compounds, clean energy, rare flora data.

#### 5. Система Forge Depths
- Планеты: **Ironfall**, **Slag Belt** (астероиды + луны).
- Богата металлами и тяжёлыми элементами. Идеальна для mass-production gROT или industrial Cybernex.
- Высокий риск PvP, отличные места для carriers и logistics hubs.

#### 6. Система Echo Ruins
- Планеты: **Ancient Core**, **Silent Orbit**.
- Древние руины, data cores, forgotten technology. Ключевые для exploration-квестов и campaign side-branches.
- Ownership даёт доступ к unique research blueprints и lore.

#### 7. Система Twilight Expanse (дальняя)
- Планеты: **Dusk Haven**, **Void Anchor**.
- Поздний контент. Редкие ресурсы, аномалии, потенциальные будущие фракции / remnant AI.
- Высокий risk / reward.

Дополнительные minor systems и procedural nodes генерируются / открываются по мере live-ops.

### 6.2 Динамическая трансформация объектов при смене фракции

При захвате / claim (через Strategy + Space + TPS, с возможным soft-help от Arena Proxy Contests на minor-объектах) объект проходит **visual + mechanical transformation**.

#### Cybernex Ownership (стиль Проекта Венера)
**Визуал:**
- Чистые футуристические линии, органические формы, стеклянные купола, живые сады, вертикальные фермы, светлые неоновые акценты (cyan / white / soft green).
- Архитектура гармонично вписана в ландшафт: природа не уничтожается, а интегрируется.
- Animal-robot aesthetics, голографические интерфейсы, спокойный ambient light и звук.
- Колонии выглядят как утопические эко-города.

**Геймплей:**
- RBE-ориентированное производство: высокая эффективность, низкие отходы, бонусы к research и Contribution generation.
- AI-боты: animal-robots (workers, caretakers, patrols).
- Доступные структуры: Habitats, Research Labs, Clean Extractors, Logistics Hubs, Peaceful Defense Platforms.
- Мягкие defensive bonuses, лучше automated logistics, выше качество generated quests от местных NPC.
- Ambient: спокойный, оптимистичный, с элементами природы.

#### gROT Ownership (индустриальный постапок + биомасса)
**Визуал:**
- Тёмные, индустриальные, постапокалиптические пейзажи. Массивные трубы, споры, пульсирующая биомасса, роевые структуры, organic-mechanical hybrid architecture.
- Ландшафт частично «поглощён»: растительность заменяется biomass growth, почва — assimilation fields.
- Акцент на mass production: сборочные линии, harvesting towers, hive-spires.
- Освещение: тёмно-красный / фиолетовый / гнилостный neon, дым, споры в воздухе.

**Геймплей:**
- Biomass-oriented production: высокий выход Biomass / aggressive resource conversion, но выше «загрязнение» и risk.
- AI-боты: swarms, mutants, infection spreaders, hierarchical guardians.
- Доступные структуры: Assimilation Chambers, Biomass Refineries, Swarm Hives, Aggressive Defense Nests, Mutation Labs.
- Бонусы к offensive capabilities, faster aggressive expansion, выше yield при high-risk operations.
- Ambient: напряжённый, органический, industrial drone + biomass sounds.

#### Переходное состояние (Contested / Transition)
- При смене ownership объект проходит фазу трансформации (несколько часов или по прогрессу claim).
- Визуально: смешанные элементы (частично Venus-style, частично biomass).
- Геймплей: mixed production, доступны обе системы ботов с ограничениями, повышенный PvP risk.
- Полный переход завершается, когда claim закреплён и AI-боты / structures полностью заменены.

### 6.3 Влияние на другие системы
- **Arena Proxy Contests**: minor objects в этих системах могут временно менять ownership через Arena (с последующей visual transition).
- **Кампании**: ключевые главы привязаны к ARK, ROT-Prime, Echo Ruins и contested systems.
- **Квесты и NPC**: местные Governors / Captains / Overseers меняют диалоги, внешний вид и выдаваемые квесты в соответствии с текущим ownership.
- **Логистика и RBE/Biomass**: маршруты и эффективность extraction меняются в зависимости от того, под каким флагом находится система.
- **Living History**: крупные смены ownership фиксируются в lore и могут становиться частью global events / Premium narrative.

---

## 7. Уникальность: Генерация контента, живые голосовые ИИ-NPC и голосовое управление

Prompt Studio, полноценный голосовой диалог NPC (модульный STT → NLU → TTS), голосовое управление (Alice / SpeechKit + open-source), настройка SpeechKit.

---

## 8. Экономика

Cybernex — RBE (Contribution). gROT — Biomass hierarchy. Мост с NAEXOS.ONLINE.

---

## 9. aiNEX + Yandex GPT + SpeechKit + Open Voice Stack

Полный набор AI-инструментов + голосовой диалог + генерация + Strategic Advisor.

---

## 10. Гейты вовлечения в NAEXOS.ONLINE

Account linking, knowledge gates, time-bank, escrow, cross-events, terminals, community votes.

---

## 11. Монетизация — Freemium + Subscription + Tokens

Freemium core. Premium: advanced AI, voice channels, premium narrative quests, high-quality SpeechKit, cosmetics. Tokens for generation & long dialogue. **Нет pay-to-win.**

---

## 12. Технологический стек

Godot 4.x + PostgreSQL + Redis + Yandex GPT + SpeechKit + open-source STT/TTS/LLM + modular systems. Asset streaming / LOD для динамической смены visuals при ownership change.

---

## 13. Серверная инфраструктура

Local-first → Yandex Cloud (как ранее).

---

## 14. Roadmap (высокоуровневый)

1. Foundation  
2. Core Loop + PvP  
3. Vertical Slice + MOBA + basic systems + one transformable planet prototype  
4. Full Systems (ownership transformation, full systems set, campaigns, voice, quests)  
5. Scale & Polish  
6. Launch

---

## Уникальные преимущества NAEON

- Playable антропоморфные киборги-животные + асимметричный playable gROT
- Resource-Based Economy + мост с NAEXOS
- Strategy + Space + TPS + MOBA с soft Arena influence
- Полноценные альянсы + Strategy mode
- **Динамические планеты и объекты**: Venus Project harmony (Cybernex) vs industrial biomass post-apoc (gROT)
- Сюжетные кампании + генерируемые квесты + alliance quest constructor
- Премиум-квесты и глобальные события как living history
- Полноценный голосовой диалог с NPC + голосовое управление
- Встроенный чат и alliance voice hubs
- Freemium + подписка + токены без P2W
- Local-first + Yandex Cloud

---

*Документ поддерживается командой разработки. Следующий шаг — детальный GDD по подсистемам и vertical slice в Godot.*
