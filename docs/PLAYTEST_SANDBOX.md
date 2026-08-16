# NAEON — Sandbox playtest (Cursor VM)

**Дата прогона:** 2026-08-16  
**Стенд:** Cursor Cloud VM, Godot **4.3.stable.official.77dcf97d8**  
**GPU:** нет. Visible = **Mesa llvmpipe (LLVM 20.1.2)** / `gl_compatibility`. Headless = dummy renderer.  
**Ветка:** `cursor/canon-plan-playtest-f0c0`  
**Команда:** `scripts/playtest_sandbox.sh`  
**Зонд:** `godot/scripts/test/SandboxPlaytest.gd` (`--sandbox-playtest`)

Это отчёт «что ломается», не QA-stamp. **Человек не смог бы поиграть на этом стенде как на целевом клиенте.** FPS-половину rules/25 **не закрываем**.

Канон и очередь: `DEVELOPMENT_PLAN.md` v3 · `docs/design/ASSET_SOURCE_CANON.md`.  
WorldFill: `docs/design/WORLD_FILL.md` (параллельный контракт, PR #6).

Сырьё: `/opt/cursor/artifacts/sandbox_*.log` и `sandbox_playtest.txt`.

---

## 1. Вердикт

| Вопрос | Ответ |
|--------|-------|
| Пригоден ли прототип для человека? | **Нет.** |
| Можно ли ставить PASS? | **Нет.** |
| Нужен ли GPU владельца? | **Да** — для freeze/FPS и 5 мин глазами. llvmpipe ≠ Mac GPU. |
| Закрыт ли rules/25 FPS? | **Нет.** |
| Что делать дальше? | P0.1 Terrain — выключить live chaos, сузить срез. Не G1. |

Владелец прав: террейны хаотичны и генерятся на ходу; прототип не тест-харнесс для человека.

`--playtest-mechanics` напечатал `[Playtest] PASS` за тот же прогон. Это **не** допуск. Occupy-метр на «присутствии» уехал **0.55 → 0.08** (вниз), зонд всё равно прошёл. Телепорты ≠ 5 минут рук.

---

## 2. Что запускали

| Сцена | Как | Запускается? | Вылет процесса | SCRIPT ERROR | Примечание |
|-------|-----|--------------|----------------|--------------|------------|
| `MainMenu` | headless `--quit-after 6` | **да** (`MM_CODE=0`) | нет | **0** | Boot UI. Visible тоже поднялся (llvmpipe). |
| `OpenSpace` | headless `--quit-after 14` | **да** (`OS_CODE=0`) | нет | **0** | 3 тела + 7 стримеров на каждое. `ERROR Parameter "m" is null` × **108** (dummy mesh). |
| `TestArena` | headless `--quit-after 8` | **да** (`TA_CODE=0`) | нет | **0** | Clash greybox. `m is null` × **39**. |
| `OpenSpace` probe | `--sandbox-playtest` | **да**, 12.4 с | exit **137** (`OS.kill` после quit — 4.3 dummy) | **0** | `HUMAN_UNFIT`. `m is null` × 14. |
| Mechanics | `--playtest-mechanics` | да | exit **137** (тот же kill) | **0** | Печатает PASS. **Не human gate.** Occupy 0.55→0.08. |
| `OpenSpace` visible | x11 + llvmpipe | **да** | нет | **0** | Кадр: корабль над Nex-Prime, alt 770 м, GFX LOW. Дальняя сфера — шейдер-пятна, не чанки. |
| `TestArena` visible | x11 + llvmpipe | **да** | нет | **0** | Три неон-полосы, примитивы. Не карта галактики. |

ALSA: `ERR_CANT_OPEN` → dummy audio. Не краш сцены.

---

## 3. Вылеты и стек

**GDScript-вылета нет.** Процесс зонда завершается `OS.kill` → 137 — так же, как старый mechanics-харнесс (dummy renderer 4.3 не выходит после `quit()`).

Повторяющийся движковый шум (не SCRIPT ERROR):

```
ERROR: Parameter "m" is null.
```

`docs/systems/GODOT_ERROR_NOTES.md` уже помечает это как dummy `mesh_get_surface_count`. На visible llvmpipe сцены живут. Это **не** «можно давать человеку»: см. §4–5.

Стека Godot-crash (SIGSEGV) в этом прогоне **нет**. Жалоба владельца на вылеты на **его** машине этим VM не опровергнута и не подтверждена. Здесь ломает **live-rebuild + два мира на одной планете + семь стримеров**, не один null-mesh.

---

## 4. Фризы

На llvmpipe **не** измеряем FPS и не закрываем порог >100 мс. Считаем работу CPU-стримеров.

| Событие | Замер |
|---------|--------|
| Boot 3 тел | Каждое тело сразу спавнит Fauna/Flora/Water/Caves/Landscape. Лог: 3× полный набор до первого кадра игры. |
| Подход 80 м AGL | nodes **413 → 551** (+138), ram **38 → 42 MB**, `SurfaceDetail` live=1. Семь стримеров `proc=true vis=true`. |
| Сдвиг на 90 м | live **1 → 4**, queue **5**. Чанки **строятся на ходу** при движении. |
| Отлёт 400 м | live **0** — видимое **сброшено**. Flora/Fauna/Water/Caves/Landscape всё ещё `proc=true`. |
| Повторный заход 75 м | live **1** снова, не 4. Уже виденное **пересобрано с нуля**, не cache-restore кольца. |

Это и есть «генерятся на ходу» + «пересборка уже видимого».

---

## 5. Террейн

| Симптом владельца | Код | Рантайм 2026-08-16 |
|-------------------|-----|---------------------|
| Генерятся на ходу | `SurfaceDetail._process` | lateral: live 1→4, queue 5 |
| Пересборка уже видимого | `_park_all` >140 м AGL | retreat live=0; reapproach live=1 (не 4) |
| Swim / дыры | два домена; flora `hash(node.name)` | flora_on все три тела; park не глушит flora process |
| Орбита ≠ грунт | шейдер `% 97` vs Relief `% 10000` | **SAME=false** на всех трёх |
| Не воксельный шар | analytic + heightfield | подтверждено: вокселей нет |

Семена с зонда:

```
Nex-Prime  shader%97=61   relief%10000=2778  SAME=false
ROT-Hive   shader%97=46   relief%10000=2339  SAME=false
Shard-Moon shader%97=49   relief%10000=9485  SAME=false
```

Visible OpenSpace (alt **770 м**, выше park 140 м): человек видит **дальнюю сферу** — пятна суши/«реки» шейдера, не чанк под ногами. Чанки в этот момент выключены. Это ровно «с орбиты одна планета, на грунте другая».

`M` / `Tab` → `TestArena`. Гейты не спавнятся. G2–G6 файлов нет.

---

## 6. FPS / память

| Метрика | Цель | Этот VM |
|---------|------|---------|
| FPS min preset | ~60 (rules/25) | **не закрыто** — llvmpipe. Visible сам себя пометил `GFX: LOW`, adapter `n/a`. |
| 5 мин soak память | нет монотонного роста | зонд **~12 с**. 38→42 MB на подход. 5 мин **не** гоняли: короткий зонд не заменяет soak на GPU. |
| Nodes | лог | boot 413 → approach 551 → later 554 |

Не утверждаем «память стабильна». Утверждаем: узлы скачут вместе с live-чанками.

---

## 7. Что выкинуть, чтобы человек мог тестировать

1. Live flora / fauna / landscape / caves / water / terrain-edit в человеческом срезе.
2. Три планеты сразу — оставить Nex-Prime (потом 1 пад + 1 CC0 проп + 1 герой).
3. Дальний шейдер-фейк выключить, пока seed и сэмплер не одни.
4. Не считать `[Playtest] PASS` допуском (occupy 0.55→0.08 всё равно PASS).
5. Не открывать G1–G6. `M` подписать как «Clash sandbox», не карта.

---

## 8. Сырые логи

| Файл | Что |
|------|-----|
| `sandbox_playtest.txt` | строки зонда |
| `sandbox_openspace_probe.log` | полный stdout probe |
| `sandbox_openspace_boot.log` | boot 3 тел + 108× `m is null` |
| `sandbox_testarena.log` | Clash boot |
| `sandbox_mainmenu.log` | menu boot |
| `sandbox_mechanics.log` | unit-в-сцене + ложный PASS |
| `sandbox_visible_openspace.png` | llvmpipe кадр: сфера-фейк, alt 770 |
| `sandbox_visible_testarena.png` | llvmpipe кадр: неон-арены |

Локально зонд пишет `user://sandbox_playtest.txt`.

---

## 9. Как повторить

```bash
./scripts/playtest_sandbox.sh
# /tmp/sb_mm.log /tmp/sb_os.log /tmp/sb_ta.log /tmp/sb_os_probe.log /tmp/sb_mech.log

# visible (нужен DISPLAY; здесь :1 + llvmpipe):
#   ./scripts/run_godot_playtest.sh --scene res://scenes/world/OpenSpace.tscn
```

Не рисуйте PASS, если человек не смог бы поиграть.
