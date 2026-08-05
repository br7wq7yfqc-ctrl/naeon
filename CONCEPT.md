# NAEON — Подробная концепция игры

**Версия:** 1.2 (обновлено 2026-08-05)  
**Репозиторий:** https://github.com/br7wq7yfqc-ctrl/naeon  
**Основа:** NAEXOS + вселенная Aexion

---

## 1. Высокоуровневое видение

**NAEON** — массивная многопользовательская онлайн-игра (MMO) в футуристической вселенной **Aexion**. Многожанровый проект, объединяющий глобальную стратегию, космический симулятор, TPS Action/RPG и MOBA (Aexion Clash).

**Уникальность:** генерация контента по промптам, живое голосовое общение с ИИ-NPC, голосовое управление, динамические миры, глубокий лор раскола, сюжетные кампании, **личное развитие через обучение + интеграция знаний в боевой процесс**, living history.

Игра standalone, 3D, тёмно-неоновая, оптимизирована для слабых машин. Обе фракции полностью играбельны. PvP / PvPvE на всех слоях.

---

## 2. Лор и фракции (углублённый)

История раскола NAEXOS, конфликт создателей, Великая Гибернация, генетическая защита ноолюдей и антропоморфных роботов-животных, мотивации Cybernex и gROT, механики Infection Hacking vs Nex-Firewall.

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

ARK, ROT-Prime, Helios Reach, Verdant Veil, Forge Depths, Echo Ruins, Twilight Expanse + динамическая трансформация под фракцию.

---

## 7. Личное развитие игроков (Knowledge & Skills)

### 7.1 Основные принципы

- Полностью **опционально**. Core progress возможен без обучения.
- Soft rewards: Knowledge Rank, Subject Mastery, cosmetics, dialogue options, platform Trust Score / Qualifications, небольшие multipliers.
- **Нет pay-to-win**. Знания не дают прямого raw combat power (урон, HP, щиты).
- Генерация задач через **aiNEX** во взаимосвязи с NAEXOS.ONLINE.

### 7.2 Обучение во время квестов и Educational Quests

Во многих квестах появляются образовательные узлы. Кроме того, существуют dedicated **Educational Quests**, специально спроектированные вокруг учебных головоломок.

#### Учебные квесты с головоломками как тестом (AI-generated)

aiNEX создаёт квесты, в которых **учебная головоломка является ключевым тестом / gate**:

1. **Контекст**: NPC или терминал выдаёт задачу, связанную с текущей ситуацией (исследование руин, настройка firewall, анализ biomass, переговоры, навигация).
2. **Генерация**: aiNEX (Yandex GPT) создаёт задачу, адаптированную под:
   - Текущий Subject Mastery игрока
   - Контекст локации / фракции / квеста
   - Предыдущие успехи и слабые места
3. **Тест**: игрок должен решить реальную учебную задачу (математика, язык, логика, физика, биология, программирование, история лора).
4. **Результат**:
   - Успех → квест продолжается / открывается путь + Knowledge progress + награда
   - Неудача → можно использовать подсказки (ограниченно), упростить задачу, или пройти альтернативным (менее выгодным) путём
5. **Связь с платформой**: успешное решение может фиксироваться на NAEXOS.ONLINE как contribution в knowledge base / Qualifications.

**Примеры Educational Quests:**
- «Расшифруй древний код» — языковая + логическая задача
- «Рассчитай безопасную траекторию прыжка» — физика / математика
- «Настрой Nex-Firewall против нового malware» — логика + основы программирования / сетей
- «Определи тип biomass-образца и способ нейтрализации» — биология / генетика
- «Проведи переговоры с нейтральным AI» — язык + история / дипломатия

Квесты могут быть короткими (5–15 мин) или частью более длинных campaign / alliance chains. Сложность масштабируется. Полностью skippable с потерей educational rewards.

### 7.3 Интеграция Subject Mastery в боевой процесс (soft)

Знания **не увеличивают raw damage / HP / shields**. Вместо этого они дают **situational soft advantages**, тактическую глубину и качество-of-life:

