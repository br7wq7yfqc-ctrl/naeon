# NAEON — Подробная концепция игры

**Версия:** 1.1 (обновлено 2026-08-05)  
**Репозиторий:** https://github.com/br7wq7yfqc-ctrl/naeon  
**Основа:** NAEXOS + вселенная Aexion

---

## 1. Высокоуровневое видение

**NAEON** — массивная многопользовательская онлайн-игра (MMO) в футуристической вселенной **Aexion**. Многожанровый проект, объединяющий глобальную стратегию, космический симулятор, TPS Action/RPG и MOBA (Aexion Clash).

**Уникальность:** генерация контента по промптам, живое голосовое общение с ИИ-NPC, голосовое управление, динамические миры, глубокий лор раскола, сюжетные кампании, **личное развитие через обучение языкам и учебным дисциплинам**, living history.

Игра standalone, 3D, тёмно-неоновая, оптимизирована для слабых машин. Обе фракции полностью играбельны. PvP / PvPvE на всех слоях.

---

## 2. Лор и фракции (углублённый)

История раскола NAEXOS, конфликт создателей, Великая Гибернация, генетическая защита ноолюдей и антропоморфных роботов-животных (с ограничениями, компенсируемыми моделью NAEXOS), мотивации Cybernex и gROT, механики Infection Hacking vs Nex-Firewall.

---

## 3. Геймплейные слои + PvP / PvPvE

Strategy • Space Simulator • TPS Action/RPG • MOBA (Aexion Clash) с soft influence на persistent world.

---

## 4. Базовые механики и петли

Стратегия для лидеров альянсов, структуры, наземные операции, логистика, социальная иерархия, крафтинг и blueprints.

---

## 5. Сюжет, квесты, события и коммуникация

Сюжетные кампании фракций, генерируемые NPC-квесты, Alliance Quest Constructor, награды/XP, Premium narrative quests и глобальные события, сетка NPC, чат + Alliance Hubs с голосовыми каналами.

---

## 6. Основные звёздные системы и планеты

ARK, ROT-Prime, Helios Reach, Verdant Veil, Forge Depths, Echo Ruins, Twilight Expanse + динамическая трансформация под фракцию (Venus Project harmony vs industrial biomass).

---

## 7. Личное развитие игроков (Knowledge & Skills)

Одна из ключевых особенностей NAEON — **обучение и личное развитие** прямо в игровом процессе. Это напрямую связано с философией NAEXOS и платформы NAEXOS.ONLINE (обмен навыками, фиксация знаний, Qualification Levels).

### 7.1 Основные принципы

- Полностью **опционально**. Core progress (Contribution, корабли, колонии, combat) возможен без обучения.
- Soft rewards: Knowledge Rank, language proficiency, subject mastery, cosmetics, dialogue options, platform Trust Score / Qualifications, небольшие multipliers.
- **Нет pay-to-win**. Знания не дают прямого боевого преимущества.
- Генерация задач через **aiNEX** (Yandex GPT) во взаимосвязи с NAEXOS.ONLINE.
- Поддержка реальных учебных дисциплин и языков в контексте вселенной Aexion.

### 7.2 Механики обучения во время квестов

Во многих квестах (особенно research, exploration, logistics, diplomacy, campaign side-objectives) появляются **образовательные узлы / головоломки**:

- Игрок сталкивается с задачей, требующей знания языка, математики, физики, биологии, логики, истории, программирования, астрономии и т.д.
- Задачи могут быть:
  - Встроенными в диалог с NPC (голосовой или текстовый)
  - Интерактивными головоломками на объектах / терминалах
  - Расчётами для навигации, extraction, crafting, firewall configuration
  - Переводом / расшифровкой данных на «древних» или фракционных языках
- Правильный ответ → progress в соответствующем навыке + награда.
- Неправильный / пропуск → квест можно продолжить, но без educational reward.

**Примеры:**
- Языки: перевод сообщений, переговоры с NPC, расшифровка логов (русский, английский, «древний код», фракционные диалекты).
- Математика / физика: расчёт траекторий прыжка, оптимизация extraction, балансировка энергосистем корабля.
- Биология / генетика: анализ biomass-образцов, понимание ограничений генетического редактирования.
- Логика / программирование: настройка Nex-Firewall, написание простых скриптов для AI-ботов, расшифровка malware.
- История / лор: ответы на вопросы о расколе, создателях, гибернации (углубляют immersion).

### 7.3 Генерация через aiNEX + связь с NAEXOS.ONLINE

- **aiNEX** генерирует задачи, адаптированные под:
  - Уровень Knowledge Rank игрока
  - Текущий контекст квеста / локации / фракции
  - Предыдущие успехи / ошибки игрока
