# OPEN SPACE — бар подхода (не копия Star Citizen)

**Статус:** OS-A…OS-H built. OS-E leftover: PBR bind (this slice). OS-I physics queued. Версия 1.8, 2026-08-21.  
**Движок:** Godot 4.7.2.  
**Не открывать:** G2–G6. Код P0.6 (`OpenSpace`, `ShipController`, `SurfaceWalker`, `SurfaceDetail`, `GameHUD`) не ломать.

Это план, как довести OPEN SPACE до **ощущения** планетарного подхода в духе Star Citizen: увидел тело из космоса → вошёл в атмосферу → грунт непрерывен от орбиты до пыли → сел → вышел → взлетел → снова космос, без экрана загрузки, ~60 FPS на MED.

Это **не** копия технологий CIG и **не** обещание Planet Tech V5. Мы приближаем петлю и читаемость, не их пайплайн.

Канон: `docs/design/WORLD_FILL.md` · `docs/design/ASSET_SOURCE_CANON.md` · `docs/design/GALAXY_LAYER_PLAN.md` (G1 только как инструмент масштаба).

Полная карта столпов SC → NAEON (роли, не клон): [`SC_FEATURE_MAP.md`](SC_FEATURE_MAP.md).  
Сшивка орбита ≠ грунт: [`WORLD_FILL.md`](WORLD_FILL.md) §5.  
Clash нативен; бар арены — Predecessor/Paragon, не Arena Commander: [`ARENA_PREDECESSOR_BENCHMARK.md`](ARENA_PREDECESSOR_BENCHMARK.md).  
Стратегия — третий бар, не Clash и не полёт OPEN SPACE: [`BASE_STATION_STRATEGY.md`](BASE_STATION_STRATEGY.md).  
Дыры каталога (очередь, не новый catalog): [`WORLD_FILL.md`](WORLD_FILL.md) §6.  
Likeness — вся фантазия SC (лететь, стыковаться, ходить, работать, драться, жить) **ролями** в каноне NAEON, не копией IFCS / Planet Tech V5.

---

## 1. Канон (не размывать)

- Нет P2W. Knowledge soft. Infection max 5. story ≠ power.
- Одна резидентная система: **ARK**. WorldFill не чеканит `SITE_*` и не изобретает системы.
- Tripo только unique / фракция. Безымянный грунт, скала, флора — готовые CC0/сканы в `s3://neon`, никогда в git.
- Нет планетарной воксельной оболочки. Analytic Relief + чанки.
- Godot 4.7.2.
- **G1 CRUISE** — в скоупе, только если без него нечестный подход 5–15 км. **G2–G6 закрыты**, пока эта петля честна.
- Срезы прогрессивные. Каждый шаг играбелен на GPU. Петлю P0.6 на RTX 3090 не ломать.

---

## 2. Бар, который приближаем

Ощущение, не чеклист чужого движка:

космос (тело читается) → снижение → оболочка атмосферы → один рельеф орбита-грунт → посадка → шаг по поверхности → взлёт → космос.

Без load screen. ~60 FPS MED. Взрослый hard-sci-fi: плотность, подъём, рельеф — физика и логистика, не «ещё слой шума».

---

## 3. Честный P0.6 (17 Aug 2026, RTX 3090)

Прогон `ca904ec` / squash `987cd34`. Галактику не открывали. llvmpipe **не** закрывает FPS.

| Факт | Число |
|------|-------|
| Петля land / EVA / takeoff | работает |
| Hold-S | спуск 770 → 0 |
| HOVER + S | тонет |
| EVA | стоит на Relief |
| Soak | 6 мин без краша, 60 FPS, 0 debugger errors |

Headless `[Playtest] PASS` и зонд на dummy — не человеческий gate. На llvmpipe FPS PASS не ставить.

### Дыры против бара (не выдумывать лишние)

- Спавн OPEN SPACE — 8 км AGL (OS-C). Петля 770 м жива снизу.
- Два сэмплера высоты: дальний шейдер (дешёвый FBM-subset) vs `PlanetRelief`. Шов WorldFill §5 — первый визуальный must. Seed/chart на P0.6 уже общие; континенты с орбиты всё ещё не равны полному Relief.
- Облаков нет (не OS-B). Вход: лимб + туман + тонкая плотность на 770 м.
- Почти нет unnamed scatter и силуэта аванпоста с высоты. OS-D: 3 unnamed пада + denser unnamed scatter (ящики / `debris_cluster` / pad-пропсы / лишние мачты) с ~2 км и у грунта. OS-G: мачта+habitat на одном паде, читается с 8 км.
- Грунт достаточно читаем, чтобы стоять. OS-E leftover (этот срез): near PBR (CC0 albedo/rough/normal + fallback ImageTexture), не unshaded plastic. Chart UV = `CHART_RADIUS`. Бинарников в git нет.
- S-sink есть. Drag/потолок оболочки — OS-B. OS-F: подъём/планирование в плотном слое; 770 м тонкая оболочка без крыла.
- Три unnamed пада (`Pad_North` class). OS-G: один силуэт на `Pad_Approach`.

---

## 4. Срезы OS-A … OS-H

