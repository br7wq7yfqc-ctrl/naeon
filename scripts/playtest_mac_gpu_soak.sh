#!/bin/bash
## Mac GPU 10-min OpenSpace soak. GUI Godot 4.7.2 — never --headless.
## Headless TIME_FPS is dummy. Pin /Applications/Godot.app (4.7.2);
## ~/Applications/Godot.app is 4.3 — do not use it.
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
if [ -x "$HOME/bin/godot" ]; then
  # ~/bin/godot must symlink to /Applications/Godot.app (4.7.2)
  GODOT="$HOME/bin/godot"
fi
if [ ! -x "$GODOT" ]; then
  echo "[soak] missing Godot 4.7.2 at $GODOT" >&2
  exit 2
fi
VER="$("$GODOT" --version 2>/dev/null || true)"
echo "[soak] using $GODOT ($VER) root=$ROOT"
case "$VER" in
  4.7.2*) ;;
  *) echo "[soak] want Godot 4.7.2, got: $VER" >&2; exit 2 ;;
esac
LOG="${SOAK_LOG:-$ROOT/logs/soak_mac_gpu.log}"
mkdir -p "$(dirname "$LOG")"
echo "[soak] log=$LOG duration=600s min-preset GUI (no --headless)"
# Mac has no GNU timeout. Python watchdog covers a hung window (~12 min).
# caffeinate keeps the GPU session awake.
set +e
/usr/bin/python3 - "$GODOT" "$ROOT/godot" "$LOG" <<'PY'
import subprocess, sys, time, os, signal
godot, path, log_path = sys.argv[1], sys.argv[2], sys.argv[3]
cmd = [
    "caffeinate", "-dimsu",
    godot,
    "--path", path,
    "--scene", "res://scenes/world/OpenSpace.tscn",
    "--", "--playtest-soak",
]
print("[soak] exec", " ".join(cmd), flush=True)
with open(log_path, "w") as log:
    log.write("[soak] start %s\n" % time.strftime("%Y-%m-%dT%H:%M:%S"))
    log.flush()
    p = subprocess.Popen(cmd, stdout=log, stderr=subprocess.STDOUT)
    deadline = time.time() + 720
    rc = None
    while time.time() < deadline:
        rc = p.poll()
        if rc is not None:
            break
        time.sleep(2)
    if rc is None:
        log.write("\n[soak] watchdog 720s — killing hung Godot\n")
        log.flush()
        try:
            os.kill(p.pid, signal.SIGTERM)
            time.sleep(3)
            if p.poll() is None:
                os.kill(p.pid, signal.SIGKILL)
        except OSError:
            pass
        rc = 124
    sys.exit(rc if rc is not None else 124)
PY
RC=$?
set -e
echo SOAK_CODE=$RC
grep -E '\[Soak\]|SCRIPT ERROR|Lambda capture' "$LOG" | tail -80 || true
if grep -q '\[Soak\] FAIL' "$LOG"; then
  exit 1
fi
if grep -q '\[Soak\] DONE' "$LOG"; then
  exit 0
fi
exit "$RC"
