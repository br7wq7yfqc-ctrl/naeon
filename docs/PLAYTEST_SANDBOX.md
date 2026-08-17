# NAEON — Sandbox playtest (P0.6 + headless история)

**Текущий человеческий факт:** 2026-08-17, **RTX 3090**, коммит `ca904ec` / P0.6 (squash `987cd34`).  
Петля land / EVA / takeoff работает. Hold-S: 770→0. HOVER+S тонет. EVA стоит на Relief.  
Soak **6 мин без краша, 60 FPS, 0 debugger errors.** Галактику не открывали.

**Не ставить FPS PASS на llvmpipe.** Headless mechanics PASS ≠ человеческий gate.

Дальше по бару подхода: `docs/design/OPEN_SPACE_SC_BENCHMARK.md`.  
Канон: `docs/design/ASSET_SOURCE_CANON.md` · `docs/design/WORLD_FILL.md`. G2–G6 закрыты.

Ниже — исторический прогон VM (dummy / llvmpipe) и P0.1–P0.2 зонд. Это не отмена 3090.

**Стенд VM:** Cursor Cloud, Godot **4.3.stable.official.77dcf97d8**, GPU нет.  
**Ветка зонда:** `cursor/p0-runtime-stabilize-3ba8` · `scripts/playtest_sandbox.sh`

Сырьё зонда: `/opt/cursor/artifacts/sandbox_*.log` и `user://sandbox_playtest.txt`.

---

## 1. Вердикт

| Вопрос | Ответ |
|--------|-------|
| Петля на RTX 3090 (P0.6)? | **Да.** Посадка / EVA / взлёт, hold-S 770→0, HOVER+S, 6 мин / 60 FPS, 0 debugger errors. |
| FPS PASS на llvmpipe / dummy? | **Нет.** Не закрывать rules/25 с этого стенда. |
| P0.1 runtime (seed / ring / park)? | **Да, на зонде.** `P0_1_RUNTIME=true` `RING_RESTORE=true` `SAME=true` |
| P0.2 срез (1 пад + 1 CC0 проп)? | **Да, на зонде.** `P0_2_SLICE=true` pads=1 filler=1. Манифест, не GLB в git. |
| Mechanics? | Печатает PASS. Occupy 0.55→0.66 к gROT. **Не human gate.** |
| Dummy `m is null`? | **0 на зонде** (счётчик не маскировали). |
| Бар SC-подхода закрыт? | **Нет.** Игрушечный масштаб, шов сферы, нет атмосферы — см. OPEN_SPACE_SC_BENCHMARK. |

---

## 2. Что запускали

Коды 137 = `timeout -s KILL` / `OS.kill` после settle. Ожидаемо: `SceneTree.quit()` / `--quit-after` на dummy сами кормят `mesh_get_surface_count`.

| Сцена | Код | SCRIPT ERROR | MNULL | Примечание |
|-------|-----|--------------|-------|------------|
| MainMenu | 137 | **0** | **0** | Clash кнопка = sandbox, не карта |
| OpenSpace boot | 137 | **0** | **0** | 1 тело. Fill cut. Было 29 (teardown) |
| TestArena | 137 | **0** | **0** | Clash greybox. Было 42 (teardown) |
| Sandbox probe | 137 (`OS.kill`) | **0** | **0** | зонд dummy. P0.1+P0.2 green. Было 9. Не FPS PASS |
| Mechanics | 137 | **0** | **0** | PASS. Было 220 (interior/pylon/limbs/rover free) |

---

## 3. Что стало лучше (этот прогон)

Сырой дамп dummy-зонда. Строка `VERDICT=HUMAN_UNFIT` — вердикт llvmpipe/dummy, **снят** прогоном RTX 3090 / P0.6 (§6).

```
seed Nex-Prime body=2778 shader=2778 detail=2778 SAME=true
bodies_spawned=1
detail[approach]   live=6 queue=3 cache=6 parked=false alt=65.9
detail[lateral]    live=7 queue=4 cache=11 parked=false alt=66.1
detail[retreat_400m] live=0 queue=0 cache=11 parked=true alt=392.7
detail[reapproach] live=9 queue=0 cache=14 parked=false alt=62.6
RING_RESTORE=true
P0_1_RUNTIME=true
pads=1
filler_props=1
filler_source=Poly Haven · CC0-1.0 · https://polyhaven.com/a/wooden_crate_01
null_mesh_instances=0
P0_2_SLICE=true
MECHANICS_IS_NOT_HUMAN_GATE=true
VERDICT=HUMAN_UNFIT
```