| Subject Mastery       | Soft-эффект в бою (TPS / Space / Strategy)                                      |
|-----------------------|----------------------------------------------------------------------------------|
| **Languages**         | Лучшее понимание вражеских / нейтральных коммуникаций, расширенные dialogue options mid-combat, шанс заранее узнать intent AI-ботов или игроков через перехват сообщений |
| **Mathematics / Physics** | Более точные индикаторы траекторий, lead markers, энергопотребления; улучшенная информация о jump calculation и projectile prediction (QoL, не auto-aim) |
| **Biology / Genetics** | Лучшее распознавание типов biomass / infection, раннее предупреждение о стадиях заражения, улучшенные подсказки по purge / counter-infection |
| **Logic / Programming** | Более эффективный Nex-Firewall (быстрее заряд / выше resist chance), лучший анализ malware, дополнительные diagnostic tools в UI |
| **History / Lore**    | Расширенные тактические подсказки от AI-NPC в бою, знание слабостей определённых врагов / структур на основе лора, уникальные voice lines и callouts |
| **Logistics / Systems** | Лучший overview состояния корабля / отряда / базы во время боя, оптимизированные resource warnings, улучшенный multi-crew coordination feedback |

**Принципы баланса:**
- Эффекты informational / QoL / situational, а не «больше урона».
- Чем выше Mastery — тем качественнее информация и удобнее инструменты, но raw power остаётся равным.
- В PvP оба игрока имеют доступ к своим Mastery-эффектам → skill expression, а не paywall.
- В MOBA (Aexion Clash) Mastery даёт небольшие informational advantages и cosmetic / callout depth, но не ломает баланс героев.
- Можно полностью игнорировать — combat остаётся честным и полным.

### 7.4 Knowledge Rank и Subject Mastery — награды

- Progress в Knowledge Rank / отдельных Subject Masteries
- Soft multipliers в thematic активностях (research, crafting, navigation, firewall)
- Cosmetics, titles, decorations, unique dialogue
- Platform Trust Score / Qualifications / skill-exchange access
- Возможность создавать более сложные educational quests в Alliance Constructor

### 7.5 Генерация и доступ

- Free: базовые задачи + limited aiNEX generation
- Premium: адаптивные глубокие треки, персонализированные Educational Quests, лучшие подсказки, голосовое обучение (Alice)
- Tokens: сложные / длинные generative educational modules

Всё остаётся soft, optional и полностью соответствует no-P2W.

---

## 8. Уникальность: Генерация контента, живые голосовые ИИ-NPC и голосовое управление

Prompt Studio, полноценный голосовой диалог NPC, голосовое управление, aiNEX генерирует как обычный контент, так и **образовательные квесты с учебными головоломками**.

---

## 9. Экономика

Cybernex — RBE (Contribution). gROT — Biomass hierarchy. Мост с NAEXOS.ONLINE (включая Knowledge / Qualifications).

---

## 10. aiNEX + Yandex GPT + SpeechKit + Open Voice Stack

Полный набор AI-инструментов + голосовой диалог + генерация контента и образовательных задач + Strategic Advisor.

---

## 11. Гейты вовлечения в NAEXOS.ONLINE

Account linking, knowledge gates (включая educational progress), time-bank / skill exchange, escrow, cross-events, terminals, community votes.

---

## 12. Монетизация — Freemium + Subscription + Tokens

Freemium core + basic educational content.  
Premium: advanced educational generation, deeper tracks, exclusive narrative.  
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
4. Full Systems (включая Knowledge integration в combat + AI educational quests)  
5. Scale & Polish  
6. Launch

---

## Уникальные преимущества NAEON

- Глубокий лор раскола NAEXOS / gROT
- Playable антропоморфные киборги-животные + ноолюди + асимметричный gROT
- Асимметричные способности: Infection Hacking vs Nex-Firewall
- Resource-Based Economy + мост с NAEXOS
- **Личное развитие + soft-интеграция знаний в боевой процесс + AI-генерируемые учебные квесты с реальными головоломками**
- Strategy + Space + TPS + MOBA с soft Arena influence
- Динамические планеты и объекты
- Сюжетные кампании + генерируемые квесты + alliance quest constructor
- Премиум-квесты и глобальные события как living history
- Полноценный голосовой диалог с NPC + голосовое управление
- Встроенный чат и alliance voice hubs
- Freemium + подписка + токены без P2W
- Local-first + Yandex Cloud

---

*Документ поддерживается командой разработки. Следующий шаг — детальный GDD по подсистемам и vertical slice в Godot.*
