# NAEON — Performance & Memory Discipline

**Version:** 0.1  
**Status:** Design + implementation authority (permanent)  
**Skill:** `naeon-holistic-economical` §25  
**Applies to:** All scenes including **primitive** TestArena, SpaceTest shells, hubs

---

## 1. Intent

Stand-alone client must stay playable on **weak machines**. FPS drops and memory leaks are defects even when the scene has “almost nothing” in it — primitive scenes are the **baseline**, not a free pass.

---

## 2. Targets (vertical slice)

| Metric | Target |
|--------|--------|
| FPS on minimum preset (VS scene) | ~**60** sustained |
| 1% lows | No multi-second freezes in normal play |
| Memory over 5 min idle | No steady monotonic climb |
| Memory over 5 min simple combat | No steady climb |
| Scene exit | Timers, tweens, signals, extra Resource refs cleared or pooled |
| Fleet presentation | Aggregated LOD — not 30 full-fidelity ships on min preset (rules/22) |

---

## 3. Hard rules

1. Profile gameplay PRs that touch `_process`, spawning, particles, UI lists, streaming (Godot Debugger / Monitor).
2. No unbounded per-frame allocations in hot paths — pool/reuse.
3. Disconnect signals; stop tweens/timers on exit.
4. Prefer `ResourceLoader` threaded loads; protect S1 land/dock from hitch spikes.
5. Particle/VFX budgets; off-screen disable; dual-theme must not double cost without need.
6. UI: virtualize long lists; avoid full-tree rebuild per tick.
7. AI/NPC: distance LOD; shared perception where possible.
8. **Leaks in empty scenes still count.**
9. Change one performance lever at a time; log in SHARED_AGENT_MEMORY.
10. Accept on **min preset** Mac + Windows, not only high-end.

---

## 4. Smoke before merge

- [ ] Touched scene, min preset → FPS note
- [ ] Idle 5 min → memory note
- [ ] Simple loop 5 min → memory note
- [ ] Leave scene → clean exit
- [ ] Regression → fix or revert before merge

---

## 5. Immersion vs cost

Seamless ladder (S0–S3) must not outrun budget. Stable S1 + 60 FPS beats fragile early S3.

---

## 6. VS must-have tooling

Debug overlay or documented Monitor steps for FPS/memory on TestArena and SpaceTest.

---

*Performance source of truth; skill §25 is the short form for agents.*
