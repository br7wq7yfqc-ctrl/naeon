# NAEON — Local Development Setup

**Last update:** 2026-09-01  
**Scope:** Mac (Godot client) + Asset VM (Tripo/Blender pipeline)

---

## Machines

| Role | Host | Access |
|------|------|--------|
| Client / Godot | MacBook (`macbook-pro-vlad`, user `vladmann`) | Tailscale `100.101.32.21` |
| Asset Pipeline VM | `naexos-vm-fixed` **84.201.170.6** (key `~/.ssh/ssh-key-vm-restored`) | SSH from Mac |
| Object Storage | Yandex bucket `neon` | S3-compatible / rclone |

> Note: IP `89.169.142.255` was listed historically; current authorized VM is **84.201.170.6**. Add your pubkey to `ubuntu@89.169…` if that host is re-enabled.

---


---

## Tailscale autostart (Mac)

Sandbox SSH to the Godot Mac is `vladmann@100.101.32.21`. Tailscale must come
up at login **and** stay up after logout (unattended), or the Mac disappears
from the tailnet after reboot.

On the Mac, once:

```bash
cd ~/Documents/naeon
./tools/mac/enable_tailscale_autostart.sh
```

That script:

1. Adds **Tailscale.app** as a hidden login item.
2. Installs LaunchAgent `com.naeon.tailscale.autostart` (`RunAtLoad` + `KeepAlive`).
3. Runs `tailscale set --unattended` and `tailscale up`.

Requires Tailscale.app already in `/Applications`. Logs:
`~/Library/Logs/naeon-tailscale-autostart.log`.

No auth keys are stored in git. If the Mac is offline, run the installer locally
after the first GUI login; FileVault still needs a person at the keyboard once.

## Mac (Godot 4.7.2)

```bash
# Repo
git clone https://github.com/br7wq7yfqc-ctrl/naeon.git ~/Documents/naeon
# Godot 4.7.2 installed under ~/Applications/Godot.app  (symlink: ~/bin/godot)

cd ~/Documents/naeon
cp .env.example .env
# fill TRIPO_API_KEY and optional YC_* keys — never commit .env

# Open project
godot --path ~/Documents/naeon/godot
# or open TestArena via editor; main scene = scenes/test/TestArena.tscn
```

### Controls

**TestArena (TPS)**  
- WASD move, mouse look, Space jump, Shift sprint  
- Q Pulse Bolt · E Nex-Firewall · R System Probe (hack/claim) · F form cycle  
- Tab → SpaceTest  

**SpaceTest (Ship)**  
- WASD thrust/strafe, Space/Shift lift, mouse aim  
- Q fire · E land → TestArena · R attach Extractor module  

---

## Asset VM

```bash
ssh -i ~/.ssh/ssh-key-vm-restored ubuntu@84.201.170.6
cd ~/naeon
source .venv/bin/activate
source .env   # TRIPO_API_KEY etc.

# Dry-run (no credits)
python pipeline/scripts/generate_tripo.py \
  --prompt "cybernex canine robot scout dark neon" \
  --name canine_scout --priority B --dry-run

# Full generation (requires Tripo balance > 0)
./pipeline/scripts/run_pipeline.sh "prompt here" my_asset B

# Blender process only
python pipeline/scripts/process_asset.py --input pipeline/inbox/NAME/model.glb --name NAME
```

Installed on VM: Docker, Blender 4.2.9 LTS (`/opt/blender`), rclone, Python venv + requests.

---

## Secrets

- **Never commit** `.env`, keys, or `/assets/` binaries  
- Tripo: `TRIPO_API_KEY=tsk_...`  
- Yandex Object Storage: `YC_STORAGE_ACCESS_KEY` / `YC_STORAGE_SECRET_KEY`  
- Configure rclone remote `neon` for auto-sync (see `docs/ASSETS_STORAGE.md`)

---

## Unified session scope

This environment runs **all tracks** in one session:

1. **Gameplay** — TPS, Ability System, Ownership, TestArena  
2. **Space** — ShipController, modules, landing → TPS, colony extractor seed  
3. **Assets** — Tripo → Blender dual-theme LODs → `assets/` → bucket `neon`