- Задачи могут быть простыми (free) или более глубокими / персонализированными (Premium + токены).
- Успешное решение и фиксация знания может:
  - Отправляться как contribution в knowledge base NAEXOS.ONLINE (Activity Mining / Knowledge gates)
  - Повышать **Trust Score** и **Qualification Levels** на платформе
  - Разблокировать skill-exchange возможности (игрок может «учить» других или получать бусты)
- Игрок может сознательно запрашивать учебные модули через Prompt Studio / terminals («aiNEX, дай мне задачу по орбитальной механике уровня 3»).

### 7.4 Knowledge Rank и Subject Mastery

- **Knowledge Rank** — общий показатель образовательного прогресса.
- **Subject Mastery** — отдельные треки: Languages, Mathematics, Physics, Biology/Genetics, Logic/Programming, History/Lore, Logistics/Systems и др.
- Mastery даёт:
  - Новые dialogue options и более глубокие разговоры с NPC
  - Soft multipliers в соответствующих активностях (research, crafting, navigation, firewall efficiency)
  - Cosmetics, titles, decorations, unique blueprints (educational-themed)
  - Прогресс в platform Qualifications
  - Возможность создавать более сложные educational quests в Alliance Constructor

### 7.5 Награды и баланс

- XP / Contribution / Biomass — небольшие, capped.
- Knowledge Rank / Subject Mastery progress.
- Cosmetics, titles, lore entries, unique decorations.
- Soft temporary или permanent multipliers (очень небольшие, тематические).
- Platform rewards (Trust Score, Qualifications, skill-exchange access).
- Premium: более сложные / интересные генерируемые задачи, персонализированные учебные треки, exclusive educational narrative content.

Всё остаётся soft и optional. Игрок, который игнорирует обучение, не теряет возможность прогрессировать в core MMO-loop. Игрок, который учится, получает дополнительную глубину, immersion и связь с реальной платформой NAEXOS.ONLINE.

---

## 8. Уникальность: Генерация контента, живые голосовые ИИ-NPC и голосовое управление

Prompt Studio, полноценный голосовой диалог NPC (модульный STT → NLU → TTS), голосовое управление (Alice / SpeechKit + open-source), настройка SpeechKit. aiNEX также генерирует образовательные задачи.

---

## 9. Экономика

Cybernex — RBE (Contribution). gROT — Biomass hierarchy. Мост с NAEXOS.ONLINE (включая Knowledge / Qualifications).

---

## 10. aiNEX + Yandex GPT + SpeechKit + Open Voice Stack

Полный набор AI-инструментов + голосовой диалог + генерация контента и **образовательных задач** + Strategic Advisor.

---

## 11. Гейты вовлечения в NAEXOS.ONLINE

Account linking, knowledge gates (включая образовательный progress), time-bank / skill exchange, escrow, cross-events, terminals, community votes.

---

## 12. Монетизация — Freemium + Subscription + Tokens

Freemium core + basic educational content.  
Premium: advanced aiNEX educational generation, deeper personalized tracks, exclusive narrative.  
Tokens for complex generation. **Нет pay-to-win.**

---

## 13. Технологический стек

Godot 4.x + PostgreSQL + Redis + Yandex GPT + SpeechKit + open-source STT/TTS/LLM + modular systems.

---

## 14. Серверная инфраструктура

Local-first → Yandex Cloud.

---

## 15. Roadmap (высокоуровневый)

1. Foundation  
2. Core Loop + PvP  
3. Vertical Slice + MOBA + basic systems  
4. Full Systems (включая Knowledge & educational quests + aiNEX generation)  
5. Scale & Polish  
6. Launch

---

## Уникальные преимущества NAEON

- Глубокий лор раскола NAEXOS / gROT и генетической защиты
- Playable антропоморфные киборги-животные + ноолюди + асимметричный gROT
- Асимметричные способности: Infection Hacking vs Nex-Firewall
- Resource-Based Economy + мост с NAEXOS
- **Личное развитие: обучение языкам и учебным дисциплинам прямо в квестах + реальные образовательные головоломки через aiNEX**
- Strategy + Space + TPS + MOBA с soft Arena influence
- Динамические планеты и объекты (Venus Project vs industrial biomass)
- Сюжетные кампании + генерируемые квесты + alliance quest constructor
- Премиум-квесты и глобальные события как living history
- Полноценный голосовой диалог с NPC + голосовое управление
- Встроенный чат и alliance voice hubs
- Freemium + подписка + токены без P2W
- Local-first + Yandex Cloud

---

*Документ поддерживается командой разработки. Следующий шаг — детальный GDD по подсистемам и vertical slice в Godot.*
