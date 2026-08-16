# NAEON — Sandbox playtest (Cursor VM)

**Дата прогона:** 2026-08-16  
**Стенд:** Cursor Cloud VM, Godot **4.3.stable**, renderer **llvmpipe / gl_compatibility** (нет игрового GPU).  
**Ветка прогона:** `cursor/canon-plan-playtest-f0c0`  
**Команда:** `scripts/playtest_sandbox.sh`  
**Зонд:** `godot/scripts/test/SandboxPlaytest.gd` (`--sandbox-playtest`)

Это отчёт «что ломается», не QA-stamp. **Человек не смог бы поиграть на этом стенде как на целевом клиенте.** FPS-половину rules/25 **не закрываем**.

Канон и очередь: `DEVELOPMENT_PLAN.md` v3 · `docs/design/ASSET_SOURCE_CANON.md`.  
WorldFill: `docs/design/WORLD_FILL.md` (параллельный контракт).

---

## 1. Вердикт

| Вопрос | Ответ |
|--------|-------|
| Пригоден ли прототип для человека? | **Нет.** |
| Можно ли ставить PASS? | **Нет.** |
| Нужен ли GPU владельца? | **Да** — для freeze/FPS и для «потрогать 5 минут глазами». llvmpipe ≠ Mac GPU. |
| Закрыт ли rules/25 FPS? | **Нет.** Только стабильность/вылеты/логи на этом VM. |
| Что делать дальше? | P0.1 Terrain — выключить live chaos, сузить срез. Не G1. |

Владелец прав: террейны хаотичны и генерятся на ходу; прототип не тест-харнесс для человека.

---

## 2. Что запускали

| Сцена | Как | Запускается? | Вылет процесса | SCRIPT ERROR | Примечание |
|-------|-----|--------------|----------------|--------------|------------|
| `MainMenu` | headless `--quit-after` | *(заполнить после прогона)* | | | Boot UI |
| `OpenSpace` | headless `--quit-after` + `--sandbox-playtest` | | | | Основной хаос террейна |
| `TestArena` | headless `--quit-after` | | | | Clash sandbox; `M` сюда режет |
| `OpenSpace` visible | `scripts/run_godot_playtest.sh` + timeout | | | | Только если DISPLAY жив |

Механик-зонд `--playtest-mechanics` **не** считается человеческим gate. Его строка PASS/FAIL пишется отдельно как «unit-в-сцене».

---

## 3. Вылеты и стек

*(заполнить из `/tmp/sb_*.log`)*

- Процесс Godot: exit codes, `OS.kill` после quit (dummy renderer 4.3 может не выйти).
- `SCRIPT ERROR` / `ERROR` / `WARNING` — цитаты, не пересказ.
- Если вылета нет, это **не** «можно давать человеку»: фризы и live-rebuild тоже ломают тест.

---

## 4. Фризы

На llvmpipe измеряем **wall-ms между тиками зонда**, не FPS.

| Событие | Ожидание | Замер |
|---------|----------|-------|
| Boot → `ready` | hitch при спавне 3 тел + 7 стримеров | |
| Подход <160 м AGL | SurfaceDetail + pads + flora/fauna/… | |
| Смена cell | enqueue + `_build_height_mesh` | |
| Отлёт >140 м + повторный заход | `_park_all` + полная пересборка | |
| `nearest_pad` / pad unload | rebuild from scratch | |

Порог плана: freeze >100 мс на **GPU владельца**. Здесь фиксируем только «было / не смогли измерить честно».

---

## 5. Террейн

Симптомы владельца обязательны. Код на `main` / этом checkout:

| Симптом | Код | Рантайм зонда |
|---------|-----|----------------|
| Генерятся на ходу | `SurfaceDetail._process` строит mesh; park сбрасывает live | |
| Пересборка уже видимого | `_park_all` + cache drop; pads `_unload_pads` «rebuilds from scratch» | |
| Swim / дыры | два домена (нормаль vs касательная `x,z`); flora seed от `node.name` | |
| Орбита ≠ грунт | шейдер seed `% 97`, Relief `% 10000` | |
| Не воксельный шар | analytic Relief + heightfield — верно; проблема не в вокселях | — |

Два сэмплера (статический факт, зонд печатает числа):

```
shader_seed = absi(planet_name.hash()) % 97
relief_seed = absi(planet_name.hash()) % 10000
flora_seed  = abs(hash(node.name)) % 10000
```

---

## 6. FPS / память

| Метрика | Цель | Этот VM |
|---------|------|---------|
| FPS min preset | ~60 (rules/25) | **не измеряем / не закрываем** — llvmpipe |
| 5 мин soak память | нет монотонного роста | короткий зонд; полный 5 мин на GPU |
| Nodes / static MB | лог | |

---

## 7. Что выкинуть, чтобы человек мог тестировать

См. `DEVELOPMENT_PLAN.md` §3. Кратко:

1. Выключить live flora/fauna/landscape/caves/water/terrain-edit в человеческом срезе.
2. Один остров: 1 пад + 1 CC0 проп + 1 герой. Не три планеты.
3. Дальний фейк выключить, пока не один сэмплер.
4. Не считать mechanics PASS допуском.
5. Не открывать G1–G6.

---

## 8. Сырые логи

Артефакты прогона копируются в `/opt/cursor/artifacts/` (имена `sandbox_*.log`).  
Локально зонд пишет `user://sandbox_playtest.txt` и stdout с префиксом `[Sandbox]`.

---

## 9. Как повторить

```bash
# Godot 4.3 в PATH
./scripts/playtest_sandbox.sh
# логи: /tmp/sb_import.log /tmp/sb_mm.log /tmp/sb_os.log /tmp/sb_ta.log /tmp/sb_os_probe.log
# optional visible (VM):
#   timeout 25 ./scripts/run_godot_playtest.sh --quit-after 20
```

Не рисуйте PASS, если человек не смог бы поиграть.
