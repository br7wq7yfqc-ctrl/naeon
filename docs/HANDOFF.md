# NAEON — Handoff (Unified Session)

**Date:** 2026-08-06  
**Status:** Unified build-session active (gameplay + space + assets).

---

## 1. Current Project State

### Repository
- **Repo:** https://github.com/br7wq7yfqc-ctrl/naeon
- **Godot:** 4.3 under `godot/` — TestArena + SpaceTest
- **Asset storage:** Yandex Object Storage bucket `neon` (`rclone neon:neon/dev`)
- **Primary dev machine:** Mac (`~/Documents/naeon`) — Docker + Grok CLI + Blender 4.5 + Godot 4.3

### Done
- Playable **TestArena**: TPS, forms, abilities, ownership pillars, extractor/resource node
- **CombatDummy** x4 (aggro + static), kill counter, Contribution on kill
- **GlbProp** runtime loader → sci_fi_crate Cybernex/gROT LODs in arena
- **ShipController** + modules + land → TestArena (SpaceTest)
- **Pipeline**: Tripo API live, Blender dual-theme LODs, S3 upload verified
- First real asset: `assets/props/sci_fi_crate` (also on `neon/dev/props/sci_fi_crate`)

### Next
1. More Priority B assets (console, barrier, ship hull, modules) within ~1000 credit budget
2. process_asset: preserve Tripo PBR + wear variants + collision export
3. Dummy AI polish / projectile VFX
4. Ship mesh from pipeline; landing pad prop
5. VM `aeldae@158.160.185.220` when SSH perimeter allows (`34.11.74.3`, `84.75.221.12`)

---

## 2. How to play (Mac)

```bash
cd ~/Documents/naeon/godot
godot .
# Tab: Arena ↔ Space | Q/E/R/F abilities | kill dummies | hack pillars
```

Pipeline:
```bash
cd ~/Documents/naeon && set -a && source .env && set +a
./pipeline/scripts/run_pipeline.sh "prompt" asset_name B
```

---

## 3. Constraints

- No secrets in git
- Heavy assets only in `assets/` + bucket `neon`
- Soft Knowledge advantages only (no P2W)
- Local-first on Mac until VM is reachable

---

*Unified session owns tracks A/B/C.*
