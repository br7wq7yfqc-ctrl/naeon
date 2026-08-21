# NAEON Dev Plan — Aug 2026

**Authority:** `DEVELOPMENT_PLAN.md` v2.1 (длинный план) + `docs/design/OPEN_SPACE_SC_BENCHMARK.md` (текущий бар).  
Этот файл — статус, не склад фич.

## Current focus: OS-E PBR leftover → occupy-refuel 0 → EVA/takeoff → OS-I physics → ST-A

SC roles → NAEON: `docs/design/SC_FEATURE_MAP.md` (OS-A first).  
Clash / Predecessor bar: `docs/design/ARENA_PREDECESSOR_BENCHMARK.md` (arena CODE after OS-A).

Не галактический слой. Петля P0.6 на RTX 3090 жива — не ломать.

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
| **OS-H** ритуал | **built (harness)** | space→atmo→land→EVA→takeoff→space; headless шаги. 60 FPS / 5 мин = 3090 human gate |
| **OS-I** физика грунта | **queued** | trimesh чанков = визуал; один chart; не проваливаться. Не voxel. Не этот PR |
| **occupy-refuel бак 0** | **next after this PR** | после спуска бак 0; occupy на паде наполняет со временем |
| **OS-H EVA/takeoff** | leftover | EVA snap после LAND + взлёт без load screen |
| **ST-A** стратегия / модульные базы | after OS-I / occupy / EVA | GPU-гейт OS-H снят. NP-C после ST-A |
| **G1 CRUISE** | later | Не нужен для 5–15 км; mass lock только вместе с CRUISE |
| **G2–G6** | **locked** | Пока петля OPEN SPACE не честна. В коде 404 |

## Старое «DONE» — не очередь

| Было | Честно |
|------|--------|
| G0 system layout **DONE 2026-08-15** | **built** (данные орбит). Не playable galaxy |
| Audit + hardening + `[Playtest] PASS` | **built** логика; **не** human gate |
| Next = G1 / T1 hypergate | **cut from now** (G1 не открыт OS-C) |
| PR #7 HUMAN_UNFIT | **снято** прогоном 3090 / P0.6 |

## Asset

Канон: `docs/design/ASSET_SOURCE_CANON.md`.  
Не T1 hypergate. Unnamed грунт/скала/флора — CC0/сканы в `s3://neon`, не git.  
S3 Index не патчить. `assets/` / `generations/` не в git.

## Standing gates

- No P2W, soft Knowledge, Infection cap 5, story ≠ power, Godot 4.7.2.
- rules/25: ~60 FPS на GPU владельца. llvmpipe не закрывает FPS.
- `site_pin` только из каталога. WorldFill не чеканит `SITE_*`.
- Не регрессить P0.6 runtime.