| Факт | Было (OS 29 / TA 42 / probe 9 / mech 220) | Стало |
|------|------------------------------------------|-------|
| Seed | SAME=true | **SAME=true** (не сломали) |
| Тела | 1, fill cut | **1, fill cut** |
| Кольцо | live=9 cache=14 | **live=9 cache=14** |
| Пады | 1 + CC0 filler | **1 + CC0 filler** |
| Nodes boot → approach | 183 → 229 | **183 → 196** |
| RAM approach | 35 MB | **33 MB** |
| Occupy | 0.55→0.66 | **0.55→0.66** (не gate) |
| MNULL | 29 / 42 / 9 / 220 | **0 / 0 / 0 / 0** |

Человек на GPU должен увидеть: одну пластину пада + один ящик (proxy, пока GLB не на `s3://neon`). Не галактику. Не героя.

---

## 4. Mechanics (не human gate)

```
occupy presence meter 0.55 -> 0.66 side=gROT
harvest in-zone 0.02 -> 1 status=extracting
harvest landed-ship 1 -> 1.99
harvest after launch 2.06 -> 2.06
[Playtest] PASS
MECHANICS_IS_NOT_HUMAN_GATE=true
```

Один пад + controller-only BaseBuilder. Летающий корпус после launch extractor не держит.

---

## 5. Dummy `m is null` — что срезали

`ERROR Parameter "m" is null` @ `dummy/storage/mesh_storage.h:120` = `mesh_get_surface_count` внутри dummy. Не SCRIPT ERROR. Не `mesh==null` в дереве (`null_mesh_instances=0`). Счётчик **не** фильтровали.

Источники, которые давали 29 / 42 / 9 / 220:

1. **Teardown** — `SceneTree.quit()` / `--quit-after` обходит null RID. Playtest теперь `timeout -s KILL` / `OS.kill`.
2. **Interior exit** — `queue_free` кармана с MeshInstance. На dummy карман = collision/markers only.
3. **Плита пада / чанки** — add MeshInstance mid-session. На dummy: коллизия пада + Node3D-маркеры кольца (live/cache те же).
4. **Lock-claim pylon** — `_ensure_claim_beacon` строил 7 мешей и на следующем claim их free. Skip на dummy.
5. **seat→pilot** — free волкера с 4 limb RID. Skip limb rig на dummy.
6. **Rover store** — free корпуса. Skip visual на dummy.

Соседи того же среза:

- Меню Quit на dummy = `OS.kill`, не `quit()`.
- FloatingOrigin: один `rebase_now` на boot; mid-session rebase на dummy выключен (hitch + RID walk).
- P0 one-pad: hide, не `_unload_pads()` (free + hitch + память-треш).
- Память: approach 33 MB, nodes 196. Не разгружаем единственный пад.

`null_mesh_instances=0`. Ошибка была внутри dummy renderer.

---

## 6. GPU RTX 3090 — P0.6 (17 Aug 2026)

Владелец, `ca904ec` / P0.6:

- OPEN SPACE: land / EVA / takeoff живы.
- Hold-S спускает 770→0. HOVER+S тонет (не держит PD).
- EVA стоит на Relief, не в пустоте под чанком.
- Soak **6 мин**, без краша, **60 FPS**, **0 debugger errors**.
- Галактику не открывали.

Ранние прогоны на той же линии (P0.3–P0.5): спуск 770 м, LAND READY→LANDED, кольцо без swim/дыр; HUD/окно/взлёт чинили без выдуманных багов.

Повтор: F5 → OPEN SPACE → hold S → E land → F EVA → F board → Space takeoff.

llvmpipe этого не подтверждает и **не** ставит FPS PASS.

## 7. Что ещё не бар подхода

Честные дыры — `docs/design/OPEN_SPACE_SC_BENCHMARK.md` §3. Не «unfit», не выдумывать лишнее:

- Спавн OPEN SPACE 8 км AGL (OS-C). Петля 770 м — снизу, не единственный вид.
- Дальний шейдер всё ещё дешёвый subset vs полный `PlanetRelief` (WorldFill §5 / OS-A).
- Нет атмосферы / облаков / входа.
- Почти нет unnamed scatter и силуэта с высоты. Один unnamed пад.
- Грунт стоит, деталь низкая. Нет аэродинамики — только S-sink.
- G2–G6 закрыты. `M` = тост locked. `Tab` = Clash sandbox.
- Dummy MNULL=0 ≠ допуск. rules/25 на llvmpipe не подписывать.

---

## 8. Как повторить

```bash
./scripts/playtest_sandbox.sh
# /tmp/sb_mm.log /tmp/sb_os.log /tmp/sb_ta.log /tmp/sb_os_probe.log /tmp/sb_mech.log
```

Не рисуйте FPS PASS. Headless mechanics PASS ≠ «можно давать человеку».
