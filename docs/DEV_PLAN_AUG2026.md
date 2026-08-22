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
| **OS-A…OS-H** | **built** | подход / ритуал. 60 FPS / 5 мин = 3090 human gate |
| **ST-A** | **built** | B overlay на unnamed паде; один habitat (0 combat); ship/TPS живы |
| **ST-B** | next | Extractor + видимый Contribution |
| **NP-C** | next after ST-A | NPC ставит один модуль |
| **G1 CRUISE** | later | Не нужен для 5–15 км |
| **G2–G6** | **locked** | Пока петля OPEN SPACE честна |

OS-A…OS-H remain built (P0.6 3090 loop). Do not regress them.

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
