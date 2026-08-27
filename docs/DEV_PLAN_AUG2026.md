# NAEON Dev Plan — Aug 2026

**Authority:** `DEVELOPMENT_PLAN.md` v2.4 (длинный план) + `docs/design/BASE_STATION_STRATEGY.md` (текущий бар).  
Этот файл — статус, не склад фич.

## Current focus: ST-A strategy overlay (OS-A…OS-H built)

SC roles → NAEON: `docs/design/SC_FEATURE_MAP.md`.  
Clash / Predecessor bar: `docs/design/ARENA_PREDECESSOR_BENCHMARK.md`.  
Стратегия: `docs/design/BASE_STATION_STRATEGY.md`.

Не галактический слой. Петля P0.6 на RTX 3090 жива — не ломать. G2–G6 locked. G1 CRUISE closed.

| Шаг | State | Gist |
|-----|-------|------|
| **P0.6** land / EVA / takeoff | **built (3090)** | hold-S 770→0, HOVER+S, EVA на Relief, 6 мин / 60 FPS. Не FPS PASS на llvmpipe |
| **OS-A** шов сферы = Relief | **built** | WorldFill §5. Дальний фейк не подменяет грунт |
| **OS-B** оболочка атмосферы | **built** | envelope + лимб/туман + drag/потолок; 770 м S-sink жив |
| **OS-C** лестница 5–15 км | **built** | спавн 8 км AGL; far/лимб до 15 км; без G1 CRUISE |
| **OS-D** unnamed fill с 2 км | **built** | 3 unnamed пада + denser scatter с полок ledger (crate/debris/mast/pad props); без SITE_*; без семи стримеров |
| **OS-E** чтение у ног | **built + PBR leftover** | PBR CC0 albedo/rough/normal на чанках (fallback ImageTexture); chart UV; не unshaded; без GLB в git |
| **OS-F** полёт в атмосфере | **built** | lift/glide в плотном слое; STALL/HOVER/LAND/hold-S живы |
| **OS-G** силуэт аванпоста | **built** | мачта+habitat на одном unnamed паде; 8 км = 2 км = грунт |
| **OS-J** orbit-read vs dirt | **built** | FarPlate/FarMast/outpost unshaded only beyond ~400 m. Near = metal hull. Cyan 96 m slab was the pad monolith. |
| **OS-H** ритуал | **built (harness)** | space→atmo→land→EVA→takeoff→space; headless шаги. 60 FPS / 5 мин = 3090 human gate |
| **OS-I** ground proxy | **built (code) 0.3.26** | Один chart-домен орбита→грунт. Collision = Relief trimesh (не сфера). AGL vs dirt. SC: physics proxy = visual, quantized chunks, no sphere-as-ground. |
| **ST-A** | **built** | B overlay на unnamed паде; один habitat (0 combat); ship/TPS живы. Не SITE_*, не G2. |
| **ST-B** | next | Extractor + видимый Contribution |
| **NP-C** | **built** | NPC ставит один habitat на пустой unnamed пад (тот же BaseBuilder). Не SITE_*. |
| **G1 CRUISE** | later | Не нужен для 5–15 км; mass lock только вместе с CRUISE |
| **G2–G6** | **locked** | Пока петля OPEN SPACE не честна. В коде 404 |

## Старое «DONE» — не очередь

| Было | Честно |
|------|--------|
| G0 system layout **DONE 2026-08-15** | **built** (данные орбит). Не playable galaxy |
| Audit + hardening + `[Playtest] PASS` | **built** логика; **не** human gate |
| Next = G1 / T1 hypergate | **cut from now** (G1 не открыт OS-C) |
| PR #7 HUMAN_UNFIT | **снято** прогоном 3090 / P0.6 |



## OS-I — грунт как в SC (оптимизация физики, не картинки)

Бенчмарк: Star Citizen planetary approach / EVA — **роли**, не Planet Tech V5.

- **Один height field.** Orbit shader, SurfaceDetail, walker snap, ship AGL — `PlanetRelief` chart (`CHART_RADIUS`), не `lon * local_radius`. Иначе биомы/текстуры «перемешиваются» на шве LOD.
- **Collision proxy = visual Relief.** SC не ставит персонажа на гладкую сферу радиуса планеты. Чанк = ArrayMesh + trimesh. Сфера — только catch под каньонами/морем (`radius - 8`).
- **AGL vs dirt.** `altitude_of` = dist − (radius + max(relief, sea)). HOVER/посадка не считают «0» внутри горы.
- **Стриминг как у SC object containers:** чанки 40 м, hysteresis park, load budget 1 mesh/tick. Не воксельная оболочка.
- **Не делать:** физика на каждом LOD-сфере, второй FBM в near shader, GLB-террейн в git.

Human gate: персонаж и корабль стоят на видимом грунте, не проваливаются; шов орбита/пыль без сдвига текстур.

## Asset

Канон: `docs/design/ASSET_SOURCE_CANON.md`.  
Не T1 hypergate. Unnamed грунт/скала/флора — CC0/сканы в `s3://neon`, не git.  
S3 Index не патчить. `assets/` / `generations/` не в git.

## Standing gates

- No P2W, soft Knowledge, Infection cap 5, story ≠ power, Godot 4.7.2.
- rules/25: ~60 FPS на GPU владельца. llvmpipe не закрывает FPS.
- `site_pin` только из каталога. WorldFill не чеканит `SITE_*`.
- Не регрессить P0.6 runtime.
