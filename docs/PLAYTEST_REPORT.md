# Playtest Report — 2026-08-06

> **Stale smoke.** Таблица 10/10 — boot 2026-08-06, не человеческий gate.  
> **2026-08-17 RTX 3090 / P0.6 (`ca904ec`):** land / EVA / takeoff, hold-S 770→0, HOVER+S, EVA на Relief, 6 мин / 60 FPS, 0 debugger errors. Галактику не открывали.  
> llvmpipe ≠ FPS PASS. Headless PASS ≠ допуск. Живой отчёт: `docs/PLAYTEST_SANDBOX.md`. Бар подхода: `docs/design/OPEN_SPACE_SC_BENCHMARK.md`.

| Scene | Result |
|-------|--------|
| OpenSpace (main) | PASS |
| TestArena / Clash | PASS |
| SpaceTest | PASS |
| Player | PASS |
| Ship | PASS |
| CombatDummy | PASS |
| Turret | PASS |
| Extractor | PASS |
| ResourceNode | PASS |
| **TOTAL** | **10/10 smoke 2026-08-06 — не human gate** |

Notes:
- SCRIPT_ERROR=0 all modes
- BUSY_ADD_CHILD fixed (deferred HUD/ghost)
- HEADLESS_MESH_NULL = Godot dummy renderer, ignore for product QA

Updated: 2026-08-06T19:20:36.738214+00:00
