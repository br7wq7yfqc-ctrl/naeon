# NAEON — Sandbox playtest (P0 runtime PR)

**Стенд:** Cursor Cloud VM, Godot 4.3.stable  
**GPU:** Mesa llvmpipe / dummy. **FPS / rules/25 не закрываем.**  
**Ветка:** `cursor/p0-runtime-stabilize-3ba8`  
**Команда:** `scripts/playtest_sandbox.sh`

Это отчёт «что починено / что ещё HUMAN_UNFIT», не QA-stamp.

Канон: DEVELOPMENT_PLAN v3 (PR #7) · WORLD_FILL (PR #6). G1–G6 не открыты.

Сырьё после прогона: `/tmp/sb_os_probe.log`, `/tmp/sb_mech.log`, `user://sandbox_playtest.txt`.

---

## 1. Вердикт

Заполняется после `scripts/playtest_sandbox.sh` в этом PR.

| Вопрос | Ответ |
|--------|-------|
| Пригоден ли прототип для человека? | **Ещё нет** (нет 5 мин soak на GPU владельца; llvmpipe ≠ Mac). |
| Можно ли ставить FPS PASS? | **Нет.** |
| P0.1 runtime (seed / ring / park)? | см. лог зонда `P0_1_RUNTIME` / `RING_RESTORE` / `SAME` |

---

## 2. Что чинили в рантайме

- Один `PlanetRelief.body_seed` на тело; шейдер сферы и чанки берут его же.
- Дальняя сфера — cheap Relief subset (continent/ridge/sea), не второй value-noise FBM.
- `SurfaceDetail`: не пересобирает live/cache; park >220 м держит cache; заход восстанавливает кольцо; enqueue каждый тик (стоя тоже).
- Общий бюджет стримеров (`P0Slice` 1 build / 6 restore на кадр). Fill-стримеры в P0 не спавнятся. В срезе одно тело (Nex-Prime).
- Occupy: актёр в кольце; mechanics требует рост метра к фракции стоящего — иначе FAIL.
- `M` — тост «galaxy map locked». `Tab` / меню — Clash sandbox, не карта.

---

## 3. Что ещё HUMAN_UNFIT

- 5 мин soak и freeze >100 мс — только на GPU владельца.
- rules/25 FPS на llvmpipe не измеряем.
- P0.2–P0.5 (пад+проп+герой → чанк → тело → ARK) не открыты.
- G1–G6 locked.

---

## 4. Как повторить

```bash
./scripts/playtest_sandbox.sh
```
