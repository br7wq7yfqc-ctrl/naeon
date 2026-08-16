# NAEON Dev Plan — Aug 2026

**Authority:** `DEVELOPMENT_PLAN.md` v3.0 (лестница). Этот файл — статус, не очередь фич.

## Current focus: P0 Stabilization

Не галактический слой. Прототип непригоден для человека, пока P0 красный.

| Шаг | State | Gist |
|-----|-------|------|
| **P0.0** честный gate | **этот PR** | `docs/PLAYTEST_SANDBOX.md` — что ломается, не PASS |
| **P0.1** Terrain stabilize | next | Stop live chaos. Один seed. Нет пересборки видимого. Два шума сшить или выключить фейк |
| **P0.2** 1 пад + 1 CC0 проп + 1 Tripo-герой | after P0.1 | Самые малые объекты |
| **P0.3** один чанк | after P0.2 | Cache hit на повторный заход |
| **P0.4** одно тело | after P0.3 | Nex-Prime only в срезе |
| **P0.5** ARK | after P0.4 | Три тела обратно. Гейты dark |
| **G1–G6** | **locked** | Пока P0 не зелёный. G2–G6 в коде 404 |

## Старое «DONE» — не очередь

| Было | Честно |
|------|--------|
| G0 system layout **DONE 2026-08-15** | **built** (данные орбит). Не playable slice |
| Audit + hardening + `[Playtest] PASS` | **built** логика; **inert** как человеческий gate |
| Next = G1 CRUISE / T1 hypergate | **cut from now** |

## Asset

Канон: `docs/design/ASSET_SOURCE_CANON.md`.  
Не T1 hypergate. P0: один unique герой + CC0 проп.  
S3 Index не патчить. `assets/` / `generations/` не в git.

## Standing gates

- No P2W, soft Knowledge, Infection cap 5, story ≠ power, Godot 4.3.
- rules/25: ~60 FPS на GPU владельца. llvmpipe не закрывает FPS.
- `site_pin` только из каталога.
