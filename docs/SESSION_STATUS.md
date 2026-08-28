**2026-08-28 — IN-B: ops console + legal seats + life-support (not ship cockpit)**

**2026-08-28 — IN-A: station foyer/ops + hangar_bay pockets (not ship cockpit)**

**2026-08-28 — ST-G: own factory print §6(c) in the existing player cluster**

**2026-08-27 — ST-F: CX↔GR owner swap on one occupied unnamed pad**

**2026-08-27 — ST-E: player orbital cluster of two catalog modules**

**2026-08-27 — ST-D: hangar queue of one module on a catalog carrier**

**2026-08-27 — ST-C: print one catalog module at pad / NPC bench**

**2026-08-28 — NP-C: NPC habitat on empty unnamed pad**

# Session Status

**2026-08-27 — ST-B extractor + visible Contribution**

**2026-08-23 — ST-A strategy overlay**

**2026-08-21 — OS-I closeout (code): warm dirt before EVA snap, no analytic hill-fight, yaw 0/PI. Headless PASS. Human gate still 3090.**

**2026-08-17 — P0.6 на RTX 3090 жив; бар подхода записан**

OS-A…OS-H built. G2–G6 locked. G1 CRUISE closed.  
ST-A: `B` opens a top-down overlay on an unnamed Nex-Prime pad and places **one** habitat (0 combat). Esc/B leaves; ship + TPS still run. No `SITE_*`. No galaxy map.  
ST-B: occupy unnamed pad → harvest → Contribution number on the OpenSpace HUD. Visible `PadHarvestExtractor` (catalog slug `t1_resource_extractor`). Knowledge labels only.  
ST-C: spend Contribution/Biomass at `PadPrintBench` (§6(a)) → **one** catalog module. No cash-shop skip. Knowledge does not cheapen `rules/15`.  
ST-D: hangar queue of **one** module on a catalog carrier (`cybernex_capital_carrier` …). Refuse if mass/power exceeded. Not a mobile `SITE_*`.  
ST-E: player-owned orbital cluster of **two** catalog modules (dock + habitat) on Nex-Prime orbit. Same scene. Not a city. Not `SITE_*`. `ORBITAL_STATIONS` stays off.  
ST-F: occupy unnamed pad → `O` / `flip_cluster_owner` CX↔GR. Theme + services list change. Harvest / print / hangar numbers stay. Not a second `SITE_*`. Not arena-flip.  
ST-G: factory in the existing `PlayerOrbitalStation` cluster (ST-E stays dock+habitat). Spend Contribution/Biomass at bench (c) → **one** catalog module. Without factory, (c) refuses. No cash-shop skip. Knowledge does not cheapen `rules/15`.  
IN-A: `I` at the player orbital cluster or an occupied unnamed pad → station foyer/ops pocket. `I` on the ST-D catalog carrier → `hangar_bay` pocket. Seat↔pocket↔hatch stays. Hatch from station/hangar returns to pad or dock (not MainMenu). No `SITE_*`. 0 Tripo.  
IN-B: station **E** is board status / occupy / factory print gate (recycler toggle stays). **F** at `OpsSeat` or `HangarSeat` boards that seat; **I** returns to the same pocket. Live life-support readout; vented pocket uses the EVA suit soft warn (no HP). Station/hangar still ≠ ship cockpit. No `SITE_*`. 0 Tripo.

P0.6 on the owner's RTX 3090 stays the FPS fact. llvmpipe ≠ FPS PASS.

**Skill:** sequential-dev + holistic. Не ломать P0.6 runtime.

## Что теперь правда

| Документ | Роль |
|----------|------|
| `docs/design/BASE_STATION_STRATEGY.md` | ST-A…ST-G built |
| `docs/design/OPEN_SPACE_SC_BENCHMARK.md` | Бар подхода OS-A…OS-H. G2–G6 закрыты |
| `docs/design/ASSET_SOURCE_CANON.md` | unique→Tripo / CC0→neon / paid→neon+notice / отказ |
| `docs/design/WORLD_FILL.md` | Авторский скелет / безымянный filler. Не чеканит `SITE_*` |
| `docs/PLAYTEST_SANDBOX.md` | 3090 факт. Не FPS PASS на llvmpipe |
| `DEVELOPMENT_PLAN.md` v2.4 | Длинный план фаз |
| `docs/PROTOTYPE_TO_PLAYABLE.md` | Исторический audit 2026-08-15 |

## Tracks

| Track | Status |
|-------|--------|
| P0.6 runtime (HUD, descend, EVA, HOVER S) | **built** на 3090 — не регрессить |
| OPEN SPACE SC bar | **OS-A…OS-H built** — 60 FPS / 5 мин = 3090 human gate |
| ST-A strategy overlay | **built** — один habitat на unnamed паде |
| ST-B extractor / Contribution | **built** — occupy → harvest → HUD number |
| ST-C print one module | **built** — spend Contribution/Biomass → one catalog module |
| ST-D hangar queue | **built** — one module on catalog carrier; mass/power refuse |
| ST-E orbital cluster | **built** — two catalog modules (dock + habitat) near Nex-Prime |
| ST-F ownership swap | **built** — CX↔GR on one occupied unnamed pad; same-tier numbers |
| ST-G own factory print | **built** — factory in player cluster; spend → one catalog module; (c) refuses without factory |
| IN-A interiors bar | **built** — station pocket ≠ ship; hangar_bay ≠ ship; doors not locked props |
| IN-B interiors bar | **built** — ops console occupy/factory gate; F seat → I same pocket; LS readout |
| NP-C | **built** — NPC habitat on empty unnamed pad |
| Galaxy G2–G6 | **locked** |
| G1 CRUISE | **in-scope only for OS-C scale** |

## Asset catalog (не трогали)

- Ledger / locks / MANUAL_CATALOG — как на main. UUID не выдумывать.
- S3 Index стёрт 2026-08-15. Не патчили.
- Канон источника: готовое из сети максимум; Tripo только unique.

## Исторический audit 2026-08-15

101 scripts / 10 scenes / 12 autoloads, ~110 confirmed defects, blockers fixed.  
Запись: `docs/PROTOTYPE_TO_PLAYABLE.md`. Не текущий бар подхода.