Каждый шаг: playable на GPU владельца. Не начинать следующий, пока текущий красный. Не открывать G2–G6 «чтобы было масштабнее».

### OS-A — один шов планеты

Дальняя сфера = тот же Relief (континент, хребет, море). LOD режет микродеталь, не подменяет шум. Без вокселей.

**Дефект на старом main:** `planet_surface.gdshader` — другой FBM + `seed % 97`; грунт — `PlanetRelief` `seed % 10000` в другой области. LOD **может** снять реки/микро; LOD **не может** подменить FBM.

**Сшивка:** far/impostor/mid = `PlanetRelief.height_macro_at` + `body_seed` + `sphere_xz`. `SurfaceDetail` на той же сферической области. EVA snap не трогать.

**DoD:** с подхода и с грунта одно тело. Нет «другой планеты» на 770 м. Петля P0.6 жива. Headless playtest не снимать.

### OS-B — оболочка атмосферы

Scatter + туман + плотность, которая уже трогает полёт (торможение / потолок, не полная аэродинамика).

`PlanetProfileCatalog.atmosphere_envelope` (Nex-Prime 1100 м). Плотность `t²` до оболочки — на 770 м тонкая, hold-S не душит. Гравитационный колодец P0.6 (`height*1.8`) не растягивать. Лимб Rayleigh/Mie + height fog + `fog_sun_scatter`. Потолок = damp на набор, не на S-sink.

**DoD:** F5 → лимб/туман читаются; у тела плотнее без ломки land/EVA/takeoff; headless playtest PASS. Нет load. 5 мин soak на 3090 без вылета.

### OS-C — лестница масштаба

Полезный подход с 5–15 км. **G1 CRUISE не открывали:** старт 8 км AGL + far-сфера/лимб до 15 км читаются без сверхсвета. Колодец `height*1.8` не растянут. Орбиты не раздували. G2–G6 закрыты.

**DoD:** с 5–15 км тело и лимб читаются; hold-S снижает к LAND READY без mouse pitch; EVA snap на 770 м жив. CRUISE нет — mass lock не нужен. После выхода корабль управляем. **Пип unnamed пада (`Pad_Approach` class) виден на HUD/radar со старта OS-C — не PADS 0.**

### OS-D — unnamed fill с высоты

WorldFill: scatter + дополнительные unnamed пады, читаемые с ~2 км. CC0/сканы первыми. Не `SITE_*`.

**В этом срезе:** `Pad_North` + `Pad_Approach` + `Pad_Flank` (локальные имена). Denser unnamed scatter с полок ledger: crate filler IDs, `debris_cluster`, `t1_resource_extractor`, `utility_bay`, extra mast (`outpost_mast_cc0`) на пластинах без OS-G. Code-first proxy, если GLB нет в git. CC0 строки только те, что уже были в `p0_filler_manifest.json`. Стримеры и `PadDensity` выключены. Чанк-бюджет не трогали. Не новый `SITE_*`.

**DoD:** с 2 км видны 2+ пластины и unnamed clutter (ящики / обломки / мачта / pad-проп). У грунта те же узлы. Нет live-хаоса семи стримеров. Git без GLB.

### OS-E — чтение у ног

Тайловый PBR, декали, near LOD. Грязь и камень не из Tripo.

