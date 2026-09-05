#!/bin/bash
## Mac GPU 10-min OpenSpace soak. GUI Godot 4.7.2 — never --headless.
## Headless TIME_FPS is dummy. Pin /Applications/Godot.app (4.7.2);
## ~/Applications/Godot.app is 4.3 — do not use it.
set -eu
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
if [ -x "$HOME/bin/godot" ]; then
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
SAMPLES="${SOAK_SAMPLES:-$ROOT/logs/soak_samples.log}"
ENGINE="${SOAK_ENGINE:-$ROOT/logs/soak_engine.log}"
mkdir -p "$(dirname "$SAMPLES")"
: > "$SAMPLES"
echo "[soak] samples=$SAMPLES engine=$ENGINE duration=600s min-preset GUI (no --headless)"
set +e
/usr/bin/python3 - "$GODOT" "$ROOT/godot" "$ENGINE" "$SAMPLES" <<'PY'
import subprocess, sys, time, os, signal
godot, path, engine_log, samples = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
cmd = [
    "caffeinate", "-dimsu",
    godot,
    "--path", path,
    "--scene", "res://scenes/world/OpenSpace.tscn",
    "--", "--playtest-soak",
]
print("[soak] exec", " ".join(cmd), flush=True)
with open(engine_log, "w") as log:
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
echo '---SAMPLES---'
grep -aE '\[Soak\]|SCRIPT ERROR|Lambda capture' "$SAMPLES" | tail -80 || true
echo '---ENGINE GPU---'
grep -aE 'Vulkan|Metal|Device|llvmpipe|SCRIPT ERROR' "$ENGINE" | head -10 || true
if grep -aq '\[Soak\] FAIL' "$SAMPLES" 2>/dev/null; then
  exit 1
fi
if grep -aq '\[Soak\] DONE' "$SAMPLES" 2>/dev/null; then
  exit 0
fi
echo "[soak] no DONE in samples (rc=$RC)" >&2
exit 1
