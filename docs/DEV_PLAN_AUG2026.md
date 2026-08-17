# NAEON Dev Plan — Aug 2026

**Authority:** `DEVELOPMENT_PLAN.md` v2.1 (длинный план) + `docs/design/OPEN_SPACE_SC_BENCHMARK.md` (текущий бар).  
Этот файл — статус, не склад фич.

## Current focus: OPEN SPACE → бар подхода (OS-A … OS-H)

Не галактический слой. Петля P0.6 на RTX 3090 жива — не ломать.

| Шаг | State | Gist |
|-----|-------|------|
| **P0.6** land / EVA / takeoff | **built (3090)** | hold-S 770→0, HOVER+S, EVA на Relief, 6 мин / 60 FPS. Не FPS PASS на llvmpipe |
| **OS-A** шов сферы = Relief | **next** | WorldFill §5. Дальний фейк не подменяет грунт |
| **OS-B … OS-H** | after OS-A | атмосфера → масштаб → fill → near read → atmo flight → силуэт → ритуал |
| **G1 CRUISE** | OS-C only | Только если нужен честный подход 5–15 км + mass lock |
| **G2–G6** | **locked** | Пока петля OPEN SPACE не честна. В коде 404 |

## Старое «DONE» — не очередь

| Было | Честно |
|------|--------|
| G0 system layout **DONE 2026-08-15** | **built** (данные орбит). Не playable galaxy |
| Audit + hardening + `[Playtest] PASS` | **built** логика; **не** human gate |
| Next = G1 / T1 hypergate | **cut from now** (G1 только OS-C) |
| PR #7 HUMAN_UNFIT | **снято** прогоном 3090 / P0.6 |

## Asset

Канон: `docs/design/ASSET_SOURCE_CANON.md`.  
Не T1 hypergate. Unnamed грунт/скала/флора — CC0/сканы в `s3://neon`, не git.  
S3 Index не патчить. `assets/` / `generations/` не в git.

## Standing gates

- No P2W, soft Knowledge, Infection cap 5, story ≠ power, Godot 4.3.
- rules/25: ~60 FPS на GPU владельца. llvmpipe не закрывает FPS.
- `site_pin` только из каталога. WorldFill не чеканит `SITE_*`.
- Не регрессить P0.6 runtime.