**В этом срезе (leftover поверх PR #16):** `planet_surface_near.gdshader` — Forward+ PBR, не `unshaded`. Самплеры `albedo_tex` / `rock_tex` / `normal_tex` / `rough_tex`. Runtime биндит CC0 с `s3://neon` / `user://filler` / `assets/` (`forest_ground_04`, `rock_face`, Ground037, Rock023). Если PNG нет — процедурный `ImageTexture`, чтобы headless всё ещё был PBR, не пластилин. Chart UV всегда `PlanetRelief.CHART_RADIUS` (`dir_to_chart`) — body radius не перетайливает грязь vs камень. Декали + `decal_density` + near LOD fade. Высота по-прежнему только `PlanetRelief.height_at`. Чанк-бюджет (40 м / LOAD_BUDGET 1 / queue 12) не трогали. Walker snap не трогали. PNG/GLB не в git.

**DoD:** EVA: грунт не «пластилин одного шейдера»; семплеры связаны (CC0 или fallback). Relief тот же. 60 FPS MED на 3090 в этом кольце — human gate, не headless.

### OS-F — полёт в атмосфере

Подъём / планирование. **STALL / HOVER / LAND остаются.** S-sink не выкидывать.

**В этом срезе:** `ShipFlightModel.aero_lift_accel` на OS-B `t²` плотности. Подъём ⊥ потоку, к крылу, только в плотном слое (atmo ≥ 0.18). Вакуум и 770 м тонкая оболочка — без крыла. HOVER = VTOL, lift не мешает hold. Hold-S по-прежнему геометрический inward (не thrust в камеру — это уже ломалось на 3090). Потолок OS-B и land gate не трогали. TestArena / Clash / Player OTS не трогали.

**DoD:** плотный слой меняет траекторию; посадка и зависание честны. Без краша 5 мин.

### OS-G — один силуэт аванпоста с орбиты

Один unnamed комплекс **или** уже существующий catalog pin. **Не чеканить `SITE_*`.**

**В этом срезе:** `OutpostSilhouette` на уже существующем `Pad_Approach` (не новый пад, не `SITE_*`). Code-first мачта + habitat-прокси. Стрим падов с 8 км AGL, чтобы спавн OS-C видел то же пятно. С 2 км и с грунта — тот же узел. Остальные пластины OS-D без изменения. TestArena / Clash / Player OTS не трогали. G2–G6 закрыты.

**DoD:** с орбиты читается пятно/мачта/пад; на грунте то же место. Без новой системы и без гейта.

### OS-H — ритуал

Космос → атмосфера → посадка → EVA → взлёт → космос. Без load screen (тот же `OpenSpace.tscn`).

**В этом срезе — harness, не новый мир.** Скриптованный ритуал в `Phase0MechanicsPlaytest`: старт на высоте OS-C (8 км), лимб виден, hold-S без mouse pitch, вход в оболочку, посадка честным gate, EVA snap, взлёт, снова выше оболочки. Если шаг пропущен — FAIL громко. Не чеканит `SITE_*`. Не открывает G2–G6. TestArena / Clash не трогали. **18 Aug leftover:** descend from 8 km is playable — HOVER hold-S drops hundreds of metres in a few seconds, not 1 m/tap.

**Headless PASS ≠ FPS PASS.** Этот срез не закрывает 60 FPS MED и не закрывает 5 мин soak — это human gate на RTX 3090. llvmpipe / dummy не ставят FPS.

**DoD (этот PR):** все шаги ритуала проходят в headless; существующий `--playtest-mechanics` всё ещё PASS; в доке есть как прогнать петлю с F5. Галактика закрыта.

**F5 (человек, Godot 4.7.2):**
1. Открыть `godot/scenes/world/OpenSpace.tscn` и нажать F5 (или F5 с MainMenu → Open Space).
2. Спавн 8 км AGL. Тело и лимб атмосферы должны читаться. HUD: `S descend · E land · F EVA`.
3. **Hold S** — геометрический спуск, **без mouse pitch**.
4. У грунта: `3` HOVER (шасси авто вниз у пада; **G** — ручной toggle, SCM default up), погасить скорость, **E** — посадка (`LAND READY`).
5. **F** — EVA, встать на Relief.
6. **F** — сесть в корабль, **Space** — взлёт.
7. Набрать выше оболочки (HUD `ATMO 0%`). Сцена не меняется.

Headless (шаги, не FPS):

```bash
godot --headless --path godot --scene res://scenes/world/OpenSpace.tscn -- --playtest-ritual
# или полный gate, включая OS-A…OS-G + OS-H:
./scripts/playtest_headless_smoke.sh
```

Искать `[Playtest] OS-H STEP` и `[Playtest] PASS`. Строка `OS-H ritual complete (headless steps; not FPS PASS)` — не 3090.

---

### OS-I — физика грунта (SC bar, не CIG clone) — **queued, не этот PR**

Падение сквозь текстуры / «планета не считывается» — это не картинка. Коллайдер сферы `radius` ≠ визуальный Relief ±метры. Чанки без trimesh. Дальний шейдер и грунт на разных chart scale у тел ≠1400 м.

Не Planet Tech V5 и не воксельный шар. Роли из SC-ощущения:

| Роль SC (ощущение) | NAEON рычаг | Не делать |
|--------------------|-------------|-----------|
| Visual mesh = physical mesh | trimesh / height collider на live `SurfaceDetail` чанке; sphere catch только ниже Relief | планетарный voxel shell |
| Object Container streaming | уже: 40 м / budget 1 / queue 12 / park ~140–380 м AGL. Не расти кольцо | шире стрим «чтобы нарисовать сферу» |
| One chart orbit→dirt | `dir_to_chart` / `CHART_RADIUS` для paint **и** height/collision. Дальний шейдер — тот же chart, не `lon*planet_radius` на чужих телах | второй FBM |
| No fall-through | walker/ship floor = Relief height (или chunk trimesh), не `radius-8` sphere | отключать гравитацию |
| LOD drop, not replace | far unshaded subset; near PBR. Не подменять высоту | третий noise |

**DoD (когда очередь дойдёт):** персонаж и корабль не проваливаются сквозь грунт на Nex-Prime / ROT-Hive / Shard-Moon. EVA snap и LAND живы. Чанк-бюджет не вырос. Headless PASS. Не SITE_*. Не G2–G6.

## 5. Вне скоупа

- Копировать CIG / Planet Tech V5 / их воксельный шар.
- Вторая резидентная система, `GalaxyCatalog`, карта `M`, hyperdrive, гейты, Clash-из-мира (G2–G6).
- Tripo-горы, Tripo-грязь, меши в git, секреты, патч S3 Index.
- Переписывать P0.6 «с нуля».

Очередь кода: этот PR = OS-E PBR leftover. Дальше: occupy-refuel бак 0 → EVA snap + takeoff без load (добить OS-H) → OS-I physics → ST-A. NP-C после ST-A. Не G2–G6.
