# NAEON — Sandbox playtest (P0 runtime PR)

**Дата прогона:** 2026-08-17  
**Стенд:** Cursor Cloud VM, Godot **4.3.stable.official.77dcf97d8**  
**GPU:** нет. Headless = dummy. Visible был бы **llvmpipe**.  
**Ветка:** `cursor/p0-runtime-stabilize-3ba8`  
**Команда:** `scripts/playtest_sandbox.sh`  
**Зонд:** `godot/scripts/test/SandboxPlaytest.gd` (`--sandbox-playtest`)

Это отчёт «что починено / что ломается», не QA-stamp. **FPS / rules/25 не закрываем.**

Канон: DEVELOPMENT_PLAN v3 (PR #7) · WORLD_FILL (PR #6). G1–G6 не открыты.

Сырьё: `/opt/cursor/artifacts/sandbox_*.log` и `user://sandbox_playtest.txt`.

---

## 1. Вердикт

| Вопрос | Ответ |
|--------|-------|
| Пригоден ли прототип для человека? | **Ещё нет** — нет 5 мин soak на GPU владельца. Ближе: один seed, кольцо восстанавливается, нет семи волн на boot. |
| Можно ли ставить PASS / FPS PASS? | **Нет.** |
| P0.1 runtime (seed / ring / park)? | **Да, на этом зонде.** `P0_1_RUNTIME=true` `RING_RESTORE=true` `SAME=true` |
| Mechanics? | Печатает PASS. Occupy 0.55→0.66 к gROT (рост). **Не human gate.** |

Владелец был прав про live-хаос. После этого PR зонд больше не видит два seed и «live=1 после отлёта».

---

## 2. Что запускали

| Сцена | Код | SCRIPT ERROR | Примечание |
|-------|-----|--------------|------------|
| MainMenu | 0 | **0** | Clash кнопка = sandbox, не карта |
| OpenSpace boot | 0 | **0** | 1 тело (Nex-Prime). ROT-Hive / Shard-Moon skip. Fill streamers cut. `m is null` = dummy mesh |
| TestArena | 0 | **0** | Clash greybox |
| Sandbox probe | 137 (`OS.kill` после quit) | **0** | `HUMAN_UNFIT`. P0.1 checks green |
| Mechanics | 137 | **0** | PASS (occupy/harvest честные). Не допуск |

---

## 3. P0.1 факты (этот прогон)

```
seed Nex-Prime body=2778 shader=2778 detail=2778 SAME=true
bodies_spawned=1
detail[approach]   live=6 queue=3 cache=6 parked=false alt=65.9
detail[lateral]    live=7 queue=4 cache=11 parked=false alt=66.1
detail[retreat_400m] live=0 queue=0 cache=11 parked=true alt=392.7
detail[reapproach] live=9 queue=0 cache=14 parked=false alt=62.6
RING_RESTORE=true
P0_1_RUNTIME=true
```

Было (PR #7, main): Nex-Prime shader%97=61 vs relief%10000=2778 SAME=false; retreat live=0; reapproach live=1; 7 стримеров live; 3 тела.

Boot nodes **194** (было 413). Approach **308 / 36 MB** (было 551 / 42 MB). Fill-стримеры не спавнятся.

---

## 4. Mechanics (не human gate)

```
occupy presence meter 0.55 -> 0.66 side=gROT
harvest in-zone 0.02 -> 1 status=extracting
harvest after launch 2.06 -> 2.06
[Playtest] PASS
```

Раньше 0.55→0.08 всё равно PASS. Теперь рост к стоящей фракции обязателен; иначе FAIL. Летающий корабль после launch больше не держит extractor (только walker в кольце или севший корабль).

---

## 5. Что ещё HUMAN_UNFIT

- 5 мин soak и freeze >100 мс — только на GPU владельца.
- rules/25 FPS на llvmpipe **не** измеряем и **не** подписываем.
- P0.2–P0.5 (пад+проп+герой → чанк → тело → ARK) не открыты.
- Dummy `ERROR Parameter "m" is null` остаётся (не SCRIPT ERROR).
- G1–G6 locked. `M` = тост locked. `Tab` = Clash sandbox.

---

## 6. Как повторить

```bash
./scripts/playtest_sandbox.sh
# /tmp/sb_mm.log /tmp/sb_os.log /tmp/sb_ta.log /tmp/sb_os_probe.log /tmp/sb_mech.log
```

Не рисуйте FPS PASS. Headless mechanics PASS ≠ «можно давать человеку».
