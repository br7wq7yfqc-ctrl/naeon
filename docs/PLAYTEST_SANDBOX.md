# NAEON — Sandbox playtest (P0.1 + P0.2 runtime)

**Дата прогона:** 2026-08-17  
**Стенд:** Cursor Cloud VM, Godot **4.3.stable.official.77dcf97d8**  
**GPU:** нет. Headless = dummy. Visible был бы **llvmpipe**.  
**Ветка:** `cursor/p0-runtime-stabilize-3ba8`  
**Команда:** `scripts/playtest_sandbox.sh`  
**Зонд:** `godot/scripts/test/SandboxPlaytest.gd` (`--sandbox-playtest`)

Это отчёт «что стало лучше / что ещё HUMAN_UNFIT», не QA-stamp. **FPS / rules/25 не закрываем.** Mechanics PASS ≠ human gate.

Канон: DEVELOPMENT_PLAN v3 (PR #7) · WORLD_FILL (PR #6). G1–G6 не открыты.

Сырьё: `/opt/cursor/artifacts/sandbox_*.log` и `user://sandbox_playtest.txt`.

---

## 1. Вердикт

| Вопрос | Ответ |
|--------|-------|
| Пригоден ли прототип для человека? | **Ещё нет** — нет 5 мин soak на GPU владельца. |
| Можно ли ставить PASS / FPS PASS? | **Нет.** llvmpipe / dummy не закрывают rules/25. |
| P0.1 runtime (seed / ring / park)? | **Да, на этом зонде.** `P0_1_RUNTIME=true` `RING_RESTORE=true` `SAME=true` |
| P0.2 срез (1 пад + 1 CC0 проп)? | **Да, на этом зонде.** `P0_2_SLICE=true` pads=1 filler=1. Манифест, не GLB в git. Tripo-герой **не** открыт. |
| Mechanics? | Печатает PASS. Occupy 0.55→0.66 к gROT. **Не human gate.** |
| Dummy `m is null`? | **0 на этом прогоне** (счётчик не маскировали). Это не «человек может играть». |

---

## 2. Что запускали

Коды 137 = `timeout -s KILL` / `OS.kill` после settle. Ожидаемо: `SceneTree.quit()` / `--quit-after` на dummy сами кормят `mesh_get_surface_count`.

| Сцена | Код | SCRIPT ERROR | MNULL | Примечание |
|-------|-----|--------------|-------|------------|
| MainMenu | 137 | **0** | **0** | Clash кнопка = sandbox, не карта |
| OpenSpace boot | 137 | **0** | **0** | 1 тело. Fill cut. Было 29 (teardown) |
| TestArena | 137 | **0** | **0** | Clash greybox. Было 42 (teardown) |
| Sandbox probe | 137 (`OS.kill`) | **0** | **0** | `HUMAN_UNFIT`. P0.1+P0.2 green. Было 9 |
| Mechanics | 137 | **0** | **0** | PASS. Было 220 (interior/pylon/limbs/rover free) |

---

## 3. Что стало лучше (этот прогон)

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

## 6. Что ещё HUMAN_UNFIT

- 5 мин soak и freeze >100 мс — только на GPU владельца.
- rules/25 FPS на llvmpipe **не** измеряем и **не** подписываем.
- Dummy MNULL=0 на этом стенде ≠ «можно давать человеку». На GPU те же free деревьев (интерьер, пад, ровер) всё ещё hitch-риск, просто без dummy spam.
- P0.2 полный DoD из плана (Tripo-герой) **не** открыт — нет GPU/ключей. P0.3–P0.5 не открыты.
- G1–G6 locked. `M` = тост locked. `Tab` = Clash sandbox.

---

## 7. Как повторить

```bash
./scripts/playtest_sandbox.sh
# /tmp/sb_mm.log /tmp/sb_os.log /tmp/sb_ta.log /tmp/sb_os_probe.log /tmp/sb_mech.log
```

Не рисуйте FPS PASS. Headless mechanics PASS ≠ «можно давать человеку».
