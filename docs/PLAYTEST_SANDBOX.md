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
| Можно ли ставить PASS / FPS PASS? | **Нет.** |
| P0.1 runtime (seed / ring / park)? | **Да, на этом зонде.** `P0_1_RUNTIME=true` `RING_RESTORE=true` `SAME=true` |
| P0.2 срез (1 пад + 1 CC0 проп)? | **Да, на этом зонде.** `P0_2_SLICE=true` pads=1 filler=1. Манифест, не GLB в git. Tripo-герой **не** открыт. |
| Mechanics? | Печатает PASS. Occupy 0.55→0.66 к gROT. **Не human gate.** |
| Dummy `m is null`? | **Не ноль.** SCRIPT ERROR=0. Счётчик стабилен на dummy (см. §5). |

---

## 2. Что запускали

| Сцена | Код | SCRIPT ERROR | MNULL | Примечание |
|-------|-----|--------------|-------|------------|
| MainMenu | 0 | **0** | **0** | Clash кнопка = sandbox, не карта |
| OpenSpace boot | 0 | **0** | 29 | 1 тело. Fill cut. Dummy mesh_storage |
| TestArena | 0 | **0** | 42 | Clash greybox |
| Sandbox probe | 137 (`OS.kill`) | **0** | 9 | `HUMAN_UNFIT`. P0.1+P0.2 green |
| Mechanics | 137 | **0** | 220 | PASS (occupy/harvest честные). Не допуск |

---

## 3. Что стало лучше (этот прогон vs PR #7 / P0.1-only)

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
```

| Факт | Было (PR #7 / main) | P0.1 зонд | Стало (этот срез) |
|------|---------------------|-----------|-------------------|
| Seed | 61 vs 2778 | SAME=true | **SAME=true** (не сломали) |
| Тела | 3 + 7 стримеров | 1, fill cut | **1, fill cut** |
| Кольцо после отлёта | live=1 | live=9 cache=14 | **live=9 cache=14** |
| Пады на срезе | 3 + density | 3 (не резали) | **1 plate (Pad_North)** |
| Filler | нет / SITE_* риск | нет | **1 unnamed CC0, манифест only** |
| Nodes boot → approach | 413 → 551 | 194 → 308 | **183 → 229** |
| RAM approach | 42 MB | 36 MB | **35 MB** |
| Occupy | 0.55→0.08 + PASS | 0.55→0.66 | **0.55→0.66** (не gate) |
| Probe MNULL | ArrayMesh flood на подходе | ~27 boot | **probe 9** (чанки = BoxMesh на dummy) |

Человек на этом срезе должен увидеть: одну пластину пада + один ящик (proxy, пока GLB не на `s3://neon`). Не галактику. Не героя.

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

## 5. Dummy `m is null` — честно

`ERROR Parameter "m" is null` @ `dummy/storage/mesh_storage.h:120`. Не SCRIPT ERROR. Не вылет сцены.

Счётчик **не сдвинулся** после stand-in'ов (OS 29 / TA 42 / probe 9 / mech 220 на трёх подряд прогонах). Значит это не те PrimitiveMesh, которые мы перестали создавать в игре: dummy всё равно зовёт `mesh_get_surface_count` (Sky / ShaderMaterial / shutdown `--quit-after` / внутренние RID).

Что сделали, чтобы не кормить его сферами:

- `MeshSafe` + `PlanetMeshCache` на headless не конструирует SphereMesh
- SurfaceDetail cache = BoxMesh (кольцо всё равно restore)
- starfield / star / belt / orbital / hull GLB / scan / shield — skip
- hull / player / dummy сцены — BoxMesh в tscn
- ContestedRing / pylon / Clash / interior / walker — box, без `TorusMesh.new()` на dummy

`null_mesh_instances=0` в дереве зонда. Ошибка — внутри dummy renderer, не «mesh == null» у наших инстансов.

---

## 6. Что ещё HUMAN_UNFIT

- 5 мин soak и freeze >100 мс — только на GPU владельца.
- rules/25 FPS на llvmpipe **не** измеряем и **не** подписываем.
- Dummy `m is null` ≠ 0.
- P0.2 полный DoD из плана (Tripo-герой) **не** открыт. P0.3–P0.5 не открыты.
- G1–G6 locked. `M` = тост locked. `Tab` = Clash sandbox.

---

## 7. Как повторить

```bash
./scripts/playtest_sandbox.sh
# /tmp/sb_mm.log /tmp/sb_os.log /tmp/sb_ta.log /tmp/sb_os_probe.log /tmp/sb_mech.log
```

Не рисуйте FPS PASS. Headless mechanics PASS ≠ «можно давать человеку».
