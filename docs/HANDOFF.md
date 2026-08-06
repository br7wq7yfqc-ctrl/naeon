# NAEON — Handoff (Unified Session)

**Date:** 2026-08-06  
**Status:** Unified build-session active (gameplay + space + assets).

---

## 1. Current Project State

### Repository
- **Repo:** https://github.com/br7wq7yfqc-ctrl/naeon
- **Godot:** 4.3 project under `godot/` with playable TestArena + SpaceTest
- **Asset storage:** Yandex Object Storage bucket `neon`
- **Asset VM:** `ubuntu@84.201.170.6` (naexos-vm-fixed)

### Done in this session
- Playable **TestArena**: TPS movement, form cycle, Pulse / Nex-Firewall / System Probe, claimable pillars (Ownership visual blend), extractor + resource node → Contribution
- **ShipController**: semi-Newtonian flight, modular attach (engine/weapon/shield/extractor), fire, land → TestArena
- **Colony seed**: ResourceNode + Extractor + OwnershipComponent
- **Pipeline**: real Tripo OpenAPI client, Blender dual-theme LOD processor, `run_pipeline.sh`
- Mac + VM bootstrap (Godot, Blender, venv, `.env` templates)

### Blocked / next
- Tripo **balance = 0** → top up credits for end-to-end asset generation
- Configure YC S3 keys + rclone remote `neon` for bucket sync
- Polish combat targets / enemy dummy, animations, better ship mesh
- Optional: authorize SSH key on `89.169.142.255` if that host should replace/join the VM fleet

---

## 2. How to continue (single session)

1. Read `docs/LOCAL_SETUP.md`
2. Pull `main` on Mac + VM
3. Play TestArena / SpaceTest in Godot 4.3
4. When Tripo has credits: `./pipeline/scripts/run_pipeline.sh "prompt" asset_name B`
5. Commit focused slices; update this file when pausing

---

## 3. Constraints (unchanged)

- No secrets in git
- Heavy assets only in `assets/` + bucket
- macOS + Windows client target
- Soft Knowledge advantages only (no P2W)
- Local-first

---

*Unified session owns tracks A/B/C until further handoff.*
